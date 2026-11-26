--!nonstrict
-- Controllers/Arrow: the first-session arrow (brief "The first session": one arrow that moves between the bag, the first boss, home,
-- the first spot and the first upgrade, and is gone after FirstBossUpgraded; no tutorial screens). Built by M2-21.
-- A bouncing arrow in the world (a real part, sized in studs: it shrinks with distance, never a pixel-sized BillboardGui). Display only.
-- The step comes from the saved funnel flags (Profile.Changed.flags, kept by Systems/Funnel) and the carry state:
--   bag      no boss Power yet (not ReachedFirstBossPower)           -> over the own bag pad
--   boss     Power reached, no boss placed, not carrying              -> over the zone 1 fixed pad (z1_fixed)
--   home     carrying the first boss, none placed yet                 -> over the own spot 1
--   cash     first boss placed, no cash collected                     -> over the own cash pad 1
--   upgrade  cash collected, first upgrade not done                   -> over the own spot 1 (the boss on it)
--   (none)   FirstBossUpgraded: the arrow is destroyed (a wiped profile brings it back: a fresh first session)
-- Targets are found by CollectionService tags every POLL_S (streamed-out parts are simply not there: the last position seen is kept,
-- the world does not move). Nothing is looked up once and held.
--   Arrow.start(ctx) (AUTO_START)   Arrow.step() -> string?   Arrow.snapshot()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)

local Arrow = { AUTO_START = true }

local flags = nil -- nil until the first Profile.Changed that carries flags (a returning player must not see a flash)
local carryCtl = nil
local model = nil
local conn = nil
local done = false
local stepName = nil
local targetPos = nil
local lastPos = {} -- step -> last position seen (static world)
local pollAcc = math.huge
local t0 = os.clock()

local function ownPart(tag: string, spotIndex: number?)
	local me = Players.LocalPlayer.UserId
	for _, part in ipairs(CollectionService:GetTagged(tag)) do -- stream-ok: re-read every POLL_S, never cached
		local plot = part.Parent
		if plot and plot:GetAttribute("OwnerUserId") == me and (spotIndex == nil or part:GetAttribute("SpotIndex") == spotIndex) then
			return part
		end
	end
	return nil
end

local function bossPad()
	for _, m in ipairs(CollectionService:GetTagged("HFB_BossPad")) do -- stream-ok: re-read every POLL_S, never cached
		if m:GetAttribute("PadId") == "z1_fixed" then
			return m
		end
	end
	return nil
end

local function topOf(inst: Instance?): Vector3?
	if not inst then
		return nil
	end
	if inst:IsA("BasePart") then
		return inst.Position + Vector3.new(0, inst.Size.Y / 2, 0)
	elseif inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	return nil
end

local function carrying(): boolean
	if carryCtl and type(carryCtl.state) == "function" then
		local name = carryCtl.state()
		return name == "carrying"
	end
	return false
end

-- The step for the flags now (pure; the check reads it through snapshot).
function Arrow.stepFor(f, isCarrying: boolean): string?
	if f == nil or f.FirstBossUpgraded then
		return nil
	end
	if not f.FirstBossPlaced then
		if isCarrying then
			return "home"
		end
		return if f.ReachedFirstBossPower then "boss" else "bag"
	end
	if not f.FirstCashCollected then
		return "cash"
	end
	return "upgrade"
end

local function targetFor(step: string): Vector3?
	local inst
	if step == "bag" then
		inst = ownPart("HFB_BagPad")
	elseif step == "boss" then
		inst = bossPad()
	elseif step == "home" or step == "upgrade" then
		inst = ownPart("HFB_Spot", 1)
	elseif step == "cash" then
		inst = ownPart("HFB_CashPad", 1)
	end
	local top = topOf(inst)
	if top then
		lastPos[step] = top
		return top
	end
	return lastPos[step]
end

local function build()
	local A = Config.Funnel.ARROW
	local color = Skin.Tokens.colors.arrowYellow
	local m = Instance.new("Model")
	m.Name = "HFB_FirstArrow"
	local function part(name: string, size: Vector3, cf: CFrame)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = cf
		p.Parent = m
		return p
	end
	-- the model's pivot is the tip: a cube on its corner for the head, a block shaft above it
	local half = A.HEAD * math.sqrt(3) / 2
	part("Head", Vector3.new(A.HEAD, A.HEAD, A.HEAD), CFrame.new(0, half, 0) * CFrame.Angles(0, 0, math.rad(45)) * CFrame.Angles(math.rad(35.264), 0, 0))
	part("Shaft", Vector3.new(A.SHAFT[1], A.SHAFT[2], A.SHAFT[3]), CFrame.new(0, half + half + A.SHAFT[2] / 2 - 0.6, 0))
	m.WorldPivot = CFrame.new(0, 0, 0)
	local hl = Instance.new("Highlight")
	hl.Name = "Outline"
	hl.FillTransparency = 1
	hl.OutlineColor = Skin.Tokens.colors.white
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = m
	hl.Parent = m
	return m
end

local function destroy()
	done = true
	if conn then
		conn:Disconnect()
		conn = nil
	end
	if model then
		model:Destroy()
		model = nil
	end
	stepName = nil
	targetPos = nil
end

local function frame(dt: number)
	if done then
		return
	end
	pollAcc += dt
	if pollAcc >= Config.Funnel.ARROW.POLL_S then
		pollAcc = 0
		stepName = Arrow.stepFor(flags, carrying())
		if stepName == nil then
			if flags ~= nil and flags.FirstBossUpgraded then
				destroy()
			elseif model then
				model.Parent = nil
			end
			return
		end
		targetPos = targetFor(stepName)
	end
	if not stepName or not targetPos then
		if model and model.Parent then
			model.Parent = nil
		end
		return
	end
	local A = Config.Funnel.ARROW
	if not model then
		model = build()
	end
	if model.Parent == nil then
		model.Parent = workspace
	end
	local bob = (0.5 + 0.5 * math.sin((os.clock() - t0) * 2 * math.pi / A.BOB_S)) * A.BOB
	local lift = A.LIFT[stepName] or 6
	model:PivotTo(CFrame.new(targetPos + Vector3.new(0, lift + bob, 0)))
end

function Arrow.step(): string?
	return stepName
end

-- For the check (TestClient "arrow" report).
function Arrow.snapshot()
	local pos = model and model.Parent ~= nil and model:GetPivot().Position or nil
	return {
		step = stepName,
		shown = pos ~= nil,
		done = done,
		x = pos and math.floor(pos.X + 0.5),
		y = pos and math.floor(pos.Y + 0.5),
		z = pos and math.floor(pos.Z + 0.5),
		flagged = flags ~= nil,
	}
end

function Arrow.start(ctx)
	carryCtl = ctx and ctx.Carry
	Net.get("Profile", "Changed").OnClientEvent:Connect(function(p)
		if typeof(p) == "table" and typeof(p.flags) == "table" then
			flags = p.flags
			if flags.FirstBossUpgraded and not done then
				destroy()
			elseif not flags.FirstBossUpgraded and done then
				-- a wiped profile (the Wipe hook) is a fresh first session
				done = false
				pollAcc = math.huge
				conn = RunService.Heartbeat:Connect(frame)
			end
		end
	end)
	if not done then
		conn = RunService.Heartbeat:Connect(frame)
	end
end

return Arrow
