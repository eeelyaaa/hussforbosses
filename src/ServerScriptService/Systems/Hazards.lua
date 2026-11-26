--!strict
-- Systems/Hazards: the server's hit test for the six zone hazards (brief system 6; m1-contract.md B, E, L;
-- m2-contract.md C, C2). Nothing moves on the server: each hazard's shape is Shared/Hazards' pure function of
-- Zones.now() (server time + the ClockOffset hook); clients animate the models from the same functions and the
-- Zones.Clock they receive. No per-frame position crosses the network.
--
-- Each Heartbeat step the server tests every character against every hazard whose band it stands in:
--   * a carrier a hazard hits (Shared/Hazards.hitsId, tolerance in the player's favour): Carry.drop (a fight carry's
--     boss lies where the carrier stood; any other carry ends the way Systems/Carry says, [M2-02 M8]) and the carrier
--     is pushed back DROP_PUSH studs along the lane, away from the volume that hit (TEAM CALL M1-11d), no stun;
--   * anyone else a hazard hits: a small push (brief "a small push only"), at most once per PUSH_COOLDOWN_S.
-- The 0.6 s warning (Config.Hazards.WARN_S) is the client's look, not a server rule.
-- Hook LogForce (config, Studio only; M2-11 widens it from the log to all six hazards): "hit" = every character
-- inside a hazard's band is hit now; "clear" = no hazard reaches anyone.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local TestHooks = require(Shared.TestHooks)
local SharedHazards = require(Shared.Hazards)
local Zones = require(script.Parent.Zones)
local Bag = require(script.Parent.Bag)
local Carry = require(script.Parent.Carry)

local Hazards = {}

local tracks: { [number]: SharedHazards.Track } = {}
local lastPush: { [Player]: number } = {}

Hazards.stats = { hits = {} :: { any }, pushes = 0 }

function Hazards.track(hazardId: number): SharedHazards.Track?
	return tracks[hazardId]
end

local function register(model: Instance)
	local id = model:GetAttribute("HazardId")
	if typeof(id) ~= "number" or not table.find(SharedHazards.IDS, id) then
		return
	end
	if typeof(model:GetAttribute("TrackHome")) ~= "CFrame" then
		if not model:IsA("Model") then
			return
		end
		-- the rest pose as built, stamped once so clients never read their own animated pivot
		model:SetAttribute("TrackHome", (model :: Model):GetPivot())
	end
	tracks[id] = SharedHazards.trackOf(model) :: SharedHazards.Track
end

-- Moves the character `dist` studs along the lane, away from `fromL` (the hitting volume's along offset), flat,
-- keeping rotation and height and staying inside the lane's walls.
local function push(player: Player, track: SharedHazards.Track, fromL: number, dist: number)
	local r = Bag.root(player)
	local ch = player.Character
	if not r or not ch then
		return
	end
	local side = (r.Position - track.home.Position):Dot(track.along) - fromL
	local dir = if side >= 0 then track.along else -track.along
	local target = r.Position + dir * dist
	local across = (target - track.home.Position):Dot(track.across)
	local lim = track.laneWidth / 2 - SharedHazards.BODY_RADIUS
	if math.abs(across) > lim then
		target -= track.across * (across - math.clamp(across, -lim, lim))
	end
	ch:PivotTo(CFrame.new(target) * r.CFrame.Rotation)
	r.AssemblyLinearVelocity = Vector3.zero
	Carry.resetAnchor(player)
end

local function record(e: any)
	table.insert(Hazards.stats.hits, e)
	if #Hazards.stats.hits > 100 then
		table.remove(Hazards.stats.hits, 1)
	end
end

local function step()
	if next(tracks) == nil then
		return
	end
	local force = TestHooks.get("LogForce")
	if force == "clear" then
		return
	end
	local t = Zones.now()
	local clock = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local r = Bag.root(player)
		if r then
			local pos = r.Position
			for id, track in pairs(tracks) do
				if SharedHazards.inStripId(id, track, pos) then
					local hit, vol
					if force == "hit" then
						hit, vol = true, nil
					else
						hit, vol = SharedHazards.hitsId(id, track, pos, t)
					end
					if hit then
						local fromL = if vol then vol.l else 0
						if Carry.isCarrying(player) then
							local ground = Vector3.new(pos.X, pos.Y - SharedHazards.ROOT_TO_FEET, pos.Z)
							if Carry.drop(player, ground, "hazard") then
								record({ userId = player.UserId, hazardId = id, at = t, pos = pos, forced = force == "hit", carrying = true })
								push(player, track, fromL, Config.Carry.DROP_PUSH)
								lastPush[player] = clock
							end
						elseif clock - (lastPush[player] or -math.huge) >= Config.Hazards.PUSH_COOLDOWN_S and force ~= "hit" then
							Hazards.stats.pushes += 1
							record({ userId = player.UserId, hazardId = id, at = t, pos = pos, forced = false, carrying = false })
							push(player, track, fromL, Config.Hazards.SMALL_PUSH)
							lastPush[player] = clock
						end
						break -- one hazard per player per step
					end
				end
			end
		end
	end
end

function Hazards.start()
	for _, m in ipairs(CollectionService:GetTagged("HFB_Hazard")) do
		register(m)
	end
	CollectionService:GetInstanceAddedSignal("HFB_Hazard"):Connect(register)
	CollectionService:GetInstanceRemovedSignal("HFB_Hazard"):Connect(function(m)
		local id = m:GetAttribute("HazardId")
		if typeof(id) == "number" and tracks[id] then
			-- another model with the same id may still be in the world
			tracks[id] = nil
			for _, o in ipairs(CollectionService:GetTagged("HFB_Hazard")) do
				if o ~= m and o:GetAttribute("HazardId") == id then
					register(o)
				end
			end
		end
	end)
	local missing = {}
	for _, id in ipairs(SharedHazards.IDS) do
		if not tracks[id] then
			table.insert(missing, tostring(id))
		end
	end
	if #missing > 0 then
		-- not a warning: the place may be a slice without every zone (studio/BuildHazards.lua adds 2..6)
		print("[HFB] Hazards: no hazard model for id " .. table.concat(missing, ", ") .. " (tag HFB_Hazard)")
	end
	Players.PlayerRemoving:Connect(function(p)
		lastPush[p] = nil
	end)
	RunService.Heartbeat:Connect(step)
end

return Hazards
