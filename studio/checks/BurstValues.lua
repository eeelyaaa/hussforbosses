if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-16: burst values and fight tap counts (team/requirements/m1-core-loop-gate.md; build plan M1 exit check 3).
-- PLAY MODE, one call per phase:
--   { phase = "a" }  the bag through the real client (AutoTap): Good = 4 (1/1/2) and Perfect = 8 (2/2/4) at
--                    0 / 0.213 / 0.401 s, the Miss restart 0.61 s, cycles 1.81 s (Speed 1) and 1.11 s (Speed 10);
--                    then the all-Perfect fight tap counts at r = 0.5, 1, 1.5, 2, 3, 5 and each band's windows.
--   { phase = "b" }  the all-Good fight tap counts at the same r, and B22 on punch 1 and on punch 2.
-- Fight tap counts use forged reports (Punch.report, the handler after Net's limiter) with the real client's reports
-- held off (L.muteClient): the client's grade windows at r >= 2 are narrower than AutoTap's +70 ms Good tap, and
-- the server believes the grade (bounded by time, rate and place), so the count is the server's damage rule.
-- Power is set on the session so r takes each value (Chomp Frog is 25): 50, 25, 16.67, 12.5, 8.34, 5.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Punch, Fight, Zones, Carry, Session = L.Config, L.Punch, L.Fight, L.Zones, L.Carry, L.Session
local s = L.s

local ctx = L.begin("BurstValues", ARGS)
local p = ctx.p
local plot = workspace.Plots.Plot1
local ringPart = workspace.Zones.Z1.Pads.Fixed.Ring
L.rootY(ctx)

local CASES = { -- r, Power, all-Good count ceil(2.5 r), all-Perfect count ceil(1.25 r), band
	{ 0.5, 50, 2, 1, "easy" },
	{ 1, 25, 3, 2, "fair" },
	{ 1.5, 16.67, 4, 2, "hard" },
	{ 2, 12.5, 5, 3, "veryHard" },
	{ 3, 8.34, 8, 4, "brutal" },
	{ 5, 5, 13, 7, "impossible" },
}

local function oneBurst(i0, grade)
	return L.waitFor(function()
		for _, b in ipairs(L.burstsSince(ctx, i0, "bag")) do if #b.beats == 3 and b.beats[1].grade == grade then return b end end
	end, 6)
end

local function bag()
	L.hook(ctx, "Wipe", true)
	task.wait(0.3)
	L.hook(ctx, "ReportBeats", true)
	L.tp(ctx, L.onPart(ctx, plot.BagPad))
	task.wait(0.6)
	for _, g in ipairs({ { "good", { 1, 1, 2 }, 4 }, { "perfect", { 2, 2, 4 }, 8 } }) do
		local i0 = #Punch.stats.log
		L.hook(ctx, "AutoTap", g[1])
		local b = oneBurst(i0, g[1])
		workspace:SetAttribute("HFB_AutoTap", nil)
		if L.check(ctx, g[1] .. ": a burst was applied", b ~= nil) then
			local vals, times, ok = {}, {}, true
			for k, e in ipairs(b.beats) do
				table.insert(vals, s(e.value))
				table.insert(times, ("%.3f(+%.1f)"):format(e.due - e.t0, e.late * 1000))
				if e.value ~= g[2][k] or math.abs((e.due - e.t0) - Config.Punch.BEAT[k]) > 1e-6 or e.late < 0 or e.late > 0.020 then ok = false end
			end
			L.check(ctx, ("%s = %d: values %s at 0 / 0.213 / 0.401 s, each applied within 20 ms"):format(g[1], g[3], table.concat(g[2], "/")), ok, table.concat(vals, "/") .. " " .. table.concat(times, " "))
		end
		task.wait(0.8)
	end
	-- Miss
	local r0 = #ctx.reports
	local i0 = #Punch.stats.log
	L.hook(ctx, "AutoTap", "miss")
	local misses = L.waitFor(function()
		local out = {}
		for _, r in ipairs(L.reportsSince(ctx, r0, "ring")) do if r.data.cause == "miss" then table.insert(out, r.data.gap) end end
		return #out >= 2 and out
	end, 7)
	workspace:SetAttribute("HFB_AutoTap", nil)
	local okM = misses ~= nil
	for _, g in ipairs(misses or {}) do if math.abs(g - 0.61) > 0.035 then okM = false end end
	L.check(ctx, "Miss: no burst, the next ring 0.61 s later (two misses)", okM and #L.burstsSince(ctx, i0, "bag") == 0, misses and table.concat(misses, ",") or "none")
	-- cycles: burst-to-burst on the server (t0 to t0) with AutoTap perfect, at Speed 1 and Speed 10
	for _, sp in ipairs({ { 1, 1.81 }, { 10, 1.11 } }) do
		ctx.expect = "hook"
		L.hook(ctx, "SetSpeed", sp[1])
		task.wait(0.4)
		ctx.expect = nil
		local sch = Punch.stats.lastSchedule[p.UserId]
		L.check(ctx, ("Speed %d: Punch.Schedule cycle %.2f"):format(sp[1], sp[2]), sch and sch.speedLevel == sp[1] and math.abs(sch.cycle - sp[2]) < 1e-9, sch and s(sch.cycle))
		local j0 = #Punch.stats.log
		L.hook(ctx, "AutoTap", "perfect")
		local bs = L.waitFor(function() local x = L.burstsSince(ctx, j0, "bag"); return #x >= 4 and x end, 4 * sp[2] + 3)
		workspace:SetAttribute("HFB_AutoTap", nil)
		if L.check(ctx, ("Speed %d: four bursts in a row"):format(sp[1]), bs ~= nil) then
			local gaps, ok = {}, true
			for k = 3, 4 do -- the first gap includes the ring that was already running when AutoTap was set
				local g = bs[k].beats[1].t0 - bs[k - 1].beats[1].t0
				table.insert(gaps, ("%.3f"):format(g))
				if math.abs(g - sp[2]) > 0.035 then ok = false end
			end
			L.check(ctx, ("Speed %d: one cycle = %.2f s burst to burst (+/- 35 ms)"):format(sp[1], sp[2]), ok, table.concat(gaps, ","))
		end
		task.wait(0.8)
	end
end

-- a fight with every burst of one grade; returns accepted bursts until the win, the Fight.State values, beats
local function fight(power, grade)
	Session.set(p, "power", power)
	if Carry.get(p) then Carry.lose(p, "check") end
	task.wait(0.05)
	local f = Fight.begin(p, "z1_fixed")
	if not f then return nil, Fight.canStart(p, "z1_fixed") end
	local fid = f.fightId
	local info = { ratio = f.ratio, band = f.band, goodMs = f.goodMs, perfectMs = f.perfectMs, health = f.health, bursts = 0, refused = 0, seqs = {} }
	local cyc = Config.Punch.CYCLE(L.prof(ctx).speedLevel) * Config.Punch.RATE_TOLERANCE + 0.04
	local last = -math.huge
	local t0 = os.clock()
	while Fight.get(p) == f and os.clock() - t0 < 20 do
		-- the next report goes out once the server's own rate gap (from its lastReport) and the running burst are over
		local st = Punch.state(p)
		local nowS = workspace:GetServerTimeNow()
		local byRate = st and st.lastReport and (st.lastReport + cyc - nowS) or 0
		local byBurst = st and st.burst and (st.burst.endsAt - nowS + 0.02) or 0
		local wait = math.max(0, last + cyc - os.clock(), byRate, byBurst)
		if wait > 0 then task.wait(wait) end
		if Fight.get(p) ~= f then break end
		local r, sq = L.forge(ctx, "fight", grade)
		last = os.clock()
		if r and r.accepted then info.bursts += 1; table.insert(info.seqs, sq) else info.refused += 1 end
		task.wait(0.45) -- beats 1..3 land within 0.401 s
	end
	info.won = false
	for _, e in ipairs(Fight.stats.log) do if e.fightId == fid and e.kind == "win" then info.won = true end end
	info.beats = {}
	for _, e in ipairs(Fight.stats.log) do if e.fightId == fid and e.kind == "beat" then table.insert(info.beats, e) end end
	info.hearts = f.hearts
	if Carry.get(p) then Carry.lose(p, "check") end
	return info
end

local function fights(grade, idx)
	L.hook(ctx, "Wipe", true)
	task.wait(0.3)
	L.hook(ctx, "PadFastBack", 0)
	Session.set(p, "speedLevel", 10)
	L.tp(ctx, L.onPart(ctx, ringPart, 1, 1))
	L.muteClient(ctx, true)
	task.wait(1)
	for _, c in ipairs(CASES) do
		local info, why = fight(c[2], grade)
		if L.check(ctx, ("r=%s (Power %s): the fight starts"):format(s(c[1]), s(c[2])), info ~= nil, why) then
			local band = Config.Fight.band(info.ratio)
			L.check(ctx, ("r=%s: band %s, windows %d/%d ms"):format(s(c[1]), c[5], band.goodMs, band.perfectMs),
				info.band == c[5] and info.goodMs == band.goodMs and info.perfectMs == band.perfectMs, ("r=%.4f %s %s/%s"):format(info.ratio, info.band, s(info.goodMs), s(info.perfectMs)))
			L.check(ctx, ("r=%s: all-%s wins in %d bursts"):format(s(c[1]), grade, c[idx]), info.won and info.bursts == c[idx] and info.hearts == 3,
				("won %s, bursts %d, refused %d, hearts %s"):format(tostring(info.won), info.bursts, info.refused, s(info.hearts)))
		end
		task.wait(0.1)
	end
	return true
end

local function b22()
	for _, case in ipairs({ { 250, 1 }, { 125, 2 } }) do
		local info = fight(case[1], "good")
		if L.check(ctx, ("B22 punch %d (Power %d): the fight starts"):format(case[2], case[1]), info ~= nil) then
			local list = {}
			for _, e in ipairs(info.beats) do table.insert(list, ("%d:%s%s"):format(e.n, s(e.health), e.won and "W" or "")) end
			local lastBeat = info.beats[#info.beats]
			local sq = info.seqs[#info.seqs]
			local after = {}
			for _, e in ipairs(L.beatsOf(ctx, sq)) do if e.n > case[2] then table.insert(after, tostring(e.contact) .. "/" .. s(e.value)) end end
			L.check(ctx, ("B22: one burst, the bar empties on punch %d, %d Fight.Beat sent"):format(case[2], case[2]), info.won and info.bursts == 1 and #info.beats == case[2] and lastBeat.won and lastBeat.n == case[2], table.concat(list, " "))
			L.check(ctx, ("B22: punches after %d made no contact and dealt nothing"):format(case[2]), #after == 3 - case[2] and not table.concat(after, ","):find("true"), table.concat(after, ","))
		end
	end
end

local ok, err = xpcall(function()
	if ARGS.phase == "b" then
		fights("good", 3)
		b22()
	else
		bag()
		fights("perfect", 4)
	end
end, debug.traceback)
if not ok then L.check(ctx, "the check ran without a script error", false, tostring(err):sub(1, 500)) end
L.finish(ctx)
