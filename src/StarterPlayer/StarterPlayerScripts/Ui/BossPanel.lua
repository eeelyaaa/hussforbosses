--!nonstrict
-- Ui/BossPanel: the placed boss's panel (brief system 9; ui-kit/phone-boss-panel.png), plain function version (M2-13).
--   BossPanel.open(info)   info = { uid, creatureId, level, income (cash/s now), spot (spotIndex), nextCost? }
--                          (whoever handles "Interact" at a placed boss calls it, M2-12; the data is one spot of Base.State)
--   BossPanel.close()      BossPanel.isOpen()
-- The server decides the price, the payment and the level: the buttons only send Boss.Upgrade { uid } and Base.PickUp { spotIndex }.
-- While open it follows Base.State (income, level, gone = closes), Boss.Result (level, nextCost), Profile.Changed (cash).
-- Display only: "After" and a missing nextCost are derived from the brief's rule (income x (1 + 0.25 x (L - 1)); cost 30 x base x 1.3^(L-1));
-- Config.Upgrades may override INCOME_STEP, COST_MULT, COST_GROWTH, MAX_LEVEL once M2-11 fills it.
local Players = game:GetService("Players")
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

local BossPanel = { AUTO_START = true }
local modal = nil
local info = nil
local cash = 0

local function cfg(key: string, default: number): number
	local u = Config.Upgrades
	local v = u and u[key]
	return if type(v) == "number" then v else default
end

local function incomeAt(base: number, level: number): number
	return base * (1 + cfg("INCOME_STEP", 0.25) * (level - 1))
end

local function baseIncome(i): number
	return i.income / (1 + cfg("INCOME_STEP", 0.25) * (i.level - 1))
end

local function nextCostOf(i): number?
	if i.level >= cfg("MAX_LEVEL", 20) then
		return nil
	end
	if i.nextCost then
		return i.nextCost
	end
	return math.floor(cfg("COST_MULT", 30) * baseIncome(i) * cfg("COST_GROWTH", 1.3) ^ (i.level - 1) + 0.5)
end

local function perSecond(v: number): string
	local text = if v < 1000 then string.format("%.2f", v) else Counters.short(v)
	return N.ui.cashPrefix .. text .. N.ui.perSecond
end

local function send(family: string, name: string, payload)
	task.spawn(function()
		local ok, r = pcall(Net.get, family, name)
		if ok then
			r:FireServer(payload)
		end
	end)
end

local function build(body: Frame)
	local zone, tier = Ids.parseCreature(info.creatureId)
	local th = math.max(U.buttonH, Kit.minDesign(U.touchMin))
	local tierColor = C.tier[tier or 1]
	local leftW = 200
	-- picture slot (the render comes with the art pass; a tier-coloured plate with the tier word until then)
	local pic = Kit.Plate(body, { name = "Picture", fill = tierColor, size = UDim2.fromOffset(leftW, 2 * th + 96), studs = false })
	pic.ZIndex = 3
	local chip = Kit.Text(pic, { name = "TierWord", text = string.upper(N.tiers[tier or 1]), size = TY.button, position = UDim2.new(0, 0, 1, -34), sizeU = UDim2.new(1, 0, 0, 28) })
	chip.ZIndex = 4
	local rx = leftW + 12
	local right = Instance.new("Frame")
	right.Name = "Right"
	right.BackgroundTransparency = 1
	right.Position = UDim2.fromOffset(rx, 0)
	right.Size = UDim2.new(1, -rx, 1, 0)
	right.ZIndex = 3
	right.Parent = body
	local zoneLine = Kit.Text(right, { name = "Zone", text = string.upper(Hud.fill(N.ui.boss.zone, { n = zone or "", name = N.zones[zone or 1] or "" })), size = TY.small, align = Enum.TextXAlignment.Left, sizeU = UDim2.new(1, 0, 0, 22) })
	zoneLine.ZIndex = 4
	local lvl = Kit.Text(right, { name = "Level", text = Hud.fill(N.ui.boss.level, { n = info.level }), size = TY.name, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(0, 24), sizeU = UDim2.new(0, 110, 0, 24) })
	lvl.ZIndex = 4
	-- level bar: 20 cells
	local maxL = cfg("MAX_LEVEL", 20)
	local bar = Instance.new("Frame")
	bar.Name = "LevelBar"
	bar.BackgroundTransparency = 1
	bar.Position = UDim2.fromOffset(116, 30)
	bar.Size = UDim2.new(1, -116, 0, 12)
	bar.ZIndex = 4
	bar.Parent = right
	local bl = Instance.new("UIListLayout")
	bl.FillDirection = Enum.FillDirection.Horizontal
	bl.Padding = UDim.new(0, 2)
	bl.Parent = bar
	for i = 1, maxL do
		local cell = Instance.new("Frame")
		cell.Name = "Cell" .. i
		cell.BorderSizePixel = 0
		cell.BackgroundColor3 = i <= info.level and C.cashGreen or C.pipEmpty
		cell.Size = UDim2.new(1 / maxL, -2, 1, 0)
		cell.ZIndex = 4
		cell.Parent = bar
	end
	-- earns now / after
	local well = Kit.Plate(right, { name = "Earns", fill = C.white, size = UDim2.new(1, 0, 0, 72), position = UDim2.fromOffset(0, 52), studs = false, outline = U.wellOutlinePx })
	well.ZIndex = 3
	local maxed = info.level >= maxL
	local afterIncome = incomeAt(baseIncome(info), info.level + 1)
	local function col(x: number, head: string, value: string)
		local h = Kit.Text(well, { text = head, size = TY.small, color = C.ink, plain = true, body = true, align = Enum.TextXAlignment.Left, position = UDim2.new(x, 10, 0, 6), sizeU = UDim2.new(0.5, -14, 0, 20) })
		h.ZIndex = 4
		local v = Kit.Text(well, { text = value, size = TY.title, color = C.ink, plain = true, align = Enum.TextXAlignment.Left, position = UDim2.new(x, 10, 0, 28), sizeU = UDim2.new(0.5, -14, 0, 34) })
		v.ZIndex = 4
	end
	col(0, N.ui.boss.earnsNow, perSecond(info.income))
	if not maxed then
		col(0.5, N.ui.boss.after, perSecond(afterIncome))
	end
	-- upgrade
	local cost = nextCostOf(info)
	local text = if cost then (N.ui.boss.upgrade .. "  " .. N.ui.cashPrefix .. Counters.short(cost)) else N.ui.boss.maxLevel
	local up = Kit.Button(right, { name = "Upgrade", text = text, fill = C.cashGreen, textSize = TY.button, size = UDim2.new(1, 0, 0, th), position = UDim2.fromOffset(0, 134) })
	up.root.ZIndex = 3
	up.setEnabled(cost ~= nil and cash >= cost)
	up.onActivated(function()
		send("Boss", "Upgrade", { uid = info.uid })
	end)
	local pick = Kit.Button(right, { name = "PickUp", text = N.ui.boss.pickUp, fill = C.white, ink = true, textSize = TY.button, size = UDim2.fromOffset(170, th), position = UDim2.fromOffset(0, 134 + th + 12) })
	pick.root.ZIndex = 3
	pick.onActivated(function()
		send("Base", "PickUp", { spotIndex = info.spot })
		modal.close()
	end)
	return math.max(2 * th + 96, 134 + 2 * th + 12) + 4, up.face
end

local function open()
	if not modal then
		return
	end
	local focus
	modal.open(function(body)
		local h, f = build(body)
		focus = f
		return h
	end)
end

function BossPanel.open(i)
	if not modal or typeof(i) ~= "table" or typeof(i.creatureId) ~= "string" then
		return
	end
	info = table.clone(i)
	info.level = info.level or 1
	info.income = info.income or 0
	modal.params.titleText = string.upper(N.creatures[info.creatureId] or "")
	local parts = Counters.parts()
	if parts then
		cash = parts.cash
	end
	open()
end

function BossPanel.close()
	if modal then
		modal.close()
	end
end

function BossPanel.isOpen()
	return modal ~= nil and modal.isOpen()
end

-- the seams the remotes call (and the check's local fake calls with contract payloads)
function BossPanel.onResult(p)
	if not (info and typeof(p) == "table" and p.uid == info.uid and p.ok) then
		return
	end
	local old = info.level
	info.level = p.level or (old + 1)
	info.income = incomeAt(baseIncome({ income = info.income, level = old }), info.level)
	info.nextCost = p.nextCost
	if modal and modal.isOpen() then
		modal.refresh()
	end
end

function BossPanel.onBaseState(p)
	if not (info and typeof(p) == "table" and p.ownerUserId == (BossPanel._testUserId or (Players.LocalPlayer and Players.LocalPlayer.UserId) or -1) and typeof(p.spots) == "table") then
		return
	end
	for idx, s in pairs(p.spots) do
		if type(s) == "table" and s.uid == info.uid then
			info.level, info.income, info.spot = s.level, s.income, idx
			info.nextCost = nil
			if modal and modal.isOpen() then
				modal.refresh()
			end
			return
		end
	end
	if modal and modal.isOpen() then -- the boss left its spot (picked up, stolen)
		modal.close()
	end
end

function BossPanel.onProfile(p)
	if typeof(p) == "table" and typeof(p.cash) == "number" then
		cash = p.cash
		if modal and modal.isOpen() then
			modal.refresh()
		end
	end
end

function BossPanel.build()
	modal = Hud.modal("Boss", { title = "", width = 560 })
	info = nil
end

function BossPanel.start()
	if not Hud.root() then
		return
	end
	BossPanel.build()
	task.spawn(function()
		for _, e in ipairs({ { "Boss", "Result", BossPanel.onResult }, { "Base", "State", BossPanel.onBaseState }, { "Profile", "Changed", BossPanel.onProfile } }) do
			local ok, r = pcall(Net.get, e[1], e[2])
			if ok then
				r.OnClientEvent:Connect(e[3])
			end
		end
	end)
end

return BossPanel
