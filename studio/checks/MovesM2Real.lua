if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-25 REAL-MESH version of the M2-22 check (checks/MovesM2.lua: box rigs). Needs SetupBosses.lua run first. Same assertions, on clones of the placed Boss_<id> models.
-- (original header) M2-22 play-mode check: the M2 boss move sets (tailed striker, rearing swayer, biped bruiser) and the five signatures, played through
-- BossMoves on BOX RIGS built from the real group boxes and pivots of the five M2 models (the meshes are not imported yet; mesh ids 0).
-- Run with the Studio MCP's run_script_in_play_mode (mode start_play) after a DevSync of src/. Not a loader-run script. It builds each
-- rig above a pad slab, plays every move over the guard (as the Fight controller does), samples every Heartbeat, prints PASS/FAIL/INFO
-- lines, and destroys what it made. Group boxes: assets-src/models/<id>_atlas.fbx bounds read in headless Blender (Blender axes; the
-- converter below makes Roblox axes: x flipped, y = Blender z, z = Blender y). Pivots: <id>.groups.json (studs from the feet).
local RS = game:GetService("RunService")
local RepS = game:GetService("ReplicatedStorage")
local Moves = require(RepS.Shared.Moves)
local Geo = require(RepS.Shared.Moves._geo)
local Lib = require(RepS.Shared.Moves._lib)
local BM = require(game.StarterPlayer.StarterPlayerScripts.Controllers.BossMoves)

local DATA = {
	z2_t2 = { H = 5.3, bodyType = 3,
		pivot = { Body = { 0, 0, 0 }, Head = { 0, 1.9, -0.19 }, FistL = { -0.95, 1.71, -0.19 }, FistR = { 0.95, 1.71, -0.19 }, TailA = { 0, 2.09, 1.52 }, TailB = { 0, 3.8, 2.375 } },
		box = { Body = { { -2.47, -1.14, -0 }, { 2.47, 2.47, 3.04 } }, FistL = { { 0.57, -3.04, 1.14 }, { 2.85, 0, 3.04 } }, FistR = { { -2.85, -3.04, 1.14 }, { -0.57, 0, 3.04 } }, Head = { { -1.14, -1.71, 0.95 }, { 1.14, 0, 3.04 } }, TailA = { { -0.57, 1.14, 1.71 }, { 0.57, 2.85, 3.8 } }, TailB = { { -0.57, -0.95, 3.23 }, { 0.57, 2.85, 5.32 } } } },
	z3_t3 = { H = 6.8, bodyType = 5,
		pivot = { Body = { 0, 0, 0 }, Upper = { 0, 1.98, 0 }, Head = { 0, 3.96, -0.44 }, FistL = { -1.32, 3.74, -0.44 }, FistR = { 1.32, 3.74, -0.44 } },
		box = { Body = { { -2.2, -1.76, -0 }, { 2.2, 3.96, 2.42 } }, FistL = { { 0.88, -2.64, 1.76 }, { 3.52, 0.22, 3.96 } }, FistR = { { -3.52, -2.64, 1.76 }, { -0.88, 0.22, 3.96 } }, Head = { { -1.32, -3.74, 3.3 }, { 1.32, 1.32, 6.82 } }, Upper = { { -1.98, -1.76, 2.2 }, { 1.98, 3.52, 6.82 } } } },
	z4_t4 = { H = 8.3, bodyType = 1,
		pivot = { Body = { 0, 0, 0 }, Head = { 0, 5.46, -0.26 }, FistL = { -2.6, 4.94, 0 }, FistR = { 2.6, 4.94, 0 } },
		box = { Body = { { -2.86, -2.08, -0 }, { 2.86, 1.3, 5.72 } }, FistL = { { 1.3, -3.38, 2.08 }, { 4.16, 1.56, 6.24 } }, FistR = { { -4.16, -3.38, 2.08 }, { -1.3, 1.56, 6.24 } }, Head = { { -1.82, -2.08, 4.68 }, { 1.82, 1.56, 8.32 } } } },
	z5_t5 = { H = 10.9, bodyType = 3,
		pivot = { Body = { 0, 0, 0 }, Head = { 0, 7.28, -0.56 }, FistL = { -2.24, 6.44, -0.28 }, FistR = { 2.24, 6.44, -0.28 }, TailA = { 0, 3.08, 1.4 }, TailB = { 3.64, 1.176, 2.8 } },
		box = { Body = { { -7, -2.24, -0 }, { 7, 1.96, 10.64 } }, FistL = { { 1.4, -3.92, 3.36 }, { 4.76, 0.56, 7 } }, FistR = { { -4.76, -3.92, 3.36 }, { -1.4, 0.56, 7 } }, Head = { { -3.08, -5.04, 6.44 }, { 3.08, 1.96, 11.2 } }, TailA = { { -3.92, 0.56, 0.56 }, { 0.84, 3.92, 3.92 } }, TailB = { { -5.88, -1.4, 0 }, { -3.08, 3.08, 2.24 } } } },
	z6_t6 = { H = 14, bodyType = 1,
		pivot = { Body = { 0, 0, 0 }, Head = { 0, 10, 0 }, FistL = { -4.8, 8.4, 0 }, FistR = { 4.8, 8.4, 0 }, Sig = { 0, 15.6, 0 } },
		box = { Body = { { -6.8, -4, -0 }, { 6.8, 2.4, 12 } }, FistL = { { 3.6, -3.6, 3.6 }, { 7.6, 1.2, 9.6 } }, FistR = { { -7.6, -3.6, 3.6 }, { -3.6, 1.2, 9.6 } }, Head = { { -2.4, -2.8, 9.6 }, { 2.4, 2, 14 } }, Sig = { { -4.4, -3.6, 14 }, { 4.4, 3.6, 16.4 } } } },
}
local ORDER = { "z2_t2", "z5_t5", "z3_t3", "z4_t4", "z6_t6" }
if _G.M222_ONLY then ORDER = _G.M222_ONLY end -- a list of ids, to run a few bosses per call (the MCP call times out near 100 s)
local PAD_Y = 800
local fails = 0
local LOG = {}
local function P(k, s) local l = k .. " " .. s; print(l); table.insert(LOG, l) end
local function check(c, s) if not c then fails += 1 end P(c and "PASS" or "FAIL", s) end

local function rbox(b)
	local lo, hi = b[1], b[2]
	local mn, mx = Vector3.new(-hi[1], lo[3], lo[2]), Vector3.new(-lo[1], hi[3], hi[2])
	return (mn + mx) / 2, mx - mn
end

local made = {}
local REALFAIL = {}
-- REAL rigs: a clone of the placed Boss_<id> (built by studio/SetupBosses.lua from the imported meshes), stood on a pad slab at PAD_Y.
-- Its joints, pivots and Body pivot are the real ones; nothing is rebuilt here. Also checks each real MeshPart's rest box against the FBX bounds in DATA.box.
local function build(id, x)
	local d = DATA[id]
	local F = CFrame.new(x, PAD_Y, 0)
	local pad = Instance.new("Part"); pad.Name = "M222Pad"; pad.Anchored = true; pad.Size = Vector3.new(40, 1, 40)
	pad.CFrame = CFrame.new(x, PAD_Y - 0.5, 0); pad.Parent = workspace; table.insert(made, pad)
	local src = workspace.Zones["Z" .. id:sub(2, 2)].Pads.Fixed["Boss_" .. id]
	local m = src:Clone(); m.Name = "M222_" .. id
	game:GetService("CollectionService"):RemoveTag(m, "HFB_Boss") -- a probe, not a game boss
	m.Parent = workspace
	m:PivotTo(F)
	table.insert(made, m)
	local parts = {}
	for _, c in ipairs(m:GetChildren()) do if c:IsA("BasePart") then parts[c.Name] = c end end
	-- the rest boxes are READ from the placed meshes (the fix pass changed them; the FBX numbers in DATA.box are the pre-fix ones, kept only to report the drift)
	local drift, real = 0, {}
	for g, p in pairs(parts) do
		local c = F:ToObjectSpace(p.CFrame).Position
		local lo, hi = c - p.Size / 2, c + p.Size / 2 -- Roblox axes, feet frame
		real[g] = { lo = lo, hi = hi }
		local old = d.box[g]
		if old then
			local oc, osz = rbox(old)
			drift = math.max(drift, (c - oc).Magnitude, (p.Size - osz).Magnitude)
		end
	end
	d.real = real
	do -- _geo.lua `back`: how far behind the feet any group reaches (fraction of H)
		local reach = -1e9
		for _, b in pairs(real) do reach = math.max(reach, b.hi.Z) end
		local g = Geo.creatures[id]
		P("INFO", ("%s rearmost reach %.3f studs = %.3f H; _geo.lua back %.3f"):format(id, reach, reach / d.H, g and g.back or -1))
		check(g ~= nil and reach / d.H <= g.back + 0.02, ("%s the real mesh reaches no further behind the feet than _geo.lua back + 0.02 H"):format(id))
	end
	P("INFO", ("%s rest boxes read from the real meshes; drift from the pre-fix FBX boxes: %.3f studs (%.3f H)"):format(id, drift, drift / d.H))
	-- every real joint's pivot equals groups.json
	local pv = 0
	for g, v in pairs(d.pivot) do
		if g ~= "Body" then
			local j = m.Body:FindFirstChild(g)
			if not j then pv = 1e9 else
				local w = (m.Body.CFrame * j.C0).Position - F.Position
				pv = math.max(pv, (w - Vector3.new(table.unpack(v))).Magnitude)
			end
		end
	end
	check(pv < 0.01, ("%s real joint pivots equal groups.json (worst %.4f studs)"):format(id, pv))
	local tex = 0
	for _, p in pairs(parts) do if p:IsA("MeshPart") and p.TextureID ~= "" and p.Color == Color3.new(1, 1, 1) and p.Material == Enum.Material.SmoothPlastic then tex += 1 end end
	check(tex == (function() local n = 0 for _ in pairs(parts) do n += 1 end return n end)(), ("%s every MeshPart textured, white, SmoothPlastic"):format(id))
	return m, parts, F
end

-- 0. the sets exist and pass the schema (scale limits, lengths, ease names, groups)
for _, id in ipairs(ORDER) do
	local d = DATA[id]
	local set = Moves.get(d.bodyType, id)
	local probs = Moves.check(set, id .. " set")
	local sig = Moves.sig(id)
	check(sig ~= nil and sig.attack ~= nil and sig.lastHeart ~= nil, id .. " has a signature (attack, lastHeart)")
	for _, pr in ipairs(Moves.check(sig or {}, id .. " signature", true)) do table.insert(probs, pr) end
	check(#probs == 0, id .. " schema: " .. (#probs == 0 and "0 problems" or table.concat(probs, "; ")))
	local missing = {}
	for _, n in ipairs(Moves.NAMES) do if not Moves.resolve(d.bodyType, id, n) then table.insert(missing, n) end end
	check(#missing == 0, id .. " resolves all 11 moves " .. table.concat(missing, ","))
	-- the layout in _geo.lua matches groups.json (fractions of H)
	local g, bad = Geo.creatures[id], {}
	for name, v in pairs(d.pivot) do
		if name ~= "Body" then
			local f = g and g[name]
			if not f then
				table.insert(bad, name .. " missing")
			else
				for k = 1, 3 do
					if math.abs(f[k] * d.H - v[k]) > 0.03 then table.insert(bad, ("%s[%d] %.3f vs %.3f"):format(name, k, f[k] * d.H, v[k])) end
				end
			end
		end
	end
	check(#bad == 0, id .. " _geo.lua matches the group pivots: " .. table.concat(bad, "; "))
end

-- 1. Lib.follow is exact: a child turned about its own pivot inside a parent turned about the parent's pivot == the flat pose
do
	local geoT = { A = { 0.1, 0.4, 0.3 }, B = { 0.2, 0.7, 0.45 } }
	local worst = 0
	for _, c in ipairs({ { { 40, 0, 0 }, { 25, 0, 0 } }, { { -30, 20, 5 }, { 15, -10, 0 } }, { { 0, 60, 0 }, { 10, 5, 3 } }, { { 85, 0, 0 }, { 0, 0, 0 } } }) do
		local pp, cp = { p = { 0.01, 0.02, 0 }, r = c[1] }, { p = { 0, 0.03, -0.02 }, r = c[2] }
		local flat = Lib.follow(geoT, "A", "B", pp, cp)
		local U, cv = Vector3.new(table.unpack(geoT.A)), Vector3.new(table.unpack(geoT.B))
		local Rp = CFrame.Angles(math.rad(c[1][1]), math.rad(c[1][2]), math.rad(c[1][3]))
		local Rc = CFrame.Angles(math.rad(c[2][1]), math.rad(c[2][2]), math.rad(c[2][3]))
		local Rf = CFrame.Angles(math.rad(flat.r[1]), math.rad(flat.r[2]), math.rad(flat.r[3]))
		for _, x in ipairs({ Vector3.new(0, 0.9, 0.7), Vector3.new(0.3, 0.2, -0.4), cv }) do
			local want = Vector3.new(0.01, 0.02, 0) + U + Rp * (cv + Rc * (x - cv) + Vector3.new(0, 0.03, -0.02) - U)
			local got = cv + Rf * (x - cv) + Vector3.new(table.unpack(flat.p))
			worst = math.max(worst, (want - got).Magnitude)
		end
	end
	check(worst < 1e-4, ("Lib.follow equals parent-then-child turning: worst error %.6f H"):format(worst))
end

-- 2. play every move on every rig, sampled each Heartbeat
local LEN = { hitGood = 0.15, hitPerfect = 0.2, hitBig = 0.3, attack = 0.45, lastHeart = 1.0, gloat = 0.35, defeat = 0.8 }
local PROBE = { -- the point whose path says the move reads, taken from the REAL rest box of the group (mode: centre, or tip = centre x, min y, min z; snout = centre x and y, min z)
	z2_t2 = { group = "TailB", mode = "tip", name = "stinger tip" },
	z5_t5 = { group = "TailB", mode = "centre", name = "club centre" },
	z3_t3 = { group = "Head", mode = "snout", name = "snout tip" },
	z4_t4 = { group = "FistR", mode = "centre", name = "right fist centre" },
	z6_t6 = { group = "FistR", mode = "centre", name = "right fist centre" },
}
local function probePoint(id, probe)
	local b = DATA[id].real[probe.group]
	local c = (b.lo + b.hi) / 2
	if probe.mode == "tip" then return Vector3.new(c.X, b.lo.Y, b.lo.Z) end
	if probe.mode == "snout" then return Vector3.new(c.X, c.Y, b.lo.Z) end
	return c
end
local NEST = { z2_t2 = { "TailA", "TailB" }, z5_t5 = { "TailA", "TailB" }, z3_t3 = { "Upper", "Head" } }
local results = {}

local function allCorners(parts, out, who)
	local n = 0
	for gname, p in pairs(parts) do
		local cf, s = p.CFrame, p.Size / 2
		for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
			n += 1; out[n] = cf:PointToWorldSpace(Vector3.new(sx * s.X, sy * s.Y, sz * s.Z)); who[n] = gname
		end end end
	end
	return n
end

local x = -90
for _, id in ipairs(ORDER) do
	x += 30
	local d = DATA[id]
	local m, parts, F = build(id, x)
	local body = m.Body
	local probe = PROBE[id]
	local pp = parts[probe.group]
	local probeLocal = pp.CFrame:PointToObjectSpace(F:PointToWorldSpace(probePoint(id, probe)))
	local nest = NEST[id]
	local joint = nest and body[nest[2]]
	local parentRest = nest and parts[nest[1]].CFrame
	local parentPivotRest = nest and (F * CFrame.new(Vector3.new(table.unpack(d.pivot[nest[1]])))).Position - F.Position
	local childPivotRest = nest and (parts[nest[2]].CFrame * body[nest[2]].C1.Position)
	local rest = {}
	for g, p in pairs(parts) do rest[g] = { cf = p.CFrame, size = p.Size } end
	local jointRest = {}
	for _, j in ipairs(body:GetChildren()) do if j:IsA("Motor6D") then jointRest[j.Name] = { c0 = j.C0, c1 = j.C1 } end end

	local stats
	local corners, who = {}, {}
	local conn = RS.Heartbeat:Connect(function()
		if not stats then return end
		local t = os.clock() - stats.t0
		local n = allCorners(parts, corners, who)
		local lo = 1e9
		local lw = nil
		for i = 1, n do local yy = corners[i].Y - PAD_Y if yy < lo then lo = yy; lw = who[i] end local pm = stats.parts[who[i]] if not pm or yy < pm then stats.parts[who[i]] = yy end end
		if lo < stats.minY then
			stats.minY = lo; stats.minWho = lw; stats.minT = t
			if _G.M222_DUMP and lw and body:FindFirstChild(lw) then
				local tf = body[lw].Transform
				local ex, ey, ez = tf:ToEulerAnglesXYZ()
				local pcf = parts[lw].CFrame
				stats.dump2 = ("%s part centre rel feet (%.2f, %.2f, %.2f) size %s, rest centre rel feet (%.2f, %.2f, %.2f)"):format(lw, pcf.X - F.X, pcf.Y - PAD_Y, pcf.Z - F.Z, tostring(parts[lw].Size), rest[lw].cf.X - F.X, rest[lw].cf.Y - PAD_Y, rest[lw].cf.Z - F.Z)
				stats.dump = ("%s joint Transform pos (%.2f, %.2f, %.2f) euler (%.1f, %.1f, %.1f); Body size %s y %.2f"):format(lw, tf.X, tf.Y, tf.Z, math.deg(ex), math.deg(ey), math.deg(ez), tostring(body.Size), body.Position.Y - PAD_Y)
			end
		end
		table.insert(stats.lows, { t, lo })
		local pt = pp.CFrame:PointToWorldSpace(probeLocal) - F.Position
		table.insert(stats.series, { t, pt })
		if nest then
			local expected = parts[nest[1]].CFrame * (parentRest:ToObjectSpace(CFrame.new(childPivotRest)))
			local actual = parts[nest[2]].CFrame * body[nest[2]].C1.Position
			-- the engine scales the Body about the feet and carries every pivot with it: pivots shift by (scale-1) x their distance
			local sc = body.Size / rest.Body.size
			local extra = body.CFrame.Rotation * (Vector3.new(sc.X - 1, sc.Y - 1, sc.Z - 1) * (childPivotRest - F.Position - parentPivotRest))
			local sh = (expected.Position + extra - actual).Magnitude
			if sh > stats.shear then stats.shear = sh end
		end
	end)
	local function at(series, t)
		local best, bd = nil, 1e9
		for _, s in ipairs(series) do local dd = math.abs(s[1] - t) if dd < bd then bd, best = dd, s[2] end end
		return best
	end
	local function run(name, opts)
		stats = { t0 = os.clock(), minY = 1e9, shear = 0, series = {}, lows = {}, parts = {} }
		local done = false
		BM.play(m, name, { onDone = function() done = true end, perfect = opts and opts.perfect, hopTo = opts and opts.hopTo })
		local t = os.clock()
		while not done and os.clock() - t < 2.5 do task.wait() end
		local s = stats; s.len = os.clock() - s.t0; s.done = done
		stats = nil
		results[id .. "/" .. name] = s
		return s
	end
	local function line(name, s)
		P("INFO", ("%s %s: %.3f s (brief %s), lowest corner %.3f studs from the pad (%s at %.2f s)%s"):format(id, name, s.len, tostring(LEN[name] or "-"), s.minY, tostring(s.minWho), s.minT or 0, nest and (", max joint shear %.3f studs = %.3f H"):format(s.shear, s.shear / d.H) or ""))
	end
	task.wait(4) -- Studio warm-up: the first moves of a session lose frames
	BM.loop(m, "guard"); task.wait(0.4)
	local worstShear, worstSink = 0, 1e9
	local lens = {}
	for _, name in ipairs({ "hitGood", "hitPerfect", "hitBig", "attack", "lastHeart", "gloat" }) do
		local s = run(name, { perfect = name == "hitPerfect" })
		line(name, s)
		worstShear = math.max(worstShear, s.shear); worstSink = math.min(worstSink, s.minY)
		check(s.done and math.abs(s.len - LEN[name]) < 0.04, ("%s %s lasts %.3f s (brief %.2f, within 2 frames)"):format(id, name, s.len, LEN[name]))
		task.wait(0.15)
	end
	check(worstSink > -0.12 * d.H, ("%s no part under the pad in any non-defeat move (lowest %.3f studs; the template dips 0.05 H and leans back 6, tolerance 0.12 H)"):format(id, worstSink))
	if nest then check(worstShear < 0.08 * d.H, ("%s the nested group stays attached to its parent: worst %.3f studs (%.3f H; chord of the linear key blend and the body squash)"):format(id, worstShear, worstShear / d.H)) end
	-- impacts: the striking part is where the style guide puts it
	do
		local pl = {}
		for g, y in pairs(results[id .. "/attack"].parts) do table.insert(pl, ("%s %.2f"):format(g, y)) end
		table.sort(pl)
		P("INFO", id .. " attack lowest corner per group: " .. table.concat(pl, ", "))
		if results[id .. "/attack"].dump then P("INFO", id .. " attack at the lowest frame: " .. results[id .. "/attack"].dump .. " | " .. results[id .. "/attack"].dump2) end
	end
	local at0 = at(results[id .. "/attack"].series, 0.0)
	local atW = at(results[id .. "/attack"].series, 0.15)
	local atI = at(results[id .. "/attack"].series, 0.21)
	local atI2 = at(results[id .. "/attack"].series, 0.33)
	local function v(p) return ("(%.2f, %.2f, %.2f)"):format(p.X, p.Y, p.Z) end
	P("INFO", ("%s attack %s path (studs from the feet): start %s, wind-up end 0.15 %s, impact 0.21 %s, second beat 0.33 %s"):format(id, probe.name, v(at0), v(atW), v(atI), v(atI2)))
	if id == "z2_t2" then
		check(atW.Y >= 4.0 and atW.Z >= 1.5, id .. " wind-up: the stinger is cocked up and behind (y>=4.0, z>=1.5) " .. v(atW))
		check(atI.Z <= -1.7 and atI.Y >= 0.8 and atI.Y <= 3.4, id .. " impact: the stinger lands in front of the head at chest height (z<=-1.7, y 0.8..3.4) " .. v(atI))
	elseif id == "z5_t5" then
		check(atW.Z >= 3.0, id .. " wind-up: the club is swung away behind (z>=3.0) " .. v(atW))
		check(atI.Z <= -2.5 and math.abs(atI.X) <= 3.6, id .. " impact: the club lands in front (z<=-2.5, |x|<=3.6) " .. v(atI))
	elseif id == "z3_t3" then
		check(atW.Z - at0.Z >= 0.5 and atW.Y > at0.Y, id .. " wind-up: rears back and up " .. v(atW))
		check(atI.Z - at0.Z <= -1.0, id .. " impact: lunged forward past the rest snout (>=1.0 stud) " .. v(atI))
	else
		check(atW.Y - at0.Y >= 2.0, id .. " wind-up: the striking fist is raised overhead (>=2 studs above the guard fist) " .. v(atW))
		check(atI.Z < atW.Z - 1.0 and atI.Y < atW.Y - 1.0, id .. " impact: the fist comes down and forward " .. v(atI))
	end
	for _, name in ipairs({ "attack", "lastHeart" }) do
		local k = Moves.resolve(d.bodyType, id, name)
		local ia = k.impactAt
		local s = results[id .. "/" .. name]
		check(math.abs(ia - ({ attack = 0.21, lastHeart = 0.26 })[name]) < 1e-6, ("%s %s impactAt %.2f"):format(id, name, ia))
	end
	for _, name in ipairs({ "defeat" }) do
		local s = run(name, { hopTo = Vector3.new(x, PAD_Y + 6, -10) })
		line(name, s)
		check(s.done and math.abs(s.len - LEN[name]) < 0.04, ("%s defeat lasts %.3f s"):format(id, s.len))
		local flopLow = 1e9
		for _, lw in ipairs(s.lows) do if lw[1] >= 0.4 and lw[1] <= 0.56 and lw[2] < flopLow then flopLow = lw[2] end end
		check(flopLow > -0.05, ("%s defeat: the flop (0.40 to 0.56 s) never goes under the pad (lowest %.3f studs; body lifted by lie %.3f H; the box corners overstate the wobble's dip)"):format(id, flopLow, Geo.creatures[id].lie))
		BM.stop(m); task.wait(0.1)
		BM.loop(m, "guard"); task.wait(0.3)
	end
	-- loops run and wrap: a full pass of idle and halfIdle, then carryRock
	for _, name in ipairs({ "idle", "halfIdle", "carryRock" }) do
		BM.stop(m); BM.loop(m, name, { phase = 0 })
		local lenL = Moves.resolve(d.bodyType, id, name).length
		stats = { t0 = os.clock(), minY = 1e9, shear = 0, series = {}, lows = {}, parts = {} }
		task.wait(lenL + 0.1)
		local s = stats; stats = nil
		P("INFO", ("%s %s loop %.1f s: lowest corner %.3f studs, joint shear %.3f"):format(id, name, lenL, s.minY, s.shear))
		check((name == "carryRock" or s.minY > -0.12 * d.H) and (not nest or s.shear < 0.08 * d.H), id .. " " .. name .. " loop stays above the pad (not carryRock: it rides a head) and attached")
	end
	-- cuts and rest: a reaction cut by the next result, then stop restores the exact rest pose
	BM.stop(m); BM.loop(m, "guard"); task.wait(0.3)
	local seq = { "hitGood", "hitPerfect", "hitBig", "attack", "hitGood", "lastHeart", "hitBig", "hitGood" }
	local cutOk = true
	for i, n in ipairs(seq) do
		BM.play(m, n, { perfect = n == "hitPerfect" })
		local _, ov = BM.current(m)
		if ov ~= n then cutOk = false end
		task.wait(0.04 + (i % 3) * 0.05)
	end
	check(cutOk, id .. " eight cuts in a row: each play is the overlay at once")
	BM.stop(m); task.wait(0.1)
	local ident, same, sizes = true, true, true
	for n, jr in pairs(jointRest) do
		if body[n].Transform ~= CFrame.identity then ident = false end
		if not (body[n].C0 == jr.c0 and body[n].C1 == jr.c1) then same = false end
	end
	for g, r in pairs(rest) do
		if (parts[g].Size - r.size).Magnitude > 1e-3 then sizes = false end
		if g == "Body" and not parts[g].CFrame:FuzzyEq(r.cf, 1e-3) then ident = false end
	end
	check(ident and same and sizes and not BM.isPlaying(m), id .. " after cuts and stop: every Transform identity, Body at rest, C0/C1 unchanged, sizes restored, nothing running")
	conn:Disconnect()
end

-- 3. S22: one set of offsets for the smallest and the largest tier (box rigs). Run the pair in one call (the MCP call times out near 100 s).
-- Biped: the same Moves.biped table drives Frost Byte (H 8.3) and Star Golem (H 14); the same fractions of H must move both the same
-- share of their height. Tailed: Scorpion (H 5.3) and Drake (H 10.9) share the builder and the fractions, each with its own pivots.
local function travel(r, id)
	local s0 = r.series[1][2]
	local best, bd = nil, 1e9
	for _, s in ipairs(r.series) do local dd = math.abs(s[1] - 0.21) if dd < bd then bd, best = dd, s[2] end end
	return (best - s0).Magnitude / DATA[id].H
end
if results["z4_t4/attack"] and results["z6_t6/attack"] then
	local fa, fb = travel(results["z4_t4/attack"], "z4_t4"), travel(results["z6_t6/attack"], "z6_t6")
	check(math.abs(fa - fb) / math.max(fa, fb) < 0.25, ("S22 biped: the same set moves the right fist %.3f H on Frost Byte (H 8.3) and %.3f H on Star Golem (H 14), within 25 percent"):format(fa, fb))
	for _, name in ipairs({ "hitGood", "hitBig", "defeat" }) do
		local ra, rb = results["z4_t4/" .. name], results["z6_t6/" .. name]
		P("INFO", ("S22 biped %s: lowest corner %.3f H (Frost Byte) and %.3f H (Star Golem)"):format(name, ra.minY / DATA.z4_t4.H, rb.minY / DATA.z6_t6.H))
	end
end
if results["z2_t2/attack"] and results["z5_t5/attack"] then
	local fa, fb = travel(results["z2_t2/attack"], "z2_t2"), travel(results["z5_t5/attack"], "z5_t5")
	P("INFO", ("S22 tailed: the striking tail part travels %.3f H on Snap Scorpion (H 5.3) and %.3f H on Ember Drake (H 10.9) by 0.21 s (different signatures and tail shapes; both land where the style guide says)"):format(fa, fb))
end

for _, o in ipairs(made) do o:Destroy() end
P(fails == 0 and "PASS" or "FAIL", "M2-25 moves check on real meshes: " .. fails .. " failures")
return table.concat(LOG, string.char(10))
