--!strict
-- Net: every remote in the game, created in one place, with its payload contract written beside it.
-- M1 entries: team/requirements/m1-contract.md section C (M1-01, tech-lead). Families from the build plan
-- ("Remotes, by family"); B8 in team/decisions.md.
--
-- Conventions:
--   * Instances live at ReplicatedStorage.Remotes.<Family>.<Name>; only the server creates them (Net.serverInit).
--   * Name = what happens, as a verb or noun phrase in PascalCase: Punch.Report, Punch.Result, Fight.Start.
--   * kind = "event" (RemoteEvent), "unreliable" (UnreliableRemoteEvent, for cosmetic broadcasts only) or
--     "function" (RemoteFunction, only for Shop.Open's quotes; never server-to-client).
--   * dir = "c2s", "s2c" or "both". Every payload is ONE table with the key names below.
--   * Every c2s remote is hooked with Net.onServerEvent, which rate-limits per player (Config.Punch.RATE,
--     over the limit = dropped silently and counted in TestHooks.reports._dropped) and drops a payload that is
--     not a plain table. The handler still validates type, range, state and distance of every field
--     (roblox-networking skill); no client value is trusted except the burst report's grade and tap time,
--     which the server bounds (build plan, "Client and server boundaries").
--   * Server time = Workspace:GetServerTimeNow(); client durations use os.clock().
--   * reserved = declared and created, but nothing sends it yet (the milestone that will is named).
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(script.Parent.Config)
local TestHooks = require(script.Parent.TestHooks)

export type Kind = "event" | "unreliable" | "function"
export type Dir = "c2s" | "s2c" | "both"
export type Spec = { kind: Kind, dir: Dir, payload: string, reserved: string? }

local Net = {}

local function ev(dir: Dir, payload: string, reserved: string?): Spec
	return { kind = "event", dir = dir, payload = payload, reserved = reserved }
end
local function unrel(dir: Dir, payload: string, reserved: string?): Spec
	return { kind = "unreliable", dir = dir, payload = payload, reserved = reserved }
end

-- The 13 families (build plan). Bag, Boss, Steal, Shield, Rebirth, Shop, Offline stay empty at M1.
Net.FAMILIES = {
	Punch = {
		-- s2c to owner. On join, on entering the bag pad or a fight, on a Speed change. The client draws every ring from it.
		Schedule = ev("s2c", "{ speedLevel: number, ringClose: number, burstLen: number, cycle: number }"),
		-- c2s. tapServerTime = client GetServerTimeNow() at the tap, absent on a Miss with no tap; sanity-checked
		-- (future <= TAP_TIME_FUTURE_S, age <= TAP_TIME_PAST_S); the server's receipt time schedules the beats.
		-- Refused with "place" when the player is not in that context (bag: own bag pad; fight: a running fight).
		Report = ev("c2s", "{ seq: number, context: 'bag'|'fight', grade: 'perfect'|'good'|'miss', tapServerTime: number? }"),
		-- s2c to owner. gains = value of each of the three punches; t0 = server time the burst was accepted.
		-- accepted=false: client fades F over 30 ms and cancels. reason: 'rate'|'place'|'state'|'grade'|'busy'.
		Result = ev("s2c", "{ seq: number, accepted: boolean, reason: string?, context: string, grade: string, gains: {number}?, t0: number? }"),
		-- s2c, nearby players except the owner.
		Burst = unrel("s2c", "{ userId: number, context: string, grade: string, t0: number }", "M2 (watching clients; TEAM CALL M1-P2)"),
	},
	Fight = {
		-- c2s. Inside that pad's Ring (RingRadius + Config.Fight.RING_SLACK), not carrying, not knocked down,
		-- not on that pad's PAD_COOLDOWN_S, no fight running.
		Start = ev("c2s", "{ padId: string }"),
		-- c2s. Ends the running fight as a loss with no knockdown ('run').
		Run = ev("c2s", "{}"),
		-- s2c to owner, at start, win, loss, run (and refused). band: 'easy'|'fair'|'hard'|'veryHard'|'brutal'|'impossible'.
		State = ev("s2c", "{ fightId: number, state: 'started'|'win'|'loss'|'run'|'refused', reason: string?, padId: string, creatureId: string, bossPower: number, playerPower: number, ratio: number, band: string, goodMs: number, perfectMs: number, health: number, maxHealth: number, hearts: number, spot: Vector3? (started: where the server stood the player, M1-26b) }"),
		-- s2c to owner, one per applied punch at its beat. won=true on the punch that empties the bar (B22); later punches send nothing.
		Beat = ev("s2c", "{ fightId: number, burstSeq: number, n: number, size: 'good'|'perfect', big: boolean, damage: number, health: number, won: boolean }"),
		-- s2c to owner, on a Miss: one heart lost; last=true when it was the last (the loss follows).
		Heart = ev("s2c", "{ fightId: number, hearts: number, last: boolean }"),
		-- s2c, nearby.
		Watch = unrel("s2c", "{ padId: string, kind: string, size: string? }", "M2 (watching clients; TEAM CALL M1-P2)"),
	},
	Bag = {},
	Base = {
		-- s2c to every player. Client cash on a pad = min(income * (now - stamp), income * capSeconds).
		State = ev("s2c", "{ plotId: number, ownerUserId: number, spots: { [number]: { uid: string, creatureId: string, level: number, income: number, stamp: number, capSeconds: number }? } }"),
		-- c2s. Carrying, the plot and spot are the player's, the spot is empty, within Config.Base.PLACE_RANGE of it.
		Place = ev("c2s", "{ spotIndex: number }"),
		-- s2c to owner. The server collects when the owner's character is within Config.Base.COLLECT_RANGE of the cash pad.
		Collected = ev("s2c", "{ spotIndex: number, amount: number }"),
	},
	Boss = {},
	Carry = {
		-- s2c to owner. graceEnds = server time the dropped boss is gone (Config.Carry.GRAB_S).
		State = ev("s2c", "{ state: 'none'|'carrying'|'dropped'|'placed', uid: string?, creatureId: string?, dropPos: Vector3?, graceEnds: number? }"),
		-- c2s. Only the player who dropped it, within Config.Carry.GRAB_RANGE, before graceEnds.
		Grab = ev("c2s", "{ uid: string }"),
	},
	Steal = {},
	Shield = {},
	Zones = {
		-- s2c to every player, on join and on change. The client colours the Power number from its own Power.
		Pads = ev("s2c", "{ { padId: string, creatureId: string, power: number, kind: 'fixed' } }"),
		-- s2c to owner, after a win: the fixed pad is back for that player in backIn seconds.
		PadBeaten = ev("s2c", "{ padId: string, backIn: number }"),
		-- s2c to every player, on join and every Config.Zones.CLOCK_EVERY_S. The hazard clock re-anchors only here.
		Clock = ev("s2c", "{ serverTime: number }"),
	},
	Rebirth = {},
	Shop = {},
	Offline = {},
	Profile = {
		-- s2c to owner, partial: only the fields that changed. After each applied bag beat: the new power.
		Changed = ev("s2c", "{ power: number?, cash: number?, strengthLevel: number?, speedLevel: number? }"),
		-- c2s, STUDIO ONLY (ignored unless RunService:IsStudio()); json <= 1 KB; stored in TestHooks.reports[name].
		TestReport = ev("c2s", "{ name: string, json: string }"),
	},
} :: { [string]: { [string]: Spec } }

Net.FAMILY_COUNT = 13

local CLASS = { event = "RemoteEvent", unreliable = "UnreliableRemoteEvent", ["function"] = "RemoteFunction" }

-- Server only, once, from Main.server.lua, before any system starts.
function Net.serverInit()
	assert(RunService:IsServer(), "Net.serverInit is server only")
	local root = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	root.Name = "Remotes"
	for family, specs in pairs(Net.FAMILIES) do
		local folder = root:FindFirstChild(family) or Instance.new("Folder")
		folder.Name = family
		for name, spec in pairs(specs) do
			local existing = folder:FindFirstChild(name)
			if existing and existing.ClassName ~= CLASS[spec.kind] then
				existing:Destroy()
				existing = nil
			end
			if not existing then
				local r = Instance.new(CLASS[spec.kind])
				r.Name = name
				r.Parent = folder
			end
		end
		folder.Parent = root
	end
	root.Parent = ReplicatedStorage
end

local function spec(family: string, name: string): Spec
	local specs = Net.FAMILIES[family]
	local s = specs and specs[name]
	assert(s, ("Net: no remote %s.%s in the contract"):format(family, name))
	return s :: Spec
end
Net.spec = spec

-- Either side: the remote instance for Family.Name. Errors on a name that is not in FAMILIES.
function Net.get(family: string, name: string): any
	spec(family, name)
	local root = ReplicatedStorage:WaitForChild("Remotes", 10)
	assert(root, "Net: ReplicatedStorage.Remotes missing (server not started?)")
	local f = (root :: Instance):WaitForChild(family, 10)
	assert(f, ("Net: family %s not created"):format(family))
	local r = (f :: Instance):WaitForChild(name, 10)
	assert(r, ("Net: remote %s.%s not created"):format(family, name))
	return r
end

-- Rate limit: at most `perSec` calls per player per remote in any 1 s window (sliding).
local stamps: { [Player]: { [string]: { number } } } = {}
if RunService:IsServer() then
	Players.PlayerRemoving:Connect(function(p)
		stamps[p] = nil
	end)
end

function Net.rateOk(player: Player, key: string, perSec: number): boolean
	local byKey = stamps[player]
	if not byKey then
		byKey = {}
		stamps[player] = byKey
	end
	local list = byKey[key]
	if not list then
		list = {}
		byKey[key] = list
	end
	local now = os.clock()
	while #list > 0 and now - list[1] >= 1 do
		table.remove(list, 1)
	end
	if #list >= perSec then
		local d = TestHooks.reports._dropped
		d[key] = (d[key] or 0) + 1
		return false
	end
	table.insert(list, now)
	return true
end

-- Server: hook a c2s remote. Rate-limited by Config.Punch.RATE["Family.Name"] (required for every c2s remote);
-- a payload that is not a table is dropped. handler(player, payload) does every other check.
function Net.onServerEvent(family: string, name: string, handler: (Player, any) -> ()): RBXScriptConnection
	assert(RunService:IsServer(), "Net.onServerEvent is server only")
	local s = spec(family, name)
	assert(s.dir ~= "s2c", ("Net: %s.%s is server-to-client"):format(family, name))
	local key = family .. "." .. name
	local perSec = Config.Punch.RATE[key]
	assert(typeof(perSec) == "number", "Net: no rate limit for " .. key .. " in Config.Punch.RATE")
	return Net.get(family, name).OnServerEvent:Connect(function(player: Player, payload: any)
		if not Net.rateOk(player, key, Config.Punch.RATE[key]) then
			return
		end
		if typeof(payload) ~= "table" then
			return
		end
		handler(player, payload)
	end)
end

-- Validation helpers for handlers (NaN and infinity first: they defeat < and >).
function Net.isNumber(x: any, lo: number?, hi: number?): boolean
	if typeof(x) ~= "number" or x ~= x or math.abs(x) == math.huge then
		return false
	end
	if lo and x < lo then
		return false
	end
	if hi and x > hi then
		return false
	end
	return true
end

function Net.isInt(x: any, lo: number?, hi: number?): boolean
	return Net.isNumber(x, lo, hi) and x % 1 == 0
end

function Net.isOneOf(x: any, set: { string }): boolean
	if typeof(x) ~= "string" then
		return false
	end
	return table.find(set, x) ~= nil
end

function Net.isShortString(x: any, maxLen: number): boolean
	return typeof(x) == "string" and #x <= maxLen and utf8.len(x) ~= nil
end

return Net
