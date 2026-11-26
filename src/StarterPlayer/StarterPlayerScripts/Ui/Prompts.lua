--!nonstrict
-- Ui/Prompts: the Place, Grab and start-a-fight prompts (style guide 6, screen 12: a white studded plate with the input glyph on a
-- small ink plate, and the word). Screen-space at M1, bottom centre; the world-space versions (BillboardGui on the object) are M2/M3.
--   show(kind: "place"|"grab"|"start", glyphKind: "keyboard"|"gamepad"|"touch")   hide(kind)   onPress(kind, fn)
-- Glyph by input in use (docs/controls.md): keyboard E (start: F), gamepad X (start: RT), touch: no glyph, the plate itself is the
-- on-screen prompt button. The plate is at least 44 px tall on screen. The word comes from Skin.Names.hudWords.
-- M2-17 (wave B), same plate family, kinds "steal" and "breakShield" (brief systems 10 and 13; ui-kit/phone-prompt-steal-hold.png, phone-prompt-break-shield.png):
--   Prompts.showSteal({ locked = bool, holdS = number, quickHandsOwned = bool, glyphKind = "keyboard"|"gamepad"|"touch" })   Prompts.hideSteal()
--       "HOLD TO STEAL" with the hold line and (until owned) the gold Quick Hands R$ button; locked = the greyed padlock plate "CAN'T BE STOLEN"
--       (no reason is shown, brief system 10 policy guard; the plate is disabled, a tap shakes it). The hold itself is M2-16's: it reads
--       Prompts.parts().kinds.steal.button.face (InputBegan / InputEnded) or Prompts.onPress("steal", fn) for the press.
--   Prompts.showBreak(plotId, ownerName)   Prompts.hideBreak()   Prompts.setShieldInfo(plotId, shieldStateTable)   Prompts.setCharges(n)
--       the gold "BREAK SHIELD R$ 39" button under "<NAME>'S SHIELD 0:37"; greyed with the reason (Just joined / Instant Shield / Broken recently, 3:20 /
--       Shield is down) from Shield.State. A press sends Shield.UseCharge when a charge is held, else Shield.BuyBreaker (server checks again).
--   Prompts.activate(kind)   fires a kind's press callbacks (keyboard E / gamepad X routed by a controller); a disabled plate does nothing.
--   Prompts.wire()           once, in play: Shield.State, Profile.Changed (breakerCharges), Shop.State (Quick Hands owned), the 0.25 s countdown.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Skin = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skin"))
local C, U, N, TY = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Names, Skin.Tokens.type

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Prompts = {}
local S = nil
local shields = {} -- plotId -> the last Shield.State payload
local charges, quickHandsOwned = 0, false
local wired = false
local breakInfo = nil -- { plotId, ownerName } while the break prompt is wanted
local stealOpts = nil

-- key letters are controls, not skin names (docs/controls.md)
local GLYPH = {
	place = { keyboard = "E", gamepad = "X" },
	grab = { keyboard = "E", gamepad = "X" },
	start = { keyboard = "F", gamepad = "RT" },
	steal = { keyboard = "E", gamepad = "X" },
	breakShield = { keyboard = "E", gamepad = "X" },
}
local WORD = { place = "place", grab = "grab", start = "huss" }
local ORDER = { place = 1, grab = 2, start = 3, steal = 4, breakShield = 8 }
local PLATE_W = 190
local WIDTH = { steal = 250, breakShield = 300 } -- wider kinds; every other kind is PLATE_W
local HOLDER_W = 300
local function widthOf(kind: string): number
	return WIDTH[kind] or PLATE_W
end
local function fill(text: string, v: { [string]: any }): string
	return (string.gsub(text, "{(%w+)}", function(k)
		return if v[k] ~= nil then tostring(v[k]) else nil
	end))
end
local function priceOf(key: string): number?
	local p = Config.Shop and Config.Shop.PRICES and Config.Shop.PRICES[key]
	return if type(p) == "number" then p else N.ui.prices[key]
end
local function mmss(sec: number): string
	sec = math.max(0, math.ceil(sec))
	return string.format("%d:%02d", sec // 60, sec % 60)
end
local Clock = nil
local function now(): number
	if Clock == nil then
		local ok, m = pcall(function()
			return require(script.Parent.Parent.Controllers.Clock)
		end)
		Clock = if ok then m else false
	end
	return if Clock then Clock.now() else workspace:GetServerTimeNow()
end
local function send(family: string, name: string, payload)
	task.spawn(function()
		local ok, r = pcall(Net.get, family, name)
		if ok then
			r:FireServer(payload)
		end
	end)
end
local GLYPH_PLATE = 32

function Prompts.build(parent: Instance)
	Prompts.destroy()
	S = { kinds = {}, callbacks = { place = {}, grab = {}, start = {}, steal = {}, breakShield = {} } }
	local holder = Instance.new("Frame")
	holder.Name = "Prompts"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, -72)
	holder.Size = UDim2.fromOffset(HOLDER_W, 130)
	holder.Parent = parent
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, U.gap + U.lipPx)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = holder
	S.holder = holder

	for kind in pairs(ORDER) do
		local h = math.max(U.buttonH - 4, Kit.minDesign(U.touchMin))
		local word = if WORD[kind] then string.upper(N.hudWords[WORD[kind]]) else (if kind == "steal" then N.ui.prompts.steal else N.ui.prompts.breakShield)
		local isBreak = kind == "breakShield"
		local b = Kit.Button(holder, { name = "Prompt_" .. kind, text = word, fill = if isBreak then C.shopGold else C.white, ink = true, textSize = TY.button, size = UDim2.fromOffset(widthOf(kind), h) })
		b.root.LayoutOrder = ORDER[kind]
		b.root.Visible = false
		-- glyph plate (ink square with the key letter); hidden on touch
		local gp = Kit.Plate(b.face, { name = "Glyph", fill = C.ink, size = UDim2.fromOffset(GLYPH_PLATE, GLYPH_PLATE), position = UDim2.new(0, 8, 0.5, 0), anchor = Vector2.new(0, 0.5), outline = U.wellOutlinePx, studs = false })
		gp.ZIndex = 5
		local gl = Kit.Text(gp, { name = "Letter", text = "", size = TY.button })
		gl.ZIndex = 6
		b.onActivated(function()
			for _, fn in ipairs(S.callbacks[kind]) do
				task.spawn(fn)
			end
		end)
		S.kinds[kind] = { kind = kind, button = b, glyphPlate = gp, glyphLabel = gl }
	end
	Prompts._buildWaveB(holder)
	task.defer(Prompts._place) -- the Huss button is built after the layout scale first runs: place again once it exists

	S.scaleConn = Kit.onScale(function()
		if not S then
			return
		end
		for _, k in pairs(S.kinds) do
			local kind = k.kind
			k.button.root.Size = UDim2.fromOffset(widthOf(kind), math.max(U.buttonH - 4, Kit.minDesign(U.touchMin)))
		end
		Prompts._layoutWaveB()
		Prompts._place()
	end)
	return holder
end

-- Keep the holder's content clear of the Huss button: centred on the screen, or pushed left until its right edge is 8 design px short of the button.
function Prompts._place()
	if not S then
		return
	end
	local holder = S.holder
	local root = holder.Parent
	if not (holder and root and root:IsA("GuiObject")) then
		return -- destroyed, or the HUD is mid-rebuild
	end
	local ok, hb = pcall(function()
		return require(script.Parent.HussButton).instance()
	end)
	local s = Kit.scale()
	local rootW = root.AbsoluteSize.X / s
	local cx = rootW / 2
	if ok and hb and hb.Parent and hb.Visible then
		local hussLeft = (hb.AbsolutePosition.X - root.AbsolutePosition.X) / s
		cx = math.min(cx, hussLeft - 8 - HOLDER_W / 2)
	end
	holder.Position = UDim2.new(0, cx, 1, -72)
end

function Prompts.destroy()
	if S then
		if S.scaleConn then
			S.scaleConn.Disconnect()
		end
		S.holder:Destroy()
		S = nil
	end
end

function Prompts.instance()
	return S and S.holder
end

function Prompts.parts()
	return S
end

function Prompts.show(kind: string, glyphKind: string)
	if not S then
		return
	end
	local k = S.kinds[kind]
	assert(k, "Prompts.show: unknown kind " .. tostring(kind))
	local glyph = GLYPH[kind][glyphKind]
	k.glyphPlate.Visible = glyph ~= nil
	k.glyphLabel.Text = glyph or ""
	k.button.label.Position = UDim2.fromOffset(glyph and (GLYPH_PLATE + 8) or 0, 0)
	k.button.label.Size = UDim2.new(1, glyph and -(GLYPH_PLATE + 8) or 0, 1, 0)
	k.glyphKind = glyphKind
	k.button.root.Visible = true
end

function Prompts.hide(kind: string)
	if not S then
		return
	end
	local k = S.kinds[kind]
	if k then
		k.button.root.Visible = false
		if kind == "steal" and S.stealInfo then
			S.stealInfo.Visible = false
		elseif kind == "breakShield" and S.breakCaption then
			S.breakCaption.Visible = false
		end
	end
end

function Prompts.onPress(kind: string, fn)
	if S and S.callbacks[kind] then
		table.insert(S.callbacks[kind], fn)
	end
end

-- ---------------------------------------------------------------- wave B (M2-17): steal prompt, break shield

local function btnH(): number
	return math.max(U.buttonH - 4, Kit.minDesign(U.touchMin))
end

local function cfgS(table_: string, key: string, default: number): number
	local t = (Config :: any)[table_]
	local v = t and t[key]
	return if type(v) == "number" then v else default
end

-- the pieces under / over the plates: the steal prompt's info card (hold line + gold Quick Hands button) and the break prompt's caption
function Prompts._buildWaveB(holder: Frame)
	local card = Kit.Plate(holder, { name = "StealInfo", fill = C.white, size = UDim2.fromOffset(HOLDER_W - 20, 52), studs = false, outline = U.wellOutlinePx })
	card.LayoutOrder = ORDER.steal + 1
	card.Visible = false
	local line = Kit.Text(card, { name = "HoldLine", text = "", size = TY.small, color = C.ink, plain = true, body = true, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(8, 0), sizeU = UDim2.new(0, 140, 1, 0) })
	line.TextWrapped = true
	line.ZIndex = 3
	local qh = Kit.Button(card, { name = "QuickHands", text = "", fill = C.shopGold, ink = true, textSize = TY.button, size = UDim2.fromOffset(130, 40), position = UDim2.new(1, -6, 0.5, -2), anchor = Vector2.new(1, 0.5) })
	qh.root.ZIndex = 3
	qh.onActivated(function()
		send("Shop", "Buy", { key = "pass_quick_hands" })
	end)
	local cap = Kit.Text(holder, { name = "BreakCaption", text = "", size = TY.name, sizeU = UDim2.fromOffset(HOLDER_W - 20, 24) })
	cap.LayoutOrder = ORDER.breakShield - 1
	cap.Visible = false
	-- a padlock for the locked steal plate: a body and a shackle, built from frames (the icon id is 0 until M3)
	local gp = S.kinds.steal.glyphPlate
	local lock = Instance.new("Frame")
	lock.Name = "Padlock"
	lock.BackgroundTransparency = 1
	lock.Size = UDim2.fromScale(1, 1)
	lock.ZIndex = 6
	lock.Visible = false
	lock.Parent = gp
	local shackle = Instance.new("Frame")
	shackle.Name = "Shackle"
	shackle.BackgroundTransparency = 1
	shackle.Size = UDim2.fromOffset(12, 12)
	shackle.Position = UDim2.new(0.5, -6, 0, 4)
	shackle.ZIndex = 6
	shackle.Parent = lock
	local ss = Instance.new("UIStroke")
	ss.Color = C.white
	ss.Thickness = 3
	ss.Parent = shackle
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 5)
	sc.Parent = shackle
	local body = Instance.new("Frame")
	body.Name = "LockBody"
	body.BackgroundColor3 = C.white
	body.BorderSizePixel = 0
	body.Size = UDim2.fromOffset(18, 12)
	body.Position = UDim2.new(0.5, -9, 0, 14)
	body.ZIndex = 7
	body.Parent = lock
	S.stealInfo, S.holdLine, S.quickHands, S.breakCaption, S.padlock = card, line, qh, cap, lock
	S.callbacks.breakShield = {
		function()
			local info = breakInfo
			local st = info and shields[info.plotId]
			if not (info and st and st.breakable) then
				return
			end
			if S.breakSent and os.clock() - S.breakSent < 1 then
				return
			end
			S.breakSent = os.clock()
			send("Shield", if charges >= 1 then "UseCharge" else "BuyBreaker", { plotId = info.plotId })
		end,
	}
	Prompts._layoutWaveB()
end

function Prompts._layoutWaveB()
	if not (S and S.stealInfo) then
		return
	end
	local h = math.max(U.buttonH - 8, Kit.minDesign(U.touchMin))
	S.stealInfo.Size = UDim2.fromOffset(widthOf("steal") + 40, h + 12)
	S.quickHands.root.Size = UDim2.fromOffset(120, h)
end

local function fmtS(v: number): string
	return string.format("%.1f", v)
end

-- opts: locked, holdS (the hold with the player's own passes), quickS (the Quick Hands hold), quickHandsOwned, glyphKind
function Prompts.showSteal(opts)
	if not S then
		return
	end
	opts = opts or {}
	stealOpts = opts
	local k = S.kinds.steal
	local locked = opts.locked == true
	k.button.setEnabled(not locked)
	k.button.setText(if locked then N.ui.prompts.locked else N.ui.prompts.steal)
	k.glyphKind = opts.glyphKind or "touch"
	local glyph = if locked then nil else GLYPH.steal[k.glyphKind]
	k.glyphLabel.Text = glyph or ""
	k.glyphPlate.Visible = locked or glyph ~= nil
	S.padlock.Visible = locked
	k.glyphLabel.Visible = not locked
	local hasGlyph = locked or glyph ~= nil
	k.button.label.Position = UDim2.fromOffset(hasGlyph and (GLYPH_PLATE + 8) or 0, 0)
	k.button.label.Size = UDim2.new(1, hasGlyph and -(GLYPH_PLATE + 8) or 0, 1, 0)
	k.button.root.Visible = true
	Prompts._place()
	-- the info line: shown on a live prompt, with the Quick Hands offer until the pass is owned. The locked plate shows nothing else.
	local owned = if opts.quickHandsOwned ~= nil then opts.quickHandsOwned else quickHandsOwned
	local holdS = opts.holdS or cfgS("Steal", "HOLD_S", 2)
	local quickS = opts.quickS or cfgS("Steal", "QUICK_HANDS_S", 1)
	if locked then
		S.stealInfo.Visible = false
		return
	end
	if owned then
		S.holdLine.Text = fill(N.ui.prompts.hold, { s = fmtS(holdS) })
		S.quickHands.root.Visible = false
	else
		S.holdLine.Text = fill(N.ui.prompts.hold, { s = fmtS(holdS) }) .. "\n" .. fill(N.ui.prompts.quickHands, { s = fmtS(quickS) })
		S.quickHands.root.Visible = true
		S.quickHands.setText(fill(N.ui.prompts.robux, { n = priceOf("pass_quick_hands") or "" }))
	end
	S.holdLine.Size = UDim2.new(0, owned and (widthOf("steal") + 40 - 16) or 140, 1, 0)
	S.stealInfo.Visible = true
end

function Prompts.hideSteal()
	stealOpts = nil
	if S then
		S.kinds.steal.button.root.Visible = false
		S.stealInfo.Visible = false
	end
end

local function renderBreak()
	if not (S and breakInfo and S.kinds.breakShield.button.root.Visible) then
		return
	end
	local k = S.kinds.breakShield
	local st = shields[breakInfo.plotId]
	local t = now()
	local left = nil
	if st and (st.state == "up" or st.state == "joining" or st.state == "instant") and st.endsAt then
		left = st.endsAt - t
	end
	local cap = string.upper(fill(N.ui.prompts.shieldOf, { name = breakInfo.ownerName }))
	if left and left > 0 then
		cap ..= "  " .. mmss(left)
	end
	S.breakCaption.Text = cap
	S.breakCaption.Visible = true
	local breakable = st ~= nil and st.breakable == true
	k.button.setEnabled(breakable)
	local label
	if breakable then
		label = if charges >= 1 then fill(N.ui.prompts.breakFree, { n = charges }) else (N.ui.prompts.breakShield .. " " .. fill(N.ui.prompts.robux, { n = priceOf("product_shield_breaker") or "" }))
	else
		local reason = st and st.reason
		if reason == "joining" then
			label = N.ui.prompts.reasonJoining
		elseif reason == "instant" then
			label = N.ui.prompts.reasonInstant
		elseif reason == "recent" then
			label = fill(N.ui.prompts.reasonRecent, { t = mmss(((st and st.brokenUntil) or t) - t) })
		else
			label = N.ui.prompts.reasonDown
		end
	end
	k.button.setText(label)
end
Prompts.renderBreak = renderBreak

function Prompts.showBreak(plotId: number, ownerName: string, glyphKind: string?)
	if not S then
		return
	end
	breakInfo = { plotId = plotId, ownerName = ownerName }
	local k = S.kinds.breakShield
	local gk = glyphKind or k.glyphKind or "touch"
	Prompts.show("breakShield", gk)
	Prompts._place()
	renderBreak()
end

function Prompts.hideBreak()
	breakInfo = nil
	if S then
		S.kinds.breakShield.button.root.Visible = false
		S.breakCaption.Visible = false
	end
end

function Prompts.setShieldInfo(plotId: number, st)
	shields[plotId] = st
	renderBreak()
end

function Prompts.setCharges(n: number)
	charges = n
	renderBreak()
end

function Prompts.activate(kind: string)
	local k = S and S.kinds[kind]
	if not (k and k.button.enabled and k.button.root.Visible) then
		return
	end
	for _, fn in ipairs(S.callbacks[kind]) do
		task.spawn(fn)
	end
end

-- Remote wiring, once, in play only (the edit-mode checks drive the setters above).
function Prompts.wire()
	if wired then
		return
	end
	wired = true
	local function listen(family: string, name: string, fn)
		task.spawn(function()
			local ok, r = pcall(Net.get, family, name)
			if ok then
				r.OnClientEvent:Connect(fn)
			end
		end)
	end
	listen("Shield", "State", function(p)
		if typeof(p) == "table" and typeof(p.plotId) == "number" then
			Prompts.setShieldInfo(p.plotId, p)
		end
	end)
	listen("Profile", "Changed", function(p)
		if typeof(p) == "table" and typeof(p.breakerCharges) == "number" then
			Prompts.setCharges(p.breakerCharges)
		end
	end)
	listen("Shop", "State", function(p)
		if typeof(p) == "table" and typeof(p.passes) == "table" then
			quickHandsOwned = p.passes.pass_quick_hands == true
			if stealOpts and S then
				stealOpts.quickHandsOwned = nil
				Prompts.showSteal(stealOpts)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			renderBreak()
		end
	end)
end

return Prompts
