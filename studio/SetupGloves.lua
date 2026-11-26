if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-12 SetupGloves: builds ReplicatedStorage.Gloves with children GloveL and GloveR, each pivoted at the wrist (m1-contract.md
-- sections G and J; M1-10's Avatar welds them to the hands). Meshes come from the first Model/Folder under ServerStorage.BossScratch
-- that holds BaseParts named GloveL and GloveR; with none, red box stand-ins are made. Wrist positions are read at run time from
-- studio/data/gloves.groups.lua ("pivot_studs_roblox_offset_from_model_pivot", from the model pivot between the two gloves).
-- Each glove: PivotOffset = the wrist in its own frame, Anchored off, Massless, no collision, no query, no touch. The model's
-- PrimaryPart is GloveL. Matte, no variant (no studs on anything worn).
--   require(game.ServerStorage.DevSync:Clone()).run("SetupGloves.lua")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local fails = 0
local function check(label, ok)
	print(("SetupGloves: %s %s"):format(ok and "PASS" or "FAIL", label))
	if not ok then fails += 1 end
end

local data = HttpService:JSONDecode(HttpService:GetAsync("http://127.0.0.1:34874/studio/data/gloves.groups.lua", true):match("%-%-%[==%[(.*)%]==%]"))
local wrist = {}
for _, g in ipairs({ "GloveL", "GloveR" }) do
	local d = data.groups[g]
	wrist[g] = Vector3.new(table.unpack(d.pivot_studs_roblox_offset_from_model_pivot))
end

local scratch = ServerStorage:FindFirstChild("BossScratch")
if not scratch then scratch = Instance.new("Folder"); scratch.Name = "BossScratch"; scratch.Parent = ServerStorage end
local src
for _, d in ipairs(scratch:GetDescendants()) do
	if (d:IsA("Model") or d:IsA("Folder")) and d:GetAttribute("StandIn") ~= true and d:FindFirstChild("GloveL") and d:FindFirstChild("GloveR")
		and d.GloveL:IsA("BasePart") and d.GloveR:IsA("BasePart") then src = d; break end
end
local isStandIn = false
local old = scratch:FindFirstChild("gloves_standin")
if old then old:Destroy() end
if not src then
	isStandIn = true
	local rs = RS:FindFirstChild("Skins")
	local red = Color3.fromRGB(224, 42, 42)
	if rs and rs:FindFirstChild("brickbrawl") then red = require(rs.brickbrawl.Tokens).colors.hussRed end
	local m = Instance.new("Model"); m.Name = "gloves_standin"; m:SetAttribute("StandIn", true)
	for g, w in pairs(wrist) do
		local p = Instance.new("Part"); p.Name = g; p.Size = Vector3.new(1.26, 1.26, 1.26)
		p.CFrame = CFrame.new(w * 1.5) -- origin at its centre, not at the wrist, on purpose
		p.Color = red; p.Material = Enum.Material.SmoothPlastic; p.Anchored = true; p.Parent = m
	end
	m.Parent = scratch
	src = m
end
print("SetupGloves: INFO source " .. src:GetFullName() .. (isStandIn and " (STAND-IN boxes)" or " (imported meshes)"))

local oldG = RS:FindFirstChild("Gloves")
if oldG then oldG:Destroy() end
local model = Instance.new("Model"); model.Name = "Gloves"
-- model frame: origin midway between the two source parts' pivots minus the json offsets (the model pivot of groups.json)
local l, r = src.GloveL, src.GloveR
local origin = ((l:GetPivot().Position - wrist.GloveL) + (r:GetPivot().Position - wrist.GloveR)) / 2
for _, g in ipairs({ "GloveL", "GloveR" }) do
	local p = src[g]:Clone()
	p.CFrame = CFrame.new(-origin) * src[g].CFrame
	p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
	if p:IsA("MeshPart") and p.TextureID ~= "" then p.Color = Color3.new(1, 1, 1); p.Material = Enum.Material.SmoothPlastic; p.Reflectance = 0 end -- M1-17: the tint multiplies the atlas texture
	p.PivotOffset = CFrame.new(p.CFrame:PointToObjectSpace(wrist[g])) -- the wrist, in the glove's own frame
	p.Parent = model
end
model.PrimaryPart = model.GloveL
model.Parent = RS

for _, g in ipairs({ "GloveL", "GloveR" }) do
	local p = model[g]
	check(g .. " pivot is at the wrist offset " .. tostring(wrist[g]), (p:GetPivot().Position - wrist[g]).Magnitude < 1e-3)
end
check("Gloves has exactly the children GloveL, GloveR", #model:GetChildren() == 2 and model:FindFirstChild("GloveL") and model:FindFirstChild("GloveR"))
local _, sz = model:GetBoundingBox()
print(("SetupGloves: INFO bounding box %.2f x %.2f x %.2f studs (groups.json: 3.92 x 1.26 x 1.26 for the pair)"):format(sz.X, sz.Y, sz.Z))
for _, g in ipairs({ "GloveL", "GloveR" }) do
	if model[g]:IsA("MeshPart") then print(("SetupGloves: MESHID %s %s (Models.lua gloves.groups)"):format(g, model[g].MeshId)) end
end
print(("SetupGloves: %s, %d failed (%s)"):format(fails == 0 and "PASS" or "FAIL", fails, isStandIn and "on stand-ins" or "on imported meshes"))
