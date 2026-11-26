--!strict
-- Net: every remote in the game, created in one place, with its payload contract written beside it.
-- M1 entries: team/requirements/m1-contract.md section C (M1-01, tech-lead). M2 entries: m2-contract.md section C
-- (M2-01, tech-lead). Families from the build plan ("Remotes, by family"); B8 in team/decisions.md.
--
-- Conventions:
--   * Instances live at ReplicatedStorage.Remotes.<Family>.<Name>; only the server creates them (Net.serverInit).
--   * Name = what happens, as a verb or noun phrase in PascalCase: Punch.Report, Punch.Result, Fight.Start.
--   * kind = "event" (RemoteEvent) or "unreliable" (UnreliableRemoteEvent, for cosmetic broadcasts only).
--     "function" (RemoteFunction) stays supported but no entry uses it: Shop.Open replies with Shop.Quotes (M2-01).
--   * dir = "c2s", "s2c" or "both". Every payload is ONE table with the key names below.
--   * Every c2s remote is hooked with Net.onServerEvent, which rate-limits per player (the entry's rate, or
--     Config.Punch.RATE for the M1 entries; Net.rateFor), over the limit = dropped silently and counted in TestHooks.reports._dropped) and drops a payload that is
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
export type Spec = { kind: Kind, dir: Dir, payload: string, reserved: string?, rate: number?, owner: string?, studioOnly: boolean? }

local Net = {}

-- M1 entries: ev(dir, payload, reserved?). Their rate stays in Config.Punch.RATE (M1 checks read it there).
local function ev(dir: Dir, payload: string, reserved: string?): Spec
	return { kind = "event", dir = dir, payload = payload, reserved = reserved }
end
local function unrel(dir: Dir, payload: string, reserved: string?): Spec
	return { kind = "unreliable", dir = dir, payload = payload, reserved = reserved }
end
-- M2 entries (m2-contract.md section C, M2-01): owner = the task that writes the handler or the sender; rate =
-- calls per second per player for a c2s remote (required). Until the owner lands, nothing listens or sends.
local function c2s(payload: string, rate: number, owner: string): Spec
	return { kind = "event", dir = "c2s", payload = payload, rate = rate, owner = owner }
end
local function s2c(payload: string, owner: string): Spec
	return { kind = "event", dir = "s2c", payload = payload, owner = owner }
end
local function s2cUnrel(payload: string, owner: string): Spec
	return { kind = "unreliable", dir = "s2c", payload = payload, owner = owner }
end

-- The 13 families (build plan "Remotes, by family"; m1-contract.md C, m2-contract.md C). Reasons in results are the
-- short strings listed per family; a client shows a toast or a greyed button from the reason, never a server text.
Net.FAMILIES = {
	Punch = {
		-- s2c to owner. On join, on entering the bag pad or a fight, on a Speed change. The client draws every ring from it.
		Schedule = ev("s2c", "{ speedLevel: number, ringClose: number, burstLen: number, cycle: number }"),
		-- c2s. tapServerTime = client GetServerTimeNow() at the tap, absent on a Miss with no tap; sanity-checked
		-- (future <= TAP_TIME_FUTURE_S, age <= TAP_TIME_PAST_S); the server's receipt time schedules the beats.
		-- Refused with "place" when the player is not in that context (bag: own bag pad; fight: a running fight).
		-- M2 (contract B, M2-06): grade 'untimed' = one punch, no burst, at most one per ring (Ids.REPORT_GRADES).
		-- M2 (contract C, M2-10): auto=true only with grade good/perfect, Auto Punch owned and on (perfect: Perfect
		-- Auto Punch owned and on), owner on own bag pad, never in a fight; one auto burst per ring (B20).
		Report = ev("c2s", "{ seq: number, context: 'bag'|'fight', grade: 'perfect'|'good'|'untimed'|'miss', tapServerTime: number?, auto: boolean? }"),
		-- s2c to owner. gains = value of each punch (three for a burst, one for untimed); t0 = server time accepted.
		-- accepted=false: client fades F over 30 ms and cancels.
		-- reason: 'rate'|'place'|'state'|'grade'|'busy'|'untimedBusy'|'pass'.
		Result = ev("s2c", "{ seq: number, accepted: boolean, reason: string?, context: string, grade: string, auto: boolean?, gains: {number}?, t0: number? }"),
		-- s2c, players within 150 studs except the owner, one per accepted burst or untimed punch (M2-06 sends, M2-16 plays).
		Burst = unrel("s2c", "{ userId: number, context: string, grade: string, auto: boolean?, t0: number }", "M2-06 sends, M2-16 plays"),
	},
	Fight = {
		-- c2s. Inside the boss's PATROL position at Zones.now() (RingRadius + RING_SLACK + Config.Zones.PATROL.slack),
		-- not carrying, not knocked down, not on that pad's PAD_COOLDOWN_S, no fight running (contract E).
		Start = ev("c2s", "{ padId: string }"),
		-- c2s. Ends the running fight as a loss with no knockdown ('run').
		Run = ev("c2s", "{}"),
		-- s2c to owner, at start, win, loss, run (and refused). band: 'easy'|'fair'|'hard'|'veryHard'|'brutal'|'impossible'.
		-- M2: bossPos (started) = where the server froze the boss for this fight (the patrol position at start).
		State = ev("s2c", "{ fightId: number, state: 'started'|'win'|'loss'|'run'|'refused', reason: string?, padId: string, creatureId: string, bossPower: number, playerPower: number, ratio: number, band: string, goodMs: number, perfectMs: number, health: number, maxHealth: number, hearts: number, spot: Vector3?, bossPos: Vector3? }"),
		-- s2c to owner, one per applied punch at its beat. won=true on the punch that empties the bar (B22).
		-- M2: size 'single' = an untimed punch (damage = Power x 1, contract B2).
		Beat = ev("s2c", "{ fightId: number, burstSeq: number, n: number, size: 'good'|'perfect'|'single', big: boolean, damage: number, health: number, won: boolean }"),
		-- s2c to owner, on a Miss (a ring with no tap): one heart lost; last=true when it was the last.
		Heart = ev("s2c", "{ fightId: number, hearts: number, last: boolean }"),
		-- s2c, players within 150 studs except the fighter; at most one per 0.3 s per boss. kind: 'hit'|'attack'|'defeat'|'win'.
		Watch = unrel("s2c", "{ padId: string, userId: number, kind: string, size: string? }", "M2-06 sends, M2-16 plays"),
	},
	Bag = {
		-- c2s. Own plot, within Config.Bag.PAD_RANGE (14) of own bag pad, level < cap (30 / 10), cash >= server cost; one mutate.
		BuyStrength = c2s("{}", 5, "M2-10"),
		BuySpeed = c2s("{}", 5, "M2-10"),
		-- c2s. The pass must be owned (Perfect: pass_perfect_auto_punch). Saved nowhere: per session, off on join.
		AutoToggle = c2s("{ on: boolean }", 2, "M2-10"),
		PerfectToggle = c2s("{ on: boolean }", 2, "M2-10"),
		-- s2c to owner, on join and on any change. Costs are the server's; nil at the cap.
		State = s2c("{ tier: number, strengthLevel: number, speedLevel: number, nextStrengthCost: number?, nextSpeedCost: number?, autoOn: boolean, perfectOn: boolean, autoOwned: boolean, perfectOwned: boolean }", "M2-10"),
		-- s2c to owner, after each c2s. action: 'buyStrength'|'buySpeed'|'auto'|'perfect'; reason: 'cash'|'cap'|'place'|'pass'|'state'.
		Result = s2c("{ action: string, ok: boolean, reason: string?, level: number? }", "M2-10"),
	},
	Base = {
		-- s2c to every player, on join and on change of that plot. Cash on a pad = min(padCash + income * (now - stamp),
		-- income * capSeconds). bought = the mark's source or false (the BOUGHT tag). ownerUserId 0 = plot free.
		State = ev("s2c", "{ plotId: number, ownerUserId: number, spotsCap: number, crateCount: number, spots: { [number]: { uid: string, creatureId: string, level: number, income: number, stamp: number, padCash: number, capSeconds: number, bought: 'spin'|'pack'|false }? } }"),
		-- c2s. Carrying, the plot and spot are the player's, the spot is empty and unlocked, within Config.Base.PLACE_RANGE.
		Place = ev("c2s", "{ spotIndex: number }"),
		-- s2c to owner. The server collects when the owner's character is within Config.Base.COLLECT_RANGE of the cash pad.
		Collected = ev("s2c", "{ spotIndex: number, amount: number }"),
		-- c2s. Own plot, boss on that spot, within PLACE_RANGE, not carrying; the pad's cash stays on the pad (brief 8).
		PickUp = c2s("{ spotIndex: number }", 4, "M2-11"),
		-- c2s. Carrying (own boss, or a stolen one already home), spot occupied, own plot, in range: the placed boss is
		-- sold (server value), the carried one takes the spot; one mutate. The client asked its one confirm first.
		Swap = c2s("{ spotIndex: number }", 4, "M2-11"),
		-- c2s. Carrying, inside own plot. Value = Config.Base.SELL_MULT (20) x income/s at its level, server computed.
		Sell = c2s("{}", 2, "M2-11"),
		-- c2s. uid is in the caller's crate, not carrying, inside own plot: the boss goes on the head (Carry.State).
		TakeCrate = c2s("{ uid: string }", 4, "M2-11"),
		-- s2c to owner, on join and on change. bought = source or false.
		Crate = s2c("{ items: { { uid: string, creatureId: string, level: number, bought: 'spin'|'pack'|false } } }", "M2-11"),
		-- s2c to owner, after each c2s. action: 'place'|'pickUp'|'swap'|'sell'|'takeCrate';
		-- reason: 'range'|'state'|'spot'|'full'|'notYours'|'locked'. amount = cash from a sale or a swap.
		Result = s2c("{ action: string, ok: boolean, reason: string?, spotIndex: number?, amount: number? }", "M2-11"),
	},
	Boss = {
		-- c2s. The caller owns uid on one of its spots, within PLACE_RANGE of it, level < 20, cash >= server cost; one mutate.
		Upgrade = c2s("{ uid: string }", 5, "M2-11"),
		-- s2c to owner. reason: 'cash'|'cap'|'range'|'notYours'.
		Result = s2c("{ uid: string, ok: boolean, reason: string?, level: number?, nextCost: number? }", "M2-11"),
	},
	Carry = {
		-- s2c to owner. graceEnds = server time the dropped boss is gone (Config.Carry.GRAB_S).
		-- M2: stolenFrom = the plot a stolen boss came from (until the steal succeeds); speed = the server's carry cap.
		State = ev("s2c", "{ state: 'none'|'carrying'|'dropped'|'placed', uid: string?, creatureId: string?, level: number?, bought: string?, stolenFrom: number?, speed: number?, dropPos: Vector3?, graceEnds: number? }"),
		-- c2s. Only the player who dropped it, within Config.Carry.GRAB_RANGE, before graceEnds.
		Grab = ev("c2s", "{ uid: string }"),
	},
	Steal = {
		-- c2s. Another player's plot, owner in the server, shield not up, boss placed there, not safe-timed (60 s),
		-- caller within Config.Steal.HOLD_RANGE (6), not carrying, not in a fight, not policy-locked (contract H).
		HoldStart = c2s("{ plotId: number, uid: string }", 2, "M2-15"),
		-- c2s. Cancels only the caller's own hold.
		HoldCancel = c2s("{}", 4, "M2-15"),
		-- c2s. Caller owns the carried boss, within Config.Steal.PUNCH_RANGE (8) of that thief, >= 0.8 s since the last.
		OwnerPunch = c2s("{ thiefUserId: number }", 3, "M2-15"),
		-- s2c to owner, when a hold completes (the boss is lifted). bought = the boss has a bought mark.
		Alert = s2c("{ uid: string, creatureId: string, thiefUserId: number, bought: boolean }", "M2-15"),
		-- s2c to thief and owner. holdEndsAt with 'held'. reason with 'cancelled'|'refused':
		-- 'moved'|'punched'|'shield'|'range'|'state'|'safe'|'locked'|'policy'|'left'|'hazard'|'speed'.
		Result = s2c("{ state: 'held'|'cancelled'|'carried'|'stagger'|'dropped'|'returned'|'success'|'refused', reason: string?, uid: string, holdEndsAt: number? }", "M2-15"),
		-- s2c to each non-owner player, on join and on change: the greyed "Can't be stolen" flag for that viewer.
		Flag = s2c("{ uid: string, locked: boolean }", "M2-15"),
		-- s2c, players within 150 studs: an owner's punch at a thief (picture and the single huss). hit: 'drop'|'stagger'.
		Punch = s2cUnrel("{ fromUserId: number, toUserId: number, hit: string }", "M2-15 sends, M2-16 plays"),
	},
	Shield = {
		-- c2s. Caller inside own plot, shield 'ready'. (Stepping on the lock pad is server-side, no remote.)
		Raise = c2s("{}", 2, "M2-15"),
		-- c2s. Within Config.Shield.BREAK_RANGE (15) of that plot's shield, breakable (not joining, not instant, not
		-- broken in the last 5 min), caller holds a charge. One mutate (charge -1) then the break.
		UseCharge = c2s("{ plotId: number }", 1, "M2-15"),
		-- c2s. Same checks without the charge; then the server opens the Shield Breaker product prompt (Shop guard,
		-- contract C.Shop) and remembers the target for the receipt (M2-18 grants; late = one stored charge).
		BuyBreaker = c2s("{ plotId: number }", 1, "M2-15"),
		-- s2c to every player, on join and on change. reason when not breakable: 'joining'|'instant'|'recent'|'down'.
		-- ownerUserId = the UserId of the player whose shield this is (the plot's owner while a shield is up or cooling), 0 when no shield is running.
		State = s2c("{ plotId: number, state: 'up'|'cooldown'|'ready'|'joining'|'instant', endsAt: number?, readyAt: number?, breakable: boolean, reason: string?, brokenUntil: number?, ownerUserId: number }", "M2-15"),
		-- s2c to owner: "[name] broke your shield!".
		Broken = s2c("{ plotId: number, byUserId: number }", "M2-15"),
		-- s2c to caller. action: 'raise'|'useCharge'|'buyBreaker'; reason: 'state'|'range'|'joining'|'instant'|'recent'|'charge'|'busy'.
		Result = s2c("{ action: string, ok: boolean, reason: string?, plotId: number? }", "M2-15"),
	},
	Zones = {
		-- s2c to each player (per player: rolls and beaten differ), on join and on change. patrol: contract E.
		Pads = ev("s2c", "{ { padId: string, zone: number, creatureId: string, power: number, kind: 'fixed'|'roll', rollEndsAt: number?, beaten: boolean, patrol: { phase: number, halfLen: number, speed: number, pauseS: number } } }"),
		-- s2c to owner, after a win: the pad is back for that player in backIn seconds.
		PadBeaten = ev("s2c", "{ padId: string, backIn: number }"),
		-- s2c to every player, on join and every Config.Zones.CLOCK_EVERY_S. Hazards and patrol re-anchor only here.
		Clock = ev("s2c", "{ serverTime: number }"),
	},
	Rebirth = {
		-- c2s. confirmed must be exactly true (the second press). Power >= requirement, rebirths < 10, not carrying,
		-- no hold or steal on the player's bosses, no fight; at most one per Config.Rebirth.COOLDOWN_S (5); one save op.
		Request = c2s("{ confirmed: true }", 1, "M2-14"),
		-- s2c to owner. reason: 'power'|'max'|'state'|'cooldown'|'save'.
		Result = s2c("{ ok: boolean, reason: string?, rebirths: number?, placed: number?, crated: number? }", "M2-14"),
	},
	Shop = {
		-- c2s. The server replies with Shop.Quotes (fresh cash pack amounts) and Shop.State.
		Open = c2s("{}", 2, "M2-18"),
		-- s2c to owner. Cash pack amounts from the player's income now, each with a key valid Config.Shop.QUOTE_S (300).
		Quotes = s2c("{ packs: { [string]: { amount: number, quoteKey: string, expiresAt: number } } }", "M2-18"),
		-- c2s. key from Ids.PASSES / Ids.PRODUCTS. quoteKey required for a cash pack and must be the live quote (else
		-- 'stale' + new Quotes). Refused: not listed, pass owned, spin while restricted, Perfect Auto Punch without
		-- Auto Punch, Shield Breaker (use Shield.BuyBreaker), Instant Shield while a shield is up, a prompt already
		-- open, or the player in a fight, carrying, or with a steal or shield-broken alert on. The server prompts.
		Buy = c2s("{ key: string, quoteKey: string? }", 1, "M2-18"),
		-- c2s. zone 1..6 on the saved zonesBeaten list, spinTickets >= 1, not restricted; ticket and boss one mutate.
		Spin = c2s("{ zone: number }", 1, "M2-18"),
		-- c2s. The Starter Pack offer was drawn on screen (funnel StarterPackShown). Accepted once per session, only
		-- after the server sent Shop.Offer.
		OfferSeen = c2s("{ key: string }", 1, "M2-18"),
		-- s2c to owner, on join and on change. passes: owned keys only.
		State = s2c("{ passes: { [string]: boolean }, policy: { randomItemsRestricted: boolean, tradingAllowed: boolean }, starterPackGiven: boolean, promptOpen: boolean }", "M2-18"),
		-- s2c to owner, after a prompt closes or a receipt is granted. reason: 'cancelled'|'stale'|'busy'|'owned'|
		-- 'restricted'|'needAuto'|'state'|'shieldUp'|'unknown'. charge=true: a late Shield Breaker stored as a charge.
		Grant = s2c("{ key: string, ok: boolean, reason: string?, amount: number?, uid: string?, creatureId: string?, charge: boolean? }", "M2-18"),
		-- s2c to owner. reason: 'zone'|'tickets'|'restricted'.
		SpinResult = s2c("{ ok: boolean, reason: string?, zone: number, creatureId: string?, tier: number?, uid: string? }", "M2-18"),
		-- s2c to owner. The Starter Pack offer, once per session after the first upgrade, until bought; the client
		-- shows it after the boss panel closes.
		Offer = s2c("{ key: string }", "M2-18"),
	},
	Offline = {
		-- s2c to owner, once on join when away >= 60 s and earned > 0. perBoss: { [uid] = amount }.
		Summary = s2c("{ seconds: number, total: number, perBoss: { [string]: number } }", "M2-14"),
		-- c2s. Only while a summary is pending; a second collect is refused.
		Collect = c2s("{}", 1, "M2-14"),
		-- s2c to owner. reason: 'none'.
		Result = s2c("{ ok: boolean, reason: string?, amount: number? }", "M2-14"),
	},
	Profile = {
		-- s2c to owner, partial: only the fields that changed (all of them once on join). After each applied bag beat:
		-- the new power. saving=false: the profile failed to load and is a temp profile (Profile.Notice notSaving).
		Changed = ev("s2c", "{ power: number?, cash: number?, boughtCash: number?, strengthLevel: number?, speedLevel: number?, rebirths: number?, spinTickets: number?, breakerCharges: number?, zonesBeaten: {number}?, flags: { [string]: boolean }?, settings: { music: number, effects: number }?, saving: boolean? }"),
		-- c2s, STUDIO ONLY (ignored unless RunService:IsStudio()); json <= 1 KB; stored in TestHooks.reports[name].
		-- studioOnly (M2-02 N3): not created on a live server, so nothing queues on a remote nobody listens to.
		TestReport = { kind = "event", dir = "c2s", payload = "{ name: string, json: string }", studioOnly = true },
		-- c2s. Each 0..1, rounded to 0.05 by the server; one mutate (M2-09 handles it).
		Settings = c2s("{ music: number, effects: number }", 2, "M2-09"),
		-- s2c to owner: a toast the server decides. kind from Ids.NOTICES; n = the number it shows, if any.
		Notice = s2c("{ kind: string, n: number? }", "any system"),
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
			if spec.studioOnly and not RunService:IsStudio() then
				continue
			end
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

-- Calls per second allowed for a c2s remote: the entry's rate (M2), else Config.Punch.RATE["Family.Name"] (M1).
function Net.rateFor(family: string, name: string): number?
	local s = spec(family, name)
	if s.rate then
		return s.rate
	end
	return Config.Punch.RATE[family .. "." .. name]
end

-- Server: hook a c2s remote. Rate-limited by Net.rateFor (required for every c2s remote); a payload that is not
-- a table is dropped. handler(player, payload) does every other check.
function Net.onServerEvent(family: string, name: string, handler: (Player, any) -> ()): RBXScriptConnection
	assert(RunService:IsServer(), "Net.onServerEvent is server only")
	local s = spec(family, name)
	assert(s.dir ~= "s2c", ("Net: %s.%s is server-to-client"):format(family, name))
	local key = family .. "." .. name
	assert(typeof(Net.rateFor(family, name)) == "number", "Net: no rate limit for " .. key)
	return Net.get(family, name).OnServerEvent:Connect(function(player: Player, payload: any)
		local perSec = Net.rateFor(family, name) :: number
		if not Net.rateOk(player, key, perSec) then
			return
		end
		if typeof(payload) ~= "table" then
			return
		end
		handler(player, payload)
	end)
end

-- Server: send a s2c remote to one player / to everyone / to players within `radius` studs of `pos` except `except`.
-- Unreliable payloads must stay under 900 bytes (engine cap 1000).
function Net.fire(family: string, name: string, player: Player, payload: any)
	Net.get(family, name):FireClient(player, payload)
end
function Net.fireAll(family: string, name: string, payload: any)
	Net.get(family, name):FireAllClients(payload)
end
function Net.fireNear(family: string, name: string, pos: Vector3, radius: number, except: Player?, payload: any)
	local r = Net.get(family, name)
	for _, p in ipairs(Players:GetPlayers()) do
		local root = p ~= except and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root and ((root :: BasePart).Position - pos).Magnitude <= radius then
			r:FireClient(p, payload)
		end
	end
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
