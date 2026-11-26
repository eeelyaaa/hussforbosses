--!nonstrict
-- Ui/Spin: the Lucky Boss Spin SCREEN (brief system 13 and screen 6; ui-kit/phone-lucky-spin.png, phone-lucky-spin-result.png), plain version (M2-20).
-- A view over Controllers/Spin and Controllers/Shop (M2-19), which own the zones beaten, tickets, policy, the spin send and the result. The Spin
-- controller calls open() / close() / isOpen() / oddsVisible() here. Reached through the shop's Lucky Spin card (no HUD button).
-- Top to bottom: the zone picker (zones beaten are pressable, the rest greyed; with none beaten zone 1 shows greyed and the line reads
-- "Beat a boss first"), the six outcomes of the picked zone with name, tier and odds, the one-line note, then tickets, SPIN and the three ticket
-- products. THE ODDS COME FIRST: the six columns are built from Shared/SpinTable.ODDS (the table the server rolls from) before any Buy or Spin
-- button exists, every one of those buttons stays greyed unless all six were listed and total 100, and oddsVisible() is what the controller
-- asks before it sends a spin. Sends only through the controllers: Spin.spin(), Spin.selectZone(z), Shop.buy(key).
--   Spin.open()  Spin.close()  Spin.isOpen()  Spin.oddsVisible()  Spin.oddsListed()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local Shop = require(script.Parent.Shop) -- the Ui/Shop view: prices
local function ctl()
	return require(script.Parent.Parent.Controllers.Spin)
end
local function shopCtl()
	return require(script.Parent.Parent.Controllers.Shop)
end
local Toasts = require(script.Parent.Toasts)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Ids = require(Shared.Ids)
local SpinTable = require(Shared.SpinTable)
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local Spin = { AUTO_START = true }
local modal = nil
local shownResult = nil -- the last ok result, until the zone changes or the screen is opened again
local listedOk = false
local PRODUCTS = { { key = "product_spin_1", k = 1 }, { key = "product_spin_3", k = 3 }, { key = "product_spin_10", k = 10 } }

local function selected(): number
	return ctl().selectedZone() or 1
end

local function beaten(z: number): boolean
	return table.find(ctl().zones(), z) ~= nil
end

function Spin.oddsListed(): boolean
	return listedOk
end

function Spin.oddsVisible(): boolean
	return listedOk and Spin.isOpen()
end

local function thH(): number
	return math.max(U.buttonH, Kit.minDesign(U.touchMin))
end

local function build(body: Frame, m)
	local W = m.params.width - 2 * U.panelPad
	local gap = 8
	local th = thH()
	local root = Hud.root()
	local dh = root and root.Size.Y.Offset or U.designH
	local hh = math.max(U.header, Kit.minDesign(U.touchMin) + 8)
	-- the outcome columns take what the screen has left (110 to 150)
	local fixed = th + gap + gap + 34 + gap + th + 6
	local colH = math.clamp(dh - hh - 2 * U.panelPad - 24 - fixed, 110, 150)
	local y = 0
	local first = nil

	-- 1. the zone picker
	local tw = (W - gap * 5) / 6
	for z = 1, 6 do
		local isSel = z == selected()
		local open = beaten(z)
		local b = Kit.Button(body, {
			name = "Zone" .. z,
			text = Hud.fill(N.ui.spin.zone, { n = z }),
			fill = if isSel then C.plateBlue else C.white,
			ink = not isSel,
			textSize = TY.small,
			size = UDim2.fromOffset(tw, th),
			position = UDim2.fromOffset((z - 1) * (tw + gap), 0),
		})
		b.root.ZIndex = 4
		b.setEnabled(open)
		b.onActivated(function()
			shownResult = nil
			ctl().selectZone(z)
		end)
		if open and not first then
			first = b.face
		end
		if not open then
			b.label.Text = Hud.fill(N.ui.spin.zone, { n = z })
		end
	end
	y += th + gap

	-- 2. THE ODDS: six columns from the one table, built before any Buy or Spin button
	local cw = (W - gap * 5) / 6
	local listed = 0
	local total = 0
	for i, o in ipairs(SpinTable.ODDS) do
		local id = Ids.creature(selected(), o.tier)
		local col = Kit.Plate(body, { name = "Outcome" .. o.tier, fill = C.tier[o.tier], size = UDim2.fromOffset(cw, colH), position = UDim2.fromOffset((i - 1) * (cw + gap), y), studs = false })
		col.ZIndex = 3
		if shownResult and shownResult.tier == o.tier and shownResult.zone == selected() then
			col.Outline.Color = C.flashYellow
			col.Outline.Thickness = U.outlinePx + 3
		end
		local nm = Kit.Text(col, { name = "Name", text = string.upper(N.creatures[id] or id), size = TY.small, position = UDim2.fromOffset(4, 6), sizeU = UDim2.new(1, -8, 0, 40) })
		nm.TextWrapped = true
		nm.ZIndex = 4
		local chip = Kit.Plate(col, { name = "TierChip", fill = C.ink, size = UDim2.new(1, -12, 0, U.tierChipH or 24), position = UDim2.new(0, 6, 0, 52), studs = false, outline = U.wellOutlinePx })
		chip.ZIndex = 4
		local ct = Kit.Text(chip, { name = "Tier", text = string.upper(N.tiers[o.tier]), size = TY.small })
		ct.ZIndex = 5
		local pct = Kit.Text(col, { name = "Percent", text = Hud.fill(N.ui.spin.odds, { p = o.percent }), size = TY.title, position = UDim2.new(0, 4, 0, 52 + (U.tierChipH or 24) + 8), sizeU = UDim2.new(1, -8, 0, 30) })
		pct.ZIndex = 4
		listed += 1
		total += o.percent
	end
	listedOk = listed == #SpinTable.ODDS and listed == 6 and total == 100
	y += colH + gap

	-- 3. the note (or what blocks the spin, or the win)
	local line
	if shownResult and shownResult.creatureId then
		line = Hud.fill(N.ui.spin.won, { boss = N.creatures[shownResult.creatureId] or shownResult.creatureId })
	elseif ctl().waiting() then
		line = N.ui.spin.again
	elseif #ctl().zones() == 0 then
		line = N.ui.spin.beatFirst
	else
		line = N.ui.spin.note
	end
	local well = Kit.Plate(body, { name = "Note", fill = C.white, size = UDim2.new(1, 0, 0, 34), position = UDim2.fromOffset(0, y), studs = false, outline = U.wellOutlinePx })
	well.ZIndex = 3
	local nt = Kit.Text(well, { name = "Text", text = line, size = TY.small, color = C.ink, plain = true, body = true, position = UDim2.fromOffset(6, 0), sizeU = UDim2.new(1, -12, 1, 0) })
	nt.TextWrapped = true
	nt.ZIndex = 4
	y += 34 + gap

	-- 4. tickets, SPIN, the three ticket products: all greyed unless the odds above were listed
	local sc = ctl()
	local canTrade = listedOk and sc.available()
	local tk = Kit.Plate(body, { name = "Tickets", fill = C.shopGold, size = UDim2.fromOffset(140, th), position = UDim2.fromOffset(0, y), studs = false })
	tk.ZIndex = 3
	local tt = Kit.Text(tk, { name = "Text", text = Hud.fill(N.ui.spin.tickets, { n = sc.tickets() }), size = TY.name, color = C.ink, plain = true, sizeU = UDim2.new(1, -8, 1, 0), position = UDim2.fromOffset(4, 0) })
	tt.ZIndex = 4
	local sw = 150
	local sb = Kit.Button(body, { name = "Spin", text = N.ui.spin.spin, fill = C.shopGold, ink = true, textSize = TY.button, size = UDim2.fromOffset(sw, th), position = UDim2.fromOffset(140 + gap, y) })
	sb.root.ZIndex = 4
	sb.setEnabled(canTrade and beaten(selected()) and sc.tickets() >= 1 and not sc.waiting())
	sb.onActivated(function()
		shownResult = nil
		sc.spin() -- the controller asks oddsVisible(), the policy, the zone, a ticket; the server rolls
	end)
	first = first or sb.face
	local bx = 140 + gap + sw + gap
	local bw = (W - bx - gap * 2) / 3
	for i, p in ipairs(PRODUCTS) do
		local b = Kit.Button(body, {
			name = "Buy" .. p.k,
			text = Hud.fill(N.ui.spin.buy, { k = p.k, n = Shop.price(p.key) or "?" }),
			fill = C.shopGold,
			ink = true,
			textSize = TY.name,
			size = UDim2.fromOffset(bw, th),
			position = UDim2.fromOffset(bx + (i - 1) * (bw + gap), y),
		})
		b.root.ZIndex = 4
		b.setEnabled(canTrade)
		b.onActivated(function()
			shopCtl().buy(p.key)
		end)
	end
	y += th + 6
	return y, first
end

function Spin.open()
	if not modal or not ctl().available() then
		return
	end
	shownResult = nil
	local root = Hud.root()
	local dw = root and root.Size.X.Offset or U.designW
	modal.params.width = math.min(780, dw - 24)
	modal.open(function(body, m)
		return build(body, m)
	end)
end

function Spin.close()
	if modal then
		modal.close()
	end
end

function Spin.isOpen(): boolean
	return modal ~= nil and modal.isOpen()
end

local function refresh()
	if modal and modal.isOpen() then
		if ctl().available() then
			modal.refresh()
		else
			modal.close()
		end
	end
end

Spin.refresh = refresh

-- a result from the controller: the won boss is marked and named; a refusal gives one toast with the skin's words
function Spin.onResult(r)
	if typeof(r) ~= "table" then
		return
	end
	if r.ok == true and r.creatureId then
		shownResult = r
	else
		shownResult = nil
		Toasts.reason(r.reason) -- reasons.zone, tickets, restricted are in the skin
	end
	refresh()
end

function Spin.build() -- the modal (start adds the controller's listeners once)
	modal = Hud.modal("Spin", { title = N.ui.spin.title, width = 780 })
	modal.onClose(function()
		ctl().close()
	end)
end

function Spin.start()
	if not Hud.root() then
		return
	end
	Spin.build()
	local c = ctl()
	c.onChange(refresh)
	c.onResult(Spin.onResult)
end

return Spin

