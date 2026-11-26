--!nonstrict
-- Ui/Offline: "While you were away" (brief system 11; ui-kit/phone-offline-earnings.png), plain function version (M2-13).
-- Offline.Summary { seconds, total, perBoss } opens it; COLLECT sends Offline.Collect {}; Offline.Result { ok, amount } closes it and flies the cash
-- to the cash plate. It has no X and no dim dismiss: the one way out is Collect (the server clears the summary on collect).
--   Offline.show(summary)   Offline.isOpen()   Offline.onResult(result)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local Counters = require(script.Parent.Counters)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local Offline = { AUTO_START = true }
local modal = nil
local pending = nil
local collecting = false

local function duration(sec: number): string
	local m = math.max(1, math.floor(sec / 60 + 0.5))
	local h = m // 60
	m = m % 60
	local T = N.ui.away
	if h > 0 and m > 0 then
		return Hud.fill(T.hm, { h = h, m = m })
	elseif h > 0 then
		return Hud.fill(T.h, { h = h })
	end
	return Hud.fill(T.m, { m = m })
end

local function build(body: Frame)
	local th = math.max(U.buttonH, Kit.minDesign(U.touchMin))
	local well = Kit.Plate(body, { name = "Earned", fill = C.white, size = UDim2.new(1, 0, 0, 110), studs = false, outline = U.wellOutlinePx })
	well.ZIndex = 3
	local icon = Kit.Icon(well, "cash", { size = 64, position = UDim2.new(0, 14, 0.5, 0), anchor = Vector2.new(0, 0.5), standIn = C.cashGreen })
	icon.ZIndex = 4
	local function line(text, y, h, size, plain)
		local l = Kit.Text(well, { text = text, size = size, color = C.ink, plain = true, body = not plain, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(92, y), sizeU = UDim2.new(1, -100, 0, h) })
		l.ZIndex = 4
		return l
	end
	line(Hud.fill(N.ui.away.away, { t = duration(pending.seconds) }), 8, 24, TY.name)
	line(N.ui.away.earned, 32, 24, TY.name)
	line(N.ui.cashPrefix .. (if pending.total < 1e9 then Kit.commas(pending.total) else Counters.short(pending.total)), 58, 40, TY.title + 6, true)
	local collect = Kit.Button(body, { name = "Collect", text = N.ui.away.collect, fill = C.cashGreen, textSize = TY.title, size = UDim2.new(1, 0, 0, th), position = UDim2.fromOffset(0, 122) })
	collect.root.ZIndex = 3
	collect.setEnabled(not collecting)
	collect.onActivated(function()
		if collecting then
			return
		end
		collecting = true
		collect.setEnabled(false)
		task.spawn(function()
			local ok, r = pcall(Net.get, "Offline", "Collect")
			if ok then
				r:FireServer({})
			end
		end)
		task.delay(5, function() -- no answer: let the player try again
			if collecting and modal and modal.isOpen() then
				collecting = false
				modal.refresh()
			end
		end)
	end)
	return 122 + th, collect.face
end

function Offline.show(summary)
	if not modal or typeof(summary) ~= "table" or typeof(summary.total) ~= "number" or typeof(summary.seconds) ~= "number" then
		return
	end
	if modal.isOpen() then -- the server resends the summary until collected (2, 6, 15 s): leave the open panel alone
		return
	end
	pending = { seconds = summary.seconds, total = summary.total }
	collecting = false
	modal.open(function(body)
		return (build(body))
	end)
end

function Offline.isOpen()
	return modal ~= nil and modal.isOpen()
end

function Offline.onResult(p)
	if typeof(p) ~= "table" then
		return
	end
	if p.ok or p.reason == "none" then
		pending, collecting = nil, false
		if modal then
			modal.close()
		end
		if p.ok and typeof(p.amount) == "number" and p.amount > 0 then
			Counters.popCash(p.amount)
		end
	else
		collecting = false
		if modal and modal.isOpen() then
			modal.refresh()
		end
	end
end

function Offline.build()
	modal = Hud.modal("Offline", { title = N.ui.away.title, width = 520, dismiss = false, noClose = true })
end

function Offline.start()
	if not Hud.root() then
		return
	end
	Offline.build()
	task.spawn(function()
		for _, e in ipairs({ { "Offline", "Summary", Offline.show }, { "Offline", "Result", Offline.onResult } }) do
			local ok, r = pcall(Net.get, e[1], e[2])
			if ok then
				r.OnClientEvent:Connect(e[3])
			end
		end
	end)
end

return Offline
