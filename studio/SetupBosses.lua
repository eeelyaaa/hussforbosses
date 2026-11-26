if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- SetupBosses (M1-12 frog, extended M2-25): builds every boss that has imported meshes into Boss_<id> on its zone's Fixed pad.
--   z1_t1 Chomp Frog (squat stomper: Body Head Sig FistL FistR), z2_t2 Snap Scorpion and z5_t5 Ember Drake (tailed striker: Body Head FistL FistR
--   TailA TailB), z3_t3 Bit Shark (rearing swayer: Body Upper Head FistL FistR), z4_t4 Frost Byte and z6_t6 Star Golem (biped bruiser: Body Head FistL
--   FistR, + Sig on the golem). Each group list is checked against the keys of studio/data/<id>.groups.lua (a copy of assets-src/models/<id>.groups.json;
--   refresh with `python tools/sync_group_data.py`).
--   * Source: BossScratch.<id>_atlas (the main session's import). Only z1_t1 falls back to part-built stand-ins; an M2 boss with no import FAILs.
--   * Pivots come from the groups data at run time; none is written here. Model pivot = the middle of the feet = the Body pivot horizontally, the lowest
--     point of all groups vertically.
--   * Joints (M1-09): one flat Motor6D per non-root group under Body (Part0 Body, C0 = pivot in Body frame, C1 = pivot in the group frame, identity
--     rotation, Transform identity = rest). Flat is what Shared/Moves/_geo.lua and _lib `expand` expect: TailB rides TailA and Head/fists ride Upper by
--     computing, not by nesting Motor6Ds. Body anchored, the rest unanchored, massless, no collision; Body.PivotOffset = the feet.
--   * Textured MeshParts: Color white, SmoothPlastic, Reflectance 0 (M1-17); TextureID = Models.lua creatures.<id>.textureId (the shared owned atlas),
--     replacing the importer's own copy.
-- Re-runnable: replaces the boss on each pad. Needs BuildSlice.lua and BuildStrip.lua first.
--   require(game.ServerStorage.DevSync:Clone()).run("SetupBosses.lua")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BOSSES = { -- id, zone, body type, tier height H, groups (Body is the root)
	{ id = "z1_t1", zone = 1, bt = 2, H = 4,    groups = { "Body", "Head", "Sig", "FistL", "FistR" } },
	{ id = "z2_t2", zone = 2, bt = 3, H = 5.3,  groups = { "Body", "Head", "FistL", "FistR", "TailA", "TailB" } },
	{ id = "z3_t3", zone = 3, bt = 5, H = 6.8,  groups = { "Body", "Upper", "Head", "FistL", "FistR" } },
	{ id = "z4_t4", zone = 4, bt = 1, H = 8.3,  groups = { "Body", "Head", "FistL", "FistR" } },
	{ id = "z5_t5", zone = 5, bt = 3, H = 10.9, groups = { "Body", "Head", "FistL", "FistR", "TailA", "TailB" } },
	{ id = "z6_t6", zone = 6, bt = 1, H = 14,   groups = { "Body", "Head", "FistL", "FistR", "Sig" } },
}
local fails = 0
local LOG = {} -- also left in ServerStorage attribute SetupBossesLog (the console buffer truncates a run this long); read it, then clear it
local function say(l) print(l); table.insert(LOG, l) end
local function check(label, ok, extra)
	say(("SetupBosses: %s %s%s"):format(ok and "PASS" or "FAIL", label, extra and (" (" .. extra .. ")") or ""))
	if not ok then fails += 1 end
end

local skinTex = {}
do
	local mod = ReplicatedStorage:FindFirstChild("Skins") and ReplicatedStorage.Skins:FindFirstChild("brickbrawl") and ReplicatedStorage.Skins.brickbrawl:FindFirstChild("Models")
	local ok, M = pcall(function() return require(mod) end)
	if ok and type(M) == "table" then
		for id, c in pairs(M.creatures) do skinTex[id] = c.textureId end
	else
		say("SetupBosses: INFO Skins/brickbrawl/Models not loadable (sync src/ first); using the importer's textures")
	end
end

local scratch = ServerStorage:FindFirstChild("BossScratch")
if not scratch then scratch = Instance.new("Folder"); scratch.Name = "BossScratch"; scratch.Parent = ServerStorage end

local function setup(B)
	local ID, MODEL_NAME, GROUPS = B.id, "Boss_" .. B.id, B.groups
	local tag = ID .. " "
	local data = HttpService:JSONDecode(HttpService:GetAsync("http://127.0.0.1:34874/studio/data/" .. ID .. ".groups.lua", true):match("%-%-%[==%[(.*)%]==%]"))
	local pivots = {}
	for _, g in ipairs(GROUPS) do
		local d = data.groups[g]
		pivots[g] = d and Vector3.new(table.unpack(d.pivot_studs_roblox_offset_from_model_pivot)) or nil
	end
	do
		local n, same = 0, true
		for k in pairs(data.groups) do n += 1; if not pivots[k] then same = false end end
		check(tag .. "groups.json groups are exactly " .. table.concat(GROUPS, ", "), same and n == #GROUPS)
	end

	local padsF = workspace.Zones:FindFirstChild("Z" .. B.zone) and workspace.Zones["Z" .. B.zone].Pads
	local Fixed = padsF and padsF:FindFirstChild("Fixed")
	local anchor = Fixed and Fixed:FindFirstChild("BossAnchor")
	check(tag .. "Z" .. B.zone .. " Fixed.BossAnchor exists (BuildSlice/BuildStrip first)", anchor ~= nil)
	if not anchor then return end

	local function hasAll(c)
		for _, g in ipairs(GROUPS) do
			local p = c:FindFirstChild(g)
			if not (p and p:IsA("BasePart")) then return false end
		end
		return true
	end
	local src, standIn
	for _, d in ipairs(scratch:GetChildren()) do
		if (d:IsA("Model") or d:IsA("Folder")) and hasAll(d) and d:GetAttribute("StandIn") ~= true and (d.Name:sub(1, #ID) == ID) then src = d break end
	end
	if not src and ID == "z1_t1" then
		for _, d in ipairs(scratch:GetChildren()) do
			if (d:IsA("Model") or d:IsA("Folder")) and hasAll(d) and d:GetAttribute("StandIn") ~= true and d.Name ~= "gloves_atlas" and not d.Name:match("^z[2-6]_") then src = d break end
		end
	end
	if not src and ID == "z1_t1" then
		local old = scratch:FindFirstChild(ID .. "_standin")
		if old then old:Destroy() end
		local m = Instance.new("Model"); m.Name = ID .. "_standin"; m:SetAttribute("StandIn", true)
		local function box(name, size, centre, col)
			local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = CFrame.new(centre)
			p.Color = col; p.Material = Enum.Material.SmoothPlastic; p.Anchored = true; p.Parent = m
			return p
		end
		local green, dark = Color3.fromRGB(95, 160, 60), Color3.fromRGB(70, 125, 45)
		local body = box("Body", Vector3.new(6, 2.4, 3.2), Vector3.new(10, 6.2, 10), green)
		body.PivotOffset = CFrame.new(0, -1.2, 0)
		local f = Vector3.new(10, 5, 10)
		box("Head", Vector3.new(6, 1.6, 2.6), f + Vector3.new(0, 2.4, 0), green)
		box("Sig", Vector3.new(5, 0.8, 2.2), f + Vector3.new(0, 1.8, -0.6), Color3.fromRGB(225, 110, 150))
		box("FistL", Vector3.new(1.4, 1.4, 1.4), f + Vector3.new(-2.2, 1.7, -0.4), dark)
		box("FistR", Vector3.new(1.4, 1.4, 1.4), f + Vector3.new(2.2, 1.7, -0.4), dark)
		m.Parent = scratch
		src, standIn = m, true
	end
	if not src then say("SetupBosses: INFO " .. ID .. " has no imported meshes in BossScratch; skipped"); fails += 1; check(tag .. "imported meshes present", false); return end
	say("SetupBosses: INFO " .. tag .. "source " .. src:GetFullName() .. (standIn and " (STAND-IN parts)" or " (imported meshes)"))
	check(tag .. "source has the groups as BaseParts", hasAll(src))

	local old = Fixed:FindFirstChild(MODEL_NAME)
	if old then old:Destroy() end
	local oldB = Fixed:FindFirstChild("Boss")
	if oldB then oldB:Destroy() end

	local srcBody = src.Body
	local lowY = math.huge
	for _, g in ipairs(GROUPS) do
		local p = src[g]
		local cf, sz = p.CFrame, p.Size
		for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz2 = -1, 1, 2 do
			lowY = math.min(lowY, cf:PointToWorldSpace(Vector3.new(sx * sz.X / 2, sy * sz.Y / 2, sz2 * sz.Z / 2)).Y)
		end end end
	end
	local bp = srcBody:GetPivot().Position
	local feet = Vector3.new(bp.X, lowY, bp.Z)
	say(("SetupBosses: INFO %sfeet at (%.3f, %.3f, %.3f); Body pivot y %.3f"):format(tag, feet.X, feet.Y, feet.Z, bp.Y))
	local F = CFrame.new(feet) * srcBody.CFrame.Rotation

	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	local parts = {}
	for _, g in ipairs(GROUPS) do
		local p = src[g]:Clone()
		p.CFrame = F:ToObjectSpace(src[g].CFrame)
		p.PivotOffset = CFrame.identity
		p.Anchored = false; p.CanCollide = false; p.CanTouch = false; p.Massless = true
		if p:IsA("MeshPart") and p.TextureID ~= "" then
			if skinTex[ID] then p.TextureID = "rbxassetid://" .. tostring(skinTex[ID]) end
			p.Color = Color3.new(1, 1, 1)
			p.Material = Enum.Material.SmoothPlastic
			p.Reflectance = 0
		end
		p.Parent = model
		parts[g] = p
	end
	local body = parts.Body
	body.Anchored = true
	body.PivotOffset = CFrame.new(body.CFrame:PointToObjectSpace(Vector3.zero))
	model.PrimaryPart = body

	local rotOk = true
	for _, g in ipairs(GROUPS) do
		if g ~= "Body" then
			local pw = pivots[g]
			local m = Instance.new("Motor6D")
			m.Name = g; m.Part0 = body; m.Part1 = parts[g]
			m.C0 = body.CFrame:ToObjectSpace(CFrame.new(pw))
			m.C1 = parts[g].CFrame:ToObjectSpace(CFrame.new(pw))
			m.Parent = body
			if not (m.C0.Rotation:FuzzyEq(CFrame.identity, 1e-4) and m.C1.Rotation:FuzzyEq(CFrame.identity, 1e-4)) then rotOk = false end
			check(tag .. "rest pose of " .. g, (body.CFrame * m.C0 * m.C1:Inverse()):FuzzyEq(parts[g].CFrame, 1e-4))
		end
	end
	check(tag .. "joints have identity rotation in C0 and C1 (M1-09)", rotOk)

	model:SetAttribute("CreatureId", ID)
	model:SetAttribute("BodyType", B.bt)
	model:SetAttribute("H", B.H)
	CollectionService:AddTag(model, "HFB_Boss")
	-- M2-34: with StreamingEnabled the boss must arrive whole (BossMoves needs every group; BossVisuals clones these as the templates for every
	-- boss in the game, so they must be on the client wherever the player stands). Six small models: Persistent (TEAM CALL M2-34-1).
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = Fixed
	model:PivotTo(CFrame.new(anchor.Position))

	local names, ok = {}, true
	for _, c in ipairs(model:GetChildren()) do if c:IsA("BasePart") then names[c.Name] = true end end
	for _, g in ipairs(GROUPS) do if not names[g] then ok = false end end
	check(tag .. "model " .. MODEL_NAME .. " has exactly the groups " .. table.concat(GROUPS, ", "), ok and #model:GetChildren() == #GROUPS)
	local unanch = true
	for g, p in pairs(parts) do if g ~= "Body" and (p.Anchored or not p.Massless or p.CanCollide) then unanch = false end end
	check(tag .. "PrimaryPart = Body, anchored; the others unanchored, massless, no collision", model.PrimaryPart == body and body.Anchored and not body.CanCollide and unanch)
	local joints = 0
	for _, g in ipairs(GROUPS) do if g ~= "Body" and body:FindFirstChild(g) and body[g]:IsA("Motor6D") then joints += 1 end end
	check(tag .. (#GROUPS - 1) .. " Motor6Ds under Body named after their group", joints == #GROUPS - 1 and #body:GetChildren() == #GROUPS - 1)
	check(tag .. "model pivot is at BossAnchor", (model:GetPivot().Position - anchor.Position).Magnitude < 1e-3)
	check(tag .. "attributes CreatureId/BodyType/H and tag HFB_Boss", model:GetAttribute("CreatureId") == ID and model:GetAttribute("BodyType") == B.bt and model:GetAttribute("H") == B.H and CollectionService:HasTag(model, "HFB_Boss"))
	check(tag .. "ModelStreamingMode is Persistent (M2-34)", model.ModelStreamingMode == Enum.ModelStreamingMode.Persistent)
	local _, bsz = model:GetBoundingBox()
	local lowest = math.huge
	for _, p in pairs(parts) do
		local cf, sz = p.CFrame, p.Size
		for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz2 = -1, 1, 2 do
			lowest = math.min(lowest, cf:PointToWorldSpace(Vector3.new(sx * sz.X / 2, sy * sz.Y / 2, sz2 * sz.Z / 2)).Y)
		end end end
	end
	say(("SetupBosses: INFO %sbounding box %.2f x %.2f x %.2f studs (H %s); lowest corner %.3f studs from the pad top; anchor y %.2f"):format(tag, bsz.X, bsz.Y, bsz.Z, tostring(B.H), lowest - anchor.Position.Y, anchor.Position.Y))
	check(tag .. "the feet stand on the pad (lowest corner within 0.05 studs of the BossAnchor)", math.abs(lowest - anchor.Position.Y) < 0.05)
	local tris = 0
	for _, g in ipairs(GROUPS) do
		local p = parts[g]
		if p:IsA("MeshPart") then say(("SetupBosses: MESHID %s%s %s"):format(tag, g, p.MeshId)) end
	end
end

for _, B in ipairs(BOSSES) do
	local ok, err = pcall(setup, B)
	if not ok then check(B.id .. " setup ran without error", false, tostring(err)) end
end
say(("SetupBosses: %s, %d failed"):format(fails == 0 and "PASS" or "FAIL", fails))
ServerStorage:SetAttribute("SetupBossesLog", table.concat(LOG, string.char(10)))
