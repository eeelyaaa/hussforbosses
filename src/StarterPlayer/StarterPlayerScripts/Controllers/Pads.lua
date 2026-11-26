--!nonstrict
-- Controllers/Pads: the 24 boss pads' numbers and states, from Zones.Pads (M1-24, M2-12; style guide 6 "Over the boss", "Fight
-- difficulty"). Per pad: the boss's Power at the pad's NumberAnchor, coloured by the band of r = boss Power / this player's Power
-- (Config.Fight.band, Skin.Tokens.colors.band), so two players see two colours on one pad; under it, for a rolling pad, the seconds
-- until its next roll (digits only); a pad this player has beaten shows only the time until it is back. The labels are
-- BillboardGuis sized in studs (Ui/WorldLabel), so they shrink with distance like the world; they sit above the hub's 4-stud
-- front wall and are not drawn past 150 studs.
-- Zones.Pads entries: { padId, zone, creatureId, power, kind, rollEndsAt?, beaten, patrol }; each is also handed to
-- Controllers/BossVisuals, which draws the pad's boss walking the patrol (server clock, nothing per frame on the wire).
-- Display only: nothing here decides a result.
--   Pads.init()   Pads.refresh()   Pads.entry(padId)   Pads.snapshot()
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)
local Clock = require(script.Parent.Clock)
local BossVisuals = require(script.Parent.BossVisuals)
local Kit = require(script.Parent.Parent.Ui.Kit)
local WorldLabel = require(script.Parent.Parent.Ui.WorldLabel)

local T = Skin.Tokens
local C = T.colors
local TAG = "HFB_BossPad"
-- Sized in studs (M2-05) so it shrinks like the world. 14 x 6 studs: about 33 px tall at 55 studs and 17 px at 100 studs on a
-- phone (874 x 402, 70 degree FOV), the sight-line range in verification/m1-greybox.md. Not drawn past 150 studs.
local LABEL_W_STUDS = 14
local LABEL_H_STUDS = 6
local MAX_DISTANCE = WorldLabel.MAX_DISTANCE

local Pads = {}
local entries = {} -- padId -> the last Zones.Pads entry
local beatenUntil = {} -- padId -> server time this player's beaten pad is back (number)
local views = {} -- padId -> { gui, label, timer, model }
local myPower = 1
local started = false

local function colorFor(bossPower: number)
	local r = bossPower / math.max(myPower, 1)
	local band = Config.Fight.band(r)
	return C.band[band.id], band.id
end

local function mmss(sec: number): string
	sec = math.max(0, math.ceil(sec))
	return string.format("%d:%02d", sec // 60, sec % 60)
end

local function isBeaten(padId: string, now: number): boolean
	local u = beatenUntil[padId]
	return u ~= nil and now < u
end

local function build(model: Instance)
	local padId = model:GetAttribute("PadId")
	if typeof(padId) ~= "string" or views[padId] then
		return
	end
	local anchor = model:FindFirstChild("NumberAnchor") or model:WaitForChild("NumberAnchor", 10)
	if not (anchor and anchor:IsA("BasePart")) then
		return
	end
	local gui = WorldLabel.new({
		name = "PowerNumber",
		adornee = anchor,
		studsW = LABEL_W_STUDS,
		studsH = LABEL_H_STUDS,
		maxDistance = MAX_DISTANCE,
		enabled = false,
	})
	local function text(name: string, size: UDim2, pos: UDim2): TextLabel
		local label = Instance.new("TextLabel")
		label.Name = name
		label.BackgroundTransparency = 1
		label.Size = size
		label.Position = pos
		label.FontFace = Kit.Font()
		label.TextScaled = true
		label.TextColor3 = C.white
		label.Text = ""
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = T.ui.textOutlinePx
		stroke.Color = C.ink
		stroke.Parent = label
		return label
	end
	local label = text("Power", UDim2.fromScale(1, 0.7), UDim2.fromScale(0, 0))
	local timer = text("Timer", UDim2.fromScale(0.5, 0.26), UDim2.fromScale(0.25, 0.72))
	timer.Visible = false
	views[padId] = { gui = gui, label = label, timer = timer, model = model }
	Pads.refresh()
end

function Pads.refresh()
	local now = Clock.now()
	for padId, v in pairs(views) do
		local e = entries[padId]
		local beaten = isBeaten(padId, now)
		if e == nil then
			v.gui.Enabled = false
		else
			if beaten then
				v.label.Visible = false
				v.timer.Visible = true
				v.timer.Text = mmss(beatenUntil[padId] - now)
			else
				v.label.Visible = true
				v.label.Text = Kit.commas(e.power)
				v.label.TextColor3 = colorFor(e.power)
				local left = if e.kind == "roll" and typeof(e.rollEndsAt) == "number" then e.rollEndsAt - now else nil
				v.timer.Visible = left ~= nil
				if left then
					v.timer.Text = mmss(left)
				end
			end
			v.gui.Enabled = true
		end
	end
end

function Pads.entry(padId: string)
	return entries[padId]
end

-- Test probe: what each pad shows now (TestClient "pads" report, and the M2-12 check).
function Pads.snapshot()
	local out = {}
	local now = Clock.now()
	for padId, v in pairs(views) do
		local e = entries[padId]
		local band = nil
		if e then
			_, band = colorFor(e.power)
		end
		out[padId] = {
			text = v.label.Text,
			color = v.label.TextColor3:ToHex(),
			band = band,
			shown = v.gui.Enabled and v.label.Visible,
			timer = if v.timer.Visible then v.timer.Text else nil,
			beaten = isBeaten(padId, now),
			kind = e and e.kind,
			zone = e and e.zone,
			creature = e and e.creatureId,
			boss = e and e.power,
			mine = myPower,
		}
	end
	return out
end

local function applyList(list)
	local now = Clock.now()
	for _, e in ipairs(list) do
		if typeof(e) == "table" and typeof(e.padId) == "string" and typeof(e.power) == "number" and typeof(e.creatureId) == "string" then
			local padId = e.padId
			entries[padId] = e
			if e.beaten == true then
				-- a roll stays beaten until it rolls; a fixed pad until it is back (PadBeaten has the exact time)
				local back = if e.kind == "roll" and typeof(e.rollEndsAt) == "number" then e.rollEndsAt else now + (Config.Fight.FIXED_BACK_S or 10)
				if not (beatenUntil[padId] and now < beatenUntil[padId]) then
					beatenUntil[padId] = back
				end
			else
				beatenUntil[padId] = nil
			end
			if typeof(e.patrol) == "table" then
				BossVisuals.setEntry(padId, e)
			end
			BossVisuals.setPadHidden(padId, isBeaten(padId, now))
		end
	end
	Pads.refresh()
end

function Pads.init()
	if started then
		return
	end
	started = true
	BossVisuals.init()
	for _, m in ipairs(CollectionService:GetTagged(TAG)) do
		task.spawn(build, m)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(m)
		task.spawn(build, m)
	end)
	Net.get("Zones", "Pads").OnClientEvent:Connect(function(list)
		if typeof(list) == "table" then
			applyList(list)
		end
	end)
	Net.get("Zones", "PadBeaten").OnClientEvent:Connect(function(p)
		if typeof(p) ~= "table" or typeof(p.padId) ~= "string" or typeof(p.backIn) ~= "number" then
			return
		end
		local padId = p.padId
		local back = Clock.now() + p.backIn
		beatenUntil[padId] = back
		Pads.refresh()
		-- The beaten boss is the carry's to hide (it hops onto the head first); it is shown again when the pad is back.
		task.delay(p.backIn + 0.05, function()
			if beatenUntil[padId] == back then
				beatenUntil[padId] = nil
				BossVisuals.setPadHidden(padId, false)
				Pads.refresh()
			end
		end)
	end)
	Net.get("Profile", "Changed").OnClientEvent:Connect(function(p)
		if typeof(p) == "table" and typeof(p.power) == "number" and p.power ~= myPower then
			myPower = p.power
			Pads.refresh()
		end
	end)
	-- the roll countdowns tick four times a second
	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc >= 0.25 then
			acc = 0
			Pads.refresh()
		end
	end)
end

return Pads
