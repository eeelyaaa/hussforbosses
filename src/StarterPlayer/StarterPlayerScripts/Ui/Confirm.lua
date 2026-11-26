--!nonstrict
-- Ui/Confirm: the one shared confirm dialog for Sell and Swap (M2-17; brief screen 11; ui-kit/phone-confirm-sell.png, phone-confirm-swap-bought.png),
-- plain function version built on Hud.modal (same frame as the rebirth confirm).
--   Confirm.sell(info)    "SELL THIS BOSS?"  CANCEL / SELL $n (green). The carried boss is sold; sends Base.Sell {}.
--   Confirm.swap(info)    "SWAP BOSSES?"     CANCEL / SWAP (orange). The placed boss is sold, the carried one takes its spot; sends Base.Swap { spotIndex }.
--   info = { creatureId, level, amount, bought = true|'spin'|'pack'|false, spotIndex? (swap) }
--          amount is the sale value the caller read (the server computes the real one and Base.Result.amount reports it; Confirm.estimate is for the caller's number).
--   A bought boss gets the gold BOUGHT tag and the line that selling it is for good (brief system 7, "Bought bosses").
--   Confirm.close()  Confirm.isOpen()  Confirm.estimate(income) -> income x Config.Base.SELL_MULT (display only)
-- Closes itself when the player stops carrying (Carry.State) and on the dim, the X, CANCEL or the B button. One press sends once.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local Counters = require(script.Parent.Counters)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)
local Ids = require(Shared.Ids)
local Config = require(Shared.Config)
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local Confirm = { AUTO_START = true }
local modal = nil
local sentAt = 0

local function fill(text: string, v): string
	return (string.gsub(text, "{(%w+)}", function(k)
		return if v[k] ~= nil then tostring(v[k]) else nil
	end))
end

function Confirm.estimate(income: number): number
	local mult = Config.Base and Config.Base.SELL_MULT
	return income * (if type(mult) == "number" then mult else 20)
end

function Confirm.isOpen(): boolean
	return modal ~= nil and modal.isOpen()
end

function Confirm.close()
	if modal then
		modal.close()
		modal = nil
	end
end

local function send(family: string, name: string, payload)
	if os.clock() - sentAt < 0.6 then
		return
	end
	sentAt = os.clock()
	task.spawn(function()
		local ok, r = pcall(Net.get, family, name)
		if ok then
			r:FireServer(payload)
		end
	end)
end

local function open(kind: string, info)
	Confirm.close()
	local isSwap = kind == "swap"
	local cn = N.ui.confirm
	local bought = info.bought == true or info.bought == "spin" or info.bought == "pack"
	local amount = Counters.short(info.amount or 0)
	local vals = { boss = N.creatures[info.creatureId] or tostring(info.creatureId), n = info.level or 1, amount = amount }
	local text = fill(if isSwap then cn.swapText else cn.sellText, vals)
	if bought then
		text ..= cn.boughtLine
	end
	local _, tier = Ids.parseCreature(info.creatureId)
	modal = Hud.modal("Confirm", { width = 520, stack = true })
	local m = modal
	m.open(function(body)
		m.title.Text = string.upper(if isSwap then cn.swapTitle else cn.sellTitle)
		local th = math.max(U.buttonH, Kit.minDesign(U.touchMin))
		local contentH = 150
		local pic = Kit.Plate(body, { name = "Pic", fill = C.padStone, size = UDim2.fromOffset(120, contentH), studs = false, outline = U.wellOutlinePx })
		pic.ZIndex = 3
		local nm = Kit.Text(pic, { name = "BossName", text = vals.boss, size = TY.name, color = C.ink, plain = true, position = UDim2.fromOffset(6, 8), sizeU = UDim2.new(1, -12, 0, 70) })
		nm.TextWrapped = true
		nm.ZIndex = 4
		local chip = Kit.Plate(pic, { name = "TierChip", fill = C.tier[tier or 1], size = UDim2.new(1, -16, 0, U.tierChipH), position = UDim2.new(0, 8, 1, -(U.tierChipH + 8)), studs = false, outline = U.wellOutlinePx })
		chip.ZIndex = 4
		local ct = Kit.Text(chip, { name = "Text", text = string.upper(N.tiers[tier or 1]), size = TY.small, color = C.ink, plain = true })
		ct.ZIndex = 5
		local y = 0
		if bought then
			local tag = Kit.Plate(body, { name = "BoughtTag", fill = C.shopGold, size = UDim2.fromOffset(84, U.tierChipH + 4), position = UDim2.fromOffset(128, 0), studs = false, outline = U.wellOutlinePx })
			tag.ZIndex = 4
			local tl = Kit.Text(tag, { name = "Text", text = N.ui.bought, size = TY.small, color = C.ink, plain = true })
			tl.ZIndex = 5
			y = U.tierChipH + 4 + 6
		end
		Hud.textBox(body, { name = "ConfirmText", size = UDim2.new(1, -128, 0, contentH - y), position = UDim2.fromOffset(128, y), text = text, textSize = TY.small })
		local cancel = Kit.Button(body, { name = "Cancel", text = cn.cancel, fill = C.white, ink = true, textSize = TY.button, size = UDim2.new(0.5, -6, 0, th), position = UDim2.fromOffset(0, contentH + 12) })
		cancel.root.ZIndex = 3
		cancel.onActivated(Confirm.close)
		local label = if isSwap then cn.swap else fill(cn.sell, vals)
		local go = Kit.Button(body, { name = "Confirm", text = label, fill = if isSwap then C.alarmOrange else C.cashGreen, textSize = TY.button, size = UDim2.new(0.5, -6, 0, th), position = UDim2.new(0.5, 6, 0, contentH + 12) })
		go.root.ZIndex = 3
		go.onActivated(function()
			if isSwap then
				send("Base", "Swap", { spotIndex = info.spotIndex })
			else
				send("Base", "Sell", {})
			end
			Confirm.close()
		end)
		return contentH + 12 + th, cancel.face
	end)
	return m
end

function Confirm.sell(info)
	return open("sell", info)
end

function Confirm.swap(info)
	return open("swap", info)
end

function Confirm.start(ctx)
	task.spawn(function()
		local ok, r = pcall(Net.get, "Carry", "State")
		if ok then
			r.OnClientEvent:Connect(function(p)
				if typeof(p) == "table" and p.state ~= "carrying" then
					Confirm.close()
				end
			end)
		end
	end)
end

return Confirm
