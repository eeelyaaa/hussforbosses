--!strict
-- Data/Transfer: the steal as one operation keyed by boss uid (m2-contract.md D "Transfer"; M2-02 M6).
--   1. In memory, in one step with no yield: the entry leaves the owner's profile (bosses or crate), the owner gets
--      `transferNote { uid, to }`, the caller's `place(thiefProfile, entry)` puts it in the thief's profile (if it
--      places nothing the boss goes to the thief's crate), and the thief's own note for that uid is removed (a boss
--      stolen back is never dropped by its old note). Both results are validated before either is applied.
--   2. The thief's profile marks the uid pending (from the owner). Every thief write leaves a pending uid out.
--   3. The owner's record is written first. When an owner write that carried the move succeeds, the mark clears
--      and the thief's record is written second. The SaveFailBetween hook errors between the two writes.
--   So after any sequence the uid is in exactly one record; a failure at worst leaves the boss with its owner.
-- If the thief leaves while a uid is still pending, the owner's write is tried once more; if that fails too and
-- the owner is still here, the boss goes back to the owner's profile (its old spot if free, else the crate).
-- Session wires this module in (Transfer.init(core)); callers use Session.transfer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local TestHooks = require(Shared.TestHooks)
local Schema = require(script.Parent.Schema)

local Transfer = {}

type Out = { thief: any, entry: any }
local core: any = nil
-- pendingIn[thief][uid] = owner (Player); outgoing[owner][uid] = { thief, entry }
local pendingIn: { [any]: { [string]: any } } = {}
-- awaiting[thief][uid] = owner: the thief's record has not yet been written WITH this boss (M2-27 MF1)
local awaiting: { [any]: { [string]: any } } = {}
local outgoing: { [any]: { [string]: Out } } = {}

function Transfer.init(c: any)
	core = c
end

-- The uids a player's writes must leave out (Session's save builds the record without them).
function Transfer.excludeFor(player: any): { [string]: any }
	local t = {}
	for uid in pairs(pendingIn[player] or {}) do
		t[uid] = true
	end
	return t
end

-- The owner's outgoing uids at the moment a record is built (cleared only by a write that carried them).
function Transfer.outgoingSnapshot(player: any): { [string]: any }
	local t = {}
	for uid, o in pairs(outgoing[player] or {}) do
		t[uid] = o.thief
	end
	return t
end

function Transfer.isPending(player: any, uid: string): boolean
	return pendingIn[player] ~= nil and pendingIn[player][uid] ~= nil
end

local function clear(owner: any, uid: string)
	local o = outgoing[owner] and outgoing[owner][uid]
	if o then
		outgoing[owner][uid] = nil
		if pendingIn[o.thief] then
			pendingIn[o.thief][uid] = nil
		end
	end
end

-- Session calls this after every successful write of `owner` (snap = Transfer.outgoingSnapshot before the write).
function Transfer.onSaved(owner: any, snap: { [string]: any }, reason: string)
	for uid, thief in pairs(snap) do
		local o = outgoing[owner] and outgoing[owner][uid]
		if o and o.thief == thief then
			clear(owner, uid)
			-- The transfer itself writes the thief next; any later owner write (autosave, leave) starts it here.
			if reason ~= "transfer" and core.isLive(thief) then
				task.spawn(core.save, thief, { reason = "transferDone" })
			end
		end
	end
end

-- Before a write: the awaited uids this record carries (pending ones are left out of it, so never counted).
function Transfer.landedSnapshot(player: any, rec: any): { [string]: any }
	local out = {}
	local aw = awaiting[player]
	if not aw then
		return out
	end
	for _, list in ipairs({ rec.bosses or {}, rec.crate or {} }) do
		for _, b in ipairs(list) do
			if aw[b.uid] then
				out[b.uid] = aw[b.uid]
			end
		end
	end
	return out
end

-- After that write succeeded: the boss has landed in the thief's record. Clear `entry` on the owner's live note so
-- the owner's next write records it as resolved (it can never be restored later), and write the owner.
function Transfer.onLanded(player: any, snap: { [string]: any })
	for uid, owner in pairs(snap) do
		if awaiting[player] then
			awaiting[player][uid] = nil
		end
		if core.profile(owner) then
			local okClear = core.applyOne(owner, function(p: any)
				for _, n in ipairs(p.transferNote) do
					if n.uid == uid and n.to == player.UserId and n.entry ~= nil then
						n.entry = nil
					end
				end
			end)
			if okClear and core.isLive(owner) then
				task.spawn(core.save, owner, { reason = "landed" })
			end
		end
	end
end

local function countUid(p: any, uid: string): number
	local n = 0
	for _, list in ipairs({ p.bosses, p.crate }) do
		for _, b in ipairs(list) do
			if b.uid == uid then
				n += 1
			end
		end
	end
	return n
end

local function takeOut(p: any, uid: string): any
	for _, list in ipairs({ p.bosses, p.crate }) do
		for i, b in ipairs(list) do
			if b.uid == uid then
				return table.remove(list, i)
			end
		end
	end
	return nil
end

-- Removes this profile's "left" notes for uid (a boss placed back into a profile is never dropped by its old note).
local function dropNote(p: any, uid: string)
	for i = #p.transferNote, 1, -1 do
		if p.transferNote[i].uid == uid and p.transferNote[i].to ~= nil then
			table.remove(p.transferNote, i)
		end
	end
end

-- Session.transfer(uid, fromPlayer, toPlayer, place) -> boolean. True once the in-memory move is applied (then
-- yields for the two writes); false with nothing changed when either profile is not live and saving, leaving, the
-- uid is not the owner's, it is still pending arrival in the owner's profile, or place/validation fails.
function Transfer.transfer(uid: string, from: any, to: any, place: (any, any) -> ()): boolean
	if typeof(uid) ~= "string" or from == to or not core.isLive(from) or not core.isLive(to) then
		return false
	end
	if Transfer.isPending(from, uid) then
		return false
	end
	local pf, pt = core.profile(from), core.profile(to)
	local nf, nt = Schema.copy(pf), Schema.copy(pt)
	local entry = takeOut(nf, uid)
	if not entry then
		return false
	end
	-- The owner's note carries the boss itself until a load resolves it (Session's load reads the thief's record:
	-- arrived there -> the note is dropped; not there and that record is not live -> the boss comes back). So a crash
	-- between the owner's write and the thief's never loses the boss.
	table.insert(nf.transferNote, { uid = uid, to = to.UserId, server = core.serverId, at = os.time(), entry = { uid = entry.uid, creatureId = entry.creatureId, level = entry.level, bought = Schema.copy(entry.bought) } })
	Schema.trimNotes(nf.transferNote, Config.Data.TRANSFER_NOTES_KEPT)
	local ok, err = pcall(place, nt, Schema.copy(entry))
	if not ok then
		warn("[HFB] Session.transfer: place failed: " .. tostring(err))
		return false
	end
	local n = countUid(nt, uid)
	if n == 0 then
		table.insert(nt.crate, { uid = entry.uid, creatureId = entry.creatureId, level = entry.level, bought = Schema.copy(entry.bought) })
	elseif n > 1 then
		warn("[HFB] Session.transfer: place put the uid in twice")
		return false
	end
	dropNote(nt, uid)
	for i = #nt.transferNote, 1, -1 do
		if nt.transferNote[i].uid == uid and nt.transferNote[i].from ~= nil then
			table.remove(nt.transferNote, i)
		end
	end
	table.insert(nt.transferNote, { uid = uid, from = from.UserId, at = os.time() })
	Schema.trimNotes(nt.transferNote, Config.Data.TRANSFER_NOTES_KEPT)
	-- Both or neither (core.applyPair validates both, then applies both, with no yield).
	if not core.applyPair(from, nf, to, nt) then
		return false
	end
	pendingIn[to] = pendingIn[to] or {}
	pendingIn[to][uid] = from
	awaiting[to] = awaiting[to] or {}
	awaiting[to][uid] = from
	outgoing[from] = outgoing[from] or {}
	outgoing[from][uid] = { thief = to, entry = Schema.copy(entry) }

	local report: { [string]: any } = { uid = uid }
	local okO, stO = core.save(from, { reason = "transfer" })
	report.owner = stO or tostring(okO)
	local okBetween, errBetween = pcall(function()
		if TestHooks.get("SaveFailBetween") == true then
			workspace:SetAttribute(TestHooks.PREFIX .. "SaveFailBetween", nil) -- one-shot: "the next steal transfer"
			error("SaveFailBetween: forced error between the owner's and the thief's write", 0)
		end
		local okT, stT = core.save(to, { reason = "transfer" })
		report.thief = stT or tostring(okT)
	end)
	if not okBetween then
		report.thief = "error: " .. tostring(errBetween)
	end
	report.pending = Transfer.isPending(to, uid)
	if RunService:IsStudio() then
		TestHooks.reports.transfer = report
	end
	return true
end

-- Leave path, before the final write. As a thief: each uid still pending gets one more owner write; if it is still
-- pending and the owner is here, the boss goes back to the owner (the thief's record never had it).
function Transfer.beforeFinal(player: any)
	for uid, owner in pairs(table.clone(pendingIn[player] or {})) do
		if core.isLive(owner) then
			core.save(owner, { reason = "thiefLeaving" })
		end
		if Transfer.isPending(player, uid) then
			local o = outgoing[owner] and outgoing[owner][uid]
			if o and core.profile(owner) then
				local entry = o.entry
				local thiefP = core.profile(player)
				local np = thiefP and Schema.copy(thiefP)
				if np then
					takeOut(np, uid)
				end
				local okBack = core.applyOne(owner, function(p: any)
					dropNote(p, uid)
					if countUid(p, uid) > 0 then
						return
					end
					local taken = false
					for _, b in ipairs(p.bosses) do
						if b.spot == entry.spot then
							taken = true
						end
					end
					if entry.spot and not taken and #p.bosses < Config.Data.LIMITS.spots then
						table.insert(p.bosses, Schema.copy(entry))
					else
						table.insert(p.crate, { uid = entry.uid, creatureId = entry.creatureId, level = entry.level, bought = Schema.copy(entry.bought) })
					end
				end)
				if okBack and np then
					core.applyOne(player, function(p: any)
						takeOut(p, uid)
					end)
				end
				clear(owner, uid)
			end
			-- Owner gone: its record still holds the uid (its write never carried the move); this record leaves it out.
		end
	end
end

-- Studio check only: a crash forgets this server's marks for the player without any write.
function Transfer.crashReset(player: any)
	pendingIn[player] = nil
	awaiting[player] = nil
	outgoing[player] = nil
end

-- After a session ends: forget its marks. A thief's still-pending uids stay out of its last record; an owner's
-- outgoing uids that never got written stay pending in the thief (its record leaves them out: back to the owner).
function Transfer.forget(player: any)
	for uid, owner in pairs(pendingIn[player] or {}) do
		if outgoing[owner] then
			outgoing[owner][uid] = nil
		end
	end
	pendingIn[player] = nil
	awaiting[player] = nil
	for uid, o in pairs(outgoing[player] or {}) do
		if pendingIn[o.thief] then
			pendingIn[o.thief][uid] = player -- stays excluded
		end
	end
	outgoing[player] = nil
end

return Transfer
