--!nonstrict
-- Ui/Hud: assembles the HUD (m1-hud-ui-and-stud-button.md; ui-kit/phone-hud-base.png) inside one full-screen ScreenGui, one
-- container, one UIScale. The controllers drive the views through the module fields:
--   Hud.huss (HussButton), Hud.counters (Counters), Hud.fight (FightOverlay), Hud.prompts (Prompts)
--   Hud.start()                      builds into the local player's PlayerGui (called once by the client entry script)
--   Hud.build(playerGui, override?)  same, for a given parent; override = { viewport = Vector2, mouse = boolean } for checks
--   Hud.setViewport(vp, mouse)       re-applies the scale rule for a viewport (device checks)
--   Hud.destroy()
-- Layout (design px, 874 x 402): Power and cash plates top left, to the right of Roblox's own top-bar buttons; the Huss button
-- bottom right beside the jump button (centre 184 px from the right edge and 142 px above the bottom, as the kit draws it).
-- The plates sit below Roblox's real top bar: y = GuiService.TopbarInset.Max.Y + 10 screen px (re-laid out when it changes, M1-25). The jump button's rectangle on screen is 80 px at 22 px from the
-- right and bottom edges (the kit's drawing); clearance is read back in the HUD check.
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local Kit = require(script.Parent.Kit)
local Skin = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Skin"))
local U = Skin.Tokens.ui
local HussButton = require(script.Parent.HussButton)
local Counters = require(script.Parent.Counters)
local FightOverlay = require(script.Parent.FightOverlay)
local Prompts = require(script.Parent.Prompts)

local Hud = {}
Hud.huss = HussButton
Hud.counters = Counters
Hud.fight = FightOverlay
Hud.prompts = Prompts

local TOP_GAP_PX = 10 -- screen px between the real top bar (GuiService.TopbarInset) and the plates
local SIDE_PAD = 16 -- design px from the left edge (plus the top bar's own left edge, for a notch)
local HUSS_FROM_BOTTOM = 142
local JUMP_PX, JUMP_MARGIN_PX, JUMP_GAP_PX = 80, 22, 12 -- the kit draws the jump button 80 px across, 22 px from the right edge

local gui, handle = nil, nil
local conn, insetConn, sizeConn = nil, nil, nil

-- left edge of a phone's notch / rounded corner in screen px (0 when the API or a notch is absent)
local function deviceLeftPx(): number
	local ok, r = pcall(function()
		return GuiService:GetSafeZoneOffsets()
	end)
	if ok and typeof(r) == "Rect" then
		return math.max(0, r.Min.X)
	end
	return 0
end

local function place()
	if not handle then
		return
	end
	local s = Kit.scale()
	-- the plates sit BELOW Roblox's top bar (the bar's rect is GuiService.TopbarInset, screen px; the HUD ignores the GuiInset)
	local inset = GuiService.TopbarInset
	local c = Counters.instance()
	local cx = SIDE_PAD + math.ceil(deviceLeftPx() / s)
	local cy = math.ceil((inset.Max.Y + TOP_GAP_PX) / s)
	if c then
		c.Position = UDim2.fromOffset(cx, cy)
	end
	-- fight overlay: Run directly under the counter plates (kit: top left under the first row), fight plate under the bar
	local cw = c and (c.AbsoluteSize.X / s) or 0
	FightOverlay.place(cx, cy + U.counterH + 4 + 8, math.ceil((inset.Max.Y + 8) / s), cx + cw + 8, handle.root.AbsoluteSize.X / s)
	local h = HussButton.instance()
	if h then
		-- centre from the right edge in SCREEN px: the jump button's width, its margin, a gap, and the band's radius, so the
		-- button stays beside the jump button when the button grows on a small phone (at scale 1 this is the kit's 184)
		local radiusPx = (HussButton.diameter() / 2 + U.bandThickPx) * s
		local fromRight = (JUMP_MARGIN_PX + JUMP_PX + JUMP_GAP_PX + radiusPx) / s
		h.Position = UDim2.new(1, -fromRight, 1, -HUSS_FROM_BOTTOM)
	end
end

function Hud.build(playerGui: Instance, override)
	Hud.destroy()
	gui = Instance.new("ScreenGui")
	gui.Name = "HussHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 1
	gui.Parent = playerGui
	handle = Kit.Scale(gui, override)
	local root = handle.root
	Counters.build(root)
	FightOverlay.build(root)
	HussButton.build(root)
	Prompts.build(root)
	conn = Kit.onScale(place)
	local ci = Counters.instance()
	if ci then
		sizeConn = ci:GetPropertyChangedSignal("AbsoluteSize"):Connect(place) -- counters grow with the numbers
	end
	insetConn = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
	place()
	return gui
end

function Hud.start()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	return Hud.build(pg)
end

function Hud.setViewport(viewport: Vector2?, mouse: boolean?)
	if handle then
		handle.set(viewport, mouse)
	end
end

function Hud.destroy()
	if conn then
		conn.Disconnect()
		conn = nil
	end
	if sizeConn then
		sizeConn:Disconnect()
		sizeConn = nil
	end
	if insetConn then
		insetConn:Disconnect()
		insetConn = nil
	end
	HussButton.destroy()
	Counters.destroy()
	FightOverlay.destroy()
	Prompts.destroy()
	if handle then
		handle.destroy()
		handle = nil
	end
	if gui then
		gui:Destroy()
		gui = nil
	end
	Kit.reset()
end

function Hud.gui()
	return gui
end

function Hud.root()
	return handle and handle.root
end

return Hud
