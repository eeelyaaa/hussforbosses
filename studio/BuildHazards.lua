if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-11 (scripter-hazardsbase): the stand-in hazards of zones 2..6 and the base's spots 11..17. Greybox only (M3 builds
-- the real hazards). Run AFTER BuildSlice.lua and BuildStrip.lua (BuildSlice wipes Plots and Zones; run this again after
-- it). Idempotent: removes what it made (attribute BuiltBy = "BuildHazards") and rebuilds.
--   require(game.ServerStorage.DevSync:Clone()).run("BuildHazards.lua")
-- Hazards: zone n's throat is Z0 .. Z0 + 30 with Z0 = 236 + 120 (n - 1) (the strip, verification/m2-10b-six-zones.md); the
-- pads start 40 in, so the throat is clear. Each model Workspace.Zones.Z<n>.Hazard_<n> carries tag HFB_Hazard, HazardId n,
-- and TrackHome = CFrame at the lane centre line (X 206), the lane top (Y 0.2), the throat's middle (Z0 + 15), not turned
-- (across = world X). Its parts are the pose at t = 0 from Shared/Hazards.volumes, never colliding, never queried or
-- touched: the server's hit test is the only rule; the client (M2-12) animates them from the same functions.
-- Zone 1 keeps BuildSlice's Rolling Log (HazardId 1).
-- Spots 11..17 (base-layout plot plan items 11 to 13): 11 = left y 68, 12 = right y 68, 13 / 14 / 15 = back row x 21 /
-- 11 / 31, 16 / 17 = back corners x 1 / 41, all y 82..90; cash pads: 11 left x 10..13, 12 right x 37..40 (y 68..76);
-- back row 8 x 3 at y 78..81 under each back spot. Placed in each plot's own frame (from Spot_1, Spot_2, Spot_9).
-- Attributes SpotIndex, SpotKind ("rebirth" | "extra"); tags HFB_Spot, HFB_CashPad. The server sets Unlocked and Glow;
-- the client draws ghosts (11..15 locked) and hides 16, 17 without the pass (M2-12).
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")

local skins = RS:FindFirstChild("Skins")
local tokMod = skins and skins:FindFirstChild("brickbrawl") and skins.brickbrawl:FindFirstChild("Tokens")
if not tokMod then error("BuildHazards: ReplicatedStorage.Skins.brickbrawl.Tokens missing; run the DevSync sync first", 0) end
local Tokens = require(tokMod)
local C = Tokens.colors
local VARIANT = Tokens.stud.variantName
local SH = require(RS.Shared.Hazards)

local fails = 0
local function check(label, ok, detail)
	if not ok then fails += 1 end
	print(("%s BuildHazards %s%s"):format(ok and "PASS" or "FAIL", label, detail and (" | " .. tostring(detail)) or ""))
end

local Zones = workspace:FindFirstChild("Zones")
local Plots = workspace:FindFirstChild("Plots")
if not (Zones and Zones:FindFirstChild("Z6") and Plots) then
	error("BuildHazards: run BuildSlice.lua and BuildStrip.lua first (Workspace.Zones.Z6 or Workspace.Plots missing)", 0)
end

-- remove the last run's pieces
for _, d in ipairs(workspace:GetDescendants()) do
	if d:GetAttribute("BuiltBy") == "BuildHazards" then
		d:Destroy()
	end
end

local function part(parent, name, cf, size, col, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	if shape then p.Shape = shape end
	p.Size = size
	p.CFrame = cf
	p.Color = col
	p.Material = Enum.Material.SmoothPlastic
	p.MaterialVariant = VARIANT
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- ============ hazards 2..6
local LANE_TOP = 0.2
local built = 0
for n = 2, 6 do
	local zone = Zones:FindFirstChild("Z" .. n)
	local z0 = 236 + 120 * (n - 1)
	local home = CFrame.new(206, LANE_TOP, z0 + 15)
	local m = Instance.new("Model")
	m.Name = "Hazard_" .. n
	m:SetAttribute("BuiltBy", "BuildHazards")
	m:SetAttribute("HazardId", n)
	m:SetAttribute("TrackHome", home)
	local track = SH.makeTrack(home)
	local col = if n == 5 then C.alarmOrange else (C["zone" .. n] and C["zone" .. n].structure) or C.alarmOrange
	if n == 5 then
		-- six tiles, 0.2 thick, 0.2 above the lane (the z-fighting rule), named Tile_1..6
		local V = require(RS.Shared.Config).Hazards.LAVA
		local tw = track.laneWidth / V.tiles
		for k = 1, V.tiles do
			local a = -track.laneWidth / 2 + tw * (k - 0.5)
			part(m, "Tile_" .. k, CFrame.new(home.Position + Vector3.new(a, 0.2 + 0.1, 0)), Vector3.new(tw, 0.2, V.tile_along), C.alarmOrange).Transparency = 0.2
		end
		m.PrimaryPart = m:FindFirstChild("Tile_1") :: BasePart
	else
		local v = SH.volumes(n, track, if n == 2 then 0.5 else 0)[1]
		assert(v, "no volume at rest for hazard " .. n)
		local cf = SH.toWorld(track, v)
		local body
		if v.shape == "ball" then
			body = part(m, "Body", cf, Vector3.one * (2 * v.r), col, Enum.PartType.Ball)
		else
			body = part(m, "Body", cf, Vector3.new(2 * v.ha, 2 * v.hy, 2 * v.hl), col)
		end
		m.PrimaryPart = body
		if n == 3 then
			local A = require(RS.Shared.Config).Hazards.ANCHOR
			local top = home.Position + Vector3.new(0, A.pivot_height, 0)
			local bottom = cf.Position + Vector3.new(0, v.hy, 0)
			local len = (top - bottom).Magnitude
			part(m, "Chain", CFrame.lookAt((top + bottom) / 2, bottom) , Vector3.new(0.6, 0.6, len), C.kerbWhite)
		elseif n == 6 then
			-- the shadow under the rock: a flat disc 0.2 above the lane
			part(m, "Shadow", CFrame.new(cf.Position.X, LANE_TOP + 0.25, cf.Position.Z) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.1, 2 * v.r, 2 * v.r), C.ink or C.alarmOrange, Enum.PartType.Cylinder).Transparency = 0.5
		end
	end
	m.Parent = zone
	CollectionService:AddTag(m, "HFB_Hazard")
	built += 1
end
check("hazard models 2..6 built", built == 5, built)

-- every id 1..6 has exactly one tagged model with a TrackHome or a pivot, in its own zone's throat
for id = 1, 6 do
	local found = {}
	for _, m in ipairs(CollectionService:GetTagged("HFB_Hazard")) do
		if m:GetAttribute("HazardId") == id then table.insert(found, m) end
	end
	local m = found[1]
	local track = m and SH.trackOf(m)
	local z0 = 236 + 120 * (id - 1)
	local zc = track and track.home.Position.Z
	check(("hazard %d: one model, home in its throat (Z %d..%d)"):format(id, z0, z0 + 30), #found == 1 and zc ~= nil and zc >= z0 and zc <= z0 + 30 and math.abs(track.home.Position.X - 206) < 1e-3,
		("%d models, home Z %s"):format(#found, tostring(zc)))
end

-- ============ spots 11..17 on every plot
local LOCAL = {
	-- index = { spot x, spot y, pad x, pad y, pad w, pad d, kind }
	[11] = { 1, 68, 10, 68, 3, 8, "rebirth" },
	[12] = { 41, 68, 37, 68, 3, 8, "rebirth" },
	[13] = { 21, 82, 21, 78, 8, 3, "rebirth" },
	[14] = { 11, 82, 11, 78, 8, 3, "rebirth" },
	[15] = { 31, 82, 31, 78, 8, 3, "rebirth" },
	[16] = { 1, 82, 1, 78, 8, 3, "extra" },
	[17] = { 41, 82, 41, 78, 8, 3, "extra" },
}
local nplots, nspots = 0, 0
for _, plot in ipairs(Plots:GetChildren()) do
	local s1, s2, s9 = plot:FindFirstChild("Spot_1"), plot:FindFirstChild("Spot_2"), plot:FindFirstChild("Spot_9")
	if plot:IsA("Model") and s1 and s2 and s9 then
		nplots += 1
		local function fl(v) return Vector3.new(v.X, 0, v.Z) end
		local ex = (fl(s2.Position - s1.Position) / 40).Unit
		local ey = (fl(s9.Position - s1.Position) / 40).Unit
		local o = fl(s1.Position) - ex * 5 - ey * 22
		local spotY = s1.Position.Y
		local pad1 = plot:FindFirstChild("CashPad_1")
		local padY = if pad1 then pad1.Position.Y else spotY
		local function rect(name, x, y, w, d, py, h, col, attrs, tag)
			local centre = o + ex * (x + w / 2) + ey * (y + d / 2) + Vector3.new(0, py, 0)
			local p = Instance.new("Part")
			p.Name = name
			p.Anchored = true
			p.Size = Vector3.new(w, h, d)
			p.CFrame = CFrame.fromMatrix(centre, ex, Vector3.yAxis)
			p.Color = col
			p.Material = Enum.Material.SmoothPlastic
			p.MaterialVariant = VARIANT
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			for k, v in pairs(attrs) do p:SetAttribute(k, v) end
			p:SetAttribute("BuiltBy", "BuildHazards")
			p.Parent = plot
			CollectionService:AddTag(p, tag)
			return p
		end
		for i = 11, 17 do
			local L = LOCAL[i]
			for _, nm in ipairs({ "Spot_" .. i, "CashPad_" .. i }) do
				local old = plot:FindFirstChild(nm)
				if old then old:Destroy() end
			end
			rect("Spot_" .. i, L[1], L[2], 8, 8, spotY, s1.Size.Y, C.padStone, { SpotIndex = i, SpotKind = L[7] }, "HFB_Spot")
			rect("CashPad_" .. i, L[3], L[4], L[5], L[6], padY, pad1 and pad1.Size.Y or 1, C.cashGreen, { SpotIndex = i, SpotKind = L[7] }, "HFB_CashPad")
			nspots += 1
		end
	end
end
check("spots 11..17 and their cash pads on every plot", nplots > 0 and nspots == 7 * nplots, ("%d plots, %d spots"):format(nplots, nspots))

-- every plot: Spot_1..17 and CashPad_1..17, each with its SpotIndex, no two spots overlapping
for _, plot in ipairs(Plots:GetChildren()) do
	if plot:IsA("Model") and plot:FindFirstChild("Spot_1") then
		local ok, overlap = true, 0
		local boxes = {}
		for i = 1, 17 do
			local s, c = plot:FindFirstChild("Spot_" .. i), plot:FindFirstChild("CashPad_" .. i)
			if not (s and c and s:GetAttribute("SpotIndex") == i and c:GetAttribute("SpotIndex") == i) then ok = false end
			if s then table.insert(boxes, s) end
			if c then table.insert(boxes, c) end
		end
		for a = 1, #boxes do
			for b = a + 1, #boxes do
				local A, B = boxes[a], boxes[b]
				local ha, hb = A.Size / 2, B.Size / 2
				local ra = A.CFrame:VectorToWorldSpace(ha)
				local rb = B.CFrame:VectorToWorldSpace(hb)
				local dx = math.abs(A.Position.X - B.Position.X) - (math.abs(ra.X) + math.abs(rb.X))
				local dz = math.abs(A.Position.Z - B.Position.Z) - (math.abs(ra.Z) + math.abs(rb.Z))
				if dx < -0.01 and dz < -0.01 then overlap += 1 end
			end
		end
		check(plot.Name .. ": Spot_1..17 and CashPad_1..17 with SpotIndex, none overlapping", ok and overlap == 0, ("overlaps %d"):format(overlap))
	end
end

-- z-fighting (manager's rule): no visible face of what this script built within 0.1 studs of a same-facing visible face
-- it overlaps
local mine, others = {}, {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Part") and d.Transparency < 1 and d.Shape == Enum.PartType.Block then
		local isMine = d:GetAttribute("BuiltBy") == "BuildHazards" or (d.Parent and d.Parent:GetAttribute("BuiltBy") == "BuildHazards")
		local cf = d.CFrame
		local ax, okAx = {}, true
		for i, v in ipairs({ cf.RightVector, cf.UpVector, cf.LookVector }) do
			local k
			for a, c in ipairs({ v.X, v.Y, v.Z }) do if math.abs(math.abs(c) - 1) < 1e-3 then k = a end end
			if not k then okAx = false; break end
			ax[i] = k
		end
		if okAx then
			local sz = {}
			sz[ax[1]] = d.Size.X; sz[ax[2]] = d.Size.Y; sz[ax[3]] = d.Size.Z
			local p = { cf.Position.X, cf.Position.Y, cf.Position.Z }
			local lo, hi = {}, {}
			for a = 1, 3 do lo[a] = p[a] - sz[a] / 2; hi[a] = p[a] + sz[a] / 2 end
			table.insert(if isMine then mine else others, { part = d, lo = lo, hi = hi })
		end
	end
end
local zf = {}
local all = table.clone(others)
for _, b in ipairs(mine) do table.insert(all, b) end
for _, A in ipairs(mine) do
	for _, B in ipairs(all) do
		if A ~= B then
			for a = 1, 3 do
				local o1, o2 = a % 3 + 1, (a + 1) % 3 + 1
				local ov1 = math.min(A.hi[o1], B.hi[o1]) - math.max(A.lo[o1], B.lo[o1])
				local ov2 = math.min(A.hi[o2], B.hi[o2]) - math.max(A.lo[o2], B.lo[o2])
				if ov1 > 0.01 and ov2 > 0.01 then
					if math.abs(A.lo[a] - B.lo[a]) < 0.1 or math.abs(A.hi[a] - B.hi[a]) < 0.1 then
						table.insert(zf, A.part:GetFullName() .. " <-> " .. B.part:GetFullName())
					end
				end
			end
		end
	end
end
for _, z in ipairs(zf) do print("BuildHazards: ZFIGHT " .. z) end
check(("ZFIGHT (%d built boxes against %d): pairs within 0.1 studs, same facing, overlapping"):format(#mine, #all), #zf == 0, #zf)

print(("BuildHazards: %s, %d failed"):format(fails == 0 and "PASS" or "FAIL", fails))
