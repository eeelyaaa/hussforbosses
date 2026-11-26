--!strict
-- Systems/Hazards: the server's hit test for the zone hazards (brief system 6; m1-contract.md sections B, E, L).
-- M1: zone 1's Rolling Log. Nothing moves on the server: the log's position is Shared/Hazards' pure function of
-- Zones.now() (server time + the ClockOffset hook); clients animate the model from the same function and the
-- Zones.Clock they receive. No per-frame position crosses the network.
--
-- Each Heartbeat step the server tests every character on the log's track:
--   * a carrier the log hits (Shared/Hazards.hits, tolerance in the player's favour): the boss drops where the
--     carrier stood (Carry.drop) and the carrier is pushed back DROP_PUSH studs along the lane, away from the
--     log's line (TEAM CALL M1-11d: along the lane, so the push never crosses the lane walls; "back" = the side
--     the carrier is on, so they lose ground), no stun;
--   * anyone else the log hits: a small push (brief "a small push only"), at most once per PUSH_COOLDOWN.
-- The 0.6 s warning (Config.Hazards.WARN_S) is the client's look, not a server rule.
-- Hook LogForce (config, Studio only): "hit" = every character in the log's crossing strip is hit now;
-- "clear" = the log never reaches anyone.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	if typeof(id) ~= "number" or id ~= 1 then
		return -- M1: the Rolling Log only
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

-- Moves the character `dist` studs along the lane, away from the log's line (flat, keeps rotation and height).
local function push(player: Player, track: SharedHazards.Track, dist: number)
	local r = Bag.root(player)
	local ch = player.Character
	if not r or not ch then
		return
	end
	local side = (r.Position - track.home.Position):Dot(track.along)
	local dir = if side >= 0 then track.along else -track.along
	local target = r.Position + dir * dist
	-- stay inside the lane's walls across
	local across = (target - track.home.Position):Dot(track.across)
	local lim = track.laneWidth / 2 - SharedHazards.BODY_RADIUS
	if math.abs(across) > lim then
		target -= track.across * (across - math.clamp(across, -lim, lim))
	end
	ch:PivotTo(CFrame.new(target) * r.CFrame.Rotation)
	r.AssemblyLinearVelocity = Vector3.zero
	Carry.resetAnchor(player)
end

local function step()
	local track = tracks[1]
	if not track then
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
			local hit = if force == "hit" then SharedHazards.inStrip(track, pos) else SharedHazards.hits(track, pos, t)
			if hit then
				if Carry.isCarrying(player) then
					-- the boss lies where it fell: on the ground under the carrier
					local ground = Vector3.new(pos.X, pos.Y - SharedHazards.ROOT_TO_FEET, pos.Z)
					if Carry.drop(player, ground) then
						table.insert(Hazards.stats.hits, { userId = player.UserId, at = t, pos = pos, forced = force == "hit", carrying = true })
						push(player, track, Config.Carry.DROP_PUSH)
						lastPush[player] = clock
					end
				elseif clock - (lastPush[player] or -math.huge) >= Config.Hazards.PUSH_COOLDOWN_S and force ~= "hit" then
					Hazards.stats.pushes += 1
					table.insert(Hazards.stats.hits, { userId = player.UserId, at = t, pos = pos, forced = false, carrying = false })
					push(player, track, Config.Hazards.SMALL_PUSH)
					lastPush[player] = clock
				end
				if #Hazards.stats.hits > 100 then
					table.remove(Hazards.stats.hits, 1)
				end
			end
		end
	end
end

function Hazards.start()
	local CollectionService = game:GetService("CollectionService")
	for _, m in ipairs(CollectionService:GetTagged("HFB_Hazard")) do
		register(m)
	end
	CollectionService:GetInstanceAddedSignal("HFB_Hazard"):Connect(register)
	if not tracks[1] then
		warn("[HFB] Hazards: no Hazard_Log (tag HFB_Hazard, HazardId 1) in the world; the log never hits")
	end
	Players.PlayerRemoving:Connect(function(p)
		lastPush[p] = nil
	end)
	RunService.Heartbeat:Connect(step)
end

return Hazards
