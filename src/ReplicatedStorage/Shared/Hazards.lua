--!strict
-- Shared/Hazards: where each zone hazard is, as a pure function of the server clock (brief system 6;
-- m1-contract.md sections B, E). Server (Systems/Hazards) and client (Controllers/Hazards, M1-14) call the same
-- functions with the same clock, so nothing per frame crosses the network: the clock is Zones.Clock /
-- Workspace:GetServerTimeNow() (+ the ClockOffset hook on the server), the numbers are Config.Hazards.
-- M1: zone 1's Rolling Log only. Structure only: no names, colours or asset ids (the skin's).
--
-- The Rolling Log (TEAM CALL M1-11a, from the brief's numbers): the log's axis runs ALONG the lane (12 studs
-- long), it is `thickness` (6) across, and it rolls ACROSS the lane between the two walls: centre offset from the
-- lane's centre line goes -travel/2 .. +travel/2 with travel = laneWidth - thickness (36 - 6 = 30), so it leaves
-- 30 studs free while it waits at a side and 15 each side mid-crossing (brief). One cycle =
-- 2 x (wait_s + cross_s) = 8 s: wait at the -side 1 s, cross 3 s (linear, it rolls), wait at the +side 1 s,
-- cross back 3 s. Phase 0 is server time 0, so every machine agrees with no anchor but the clock.
--
-- The track (where the lane is) comes from the world, never from a position search:
--   * home  : CFrame of the log's rest pose at the lane's centre line. The server stamps it on the model as the
--             attribute `TrackHome` (CFrame) at start, from the model's pivot as built (the builder puts the
--             Hazard_Log pivot on the lane's centre line at the crossing). Clients read the attribute, never the
--             (client-animated) pivot.
--   * across: the lane's cross direction, world X (every lane leaves the hub along world +Z: contract B, hub
--             frame); along = world Z. Never the model's rotation (a cylinder part's axis is its own X, so a log
--             turned to lie along the lane has a pivot whose RightVector is Z). Attribute `TrackAcross`
--             (Vector3) overrides it for a lane that does not run along Z.
--   * laneWidth: attribute `LaneWidth` on the model if set, else LANE_WIDTH (the brief's 36-wide throat).
local Config = require(script.Parent.Config)

local Hazards = {}

-- The walled throat of every zone lane is 36 wide (brief system 5 / 6). Structure, not a tunable.
Hazards.LANE_WIDTH = 36
-- Half-width of a character's body for the hit test (a carrier is about 2 to 3 wide: brief system 6).
Hazards.BODY_RADIUS = 1.25
-- A character's root to feet and root to head, studs (R15 default: hip 2 + half root 1 = 3 down; head ~2.5 up).
Hazards.ROOT_TO_FEET = 3
Hazards.ROOT_TO_HEAD = 2.5

export type Track = {
	home: CFrame, -- rest pose at the lane centre line (position = log centre, at its rolling height)
	across: Vector3, -- unit, flat
	along: Vector3, -- unit, flat
	laneWidth: number,
}

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-6 then f.Unit else Vector3.xAxis
end

-- Builds a track from a home CFrame (and optional overrides). Pure.
function Hazards.makeTrack(home: CFrame, across: Vector3?, laneWidth: number?): Track
	local a = flat(across or Vector3.xAxis)
	local along = flat(Vector3.yAxis:Cross(a)) -- right-handed: along x across = up
	return { home = home, across = a, along = along, laneWidth = laneWidth or Hazards.LANE_WIDTH }
end

-- The track of a Hazard_Log model: from its TrackHome attribute (stamped by the server), else its pivot (server
-- side, before anything moves it). nil when the model has neither.
function Hazards.trackOf(model: Instance): Track?
	local home = model:GetAttribute("TrackHome")
	if typeof(home) ~= "CFrame" then
		if model:IsA("Model") then
			home = model:GetPivot()
		else
			return nil
		end
	end
	local across = model:GetAttribute("TrackAcross")
	local width = model:GetAttribute("LaneWidth")
	return Hazards.makeTrack(
		home :: CFrame,
		if typeof(across) == "Vector3" then across else nil,
		if typeof(width) == "number" then width else nil
	)
end

-- The Rolling Log's numbers, read live from Config (tests override Config at runtime).
local function log()
	return Config.Hazards.LOG
end

-- Cycle length of the log, seconds.
function Hazards.logPeriod(): number
	local L = log()
	return 2 * (L.wait_s + L.cross_s)
end

-- Travel from one side to the other (studs, between the centre's two rest offsets).
function Hazards.logTravel(laneWidth: number?): number
	return math.max(0, (laneWidth or Hazards.LANE_WIDTH) - log().thickness)
end

-- Where the log is at server time t: (offset across from the lane centre, studs; phase name; velocity across,
-- studs/s). phase is "waitMinus" | "toPlus" | "waitPlus" | "toMinus". Pure function of t.
function Hazards.logOffset(t: number, laneWidth: number?): (number, string, number)
	local L = log()
	local half = Hazards.logTravel(laneWidth) / 2
	local period = Hazards.logPeriod()
	local p = t % period
	if p < L.wait_s then
		return -half, "waitMinus", 0
	end
	p -= L.wait_s
	if p < L.cross_s then
		local v = (2 * half) / L.cross_s
		return -half + v * p, "toPlus", v
	end
	p -= L.cross_s
	if p < L.wait_s then
		return half, "waitPlus", 0
	end
	p -= L.wait_s
	local v = (2 * half) / L.cross_s
	return half - v * p, "toMinus", -v
end

-- The log's CFrame at server time t on a track (the client poses the model with this; the roll angle is the
-- client's: distance / radius). Pure.
function Hazards.logCFrame(track: Track, t: number): CFrame
	local off = Hazards.logOffset(t, track.laneWidth)
	return track.home + track.across * off
end

-- Distance from a point (a character's root) to the log's surface at time t, studs (negative = inside).
-- The character is a vertical segment from feet to head with BODY_RADIUS; the log is a cylinder of diameter
-- `thickness` whose axis runs along the lane, `length` long. Pure.
function Hazards.logGap(track: Track, rootPos: Vector3, t: number): number
	local L = log()
	local centre = Hazards.logCFrame(track, t).Position
	local d = rootPos - centre
	local dAcross = d:Dot(track.across)
	local dAlong = math.abs(d:Dot(track.along))
	-- nearest point of the body's vertical segment to the axis height
	local feet = d.Y - Hazards.ROOT_TO_FEET
	local head = d.Y + Hazards.ROOT_TO_HEAD
	local dy = math.clamp(0, feet, head) -- the axis is at dy = 0 in this frame
	local radial = math.sqrt(dAcross * dAcross + dy * dy) - L.thickness / 2 - Hazards.BODY_RADIUS
	local endGap = dAlong - L.length / 2 - Hazards.BODY_RADIUS
	-- inside the cylinder's length: the radial gap decides; past an end: the larger of the two
	return math.max(radial, endGap)
end

-- Does the log hit a character whose root is at rootPos, at server time t? Tolerance (Config.Hazards
-- .HAZARD_TOLERANCE studs) counts in the player's favour: a hit needs the body to be that deep inside. Pure.
function Hazards.hits(track: Track, rootPos: Vector3, t: number): boolean
	return Hazards.logGap(track, rootPos, t) < -Config.Hazards.HAZARD_TOLERANCE
end

-- Is the point inside the log's crossing strip (the band of lane the log sweeps, any time)? For the LogForce
-- = "hit" hook: "the log is on the carrier's path now". Pure.
function Hazards.inStrip(track: Track, rootPos: Vector3): boolean
	local L = log()
	local d = rootPos - track.home.Position
	local dAcross = math.abs(d:Dot(track.across))
	local dAlong = math.abs(d:Dot(track.along))
	return dAlong < L.length / 2 + Hazards.BODY_RADIUS and dAcross <= track.laneWidth / 2 + Hazards.BODY_RADIUS
		and math.abs(d.Y) < 12
end

-- The hazard models in the world (tag HFB_Hazard), by HazardId. Either side.
function Hazards.models(): { [number]: Instance }
	local out = {}
	for _, m in ipairs(game:GetService("CollectionService"):GetTagged("HFB_Hazard")) do
		local id = m:GetAttribute("HazardId")
		if typeof(id) == "number" then
			out[id] = m
		end
	end
	return out
end

return Hazards
