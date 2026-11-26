--!strict
-- Data/Session: the facade every system uses for the player's profile (m2-contract.md section D), plus the M1
-- plot and spawn duties (TEAM CALL M1-06a). Built by M2-09 (data-engineer) to the `roblox-data` skill and TEAM
-- CALL B3: one record per player, the session lock inside the record, one UpdateAsync per write.
--
-- Pieces: Data/Schema (record v1, validation), Data/Migrations (steps n -> n+1), Data/Store (DataStore or the
-- stand-in memory store, retries), Data/Transfer (the steal by uid), Data/Purchases (the receipt record).
--
-- API (M1 names keep working: get, set, onChanged, onJoin, plot, wipe):
--   get(player) -> Profile?               never yields; nil while loading and after leaving. Read-only by convention.
--   mutate(player, fn, token?) -> bool    sync; fn changes a copy; the copy is validated (finite, ints in range, the
--                                         schema) and the protected fields checked; then applied, Profile.Changed
--                                         sent for public keys that changed. False and nothing applied if fn
--                                         errors, a check fails or there is no profile. After every change
--                                         boughtCash = min(boughtCash, cash).
--   set(player, key, value)               M1: one key. Refuses protected keys. "cash" goes through addCash/spendCash.
--   addCash(player, n, bought?) -> bool   spendCash(player, n) -> bool (the bought-cash rule)
--   addZoneBeaten(player, zone) -> bool   newUid(player) -> string?  ("<userId>-<n>", unique for ever)
--   save(player, reason) -> (bool, string?)  yields: one UpdateAsync that checks and renews the lock
--   transfer(uid, fromPlayer, toPlayer, place(profile, entry)) -> bool   (Data/Transfer; yields for the writes)
--   recordPurchase(player, purchaseId, grant(profile)) -> "granted" | "already" | "retry"   (Data/Purchases)
--   isSaving(player) -> bool              onLeaving(fn(player))  runs before the final write (thief returns)
--   claim(name) -> token                  for the owners of protected fields: "BoughtMark", "StarterPack"
--   ops                                   pure helpers for grants and claimed mutates: ops.addCash(p, n, bought),
--                                         ops.spendCash(p, n), ops.newUid(p, userId)
-- Lifecycle: join loads (lock taken in the load's write; a foreign live lock or an error: retried LOAD_TRIES over
-- 15 s, then a temp profile with Profile.Notice notSaving, still retried in the background until the lease ends;
-- a record newer than this code: temp profile, never written). Autosave every AUTOSAVE_S. Leave: onLeaving, thief
-- bookkeeping, leftAt, final write releasing the lock. BindToClose: every leave in parallel within 25 s.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)
local Schema = require(script.Parent.Schema)
local Migrations = require(script.Parent.Migrations)
local Store = require(script.Parent.Store)
local Transfer = require(script.Parent.Transfer)
local Purchases = require(script.Parent.Purchases)

export type Spot = { uid: string, creatureId: string, level: number, stamp: number }
export type Boss = { uid: string, creatureId: string, level: number, spot: number, padCash: number, padStamp: number, bought: { source: string, buyer: number }? }
export type CrateBoss = { uid: string, creatureId: string, level: number, bought: { source: string, buyer: number }? }
export type Profile = {
	version: number,
	power: number,
	cash: number,
	boughtCash: number,
	strengthLevel: number,
	speedLevel: number,
	rebirths: number,
	bosses: { Boss },
	crate: { CrateBoss },
	zonesBeaten: { number },
	spinTickets: number,
	breakerCharges: number,
	starterPackGiven: boolean,
	purchases: { string },
	transferNote: { { uid: string, to: number } },
	nextUid: number,
	leftAt: number,
	shieldReadyAt: number,
	flags: { [string]: boolean },
	settings: { music: number, effects: number },
	-- runtime only (never saved): M1's carry and the M1 spots view of `bosses` (kept in step both ways)
	carry: { uid: string, creatureId: string }?,
	spots: { [number]: Spot },
}

type Sess = {
	player: any,
	userId: number,
	key: string,
	store: any,
	state: "loading" | "live" | "temp" | "lost",
	saving: boolean,
	leaving: boolean,
	standIn: boolean,
	profile: any,
	lastSave: number,
	busy: boolean,
	waiters: { thread },
	pendingHooks: { (any) -> () },
	why: string?,
	finalStatus: string?,
}

local Session = {}

-- One id per server for the lock (M2-02 S1: game.JobId is "" in Studio, so two Studio sessions would share it).
local SERVER_ID = HttpService:GenerateGUID(false) -- replaced only by the Studio crash simulation
Session.SERVER_ID = SERVER_ID

local sessions: { [any]: Sess } = {}
local profiles: { [any]: any } = {}
local plots: { [Player]: Model } = {}
local listeners: { (Player, string, any) -> () } = {}
local charConns: { [Player]: RBXScriptConnection } = {}
local leavingFns: { (Player) -> () } = {}
local joinFns: { (Player) -> () } = {}
local inflight = 0

-- Allow sets for the protected fields (M2-02 M1). ALL is the store's own and the owning APIs' (internal).
local ALL = setmetatable({}, { __index = function()
	return true
end })
local CLAIMS: { [string]: { [string]: boolean } } = {
	BoughtMark = { bought = true, boughtCash = true },
	StarterPack = { bought = true, boughtCash = true, starterPackGiven = true },
}
local tokens: { [any]: { [string]: boolean } } = {}
local tokenByName: { [string]: any } = {}

local function isReal(player: any): boolean
	return typeof(player) == "Instance" and player.Parent == Players
end

-- Listeners ----------------------------------------------------------------------------------------------------------

function Session.onChanged(fn: (Player, string, any) -> ()): () -> ()
	table.insert(listeners, fn)
	return function()
		local i = table.find(listeners, fn)
		if i then
			table.remove(listeners, i)
		end
	end
end

local function fire(player: any, key: string, value: any)
	for _, fn in ipairs(table.clone(listeners)) do
		local ok, err = pcall(fn, player, key, value)
		if not ok then
			warn("[HFB] Session listener error: " .. tostring(err))
		end
	end
end

local function sendChanged(player: any, payload: { [string]: any })
	if next(payload) and isReal(player) then
		Net.get("Profile", "Changed"):FireClient(player, payload)
	end
end

local function notice(player: any, kind: string)
	if isReal(player) then
		Net.get("Profile", "Notice"):FireClient(player, { kind = kind })
	end
end

local function sendAll(player: any)
	local p = profiles[player]
	local S = sessions[player]
	if not p or not S then
		return
	end
	local payload: { [string]: any } = {}
	for k in pairs(Schema.PUBLIC) do
		payload[k] = Schema.copy(p[k])
	end
	payload.saving = S.saving
	sendChanged(player, payload)
end

-- The mutate engine ---------------------------------------------------------------------------------------------------

-- Replaces the live profile's contents with `new` in place (callers may hold the table), then tells everyone.
local function commit(player: any, new: any, force: { string }?)
	local p = profiles[player]
	local changed = {}
	for k, v in pairs(new) do
		if not Schema.equal(p[k], v) then
			table.insert(changed, k)
		end
	end
	for k in pairs(p) do
		if new[k] == nil then
			table.insert(changed, k)
		end
	end
	for k in pairs(p) do
		p[k] = nil
	end
	for k, v in pairs(new) do
		p[k] = v
	end
	local payload = {}
	for _, k in ipairs(changed) do
		if Schema.PUBLIC[k] then
			payload[k] = Schema.copy(p[k])
		end
	end
	sendChanged(player, payload)
	local fired = {}
	for _, k in ipairs(changed) do
		fired[k] = true
		fire(player, k, p[k])
	end
	for _, k in ipairs(force or {}) do
		if not fired[k] then
			fire(player, k, p[k])
		end
	end
end

-- Checks a candidate profile against the old one: protected fields (unless allowed), the bought marks, the
-- invariant, the spots view, the schema. Returns (true) or (false, why). Changes `new` (invariant, spots).
local function prepare(old: any, new: any, allow: any): (boolean, string?)
	-- The bought-cash rule may lower boughtCash to cash without a claim (spendCash and ops.spendCash do exactly that);
	-- any other change to it needs one.
	if not allow.boughtCash and type(old.boughtCash) == "number" and type(new.cash) == "number" then
		if new.boughtCash == math.min(old.boughtCash, new.cash) then
			new.boughtCash = old.boughtCash
		end
	end
	for k in pairs(Schema.PROTECTED) do
		if not allow[k] and not Schema.equal(old[k], new[k]) then
			return false, "protected field " .. k
		end
	end
	if not allow.bought then
		local before, after = Schema.marks(old), Schema.marks(new)
		for uid, m in pairs(after) do
			if m ~= false and (before[uid] == nil or not Schema.equal(before[uid], m)) then
				return false, "protected field bought (" .. uid .. ")"
			end
		end
		for uid, m in pairs(before) do
			if m ~= false and after[uid] == false then
				return false, "protected field bought cleared (" .. uid .. ")"
			end
		end
	end
	if type(new.boughtCash) == "number" and type(new.cash) == "number" and new.boughtCash > new.cash then
		new.boughtCash = new.cash
	end
	if not Schema.equal(old.bosses, new.bosses) or new.spots == nil then
		new.spots = Schema.spotsFrom(new.bosses or {})
	end
	return Schema.validate(new)
end

local function apply(player: any, fn: (any) -> (), allow: any, force: { string }?): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	local new = Schema.copy(p)
	local ok, err = pcall(fn, new)
	if not ok then
		warn("[HFB] Session.mutate: fn errored, nothing applied: " .. tostring(err))
		return false
	end
	local valid, why = prepare(p, new, allow)
	if not valid then
		warn("[HFB] Session.mutate refused, nothing applied: " .. tostring(why))
		return false
	end
	commit(player, new, force)
	return true
end

function Session.mutate(player: Player, fn: (Profile) -> (), token: any?): boolean
	local allow = (token ~= nil and tokens[token]) or {}
	return apply(player, fn :: any, allow)
end

function Session.claim(name: string): any
	assert(CLAIMS[name], "Session.claim: no protected-field owner named " .. tostring(name))
	local t = tokenByName[name]
	if not t then
		t = newproxy(false)
		tokens[t] = CLAIMS[name]
		tokenByName[name] = t
	end
	return t
end

-- Pure ops (for grants inside recordPurchase and for claimed mutates).
Session.ops = {}
function Session.ops.addCash(p: any, n: number, bought: boolean?)
	assert(Net.isNumber(n, 0), "ops.addCash: bad amount")
	p.cash += n
	if bought then
		p.boughtCash += n
	end
end
function Session.ops.spendCash(p: any, n: number): boolean
	if not Net.isNumber(n, 0) or p.cash < n then
		return false
	end
	p.cash -= n
	if p.boughtCash > p.cash then
		p.boughtCash = p.cash
	end
	return true
end
function Session.ops.newUid(p: any, userId: number): string
	local id = ("%d-%d"):format(userId, p.nextUid)
	p.nextUid += 1
	return id
end

-- M1 API --------------------------------------------------------------------------------------------------------------

function Session.get(player: Player): Profile?
	return profiles[player]
end

function Session.set(player: Player, key: string, value: any)
	local p = profiles[player]
	if not p then
		return
	end
	if Schema.PROTECTED[key] then
		warn("[HFB] Session.set refused: " .. key .. " is protected (use its own API)")
		return
	end
	if key == "cash" then
		if not Net.isNumber(value, 0) then
			warn("[HFB] Session.set cash refused: " .. tostring(value))
			return
		end
		local diff = value - p.cash
		if diff > 0 then
			apply(player, function(q)
				Session.ops.addCash(q, diff, false)
			end, {}, { "cash" })
		elseif diff < 0 then
			apply(player, function(q)
				Session.ops.spendCash(q, -diff)
			end, {}, { "cash" })
		else
			fire(player, "cash", p.cash)
		end
		return
	end
	if key == "carry" then
		p.carry = value
		fire(player, key, value)
		return
	end
	if key == "spots" then
		apply(player, function(q)
			q.bosses = Schema.bossesFromSpots(value, q.bosses)
		end, {}, { "spots" })
		return
	end
	apply(player, function(q)
		q[key] = value
	end, {}, { key })
end

function Session.addCash(player: Player, n: number, bought: boolean?): boolean
	if not Net.isNumber(n, 0) then
		return false
	end
	return apply(player, function(q)
		Session.ops.addCash(q, n, bought)
	end, if bought then { boughtCash = true } else {})
end

function Session.spendCash(player: Player, n: number): boolean
	local p = profiles[player]
	if not p or not Net.isNumber(n, 0) or p.cash < n then
		return false
	end
	return apply(player, function(q)
		assert(Session.ops.spendCash(q, n))
	end, {})
end

function Session.addZoneBeaten(player: Player, zone: number): boolean
	if not Net.isInt(zone, 1, Config.Data.LIMITS.zones) then
		return false
	end
	return apply(player, function(q)
		if not table.find(q.zonesBeaten, zone) then
			table.insert(q.zonesBeaten, zone)
			table.sort(q.zonesBeaten)
		end
	end, { zonesBeaten = true })
end

function Session.newUid(player: Player): string?
	local id: string? = nil
	local userId = (player :: any).UserId
	local ok = apply(player, function(q)
		id = Session.ops.newUid(q, userId)
	end, { nextUid = true })
	return if ok then id else nil
end

-- Fresh profile for this player (the Wipe hook). Keeps the keys that must never go back (uids, handled purchases,
-- transfer notes, version); every key is re-sent.
function Session.wipe(player: Player)
	local p = profiles[player]
	if not p then
		return
	end
	local f = Schema.fresh()
	f.nextUid, f.purchases, f.transferNote = p.nextUid, Schema.copy(p.purchases), Schema.copy(p.transferNote)
	f.carry = nil
	local force = {}
	for k in pairs(f) do
		table.insert(force, k)
	end
	table.insert(force, "carry")
	apply(player, function(q)
		for k in pairs(q) do
			q[k] = nil
		end
		for k, v in pairs(f) do
			q[k] = v
		end
	end, ALL, force)
	sendAll(player)
end

function Session.plot(player: Player): Model?
	return plots[player]
end

function Session.isSaving(player: Player): boolean
	local S = sessions[player]
	return S ~= nil and S.state == "live" and S.saving and not S.leaving
end

-- "loading" | "live" | "temp" | "lost" | nil (for checks and the HUD's saving state).
function Session.state(player: Player): string?
	local S = sessions[player]
	return S and S.state
end

function Session.onLeaving(fn: (Player) -> ())
	table.insert(leavingFns, fn)
end

function Session.onJoin(fn: (Player) -> ())
	table.insert(joinFns, fn)
	for pl, S in pairs(sessions) do
		if profiles[pl] and not S.standIn then
			task.spawn(fn, pl)
		end
	end
end

-- Saving --------------------------------------------------------------------------------------------------------------

local function acquire(S: Sess)
	while S.busy do
		table.insert(S.waiters, coroutine.running())
		coroutine.yield()
	end
	S.busy = true
end

local function release(S: Sess)
	S.busy = false
	local nxt = table.remove(S.waiters, 1)
	if nxt then
		task.defer(nxt)
	end
end

local function lostLock(S: Sess, why: string)
	if S.saving then
		S.saving = false
		S.state = "lost"
		S.why = why
		warn(("[HFB] Session: %d stops saving (%s)"):format(S.userId, why))
		notice(S.player, "notSaving")
		sendChanged(S.player, { saving = false })
	end
end

-- opts: { reason, release?, purchase? = { id, grant } }. Returns (ok, status).
local function save(player: any, opts: { [string]: any }): (boolean, string)
	local S = sessions[player]
	if not S or not profiles[player] then
		return false, "noProfile"
	end
	if not S.saving then
		return false, "notSaving"
	end
	acquire(S)
	local result: { any } = {}
	local okBody, errBody = pcall(function()
		if not S.saving or sessions[player] ~= S then
			result = { false, "notSaving" }
			return
		end
		local p = profiles[player]
		local snap = Transfer.outgoingSnapshot(player)
		local rec = Schema.toRecord(p, Transfer.excludeFor(player))
		local landed = Transfer.landedSnapshot(player, rec)
		local valid, why = Schema.validate(rec)
		if not valid then
			warn("[HFB] Session.save: record invalid, not written: " .. tostring(why))
			result = { false, "invalid" }
			return
		end
		local purchase = opts.purchase
		if purchase and table.find(p.purchases, purchase.id) then
			result = { true, "liveAlready" }
			return
		end
		local status = "error"
		local userId = S.userId
		local function transform(old: any): (any, any)
			status = "error"
			if old ~= nil then
				if type(old) ~= "table" then
					status = "corrupt"
					return nil
				end
				if (tonumber(old.version) or 1) > Schema.VERSION then
					status = "newer"
					return nil
				end
				local lk = old.lock
				if type(lk) ~= "table" or lk.server ~= SERVER_ID then
					status = "lockLost"
					return nil
				end
			end
			local out = Schema.copy(rec)
			if purchase then
				if old ~= nil and type(old.purchases) == "table" and table.find(old.purchases, purchase.id) then
					status = "alreadyInRecord" -- a retried call had committed it
					return nil
				end
				local okG, errG = pcall(purchase.grant, out)
				if not okG then
					warn("[HFB] Session.recordPurchase: grant errored: " .. tostring(errG))
					status = "grantError"
					return nil
				end
				if out.boughtCash > out.cash then
					out.boughtCash = out.cash
				end
				table.insert(out.purchases, purchase.id)
				while #out.purchases > Config.Data.PURCHASES_KEPT do
					table.remove(out.purchases, 1)
				end
				local okV, whyV = Schema.validate(out)
				if not okV then
					warn("[HFB] Session.recordPurchase: granted record invalid: " .. tostring(whyV))
					status = "invalid"
					return nil
				end
			end
			if not opts.release then
				out.lock = { server = SERVER_ID, stamp = os.time() }
			end
			status = "ok"
			if userId > 0 then
				return out, { userId }
			end
			return out
		end
		local okW, errW = S.store:update(S.key, transform)
		if not okW then
			warn(("[HFB] Session.save %d (%s) failed: %s"):format(userId, tostring(opts.reason), tostring(errW)))
			result = { false, "error" }
			return
		end
		if status == "ok" or status == "alreadyInRecord" then
			S.lastSave = os.clock()
			if purchase then
				-- The record holds the grant: the live profile gets it now, before the next write builds its record.
				local applied = apply(player, function(q)
					purchase.grant(q)
					table.insert(q.purchases, purchase.id)
					while #q.purchases > Config.Data.PURCHASES_KEPT do
						table.remove(q.purchases, 1)
					end
				end, ALL)
				if not applied then
					warn(("[HFB] Session.recordPurchase: %s saved but not applied live; keeping the id"):format(purchase.id))
					apply(player, function(q)
						table.insert(q.purchases, purchase.id)
					end, ALL)
				end
			end
			Transfer.onSaved(player, snap, tostring(opts.reason))
			Transfer.onLanded(player, landed)
			result = { true, status }
			return
		end
		if status == "lockLost" or status == "newer" or status == "corrupt" then
			lostLock(S, status)
		end
		result = { false, status }
	end)
	release(S)
	if not okBody then
		warn("[HFB] Session.save errored: " .. tostring(errBody))
		return false, "error"
	end
	return result[1] :: boolean, result[2] :: string
end

function Session.save(player: Player, reason: string?): (boolean, string?)
	return save(player, { reason = reason or "manual" })
end

-- Loading -------------------------------------------------------------------------------------------------------------

-- One load attempt on (store, key) as server `sid`. Returns (status, record-without-lock?). Writes only on "ok"
-- (taking the lock); a locked, newer, corrupt, invalid or unmigratable record is never written over.
local function hasUid(r: any, uid: string): boolean
	for _, list in ipairs({ r.bosses or {}, r.crate or {} }) do
		for _, b in ipairs(list) do
			if b.uid == uid then
				return true
			end
		end
	end
	return false
end

-- For each "left" note that still carries its boss: "drop" (the thief's record has it, or notes its arrival from
-- this user), "restore" (it is not there and that record is not held by a live session: the thief's write never
-- happened), or nil (undecided: the thief's session is live or its record could not be read; asked again next load).
local function resolveNotes(cur: any, userId: number): { [string]: string }
	local out = {}
	if type(cur) ~= "table" or type(cur.transferNote) ~= "table" then
		return out
	end
	for _, n in ipairs(cur.transferNote) do
		if type(n) == "table" and n.to ~= nil and type(n.entry) == "table" and typeof(n.uid) == "string" then
			local thiefId = tonumber(n.to)
			if type(n.at) == "number" and os.time() - n.at >= Config.Data.ARRIVAL_KEEP_S then
				out[n.uid] = "drop" -- older than the arrival evidence is kept: never restored blind (M2-27 MF1)
			elseif thiefId and (thiefId > 0 or RunService:IsStudio()) then
				local okT, tr = Store.forUser(thiefId):read(Store.key(thiefId))
				if okT then
					local arrived = false
					if type(tr) == "table" then
						arrived = hasUid(tr, n.uid)
						for _, m in ipairs(tr.transferNote or {}) do
							if type(m) == "table" and m.uid == n.uid and m.from == userId then
								arrived = true
							end
						end
					end
					-- Only the server that made the move can still write it: a live lock from any other server
					-- loaded the thief's record without the boss, so it can never write it.
					local lk = type(tr) == "table" and tr.lock or nil
					local live = type(lk) == "table" and lk.server == n.server and os.time() - (tonumber(lk.stamp) or 0) < Config.Data.LOCK_LEASE_S
					if arrived then
						out[n.uid] = "drop"
					elseif not live then
						out[n.uid] = "restore"
					end
				end
			end
		end
	end
	return out
end

local function loadOnce(store: any, key: string, userId: number, sid: string, lease: number?): (string, any)
	local status, loaded = "error", nil
	local leaseS = lease or Config.Data.LOCK_LEASE_S
	-- Notes that carry a boss are resolved from the thief's record, read before the write (a transform cannot yield).
	local okC, cur = store:read(key)
	if not okC then
		warn(("[HFB] Session.load %d failed: %s"):format(userId, tostring(cur)))
		return "error", nil
	end
	local resolve = resolveNotes(cur, userId)
	local function transform(old: any): (any, any)
		status, loaded = "error", nil
		local rec
		if old == nil then
			rec = Schema.fresh()
		else
			if type(old) ~= "table" then
				status = "corrupt"
				return nil
			end
			if (tonumber(old.version) or 1) > Schema.VERSION then
				status = "newer"
				return nil
			end
			local lk = old.lock
			if type(lk) == "table" and lk.server ~= sid and os.time() - (tonumber(lk.stamp) or 0) < leaseS then
				status = "locked"
				return nil
			end
			local okM, r = pcall(Migrations.run, Schema.copy(old), Schema.VERSION)
			if not okM then
				warn("[HFB] Session.load: migration failed: " .. tostring(r))
				status = "migrate"
				return nil
			end
			rec = Schema.reconcile(r)
			if type(rec.transferNote) == "table" then
				for i = #rec.transferNote, 1, -1 do
					local n = rec.transferNote[i]
					local act = type(n) == "table" and n.entry ~= nil and resolve[n.uid] or nil
					if act == "drop" then
						n.entry = nil -- resolved: a plain "left" note from here on
					elseif act == "restore" then
						table.remove(rec.transferNote, i)
						if type(rec.crate) == "table" and not hasUid(rec, n.uid) then
							table.insert(rec.crate, { uid = n.entry.uid, creatureId = n.entry.creatureId, level = n.entry.level, bought = n.entry.bought })
						end
					end
				end
			end
			Schema.dropNoted(rec)
		end
		rec.lock = nil
		local okV, why = Schema.validate(rec)
		if not okV then
			warn("[HFB] Session.load: stored record invalid, kept as is: " .. tostring(why))
			status = "invalid"
			return nil
		end
		loaded = Schema.copy(rec)
		rec.lock = { server = sid, stamp = os.time() }
		status = "ok"
		if userId > 0 then
			return rec, { userId }
		end
		return rec
	end
	local okW, err = store:update(key, transform)
	if not okW then
		warn(("[HFB] Session.load %d failed: %s"):format(userId, tostring(err)))
		return "error", nil
	end
	return status, loaded
end

local NO_RETRY = { newer = true, corrupt = true, invalid = true, migrate = true }

local function runJoinFns(player: any)
	for _, fn in ipairs(joinFns) do
		task.spawn(fn, player)
	end
end

local function install(S: Sess, prof: any)
	prof.spots = Schema.spotsFrom(prof.bosses)
	prof.carry = nil
	profiles[S.player] = prof
	S.profile = prof
end

-- Background retry for a temp profile (M2-02 S2): swaps the real profile in when the lock frees.
local function retryInBackground(S: Sess)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < Config.Data.BG_RETRY_FOR_S do
			task.wait(Config.Data.BG_RETRY_S)
			if sessions[S.player] ~= S or S.leaving or S.state ~= "temp" then
				return
			end
			local status, rec = loadOnce(S.store, S.key, S.userId, SERVER_ID)
			if status == "ok" and sessions[S.player] == S and not S.leaving and S.state == "temp" then
				rec.spots = Schema.spotsFrom(rec.bosses)
				rec.carry = nil
				S.state, S.saving, S.lastSave = "live", true, os.clock()
				local force = {}
				for k in pairs(rec) do
					table.insert(force, k)
				end
				commit(S.player, rec, force)
				sendAll(S.player)
				print(("[HFB] Session: %d real profile loaded after a temp profile"):format(S.userId))
				return
			elseif status == "ok" then
				-- took the lock but the session moved on: let it go again
				S.store:update(S.key, function(old)
					if type(old) == "table" and type(old.lock) == "table" and old.lock.server == SERVER_ID then
						old.lock = nil
						return old
					end
					return nil
				end)
				return
			elseif NO_RETRY[status] then
				return
			end
		end
	end)
end

-- Loads (or makes) the session for a player or stand-in. Yields.
local function join(player: any, standIn: boolean)
	if sessions[player] then
		return
	end
	local userId = player.UserId
	local S: Sess = {
		player = player,
		userId = userId,
		key = Store.key(userId),
		store = Store.forUser(userId),
		state = "loading",
		saving = false,
		leaving = false,
		standIn = standIn,
		profile = nil,
		lastSave = os.clock(),
		busy = false,
		waiters = {},
		pendingHooks = {},
		why = nil,
	}
	sessions[player] = S
	local status, rec = "off", nil
	if TestHooks.get("SaveOff") == true then
		status = "off"
	else
		-- Studio only: a play session's first load takes a lock left by an earlier play session on this machine
		-- (a stopped test that never released it); checks set STUDIO_TAKE_LOCK_ON_JOIN = false to test real locks.
		local lease = nil
		if RunService:IsStudio() and Config.Data.STUDIO_TAKE_LOCK_ON_JOIN and not standIn then
			lease = 0
		end
		for i = 1, Config.Data.LOAD_TRIES do
			status, rec = loadOnce(S.store, S.key, userId, SERVER_ID, lease)
			if status == "ok" or NO_RETRY[status] or sessions[player] ~= S or S.leaving then
				break
			end
			if i < Config.Data.LOAD_TRIES then
				task.wait(Config.Data.LOAD_GAP_S)
			end
		end
	end
	if status == "ok" then
		install(S, rec)
		S.state, S.saving = "live", true
	else
		install(S, Schema.fresh())
		S.state, S.saving, S.why = "temp", false, status
		if status ~= "off" then
			warn(("[HFB] Session: %d gets a temp profile (%s); nothing is saved"):format(userId, status))
			notice(player, "notSaving")
			if status == "locked" or status == "error" then
				retryInBackground(S)
			end
		end
	end
	S.lastSave = os.clock()
	sendAll(player)
	for _, fn in ipairs(S.pendingHooks) do
		task.spawn(fn, player)
	end
	S.pendingHooks = {}
	if not standIn and S.leaving == false then
		runJoinFns(player)
	end
end

-- Leaving -------------------------------------------------------------------------------------------------------------

-- The leave path: counted in flight from its first line (the shutdown wait sees it even while it waits behind a
-- running save), decremented on every return. Returns the final write's status.
local function leave(player: any, reason: string): string
	inflight += 1
	local status = "none"
	local ok, err = pcall(function()
		local S = sessions[player]
		if not S then
			return
		end
		if S.leaving then
			local t0 = os.clock()
			while sessions[player] == S and os.clock() - t0 < Config.Data.SHUTDOWN_BUDGET_S do
				task.wait(0.1)
			end
			-- PlayerRemoving's leave and BindToClose's both reach here on a Studio stop (no order is documented):
			-- report the leave that ran, not "already" (which the shutdown count read as a failure).
			status = S.finalStatus or "already"
			return
		end
		S.leaving = true
		local t0 = os.clock()
		while S.state == "loading" and os.clock() - t0 < 30 do
			task.wait(0.1)
		end
		for _, fn in ipairs(leavingFns) do
			local okF, errF = pcall(fn, player)
			if not okF then
				warn("[HFB] Session.onLeaving fn errored: " .. tostring(errF))
			end
		end
		Transfer.beforeFinal(player)
		if profiles[player] then
			apply(player, function(q)
				q.leftAt = math.max(0, workspace:GetServerTimeNow())
			end, ALL)
		end
		if S.saving then
			local okS, st = save(player, { reason = reason, release = true })
			status = if okS then "saved" else ("failed:" .. tostring(st))
		else
			status = "notSaving:" .. tostring(S.state)
		end
		S.finalStatus = status
		Transfer.forget(player)
		sessions[player] = nil
		profiles[player] = nil
	end)
	inflight -= 1
	if not ok then
		warn("[HFB] Session leave errored: " .. tostring(err))
		status = "error"
	end
	return status
end

-- Every session's leave in parallel; waits for every leave in flight (also ones PlayerRemoving started) up to the
-- budget. Returns { players, saved, failed, seconds, left }.
local function shutdownAll(): { [string]: any }
	local t0 = os.clock()
	local results: { [string]: string } = {}
	local n = 0
	for pl, S in pairs(sessions) do
		n += 1
		task.spawn(function()
			results[tostring(S.userId)] = leave(pl, "shutdown")
		end)
	end
	task.wait()
	while inflight > 0 and os.clock() - t0 < Config.Data.SHUTDOWN_BUDGET_S do
		task.wait(0.1)
	end
	local saved, failed = 0, 0
	for _, st in pairs(results) do
		if st == "saved" then
			saved += 1
		else
			failed += 1
		end
	end
	return { players = n, saved = saved, failed = failed, seconds = os.clock() - t0, left = inflight, results = results }
end

-- Transfer and purchases ----------------------------------------------------------------------------------------------

local core = {}
core.serverId = SERVER_ID
function core.isLive(player: any): boolean
	local S = sessions[player]
	return S ~= nil and S.state == "live" and S.saving and not S.leaving and profiles[player] ~= nil
end
function core.isPresent(player: any): boolean
	return profiles[player] ~= nil
end
function core.profile(player: any): any
	return profiles[player]
end
core.save = save
function core.applyOne(player: any, fn: (any) -> ()): boolean
	return apply(player, fn, ALL)
end
-- Validates both candidates first, then applies both (no yield in between).
function core.applyPair(a: any, na: any, b: any, nb: any): boolean
	local pa, pb = profiles[a], profiles[b]
	if not pa or not pb then
		return false
	end
	local okA, whyA = prepare(pa, na, ALL)
	local okB, whyB = prepare(pb, nb, ALL)
	if not okA or not okB then
		warn("[HFB] Session.transfer refused: " .. tostring(whyA or whyB))
		return false
	end
	commit(a, na)
	commit(b, nb)
	return true
end
Transfer.init(core)
Purchases.init(core)

function Session.transfer(uid: string, fromPlayer: Player, toPlayer: Player, place: (Profile, any) -> ()): boolean
	return Transfer.transfer(uid, fromPlayer, toPlayer, place :: any)
end

function Session.recordPurchase(player: Player, purchaseId: string, grant: (Profile) -> ()): string
	return Purchases.record(player, purchaseId, grant :: any)
end

-- Stand-in second player (Studio only; M2-02 S9): user id <= 0, memory store only, never a DataStore.
function Session.standIn(userId: number): any
	assert(RunService:IsStudio(), "Session.standIn is Studio only")
	assert(Net.isInt(userId) and userId <= 0, "Session.standIn: user id must be <= 0")
	local fake = { UserId = userId, Name = "StandIn" .. tostring(-userId), Parent = nil }
	join(fake, true)
	return fake
end
function Session.removeStandIn(fake: any): string
	assert(RunService:IsStudio(), "Session.removeStandIn is Studio only")
	return leave(fake, "standInLeave")
end

-- Plot and spawn (M1, unchanged) --------------------------------------------------------------------------------------

local function assignPlot(player: Player)
	local root = workspace:FindFirstChild("Plots")
	if not root then
		warn("[HFB] Session: Workspace.Plots missing; no plot for " .. player.Name)
		return
	end
	local list = {}
	for _, m in ipairs(root:GetChildren()) do
		if m:IsA("Model") and typeof(m:GetAttribute("PlotId")) == "number" then
			table.insert(list, m)
		end
	end
	table.sort(list, function(a, b)
		return (a:GetAttribute("PlotId") :: number) < (b:GetAttribute("PlotId") :: number)
	end)
	-- Fill order 1, 8, 4, 5, 2, 7, 3, 6 (Systems/Plots.pick, M2-15); lowest free id if Plots is not there.
	local okP, PlotsMod = pcall(require, game:GetService("ServerScriptService").Systems.Plots)
	local pick = okP and type(PlotsMod) == "table" and PlotsMod.pick and PlotsMod.pick(list) or nil
	for _, m in ipairs(if pick then { pick } else list) do
		if (m:GetAttribute("OwnerUserId") or 0) == 0 then
			m:SetAttribute("OwnerUserId", player.UserId)
			plots[player] = m :: Model
			return
		end
	end
	warn("[HFB] Session: no free plot for " .. player.Name)
end

local function toSpawn(player: Player, character: Model)
	local plot = plots[player]
	local sp = plot and plot:FindFirstChild("SpawnPoint")
	if not (sp and sp:IsA("BasePart")) then
		return
	end
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	local hum = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hrp or not hum or character.Parent == nil then
		return
	end
	local lift = sp.Size.Y / 2 + hum.HipHeight + (hrp :: BasePart).Size.Y / 2
	if hum.RigType == Enum.HumanoidRigType.R6 then
		lift = sp.Size.Y / 2 + 3
	end
	task.defer(function()
		if character.Parent then
			character:PivotTo(sp.CFrame + Vector3.new(0, lift, 0))
		end
	end)
end

local function onPlayerAdded(player: Player)
	if sessions[player] or plots[player] then
		return
	end
	assignPlot(player)
	charConns[player] = player.CharacterAdded:Connect(function(c)
		toSpawn(player, c)
	end)
	if player.Character then
		toSpawn(player, player.Character)
	end
	join(player, false)
end

local function onPlayerRemoving(player: Player)
	leave(player, "leave")
	local plot = plots[player]
	if plot and plot:GetAttribute("OwnerUserId") == player.UserId then
		plot:SetAttribute("OwnerUserId", 0)
	end
	plots[player] = nil
	local c = charConns[player]
	if c then
		c:Disconnect()
	end
	charConns[player] = nil
end

-- Test hooks (Studio only) --------------------------------------------------------------------------------------------

-- Applies fn to every real player with a profile now, and to each still loading as soon as it loads.
local function forPlayers(fn: (any) -> ())
	for pl, S in pairs(sessions) do
		if not S.standIn then
			if profiles[pl] then
				task.spawn(fn, pl)
			elseif S.state == "loading" then
				table.insert(S.pendingHooks, fn)
			end
		end
	end
end

local function hookNumber(name: string, key: string, lo: number, hi: number, int: boolean)
	TestHooks.onSet(name, function(v)
		if not Net.isNumber(v, lo, hi) then
			warn(("[HFB] hook %s ignored: %s"):format(name, tostring(v)))
			return
		end
		local value = if int then math.floor(v) else v
		forPlayers(function(p)
			Session.set(p, key, value)
		end)
	end)
end

local function startHooks()
	hookNumber("SetPower", "power", 0, 1e15, false)
	hookNumber("SetCash", "cash", 0, 1e15, false)
	hookNumber("SetStrength", "strengthLevel", 1, Config.Bag.STRENGTH_MAX, true)
	hookNumber("SetSpeed", "speedLevel", 1, Config.Bag.SPEED_MAX, true)
	TestHooks.onSet("SetBoughtCash", function(v)
		if not Net.isNumber(v, 0, 1e15) then
			return
		end
		forPlayers(function(p)
			apply(p, function(q)
				q.boughtCash = v
				q.cash = math.max(q.cash, v)
			end, ALL)
		end)
	end)
	TestHooks.onSet("Wipe", function(v)
		if v == true then
			forPlayers(function(p)
				Session.wipe(p)
			end)
		end
	end)
	TestHooks.onSet("ForceSave", function(v)
		if v ~= true then
			return
		end
		forPlayers(function(p)
			local ok, st = Session.save(p, "hook")
			TestHooks.reports.save = { userId = p.UserId, ok = ok, status = st, at = os.clock() }
		end)
	end)
	TestHooks.onSet("Leave", function(v)
		if v ~= true then
			return
		end
		for _, p in ipairs(Players:GetPlayers()) do
			task.spawn(function()
				TestHooks.reports.leave = { userId = p.UserId, status = leave(p, "hook"), at = os.clock() }
			end)
		end
	end)
	TestHooks.onSet("Rejoin", function(v)
		if v ~= true then
			return
		end
		for _, p in ipairs(Players:GetPlayers()) do
			if not sessions[p] then
				task.spawn(function()
					join(p, false)
					TestHooks.reports.rejoin = { userId = p.UserId, state = Session.state(p), at = os.clock() }
				end)
			end
		end
	end)
	TestHooks.onSet("Shutdown", function(v)
		if v == true then
			task.spawn(function()
				TestHooks.reports.shutdown = shutdownAll()
			end)
		end
	end)
end

-- Studio only (nil on a live server): replaces zonesBeaten with `list` (ints 1..6) for the SetZonesBeaten hook
-- (M2-10), which otherwise could only add zones through addZoneBeaten. Returns false if the list is invalid.
Session.setZonesBeatenForTest = nil :: any
if RunService:IsStudio() then
	Session.setZonesBeatenForTest = function(player: Player, list: { number }): boolean
		if type(list) ~= "table" then
			return false
		end
		local zs = {}
		for _, z in ipairs(list) do
			if not Net.isInt(z, 1, Config.Data.LIMITS.zones) then
				return false
			end
			if not table.find(zs, z) then
				table.insert(zs, z)
			end
		end
		table.sort(zs)
		return apply(player, function(q)
			q.zonesBeaten = zs
		end, { zonesBeaten = true })
	end
end

-- Studio-only helpers for studio/checks/Saving.lua (raw records in the CURRENT store, a second server's load).
Session._test = nil :: any
if RunService:IsStudio() then
	local T = {}
	T.leave = leave
	T.join = function(p)
		join(p, false)
	end
	T.shutdown = shutdownAll
	T.inflight = function()
		return inflight
	end
	T.serverId = SERVER_ID
	T.store = Store
	T.schema = Schema
	T.migrations = Migrations
	T.transfer = Transfer
	-- A load as another server (a second session): status, and the record only if it took the lock.
	T.tryLoad = function(userId: number, sid: string)
		return loadOnce(Store.forUser(userId), Store.key(userId), userId, sid)
	end
	T.rawRead = function(userId: number)
		assert(Config.Env == "Studio")
		return Store.forUser(userId):read(Store.key(userId))
	end
	T.rawWrite = function(userId: number, rec: any)
		assert(Config.Env == "Studio" and Config.Data.STORE_BASE ~= "Players", "rawWrite only into a check store")
		return Store.forUser(userId):update(Store.key(userId), function()
			return rec
		end)
	end
	T.rawRemove = function(userId: number)
		assert(Config.Env == "Studio" and Config.Data.STORE_BASE ~= "Players", "rawRemove only in a check store")
		return Store.forUser(userId):remove(Store.key(userId))
	end
	-- A crash: the sessions vanish with no write and no release (locks stay as last written).
	-- The check then goes on as a NEW server (a fresh lock id), as a restarted game would.
	T.crash = function(list: { any })
		for _, p in ipairs(list) do
			Transfer.crashReset(p)
			sessions[p] = nil
			profiles[p] = nil
		end
		SERVER_ID = HttpService:GenerateGUID(false)
		Session.SERVER_ID = SERVER_ID
		core.serverId = SERVER_ID
		T.serverId = SERVER_ID
	end
	T.session = function(p)
		return sessions[p]
	end
	Session._test = T
end

-- Start ---------------------------------------------------------------------------------------------------------------

local started = false
function Session.start()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, p)
	end
	game:BindToClose(function()
		local r = shutdownAll()
		local parts = {}
		for id, st in pairs(r.results) do
			table.insert(parts, id .. "=" .. st)
		end
		print(("[HFB] Session shutdown: %d players, %d saved, %d failed, %.1f s (%s)"):format(r.players, r.saved, r.failed, r.seconds, table.concat(parts, " ")))
	end)
	-- Autosave (B9): each live profile every AUTOSAVE_S, which also renews the lock.
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for pl, S in pairs(sessions) do
				if S.state == "live" and S.saving and not S.leaving and not S.busy and now - S.lastSave >= Config.Data.AUTOSAVE_S then
					S.lastSave = now
					task.spawn(save, pl, { reason = "auto" })
				end
			end
		end
	end)
	-- Profile.Settings (contract C): each 0..1, rounded to 0.05; one mutate.
	Net.onServerEvent("Profile", "Settings", function(player: Player, p: any)
		if not Net.isNumber(p.music, 0, 1) or not Net.isNumber(p.effects, 0, 1) then
			return
		end
		local m = math.floor(p.music / 0.05 + 0.5) * 0.05
		local e = math.floor(p.effects / 0.05 + 0.5) * 0.05
		apply(player, function(q)
			q.settings = { music = math.clamp(m, 0, 1), effects = math.clamp(e, 0, 1) }
		end, {})
	end)
	startHooks()
end

return Session
