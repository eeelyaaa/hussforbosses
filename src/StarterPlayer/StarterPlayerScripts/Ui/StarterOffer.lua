--!nonstrict
-- Ui/StarterOffer: the Starter Pack offer SCREEN (brief system 13 and screen 9; ui-kit/phone-starter-pack.png), plain version (M2-20).
-- Controllers/Shop (M2-19) owns when: on Shop.Offer it calls show() until it returns true (boss panel closed, nothing blocking), then sends
-- Shop.OfferSeen once; on an owned pack it calls hide(). show() returns false (and the controller retries) while any other screen is open, and
-- true once drawn. Once a session: after it was drawn, show() returns false. BUY sends nothing itself: Shop.buy through the controller.
-- Contents: the cash and the Headbutt Ram with its income, the price on the BUY button, a close button. No countdown, no "% off", no struck-out
-- price, no urgent wording (brief, "No countdown, no '% off', no struck-out price").
--   StarterOffer.show(_) -> drawn   StarterOffer.hide()   StarterOffer.close()   StarterOffer.isOpen()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local Shop = require(script.Parent.Shop)
local Counters = require(script.Parent.Counters)
local function shopCtl()
	return require(script.Parent.Parent.Controllers.Shop)
end
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Config = require(Shared.Config)
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local KEY = "pass_starter_pack"
local StarterOffer = { AUTO_START = true }
local modal = nil
local shownThisSession = false

local function build(body: Frame)
	local W = modal.params.width - 2 * U.panelPad
	local gap = 8
	local th = math.max(U.buttonH, Kit.minDesign(U.touchMin))
	local colH = 130
	local half = (W - gap) / 2
	local cash = Kit.Plate(body, { name = "CashWell", fill = C.cashGreen, size = UDim2.fromOffset(half, colH), studs = false })
	cash.ZIndex = 3
	local ci = Kit.Icon(cash, "cash", { size = 44, position = UDim2.new(0.5, 0, 0, 8), anchor = Vector2.new(0.5, 0), standIn = C.white })
	ci.ZIndex = 4
	local cv = Kit.Text(cash, { name = "Amount", text = N.ui.cashPrefix .. Kit.commas(Config.Shop.STARTER_CASH), size = TY.title, position = UDim2.fromOffset(4, 58), sizeU = UDim2.new(1, -8, 0, 30) })
	cv.ZIndex = 4
	local cl = Kit.Text(cash, { name = "Label", text = N.ui.starter.cash, size = TY.name, position = UDim2.fromOffset(4, 92), sizeU = UDim2.new(1, -8, 0, 24) })
	cl.ZIndex = 4

	local id = Config.Shop.STARTER_CREATURE
	local _, tier = string.match(id, "z(%d+)_t(%d+)")
	tier = tonumber(tier) or 4
	local ram = Kit.Plate(body, { name = "BossWell", fill = C.tier[tier], size = UDim2.fromOffset(half, colH), position = UDim2.fromOffset(half + gap, 0), studs = false })
	ram.ZIndex = 3
	local nm = Kit.Text(ram, { name = "Name", text = string.upper(N.creatures[id] or id), size = TY.button, position = UDim2.fromOffset(4, 10), sizeU = UDim2.new(1, -8, 0, 28) })
	nm.ZIndex = 4
	local chip = Kit.Plate(ram, { name = "TierChip", fill = C.ink, size = UDim2.fromOffset(110, U.tierChipH), position = UDim2.new(0.5, -55, 0, 46), studs = false, outline = U.wellOutlinePx })
	chip.ZIndex = 4
	local ct = Kit.Text(chip, { name = "Tier", text = string.upper(N.tiers[tier]), size = TY.small })
	ct.ZIndex = 5
	local income = Config.Zones.INCOME[id] or 0
	local ev = Kit.Text(ram, { name = "Income", text = Hud.fill(N.ui.starter.earns, { n = N.ui.cashPrefix .. Counters.short(income) }), size = TY.title, position = UDim2.fromOffset(4, 46 + U.tierChipH + 12), sizeU = UDim2.new(1, -8, 0, 30) })
	ev.ZIndex = 4
	local y = colH + gap

	local note = Kit.Plate(body, { name = "Note", fill = C.white, size = UDim2.new(1, 0, 0, 34), position = UDim2.fromOffset(0, y), studs = false, outline = U.wellOutlinePx })
	note.ZIndex = 3
	local nt = Kit.Text(note, { name = "Text", text = N.ui.starter.note, size = TY.small, color = C.ink, plain = true, body = true, position = UDim2.fromOffset(6, 0), sizeU = UDim2.new(1, -12, 1, 0) })
	nt.TextWrapped = true
	nt.ZIndex = 4
	y += 34 + gap

	local buy = Kit.Button(body, { name = "Buy", text = Hud.fill(N.ui.starter.buy, { n = Shop.price(KEY) or "?" }), fill = C.shopGold, ink = true, textSize = TY.button, size = UDim2.new(1, 0, 0, th), position = UDim2.fromOffset(0, y) })
	buy.root.ZIndex = 4
	buy.onActivated(function()
		shopCtl().buy(KEY)
	end)
	return y + th + 6, buy.face
end

local function screensClear(): boolean
	local layer = Hud.layer()
	if not layer or Hud.fightShowing() then
		return false
	end
	for _, c in ipairs(layer:GetChildren()) do
		if string.sub(c.Name, 1, 6) == "Modal_" then
			return false
		end
	end
	return true
end

function StarterOffer.show(_): boolean
	if not modal or shownThisSession or Shop.owned(KEY) then
		return false
	end
	if not screensClear() then
		return false
	end
	shownThisSession = true
	local root = Hud.root()
	modal.params.width = math.min(640, (root and root.Size.X.Offset or U.designW) - 24)
	modal.open(function(body)
		return build(body)
	end)
	return true
end

function StarterOffer.hide()
	StarterOffer.close()
end

function StarterOffer.reset() -- the check only: a new session
	shownThisSession = false
end

function StarterOffer.close()
	if modal then
		modal.close()
	end
end

function StarterOffer.isOpen(): boolean
	return modal ~= nil and modal.isOpen()
end

function StarterOffer.build()
	modal = Hud.modal("StarterOffer", { title = N.ui.starter.title, width = 640 })
end

function StarterOffer.start()
	if not Hud.root() then
		return
	end
	StarterOffer.build()
end

return StarterOffer
