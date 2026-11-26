--!nonstrict
-- Ui/LockBoard: the owner's lock board buttons (M2-17; brief system 10 "The lock board", system 13 "Where things are offered"), plain function version.
-- The board itself is a world piece (the base layout's board beside the lock pad); its two buttons are drawn here as a small plate in the top-centre slot
-- (the same one the alerts use), shown while the owner stands at the board, so a tap works on a phone and nothing in the world has to be clickable
-- (TEAM CALL M2-17-1). Nothing here is sized in studs: it is HUD, not a world label.
--   LONG LOCK R$ 199      shown until the pass is owned.                       sends Shop.Buy { key = "pass_long_lock" }
--   INSTANT SHIELD R$ 19  shown only while the shield is down (ready or cooldown): hidden while it is up, joining or an Instant Shield.
--                                                                              sends Shop.Buy { key = "product_instant_shield" }
--   Both are hidden while a steal alert or a shield-broken alert is on (StealAlert.isOn), and the plate is hidden when neither shows.
--   LockBoard.show() / hide()           the controller calls these when the owner steps to / away from the board
--   LockBoard.setShield(state)          "up"|"cooldown"|"ready"|"joining"|"instant" (Shield.State for the own plot is wired in start)
--   LockBoard.setPasses(passes)         { pass_long_lock = bool, ... } (Shop.State.passes is wired in start)
--   LockBoard.visible() -> boolean      LockBoard.parts()
-- The price is Config.Shop.PRICES[key] once M2-18 fills it, else the brief's number from Skin.Names.ui.prices. The server decides everything
-- (a pass already owned, a shield up, a prompt already open are refused there; Shop.Grant / Profile.Notice answer).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local StealAlert = require(script.Parent.StealAlert)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)
local Config = require(Shared.Config)
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local LockBoard = { AUTO_START = true }
local MAX_W = 420
local frame = nil
local wanted = false
local shieldState = "ready"
local passes = {}
local sentAt = 0
local myPlot = nil

local function fill(text: string, v): string
	return (string.gsub(text, "{(%w+)}", function(k)
		return if v[k] ~= nil then tostring(v[k]) else nil
	end))
end

local function priceOf(key: string)
	local p = Config.Shop and Config.Shop.PRICES and Config.Shop.PRICES[key]
	return if type(p) == "number" then p else N.ui.prices[key]
end

-- which buttons the state asks for
local function wantedButtons()
	local list = {}
	if passes.pass_long_lock ~= true then
		table.insert(list, { key = "pass_long_lock", name = N.ui.lockBoard.longLock })
	end
	if shieldState == "ready" or shieldState == "cooldown" then
		table.insert(list, { key = "product_instant_shield", name = N.ui.lockBoard.instant })
	end
	return list
end

function LockBoard.visible(): boolean
	return wanted and not StealAlert.isOn() and #wantedButtons() > 0
end

function LockBoard.parts()
	return frame
end

local function destroyFrame()
	if frame then
		frame:Destroy()
		frame = nil
	end
end

local function render()
	destroyFrame()
	local root = Hud.root()
	if not (root and LockBoard.visible()) then
		return
	end
	local list = wantedButtons()
	local left, top, avail = StealAlert.slot()
	local w = math.min(MAX_W, avail)
	local th = math.max(U.buttonH, Kit.minDesign(U.touchMin))
	local titleH = if Kit.scale() >= 0.9 then 24 else 0 -- no title row on a small phone: the plate must stay under the Huss button
	local h = titleH + th + 8 + 8
	frame = Kit.Plate(root, { name = "LockBoard", fill = C.panelGrey, size = UDim2.fromOffset(w, h), position = UDim2.fromOffset(left + (avail - w) / 2, top) })
	frame.ZIndex = 41
	local title = Kit.Text(frame, { name = "Title", text = N.ui.lockBoard.title, size = TY.small, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(10, 2), sizeU = UDim2.new(1, -20, 0, 20) })
	title.ZIndex = 42
	title.Visible = titleH > 0
	local n = #list
	local gap = 8
	local bw = (w - 16 - gap * (n - 1)) / n
	for i, it in ipairs(list) do
		local b = Kit.Button(frame, {
			name = "Buy_" .. it.key,
			text = it.name .. "\n" .. fill(N.ui.prompts.robux, { n = priceOf(it.key) or "" }),
			fill = C.shopGold,
			ink = true,
			textSize = TY.small,
			size = UDim2.fromOffset(bw, th),
			position = UDim2.fromOffset(8 + (i - 1) * (bw + gap), titleH + 2 + (if titleH == 0 then 4 else 0)),
		})
		b.label.TextWrapped = true
		b.root.ZIndex = 42
		b.onActivated(function()
			if os.clock() - sentAt < 1 then
				return
			end
			sentAt = os.clock()
			task.spawn(function()
				local ok, r = pcall(Net.get, "Shop", "Buy")
				if ok then
					r:FireServer({ key = it.key })
				end
			end)
		end)
	end
end

LockBoard.refresh = render

function LockBoard.show()
	wanted = true
	render()
end

function LockBoard.hide()
	wanted = false
	render()
end

function LockBoard.setShield(state: string?)
	shieldState = state or "ready"
	render()
end

function LockBoard.setPasses(p)
	passes = if typeof(p) == "table" then p else {}
	render()
end

function LockBoard.destroy()
	destroyFrame()
	wanted = false
end

function LockBoard.start(ctx)
	StealAlert.onChange(render)
	Kit.onScale(render)
	local mine = Players.LocalPlayer.UserId
	local function listen(family, name, fn)
		task.spawn(function()
			local ok, r = pcall(Net.get, family, name)
			if ok then
				r.OnClientEvent:Connect(fn)
			end
		end)
	end
	listen("Base", "State", function(p)
		if typeof(p) == "table" and p.ownerUserId == mine then
			myPlot = p.plotId
		end
	end)
	listen("Shield", "State", function(p)
		if typeof(p) == "table" and p.plotId == myPlot then
			LockBoard.setShield(p.state)
		end
	end)
	listen("Shop", "State", function(p)
		if typeof(p) == "table" and typeof(p.passes) == "table" then
			LockBoard.setPasses(p.passes)
		end
	end)
end

return LockBoard
