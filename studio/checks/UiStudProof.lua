if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-15 UI stud proof (gui-designer). Edit mode, studio lock held, after a sync:
--   require(game.ServerStorage.DevSync:Clone()).run("checks/UiStudProof.lua")
-- Builds StarterGui.StudProofUi: the Huss button (round, stud tile clipped to the circle) and one studded panel with text, at
-- UIScale 0.75, 1.0 and 1.65, left to right. Prints read-backs. Remove with ONE call:
--   game.StarterGui.StudProofUi:Destroy()     (also run this script again: it replaces the old proof first)
-- The tile of each section is sized for that section's scale (Kit.StudTile fixedScale), independent of any live HUD.
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ContentProvider = game:GetService("ContentProvider")
local TextService = game:GetService("TextService")

local Kit = require(StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Ui"):WaitForChild("Kit"))
local Skin = require(game:GetService("ReplicatedStorage").Shared.Skin)
local C, U, TY = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type

local old = StarterGui:FindFirstChild("StudProofUi")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "StudProofUi"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Kit.shade(C.plateBlue, 0.55)
backdrop.BorderSizePixel = 0
backdrop.Parent = gui

local SCALES = { 0.75, 1.0, 1.65 }
local DESIGN_W, DESIGN_H = 300, 280
local GAP = 24
local PANEL_W, PANEL_H = 280, 96
local x = 24
local sections = {}
local lines = {}
local function out(s) print("UiStudProof: " .. s) table.insert(lines, s) end

for _, s in ipairs(SCALES) do
	local sec = Instance.new("Frame")
	sec.Name = ("Scale_%.2f"):format(s)
	sec.BackgroundTransparency = 1
	sec.Size = UDim2.fromOffset(DESIGN_W, DESIGN_H)
	sec.Position = UDim2.fromOffset(x, 24)
	local us = Instance.new("UIScale")
	us.Scale = s
	us.Parent = sec
	sec.Parent = backdrop
	x += math.ceil(DESIGN_W * s) + GAP

	Kit.Text(sec, { name = "Caption", text = ("UIScale %.2f"):format(s), size = 16, position = UDim2.fromOffset(10, 0), sizeU = UDim2.fromOffset(280, 22), align = Enum.TextXAlignment.Left })

	-- panel: 4 px UICorner, 3 px outline, tile, one line of 16 px text over the studs
	local panel = Kit.Plate(sec, { name = "Panel", fill = C.panelGrey, size = UDim2.fromOffset(PANEL_W, PANEL_H), position = UDim2.fromOffset(10, 28), fixedScale = s })
	Kit.Text(panel, { name = "Text", text = "POWER 1,234", size = 16 })

	-- Huss button: same recipe as Ui/HussButton (lip, face, stud tile on the round face, label)
	local H = math.max(U.hussButtonPx, math.ceil(U.hussButtonMinPx / s))
	local faceD = H - 2 * U.hussOutlinePx
	local cx, cy = 10 + H / 2 + 4, 28 + PANEL_H + 16 + H / 2 + 4
	local function round(name, z)
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = UDim2.fromOffset(faceD, faceD)
		f.BorderSizePixel = 0
		f.ZIndex = z
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = f
		local st = Instance.new("UIStroke")
		st.Color = C.ink
		st.Thickness = U.hussOutlinePx
		st.Parent = f
		f.Parent = sec
		return f
	end
	local lip = round("Lip", 4)
	lip.BackgroundColor3 = Kit.shade(C.hussRed, U.lipFactor)
	lip.Position = UDim2.fromOffset(cx, cy + U.hussLipPx)
	local face = round("Face", 5)
	face.BackgroundColor3 = C.hussRed
	face.Position = UDim2.fromOffset(cx, cy)
	Kit.StudTile(face, 0.5, s)
	local label = Kit.Text(face, { name = "Label", text = "HUSS!", size = TY.huss })
	label.ZIndex = 6
	table.insert(sections, { s = s, sec = sec, panel = panel, face = face, H = H, faceD = faceD })
end
gui.Parent = StarterGui

-- ---------------------------------------------------------------- read-backs
for _, r in ipairs(sections) do
	local s = r.s
	local pt = r.panel:FindFirstChild("Studs")
	local ft = r.face:FindFirstChild("Studs")
	out(("scale %.2f: section AbsoluteSize %dx%d (design %dx%d)"):format(s, r.sec.AbsoluteSize.X, r.sec.AbsoluteSize.Y, DESIGN_W, DESIGN_H))
	out(("  panel AbsoluteSize %.1fx%.1f px (design %dx%d x %.2f)"):format(r.panel.AbsoluteSize.X, r.panel.AbsoluteSize.Y, PANEL_W, PANEL_H, s))
	local t = pt.TileSize
	local onScreen = t.X.Offset * s
	out(("  panel tile TileSize = (%.3f,%.3f) Offset, scale parts (%g,%g), ScaleType %s -> %.2f px on screen (clamp %d..%d) %s"):format(
		t.X.Offset, t.Y.Offset, t.X.Scale, t.Y.Scale, pt.ScaleType.Name, onScreen, U.studTileMin, U.studTileMax,
		(onScreen >= U.studTileMin - 0.01 and onScreen <= U.studTileMax + 0.01) and "PASS" or "FAIL"))
	out(("  panel studs across: %.2f x %.2f (same at every scale if the tile follows the UIScale)"):format(r.panel.AbsoluteSize.X / onScreen, r.panel.AbsoluteSize.Y / onScreen))
	local pc = pt:FindFirstChildOfClass("UICorner")
	local pcp = r.panel:FindFirstChildOfClass("UICorner")
	out(("  clip: panel corner %s design px, tile corner %s design px (screen %.2f px), tile AbsoluteSize == panel %s"):format(
		pcp.CornerRadius.Offset, pc.CornerRadius.Offset, pc.CornerRadius.Offset * s, tostring(pt.AbsoluteSize == r.panel.AbsoluteSize)))
	local fc = r.face:FindFirstChildOfClass("UICorner")
	local fcc = ft:FindFirstChildOfClass("UICorner")
	out(("  Huss button: %d design px (%.1f px on screen, floor 96 %s); face AbsoluteSize %.1fx%.1f; face corner scale %.2f, tile corner scale %.2f; tile AbsoluteSize == face %s; TileSize %.3f Offset -> %.2f px"):format(
		r.H, r.H * s, (r.H * s >= 96 - 0.01) and "PASS" or "FAIL", r.face.AbsoluteSize.X, r.face.AbsoluteSize.Y, fc.CornerRadius.Scale, fcc.CornerRadius.Scale,
		tostring(ft.AbsoluteSize == r.face.AbsoluteSize), ft.TileSize.X.Offset, ft.TileSize.X.Offset * s))
	local ps = r.panel:FindFirstChild("Outline")
	local fs = r.face:FindFirstChildOfClass("UIStroke")
	local ts = r.panel.Text.Outline
	out(("  UIStroke Thickness (design px; x%.2f = expected on screen): panel %g -> %.2f, Huss face %g -> %.2f, text %g -> %.2f"):format(
		s, ps.Thickness, ps.Thickness * s, fs.Thickness, fs.Thickness * s, ts.Thickness, ts.Thickness * s))
end

-- font weight
local fam = Skin.Tokens.font.family
local heavy = Font.new("rbxasset://fonts/families/" .. fam .. ".json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
local bold = Font.new("rbxasset://fonts/families/" .. fam .. ".json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
out(("font: Tokens weight name %q -> Enum.FontWeight.%s (Value %d); Kit.fontHeavy.Weight = %s, family %s"):format(Skin.Tokens.font.weight, Kit.fontHeavy.Weight.Name, Kit.fontHeavy.Weight.Value, Kit.fontHeavy.Weight.Name, Kit.fontHeavy.Family))
local lbl = sections[1].face.Label
out(("font: HUSS! label FontFace.Weight = %s, Bold = %s"):format(lbl.FontFace.Weight.Name, Kit.fontBody.Weight.Name))
local okH, bh = pcall(function() local p = Instance.new("GetTextBoundsParams") p.Text = "HUSS HUSS HUSS" p.Font = heavy p.Size = 40 p.Width = 10000 return TextService:GetTextBoundsAsync(p) end)
local okB, bb = pcall(function() local p = Instance.new("GetTextBoundsParams") p.Text = "HUSS HUSS HUSS" p.Font = bold p.Size = 40 p.Width = 10000 return TextService:GetTextBoundsAsync(p) end)
if okH and okB then
	out(("font: text width at 40 px, Heavy %.1f vs Bold %.1f -> %s"):format(bh.X, bb.X, (math.abs(bh.X - bb.X) > 0.5) and "PASS (Heavy resolves to a different, wider face than Bold)" or "SAME WIDTH: check the face"))
else
	out("font: GetTextBoundsAsync failed: " .. tostring(bh) .. " / " .. tostring(bb))
end
for _, w in ipairs({ "Black", "ExtraBold", "Heavy" }) do
	out(("font: Enum.FontWeight.%s exists: %s"):format(w, tostring(pcall(function() return Enum.FontWeight[w] end))))
end

-- image load
local img = sections[1].panel.Studs
local statuses = {}
ContentProvider:PreloadAsync({ img }, function(id, status) table.insert(statuses, id .. " = " .. status.Name) end)
out("PreloadAsync: " .. table.concat(statuses, "; ") .. " | Image " .. img.Image .. " | ImageLabel.IsLoaded " .. tostring(img.IsLoaded))
print("UiStudProof: built StarterGui.StudProofUi (" .. #sections .. " sections). Remove: game.StarterGui.StudProofUi:Destroy()")
