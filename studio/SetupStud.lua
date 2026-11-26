if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-12 the stud: MaterialService variants, and the proof strip Workspace.StudProof (separate from the game slice; delete it any time).
--  MaterialService.Stud           the world variant. A plain stand-in (SmoothPlastic, no maps) until the manager says yes to the
--                                 stud proof; then set PROMOTE below to "normal" or "flipped" and run again: one instance changes,
--                                 every part that names "Stud" follows.
--  MaterialService.StudProof_A    the three maps, normal map as made (Tokens.stud.worldNormalMapId)
--  MaterialService.StudProof_B    the three maps, normal map flipped (green inverted; Tokens.stud.worldNormalMapFlippedId)
--  Workspace.StudProof            two identical test sets side by side, A on the left, B on the right: a floor (the slab), a wall of
--                                 mixed brick sizes, a crate, three tint cubes (red, green, blue: does BasePart.Color tint the variant),
--                                 and one UI button with the tiled stud overlay, each labelled. Placed at hub X 100..280, Z 400..470 (south of
--                                 the zone 1 ground, which ends at Z 380). View from the south (Z ~405), looking +Z; faces point -Z.
-- Idempotent. Needs the DevSync sync first (reads Skins.brickbrawl.Tokens).
--   require(game.ServerStorage.DevSync:Clone()).run("SetupStud.lua")
local PROMOTE = "flipped" -- nil = Stud stays a plain stand-in; "normal" or "flipped" after the manager's yes

local MaterialService = game:GetService("MaterialService")
local RS = game:GetService("ReplicatedStorage")
local skins = RS:FindFirstChild("Skins")
local tokMod = skins and skins:FindFirstChild("brickbrawl") and skins.brickbrawl:FindFirstChild("Tokens")
if not tokMod then error("SetupStud: ReplicatedStorage.Skins.brickbrawl.Tokens missing; run the DevSync sync first", 0) end
local Tokens = require(tokMod)
local S, C, U = Tokens.stud, Tokens.colors, Tokens.ui
local function url(id) return "rbxassetid://" .. tostring(id) end

local function variant(name, normalId)
	local old = MaterialService:FindFirstChild(name)
	if old then old:Destroy() end
	local v = Instance.new("MaterialVariant")
	v.Name = name
	v.BaseMaterial = Enum.Material.SmoothPlastic
	v.StudsPerTile = S.studsPerTile
	if normalId then
		v.ColorMap = url(S.worldColorMapId)
		v.NormalMap = url(normalId)
		v.RoughnessMap = url(S.worldRoughMapId)
	end
	v.Parent = MaterialService
	return v
end

local promoteId = (PROMOTE == "normal" and S.worldNormalMapId) or (PROMOTE == "flipped" and S.worldNormalMapFlippedId) or nil
variant(S.variantName, promoteId)
variant("StudProof_A", S.worldNormalMapId)
variant("StudProof_B", S.worldNormalMapFlippedId)

-- ---------------------------------------------------------------- proof strip
local old = workspace:FindFirstChild("StudProof")
if old then old:Destroy() end
local Proof = Instance.new("Folder"); Proof.Name = "StudProof"; Proof.Parent = workspace

local function box(parent, name, x0, z0, x1, z1, y0, h, col, var)
	local p = Instance.new("Part")
	p.Name = name; p.Anchored = true
	p.Size = Vector3.new(x1 - x0, h, z1 - z0)
	p.Position = Vector3.new((x0 + x1) / 2, y0 + h / 2, (z0 + z1) / 2)
	p.Color = col; p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if var then p.MaterialVariant = var end
	p.Parent = parent
	return p
end

local function label(part, text, textColor, fillColor)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 24
	g.Parent = part
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1); t.BackgroundColor3 = fillColor; t.BorderSizePixel = 0
	t.Text = text; t.TextColor3 = textColor; t.TextScaled = true; t.Font = Enum.Font.GothamBlack
	t.Parent = g
end

local function set(ox, var, title)
	local m = Instance.new("Model"); m.Name = "Set_" .. var; m.Parent = Proof
	box(m, "Floor", ox, 400, ox + 80, 470, -2, 2, C.zone1.ground, var)
	local lab = box(m, "Sign", ox + 4, 410, ox + 28, 411, 0, 3, C.ink)
	label(lab, title, C.white, C.ink)
	-- wall of mixed brick sizes on the 1-stud grid (4 x 2 and 8 x 2 bricks, staggered)
	local w = Instance.new("Model"); w.Name = "Wall"; w.Parent = m
	box(w, "R1_a", ox + 4, 440, ox + 8, 442, 0, 2, C.zone1.structure, var)
	box(w, "R1_b", ox + 8, 440, ox + 16, 442, 0, 2, C.zone1.structure, var)
	box(w, "R2_a", ox + 4, 440, ox + 12, 442, 2, 2, C.zone1.structure, var)
	box(w, "R2_b", ox + 12, 440, ox + 16, 442, 2, 2, C.zone1.structure, var)
	-- M1-21: rotated bricks (tile alignment on rotated parts): a 4 x 2 pair turned 90 degrees and an 8 x 2 pair turned 45, both
	-- stacked as a wall two bricks high; the plain wall above is the axis-aligned reference
	local rw = Instance.new("Model"); rw.Name = "RotatedWall"; rw.Parent = m
	for i, spec in ipairs({ { 0, 4 }, { 4, 4 }, { 8, 4 } }) do
		local p1 = box(rw, "Rot90_" .. i, 0, 0, spec[2], 2, (i - 1) % 2 * 2, 2, C.zone1.structure, var)
		p1.CFrame = CFrame.new(ox + 4 + (i - 1) * 2, 1 + (i - 1) % 2 * 2, 456) * CFrame.Angles(0, math.rad(90), 0)
	end
	for i = 1, 2 do
		local p2 = box(rw, "Rot45_" .. i, 0, 0, 8, 2, 0, 2, C.zone1.structure, var)
		p2.CFrame = CFrame.new(ox + 30 + (i - 1) * 6, 1 + (i - 1) * 2, 456) * CFrame.Angles(0, math.rad(45), 0)
	end
	box(m, "Crate", ox + 22, 420, ox + 26, 424, 0, 4, C.shopGold, var)
	box(m, "TintRed", ox + 32, 420, ox + 36, 424, 0, 4, C.hussRed, var)
	box(m, "TintGreen", ox + 38, 420, ox + 42, 424, 0, 4, C.cashGreen, var)
	box(m, "TintBlue", ox + 44, 420, ox + 48, 424, 0, 4, C.plateBlue, var)
	-- one UI button: the Huss button recipe (plate fill, ink outline, tiled stud overlay at 16 px) on a 12 x 6 board, 20 px a stud
	local b = box(m, "UiButton", ox + 54, 430, ox + 66, 431, 0, 6, C.panelGrey)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front; g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; g.PixelsPerStud = 20; g.Parent = b
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = C.hussRed; f.BorderSizePixel = 0; f.Parent = g
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, U.radiusPx); c.Parent = f
	local st = Instance.new("UIStroke"); st.Color = C.ink; st.Thickness = U.hussOutlinePx; st.Parent = f
	if S.uiTileId ~= 0 then
		local img = Instance.new("ImageLabel")
		img.Name = "Studs"; img.BackgroundTransparency = 1; img.BorderSizePixel = 0; img.Size = UDim2.fromScale(1, 1)
		img.Image = url(S.uiTileId); img.ScaleType = Enum.ScaleType.Tile; img.TileSize = UDim2.fromOffset(U.studTilePx, U.studTilePx)
		img.Parent = f
		local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0, U.radiusPx); c2.Parent = img
	end
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Size = UDim2.fromScale(1, 1); t.Text = "HUSS"; t.TextColor3 = C.white
	t.Font = Enum.Font.GothamBlack; t.TextSize = 56; t.Parent = f
	local ts = Instance.new("UIStroke"); ts.Color = C.ink; ts.Thickness = 3; ts.Parent = t
	return m
end
set(100, "StudProof_A", "A  normal map as made")
set(200, "StudProof_B", "B  normal map flipped")

local ok = MaterialService:FindFirstChild("Stud") and MaterialService:FindFirstChild("StudProof_A") and MaterialService:FindFirstChild("StudProof_B")
print(("SetupStud: %s variants Stud (%s), StudProof_A, StudProof_B; Workspace.StudProof has %d parts"):format(ok and "PASS" or "FAIL", PROMOTE and ("maps, " .. PROMOTE) or "plain stand-in", #Proof:GetDescendants()))
