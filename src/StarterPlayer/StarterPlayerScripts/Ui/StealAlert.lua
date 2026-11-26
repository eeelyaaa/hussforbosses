--!nonstrict
-- Ui/StealAlert: the steal and shield alerts (M2-17; brief system 10 and screen 10; ui-kit/phone-alert-steal-owner.png, -steal-thief.png,
-- -shield-broken.png), plain function versions. Banners stack top centre under the counters, clear of the tile row and the shield plate.
--   Owner:   "YOUR {BOSS} IS BEING STOLEN!" (orange) with the gold BOUGHT tag when the boss came from the shop, and an arrow to the thief.
--            Steal.Alert shows it; Steal.Result dropped / returned / success for that uid ends it.
--   Owner:   "{NAME} BROKE YOUR SHIELD!" (orange) with an arrow home. Shield.Broken shows it for Config.Shield.BROKEN_ALERT_S (10 s, TEAM CALL M2-17-2).
--   Thief:   the green "GET IT HOME!" strip with an arrow home, and the "STOLEN {BOSS}" strip with its tier chip (and BOUGHT). Driven by Carry.State
--            (carrying with stolenFrom set), so the client never has to guess which role it is; Steal.Result refusals become a toast.
--   StealAlert.showOwner(p) hideOwner(uid)   showBroken(p) hideBroken()   showThief(info) hideThief()   StealAlert.isOn() onChange(fn)
--   StealAlert.homeProvider = function() -> Vector3?   (own plot; default reads Base.State and workspace.Plots)
-- Arrows turn to the thief (or home) from the camera's heading every frame; the banners are never buttons and the lock board and offers are hidden while one is on
-- (brief system 10). Display only: the server decides everything; nothing here is sent.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local Toasts = require(script.Parent.Toasts)
local Prompts = require(script.Parent.Prompts)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)
local Ids = require(Shared.Ids)
local Config = require(Shared.Config)
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local StealAlert = { AUTO_START = true }

local ROW_H, STRIP_H, INFO_H = 52, 40, 42
local MAX_W = 460
local holder = nil
local owner = {} -- uid -> row
local broken, thiefGreen, thiefInfo = nil, nil, nil
local listeners = {}
local myPlot = nil

local function fill(text: string, v): string
	return (string.gsub(text, "{(%w+)}", function(k)
		return if v[k] ~= nil then tostring(v[k]) else nil
	end))
end

local function cfgShield(key: string, default: number): number
	local v = Config.Shield and Config.Shield[key]
	return if type(v) == "number" then v else default
end

-- ---------------------------------------------------------------- pieces

-- A white plate with an arrow that turns. 0 = up. Uses the pointerArrow icon once it exists, else a shaft and a diamond head.
local function Arrow(parent: Instance)
	local plate = Kit.Plate(parent, { name = "Arrow", fill = C.white, size = UDim2.fromOffset(36, 36), studs = false, outline = U.wellOutlinePx })
	plate.ZIndex = 5
	local rot = Instance.new("Frame")
	rot.Name = "Rot"
	rot.BackgroundTransparency = 1
	rot.AnchorPoint = Vector2.new(0.5, 0.5)
	rot.Position = UDim2.fromScale(0.5, 0.5)
	rot.Size = UDim2.fromOffset(36, 36)
	rot.ZIndex = 5
	rot.Parent = plate
	local icon = Skin.Icons.pointerArrow
	if icon and icon ~= 0 then
		local ic = Kit.Icon(rot, "pointerArrow", { name = "Glyph", size = 28, position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5) })
		ic.ZIndex = 6
	else
		local shaft = Instance.new("Frame")
		shaft.Name = "Shaft"
		shaft.BackgroundColor3 = C.ink
		shaft.BorderSizePixel = 0
		shaft.Size = UDim2.fromOffset(15, 4)
		shaft.Position = UDim2.fromOffset(7, 16)
		shaft.ZIndex = 6
		shaft.Parent = rot
		local head = Instance.new("Frame")
		head.Name = "Head"
		head.BackgroundColor3 = C.ink
		head.BorderSizePixel = 0
		head.Size = UDim2.fromOffset(9, 9)
		head.AnchorPoint = Vector2.new(0.5, 0.5)
		head.Position = UDim2.fromOffset(23, 18)
		head.Rotation = 45
		head.ZIndex = 6
		head.Parent = rot
	end
	rot.Rotation = -90
	return { plate = plate, rot = rot }
end

local function Chip(parent: Instance, text: string, fillColor: Color3, w: number)
	local chip = Kit.Plate(parent, { name = "Chip", fill = fillColor, size = UDim2.fromOffset(w, U.tierChipH), studs = false, outline = U.wellOutlinePx })
	chip.ZIndex = 5
	local l = Kit.Text(chip, { name = "Text", text = text, size = TY.small, color = C.ink, plain = true })
	l.ZIndex = 6
	return chip
end

local function creatureName(id: string?): string
	return N.creatures[id or ""] or tostring(id or "")
end

-- A banner row. Children laid out by offsets from the row's edges, so only the row's width changes.
-- p: name, fill, iconKey, text, arrow (bool), bought (bool), height
local function Banner(p)
	local row = Kit.Plate(holder, { name = p.name, fill = p.fill, size = UDim2.fromOffset(MAX_W, p.height or ROW_H) })
	row.LayoutOrder = p.order or 1
	row.ZIndex = 41
	local right = 10
	local arrow
	if p.arrow then
		arrow = Arrow(row)
		arrow.plate.AnchorPoint = Vector2.new(1, 0.5)
		arrow.plate.Position = UDim2.new(1, -right, 0.5, 0)
		right += 36 + 8
	end
	local chip
	if p.bought then
		chip = Chip(row, N.ui.bought, C.shopGold, 84)
		chip.AnchorPoint = Vector2.new(1, 0.5)
		chip.Position = UDim2.new(1, -right, 0.5, 0)
		right += 84 + 8
	end
	local icon = Kit.Icon(row, p.iconKey, { name = "Icon", size = 32, position = UDim2.new(0, 10, 0.5, -16), standIn = C.white })
	icon.ZIndex = 42
	local text = Kit.Text(row, { name = "Text", text = p.text, size = TY.name, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(52, 0), sizeU = UDim2.new(1, -(52 + right), 1, 0) })
	text.TextWrapped = true
	text.ZIndex = 42
	return { row = row, arrow = arrow, text = text, chip = chip }
end

-- ---------------------------------------------------------------- layout

local function rootWidth(): number
	local root = Hud.root()
	return root and (root.AbsoluteSize.X / Kit.scale()) or U.designW
end

local function tilesRight(): number
	local root = Hud.root()
	local tiles = root and root:FindFirstChild("Tiles")
	if tiles and tiles.AbsoluteSize.X > 0 then
		return (tiles.AbsolutePosition.X + tiles.AbsoluteSize.X - root.AbsolutePosition.X) / Kit.scale()
	end
	return 16
end

-- the top-centre slot (design px): left, top, width. The lock board uses the same slot (it is hidden while an alert is on).
function StealAlert.slot(): (number, number, number)
	local s = Kit.scale()
	local rootW = rootWidth()
	local w = math.min(MAX_W, rootW - 32)
	local left = rootW / 2 - w / 2
	local tr = tilesRight() + 12
	if left < tr then
		left = tr
		w = math.min(w, rootW - 16 - left)
	end
	local top = math.ceil((GuiService.TopbarInset.Max.Y + 10) / s) + U.counterH + 8 + (if Hud.fightShowing() then 90 else 0)
	return left, top, w
end

local function layout()
	if not (holder and Hud.root()) then
		return
	end
	local left, top, w = StealAlert.slot()
	holder.Position = UDim2.fromOffset(left, top)
	holder.Size = UDim2.fromOffset(w, 0)
	for _, ch in ipairs(holder:GetChildren()) do
		if ch:IsA("GuiObject") then
			ch.Size = UDim2.fromOffset(w, ch.Size.Y.Offset)
		end
	end
end

local function changed()
	layout()
	for _, fn in ipairs(table.clone(listeners)) do
		task.spawn(fn, StealAlert.isOn())
	end
end

function StealAlert.build(parent: Instance)
	if holder then
		holder:Destroy()
	end
	owner, broken, thiefGreen, thiefInfo = {}, nil, nil, nil
	holder = Instance.new("Frame")
	holder.Name = "Alerts"
	holder.BackgroundTransparency = 1
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.Size = UDim2.fromOffset(MAX_W, 0)
	holder.ZIndex = 40
	holder.Parent = parent
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, 6)
	list.Parent = holder
	if StealAlert._scaleConn then
		StealAlert._scaleConn.Disconnect()
	end
	StealAlert._scaleConn = Kit.onScale(layout)
	layout()
	return holder
end

function StealAlert.destroy()
	if StealAlert._scaleConn then
		StealAlert._scaleConn.Disconnect()
		StealAlert._scaleConn = nil
	end
	if holder then
		holder:Destroy()
		holder = nil
	end
	owner, broken, thiefGreen, thiefInfo = {}, nil, nil, nil
end

function StealAlert.instance()
	return holder
end

function StealAlert.isOn(): boolean
	return next(owner) ~= nil or broken ~= nil
end

function StealAlert.onChange(fn)
	table.insert(listeners, fn)
end

-- the thief's strips count as "the alert is on" for nothing: they are the thief's own, not an offer blocker (brief: owner alerts only)

-- ---------------------------------------------------------------- owner alerts

-- p = Steal.Alert payload { uid, creatureId, thiefUserId, bought }
function StealAlert.showOwner(p)
	if not holder or typeof(p) ~= "table" or typeof(p.uid) ~= "string" then
		return
	end
	if owner[p.uid] then
		owner[p.uid].row:Destroy()
	end
	local text = string.upper(fill(N.ui.alerts.stolenOwner, { boss = creatureName(p.creatureId) }))
	local b = Banner({ name = "StealOwner", fill = C.alarmOrange, iconKey = "stealAlert", text = text, arrow = true, bought = p.bought == true, order = 1 })
	b.thiefUserId = p.thiefUserId
	owner[p.uid] = b
	Kit.popScale(b.row, 1.04, 0.06, 0.1)
	changed()
	return b
end

function StealAlert.hideOwner(uid: string)
	local b = owner[uid]
	if b then
		b.row:Destroy()
		owner[uid] = nil
		changed()
	end
end

local brokenToken = 0
function StealAlert.showBroken(p)
	if not holder or typeof(p) ~= "table" then
		return
	end
	if broken then
		broken.row:Destroy()
	end
	brokenToken += 1
	local token = brokenToken
	local who = Players:GetPlayerByUserId(p.byUserId or 0)
	local name = who and who.DisplayName or N.ui.alerts.someone
	broken = Banner({ name = "ShieldBroken", fill = C.alarmOrange, iconKey = "shieldBroken", text = string.upper(fill(N.ui.alerts.brokenShield, { name = name })), arrow = true, order = 2 })
	Kit.popScale(broken.row, 1.04, 0.06, 0.1)
	if not who and typeof(p.byUserId) == "number" then
		task.spawn(function()
			local ok, n = pcall(function()
				return Players:GetNameFromUserIdAsync(p.byUserId)
			end)
			if ok and broken and token == brokenToken and broken.text.Parent then
				broken.text.Text = string.upper(fill(N.ui.alerts.brokenShield, { name = n }))
			end
		end)
	end
	changed()
	task.delay(cfgShield("BROKEN_ALERT_S", 10), function()
		if token == brokenToken then
			StealAlert.hideBroken()
		end
	end)
	return broken
end

function StealAlert.hideBroken()
	if broken then
		broken.row:Destroy()
		broken = nil
		changed()
	end
end

-- ---------------------------------------------------------------- the thief's strips

-- info = { creatureId, level?, bought? }
function StealAlert.showThief(info)
	if not holder then
		return
	end
	StealAlert.hideThief()
	thiefGreen = Banner({ name = "GetItHome", fill = C.cashGreen, iconKey = "steal", text = string.upper(N.ui.alerts.getItHome), arrow = true, order = 3, height = STRIP_H })
	local zone, tier = Ids.parseCreature(info.creatureId)
	local row = Kit.Plate(holder, { name = "StolenInfo", fill = C.panelGrey, size = UDim2.fromOffset(rootWidth(), INFO_H) })
	row.LayoutOrder = 4
	row.ZIndex = 41
	local right = 10
	local tierColor = tier and C.tier[tier] or C.tier[1]
	local chipW = 120
	local tc = Chip(row, string.upper(N.tiers[tier or 1]), tierColor, chipW)
	tc.AnchorPoint = Vector2.new(1, 0.5)
	tc.Position = UDim2.new(1, -right, 0.5, 0)
	right += chipW + 8
	if info.bought then
		local bc = Chip(row, N.ui.bought, C.shopGold, 84)
		bc.AnchorPoint = Vector2.new(1, 0.5)
		bc.Position = UDim2.new(1, -right, 0.5, 0)
		right += 84 + 8
	end
	local text = Kit.Text(row, { name = "Text", text = string.upper(fill(N.ui.alerts.stolenLine, { boss = creatureName(info.creatureId) })), size = TY.name, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(10, 0), sizeU = UDim2.new(1, -(10 + right), 1, 0) })
	text.TextWrapped = true
	text.ZIndex = 42
	thiefInfo = { row = row, text = text }
	layout()
end

function StealAlert.hideThief()
	if thiefGreen then
		thiefGreen.row:Destroy()
		thiefGreen = nil
	end
	if thiefInfo then
		thiefInfo.row:Destroy()
		thiefInfo = nil
	end
end

function StealAlert.thiefShowing(): boolean
	return thiefGreen ~= nil
end

-- ---------------------------------------------------------------- arrows

StealAlert.homeProvider = nil
local function homePosition(): Vector3?
	if StealAlert.homeProvider then
		return StealAlert.homeProvider()
	end
	local plots = workspace:FindFirstChild("Plots") -- stream-ok: read every frame by update(), nil-tolerant
	local model = plots and myPlot and plots:FindFirstChild("Plot" .. tostring(myPlot))
	return model and model:GetPivot().Position or nil
end

local function bearingTo(target: Vector3?): number?
	local cam = workspace.CurrentCamera
	if not (cam and target) then
		return nil
	end
	local rel = target - cam.CFrame.Position
	local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
	local f = look.X * rel.X + look.Z * rel.Z
	local r = right.X * rel.X + right.Z * rel.Z
	return math.deg(math.atan2(r, f))
end

-- exposed for the check: turn an alert's arrow to a bearing (degrees right of straight ahead)
function StealAlert.setBearing(arrow, deg: number)
	if arrow then
		arrow.rot.Rotation = deg - 90
	end
end

local function update()
	if not holder then
		return
	end
	for _, b in pairs(owner) do
		local plr = Players:GetPlayerByUserId(b.thiefUserId or 0)
		local hrp = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local deg = bearingTo(hrp and hrp.Position)
		if deg then
			StealAlert.setBearing(b.arrow, deg)
		end
	end
	local home = (broken or thiefGreen) and bearingTo(homePosition())
	if home then
		if broken then
			StealAlert.setBearing(broken.arrow, home)
		end
		if thiefGreen then
			StealAlert.setBearing(thiefGreen.arrow, home)
		end
	end
end

-- ---------------------------------------------------------------- wiring

function StealAlert.start(ctx)
	local root = Hud.root()
	if not root then
		return
	end
	StealAlert.build(root)
	Prompts.wire()
	RunService.RenderStepped:Connect(update)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layout)
	local mine = Players.LocalPlayer.UserId
	task.spawn(function()
		local function listen(family, name, fn)
			task.spawn(function()
				local ok, r = pcall(Net.get, family, name)
				if ok then
					r.OnClientEvent:Connect(fn)
				end
			end)
		end
		listen("Steal", "Alert", StealAlert.showOwner)
		listen("Steal", "Result", function(p)
			if typeof(p) ~= "table" then
				return
			end
			local st = p.state
			if (st == "dropped" or st == "returned" or st == "success") and typeof(p.uid) == "string" then
				StealAlert.hideOwner(p.uid)
			elseif st == "refused" then
				Toasts.reason(p.reason)
			end
		end)
		listen("Shield", "Broken", StealAlert.showBroken)
		listen("Base", "State", function(p)
			if typeof(p) == "table" and p.ownerUserId == mine then
				myPlot = p.plotId
			end
		end)
		listen("Carry", "State", function(p)
			if typeof(p) ~= "table" then
				return
			end
			if p.state == "carrying" and p.stolenFrom ~= nil then
				if not thiefGreen then
					StealAlert.showThief({ creatureId = p.creatureId, level = p.level, bought = p.bought ~= nil and p.bought ~= false })
				end
			else
				StealAlert.hideThief()
			end
		end)
	end)
end

return StealAlert
