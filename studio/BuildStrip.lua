if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-10b the plain six-zone test strip (builder-sixzones). Run AFTER BuildSlice.lua (BuildSlice destroys Workspace.Zones;
-- run this again after every BuildSlice run). Greybox only: ground, lane, the 23 missing boss pads. No hazards (M2-11), no
-- M3 world art. Spec: team/verification/m2-10-bag-zones-patrol.md "What the builder must add".
--   require(game.ServerStorage.DevSync:Clone()).run("BuildStrip.lua")
-- Layout (hub frame: world X, Z = the lane direction, Y up; the lane centre line is Config.Zones.LANE, X 206 along +Z):
--   zone n starts at Z0 = 236 + 120 (n - 1). Pads sit 40 / 60 / 80 / 100 studs in (fixed, roll1, roll2, roll3), alternating
--   east (X 233, ring X 227..239) and west (X 179, ring X 173..185) of the 36-wide lane (X 188..224). Each boss walks 14
--   either way along Z (Config.Zones.PATROL), so every pad has 15 studs of clear bay each way along Z.
--   Zone 1: BuildSlice made the ground (Z 236..380), the lane to 300 and z1_fixed. This script adds LaneExt (300..380) and
--   z1_roll1..3. Zones 2..6: ground (zone 2: 380..476, then 120 each to Z 956), lane the same range, a white start line at
--   Z0 (zone 2's lies on LaneExt), four pads each.
-- Names: Workspace.Zones.Z<n>.Pads.<Fixed|Roll1|Roll2|Roll3>, tag HFB_BossPad, attributes PadId / ZoneId / Kind, parts Ring
-- (12 x 1 x 12, RingRadius 6), BossAnchor (invisible, ring top), NumberAnchor (invisible, 13.5 up).
-- Z-FIGHTING RULE (manager, 2026-11-25): pieces meet edge to edge or on opposite faces; overlays sit >= 0.2 above. The check
-- at the end is the BuildSlice ZFIGHT scan (must print 0 pairs).
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")

local skins = RS:FindFirstChild("Skins")
local tokMod = skins and skins:FindFirstChild("brickbrawl") and skins.brickbrawl:FindFirstChild("Tokens")
if not tokMod then error("BuildStrip: ReplicatedStorage.Skins.brickbrawl.Tokens missing; run the DevSync sync first", 0) end
local Tokens = require(tokMod)
local C = Tokens.colors
local VARIANT = Tokens.stud.variantName
local ZC = require(RS.Shared.Config.Zones)

local Zones = workspace:FindFirstChild("Zones")
local Z1 = Zones and Zones:FindFirstChild("Z1")
if not (Z1 and Z1:FindFirstChild("Pads") and Z1.Pads:FindFirstChild("Fixed")) then
	error("BuildStrip: run BuildSlice.lua first (Workspace.Zones.Z1.Pads.Fixed missing)", 0)
end

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
		p.CanQuery = false
		p.CanTouch = false
	else
		p.MaterialVariant = VARIANT
	end
	if o.nocollide then p.CanCollide = false end
	p.Parent = parent
	return p
end
local function folder(parent, name, class)
	local f = Instance.new(class or "Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- idempotent: remove what this script owns
for n = 2, 6 do
	local o = Zones:FindFirstChild("Z" .. n)
	if o then o:Destroy() end
end
for _, n in ipairs({ "Roll1", "Roll2", "Roll3" }) do
	local o = Z1.Pads:FindFirstChild(n)
	if o then o:Destroy() end
end
local o = Z1:FindFirstChild("LaneExt")
if o then o:Destroy() end

local LANE_X0, LANE_X1 = 188, 224 -- the 36-wide lane, centre X 206
local SLOT_NAME = { "Fixed", "Roll1", "Roll2", "Roll3" }
local SLOT_ID = { "fixed", "roll1", "roll2", "roll3" }

local function pad(zone, slot, parent, z0)
	local cx = (slot % 2 == 1) and 233 or 179
	local cz = z0 + 20 + 20 * slot
	local zt = C["zone" .. zone]
	local m = folder(parent, SLOT_NAME[slot], "Model")
	m:SetAttribute("PadId", ("z%d_%s"):format(zone, SLOT_ID[slot]))
	m:SetAttribute("ZoneId", zone)
	m:SetAttribute("Kind", slot == 1 and "fixed" or "roll")
	CollectionService:AddTag(m, "HFB_BossPad")
	local ring = mk(m, "Ring", cx - 6, cz - 6, cx + 6, cz + 6, 0, 1, slot == 1 and C.padStone or zt.ground2, { nocollide = true })
	ring:SetAttribute("RingRadius", 6)
	local ba = mk(m, "BossAnchor", cx - 0.5, cz - 0.5, cx + 0.5, cz + 0.5, 1, 0.2, C.kerbWhite, { invisible = true, nocollide = true })
	ba.Position = Vector3.new(cx, 1, cz)
	local na = mk(m, "NumberAnchor", cx - 0.5, cz - 0.5, cx + 0.5, cz + 0.5, 13, 1, C.kerbWhite, { invisible = true, nocollide = true })
	na.Position = Vector3.new(cx, 13.5, cz)
	m.PrimaryPart = ring
	return m
end

-- ============ zone 1: lane extension + the three rolling pads ============
mk(Z1, "LaneExt", LANE_X0, 300, LANE_X1, 380, 0, 0.2, C.laneGrey)
for slot = 2, 4 do pad(1, slot, Z1.Pads, 236) end

-- ============ zones 2..6 ============
for n = 2, 6 do
	local z0 = 236 + 120 * (n - 1)
	local g0 = (n == 2) and 380 or z0 -- zone 1's ground already runs to 380
	local zt = C["zone" .. n]
	local Z = folder(Zones, "Z" .. n)
	mk(Z, "Ground", 0, g0, 412, z0 + 120, -2, 2, zt.ground)
	mk(Z, "Lane", LANE_X0, g0, LANE_X1, z0 + 120, 0, 0.2, C.laneGrey)
	-- start line: 2 deep, 0.2 above the lane (on zone 1's LaneExt for zone 2)
	mk(Z, "StartLine", LANE_X0, z0, LANE_X1, z0 + 2, 0.2, 0.2, C.kerbWhite, { nocollide = true })
	local Pads = folder(Z, "Pads")
	for slot = 1, 4 do pad(n, slot, Pads, z0) end
end

-- ============ asserts ============
local fails = 0
local function check(label, ok)
	print(("BuildStrip: %s %s"):format(ok and "PASS" or "FAIL", label))
	if not ok then fails += 1 end
end

local tagged = CollectionService:GetTagged("HFB_BossPad")
local byId = {}
for _, m in ipairs(tagged) do
	if m:IsDescendantOf(Zones) then byId[m:GetAttribute("PadId")] = m end
end
local nPads, spec = 0, true
for id, d in pairs(ZC.PADS) do
	nPads += 1
	local m = byId[id]
	if not (m and m:GetAttribute("ZoneId") == (d.zone or tonumber(id:match("^z(%d)"))) and m:GetAttribute("Kind") == d.kind) then spec = false end
	if m then
		local r, ba, na = m:FindFirstChild("Ring"), m:FindFirstChild("BossAnchor"), m:FindFirstChild("NumberAnchor")
		if not (r and ba and na and r.Size == Vector3.new(12, 1, 12) and r:GetAttribute("RingRadius") == 6 and r.CanCollide == false) then spec = false end
		if ba and r and math.abs(ba.Position.Y - 1) > 1e-3 then spec = false end
	end
end
check(("%d pads in Config.Zones.PADS, each in the world once (HFB_BossPad), ids / ZoneId / Kind / Ring 12x1x12 RingRadius 6 / anchors"):format(nPads), nPads == 24 and spec)
local nTagged = 0
for _ in pairs(byId) do nTagged += 1 end
check("exactly 24 HFB_BossPad models under Workspace.Zones", nTagged == 24 and #tagged == 24)

-- clear walk: nothing solid above Y 1 within 3 studs of the walk line, 15 studs each way along the lane axis (Z)
local axis = ZC.LANE.axis
do
	local bad = {}
	local params = OverlapParams.new()
	params.RespectCanCollide = true
	for id, m in pairs(byId) do
		local ba = m.BossAnchor.Position
		local box = CFrame.new(ba.X, 3.5, ba.Z)
		local hits = workspace:GetPartBoundsInBox(box, Vector3.new(6, 5, 2 * (ZC.PATROL.halfLen + 1)), params)
		for _, h in ipairs(hits) do
			if h.CanCollide and h.Name ~= "Terrain" and not h:IsDescendantOf(m) then
				local top = h.Position.Y + h.Size.Y / 2
				if top > 1.05 then table.insert(bad, id .. " <- " .. h:GetFullName()) end
			end
		end
	end
	for _, b in ipairs(bad) do print("BuildStrip: CLEARWALK " .. b) end
	check("clear walk: nothing solid above 1 stud within 15 studs each way along Z of any BossAnchor", #bad == 0)
end
check("lane axis is world Z (Config.Zones.LANE), lane centre X 206", math.abs(axis.Z) == 1 and ZC.LANE.origin.X == 206 and (LANE_X0 + LANE_X1) / 2 == 206)
do
	local worst = 0
	for _, m in pairs(byId) do
		local z = m.BossAnchor.Position.Z
		worst = math.max(worst, z) -- last pad
		if z - 15 < 236 or z + 15 > 956 then worst = math.huge end
	end
	check("every pad's 14 stud walk (+1) lies inside Z 236..956 (worst pad Z " .. worst .. ")", worst < math.huge)
end
check("no part taller than 4 studs built by this script", (function()
	for n = 2, 6 do
		for _, d in ipairs(Zones["Z" .. n]:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 1 and d.Position.Y + d.Size.Y / 2 > 4 then return false end
		end
	end
	return true
end)())
do
	local bad = 0
	for _, d in ipairs(Zones:GetDescendants()) do
		local boss = d:FindFirstAncestorWhichIsA("Model") and d:FindFirstAncestorWhichIsA("Model"):GetAttribute("CreatureId") ~= nil
		if d:IsA("BasePart") and d.Transparency < 1 and d.MaterialVariant ~= VARIANT and d.Name ~= "Log" and not boss then bad += 1 end
	end
	check("every visible strip part carries MaterialVariant '" .. VARIANT .. "'", bad == 0)
end

-- ============ z-fighting check (same scan as BuildSlice) ============
local function zfight(tol)
	local boxes, skipped = {}, 0
	for _, d in ipairs(workspace:GetDescendants()) do
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
	print(("BuildStrip: ZFIGHT %s  <->  %s  (%s)"):format(pr[1]:GetFullName(), pr[2]:GetFullName(), pr[3]))
end
check(("ZFIGHT (%d visible boxes scanned, %d rotated skipped): %d pairs within 0.1 studs, same plane, same facing"):format(nboxes, nskip, #zf), #zf == 0)

local nparts = 0
for n = 2, 6 do nparts += #Zones["Z" .. n]:GetDescendants() end
nparts += #Z1.LaneExt:GetDescendants() + 1
for _, n in ipairs({ "Roll1", "Roll2", "Roll3" }) do nparts += #Z1.Pads[n]:GetDescendants() + 1 end
print(("BuildStrip: %s, %d failed, %d instances added (Z2..Z6 folders, LaneExt, Roll1..3 included)"):format(fails == 0 and "PASS" or "FAIL", fails, nparts))
