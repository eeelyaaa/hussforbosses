--!strict
-- Data/Schema: the saved record, version 1 (m2-contract.md section D). Pure: no services, no yields.
-- The runtime profile is the record minus `lock`, plus two runtime-only keys the M1 systems use (`carry`, `spots`),
-- which are never saved. Content is saved by id only (creature ids `z<zone>_t<tier>`, uids, purchase ids).
--
-- Schema.VERSION / Schema.DEFAULTS are read at call time, so the migration check can stand in a v2 at runtime.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Ids = require(Shared.Ids)

local Schema = {}

Schema.VERSION = 1

-- Every saved key and its default (deep-copied per profile; never share a nested default).
Schema.DEFAULTS = {
	version = 1,
	power = 0,
	cash = 0,
	boughtCash = 0,
	strengthLevel = 1,
	speedLevel = 1,
	rebirths = 0,
	bosses = {}, -- { uid, creatureId, level, spot, padCash, padStamp, bought? }
	crate = {}, -- { uid, creatureId, level, bought? }
	zonesBeaten = {},
	spinTickets = 0,
	breakerCharges = 0,
	starterPackGiven = false,
	purchases = {},
	transferNote = {}, -- { uid, to }
	nextUid = 1,
	leftAt = 0,
	shieldReadyAt = 0,
	flags = {},
	settings = { music = 1, effects = 1 },
} :: { [string]: any }

-- Written only by the API that owns them (M2-02 M1). `bought` (on a boss) is checked separately.
Schema.PROTECTED = {
	version = true,
	boughtCash = true,
	zonesBeaten = true,
	purchases = true,
	nextUid = true,
	transferNote = true,
	starterPackGiven = true,
	lock = true,
}

-- Sent to the owner in Profile.Changed (the keys named in Net's Profile.Changed payload).
Schema.PUBLIC = {
	power = true,
	cash = true,
	boughtCash = true,
	strengthLevel = true,
	speedLevel = true,
	rebirths = true,
	spinTickets = true,
	breakerCharges = true,
	zonesBeaten = true,
	flags = true,
	settings = true,
}

-- Runtime-only keys (never saved, never validated as schema).
Schema.RUNTIME = { carry = true, spots = true }

function Schema.copy(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local t = {}
	for k, x in pairs(v) do
		t[k] = Schema.copy(x)
	end
	return t
end

function Schema.equal(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for k, x in pairs(a) do
		if not Schema.equal(x, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

function Schema.fresh(): { [string]: any }
	local r = Schema.copy(Schema.DEFAULTS)
	r.power = Config.Bag.START_POWER
	r.strengthLevel = Config.Bag.DEFAULT_STRENGTH
	r.speedLevel = Config.Bag.DEFAULT_SPEED
	r.version = Schema.VERSION
	return r
end

-- Fills missing keys from DEFAULTS and drops keys the schema does not have (runtime keys and lock excepted).
function Schema.reconcile(r: { [string]: any }): { [string]: any }
	for k, d in pairs(Schema.DEFAULTS) do
		if r[k] == nil then
			r[k] = Schema.copy(d)
		end
	end
	if type(r.settings) == "table" then
		for k, d in pairs(Schema.DEFAULTS.settings) do
			if r.settings[k] == nil then
				r.settings[k] = d
			end
		end
	end
	for k in pairs(r) do
		if Schema.DEFAULTS[k] == nil and k ~= "lock" and not Schema.RUNTIME[k] then
			r[k] = nil
		end
	end
	return r
end

local function finite(x: any): boolean
	return type(x) == "number" and x == x and math.abs(x) ~= math.huge
end
local function num(x: any, lo: number, hi: number?): boolean
	return finite(x) and x >= lo and (hi == nil or x <= hi)
end
local function int(x: any, lo: number, hi: number?): boolean
	return num(x, lo, hi) and x % 1 == 0
end
local function str(x: any, max: number): boolean
	return type(x) == "string" and #x > 0 and #x <= max and utf8.len(x) ~= nil
end

local function boughtOk(b: any): boolean
	if b == nil then
		return true
	end
	return type(b) == "table" and table.find(Ids.BOUGHT_SOURCES, b.source) ~= nil and int(b.buyer, -1e12, 1e15)
end

-- Validates a profile or record against the schema. Returns (true) or (false, reason). Only DEFAULTS keys are checked
-- by rule; the migration check's stand-in v2 keys pass if they are plain finite values.
function Schema.validate(r: any): (boolean, string?)
	if type(r) ~= "table" then
		return false, "not a table"
	end
	local L = Config.Data.LIMITS
	if not int(r.version, 1) then
		return false, "version"
	end
	for _, k in ipairs({ "power", "cash", "boughtCash" }) do
		if not num(r[k], 0) then
			return false, k
		end
	end
	if not int(r.strengthLevel, 1, Config.Bag.STRENGTH_MAX) then
		return false, "strengthLevel"
	end
	if not int(r.speedLevel, 1, Config.Bag.SPEED_MAX) then
		return false, "speedLevel"
	end
	if not int(r.rebirths, 0, L.rebirthsMax) then
		return false, "rebirths"
	end
	if type(r.bosses) ~= "table" or type(r.crate) ~= "table" then
		return false, "bosses/crate"
	end
	local uids, spots = {}, {}
	for i, b in ipairs(r.bosses) do
		if type(b) ~= "table" or not str(b.uid, 40) or Ids.parseCreature(b.creatureId) == nil then
			return false, "bosses[" .. i .. "]"
		end
		if not int(b.level, 1, L.bossLevelMax) or not int(b.spot, 1, L.spots) then
			return false, "bosses[" .. i .. "].level/spot"
		end
		if not num(b.padCash, 0) or not num(b.padStamp, 0) or not boughtOk(b.bought) then
			return false, "bosses[" .. i .. "].pad/bought"
		end
		if uids[b.uid] or spots[b.spot] then
			return false, "bosses[" .. i .. "] duplicate uid or spot"
		end
		uids[b.uid] = true
		spots[b.spot] = true
	end
	for _, list in ipairs({ r.bosses, r.crate, r.zonesBeaten }) do
		local n = 0
		for _ in pairs(list) do
			n += 1
		end
		if n ~= #list then
			return false, "a list is not an array"
		end
	end
	for i, b in ipairs(r.crate) do
		if type(b) ~= "table" or not str(b.uid, 40) or Ids.parseCreature(b.creatureId) == nil then
			return false, "crate[" .. i .. "]"
		end
		if not int(b.level, 1, L.bossLevelMax) or not boughtOk(b.bought) then
			return false, "crate[" .. i .. "].level/bought"
		end
		if uids[b.uid] then
			return false, "crate[" .. i .. "] duplicate uid"
		end
		uids[b.uid] = true
	end
	if type(r.zonesBeaten) ~= "table" then
		return false, "zonesBeaten"
	end
	local seenZ = {}
	for _, z in ipairs(r.zonesBeaten) do
		if not int(z, 1, L.zones) or seenZ[z] then
			return false, "zonesBeaten"
		end
		seenZ[z] = true
	end
	if not int(r.spinTickets, 0) or not int(r.breakerCharges, 0) then
		return false, "tickets/charges"
	end
	if type(r.starterPackGiven) ~= "boolean" then
		return false, "starterPackGiven"
	end
	if type(r.purchases) ~= "table" then
		return false, "purchases"
	end
	for _, id in ipairs(r.purchases) do
		if not str(id, 100) then
			return false, "purchases"
		end
	end
	if type(r.transferNote) ~= "table" then
		return false, "transferNote"
	end
	-- { uid, to, entry? } = this boss left to user `to` (entry: the boss as it left, until the load resolves it);
	-- { uid, from } = this boss arrived from user `from` (the owner's load reads it to know the move landed).
	for _, n in ipairs(r.transferNote) do
		if type(n) ~= "table" or not str(n.uid, 40) then
			return false, "transferNote"
		end
		local hasTo, hasFrom = int(n.to, -1e12, 1e15), int(n.from, -1e12, 1e15)
		if hasTo == hasFrom then
			return false, "transferNote to/from"
		end
		if n.at ~= nil and not num(n.at, 0) then
			return false, "transferNote at"
		end
		if n.server ~= nil and not str(n.server, 64) then
			return false, "transferNote server"
		end
		local e = n.entry
		if e ~= nil and (not hasTo or type(e) ~= "table" or e.uid ~= n.uid or Ids.parseCreature(e.creatureId) == nil or not int(e.level, 1, L.bossLevelMax) or not boughtOk(e.bought)) then
			return false, "transferNote entry"
		end
	end
	if not int(r.nextUid, 1) then
		return false, "nextUid"
	end
	if r.leftAt ~= nil and not num(r.leftAt, 0) then
		return false, "leftAt"
	end
	if not num(r.shieldReadyAt, 0) then
		return false, "shieldReadyAt"
	end
	if type(r.flags) ~= "table" then
		return false, "flags"
	end
	for k, v in pairs(r.flags) do
		if not str(k, 40) or v ~= true then
			return false, "flags"
		end
	end
	local s = r.settings
	if type(s) ~= "table" or not num(s.music, 0, 1) or not num(s.effects, 0, 1) then
		return false, "settings"
	end
	-- Keys outside the v1 rules (a stand-in newer version in the migration check): plain finite values only.
	for k, v in pairs(r) do
		if type(v) == "number" and not finite(v) then
			return false, tostring(k)
		end
	end
	return true
end

-- The record to write: a deep copy of the profile's saved keys, lists trimmed, `exclude` uids left out
-- (M2-02 M6: a stolen boss whose owner's write has not succeeded yet).
function Schema.toRecord(p: { [string]: any }, exclude: { [string]: any }?): { [string]: any }
	local r = {}
	for k in pairs(Schema.DEFAULTS) do
		r[k] = Schema.copy(p[k])
	end
	if exclude and next(exclude) then
		for _, list in ipairs({ r.bosses, r.crate }) do
			for i = #list, 1, -1 do
				if exclude[list[i].uid] then
					table.remove(list, i)
				end
			end
		end
		-- the arrival note goes out with the boss, never before it
		for i = #r.transferNote, 1, -1 do
			local n = r.transferNote[i]
			if n.from ~= nil and exclude[n.uid] then
				table.remove(r.transferNote, i)
			end
		end
	end
	local P, N = Config.Data.PURCHASES_KEPT, Config.Data.TRANSFER_NOTES_KEPT
	while #r.purchases > P do
		table.remove(r.purchases, 1)
	end
	Schema.trimNotes(r.transferNote, N)
	r.version = Schema.VERSION
	return r
end

-- Trims transfer notes (M2-27 MF1): resolved "left" notes (no entry) keep the newest `n`; a "left" note that still
-- carries its boss is never trimmed; arrival notes are kept by age (Config.Data.ARRIVAL_KEEP_S), with a safety cap.
function Schema.trimNotes(notes: { any }, n: number)
	local now = os.time()
	local keepS, cap = Config.Data.ARRIVAL_KEEP_S, Config.Data.ARRIVAL_MAX
	for i = #notes, 1, -1 do
		local x = notes[i]
		if x.from ~= nil and type(x.at) == "number" and now - x.at > keepS then
			table.remove(notes, i)
		end
	end
	local function trim(pred: (any) -> boolean, max: number)
		local count = 0
		for _, x in ipairs(notes) do
			if pred(x) then
				count += 1
			end
		end
		local i = 1
		while count > max and i <= #notes do
			if pred(notes[i]) then
				table.remove(notes, i)
				count -= 1
			else
				i += 1
			end
		end
	end
	trim(function(x)
		return x.to ~= nil and x.entry == nil
	end, n)
	trim(function(x)
		return x.from ~= nil
	end, cap)
end

-- Drops from bosses and crate every uid this record's own transferNote says has left (contract D).
function Schema.dropNoted(r: { [string]: any })
	local gone = {}
	for _, n in ipairs(r.transferNote or {}) do
		if n.to ~= nil then
			gone[n.uid] = true
		end
	end
	if not next(gone) then
		return
	end
	for _, list in ipairs({ r.bosses or {}, r.crate or {} }) do
		for i = #list, 1, -1 do
			if gone[list[i].uid] then
				table.remove(list, i)
			end
		end
	end
end

-- M1 compat: the `spots` map the M1 systems read ({ [spot] = { uid, creatureId, level, stamp } }), from bosses.
function Schema.spotsFrom(bosses: { any }): { [number]: any }
	local m = {}
	for _, b in ipairs(bosses) do
		m[b.spot] = { uid = b.uid, creatureId = b.creatureId, level = b.level, stamp = b.padStamp }
	end
	return m
end

-- M1 compat: bosses from an M1 `spots` map, keeping padCash and the bought mark of uids already owned.
function Schema.bossesFromSpots(spots: { [number]: any }, old: { any }): { any }
	local byUid = {}
	for _, b in ipairs(old) do
		byUid[b.uid] = b
	end
	local out = {}
	for spot, s in pairs(spots) do
		local prev = byUid[s.uid]
		table.insert(out, {
			uid = s.uid,
			creatureId = s.creatureId,
			level = s.level,
			spot = spot,
			padCash = prev and prev.padCash or 0,
			padStamp = s.stamp or (prev and prev.padStamp) or 0,
			bought = prev and Schema.copy(prev.bought) or nil,
		})
	end
	table.sort(out, function(a, b)
		return a.spot < b.spot
	end)
	return out
end

-- Every boss entry by uid (bosses and crate) -> its bought mark (or false), for the protected-field check.
function Schema.marks(p: { [string]: any }): { [string]: any }
	local m = {}
	for _, list in ipairs({ p.bosses or {}, p.crate or {} }) do
		for _, b in ipairs(list) do
			m[b.uid] = b.bought or false
		end
	end
	return m
end

return Schema
