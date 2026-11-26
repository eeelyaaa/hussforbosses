--!nonstrict
-- Moves/_lib: helpers shared by the M2 body-type sets (tailed, swayer, biped) and their signatures.
-- Structure only: fractions of H, degrees, seconds. Not a move set (Moves.get never loads it).
--
-- The joints are flat (M1-09 / B11): every group's Motor6D hangs off Body, so a group does not inherit its parent's
-- turn. Where a group rides another (TailB on TailA, Head and the fists on Upper), the set is authored in the
-- natural way (the parent's turn, the child's own turn LOCAL to the parent) and `expand` turns it into flat poses:
-- the child gets the parent's rotation composed with its own, and the shift of its pivot as the parent turns about the
-- parent's pivot (from the creature's pivot fractions, `Geo`). Exact at the keys, a straight line between them.
local Lib = {}
local rad, deg = math.rad, math.deg

function Lib.rest()
	return { p = { 0, 0, 0 }, r = { 0, 0, 0 }, s = 1 }
end

function Lib.K(t, ease, pose)
	return { t = t, ease = ease, pose = pose }
end

function Lib.merge(a, b)
	for k, v in pairs(b) do
		a[k] = v
	end
	return a
end

function Lib.sorted(keys)
	table.sort(keys, function(a, b)
		return a.t < b.t
	end)
	return keys
end

local function vec(a)
	return a and Vector3.new(a[1], a[2], a[3]) or Vector3.zero
end

local function isZero(a)
	return a == nil or (a[1] == 0 and a[2] == 0 and a[3] == 0)
end

-- The flat pose of `child` while `parent` has pose pp (p, r) and the child's own local pose is cp (p, r, s).
function Lib.follow(geo, parent, child, pp, cp)
	local cr = cp.r or { 0, 0, 0 }
	if isZero(pp.r) then
		local p = vec(pp.p) + vec(cp.p)
		return { p = { p.X, p.Y, p.Z }, r = { cr[1], cr[2], cr[3] }, s = cp.s }
	end
	local U, c = vec(geo[parent]), vec(geo[child])
	local pr = pp.r
	local Rp = CFrame.Angles(rad(pr[1]), rad(pr[2]), rad(pr[3]))
	local Rc = CFrame.Angles(rad(cr[1]), rad(cr[2]), rad(cr[3]))
	local rel = c - U
	local pos = vec(pp.p) + (Rp * rel - rel) + Rp * vec(cp.p)
	local ex, ey, ez = (Rp * Rc):ToEulerAnglesXYZ()
	return { p = { pos.X, pos.Y, pos.Z }, r = { deg(ex), deg(ey), deg(ez) }, s = cp.s }
end

-- nest = { parent = "Upper", children = { "Head", "FistL", "FistR" } }. Every key (or a key at the same time) that
-- poses the parent gives each child its flat pose; a child posed where the parent is not is an authoring error.
function Lib.expand(keys, geo, nest)
	local function near(a, b)
		return math.abs(a - b) < 1e-6
	end
	local parentAt = function(t)
		for _, k in ipairs(keys) do
			if near(k.t, t) and k.pose[nest.parent] then
				return k.pose[nest.parent]
			end
		end
		return nil
	end
	for _, child in ipairs(nest.children) do
		for _, k in ipairs(keys) do
			local cp = k.pose[child]
			local pp = parentAt(k.t)
			if cp and not pp then
				error(("Moves: %s keyed at t=%.3f without %s (authoring error)"):format(child, k.t, nest.parent), 0)
			end
			if cp then
				k.pose[child] = Lib.follow(geo, nest.parent, child, pp, cp)
			end
		end
		for _, k in ipairs(keys) do
			if k.pose[nest.parent] and not k.pose[child] then
				local has = false
				for _, k2 in ipairs(keys) do
					if near(k2.t, k.t) and k2.pose[child] then
						has = true
					end
				end
				if not has then
					k.pose[child] = Lib.follow(geo, nest.parent, child, k.pose[nest.parent], {})
				end
			end
		end
	end
	return keys
end

-- Bob: n cycles of 1.2 s, Sine, Body up by amp H, Head the other way (half as much).
function Lib.bob(keys, amp, cycles)
	for c = 0, cycles - 1 do
		local t = c * 1.2
		table.insert(keys, Lib.K(t + 0.6, "Sine", { Body = { p = { 0, amp, 0 } }, Head = { p = { 0, -amp * 0.5, 0 } } }))
		table.insert(keys, Lib.K(t + 1.2, "Sine", { Body = Lib.rest(), Head = Lib.rest() }))
	end
end

-- One fist jab: out 0.08 H in 0.05 s, back in 0.08 s (the manager's rhythm; style guide section 5).
function Lib.jab(keys, group, t0)
	table.insert(keys, Lib.K(t0, "Quad", { [group] = Lib.rest() }))
	table.insert(keys, Lib.K(t0 + 0.05, "Quad", { [group] = { p = { 0, 0, -0.08 } } }))
	table.insert(keys, Lib.K(t0 + 0.13, "Quad", { [group] = Lib.rest() }))
end

function Lib.triplet(keys, t0)
	Lib.jab(keys, "FistL", t0)
	Lib.jab(keys, "FistR", t0 + 0.21)
	Lib.jab(keys, "FistL", t0 + 0.40)
end

-- The boss leans back 6 and dips 0.05 H, squashed (wind-up) then hops a step in and lands (impact). The squat
-- stomper's Body and Head keys (squat.lua _strike) without the jaw: windup is the wind-up length in seconds.
-- Returns keys for Body and Head only, from 0 to the impact hold end.
function Lib.strikeBody(windup)
	local ti = windup + 0.06
	local th = ti + 0.06
	local dip = {
		Body = { p = { 0, -0.05, 0 }, r = { 6, 0, 0 }, s = { 1.1, 0.88, 1.1 } },
		Head = { r = { 6, 0, 0 } },
	}
	local function copy(t)
		return { Body = { p = t.Body.p, r = t.Body.r, s = t.Body.s }, Head = { r = t.Head.r } }
	end
	local land = {
		Body = { p = { 0, 0, -0.2 }, s = { 1.08, 0.92, 1.08 } },
		Head = { r = { -3, 0, 0 } },
	}
	return {
		Lib.K(0, "Quad", { Body = Lib.rest(), Head = Lib.rest() }),
		Lib.K(windup - 0.05, "Quad", copy(dip)),
		Lib.K(windup, "Quad", copy(dip)),
		Lib.K(windup + 0.03, "Quad", { Body = { p = { 0, 0.05, -0.1 }, r = { -2, 0, 0 }, s = { 0.98, 1.04, 0.98 } } }),
		Lib.K(ti, "Back", copy(land)),
		Lib.K(th, "Quad", copy(land)),
	}
end

-- Carry rock (every boss): leans back 8 degrees and rocks 4 degrees each way on a 1.0 s stride. Nothing else moves.
function Lib.carryRock()
	return {
		length = 1.0,
		loop = true,
		keys = {
			Lib.K(0.25, "Sine", { Body = { r = { 8, 0, 4 } } }),
			Lib.K(0.5, "Sine", { Body = { r = { 8, 0, 0 } } }),
			Lib.K(0.75, "Sine", { Body = { r = { 8, 0, -4 } } }),
			Lib.K(1.0, "Sine", { Body = { r = { 8, 0, 0 } } }),
		},
	}
end

return Lib
