--!nonstrict
-- Ui/Kit: the shared pieces every view is built from (m1-contract.md section I). Reads Skin.Tokens only: no hex, no asset id.
--   Kit.Scale(gui, override?)   the one UIScale rule: min(w/874, h/402), x0.75 on mouse and keyboard. Returns a handle
--                               { root, uiScale, set(viewport, mouse), apply(), destroy() }. Everything is laid out in
--                               DESIGN px (the 874 x 402 frame) inside handle.root, which is the full screen / scale.
--   Kit.scale()                 the current scale; Kit.onScale(fn) subscribes (fn(scale)); Kit.minDesign(px) = design px
--                               that render as at least px on screen (touch targets, the Huss button floor).
--   Kit.Font / Kit.Text         Montserrat, outlined, with a text floor (never renders under 14 px on screen, boost capped at 1.3x).
--   Kit.Plate / Kit.Panel       studded rectangle in a job colour: corner, ink outline, stud tile (plain fill while uiTileId == 0).
--   Kit.StudTile                the tiled ImageLabel (ScaleType Tile; TileSize in Offset = studTilePx x scale, clamped 12 to 32 on screen).
--   Kit.Button                  lip, top line, hover, pressed, disabled.  Kit.Counter is built in Ui/Counters from Kit.Plate.
--   Kit.Icon                    the icon by key, or a plain square stand-in while its id is 0.
-- Stroke thickness is in design px under the UIScale (assumed to scale with it; checked on screen, and by M1-15).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Skin = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skin"))
local Tokens = Skin.Tokens
local C = Tokens.colors
local U = Tokens.ui

local TEXT_FLOOR_PX = 14 -- style guide 6, "Type": no text renders under 14 px on any device
local TEXT_FLOOR_MAX_BOOST = 1.3

local Kit = {}
Kit.Tokens = Tokens
Kit.C = C
Kit.U = U

local state = {
	scale = 1,
	mouse = false,
	viewport = Vector2.new(U.designW, U.designH),
	listeners = {},
	texts = setmetatable({}, { __mode = "k" }), -- label -> design size
	tiles = setmetatable({}, { __mode = "k" }), -- ImageLabel -> true
}

-- ---------------------------------------------------------------- scale

function Kit.scale(): number
	return state.scale
end

function Kit.isMouse(): boolean
	return state.mouse
end

function Kit.minDesign(screenPx: number): number
	return math.ceil(screenPx / state.scale)
end

function Kit.computeScale(viewport: Vector2, mouse: boolean): number
	local s = math.min(viewport.X / U.designW, viewport.Y / U.designH)
	if mouse then
		s = s * U.mouseScale
	end
	return s
end

local function floorSize(designSize: number): number
	local want = math.ceil(TEXT_FLOOR_PX / state.scale)
	return math.min(math.max(designSize, want), math.floor(designSize * TEXT_FLOOR_MAX_BOOST))
end

local function tileDesignPx(scale: number?): number
	local sc = scale or state.scale
	local onScreen = math.clamp(U.studTilePx * sc, U.studTileMin, U.studTileMax)
	return onScreen / sc
end

local function fire()
	for label, ds in pairs(state.texts) do
		if label.Parent then
			label.TextSize = floorSize(ds)
		end
	end
	for tile in pairs(state.tiles) do
		if tile.Parent then
			local t = tileDesignPx()
			tile.TileSize = UDim2.fromOffset(t, t)
		end
	end
	for _, entry in ipairs(table.clone(state.listeners)) do
		entry.fn(state.scale)
	end
end

function Kit.onScale(fn)
	local entry = { fn = fn }
	table.insert(state.listeners, entry)
	return {
		Disconnect = function()
			local i = table.find(state.listeners, entry)
			if i then
				table.remove(state.listeners, i)
			end
		end,
	}
end

function Kit.reset()
	state.listeners = {}
end

function Kit.Scale(gui: ScreenGui, override: { viewport: Vector2?, mouse: boolean? }?)
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Parent = gui
	local uiScale = Instance.new("UIScale")
	uiScale.Name = "UIScale"
	uiScale.Parent = root

	local handle = { root = root, uiScale = uiScale, override = override or {}, conns = {} }

	function handle.apply()
		local o = handle.override
		local cam = workspace.CurrentCamera
		local vp = o.viewport or (cam and cam.ViewportSize) or Vector2.new(U.designW, U.designH)
		local mouse = o.mouse
		if mouse == nil then
			mouse = UserInputService.KeyboardEnabled and UserInputService.MouseEnabled and not UserInputService.TouchEnabled
		end
		local s = Kit.computeScale(vp, mouse)
		state.scale, state.mouse, state.viewport = s, mouse, vp
		uiScale.Scale = s
		-- the root is the whole screen in design px: (screen px) / s, drawn through the UIScale
		root.Size = UDim2.fromOffset(vp.X / s, vp.Y / s)
		fire()
	end

	function handle.set(viewport: Vector2?, mouse: boolean?)
		handle.override = { viewport = viewport, mouse = mouse }
		handle.apply()
	end

	function handle.destroy()
		for _, c in ipairs(handle.conns) do
			c:Disconnect()
		end
		handle.conns = {}
		root:Destroy()
	end

	local function watchCamera()
		local cam = workspace.CurrentCamera
		if cam then
			table.insert(handle.conns, cam:GetPropertyChangedSignal("ViewportSize"):Connect(handle.apply))
		end
	end
	watchCamera()
	table.insert(handle.conns, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		watchCamera()
		handle.apply()
	end))

	handle.apply()
	return handle
end

-- Centre of a gui object in design px relative to the root (AbsolutePosition is in screen px).
function Kit.toDesign(root: GuiObject, obj: GuiObject): Vector2
	local centre = obj.AbsolutePosition + obj.AbsoluteSize / 2
	return (centre - root.AbsolutePosition) / state.scale
end

-- ---------------------------------------------------------------- colour helpers

function Kit.lighten(c: Color3, f: number): Color3
	return c:Lerp(C.white, f)
end

function Kit.shade(c: Color3, f: number): Color3
	local h, s, v = c:ToHSV() -- scaling V scales every channel: the kit's "fill x 0.72"
	return Color3.fromHSV(h, s, v * f)
end

-- ---------------------------------------------------------------- font and text

local function makeFont(spec): Font
	local ok, weight = pcall(function()
		return Enum.FontWeight[spec.weight]
	end)
	return Font.new("rbxasset://fonts/families/" .. spec.family .. ".json", ok and weight or Enum.FontWeight.Bold, Enum.FontStyle.Normal)
end

Kit.fontHeavy = makeFont(Tokens.font)
Kit.fontBody = makeFont(Tokens.fontBody or Tokens.font)

function Kit.Font(body: boolean?): Font
	return body and Kit.fontBody or Kit.fontHeavy
end

function Kit.commas(n: number): string
	local s = string.format("%d", math.floor(n + 0.5))
	local neg = string.sub(s, 1, 1) == "-"
	if neg then
		s = string.sub(s, 2)
	end
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return (neg and "-" or "") .. out
end

-- p: name, text, size (design px), color, body (Bold, sentence case), plain (no outline: dark text on a light well),
--    align, position, anchor, sizeU
function Kit.Text(parent: Instance?, p): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = p.name or "Text"
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.FontFace = Kit.Font(p.body)
	l.Text = p.text or ""
	l.TextColor3 = p.color or C.white
	l.TextXAlignment = p.align or Enum.TextXAlignment.Center
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextWrapped = false
	l.RichText = false
	l.Size = p.sizeU or UDim2.fromScale(1, 1)
	l.Position = p.position or UDim2.new()
	l.AnchorPoint = p.anchor or Vector2.zero
	local ds = p.size or Tokens.type.button
	state.texts[l] = ds
	l.TextSize = floorSize(ds)
	if not p.plain then
		local stroke = Instance.new("UIStroke")
		stroke.Name = "Outline"
		stroke.Color = C.ink
		stroke.Thickness = U.textOutlinePx
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Parent = l
	end
	l.Parent = parent
	return l
end

-- ---------------------------------------------------------------- stud tile, plate, panel

local warnedUrl = false
local function assetUrl(id: number): string?
	-- The one place an id becomes a content string is the skin (nothing outside Skins/ writes the prefix). Until Skin.assetUrl
	-- exists (contract issue reported by M1-08) a non-zero id draws the plain fill.
	local f = Skin.assetUrl
	if type(f) == "function" then
		return f(id)
	end
	if not warnedUrl then
		warnedUrl = true
		warn("[Ui.Kit] Tokens.stud.uiTileId is set but Skin.assetUrl(id) does not exist: drawing plain fills")
	end
	return nil
end

-- Tile over a surface; the frame keeps its colour. Returns nil while the tile id is 0.
-- fixedScale (the M1-15 proof only): size the tile for this UIScale and do not follow the live scale.
function Kit.StudTile(parent: GuiObject, cornerScale: number?, fixedScale: number?): ImageLabel?
	local id = Tokens.stud.uiTileId
	if id == 0 then
		return nil
	end
	local url = assetUrl(id)
	if not url then
		return nil
	end
	local img = Instance.new("ImageLabel")
	img.Name = "Studs"
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.Size = UDim2.fromScale(1, 1)
	img.Image = url
	img.ScaleType = Enum.ScaleType.Tile
	local t = tileDesignPx(fixedScale)
	img.TileSize = UDim2.fromOffset(t, t)
	img.ZIndex = parent.ZIndex
	local corner = Instance.new("UICorner")
	corner.CornerRadius = cornerScale and UDim.new(cornerScale, 0) or UDim.new(0, U.radiusPx)
	corner.Parent = img
	img.Parent = parent
	if not fixedScale then
		state.tiles[img] = true
	end
	return img
end

-- p: name, fill, size, position, anchor, outline, radius, studs (default true), fixedScale (M1-15 proof only: tile sized for that UIScale)
function Kit.Plate(parent: Instance?, p): Frame
	local f = Instance.new("Frame")
	f.Name = p.name or "Plate"
	f.BackgroundColor3 = p.fill or C.panelGrey
	f.BorderSizePixel = 0
	f.Size = p.size or UDim2.fromOffset(100, 32)
	f.Position = p.position or UDim2.new()
	f.AnchorPoint = p.anchor or Vector2.zero
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, p.radius or U.radiusPx)
	corner.Parent = f
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Outline"
	stroke.Color = C.ink
	stroke.Thickness = p.outline or U.outlinePx
	stroke.Parent = f
	if p.studs ~= false then
		Kit.StudTile(f, nil, p.fixedScale)
	end
	f.Parent = parent
	return f
end

function Kit.Panel(parent: Instance?, p): Frame
	p.fill = p.fill or C.panelGrey
	p.name = p.name or "Panel"
	return Kit.Plate(parent, p)
end

-- ---------------------------------------------------------------- tween helpers

function Kit.tween(obj: Instance, props, t: number, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- Scale pop through a child UIScale named "Pop": 1 -> peak in upT, back to 1 in downT. A new pop cancels the old.
function Kit.popScale(obj: GuiObject, peak: number, upT: number, downT: number)
	local s = obj:FindFirstChild("Pop")
	if not s then
		s = Instance.new("UIScale")
		s.Name = "Pop"
		s.Parent = obj
	end
	local gen = (s:GetAttribute("gen") or 0) + 1
	s:SetAttribute("gen", gen)
	s.Scale = 1
	Kit.tween(s, { Scale = peak }, upT)
	task.delay(upT, function()
		if s.Parent and s:GetAttribute("gen") == gen then
			Kit.tween(s, { Scale = 1 }, downT)
		end
	end)
end

-- Sideways shake: offsets in px, 0.03 s each, then back to base.
function Kit.shake(obj: GuiObject, px: number, times: number)
	local base = obj.Position
	local gen = (obj:GetAttribute("shakeGen") or 0) + 1
	obj:SetAttribute("shakeGen", gen)
	task.spawn(function()
		for i = 1, times * 2 do
			if obj.Parent == nil or obj:GetAttribute("shakeGen") ~= gen then
				return
			end
			local dx = (i % 2 == 1) and px or -px
			obj.Position = base + UDim2.fromOffset(dx, 0)
			task.wait(0.0375)
		end
		if obj.Parent and obj:GetAttribute("shakeGen") == gen then
			obj.Position = base
		end
	end)
end

-- ---------------------------------------------------------------- icons

-- Icon by key (Skin.Icons), or a plain square stand-in while the id is 0 or unresolved.
function Kit.Icon(parent: Instance?, key: string, p): GuiObject
	local px = p.size or U.glyphPx
	local id = Skin.Icons[key]
	local url = (id and id ~= 0) and assetUrl(id) or nil
	local obj
	if url then
		obj = Instance.new("ImageLabel")
		obj.BackgroundTransparency = 1
		obj.Image = url
		obj.ScaleType = Enum.ScaleType.Fit
	else
		obj = Instance.new("Frame")
		obj.BackgroundColor3 = p.standIn or C.white
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, U.radiusPx)
		corner.Parent = obj
		local stroke = Instance.new("UIStroke")
		stroke.Color = C.ink
		stroke.Thickness = U.wellOutlinePx
		stroke.Parent = obj
	end
	obj.Name = p.name or ("Icon_" .. key)
	obj.BorderSizePixel = 0
	obj.Size = UDim2.fromOffset(px, px)
	obj.Position = p.position or UDim2.new()
	obj.AnchorPoint = p.anchor or Vector2.zero
	obj.Parent = parent
	return obj
end

-- A square-built heart (7 x 6 cells), the stand-in while Icons.heart is 0. Returns the holder; setColor(c) recolours it.
local HEART = { "0110110", "1111111", "1111111", "0111110", "0011100", "0001000" }
function Kit.PixelHeart(parent: Instance?, color: Color3, cell: number)
	local holder = Instance.new("Frame")
	holder.Name = "Heart"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(cell * 7, cell * 6)
	holder.Parent = parent
	local cells = {}
	for r, row in ipairs(HEART) do
		for c = 1, 7 do
			if string.sub(row, c, c) == "1" then
				local f = Instance.new("Frame")
				f.Name = "Cell"
				f.BorderSizePixel = 0
				f.BackgroundColor3 = color
				f.Size = UDim2.fromOffset(cell, cell)
				f.Position = UDim2.fromOffset((c - 1) * cell, (r - 1) * cell)
				f.Parent = holder
				table.insert(cells, f)
			end
		end
	end
	local obj = { holder = holder }
	function obj.setColor(col: Color3)
		for _, f in ipairs(cells) do
			f.BackgroundColor3 = col
		end
	end
	return obj
end

-- ---------------------------------------------------------------- button

-- p: name, text, fill, textColor, ink (dark text, no outline), textSize, size (UDim2, design px), position, anchor
-- Returns { root, face, lip, label, setText, setEnabled, onActivated, setSize, enabled }.
function Kit.Button(parent: Instance?, p)
	local fill = p.fill or C.white
	local b = { enabled = true, hover = false, down = false, callbacks = {} }

	local root = Instance.new("Frame")
	root.Name = p.name or "Button"
	root.BackgroundTransparency = 1
	root.Size = p.size or UDim2.fromOffset(120, U.buttonH)
	root.Position = p.position or UDim2.new()
	root.AnchorPoint = p.anchor or Vector2.zero
	root.Parent = parent

	local lip = Instance.new("Frame")
	lip.Name = "Lip"
	lip.BorderSizePixel = 0
	lip.Size = UDim2.fromScale(1, 1)
	lip.Position = UDim2.fromOffset(0, U.lipPx)
	local lc = Instance.new("UICorner")
	lc.CornerRadius = UDim.new(0, U.radiusPx)
	lc.Parent = lip
	local ls = Instance.new("UIStroke")
	ls.Color = C.ink
	ls.Thickness = U.outlinePx
	ls.Parent = lip
	lip.Parent = root

	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.AutoButtonColor = false
	face.Text = ""
	face.BorderSizePixel = 0
	face.Size = UDim2.fromScale(1, 1)
	face.ZIndex = 2
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, U.radiusPx)
	fc.Parent = face
	local fs = Instance.new("UIStroke")
	fs.Color = C.ink
	fs.Thickness = U.outlinePx
	fs.Parent = face
	face.Parent = root
	Kit.StudTile(face)

	local top = Instance.new("Frame")
	top.Name = "TopLine"
	top.BorderSizePixel = 0
	top.Size = UDim2.new(1, -2 * U.radiusPx, 0, 2)
	top.Position = UDim2.fromOffset(U.radiusPx, 2)
	top.ZIndex = 3
	top.Parent = face

	local label = Kit.Text(face, { name = "Label", text = p.text or "", size = p.textSize or Tokens.type.button, color = p.textColor or (p.ink and C.ink or C.white), plain = p.ink })
	label.ZIndex = 4

	b.root, b.face, b.lip, b.label = root, face, lip, label

	local function refresh()
		local base = b.enabled and fill or C.disabledGrey
		if b.enabled and b.hover and not b.down then
			base = Kit.lighten(base, U.hoverLighten)
		end
		if b.down and b.enabled then
			base = Kit.shade(base, U.pressedFill)
		end
		face.BackgroundColor3 = base
		lip.BackgroundColor3 = Kit.shade(b.enabled and fill or C.disabledGrey, U.lipFactor)
		top.BackgroundColor3 = Kit.lighten(base, U.topLineLighten)
		top.Visible = b.enabled
		label.TextColor3 = b.enabled and (p.textColor or (p.ink and C.ink or C.white)) or C.disabledText
		local dy = 0
		if b.down and b.enabled then
			dy = U.pressedDropPx
		elseif b.hover and b.enabled then
			dy = -1
		end
		face.Position = UDim2.fromOffset(0, dy)
		lip.Position = UDim2.fromOffset(0, b.enabled and U.lipPx or 2)
	end
	refresh()
	b.refresh = refresh

	face.MouseEnter:Connect(function()
		b.hover = true
		refresh()
	end)
	face.MouseLeave:Connect(function()
		b.hover = false
		b.down = false
		refresh()
	end)
	face.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			b.down = true
			refresh()
		end
	end)
	face.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			b.down = false
			refresh()
		end
	end)
	face.Activated:Connect(function()
		if not b.enabled then
			Kit.shake(face, 6, 2) -- a tap on a disabled button shakes it
			return
		end
		for _, fn in ipairs(b.callbacks) do
			task.spawn(fn)
		end
	end)

	function b.setText(t: string)
		label.Text = t
	end
	function b.setEnabled(on: boolean)
		b.enabled = on
		refresh()
	end
	function b.onActivated(fn)
		table.insert(b.callbacks, fn)
	end
	return b
end

return Kit
