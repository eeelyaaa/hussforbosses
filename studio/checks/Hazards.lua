if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-11: gate row S6 (brief system 6): six hazards on the server clock, always a way through, the hit test in the
-- player's favour, carry speed and Fast Carry, drop, push, grab, grace, the movement check, a stolen carry never
-- dropped. PLAY MODE, one call per phase, installed into ServerStorage.TmpChecks next to CheckLib:
--   { phase = "a" }  the six paths against the brief's numbers, "always leaves a way through" (sampled every 0.05 s over
--                    a period at every stud of the band), the tolerance edge, the six models registered.
--   { phase = "b" }  the server's hit test in play: each hazard drops a carried boss and pushes the carrier 6 studs
--                    along the lane; a non-carrier gets the small push; LogForce clear / hit; grab inside the grace, the
--                    boss gone after it; a stolen carry ends instead of dropping and cannot be grabbed.
--   { phase = "c" }  carry speed 12 / 16 with Fast Carry (PassOwned), a teleport and an over-speed pulled back, a real
--                    walk not pulled back.
-- Needs studio/BuildHazards.lua run after BuildSlice + BuildStrip. Every pass is forced off with PassOwned first (the
-- Studio account owns the passes for real).
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Carry, Hazards, Session, Zones = L.Config, L.Carry, L.Hazards, L.Session, L.Zones
local SH = L.SH
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Ids = require(RS.Shared.Ids)
local s = L.s

local ctx = L.begin("Hazards", ARGS)
local p = ctx.p
L.rootY(ctx)
local H = Config.Hazards

local function passesOff(extra)
	local parts = {}
	for _, k in ipairs(Ids.SHOP_KEYS) do
		if Ids.isPass(k) then
			table.insert(parts, k .. "=" .. ((extra and extra[k]) or "off"))
		end
	end
	L.hook(ctx, "PassOwned", table.concat(parts, ","))
	task.wait(0.1)
end
local function near(a, b, tol) return math.abs(a - b) <= (tol or 1e-6) end
local function clearCarry() if Carry.get(p) then Carry.lose(p, "check") end; task.wait(0.05) end

passesOff()

if ctx.phase == "a" then
	-- models
	for id = 1, 6 do
		L.check(ctx, ("hazard %d registered by the server (tag HFB_Hazard, TrackHome)"):format(id), Hazards.track(id) ~= nil)
	end
	-- 1 log: crosses 30 studs in 3 s, waits 1 s each side
	local off0 = SH.logOffset(0.5)
	local offMid = SH.logOffset(1 + 1.5)
	L.check(ctx, "1 log: waits at -15 (30 free), mid-crossing at 0 (15 each side), period 8 s", near(off0, -15) and near(offMid, 0, 1e-6) and near(SH.logPeriod(), 8), ("%s, %s, %s"):format(s(off0), s(offMid), s(SH.logPeriod())))
	-- 2 cactus: 8 wide, 14 studs/s, one every 6 s, toward the bases
	local on1, l1 = SH.cactusAt(0.0)
	local on2, l2 = SH.cactusAt(1.0)
	local on3 = SH.cactusAt(30 / 14 + 0.01)
	local on4 = SH.cactusAt(6.0)
	L.check(ctx, "2 cactus: 14 studs/s toward the bases (along +), gone after 30/14 s, the next at 6 s", on1 and on2 and near(l2 - l1, 14, 1e-6) and not on3 and on4, ("l %s -> %s"):format(s(l1), s(l2)))
	local maxA = 0
	for t = 0, 2.1, 0.01 do local on, _, a = SH.cactusAt(t); if on then maxA = math.max(maxA, math.abs(a)) end end
	L.check(ctx, "2 cactus: zigzag stays between the walls (|across| <= 14, so 28 free beside it)", maxA <= 14 + 1e-6 and maxA > 13.5, s(maxA))
	-- 3 anchor: covers the middle 24, one swing every 3 s
	local a0, a3 = SH.anchorOffset(0), SH.anchorOffset(3)
	L.check(ctx, "3 anchor: head edge reaches +-12 (covers the middle 24, 6 free each side), one swing per 3 s", near(a0 + H.ANCHOR.head_across / 2, 12) and near(a3 - H.ANCHOR.head_across / 2, -12), ("%s, %s"):format(s(a0), s(a3)))
	-- 4 ice: 10 x 10, 20 studs/s, waits 1 s
	local i0 = SH.iceOffset(0.5)
	local _, ph, v = SH.iceOffset(1.5)
	L.check(ctx, "4 ice: waits at -13 (26 free), slides at 20 studs/s", near(i0, -13) and ph == "toPlus" and near(v, 20), ("%s, %s %s"):format(s(i0), ph, s(v)))
	-- 5 lava: glow 0.8 then erupt 0.6 per tile, a sweep 4 s, at most two erupting
	local maxE, minE, windows = 0, 99, {}
	for k = 1, 6 do windows[k] = { glow = 0, erupt = 0 } end
	for i = 0, 799 do
		local t = i * 0.01
		local st = SH.lavaTiles(t)
		local e = 0
		for k = 1, 6 do
			if st[k] == "erupt" then e += 1; windows[k].erupt += 0.01 elseif st[k] == "glow" then windows[k].glow += 0.01 end
		end
		maxE = math.max(maxE, e); minE = math.min(minE, e)
	end
	local okW = true
	for k = 1, 6 do if not (near(windows[k].glow, 1.6, 0.03) and near(windows[k].erupt, 1.2, 0.03)) then okW = false end end
	L.check(ctx, "5 lava: each tile glows 0.8 s and erupts 0.6 s twice per 8 s (one sweep each way), never more than 2 erupting", okW and maxE <= 2 and minE == 0, ("max %d erupting; tile 1 glow %s erupt %s"):format(maxE, s(windows[1].glow), s(windows[1].erupt)))
	local first = SH.lavaTiles(0.85)
	L.check(ctx, "5 lava: the sweep starts at tile 1 (tile 1 erupting at 0.85 s, tile 6 idle)", first[1] == "erupt" and first[6] == "idle", table.concat(first, ","))
	-- 6 meteor: radius 14, lap 4 s
	local ma, ml = SH.meteorAt(1)
	L.check(ctx, "6 meteor: radius 14 round the throat's middle, a quarter lap at 1 s", near(ma, 0, 1e-6) and near(ml, 14, 1e-6), ("%s, %s"):format(s(ma), s(ml)))

	-- always a way through: every 0.05 s over a period, every stud of the band
	local periods = { 8, 6, 6, 4.6, 8, 4 }
	for id = 1, 6 do
		local track = Hazards.track(id) or SH.makeTrack(CFrame.new())
		local reach = SH.reach(id) + SH.BODY_RADIUS
		local minW, at = math.huge, nil
		local t = 0
		while t < periods[id] do
			local l = -reach
			while l <= reach do
				local w = SH.clearWidth(id, track, t, l, 0.25)
				if w < minW then minW, at = w, ("t=%.2f l=%.1f"):format(t, l) end
				l += 1
			end
			t += 0.05
		end
		L.check(ctx, ("%d always leaves a way through: narrowest clear stretch >= %d studs"):format(id, H.MIN_WAY), minW >= H.MIN_WAY, ("%s studs at %s"):format(s(minW), tostring(at)))
	end

	-- the tolerance: 0.9 inside a volume is not a hit, 1.1 inside is (in the player's favour)
	local times = { 0.5, 0.5, 0.3, 0.5, 0.85, 0.3 }
	for id = 1, 6 do
		local track = Hazards.track(id) or SH.makeTrack(CFrame.new())
		local v = SH.volumes(id, track, times[id])[1]
		local footY = if id == 1 then -H.LOG.thickness / 2 else 0
		local ext = v and (v.ha or v.r) or 0
		local function at(depth)
			local a = v.a + (if v.a <= 0 then 1 else -1) * (ext + SH.BODY_RADIUS - depth)
			return track.home.Position + track.across * a + track.along * v.l + Vector3.yAxis * (footY + SH.ROOT_TO_FEET)
		end
		local shallow = v and SH.hitsId(id, track, at(0.9), times[id])
		local deep = v and SH.hitsId(id, track, at(1.1), times[id])
		L.check(ctx, ("%d tolerance: 0.9 studs into it is not a hit, 1.1 is"):format(id), v ~= nil and shallow == false and deep == true, ("%s / %s"):format(tostring(shallow), tostring(deep)))
	end

elseif ctx.phase == "b" then
	L.hook(ctx, "Wipe", true)
	task.wait(0.5)
	local function volumeNow(id)
		local track = Hazards.track(id)
		local vols = SH.volumes(id, track, Zones.now() + 0.05)
		return track, vols[1]
	end
	-- stand the player inside the hazard (re-placed each frame until the server reacts, up to 6 s)
	local function standIn(id, until_)
		local t0 = os.clock()
		while os.clock() - t0 < 6 do
			local track, v = volumeNow(id)
			if v then
				local footY = if id == 1 then -H.LOG.thickness / 2 else 0
				local pos = track.home.Position + track.across * v.a + track.along * v.l + Vector3.yAxis * (footY + L.rootY(ctx))
				L.tp(ctx, pos)
			end
			RunService.Heartbeat:Wait()
			if until_() then return true end
		end
		return false
	end
	local grabbed = false
	for id = 1, 6 do
		clearCarry()
		local c = Carry.begin(p, "z1_t1")
		local hits0 = #Hazards.stats.hits
		local ok = standIn(id, function() return #Hazards.stats.hits > hits0 end)
		local d = Carry.get(p)
		local hit = Hazards.stats.hits[#Hazards.stats.hits]
		L.check(ctx, ("%d hits a carrier on the server: the boss drops (dropped, same uid)"):format(id), ok and hit and hit.hazardId == id and hit.carrying and d and d.state == "dropped" and d.uid == c.uid, ("%s %s"):format(tostring(hit and hit.hazardId), d and d.state or "none"))
		if hit and d then
			task.wait(0.05)
			local track = Hazards.track(id)
			local moved = ctx.hrp.Position - hit.pos
			local alongMoved = math.abs(moved:Dot(track.along))
			L.check(ctx, ("%d push: about 6 studs along the lane, no stun (WalkSpeed 16)"):format(id), near(alongMoved, Config.Carry.DROP_PUSH, 0.6) and ctx.hum.WalkSpeed == Config.Carry.WALK, ("along %s, across %s, speed %s"):format(s(alongMoved), s(math.abs(moved:Dot(track.across))), s(ctx.hum.WalkSpeed)))
			L.check(ctx, ("%d grace: graceEnds 5 s after the hit, dropPos where the carrier stood"):format(id), near(d.graceEnds - hit.at, Config.Carry.GRAB_S, 0.1) and L.flat(d.dropPos, hit.pos) < 0.01, s(d.graceEnds - hit.at))
			if id == 3 and not grabbed then
				grabbed = true
				L.tp(ctx, d.dropPos + track.along * 7 + Vector3.yAxis * L.rootY(ctx))
				task.wait(0.1)
				local why = Carry.tryGrab(p, "nope-1")
				local why2 = Carry.tryGrab(p, d.uid)
				local g = Carry.get(p)
				L.check(ctx, "grab: wrong uid refused 'uid'; the dropper 7 studs away inside the grace -> carrying again", why == "uid" and why2 == nil and g and g.state == "carrying" and g.uid == d.uid, ("%s / %s"):format(tostring(why), tostring(why2)))
			end
		end
	end
	-- grace over: the fight boss is gone
	clearCarry()
	Carry.begin(p, "z1_t2")
	local hits0 = #Hazards.stats.hits
	standIn(4, function() return #Hazards.stats.hits > hits0 end)
	local dd = Carry.get(p)
	L.tp(ctx, Vector3.new(206, 0.2 + L.rootY(ctx), 180)) -- the yard, away from every hazard
	local gone = L.waitFor(function() return Carry.get(p) == nil end, 6.5)
	L.check(ctx, "not grabbed in 5 s: the fight boss is gone (no carry, not in the profile)", dd and dd.state == "dropped" and gone and #L.prof(ctx).bosses == 0 and #L.prof(ctx).crate == 0)
	-- a non-carrier: the small push only
	clearCarry()
	task.wait(1.1)
	local pushes0 = Hazards.stats.pushes
	local okP = standIn(4, function() return Hazards.stats.pushes > pushes0 end)
	L.check(ctx, "a non-carrier hit: small push only, no carry state", okP and Carry.get(p) == nil, Hazards.stats.pushes - pushes0)
	-- LogForce clear / hit
	clearCarry()
	Carry.begin(p, "z1_t1")
	L.hook(ctx, "LogForce", "clear")
	hits0 = #Hazards.stats.hits
	local hitWhileClear = standIn(3, function() return #Hazards.stats.hits > hits0 end)
	L.check(ctx, "LogForce clear: 6 s inside the anchor's path, never hit", not hitWhileClear and Carry.isCarrying(p))
	L.hook(ctx, "LogForce", "hit")
	local track6 = Hazards.track(6)
	L.tp(ctx, track6.home.Position + track6.across * 15 + Vector3.yAxis * L.rootY(ctx)) -- in the band, far from the rock
	local forced = L.waitFor(function() local x = Carry.get(p); return x and x.state == "dropped" end, 1)
	L.check(ctx, "LogForce hit: dropped at once anywhere in a hazard's band (meteor band)", forced ~= nil)
	workspace:SetAttribute("HFB_LogForce", nil)
	L.tp(ctx, Vector3.new(206, 0.2 + L.rootY(ctx), 180))
	clearCarry()
	-- a stolen carry: never dropped, never grabbable; its end reaches the listener with the reason
	local seen
	Carry.onChanged(function(pl, state, c, why) if pl == p and c and c.origin == "stolen" and state == "none" then seen = why end end)
	Carry.begin(p, "z1_t3", { origin = "stolen", uid = "0-1", level = 4, stolenFrom = 99 })
	local cs = Carry.get(p)
	hits0 = #Hazards.stats.hits
	standIn(4, function() return Carry.get(p) == nil end)
	L.check(ctx, "a stolen carry hit by a hazard ends (never 'dropped'), the listener sees why = 'hazard' [M2-02 M8]", cs and cs.level == 4 and Carry.get(p) == nil and seen == "hazard", tostring(seen))
	L.check(ctx, "Carry.Grab on that uid refused 'state'", Carry.tryGrab(p, "0-1") == "state")
	L.tp(ctx, Vector3.new(206, 0.2 + L.rootY(ctx), 180))

elseif ctx.phase == "c" then
	L.hook(ctx, "Wipe", true)
	task.wait(0.5)
	local yard = Vector3.new(206, 0.2 + L.rootY(ctx), 170)
	L.tp(ctx, yard)
	clearCarry()
	Carry.begin(p, "z1_t1")
	task.wait(0.2)
	L.check(ctx, "carry speed 12 without Fast Carry (server WalkSpeed, Carry.speed)", ctx.hum.WalkSpeed == 12 and Carry.speed(p) == 12, ctx.hum.WalkSpeed)
	passesOff({ pass_fast_carry = "on" })
	task.wait(0.2)
	L.check(ctx, "carry speed 16 with Fast Carry", ctx.hum.WalkSpeed == 16 and Carry.speed(p) == 16, ctx.hum.WalkSpeed)
	passesOff()
	task.wait(0.2)
	-- a teleport: one step of 30 studs
	L.tp(ctx, yard)
	task.wait(0.5)
	local tp0, pb0 = Carry.stats.teleports, Carry.stats.pulledBack
	local start = ctx.hrp.Position
	ctx.char:PivotTo(CFrame.new(start + Vector3.new(0, 0, 30)))
	task.wait(0.2)
	L.check(ctx, "a 30-stud teleport while carrying: counted and pulled back (within 2 studs of the start)", Carry.stats.teleports > tp0 and Carry.stats.pulledBack > pb0 and L.flat(ctx.hrp.Position, start) < 2, ("%s studs from start"):format(s(L.flat(ctx.hrp.Position, start))))
	-- over-speed: 30 studs/s for 1.2 s in small steps (each under the teleport step)
	L.tp(ctx, yard)
	task.wait(0.5)
	local os0 = Carry.stats.overSpeed
	start = ctx.hrp.Position
	local t0 = os.clock()
	local maxDist = 0
	while os.clock() - t0 < 1.2 do
		local dt = RunService.Heartbeat:Wait()
		ctx.char:PivotTo(ctx.hrp.CFrame + Vector3.new(0, 0, 30 * dt))
		maxDist = math.max(maxDist, L.flat(ctx.hrp.Position, start))
	end
	task.wait(0.1)
	L.check(ctx, "30 studs/s in small steps: over the 1 s window (12 x 1.25 + 2 = 17), pulled back", Carry.stats.overSpeed > os0 and maxDist < 30, ("got %s studs at most"):format(s(maxDist)))
	-- a real walk at carry speed: never pulled back
	L.tp(ctx, yard)
	task.wait(0.5)
	local pb1 = Carry.stats.pulledBack
	start = ctx.hrp.Position
	ctx.hum:MoveTo(start + Vector3.new(0, 0, 24))
	task.wait(2.2)
	L.check(ctx, "a real walk (Humanoid:MoveTo, 2.2 s) is not pulled back", Carry.stats.pulledBack == pb1 and L.flat(ctx.hrp.Position, start) > 15, ("%s studs walked"):format(s(L.flat(ctx.hrp.Position, start))))
	-- M2-11b: the server slow seam (Iron Grip stagger): x0.5 for 0.5 s, then back; the movement check keeps 12
	L.tp(ctx, yard)
	task.wait(0.3)
	Carry.setSlow(p, 0.5, 0.5)
	task.wait(0.1)
	local slowed, cap = ctx.hum.WalkSpeed, Carry.speed(p)
	task.wait(0.6)
	L.check(ctx, "Carry.setSlow(p, 0.5, 0.5): WalkSpeed 6 at once, 12 again after 0.5 s; Carry.speed stays 12 (M2-11b)", slowed == 6 and cap == 12 and ctx.hum.WalkSpeed == 12, ("%s -> %s"):format(s(slowed), s(ctx.hum.WalkSpeed)))
	Carry.setSlow(p, 0.5, 5)
	task.wait(0.1)
	clearCarry()
	task.wait(0.2)
	L.check(ctx, "the carry ending during a slow: WalkSpeed back to 16, the slow cleared", ctx.hum.WalkSpeed == 16 and Carry.walkSpeed(p) == 12, ctx.hum.WalkSpeed)
	L.check(ctx, "Carry.setSlow refuses bad numbers by clearing (NaN, 0, > 1)", (function() Carry.setSlow(p, 0 / 0, 1); local a = Carry.walkSpeed(p); Carry.setSlow(p, 2, 1); return a == Carry.speed(p) and Carry.walkSpeed(p) == Carry.speed(p) end)())
	clearCarry()
	task.wait(0.2)
	L.check(ctx, "carry ended: WalkSpeed back to 16", ctx.hum.WalkSpeed == 16, ctx.hum.WalkSpeed)
end

clearCarry()
L.hook(ctx, "Wipe", true)
task.wait(0.3)
L.finish(ctx)
