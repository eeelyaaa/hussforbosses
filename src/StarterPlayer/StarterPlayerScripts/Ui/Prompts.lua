--!nonstrict
-- Ui/Prompts: the Place, Grab and start-a-fight prompts (style guide 6, screen 12: a white studded plate with the input glyph on a
-- small ink plate, and the word). Screen-space at M1, bottom centre; the world-space versions (BillboardGui on the object) are M2/M3.
--   show(kind: "place"|"grab"|"start", glyphKind: "keyboard"|"gamepad"|"touch")   hide(kind)   onPress(kind, fn)
-- Glyph by input in use (docs/controls.md): keyboard E (start: F), gamepad X (start: RT), touch: no glyph, the plate itself is the
-- on-screen prompt button. The plate is at least 44 px tall on screen. The word comes from Skin.Names.hudWords.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Skin = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skin"))
local C, U, N, TY = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Names, Skin.Tokens.type

local Prompts = {}
local S = nil

-- key letters are controls, not skin names (docs/controls.md)
local GLYPH = {
	place = { keyboard = "E", gamepad = "X" },
	grab = { keyboard = "E", gamepad = "X" },
	start = { keyboard = "F", gamepad = "RT" },
}
local WORD = { place = "place", grab = "grab", start = "huss" }
local ORDER = { place = 1, grab = 2, start = 3 }
local PLATE_W = 190
local GLYPH_PLATE = 32

function Prompts.build(parent: Instance)
	Prompts.destroy()
	S = { kinds = {}, callbacks = { place = {}, grab = {}, start = {} } }
	local holder = Instance.new("Frame")
	holder.Name = "Prompts"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, -72)
	holder.Size = UDim2.fromOffset(PLATE_W + 20, 130)
	holder.Parent = parent
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, U.gap + U.lipPx)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = holder
	S.holder = holder

	for kind in pairs(ORDER) do
		local h = math.max(U.buttonH - 4, Kit.minDesign(U.touchMin))
		local b = Kit.Button(holder, { name = "Prompt_" .. kind, text = string.upper(N.hudWords[WORD[kind]]), fill = C.white, ink = true, textSize = TY.button, size = UDim2.fromOffset(PLATE_W, h) })
		b.root.LayoutOrder = ORDER[kind]
		b.root.Visible = false
		-- glyph plate (ink square with the key letter); hidden on touch
		local gp = Kit.Plate(b.face, { name = "Glyph", fill = C.ink, size = UDim2.fromOffset(GLYPH_PLATE, GLYPH_PLATE), position = UDim2.new(0, 8, 0.5, 0), anchor = Vector2.new(0, 0.5), outline = U.wellOutlinePx, studs = false })
		gp.ZIndex = 5
		local gl = Kit.Text(gp, { name = "Letter", text = "", size = TY.button })
		gl.ZIndex = 6
		b.onActivated(function()
			for _, fn in ipairs(S.callbacks[kind]) do
				task.spawn(fn)
			end
		end)
		S.kinds[kind] = { button = b, glyphPlate = gp, glyphLabel = gl }
	end

	S.scaleConn = Kit.onScale(function()
		if not S then
			return
		end
		for _, k in pairs(S.kinds) do
			k.button.root.Size = UDim2.fromOffset(PLATE_W, math.max(U.buttonH - 4, Kit.minDesign(U.touchMin)))
		end
	end)
	return holder
end

function Prompts.destroy()
	if S then
		if S.scaleConn then
			S.scaleConn.Disconnect()
		end
		S.holder:Destroy()
		S = nil
	end
end

function Prompts.instance()
	return S and S.holder
end

function Prompts.parts()
	return S
end

function Prompts.show(kind: string, glyphKind: string)
	if not S then
		return
	end
	local k = S.kinds[kind]
	assert(k, "Prompts.show: unknown kind " .. tostring(kind))
	local glyph = GLYPH[kind][glyphKind]
	k.glyphPlate.Visible = glyph ~= nil
	k.glyphLabel.Text = glyph or ""
	k.button.label.Position = UDim2.fromOffset(glyph and (GLYPH_PLATE + 8) or 0, 0)
	k.button.label.Size = UDim2.new(1, glyph and -(GLYPH_PLATE + 8) or 0, 1, 0)
	k.glyphKind = glyphKind
	k.button.root.Visible = true
end

function Prompts.hide(kind: string)
	if not S then
		return
	end
	local k = S.kinds[kind]
	if k then
		k.button.root.Visible = false
	end
end

function Prompts.onPress(kind: string, fn)
	if S and S.callbacks[kind] then
		table.insert(S.callbacks[kind], fn)
	end
end

return Prompts
