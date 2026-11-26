if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- The skin check, part 2 setup and the Skin API checks (team/requirements/m1-core-loop-gate.md, "The skin check";
-- M1-01). Edit mode, holding the studio lock:
--   require(game.ServerStorage.DevSync:Clone()).run("CheckSkin.lua")
-- Part 1 of the skin check is the repo scan: python tools/check_skin.py (exit 0).
--
-- What this script does, printing PASS/FAIL lines and a summary:
--   A. Skin.check on the stub skin and on brickbrawl: every key of m1-contract.md section F, with its type.
--   B. Skin.shapeDiff(brickbrawl, stub): the two skins have the same keys (the stub mirrors brickbrawl).
--   C. Skin API: get -> nil on a missing key, need -> an error naming it (no silent default).
--   D. ForceSkin: with HFB_ForceSkin = "stub", a fresh Shared/Skin loads the stub.
--   E. Builds the stub boss "Boss_z1_t1_stub" (five grey groups, Ids.GROUPS) in ServerStorage.HFB_SkinCheck.
--   F. ARMS part 2: leaves HFB_ForceSkin = "stub" set, so the next play session runs under the stub. Then:
--        start play, run studio/checks/CoreLoop.lua with skin "stub" (M1-16), stop play, and DISARM in edit mode:
--        workspace:SetAttribute("HFB_ForceSkin", nil); local f = game.ServerStorage:FindFirstChild("HFB_SkinCheck"); if f then f:Destroy() end
--      Set HFB_CheckSkinNoArm = true on Workspace before running to skip F (part 1 only).
-- Everything is required from fresh clones of Shared + Skins, so edit-mode module caching never hides a change.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local failed, passed = 0, 0
local function result(ok, what, detail)
	if ok then
		passed += 1
	else
		failed += 1
	end
	print(("CheckSkin: %s %s%s"):format(ok and "PASS" or "FAIL", what, detail and (" (" .. detail .. ")") or ""))
end
local function listOut(label, items, max)
	for i, s in ipairs(items) do
		if i > max then
			print(("CheckSkin:   ... %d more"):format(#items - max))
			break
		end
		print("CheckSkin:   " .. label .. ": " .. s)
	end
end

local HOOK = "HFB_ForceSkin"
local prior = workspace:GetAttribute(HOOK)
if prior ~= nil then
	warn("CheckSkin: HFB_ForceSkin was already set to " .. tostring(prior) .. "; cleared for the checks")
	workspace:SetAttribute(HOOK, nil)
end
local old = ServerStorage:FindFirstChild("HFB_SkinCheck")
if old then
	old:Destroy()
end
local scratch = Instance.new("Folder")
scratch.Name = "HFB_SkinCheck_tmp"
scratch.Parent = ServerStorage

-- A fresh, coherent copy of Shared + Skins (Skin.load finds Skins beside Shared), so edit-mode module caching
-- never hides a change and the stub's Ids come from the same copy.
local function freshRoot()
	local root = Instance.new("Folder")
	root.Name = "Root"
	ReplicatedStorage.Shared:Clone().Parent = root
	ReplicatedStorage.Skins:Clone().Parent = root
	root.Parent = scratch
	return root
end

local ok, err = pcall(function()
	local root = freshRoot()
	local Skin = require(root.Shared.Skin)
	local Ids = require(root.Shared.Ids)
	result(Skin.Id == "brickbrawl", "active skin with no hook is brickbrawl", tostring(Skin.Id))

	local stub = Skin.load("stub")
	local bb = Skin.load("brickbrawl")

	-- A
	local ps = Skin.check(stub)
	result(#ps == 0, "A1 stub skin has every M1 key (" .. #Skin.SCHEMA .. " in the schema)", #ps .. " problems")
	listOut("stub", ps, 25)
	local pb = Skin.check(bb)
	result(#pb == 0, "A2 brickbrawl skin has every M1 key", #pb .. " problems")
	listOut("brickbrawl", pb, 40)

	-- B
	local d = Skin.shapeDiff(bb, stub, "brickbrawl", "stub")
	result(#d == 0, "B  brickbrawl and stub have the same key shape", #d .. " differences")
	listOut("shape", d, 40)

	-- C
	result(Skin.get("Names.noSuchKey.x") == nil, "C1 Skin.get on a missing key is nil")
	local okNeed, msg = pcall(Skin.need, "Names.noSuchKey")
	result(not okNeed and tostring(msg):find("Names.noSuchKey", 1, true) ~= nil, "C2 Skin.need on a missing key errors with its name", tostring(msg))
	local okHave, v = pcall(Skin.need, "Names.creatures.z1_t1")
	result(okHave and v ~= nil and v == (bb.Names.creatures or {}).z1_t1, "C3 Skin.need on a present key returns it")

	-- D
	workspace:SetAttribute(HOOK, "stub")
	local root2 = freshRoot()
	local okStub, Skin2 = pcall(require, root2.Shared.Skin)
	workspace:SetAttribute(HOOK, nil)
	result(okStub and Skin2.Id == "stub", "D1 HFB_ForceSkin = stub loads the stub", okStub and tostring(Skin2.Id) or tostring(Skin2))
	if okStub then
		result(Skin2.Names.creatures.z1_t1 == "z1_t1", "D2 stub names are ids", tostring(Skin2.Names.creatures.z1_t1))
		result(Skin2.Models.creatures.z1_t1.model == "Boss_z1_t1_stub", "D3 stub boss model name", tostring(Skin2.Models.creatures.z1_t1.model))
	end

	-- E: the stub boss: five grey boxes named by Ids.GROUPS, pivot at the feet, H = heightStuds.
	local spec = stub.Models.creatures.z1_t1
	local H = spec.heightStuds
	local folder = Instance.new("Folder")
	folder.Name = "HFB_SkinCheck"
	local model = Instance.new("Model")
	model.Name = spec.model
	local layout = { -- size and centre in fractions of H, about a squat stomper
		Body = { Vector3.new(1, 0.55, 0.8), Vector3.new(0, 0.275, 0) },
		Head = { Vector3.new(0.9, 0.3, 0.7), Vector3.new(0, 0.7, 0) },
		Sig = { Vector3.new(0.8, 0.15, 0.6), Vector3.new(0, 0.5, 0.1) },
		FistL = { Vector3.new(0.3, 0.3, 0.3), Vector3.new(-0.7, 0.35, 0) },
		FistR = { Vector3.new(0.3, 0.3, 0.3), Vector3.new(0.7, 0.35, 0) },
	}
	for _, g in ipairs(Ids.GROUPS) do
		local p = Instance.new("Part")
		p.Name = g
		p.Size = layout[g][1] * H
		p.CFrame = CFrame.new(layout[g][2] * H)
		p.Color = stub.Tokens.colors.panelGrey
		p.Anchored = g == "Body"
		p.CanCollide = false
		p.Massless = g ~= "Body"
		p.Parent = model
		if g ~= "Body" then
			local w = Instance.new("WeldConstraint")
			w.Part0 = model:FindFirstChild("Body") or p
			w.Part1 = p
			w.Parent = p
		end
	end
	model.PrimaryPart = model:FindFirstChild("Body")
	model:SetAttribute("CreatureId", "z1_t1")
	model:SetAttribute("BodyType", spec.bodyType)
	model:SetAttribute("H", H)
	model.Parent = folder
	folder.Parent = ServerStorage
	local names = {}
	for _, c in ipairs(model:GetChildren()) do
		table.insert(names, c.Name)
	end
	table.sort(names)
	local want = table.clone(Ids.GROUPS)
	table.sort(want)
	result(table.concat(names, ",") == table.concat(want, ","), "E1 stub boss has the five groups", table.concat(names, ","))
	local groupKeys = {}
	for k in pairs(spec.groups) do
		table.insert(groupKeys, k)
	end
	table.sort(groupKeys)
	result(table.concat(groupKeys, ",") == table.concat(want, ","), "E2 stub Models groups match Ids.GROUPS")
	result(model.PrimaryPart ~= nil and model.PrimaryPart.Name == "Body", "E3 stub boss PrimaryPart is Body")
end)
if not ok then
	result(false, "the checks ran without an error", tostring(err))
end
scratch:Destroy()

if workspace:GetAttribute("HFB_CheckSkinNoArm") == true then
	workspace:SetAttribute("HFB_CheckSkinNoArm", nil)
	local f = ServerStorage:FindFirstChild("HFB_SkinCheck")
	if f then
		f:Destroy()
	end
	print("CheckSkin: part 2 not armed (HFB_CheckSkinNoArm)")
else
	workspace:SetAttribute(HOOK, "stub")
	print("CheckSkin: ARMED part 2: HFB_ForceSkin = stub. Start play, run checks/CoreLoop.lua with skin 'stub', stop play, then DISARM:")
	print('CheckSkin:   workspace:SetAttribute("HFB_ForceSkin", nil); local f = game.ServerStorage:FindFirstChild("HFB_SkinCheck"); if f then f:Destroy() end')
end
print(("CheckSkin: %s, %d passed, %d failed"):format(failed == 0 and "PASS" or "FAIL", passed, failed))
