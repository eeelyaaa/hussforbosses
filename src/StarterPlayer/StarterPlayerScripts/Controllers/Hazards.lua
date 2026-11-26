--!nonstrict
-- Controllers/Hazards: draws the six zone hazards from the server clock (m1-contract.md B, E; m2-contract.md C; Shared/Hazards).
-- Nothing per frame crosses the network: every RenderStepped each hazard model is posed from
-- Hazards.volumes(id, track, Clock.now()), the same pure function the server's hit test uses. The server's own copy of a
-- model never moves (this is the client's replica, posed locally). Models: Workspace.Zones.Z<n>.Hazard_<n>, tag HFB_Hazard,
-- attributes HazardId and TrackHome (CFrame, the track's home).
--   1 Rolling Log   the log rolls (offset / radius about the lane axis)             (M1)
--   2 Tumble Cactus, 3 Swinging Anchor (+ Chain), 4 Sliding Ice Block, 6 Orbit Meteor (+ Shadow): the model's Body follows
--                   volumes()[1]; no volume (the cactus between runs) = Body not drawn
--   5 Lava Burst Row: Tile_1..6 follow Hazards.lavaTiles: idle = a faint flat tile, glow = the warning (bright, pulsing),
--                   erupt = the raised block (the volume the server hits with)
-- THE 0.6 S WARNING (brief system 6): a flat marker on the lane where the hazard will be at t + Config.Hazards.WARN_S
-- (volumes(id, track, t + WARN_S)), shown while there is something to warn about; lava's glow (0.8 s) is its own warning.
-- Display only. API: Hazards.init(), Hazards.state() -> { model, track, off, t } (the log, for the M1 checks),
-- Hazards.snapshot() -> per hazard id { id, bodyPos, bodyShown, warn, warnPos, tiles } (the M2-12 check).
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
local logs = {} -- model -> { track, shadow, groundY }   (hazard 1)
local others = {} -- model -> { id, track, body, chain, shadow, tiles, marker, markerOn, bodyOn }   (hazards 2..6)
local last = { off = 0, t = 0 }
local started = false
local DRAW_RANGE = 420 -- studs from the camera; farther hazards are not posed (nobody can see them)

local function flatPart(name: string, color: Color3, transparency: number): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.Transparency = transparency
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return p
end

local function ground(model: Model, track): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { model, BossVisuals.fx() }
	local from = track.home.Position
	local r = workspace:Raycast(from, Vector3.new(0, -40, 0), params)
	return if r then r.Position.Y else from.Y - Config.Hazards.LOG.thickness / 2
end

-- ------------------------------------------------------------------------------------------------ hazard 1: the log
local function setupLog(model: Model)
	local function build()
		if logs[model] or typeof(model:GetAttribute("TrackHome")) ~= "CFrame" then
			return
		end
		local track = SharedHazards.trackOf(model)
		if not track then
			return
		end
		local shadow = flatPart("LogWarning", Skin.Tokens.colors.alarmOrange, 1)
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

local function renderLog(t: number)
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

-- ------------------------------------------------------------------------------------------------ hazards 2..6
local function setupOther(model: Model, id: number)
	local function build()
		if others[model] or typeof(model:GetAttribute("TrackHome")) ~= "CFrame" then
			return
		end
		local track = SharedHazards.trackOf(model)
		if not track then
			return
		end
		local d = { id = id, track = track, tiles = {}, markerOn = false, bodyOn = true, model = model }
		d.body = model:FindFirstChild("Body")
		d.chain = model:FindFirstChild("Chain")
		d.shadow = model:FindFirstChild("Shadow")
		for k = 1, Config.Hazards.LAVA.tiles do
			local tile = model:FindFirstChild("Tile_" .. k)
			if tile then
				d.tiles[k] = tile
			end
		end
		if id ~= 5 then
			local marker = flatPart("Warning" .. id, Skin.Tokens.colors.alarmOrange, 1)
			marker.Size = Vector3.new(1, 0.1, 1)
			marker.Parent = BossVisuals.fx()
			d.marker = marker
		end
		others[model] = d
	end
	build()
	if not others[model] then
		model:GetAttributeChangedSignal("TrackHome"):Connect(build)
	end
end

local function setBodyShown(d, shown: boolean)
	if d.bodyOn == shown then
		return
	end
	d.bodyOn = shown
	for _, p in ipairs({ d.body, d.chain, d.shadow }) do
		if p and p:IsA("BasePart") then
			p.LocalTransparencyModifier = if shown then 0 else 1
		end
	end
end

local function warnMarker(d, t: number)
	local track = d.track
	local vols = SharedHazards.volumes(d.id, track, t + Config.Hazards.WARN_S)
	local v = vols[1]
	if not v then
		d.markerOn = false
		d.marker.Transparency = 1
		return
	end
	local w = SharedHazards.toWorld(track, v)
	local y = track.home.Position.Y + 0.11
	local size
	local cf = CFrame.fromMatrix(Vector3.new(w.Position.X, y, w.Position.Z), track.across, Vector3.yAxis)
	if v.shape == "box" then
		size = Vector3.new(2 * v.ha, 0.1, 2 * v.hl)
	else
		size = Vector3.new(2 * v.r, 0.1, 2 * v.r)
	end
	d.marker.Size = size
	d.marker.CFrame = cf
	d.marker.Transparency = 0.45
	d.markerOn = true
	d.warnPos = cf.Position
end

local function renderOther(d, t: number)
	local track = d.track
	local id = d.id
	-- the parts may arrive after the model's attributes: look again until they are all there
	if not d.complete then
		local m = d.model
		d.body = d.body or m:FindFirstChild("Body")
		d.chain = d.chain or m:FindFirstChild("Chain")
		d.shadow = d.shadow or m:FindFirstChild("Shadow")
		local tiles = 0
		for k = 1, Config.Hazards.LAVA.tiles do
			d.tiles[k] = d.tiles[k] or m:FindFirstChild("Tile_" .. k)
			if d.tiles[k] then
				tiles += 1
			end
		end
		d.complete = if id == 5 then tiles == Config.Hazards.LAVA.tiles elseif id == 3 then d.body ~= nil and d.chain ~= nil elseif id == 6 then d.body ~= nil and d.shadow ~= nil else d.body ~= nil
	end
	if id == 5 then
		local V = Config.Hazards.LAVA
		local states = SharedHazards.lavaTiles(t)
		local tw = track.laneWidth / V.tiles
		local pulse = 0.3 + 0.15 * math.sin(t * 14)
		local C = Skin.Tokens.colors
		d.tileStates = states
		for k, tile in pairs(d.tiles) do
			local st = states[k]
			local a = -track.laneWidth / 2 + tw * (k - 0.5)
			local base = track.home.Position + track.across * a
			if st == "erupt" then
				tile.Size = Vector3.new(tw, V.height, V.tile_along)
				tile.Position = base + Vector3.new(0, V.height / 2, 0)
				tile.Transparency = 0
				tile.Color = C.alarmOrange
			else
				tile.Size = Vector3.new(tw, 0.2, V.tile_along)
				tile.Position = base + Vector3.new(0, 0.3, 0)
				tile.Transparency = if st == "glow" then pulse else 0.8
				tile.Color = C.alarmOrange
			end
		end
		return
	end
	local vols = SharedHazards.volumes(id, track, t)
	local v = vols[1]
	if v and d.body then
		local cf = SharedHazards.toWorld(track, v)
		d.body.CFrame = cf
		setBodyShown(d, true)
		if id == 3 and d.chain then
			local A = Config.Hazards.ANCHOR
			local top = track.home.Position + Vector3.new(0, A.pivot_height, 0)
			local bottom = cf.Position + Vector3.new(0, v.hy, 0)
			local len = (top - bottom).Magnitude
			d.chain.Size = Vector3.new(d.chain.Size.X, d.chain.Size.Y, len)
			d.chain.CFrame = CFrame.lookAt((top + bottom) / 2, bottom)
		elseif id == 6 and d.shadow then
			d.shadow.CFrame = CFrame.new(cf.Position.X, track.home.Position.Y + 0.25, cf.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
		end
	else
		setBodyShown(d, false)
	end
	warnMarker(d, t)
end

local function setup(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local id = model:GetAttribute("HazardId")
	if typeof(id) ~= "number" then
		return
	end
	if id == 1 then
		if not logs[model] then
			setupLog(model)
		end
	elseif id >= 2 and id <= 6 then
		if not others[model] then
			setupOther(model, id)
		end
	end
end

local function render()
	local t = Clock.now()
	renderLog(t)
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position
	for model, d in pairs(others) do
		if not model.Parent then
			if d.marker then
				d.marker:Destroy()
			end
			others[model] = nil
			continue
		end
		if not camPos or (camPos - d.track.home.Position).Magnitude < DRAW_RANGE then
			renderOther(d, t)
		end
	end
end

function Hazards.state()
	return last
end

function Hazards.snapshot()
	local out = {}
	for _, d in pairs(others) do
		local row = { id = d.id, bodyShown = d.bodyOn, warn = d.markerOn }
		if d.body then
			row.bodyPos = d.body.Position
		end
		if d.markerOn then
			row.warnPos = d.warnPos
		end
		if d.tileStates then
			row.tiles = table.concat(d.tileStates, ",")
		end
		out[d.id] = row
	end
	return out
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
