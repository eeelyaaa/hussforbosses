--!strict
-- Systems/Carry: a boss on the player's head, dropping it, grabbing it back (brief systems 6 and 7; m1-contract.md
-- C, E, K, L; m2-contract.md C "Carry", C2, D "Not saved" with [M2-02 M7, M8]).
--
-- Every carry has an ORIGIN ([M2-02 M8]):
--   fight  : a beaten boss (Fight win, or the GrantBoss hook with to=head). Not owned until placed. It is the only
--            carry that can vanish: grace over, death, reset, falling off, leaving. Its uid is minted at the win with
--            Session.newUid (unique for ever).
--   crate  : taken out of the delivery crate (Base.TakeCrate). The boss stays in the profile's `crate` until the one
--            mutate that places or sells it; any other end of the carry leaves it in the crate.
--   spot   : picked up from one of the owner's spots (Base.PickUp). It stays in `bosses` at its spot until the one
--            mutate that places it elsewhere, swaps or sells it; any other end puts it back on that spot. Its pad
--            stops filling while it is carried (the pad's stamp is moved to "now" when it comes back).
--   stolen : Systems/Steal (M2-15) lifts another player's boss (Carry.begin with origin "stolen"). It never enters
--            `dropped` and Grab is refused for it: a hazard, a fall, a reset, an over-speed or teleport, or leaving
--            ends it (Carry.lose) and Steal's onChanged listener returns the boss to its owner's spot.
-- Crate and spot carries are kept inside the owner's plot (brief 7: "a boss that belongs to you cannot be carried
-- out of your own base"): a carrier more than Config.Carry.BASE_MARGIN outside it is put back where it last stood
-- inside (TEAM CALL M2-11-3).
--
-- States (server's, per player): none -> carrying -> dropped (fight only; Hazards calls Carry.drop) -> carrying
-- (Carry.Grab, or walking into it, inside GRAB_S) or none (grace over) ; carrying -> placed (Base calls Carry.take).
-- The session's runtime key `carry` = { uid, creatureId, origin, spot } while carrying or dropped (Fight refuses
-- 'carrying'; Income stops a carried spot boss's pad).
--
-- Speed: WalkSpeed = Config.Carry.CARRY, FAST_CARRY with the Fast Carry pass (Bag.owns, cached, never yields), put
-- back each step if anything changes it. Movement check ([M2-02 M7]) every Heartbeat on the flat: a step longer than
-- speed x dt x STEP_MULT + STEP_PAD is a teleport; more than speed x WINDOW_MULT + WINDOW_PAD over any WINDOW_S
-- window is over-speed. Either pulls a fight/crate/spot carrier back to its last good position (TEAM CALL M2-11-4)
-- and ends a stolen carry (why "speed").
--
-- c2s: Carry.Grab { uid }. s2c: Carry.State (owner).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Session = require(script.Parent.Parent.Data.Session)
local Zones = require(script.Parent.Zones)
local Fight = require(script.Parent.Fight)
local Bag = require(script.Parent.Bag)

export type CarryT = {
	state: "carrying" | "dropped",
	origin: string, -- "fight" | "crate" | "spot" | "stolen"
	uid: string,
	creatureId: string,
	level: number,
	bought: any?, -- the bought mark { source, buyer } or nil
	spot: number?, -- origin "spot": the spot it came from
	stolenFrom: number?, -- origin "stolen": the owner's plot id
	dropPos: Vector3?,
	graceEnds: number?,
}

local Carry = {}

local ORIGINS = { fight = true, crate = true, spot = true, stolen = true }

local carries: { [Player]: CarryT } = {}
local listeners: { (Player, string, CarryT?, string?) -> () } = {}
-- movement check: recent flat samples { pos, at } (os.clock) for the window, and the last good position
local samples: { [Player]: { { pos: Vector3, at: number } } } = {}
local lastInside: { [Player]: Vector3 } = {}

Carry.stats = {
	log = {} :: { any },
	refused = {} :: { [string]: number },
	pulledBack = 0,
	teleports = 0,
	overSpeed = 0,
	keptInBase = 0,
}
local function logEvent(e: any)
	e.at = Zones.now()
	table.insert(Carry.stats.log, e)
	if #Carry.stats.log > 200 then
		table.remove(Carry.stats.log, 1)
	end
end
local function refused(reason: string)
	Carry.stats.refused[reason] = (Carry.stats.refused[reason] or 0) + 1
end

-- Carry.onChanged(fn(player, state, carry?, why?)): state "none" | "carrying" | "dropped" | "placed"; why is the reason
-- a carry ended ("grace", "died", "respawn", "left", "hazard", "speed", "check", ...) when state is "none".
function Carry.onChanged(fn: (Player, string, CarryT?, string?) -> ())
	table.insert(listeners, fn)
end

function Carry.get(player: Player): CarryT?
	return carries[player]
end

function Carry.isCarrying(player: Player): boolean
	local c = carries[player]
	return c ~= nil and c.state == "carrying"
end

-- The walk speed the server holds a carrier to (Fast Carry from the pass cache; never yields).
function Carry.speed(player: Player): number
	if Bag.owns(player, Config.Carry.FAST_PASS) then
		return Config.Carry.FAST_CARRY
	end
	return Config.Carry.CARRY
end

-- ------------------------------------------------------------------------------------------------ plot frame
-- A plot's own frame from its spots (base-layout plot plan: Spot_1 centre at (5, 22), Spot_2 at (45, 22), Spot_9 at
-- (5, 62) in plot units: x across 0..50, y deep 0..92 from the front fence line). Works for any turn of the plot.
local frames: { [Instance]: { o: Vector3, ex: Vector3, ey: Vector3 } } = {}
function Carry.plotFrame(plot: Model): { o: Vector3, ex: Vector3, ey: Vector3 }?
	local f = frames[plot]
	if f then
		return f
	end
	local s1, s2, s9 = plot:FindFirstChild("Spot_1"), plot:FindFirstChild("Spot_2"), plot:FindFirstChild("Spot_9")
	if not (s1 and s2 and s9 and s1:IsA("BasePart") and s2:IsA("BasePart") and s9:IsA("BasePart")) then
		return nil
	end
	local function fl(v: Vector3): Vector3
		return Vector3.new(v.X, 0, v.Z)
	end
	local ex = fl(s2.Position - s1.Position) / 40
	local ey = fl(s9.Position - s1.Position) / 40
	local o = fl(s1.Position) - ex * 5 - ey * 22
	f = { o = o, ex = ex.Unit, ey = ey.Unit }
	frames[plot] = f
	plot.AncestryChanged:Connect(function()
		if not plot:IsDescendantOf(game) then
			frames[plot] = nil
		end
	end)
	return f
end

-- (x, y) of a world position in the plot's frame, or nil when the plot has no frame.
function Carry.plotLocal(plot: Model, pos: Vector3): (number?, number?)
	local f = Carry.plotFrame(plot)
	if not f then
		return nil, nil
	end
	local d = Vector3.new(pos.X, 0, pos.Z) - f.o
	return d:Dot(f.ex), d:Dot(f.ey)
end

-- Is a world position inside the plot's 50 x 92 (plus margin)?
function Carry.insidePlot(plot: Model, pos: Vector3, margin: number?): boolean
	local x, y = Carry.plotLocal(plot, pos)
	if not x or not y then
		return false
	end
	local m = margin or 0
	return x >= -m and x <= Config.Base.PLOT_W + m and y >= -m and y <= Config.Base.PLOT_D + m
end

-- Is the player's root inside the plot they own?
function Carry.insideOwnPlot(player: Player, margin: number?): boolean
	local plot = Session.plot(player)
	local r = Bag.root(player)
	if not plot or not r or plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return false
	end
	return Carry.insidePlot(plot, r.Position, margin)
end

-- ------------------------------------------------------------------------------------------------ state
local function humanoid(player: Player): Humanoid?
	local ch = player.Character
	return ch and ch:FindFirstChildOfClass("Humanoid")
end

-- Server-set slow-downs (M2-11b; the Iron Grip stagger): while one runs, a carrier's WalkSpeed is the carry speed x
-- factor. The movement check keeps the unslowed Carry.speed (a slowed carrier is never over its limit).
local slows: { [Player]: { factor: number, untilT: number } } = {}
local applied: { [Player]: number } = {} -- the WalkSpeed this module last set on a carrier

-- Carry.setSlow(player, factor, seconds): slows a carrier to factor x the carry speed for `seconds` (server clock,
-- os.clock). factor in (0, 1]; a later call replaces an earlier one; factor 1 or seconds <= 0 clears it. Never yields.
-- Ends by itself; the carry ending also clears it.
function Carry.setSlow(player: Player, factor: number, seconds: number)
	if not Net.isNumber(factor, 0, 1) or not Net.isNumber(seconds) or factor >= 1 or seconds <= 0 or factor <= 0 then
		slows[player] = nil
	else
		slows[player] = { factor = factor, untilT = os.clock() + seconds }
	end
	local c = carries[player]
	if c then
		Carry.send(player, c.state, c)
	end
end

-- The walk speed the server holds a carrier to right now (slow included).
function Carry.walkSpeed(player: Player): number
	local s = slows[player]
	if s and os.clock() < s.untilT then
		return Carry.speed(player) * s.factor
	end
	slows[player] = nil
	return Carry.speed(player)
end

local function applySpeed(player: Player)
	local hum = humanoid(player)
	if not hum then
		return
	end
	if Carry.isCarrying(player) then
		local speed = Carry.walkSpeed(player)
		if hum.WalkSpeed ~= speed then
			hum.WalkSpeed = speed
		end
		applied[player] = speed
	else
		slows[player] = nil
		local was = applied[player]
		applied[player] = nil
		if (hum.WalkSpeed == Config.Carry.CARRY or hum.WalkSpeed == Config.Carry.FAST_CARRY or hum.WalkSpeed == was)
			and hum.WalkSpeed ~= Config.Carry.WALK then
			-- back to walking; any other value (a fight's 0) belongs to another system and is left alone
			hum.WalkSpeed = Config.Carry.WALK
		end
	end
end

-- Re-applies the carry speed (Systems/Passes calls it after a Fast Carry purchase).
function Carry.refreshSpeed(player: Player)
	applySpeed(player)
	local c = carries[player]
	if c then
		Carry.send(player, c.state, c)
	end
end

function Carry.send(player: Player, state: string, c: CarryT?)
	if player.Parent ~= Players then
		return
	end
	Net.get("Carry", "State"):FireClient(player, {
		state = state,
		uid = c and c.uid,
		creatureId = c and c.creatureId,
		level = c and c.level,
		bought = c and c.bought and c.bought.source or nil,
		stolenFrom = c and c.stolenFrom,
		speed = Carry.speed(player),
		slowSpeed = (slows[player] and Carry.walkSpeed(player)) or nil, -- M2-11b: the stagger's speed while it runs
		origin = c and c.origin,
		dropPos = c and c.dropPos,
		graceEnds = c and c.graceEnds,
	})
end

local function set(player: Player, state: string, c: CarryT?, why: string?)
	if state == "carrying" or state == "dropped" then
		local cc = c :: CarryT
		carries[player] = cc
		Session.set(player, "carry", { uid = cc.uid, creatureId = cc.creatureId, origin = cc.origin, spot = cc.spot })
	else
		carries[player] = nil
		if Session.get(player) then
			Session.set(player, "carry", nil)
		end
	end
	samples[player] = nil
	if state ~= "carrying" then
		lastInside[player] = nil
	end
	applySpeed(player)
	Carry.send(player, state, c)
	logEvent({ kind = state, why = why, userId = player.UserId, uid = c and c.uid, creatureId = c and c.creatureId, origin = c and c.origin })
	for _, fn in ipairs(table.clone(listeners)) do
		local ok, err = pcall(fn, player, state, c, why)
		if not ok then
			warn("[HFB] Carry listener error: " .. tostring(err))
		end
	end
end

-- Puts a boss on the player's head. opts: { origin = "fight" (default) | "crate" | "spot" | "stolen", uid, level,
-- bought, spot, stolenFrom }. A fight carry with no uid gets one from Session.newUid. Refused while already carrying
-- or dropped. Returns the carry or nil.
function Carry.begin(player: Player, creatureId: string, opts: { [string]: any }?): CarryT?
	local o = opts or {}
	if carries[player] then
		refused("busy")
		return nil
	end
	local origin = o.origin or "fight"
	if not Session.get(player) or Config.Zones.POWER[creatureId] == nil or not ORIGINS[origin] then
		refused("bad")
		return nil
	end
	local uid = o.uid
	if uid == nil then
		if origin ~= "fight" then
			refused("bad")
			return nil
		end
		uid = Session.newUid(player)
		if uid == nil then
			refused("bad")
			return nil
		end
	end
	local level = if Net.isInt(o.level, 1, Config.Upgrades.LEVEL_CAP) then o.level else Config.Income.DEFAULT_LEVEL
	local c: CarryT = {
		state = "carrying",
		origin = origin,
		uid = uid,
		creatureId = creatureId,
		level = level,
		bought = o.bought,
		spot = o.spot,
		stolenFrom = o.stolenFrom,
	}
	set(player, "carrying", c)
	return c
end

-- A hazard hit while carrying. A fight carry's boss lies where it fell for GRAB_S; any other carry ends at once
-- ([M2-02 M8]: crate and spot bosses stay where the profile has them; a stolen one goes back to its owner).
-- Systems/Hazards pushes the carrier. Returns true when the carry was affected.
function Carry.drop(player: Player, at: Vector3, why: string?): boolean
	local c = carries[player]
	if not c or c.state ~= "carrying" then
		return false
	end
	if c.origin ~= "fight" then
		Carry.lose(player, why or "hazard")
		return true
	end
	local d: CarryT = table.clone(c)
	d.state = "dropped"
	d.dropPos = at
	d.graceEnds = Zones.now() + Config.Carry.GRAB_S
	set(player, "dropped", d)
	return true
end

-- The carry ends without placing: a fight boss is gone; a crate boss is still in the crate; a spot boss is back on its
-- spot (its pad starts filling again from now); a stolen one is returned by Systems/Steal's listener.
function Carry.lose(player: Player, why: string)
	local c = carries[player]
	if not c then
		return
	end
	logEvent({ kind = "lost", why = why, userId = player.UserId, origin = c.origin, uid = c.uid })
	set(player, "none", c, why)
	if c.origin == "spot" then
		local uid = c.uid
		local now = Zones.now()
		Session.mutate(player, function(q)
			for _, b in ipairs(q.bosses) do
				if b.uid == uid then
					b.padStamp = math.max(b.padStamp, now)
				end
			end
		end)
	end
end

-- Systems/Base: the carried boss leaves the head for a spot, or is sold. Returns the carry or nil.
function Carry.take(player: Player): CarryT?
	local c = carries[player]
	if not c or c.state ~= "carrying" then
		return nil
	end
	set(player, "placed", c)
	return c
end

-- Grab a dropped boss (only a fight carry is ever dropped). Rules (contract C): only the dropper, within
-- GRAB_RANGE of it, before graceEnds, alive. Returns nil on success or the refusal reason.
function Carry.tryGrab(player: Player, uid: any): string?
	if not Net.isShortString(uid, 64) then
		refused("bad")
		return "bad"
	end
	local c = carries[player]
	if not c or c.state ~= "dropped" or c.origin ~= "fight" then
		refused("state")
		return "state"
	end
	if c.uid ~= uid then
		refused("uid")
		return "uid"
	end
	if Zones.now() > (c.graceEnds :: number) then
		refused("late")
		return "late"
	end
	local r = Bag.root(player)
	if not r or (r.Position - (c.dropPos :: Vector3)).Magnitude > Config.Carry.GRAB_RANGE then
		refused("range")
		return "range"
	end
	local g: CarryT = table.clone(c)
	g.state = "carrying"
	g.dropPos = nil
	g.graceEnds = nil
	set(player, "carrying", g)
	return nil
end

-- The server moved the character itself (a push, a check): the movement check starts over from here.
function Carry.resetAnchor(player: Player)
	samples[player] = nil
end

local function flatDist(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function putBack(player: Player, r: BasePart, to: Vector3)
	local ch = player.Character :: Model
	local back = Vector3.new(to.X, math.max(to.Y, r.Position.Y), to.Z)
	ch:PivotTo(CFrame.new(back) * r.CFrame.Rotation)
	r.AssemblyLinearVelocity = Vector3.zero
	samples[player] = { { pos = back, at = os.clock() } }
end

-- One carrier's movement check. Returns false when the carry ended.
local function checkMove(player: Player, c: CarryT, r: BasePart, clock: number, dt: number): boolean
	local list = samples[player]
	local pos = r.Position
	if not list or #list == 0 then
		samples[player] = { { pos = pos, at = clock } }
		return true
	end
	local speed = Carry.speed(player)
	local C = Config.Carry
	local last = list[#list]
	local stepLen = flatDist(pos, last.pos)
	local kind: string? = nil
	local backTo = last.pos
	if stepLen > speed * math.max(dt, clock - last.at) * C.STEP_MULT + C.STEP_PAD then
		kind = "teleport"
	else
		-- drop samples older than the window; the oldest left is the window's start
		while #list > 1 and clock - list[1].at > C.WINDOW_S do
			table.remove(list, 1)
		end
		if flatDist(pos, list[1].pos) > speed * C.WINDOW_MULT + C.WINDOW_PAD then
			kind = "overSpeed"
			backTo = list[1].pos -- the window's start: the last position known to be within the rule
		end
	end
	if kind then
		if kind == "teleport" then
			Carry.stats.teleports += 1
		else
			Carry.stats.overSpeed += 1
		end
		logEvent({ kind = kind, userId = player.UserId, origin = c.origin, moved = stepLen })
		if c.origin == "stolen" then
			Carry.lose(player, "speed")
			return false
		end
		Carry.stats.pulledBack += 1
		putBack(player, r, backTo)
		return true
	end
	table.insert(list, { pos = pos, at = clock })
	if #list > 240 then
		table.remove(list, 1)
	end
	return true
end

-- A crate or spot carrier stays inside the own plot.
local function keepInBase(player: Player, r: BasePart)
	local plot = Session.plot(player)
	if not plot or plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end
	if Carry.insidePlot(plot, r.Position, Config.Carry.BASE_MARGIN) then
		lastInside[player] = r.Position
		return
	end
	local back = lastInside[player]
	if back then
		Carry.stats.keptInBase += 1
		logEvent({ kind = "keptInBase", userId = player.UserId })
		putBack(player, r, back)
	end
end

local function step(dt: number)
	local now = Zones.now()
	local clock = os.clock()
	for player, c in pairs(carries) do
		if c.state == "dropped" then
			if now > (c.graceEnds :: number) then
				Carry.lose(player, "grace")
			else
				local r = Bag.root(player)
				if r and flatDist(r.Position, c.dropPos :: Vector3) <= Config.Carry.WALK_IN_GRAB
					and math.abs(r.Position.Y - (c.dropPos :: Vector3).Y) < 6 then
					Carry.tryGrab(player, c.uid)
				end
			end
		else
			applySpeed(player)
			local r = Bag.root(player)
			if r and checkMove(player, c, r, clock, dt) then
				if (c.origin == "crate" or c.origin == "spot") and carries[player] == c then
					keepInBase(player, r)
				end
			end
		end
	end
end

function Carry.start()
	Fight.onEnd(function(player, f, state)
		if state == "win" and player.Parent == Players then
			Carry.begin(player, f.creatureId)
		end
	end)

	Net.onServerEvent("Carry", "Grab", function(player, payload)
		Carry.tryGrab(player, payload.uid)
	end)

	local function watch(player: Player)
		player.CharacterAdded:Connect(function(ch)
			-- a respawn (reset, death, falling off the map) while carrying or dropped
			Carry.lose(player, "respawn")
			local hum = ch:WaitForChild("Humanoid", 5) :: Humanoid?
			if hum then
				hum.Died:Connect(function()
					Carry.lose(player, "died")
				end)
			end
		end)
		local ch = player.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Died:Connect(function()
				Carry.lose(player, "died")
			end)
		end
		Carry.send(player, "none", nil)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(watch, p)
	end
	-- Leaving (and the Leave hook, shutdown): the carry ends before the final save, so a spot boss's stamp is right and
	-- Systems/Steal's listener returns a stolen boss first.
	Session.onLeaving(function(player)
		if carries[player] then
			Carry.lose(player, "left")
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if carries[player] then
			logEvent({ kind = "lost", why = "left", userId = player.UserId })
		end
		carries[player] = nil
		samples[player] = nil
		lastInside[player] = nil
		slows[player] = nil
		applied[player] = nil
	end)

	-- A wipe clears the carry (the session's carry key becomes nil from outside this module).
	Session.onChanged(function(player, key, value)
		if key == "carry" and value == nil and carries[player] then
			carries[player] = nil
			samples[player] = nil
			applySpeed(player)
			Carry.send(player, "none", nil)
		end
	end)

	RunService.Heartbeat:Connect(step)
end

return Carry
