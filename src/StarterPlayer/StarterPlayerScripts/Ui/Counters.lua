--!nonstrict
-- Ui/Counters: the Power plate (Huss red) and the cash plate (cash green), top left (style guide 6, "Counter plates").
--   setPower(n)   setCash(n)   popPower(amount, big, fromPos?)   popCash(amount, fromScreen?)  (popCash: M1-14)
-- M1 prints full numbers with thousands separators; shortening (48.2K) is M2 (B16). The plates are studded, 32 px tall,
-- 3 px ink outline, icon 36 px overlapping the left edge by 8 px, number 18 px white with an ink outline, not pressable.
-- Icons are plain stand-ins while Skin.Icons.power / cash are 0 (M3 uploads).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Skin = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skin"))
local C, U, TY = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type

local Counters = {}
local S = nil

local CASH_PREFIX = "$"
local MIN_PLATE_W = 96

local function plate(parent: Instance, name: string, fill: Color3, iconKey: string, standIn: Color3)
	local f = Kit.Plate(parent, { name = name, fill = fill, size = UDim2.fromOffset(MIN_PLATE_W, U.counterH) })
	f.AutomaticSize = Enum.AutomaticSize.X
	local min = Instance.new("UISizeConstraint")
	min.MinSize = Vector2.new(MIN_PLATE_W, U.counterH)
	min.Parent = f
	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = f
	local value = Kit.Text(f, {
		name = "Value",
		text = "0",
		size = TY.button,
		align = Enum.TextXAlignment.Left,
		position = UDim2.fromOffset(U.counterIconPx - U.counterIconOverlapPx + 6, 0),
		sizeU = UDim2.fromOffset(0, U.counterH),
	})
	value.AutomaticSize = Enum.AutomaticSize.X
	value.ZIndex = 3
	local icon = Kit.Icon(f, iconKey, {
		name = "Icon",
		size = U.counterIconPx,
		position = UDim2.fromOffset(-U.counterIconOverlapPx, (U.counterH - U.counterIconPx) / 2),
		standIn = standIn,
	})
	icon.ZIndex = 4
	return f, value
end

function Counters.build(parent: Instance, position: UDim2?)
	Counters.destroy()
	S = { root = parent }
	local holder = Instance.new("Frame")
	holder.Name = "Counters"
	holder.BackgroundTransparency = 1
	holder.AutomaticSize = Enum.AutomaticSize.X
	holder.Size = UDim2.fromOffset(0, U.counterH + 4)
	holder.Position = position or UDim2.fromOffset(16, 48)
	holder.Parent = parent
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, 14)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = holder
	S.holder = holder

	S.powerPlate, S.powerValue = plate(holder, "PowerPlate", C.hussRed, "power", C.flashYellow)
	S.powerPlate.LayoutOrder = 1
	S.cashPlate, S.cashValue = plate(holder, "CashPlate", C.cashGreen, "cash", C.white)
	S.cashPlate.LayoutOrder = 2
	S.power, S.cash = 0, 0
	return holder
end

function Counters.destroy()
	if S then
		S.holder:Destroy()
		S = nil
	end
end

function Counters.instance()
	return S and S.holder
end

function Counters.parts()
	return S
end

function Counters.setPower(n: number)
	if not S then
		return
	end
	S.power = n
	S.powerValue.Text = Kit.commas(n)
end

function Counters.setCash(n: number)
	if not S then
		return
	end
	S.cash = n
	S.cashValue.Text = CASH_PREFIX .. Kit.commas(n)
end

-- keep a pop's start point (design px) out from under Roblox's top bar: its half height (15) plus 10 screen px below TopbarInset
local function clampBelowTopbar(root: GuiObject, from: Vector2): Vector2
	-- the root's origin is the screen's top (IgnoreGuiInset), so TopbarInset (screen px) / scale is design px here
	local minY = (game:GetService("GuiService").TopbarInset.Max.Y + 10) / Kit.scale() + 15
	return Vector2.new(from.X, math.max(from.Y, minY))
end

-- "+N" flies to the Power plate (0.35 s, Quad In) and the plate bumps; the third punch (big) is bigger.
-- fromPos: a Vector2 in design px relative to the root; default is below and right of the plate.
function Counters.popPower(amount: number, big: boolean?, fromPos: Vector2?)
	if not S then
		return
	end
	local root = S.root
	local target = Kit.toDesign(root, S.powerPlate)
	local from = clampBelowTopbar(root, fromPos or (target + Vector2.new(40, 90)))
	local label = Kit.Text(root, {
		name = "PowerPop",
		text = "+" .. Kit.commas(amount),
		size = big and 26 or TY.huss,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromOffset(from.X, from.Y),
		sizeU = UDim2.fromOffset(120, 30),
	})
	label.ZIndex = 20
	Kit.tween(label, { Position = UDim2.fromOffset(target.X, target.Y) }, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local plateRef = S.powerPlate
	task.delay(0.35, function()
		label:Destroy()
		if plateRef.Parent then
			Kit.popScale(plateRef, big and 1.2 or 1.1, 0.06, 0.1)
		end
	end)
end

-- "+$N" flies to the cash plate (0.35 s, Quad In) and the plate bumps. fromScreen: a Vector2 in screen px (the HUD ignores the
-- GuiInset, so viewport px); default is below and right of the plate. (M1-14)
function Counters.popCash(amount: number, fromScreen: Vector2?)
	if not S then
		return
	end
	local root = S.root
	local target = Kit.toDesign(root, S.cashPlate)
	local from = clampBelowTopbar(root, if fromScreen then (fromScreen - root.AbsolutePosition) / Kit.scale() else (target + Vector2.new(40, 90)))
	local label = Kit.Text(root, {
		name = "CashPop",
		text = "+" .. CASH_PREFIX .. Kit.commas(amount),
		size = TY.huss,
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromOffset(from.X, from.Y),
		sizeU = UDim2.fromOffset(140, 30),
	})
	label.ZIndex = 20
	Kit.tween(label, { Position = UDim2.fromOffset(target.X, target.Y) }, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local plateRef = S.cashPlate
	task.delay(0.35, function()
		label:Destroy()
		if plateRef.Parent then
			Kit.popScale(plateRef, 1.1, 0.06, 0.1)
		end
	end)
end

return Counters
