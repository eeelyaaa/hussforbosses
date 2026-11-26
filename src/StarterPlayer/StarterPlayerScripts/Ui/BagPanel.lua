--!nonstrict
-- Ui/BagPanel: the punching bag sign (brief system 2; ui-kit/phone-bag-panel.png), plain function version (M2-13).
-- Rows: Punch Strength (buy), Punch Speed (buy), Auto Punch (toggle; BUY when the pass is not owned), Perfect Auto Punch (toggle,
-- or BUY; the row exists only for owners of Auto Punch or Perfect, brief "offered ... only to owners of Auto Punch").
--   BagPanel.open()  BagPanel.close()  BagPanel.isOpen()
-- A tile "BAG" appears in the tile row while the player stands on their own bag pad (the Interact prompt on the pad is M2-12's and calls open()).
-- Views only: Bag.BuyStrength / BuySpeed / AutoToggle / PerfectToggle carry no number; costs and levels come from Bag.State
-- (the server's). Perfect row polish and the real price are M2-20 (the BUY button sends Shop.Buy { key } and the server prompts).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local Counters = require(script.Parent.Counters)
local Shop = require(script.Parent.Shop) -- M2-20: the Perfect Auto Punch price
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)
local Config = require(Shared.Config)
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local BagPanel = { AUTO_START = true }
local modal, tile = nil, nil
local state = { strengthLevel = 1, speedLevel = 1, autoOn = false, perfectOn = false, autoOwned = false, perfectOwned = false }
local cash = 0
local STRENGTH_CAP, SPEED_CAP = 30, 10

local function send(family: string, name: string, payload)
	task.spawn(function()
		local ok, r = pcall(Net.get, family, name)
		if ok then
			r:FireServer(payload or {})
		end
	end)
end

local function mult(v: number): string
	return if v < 10 then string.format("%.2f", v) elseif v < 100 then string.format("%.1f", v) else Counters.short(v)
end

local function ringTime(level: number): number
	local r = Config.Punch.RING
	return r[math.clamp(level, 1, #r)]
end

local function toggle(parent: Instance, on: boolean, fn)
	local th = math.max(U.buttonH - 12, Kit.minDesign(U.touchMin))
	local btn = Instance.new("TextButton")
	btn.Name = "Toggle"
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = on and C.cashGreen or C.pipEmpty
	btn.Size = UDim2.fromOffset(92, th)
	btn.Position = UDim2.new(1, -4, 0.5, 0)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.ZIndex = 4
	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(0, U.radiusPx)
	cr.Parent = btn
	local st = Instance.new("UIStroke")
	st.Color = C.ink
	st.Thickness = U.outlinePx
	st.Parent = btn
	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.BackgroundColor3 = C.white
	knob.AnchorPoint = Vector2.new(on and 1 or 0, 0.5)
	knob.Position = UDim2.new(on and 1 or 0, on and -4 or 4, 0.5, 0)
	knob.Size = UDim2.new(0.42, 0, 1, -10)
	knob.ZIndex = 5
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(0, U.radiusPx)
	kc.Parent = knob
	local ks = Instance.new("UIStroke")
	ks.Color = C.ink
	ks.Thickness = U.wellOutlinePx
	ks.Parent = knob
	knob.Parent = btn
	local word = Kit.Text(btn, { name = "Word", text = on and N.ui.bag.on or N.ui.bag.off, size = TY.small, align = on and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right, position = UDim2.fromOffset(on and 10 or -10, 0) })
	word.ZIndex = 5
	btn.Parent = parent
	btn.Activated:Connect(fn)
	return btn
end

local function row(body: Frame, y: number, h: number, iconKey: string, title: string, lines: string)
	local r = Kit.Plate(body, { name = "Row", fill = C.white, size = UDim2.new(1, 0, 0, h), position = UDim2.fromOffset(0, y), studs = false, outline = U.wellOutlinePx })
	r.ZIndex = 3
	local icon = Kit.Icon(r, iconKey, { size = 44, position = UDim2.new(0, 10, 0.5, 0), anchor = Vector2.new(0, 0.5), standIn = C.hussRed })
	icon.ZIndex = 4
	local t = Kit.Text(r, { name = "Title", text = title, size = TY.name, color = C.ink, plain = true, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(66, 4), sizeU = UDim2.new(1, -66 - 150, 0, 22) })
	t.ZIndex = 4
	local d = Kit.Text(r, { name = "Body", text = lines, size = TY.small, color = C.ink, plain = true, body = true, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(66, 26), sizeU = UDim2.new(1, -66 - 150, 1, -28) })
	d.TextWrapped = true
	d.TextYAlignment = Enum.TextYAlignment.Top
	d.ZIndex = 4
	local right = Instance.new("Frame")
	right.Name = "Right"
	right.BackgroundTransparency = 1
	right.AnchorPoint = Vector2.new(1, 0)
	right.Position = UDim2.new(1, -8, 0, 0)
	right.Size = UDim2.new(0, 140, 1, 0)
	right.ZIndex = 4
	right.Parent = r
	return r, right
end

local function buyButton(right: Frame, text: string, fill: Color3, enabled: boolean, fn, ink: boolean?)
	local th = math.max(U.buttonH, Kit.minDesign(U.touchMin))
	local b = Kit.Button(right, { name = "Buy", text = text, fill = fill, ink = ink, textSize = TY.button, size = UDim2.new(1, 0, 0, th), position = UDim2.new(0, 0, 0.5, -th / 2 - 2) })
	b.root.ZIndex = 4
	b.setEnabled(enabled)
	b.onActivated(fn)
	return b
end

local function build(body: Frame)
	local rowH = 66
	local y = 0
	local first
	-- strength
	local sl = state.strengthLevel
	local strengthMax = sl >= STRENGTH_CAP
	local sv = Config.Bag.STRENGTH_VALUE
	local body1 = Hud.fill(N.ui.bag.strengthBody, { v = mult(sv(sl)) }) .. "\n" .. (strengthMax and N.ui.bag.maxed or Hud.fill(N.ui.bag.strengthNext, { v = mult(sv(sl + 1)) }))
	local r, right = row(body, y, rowH, "punchStrength", Hud.fill(N.ui.bag.strength, { n = sl }), body1)
	local cost = state.nextStrengthCost
	local b1 = buyButton(right, strengthMax and N.ui.bag.maxed or (cost and (N.ui.cashPrefix .. Counters.short(cost)) or "..."), C.cashGreen, cost ~= nil and not strengthMax and cash >= cost, function()
		send("Bag", "BuyStrength")
	end)
	first = b1.face
	y += rowH + 6
	-- speed
	local pl = state.speedLevel
	local speedMax = pl >= SPEED_CAP
	local body2 = Hud.fill(N.ui.bag.speedBody, { s = string.format("%.2f", ringTime(pl)) }) .. "\n" .. (speedMax and N.ui.bag.maxed or Hud.fill(N.ui.bag.speedNext, { s = string.format("%.2f", ringTime(pl + 1)) }))
	local _, right2 = row(body, y, rowH, "punchSpeed", Hud.fill(N.ui.bag.speed, { n = pl }), body2)
	local cost2 = state.nextSpeedCost
	buyButton(right2, speedMax and N.ui.bag.maxed or (cost2 and (N.ui.cashPrefix .. Counters.short(cost2)) or "..."), C.cashGreen, cost2 ~= nil and not speedMax and cash >= cost2, function()
		send("Bag", "BuySpeed")
	end)
	y += rowH + 6
	-- auto punch
	local _, right3 = row(body, y, rowH, "bagPanel", N.ui.bag.auto, N.ui.bag.autoBody)
	if state.autoOwned then
		toggle(right3, state.autoOn, function()
			state.autoOn = not state.autoOn -- the server's Bag.State has the last word
			send("Bag", "AutoToggle", { on = state.autoOn })
			modal.refresh()
		end)
	else
		buyButton(right3, N.ui.bag.buy, C.shopGold, true, function()
			send("Shop", "Buy", { key = "pass_auto_punch" })
		end, true)
	end
	y += rowH + 6
	-- perfect auto punch: only for owners of Auto Punch (or of Perfect itself)
	if state.autoOwned or state.perfectOwned then
		local _, right4 = row(body, y, rowH, "bagPanel", N.ui.bag.perfect, N.ui.bag.perfectBody)
		if state.perfectOwned then
			toggle(right4, state.perfectOn, function()
				state.perfectOn = not state.perfectOn
				send("Bag", "PerfectToggle", { on = state.perfectOn })
				modal.refresh()
			end)
		else
			buyButton(right4, Shop.robux("pass_perfect_auto_punch"), C.shopGold, true, function()
				send("Shop", "Buy", { key = "pass_perfect_auto_punch" })
			end, true)
		end
		y += rowH + 6
	end
	return y - 6, first
end

function BagPanel.open()
	if not modal then
		return
	end
	local parts = Counters.parts()
	if parts then
		cash = parts.cash
	end
	modal.open(function(body)
		return (build(body))
	end)
end

function BagPanel.close()
	if modal then
		modal.close()
	end
end

function BagPanel.isOpen()
	return modal ~= nil and modal.isOpen()
end

function BagPanel.onState(p)
	if typeof(p) ~= "table" then
		return
	end
	for _, k in ipairs({ "strengthLevel", "speedLevel", "autoOn", "perfectOn", "autoOwned", "perfectOwned", "nextStrengthCost", "nextSpeedCost" }) do
		state[k] = p[k] -- a missing cost is the cap (nil), as in the contract
	end
	if modal and modal.isOpen() then
		modal.refresh()
	end
end

function BagPanel.onProfile(p)
	if typeof(p) ~= "table" then
		return
	end
	if typeof(p.cash) == "number" then
		cash = p.cash
	end
	if typeof(p.strengthLevel) == "number" and state.nextStrengthCost == nil then
		state.strengthLevel = p.strengthLevel
	end
	if modal and modal.isOpen() then
		modal.refresh()
	end
end

function BagPanel.build()
	modal = Hud.modal("Bag", { title = N.ui.bag.title, width = 640 })
	tile = Hud.tile("bag", N.ui.tiles.bag, 4, function()
		if modal.isOpen() then
			modal.close()
		else
			BagPanel.open()
		end
	end)
	if tile then
		tile.setVisible(false)
	end
end

function BagPanel.start(ctx)
	if not Hud.root() then
		return
	end
	BagPanel.build()
	task.spawn(function()
		for _, e in ipairs({ { "Bag", "State", BagPanel.onState }, { "Profile", "Changed", BagPanel.onProfile } }) do
			local ok, r = pcall(Net.get, e[1], e[2])
			if ok then
				r.OnClientEvent:Connect(e[3])
			end
		end
	end)
	local Ring = ctx and ctx.Ring
	task.spawn(function() -- the tile follows the bag pad (the same test the Huss button uses)
		local shown = nil
		while Hud.root() do
			local on = Ring ~= nil and Ring.onBagPad()
			if on ~= shown and tile then
				shown = on
				tile.setVisible(on)
				if not on and modal.isOpen() then
					modal.close()
				end
			end
			task.wait(0.2)
		end
	end)
end

return BagPanel
