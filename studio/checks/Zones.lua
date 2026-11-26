if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-10: six zones, 24 pads, rolls and 45 s timers, per-player "beaten", the patrol (the manager's P5), fight start
-- against the patrol position, and the saved zones-beaten list on a win (gate rows S4, S5; brief systems 4, 5, 14;
-- m2-contract.md C "Zones", E). PLAY MODE, one call per phase, installed into ServerStorage.TmpChecks next to CheckLib:
--   { phase = "a" }  config (24 pads, odds rows), Shared/Patrol against the formula, djb2 phase, 100,000 rolls per zone
--                    against the odds, every rolling pad rolled at start in its own zone, staggered timers, the
--                    Zones.Pads payload per player.
--   { phase = "b" }  live rolls with PadsFast, ForceRoll, the roll's creature and Power on the pad.
--   { phase = "c" }  fights: start against where the boss walks now (in and out of the ring + slack), bossPos, a win
--                    writes zonesBeaten once (no duplicate), a loss writes nothing, "beaten this roll" per player until
--                    the pad rolls, the fixed pad back after PadFastBack, auto never in a fight.
-- The world has only zone 1's fixed pad until the builder grows the strip (M2-10 report): the check adds stand-in pads
-- (tagged HFB_BossPad, at the proposed layout: zone n starts at Z 236 + 120 (n - 1), pads at 40/60/80/100 studs in,
-- east X 233 / west X 179) in Workspace.HFB_M210Pads, and removes them at the end.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Punch, Fight, Carry, Session, Zones = L.Config, L.Punch, L.Fight, L.Carry, L.Session, L.Zones
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Patrol = require(RS.Shared.Patrol)
local Ids = require(RS.Shared.Ids)
local s = L.s

local ctx = L.begin("Zones", ARGS)
local p = ctx.p
L.rootY(ctx)
local Z = Config.Zones

local function near(a, b, tol) return math.abs(a - b) <= (tol or 1e-6) end
local function setv(name, v) L.hook(ctx, name, v); task.wait(0.15) end
local function clearCarry() if Carry.get(p) then Carry.lose(p, "check") end; task.wait(0.05) end

-- ------------------------------------------------------------------ stand-in pads
local folder
local function standIns()
	folder = Instance.new("Folder")
	folder.Name = "HFB_M210Pads"
	folder.Parent = workspace
	local added = 0
	for zone = 1, 6 do
		local z0 = 236 + 120 * (zone - 1)
		local floor = Instance.new("Part")
		floor.Name = "Floor_Z" .. zone
		floor.Anchored = true
		floor.Size = Vector3.new(90, 1, 120)
		floor.Position = Vector3.new(206, -0.6, z0 + 60)
		floor.Transparency = 1
		floor.CanCollide = zone > 1 -- zone 1 has its own ground
		floor.Parent = folder
		for slot, kind in ipairs({ "fixed", "roll1", "roll2", "roll3" }) do
			local padId = ("z%d_%s"):format(zone, kind)
			if not Zones.pad(padId) then
				local x = if slot % 2 == 1 then 233 else 179
				local zc = z0 + 20 + 20 * slot
				local m = Instance.new("Model")
				m.Name = padId
				m:SetAttribute("PadId", padId)
				m:SetAttribute("ZoneId", zone)
				m:SetAttribute("Kind", if slot == 1 then "fixed" else "roll")
				local ring = Instance.new("Part")
				ring.Name = "Ring"
				ring.Anchored = true
				ring.CanCollide = false
				ring.Size = Vector3.new(12, 1, 12)
				ring.Position = Vector3.new(x, 0.5, zc)
				ring:SetAttribute("RingRadius", 6)
				ring.Parent = m
				local ba = Instance.new("Part")
				ba.Name = "BossAnchor"
				ba.Anchored = true
				ba.CanCollide = false
				ba.Transparency = 1
				ba.Size = Vector3.new(1, 0.2, 1)
				ba.Position = Vector3.new(x, 1, zc)
				ba.Parent = m
				m.PrimaryPart = ring
				m.Parent = folder
				CollectionService:AddTag(m, "HFB_BossPad")
				added += 1
			end
		end
	end
	local all = L.waitFor(function()
		for id in pairs(Z.PADS) do if not Zones.pad(id) then return false end end
		return true
	end, 3)
	return added, all
end
local function removeStandIns()
	if folder then folder:Destroy(); folder = nil end
end

-- ------------------------------------------------------------------ phase a: config, patrol, rolls
local function phaseA()
	local nFixed, nRoll, zonesOk = 0, 0, true
	for zone = 1, 6 do
		local f = Z.PADS[("z%d_fixed"):format(zone)]
		if not (f and f.kind == "fixed" and f.creatureId == Ids.creature(zone, 1)) then zonesOk = false end
		for k = 1, 3 do
			local r = Z.PADS[("z%d_roll%d"):format(zone, k)]
			if not (r and r.kind == "roll" and r.zone == zone) then zonesOk = false end
		end
	end
	for _, d in pairs(Z.PADS) do if d.kind == "fixed" then nFixed += 1 else nRoll += 1 end end
	L.check(ctx, "S5 six zones x 4 pads: 6 fixed (each zone's Common) + 18 rolling", zonesOk and nFixed == 6 and nRoll == 18, ("%d fixed, %d roll"):format(nFixed, nRoll))
	local rowsOk = true
	for zone = 1, 6 do
		local t = 0
		for _, w in ipairs(Z.ROLL_ODDS[zone]) do t += w end
		if not near(t, 100, 1e-9) then rowsOk = false end
	end
	L.check(ctx, "S5 roll odds: six rows of six, each 100%; zone 1 50/28/14/6/1.7/0.3, zone 6 30/25/21/15/7/2", rowsOk and Z.ROLL_ODDS[1][1] == 50 and Z.ROLL_ODDS[1][6] == 0.3 and Z.ROLL_ODDS[6][1] == 30 and Z.ROLL_ODDS[6][6] == 2 and Z.ROLL_S == 45)
	-- deeper zones roll high tiers more often
	local deeper = true
	for zone = 2, 6 do if Z.ROLL_ODDS[zone][6] <= Z.ROLL_ODDS[zone - 1][6] or Z.ROLL_ODDS[zone][1] >= Z.ROLL_ODDS[zone - 1][1] then deeper = false end end
	L.check(ctx, "S5 deeper zones: Common odds fall and Mythic odds rise zone by zone", deeper)

	-- Patrol, pure (phase 0, the stand-in numbers: leg 7 s, T 16 s)
	local P = Z.PATROL
	local pr = { phase = 0, halfLen = P.halfLen, speed = P.speed, pauseS = P.pauseS }
	L.check(ctx, "E patrol stand-ins halfLen 14, speed 4, pause 1.0, slack 1.5 (Q3 PROVISIONAL); leg 7 s, period 16 s", P.halfLen == 14 and P.speed == 4 and P.pauseS == 1 and P.slack == 1.5 and Patrol.leg(pr) == 7 and Patrol.period(pr) == 16)
	local anchor = CFrame.lookAt(Vector3.new(10, 1, 20), Vector3.new(0, 1, 20)) -- look -X, right = -Z... measured below
	local R, LV = anchor.RightVector, anchor.LookVector
	local function at(t) return Patrol.position(anchor, pr, t) end
	local rows = {
		{ 0, -14, R }, { 3.5, 0, R }, { 6.99, 13.96, R }, { 7.5, 14, LV }, { 8, 14, -R }, { 11.5, 0, -R }, { 15.5, -14, LV }, { 16, -14, R }, { 16 * 3 + 3.5, 0, R },
	}
	local okP, got = true, {}
	for _, row in ipairs(rows) do
		local pos, face = at(row[1])
		local want = anchor.Position + R * row[2]
		if (pos - want).Magnitude > 1e-6 or (face - row[3]).Magnitude > 1e-6 then okP = false end
		table.insert(got, ("t=%s x=%s"):format(s(row[1]), s((pos - anchor.Position):Dot(R))))
	end
	L.check(ctx, "E Patrol.position: -14 -> +14 over 7 s facing travel, 1 s pause at +14 facing the look, back, pause at -14, period 16", okP, table.concat(got, " "))
	-- continuous: no jump at the turns, never past halfLen
	local maxStep, maxAbs = 0, 0
	local prev = at(0)
	for i = 1, 1600 do
		local pos = at(i * 0.01)
		maxStep = math.max(maxStep, (pos - prev).Magnitude)
		maxAbs = math.max(maxAbs, math.abs((pos - anchor.Position):Dot(R)))
		prev = pos
	end
	L.check(ctx, "E the walk is continuous (largest 0.01 s step <= speed x 0.01) and stays within +-halfLen", maxStep <= 0.04 + 1e-6 and maxAbs <= 14 + 1e-6, ("step %s, max %s"):format(s(maxStep), s(maxAbs)))
	L.check(ctx, "E djb2('z1_fixed') = 251135, phase = 135/1000 x 16 = 2.16 s (contract formula)", Patrol.hash("z1_fixed") == 251135 and near(Patrol.phase("z1_fixed", P), 2.16, 1e-9), s(Patrol.hash("z1_fixed")) .. " " .. s(Patrol.phase("z1_fixed", P)))
	local phOk = true
	for id in pairs(Z.PADS) do local ph = Patrol.phase(id, P); if ph < 0 or ph >= 16 then phOk = false end end
	L.check(ctx, "E every pad's phase in [0, T)", phOk)

	-- the zone 1 fixed pad walks along the lane (world Z), facing the lane at the turns
	local fixed = Zones.pad("z1_fixed")
	local a1 = fixed and fixed.anchor
	L.check(ctx, "E z1_fixed: anchor at the BossAnchor (233, 276), walking along the lane (RightVector = +-Z), looking at the lane (-X)", a1 ~= nil and near(a1.Position.X, 233, 1e-3) and near(a1.Position.Z, 276, 1e-3) and near(math.abs(a1.RightVector.Z), 1, 1e-6) and near(a1.LookVector.X, -1, 1e-6), a1 and tostring(a1.RightVector) .. " / " .. tostring(a1.LookVector))
	local now = Zones.now()
	local bp = Zones.bossPosition("z1_fixed", now)
	local want = Patrol.position(a1, Zones.patrolParams("z1_fixed"), now)
	L.check(ctx, "E Zones.bossPosition(z1_fixed, now) = Patrol.position(anchor, the sent params, now)", bp ~= nil and (bp - want).Magnitude < 1e-9, bp and tostring(bp))
	L.note(ctx, ("PATROL z1_fixed now=%.2f offset=%.2f studs (from %s to %s along Z)"):format(now, (bp - a1.Position):Dot(a1.RightVector), s(276 - 14), s(276 + 14)))

	-- 100,000 rolls per zone against the odds
	local rng = Random.new(7)
	local worst, worstAt = 0, ""
	for zone = 1, 6 do
		local count = { 0, 0, 0, 0, 0, 0 }
		local N = 100000
		for _ = 1, N do local t = Zones.pickTier(zone, rng:NextNumber()); count[t] += 1 end
		for tier = 1, 6 do
			local pExp = Z.ROLL_ODDS[zone][tier] / 100
			local sd = math.sqrt(N * pExp * (1 - pExp))
			local z = math.abs(count[tier] - N * pExp) / sd
			if z > worst then worst, worstAt = z, ("zone %d tier %d: %d vs %.0f"):format(zone, tier, count[tier], N * pExp) end
		end
	end
	L.check(ctx, "S5 100,000 rolls a zone match the odds (every tier within 4 standard deviations)", worst < 4, ("worst %.2f sd at %s"):format(worst, worstAt))

	-- the rolls at start
	local rollOk, staggers = true, {}
	for id, d in pairs(Z.PADS) do
		if d.kind == "roll" then
			local r = Zones.roll(id)
			local zz = r and Ids.parseCreature(r.creatureId)
			if not r or zz ~= d.zone then rollOk = false end
			if d.zone == 2 and r then staggers[d.slot] = r.endsAt end
		end
	end
	L.check(ctx, "S5 every rolling pad has a roll from its own zone from the first second", rollOk)
	local st1, st2, st3 = staggers[1], staggers[2], staggers[3]
	local diff1 = st1 and st2 and ((st2 - st1) % 45) or -1
	local diff2 = st2 and st3 and ((st3 - st2) % 45) or -1
	L.check(ctx, "S5 a zone's three timers are 15 s apart (TEAM CALL M2-10-2), each at most 45 s ahead", near(diff1, 15, 0.2) and near(diff2, 15, 0.2) and st3 - Zones.now() <= 45.01, ("%s, %s"):format(s(diff1), s(diff2)))

	local added, all = standIns()
	L.check(ctx, ("S5 all 24 pads registered (%d stand-ins added for the pads not in the world yet)"):format(added), all == true)
	local payload = Zones.padsPayload(p)
	local fieldsOk = #payload == 24
	for _, e in ipairs(payload) do
		local d = Z.PADS[e.padId]
		if not (d and e.zone == d.zone and e.kind == d.kind and type(e.creatureId) == "string" and e.power == Z.POWER[e.creatureId] and e.beaten == false
			and type(e.patrol) == "table" and e.patrol.halfLen == 14 and e.patrol.speed == 4 and e.patrol.pauseS == 1 and near(e.patrol.phase, Patrol.phase(e.padId, Z.PATROL))
			and ((e.kind == "roll") == (type(e.rollEndsAt) == "number"))) then fieldsOk = false end
	end
	L.check(ctx, "S5 Zones.Pads for the player: 24 entries with zone, creature, Power, kind, rollEndsAt (rolls only), beaten, patrol", fieldsOk, #payload)
	local fx = {}
	for _, e in ipairs(payload) do if e.kind == "fixed" then fx[e.zone] = e.power end end
	L.check(ctx, "S5 fixed pads' Power 25 / 250 / 2,500 / 25,000 / 250,000 / 2.5M", fx[1] == 25 and fx[2] == 250 and fx[3] == 2500 and fx[4] == 25000 and fx[5] == 250000 and fx[6] == 2.5e6)
	local http = game:GetService("HttpService")
	local bytes = #http:JSONEncode(payload)
	L.check(ctx, "Zones.Pads payload size reported (reliable event)", bytes > 0, ("%d bytes JSON"):format(bytes))
	removeStandIns()
end

-- ------------------------------------------------------------------ phase b: live rolls
local function phaseB()
	standIns()
	local before = {}
	for id, d in pairs(Z.PADS) do if d.kind == "roll" then before[id] = Zones.roll(id).rollId end end
	local sends0 = Zones.stats.sends
	setv("PadsFast", 1.5)
	-- the current timers still run out (up to 45 s); force them due by moving the clock once
	setv("ClockOffset", 46)
	task.wait(0.5)
	local mid = {}
	for id in pairs(before) do mid[id] = Zones.roll(id).rollId end
	task.wait(2.0)
	local advanced, endsOk = 0, true
	for id, r0 in pairs(before) do
		local r = Zones.roll(id)
		if r.rollId >= mid[id] + 1 and mid[id] > r0 then advanced += 1 end
		local left = r.endsAt - Zones.now()
		if left < -0.15 or left > 1.5 + 0.15 then endsOk = false end
		if Ids.parseCreature(r.creatureId) ~= Z.PADS[id].zone then endsOk = false end
	end
	L.check(ctx, "S5 rolls run on the server clock: all 18 rolled when due, then again every PadsFast 1.5 s", advanced == 18 and endsOk, ("%d advanced"):format(advanced))
	L.check(ctx, "S5 each roll sends Zones.Pads to the player", Zones.stats.sends > sends0, s(Zones.stats.sends - sends0))
	workspace:SetAttribute("HFB_PadsFast", nil)
	workspace:SetAttribute("HFB_ClockOffset", nil)
	task.wait(1.7)
	-- ForceRoll
	setv("ForceRoll", "z3_roll2=z3_t6")
	local pad = Zones.pad("z3_roll2")
	local r = Zones.roll("z3_roll2")
	L.check(ctx, "S5 ForceRoll z3_roll2=z3_t6: the pad's creature z3_t6, Power 22,500, a fresh 45 s timer", pad and pad.creatureId == "z3_t6" and pad.power == 22500 and r and near(r.endsAt - Zones.now(), 45, 0.5), pad and pad.creatureId .. " " .. s(r.endsAt - Zones.now()))
	local e
	for _, x in ipairs(Zones.padsPayload(p)) do if x.padId == "z3_roll2" then e = x end end
	L.check(ctx, "S5 the payload shows the forced roll and its timer", e and e.creatureId == "z3_t6" and e.power == 22500 and near(e.rollEndsAt, r.endsAt))
	L.check(ctx, "S5 the server's rolls are the same for everyone (one roll per pad, not per player)", Zones.roll("z3_roll2") == r)
	removeStandIns()
end

-- ------------------------------------------------------------------ phase c: fights, beaten, patrol
local function zonesBeaten() return table.clone(L.prof(ctx).zonesBeaten or {}) end
local function count(list, z) local n = 0; for _, v in ipairs(list) do if v == z then n += 1 end end; return n end

local function standAt(pos)
	L.tp(ctx, Vector3.new(pos.X, L.rootY(ctx), pos.Z))
	task.wait(0.05)
end

local function winFight(padId)
	clearCarry()
	local now = Zones.now()
	standAt(Zones.bossPosition(padId, now))
	local f = Fight.begin(p, padId)
	if not f then return nil, "refused " .. tostring(Fight.stats and Fight.stats.refused and "see stats") end
	task.wait(1.2) -- the first ring
	local r = L.forge(ctx, "fight", "perfect")
	L.waitFor(function() return Fight.get(p) == nil end, 2)
	return f, r
end

local function phaseC()
	standIns()
	setv("Wipe", true)
	setv("SetZonesBeaten", "")
	task.wait(0.3)
	L.muteClient(ctx, true)
	task.wait(1.6)
	setv("SetPower", 1e6)
	setv("ForceRoll", "z2_roll1=z2_t1")
	local padId = "z2_roll1"
	local pad = Zones.pad(padId)
	local P = Z.PATROL

	-- patrol and the ring test
	local now = Zones.now()
	local bp = Zones.bossPosition(padId, now) :: Vector3
	local off = (bp - pad.anchor.Position):Dot(pad.anchor.RightVector)
	local lim = pad.radius + Config.Fight.RING_SLACK + P.slack
	local look = pad.anchor.LookVector
	standAt(bp + look * (lim - 0.5))
	local inside = Fight.canStart(p, padId)
	standAt(Zones.bossPosition(padId, Zones.now()) + look * (lim + 1.0))
	local outside = Fight.canStart(p, padId)
	L.check(ctx, ("S5 Fight.Start against where the boss walks now: %.1f studs from it (ring %s + slack %s + patrol %s) ok, %.1f refused 'ring'"):format(lim - 0.5, s(pad.radius), s(Config.Fight.RING_SLACK), s(P.slack), lim + 1), inside == nil and outside == "ring", tostring(inside) .. "/" .. tostring(outside))
	-- standing on the pad's centre while the boss is far along its walk
	local tEnd = L.waitFor(function()
		local o = (Zones.bossPosition(padId, Zones.now()) - pad.anchor.Position):Dot(pad.anchor.RightVector)
		return math.abs(o) >= 12 and o
	end, 9, 0.05)
	standAt(pad.anchor.Position)
	local atCentre = Fight.canStart(p, padId)
	L.check(ctx, "P5 with the boss walked 12+ studs away, standing on the pad's centre is refused 'ring' (walk up to it)", tEnd ~= nil and atCentre == "ring", ("offset %s: %s"):format(s(tEnd), tostring(atCentre)))
	L.note(ctx, ("PATROL z2_roll1 offset at the first sample %.2f studs; limit %.1f studs"):format(off, lim))

	-- a win writes the zone once
	local zb0 = zonesBeaten()
	local f, r = winFight(padId)
	local zb1 = zonesBeaten()
	L.check(ctx, "S4 a won fight on a zone 2 pad: zonesBeaten gains 2", f ~= nil and count(zb1, 2) == 1 and count(zb0, 2) == 0, table.concat(zb1, ","))
	L.check(ctx, "E Fight.State bossPos = the boss's patrol position at the start (on the walk line)", f ~= nil and f.bossPos ~= nil and math.abs((f.bossPos - pad.anchor.Position):Dot(look)) < 1e-6 and math.abs((f.bossPos - pad.anchor.Position):Dot(pad.anchor.RightVector)) <= 14 + 1e-6, f and tostring(f.bossPos))
	local open, left = Zones.isOpen(p, padId)
	local rr = Zones.roll(padId)
	L.check(ctx, "S5 beaten this roll: the pad is closed to the player until it rolls (left = the roll's timer)", Zones.isBeaten(p, padId) and not open and near(left, rr.endsAt - Zones.now(), 0.3), s(left))
	local e
	for _, x in ipairs(Zones.padsPayload(p)) do if x.padId == padId then e = x end end
	L.check(ctx, "S5 Zones.Pads for the player says beaten = true for that pad", e and e.beaten == true)
	clearCarry()
	standAt(Zones.bossPosition(padId, Zones.now()))
	L.check(ctx, "S5 Fight.Start on the beaten roll refused 'closed'", Fight.canStart(p, padId) == "closed")
	-- a new roll opens it again; a second win in zone 2 does not duplicate
	setv("ForceRoll", "z2_roll1=z2_t2")
	L.check(ctx, "S5 the pad rolled: open to the player again, beaten false", Zones.isOpen(p, padId) and not Zones.isBeaten(p, padId))
	task.wait(1.0)
	local f2 = winFight(padId)
	L.check(ctx, "S4 a second zone 2 win: zonesBeaten still has 2 once", f2 ~= nil and count(zonesBeaten(), 2) == 1, table.concat(zonesBeaten(), ","))
	-- a loss writes nothing
	clearCarry()
	setv("SetPower", 1)
	task.wait(1.0)
	setv("ForceRoll", "z3_roll1=z3_t1")
	standAt(Zones.bossPosition("z3_roll1", Zones.now()))
	local f3 = Fight.begin(p, "z3_roll1")
	-- auto never in a fight (S2): a running fight refuses auto reports
	workspace:SetAttribute("HFB_PassOwned", "pass_auto_punch=on")
	ctx.hooks.PassOwned = true
	require(game:GetService("ServerScriptService").Systems.AutoPunch).autoToggle(p, { on = true })
	local ab = L.forge(ctx, "bag", "good", { auto = true })
	local af = L.forge(ctx, "fight", "good", { auto = true })
	L.check(ctx, "S2 Auto Punch never in a fight (fight running, toggle on, pass owned): auto 'bag' report refused (the fighter is off the bag pad: 'place'), auto 'fight' report refused 'place'", Fight.get(p) ~= nil and ab and (ab.reason == "place" or ab.reason == "state") and af and af.reason == "place", tostring(ab and ab.reason) .. "/" .. tostring(af and af.reason))
	workspace:SetAttribute("HFB_PassOwned", nil)
	for _ = 1, 3 do
		task.wait(0.7)
		L.forge(ctx, "fight", "miss")
	end
	L.waitFor(function() return Fight.get(p) == nil end, 2)
	L.check(ctx, "S4 a lost fight in zone 3: zonesBeaten has no 3", f3 ~= nil and count(zonesBeaten(), 3) == 0, table.concat(zonesBeaten(), ","))
	-- the fixed pad: back for that player after PadFastBack
	task.wait(2.2) -- the knockdown
	setv("SetPower", 1e6)
	setv("PadFastBack", 2)
	local f4 = winFight("z2_fixed")
	local b1 = Zones.isBeaten(p, "z2_fixed")
	local o1 = Zones.isOpen(p, "z2_fixed")
	task.wait(2.2)
	L.check(ctx, "S5 the fixed pad: beaten and closed after a win, open again after PadFastBack (2 s; 10 s live)", f4 ~= nil and b1 and not o1 and Zones.isOpen(p, "z2_fixed") and not Zones.isBeaten(p, "z2_fixed"), tostring(b1) .. "/" .. tostring(o1))
	L.check(ctx, "S4 zonesBeaten after the fixed-pad win is still { 2 } (zone already there)", count(zonesBeaten(), 2) == 1 and #zonesBeaten() == 1, table.concat(zonesBeaten(), ","))
	L.check(ctx, "S4 every zonesBeaten write came from a fight win (Zones.markBeaten is the only writer)", #Zones.stats.beatenWrites == 3, s(#Zones.stats.beatenWrites))
	-- the gap Fight.fightSpot leaves (M2-06's file): measured, reported, not judged here
	clearCarry()
	task.wait(1.0)
	local zf = Zones.pad("z1_fixed")
	local tFar = L.waitFor(function()
		local o = (Zones.bossPosition("z1_fixed", Zones.now()) - zf.anchor.Position):Dot(zf.anchor.RightVector)
		return math.abs(o) >= 10 and o
	end, 9, 0.05)
	if tFar then
		local bpos = Zones.bossPosition("z1_fixed", Zones.now())
		standAt(bpos)
		local f5 = Fight.begin(p, "z1_fixed")
		local hrp = ctx.hrp.Position
		L.note(ctx, ("FIGHTSPOT z1_fixed boss walked %.1f studs; fighter placed %.1f studs from the walking boss, %.1f from the pad centre (spot %s)"):format(tFar, L.flat(hrp, bpos), L.flat(hrp, zf.anchor.Position), tostring(f5 and f5.spot)))
		if f5 then Fight.finish(p, f5, "run") end
	end
	L.muteClient(ctx, false)
	removeStandIns()
end

local ok, err = pcall(function()
	if ctx.phase == "a" then phaseA()
	elseif ctx.phase == "b" then phaseB()
	elseif ctx.phase == "c" then phaseC()
	else L.check(ctx, "known phase", false, ctx.phase) end
end)
if not ok then L.check(ctx, "phase ran without a Lua error", false, tostring(err)) end
removeStandIns()
L.finish(ctx)
