--!nonstrict
-- Ui/HussButton: the round Huss button, its timing ring and hit band, the impact star, the GOOD/PERFECT pop and the three pips.
-- A view: plain values in, nothing read from the network or the clock (m1-contract.md section I).
--   setMode("bag"|"fight"|"start"|"hidden")   setRing(progress|nil)   landed(grade)   missed()   pressed(bool)
--   landed("perfect") floats PERFECT up above the button (M2-08, manager P3); landed("good") keeps the small GOOD pop;
--   landed("untimed") is the small pop of a single untimed punch: a short star and a squash, no word (m2-contract B2).
--   pips(n)   clearPips()   onTap(fn)
-- Style guide 6, "The Huss button, timing ring and pips". The button is 120 design px, never under 96 px on screen
-- (the diameter grows when the scale is small). All sizes come from Tokens.ui.
--
-- How the ring is drawn (TEAM CALL, gui-designer): three transparent round Frames, each a UIStroke (strokes sit outside the
-- frame): ink (2 px, inner line), white (6 px, the ring), ink (2 px, outer line). setRing resizes the three; no image and no
-- rotation, so it is sharp at every scale. The white ring's OUTER edge is the ring's size: 1.6 x the button at progress 0,
-- Tokens.ui.ringLandScale x the button at progress 1 (centre of the hit band). The band is a round frame whose stroke is
-- bandThickPx thick, starting at the button's outline.
--
-- Taps fire on the touch or click going DOWN (the grade is judged at the tap, not the release): TEAM CALL.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Skin = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skin"))
local C, U, N, TY = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Names, Skin.Tokens.type

local HussButton = {}
local S = nil -- the one built instance

local ZERO = Vector2.new(0.5, 0.5)

local function round(parent: Instance, name: string, z: number): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = ZERO
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.BorderSizePixel = 0
	f.ZIndex = z
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = f
	f.Parent = parent
	return f
end

local function ringFrame(parent: Instance, name: string, color: Color3, thick: number, z: number)
	local f = round(parent, name, z)
	f.BackgroundTransparency = 1
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thick
	stroke.Parent = f
	return f, stroke
end

local function hussPx(): number
	return math.max(U.hussButtonPx, Kit.minDesign(U.hussButtonMinPx))
end

local function paintFace()
	local base = S.flash and C.flashYellow or C.hussRed
	if S.pressed then
		base = Kit.shade(base, U.pressedFill)
	end
	if S.spent then
		base = Kit.shade(base, U.spentFill)
	end
	S.label.TextTransparency = S.spent and U.spentTextAlpha or 0
	S.face.BackgroundColor3 = base
	S.lip.BackgroundColor3 = Kit.shade(base, U.lipFactor)
	S.face.Position = UDim2.new(0.5, 0, 0.5, S.pressed and U.pressedDropPx or 0)
end

local function drawRing()
	local mode = S.mode
	local live = mode == "bag" or mode == "fight"
	S.band.Visible = live
	local show = live and S.progress ~= nil
	S.ringIn.Visible, S.ringW.Visible, S.ringOut.Visible = show, show, show
	if not show then
		return
	end
	local p = math.clamp(S.progress, 0, 1)
	local sc = U.ringStartScale + (U.ringLandScale - U.ringStartScale) * p
	local outer = S.H * sc
	local white = outer - 2 * U.ringThickPx
	S.ringOut.Size = UDim2.fromOffset(outer, outer)
	S.ringW.Size = UDim2.fromOffset(white, white)
	S.ringIn.Size = UDim2.fromOffset(white - 2 * U.ringLineOutlinePx, white - 2 * U.ringLineOutlinePx)
	S.ringWStroke.Color = S.missed and C.disabledGrey or C.white
end

local function layout()
	local H = hussPx()
	S.H = H
	local D = math.ceil(H * U.ringStartScale) + 24
	S.holder.Size = UDim2.fromOffset(D, D)
	local faceD = H - 2 * U.hussOutlinePx
	S.face.Size = UDim2.fromOffset(faceD, faceD)
	S.lip.Size = UDim2.fromOffset(faceD, faceD)
	S.lip.Position = UDim2.new(0.5, 0, 0.5, U.hussLipPx)
	S.band.Size = UDim2.fromOffset(H, H)
	S.hit.Size = UDim2.fromOffset(H, H)
	local a = H
	S.starHolder.Size = UDim2.fromOffset(a, a)
	for _, f in ipairs({ S.starInkA, S.starInkB }) do
		f.Size = UDim2.fromOffset(a + 8, a + 8)
	end
	for _, f in ipairs({ S.starA, S.starB }) do
		f.Size = UDim2.fromOffset(a, a)
	end
	local bandTop = math.floor(H * U.bandOuter / 2) + 9
	S.pipFrame.Position = UDim2.new(0.5, 0, 0.5, -bandTop)
	S.floatBase = bandTop + U.pipPx + 4 -- where a floating grade word starts (just above the pips)
	S.popLabel.Position = UDim2.new(0.5, 0, 0.5, -S.floatBase)
	drawRing()
	paintFace()
end

local function paintPips(n: number)
	for i, cell in ipairs(S.pipCells) do
		local on = i <= n
		cell.frame.BackgroundColor3 = on and C.hussRed or C.pipEmpty
		cell.line.Visible = on
	end
end

local function applyMode()
	local mode = S.mode
	S.holder.Visible = mode ~= "hidden"
	local live = mode == "bag" or mode == "fight"
	S.pipFrame.Visible = live
	drawRing()
end

function HussButton.build(parent: Instance, position: UDim2?)
	HussButton.destroy()
	S = {
		mode = "bag",
		progress = nil,
		lastP = nil,
		missed = false,
		pressed = false,
		flash = false,
		pipN = 0,
		pipGen = 0,
		flashGen = 0,
		popGen = 0,
		taps = {},
		conns = {},
		H = U.hussButtonPx,
	}

	local holder = Instance.new("Frame")
	holder.Name = "HussButton"
	holder.AnchorPoint = ZERO
	holder.Position = position or UDim2.new(1, -184, 1, -142)
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	S.holder = holder

	-- impact star (behind everything): two ink squares and two flash-yellow squares, one turned 45 degrees = 8 points
	local starHolder = round(holder, "Star", 1)
	starHolder.BackgroundTransparency = 1
	starHolder.Visible = false
	starHolder:FindFirstChildOfClass("UICorner"):Destroy()
	local function square(name: string, color: Color3, rot: number, z: number)
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = ZERO
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.BackgroundColor3 = color
		f.BorderSizePixel = 0
		f.Rotation = rot
		f.ZIndex = z
		f.Parent = starHolder
		return f
	end
	S.starHolder = starHolder
	S.starInkA = square("InkA", C.ink, 0, 1)
	S.starInkB = square("InkB", C.ink, 45, 1)
	S.starA = square("YellowA", C.flashYellow, 0, 2)
	S.starB = square("YellowB", C.flashYellow, 45, 2)

	-- ring: ink, white, ink (outside strokes); drawn by setRing
	S.ringOut = ringFrame(holder, "RingInkOuter", C.ink, U.ringLineOutlinePx, 2)
	S.ringW, S.ringWStroke = ringFrame(holder, "Ring", C.white, U.ringThickPx, 2)
	S.ringIn = ringFrame(holder, "RingInkInner", C.ink, U.ringLineOutlinePx, 2)
	S.ringOut.Visible, S.ringW.Visible, S.ringIn.Visible = false, false, false

	-- hit band
	S.band = ringFrame(holder, "HitBand", C.flashYellow, U.bandThickPx, 3)

	-- button: lip, face, label
	local lip = round(holder, "Lip", 4)
	lip.BackgroundColor3 = Kit.shade(C.hussRed, U.lipFactor)
	local ls = Instance.new("UIStroke")
	ls.Color = C.ink
	ls.Thickness = U.hussOutlinePx
	ls.Parent = lip
	S.lip = lip

	local face = round(holder, "Face", 5)
	face.BackgroundColor3 = C.hussRed
	local fs = Instance.new("UIStroke")
	fs.Color = C.ink
	fs.Thickness = U.hussOutlinePx
	fs.Parent = face
	S.face = face
	Kit.StudTile(face, 0.5)

	S.label = Kit.Text(face, { name = "Label", text = N.hudWords.huss, size = TY.huss })
	S.label.ZIndex = 6

	-- hit area (a plain TextButton; the press is read from the input going down)
	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.AnchorPoint = ZERO
	hit.Position = UDim2.fromScale(0.5, 0.5)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.ZIndex = 7
	hit.Parent = holder
	S.hit = hit
	table.insert(S.conns, hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			HussButton.pressed(true)
			for _, fn in ipairs(S.taps) do
				task.spawn(fn)
			end
		end
	end))
	table.insert(S.conns, hit.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			HussButton.pressed(false)
		end
	end))

	-- pips, centred above the band
	local pipFrame = Instance.new("Frame")
	pipFrame.Name = "Pips"
	pipFrame.AnchorPoint = Vector2.new(0.5, 1)
	pipFrame.BackgroundTransparency = 1
	pipFrame.Size = UDim2.fromOffset(3 * U.pipPx + 2 * U.pipGap, U.pipPx)
	pipFrame.ZIndex = 8
	pipFrame.Parent = holder
	S.pipFrame = pipFrame
	S.pipCells = {}
	for i = 1, 3 do
		local cell = Instance.new("Frame")
		cell.Name = "Pip" .. i
		cell.BorderSizePixel = 0
		cell.BackgroundColor3 = C.pipEmpty
		cell.Size = UDim2.fromOffset(U.pipPx, U.pipPx)
		cell.Position = UDim2.fromOffset((i - 1) * (U.pipPx + U.pipGap), 0)
		cell.ZIndex = 8
		local st = Instance.new("UIStroke")
		st.Color = C.ink
		st.Thickness = U.pipOutlinePx
		st.Parent = cell
		local line = Instance.new("Frame")
		line.Name = "TopLine"
		line.BorderSizePixel = 0
		line.BackgroundColor3 = Kit.lighten(C.hussRed, U.topLineLighten)
		line.Size = UDim2.new(1, 0, 0, 2)
		line.ZIndex = 9
		line.Visible = false
		line.Parent = cell
		cell.Parent = pipFrame
		S.pipCells[i] = { frame = cell, line = line }
	end

	-- GOOD / PERFECT pop (above the pips)
	local pop = Kit.Text(holder, { name = "GradePop", text = "", size = TY.huss, sizeU = UDim2.fromOffset(160, 26), anchor = Vector2.new(0.5, 1) })
	pop.ZIndex = 9
	pop.Visible = false
	S.popLabel = pop

	S.scaleConn = Kit.onScale(function()
		if S then
			layout()
		end
	end)
	layout()
	applyMode()
	return holder
end

function HussButton.destroy()
	if not S then
		return
	end
	for _, c in ipairs(S.conns) do
		c:Disconnect()
	end
	if S.scaleConn then
		S.scaleConn.Disconnect()
	end
	S.holder:Destroy()
	S = nil
end

function HussButton.instance()
	return S and S.holder
end

-- The button's diameter in design px right now (120, or more when the scale is small).
function HussButton.diameter(): number?
	return S and S.H
end

function HussButton.parts()
	return S
end

function HussButton.setMode(mode: string)
	if not S then
		return
	end
	assert(mode == "bag" or mode == "fight" or mode == "start" or mode == "hidden", "HussButton.setMode: " .. tostring(mode))
	S.mode = mode
	applyMode()
end

function HussButton.setRing(progress: number?)
	if not S then
		return
	end
	if S.missed and (progress == nil or (S.lastP ~= nil and progress < S.lastP)) then
		S.missed = false
	end
	S.lastP = progress
	S.progress = progress
	drawRing()
end

-- Dim the button while the ring is spent (after an untimed tap, until the next ring opens). Taps still fire.
function HussButton.setSpent(on: boolean)
	if not S then
		return
	end
	S.spent = on == true
	paintFace()
end

function HussButton.pressed(down: boolean)
	if not S then
		return
	end
	S.pressed = down
	paintFace()
end

-- PERFECT floats up above the button: pops in at 1.35x, rises U.perfectRisePx design px (drifting U.perfectDriftPx to the right, clear of the fight plate on a small phone) over U.perfectFloatS, and fades out over the
-- last part. Each one is its own label, so a second Perfect inside the first one's float does not cut it short.
local function floatPerfect()
	local lbl = Kit.Text(S.holder, {
		name = "PerfectFloat",
		text = N.grades.perfect,
		size = TY.title,
		color = C.flashYellow,
		sizeU = UDim2.fromOffset(220, 30),
		anchor = Vector2.new(0.5, 1),
		position = UDim2.new(0.5, 0, 0.5, -S.floatBase),
	})
	lbl.ZIndex = 10
	local outline = lbl:FindFirstChild("Outline")
	Kit.popScale(lbl, U.perfectPopScale, 0.08, 0.1)
	local T = U.perfectFloatS
	Kit.tween(lbl, { Position = UDim2.new(0.5, U.perfectDriftPx, 0.5, -(S.floatBase + U.perfectRisePx)) }, T, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay(T * U.perfectFadeFrom, function()
		if lbl.Parent then
			local fade = T * (1 - U.perfectFadeFrom)
			Kit.tween(lbl, { TextTransparency = 1 }, fade, Enum.EasingStyle.Linear)
			if outline then
				Kit.tween(outline, { Transparency = 1 }, fade, Enum.EasingStyle.Linear)
			end
		end
	end)
	task.delay(T + 0.05, function()
		if lbl.Parent then
			lbl:Destroy()
		end
	end)
	return lbl
end

function HussButton.landed(grade: string)
	if not S then
		return
	end
	local untimed = grade == "untimed"
	-- the button flashes flash-yellow for 0.08 s (an untimed single does not: it is the small one)
	if not untimed then
		S.flashGen += 1
		local gen = S.flashGen
		S.flash = true
		paintFace()
		task.delay(0.08, function()
			if S and S.flashGen == gen then
				S.flash = false
				paintFace()
			end
		end)
	end
	-- the 8-point star pops behind the button (bigger on the third punch: the controller passes grade only, so the pips decide;
	-- smaller still for an untimed single)
	local big = S.pipN >= 3
	local sc = S.starHolder:FindFirstChild("Pop")
	if not sc then
		sc = Instance.new("UIScale")
		sc.Name = "Pop"
		sc.Parent = S.starHolder
	end
	S.starHolder.Visible = true
	sc.Scale = untimed and 0.4 or 0.5
	Kit.tween(sc, { Scale = untimed and U.untimedStarScale or (big and 1.5 or 1.15) }, untimed and 0.1 or 0.12)
	S.popGen += 1
	local pg = S.popGen
	if untimed then
		Kit.popScale(S.face, U.untimedPopScale, 0.05, 0.08)
		S.popLabel.Visible = false
	elseif grade == "perfect" then
		S.popLabel.Visible = false
		floatPerfect()
	else
		S.popLabel.Text = N.grades[grade] or string.upper(grade)
		S.popLabel.TextColor3 = C.white
		S.popLabel.Visible = true
		Kit.popScale(S.popLabel, 1.2, 0.08, 0.1)
	end
	task.delay(untimed and 0.2 or 0.3, function()
		if S and S.popGen == pg then
			S.starHolder.Visible = false
		end
	end)
	task.delay(0.5, function()
		if S and S.popGen == pg then
			S.popLabel.Visible = false
		end
	end)
end

function HussButton.missed()
	if not S then
		return
	end
	S.missed = true
	drawRing()
	Kit.shake(S.face, 6, 2)
end

function HussButton.pips(n: number)
	if not S then
		return
	end
	n = math.clamp(math.floor(n or 0), 0, 3)
	S.pipGen += 1 -- a new fill cancels a pending clear
	paintPips(n)
	for i = S.pipN + 1, n do
		Kit.popScale(S.pipCells[i].frame, i == 3 and U.pipBigPopScale or U.pipPopScale, 0.08, 0.1)
	end
	S.pipN = n
end

-- All three flash flash-yellow, then clear 0.15 s later (the controller calls this after the third punch).
function HussButton.clearPips()
	if not S or S.pipN == 0 then
		return
	end
	S.pipGen += 1
	local gen = S.pipGen
	for _, cell in ipairs(S.pipCells) do
		cell.frame.BackgroundColor3 = C.flashYellow
		cell.line.Visible = false
	end
	task.delay(0.15, function()
		if S and S.pipGen == gen then
			S.pipN = 0
			paintPips(0)
		end
	end)
end

function HussButton.onTap(fn)
	if S then
		table.insert(S.taps, fn)
	end
end

return HussButton
