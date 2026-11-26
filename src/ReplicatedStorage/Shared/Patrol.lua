--!strict
-- Shared/Patrol: where a zone boss stands at a server time (the manager's P5, "Bosses walk back and forth along their
-- region"; m2-contract.md section E, TEAM CALL M2-P4). Pure and the same on both sides: the server tests Fight.Start
-- against it (Systems/Zones.bossPosition), the client draws the walk from it (M2-12). Nothing is replicated per frame.
--
-- Patrol.position(anchor, patrol, serverTime) -> (position, facing)
--   Ping-pong along anchor.RightVector through anchor.Position. leg = 2 x halfLen / speed, T = 2 x (leg + pauseS),
--   t = (serverTime + phase) % T: [0, leg) walks -halfLen -> +halfLen facing +Right, then a pause at +halfLen facing
--   anchor.LookVector, then back facing -Right, then a pause at -halfLen facing anchor.LookVector.
-- Patrol.phase(padId, patrol): (djb2(padId) % 1000) / 1000 x T (the server sends it in Zones.Pads).
-- Patrol.anchor(padModel, lane): the pad's PatrolAnchor part's CFrame when the world has one (M3 region paths), else
--   the BossAnchor (or Ring) position facing the lane's centre line, so the walk runs along the lane.
local Patrol = {}

export type Params = { phase: number, halfLen: number, speed: number, pauseS: number }
export type Lane = { origin: Vector3, axis: Vector3 }

function Patrol.leg(p: Params): number
	return 2 * p.halfLen / p.speed
end

function Patrol.period(p: Params): number
	return 2 * (Patrol.leg(p) + p.pauseS)
end

-- djb2 over the bytes, kept below 2^24 so it is exact in a double on both sides.
function Patrol.hash(s: string): number
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 16777216
	end
	return h
end

function Patrol.phase(padId: string, p: { halfLen: number, speed: number, pauseS: number }): number
	local T = 2 * (2 * p.halfLen / p.speed + p.pauseS)
	return (Patrol.hash(padId) % 1000) / 1000 * T
end

-- Offset along the axis (studs, -halfLen..+halfLen) and the travel sign (+1, -1, or 0 while paused).
function Patrol.offset(p: Params, serverTime: number): (number, number)
	local leg = Patrol.leg(p)
	local T = 2 * (leg + p.pauseS)
	local t = (serverTime + p.phase) % T
	if t < leg then
		return -p.halfLen + p.speed * t, 1
	elseif t < leg + p.pauseS then
		return p.halfLen, 0
	elseif t < 2 * leg + p.pauseS then
		return p.halfLen - p.speed * (t - leg - p.pauseS), -1
	end
	return -p.halfLen, 0
end

function Patrol.position(anchor: CFrame, p: Params, serverTime: number): (Vector3, Vector3)
	local x, dir = Patrol.offset(p, serverTime)
	local pos = anchor.Position + anchor.RightVector * x
	local facing = if dir == 0 then anchor.LookVector else anchor.RightVector * dir
	return pos, facing
end

function Patrol.anchor(model: Instance, lane: Lane): CFrame?
	local pa = model:FindFirstChild("PatrolAnchor")
	if pa and pa:IsA("BasePart") then
		return pa.CFrame
	end
	local base = model:FindFirstChild("BossAnchor") or model:FindFirstChild("Ring")
	if not (base and base:IsA("BasePart")) then
		return nil
	end
	local pos = base.Position
	local axis = Vector3.new(lane.axis.X, 0, lane.axis.Z)
	axis = if axis.Magnitude > 1e-6 then axis.Unit else Vector3.new(0, 0, 1)
	-- the nearest point on the lane's centre line; look at it (perpendicular to the lane)
	local rel = Vector3.new(pos.X - lane.origin.X, 0, pos.Z - lane.origin.Z)
	local across = rel - axis * rel:Dot(axis)
	local look = if across.Magnitude > 1e-3 then -across.Unit else Vector3.new(axis.Z, 0, -axis.X)
	return CFrame.lookAt(pos, pos + look)
end

return Patrol
