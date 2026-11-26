--!nonstrict
-- Ui/Hud: assembles the HUD (m1-hud-ui-and-stud-button.md; ui-kit/phone-hud-base.png) inside one full-screen ScreenGui, one
-- container, one UIScale. The controllers drive the views through the module fields:
--   Hud.huss (HussButton), Hud.counters (Counters), Hud.fight (FightOverlay), Hud.prompts (Prompts)
--   Hud.start()                      builds into the local player's PlayerGui (called once by the client entry script)
--   Hud.build(playerGui, override?)  same, for a given parent; override = { viewport = Vector2, mouse = boolean } for checks
--   Hud.setViewport(vp, mouse)       re-applies the scale rule for a viewport (device checks)
--   Hud.destroy()
-- M2-13 adds the shared screen pieces (every plain screen is built from them; the kit polish is M3):
--   Hud.layer()                      the full-screen frame screens live in (above the HUD)
--   Hud.modal(name, p)               a studded panel with a blue header and an X, over an ink dim. p = { title, width, dismiss = true, stack, noClose }
--       m.open(build, focus?)        build(body, m) draws the content into body and returns its height (design px); opened lazily so sizes
--                                    follow the live scale. m.refresh() rebuilds (coalesced). m.close(). m.isOpen(). m.onClose(fn).
--   Hud.closeTop()                   closes the top modal (gamepad B, the key that opened it)
--   Hud.tile(name, text, order, fn)  a button in the tile row under the counters (hidden during a fight): returns { button, setVisible, bar }
--   Hud.textBox(parent, p)           a white well with scrolling, wrapped text: returns { well, label }
--   Hud.fill(text, values)           "{n}" placeholders
--   Hud.setShield(state, untilTime)  the shield plate, top right (B12: ready = the plate stays, grey "0:00")
-- Layout (design px, 874 x 402): Power and cash plates top left, to the right of Roblox's own top-bar buttons; the Huss button
-- bottom right beside the jump button (centre 184 px from the right edge and 142 px above the bottom, as the kit draws it).
-- The plates sit below Roblox's real top bar: y = GuiService.TopbarInset.Max.Y + 10 screen px (re-laid out when it changes, M1-25). The jump button's rectangle on screen is 80 px at 22 px from the
-- right and bottom edges (the kit's drawing); clearance is read back in the HUD check.
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Skin = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Skin"))
local U, C, TY, N = Skin.Tokens.ui, Skin.Tokens.colors, Skin.Tokens.type, Skin.Names
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local HussButton = require(script.Parent.HussButton)
local Counters = require(script.Parent.Counters)
local FightOverlay = require(script.Parent.FightOverlay)
local Prompts = require(script.Parent.Prompts)

local Hud = {}
Hud.huss = HussButton
Hud.counters = Counters
Hud.fight = FightOverlay
Hud.prompts = Prompts

local TOP_GAP_PX = 10 -- screen px between the real top bar (GuiService.TopbarInset) and the plates
local SIDE_PAD = 16 -- design px from the left edge (plus the top bar's own left edge, for a notch)
local HUSS_FROM_BOTTOM = 142
local JUMP_PX, JUMP_MARGIN_PX, JUMP_GAP_PX = 80, 22, 12 -- the kit draws the jump button 80 px across, 22 px from the right edge

local gui, handle = nil, nil
local conn, insetConn, sizeConn = nil, nil, nil
local layer, tilesRow, shieldPlate = nil, nil, nil
local tiles = {}
local modalStack = {}
local shieldInfo = nil
local fightConn = nil
local Clock = nil

-- left edge of a phone's notch / rounded corner in screen px (0 when the API or a notch is absent)
local function deviceLeftPx(): number
	local ok, r = pcall(function()
		return GuiService:GetSafeZoneOffsets()
	end)
	if ok and typeof(r) == "Rect" then
		return math.max(0, r.Min.X)
	end
	return 0
end

local function place()
	if not handle then
		return
	end
	local s = Kit.scale()
	-- the plates sit BELOW Roblox's top bar (the bar's rect is GuiService.TopbarInset, screen px; the HUD ignores the GuiInset)
	local inset = GuiService.TopbarInset
	local c = Counters.instance()
	local cx = SIDE_PAD + math.ceil(deviceLeftPx() / s)
	local cy = math.ceil((inset.Max.Y + TOP_GAP_PX) / s)
	if c then
		c.Position = UDim2.fromOffset(cx, cy)
	end
	-- fight overlay: Run directly under the counter plates (kit: top left under the first row), fight plate under the bar
	local cw = c and (c.AbsoluteSize.X / s) or 0
	FightOverlay.place(cx, cy + U.counterH + 4 + 8, math.ceil((inset.Max.Y + 8) / s), cx + cw + 8, handle.root.AbsoluteSize.X / s)
	if tilesRow then
		tilesRow.Position = UDim2.fromOffset(cx, cy + U.counterH + 12)
	end
	if shieldPlate then
		local rootW = handle.root.AbsoluteSize.X / s
		shieldPlate.Position = UDim2.fromOffset(rootW - SIDE_PAD, cy)
	end
	local h = HussButton.instance()
	if h then
		-- centre from the right edge in SCREEN px: the jump button's width, its margin, a gap, and the band's radius, so the
		-- button stays beside the jump button when the button grows on a small phone (at scale 1 this is the kit's 184)
		local radiusPx = (HussButton.diameter() / 2 + U.bandThickPx) * s
		local fromRight = (JUMP_MARGIN_PX + JUMP_PX + JUMP_GAP_PX + radiusPx) / s
		h.Position = UDim2.new(1, -fromRight, 1, -HUSS_FROM_BOTTOM)
	end
end

-- ---------------------------------------------------------------- shared screen pieces (M2-13)

function Hud.fill(text: string, values: { [string]: any }?): string
	local out = string.gsub(text, "{(%w+)}", function(k)
		local v = values and values[k]
		if v == nil then
			return nil
		end
		return tostring(v)
	end)
	return out
end

function Hud.layer()
	return layer
end

local function isGamepadOnly(): boolean
	return UserInputService.GamepadEnabled and not UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function Hud.modal(name: string, p)
	local m = { name = name, params = p, callbacks = {}, builder = nil, opened = false, queued = false }
	local function header(): number
		return math.max(U.header, Kit.minDesign(U.touchMin) + 8)
	end

	local function destroyUi()
		if m.frame then
			m.frame:Destroy()
			m.frame, m.panel, m.body, m.header = nil, nil, nil, nil
		end
		if m.scaleConn then
			m.scaleConn.Disconnect()
			m.scaleConn = nil
		end
	end

	local function layout()
		if not m.frame then
			return
		end
		local hh = header()
		m.header.Size = UDim2.new(1, 0, 0, hh)
		m.xbtn.root.Size = UDim2.fromOffset(hh - 8, hh - 8)
		m.body.Position = UDim2.fromOffset(U.panelPad, hh + U.panelPad)
		m.panel.Size = UDim2.fromOffset(p.width or 600, hh + U.panelPad * 2 + (m.contentH or 100))
	end

	local function build()
		destroyUi()
		local frame = Instance.new("Frame")
		frame.Name = "Modal_" .. name
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 1)
		frame.ZIndex = p.stack and 2 or 1
		frame.Parent = layer
		m.frame = frame
		local dim = Instance.new("TextButton")
		dim.Name = "Dim"
		dim.Text = ""
		dim.AutoButtonColor = false
		dim.Selectable = false
		dim.BorderSizePixel = 0
		dim.BackgroundColor3 = C.ink
		dim.BackgroundTransparency = 1 - U.dimAlpha
		dim.Size = UDim2.fromScale(1, 1)
		dim.Parent = frame
		dim.Activated:Connect(function()
			if p.dismiss ~= false then
				m.close()
			end
		end)
		local panel = Kit.Panel(frame, { name = "Panel", size = UDim2.fromOffset(p.width or 600, 200), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5) })
		panel.ZIndex = 2
		m.panel = panel
		local head = Kit.Plate(panel, { name = "Header", fill = C.plateBlue, size = UDim2.new(1, 0, 0, U.header) })
		head.ZIndex = 3
		m.header = head
		local title = Kit.Text(head, {
			name = "Title",
			text = p.titleText or p.title or "",
			size = TY.title,
			align = Enum.TextXAlignment.Left,
			position = UDim2.fromOffset(14, 0),
			sizeU = UDim2.new(1, -70, 1, 0),
		})
		title.ZIndex = 4
		title.TextTruncate = Enum.TextTruncate.AtEnd
		m.title = title
		local x = Kit.Button(head, { name = "Close", text = N.ui.close, fill = C.white, ink = true, textSize = TY.button, size = UDim2.fromOffset(36, 36), position = UDim2.new(1, -6, 0.5, 0), anchor = Vector2.new(1, 0.5) })
		x.root.ZIndex = 5
		x.onActivated(function()
			m.close()
		end)
		if p.noClose then
			x.root.Visible = false
		end
		m.xbtn = x
		local body = Instance.new("Frame")
		body.Name = "Body"
		body.BackgroundTransparency = 1
		body.Size = UDim2.new(1, -2 * U.panelPad, 1, -(U.header + 2 * U.panelPad))
		body.ZIndex = 3
		body.Parent = panel
		m.body = body
		body.Size = UDim2.new(1, -2 * U.panelPad, 0, 0)
		body.AutomaticSize = Enum.AutomaticSize.None
		m.contentH = m.builder(body, m) or 100
		body.Size = UDim2.new(1, -2 * U.panelPad, 0, m.contentH)
		layout()
		m.scaleConn = Kit.onScale(function()
			if m.opened and m.frame then
				m.refresh()
			end
		end)
	end

	function m.open(builder, focus)
		m.builder = builder
		if p.stack ~= true then
			for _, other in ipairs(table.clone(modalStack)) do
				if other ~= m then
					other.close()
				end
			end
		end
		if not table.find(modalStack, m) then
			table.insert(modalStack, m)
		end
		m.opened = true
		build()
		m.focus = focus
		if focus and isGamepadOnly() then
			GuiService.SelectedObject = focus
		end
	end
	function m.refresh()
		if not m.opened or m.queued then
			return
		end
		m.queued = true
		task.defer(function()
			m.queued = false
			if m.opened and m.builder then
				build()
			end
		end)
	end
	function m.close()
		if not m.opened then
			return
		end
		m.opened = false
		local i = table.find(modalStack, m)
		if i then
			table.remove(modalStack, i)
		end
		destroyUi()
		for _, fn in ipairs(table.clone(m.callbacks)) do
			task.spawn(fn)
		end
	end
	function m.isOpen()
		return m.opened
	end
	function m.onClose(fn)
		table.insert(m.callbacks, fn)
	end
	return m
end

function Hud.closeTop()
	local top = modalStack[#modalStack]
	if top and top.name ~= "Offline" then
		top.close()
		return true
	end
	return false
end

-- A white well with wrapped, scrolling ink text. p: size, position, text, textSize, name
function Hud.textBox(parent: Instance, p)
	local well = Kit.Plate(parent, { name = p.name or "TextBox", fill = C.white, size = p.size, position = p.position, studs = false, outline = U.wellOutlinePx })
	well.ZIndex = 3
	local sf = Instance.new("ScrollingFrame")
	sf.Name = "Scroll"
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.Size = UDim2.new(1, -10, 1, -10)
	sf.Position = UDim2.fromOffset(5, 5)
	sf.ScrollBarThickness = 4
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.CanvasSize = UDim2.new()
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.ZIndex = 3
	sf.Parent = well
	local label = Kit.Text(sf, { name = "Text", text = p.text or "", size = p.textSize or TY.small, color = C.ink, plain = true, body = true, align = Enum.TextXAlignment.Left, sizeU = UDim2.new(1, -8, 0, 0) })
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.ZIndex = 4
	return { well = well, label = label, scroll = sf }
end

-- The tile row under the counters (kit: the Shop and Rebirth tiles). Hidden while a fight plate shows (Run sits there).
function Hud.tile(name: string, text: string, order: number, fn)
	if not tilesRow then
		return nil
	end
	local old = tiles[name]
	if old then
		old.scaleConn.Disconnect()
		old.holder:Destroy()
	end
	local TILE_W = 88
	local holder = Instance.new("Frame")
	holder.Name = "Tile_" .. name
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = order
	holder.Parent = tilesRow
	local b = Kit.Button(holder, { name = "Button", text = text, fill = C.white, ink = true, textSize = TY.small, size = UDim2.fromOffset(TILE_W, 40) })
	b.onActivated(function()
		task.spawn(fn)
	end)
	local barBack = Instance.new("Frame")
	barBack.Name = "BarBack"
	barBack.BackgroundColor3 = C.pipEmpty
	barBack.BorderSizePixel = 0
	barBack.Size = UDim2.new(1, 0, 0, 6)
	barBack.Visible = false
	barBack.Parent = holder
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.BackgroundColor3 = C.plateBlue
	bar.BorderSizePixel = 0
	bar.Size = UDim2.fromScale(0, 1)
	bar.Parent = barBack
	-- The size follows the live scale: the touch floor (44 px on screen) is Kit.minDesign, which is huge while the camera's viewport is
	-- still unsettled at spawn (a tile built then stayed tall: the "two tall white panels", M2-13 follow-up). Capped at 64 design px.
	local function resize()
		if not holder.Parent then
			return
		end
		local h = math.min(64, math.max(U.buttonH - 8, Kit.minDesign(U.touchMin)))
		b.root.Size = UDim2.fromOffset(TILE_W, h)
		barBack.Position = UDim2.new(0, 0, 0, h + 7)
		holder.Size = UDim2.fromOffset(TILE_W, h + 14)
	end
	resize()
	local t = { holder = holder, button = b, barBack = barBack, bar = bar, wanted = true, scaleConn = Kit.onScale(resize) }
	function t.setVisible(v: boolean)
		t.wanted = v
		holder.Visible = v and not Hud.fightShowing()
	end
	function t.setProgress(f: number?)
		barBack.Visible = f ~= nil
		if f then
			bar.Size = UDim2.fromScale(math.clamp(f, 0, 1), 1)
		end
	end
	tiles[name] = t
	return t
end

function Hud.fightShowing(): boolean
	local parts = FightOverlay.parts()
	return parts ~= nil and parts.plate ~= nil and parts.plate.Visible
end

local function refreshTiles()
	local hide = Hud.fightShowing()
	for _, t in pairs(tiles) do
		t.holder.Visible = t.wanted and not hide
	end
end

-- B12 (TEAM CALL M2-13-2): the shield plate is always there. Up: cyan with the time left. Cooldown: grey with the time to ready.
-- Ready (can be raised): grey "0:00". state: "up"|"joining"|"instant"|"cooldown"|"ready"; untilTime = server time it ends.
local function mmss(sec: number): string
	sec = math.max(0, math.ceil(sec))
	return string.format("%d:%02d", sec // 60, sec % 60)
end

local function paintShield()
	if not shieldPlate then
		return
	end
	local st = shieldInfo and shieldInfo.state or "ready"
	local left = 0
	if shieldInfo and shieldInfo.untilTime then
		left = shieldInfo.untilTime - (Clock and Clock.now() or 0)
	end
	local lit = (st == "up" or st == "joining" or st == "instant") and left > 0
	shieldPlate.BackgroundColor3 = lit and C.shieldCyan or C.disabledGrey
	local label = shieldPlate:FindFirstChild("Value") :: TextLabel
	label.Text = if st == "ready" or left <= 0 then N.ui.shield.ready else mmss(left)
end

function Hud.setShield(state: string?, untilTime: number?)
	shieldInfo = { state = state or "ready", untilTime = untilTime }
	paintShield()
end

local function wireRemotes()
	task.spawn(function()
		local ok, baseState = pcall(Net.get, "Base", "State")
		local ok2, shieldState = pcall(Net.get, "Shield", "State")
		if not (ok and ok2) then
			return
		end
		local mine, myPlot = Players.LocalPlayer.UserId, nil
		baseState.OnClientEvent:Connect(function(p)
			if typeof(p) == "table" and p.ownerUserId == mine then
				myPlot = p.plotId
			end
		end)
		shieldState.OnClientEvent:Connect(function(p)
			if typeof(p) == "table" and p.plotId == myPlot then
				local st = p.state
				Hud.setShield(st, if st == "cooldown" or st == "ready" then p.readyAt else p.endsAt)
			end
		end)
	end)
end


function Hud.build(playerGui: Instance, override)
	Hud.destroy()
	gui = Instance.new("ScreenGui")
	gui.Name = "HussHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 1
	gui.Parent = playerGui
	handle = Kit.Scale(gui, override)
	local root = handle.root
	Counters.build(root)
	FightOverlay.build(root)
	HussButton.build(root)
	Prompts.build(root)
	modalStack, tiles = {}, {}
	Clock = Clock or (function()
		local ok, m = pcall(function()
			return require(script.Parent.Parent.Controllers.Clock)
		end)
		return ok and m or nil
	end)()
	-- the tile row, the shield plate and the screen layer (above everything the HUD draws)
	tilesRow = Instance.new("Frame")
	tilesRow.Name = "Tiles"
	tilesRow.BackgroundTransparency = 1
	tilesRow.AutomaticSize = Enum.AutomaticSize.XY
	tilesRow.Size = UDim2.new()
	local tl = Instance.new("UIListLayout")
	tl.FillDirection = Enum.FillDirection.Horizontal
	tl.SortOrder = Enum.SortOrder.LayoutOrder
	tl.Padding = UDim.new(0, 8)
	tl.Parent = tilesRow
	tilesRow.Parent = root
	shieldPlate = Kit.Plate(root, { name = "ShieldPlate", fill = C.disabledGrey, size = UDim2.fromOffset(118, U.counterH), anchor = Vector2.new(1, 0) })
	local sv = Kit.Text(shieldPlate, { name = "Value", text = N.ui.shield.ready, size = TY.button, align = Enum.TextXAlignment.Center, position = UDim2.fromOffset(18, 0), sizeU = UDim2.new(1, -18, 1, 0) })
	sv.ZIndex = 3
	local si = Kit.Icon(shieldPlate, "lockShield", { name = "Icon", size = U.counterIconPx, position = UDim2.fromOffset(-U.counterIconOverlapPx, (U.counterH - U.counterIconPx) / 2), standIn = C.white })
	si.ZIndex = 4
	layer = Instance.new("Frame")
	layer.Name = "Screens"
	layer.BackgroundTransparency = 1
	layer.Size = UDim2.fromScale(1, 1)
	layer.ZIndex = 50
	layer.Parent = root
	paintShield()
	local fo = FightOverlay.parts()
	if fo and fo.plate then
		fightConn = fo.plate:GetPropertyChangedSignal("Visible"):Connect(refreshTiles)
	end
	conn = Kit.onScale(place)
	local ci = Counters.instance()
	if ci then
		sizeConn = ci:GetPropertyChangedSignal("AbsoluteSize"):Connect(place) -- counters grow with the numbers
	end
	insetConn = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
	place()
	return gui
end

function Hud.start()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local g = Hud.build(pg)
	wireRemotes()
	task.spawn(function() -- the shield plate counts down on the server clock
		while true do
			task.wait(0.25)
			if gui == nil then
				break
			end
			paintShield()
		end
	end)
	UserInputService.InputBegan:Connect(function(io)
		if io.KeyCode == Enum.KeyCode.ButtonB then
			Hud.closeTop()
		end
	end)
	return g
end

function Hud.setViewport(viewport: Vector2?, mouse: boolean?)
	if handle then
		handle.set(viewport, mouse)
	end
end

function Hud.destroy()
	if fightConn then
		fightConn:Disconnect()
		fightConn = nil
	end
	modalStack, tiles, layer, tilesRow, shieldPlate = {}, {}, nil, nil, nil
	if conn then
		conn.Disconnect()
		conn = nil
	end
	if sizeConn then
		sizeConn:Disconnect()
		sizeConn = nil
	end
	if insetConn then
		insetConn:Disconnect()
		insetConn = nil
	end
	HussButton.destroy()
	Counters.destroy()
	FightOverlay.destroy()
	Prompts.destroy()
	if handle then
		handle.destroy()
		handle = nil
	end
	if gui then
		gui:Destroy()
		gui = nil
	end
	Kit.reset()
end

function Hud.gui()
	return gui
end

function Hud.root()
	return handle and handle.root
end

return Hud
