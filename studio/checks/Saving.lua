if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-09: the saving checks (gate rows S14, S15; team/requirements/m2-gate.md). Data/Session, Store, Schema,
-- Migrations, Transfer, Purchases against the Studio DataStore and the stand-in memory store.
--
-- Two ways to run it, holding the studio lock:
--   EDIT MODE (installs): require(game.ServerStorage.DevSync:Clone()).run("checks/Saving.lua")
--     syncs nothing; fetches this file and checks/SkinCheck3.lua from the sync server and installs them as
--     ServerStorage.TmpChecksData.{Saving, SkinCheck3} (each wrapped as `return function(...) <file> end`).
--   PLAY MODE (one run_script_in_play_mode / start_play call per phase, each well under 90 s):
--     require(game.ServerStorage.TmpChecksData.Saving)("a")   -- save/leave/rejoin, second session, protected
--                                                              -- fields, content by id, autosave, shutdown
--     require(game.ServerStorage.TmpChecksData.Saving)("b")   -- foreign lock -> temp -> background swap, load
--                                                              -- error, failed save, receipts
--     require(game.ServerStorage.TmpChecksData.Saving)("c")   -- v1 -> v2 migration, newer record never written
--     require(game.ServerStorage.TmpChecksData.Saving)("d")   -- transfer by uid, SaveFailBetween, M6 pending
--   Clean up in edit mode: game.ServerStorage.TmpChecksData:Destroy()
--
-- Every phase moves the test player to the CHECK store (Config.Data.STORE_BASE = "PlayersCheck", so the record
-- is HFB_Studio_PlayersCheck/player_<id>) and back at the end; the player's normal Studio record is only left and
-- re-joined. Stand-ins (user id <= 0) live in the memory store. Hooks set here are cleared. Lines:
-- "Saving: PASS|FAIL ..." and one "CHECK Saving/<phase> pass=<n> fail=<m>" summary.
local phase = ...
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

if not RunService:IsRunning() then
	-- Edit mode: install.
	local HttpService = game:GetService("HttpService")
	local BASE = "http://127.0.0.1:34874"
	local old = ServerStorage:FindFirstChild("TmpChecksData")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "TmpChecksData"
	for _, name in ipairs({ "Saving", "SkinCheck3" }) do
		local src = HttpService:GetAsync(BASE .. "/studio/checks/" .. name .. ".lua", true)
		local m = Instance.new("ModuleScript")
		m.Name = name
		m.Source = "return function(...)\n" .. src .. "\nend\n"
		m.Parent = folder
	end
	folder.Parent = ServerStorage
	print("Saving: installed ServerStorage.TmpChecksData (Saving, SkinCheck3); play calls: Saving a, b, c, d")
else
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local SSS = game:GetService("ServerScriptService")
	local HttpService = game:GetService("HttpService")
	local Config = require(ReplicatedStorage.Shared.Config)
	local TestHooks = require(ReplicatedStorage.Shared.TestHooks)
	local Session = require(SSS.Data.Session)
	-- If Main.server failed before starting the data layer (a broken file elsewhere in a sync), start it here so
	-- the data checks still run; the failure is printed as a FAIL line so it is not hidden.
	if not ReplicatedStorage:WaitForChild("Remotes", 15) then
		print("Saving: FAIL " .. tostring(phase) .. "/Main.server did not start (Remotes missing): starting Net + Session here")
		require(ReplicatedStorage.Shared.Net).serverInit()
		Session.start()
	end
	local T = Session._test
	local Schema = T.schema
	local Store = T.store

	local pass, fail = 0, 0
	local function check(ok: any, what: string, detail: any?)
		if ok then
			pass += 1
		else
			fail += 1
		end
		print(("Saving: %s %s/%s%s"):format(ok and "PASS" or "FAIL", tostring(phase), what, detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local function j(v: any): string
		local ok, s = pcall(HttpService.JSONEncode, HttpService, v)
		return ok and s or tostring(v)
	end
	local function waitFor(fn: () -> boolean, secs: number): boolean
		local t0 = os.clock()
		while os.clock() - t0 < secs do
			if fn() then
				return true
			end
			task.wait(0.1)
		end
		return fn()
	end
	local function strip(p: any): any
		local c = Schema.copy(p)
		c.spots, c.carry, c.lock, c.leftAt = nil, nil, nil, nil
		return c
	end
	local function hasUid(r: any, uid: string): number
		local n = 0
		if type(r) ~= "table" then
			return 0
		end
		for _, list in ipairs({ r.bosses or {}, r.crate or {} }) do
			for _, b in ipairs(list) do
				if b.uid == uid then
					n += 1
				end
			end
		end
		return n
	end

	-- Saved defaults, restored at the end whatever happens.
	local SAVED = Schema.copy(Config.Data)
	local function restoreConfig()
		for k, v in pairs(SAVED) do
			(Config.Data :: any)[k] = Schema.copy(v)
		end
	end

	local P = Players:GetPlayers()[1]
	local t0 = os.clock()
	while not P and os.clock() - t0 < 20 do
		task.wait(0.1)
		P = Players:GetPlayers()[1]
	end
	assert(P, "no player")
	waitFor(function()
		local st = Session.state(P)
		return st ~= nil and st ~= "loading"
	end, 30)
	local uid0 = P.UserId

	-- To the check store (taking a stale check-store lock left by an aborted run), then real locks from here on.
	local function toCheckStore()
		T.leave(P, "check")
		Config.Data.STORE_BASE = "PlayersCheck"
		Config.Data.STUDIO_TAKE_LOCK_ON_JOIN = true
		T.join(P)
		Config.Data.STUDIO_TAKE_LOCK_ON_JOIN = false
		check(Session.state(P) == "live" and Store.storeName() == "HFB_Studio_PlayersCheck", "on the check store", Store.storeName() .. " " .. tostring(Session.state(P)))
	end
	local function back()
		T.leave(P, "check")
		restoreConfig()
		T.join(P)
		TestHooks.clearAll()
	end

	local function run()
		toCheckStore()
		local key = Store.key(uid0)

		if phase == "a" then
			-- a1: the load took the lock, as this server.
			local ok, r = T.rawRead(uid0)
			check(ok and type(r) == "table" and type(r.lock) == "table" and r.lock.server == T.serverId, "load took the lock", ok and j(r and r.lock))
			check(Config.Env == "Studio" and Store.storeName():find("Studio", 1, true) ~= nil, "store name carries Config.Env", Store.storeName())

			-- a2: save, leave, rejoin gives the same profile.
			Session.wipe(P)
			Session.set(P, "power", 1234.5)
			Session.addCash(P, 500)
			Session.addCash(P, 300, true)
			Session.set(P, "strengthLevel", 5)
			Session.set(P, "speedLevel", 3)
			Session.addZoneBeaten(P, 2)
			Session.addZoneBeaten(P, 1)
			local u1, u2 = Session.newUid(P), Session.newUid(P)
			local okM = Session.mutate(P, function(p)
				table.insert(p.bosses, { uid = u1, creatureId = "z2_t3", level = 4, spot = 2, padCash = 12.5, padStamp = workspace:GetServerTimeNow() })
				table.insert(p.crate, { uid = u2, creatureId = "z1_t1", level = 1 })
				p.flags.Joined = true
				p.settings.music = 0.5
				p.spinTickets = 3
			end)
			check(okM and u1 ~= nil and u2 ~= nil and u1 ~= u2 and u1:find(tostring(uid0) .. "-", 1, true) == 1, "mutate + newUid", tostring(u1) .. " " .. tostring(u2))
			local before = strip(Session.get(P))
			local st = T.leave(P, "check")
			check(st == "saved", "leave saved", st)
			local okR, rec = T.rawRead(uid0)
			check(okR and rec ~= nil and rec.lock == nil, "leave released the lock", okR and j(rec and rec.lock))
			check(okR and Schema.equal(strip(rec), before), "record = profile at leave", okR and j(strip(rec)) or "read failed")
			check(type(rec) == "table" and type(rec.leftAt) == "number" and rec.leftAt > 0, "leftAt saved", rec and rec.leftAt)
			T.join(P)
			check(Session.state(P) == "live" and Schema.equal(strip(Session.get(P)), before), "rejoin gives the same profile", j(strip(Session.get(P) or {})))
			local sp = (Session.get(P) :: any).spots
			check(sp and sp[2] and sp[2].uid == u1, "M1 spots view rebuilt from bosses", j(sp))

			-- a3: a second session cannot take the locked profile; the record is not written.
			local _, recA = T.rawRead(uid0)
			local stB = T.tryLoad(uid0, "second-server-guid")
			local _, recB = T.rawRead(uid0)
			check(stB == "locked", "second session refused", stB)
			check(recB and recB.lock and recB.lock.server == T.serverId and Schema.equal(recA, recB), "locked record untouched by the refused load")
			check(T.serverId ~= game.JobId and #T.serverId >= 32, "lock id is a per-server GUID, not JobId", T.serverId)

			-- a4: protected fields (M2-02 M1) and validation.
			local p = Session.get(P) :: any
			local bc = p.boughtCash
			check(Session.mutate(P, function(q)
				q.boughtCash += 100
			end) == false and p.boughtCash == bc, "mutate cannot write boughtCash")
			Session.set(P, "boughtCash", 9999)
			check(p.boughtCash == bc, "set refuses boughtCash")
			for _, k in ipairs({ "zonesBeaten", "purchases", "nextUid", "transferNote", "starterPackGiven", "version" }) do
				local was = Schema.copy(p[k])
				local okX = Session.mutate(P, function(q)
					if type(q[k]) == "table" then
						table.insert(q[k], if k == "zonesBeaten" then 6 elseif k == "transferNote" then { uid = "x", to = 1 } else "x")
					elseif type(q[k]) == "boolean" then
						q[k] = not q[k]
					else
						q[k] += 1
					end
				end)
				check(okX == false and Schema.equal(p[k], was), "mutate cannot write " .. k)
			end
			check(Session.mutate(P, function(q)
				q.crate[1].bought = { source = "spin", buyer = uid0 }
			end) == false and p.crate[1].bought == nil, "mutate cannot set a bought mark")
			check(Session.mutate(P, function(q)
				table.insert(q.crate, { uid = "f-1", creatureId = "z1_t2", level = 1, bought = { source = "pack", buyer = uid0 } })
			end) == false, "mutate cannot add a bought boss")
			local tok = Session.claim("BoughtMark")
			check(Session.mutate(P, function(q)
				q.crate[1].bought = { source = "spin", buyer = uid0 }
			end, tok) == true and p.crate[1].bought ~= nil, "the BoughtMark token can set a mark")
			check(Session.mutate(P, function(q)
				q.crate[1].bought = nil
			end) == false and p.crate[1].bought ~= nil, "mutate cannot clear a bought mark")
			local pw = p.power
			check(Session.mutate(P, function(q)
				q.power = 1
				error("boom")
			end) == false and p.power == pw, "fn error: nothing applied")
			check(Session.mutate(P, function(q)
				q.power = 0 / 0
			end) == false and p.power == pw, "NaN refused")
			check(Session.mutate(P, function(q)
				q.cash = math.huge
			end) == false, "infinity refused")
			check(Session.mutate(P, function(q)
				q.strengthLevel = 31
			end) == false, "level out of range refused")
			check(Session.mutate(P, function(q)
				q.crate[1].creatureId = "Chomp Frog"
			end) == false, "a name instead of an id refused")
			check(Session.setZonesBeatenForTest ~= nil and Session.setZonesBeatenForTest(P, { 3, 1 }) and Schema.equal(p.zonesBeaten, { 1, 3 }), "setZonesBeatenForTest (Studio) replaces the list", j(p.zonesBeaten))
			check(Session.setZonesBeatenForTest(P, { 7 }) == false and Schema.equal(p.zonesBeaten, { 1, 3 }), "setZonesBeatenForTest refuses a bad zone")
			Session.setZonesBeatenForTest(P, { 1, 2 })
			check(Session.addCash(P, -5) == false and Session.spendCash(P, p.cash + 1) == false, "negative add / overspend refused")
			-- boughtCash = min(boughtCash, cash): cash 800, bought 300; set cash 100 -> bought 100; spend 40 -> 60/60.
			check(p.cash == 800 and p.boughtCash == 300, "cash 800, bought 300", p.cash .. "/" .. p.boughtCash)
			Session.set(P, "cash", 100)
			check(p.cash == 100 and p.boughtCash == 100, "set(cash) lowers boughtCash", p.cash .. "/" .. p.boughtCash)
			Session.spendCash(P, 40)
			check(p.cash == 60 and p.boughtCash == 60, "spendCash keeps boughtCash <= cash", p.cash .. "/" .. p.boughtCash)
			Session.mutate(P, function(q)
				q.cash = 10
			end)
			check(p.boughtCash == 10, "mutate lowering cash lowers boughtCash", p.boughtCash)
			Session.addCash(P, 50, true)
			check(p.cash == 60 and p.boughtCash == 60, "addCash(bought) raises both", p.cash .. "/" .. p.boughtCash)

			-- a5: content saved by id only (scan of the saved record).
			Session.save(P, "check")
			local _, recC = T.rawRead(uid0)
			local names = {}
			local function collect(t: any)
				for _, v in pairs(t) do
					if type(v) == "table" then
						collect(v)
					elseif type(v) == "string" and #v >= 3 then
						names[v] = true
					end
				end
			end
			local okN, namesMod = pcall(require, ReplicatedStorage.Skins.brickbrawl.Names)
			check(okN, "brickbrawl Names loads (for the scan)", not okN and tostring(namesMod) or nil)
			if okN then
				collect(namesMod)
			end
			local bad = {}
			local function scan(t: any, path: string)
				for k, v in pairs(t) do
					local here = path .. "." .. tostring(k)
					if type(k) == "string" and names[k] and path ~= ".flags" then
						table.insert(bad, here .. " key")
					end
					if type(v) == "table" then
						scan(v, here)
					elseif type(v) == "string" and names[v] then
						table.insert(bad, here .. "=" .. v)
					elseif typeof(v) ~= "string" and typeof(v) ~= "number" and typeof(v) ~= "boolean" then
						table.insert(bad, here .. " " .. typeof(v))
					end
				end
			end
			scan(recC, "")
			local ids = true
			for _, list in ipairs({ recC.bosses, recC.crate }) do
				for _, b in ipairs(list) do
					ids = ids and require(ReplicatedStorage.Shared.Ids).parseCreature(b.creatureId) ~= nil
				end
			end
			check(#bad == 0 and ids, "saved record holds ids only (no skin name, no Instance)", #bad > 0 and table.concat(bad, ", ") or nil)

			-- a6: autosave writes and renews the lock.
			local _, r0 = T.rawRead(uid0)
			Config.Data.AUTOSAVE_S = 2
			Session.set(P, "power", 777)
			local seen = waitFor(function()
				local _, r = T.rawRead(uid0)
				return r and r.power == 777
			end, 8)
			local _, r1 = T.rawRead(uid0)
			check(seen, "autosave wrote within AUTOSAVE_S", r1 and r1.power)
			check(r1 and r0 and r1.lock and r0.lock and r1.lock.stamp >= r0.lock.stamp and r1.lock.server == T.serverId, "autosave renewed the lock")
			Config.Data.AUTOSAVE_S = SAVED.AUTOSAVE_S

			-- a7: a simulated shutdown saves (the BindToClose path, called directly) and releases.
			Session.set(P, "power", 888)
			local rep = T.shutdown()
			local _, r2 = T.rawRead(uid0)
			check(rep.players >= 1 and rep.saved == rep.players and rep.failed == 0 and rep.seconds < 25, "shutdown saved every session within 25 s", j(rep))
			check(r2 and r2.power == 888 and r2.lock == nil, "shutdown: record has the last change, lock released", r2 and (tostring(r2.power) .. " " .. j(r2.lock)))
			check(Session.get(P) == nil and T.inflight() == 0, "shutdown: no session left, nothing in flight")
			-- a8: the Shutdown hook takes the same path.
			T.join(P)
			workspace:SetAttribute("HFB_Shutdown", true)
			local okH = waitFor(function()
				return TestHooks.reports.shutdown ~= nil
			end, 20)
			check(okH and TestHooks.reports.shutdown.saved >= 1, "Shutdown hook saved", j(TestHooks.reports.shutdown))
			T.join(P)
			-- a9: Leave / Rejoin / ForceSave hooks.
			Session.set(P, "power", 999)
			workspace:SetAttribute("HFB_ForceSave", true)
			waitFor(function()
				return TestHooks.reports.save ~= nil
			end, 10)
			local _, r3 = T.rawRead(uid0)
			check(TestHooks.reports.save and TestHooks.reports.save.ok and r3.power == 999, "ForceSave hook", j(TestHooks.reports.save))
			workspace:SetAttribute("HFB_Leave", true)
			waitFor(function()
				return TestHooks.reports.leave ~= nil and Session.state(P) == nil
			end, 10)
			check(Session.get(P) == nil and TestHooks.reports.leave and TestHooks.reports.leave.status == "saved", "Leave hook", j(TestHooks.reports.leave))
			workspace:SetAttribute("HFB_Rejoin", true)
			waitFor(function()
				return Session.state(P) == "live"
			end, 10)
			check(Session.state(P) == "live" and (Session.get(P) :: any).power == 999, "Rejoin hook")
			-- a10: a Studio stop runs PlayerRemoving's leave and BindToClose's at once: the shutdown counts it saved.
			task.spawn(T.leave, P, "leave")
			local rep2 = T.shutdown()
			check(rep2.players == 1 and rep2.saved == 1 and rep2.failed == 0, "leave + shutdown at once: counted saved", j(rep2.results))
			T.join(P)
		elseif phase == "b" then
			Config.Data.WRITE_TRIES = 1
			Config.Data.LOAD_TRIES = 2
			Config.Data.LOAD_GAP_S = 1
			Config.Data.BG_RETRY_S = 2
			Config.Data.BG_RETRY_FOR_S = 30
			Config.Data.LOCK_LEASE_S = 8
			Session.set(P, "power", 4242)
			T.leave(P, "check")
			-- b1: a foreign live lock refuses the load: temp profile, record untouched; background swap later.
			local _, rec = T.rawRead(uid0)
			rec.lock = { server = "foreign-server", stamp = os.time() }
			T.rawWrite(uid0, rec)
			T.join(P)
			local _, recL = T.rawRead(uid0)
			check(Session.state(P) == "temp" and not Session.isSaving(P), "foreign lock: temp profile, not saving", Session.state(P))
			check(recL.lock and recL.lock.server == "foreign-server" and recL.power == 4242, "foreign lock: record untouched")
			check((Session.get(P) :: any).power == 0, "temp profile starts fresh")
			-- receipts into a temp profile: retry, nothing granted (M2-02 M3)
			local cashT = (Session.get(P) :: any).cash
			local rT = Session.recordPurchase(P, "chk-temp", function(q)
				Session.ops.addCash(q, 100, true)
			end)
			check(rT == "retry" and (Session.get(P) :: any).cash == cashT, "receipt into a temp profile: retry, nothing granted", rT)
			check(Session.save(P, "check") == false, "a temp profile is never written")
			local swapped = waitFor(function()
				return Session.state(P) == "live"
			end, 20)
			local _, recS = T.rawRead(uid0)
			check(swapped and (Session.get(P) :: any).power == 4242 and recS.lock.server == T.serverId, "lease ended: real profile swapped in (S2)", Session.state(P))
			-- b2: a load error never writes over the record; temp, then the background retry loads it.
			T.leave(P, "check")
			Store.failNext(key, 2) -- the two load attempts (the raw read below must not take one)
			T.join(P)
			local _, recE = T.rawRead(uid0)
			check(Session.state(P) == "temp" and recE.power == 4242 and recE.lock == nil, "load error: temp profile, record untouched", Session.state(P))
			local back2 = waitFor(function()
				return Session.state(P) == "live"
			end, 12)
			check(back2 and (Session.get(P) :: any).power == 4242, "load error: background retry loaded the record")
			-- b3: a failed save keeps the session; the next save writes.
			Session.set(P, "power", 5151)
			Store.failNext(key, 1)
			local okF, stF = Session.save(P, "check")
			local _, recF = T.rawRead(uid0)
			check(okF == false and stF == "error" and Session.isSaving(P) and recF.power == 4242, "failed save: false, still saving, record unchanged", tostring(stF))
			local okG = Session.save(P, "check")
			local _, recG = T.rawRead(uid0)
			check(okG and recG.power == 5151, "the next save writes")
			-- b4: receipts (M2-02 M3). Ids unique per run: the check store keeps the last run's.
			local RID = "chk" .. HttpService:GenerateGUID(false):sub(1, 8)
			local p = Session.get(P) :: any
			local c0, b0 = p.cash, p.boughtCash
			local grant = function(q)
				Session.ops.addCash(q, 100, true)
			end
			local r1 = Session.recordPurchase(P, RID .. "-1", grant)
			local _, recP = T.rawRead(uid0)
			check(r1 == "granted" and p.cash == c0 + 100 and p.boughtCash == b0 + 100, "receipt granted once into the live profile", r1)
			check(table.find(recP.purchases, RID .. "-1") ~= nil and recP.cash == c0 + 100, "grant and purchase id in one write")
			local r2 = Session.recordPurchase(P, RID .. "-1", grant)
			check(r2 == "already" and p.cash == c0 + 100, "same id again: already, not granted", r2)
			Store.failNext(key, 1)
			local r3 = Session.recordPurchase(P, RID .. "-2", grant)
			check(r3 == "retry" and p.cash == c0 + 100 and table.find(p.purchases, RID .. "-2") == nil, "write failed: retry, live profile unchanged", r3)
			local r4 = Session.recordPurchase(P, RID .. "-2", grant)
			check(r4 == "granted" and p.cash == c0 + 200, "redelivered: granted once", r4)
			local rErr = Session.recordPurchase(P, RID .. "-3", function()
				error("grant bug")
			end)
			check(rErr == "retry" and p.cash == c0 + 200, "a grant that errors: retry, nothing granted", rErr)
			-- receipts while leaving: retry
			local leaving = task.spawn(T.leave, P, "check")
			local rL = Session.recordPurchase(P, RID .. "-4", grant)
			check(rL == "retry", "receipt while leaving: retry", rL)
			waitFor(function()
				return Session.state(P) == nil
			end, 10)
			local _ = leaving
			T.join(P)
			check(table.find((Session.get(P) :: any).purchases, RID .. "-2") ~= nil and (Session.get(P) :: any).cash == c0 + 200, "purchases kept after rejoin")
		elseif phase == "c" then
			-- c1: a v1 record migrates to a stand-in v2 (one new field, one renamed key).
			T.leave(P, "check")
			local v1 = Schema.fresh()
			v1.power, v1.leftAt, v1.cash = 42, 12345, 7
			T.rawWrite(uid0, v1)
			local savedDefaults = Schema.copy(Schema.DEFAULTS)
			Schema.VERSION = 2
			Schema.DEFAULTS.testField = 0
			Schema.DEFAULTS.leftAtV2 = 0
			Schema.DEFAULTS.leftAt = nil
			T.migrations.steps[1] = function(r)
				r.testField = 7
				r.leftAtV2 = r.leftAt
				r.leftAt = nil
				return r
			end
			local okRun = pcall(function()
				T.join(P)
				local p = Session.get(P) :: any
				check(Session.state(P) == "live" and p.version == 2 and p.testField == 7 and p.leftAtV2 == 12345 and p.leftAt == nil and p.power == 42, "v1 -> v2 on load: new field, renamed key, data kept", j({ v = p.version, t = p.testField, l2 = p.leftAtV2, l = p.leftAt, pw = p.power }))
				local _, r = T.rawRead(uid0)
				check(r.version == 2 and r.testField == 7 and r.leftAtV2 == 12345 and r.leftAt == nil, "migrated record written back in the load", j({ v = r.version, t = r.testField }))
				T.leave(P, "check")
			end)
			-- c2: back to v1 code: the newer record is never loaded and never written (M2-02 M10).
			Schema.VERSION = 1
			for k in pairs(Schema.DEFAULTS) do
				Schema.DEFAULTS[k] = nil
			end
			for k, v in pairs(savedDefaults) do
				Schema.DEFAULTS[k] = v
			end
			T.migrations.steps[1] = nil
			check(okRun, "v2 run without error")
			local _, rv2 = T.rawRead(uid0)
			T.join(P)
			check(Session.state(P) == "temp" and not Session.isSaving(P), "older code: newer record gives a temp profile", Session.state(P))
			Session.set(P, "power", 1)
			Session.save(P, "check")
			T.leave(P, "check")
			local _, rv2b = T.rawRead(uid0)
			check(Schema.equal(rv2, rv2b) and rv2b.version == 2, "newer record never written by older code")
			-- c3: a missing step fails the load safely (temp, record untouched).
			T.rawWrite(uid0, (function()
				local r = Schema.fresh()
				r.version = 0
				return r
			end)())
			T.join(P)
			check(Session.state(P) == "temp", "bad version: temp profile, nothing written", Session.state(P))
			T.leave(P, "check")
			T.rawRemove(uid0)
			T.join(P)
			check(Session.state(P) == "live" and (Session.get(P) :: any).version == 1, "fresh v1 record after the test")
		elseif phase == "d" then
			-- d: the transfer (steal) by uid, real player P (check store) and stand-in S (memory store).
			local sid = -2
			-- Stand-in uids restart each session (fresh memory store), so the last run's bosses and notes in P's check
			-- record would collide: start P from an empty check record.
			T.leave(P, "check")
			T.rawRemove(uid0)
			T.join(P)
			local S = Session.standIn(sid)
			check(Session.state(S) == "live", "stand-in loaded from the memory store", Session.state(S))
			check(T.session(S).store.kind == "memory", "stand-in never touches a DataStore (S9)")
			local function count(uid: string): (number, number)
				local _, rp = T.rawRead(uid0)
				local _, rs = Store.forUser(sid):read(Store.key(sid))
				local live = hasUid(Session.get(P), uid) + hasUid(Session.get(S), uid)
				return hasUid(rp, uid) + hasUid(rs, uid), live
			end
			local function placeSpot(spot: number)
				return function(prof, e)
					e.spot = spot
					e.padCash, e.padStamp = 0, workspace:GetServerTimeNow()
					table.insert(prof.bosses, e)
				end
			end
			-- d1: plain transfer S -> P.
			local uA = Session.newUid(S) :: string
			Session.mutate(S, function(q)
				table.insert(q.bosses, { uid = uA, creatureId = "z2_t3", level = 4, spot = 3, padCash = 5, padStamp = 0 })
			end)
			Session.save(S, "check")
			local okT = Session.transfer(uA, S, P, placeSpot(5))
			local rep = TestHooks.reports.transfer or {}
			local nRec, nLive = count(uA)
			check(okT and rep.owner == "ok" and rep.thief == "ok" and rep.pending == false, "transfer: owner then thief written", j(rep))
			check(nRec == 1 and nLive == 1 and hasUid(Session.get(P), uA) == 1, "transfer: uid in exactly one record and one profile", nRec .. "/" .. nLive)
			local noteOk = false
			for _, n in ipairs((Session.get(S) :: any).transferNote) do
				noteOk = noteOk or (n.uid == uA and n.to == uid0)
			end
			check(noteOk, "owner got transferNote { uid, to }")
			check(Session.transfer(uA, S, P, placeSpot(6)) == false, "transfer of a uid the owner no longer has: refused")
			-- d2: forced error between the two writes (SaveFailBetween), then both reload.
			local uB = Session.newUid(P) :: string
			Session.mutate(P, function(q)
				table.insert(q.crate, { uid = uB, creatureId = "z3_t2", level = 2 })
			end)
			Session.save(P, "check")
			workspace:SetAttribute("HFB_SaveFailBetween", true)
			local okB = Session.transfer(uB, P, S, function(prof, e)
				table.insert(prof.crate, e)
			end)
			local repB = TestHooks.reports.transfer or {}
			check(okB and repB.owner == "ok" and tostring(repB.thief):find("SaveFailBetween", 1, true) ~= nil, "SaveFailBetween: error between the writes", j(repB))
			check(workspace:GetAttribute("HFB_SaveFailBetween") == nil, "SaveFailBetween is one-shot (cleared)")
			T.leave(P, "check")
			Session.removeStandIn(S)
			local nB = count(uB)
			check(nB == 1, "after the forced error and both reloads: uid in exactly one record", nB)
			T.join(P)
			S = Session.standIn(sid)
			local _, nBl = count(uB)
			check(nBl == 1 and hasUid(Session.get(S), uB) == 1, "after rejoin: uid in exactly one profile (the thief's)", nBl)
			-- d3 (M2-02 M6): the owner's write fails: the thief's writes leave the uid out until it succeeds.
			Config.Data.WRITE_TRIES = 1
			Store.failNext(Store.key(sid), 1)
			local okC = Session.transfer(uB, S, P, function(prof, e)
				table.insert(prof.crate, e)
			end)
			local repC = TestHooks.reports.transfer or {}
			check(okC and repC.owner == "error" and repC.pending == true, "owner write failed: uid pending in the thief", j(repC))
			Session.save(P, "check")
			local _, rp3 = T.rawRead(uid0)
			local _, rs3 = Store.forUser(sid):read(Store.key(sid))
			check(hasUid(rp3, uB) == 0 and hasUid(rs3, uB) == 1, "thief's save leaves the pending uid out; the owner's record still has it")
			Session.save(S, "check") -- the owner's next write succeeds -> the mark clears -> the thief is written
			waitFor(function()
				local _, r = T.rawRead(uid0)
				return hasUid(r, uB) == 1
			end, 8)
			local nC = count(uB)
			local _, rs4 = Store.forUser(sid):read(Store.key(sid))
			check(nC == 1 and hasUid(rs4, uB) == 0, "owner write succeeded: the thief's record now has it, the owner's not", nC)
			-- d4: stolen back: the old note does not drop it on the next load.
			local okD = Session.transfer(uB, P, S, function(prof, e)
				table.insert(prof.crate, e)
			end)
			local hadNote = false
			for _, n in ipairs((Session.get(S) :: any).transferNote) do
				hadNote = hadNote or (n.uid == uB and n.to ~= nil) -- the arrival note ({ uid, from }) is expected
			end
			check(okD and not hadNote, "stolen back: the owner's old note for the uid is removed")
			Session.removeStandIn(S)
			S = Session.standIn(sid)
			check(hasUid(Session.get(S), uB) == 1 and count(uB) == 1, "stolen back: kept after reload")
			-- d5: the thief leaves while the uid is pending and the owner's write keeps failing: back to the owner.
			Store.failNext(Store.key(sid), 2)
			Session.transfer(uB, S, P, function(prof, e)
				table.insert(prof.crate, e)
			end)
			T.leave(P, "check")
			check(hasUid(Session.get(S), uB) == 1, "thief left before the owner's write: boss back in the owner's profile")
			Session.save(S, "check")
			check(count(uB) == 1, "and in exactly one record")
			T.join(P)
			local _, l5 = count(uB)
			check(l5 == 1, "after rejoin: exactly one profile", l5)
			-- d6: a CRASH between the owner's write and the thief's (M2-15 follow-up): the owner's note carries the
			-- boss; the owner's next load reads the thief's record and brings it back. Owner S (stand-in), thief P.
			Config.Data.WRITE_TRIES = 3
			local uC = Session.newUid(S) :: string
			Session.mutate(S, function(q)
				table.insert(q.bosses, { uid = uC, creatureId = "z4_t2", level = 3, spot = 9, padCash = 0, padStamp = 0 })
			end)
			Session.save(S, "check")
			workspace:SetAttribute("HFB_SaveFailBetween", true)
			Session.transfer(uC, S, P, placeSpot(11))
			local repD = TestHooks.reports.transfer or {}
			local movedBy = T.serverId
			T.crash({ P, S }) -- no more writes, no releases
			local _, rsC = Store.forUser(sid):read(Store.key(sid))
			local noteEntry = false
			for _, n in ipairs(rsC.transferNote or {}) do
				noteEntry = noteEntry or (n.uid == uC and n.to == uid0 and type(n.entry) == "table" and n.server == movedBy)
			end
			local rawC = count(uC)
			check(repD.owner == "ok" and tostring(repD.thief):find("SaveFailBetween", 1, true) ~= nil and rawC == 0 and noteEntry, "crash after the owner's write: no record holds the boss, the owner's note carries it", rawC)
			Config.Data.LOCK_LEASE_S = 2 -- the crashed server's locks go stale (a new server would see them stale after the lease)
			task.wait(3)
			S = Session.standIn(sid) -- the owner loads first: the thief's record lacks it and no live session can write it
			check(hasUid(Session.get(S), uC) == 1, "owner's load brought the boss back from its note", Session.state(S))
			T.join(P)
			local nCrash, lCrash = count(uC)
			check(nCrash == 1 and lCrash == 1, "after the crash and both loads: exactly one record and one profile", nCrash .. "/" .. lCrash)
			-- d7: the same crash, the thief loads first; then the owner.
			workspace:SetAttribute("HFB_SaveFailBetween", true)
			Session.transfer(uC, S, P, placeSpot(12))
			T.crash({ P, S })
			task.wait(3)
			T.join(P)
			S = Session.standIn(sid)
			local nC7, lC7 = count(uC)
			check(nC7 == 1 and lC7 == 1 and hasUid(Session.get(S), uC) == 1, "thief loads first: still exactly one (the owner's)", nC7 .. "/" .. lC7)
			-- d8: crash after both writes landed: the owner's load drops its note, the boss stays with the thief.
			Session.transfer(uC, S, P, placeSpot(12))
			T.crash({ P, S })
			task.wait(3)
			S = Session.standIn(sid)
			T.join(P)
			local nC8, lC8 = count(uC)
			check(nC8 == 1 and lC8 == 1 and hasUid(Session.get(P), uC) == 1, "crash after both writes: exactly one (the thief's)", nC8 .. "/" .. lC8)
			-- d9: owner rejoins in the server that made the move while the thief's write is still pending: undecided, not restored.
			workspace:SetAttribute("HFB_SaveFailBetween", true)
			Config.Data.LOCK_LEASE_S = SAVED.LOCK_LEASE_S
			Session.transfer(uC, P, S, function(prof, e)
				table.insert(prof.crate, e)
			end) -- owner P written, thief S not
			T.leave(P, "check")
			-- S (thief) is live in this server: P's load must not restore the boss
			T.join(P)
			check(hasUid(Session.get(P), uC) == 0 and hasUid(Session.get(S), uC) == 1, "owner rejoins while the thief's write is pending: not restored (no copy)")
			Session.save(S, "check")
			local n9 = count(uC)
			check(n9 == 1, "after the thief's write: exactly one record", n9)
			T.leave(P, "check")
			T.join(P)
			local n9b, l9b = count(uC)
			check(n9b == 1 and l9b == 1, "owner's next load drops its resolved note: still one", n9b .. "/" .. l9b)
			workspace:SetAttribute("HFB_SaveFailBetween", nil)
			-- M2-27 MF1: a thief who sells the boss and then takes 21 more must not make the victim's load restore it.
			local function noteOf(prof: any, uid: string): any
				for _, n in ipairs(prof and prof.transferNote or {}) do
					if n.uid == uid and n.to ~= nil then
						return n
					end
				end
				return nil
			end
			local function stealMany(from: any, k: number)
				for _ = 1, k do
					local u = Session.newUid(from) :: string
					Session.mutate(from, function(q)
						table.insert(q.crate, { uid = u, creatureId = "z1_t3", level = 1 })
					end)
					Session.transfer(u, from, P, function(prof, e)
						table.insert(prof.crate, e)
					end)
				end
			end
			local function sell(uid: string)
				Session.mutate(P, function(q)
					for _, list in ipairs({ q.bosses, q.crate }) do
						for i = #list, 1, -1 do
							if list[i].uid == uid then
								table.remove(list, i)
							end
						end
					end
				end)
				Session.save(P, "check")
			end
			-- d10: both stay: the thief's write clears the owner's live note at once.
			local uE = Session.newUid(S) :: string
			Session.mutate(S, function(q)
				table.insert(q.crate, { uid = uE, creatureId = "z5_t1", level = 2 })
			end)
			Session.transfer(uE, S, P, function(prof, e)
				table.insert(prof.crate, e)
			end)
			local nE = noteOf(Session.get(S), uE)
			check(nE ~= nil and nE.entry == nil, "thief's write landed: the owner's live note no longer carries the boss")
			waitFor(function()
				local _, r = Store.forUser(sid):read(Store.key(sid))
				local n = noteOf(r, uE)
				return n ~= nil and n.entry == nil
			end, 6)
			local _, rsE = Store.forUser(sid):read(Store.key(sid))
			check(noteOf(rsE, uE) ~= nil and noteOf(rsE, uE).entry == nil, "and the owner's record has the resolved note")
			sell(uE)
			stealMany(S, 21)
			Session.removeStandIn(S)
			S = Session.standIn(sid)
			check(hasUid(Session.get(S), uE) == 0 and count(uE) == 0, "sold, then 21 more steals, victim reloads: not restored (no duplicate)", count(uE))
			-- d11: the owner leaves before the thief's write (its record keeps the entry); the thief writes, sells, 21 more.
			local uF = Session.newUid(S) :: string
			Session.mutate(S, function(q)
				table.insert(q.crate, { uid = uF, creatureId = "z5_t2", level = 2 })
			end)
			Session.save(S, "check")
			workspace:SetAttribute("HFB_SaveFailBetween", true)
			Session.transfer(uF, S, P, function(prof, e)
				table.insert(prof.crate, e)
			end)
			Session.removeStandIn(S) -- the owner leaves; its record keeps the note with the boss
			local _, rsF = Store.forUser(sid):read(Store.key(sid))
			check(noteOf(rsF, uF) ~= nil and noteOf(rsF, uF).entry ~= nil, "owner left before the thief's write: its record note still carries the boss")
			Session.save(P, "check") -- the boss lands in the thief's record (with its arrival note)
			sell(uF)
			local S2 = Session.standIn(-3)
			stealMany(S2, 21)
			Session.removeStandIn(S2)
			S = Session.standIn(sid)
			check(hasUid(Session.get(S), uF) == 0 and count(uF) == 0, "owner away, thief sold it and took 21 more, owner reloads: not restored (arrival kept by age)", count(uF))
			local nF = noteOf(Session.get(S), uF)
			check(nF ~= nil and nF.entry == nil, "the owner's note is resolved on that load")
			Session.removeStandIn(S)
		elseif phase ~= nil then
			check(false, "unknown phase " .. tostring(phase))
		end
	end

	local okRun, err = pcall(run)
	if not okRun then
		check(false, "the check errored", err)
	end
	local okBack, errBack = pcall(back)
	if not okBack then
		check(false, "restore errored", errBack)
	end
	restoreConfig()
	TestHooks.clearAll()
	check(Store.storeName() == "HFB_Studio_Players" and Session.state(P) ~= nil, "restored: normal store, player has a session", Store.storeName() .. " " .. tostring(Session.state(P)))
	print(("CHECK Saving/%s pass=%d fail=%d"):format(tostring(phase), pass, fail))
end
