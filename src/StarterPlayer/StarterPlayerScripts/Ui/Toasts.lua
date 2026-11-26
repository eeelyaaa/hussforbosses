--!nonstrict
-- Ui/Toasts: short messages top centre (M2-13; wording is B16, TEAM CALL M2-13-3).
--   Toasts.show(text, kind?)   kind "info" (white), "warn" (alarm orange), "good" (cash green)
--   Toasts.notice(kind, n?)    a Profile.Notice kind from Ids.NOTICES, text from Skin.Names.ui.notices
--   Toasts.reason(reason)      a refusal reason (Result.reason), text from Skin.Names.ui.reasons
-- Wired to Profile.Notice and to every failed Result of the screens' remotes (Bag, Boss, Base, Rebirth, Offline, Shield).
-- Not a decision-maker: the server's reason is only shown. At most 3 on screen, 2.6 s each, the oldest goes first.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local Skin = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skin"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local Toasts = { AUTO_START = true }
local holder = nil
local MAX, LIFE = 3, 2.6
local TOAST_W = 260

function Toasts.build(parent: Instance)
	if holder then
		holder:Destroy()
	end
	holder = Instance.new("Frame")
	holder.Name = "Toasts"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, 58)
	holder.Size = UDim2.fromOffset(TOAST_W, 100)
	holder.ZIndex = 60
	holder.Parent = parent
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.VerticalAlignment = Enum.VerticalAlignment.Top
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = holder
	return holder
end

function Toasts.instance()
	return holder
end

-- Top centre, in the counter row's height (below the real top bar); under the fight plate while a fight shows, and under the steal / shield-broken
-- alert (Ui/StealAlert, M2-17) while one is on, so a toast never covers it. Re-placed when the alert changes.
function Toasts.place()
	if not holder then
		return
	end
	local top = math.ceil((game:GetService("GuiService").TopbarInset.Max.Y + 10) / Kit.scale())
	local y = top + (if Hud.fightShowing() then 90 else 0)
	local ok, alert = pcall(function()
		local m = script.Parent:FindFirstChild("StealAlert")
		return m and require(m)
	end)
	local ai = ok and alert and alert.instance and alert.instance()
	local root = Hud.root()
	if ai and root and alert.isOn() and ai.AbsoluteSize.Y > 0 then
		local bottom = (ai.AbsolutePosition.Y + ai.AbsoluteSize.Y - root.AbsolutePosition.Y) / Kit.scale()
		y = math.max(y, math.ceil(bottom) + 6)
	end
	holder.Position = UDim2.new(0.5, 0, 0, y)
end

local order = 0
function Toasts.show(text: string, kind: string?)
	if not holder then
		return
	end
	Toasts.place()
	local children = {}
	for _, c in ipairs(holder:GetChildren()) do
		if c:IsA("Frame") then
			table.insert(children, c)
		end
	end
	table.sort(children, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #children >= MAX do
		table.remove(children, 1):Destroy()
	end
	local fill = (kind == "warn" and C.alarmOrange) or (kind == "good" and C.cashGreen) or C.white
	local dark = kind == "info" or kind == nil
	order += 1
	local plate = Kit.Plate(holder, { name = "Toast", fill = fill, size = UDim2.fromOffset(TOAST_W, 0), studs = false, outline = U.wellOutlinePx })
	plate.AutomaticSize = Enum.AutomaticSize.Y
	plate.LayoutOrder = order
	plate.ZIndex = 61
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	pad.Parent = plate
	local label = Kit.Text(plate, { name = "Text", text = text, size = TY.small, color = dark and C.ink or C.white, plain = dark, body = true, sizeU = UDim2.new(1, 0, 0, 0) })
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.ZIndex = 62
	Kit.popScale(plate, 1.06, 0.06, 0.1)
	task.delay(LIFE, function()
		if plate.Parent then
			Kit.tween(plate, { BackgroundTransparency = 1 }, 0.25)
			Kit.tween(label, { TextTransparency = 1 }, 0.25)
			task.delay(0.26, function()
				plate:Destroy()
			end)
		end
	end)
	return plate
end

function Toasts.notice(kind: string, n: number?)
	local text = N.ui.notices[kind]
	if not text then
		return
	end
	local warn = kind == "notSaving" or kind == "saveFailed" or kind == "promptBusy" or kind == "stealSafe"
	Toasts.show(Hud.fill(text, { n = n }), warn and "warn" or "info")
end

function Toasts.reason(reason: string?)
	Toasts.show(N.ui.reasons[reason or "generic"] or N.ui.reasons.generic, "warn")
end

function Toasts.start(ctx)
	local root = Hud.root()
	if not root then
		return
	end
	Toasts.build(root)
	local okA, alert = pcall(function()
		return require(script.Parent.StealAlert)
	end)
	if okA and alert and type(alert.onChange) == "function" then
		alert.onChange(function()
			task.defer(Toasts.place) -- after the alert has laid out
		end)
	end
	task.spawn(function()
		local function listen(family, name, fn)
			local ok, r = pcall(Net.get, family, name)
			if ok then
				r.OnClientEvent:Connect(fn)
			end
		end
		listen("Profile", "Notice", function(p)
			if typeof(p) == "table" and typeof(p.kind) == "string" then
				Toasts.notice(p.kind, if typeof(p.n) == "number" then p.n else nil)
			end
		end)
		for _, fam in ipairs({ { "Bag", "Result" }, { "Boss", "Result" }, { "Base", "Result" }, { "Offline", "Result" }, { "Shield", "Result" } }) do
			listen(fam[1], fam[2], function(p)
				if typeof(p) == "table" and p.ok == false then
					Toasts.reason(p.reason)
				end
			end)
		end
		listen("Rebirth", "Result", function(p)
			if typeof(p) ~= "table" then
				return
			end
			if p.ok then
				Toasts.show(Hud.fill(N.ui.rebirth.done, { n = p.rebirths or "" }), "good")
			else
				Toasts.reason(p.reason)
			end
		end)
	end)
end

return Toasts
