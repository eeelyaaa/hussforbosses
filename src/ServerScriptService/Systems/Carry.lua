--!strict
-- Systems/Carry: the beaten boss on the player's head, dropping it, grabbing it back (brief system 6;
-- m1-contract.md sections C, E, K, L).
--
-- States (server's, per player): none -> carrying (a win, or the GrantBoss hook) -> dropped (a hazard hit;
-- Systems/Hazards calls Carry.drop) -> carrying (Carry.Grab, or walking into it, inside GRAB_S) or none (grace
-- over: the boss is gone) ; carrying -> placed (Systems/Base calls Carry.take) -> none.
-- Death, reset, falling off the map or leaving while carrying or dropped: the boss is gone.
-- The session holds `carry = { uid, creatureId }` while carrying AND while dropped (TEAM CALL M1-11b: a fight is
-- refused 'carrying' during the 5 s grace, so "the boss is gone and the player may fight for another" holds).
--
-- Speed: while carrying the server sets Humanoid.WalkSpeed = Config.Carry.CARRY (FAST_CARRY with the pass, M2)
-- and puts it back each step if anything changes it; a lenient server-side distance check (TEAM CALL M1-11c)
-- pulls a carrier back to the last good spot when it moved clearly faster than the carry speed over a window.
--
-- c2s: Carry.Grab { uid }. s2c: Carry.State (owner). Hook: GrantBoss (state hook, every player).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)
local Session = require(script.Parent.Parent.Data.Session)
local Zones = require(script.Parent.Zones)
local Fight = require(script.Parent.Fight)
local Bag = require(script.Parent.Bag)

export type CarryT = {
	state: "carrying" | "dropped",
	uid: string,
	creatureId: string,
	dropPos: Vector3?,
	graceEnds: number?,
}

local Carry = {}


local carries: { [Player]: CarryT } = {}
local listeners: { (Player, string, CarryT?) -> () } = {}
-- speed check: last good root position and its time
local anchor: { [Player]: { pos: Vector3, at: number } } = {}

-- Checks read these (module state, never the client's).
Carry.stats = {
	log = {} :: { any },
	refused = {} :: { [string]: number },
	pulledBack = 0,
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

-- Carry.onChanged(fn(player, state, carry?)): state is "none" | "carrying" | "dropped" | "placed".
function Carry.onChanged(fn: (Player, string, CarryT?) -> ())
	table.insert(listeners, fn)
end

function Carry.get(player: Player): CarryT?
	return carries[player]
end

function Carry.isCarrying(player: Player): boolean
	local c = carries[player]
	return c ~= nil and c.state == "carrying"
end

-- The walk speed the server holds a carrier to.
function Carry.speed(_player: Player): number
	return Config.Carry.CARRY -- Fast Carry (Config.Carry.FAST_CARRY) is the M2 pass
end

local function humanoid(player: Player): Humanoid?
	local ch = player.Character
	return ch and ch:FindFirstChildOfClass("Humanoid")
end

local function applySpeed(player: Player)
	local hum = humanoid(player)
	if not hum then
		return
	end
	local carry = Carry.speed(player)
	if Carry.isCarrying(player) then
		if hum.WalkSpeed ~= carry then
			hum.WalkSpeed = carry
		end
	elseif hum.WalkSpeed == carry and carry ~= Config.Carry.WALK then
		-- back to walking; any other value (a fight's 0) belongs to another system and is left alone
		hum.WalkSpeed = Config.Carry.WALK
	end
end

local function send(player: Player, state: string, c: CarryT?)
	if player.Parent ~= Players then
		return
	end
	Net.get("Carry", "State"):FireClient(player, {
		state = state,
		uid = c and c.uid,
		creatureId = c and c.creatureId,
		dropPos = c and c.dropPos,
		graceEnds = c and c.graceEnds,
	})
end

local function set(player: Player, state: string, c: CarryT?)
	if state == "carrying" or state == "dropped" then
		carries[player] = c
		Session.set(player, "carry", { uid = (c :: CarryT).uid, creatureId = (c :: CarryT).creatureId })
	else
		carries[player] = nil
		if Session.get(player) then
			Session.set(player, "carry", nil)
		end
	end
	anchor[player] = nil
	applySpeed(player)
	send(player, state, c)
	logEvent({ kind = state, userId = player.UserId, uid = c and c.uid, creatureId = c and c.creatureId })
	for _, fn in ipairs(table.clone(listeners)) do
		local ok, err = pcall(fn, player, state, c)
		if not ok then
			warn("[HFB] Carry listener error: " .. tostring(err))
		end
	end
end

-- Puts a boss on the player's head (a win, or the GrantBoss hook). Replaces nothing: refused while already
-- carrying or dropped. Returns the carry or nil.
function Carry.begin(player: Player, creatureId: string): CarryT?
	if carries[player] then
		refused("busy")
		return nil
	end
	if not Session.get(player) or Config.Zones.POWER[creatureId] == nil then
		refused("bad")
		return nil
	end
	local c: CarryT = { state = "carrying", uid = HttpService:GenerateGUID(false), creatureId = creatureId }
	set(player, "carrying", c)
	return c
end

-- A hazard hit while carrying: the boss lies where it fell for GRAB_S. Systems/Hazards pushes the carrier.
function Carry.drop(player: Player, at: Vector3): boolean
	local c = carries[player]
	if not c or c.state ~= "carrying" then
		return false
	end
	local d: CarryT = {
		state = "dropped",
		uid = c.uid,
		creatureId = c.creatureId,
		dropPos = at,
		graceEnds = Zones.now() + Config.Carry.GRAB_S,
	}
	set(player, "dropped", d)
	return true
end

-- The boss is gone (grace over, death, reset, leave, wipe).
function Carry.lose(player: Player, why: string)
	if not carries[player] then
		return
	end
	logEvent({ kind = "lost", why = why, userId = player.UserId })
	set(player, "none", nil)
end

-- Systems/Base: the carried boss leaves the head for a spot. Returns {uid, creatureId} or nil.
function Carry.take(player: Player): CarryT?
	local c = carries[player]
	if not c or c.state ~= "carrying" then
		return nil
	end
	set(player, "placed", c)
	return c
end

-- Grab a dropped boss. Rules (contract C): only the dropper, within GRAB_RANGE of it, before graceEnds, alive.
-- Returns nil on success or the refusal reason.
function Carry.tryGrab(player: Player, uid: any): string?
	if not Net.isShortString(uid, 64) then
		refused("bad")
		return "bad"
	end
	local c = carries[player]
	if not c or c.state ~= "dropped" then
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
	set(player, "carrying", { state = "carrying", uid = c.uid, creatureId = c.creatureId })
	return nil
end

-- The server moved the carrier itself (a push): the speed check starts over from here.
function Carry.resetAnchor(player: Player)
	anchor[player] = nil
end

local function flatDist(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function step()
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
			if r then
				local a = anchor[player]
				if not a then
					anchor[player] = { pos = r.Position, at = clock }
				elseif clock - a.at >= Config.Carry.SPEED_WINDOW then
					local dt = clock - a.at
					local allowed = Carry.speed(player) * dt * Config.Carry.SPEED_SLACK + Config.Carry.SPEED_PAD
					if flatDist(r.Position, a.pos) > allowed then
						-- too fast for a carrier: back to the last good spot (keeps the height the client has)
						Carry.stats.pulledBack += 1
						logEvent({ kind = "pulledBack", userId = player.UserId, moved = flatDist(r.Position, a.pos), allowed = allowed })
						local ch = player.Character :: Model
						local back = Vector3.new(a.pos.X, math.max(a.pos.Y, r.Position.Y), a.pos.Z)
						ch:PivotTo(CFrame.new(back) * r.CFrame.Rotation)
						r.AssemblyLinearVelocity = Vector3.zero
						anchor[player] = { pos = back, at = clock }
					else
						anchor[player] = { pos = r.Position, at = clock }
					end
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
			-- a respawn (reset, death, falling off the map) while carrying or dropped: the boss is gone
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
		send(player, "none", nil)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(watch, p)
	end
	Players.PlayerRemoving:Connect(function(player)
		if carries[player] then
			logEvent({ kind = "lost", why = "left", userId = player.UserId })
		end
		carries[player] = nil
		anchor[player] = nil
	end)

	-- A wipe clears the carry (the session's carry key becomes nil from outside this module).
	Session.onChanged(function(player, key, value)
		if key == "carry" and value == nil and carries[player] then
			carries[player] = nil
			anchor[player] = nil
			applySpeed(player)
			send(player, "none", nil)
		end
	end)

	-- GrantBoss (state hook, Studio only): that boss on every player's head as if beaten. A running carry or
	-- drop is replaced (a test asks for a fresh carry).
	TestHooks.onSet("GrantBoss", function(v)
		if typeof(v) ~= "string" or Config.Zones.POWER[v] == nil then
			warn("[HFB] hook GrantBoss ignored: " .. tostring(v))
			return
		end
		for _, p in ipairs(Players:GetPlayers()) do
			if carries[p] then
				Carry.lose(p, "granted")
			end
			Carry.begin(p, v)
		end
	end)

	RunService.Heartbeat:Connect(step)
end

return Carry
