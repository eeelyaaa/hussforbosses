--!strict
-- Systems/Zones: the 24 boss pads (6 zones x 1 fixed + 3 rolling), each pad's creature and Power, the rolls and their
-- timers, per-player "beaten" (the fixed Common back 10 s after a win; a roll beaten once per roll), the patrol (the
-- manager's P5), the saved zones-beaten list on a fight win, and the server clock the hazards and pads run on
-- (brief systems 4, 5, 14; m2-contract.md sections C "Zones", D, E).
--
-- The server decides (brief 5): every roll, pad timers, which player has beaten which roll. Nothing here is saved
-- except zonesBeaten (Session.addZoneBeaten, on a fight win only: never on a steal or a purchase).
-- Patrol: Shared/Patrol, a pure function of Zones.now(); the server never moves a boss per frame. Fight.Start's ring
-- test uses Zones.bossPosition(padId, Zones.now()) (Systems/Fight.bossCentre, with Config.Zones.PATROL.slack). A
-- fight freezes the boss for the fighter's client at Fight.State.bossPos; everyone else still sees it walk.
--
-- Remotes sent: Zones.Pads (per player: rolls are shared, "beaten" is that player's; on join, on spawn, on every roll,
-- after a win, when a pad appears or goes), Zones.PadBeaten (owner, after a win), Zones.Clock (every player, on join,
-- every Config.Zones.CLOCK_EVERY_S and when the ClockOffset hook changes).
-- Hooks honoured: ForceRoll ('<padId>=<creatureId>', state), PadsFast (seconds, config), SetZonesBeaten ('1,2', state),
-- PadFastBack (M1), ClockOffset (M1).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Ids = require(Shared.Ids)
local TestHooks = require(Shared.TestHooks)
local Patrol = require(Shared.Patrol)
local Session = require(script.Parent.Parent.Data.Session)

export type Pad = {
	padId: string,
	model: Model,
	ring: BasePart,
	radius: number,
	creatureId: string,
	power: number,
	kind: string,
	zone: number,
	anchor: CFrame?,
}

type Roll = { creatureId: string, rollId: number, endsAt: number }

local Zones = {}

-- What checks read.
Zones.stats = { rolls = 0, sends = 0, beatenWrites = {} :: { any } }

local pads: { [string]: Pad } = {}
-- rolls[padId] for every rolling pad in Config.Zones.PADS (the world may not have it yet)
local rolls: { [string]: Roll } = {}
-- availableAt[player][padId] = Zones.now() at which that pad opens again for that player (loss cooldown, fixed win)
local availableAt: { [Player]: { [string]: number } } = {}
-- fixedBeatenUntil[player][padId]: the fixed pad's "beaten" for the payload (until it is back)
local fixedBeatenUntil: { [Player]: { [string]: number } } = {}
-- beatenRoll[player][padId] = the rollId that player beat
local beatenRoll: { [Player]: { [string]: number } } = {}
-- the roll each player's running fight started on (a win marks that roll, even if the pad rolled during the fight)
local fightRoll: { [Player]: { padId: string, rollId: number } } = {}
local rng = Random.new()

-- The server's hazard and pad clock: server time plus the ClockOffset hook (Studio only).
function Zones.now(): number
	local off = TestHooks.get("ClockOffset")
	return workspace:GetServerTimeNow() + (if Net.isNumber(off) then off else 0)
end

function Zones.pad(padId: string): Pad?
	return pads[padId]
end

function Zones.roll(padId: string): Roll?
	return rolls[padId]
end

local function period(): number
	local fast = TestHooks.get("PadsFast")
	return if Net.isNumber(fast, 0.5, 3600) then fast else Config.Zones.ROLL_S
end

-- ---------------------------------------------------------------- rolls
-- A creature of the zone by the zone's odds (brief system 5). r in [0, 1) (a check passes its own stream).
function Zones.pickTier(zone: number, r: number): number
	local odds = Config.Zones.ROLL_ODDS[zone]
	local total = 0
	for _, w in ipairs(odds) do
		total += w
	end
	local x = r * total
	local acc = 0
	for tier, w in ipairs(odds) do
		acc += w
		if x < acc then
			return tier
		end
	end
	return #odds
end

local function applyCreature(padId: string, creatureId: string)
	local pad = pads[padId]
	if pad then
		pad.creatureId = creatureId
		pad.power = Config.Zones.POWER[creatureId]
	end
end

local function setRoll(padId: string, creatureId: string, endsAt: number)
	local prev = rolls[padId]
	rolls[padId] = { creatureId = creatureId, rollId = (if prev then prev.rollId else 0) + 1, endsAt = endsAt }
	Zones.stats.rolls += 1
	applyCreature(padId, creatureId)
end

local function rollNow(padId: string, endsAt: number)
	local def = Config.Zones.PADS[padId]
	setRoll(padId, Ids.creature(def.zone, Zones.pickTier(def.zone, rng:NextNumber())), endsAt)
end

-- ---------------------------------------------------------------- patrol
local function patrolParams(padId: string): Patrol.Params
	local P = Config.Zones.PATROL
	return { phase = Patrol.phase(padId, P), halfLen = P.halfLen, speed = P.speed, pauseS = P.pauseS }
end
Zones.patrolParams = patrolParams

-- Where the pad's boss stands at serverTime (contract E), or nil for an unknown pad.
function Zones.bossPosition(padId: string, serverTime: number): Vector3?
	local pad = pads[padId]
	if not pad or not pad.anchor then
		return nil
	end
	local pos = Patrol.position(pad.anchor :: CFrame, patrolParams(padId), serverTime)
	return pos
end

-- ---------------------------------------------------------------- per player
local function byPlayer<T>(map: { [Player]: { [string]: T } }, player: Player): { [string]: T }
	local m = map[player]
	if not m then
		m = {}
		map[player] = m
	end
	return m
end

-- Has this player beaten the pad's current boss (the fixed pad: until it is back; a roll: this roll)?
function Zones.isBeaten(player: Player, padId: string): boolean
	local pad = pads[padId]
	if not pad then
		return false
	end
	if pad.kind == "roll" then
		local r = rolls[padId]
		local b = beatenRoll[player] and beatenRoll[player][padId]
		return r ~= nil and b == r.rollId
	end
	local u = fixedBeatenUntil[player] and fixedBeatenUntil[player][padId]
	return u ~= nil and Zones.now() < u
end

-- Is the pad open to this player now? (false, secondsLeft) while beaten (this roll / the fixed 10 s) or on the loss
-- cooldown.
function Zones.isOpen(player: Player, padId: string): (boolean, number)
	local left = 0
	local t = availableAt[player] and availableAt[player][padId]
	if t then
		left = math.max(left, t - Zones.now())
	end
	local pad = pads[padId]
	if pad and pad.kind == "roll" and Zones.isBeaten(player, padId) then
		local r = rolls[padId] :: Roll
		left = math.max(left, r.endsAt - Zones.now(), 1e-3)
	end
	if left > 0 then
		return false, left
	end
	return true, 0
end

-- Closes the pad to this player for `seconds` (the loss cooldown).
function Zones.closeFor(player: Player, padId: string, seconds: number)
	local m = byPlayer(availableAt, player)
	m[padId] = math.max(m[padId] or 0, Zones.now() + seconds)
end

-- The Zones.Pads payload for one player (contract C).
function Zones.padsPayload(player: Player?): { any }
	local out = {}
	for id, p in pairs(pads) do
		local r = rolls[id]
		table.insert(out, {
			padId = id,
			zone = p.zone,
			creatureId = p.creatureId,
			power = p.power,
			kind = p.kind,
			rollEndsAt = if p.kind == "roll" and r then r.endsAt else nil,
			beaten = if player then Zones.isBeaten(player, id) else false,
			patrol = patrolParams(id),
		})
	end
	table.sort(out, function(a, b)
		return a.padId < b.padId
	end)
	return out
end

function Zones.sendPads(player: Player)
	if player.Parent ~= Players then
		return
	end
	Zones.stats.sends += 1
	Net.fire("Zones", "Pads", player, Zones.padsPayload(player))
end

local function sendPadsAll()
	for _, p in ipairs(Players:GetPlayers()) do
		Zones.sendPads(p)
	end
end

-- ---------------------------------------------------------------- zones beaten (saved; brief 4 and 14)
local S = Session :: any
local function addZoneBeaten(player: Player, zone: number)
	if type(S.addZoneBeaten) == "function" then
		S.addZoneBeaten(player, zone)
	else
		-- M1 facade (before M2-09): the same list through set
		local p = Session.get(player) :: any
		if not p then
			return
		end
		local list = table.clone(p.zonesBeaten or {})
		if not table.find(list, zone) then
			table.insert(list, zone)
			table.sort(list)
			Session.set(player, "zonesBeaten", list)
		end
	end
	table.insert(Zones.stats.beatenWrites, { userId = player.UserId, zone = zone, at = os.clock() })
end

-- After a fight win (Systems/Fight.finish, the only caller): the fixed pad is back for that player in FIXED_BACK_S
-- (hook PadFastBack); a rolling pad stays beaten for that player until it rolls; the zone joins zonesBeaten.
function Zones.markBeaten(player: Player, padId: string)
	local pad = pads[padId]
	local backIn = 0
	if pad and pad.kind == "roll" then
		local r = rolls[padId]
		local fr = fightRoll[player]
		local rid = if fr and fr.padId == padId then fr.rollId elseif r then r.rollId else 0
		byPlayer(beatenRoll, player)[padId] = rid
		backIn = if r and r.rollId == rid then math.max(0, r.endsAt - Zones.now()) else 0
	else
		local fast = TestHooks.get("PadFastBack")
		backIn = if Net.isNumber(fast, 0, 3600) then fast else Config.Fight.FIXED_BACK_S
		Zones.closeFor(player, padId, backIn)
		byPlayer(fixedBeatenUntil, player)[padId] = Zones.now() + backIn
	end
	fightRoll[player] = nil
	local def = Config.Zones.PADS[padId]
	if def then
		addZoneBeaten(player, def.zone)
	end
	Net.fire("Zones", "PadBeaten", player, { padId = padId, backIn = backIn })
	Zones.sendPads(player)
end

-- ---------------------------------------------------------------- the world's pads
local function register(model: Instance): boolean
	if not model:IsA("Model") then
		return false
	end
	local padId = model:GetAttribute("PadId")
	if typeof(padId) ~= "string" then
		return false
	end
	local def = Config.Zones.PADS[padId]
	if not def then
		warn("[HFB] Zones: pad " .. padId .. " is not in Config.Zones.PADS")
		return false
	end
	local ring = model:FindFirstChild("Ring")
	if not (ring and ring:IsA("BasePart")) then
		warn("[HFB] Zones: pad " .. padId .. " has no Ring part")
		return false
	end
	local radius = ring:GetAttribute("RingRadius")
	local creatureId = if def.kind == "roll" then (rolls[padId] :: Roll).creatureId else def.creatureId :: string
	local power = Config.Zones.POWER[creatureId]
	assert(typeof(power) == "number", "Zones: no Power for " .. creatureId)
	pads[padId] = {
		padId = padId,
		model = model,
		ring = ring,
		radius = if typeof(radius) == "number" then radius else ring.Size.X / 2,
		creatureId = creatureId,
		power = power,
		kind = def.kind,
		zone = def.zone,
		anchor = Patrol.anchor(model, Config.Zones.LANE),
	}
	return true
end

local function unregister(model: Instance)
	local padId = model:GetAttribute("PadId")
	if typeof(padId) == "string" and pads[padId] and pads[padId].model == model then
		pads[padId] = nil
		sendPadsAll()
	end
end

local function sendClockAll()
	Net.get("Zones", "Clock"):FireAllClients({ serverTime = Zones.now() })
end

-- ---------------------------------------------------------------- hooks
local function onForceRoll(v: any)
	if typeof(v) ~= "string" then
		return
	end
	local padId, creatureId = string.match(v, "^([%w_]+)=([%w_]+)$")
	local def = padId and Config.Zones.PADS[padId]
	local zone = Ids.parseCreature(creatureId)
	if not def or def.kind ~= "roll" or zone ~= def.zone then
		warn("[HFB] hook ForceRoll ignored: " .. v)
		return
	end
	setRoll(padId :: string, creatureId :: string, Zones.now() + period())
	sendPadsAll()
end

local function onSetZonesBeaten(v: any)
	if typeof(v) ~= "string" then
		return
	end
	local list = {}
	for n in string.gmatch(v, "%d+") do
		local z = tonumber(n) :: number
		if z >= 1 and z <= 6 and not table.find(list, z) then
			table.insert(list, z)
		end
	end
	table.sort(list)
	for _, player in ipairs(Players:GetPlayers()) do
		local p = Session.get(player) :: any
		if p then
			if type(S.setZonesBeatenForTest) == "function" then
				S.setZonesBeatenForTest(player, list) -- M2-09's Studio-only writer, if it gives one
			elseif type(S.addZoneBeaten) == "function" then
				-- the protected API can only add: a hook that removes zones needs Data/Session's test path
				for _, z in ipairs(list) do
					S.addZoneBeaten(player, z)
				end
				if #(p.zonesBeaten or {}) ~= #list then
					warn("[HFB] hook SetZonesBeaten: Data/Session can only add zones; list is " .. table.concat(p.zonesBeaten or {}, ","))
				end
			else
				Session.set(player, "zonesBeaten", list)
			end
		end
	end
end

function Zones.start()
	-- the rolls exist from the first second, for every rolling pad in the config (world or not)
	local now = Zones.now()
	local per = period()
	for padId, def in pairs(Config.Zones.PADS) do
		if def.kind == "roll" then
			local first = if Config.Zones.ROLL_STAGGER then per * def.slot / 3 else per
			rollNow(padId, now + first)
		end
	end

	for _, m in ipairs(CollectionService:GetTagged("HFB_BossPad")) do
		register(m)
	end
	CollectionService:GetInstanceAddedSignal("HFB_BossPad"):Connect(function(m)
		-- a pad cloned in carries its children a frame later
		task.defer(function()
			if register(m) then
				sendPadsAll()
			end
		end)
	end)
	CollectionService:GetInstanceRemovedSignal("HFB_BossPad"):Connect(unregister)
	local missing = {}
	for id in pairs(Config.Zones.PADS) do
		if not pads[id] then
			table.insert(missing, id)
		end
	end
	if #missing > 0 then
		table.sort(missing)
		-- not an [HFB] warning: the plain six-zone strip is the builder's (M2-10 report); the rolls run without it
		print(("Zones: %d of %d pads not in the world yet: %s"):format(#missing, #missing + #(Zones.padsPayload()), table.concat(missing, ",")))
	end

	-- the roll clock (one comparison per rolling pad, 10 times a second)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		local t = Zones.now()
		local changed = false
		for padId, r in pairs(rolls) do
			if t >= r.endsAt then
				rollNow(padId, t + period())
				changed = true
			end
		end
		if changed then
			sendPadsAll()
		end
	end)

	-- the fight's roll, so a win during a re-roll marks the roll that was fought (lazy require: Fight requires Zones)
	local Fight = require(script.Parent.Fight) :: any
	Fight.onStart(function(player: Player, f: any)
		local r = rolls[f.padId]
		fightRoll[player] = if r then { padId = f.padId, rollId = r.rollId } else nil
	end)
	Fight.onEnd(function(player: Player, f: any, state: string)
		if state ~= "win" then
			local fr = fightRoll[player]
			if fr and fr.padId == f.padId then
				fightRoll[player] = nil
			end
		end
	end)

	local function onJoin(p: Player)
		Zones.sendPads(p)
		Net.get("Zones", "Clock"):FireClient(p, { serverTime = Zones.now() })
	end
	local function watchSpawn(p: Player)
		p.CharacterAdded:Connect(function()
			task.wait(1) -- the client's Pads controller subscribes after the character loads (resend; M2-13 note)
			Zones.sendPads(p)
		end)
	end
	Players.PlayerAdded:Connect(function(p)
		onJoin(p)
		watchSpawn(p)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(onJoin, p)
		watchSpawn(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		availableAt[p] = nil
		fixedBeatenUntil[p] = nil
		beatenRoll[p] = nil
		fightRoll[p] = nil
	end)

	TestHooks.onSet("ForceRoll", onForceRoll)
	TestHooks.onSet("SetZonesBeaten", onSetZonesBeaten)
	workspace:GetAttributeChangedSignal(TestHooks.PREFIX .. "ClockOffset"):Connect(sendClockAll)
	task.spawn(function()
		while true do
			task.wait(Config.Zones.CLOCK_EVERY_S)
			sendClockAll()
		end
	end)
end

return Zones
