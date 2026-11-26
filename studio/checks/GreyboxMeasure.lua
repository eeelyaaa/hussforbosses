if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-05: measures the greybox slice against base-layout.md section 5 (plot 1). Edit mode, after BuildSlice.lua.
--   require(game.ServerStorage.DevSync:Clone()).run("checks/GreyboxMeasure.lua")
local PathfindingService = game:GetService("PathfindingService")
local WALK, CARRY, FAST = 16, 12, 16
local Plot = workspace.Plots.Plot1
local bp = Plot.BagPad.Position
local door = Vector3.new(96, 0, Plot.Entrance.Position.Z)       -- the layout's door point on the fence line
local gate = Vector3.new(206, 0, 234)                            -- layout GATE_C
local ringC = workspace.Zones.Z1.Pads.Fixed.Ring.Position
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function d(a, b) return (flat(a) - flat(b)).Magnitude end
local function p(...) print("GreyboxMeasure:", ...) end

local inside = d(bp, door)
local toGate = inside + d(door, gate)
local gateToRing = d(gate, ringC)
local toPad = inside + d(door, gate) + gateToRing - 6
p(("bag pad centre -> entrance: %.1f"):format(inside))
p(("bag pad -> gate (via door, to gate centre): %.1f studs, %.2f s walk"):format(toGate, toGate / WALK))
p(("gate -> fixed pad centre: %.1f; ring radius 6 so run ends at the ring edge"):format(gateToRing))
p(("run to the fixed pad ring: %.1f studs, %.2f s at walk 16"):format(toPad, toPad / WALK))
p(("carry home (same path): %.2f s at carry 12, %.2f s with Fast Carry (16)"):format(toPad / CARRY, toPad / FAST))
-- a straight door -> gate line: does it cross the plot or the wall? (it is the layout's polyline)
-- real walkable path with PathfindingService (agent radius 2, height 5)
local okp, err = pcall(function()
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
	local function len(a, b)
		path:ComputeAsync(a, b)
		if path.Status ~= Enum.PathStatus.Success then return nil, tostring(path.Status) end
		local w, t = path:GetWaypoints(), 0
		for i = 2, #w do t += (flat(w[i].Position) - flat(w[i - 1].Position)).Magnitude end
		return t
	end
	local start = Vector3.new(bp.X, 2, bp.Z)
	local dir = (flat(ringC) - flat(gate)).Unit
	local ringEdge = Vector3.new(ringC.X, 2, ringC.Z) - Vector3.new(dir.X, 0, dir.Z) * 6
	local a, ea = len(start, Vector3.new(gate.X, 2, gate.Z))
	local b, eb = len(start, ringEdge)
	p("PathfindingService bag pad -> gate centre:", a and ("%.1f studs"):format(a) or ea)
	p("PathfindingService bag pad -> ring edge:", b and ("%.1f studs, %.2f s walk, %.2f s carry, %.2f s Fast Carry"):format(b, b / WALK, b / CARRY, b / FAST) or eb)
end)
if not okp then p("PathfindingService unavailable here:", tostring(err)) end

-- sight line over the 4-stud wall. Invisible blockers (Transparency 1) are excluded: the camera does not see them.
-- (Measured: a Raycast still hits a CanQuery=false part that has CanCollide on; see m1-greybox.md.)
-- Eye = standing eye on the bag pad. Camera estimate = the default third-person camera turned to look at the target:
-- 12.5 studs behind the head along the view direction, 2 studs above the eye.
local eye = workspace.Sight.BagPadEye.Position
local na = workspace.Zones.Z1.Pads.Fixed.NumberAnchor.Position
local wm = workspace.Sight.WindmillStandIn
local wmTop = wm.Position + Vector3.new(0, wm.Size.Y / 2 - 1, 0)
local targets = {
	{ "fixed pad number anchor", na },
	{ "fixed pad ring centre", ringC + Vector3.new(0, 2, 0) },
	{ "windmill stand-in top", wmTop },
	{ "windmill stand-in middle", wm.Position },
}
local ignore = {}
for _, inst in ipairs(workspace:GetDescendants()) do
	if inst:IsA("BasePart") and inst.Transparency >= 1 then table.insert(ignore, inst) end
end
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
rp.FilterDescendantsInstances = ignore
local function cast(from, to)
	local r = workspace:Raycast(from, to - from, rp)
	return r == nil, r and r.Instance:GetFullName() .. " at " .. tostring(r.Position)
end
for _, t in ipairs(targets) do
	local dir = flat(t[2] - eye).Unit
	local cam = eye - dir * 12.5 + Vector3.new(0, 2, 0)
	local o1, w1 = cast(eye, t[2])
	local o2, w2 = cast(cam, t[2])
	p(("sight to %s: standing eye %s%s; camera %s%s"):format(t[1], o1 and "CLEAR" or "BLOCKED", o1 and "" or (" by " .. w1), o2 and "CLEAR" or "BLOCKED", o2 and "" or (" by " .. w2)))
end
local function heightAtZ(from, to, z) local t = (z - from.Z) / (to.Z - from.Z) return from.Y + (to.Y - from.Y) * t, from.X + (to.X - from.X) * t end
local h, x = heightAtZ(eye, na, 235)
p(("line eye -> number anchor crosses the front wall (Z 235) at X %.1f, height %.1f (wall top 4): clearance %.1f"):format(x, h, h - 4))
h, x = heightAtZ(eye, wmTop, 235)
p(("line eye -> windmill top crosses the wall at X %.1f, height %.1f: clearance %.1f"):format(x, h, h - 4))
p(("eye height %.1f, wall top 4, wall is %.0f studs from the eye"):format(eye.Y, 235 - eye.Z))
-- the name board: does it sit across the view from the bag pad toward the gate?
local nb = Plot.NameBoard
p(("name board: X %.1f..%.1f, Z %.1f..%.1f, Y %.1f..%.1f"):format(nb.Position.X - nb.Size.X / 2, nb.Position.X + nb.Size.X / 2, nb.Position.Z - nb.Size.Z / 2, nb.Position.Z + nb.Size.Z / 2, nb.Position.Y - nb.Size.Y / 2, nb.Position.Y + nb.Size.Y / 2))
