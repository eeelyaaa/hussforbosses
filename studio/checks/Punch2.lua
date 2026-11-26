if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-06: the punch server after the manager's P3 and P2 (team/requirements/m2-punch-p3-p2-p4.md, m2-contract.md B,
-- m2-punch-numbers.md sections 1 to 3; gate rows S1 and S4 in m2-gate.md). PLAY MODE, one call per phase:
--   { phase = "a" }  the M2 numbers in Config; the bag: untimed = one punch at once (+STRENGTH_VALUE, x1.35 at Strength 2),
--                    a second untimed in the ring refused 'untimedBusy', timed after untimed, untimed during a burst
--                    'busy', a forged timed report over the rate 'rate', Good 4 / Perfect 8 unchanged, auto rules,
--                    tap-time sanity, the limiter at 20 reports a second, the funnel marks.
--   { phase = "b" }  mashing: a forged untimed every 0.1 s for 10 s against 10 s of Good bursts at the real cadence.
--   { phase = "c" }  fights: untimed damage = Power x 1 (Easy, Fair: no heart; Hard: a heart after the punch, loss on
--                    the third), the expected landing moves on one ring after an untimed tap (stall timing), Good x4 and
--                    Perfect x8, bossPos in the fight, the heart rule table.
--   { phase = "d" }  the fight spot around a patrolling boss (M2-10 follow-up): at both ends of the walk (14 studs
--                    from rest, ClockOffset puts the patrol clock in each end's pause), the fighter stands at the same
--                    distance from the boss as at rest, inside the moved ring.
-- Every phase first forces the account's real passes off (PassOwned: the Studio account owns Auto Punch, Perfect Auto
-- Punch and 2x Power for real, which doubles bag values).
-- Forged reports go through Punch.report (the handler after Net's limiter) with the real client's reports held off
-- (L.muteClient). Warm-up as M1: 1.6 s after muting before the first forged report. Hooks and Config overrides are
-- cleared at the end. Installed into ServerStorage.TmpChecks next to CheckLib (CheckAll "install", then this file).
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Punch, Fight, Carry, Session, Net = L.Config, L.Punch, L.Fight, L.Carry, L.Session, L.Net
local s = L.s

local ctx = L.begin("Punch2", ARGS)
local p = ctx.p
local plot = workspace.Plots.Plot1
local ringPart = workspace.Zones.Z1.Pads.Fixed.Ring
L.rootY(ctx)

local SV = Config.Bag.STRENGTH_VALUE
local PASSES_OFF = "pass_auto_punch=off,pass_perfect_auto_punch=off,pass_2x_power=off"
local function passesOff()
	L.hook(ctx, "PassOwned", PASSES_OFF)
	task.wait(0.2)
end
local function untimedLog()
	local e = Punch.stats.log[#Punch.stats.log]
	return e
end
local function waitSince(t, sec)
	local left = sec - (os.clock() - t)
	if left > 0 then task.wait(left) end
end
local function funnelHas(name)
	for _, e in ipairs(L.TestHooks.reports.funnel or {}) do
		if e.name == name and e.userId == p.UserId then return true end
	end
	return false
end
local function clearCarry() if Carry.get(p) then Carry.lose(p, "check") end; task.wait(0.05) end

local function same(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do if math.abs(a[i] - b[i]) > 1e-9 then return false end end
	return true
end

local function configValues()
	local P, F = Config.Punch, Config.Fight
	L.check(ctx, "Config.Punch.RING = 1.05 .. 0.41 (P2)", same(P.RING, { 1.05, 0.98, 0.91, 0.84, 0.77, 0.70, 0.63, 0.56, 0.48, 0.41 }), table.concat(P.RING, " "))
	L.check(ctx, "cycles 1.66 (Speed 1) and 1.02 (Speed 10)", math.abs(P.CYCLE(1) - 1.66) < 1e-9 and math.abs(P.CYCLE(10) - 1.02) < 1e-9, s(P.CYCLE(1)) .. "/" .. s(P.CYCLE(10)))
	L.check(ctx, "bag windows 130 / 55 ms", P.BAG_WINDOWS.goodMs == 130 and P.BAG_WINDOWS.perfectMs == 55)
	L.check(ctx, "GRADE_VALUE perfect 2, good 1, untimed 1, miss 0; BIG_MULT 2; BEAT and BURST_LEN unchanged",
		P.GRADE_VALUE.perfect == 2 and P.GRADE_VALUE.good == 1 and P.GRADE_VALUE.untimed == 1 and P.GRADE_VALUE.miss == 0 and P.BIG_MULT == 2
			and same(P.BEAT, { 0, 0.213, 0.401 }) and P.BURST_LEN == 0.61 and P.MISS_RESTART == 0.61)
	L.check(ctx, "RATE_TOLERANCE 0.75, UNTIMED_MIN_GAP_S 0.66, RING_GRACE_S 0.15, Punch.Report 4/s, EARLY_TAP_S gone",
		P.RATE_TOLERANCE == 0.75 and P.UNTIMED_MIN_GAP_S == 0.66 and P.RING_GRACE_S == 0.15 and P.RATE["Punch.Report"] == 4 and P.EARLY_TAP_S == nil)
	local want = { easy = { 150, 65 }, fair = { 130, 55 }, hard = { 100, 40 }, veryHard = { 80, 30 }, brutal = { 65, 24 }, impossible = { 55, 20 } }
	local ok, got = #F.BANDS == 6, {}
	for _, b in ipairs(F.BANDS) do
		local w = want[b.id]
		table.insert(got, ("%s %d/%d"):format(b.id, b.goodMs, b.perfectMs))
		if not w or w[1] ~= b.goodMs or w[2] ~= b.perfectMs then ok = false end
	end
	L.check(ctx, "fight bands 150/65 130/55 100/40 80/30 65/24 55/20 (Good/Perfect)", ok, table.concat(got, ", "))
	local heart = {}
	for _, b in ipairs(F.BANDS) do table.insert(heart, b.id .. "=" .. tostring(F.untimedCostsHeart(b.id))) end
	L.check(ctx, "heart rule (PROVISIONAL Q1): untimed costs a heart from Hard up, not Easy or Fair",
		F.UNTIMED_HEART_FROM == "hard" and not F.untimedCostsHeart("easy") and not F.untimedCostsHeart("fair") and F.untimedCostsHeart("hard")
			and F.untimedCostsHeart("veryHard") and F.untimedCostsHeart("brutal") and F.untimedCostsHeart("impossible"), table.concat(heart, " "))
end

-- ------------------------------------------------------------------ phase a: the bag
local function phaseA()
	configValues()
	L.hook(ctx, "Wipe", true)
	task.wait(0.3)
	passesOff()
	L.tp(ctx, L.onPart(ctx, plot.BagPad))
	task.wait(0.4)
	L.muteClient(ctx, true)
	task.wait(1.6)
	local sv1 = SV(1)

	-- 1. untimed = one punch, applied at accept time, no burst
	local p0 = L.power(ctx)
	local r1 = L.forge(ctx, "bag", "untimed")
	local t1 = os.clock()
	local st = Punch.state(p)
	local e1 = untimedLog()
	L.check(ctx, "S1 untimed on the bag accepted, gains { STRENGTH_VALUE(1) } = { 1 }", r1 and r1.accepted and type(r1.gains) == "table" and #r1.gains == 1 and r1.gains[1] == sv1 and sv1 == 1, r1 and (tostring(r1.reason) .. " " .. (r1.gains and table.concat(r1.gains, ",") or "-")))
	L.check(ctx, "S1 untimed: +1 Power at once (beat 0, no wait), no burst running", L.power(ctx) == p0 + sv1 and st and st.burst == nil, ("+%s burst %s"):format(s(L.power(ctx) - p0), tostring(st and st.burst)))
	L.check(ctx, "S1 untimed: one logged punch, grade untimed, n 1, value 1", e1 and e1.grade == "untimed" and e1.n == 1 and e1.value == sv1 and e1.context == "bag")
	L.check(ctx, "funnel FirstBagPunch marked on the first untimed bag punch", funnelHas("FirstBagPunch"))

	-- 2. a second untimed in the same ring
	task.wait(0.2)
	local before = L.snap(ctx)
	local r2 = L.forge(ctx, "bag", "untimed")
	L.check(ctx, "S1 a second untimed 0.2 s later refused 'untimedBusy', no state change", r2 and not r2.accepted and r2.reason == "untimedBusy" and L.snap(ctx) == before, r2 and r2.reason)
	waitSince(t1, 0.72)
	local r3 = L.forge(ctx, "bag", "untimed")
	L.check(ctx, "S1 an untimed 0.72 s after an untimed (under 0.66 + the bag's 0.13 Good window) refused 'untimedBusy' (TEAM CALL M2-06-1)", r3 and not r3.accepted and r3.reason == "untimedBusy" and L.snap(ctx) == before, r3 and r3.reason)
	waitSince(t1, 0.92)
	local r4 = L.forge(ctx, "bag", "untimed")
	local t4 = os.clock()
	L.check(ctx, "S1 an untimed 0.92 s after an untimed (the next ring's earliest legit tap is >= 0.89) accepted, +1", r4 and r4.accepted and L.power(ctx) == p0 + 2 * sv1, r4 and r4.reason)

	-- 3. timed after untimed
	waitSince(t4, 0.3)
	before = L.snap(ctx)
	local r5 = L.forge(ctx, "bag", "good")
	L.check(ctx, "S1 a Good 0.3 s after an untimed (under 0.66 s since any) refused 'rate', no state change", r5 and not r5.accepted and r5.reason == "rate" and L.snap(ctx) == before, r5 and r5.reason)
	waitSince(t4, 0.72)
	local pg = L.power(ctx)
	local r6 = L.forge(ctx, "bag", "good")
	local tg = os.clock()
	L.check(ctx, "S1 a Good 0.72 s after an untimed accepted, gains 1/1/2 (timed burst unchanged)", r6 and r6.accepted and r6.gains and same(r6.gains, { sv1, sv1, 2 * sv1 }), r6 and (tostring(r6.reason) .. " " .. (r6.gains and table.concat(r6.gains, ",") or "-")))
	-- 4. untimed during the burst
	waitSince(tg, 0.1)
	local r7 = L.forge(ctx, "bag", "untimed")
	L.check(ctx, "S1 an untimed during a burst refused 'busy'", r7 and not r7.accepted and r7.reason == "busy", r7 and r7.reason)
	waitSince(tg, 0.5)
	L.check(ctx, "S1 Good = 4 on the bag (the burst the untimed hit is unchanged)", L.power(ctx) == pg + 4 * sv1, "+" .. s(L.power(ctx) - pg))
	-- 5. a forged timed report over the rate
	waitSince(tg, 0.9)
	before = L.snap(ctx)
	local r8 = L.forge(ctx, "bag", "perfect")
	L.check(ctx, "S1 a forged Perfect 0.9 s after a Good (under CYCLE x 0.75 = 1.245) refused 'rate', no state change", r8 and not r8.accepted and r8.reason == "rate" and L.snap(ctx) == before, r8 and r8.reason)
	waitSince(tg, 1.3)
	local pp = L.power(ctx)
	local r9 = L.forge(ctx, "bag", "perfect")
	local tp = os.clock()
	task.wait(0.5)
	L.check(ctx, "S1 Perfect = 8 (2/2/4) 1.3 s after a Good, accepted", r9 and r9.accepted and same(r9.gains, { 2 * sv1, 2 * sv1, 4 * sv1 }) and L.power(ctx) == pp + 8 * sv1, "+" .. s(L.power(ctx) - pp))
	L.check(ctx, "funnel FirstPerfectLanded marked on the first hand Perfect", funnelHas("FirstPerfectLanded"))
	-- 6. untimed right after a burst ends
	waitSince(tp, 0.635)
	before = L.snap(ctx)
	local r10 = L.forge(ctx, "bag", "untimed")
	L.check(ctx, "S1 an untimed 0.635 s after a burst's tap (burst over, under 0.66) refused 'untimedBusy'", r10 and not r10.accepted and r10.reason == "untimedBusy" and L.snap(ctx) == before, r10 and r10.reason)
	waitSince(tp, 0.78)
	local pu = L.power(ctx)
	local r11 = L.forge(ctx, "bag", "untimed")
	L.check(ctx, "S1 an untimed 0.78 s after a burst's tap accepted (legit: 0.61 + 0.15 = 0.76)", r11 and r11.accepted and L.power(ctx) == pu + sv1, r11 and r11.reason)

	-- 7. auto and tap-time rules
	task.wait(1.3)
	before = L.snap(ctx)
	local ra = L.forge(ctx, "bag", "untimed", { auto = true })
	L.check(ctx, "forged untimed with auto = true refused 'grade' (auto is never untimed)", ra and not ra.accepted and ra.reason == "grade" and L.snap(ctx) == before, ra and ra.reason)
	local rm = L.forge(ctx, "bag", "miss", { auto = true })
	L.check(ctx, "forged miss with auto = true refused 'grade'", rm and not rm.accepted and rm.reason == "grade", rm and rm.reason)
	local rb = L.forge(ctx, "bag", "good", { auto = true })
	L.check(ctx, "auto Good with no Auto Punch pass refused 'pass' (M2-10 builds the pass and toggle)", rb and not rb.accepted and rb.reason == "pass" and L.snap(ctx) == before, rb and rb.reason)
	local d0 = Punch.stats.dropped
	Punch.report(p, { seq = 7, context = "bag", grade = "untimed", tapServerTime = workspace:GetServerTimeNow(), auto = "yes" })
	Punch.report(p, { seq = 8, context = "bag", grade = "untimeD", tapServerTime = workspace:GetServerTimeNow() })
	L.check(ctx, "auto not a boolean, and an unknown grade, dropped by the shape check", Punch.stats.dropped == d0 + 2 and L.snap(ctx) == before, Punch.stats.dropped - d0)
	Punch.report(p, { seq = 9, context = "bag", grade = "untimed" })
	local rn = Punch.stats.lastResult[p.UserId]
	L.check(ctx, "an untimed with no tapServerTime refused 'grade'", rn and rn.seq == 9 and not rn.accepted and rn.reason == "grade" and L.snap(ctx) == before, rn and rn.reason)
	local ro = L.forge(ctx, "bag", "untimed", { tapServerTime = workspace:GetServerTimeNow() - 2 })
	L.check(ctx, "an untimed with a tap 2 s old refused 'grade'", ro and not ro.accepted and ro.reason == "grade" and L.snap(ctx) == before, ro and ro.reason)

	-- 8. Strength 2
	ctx.expect = "hook"
	L.hook(ctx, "SetStrength", 2)
	task.wait(0.3)
	ctx.expect = nil
	task.wait(0.5)
	local p2 = L.power(ctx)
	local r12 = L.forge(ctx, "bag", "untimed")
	L.check(ctx, ("S1 untimed at Strength 2 = STRENGTH_VALUE(2) = %s (x%s of Strength 1; brief x1.35)"):format(s(SV(2)), s(SV(2) / sv1)),
		r12 and r12.accepted and math.abs(L.power(ctx) - p2 - SV(2)) < 1e-9 and r12.gains[1] == SV(2) and math.abs(SV(2) / sv1 - 1.35) < 1e-9, "+" .. s(L.power(ctx) - p2))
	L.note(ctx, "rebirth and 2x Power pass multipliers ride on Bag.value (M2-10 adds them); untimed reads the same function as a Good punch 1")
	-- 9. a bag Miss gives nothing
	task.wait(0.8)
	before = L.snap(ctx)
	local r13 = L.forge(ctx, "bag", "miss")
	L.check(ctx, "S1 a bag Miss accepted and gives nothing", r13 and r13.accepted and L.snap(ctx) == before, r13 and r13.reason)

	-- 10. the limiter at 20 reports a second: the real path's Net.rateOk (4/s) in front of the handler. The muted
	-- client holds the live "Punch.Report" key full, so the same limiter runs here under a check-only key.
	task.wait(1)
	local passed, acc0, pw0 = 0, Punch.stats.accepted, L.power(ctx)
	local tl = os.clock()
	for i = 1, 20 do
		if Net.rateOk(p, "Punch2.RateCap", Config.Punch.RATE["Punch.Report"]) then
			passed += 1
			L.forge(ctx, "bag", "untimed")
		end
		waitSince(tl, i * 0.05)
	end
	L.check(ctx, ("S1 20 untimed reports in 1 s: the limiter passes <= 4, the handler accepts <= 2 (got %d passed)"):format(passed),
		passed <= 4 and Punch.stats.accepted - acc0 <= 2 and L.power(ctx) - pw0 <= 2 * SV(2), ("accepted %d, +%s Power"):format(Punch.stats.accepted - acc0, s(L.power(ctx) - pw0)))
	L.authority(ctx, 0, "phase a")
end

-- ------------------------------------------------------------------ phase b: mashing vs Good
local function phaseB()
	L.hook(ctx, "Wipe", true)
	task.wait(0.3)
	passesOff()
	L.tp(ctx, L.onPart(ctx, plot.BagPad))
	task.wait(0.4)
	L.muteClient(ctx, true)
	task.wait(1.6)
	-- mash: a forged untimed every 0.1 s for 10 s, straight into the handler (past the 4/s limiter: a stronger cheat
	-- than any client can send)
	local m0, a0 = L.power(ctx), Punch.stats.accepted
	local t0 = os.clock()
	local refused = {}
	for i = 1, 100 do
		local r = L.forge(ctx, "bag", "untimed")
		if r and not r.accepted then refused[r.reason] = (refused[r.reason] or 0) + 1 end
		waitSince(t0, i * 0.1)
	end
	local mash = L.power(ctx) - m0
	local mashAcc = Punch.stats.accepted - a0
	L.note(ctx, ("mash: 100 untimed in 10 s -> %d accepted, +%s Power; refused untimedBusy %d"):format(mashAcc, s(mash), refused.untimedBusy or 0))
	L.check(ctx, "S1 mashing refused by rate: at most one untimed per 0.79 s (<= 13 in 10 s)", mashAcc <= 13 and (refused.untimedBusy or 0) >= 85, mashAcc)
	task.wait(1)
	-- Good bursts at the real cadence (one per cycle, 1.66 s at Speed 1) for 10 s
	local g0 = L.power(ctx)
	local t1 = os.clock()
	local cyc = Config.Punch.CYCLE(1)
	local k, gacc = 0, 0
	while os.clock() - t1 < 10 do
		local r = L.forge(ctx, "bag", "good")
		if r and r.accepted then gacc += 1 end
		k += 1
		waitSince(t1, k * cyc)
	end
	task.wait(0.5)
	local good = L.power(ctx) - g0
	L.note(ctx, ("Good: %d bursts in 10 s at %.2f s -> +%s Power"):format(gacc, cyc, s(good)))
	L.check(ctx, "acceptance 2: 10 s of mashing gives less Power than 10 s of Good bursts", mash < good and gacc >= 6, ("mash %s < good %s"):format(s(mash), s(good)))
	L.authority(ctx, 0, "phase b")
end

-- ------------------------------------------------------------------ phase c: fights
-- next to where the boss is now (M2-10's patrol): 3 studs off it across the lane, else the pad's ring
local function nearBoss()
	local Zones = L.Zones
	local pad = Zones.pad("z1_fixed")
	local bp = type(Zones.bossPosition) == "function" and Zones.bossPosition("z1_fixed", Zones.now()) or nil
	if not (pad and pad.anchor and bp) then return L.onPart(ctx, ringPart, 1, 1) end
	local top = ringPart.Position.Y + ringPart.Size.Y / 2 + L.rootY(ctx)
	return Vector3.new(bp.X, top, bp.Z) + pad.anchor.LookVector * 3
end
local function startFight(power)
	clearCarry()
	Session.set(p, "power", power)
	L.tp(ctx, nearBoss())
	task.wait(0.1)
	local f = Fight.begin(p, "z1_fixed")
	return f, (not f) and Fight.canStart(p, "z1_fixed") or nil
end
local function beatsOf(fid)
	local out = {}
	for _, e in ipairs(Fight.stats.log) do if e.fightId == fid and (e.kind == "beat" or e.kind == "heart" or e.kind == "win" or e.kind == "loss") then table.insert(out, e) end end
	return out
end
-- waits until the server's current fight ring is open (its landing - RING + 0.25 s), then forges an untimed report:
-- the real client's rhythm (one untimed per ring, M2-02 S6)
local function untimedInRing()
	local st = Punch.state(p)
	if st and st.nextLanding then
		local opens = st.nextLanding - Config.Punch.RING[L.prof(ctx).speedLevel] + 0.25
		local w = opens - workspace:GetServerTimeNow()
		if w > 0 then task.wait(w) end
	end
	return L.forge(ctx, "fight", "untimed")
end
local function endFight(f)
	if f and Fight.get(p) == f then Fight.finish(p, f, "run") end
	clearCarry()
	task.wait(0.9) -- past the 0.79 s untimed-after-untimed gap, so the next fight's first untimed is not refused by it
end

local function phaseC()
	local keep = { pad = Config.Fight.PAD_COOLDOWN_S, knock = Config.Fight.KNOCKDOWN_S }
	Config.Fight.PAD_COOLDOWN_S = 0
	Config.Fight.KNOCKDOWN_S = 0.1
	local ok, err = pcall(function()
		L.hook(ctx, "Wipe", true)
		task.wait(0.3)
		passesOff()
		L.hook(ctx, "PadFastBack", 0)
		L.tp(ctx, L.onPart(ctx, ringPart, 1, 1))
		L.muteClient(ctx, true)
		task.wait(1.6)

		-- Fair (r = 1): untimed = Power x 1, no heart; timed after untimed; Good x4; Perfect x2 per punch
		local f, why = startFight(25)
		if L.check(ctx, "S4 setup: a Fair fight starts (Power 25, Chomp Frog 25)", f ~= nil and f.band == "fair", why or (f and f.band)) then
			L.check(ctx, "Fight.State started carries bossPos (the pad's ring until M2-10's patrol)", typeof(f.bossPos) == "Vector3", f.bossPos)
			L.check(ctx, "funnel FirstFightStarted marked", funnelHas("FirstFightStarted"))
			task.wait(0.3)
			local r1 = L.forge(ctx, "fight", "untimed")
			local t1 = os.clock()
			L.check(ctx, "S4 untimed in a Fair fight: gains { 25 } and health 250 -> 225 at once, hearts 3", r1 and r1.accepted and r1.gains and r1.gains[1] == 25 and f.health == 225 and f.hearts == 3,
				("%s health %s hearts %s"):format(r1 and tostring(r1.reason) or "-", s(f.health), s(f.hearts)))
			task.wait(0.3)
			local r2 = L.forge(ctx, "fight", "untimed")
			L.check(ctx, "S4 a second untimed 0.3 s later refused 'untimedBusy', health 225", r2 and not r2.accepted and r2.reason == "untimedBusy" and f.health == 225, r2 and r2.reason)
			waitSince(t1, 0.4)
			local r3 = L.forge(ctx, "fight", "good")
			L.check(ctx, "S4 a Good 0.4 s after an untimed refused 'rate'", r3 and not r3.accepted and r3.reason == "rate" and f.health == 225, r3 and r3.reason)
			waitSince(t1, 1.0)
			local r4 = L.forge(ctx, "fight", "good")
			local tg = os.clock()
			task.wait(0.5)
			L.check(ctx, "S4 Good in the fight = Power x 4 (25/25/50), health 225 -> 125", r4 and r4.accepted and r4.gains and same(r4.gains, { 25, 25, 50 }) and f.health == 125, ("%s health %s"):format(r4 and tostring(r4.reason) or "-", s(f.health)))
			waitSince(tg, 1.3)
			local r5 = L.forge(ctx, "fight", "perfect")
			task.wait(0.5)
			local list = {}
			for _, e in ipairs(beatsOf(f.fightId)) do table.insert(list, e.kind .. (e.damage and (":" .. s(e.damage)) or "")) end
			L.check(ctx, "S4 Perfect = Power x 8 (gains 50/50/100); the bar (125) empties on punch 3, the fight is won, hearts 3",
				r5 and r5.accepted and same(r5.gains, { 50, 50, 100 }) and Fight.get(p) == nil and f.health == 0 and f.hearts == 3, table.concat(list, " "))
			L.check(ctx, "funnel FirstBossBeaten marked on the win", funnelHas("FirstBossBeaten"))
		end
		endFight(f)

		-- Easy (r = 0.5): five untimed punches win with no heart
		f, why = startFight(50)
		if L.check(ctx, "S4 setup: an Easy fight starts (Power 50)", f ~= nil and f.band == "easy", why or (f and f.band)) then
			task.wait(0.3)
			local n = 0
			while Fight.get(p) == f and n < 8 do
				untimedInRing()
				n += 1
			end
			local dmg, hearts = {}, 0
			for _, e in ipairs(beatsOf(f.fightId)) do
				if e.kind == "beat" then table.insert(dmg, s(e.damage)) elseif e.kind == "heart" then hearts += 1 end
			end
			L.check(ctx, "S4 Easy: five untimed punches of 50 (Power x 1) win, no heart lost", f.over and f.health == 0 and #dmg == 5 and table.concat(dmg, ",") == "50,50,50,50,50" and hearts == 0 and f.hearts == 3,
				("beats %s, hearts lost %d"):format(table.concat(dmg, ","), hearts))
		end
		endFight(f)

		-- Fair: the expected landing moves on one ring after an untimed tap (stall rule timing)
		f, why = startFight(25)
		if L.check(ctx, "S4 setup: a Fair fight for the stall timing", f ~= nil, why) then
			local t0 = os.clock()
			task.wait(0.3)
			L.forge(ctx, "fight", "untimed")
			local stalls0 = Punch.stats.stalls
			local got = L.waitFor(function() return f.hearts < 3 end, 7)
			local dt = os.clock() - t0
			local R = Config.Punch.RING[1]
			local expectS = R + Config.Punch.MISS_RESTART + R + R + Config.Fight.STALL_SLACK_S
			L.check(ctx, ("S4 no tap after an untimed: one heart by the stall rule at RING + 0.61 + RING + RING + 0.5 = %.2f s (+/- 0.15)"):format(expectS),
				got and f.hearts == 2 and Punch.stats.stalls == stalls0 + 1 and math.abs(dt - expectS) <= 0.15, ("%.2f s, hearts %s"):format(dt, s(f.hearts)))
		end
		endFight(f)

		-- Hard (r = 1.5): an untimed punch lands, then costs a heart; the third is the loss
		f, why = startFight(16.67)
		if L.check(ctx, "S4 setup: a Hard fight starts (Power 16.67, r 1.4998)", f ~= nil and f.band == "hard", why or (f and f.band)) then
			task.wait(0.3)
			local r1 = L.forge(ctx, "fight", "untimed")
			local seq = beatsOf(f.fightId)
			local order = {}
			for _, e in ipairs(seq) do table.insert(order, e.kind .. (e.why and ("/" .. e.why) or "")) end
			L.check(ctx, "S4 Hard: untimed deals 16.67 then costs one heart (beat before heart, why 'untimed')",
				r1 and r1.accepted and math.abs(f.health - (250 - 16.67)) < 1e-6 and f.hearts == 2 and #seq == 2 and seq[1].kind == "beat" and seq[2].kind == "heart" and seq[2].why == "untimed",
				table.concat(order, " "))
			untimedInRing()
			untimedInRing()
			task.wait(0.2)
			local lost = false
			for _, e in ipairs(Fight.stats.log) do if e.fightId == f.fightId and e.kind == "loss" then lost = true end end
			L.check(ctx, "S4 Hard: the third untimed punch takes the last heart, the fight is lost", f.over and lost and f.hearts == 0, ("over %s hearts %s"):format(tostring(f.over), s(f.hearts)))
		end
		endFight(f)
		task.wait(0.3)

		-- M2-02 S6: untimed mashing in a Fair fight cannot push the expected landing ahead of the clock
		f, why = startFight(25)
		if L.check(ctx, "S4 setup: a Fair fight for untimed mashing (M2-02 S6)", f ~= nil, why) then
			local R = Config.Punch.RING[1]
			local re = L.forge(ctx, "fight", "untimed")
			L.check(ctx, "S6 an untimed at the fight's first ring open (inside RING_GRACE_S less the 0.10 s slack) refused 'untimedBusy'", re and not re.accepted and re.reason == "untimedBusy", re and re.reason)
			task.wait(0.25)
			local acc, ahead = 0, -math.huge
			local t0 = os.clock()
			for i = 1, 60 do -- a forged untimed every 0.1 s for 6 s
				local r = L.forge(ctx, "fight", "untimed")
				if r and r.accepted then acc += 1 end
				local st = Punch.state(p)
				if st and st.nextLanding then ahead = math.max(ahead, st.nextLanding - workspace:GetServerTimeNow()) end
				waitSince(t0, i * 0.1)
			end
			local bound = Config.Punch.MISS_RESTART + 2 * R
			L.check(ctx, ("S6 mashing 6 s: at most one untimed per server ring (<= 5 accepted), the expected landing never more than 0.61 + 2 x RING = %.2f s ahead"):format(bound),
				acc <= 5 and acc >= 3 and ahead <= bound + 1e-6 and f.hearts == 3, ("accepted %d, max ahead %.2f s, hearts %s"):format(acc, ahead, s(f.hearts)))
			-- then stop: the next ring passes untapped and the stall rule takes a heart, on time
			local st = Punch.state(p)
			local deadline = (st and st.nextLanding or 0) + R + Config.Fight.STALL_SLACK_S
			local got = L.waitFor(function() return f.hearts < 3 end, 6)
			local late = workspace:GetServerTimeNow() - deadline
			L.check(ctx, "S6 after the mashing stops, a ring with no tap still costs one heart at the stall deadline (+/- 0.15 s)", got and f.hearts == 2 and math.abs(late) <= 0.15, ("hearts %s, %.2f s from the deadline"):format(s(f.hearts), late))
		end
		endFight(f)

		-- a reported Miss in a fight still costs a heart (M1 rule kept)
		f, why = startFight(25)
		if L.check(ctx, "setup: a Fair fight for a reported Miss", f ~= nil, why) then
			task.wait(0.3)
			local rm = L.forge(ctx, "fight", "miss")
			L.check(ctx, "S4 a reported Miss in a fight: one heart", rm and rm.accepted and f.hearts == 2, rm and rm.reason)
		end
		endFight(f)
	end)
	Config.Fight.PAD_COOLDOWN_S = keep.pad
	Config.Fight.KNOCKDOWN_S = keep.knock
	if not ok then error(err, 0) end
end

-- ------------------------------------------------------------------ phase d: the fight spot on a patrolling boss
local function phaseD()
	local Patrol = require(game.ReplicatedStorage.Shared.Patrol)
	local Zones = L.Zones
	local keepCool = Config.Fight.PAD_COOLDOWN_S
	Config.Fight.PAD_COOLDOWN_S = 0 -- the first end's Run must not close the pad for the second (restored below)
	L.hook(ctx, "Wipe", true)
	task.wait(0.3)
	passesOff()
	L.hook(ctx, "PadFastBack", 0)
	local padId = "z1_fixed"
	local pad = Zones.pad(padId)
	if not L.check(ctx, "setup: z1_fixed has a patrol anchor and Zones.bossPosition", pad ~= nil and pad.anchor ~= nil and type(Zones.bossPosition) == "function") then return end
	local P = Zones.patrolParams(padId)
	local anchor = pad.anchor
	local period = Patrol.period(P)
	-- the middle of each end's pause on the patrol clock, from a scan of one period
	local t0 = workspace:GetServerTimeNow()
	local ends = { plus = {}, minus = {} }
	for k = 0, 3199 do
		local t = t0 + k * period / 3200
		local pos = Patrol.position(anchor, P, t)
		local along = (pos - anchor.Position):Dot(anchor.RightVector)
		if along >= P.halfLen - 1e-3 then table.insert(ends.plus, t) elseif along <= -P.halfLen + 1e-3 then table.insert(ends.minus, t) end
	end
	local function mid(list) -- the middle of the first contiguous run
		if #list == 0 then return nil end
		local run = { list[1] }
		for i = 2, #list do if list[i] - list[i - 1] < 2 * period / 3200 then table.insert(run, list[i]) else break end end
		return (run[1] + run[#run]) / 2
	end
	local boss = nil
	for _, d in ipairs(pad.model:GetDescendants()) do if d:IsA("Model") and (d.Name == "Boss" or game:GetService("CollectionService"):HasTag(d, "HFB_Boss")) then boss = d break end end
	if not L.check(ctx, "setup: the pad has a boss model", boss ~= nil) then return end
	local rest = boss:GetPivot().Position
	L.note(ctx, ("rest pivot vs patrol anchor (flat): %.2f studs"):format(Vector3.new(rest.X - anchor.Position.X, 0, rest.Z - anchor.Position.Z).Magnitude))
	local top = pad.ring.Position.Y + pad.ring.Size.Y / 2 + L.rootY(ctx)
	-- at rest: the M1-26b spot from a stand point 3 studs off the boss across the lane
	local side = anchor.LookVector
	local restFrom = Vector3.new(rest.X, top, rest.Z) + side * 3
	local restSpot = Fight.fightSpot(pad, restFrom, L.rootY(ctx), { ctx.char }, nil)
	local dRest = restSpot and Vector3.new(restSpot.Position.X - rest.X, 0, restSpot.Position.Z - rest.Z).Magnitude
	L.check(ctx, "setup: the rest spot (no patrol offset) exists", dRest ~= nil, dRest)
	-- visit the ends in patrol-clock order: the clock must only go forward, or the first Run's pad time
	-- (Zones.closeFor at the first end's clock) lies in the second end's future and the pad reads 'closed'
	local order = { { "plus", mid(ends.plus) }, { "minus", mid(ends.minus) } }
	if order[1][2] and order[2][2] and order[2][2] < order[1][2] then order = { order[2], order[1] } end
	for _, e in ipairs(order) do
		local name, tEnd = e[1], e[2]
		if L.check(ctx, ("setup: the %s end's pause found on the patrol clock"):format(name), tEnd ~= nil) then
			clearCarry()
			L.hook(ctx, "ClockOffset", tEnd - workspace:GetServerTimeNow())
			task.wait(0.05)
			local bp = Zones.bossPosition(padId, Zones.now())
			local along = (bp - anchor.Position):Dot(anchor.RightVector)
			L.tp(ctx, Vector3.new(bp.X, top, bp.Z) + side * 3)
			task.wait(0.15)
			local why = Fight.canStart(p, padId)
			local f = if why == nil then Fight.begin(p, padId) else nil
			if L.check(ctx, ("S4 %s end (boss %.1f studs along its walk): a fight starts next to the walking boss"):format(name, along), f ~= nil and math.abs(math.abs(along) - P.halfLen) < 0.6, f == nil and why or nil) then
				task.wait(0.15)
				local spot, bpos = f.spot, f.bossPos
				local dEnd = spot and bpos and Vector3.new(spot.X - bpos.X, 0, spot.Z - bpos.Z).Magnitude
				local root = ctx.hrp.Position
				local dRoot = spot and Vector3.new(root.X - spot.X, 0, root.Z - spot.Z).Magnitude
				local dBoss = bpos and Vector3.new(root.X - bpos.X, 0, root.Z - bpos.Z).Magnitude
				L.check(ctx, ("S4 %s end: the fighter stands as far from the walking boss as at rest (%.2f, +/- 0.3)"):format(name, dRest or -1),
					dEnd ~= nil and dRest ~= nil and math.abs(dEnd - dRest) <= 0.3, ("spot %.2f from bossPos"):format(dEnd or -1))
				L.check(ctx, ("S4 %s end: the character was moved to that spot, within the ring around the boss (< RingRadius %d)"):format(name, pad.radius),
					dRoot ~= nil and dRoot <= 0.5 and dBoss ~= nil and dBoss < pad.radius, ("root %.2f from the spot, %.2f from the boss"):format(dRoot or -1, dBoss or -1))
				Fight.finish(p, f, "run")
			end
			workspace:SetAttribute("HFB_ClockOffset", nil)
			task.wait(0.9)
		end
	end
	clearCarry()
	Config.Fight.PAD_COOLDOWN_S = keepCool
end

local ok, err = xpcall(function()
	if ARGS.phase == "b" then phaseB() elseif ARGS.phase == "c" then phaseC() elseif ARGS.phase == "d" then phaseD() else phaseA() end
end, debug.traceback)
if not ok then L.check(ctx, "the check ran without a script error", false, tostring(err):sub(1, 500)) end
L.finish(ctx)
