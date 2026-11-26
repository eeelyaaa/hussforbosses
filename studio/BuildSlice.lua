if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-12 the real M1 slice (builder-m1-12). Replaces the M1-05 greybox: same part sizes, colours from Skin.Tokens, the
-- "Stud" MaterialVariant name on every visible built part (the variant itself is made by SetupStud.lua: a plain stand-in
-- until the manager says yes to the stud proof), invisible blockers tagged HFB_Blocker, and a z-fighting check.
-- Hub frame (base-layout.md section 2): world X = hub X, world Z = hub Y (toward the gate), world Y up, 1 unit = 1 stud.
-- Builds: plot 1 (50 x 92 at hub X 4..96, Y 154..204, turned to face +X), the track and start line, the 4-stud front
-- wall with its blocker and the 36-wide gate opening, the gate arch, the zone 1 lane to Y 300, the fixed pad at (233, 276),
-- the rolling log stand-in, a windmill stand-in. Names and tags: m1-contract.md section B.
-- Idempotent: destroys what it owns (Plots, Hub, Zones, Sight) and rebuilds; deletes the default Baseplate (z-fighting:
-- its top is Y 0 and so is the slice floor's). Never touches Workspace.StudProof (SetupStud.lua owns it).
-- Z-FIGHTING RULE (manager, 2026-11-25): never stack coplanar or near-coplanar faces. Overlays sit at least 0.2 above what
-- they lie on; pieces that meet do so edge to edge or on opposite faces, never overlapping with the same facing within 0.1.
-- The check at the end scans every visible axis-aligned box in Workspace and must print "ZFIGHT PASS (0 pairs)". Keep it for M3.
--   require(game.ServerStorage.DevSync:Clone()).run("BuildSlice.lua")
local CollectionService = game:GetService("CollectionService")
local MaterialService = game:GetService("MaterialService")
local RS = game:GetService("ReplicatedStorage")

local skins = RS:FindFirstChild("Skins")
local tokMod = skins and skins:FindFirstChild("brickbrawl") and skins.brickbrawl:FindFirstChild("Tokens")
if not tokMod then error("BuildSlice: ReplicatedStorage.Skins.brickbrawl.Tokens missing; run the DevSync sync first", 0) end
local Tokens = require(tokMod)
local C = Tokens.colors
local VARIANT = Tokens.stud.variantName

-- the variant and the proof strip come first (a script on an empty place must work on its own)
if not MaterialService:FindFirstChild(VARIANT) or not workspace:FindFirstChild("StudProof") then
	require(game.ServerStorage.DevSync:Clone()).run("SetupStud.lua")
end

for _, n in ipairs({ "Plots", "Hub", "Zones", "Sight" }) do
	local o = workspace:FindFirstChild(n)
	if o then o:Destroy() end
end
local bp0 = workspace:FindFirstChild("Baseplate")
if bp0 then bp0:Destroy() end
local spawn0 = workspace:FindFirstChildOfClass("SpawnLocation")
if spawn0 then spawn0.Position = Vector3.new(206, 0.7, 112) end 

local K = {
	floor = C.zone1.ground, lane = C.laneGrey, white = C.kerbWhite, wall = C.zone1.structure, pad = C.padStone,
	red = C.bagRed, green = C.cashGreen, cyan = C.shieldCyan, gold = C.shopGold, blue = C.plateBlue,
	orange = C.alarmOrange, fence = C.kerbWhite, tower = C.zone1.structure,
}

local function mk(parent, name, x0, z0, x1, z1, y0, h, col, o)
	o = o or {}
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = Vector3.new(x1 - x0, h, z1 - z0)
	p.Position = Vector3.new((x0 + x1) / 2, y0 + h / 2, (z0 + z1) / 2)
	p.Color = col
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if o.invisible then
		p.Transparency = 1
		p.CanQuery = false -- (Raycast still hits a CanCollide part: exclude by the tag HFB_Blocker)
		p.CanTouch = false
		if o.blocker then CollectionService:AddTag(p, "HFB_Blocker") end
	else
		p.MaterialVariant = VARIANT
	end
	if o.nocollide then p.CanCollide = false end
	if o.tag then CollectionService:AddTag(p, o.tag) end
	for k, v in pairs(o.attrs or {}) do p:SetAttribute(k, v) end
	p.Parent = parent
	return p
end

local function folder(parent, name, class)
	local f = Instance.new(class or "Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- ============ Hub ============
local Hub = folder(workspace, "Hub")
-- floor under the whole slice, top at Y 0 (the Baseplate is deleted above, so nothing else lies in that plane)
mk(Hub, "Floor", 0, 0, 412, 236, -2, 2, K.floor)
-- track: lane grey, 0.2 above the floor, X 188..224, from Y 100 through the gate
mk(Hub, "Track", 188, 100, 224, 236, 0, 0.2, K.lane)
mk(Hub, "StartLine", 188, 226, 224, 228, 0.2, 0.2, K.white)
-- front wall: 2 thick (Y 234..236), 4 tall, ends at the gate pillars; invisible blocker to 10 along the wall line
local FW = folder(Hub, "FrontWall", "Model")
mk(FW, "WallLeft", 0, 234, 184, 236, 0, 4, K.wall)
mk(FW, "WallRight", 228, 234, 412, 236, 0, 4, K.wall)
mk(FW, "BlockerLeft", 0, 234, 188, 236, 0, 10, K.wall, { invisible = true, blocker = true })
mk(FW, "BlockerRight", 224, 234, 412, 236, 0, 10, K.wall, { invisible = true, blocker = true })
-- gate arch: pillars 4 x 4 x 16 (1 wider each side of the wall), lintel 4 tall x 36 across (the sign is the skin's)
local Gate = folder(Hub, "Gate", "Model")
mk(Gate, "PillarLeft", 184, 233, 188, 237, 0, 16, K.wall)
mk(Gate, "PillarRight", 224, 233, 228, 237, 0, 16, K.wall)
mk(Gate, "Lintel", 188, 234, 224, 236, 12, 4, K.wall)
Gate:SetAttribute("OpeningCenterX", 206)

-- ============ Plot 1 ============
local Plots = folder(workspace, "Plots")
local Plot = folder(Plots, "Plot1", "Model")
Plot:SetAttribute("PlotId", 1)
Plot:SetAttribute("OwnerUserId", 0)
-- plot-local (x across 0..50, x=50 is right seen from the yard; y depth from the front fence) -> hub rect.
-- plot 1 (left wall): hub X = 96 - y, hub Z = 204 - x   (layout.py to_world)
local function PL(x, y, w, d) return 96 - (y + d), 204 - (x + w), 96 - y, 204 - x end
local function L(parent, name, x, y, w, d, y0, h, col, o)
	local X0, Z0, X1, Z1 = PL(x, y, w, d)
	return mk(parent, name, X0, Z0, X1, Z1, y0, h, col, o)
end

-- fence: the four runs meet edge to edge (the greybox overlapped at the corners: coplanar tops)
local Fence = folder(Plot, "Fence")
local function fence(nm, x, y, w, d)
	L(Fence, nm, x, y, w, d, 0, 3, K.fence)
	L(Fence, nm .. "_Blocker", x, y, w, d, 0, 10, K.fence, { invisible = true, blocker = true })
end
fence("FrontLeft", 1, 0, 18, 1)
fence("FrontRight", 31, 0, 18, 1)
fence("Back", 1, 91, 48, 1)
fence("SideBagSide", 49, 0, 1, 92)
fence("SideBackSide", 0, 0, 1, 92)

L(Plot, "Driveway", 19, -4, 12, 4, 0, 0.2, K.lane)
L(Plot, "Entrance", 19, 0, 12, 1, 0, 10, K.white, { invisible = true, nocollide = true, tag = "HFB_PlotEntrance" })
local sp = L(Plot, "SpawnPoint", 29, 10, 4, 4, 0, 0.2, K.green, { tag = "HFB_PlotSpawn" })
sp.CFrame = CFrame.lookAt(sp.Position, sp.Position + Vector3.new(0, 0, -1)) -- facing the bag (local +x = world -Z)
L(Plot, "BagPad", 35, 3, 8, 8, 0, 1, K.red, { tag = "HFB_BagPad" })
local Bag = folder(Plot, "Bag", "Model")
Bag:SetAttribute("BagTier", 1)
L(Bag, "Plinth", 43, 4, 6, 6, 0, 1, K.wall)
L(Bag, "Frame", 45, 4, 2, 6, 1, 13, K.blue)
L(Bag, "Body", 44, 5, 4, 4, 4, 8, K.red)
L(Plot, "BagSignPost", 44, 12, 1, 1, 0, 2, K.fence)
L(Plot, "BagSign", 44, 12, 1, 5, 2, 4, K.blue)
L(Plot, "LockPad", 11, 3, 6, 6, 0, 1, K.cyan, { tag = "HFB_LockPad" })
L(Plot, "LockBoard", 9, 3, 1, 6, 2, 4.5, K.blue, { tag = "HFB_LockBoard" })
L(Plot, "Crate", 2, 3, 6, 6, 0, 6, K.gold, { tag = "HFB_Crate" })
L(Plot, "SpotsFullPost", 4, 11, 1, 1, 0, 1, K.fence)
L(Plot, "SpotsFullSign", 2, 11, 6, 1, 1, 3, K.orange, { tag = "HFB_SpotsFullSign" })
-- name board over the entrance: 16 x 3.5 x 1, bottom at 7.5, on two posts (posts are 0.3 wider than the fence in depth,
-- so their faces are never within 0.1 of the fence's)
L(Plot, "NameBoardPostA", 17, -0.3, 1, 1.6, -0.5, 8, K.fence)
L(Plot, "NameBoardPostB", 32, -0.3, 1, 1.6, -0.5, 8, K.fence)
L(Plot, "NameBoard", 17, 0, 16, 1, 7.5, 3.5, K.blue, { tag = "HFB_NameBoard" })
for k = 1, 10 do
	local row = math.ceil(k / 2)
	local y = 18 + (row - 1) * 10
	local left = (k % 2 == 1)
	L(Plot, "Spot_" .. k, left and 1 or 41, y, 8, 8, 0, 1, K.pad, { tag = "HFB_Spot", attrs = { SpotIndex = k } })
	L(Plot, "CashPad_" .. k, left and 10 or 37, y, 3, 8, 0, 1, K.green, { tag = "HFB_CashPad", attrs = { SpotIndex = k } })
end

-- ============ Zone 1 (strip) ============
local Zones = folder(workspace, "Zones")
local Z1 = folder(Zones, "Z1")
mk(Z1, "Ground", 0, 236, 412, 380, -2, 2, K.floor)
mk(Z1, "Lane", 188, 236, 224, 300, 0, 0.2, K.lane)
-- Rolling Log stand-in (M1-21): Config.Hazards.LOG size (12 long, 6 thick, read from Config so it cannot drift), axis ALONG the lane
-- (world Z; the part's own cylinder axis is X, turned 90 degrees about Y), pivot on the lane centre line (X 206) at the
-- crossing (Z 248, middle of the run 236..261) at the rolling-axis height (lane top 0.2 + radius). CanCollide off: the hit test
-- is the server's and a colliding copy at rest would block the lane centre. Shared/Hazards.logCFrame and the client roll
-- (about track.along, then home.Rotation) take this pivot as TrackHome.
local LOGC = require(RS.Shared.Config.Hazards).LOG
local Log = folder(Z1, "Hazard_Log", "Model")
Log:SetAttribute("HazardId", 1)
CollectionService:AddTag(Log, "HFB_Hazard")
local lg = Instance.new("Part")
lg.Name = "Log"; lg.Shape = Enum.PartType.Cylinder; lg.Anchored = true; lg.CanCollide = false; lg.CanQuery = false; lg.CanTouch = false
lg.Size = Vector3.new(LOGC.length, LOGC.thickness, LOGC.thickness) -- cylinder axis is the part's X
lg.CFrame = CFrame.new(206, 0.2 + LOGC.thickness / 2, 248) * CFrame.Angles(0, math.rad(90), 0) -- axis now along world Z
lg.Color = K.orange; lg.Material = Enum.Material.SmoothPlastic; lg.MaterialVariant = VARIANT
lg.Parent = Log
Log.PrimaryPart = lg

local Pads = folder(Z1, "Pads")
local Fixed = folder(Pads, "Fixed", "Model")
Fixed:SetAttribute("PadId", "z1_fixed")
Fixed:SetAttribute("ZoneId", 1)
Fixed:SetAttribute("Kind", "fixed")
CollectionService:AddTag(Fixed, "HFB_BossPad")
local ring = mk(Fixed, "Ring", 227, 270, 239, 282, 0, 1, K.pad, { nocollide = true })
ring:SetAttribute("RingRadius", 6)
-- BossAnchor: its Position is the middle of the boss's feet (ring top is Y 1); SetupBosses stands the Body pivot here
local ba = mk(Fixed, "BossAnchor", 232.5, 275.5, 233.5, 276.5, 1, 0.2, K.white, { invisible = true, nocollide = true })
ba.Position = Vector3.new(233, 1, 276)
local na = mk(Fixed, "NumberAnchor", 232.5, 275.5, 233.5, 276.5, 13, 1, K.white, { invisible = true, nocollide = true })
na.Position = Vector3.new(233, 13.5, 276) -- where the Power number billboard hangs (boss ~9 tall plus a gap)
Fixed.PrimaryPart = ring

-- ============ Sight markers ============
local Sight = folder(workspace, "Sight")
local bp = Plot.BagPad
local eye = Instance.new("Part")
eye.Name = "BagPadEye"; eye.Anchored = true; eye.CanCollide = false; eye.CanQuery = false; eye.CanTouch = false
eye.Transparency = 1; eye.Size = Vector3.new(0.5, 0.5, 0.5)
eye.Position = Vector3.new(bp.Position.X, bp.Position.Y + 0.5 + 4.5, bp.Position.Z)
eye.Parent = Sight
-- WindmillStandIn: 6 x 6 x 44 tower left of the lane at hub (130, 340) (TEAM CALL M1-05-3: where plot 1's name board does not hide it)
mk(Sight, "WindmillStandIn", 127, 337, 133, 343, 0, 44, K.tower)

-- the boss on its pad and the gloves, from whatever meshes (or stand-ins) are in ServerStorage.BossScratch
do
	local D = require(game.ServerStorage.DevSync:Clone())
	D.run("SetupBosses.lua")
	D.run("SetupGloves.lua")
end

-- ============ asserts (contract B) ============
local fails = 0
local function check(label, ok)
	print(("BuildSlice: %s %s"):format(ok and "PASS" or "FAIL", label))
	if not ok then fails += 1 end
end
local function count(tag) return #CollectionService:GetTagged(tag) end
check("Plot1 attrs PlotId=1 OwnerUserId=0", Plot:GetAttribute("PlotId") == 1 and Plot:GetAttribute("OwnerUserId") == 0)
for _, n in ipairs({ "BagPad", "Bag", "Entrance", "SpawnPoint", "LockPad", "LockBoard", "Crate", "SpotsFullSign", "NameBoard" }) do
	check("Workspace.Plots.Plot1." .. n, Plot:FindFirstChild(n) ~= nil)
end
for k = 1, 10 do
	local s, c = Plot:FindFirstChild("Spot_" .. k), Plot:FindFirstChild("CashPad_" .. k)
	check(("Spot_%d / CashPad_%d with SpotIndex"):format(k, k), s and c and s:GetAttribute("SpotIndex") == k and c:GetAttribute("SpotIndex") == k)
end
check("tags HFB_Spot x10, HFB_CashPad x10", count("HFB_Spot") == 10 and count("HFB_CashPad") == 10)
check("tags BagPad/PlotEntrance/PlotSpawn x1", count("HFB_BagPad") == 1 and count("HFB_PlotEntrance") == 1 and count("HFB_PlotSpawn") == 1)
check("tags LockPad/LockBoard/Crate/SpotsFullSign/NameBoard x1", count("HFB_LockPad") == 1 and count("HFB_LockBoard") == 1 and count("HFB_Crate") == 1 and count("HFB_SpotsFullSign") == 1 and count("HFB_NameBoard") == 1)
check("Hub.Track/StartLine/FrontWall/Gate", Hub:FindFirstChild("Track") and Hub:FindFirstChild("StartLine") and Hub:FindFirstChild("FrontWall") and Hub:FindFirstChild("Gate"))
check("Zones.Z1.Hazard_Log tagged HFB_Hazard, HazardId=1", Log:GetAttribute("HazardId") == 1 and CollectionService:HasTag(Log, "HFB_Hazard"))
check("Zones.Z1.Pads.Fixed tag HFB_BossPad, PadId z1_fixed, ZoneId 1, Kind fixed", CollectionService:HasTag(Fixed, "HFB_BossPad") and Fixed:GetAttribute("PadId") == "z1_fixed" and Fixed:GetAttribute("ZoneId") == 1 and Fixed:GetAttribute("Kind") == "fixed")
check("Hazard_Log stand-in = Config size, pivot on lane centre X 206 at height 3.2, axis along Z, CanCollide off", (function()
	local pv = Log:GetPivot(); local ax = pv.RightVector
	return lg.Size == Vector3.new(LOGC.length, LOGC.thickness, LOGC.thickness) and math.abs(pv.Position.X - 206) < 1e-3
		and math.abs(pv.Position.Y - (0.2 + LOGC.thickness / 2)) < 1e-3 and math.abs(math.abs(ax.Z) - 1) < 1e-3 and lg.CanCollide == false
end)())
check("Fixed.Ring 12x12 RingRadius 6", ring.Size.X == 12 and ring.Size.Z == 12 and ring:GetAttribute("RingRadius") == 6)
check("Fixed.BossAnchor and NumberAnchor", Fixed:FindFirstChild("BossAnchor") ~= nil and Fixed:FindFirstChild("NumberAnchor") ~= nil)
check("Sight.BagPadEye and WindmillStandIn", Sight:FindFirstChild("BagPadEye") ~= nil and Sight:FindFirstChild("WindmillStandIn") ~= nil)
check("Zones.Z1.Pads.Fixed.Boss_z1_t1 (tag HFB_Boss) and ReplicatedStorage.Gloves.GloveL/GloveR", Fixed:FindFirstChild("Boss_z1_t1") ~= nil and CollectionService:HasTag(Fixed.Boss_z1_t1, "HFB_Boss") and RS:FindFirstChild("Gloves") ~= nil and RS.Gloves:FindFirstChild("GloveL") ~= nil and RS.Gloves:FindFirstChild("GloveR") ~= nil)
check("bag pad centre at hub (89, 165)", math.abs(bp.Position.X - 89) < 1e-3 and math.abs(bp.Position.Z - 165) < 1e-3)
check("entrance centre at hub (95.5, 179)", math.abs(Plot.Entrance.Position.X - 95.5) < 1e-3 and math.abs(Plot.Entrance.Position.Z - 179) < 1e-3)
check("blockers tagged HFB_Blocker (2 wall + 5 fence)", count("HFB_Blocker") == 7)
check("no Baseplate in Workspace", workspace:FindFirstChild("Baseplate") == nil)
check("MaterialService." .. VARIANT .. " exists, StudProof exists", MaterialService:FindFirstChild(VARIANT) ~= nil and workspace:FindFirstChild("StudProof") ~= nil)
do
	local bad = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 1 and d.Name ~= "Terrain" and d:IsDescendantOf(Plots) and d.MaterialVariant ~= VARIANT then bad += 1 end
	end
	check("every visible plot part carries MaterialVariant '" .. VARIANT .. "'", bad == 0)
end

-- ============ z-fighting check (the manager's rule; stays in this script for M3) ============
-- Every visible, axis-aligned Block part in Workspace. Two parts are a pair when a face of one lies within TOL of a face of
-- the other with the SAME facing and the two faces overlap in area (so edge-to-edge neighbours and opposite faces that
-- merely touch are not pairs). Prints both part names, the axis and the gap.
local function zfight(tol)
	local boxes, skipped = {}, 0
	for _, d in ipairs(workspace:GetDescendants()) do
		-- bosses are imported meshes (never scanned); the stand-in boxes of SetupBosses overlap each other by design
		local inBoss = d:FindFirstAncestorWhichIsA("Model") and d:FindFirstAncestorWhichIsA("Model"):GetAttribute("CreatureId") ~= nil
		if d:IsA("Part") and d.Shape == Enum.PartType.Block and d.Transparency < 1 and not inBoss then
			local cf = d.CFrame
			local ax = {}
			local ok = true
			for i, v in ipairs({ cf.RightVector, cf.UpVector, cf.LookVector }) do
				local k
				for a, c in ipairs({ v.X, v.Y, v.Z }) do if math.abs(math.abs(c) - 1) < 1e-3 then k = a end end
				if not k then ok = false; break end
				ax[i] = k
			end
			if ok then
				local sz = {}
				sz[ax[1]] = d.Size.X; sz[ax[2]] = d.Size.Y; sz[ax[3]] = d.Size.Z
				local p = cf.Position
				local pos = { p.X, p.Y, p.Z }
				local lo, hi = {}, {}
				for a = 1, 3 do lo[a] = pos[a] - sz[a] / 2; hi[a] = pos[a] + sz[a] / 2 end
				table.insert(boxes, { part = d, lo = lo, hi = hi })
			else
				skipped += 1
			end
		end
	end
	local pairsFound = {}
	for i = 1, #boxes do
		local A = boxes[i]
		for j = i + 1, #boxes do
			local B = boxes[j]
			local near = true
			for a = 1, 3 do
				if A.lo[a] > B.hi[a] + tol or B.lo[a] > A.hi[a] + tol then near = false; break end
			end
			if near then
				for a = 1, 3 do
					local o1, o2 = a % 3 + 1, (a + 1) % 3 + 1
					local ov1 = math.min(A.hi[o1], B.hi[o1]) - math.max(A.lo[o1], B.lo[o1])
					local ov2 = math.min(A.hi[o2], B.hi[o2]) - math.max(A.lo[o2], B.lo[o2])
					if ov1 > 0.01 and ov2 > 0.01 then
						local dMin, dMax = math.abs(A.lo[a] - B.lo[a]), math.abs(A.hi[a] - B.hi[a])
						if dMin < tol then table.insert(pairsFound, { A.part, B.part, ("-%s face, gap %.3f"):format(({ "X", "Y", "Z" })[a], dMin) }) end
						if dMax < tol then table.insert(pairsFound, { A.part, B.part, ("+%s face, gap %.3f"):format(({ "X", "Y", "Z" })[a], dMax) }) end
					end
				end
			end
		end
	end
	return pairsFound, #boxes, skipped
end
local zf, nboxes, nskip = zfight(0.1)
for _, pr in ipairs(zf) do
	print(("BuildSlice: ZFIGHT %s  <->  %s  (%s)"):format(pr[1]:GetFullName(), pr[2]:GetFullName(), pr[3]))
end
check(("ZFIGHT (%d visible boxes scanned, %d rotated skipped): %d pairs within 0.1 studs, same plane, same facing"):format(nboxes, nskip, #zf), #zf == 0)

local nparts = 0
for _, n in ipairs({ "Plots", "Hub", "Zones", "Sight" }) do nparts += #workspace[n]:GetDescendants() end
print(("BuildSlice: %s, %d failed, %d descendants in Plots/Hub/Zones/Sight"):format(fails == 0 and "PASS" or "FAIL", fails, nparts))
