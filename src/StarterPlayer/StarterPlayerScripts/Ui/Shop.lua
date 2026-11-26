--!nonstrict
-- Ui/Shop: the shop SCREEN (brief system 13 and screen 5; ui-kit/05-shop-full-list.png, phone-shop.png), plain function version (M2-20).
-- A view over Controllers/Shop (M2-19): the controller owns the Shop tile, B / D-pad, Shop.Open, quotes, passes, policy, tickets, the prompt
-- guard and every send; this module draws what it reads and calls its Shop.buy. The controller calls open() / close() / isOpen() here.
-- Cards: 10 passes (Perfect Auto Punch only for owners of Auto Punch), 4 cash packs with the exact amount on the button, the bought-cash
-- well, Instant Shield (greyed "SHIELD IS UP" while a shield is up), Shield Breaker (explained, bought at a shield), and the Lucky Boss Spin
-- card ("SEE THE ODDS", opens the Spin screen; gone for a player restricted from paid random items). The three spin products are bought on
-- the Spin screen, so with them the shop reaches all 19 products. Text, prices and descriptions come from the skin (Names.ui.shop,
-- Names.ui.prices); Config.Shop.PRICES wins over the skin's fallback prices once it exists.
--   Shop.open()  Shop.close()  Shop.isOpen()  Shop.price(key)  Shop.robux(key)  Shop.owned(key)  Shop.refresh()
-- Own listeners (start): Profile.Changed boughtCash (the well), Base.State + Shield.State (Instant Shield greyed while a shield is up), the
-- controller's onChange (redraw) and onGrant (a refused purchase gives one toast from Names.ui.reasons). No tile, no key, no remote sent here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local Counters = require(script.Parent.Counters)
local Toasts = require(script.Parent.Toasts)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)
local Ids = require(Shared.Ids)
local Config = require(Shared.Config)
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local function ctl()
	return require(script.Parent.Parent.Controllers.Shop)
end
local function spinCtl()
	return require(script.Parent.Parent.Controllers.Spin)
end

local Shop = { AUTO_START = true }
local modal, tile = nil, nil
local listeners = {}
local myPlot = nil
local scrollY = 0

-- what only this view reads (the controller keeps everything else)
local own = { boughtCash = 0, shieldUp = false }
Shop.own = own


local CARDS_PASSES = { "pass_auto_punch", "pass_perfect_auto_punch", "pass_2x_power", "pass_2x_cash", "pass_fast_carry", "pass_extra_spots", "pass_starter_pack", "pass_long_lock", "pass_quick_hands", "pass_iron_grip" }
local CARDS_PACKS = { "product_cash_small", "product_cash_medium", "product_cash_large", "product_cash_huge" }
local CARDS_SHIELDS = { "product_instant_shield", "product_shield_breaker", "spin_card" }

-- structure only: which token colours a card, which icon key it uses (names and pictures are the skin's)
local FILL = {
	pass_long_lock = "shieldCyan", product_instant_shield = "shieldCyan",
	pass_quick_hands = "alarmOrange", pass_iron_grip = "alarmOrange", product_shield_breaker = "alarmOrange",
	product_cash_small = "cashGreen", product_cash_medium = "cashGreen", product_cash_large = "cashGreen", product_cash_huge = "cashGreen",
	spin_card = "shopGold",
}
local ICON = {
	pass_auto_punch = "autoPunch", pass_perfect_auto_punch = "perfectAutoPunch", pass_2x_power = "power2x", pass_2x_cash = "cash2x",
	pass_fast_carry = "fastCarry", pass_long_lock = "longLock", pass_extra_spots = "extraSpots", pass_quick_hands = "quickHands",
	pass_iron_grip = "ironGrip", pass_starter_pack = "starterPack", product_cash_small = "cashPackSmall", product_cash_medium = "cashPackMedium",
	product_cash_large = "cashPackLarge", product_cash_huge = "cashPackHuge", product_instant_shield = "instantShield",
	product_shield_breaker = "shieldBreaker", spin_card = "luckySpin",
}

function Shop.refresh()
	if modal and modal.isOpen() then
		modal.refresh()
	end
end

function Shop.price(key: string): number?
	local p = Config.Shop and Config.Shop.PRICES
	local v = p and p[key]
	if type(v) ~= "number" then
		v = N.ui.prices[key]
	end
	return v
end

function Shop.robux(key: string): string
	return Hud.fill(N.ui.shop.robux, { n = Shop.price(key) or "?" })
end

function Shop.owned(key: string): boolean
	local c = ctl()
	if key == "pass_starter_pack" and c.starterPackGiven() then
		return true
	end
	return c.owns(key)
end

function Shop.restricted(): boolean
	return ctl().restricted()
end

function Shop.buy(key: string)
	return ctl().buy(key)
end

-- ---------------------------------------------------------------- the screen

local function isPass(key: string): boolean
	return string.sub(key, 1, 5) == "pass_"
end

local function thH(): number
	return math.max(U.buttonH, Kit.minDesign(U.touchMin))
end

local function designSize(): (number, number)
	local root = Hud.root()
	if root then
		return root.Size.X.Offset, root.Size.Y.Offset
	end
	return U.designW, U.designH
end

local function headerH(): number
	return math.max(U.header, Kit.minDesign(U.touchMin) + 8)
end

local DESC_H = 66

local function cardH(): number
	return 8 + 48 + 4 + DESC_H + 6 + thH() + 10
end

-- A card: icon, name, description well, one button. Returns the card and its button.
local function card(parent: Instance, key: string, x: number, y: number, w: number, h: number)
	local fillName = FILL[key]
	local f = Kit.Plate(parent, { name = "Card_" .. key, fill = fillName and C[fillName] or C.panelGrey, size = UDim2.fromOffset(w, h), position = UDim2.fromOffset(x, y), studs = false })
	f.ZIndex = 3
	local icon = Kit.Icon(f, ICON[key], { size = 44, position = UDim2.fromOffset(8, 6), standIn = C.white })
	icon.ZIndex = 4
	local title = if key == "spin_card" then N.ui.spin.title else N.products[key]
	local t = Kit.Text(f, { name = "Title", text = string.upper(title), size = TY.name, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(60, 6), sizeU = UDim2.new(1, -68, 0, 44) })
	t.TextWrapped = true
	t.ZIndex = 4
	local well = Kit.Plate(f, { name = "DescWell", fill = C.white, size = UDim2.new(1, -16, 0, DESC_H), position = UDim2.fromOffset(8, 60), studs = false, outline = U.wellOutlinePx })
	well.ZIndex = 4
	local text = N.ui.shop.desc[key]
	if key == "product_shield_breaker" and ctl().breakerCharges() > 0 then
		text ..= Hud.fill(N.ui.shop.charges, { n = ctl().breakerCharges() })
	end
	local d = Kit.Text(well, { name = "Desc", text = text, size = TY.small, color = C.ink, plain = true, body = true, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(6, 4), sizeU = UDim2.new(1, -12, 1, -8) })
	d.TextWrapped = true
	d.TextYAlignment = Enum.TextYAlignment.Top
	d.ZIndex = 5
	local th = thH()
	local b = Kit.Button(f, { name = "Buy", text = "", fill = if key == "spin_card" then C.white else C.shopGold, ink = true, textSize = TY.button, size = UDim2.new(1, -16, 0, th), position = UDim2.fromOffset(8, 60 + DESC_H + 6) })
	b.root.ZIndex = 4
	return f, b
end

local function cardButton(key: string, b)
	local N2 = N.ui.shop
	local function disabled(text: string)
		b.setText(text)
		b.setEnabled(false)
	end
	if key == "spin_card" then
		b.setText(N2.seeOdds)
		b.onActivated(function()
			spinCtl().open()
		end)
		return
	end
	if key == "product_shield_breaker" then
		return disabled(N2.buyAtShield) -- bought at the shield (Shield.BuyBreaker), never here
	end
	if isPass(key) then
		if Shop.owned(key) then
			return disabled(N2.owned)
		end
	elseif key == "product_instant_shield" and own.shieldUp then
		return disabled(N2.shieldUp)
	end
	if table.find(CARDS_PACKS, key) then
		local q = ctl().quoteFor(key)
		if not q then
			return disabled(N2.waiting) -- the exact amount is not here yet: no button to press
		end
		b.setText(Hud.fill(N2.pack, { amount = N.ui.cashPrefix .. Counters.short(q.amount), n = Shop.price(key) or "?" }))
	else
		b.setText(Shop.robux(key))
	end
	b.setEnabled(true)
	b.onActivated(function()
		Shop.buy(key)
	end)
end

local function boughtCashWell(parent: Instance, x: number, y: number, w: number, h: number)
	local f = Kit.Plate(parent, { name = "BoughtCash", fill = C.white, size = UDim2.fromOffset(w, h), position = UDim2.fromOffset(x, y), studs = false })
	f.ZIndex = 3
	local icon = Kit.Icon(f, "cash", { size = 44, position = UDim2.fromOffset(10, 8), standIn = C.cashGreen })
	icon.ZIndex = 4
	local t = Kit.Text(f, { name = "Title", text = N.ui.shop.boughtCash, size = TY.name, color = C.ink, plain = true, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(64, 6), sizeU = UDim2.new(1, -72, 0, 22) })
	t.ZIndex = 4
	local v = Kit.Text(f, { name = "Value", text = N.ui.cashPrefix .. Kit.commas(own.boughtCash), size = TY.title, color = C.ink, plain = true, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(64, 28), sizeU = UDim2.new(1, -72, 0, 28) })
	v.ZIndex = 4
	local d = Kit.Text(f, { name = "Body", text = N.ui.shop.boughtCashBody, size = TY.small, color = C.ink, plain = true, body = true, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(10, 62), sizeU = UDim2.new(1, -20, 1, -70) })
	d.TextWrapped = true
	d.TextYAlignment = Enum.TextYAlignment.Top
	d.ZIndex = 4
	return f
end

-- Lay the sections out in a ScrollingFrame; returns the total height and the first button's face.
local function layout(scroll: ScrollingFrame, W: number)
	local gap = 8
	local cols = 3
	local cw = (W - gap * (cols - 1)) / cols
	local ch = cardH()
	local y = 0
	local first = nil
	local function header(text: string)
		local h = Kit.Text(scroll, { name = "Header", text = text, size = TY.name, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(2, y), sizeU = UDim2.new(1, -4, 0, 28) })
		h.ZIndex = 3
		h.TextTruncate = Enum.TextTruncate.AtEnd
		y += 32
	end
	local function grid(items)
		local col = 0
		for _, it in ipairs(items) do
			local span = it.span or 1
			if col + span > cols then
				col = 0
				y += ch + gap
			end
			local x = col * (cw + gap)
			local w = cw * span + gap * (span - 1)
			if it.well then
				boughtCashWell(scroll, x, y, w, ch)
			else
				local _, b = card(scroll, it.key, x, y, w, ch)
				cardButton(it.key, b)
				first = first or b.face
			end
			col += span
		end
		y += ch + gap
	end
	-- passes: Perfect Auto Punch only for an owner of Auto Punch (or of Perfect itself)
	local passes = {}
	for _, k in ipairs(CARDS_PASSES) do
		if k ~= "pass_perfect_auto_punch" or Shop.owned("pass_auto_punch") or Shop.owned("pass_perfect_auto_punch") then
			table.insert(passes, { key = k })
		end
	end
	header(N.ui.shop.passes)
	grid(passes)
	header(N.ui.shop.packs)
	local packs = {}
	for _, k in ipairs(CARDS_PACKS) do
		table.insert(packs, { key = k })
	end
	table.insert(packs, { well = true, span = 2 })
	grid(packs)
	header(if ctl().restricted() then N.ui.shop.shieldsOnly else N.ui.shop.shields)
	local sh = {}
	for _, k in ipairs(CARDS_SHIELDS) do
		if k ~= "spin_card" or not ctl().restricted() then
			table.insert(sh, { key = k })
		end
	end
	grid(sh)
	return y - gap, first
end

local function build(body: Frame, m)
	local w = m.params.width
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ZIndex = 3
	scroll.Parent = body
	local total, first = layout(scroll, w - 2 * U.panelPad - 12)
	local _, dh = designSize()
	local avail = dh - headerH() - 2 * U.panelPad - 24
	local viewH = math.max(math.min(total, avail), 80)
	scroll.Size = UDim2.new(1, 0, 0, viewH)
	scroll.CanvasSize = UDim2.fromOffset(0, total)
	scroll.CanvasPosition = Vector2.new(0, math.min(scrollY, math.max(total - viewH, 0)))
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		scrollY = scroll.CanvasPosition.Y
	end)
	return viewH, first
end

function Shop.open()
	if not modal then
		return
	end
	local dw = designSize()
	modal.params.width = math.min(780, dw - 24)
	scrollY = 0
	modal.open(function(body, m)
		return build(body, m)
	end)
end

function Shop.close()
	if modal then
		modal.close()
	end
end

function Shop.isOpen(): boolean
	return modal ~= nil and modal.isOpen()
end

-- ---------------------------------------------------------------- handlers

function Shop.onProfile(p)
	if typeof(p) == "table" and typeof(p.boughtCash) == "number" and own.boughtCash ~= p.boughtCash then
		own.boughtCash = p.boughtCash
		Shop.refresh()
	end
end

function Shop.setPlot(plotId: number?) -- the check's seam (no LocalPlayer in edit mode)
	myPlot = plotId
end

function Shop.onBaseState(p)
	local lp = Players.LocalPlayer
	if typeof(p) == "table" and lp and p.ownerUserId == lp.UserId then
		myPlot = p.plotId
	end
end

function Shop.onShieldState(p)
	if typeof(p) == "table" and p.plotId == myPlot then
		local up = p.state == "up" or p.state == "instant" or p.state == "joining"
		if own.shieldUp ~= up then
			own.shieldUp = up
			Shop.refresh()
		end
	end
end

-- a refused purchase: one toast with the skin's words (cancelled, stale and busy are silent: the quote and prompt notices say them)
local SILENT = { cancelled = true, stale = true, busy = true }
function Shop.onGrant(p)
	if typeof(p) == "table" and p.ok == false and not SILENT[p.reason] then
		Toasts.reason(p.reason)
	end
end

function Shop.build()
	modal = Hud.modal("Shop", { title = N.ui.shop.title, width = 780 })
	modal.onClose(function()
		ctl().close() -- the X, the dim or another screen closed it: the controller keeps its open flag true to the screen
	end)
end

function Shop.start()
	if not Hud.root() then
		return
	end
	Shop.build()
	local c = ctl()
	c.onChange(Shop.refresh)
	c.onGrant(Shop.onGrant)
	for _, e in ipairs({ { "Base", "State", Shop.onBaseState }, { "Shield", "State", Shop.onShieldState }, { "Profile", "Changed", Shop.onProfile } }) do
		task.spawn(function()
			local ok, r = pcall(Net.get, e[1], e[2])
			if ok then
				r.OnClientEvent:Connect(e[3])
			end
		end)
	end
end

return Shop
