--!strict
-- Systems/Steal: holding a boss on another player's spot, carrying it off, the owner's punch and chase, returns, the
-- transfer, the 60 s safe time and the bought-boss policy guard (brief system 10; m2-contract.md C "Steal", C2, H with
-- [M2-02 M5, M6, M7, M8]; TEAM CALL 38).
--
-- One lock per boss uid ([M2-02 M5]): from an accepted HoldStart ('held') through the carry-off ('carriedOff') until
-- the boss is back or the transfer's in-memory move is done. Base.setLockCheck(Steal.isLocked) refuses the owner's
-- PickUp, Swap, Upgrade, Place onto that spot and Rebirth (Base.isLocked) meanwhile. The boss stays in the owner's
-- profile at its spot the whole time; nothing is saved until the transfer.
--
-- Hold: timed by the server (receipt + HOLD_S, Quick Hands 1.0 s), sampled every Heartbeat: the thief beyond
-- HOLD_RANGE + 1 ('moved'), the owner's shield rising ('shield'), an owner punch ('punched'), either player leaving
-- ('left'), the boss gone or the thief carrying / fighting ('state'). No client "done".
-- Carry-off: Carry.begin(thief, origin "stolen"). The owner gets Steal.Alert and runs at CHASE_SPEED. The carry never
-- enters `dropped` (Carry): a hazard, a fall, a reset, an over-speed or teleport, or leaving ends it and Carry's
-- listener here returns the boss ('returned' with the reason); the owner's punch returns it ('dropped'; Iron Grip:
-- the first hit staggers, a second within 10 s drops); the owner's shield rising while the thief is still inside the
-- owner's plot returns it ('shield'); the owner leaving returns it ('left').
-- Success: the thief inside their own plot, in the same step: the uid still at that spot in the owner's profile and
-- locked to this thief, the minimum travel time passed (else 'speed': home faster than possible = a teleport); the
-- owner's pad is settled and paid to the owner (TEAM CALL M2-11-2); then Session.transfer (in memory at once; then the
-- owner's write, then the thief's). The boss goes to the thief's crate in the save (level and bought mark unchanged)
-- and stays on the thief's head as a crate carry, to place, swap or sell like any carried boss. 60 s safe time.
-- Policy guard (H, TEAM CALL 38): a boss with a bought mark cannot be lifted when Policy.get(thief) or
-- Policy.get(owner) says tradingAllowed = false; Steal.Flag tells each viewer; a forced HoldStart is refused 'locked'.
--
-- c2s: Steal.HoldStart { plotId, uid }, HoldCancel {}, OwnerPunch { thiefUserId }.
-- s2c: Steal.Alert (owner), Result (thief and owner), Flag (each viewer, bought bosses), Punch (unreliable, near).
-- Seam entry points (the remotes and the Steal2 hook call the same): tryHold, tryCancel, tryPunch.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Session = require(script.Parent.Parent.Data.Session)
local Transfer = require(script.Parent.Parent.Data.Transfer)
local Schema = require(script.Parent.Parent.Data.Schema)
local Plots = require(script.Parent.Plots)
local Policy = require(script.Parent.Policy)
local Shield = require(script.Parent.Shield)
local Carry = require(script.Parent.Carry)
local Base = require(script.Parent.Base)
local Bag = require(script.Parent.Bag)
local Fight = require(script.Parent.Fight)
local Income = require(script.Parent.Income)
local Zones = require(script.Parent.Zones)

local Steal = {}

type Hold = {
	thief: any,
	owner: any,
	plot: Model,
	plotId: number,
	uid: string,
	spot: number,
	spotPos: Vector3,
	creatureId: string,
	startedAt: number,
	endsAt: number,
}
type Off = {
	thief: any,
	owner: any,
	plot: Model,
	plotId: number,
	uid: string,
	spot: number,
	creatureId: string,
	level: number,
	bought: any?,
	liftAt: number,
	minTravel: number,
	phase: string, -- "carried" | "transferring"
	staggerAt: number?,
}

local holds: { [any]: Hold } = {}
local offs: { [any]: Off } = {}
local locks: { [string]: { thief: any, kind: string } } = {}
local safeUntil: { [string]: number } = {}
local lastPunch: { [any]: number } = {}
local stunUntil: { [any]: number } = {}
local staggerUntil: { [any]: number } = {}
local chasing: { [any]: boolean } = {}
local chaseSamples: { [any]: { { pos: Vector3, at: number } } } = {}
local chaseFlag: { [any]: number } = {}
local flagSent: { [any]: { [string]: boolean } } = {}

Steal.stats = { results = {} :: { any }, alerts = {} :: { any }, punches = {} :: { any }, refused = {} :: { [string]: number }, transfers = {} :: { any }, flags = {} :: { any } }

local function now(): number
	return workspace:GetServerTimeNow()
end

local function isReal(p: any): boolean
	return typeof(p) == "Instance" and p.Parent == Players
end

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function log(list: { any }, e: any)
	e.at = now()
	table.insert(list, e)
	if #list > 200 then
		table.remove(list, 1)
	end
end

-- Steal.Result to one player (real players only; the stats keep every one for the checks).
local function send(to: any, payload: any)
	log(Steal.stats.results, { userId = to.UserId, state = payload.state, reason = payload.reason, uid = payload.uid })
	if isReal(to) then
		Net.fire("Steal", "Result", to, payload)
	end
end
local function both(a: any, b: any, payload: any)
	send(a, payload)
	if b and b ~= a then
		send(b, payload)
	end
end

local function refuse(thief: any, reason: string, uid: any): string
	Steal.stats.refused[reason] = (Steal.stats.refused[reason] or 0) + 1
	send(thief, { state = "refused", reason = reason, uid = if typeof(uid) == "string" then uid else "" })
	return reason
end

function Steal.isLocked(uid: string): boolean
	return locks[uid] ~= nil
end

-- The owner has a steal alert on (one of their bosses carried off) or a shield-broken alert.
function Steal.alertOn(player: any): boolean
	for _, o in pairs(offs) do
		if o.owner == player and o.phase == "carried" then
			return true
		end
	end
	return Shield.brokenAlertOn(player)
end

function Steal.holdOf(thief: any): Hold?
	return holds[thief]
end
function Steal.offOf(thief: any): Off?
	return offs[thief]
end
function Steal.safeUntil(uid: string): number?
	return safeUntil[uid]
end

local function bossOn(p: any, uid: string): any
	for _, b in ipairs(p.bosses) do
		if b.uid == uid then
			return b
		end
	end
	return nil
end

-- The policy guard (contract H): is this bought boss locked for this thief?
function Steal.policyLocked(thief: any, owner: any, boss: any): boolean
	if not (boss and boss.bought) then
		return false
	end
	return Policy.get(thief).tradingAllowed ~= true or Policy.get(owner).tradingAllowed ~= true
end

local function inFight(p: any): boolean
	return typeof(p) == "Instance" and Fight.get(p) ~= nil
end

-- ------------------------------------------------------------------------------------------------ the hold
function Steal.tryHold(thief: any, plotId: any, uid: any): string?
	if not Net.isInt(plotId, 1, 64) or not Net.isShortString(uid, 40) then
		return refuse(thief, "state", uid)
	end
	if not Session.get(thief) or not Plots.of(thief) then
		return refuse(thief, "state", uid) -- S8: no plot, no steal
	end
	local plot = Plots.byId(plotId)
	if not plot or plot == Plots.of(thief) then
		return refuse(thief, "state", uid)
	end
	local owner = Plots.ownerOf(plot)
	local op = owner and Session.get(owner)
	if not owner or not op then
		return refuse(thief, "left", uid)
	end
	if Shield.isUpPlot(plot) then
		return refuse(thief, "shield", uid)
	end
	local b = bossOn(op, uid)
	if not b or not Net.isInt(b.spot, 1, Config.Base.MAX_SPOTS) then
		return refuse(thief, "state", uid) -- not placed there (the crate, pads and cash cannot be stolen)
	end
	local oc = Carry.get(owner)
	if locks[uid] or holds[thief] or offs[thief] or (oc and oc.uid == uid) or Transfer.isPending(owner, uid) then
		return refuse(thief, "state", uid)
	end
	if (safeUntil[uid] or -math.huge) > Shield.clock() then
		return refuse(thief, "safe", uid)
	end
	if Carry.get(thief) or inFight(thief) or (stunUntil[thief] or 0) > now() then
		return refuse(thief, "state", uid)
	end
	local part = Base.spotPart(plot, b.spot)
	local r = Plots.root(thief)
	if not part or not r then
		return refuse(thief, "state", uid)
	end
	if flat(r.Position, part.Position) > Config.Steal.HOLD_RANGE or math.abs(r.Position.Y - part.Position.Y) > Config.Steal.HOLD_HEIGHT then
		return refuse(thief, "range", uid)
	end
	if Steal.policyLocked(thief, owner, b) then
		return refuse(thief, "locked", uid)
	end
	local t = now()
	local holdS = if Bag.owns(thief, Config.Steal.QUICK_PASS) then Config.Steal.QUICK_HOLD_S else Config.Steal.HOLD_S
	local h: Hold = {
		thief = thief,
		owner = owner,
		plot = plot,
		plotId = plotId,
		uid = uid,
		spot = b.spot,
		spotPos = part.Position,
		creatureId = b.creatureId,
		startedAt = t,
		endsAt = t + holdS,
	}
	holds[thief] = h
	locks[uid] = { thief = thief, kind = "held" }
	both(thief, owner, { state = "held", uid = uid, holdEndsAt = h.endsAt })
	return nil
end

local function endHold(h: Hold, reason: string)
	if holds[h.thief] ~= h then
		return
	end
	holds[h.thief] = nil
	if locks[h.uid] and locks[h.uid].thief == h.thief then
		locks[h.uid] = nil
	end
	both(h.thief, h.owner, { state = "cancelled", reason = reason, uid = h.uid })
end

function Steal.tryCancel(thief: any): string?
	local h = holds[thief]
	if not h then
		return "state"
	end
	endHold(h, "moved")
	return nil
end

-- ------------------------------------------------------------------------------------------------ chase speed
local function humanoid(p: any): Humanoid?
	local c = p and p.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function chaseOn(owner: any): boolean
	for _, o in pairs(offs) do
		if o.owner == owner and o.phase == "carried" then
			return true
		end
	end
	return false
end

local function updateChase(owner: any)
	local on = chaseOn(owner) and Carry.get(owner) == nil
	local hum = humanoid(owner)
	if on then
		chasing[owner] = true
		if hum and hum.WalkSpeed == Config.Steal.WALK then
			hum.WalkSpeed = Config.Steal.CHASE_SPEED
		end
	elseif chasing[owner] then
		chasing[owner] = nil
		chaseSamples[owner] = nil
		if hum and hum.WalkSpeed == Config.Steal.CHASE_SPEED then
			hum.WalkSpeed = Config.Steal.WALK
		end
	end
end

-- The server moved the character (a push, a check): the chase sampling starts over.
function Steal.resetChase(who: any)
	chaseSamples[who] = nil
end

-- [M2-02 M7] the chase sampled like a carry: over the limits the owner's punches are refused 'speed' for a moment.
local function sampleChase(owner: any, dt: number)
	local r = Plots.root(owner)
	if not r then
		return
	end
	local S = Config.Steal
	local list = chaseSamples[owner]
	local clock = os.clock()
	if not list then
		chaseSamples[owner] = { { pos = r.Position, at = clock } }
		return
	end
	local last = list[#list]
	local bad = flat(r.Position, last.pos) > S.CHASE_SPEED * math.max(dt, clock - last.at) * S.CHASE_STEP_MULT + S.CHASE_STEP_PAD
	while #list > 1 and clock - list[1].at > S.CHASE_WINDOW_S do
		table.remove(list, 1)
	end
	if not bad and flat(r.Position, list[1].pos) > S.CHASE_SPEED * S.CHASE_WINDOW_MULT + S.CHASE_WINDOW_PAD then
		bad = true
	end
	if bad then
		chaseFlag[owner] = now() + S.CHASE_FLAG_S
		chaseSamples[owner] = { { pos = r.Position, at = clock } }
		return
	end
	table.insert(list, { pos = r.Position, at = clock })
	if #list > 240 then
		table.remove(list, 1)
	end
end

-- ------------------------------------------------------------------------------------------------ lift, return, success
local function entranceOf(plot: Model): Vector3
	local e = plot:FindFirstChild("Entrance")
	if e and e:IsA("BasePart") then
		return e.Position
	end
	return plot:GetPivot().Position
end

local function lift(h: Hold)
	holds[h.thief] = nil
	local thief, owner = h.thief, h.owner
	local op = Session.get(owner)
	local b = op and bossOn(op, h.uid)
	if not b or b.spot ~= h.spot or Carry.get(thief) or not Plots.of(thief) then
		locks[h.uid] = nil
		both(thief, owner, { state = "cancelled", reason = "state", uid = h.uid })
		return
	end
	local c = Carry.begin(thief, b.creatureId, { origin = "stolen", uid = h.uid, level = b.level, bought = Schema.copy(b.bought), stolenFrom = h.plotId })
	if not c then
		locks[h.uid] = nil
		both(thief, owner, { state = "cancelled", reason = "state", uid = h.uid })
		return
	end
	local home = entranceOf(Plots.of(thief) :: Model)
	local t = now()
	offs[thief] = {
		thief = thief,
		owner = owner,
		plot = h.plot,
		plotId = h.plotId,
		uid = h.uid,
		spot = h.spot,
		creatureId = b.creatureId,
		level = b.level,
		bought = b.bought,
		liftAt = t,
		minTravel = Config.Steal.TRAVEL_FACTOR * flat(h.spotPos, home) / Carry.speed(thief),
		phase = "carried",
	}
	locks[h.uid] = { thief = thief, kind = "carriedOff" }
	local alert = { uid = h.uid, creatureId = b.creatureId, thiefUserId = thief.UserId, bought = b.bought ~= nil }
	log(Steal.stats.alerts, { owner = owner.UserId, uid = h.uid, thief = thief.UserId, bought = alert.bought })
	if isReal(owner) then
		Net.fire("Steal", "Alert", owner, alert)
	end
	both(thief, owner, { state = "carried", uid = h.uid })
	updateChase(owner)
end

-- The boss is back on its spot (it never left the owner's profile). state "returned" or "dropped" (a punch).
local function returnBoss(o: Off, reason: string, state: string?)
	if offs[o.thief] ~= o then
		return
	end
	offs[o.thief] = nil
	if locks[o.uid] and locks[o.uid].thief == o.thief then
		locks[o.uid] = nil
	end
	local c = Carry.get(o.thief)
	if c and c.origin == "stolen" and c.uid == o.uid then
		Carry.lose(o.thief, reason) -- the listener finds no off and does nothing more
	end
	both(o.thief, o.owner, { state = state or "returned", reason = reason, uid = o.uid })
	updateChase(o.owner)
end

local CARRY_WHY = { hazard = "hazard", speed = "speed", left = "left", shield = "shield", punched = "punched" }

local function finishTransfer(o: Off, ok: boolean)
	if offs[o.thief] ~= o then
		return
	end
	if not ok then
		-- nothing moved (the in-memory step refused): the boss is still the owner's
		o.phase = "carried"
		returnBoss(o, "state")
		return
	end
	offs[o.thief] = nil
	local c = Carry.get(o.thief)
	if c and c.origin == "stolen" and c.uid == o.uid then
		if Transfer.isPending(o.thief, o.uid) then
			-- the owner's write has not succeeded yet: the boss waits in the thief's crate (left out of the thief's
			-- saves until it does, [M2-02 M6]) instead of on the head
			Carry.lose(o.thief, "pending")
		else
			Carry.take(o.thief)
			Carry.begin(o.thief, o.creatureId, { origin = "crate", uid = o.uid, level = o.level, bought = Schema.copy(o.bought) })
		end
	end
end

local function succeed(o: Off)
	local thief, owner = o.thief, o.owner
	local op, tp = Session.get(owner), Session.get(thief)
	local b = op and bossOn(op, o.uid)
	local lk = locks[o.uid]
	if not b or not tp or b.spot ~= o.spot or not lk or lk.thief ~= thief then
		returnBoss(o, "state")
		return
	end
	if now() - o.liftAt < o.minTravel then
		returnBoss(o, "speed") -- home sooner than the carry speed allows: a teleport ([M2-02 M7])
		return
	end
	if not Session.isSaving(owner) or not Session.isSaving(thief) then
		returnBoss(o, "state") -- a temp profile could not keep the boss
		return
	end
	-- the owner's pad cash stays the owner's: settled and paid in one mutate before the boss leaves (M2-11-2)
	local zt = Zones.now()
	local mult = Income.mult(if typeof(owner) == "Instance" then owner else nil, op)
	local paid = 0
	Session.mutate(owner, function(q)
		local qb = bossOn(q, o.uid)
		if qb then
			paid = Income.settleOp(q, qb, zt, mult)
			qb.padCash = 0
			if paid > 0 then
				Session.ops.addCash(q, paid, false)
			end
		end
	end)
	if paid > 0 then
		Income.collected(owner, o.spot, paid)
	end
	o.phase = "transferring"
	local entry = { uid = o.uid, creatureId = b.creatureId, level = b.level, bought = Schema.copy(b.bought) }
	-- Session.transfer applies the move in memory before its first yield, then writes owner then thief.
	task.spawn(function()
		local ok = Session.transfer(o.uid, owner, thief, function(nt, e)
			table.insert(nt.crate, { uid = e.uid, creatureId = e.creatureId, level = e.level, bought = Schema.copy(e.bought) })
		end)
		log(Steal.stats.transfers, { uid = o.uid, from = owner.UserId, to = thief.UserId, ok = ok, pending = Transfer.isPending(thief, o.uid) })
		finishTransfer(o, ok)
	end)
	if offs[thief] ~= o then
		return -- refused at once (finishTransfer returned it)
	end
	local moved = false
	for _, e in ipairs(tp.crate) do
		if e.uid == o.uid then
			moved = true
		end
	end
	if not moved then
		return
	end
	locks[o.uid] = nil
	safeUntil[o.uid] = Shield.clock() + Config.Steal.SAFE_S
	both(thief, owner, { state = "success", uid = entry.uid })
	updateChase(owner)
end

-- ------------------------------------------------------------------------------------------------ the owner's punch
local function stun(thief: any)
	stunUntil[thief] = now() + Config.Steal.STUN_S
	local hum = humanoid(thief)
	if hum then
		hum.WalkSpeed = 0
	end
	task.delay(Config.Steal.STUN_S, function()
		local h2 = humanoid(thief)
		if h2 and h2.WalkSpeed == 0 and (stunUntil[thief] or 0) <= now() + 0.01 and not inFight(thief) then
			h2.WalkSpeed = Config.Steal.WALK
		end
	end)
end

local function broadcastPunch(owner: any, thief: any, hit: string)
	log(Steal.stats.punches, { from = owner.UserId, to = thief.UserId, hit = hit })
	local r = Plots.root(thief)
	if r then
		Net.fireNear("Steal", "Punch", r.Position, Config.Steal.PUNCH_RADIUS, nil, { fromUserId = owner.UserId, toUserId = thief.UserId, hit = hit })
	end
end

function Steal.tryPunch(owner: any, thiefUserId: any): string?
	if not Net.isInt(thiefUserId) then
		return "bad"
	end
	local t = now()
	if t - (lastPunch[owner] or -math.huge) < Config.Steal.PUNCH_GAP_S - 0.02 then
		Steal.stats.refused.gap = (Steal.stats.refused.gap or 0) + 1
		return "gap"
	end
	local thief = Plots.byUserId(thiefUserId)
	if not thief or thief == owner or not Session.get(owner) then
		return "state"
	end
	local h, o = holds[thief], offs[thief]
	local myPlot = Plots.of(owner)
	local target = if h and h.owner == owner then h elseif o and o.owner == owner and o.phase == "carried" then o else nil
	if not target or not myPlot or target.plot ~= myPlot then
		return "notYours"
	end
	if Carry.get(owner) or inFight(owner) then
		return "state"
	end
	local ro, rt = Plots.root(owner), Plots.root(thief)
	if not ro or not rt or flat(ro.Position, rt.Position) > Config.Steal.PUNCH_RANGE or math.abs(ro.Position.Y - rt.Position.Y) > Config.Steal.PUNCH_HEIGHT then
		return "range"
	end
	if (chaseFlag[owner] or 0) > t then
		return "speed"
	end
	lastPunch[owner] = t
	if h and target == h then
		broadcastPunch(owner, thief, "drop")
		endHold(h, "punched")
		return nil
	end
	local off = o :: Off
	-- the carried boss must still be the owner's (stolenFrom = the owner's plot, the uid in the owner's profile)
	local c = Carry.get(thief)
	local op = Session.get(owner)
	if not c or c.origin ~= "stolen" or c.uid ~= off.uid or c.stolenFrom ~= myPlot:GetAttribute("PlotId") or not (op and bossOn(op, off.uid)) then
		return "state"
	end
	if Bag.owns(thief, Config.Steal.IRON_PASS) and not (off.staggerAt and t - off.staggerAt <= Config.Steal.IRON_WINDOW_S) then
		off.staggerAt = t
		staggerUntil[thief] = t + Config.Steal.STAGGER_S
		Carry.setSlow(thief, Config.Steal.STAGGER_SLOW, Config.Steal.STAGGER_S) -- server-held slow (M2-11b seam)
		broadcastPunch(owner, thief, "stagger")
		both(thief, owner, { state = "stagger", uid = off.uid })
		return nil
	end
	broadcastPunch(owner, thief, "drop")
	returnBoss(off, "punched", "dropped")
	stun(thief)
	return nil
end

-- Studio, checks: stagger and stun windows the server keeps (the stagger's slow is Carry.setSlow, server-held).
function Steal.staggered(thief: any): boolean
	return (staggerUntil[thief] or 0) > now()
end
function Steal.stunned(thief: any): boolean
	return (stunUntil[thief] or 0) > now()
end

-- ------------------------------------------------------------------------------------------------ the policy flag
-- What one viewer's Steal prompt shows for one boss on another player's plot: locked = the greyed "Can't be stolen".
function Steal.flagFor(viewer: any, owner: any, boss: any): boolean
	return Steal.policyLocked(viewer, owner, boss)
end

local flagsDirty = false
local function sendFlags()
	flagsDirty = false
	local everyone = Plots.players()
	for _, viewer in ipairs(everyone) do
		local sent = flagSent[viewer] or {}
		flagSent[viewer] = sent
		local seen: { [string]: boolean } = {}
		for _, owner in ipairs(everyone) do
			local p = owner ~= viewer and Session.get(owner)
			if p then
				for _, b in ipairs(p.bosses) do
					if b.bought then
						local locked = Steal.flagFor(viewer, owner, b)
						seen[b.uid] = true
						if sent[b.uid] ~= locked then
							sent[b.uid] = locked
							log(Steal.stats.flags, { viewer = viewer.UserId, uid = b.uid, locked = locked })
							if isReal(viewer) then
								Net.fire("Steal", "Flag", viewer, { uid = b.uid, locked = locked })
							end
						end
					end
				end
			end
		end
		for uid in pairs(sent) do
			if not seen[uid] then
				sent[uid] = nil
			end
		end
	end
end
local function dirtyFlags()
	if not flagsDirty then
		flagsDirty = true
		task.defer(sendFlags)
	end
end
Steal.refreshFlags = dirtyFlags

-- ------------------------------------------------------------------------------------------------ the step
local function step(dt: number)
	local t = now()
	for thief, h in pairs(holds) do
		local op = Session.get(h.owner)
		local r = Plots.root(thief)
		if not op or not Session.get(thief) or Plots.ownerOf(h.plot) ~= h.owner then
			endHold(h, "left")
		elseif Shield.isUpPlot(h.plot) then
			endHold(h, "shield")
		elseif not bossOn(op, h.uid) or Carry.get(thief) or inFight(thief) or not r then
			endHold(h, "state")
		elseif flat(r.Position, h.spotPos) > Config.Steal.HOLD_RANGE + Config.Steal.HOLD_CANCEL_SLACK then
			endHold(h, "moved")
		elseif t >= h.endsAt then
			lift(h)
		end
	end
	for thief, o in pairs(offs) do
		if o.phase == "carried" then
			local r = Plots.root(thief)
			local home = Plots.of(thief)
			if not Session.get(o.owner) or Plots.ownerOf(o.plot) ~= o.owner then
				returnBoss(o, "left")
			elseif r and Shield.isUpPlot(o.plot) and Carry.insidePlot(o.plot, r.Position, 0) then
				returnBoss(o, "shield")
			elseif r and home and Carry.insidePlot(home, r.Position, 0) then
				succeed(o)
			end
		end
	end
	for owner in pairs(chasing) do
		updateChase(owner)
		if chasing[owner] then
			sampleChase(owner, dt)
		end
	end
end

function Steal.start()
	Base.setLockCheck(Steal.isLocked)
	Base.setAlertCheck(Steal.alertOn)

	Net.onServerEvent("Steal", "HoldStart", function(player, payload)
		Steal.tryHold(player, payload.plotId, payload.uid)
	end)
	Net.onServerEvent("Steal", "HoldCancel", function(player, _payload)
		Steal.tryCancel(player)
	end)
	Net.onServerEvent("Steal", "OwnerPunch", function(player, payload)
		local why = Steal.tryPunch(player, payload.thiefUserId)
		if why and why ~= "gap" then
			Steal.stats.refused["punch:" .. why] = (Steal.stats.refused["punch:" .. why] or 0) + 1
		end
	end)

	-- A stolen carry ended by anything but the transfer: the boss goes back ([M2-02 M8]).
	Carry.onChanged(function(player, state, c, why)
		if state ~= "none" or not c or c.origin ~= "stolen" then
			return
		end
		local o = offs[player]
		if o and o.uid == c.uid and o.phase == "carried" then
			returnBoss(o, CARRY_WHY[why or ""] or "state")
		end
	end)

	-- The owner's shield rising: holds on that plot cancelled, a lifted boss still inside goes back.
	Shield.onRaised(function(plot, _how)
		for _, h in pairs(holds) do
			if h.plot == plot then
				endHold(h, "shield")
			end
		end
		for thief, o in pairs(offs) do
			local r = Plots.root(thief)
			if o.plot == plot and o.phase == "carried" and r and Carry.insidePlot(plot, r.Position, 0) then
				returnBoss(o, "shield")
			end
		end
	end)

	-- Leaving (before the final save): a thief's hold or carry ends; an owner's bosses held or carried off come back.
	local function leaving(player: any)
		for _, h in pairs(holds) do
			if h.thief == player or h.owner == player then
				endHold(h, "left")
			end
		end
		for _, o in pairs(offs) do
			if (o.thief == player or o.owner == player) and o.phase == "carried" then
				returnBoss(o, "left")
			end
		end
		updateChase(player)
	end
	Session.onLeaving(leaving)
	Plots.onStandIn(function(_fake, _opts)
		dirtyFlags()
	end, leaving)
	Players.PlayerRemoving:Connect(function(p)
		leaving(p)
		lastPunch[p], stunUntil[p], staggerUntil[p], chasing[p], chaseSamples[p], chaseFlag[p], flagSent[p] = nil, nil, nil, nil, nil, nil, nil
	end)

	-- The policy flags: on join, on any change of a player's bosses, on a policy answer.
	Session.onJoin(function(_player)
		dirtyFlags()
	end)
	Session.onChanged(function(_player, key, _value)
		if key == "bosses" then
			dirtyFlags()
		end
	end)
	Policy.onChange(function(_player)
		dirtyFlags()
	end)

	-- A respawn while chasing: the new character gets the chase speed (updateChase each step).
	RunService.Heartbeat:Connect(step)
end

return Steal
