--!strict
-- Data/Migrations: one step per version, Migrations.steps[n] turns a version n record into version n + 1
-- (m2-contract.md section D). Pure: no services, no yields. Steps run in order on load, inside the load's
-- UpdateAsync, so a migrated record is written back with the lock in the same call.
--
-- Rules for a new step (the data-engineer's, for every later schema change):
--   1. Never delete player data in a step: rename by copying the value to the new key, then clearing the old one.
--   2. Bump Schema.VERSION and add the new key to Schema.DEFAULTS in the same change.
--   3. Test it on a Studio check-store record first (studio/checks/Saving.lua phase "c" stands in a v2); never on
--      live data. Before publishing a version bump: the manager shuts down old servers after publishing (a newer
--      record is never written by older code, M2-02 M10, but a player on an old server keeps a temp profile).
--   4. Rollback: DataStore keeps a version per UTC hour for 30 days (ListVersionsAsync / GetVersionAsync); the
--      rollback steps go to manager-todo before the release that carries the bump.
--
-- Version 1 is the first saved version: nothing was saved before M2 (M1 kept profiles in memory), so there is no
-- step yet. A record without `version` is treated as version 1.
local Migrations = {}

Migrations.steps = {} :: { [number]: (rec: { [string]: any }) -> { [string]: any } }

-- Runs every step from the record's version up to `target`. Errors (the load then keeps a temp profile and writes
-- nothing) when a step is missing or the record is newer than `target`.
function Migrations.run(rec: { [string]: any }, target: number): { [string]: any }
	local v = rec.version
	if v == nil then
		v = 1
	end
	assert(type(v) == "number" and v % 1 == 0 and v >= 1, "Migrations: bad version " .. tostring(v))
	assert(v <= target, ("Migrations: record version %d is newer than this code (%d)"):format(v, target))
	while v < target do
		local step = Migrations.steps[v]
		assert(step, ("Migrations: no step from version %d"):format(v))
		rec = step(rec)
		v += 1
		rec.version = v
	end
	rec.version = v
	return rec
end

return Migrations
