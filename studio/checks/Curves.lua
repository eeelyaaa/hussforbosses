if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-26 (game-designer): the curves against the brief's tables and requirements/m2-punch-numbers.md (sections 4 to 6).
-- Gate row S26. PLAY MODE, installed into ServerStorage.TmpChecks next to CheckLib (CheckAll "install", then this file
-- added from the sync). Every pass forced off (L.begin) and the Shop prompt stubbed (L.begin). Measures; it never tunes.
--   (each play call must stay under about 90 s: pass one or two modes per call)
--   { phase = "a", speed = 1|10, secs = 30, modes = "good,perfect" }  Power a second on the bag at Strength 1: the REAL client taps (AutoTap)
--        good, perfect, mix (45/45/10, the client's mix misses instead of clicking), untimed (one click per ring),
--        mash (a click every 0.1 s). Warm-up 4 s per player; Punch refusals counted per player.
--   { phase = "b", modes = "good,perfect,untimed", rs = "0.5,1,1.5,2,3,5", runs = 1 }  fights against Chomp Frog
--        (Power 25) with Power set for each r: the real client taps; seconds started -> end, bursts, singles, hearts.
--        mode "mix" uses AutoMix 45,45,10 (win rates per band).
--   { phase = "c", seed = 0, policy = "half"|"greedy", mix = 5.5 }  the 30-minute economy run with Power gating, on
--        ClockOffset time: bag Power at `mix` per ring x Strength value / cycle (the measured rate from phase a),
--        fights only at r <= 1 (green), trip times from the base layout (walk 16, carry 12; 200 studs to zone 1's
--        fixed pad, +120 a zone, +20 a pad), fight seconds from section 5; real server calls for place, swap,
--        collect, upgrade, Strength and Speed. NOTE lines at minutes 3, 10, 30 and at each milestone.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local SSS = game:GetService("ServerScriptService")
local Config, Session, Carry, Base, Income, Bag, Fight, Punch = L.Config, L.Session, L.Carry, L.Base, L.Income, L.Bag, L.Fight, L.Punch
local Upgrades = require(SSS.Systems.Upgrades)
local s = L.s

local ctx = L.begin("Curves", ARGS)
local p = ctx.p
L.rootY(ctx)
local function prof() return Session.get(p) end
local function C(label, ok, detail) return L.check(ctx, label, ok, detail) end
local function N(str) L.note(ctx, str) end
local plot = Session.plot(p)
local function clearCarry() if Carry.get(p) then Carry.lose(p, "check") end; task.wait(0.05) end
local function refusedCopy() return table.clone(Punch.stats.refused) end
local function refusedSince(r0)
	local out, n = {}, 0
	for k, v in pairs(Punch.stats.refused) do
		local d = v - (r0[k] or 0)
		if d > 0 then table.insert(out, k .. "=" .. d); n += d end
	end
	return n, table.concat(out, ",")
end

L.waitFor(function() return Session.get(p) ~= nil and Session.state(p) == "live" end, 20)
task.wait(1)
L.hook(ctx, "Wipe", true)
L.waitFor(function() return prof() and prof().power == 0 and workspace:GetAttribute("HFB_Wipe") == nil end, 3)
task.wait(0.5)
L.passesOff(ctx)

local ok, err = xpcall(function()
	if ctx.phase == "a" then
		local speed = tonumber(ARGS.speed) or 1
		local secs = tonumber(ARGS.secs) or 30
		L.hook(ctx, "SetSpeed", speed)
		task.wait(0.5)
		C("setup: Speed level " .. speed .. ", Strength 1", prof().speedLevel == speed and prof().strengthLevel == 1, prof().speedLevel)
		L.tp(ctx, L.onPart(ctx, plot.BagPad))
		task.wait(3.5) -- the client's clock offset settles (M1)
		local paper = { -- m2-punch-numbers.md section 4
			[1] = { untimed = 0.60, good = 2.41, mix = 3.25, perfect = 4.82, mash = 0.60 },
			[10] = { untimed = 0.98, good = 3.92, mix = 5.31, perfect = 7.84, mash = 0.98 },
		}
		for _, mode in ipairs(string.split(ARGS.modes or "good,perfect,mix,untimed,mash", ",")) do
			if mode == "mix" then L.hook(ctx, "AutoMix", "45,45,10") end
			L.hook(ctx, "AutoTap", mode)
			task.wait(4)
			local p0, r0, a0, t0 = prof().power, refusedCopy(), Punch.stats.accepted, os.clock()
			task.wait(secs)
			local p1, t1 = prof().power, os.clock()
			local nRef, refs = refusedSince(r0)
			local rate = (p1 - p0) / (t1 - t0)
			local want = (paper[speed] or {})[mode]
			-- M2-28 (TEAM CALL): the paper figure assumes the tap at the landing (the Perfect cadence). AutoTap "good" taps GOOD_TAP_OFFSET
			-- (0.070 s, Controllers/TestClient OFFSET.good) after it, so each cycle is that much longer: expect paper x CYCLE / (CYCLE + offset),
			-- computed, not a constant (Speed 10: 3.92 -> about 3.67, measured 3.665 by M2-07).
			if want and mode == "good" then
				local cyc = Config.Punch.CYCLE(speed)
				want = want * cyc / (cyc + 0.070)
			end
			N(("POWERS speed=%d mode=%s rate=%.3f/s paper=%s accepted=%d refused=%d %s over %.1f s"):format(speed, mode, rate, tostring(want), Punch.stats.accepted - a0, nRef, refs, t1 - t0))
			if want and mode ~= "mash" and mode ~= "mix" then
				C(("Power a second, Speed %d, %s within 5%% of paper %.2f"):format(speed, mode, want), math.abs(rate - want) / want <= 0.05, ("%.3f"):format(rate))
			end
			if mode ~= "mash" then
				C(("no refusal for the legit %s player at Speed %d"):format(mode, speed), nRef == 0, refs)
			end
			L.hook(ctx, "AutoTap", nil)
			task.wait(1.5)
		end
		workspace:SetAttribute("HFB_AutoMix", nil)

	elseif ctx.phase == "b" then
		local keep = { pad = Config.Fight.PAD_COOLDOWN_S, knock = Config.Fight.KNOCKDOWN_S }
		Config.Fight.PAD_COOLDOWN_S = 0
		Config.Fight.KNOCKDOWN_S = 0.1
		L.hook(ctx, "PadFastBack", 0)
		L.hook(ctx, "AutoMix", "45,45,10")
		local modes = string.split(ARGS.modes or "good,perfect,untimed", ",")
		local rs = string.split(ARGS.rs or "0.5,1,1.5,2,3,5", ",")
		local runs = tonumber(ARGS.runs) or 1
		local ends = {}
		local conn = Fight.onEnd(function(pl, f, state) if pl == p then ends[f.fightId] = { state = state, hearts = f.hearts, at = workspace:GetServerTimeNow() } end end)
		local function fightOnce(mode, r)
			clearCarry()
			L.hook(ctx, "AutoTap", nil)
			task.wait(0.8)
			Session.set(p, "power", 25 / r)
			L.tp(ctx, L.nearBoss(ctx, "z1_fixed"))
			task.wait(0.2)
			local f = Fight.begin(p, "z1_fixed")
			if not f then return nil, Fight.canStart(p, "z1_fixed") end
			L.hook(ctx, "AutoTap", mode)
			local r0 = refusedCopy()
			L.waitFor(function() return ends[f.fightId] end, 40)
			L.hook(ctx, "AutoTap", nil)
			local e = ends[f.fightId]
			local bursts, singles = {}, 0
			for _, ev in ipairs(Fight.stats.log) do
				if ev.fightId == f.fightId and ev.kind == "beat" then
					if ev.burstSeq then bursts[ev.burstSeq] = true end
				end
			end
			local nb = 0
			for _ in pairs(bursts) do nb += 1 end
			local nRef, refs = refusedSince(r0)
			return { band = f.band, state = e and e.state or "timeout", secs = e and (e.at - f.startedAt) or -1, hearts = e and e.hearts or -1, bursts = nb, refused = nRef, refs = refs }
		end
		for _, mode in ipairs(modes) do
			for _, rr in ipairs(rs) do
				local r = tonumber(rr)
				local wins, n, tot = 0, 0, 0
				for i = 1, runs do
					local res, why = fightOnce(mode, r)
					if res then
						n += 1
						if res.state == "win" then wins += 1; tot += res.secs end
						N(("FIGHT mode=%s r=%s band=%s run=%d state=%s secs=%.2f bursts=%d heartsLeft=%d refused=%d %s"):format(mode, rr, res.band, i, res.state, res.secs, res.bursts, res.hearts, res.refused, res.refs))
					else
						N(("FIGHT mode=%s r=%s run=%d did not start: %s"):format(mode, rr, i, tostring(why)))
					end
				end
				N(("FIGHTSUM mode=%s r=%s wins=%d/%d meanWinSecs=%.2f"):format(mode, rr, wins, n, wins > 0 and tot / wins or -1))
			end
		end
		conn = nil
		clearCarry()
		Config.Fight.PAD_COOLDOWN_S = keep.pad
		Config.Fight.KNOCKDOWN_S = keep.knock

	elseif ctx.phase == "c" then
		local Z = Config.Zones
		local RING, BURST = Config.Punch.RING, Config.Punch.BURST_LEN
		local mix = tonumber(ARGS.mix) or 5.5
		local policy = ARGS.policy or "half"
		local rng = Random.new(tonumber(ARGS.seed) or 0)
		local T = tonumber(ARGS.minutes or 30) * 60
		local simT, P = 0, 0
		local serverStart = workspace:GetServerTimeNow()
		local offset = 0
		local function goTo(t)
			offset = t - (workspace:GetServerTimeNow() - serverStart)
			workspace:SetAttribute("HFB_ClockOffset", offset)
			ctx.hooks.ClockOffset = true
		end
		local function S() return prof().strengthLevel end
		local function V() return prof().speedLevel end
		local function cycle() return RING[V()] + BURST end
		local function incomeNow()
			local sum, m = 0, Income.mult(p)
			for _, b in ipairs(prof().bosses) do sum += Income.rate(prof(), b, m) end
			return sum
		end
		local events, marks = {}, {}
		local function ev(name) if not events[name] then events[name] = simT; N(("MILESTONE %s at %d s (%d:%02d)"):format(name, simT, simT // 60, simT % 60)) end end
		local function mark()
			for _, m in ipairs({ 180, 600, 1800 }) do
				if not marks[m] and simT >= m then
					marks[m] = true
					local lv = {}
					for _, b in ipairs(prof().bosses) do table.insert(lv, b.creatureId .. "@" .. b.level) end
					N(("RUN minute %d (at %d s): income $%s/s, Power %d, Strength %d, Speed %d, %d bosses, cash $%s | %s"):format(m / 60, simT, s(incomeNow()), P, S(), V(), #prof().bosses, s(prof().cash), table.concat(lv, " ")))
				end
			end
		end
		local function setPower() Session.set(p, "power", math.floor(P)) end
		local function bag(dt)
			local whole = math.floor(dt)
			for _ = 1, whole do
				simT += 1
				P += mix / cycle() * Config.Bag.STRENGTH_VALUE(S())
				mark()
			end
			goTo(simT)
			setPower()
		end
		local function away(dt)
			local whole = math.floor(dt + 0.5)
			for _ = 1, whole do simT += 1; mark() end
			goTo(simT)
		end
		local function standAt(part) L.tp(ctx, L.onPart(ctx, part)); task.wait() end
		local function atBase()
			local got = 0
			for _, b in ipairs(table.clone(prof().bosses)) do got += Income.collect(p, b.spot) end
			if got > 0 then ev("FirstCashCollected") end
			local bought = true
			while bought do
				bought = false
				local best, bestPay
				for _, b in ipairs(prof().bosses) do
					local cost = Upgrades.cost(b.creatureId, b.level)
					local gain = (Z.INCOME[b.creatureId] or 0) * 0.25
					if b.level < 20 and cost and cost / gain <= 600 and cost <= prof().cash and (not bestPay or cost / gain < bestPay) then best, bestPay = b, cost / gain end
				end
				local sc = Config.Bag.nextStrengthCost(S())
				local vc = Config.Bag.nextSpeedCost(V())
				local cash = prof().cash
				if sc and cash >= sc and (not best or sc <= Upgrades.cost(best.creatureId, best.level) * 4) then
					standAt(plot.BagPad); local l0 = S(); Bag.buyStrength(p, {}); bought = S() > l0
					if bought then ev("FirstStrengthBought") end
				elseif vc and cash >= vc and (not sc or vc <= sc) then
					standAt(plot.BagPad); local l0 = V(); Bag.buySpeed(p, {}); bought = V() > l0
				elseif best then
					standAt(Base.spotPart(plot, best.spot))
					local l0 = best.level
					bought = Upgrades.tryUpgrade(p, best.uid) == nil
					if bought then ev("FirstBossUpgraded") end
					if not bought then N("upgrade refused at " .. simT .. " lvl " .. l0) end
				end
			end
		end
		local rolls = {}
		local function rollTier(z, k, t)
			local idx = (t + k * 15) // 45
			local key = z .. ":" .. k .. ":" .. idx
			if not rolls[key] then
				local r, acc, tier = rng:NextNumber() * 100, 0, 6
				for ti, o in ipairs(Z.ROLL_ODDS[z]) do acc += o; if r < acc then tier = ti; break end end
				rolls[key] = tier
			end
			return key, rolls[key]
		end
		local beaten = {}
		local function fightSecs(r)
			local taps = math.ceil(10 * r / mix)
			return RING[V()] + (taps - 1) * cycle() + 0.4
		end
		local bagT, tripT, first, trips = 0, 0, true, 0
		local refused0 = { b = table.clone(Base.stats.refused), u = table.clone(Upgrades.stats.refused) }
		while simT < T do
			if policy == "half" and P >= 25 and bagT < tripT then
				standAt(plot.BagPad); bag(5); bagT += 5; atBase()
				continue
			end
			local bosses = prof().bosses
			local low, lowR
			if Base.freeSpot(p, prof()) == nil then
				for _, b in ipairs(bosses) do local r = Income.perSecond(b.creatureId, b.level); if not lowR or r < lowR then low, lowR = b, r end end
			end
			local best
			for z = 1, 6 do
				for k = 0, 3 do
					local key, tier
					if k == 0 then key, tier = "fixed" .. z, 1 else key, tier = rollTier(z, k, simT) end
					local cid = ("z%d_t%d"):format(z, tier)
					local r = P > 0 and Z.POWER[cid] / P or math.huge
					if not beaten[key] and r <= 1 then
						local d = 200 + 120 * (z - 1) + 20 * k
						local trip = d / 16 + fightSecs(r) + d / 12 + 4
						local gain = Z.INCOME[cid] - (lowR or 0)
						if gain > 0 and (not best or gain / trip > best.score) then best = { score = gain / trip, cid = cid, key = key, k = k, d = d, trip = trip, r = r, z = z } end
					end
				end
			end
			if not best then
				standAt(plot.BagPad); bag(5); bagT += 5; atBase()
				continue
			end
			if first then events.FirstFightStarted = simT + best.d / 16; N(("MILESTONE FirstFightStarted at %d s"):format(events.FirstFightStarted)) end
			away(best.trip); tripT += best.trip; trips += 1
			if best.k ~= 0 then beaten[best.key] = true end
			clearCarry()
			Carry.begin(p, best.cid, { level = 1 })
			if low then
				standAt(Base.spotPart(plot, low.spot))
				if Base.trySwap(p, low.spot) ~= nil then N("swap refused at " .. simT) end
			else
				local free = Base.freeSpot(p, prof())
				standAt(Base.spotPart(plot, free))
				if Base.tryPlace(p, free) ~= nil then N("place refused at " .. simT) end
			end
			clearCarry()
			if first then ev("FirstBossPlaced"); first = false end
			ev(("Zone%dBossPlaced"):format(best.z))
			atBase()
		end
		mark()
		N(("RUN end: %d trips, bag %d s, trips %d s, policy %s, mix %.2f, seed %s"):format(trips, bagT, tripT, policy, mix, tostring(ARGS.seed or 0)))
		C("the run reached minute " .. T / 60 .. " with income at 3, 10, 30", marks[180] and marks[600] and (T < 1800 or marks[1800]))
		local bad = {}
		for k, v in pairs(Base.stats.refused) do if v > (refused0.b[k] or 0) then table.insert(bad, "Base." .. k) end end
		for k, v in pairs(Upgrades.stats.refused) do if v > (refused0.u[k] or 0) then table.insert(bad, "Upgrades." .. k) end end
		C("no place, swap or upgrade refused during the run", #bad == 0, table.concat(bad, ","))
	end
end, debug.traceback)
if not ok then C("the check ran to the end", false, tostring(err):sub(1, 500)) end
pcall(function()
	if Carry.get(p) then Carry.lose(p, "check") end
	workspace:SetAttribute("HFB_AutoTap", nil)
	workspace:SetAttribute("HFB_ClockOffset", nil)
	workspace:SetAttribute("HFB_Wipe", true)
	task.wait(0.4)
end)
L.finish(ctx)
