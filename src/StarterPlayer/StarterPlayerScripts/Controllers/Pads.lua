--!nonstrict
-- Controllers/Pads: each boss pad's Power number, drawn at the pad's NumberAnchor (M1-24; style guide 6 "Over the boss",
-- "Fight difficulty"). The number is the boss's Power, coloured by the band of r = boss Power / this player's Power
-- (Config.Fight.band, Skin.Tokens.colors.band), so two players see two colours on one pad. A BillboardGui in screen
-- pixels (it stays the same size on screen) that draws on top and reaches past 320 studs, so every plot reads it over the
-- hub's 4-stud front wall. Display only: the server sends Zones.Pads (power per pad), Zones.PadBeaten (empty for backIn
-- seconds) and Profile.Changed (the player's Power); nothing here decides a result.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)
local Kit = require(script.Parent.Parent.Ui.Kit)

local T = Skin.Tokens
local C = T.colors
local TAG = "HFB_BossPad"
local TEXT_PX = math.floor(T.type.title * 1.5 + 0.5) -- 1.5 x the name size (style guide); the title step
local MAX_DISTANCE = 400 -- past the 320 studs the style guide asks for

local Pads = {}
local powers = {} -- padId -> boss Power (Zones.Pads)
local hiddenUntil = {} -- padId -> true while the pad is empty for this player
local views = {} -- padId -> { gui, label, model }
local myPower = 1
local started = false

local function colorFor(bossPower: number)
	local r = bossPower / math.max(myPower, 1)
	local band = Config.Fight.band(r)
	return C.band[band.id], band.id
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
	local gui = Instance.new("BillboardGui")
	gui.Name = "PowerNumber"
	gui.Size = UDim2.fromOffset(TEXT_PX * 6, TEXT_PX * 1.6)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = MAX_DISTANCE
	gui.ResetOnSpawn = false
	gui.Adornee = anchor
	gui.Enabled = false
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Name = "Power"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.FontFace = Kit.Font()
	label.TextSize = TEXT_PX
	label.TextColor3 = C.white
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = T.ui.textOutlinePx
	stroke.Color = C.ink
	stroke.Parent = label
	views[padId] = { gui = gui, label = label, model = model }
	Pads.refresh()
end

function Pads.refresh()
	for padId, v in pairs(views) do
		local power = powers[padId]
		if power == nil or hiddenUntil[padId] then
			v.gui.Enabled = false
		else
			local color = colorFor(power)
			v.label.Text = Kit.commas(power)
			v.label.TextColor3 = color
			v.gui.Enabled = true
		end
	end
end

-- Test probe: what each pad shows now (TestClient "pads" report).
function Pads.snapshot()
	local out = {}
	for padId, v in pairs(views) do
		local power = powers[padId]
		local band = nil
		if power then
			_, band = colorFor(power)
		end
		out[padId] = {
			text = v.label.Text,
			color = v.label.TextColor3:ToHex(),
			band = band,
			shown = v.gui.Enabled,
			boss = power,
			mine = myPower,
		}
	end
	return out
end

function Pads.init()
	if started then
		return
	end
	started = true
	for _, m in ipairs(CollectionService:GetTagged(TAG)) do
		task.spawn(build, m)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(m)
		task.spawn(build, m)
	end)
	Net.get("Zones", "Pads").OnClientEvent:Connect(function(list)
		if typeof(list) ~= "table" then
			return
		end
		for _, e in ipairs(list) do
			if typeof(e) == "table" and typeof(e.padId) == "string" and typeof(e.power) == "number" then
				powers[e.padId] = e.power
			end
		end
		Pads.refresh()
	end)
	Net.get("Zones", "PadBeaten").OnClientEvent:Connect(function(p)
		if typeof(p) ~= "table" or typeof(p.padId) ~= "string" or typeof(p.backIn) ~= "number" then
			return
		end
		local padId = p.padId
		local token = {}
		hiddenUntil[padId] = token
		Pads.refresh()
		task.delay(p.backIn, function()
			if hiddenUntil[padId] == token then
				hiddenUntil[padId] = nil
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
end

return Pads
