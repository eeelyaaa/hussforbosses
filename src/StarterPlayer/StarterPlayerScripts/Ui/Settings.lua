--!nonstrict
-- Ui/Settings: music and effects volume (brief controls: the gear tile or M; ui-kit/phone-settings.png), plain function version (M2-13).
--   Settings.open() / close() / toggle() / isOpen()      Settings.values() -> { music, effects } (0..1, the server's saved ones)
-- Each row: a slider (drag), "-" and "+" (steps of 0.1, for the gamepad and for fine taps), and the percentage. Changes go to
-- Profile.Settings { music, effects } 0.5 s after the last change (the server's rate is 2 a second) and when the panel closes.
-- The server rounds to 0.05 and keeps the number; the mix that uses the numbers is M4 (TEAM CALL M2-01-7).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)
local Hud = require(script.Parent.Hud)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)
local C, U, TY, N = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Tokens.type, Skin.Names

local Settings = { AUTO_START = true }
local modal, tile = nil, nil
local vals = { music = 1, effects = 1 }
local dirty, sendToken, dragging = false, 0, false

local function snap(v: number): number
	return math.floor(math.clamp(v, 0, 1) / 0.05 + 0.5) * 0.05
end

local function flush()
	if not dirty then
		return
	end
	dirty = false
	local payload = { music = snap(vals.music), effects = snap(vals.effects) }
	task.spawn(function()
		local ok, r = pcall(Net.get, "Profile", "Settings")
		if ok then
			r:FireServer(payload)
		end
	end)
end

local function schedule()
	dirty = true
	sendToken += 1
	local my = sendToken
	task.delay(0.5, function()
		if my == sendToken then
			flush()
		end
	end)
end

local function slider(body: Frame, y: number, h: number, key: string, iconKey: string, label: string)
	local r = Kit.Plate(body, { name = "Row_" .. key, fill = C.white, size = UDim2.new(1, 0, 0, h), position = UDim2.fromOffset(0, y), studs = false, outline = U.wellOutlinePx })
	r.ZIndex = 3
	local icon = Kit.Icon(r, iconKey, { size = 36, position = UDim2.new(0, 10, 0.5, 0), anchor = Vector2.new(0, 0.5), standIn = C.plateBlue })
	icon.ZIndex = 4
	local t = Kit.Text(r, { text = label, size = TY.name, color = C.ink, plain = true, align = Enum.TextXAlignment.Left, position = UDim2.fromOffset(54, 0), sizeU = UDim2.fromOffset(100, h) })
	t.ZIndex = 4
	local pct = Kit.Text(r, { name = "Percent", text = "", size = TY.name, color = C.ink, plain = true, align = Enum.TextXAlignment.Right, position = UDim2.new(1, -10, 0, 0), anchor = Vector2.new(1, 0), sizeU = UDim2.fromOffset(60, h) })
	pct.ZIndex = 4
	local bw = math.max(36, Kit.minDesign(U.touchMin))
	local function step(label2, x, anchorX, dv)
		local b = Kit.Button(r, { name = "Step", text = label2, fill = C.white, ink = true, textSize = TY.button, size = UDim2.fromOffset(bw, bw), position = UDim2.new(x, anchorX, 0.5, -bw / 2 - 2) })
		b.root.ZIndex = 4
		b.onActivated(function()
			vals[key] = snap(vals[key] + dv)
			schedule()
			modal.refresh()
		end)
		return b
	end
	local left = 160
	local minus = step(N.ui.settings.less, 0, left, -0.1)
	local plus = step(N.ui.settings.more, 1, -(10 + 60 + bw + 6), 0.1)
	local trackX0, trackX1 = left + bw + 8, 10 + 60 + bw + 6 + bw + 8 -- from the left, from the right
	local hit = Instance.new("Frame") -- the whole track row catches the touch (at least 44 px tall)
	hit.Name = "Hit"
	hit.BackgroundTransparency = 1
	hit.Active = true
	hit.Position = UDim2.new(0, trackX0, 0, 0)
	hit.Size = UDim2.new(1, -(trackX0 + trackX1), 1, 0)
	hit.ZIndex = 4
	hit.Parent = r
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundColor3 = C.pipEmpty
	track.BorderSizePixel = 0
	track.AnchorPoint = Vector2.new(0, 0.5)
	track.Position = UDim2.new(0, 0, 0.5, 0)
	track.Size = UDim2.new(1, 0, 0, 14)
	track.ZIndex = 4
	track.Parent = hit
	local fillBar = Instance.new("Frame")
	fillBar.Name = "Fill"
	fillBar.BackgroundColor3 = C.plateBlue
	fillBar.BorderSizePixel = 0
	fillBar.Size = UDim2.fromScale(vals[key], 1)
	fillBar.ZIndex = 5
	fillBar.Parent = track
	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.BackgroundColor3 = C.white
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(vals[key], 0, 0.5, 0)
	knob.Size = UDim2.fromOffset(26, 34)
	knob.ZIndex = 6
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(0, U.radiusPx)
	kc.Parent = knob
	local ks = Instance.new("UIStroke")
	ks.Color = C.ink
	ks.Thickness = U.outlinePx
	ks.Parent = knob
	knob.Parent = track
	pct.Text = string.format("%d", math.floor(vals[key] * 100 + 0.5)) .. N.ui.percent

	local function setFrom(x: number)
		local f = snap((x - hit.AbsolutePosition.X) / math.max(hit.AbsoluteSize.X, 1))
		vals[key] = f
		fillBar.Size = UDim2.fromScale(f, 1)
		knob.Position = UDim2.new(f, 0, 0.5, 0)
		pct.Text = string.format("%d", math.floor(f * 100 + 0.5)) .. N.ui.percent
		schedule()
	end
	local moveConn, endConn
	hit.InputBegan:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFrom(io.Position.X)
			moveConn = UserInputService.InputChanged:Connect(function(m)
				if m.UserInputType == Enum.UserInputType.MouseMovement or m.UserInputType == Enum.UserInputType.Touch then
					setFrom(m.Position.X)
				end
			end)
			endConn = UserInputService.InputEnded:Connect(function(e)
				if e.UserInputType == Enum.UserInputType.MouseButton1 or e.UserInputType == Enum.UserInputType.Touch then
					dragging = false
					moveConn:Disconnect()
					endConn:Disconnect()
				end
			end)
		end
	end)
	return minus.face
end

local function build(body: Frame)
	local h = math.max(66, Kit.minDesign(U.touchMin) + 12)
	local f1 = slider(body, 0, h, "music", "music", N.ui.settings.music)
	slider(body, h + 8, h, "effects", "effects", N.ui.settings.effects)
	return 2 * h + 8, f1
end

function Settings.open()
	if not modal then
		return
	end
	modal.open(function(body)
		return (build(body))
	end)
end

function Settings.close()
	if modal then
		modal.close()
	end
end

function Settings.toggle()
	if modal and modal.isOpen() then
		modal.close()
	else
		Settings.open()
	end
end

function Settings.isOpen()
	return modal ~= nil and modal.isOpen()
end

function Settings.values()
	return { music = vals.music, effects = vals.effects }
end

function Settings.onProfile(p)
	if typeof(p) == "table" and typeof(p.settings) == "table" and not dragging and not dirty then
		for _, k in ipairs({ "music", "effects" }) do
			if typeof(p.settings[k]) == "number" then
				vals[k] = math.clamp(p.settings[k], 0, 1)
			end
		end
		if modal and modal.isOpen() then
			modal.refresh()
		end
	end
end

function Settings.build()
	modal = Hud.modal("Settings", { title = N.ui.settings.title, width = 600 })
	modal.onClose(flush)
	tile = Hud.tile("settings", N.ui.tiles.settings, 3, Settings.toggle)
end

function Settings.start(ctx)
	if not Hud.root() then
		return
	end
	Settings.build()
	UserInputService.InputBegan:Connect(function(io, processed)
		if not processed and (io.KeyCode == Enum.KeyCode.M or io.KeyCode == Enum.KeyCode.DPadLeft) then
			Settings.toggle()
		end
	end)
	task.spawn(function()
		local ok, r = pcall(Net.get, "Profile", "Changed")
		if ok then
			r.OnClientEvent:Connect(Settings.onProfile)
		end
	end)
end

return Settings
