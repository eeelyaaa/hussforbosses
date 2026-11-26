if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-16 (script) / M1-20 (run, look): no fight move delays the ring (build plan M1 exit check 6;
-- team/requirements/m1-core-loop-gate.md). PLAY MODE, one call: require(...TmpChecks.NoDelay)({ phase = "a" })
-- Misses and big husses back to back at Speed 10 (SetSpeed 10, AutoTap = "mix", AutoMix 40,30,30), the real client
-- fighting Chomp Frog at Power 20 (r = 1.25), fight after fight for about 45 s (PadFastBack 0; a win's carry is dropped by the
-- check; a loss waits out its knockdown and cooldown).
-- Asserts: every fight ring after a burst or a miss starts 0.61 s after it (client ring log, +/- 35 ms), and every
-- BossMoves.play that lands on a running overlay cuts it at once (the check probe's BossMoves log: the overlay after
-- the call is the new move). The probe (HFB_CheckProbe = "moves") wraps the client's BossMoves.play.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Fight, Carry, Session = L.Fight, L.Carry, L.Session
local s = L.s

local ctx = L.begin("NoDelay", ARGS)
local p = ctx.p
local ringPart = workspace.Zones.Z1.Pads.Fixed.Ring
local DURATION = tonumber(ARGS.seconds) or 45
local POWER = 20 -- r = 1.25 (hard, M2 100/40 ms: AutoTap's +70 ms tap is Good); a win takes 4 Good bursts
L.rootY(ctx)

local ok, err = xpcall(function()
	L.hook(ctx, "Wipe", true)
	task.wait(0.3)
	L.hook(ctx, "ReportBeats", true)
	L.hook(ctx, "SetSpeed", 10)
	L.hook(ctx, "PadFastBack", 0)
	task.wait(0.3)
	local r0 = #ctx.reports
	workspace:SetAttribute("HFB_CheckProbe", "moves")
	local armed = L.waitFor(function()
		for _, r in ipairs(L.reportsSince(ctx, r0, "probe")) do if r.data.done == "moves" then return true end end
	end, 4)
	L.check(ctx, "the probe wrapped BossMoves.play on the client", armed == true)
	L.hook(ctx, "AutoMix", "40,30,30")
	L.hook(ctx, "AutoTap", "mix")
	local flog0 = #Fight.stats.log
	local t0 = os.clock()
	local wins, losses, lastHearts = 0, 0, 0
	while os.clock() - t0 < DURATION do
		if not Fight.get(p) then
			if Carry.get(p) then Carry.lose(p, "check") end
			local why = Fight.canStart(p, "z1_fixed")
			if why == "ring" or why == nil then
				Session.set(p, "power", POWER)
				L.tp(ctx, L.nearBoss(ctx, "z1_fixed", ringPart)) -- next to where the boss patrols now (M2-28)
			end
		end
		task.wait(0.25)
	end
	workspace:SetAttribute("HFB_AutoTap", nil)
	-- M2-06: a fight still running here would lose by misses during the flush wait and its lastHeart report would
	-- land after the count (seen 2026-11-25, run 2); end it now so the counts cover the same fights.
	if Fight.get(p) then Fight.finish(p, Fight.get(p), "run") end
	task.wait(3.2) -- the last ring and moves reports (M1-20: probe flushes 14 a second, give it time)
	for i = flog0 + 1, #Fight.stats.log do
		local e = Fight.stats.log[i]
		if e.kind == "win" then wins += 1 elseif e.kind == "loss" then losses += 1 end
		if e.kind == "heart" and e.hearts == 0 then lastHearts += 1 end
	end
	L.note(ctx, ("server last-heart events %d for %d losses"):format(lastHearts, losses))
	-- rings
	local gaps, late, n, misses, bursts = {}, {}, 0, 0, 0
	for _, r in ipairs(L.reportsSince(ctx, r0, "ring")) do
		local d = r.data
		if d.ctx == "fight" and (d.cause == "burst" or d.cause == "miss") and d.gap then
			n += 1
			if d.cause == "miss" then misses += 1 else bursts += 1 end
			if math.abs(d.gap - 0.61) > 0.035 then table.insert(late, ("%s %.3f"):format(d.cause, d.gap)) end
			if #gaps < 40 then table.insert(gaps, ("%s:%.3f"):format(d.cause == "miss" and "m" or "b", d.gap)) end
		end
	end
	L.note(ctx, ("fights won %d, lost %d; fight rings after a burst %d, after a miss %d"):format(wins, losses, bursts, misses))
	L.note(ctx, "ring gaps " .. table.concat(gaps, " "))
	L.check(ctx, "enough mixed play: >= 10 rings after bursts and >= 4 after misses", bursts >= 10 and misses >= 4, ("%d/%d"):format(bursts, misses))
	L.check(ctx, "every fight ring starts 0.61 s after the burst or miss before it (+/- 35 ms)", n > 0 and #late == 0, #late > 0 and table.concat(late, ", ") or nil)
	-- moves
	local plays, cuts, badCuts, bigs, attacks, names = 0, 0, {}, 0, 0, {}
	for _, r in ipairs(L.reportsSince(ctx, r0, "probe")) do
		for _, m in ipairs(r.data.moves or {}) do
			plays += 1
			names[m[1]] = (names[m[1]] or 0) + 1
			if m[1] == "hitBig" then bigs += 1 elseif m[1] == "attack" then attacks += 1 end
			if m[2] and m[2] ~= false then
				cuts += 1
				if m[3] ~= m[1] then table.insert(badCuts, ("%s over %s -> %s"):format(m[1], tostring(m[2]), tostring(m[3]))) end
			end
		end
	end
	local nm = {}
	for k, v in pairs(names) do table.insert(nm, k .. "=" .. v) end
	table.sort(nm)
	L.note(ctx, ("BossMoves plays %d (%s); cuts %d"):format(plays, table.concat(nm, " "), cuts))
	L.check(ctx, "every last-heart loss played one lastHeart move (M1-20)", (names.lastHeart or 0) == lastHearts, ("lastHeart plays %d, last-heart events %d"):format(names.lastHeart or 0, lastHearts))
	L.check(ctx, "the boss reacted: hitBig and attack (Miss) moves played", bigs >= 3 and attacks >= 2, ("hitBig %d, attack %d"):format(bigs, attacks))
	L.check(ctx, "reactions still running were cut by the next result (>= 1 cut seen)", cuts >= 1, cuts)
	L.check(ctx, "every cut started the new move at once (overlay after the call = the new move)", #badCuts == 0, #badCuts > 0 and table.concat(badCuts, "; ") or nil)
	if Carry.get(p) then Carry.lose(p, "check") end
	if Fight.get(p) then Fight.finish(p, Fight.get(p), "run") end
end, debug.traceback)
if not ok then L.check(ctx, "the check ran without a script error", false, tostring(err):sub(1, 500)) end
L.finish(ctx)
