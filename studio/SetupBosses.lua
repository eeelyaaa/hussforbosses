if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-12 SetupBosses: builds Chomp Frog (Boss_z1_t1) on the zone 1 fixed pad, to m1-contract.md section G.
--   * Source meshes: the first Model/Folder under ServerStorage.BossScratch that holds BaseParts named exactly Body, Head, Sig,
--     FistL, FistR (the importer's output for the atlas route; the main session imports there, MS-A3). With none, part-built
--     stand-ins of the five groups are made in ServerStorage.BossScratch.z1_t1_standin (attribute StandIn) and used, so the
--     joints, pivots and placement can be tested before the meshes exist. A real import always wins over the stand-in.
--   * Pivots are read at run time from studio/data/z1_t1.groups.lua (guard line + the JSON in a block comment, a copy of assets-src/models/z1_t1.groups.json; refresh it
--     with `python tools/sync_group_data.py` after the modeler changes a pivot). Nothing about a pivot is written in this script.
--     The JSON's "pivot_studs_roblox_offset_from_model_pivot" is measured from the model pivot = the middle of the feet.
--   * Where the feet are: horizontally the Body's own pivot, vertically the lowest point of the five parts. (Assumption to check
--     at M1-17: the importer keeps Blender's origin as the Body's pivot.) The script prints INFO lines for it.
--   * Joints (M1-09's rule): one Motor6D per non-root group under Body, Part0 = Body, Part1 = group, C0 = the pivot in Body's frame,
--     C1 = the pivot in the group's frame, both with identity rotation, so Transform = identity is the rest pose and nothing else
--     moves the model. Body.PivotOffset = the middle of the feet. Body anchored, the rest welded by the joints, CanCollide off, Massless.
--   * Route: atlas (one mesh per group). The per-role route is not built until B4 picks it (its meshes are named Body_g1 etc).
-- Idempotent: replaces Fixed's boss each run. Needs BuildSlice.lua first.
--   require(game.ServerStorage.DevSync:Clone()).run("SetupBosses.lua")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local ID, MODEL_NAME, BODY_TYPE, H = "z1_t1", "Boss_z1_t1", 2, 4
local GROUPS = { "Body", "Head", "Sig", "FistL", "FistR" } -- contract G; Body is the root
local fails = 0
local function check(label, ok, extra)
	print(("SetupBosses: %s %s%s"):format(ok and "PASS" or "FAIL", label, extra and (" (" .. extra .. ")") or ""))
	if not ok then fails += 1 end
end

local data = HttpService:JSONDecode(HttpService:GetAsync("http://127.0.0.1:34874/studio/data/" .. ID .. ".groups.lua", true):match("%-%-%[==%[(.*)%]==%]"))
local pivots = {}
for _, g in ipairs(GROUPS) do
	local d = data.groups[g]
	pivots[g] = d and Vector3.new(table.unpack(d.pivot_studs_roblox_offset_from_model_pivot)) or nil
end
do
	local n, same = 0, true
	for k in pairs(data.groups) do n += 1; if not pivots[k] then same = false end end
	check("groups.json groups are exactly Body, Head, Sig, FistL, FistR", same and n == #GROUPS)
end

local Fixed = workspace.Zones.Z1.Pads.Fixed
local anchor = Fixed:FindFirstChild("BossAnchor")
check("Fixed.BossAnchor exists (run BuildSlice.lua first)", anchor ~= nil)
if not anchor then error("SetupBosses: no BossAnchor", 0) end

-- ---------------------------------------------------------------- source
local scratch = ServerStorage:FindFirstChild("BossScratch")
if not scratch then
	scratch = Instance.new("Folder"); scratch.Name = "BossScratch"; scratch.Parent = ServerStorage
end
local function hasAll(c)
	for _, g in ipairs(GROUPS) do
		local p = c:FindFirstChild(g)
		if not (p and p:IsA("BasePart")) then return false end
	end
	return true
end
local function findSource(preferReal)
	for _, d in ipairs(scratch:GetDescendants()) do
		if (d:IsA("Model") or d:IsA("Folder")) and hasAll(d) and (d:GetAttribute("StandIn") == true) ~= preferReal then return d end
	end
end
local src = findSource(true)
if src then
	local old = scratch:FindFirstChild(ID .. "_standin")
	if old then old:Destroy() end
else
	local old = scratch:FindFirstChild(ID .. "_standin")
	if old then old:Destroy() end
	-- stand-ins: boxes where the groups are (sizes from the M1-09 box rig); origins are NOT at the pivots, to prove the maths
	local m = Instance.new("Model"); m.Name = ID .. "_standin"; m:SetAttribute("StandIn", true)
	local function box(name, size, centre, col)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = CFrame.new(centre)
		p.Color = col; p.Material = Enum.Material.SmoothPlastic; p.Anchored = true; p.Parent = m
		return p
	end
	local green, dark = Color3.fromRGB(95, 160, 60), Color3.fromRGB(70, 125, 45)
	local body = box("Body", Vector3.new(6, 2.4, 3.2), Vector3.new(10, 1.2 + 5, 10), green) -- origin at its centre; placed away from the origin on purpose
	body.PivotOffset = CFrame.new(0, -1.2, 0) -- Body pivot at the middle of the feet
	local feet = Vector3.new(10, 5, 10)
	box("Head", Vector3.new(6, 1.6, 2.6), feet + Vector3.new(0, 2.4, 0), green)
	box("Sig", Vector3.new(5, 0.8, 2.2), feet + Vector3.new(0, 1.8, -0.6), Color3.fromRGB(225, 110, 150))
	box("FistL", Vector3.new(1.4, 1.4, 1.4), feet + Vector3.new(-2.2, 1.7, -0.4), dark)
	box("FistR", Vector3.new(1.4, 1.4, 1.4), feet + Vector3.new(2.2, 1.7, -0.4), dark)
	m.Parent = scratch
	src = m
end
local isStandIn = src:GetAttribute("StandIn") == true
print("SetupBosses: INFO source " .. src:GetFullName() .. (isStandIn and " (STAND-IN parts, no real meshes imported yet)" or " (imported meshes)"))
check("source has the five groups as BaseParts, each its own part", hasAll(src))

-- ---------------------------------------------------------------- build
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
print(("SetupBosses: INFO feet at (%.3f, %.3f, %.3f); Body pivot y %.3f (assumption: the Body's pivot is the feet, so these agree)"):format(feet.X, feet.Y, feet.Z, bp.Y, 0))
local F = CFrame.new(feet) * srcBody.CFrame.Rotation -- model frame: origin at the feet, rotated like the Body

local model = Instance.new("Model")
model.Name = MODEL_NAME
local parts = {}
for _, g in ipairs(GROUPS) do
	local p = src[g]:Clone()
	p.CFrame = F:ToObjectSpace(src[g].CFrame) -- rebuilt in the model frame (origin = feet)
	p.PivotOffset = CFrame.identity
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.Massless = true
	if p:IsA("MeshPart") and p.TextureID ~= "" then
		-- M1-17: MeshPart.Color multiplies the atlas texture; the importer leaves the default grey (163,162,165), which dulled the cream
		-- to a grey-green. The atlas carries every colour, so the tint must be white. Matte, no reflectance.
		p.Color = Color3.new(1, 1, 1)
		p.Material = Enum.Material.SmoothPlastic
		p.Reflectance = 0
	end
	p.Parent = model
	parts[g] = p
end
local body = parts.Body
body.Anchored = true
body.PivotOffset = CFrame.new(body.CFrame:PointToObjectSpace(Vector3.zero)) -- the middle of the feet
model.PrimaryPart = body

local rotOk = true
for _, g in ipairs(GROUPS) do
	if g ~= "Body" then
		local pw = pivots[g]
		local m = Instance.new("Motor6D")
		m.Name = g
		m.Part0 = body
		m.Part1 = parts[g]
		m.C0 = body.CFrame:ToObjectSpace(CFrame.new(pw))
		m.C1 = parts[g].CFrame:ToObjectSpace(CFrame.new(pw))
		m.Parent = body
		if not (m.C0.Rotation:FuzzyEq(CFrame.identity, 1e-4) and m.C1.Rotation:FuzzyEq(CFrame.identity, 1e-4)) then rotOk = false end
		local rest = body.CFrame * m.C0 * m.C1:Inverse()
		check("rest pose of " .. g .. " (Body * C0 * C1^-1 = its CFrame)", rest:FuzzyEq(parts[g].CFrame, 1e-4))
	end
end
check("joints have identity rotation in C0 and C1 (M1-09)", rotOk)

model:SetAttribute("CreatureId", ID)
model:SetAttribute("BodyType", BODY_TYPE)
model:SetAttribute("H", H)
CollectionService:AddTag(model, "HFB_Boss")
model.Parent = Fixed
model:PivotTo(CFrame.new(anchor.Position)) -- the Body pivot (middle of the feet) stands on the BossAnchor

-- ---------------------------------------------------------------- checks
local names, ok = {}, true
for _, c in ipairs(model:GetChildren()) do if c:IsA("BasePart") then names[c.Name] = true end end
for _, g in ipairs(GROUPS) do if not names[g] then ok = false end end
check("model " .. MODEL_NAME .. " has exactly the groups Body, Head, Sig, FistL, FistR", ok and #model:GetChildren() == #GROUPS)
check("PrimaryPart = Body, Body anchored, the other four unanchored, massless, no collision", model.PrimaryPart == body and body.Anchored and not parts.Head.Anchored and not parts.Sig.Anchored and not parts.FistL.Anchored and not parts.FistR.Anchored and parts.Head.Massless and not parts.Head.CanCollide and not body.CanCollide)
check("4 Motor6Ds under Body named after their group", #body:GetChildren() == 4 and body:FindFirstChild("Head") and body.Head:IsA("Motor6D") and body:FindFirstChild("Sig") and body:FindFirstChild("FistL") and body:FindFirstChild("FistR"))
check("model pivot (Body pivot) is at BossAnchor", (model:GetPivot().Position - anchor.Position).Magnitude < 1e-3)
check("attributes CreatureId/BodyType/H and tag HFB_Boss", model:GetAttribute("CreatureId") == ID and model:GetAttribute("BodyType") == BODY_TYPE and model:GetAttribute("H") == H and CollectionService:HasTag(model, "HFB_Boss"))
local _, bsz = model:GetBoundingBox()
print(("SetupBosses: INFO bounding box %.2f x %.2f x %.2f studs (expected 6.8 x 4.0 x 3.0 per groups.json; H = %d)"):format(bsz.X, bsz.Y, bsz.Z, H))
local tris = 0
for _, g in ipairs(GROUPS) do
	local p = parts[g]
	if p:IsA("MeshPart") then print(("SetupBosses: MESHID %s %s (wire into Skins/brickbrawl/Models.lua creatures.%s.groups)"):format(g, p.MeshId, ID)) end
end
print(("SetupBosses: %s, %d failed (%s)"):format(fails == 0 and "PASS" or "FAIL", fails, isStandIn and "on stand-in parts" or "on imported meshes"))
