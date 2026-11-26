--!strict
-- Systems/Fight: boss fights (brief system 4; m1-contract.md sections C, D, E).
-- r and the band at start, boss health (10 x boss Power), 3 hearts, damage per beat (from Systems/Punch's beat
-- queue), win on the beat that empties the bar (B22), loss on the last heart (2 s knockdown, that pad closed to the
-- player for 5 s), Run, and the player held in place for the fight (B13, server half).
--
-- c2s: Fight.Start { padId }, Fight.Run {}. s2c: Fight.State, Fight.Beat, Fight.Heart (owner only).
-- Fight.Watch (nearby) is reserved for M2 and never sent here.
-- Other systems: Fight.onStart(fn(player, fight)), Fight.onEnd(fn(player, fight, state)) (M1-11's Carry
-- listens for state == "win" to put the boss on the player's head).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Session = require(script.Parent.Parent.Data.Session)
local Zones = require(script.Parent.Zones)
local Bag = require(script.Parent.Bag)
local Funnel = require(script.Parent.Funnel)

export type FightT = {
	fightId: number,
	padId: string,
	creatureId: string,
	bossPower: number,
	playerPower: number,
	ratio: number,
	band: string,
	goodMs: number,
	perfectMs: number,
	health: number,
	maxHealth: number,
	hearts: number,
	startedAt: number,
	over: boolean,
	spot: Vector3?, -- where the server stood the player for the fight (M1-26b), sent in Fight.State started
	bossPos: Vector3?, -- where the boss stood (froze) for this fight (contract E), sent in Fight.State started
}

local Fight = {}

local fights: { [Player]: FightT } = {}
local knockUntil: { [Player]: number } = {}
local frozen: { [Player]: { hum: Humanoid, walk: number, jumpPower: number, jumpHeight: number } } = {}
local nextId = 0

-- Largest ratio sent over the wire (a player with 0 Power against a boss: r is infinite, band impossible).
local RATIO_CAP = 1e6

local startFns: { (Player, FightT) -> () } = {}
local endFns: { (Player, FightT, string) -> () } = {}
function Fight.onStart(fn: (Player, FightT) -> ())
	table.insert(startFns, fn)
end
function Fight.onEnd(fn: (Player, FightT, string) -> ())
	table.insert(endFns, fn)
end

-- Checks read these (module-level state, never the client's).
Fight.stats = { refused = {} :: { [string]: number }, log = {} :: { any } }
local function logEvent(e: any)
	table.insert(Fight.stats.log, e)
	if #Fight.stats.log > 300 then
		table.remove(Fight.stats.log, 1)
	end
end

function Fight.get(player: Player): FightT?
	local f = fights[player]
	return if f and not f.over then f else nil
end

function Fight.knockedDown(player: Player): boolean
	local t = knockUntil[player]
	return t ~= nil and workspace:GetServerTimeNow() < t
end

local function statePayload(f: FightT, state: string, reason: string?): any
	return {
		fightId = f.fightId,
		state = state,
		reason = reason,
		padId = f.padId,
		creatureId = f.creatureId,
		bossPower = f.bossPower,
		playerPower = f.playerPower,
		ratio = f.ratio,
		band = f.band,
		goodMs = f.goodMs,
		perfectMs = f.perfectMs,
		health = f.health,
		maxHealth = f.maxHealth,
		hearts = f.hearts,
		spot = if state == "started" then f.spot else nil,
		bossPos = if state == "started" then f.bossPos else nil,
	}
end

-- r = boss Power / player Power and its band (Config.Fight.band).
function Fight.rate(bossPower: number, playerPower: number): (number, any)
	local ratio = if playerPower > 0 then bossPower / playerPower else math.huge
	return math.min(ratio, RATIO_CAP), Config.Fight.band(ratio)
end

local function freeze(player: Player)
	local c = player.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not hum or frozen[player] then
		return
	end
	frozen[player] = { hum = hum, walk = hum.WalkSpeed, jumpPower = hum.JumpPower, jumpHeight = hum.JumpHeight }
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.JumpHeight = 0
end

local function unfreeze(player: Player)
	local f = frozen[player]
	frozen[player] = nil
	if f and f.hum.Parent then
		f.hum.WalkSpeed = f.walk
		f.hum.JumpPower = f.jumpPower
		f.hum.JumpHeight = f.jumpHeight
	end
end

local function refuse(player: Player, padId: string, reason: string)
	Fight.stats.refused[reason] = (Fight.stats.refused[reason] or 0) + 1
	local pad = Zones.pad(padId)
	local p = Session.get(player)
	local playerPower = if p then p.power else 0
	local bossPower = if pad then pad.power else 0
	local ratio, band = Fight.rate(bossPower, playerPower)
	Net.get("Fight", "State"):FireClient(player, {
		fightId = 0,
		state = "refused",
		reason = reason,
		padId = padId,
		creatureId = if pad then pad.creatureId else "",
		bossPower = bossPower,
		playerPower = playerPower,
		ratio = ratio,
		band = band.id,
		goodMs = band.goodMs,
		perfectMs = band.perfectMs,
		health = 0,
		maxHealth = 0,
		hearts = 0,
	})
end

local function finish(player: Player, f: FightT, state: string, reason: string?)
	if f.over then
		return
	end
	f.over = true
	if fights[player] == f then
		fights[player] = nil
	end
	logEvent({ kind = state, fightId = f.fightId, health = f.health, hearts = f.hearts, at = workspace:GetServerTimeNow() })
	if player.Parent == Players then
		Net.get("Fight", "State"):FireClient(player, statePayload(f, state, reason))
	end
	if state == "win" then
		unfreeze(player)
		Zones.markBeaten(player, f.padId)
		Funnel.mark(player, "FirstBossBeaten")
	elseif state == "loss" and (reason == "died" or reason == "left") then
		unfreeze(player)
		Zones.closeFor(player, f.padId, Config.Fight.PAD_COOLDOWN_S)
	elseif state == "loss" then
		-- Knocked back out of the ring and down for KNOCKDOWN_S; that pad closed to the player for PAD_COOLDOWN_S.
		knockUntil[player] = workspace:GetServerTimeNow() + Config.Fight.KNOCKDOWN_S
		Zones.closeFor(player, f.padId, Config.Fight.PAD_COOLDOWN_S)
		local pad = Zones.pad(f.padId)
		local r = Bag.root(player)
		if pad and r then
			local d = r.Position - pad.ring.Position
			local dir = Vector3.new(d.X, 0, d.Z)
			dir = if dir.Magnitude > 0.1 then dir.Unit else Vector3.new(0, 0, -1)
			local out = pad.ring.Position + dir * (pad.radius + Config.Fight.RING_SLACK + 2)
			local c = player.Character :: Model
			c:PivotTo(CFrame.lookAt(Vector3.new(out.X, r.Position.Y, out.Z), Vector3.new(pad.ring.Position.X, r.Position.Y, pad.ring.Position.Z)))
		end
		task.delay(Config.Fight.KNOCKDOWN_S, function()
			if not fights[player] then
				unfreeze(player)
			end
		end)
	else
		-- run (and a death or leave): no knockdown; the pad cooldown of a loss applies (TEAM CALL M1-06d).
		unfreeze(player)
		if state == "run" then
			Zones.closeFor(player, f.padId, Config.Fight.PAD_COOLDOWN_S)
		end
	end
	for _, fn in ipairs(endFns) do
		task.spawn(fn, player, f, state)
	end
end
Fight.finish = finish

-- One punch of a burst at its beat (called by Systems/Punch's beat queue), or the single punch of an untimed tap
-- (grade 'untimed', n = 1: Power x GRADE_VALUE.untimed, Fight.Beat size 'single'). Returns true when it made contact.
-- B22: health is checked first; the beat that empties the bar wins and the caller stops the burst.
function Fight.applyBeat(player: Player, fightId: number, burstSeq: number, grade: string, n: number): (boolean, boolean)
	local f = fights[player]
	if not f or f.over or f.fightId ~= fightId or f.health <= 0 then
		return false, false
	end
	local gv = Config.Punch.GRADE_VALUE[grade] or 0
	local damage = f.playerPower * gv * (if n == 3 then Config.Punch.BIG_MULT else 1)
	f.health = math.max(0, f.health - damage)
	local won = f.health <= 0
	logEvent({ kind = "beat", fightId = f.fightId, burstSeq = burstSeq, n = n, damage = damage, health = f.health, won = won, at = workspace:GetServerTimeNow() })
	Net.get("Fight", "Beat"):FireClient(player, {
		fightId = f.fightId,
		burstSeq = burstSeq,
		n = n,
		size = if grade == "untimed" then "single" else grade,
		big = n == 3,
		damage = damage,
		health = f.health,
		won = won,
	})
	if won then
		finish(player, f, "win")
	end
	return true, won
end

-- A Miss in the fight (reported, or counted by the stall rule): one heart; the last heart is the loss.
function Fight.miss(player: Player, why: string)
	local f = fights[player]
	if not f or f.over then
		return
	end
	f.hearts = math.max(0, f.hearts - 1)
	local last = f.hearts == 0
	logEvent({ kind = "heart", why = why, fightId = f.fightId, hearts = f.hearts, at = workspace:GetServerTimeNow() })
	Net.get("Fight", "Heart"):FireClient(player, { fightId = f.fightId, hearts = f.hearts, last = last })
	if last then
		finish(player, f, "loss")
	end
end

-- Where the boss of a pad stands now and the extra slack for a moving boss (contract E). Zones.bossPosition is
-- M2-10's; until it exists (or when it answers nil) the pad's ring centre, no extra slack.
function Fight.bossCentre(padId: string, pad: Zones.Pad): (Vector3, number)
	local fn = (Zones :: any).bossPosition
	if type(fn) == "function" then
		local ok, pos = pcall(fn, padId, Zones.now())
		if ok and typeof(pos) == "Vector3" then
			local patrol = (Config :: any).Zones and (Config :: any).Zones.PATROL
			local slack = if type(patrol) == "table" and type(patrol.slack) == "number" then patrol.slack else 0
			return Vector3.new(pos.X, pad.ring.Position.Y, pos.Z), slack
		end
	end
	return pad.ring.Position, 0
end

-- Fight.Start's checks, in order; returns nil when the fight may start, else the refusal reason.
-- Reasons (TEAM CALL M1-06c): bad, pad, dead, running, knocked, carrying, closed, ring.
function Fight.canStart(player: Player, padId: any): string?
	if not Net.isShortString(padId, 40) then
		return "bad"
	end
	local pad = Zones.pad(padId)
	if not pad then
		return "pad"
	end
	local r = Bag.root(player)
	local p = Session.get(player)
	if not r or not p then
		return "dead"
	end
	if fights[player] then
		return "running"
	end
	if Fight.knockedDown(player) then
		return "knocked"
	end
	if p.carry ~= nil then
		return "carrying"
	end
	if not Zones.isOpen(player, padId) then
		return "closed"
	end
	-- "In the ring" is against where the boss is now (contract C/E: Zones.bossPosition once M2-10's patrol lands,
	-- with PATROL.slack more), else the pad's ring.
	local centre, slack = Fight.bossCentre(padId, pad)
	local d = r.Position - centre
	if Vector3.new(d.X, 0, d.Z).Magnitude > pad.radius + Config.Fight.RING_SLACK + slack or math.abs(d.Y) > 10 then
		return "ring"
	end
	return nil
end

-- The fight spot (TEAM CALL M1-26b, Config.Fight.SPOT). The boss model of a pad (child "Boss" or the HFB_Boss model).
local function bossOf(pad: Zones.Pad): Model?
	local b = pad.model:FindFirstChild("Boss")
	if b and b:IsA("Model") then
		return b
	end
	for _, d in ipairs(pad.model:GetDescendants()) do
		if d:IsA("Model") and CollectionService:HasTag(d, "HFB_Boss") then
			return d
		end
	end
	return nil
end

local function flatUnit(v: Vector3): Vector3?
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 0.01 then f.Unit else nil
end

-- Half the oriented box's extent along a unit direction (its support distance).
local function halfAlong(cf: CFrame, size: Vector3, dir: Vector3): number
	return math.abs(cf.RightVector:Dot(dir)) * size.X / 2
		+ math.abs(cf.UpVector:Dot(dir)) * size.Y / 2
		+ math.abs(cf.LookVector:Dot(dir)) * size.Z / 2
end

-- Where the player stands for this fight: on the line from the boss's centre toward `fromPos`, at the box's
-- half-extent + GAP_H x H, on the pad (RingRadius - EDGE_MARGIN) and short of walls; facing the boss. If the ring
-- leaves less than MIN_GAP on that side, the line turns (15 degree steps, either way) to the nearest side that has
-- room. Pure apart from one raycast per tried line; returns nil when there is no boss.
-- bossAt (M2-06 follow-up to M2-10's patrol): where the boss is frozen for this fight (Fight.State.bossPos). The
-- server's boss model stands at rest; its box and the pad's ring are moved by (bossAt - the model's rest pivot), flat,
-- so the spot is built around the walking boss exactly as M1-26b builds it around the resting one.
function Fight.fightSpot(pad: Zones.Pad, fromPos: Vector3, rootHeight: number, ignore: { Instance }, bossAt: Vector3?): CFrame?
	local S = Config.Fight.SPOT
	local boss = bossOf(pad)
	if not boss then
		return nil
	end
	local offset = Fight.patrolOffset(pad, bossAt)
	local bbCf, bbSize = boss:GetBoundingBox()
	bbCf = bbCf + offset
	local h = boss:GetAttribute("H")
	local height = if typeof(h) == "number" and h > 0 then h else bbSize.Y
	local c = bbCf.Position
	local ringC = pad.ring.Position + offset
	local y = ringC.Y + pad.ring.Size.Y / 2 + rootHeight
	local maxR = pad.radius - S.EDGE_MARGIN
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = { boss }
	for _, i in ipairs(ignore) do
		table.insert(exclude, i)
	end
	for _, b in ipairs(CollectionService:GetTagged("HFB_Blocker")) do
		table.insert(exclude, b)
	end
	params.FilterDescendantsInstances = exclude
	local o = Vector3.new(c.X - ringC.X, 0, c.Z - ringC.Z)
	-- distance along dir and the air left between the box and the root
	local function along(dir: Vector3): (number, number)
		local half = halfAlong(bbCf, bbSize, dir)
		local want = half + S.GAP_H * height
		local b = o:Dot(dir)
		local disc = b * b - (o:Dot(o) - maxR * maxR)
		local t = math.min(want, if disc >= 0 then -b + math.sqrt(disc) else 0)
		local from = Vector3.new(c.X, y, c.Z)
		local hit = workspace:Raycast(from, dir * (t + S.AVATAR_RADIUS), params)
		if hit then
			t = math.min(t, hit.Distance - S.AVATAR_RADIUS)
		end
		return t, t - half
	end
	local base = flatUnit(fromPos - c) or flatUnit(boss:GetPivot().LookVector) or Vector3.new(0, 0, 1)
	local dir = base
	local t: number? = nil
	local bestDir, bestT, bestGap = base, 0, -math.huge
	for step = 0, 12 do -- 0, +15, -15, +30, -30 ... +90, -90
		local deg = math.ceil(step / 2) * 15 * (if step % 2 == 1 then 1 else -1)
		local d = CFrame.Angles(0, math.rad(deg), 0) * base
		local tt, gap = along(d)
		if gap > bestGap then
			bestDir, bestT, bestGap = d, tt, gap
		end
		if gap >= S.MIN_GAP then
			dir, t = d, tt
			break
		end
	end
	if not t then
		dir, t = bestDir, bestT
	end
	local pos = Vector3.new(c.X, y, c.Z) + dir * (t :: number)
	return CFrame.lookAt(pos, Vector3.new(c.X, y, c.Z))
end

-- The flat move from the boss model's rest pivot to bossAt (zero without a boss, without bossAt, or for a bad value).
function Fight.patrolOffset(pad: Zones.Pad, bossAt: Vector3?): Vector3
	local boss = bossOf(pad)
	if not boss or typeof(bossAt) ~= "Vector3" or bossAt ~= bossAt then
		return Vector3.zero
	end
	local rest = boss:GetPivot().Position
	local d = Vector3.new(bossAt.X - rest.X, 0, bossAt.Z - rest.Z)
	-- never further than the patrol can walk (halfLen) plus a stud: a wrong bossAt cannot throw the fighter across the map
	local patrol = (Config :: any).Zones and (Config :: any).Zones.PATROL
	local limit = (if type(patrol) == "table" and type(patrol.halfLen) == "number" then patrol.halfLen else 0) + 1
	return if d.Magnitude <= limit then d else Vector3.zero
end

-- The root's height above the floor for this rig (R15: HipHeight + half the root; R6: legs of 2).
local function rootHeightOf(hum: Humanoid, root: BasePart): number
	if hum.RigType == Enum.HumanoidRigType.R15 then
		return hum.HipHeight + root.Size.Y / 2
	end
	return root.Size.Y / 2 + 2
end

-- Moves the character to the fight spot (server side, so every client sees the same). Validated: finite, on the
-- pad, and no further from where the player stood than the ring's diameter plus the start slack.
local function standAtSpot(player: Player, pad: Zones.Pad, bossAt: Vector3?): Vector3?
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = Bag.root(player)
	if not (char and hum and root) then
		return nil
	end
	local cf = Fight.fightSpot(pad, root.Position, rootHeightOf(hum, root), { char }, bossAt)
	if not cf then
		return nil
	end
	local p = cf.Position
	local ringC = pad.ring.Position + Fight.patrolOffset(pad, bossAt)
	local dRing = Vector3.new(p.X - ringC.X, 0, p.Z - ringC.Z).Magnitude
	local moved = (p - root.Position).Magnitude
	if p ~= p or dRing > pad.radius + 1e-3 or moved > 2 * pad.radius + Config.Fight.RING_SLACK + 10 then
		warn(("[HFB] Fight: fight spot refused (ring %.1f, moved %.1f)"):format(dRing, moved))
		return nil
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	char:PivotTo(cf)
	return p
end

function Fight.begin(player: Player, padId: string): FightT?
	local why = Fight.canStart(player, padId)
	if why then
		if why ~= "bad" then
			refuse(player, padId, why)
		else
			Fight.stats.refused.bad = (Fight.stats.refused.bad or 0) + 1
		end
		return nil
	end
	local pad = Zones.pad(padId) :: Zones.Pad
	local p = Session.get(player) :: Session.Profile
	local ratio, band = Fight.rate(pad.power, p.power)
	nextId += 1
	local health = Config.Fight.HEALTH_PER_POWER * pad.power
	local f: FightT = {
		fightId = nextId,
		padId = padId,
		creatureId = pad.creatureId,
		bossPower = pad.power,
		playerPower = p.power,
		ratio = ratio,
		band = band.id,
		goodMs = band.goodMs,
		perfectMs = band.perfectMs,
		health = health,
		maxHealth = health,
		hearts = Config.Fight.HEARTS,
		startedAt = workspace:GetServerTimeNow(),
		over = false,
	}
	fights[player] = f
	freeze(player)
	-- the boss is frozen where it walked to (contract E); the fighter's spot is built around that position
	f.bossPos = (Fight.bossCentre(padId, pad))
	f.spot = standAtSpot(player, pad, f.bossPos)
	Funnel.mark(player, "FirstFightStarted")
	logEvent({ kind = "started", fightId = f.fightId, ratio = ratio, band = band.id, health = health, at = f.startedAt })
	Net.get("Fight", "State"):FireClient(player, statePayload(f, "started"))
	for _, fn in ipairs(startFns) do
		task.spawn(fn, player, f)
	end
	return f
end

function Fight.start()
	Net.onServerEvent("Fight", "Start", function(player, payload)
		Fight.begin(player, payload.padId)
	end)
	Net.onServerEvent("Fight", "Run", function(player, _payload)
		local f = fights[player]
		if f and not f.over then
			finish(player, f, "run")
		end
	end)
	-- A disconnect is a loss (brief system 4); a death ends the fight the same way.
	Players.PlayerRemoving:Connect(function(player)
		local f = fights[player]
		if f then
			finish(player, f, "loss", "left")
		end
		fights[player] = nil
		knockUntil[player] = nil
		frozen[player] = nil
	end)
	local function watchCharacter(player: Player)
		player.CharacterAdded:Connect(function(c)
			frozen[player] = nil
			local f = fights[player]
			if f then
				finish(player, f, "loss", "died")
			end
			local hum = c:WaitForChild("Humanoid", 5) :: Humanoid?
			if hum then
				hum.Died:Connect(function()
					local g = fights[player]
					if g then
						finish(player, g, "loss", "died")
					end
				end)
			end
		end)
	end
	Players.PlayerAdded:Connect(watchCharacter)
	for _, p in ipairs(Players:GetPlayers()) do
		watchCharacter(p)
	end
	-- A wipe or a carry starting mid-fight (test hooks, M1-11) ends the fight without a result.
	Session.onChanged(function(player, key, value)
		local f = fights[player]
		if f and key == "carry" and value ~= nil then
			finish(player, f, "run", "carrying")
		end
	end)
end

return Fight
