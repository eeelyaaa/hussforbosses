--!strict
-- Shared/Hazards: where each zone hazard is, as a pure function of the server clock (brief system 6;
-- m1-contract.md B, E; m2-contract.md C). Server (Systems/Hazards) and client (Controllers/Hazards) call the same
-- functions with the same clock, so nothing per frame crosses the network: the clock is Zones.Clock /
-- Workspace:GetServerTimeNow() (+ the ClockOffset hook on the server), the numbers are Config.Hazards.
-- Structure only: no names, colours or asset ids (the skin's).
--
-- THE TRACK (where a hazard's lane is) comes from the world, never from a position search:
--   * home  : CFrame attribute `TrackHome` on the hazard Model (tag HFB_Hazard, attribute HazardId 1..6). For hazard 1
--             (the Rolling Log, M1) home is the log's centre at its rolling height; for 2..6 (M2-11) home is the point
--             on the lane's centre line, at the lane's top, in the middle of the 30-stud throat. If the attribute is
--             missing the server stamps the model's pivot as built (studio/BuildHazards.lua sets it for 2..6).
--   * across: world X (every lane runs along world Z); attribute `TrackAcross` overrides. along = up x across, which
--             for across = +X is world -Z: TOWARD THE BASES. So a positive along offset is nearer the hub.
--   * laneWidth: attribute `LaneWidth`, else LANE_WIDTH (the brief's 36-wide throat).
--
-- THE SHAPES. Each hazard at time t is a list of volumes in the track's own frame (a = across, l = along, y = up from
-- home), each { shape = "box" | "ball" | "cyl", a, l, y, ha, hl, hy (box half sizes) | r (ball, cyl), and for "cyl"
-- an axis along the lane with half length hl }. Hazards.volumes(id, track, t) returns them; Hazards.toWorld(track, v)
-- gives a world CFrame (the client draws stand-ins and the 0.6 s warning from volumes(id, track, t + WARN_S)).
-- A character is a vertical segment from root - ROOT_TO_FEET to root + ROOT_TO_HEAD with BODY_RADIUS.
-- Hazards.hitsId(id, track, rootPos, t): the body is more than HAZARD_TOLERANCE inside a volume (in the player's
-- favour). Paths (TEAM CALL M2-11-1 for the numbers the brief leaves open):
--   1 Rolling Log      across, wait 1 s each side, crosses in 3 s (M1).
--   2 Tumble Cactus    a ball 8 wide enters the throat's far end every 6 s and bounces 30 studs toward the bases at
--                      14 studs/s (2.14 s), zigzagging across between the walls (two legs); the start side alternates.
--   3 Swinging Anchor  the head swings across the middle 24 studs: offset = 10 x cos(pi t / 3).
--   4 Sliding Ice Block a 10 x 10 block slides side to side at 20 studs/s (1.3 s), waits 1 s at each side.
--   5 Lava Burst Row   six 6-wide tiles; tile k glows from k x 0.52 s for 0.8 s, then erupts 0.6 s; the next 4 s
--                      sweep runs back (tile 5 first). At most two tiles erupt at once; glowing tiles do not hit.
--   6 Orbit Meteor     a ball of radius 3, 3.5 above the lane, on a circle of radius 14 round home, a lap every 4 s.
local Config = require(script.Parent.Config)

local Hazards = {}

-- The walled throat of every zone lane is 36 wide (brief system 5 / 6), and 30 long. Structure, not tunables.
Hazards.LANE_WIDTH = 36
Hazards.THROAT_LEN = 30
-- Half-width of a character's body for the hit test (a carrier is about 2 to 3 wide: brief system 6).
Hazards.BODY_RADIUS = 1.25
-- A character's root to feet and root to head, studs (R15 default: hip 2 + half root 1 = 3 down; head ~2.5 up).
Hazards.ROOT_TO_FEET = 3
Hazards.ROOT_TO_HEAD = 2.5

Hazards.IDS = { 1, 2, 3, 4, 5, 6 }

export type Track = {
	home: CFrame,
	across: Vector3, -- unit, flat
	along: Vector3, -- unit, flat (toward the bases for across = +X)
	laneWidth: number,
}
export type Volume = {
	shape: string,
	a: number,
	l: number,
	y: number,
	ha: number?,
	hl: number?,
	hy: number?,
	r: number?,
	tile: number?, -- lava: which tile
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

-- The track of a hazard model: from its TrackHome attribute, else its pivot (server side, before anything moves it).
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

-- ------------------------------------------------------------------------------------------------ side to side
-- A block of width w crossing a lane of width W: wait at -side, cross, wait at +side, cross back. (offset, phase, v)
local function sideToSide(t: number, W: number, w: number, crossS: number, waitS: number): (number, string, number)
	local half = math.max(0, W - w) / 2
	local period = 2 * (waitS + crossS)
	local p = t % period
	if p < waitS then
		return -half, "waitMinus", 0
	end
	p -= waitS
	local v = if crossS > 0 then (2 * half) / crossS else 0
	if p < crossS then
		return -half + v * p, "toPlus", v
	end
	p -= crossS
	if p < waitS then
		return half, "waitPlus", 0
	end
	p -= waitS
	return half - v * p, "toMinus", -v
end

-- ------------------------------------------------------------------------------------------------ 1 Rolling Log (M1 API)
local function log()
	return Config.Hazards.LOG
end

function Hazards.logPeriod(): number
	local L = log()
	return 2 * (L.wait_s + L.cross_s)
end

function Hazards.logTravel(laneWidth: number?): number
	return math.max(0, (laneWidth or Hazards.LANE_WIDTH) - log().thickness)
end

-- (offset across from the lane centre, phase, velocity across). Pure.
function Hazards.logOffset(t: number, laneWidth: number?): (number, string, number)
	local L = log()
	return sideToSide(t, laneWidth or Hazards.LANE_WIDTH, L.thickness, L.cross_s, L.wait_s)
end

function Hazards.logCFrame(track: Track, t: number): CFrame
	local off = Hazards.logOffset(t, track.laneWidth)
	return track.home + track.across * off
end

-- ------------------------------------------------------------------------------------------------ 2 Tumble Cactus
-- (active, along offset, across offset, height of the ball's centre above home, spawn number). Pure.
function Hazards.cactusAt(t: number, laneWidth: number?): (boolean, number, number, number, number)
	local C = Config.Hazards.CACTUS
	local W = laneWidth or Hazards.LANE_WIDTH
	local n = math.floor(t / C.every_s)
	local dur = C.run / C.speed
	local into = t - n * C.every_s
	if into >= dur then
		return false, 0, 0, 0, n
	end
	local u = into / dur -- 0..1 through the throat
	local l = -C.run / 2 + u * C.run -- far end (deeper zone) to near end (toward the bases)
	local A = math.max(0, W - C.width) / 2
	local side = if n % 2 == 0 then 1 else -1
	local x = u * C.zigs
	local tri = 1 - 2 * math.abs((x % 2) - 1) -- -1 .. 1 .. -1 ...
	local a = side * A * tri
	local y = C.width / 2 + C.bounce * math.abs(math.sin(math.pi * x))
	return true, l, a, y, n
end

-- ------------------------------------------------------------------------------------------------ 3 Swinging Anchor
function Hazards.anchorOffset(t: number): number
	local A = Config.Hazards.ANCHOR
	local amp = math.max(0, A.cover / 2 - A.head_across / 2)
	return amp * math.cos(math.pi * t / A.swing_s)
end

-- ------------------------------------------------------------------------------------------------ 4 Sliding Ice Block
function Hazards.iceOffset(t: number, laneWidth: number?): (number, string, number)
	local I = Config.Hazards.ICE
	local W = laneWidth or Hazards.LANE_WIDTH
	local travel = math.max(0, W - I.size)
	return sideToSide(t, W, I.size, travel / I.speed, I.wait_s)
end

-- ------------------------------------------------------------------------------------------------ 5 Lava Burst Row
function Hazards.lavaPeriod(): number
	return 2 * Config.Hazards.LAVA.sweep_s
end

-- Each tile's state at t: an array of "idle" | "glow" | "erupt" (1-based tiles, tile 1 at the -across wall). Pure.
function Hazards.lavaTiles(t: number): { string }
	local V = Config.Hazards.LAVA
	local n = V.tiles
	local step = if n > 1 then (V.sweep_s - V.glow_s - V.erupt_s) / (n - 1) else 0
	local p = t % (2 * V.sweep_s)
	local out = table.create(n, "idle")
	for k = 0, n - 1 do
		for _, start in ipairs({ k * step, V.sweep_s + (n - 1 - k) * step }) do
			local d = p - start
			if d < 0 then
				d += 2 * V.sweep_s -- a window that wraps past the period's end
			end
			if d < V.glow_s then
				out[k + 1] = if out[k + 1] == "erupt" then "erupt" else "glow"
			elseif d < V.glow_s + V.erupt_s then
				out[k + 1] = "erupt"
			end
		end
	end
	return out
end

-- ------------------------------------------------------------------------------------------------ 6 Orbit Meteor
function Hazards.meteorAt(t: number): (number, number)
	local M = Config.Hazards.METEOR
	local th = 2 * math.pi * (t % M.lap_s) / M.lap_s
	return M.circle_r * math.cos(th), M.circle_r * math.sin(th)
end

-- ------------------------------------------------------------------------------------------------ volumes
-- The solid parts of hazard `id` at time t, in the track's frame. Pure.
function Hazards.volumes(id: number, track: Track, t: number): { Volume }
	local W = track.laneWidth
	local H = Config.Hazards
	if id == 1 then
		local L = H.LOG
		return { { shape = "cyl", a = Hazards.logOffset(t, W), l = 0, y = 0, r = L.thickness / 2, hl = L.length / 2 } }
	elseif id == 2 then
		local on, l, a, y = Hazards.cactusAt(t, W)
		if not on then
			return {}
		end
		return { { shape = "ball", a = a, l = l, y = y, r = H.CACTUS.width / 2 } }
	elseif id == 3 then
		local A = H.ANCHOR
		return { { shape = "box", a = Hazards.anchorOffset(t), l = 0, y = A.lift + A.head_height / 2, ha = A.head_across / 2, hl = A.head_along / 2, hy = A.head_height / 2 } }
	elseif id == 4 then
		local I = H.ICE
		return { { shape = "box", a = Hazards.iceOffset(t, W), l = 0, y = I.height / 2, ha = I.size / 2, hl = I.size / 2, hy = I.height / 2 } }
	elseif id == 5 then
		local V = H.LAVA
		local tw = W / V.tiles
		local out = {}
		for k, st in ipairs(Hazards.lavaTiles(t)) do
			if st == "erupt" then
				table.insert(out, { shape = "box", a = -W / 2 + tw * (k - 0.5), l = 0, y = V.height / 2, ha = tw / 2, hl = V.tile_along / 2, hy = V.height / 2, tile = k })
			end
		end
		return out
	elseif id == 6 then
		local M = H.METEOR
		local a, l = Hazards.meteorAt(t)
		return { { shape = "ball", a = a, l = l, y = M.height, r = M.radius } }
	end
	return {}
end

-- World CFrame of a volume's centre (axes: X = across, Y = up, Z = -along, i.e. the track's own frame). Pure.
function Hazards.toWorld(track: Track, v: Volume): CFrame
	local pos = track.home.Position + track.across * v.a + track.along * v.l + Vector3.yAxis * v.y
	return CFrame.fromMatrix(pos, track.across, Vector3.yAxis)
end

-- The body's local coordinates: (a, l, y of the root) relative to home.
local function localOf(track: Track, rootPos: Vector3): (number, number, number)
	local d = rootPos - track.home.Position
	return d:Dot(track.across), d:Dot(track.along), d.Y
end

-- Distance from the body (vertical segment, BODY_RADIUS) to one volume's surface, studs (negative = inside). Pure.
function Hazards.volumeGap(v: Volume, pa: number, pl: number, py: number): number
	local y0, y1 = py - Hazards.ROOT_TO_FEET, py + Hazards.ROOT_TO_HEAD
	local R = Hazards.BODY_RADIUS
	if v.shape == "box" then
		local ha, hl, hy = v.ha :: number, v.hl :: number, v.hy :: number
		local ia, il = math.abs(pa - v.a) - ha, math.abs(pl - v.l) - hl
		local dx, dz = math.max(ia, 0), math.max(il, 0)
		local dy = math.max(0, (v.y - hy) - y1, y0 - (v.y + hy))
		if dx == 0 and dz == 0 and dy == 0 then
			return -(R + math.min(-ia, -il)) -- inside the footprint and the height: the shallower way out
		end
		return math.sqrt(dx * dx + dz * dz + dy * dy) - R
	elseif v.shape == "ball" then
		local yc = math.clamp(v.y, y0, y1)
		local da, dl, dy = pa - v.a, pl - v.l, yc - v.y
		return math.sqrt(da * da + dl * dl + dy * dy) - (v.r :: number) - R
	else -- "cyl": axis along the lane at height v.y
		local yc = math.clamp(v.y, y0, y1)
		local da, dy = pa - v.a, yc - v.y
		local radial = math.sqrt(da * da + dy * dy) - (v.r :: number) - R
		local endGap = math.abs(pl - v.l) - (v.hl :: number) - R
		return math.max(radial, endGap)
	end
end

-- The nearest volume of hazard `id` to the body at t and its gap (nil, math.huge when none). Pure.
function Hazards.nearest(id: number, track: Track, rootPos: Vector3, t: number): (Volume?, number)
	local pa, pl, py = localOf(track, rootPos)
	local best, gap = nil, math.huge
	for _, v in ipairs(Hazards.volumes(id, track, t)) do
		local g = Hazards.volumeGap(v, pa, pl, py)
		if g < gap then
			best, gap = v, g
		end
	end
	return best, gap
end

-- Does hazard `id` hit a character whose root is at rootPos, at time t? Tolerance in the player's favour. Pure.
function Hazards.hitsId(id: number, track: Track, rootPos: Vector3, t: number): (boolean, Volume?)
	local v, gap = Hazards.nearest(id, track, rootPos, t)
	return gap < -Config.Hazards.HAZARD_TOLERANCE, v
end

-- Half the along-lane depth of the band hazard `id` ever sweeps (for the strip test and the check). Pure.
function Hazards.reach(id: number): number
	local H = Config.Hazards
	if id == 1 then
		return H.LOG.length / 2
	elseif id == 2 then
		return H.CACTUS.run / 2 + H.CACTUS.width / 2
	elseif id == 3 then
		return H.ANCHOR.head_along / 2
	elseif id == 4 then
		return H.ICE.size / 2
	elseif id == 5 then
		return H.LAVA.tile_along / 2
	elseif id == 6 then
		return H.METEOR.circle_r + H.METEOR.radius
	end
	return 0
end

-- Is the point inside the band of lane hazard `id` sweeps at any time? (the LogForce = "hit" hook, and a cheap
-- prefilter before the exact test). Pure.
function Hazards.inStripId(id: number, track: Track, rootPos: Vector3): boolean
	local pa, pl, py = localOf(track, rootPos)
	local up = if id == 1 then 0 else 3 -- the log's home is at its axis height; the others' at the lane top
	return math.abs(pl) < Hazards.reach(id) + Hazards.BODY_RADIUS and math.abs(pa) <= track.laneWidth / 2 + Hazards.BODY_RADIUS
		and math.abs(py - up) < 12
end

-- M1 names, kept for the log (Controllers/Hazards and the M1 checks call them).
function Hazards.logGap(track: Track, rootPos: Vector3, t: number): number
	local _, gap = Hazards.nearest(1, track, rootPos, t)
	return gap
end
function Hazards.hits(track: Track, rootPos: Vector3, t: number): boolean
	return (Hazards.hitsId(1, track, rootPos, t))
end
function Hazards.inStrip(track: Track, rootPos: Vector3): boolean
	return Hazards.inStripId(1, track, rootPos)
end

-- The longest clear stretch across the lane (studs between body centres that are not hit, plus the body's width) at
-- along offset l and time t, for a body standing on the lane: the "always leaves a way through" measure. Pure.
function Hazards.clearWidth(id: number, track: Track, t: number, l: number, step: number?): number
	local s = step or 0.25
	local W = track.laneWidth
	local R = Hazards.BODY_RADIUS
	local vols = Hazards.volumes(id, track, t)
	local footY = if id == 1 then -log().thickness / 2 else 0 -- the lane top in the track's frame
	local py = footY + Hazards.ROOT_TO_FEET
	local best, run = 0, -1
	local a = -W / 2 + R
	while a <= W / 2 - R + 1e-9 do
		local free = true
		for _, v in ipairs(vols) do
			if Hazards.volumeGap(v, a, l, py) < 0 then
				free = false
				break
			end
		end
		if free then
			run = if run < 0 then 0 else run + s
			best = math.max(best, run + 2 * R)
		else
			run = -1
		end
		a += s
	end
	return best
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
