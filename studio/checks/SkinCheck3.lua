if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-09: skin check part 3 (gate row S23): a save made under the real skin (brickbrawl) loads under the stub.
-- Installed by checks/Saving.lua (edit mode) as ServerStorage.TmpChecksData.SkinCheck3. Two play sessions:
--   1. normal play (brickbrawl):  require(game.ServerStorage.TmpChecksData.SkinCheck3)("save")
--   2. arm the stub in EDIT mode: workspace:SetAttribute("HFB_ForceSkin", "stub")
--      then play:                 require(game.ServerStorage.TmpChecksData.SkinCheck3)("load")
--      then DISARM in edit mode:  workspace:SetAttribute("HFB_ForceSkin", nil)
-- The record lives in the check store (HFB_Studio_PlayersCheck/player_<id>); "load" removes it at the end.
local phase = ...
local RunService = game:GetService("RunService")
if not RunService:IsRunning() then
	print("SkinCheck3: install with checks/Saving.lua in edit mode, then run the two play calls")
else
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local SSS = game:GetService("ServerScriptService")
	local HttpService = game:GetService("HttpService")
	local Config = require(ReplicatedStorage.Shared.Config)
	local Ids = require(ReplicatedStorage.Shared.Ids)
	local Skin = require(ReplicatedStorage.Shared.Skin)
	local TestHooks = require(ReplicatedStorage.Shared.TestHooks)
	local Session = require(SSS.Data.Session)
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
		print(("SkinCheck3: %s %s/%s%s"):format(ok and "PASS" or "FAIL", tostring(phase), what, detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
	end
	local function j(v: any): string
		local ok, s = pcall(HttpService.JSONEncode, HttpService, v)
		return ok and s or tostring(v)
	end
	local SAVED = Schema.copy(Config.Data)

	local P = Players:GetPlayers()[1]
	local t0 = os.clock()
	while (not P or Session.state(P) == nil or Session.state(P) == "loading") and os.clock() - t0 < 30 do
		task.wait(0.1)
		P = Players:GetPlayers()[1]
	end
	local uid0 = P.UserId

	-- The fixed content both sessions expect: one boss of every zone on spots, a crate, numbers, flags.
	local function expected(): any
		local e = { bosses = {}, crate = {} }
		for z = 1, 6 do
			table.insert(e.bosses, { uid = ("%d-sk%d"):format(uid0, z), creatureId = Ids.creature(z, z), level = z, spot = z, padCash = z * 10, padStamp = 1000 + z })
		end
		table.insert(e.crate, { uid = ("%d-sk9"):format(uid0), creatureId = Ids.creature(6, 1), level = 2 })
		e.power, e.cash, e.strengthLevel, e.speedLevel = 31337, 4200, 7, 4
		return e
	end
	local function strip(r: any): any
		local c = Schema.copy(r)
		c.lock, c.leftAt, c.spots, c.carry = nil, nil, nil, nil
		return c
	end

	local function run()
		T.leave(P, "check")
		Config.Data.STORE_BASE = "PlayersCheck"
		Config.Data.STUDIO_TAKE_LOCK_ON_JOIN = true
		T.join(P)
		check(Session.state(P) == "live", "on the check store", Store.storeName())
		if phase == "save" then
			check(Skin.Id == "brickbrawl", "this session runs the real skin", Skin.Id)
			Session.wipe(P)
			local e = expected()
			local ok = Session.mutate(P, function(q)
				q.bosses, q.crate = e.bosses, e.crate
				q.power, q.cash, q.strengthLevel, q.speedLevel = e.power, e.cash, e.strengthLevel, e.speedLevel
				q.flags.Joined = true
			end)
			check(ok, "content set")
			local st = T.leave(P, "check")
			local _, rec = T.rawRead(uid0)
			check(st == "saved" and rec and #rec.bosses == 6, "saved under brickbrawl", st)
			print("SkinCheck3: record " .. j(strip(rec)))
		elseif phase == "load" then
			check(Skin.Id == "stub", "this session runs the stub (HFB_ForceSkin armed)", Skin.Id)
			local _, rec = T.rawRead(uid0)
			local p = Session.get(P) :: any
			local e = expected()
			check(Schema.equal(p.bosses, e.bosses) and Schema.equal(p.crate, e.crate), "bosses and crate load unchanged under the stub", j(p.bosses))
			check(p.power == e.power and p.cash == e.cash and p.strengthLevel == e.strengthLevel and p.speedLevel == e.speedLevel and p.flags.Joined == true, "numbers and flags load unchanged")
			local missing = {}
			for _, list in ipairs({ p.bosses, p.crate }) do
				for _, b in ipairs(list) do
					if Skin.Names == nil or Skin.Names.creatures == nil or Skin.Names.creatures[b.creatureId] == nil then
						table.insert(missing, b.creatureId)
					end
				end
			end
			check(#missing == 0, "every saved id resolves in the stub skin", table.concat(missing, ","))
			-- A save under the stub writes the same record (nothing skin-dependent creeps in).
			local before = strip(rec)
			T.leave(P, "check")
			local _, rec2 = T.rawRead(uid0)
			check(Schema.equal(before, strip(rec2)), "a save under the stub writes the same record")
			T.rawRemove(uid0)
			T.join(P)
		else
			check(false, "unknown phase " .. tostring(phase))
		end
	end
	local ok, err = pcall(run)
	if not ok then
		check(false, "the check errored", err)
	end
	pcall(function()
		T.leave(P, "check")
	end)
	for k, v in pairs(SAVED) do
		(Config.Data :: any)[k] = Schema.copy(v)
	end
	T.join(P)
	check(Store.storeName() == "HFB_Studio_Players" and Session.state(P) ~= nil, "restored: normal store", Store.storeName())
	print(("CHECK SkinCheck3/%s pass=%d fail=%d"):format(tostring(phase), pass, fail))
	local _ = TestHooks
end
