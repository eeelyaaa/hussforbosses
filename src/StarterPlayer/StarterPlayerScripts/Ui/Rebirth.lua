--!nonstrict
-- Ui/Rebirth: the rebirth screen and its second confirm (brief system 12; ui-kit/phone-rebirth.png and phone-rebirth-confirm.png), plain
-- function version (M2-13). The tile "REBIRTH" (N, D-pad right) opens the screen: a Power bar toward the next requirement, three columns
-- (REBIRTH RESETS / YOU KEEP / YOU GET) with the player's own numbers, and the REBIRTH button. That button opens the confirm
-- ("REBIRTH NOW?", the brief's text with the same numbers, CANCEL / REBIRTH); only the second REBIRTH sends Rebirth.Request { confirmed = true }.
--   Rebirth.open() / close() / isOpen()     Rebirth.onResult(p)     Rebirth.numbers() -> the numbers the texts print
-- Numbers: Power, rebirths, spin tickets, Shield Breaker charges, bought cash from Profile.Changed; the count of bought bosses is the bosses with a
-- bought mark on the player's own spots (Base.State) and crate (Base.Crate), only those whose uid carries the player's own id (N6: not stolen ones).
-- The table (Power needed per rebirth, 10M, 16M, ...) is the brief's; Config.Rebirth.REQUIRED overrides it once M2-14 fills it (TEAM CALL M2-13-4).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local Counters = require(script.Parent.Counters)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)
local Config = require(Shared.Config)
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local Rebirth = { AUTO_START = true }
local modal, confirm, tile = nil, nil, nil
local FALLBACK_REQUIRED = { 10e6, 16e6, 25e6, 40e6, 65e6, 100e6, 160e6, 250e6, 400e6, 650e6 }
local S = { power = 0, rebirths = 0, spinTickets = 0, breakerCharges = 0, boughtCash = 0, placedBought = 0, crateBought = 0 }
local requested = false

local function required(): { number }
	local r = Config.Rebirth and Config.Rebirth.REQUIRED
	return if type(r) == "table" and #r > 0 then r else FALLBACK_REQUIRED
end

local function myId(): number
	return Rebirth._testUserId or (Players.LocalPlayer and Players.LocalPlayer.UserId) or -1
end

-- N6: only a boss the player bought and still holds is kept, never one stolen from another player. A boss's uid is "<userId>-<n>" with
-- the userId of the player it was first granted to, and a bought boss is granted to its buyer, so a uid with the player's own prefix is theirs
-- (a bought boss of theirs that was stolen and stolen back counts; one stolen from someone else does not).
local function isOwnBought(entry): boolean
	if type(entry) ~= "table" or not entry.bought then
		return false
	end
	return type(entry.uid) == "string" and string.sub(entry.uid, 1, #tostring(myId()) + 1) == tostring(myId()) .. "-"
end

local function cfgNum(key: string, default: number): number
	local v = Config.Rebirth and Config.Rebirth[key]
	return if type(v) == "number" then v else default
end

-- the numbers every text prints
function Rebirth.numbers()
	local req = required()
	local cp = Counters.parts()
	local powerNow = (cp and cp.power) or S.power
	local n = S.rebirths + 1
	local maxed = S.rebirths >= #req
	local baseSpots = (Config.Base and (Config.Base.SPOTS_BASE or Config.Base.SPOTS_AT_START)) or 10
	if type(baseSpots) ~= "number" then
		baseSpots = 10
	end
	local fmt = function(v: number): string
		return if v % 1 == 0 then string.format("%d", v) else string.format("%.1f", v)
	end
	return {
		n = n,
		maxed = maxed,
		need = req[math.min(n, #req)],
		power = powerNow,
		spin = Kit.commas(S.spinTickets),
		bought = Kit.commas(S.placedBought + S.crateBought),
		charges = Kit.commas(S.breakerCharges),
		cash = Counters.short(S.boughtCash),
		bagMult = fmt(1 + n * cfgNum("BAG_MULT_STEP", 1)),
		incomeMult = fmt(1 + n * cfgNum("INCOME_STEP", 0.5)),
		spotsLine = if n <= 5 then baseSpots + n else nil,
	}
end

local function texts()
	local x = Rebirth.numbers()
	local T = N.ui.rebirth
	local spotsCol = x.spotsLine and Hud.fill(T.spotsLine, { n = x.spotsLine }) or ""
	local spotsIn = x.spotsLine and Hud.fill(T.spotsInline, { n = x.spotsLine }) or ""
	local v = { spin = x.spin, bought = x.bought, charges = x.charges, cash = x.cash, power = x.bagMult, income = x.incomeMult }
	local colV = table.clone(v)
	colV.spots = spotsCol
	local conV = table.clone(v)
	conV.spots = spotsIn
	return {
		resets = T.resetsBody,
		keep = Hud.fill(T.keepBody, v),
		get = Hud.fill(T.getBody, colV),
		confirm = Hud.fill(T.confirmText, conV),
		x = x,
	}
end

local function sendRequest()
	if requested then
		return
	end
	requested = true
	task.spawn(function()
		local ok, r = pcall(Net.get, "Rebirth", "Request")
		if ok then
			r:FireServer({ confirmed = true })
		end
	end)
	task.delay(5, function()
		requested = false
	end)
end

local function openConfirm()
	local t = texts()
	confirm.open(function(body)
		local th = math.max(U.buttonH, Kit.minDesign(U.touchMin))
		local box = Hud.textBox(body, { name = "ConfirmText", size = UDim2.new(1, 0, 0, 190), text = t.confirm, textSize = TY.small })
		local cancel = Kit.Button(body, { name = "Cancel", text = N.ui.rebirth.cancel, fill = C.white, ink = true, textSize = TY.button, size = UDim2.new(0.5, -6, 0, th), position = UDim2.fromOffset(0, 202) })
		cancel.root.ZIndex = 3
		cancel.onActivated(function()
			confirm.close()
		end)
		local go = Kit.Button(body, { name = "Confirm", text = N.ui.rebirth.button, fill = C.alarmOrange, textSize = TY.button, size = UDim2.new(0.5, -6, 0, th), position = UDim2.new(0.5, 6, 0, 202) })
		go.root.ZIndex = 3
		go.onActivated(sendRequest)
		return 202 + th, cancel.face
	end)
end

Rebirth.openConfirm = openConfirm -- the check opens the second screen without a click

local function build(body: Frame)
	local t = texts()
	local x = t.x
	local th = math.max(U.buttonH, Kit.minDesign(U.touchMin))
	local barH = 30
	local back = Kit.Plate(body, { name = "PowerBar", fill = C.pipEmpty, size = UDim2.new(1, 0, 0, barH), studs = false, outline = U.wellOutlinePx })
	back.ZIndex = 3
	local frac = if x.maxed then 1 else math.clamp(x.power / x.need, 0, 1)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = C.plateBlue
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(frac, 1)
	fill.ZIndex = 4
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, U.radiusPx)
	fc.Parent = fill
	fill.Parent = back
	local bt = Kit.Text(back, { name = "Label", text = if x.maxed then N.ui.rebirth.barMax else Hud.fill(N.ui.rebirth.bar, { p = Counters.short(x.power), r = Counters.short(x.need) }), size = TY.small })
	bt.ZIndex = 5
	local colH = 168
	local gap = 8
	local heads = { N.ui.rebirth.resets, N.ui.rebirth.keep, N.ui.rebirth.get }
	local bodies = { t.resets, t.keep, t.get }
	for i = 1, 3 do
		local col = Kit.Plate(body, { name = "Column" .. i, fill = C.white, size = UDim2.new(1 / 3, -gap * 2 / 3, 0, colH), position = UDim2.new((i - 1) / 3, (i - 1) * gap / 3, 0, barH + gap), studs = false, outline = U.wellOutlinePx })
		col.ZIndex = 3
		local h = Kit.Text(col, { name = "Head", text = heads[i], size = TY.button, color = C.ink, plain = true, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(10, 4), sizeU = UDim2.new(1, -20, 0, 24) })
		h.ZIndex = 4
		local line = Instance.new("Frame")
		line.BackgroundColor3 = C.ink
		line.BorderSizePixel = 0
		line.Position = UDim2.fromOffset(10, 30)
		line.Size = UDim2.new(1, -20, 0, 2)
		line.ZIndex = 4
		line.Parent = col
		local tb = Hud.textBox(col, { name = "Body", size = UDim2.new(1, -8, 1, -38), position = UDim2.fromOffset(4, 34), text = bodies[i], textSize = TY.small })
		tb.well.BackgroundTransparency = 1
		local st = tb.well:FindFirstChildOfClass("UIStroke")
		if st then
			st.Enabled = false
		end
	end
	local btn = Kit.Button(body, { name = "Rebirth", text = N.ui.rebirth.button, fill = C.white, ink = true, textSize = TY.button, size = UDim2.new(0, 260, 0, th), position = UDim2.new(0.5, -130, 0, barH + gap + colH + 10) })
	btn.root.ZIndex = 3
	btn.setEnabled(not x.maxed and x.power >= x.need)
	btn.onActivated(openConfirm)
	return barH + gap + colH + 10 + th + 4, btn.face
end

function Rebirth.open()
	if not modal then
		return
	end
	modal.params.titleText = Hud.fill(N.ui.rebirth.title, { n = math.min(S.rebirths + 1, #required()) })
	modal.open(function(body)
		return (build(body))
	end)
end

function Rebirth.close()
	if confirm then
		confirm.close()
	end
	if modal then
		modal.close()
	end
end

function Rebirth.toggle()
	if modal and modal.isOpen() then
		Rebirth.close()
	else
		Rebirth.open()
	end
end

function Rebirth.isOpen()
	return modal ~= nil and modal.isOpen()
end

local function updateTile()
	if tile then
		local x = Rebirth.numbers()
		tile.setProgress(if x.maxed then 1 else x.power / x.need)
	end
end

local function changed()
	updateTile()
	if modal and modal.isOpen() then
		modal.params.titleText = Hud.fill(N.ui.rebirth.title, { n = math.min(S.rebirths + 1, #required()) })
		modal.refresh()
	end
	if confirm and confirm.isOpen() then
		confirm.refresh()
	end
end

function Rebirth.onProfile(p)
	if typeof(p) ~= "table" then
		return
	end
	for _, k in ipairs({ "power", "rebirths", "spinTickets", "breakerCharges", "boughtCash" }) do
		if typeof(p[k]) == "number" then
			S[k] = p[k]
		end
	end
	changed()
end

function Rebirth.onBaseState(p)
	if typeof(p) == "table" and p.ownerUserId == myId() and typeof(p.spots) == "table" then
		local n = 0
		for _, s in pairs(p.spots) do
			if isOwnBought(s) then -- an empty spot arrives as false
				n += 1
			end
		end
		S.placedBought = n
		changed()
	end
end

function Rebirth.onCrate(p)
	if typeof(p) == "table" and typeof(p.items) == "table" then
		local n = 0
		for _, it in ipairs(p.items) do
			if isOwnBought(it) then
				n += 1
			end
		end
		S.crateBought = n
		changed()
	end
end

function Rebirth.onResult(p)
	requested = false
	if typeof(p) == "table" and p.ok then
		Rebirth.close() -- the celebration is the Feel pass; the toast comes from Ui/Toasts
	elseif confirm and confirm.isOpen() then
		confirm.close()
	end
end

function Rebirth.build()
	modal = Hud.modal("Rebirth", { title = "", width = 820 })
	confirm = Hud.modal("RebirthConfirm", { title = N.ui.rebirth.confirmTitle, width = 600, stack = true })
	tile = Hud.tile("rebirth", N.ui.tiles.rebirth, 2, Rebirth.toggle)
	updateTile()
end

function Rebirth.start()
	if not Hud.root() then
		return
	end
	Rebirth.build()
	UserInputService.InputBegan:Connect(function(io, processed)
		if not processed and (io.KeyCode == Enum.KeyCode.N or io.KeyCode == Enum.KeyCode.DPadRight) then
			Rebirth.toggle()
		end
	end)
	task.spawn(function()
		for _, e in ipairs({ { "Profile", "Changed", Rebirth.onProfile }, { "Base", "State", Rebirth.onBaseState }, { "Base", "Crate", Rebirth.onCrate }, { "Rebirth", "Result", Rebirth.onResult } }) do
			local ok, r = pcall(Net.get, e[1], e[2])
			if ok then
				r.OnClientEvent:Connect(e[3])
			end
		end
	end)
end

return Rebirth
