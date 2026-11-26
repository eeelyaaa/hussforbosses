--!nonstrict
-- Controllers/Hazards: draws the Rolling Log from the server clock (m1-contract.md B, E; Shared/Hazards). Nothing per
-- frame crosses the network: pose = Hazards.logCFrame(track, Clock.now()) each RenderStepped, rolled by offset / radius
-- about the lane axis. The server's own copy of the model never moves (this is the client's replica, posed locally).
-- The 0.6 s warning: a ground shadow where the log will be at t + Config.Hazards.WARN_S, shown while the log moves or
-- is about to (the model's warning, not the server's: brief system 6).
-- API: Hazards.init(), Hazards.state() -> { model, track, off, t } for checks.
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Skin = require(Shared.Skin)
local SharedHazards = require(Shared.Hazards)
local Clock = require(script.Parent.Clock)
local BossVisuals = require(script.Parent.BossVisuals)

local Hazards = {}
local logs = {} -- model -> { track, shadow, groundY }
local last = { off = 0, t = 0 }
local started = false

local function ground(model: Model, track): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, BossVisuals.fx() }
	local from = track.home.Position
	local r = workspace:Raycast(from, Vector3.new(0, -40, 0), params)
	return if r then r.Position.Y else from.Y - Config.Hazards.LOG.thickness / 2
end

local function setup(model: Instance)
	if logs[model] or not model:IsA("Model") or model:GetAttribute("HazardId") ~= 1 then
		return
	end
	local function build()
		if logs[model] or typeof(model:GetAttribute("TrackHome")) ~= "CFrame" then
			return
		end
		local track = SharedHazards.trackOf(model)
		if not track then
			return
		end
		local shadow = Instance.new("Part")
		shadow.Name = "LogWarning"
		shadow.Anchored, shadow.CanCollide, shadow.CanQuery, shadow.CanTouch, shadow.CastShadow = true, false, false, false, false
		shadow.Material = Enum.Material.SmoothPlastic
		shadow.Color = Skin.Tokens.colors.alarmOrange
		shadow.Transparency = 1
		local L = Config.Hazards.LOG
		shadow.Size = Vector3.new(L.thickness, 0.1, L.length)
		shadow.Parent = BossVisuals.fx()
		logs[model] = { track = track, shadow = shadow, groundY = ground(model, track) + 0.06 }
	end
	build()
	if not logs[model] then
		model:GetAttributeChangedSignal("TrackHome"):Connect(build)
	end
end

local function moving(t: number, laneWidth: number): boolean
	local _, _, v = SharedHazards.logOffset(t, laneWidth)
	return v ~= 0
end

local function render()
	local t = Clock.now()
	for model, d in pairs(logs) do
		if not model.Parent then
			d.shadow:Destroy()
			logs[model] = nil
			continue
		end
		local track = d.track
		local off = SharedHazards.logOffset(t, track.laneWidth)
		local pos = SharedHazards.logCFrame(track, t).Position
		local radius = Config.Hazards.LOG.thickness / 2
		model:PivotTo(CFrame.new(pos) * CFrame.fromAxisAngle(track.along, off / radius) * track.home.Rotation)
		last.off, last.t, last.model = off, t, model
		last.meas = (model:GetPivot().Position - track.home.Position):Dot(track.across)
		-- the warning
		local warn = Config.Hazards.WARN_S
		local ahead = SharedHazards.logOffset(t + warn, track.laneWidth)
		if moving(t, track.laneWidth) or moving(t + warn, track.laneWidth) then
			local p = track.home.Position + track.across * ahead
			d.shadow.CFrame = CFrame.fromMatrix(Vector3.new(p.X, d.groundY, p.Z), track.across, Vector3.yAxis)
			d.shadow.Transparency = 0.45
		else
			d.shadow.Transparency = 1
		end
	end
end

function Hazards.state()
	return last
end

function Hazards.init()
	if started then
		return
	end
	started = true
	for _, m in ipairs(CollectionService:GetTagged("HFB_Hazard")) do
		setup(m)
	end
	CollectionService:GetInstanceAddedSignal("HFB_Hazard"):Connect(setup)
	RunService.RenderStepped:Connect(render)
end

return Hazards
