if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-10: bag training, Punch Strength and Punch Speed, the six bag tiers, Auto Punch and Perfect Auto Punch, Power
-- (gate rows S2, S3; brief systems 2, 3; m2-contract.md C "Bag" and "Punch.Report with auto"). PLAY MODE, one call
-- per phase, installed into ServerStorage.TmpChecks next to CheckLib:
--   { phase = "a" }  costs (30 / 10 levels, the brief's tables and totals), buying through the handlers (cash, cap,
--                    place, one level per call, cash taken by the server), the bag tier attribute, Bag.State costs
--                    (nil at the cap), Punch.Schedule resent on a Speed buy, the funnel marks, Power untouched (S3).
--   { phase = "b" }  Auto Punch: toggles need the pass (PassOwned hook), auto Good = 1+1+2, Perfect only with Perfect
--                    Auto Punch (also alone, the web buyer), untimed/miss auto refused, off the pad refused, one burst
--                    per ring (B20: a second auto or a hand tap during the auto burst refused 'busy'), the rebirth and
--                    2x Power multipliers through Bag.value.
--   { phase = "c" }  Power a second for M2-26: auto Good and auto Perfect at Speed 1 and Speed 10, 6 cycles each.
-- Forged reports go through Punch.report with the real client's reports held off (L.muteClient), as Punch2.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Punch, Bag, Session = L.Config, L.Punch, L.Bag, L.Session
local SSS = game:GetService("ServerScriptService")
local AutoPunch = require(SSS.Systems.AutoPunch)
local Funnel = require(SSS.Systems.Funnel)
local s = L.s

local ctx = L.begin("Bag", ARGS)
local p = ctx.p
local plot = workspace.Plots.Plot1
L.rootY(ctx)
local SV = Config.Bag.STRENGTH_VALUE

local function near(a, b) return math.abs(a - b) < 1e-6 * math.max(1, math.abs(b)) end
local function same(a, b)
	if type(a) ~= "table" or #a ~= #b then return false end
	for i = 1, #a do if not near(a[i], b[i]) then return false end end
	return true
end
local function setv(name, v) L.hook(ctx, name, v); task.wait(0.15) end
local function res() return Bag.stats.lastResult[p.UserId] end
local function st() return Bag.stats.lastState[p.UserId] end
local function onPad() L.tp(ctx, L.onPart(ctx, plot.BagPad)); task.wait(0.2) end
local function waitSince(t, sec) local left = sec - (os.clock() - t); if left > 0 then task.wait(left) end end

-- ------------------------------------------------------------------ phase a: costs and buying
local function phaseA()
	local B = Config.Bag
	local sum = 0
	for _, c in ipairs(B.STRENGTH_COST) do sum += c end
	local sum2 = 0
	for _, c in ipairs(B.SPEED_COST) do sum2 += c end
	L.check(ctx, "S2 Strength: 30 levels, value 1.35^(L-1) (L30 = 6,000 to two figures)", B.STRENGTH_MAX == 30 and #B.STRENGTH_COST == 30 and near(SV(2), 1.35) and math.abs(SV(30) - 6000) / 6000 < 0.05, s(SV(30)))
	L.check(ctx, "S2 Strength costs as the brief's table: L2 150, L5 1,800, L6 3,200, L15 640,000, L30 4.3B; total 9.67B", B.STRENGTH_COST[2] == 150 and B.STRENGTH_COST[5] == 1800 and B.STRENGTH_COST[6] == 3200 and B.STRENGTH_COST[15] == 640000 and B.STRENGTH_COST[30] == 4.3e9 and math.abs(sum - 9.67e9) < 0.005e9, s(sum))
	local formulaOk = true
	for lv = 6, 30 do
		local f = 1800 * 1.8 ^ (lv - 5)
		local mag = 10 ^ (math.floor(math.log10(f)) - 1)
		if math.floor(f / mag + 0.5) * mag ~= B.STRENGTH_COST[lv] then formulaOk = false end
	end
	L.check(ctx, "S2 Strength costs from L6 = 1,800 x 1.8^(L-5) rounded to two figures", formulaOk)
	L.check(ctx, "S2 Speed: 10 levels, costs 100 400 1,600 6,500 26,000 100,000 400,000 1.6M 6.5M (total 8.63M)", B.SPEED_MAX == 10 and same(B.SPEED_COST, { 0, 100, 400, 1600, 6500, 26000, 100000, 400000, 1.6e6, 6.5e6 }) and sum2 == 8634600, s(sum2))
	local tiers = {}
	for lv = 1, 30 do tiers[lv] = B.TIER(lv) end
	L.check(ctx, "S2 six bag tiers: 1-5 -> 1, 6-10 -> 2, 11-15 -> 3, 16-20 -> 4, 21-25 -> 5, 26-30 -> 6", tiers[1] == 1 and tiers[5] == 1 and tiers[6] == 2 and tiers[10] == 2 and tiers[11] == 3 and tiers[16] == 4 and tiers[21] == 5 and tiers[25] == 5 and tiers[26] == 6 and tiers[30] == 6)

	setv("Wipe", true)
	task.wait(0.2)
	onPad()
	local power0 = L.power(ctx)
	-- no cash
	setv("SetCash", 0)
	Bag.buyStrength(p, {})
	local r = res()
	L.check(ctx, "S2 BuyStrength with $0 refused 'cash', level stays 1", r and r.action == "buyStrength" and not r.ok and r.reason == "cash" and L.prof(ctx).strengthLevel == 1, r and r.reason)
	-- exactly the cost
	setv("SetCash", 150)
	Bag.buyStrength(p, {})
	r = res()
	local pr = L.prof(ctx)
	L.check(ctx, "S2 BuyStrength with $150: ok, level 2, cash 0 (the server took 150)", r and r.ok and r.level == 2 and pr.strengthLevel == 2 and pr.cash == 0, r and (tostring(r.reason) .. " lv " .. tostring(pr.strengthLevel) .. " cash " .. s(pr.cash)))
	L.check(ctx, "S2 Bag.State after the buy: strength 2, nextStrengthCost 400, tier 1, nextSpeedCost 100", st() and st().strengthLevel == 2 and st().nextStrengthCost == 400 and st().tier == 1 and st().nextSpeedCost == 100)
	local function hasMark(name)
		for _, e in ipairs(L.TestHooks.reports.funnel or {}) do if e.name == name and e.userId == p.UserId then return true end end
		return false
	end
	L.check(ctx, "funnel FirstStrengthBought marked on the first accepted BuyStrength", hasMark("FirstStrengthBought"))
	-- one call = one level, whatever the cash
	setv("SetCash", 1e6)
	Bag.buyStrength(p, {})
	pr = L.prof(ctx)
	L.check(ctx, "S2 one BuyStrength = one level (cash 1,000,000 -> level 3, cash 999,600)", pr.strengthLevel == 3 and pr.cash == 1e6 - 400, s(pr.cash))
	-- range
	L.tp(ctx, L.onPart(ctx, plot.BagPad, 16, 0))
	task.wait(0.15)
	local before = pr.cash
	Bag.buyStrength(p, {})
	r = res()
	L.check(ctx, "S2 BuyStrength 16 studs from the bag pad (range 14) refused 'place', nothing taken", r and not r.ok and r.reason == "place" and L.prof(ctx).cash == before and L.prof(ctx).strengthLevel == 3, r and r.reason)
	L.tp(ctx, L.onPart(ctx, plot.BagPad, 12, 0))
	task.wait(0.15)
	Bag.buyStrength(p, {})
	r = res()
	L.check(ctx, "S2 BuyStrength 12 studs from the pad (at the bag sign) accepted", r and r.ok and L.prof(ctx).strengthLevel == 4, r and r.reason)
	onPad()
	-- tier change at 6
	setv("SetStrength", 5)
	setv("SetCash", 3200)
	Bag.buyStrength(p, {})
	L.check(ctx, "S2 Strength 5 -> 6 for $3,200: the bag tier becomes 2 (plot BagTier and Bag.State)", L.prof(ctx).strengthLevel == 6 and plot:GetAttribute("BagTier") == 2 and st() and st().tier == 2, tostring(plot:GetAttribute("BagTier")))
	-- all the way to 30 with exactly the total
	setv("SetStrength", 1)
	setv("SetCash", 9669146250)
	local n = 0
	for _ = 1, 35 do
		Bag.buyStrength(p, {})
		if res().ok then n += 1 end
	end
	pr = L.prof(ctx)
	L.check(ctx, "S2 the whole table: $9,669,146,250 buys exactly 29 levels to 30, cash 0, then 'cap'", n == 29 and pr.strengthLevel == 30 and math.abs(pr.cash) < 1e-3 and res().reason == "cap", ("%d levels, cash %s, last %s"):format(n, s(pr.cash), tostring(res().reason)))
	L.check(ctx, "S2 at the cap: Bag.State nextStrengthCost nil, tier 6", st() and st().nextStrengthCost == nil and st().tier == 6 and plot:GetAttribute("BagTier") == 6)
	-- speed
	setv("SetCash", 100)
	local sched0 = Punch.stats.schedules
	Bag.buySpeed(p, {})
	r = res()
	L.check(ctx, "S2 BuySpeed with $100: ok, Speed 2, cash 0", r and r.ok and r.action == "buySpeed" and L.prof(ctx).speedLevel == 2 and L.prof(ctx).cash == 0, r and r.reason)
	task.wait(0.2)
	local sch = Punch.stats.lastSchedule[p.UserId]
	L.check(ctx, "S2 a Speed buy re-sends Punch.Schedule at the new ring (0.98 s)", Punch.stats.schedules > sched0 and sch and sch.speedLevel == 2 and near(sch.ringClose, 0.98), sch and s(sch.ringClose))
	setv("SetCash", 8634600 - 100)
	n = 0
	for _ = 1, 12 do Bag.buySpeed(p, {}); if res().ok then n += 1 end end
	pr = L.prof(ctx)
	L.check(ctx, "S2 Speed 2 -> 10 costs exactly the rest of the table ($8,634,500), then 'cap', nextSpeedCost nil", n == 8 and pr.speedLevel == 10 and math.abs(pr.cash) < 1e-3 and res().reason == "cap" and st().nextSpeedCost == nil, ("%d, cash %s"):format(n, s(pr.cash)))
	L.check(ctx, "S3 Power untouched by every buy and refusal (never spent)", L.power(ctx) == power0, s(L.power(ctx)) .. " vs " .. s(power0))
	-- a dead player cannot buy (state)
	setv("SetCash", 1e6)
	setv("SetStrength", 1)
	-- milestone
	setv("SetPower", 25)
	task.wait(0.2)
	L.check(ctx, "S3 funnel ReachedFirstBossPower at Power >= 25 (the zone 1 fixed pad's boss)", hasMark("ReachedFirstBossPower"))
	-- the remotes carry no price, level or amount (shape: an empty table; extra keys are ignored)
	setv("SetCash", 150)
	Bag.buyStrength(p, { level = 30, cost = 0, amount = 1e9 })
	L.check(ctx, "S2 a forged { level = 30, cost = 0 } payload buys one level at the server's price", L.prof(ctx).strengthLevel == 2 and L.prof(ctx).cash == 0)
end

-- ------------------------------------------------------------------ phase b: Auto Punch
local function phaseB()
	setv("Wipe", true)
	workspace:SetAttribute("HFB_PassOwned", nil)
	task.wait(0.2)
	-- what Roblox says for this Studio account (the cache filled on join); the hook overrides it below
	L.note(ctx, ("ROBLOX ownership for %d: auto=%s perfect=%s 2xPower=%s"):format(p.UserId, tostring(Bag.owns(p, "pass_auto_punch")), tostring(Bag.owns(p, "pass_perfect_auto_punch")), tostring(Bag.owns(p, "pass_2x_power"))))
	setv("PassOwned", "pass_auto_punch=off,pass_perfect_auto_punch=off,pass_2x_power=off")
	onPad()
	L.muteClient(ctx, true)
	task.wait(1.6)
	-- without the pass
	AutoPunch.autoToggle(p, { on = true })
	local r = res()
	L.check(ctx, "S2 AutoToggle on without Auto Punch refused 'pass'", r and r.action == "auto" and not r.ok and r.reason == "pass" and Bag.toggles(p).auto == false, r and r.reason)
	local a1 = L.forge(ctx, "bag", "good", { auto = true })
	L.check(ctx, "S2 an auto Good with no pass and no toggle refused 'pass'", a1 and not a1.accepted and a1.reason == "pass", a1 and a1.reason)
	AutoPunch.autoToggle(p, { on = "yes" })
	L.check(ctx, "S2 AutoToggle { on = 'yes' } dropped (not a boolean)", Bag.toggles(p).auto == false)
	-- Auto Punch owned
	setv("PassOwned", "pass_auto_punch=on,pass_perfect_auto_punch=off,pass_2x_power=off")
	L.check(ctx, "S2 Bag.State autoOwned true, perfectOwned false with the PassOwned hook", st() and st().autoOwned == true and st().perfectOwned == false)
	local a0 = L.forge(ctx, "bag", "good", { auto = true })
	L.check(ctx, "S2 owned but the toggle off: auto Good refused 'pass'", a0 and not a0.accepted and a0.reason == "pass", a0 and a0.reason)
	AutoPunch.autoToggle(p, { on = true })
	L.check(ctx, "S2 AutoToggle on with Auto Punch: ok, Bag.State autoOn", res().ok and Bag.toggles(p).auto and st().autoOn == true)
	local p0 = L.power(ctx)
	local a2 = L.forge(ctx, "bag", "good", { auto = true })
	local t2 = os.clock()
	L.check(ctx, "S2 auto Good accepted, gains 1/1/2, Punch.Result auto = true", a2 and a2.accepted and same(a2.gains, { 1, 1, 2 }) and a2.auto == true, a2 and tostring(a2.reason))
	-- B20: one burst per ring
	task.wait(0.15)
	local a3 = L.forge(ctx, "bag", "good", { auto = true })
	local h3 = L.forge(ctx, "bag", "perfect")
	L.check(ctx, "B20 a second auto tap and a hand Perfect during the auto burst both refused 'busy'", a3 and a3.reason == "busy" and h3 and h3.reason == "busy", tostring(a3 and a3.reason) .. "/" .. tostring(h3 and h3.reason))
	task.wait(0.7)
	L.check(ctx, "S2 the auto burst applied 4 Power (Strength 1)", near(L.power(ctx) - p0, 4), s(L.power(ctx) - p0))
	local a4 = L.forge(ctx, "bag", "perfect", { auto = true })
	L.check(ctx, "S2 an auto Perfect with only Auto Punch refused 'pass'", a4 and not a4.accepted and a4.reason == "pass", a4 and a4.reason)
	local u = L.forge(ctx, "bag", "untimed", { auto = true })
	local m = L.forge(ctx, "bag", "miss", { auto = true })
	L.check(ctx, "S2 auto untimed and auto miss refused 'grade'", u and u.reason == "grade" and m and m.reason == "grade")
	AutoPunch.perfectToggle(p, { on = true })
	L.check(ctx, "S2 PerfectToggle on without Perfect Auto Punch refused 'pass'", not res().ok and res().reason == "pass" and Bag.toggles(p).perfect == false)
	-- the next ring: an auto tap one cycle later is accepted (rate as a hand burst)
	waitSince(t2, Config.Punch.CYCLE(1))
	local a5 = L.forge(ctx, "bag", "good", { auto = true })
	L.check(ctx, "S2 auto Good one cycle (1.66 s) later accepted", a5 and a5.accepted, a5 and a5.reason)
	local t5 = os.clock()
	-- off the pad
	waitSince(t5, Config.Punch.CYCLE(1))
	L.tp(ctx, L.onPart(ctx, plot.BagPad, 9, 0))
	task.wait(0.15)
	local a6 = L.forge(ctx, "bag", "good", { auto = true })
	L.check(ctx, "S2 auto Good off the bag pad refused 'place' (only on the owner's pad)", a6 and a6.reason == "place", a6 and a6.reason)
	local a7 = L.forge(ctx, "fight", "good", { auto = true })
	L.check(ctx, "S2 auto with context 'fight' and no fight refused 'place' (never in fights; the running-fight case is in Zones c)", a7 and a7.reason == "place", a7 and a7.reason)
	onPad()
	-- Perfect Auto Punch alone (the web-page buyer)
	AutoPunch.autoToggle(p, { on = false })
	setv("PassOwned", "pass_auto_punch=off,pass_perfect_auto_punch=on,pass_2x_power=off")
	L.check(ctx, "S2 Perfect Auto Punch alone: Bag.State autoOwned and perfectOwned true", st() and st().autoOwned == true and st().perfectOwned == true)
	AutoPunch.perfectToggle(p, { on = true })
	L.check(ctx, "S2 PerfectToggle on with Perfect Auto Punch alone: ok", res().ok and Bag.toggles(p).perfect == true and st().perfectOn == true)
	local p1 = L.power(ctx)
	local a8 = L.forge(ctx, "bag", "perfect", { auto = true })
	local t8 = os.clock()
	L.check(ctx, "S2 auto Perfect accepted with Perfect Auto Punch alone, gains 2/2/4", a8 and a8.accepted and same(a8.gains, { 2, 2, 4 }), a8 and a8.reason)
	task.wait(0.7)
	L.check(ctx, "S2 the auto Perfect burst applied 8", near(L.power(ctx) - p1, 8), s(L.power(ctx) - p1))
	waitSince(t8, Config.Punch.CYCLE(1))
	local a9 = L.forge(ctx, "bag", "good", { auto = true })
	L.check(ctx, "S2 Perfect Auto Punch includes Auto Punch: an auto Good is also allowed", a9 and a9.accepted, a9 and a9.reason)
	local t9 = os.clock()
	AutoPunch.perfectToggle(p, { on = false })
	waitSince(t9, Config.Punch.CYCLE(1))
	local a10 = L.forge(ctx, "bag", "perfect", { auto = true })
	L.check(ctx, "S2 toggle off: auto refused 'pass' again (turning off needs no pass)", res().ok and a10 and a10.reason == "pass", a10 and a10.reason)
	-- multipliers through Bag.value (rebirth x(1 + n), 2x Power x2)
	setv("PassOwned", "pass_auto_punch=off,pass_perfect_auto_punch=off,pass_2x_power=on")
	Session.set(p, "rebirths", 2)
	ctx.expect = "rebirths"
	local v = Bag.value(p, "untimed", 1)
	local g = Bag.gains(p, "good")
	L.check(ctx, "S2 Bag.value with 2 rebirths and 2x Power: untimed 1 x 3 x 2 = 6; Good 6/6/12", near(v, 6) and same(g, { 6, 6, 12 }), s(v))
	waitSince(t9, Config.Punch.CYCLE(1) + 0.2)
	local p2 = L.power(ctx)
	local h = L.forge(ctx, "bag", "untimed")
	L.check(ctx, "S2 a hand untimed tap with the multipliers adds 6 (the untimed path rides on Bag.value too)", h and h.accepted and near(L.power(ctx) - p2, 6), s(L.power(ctx) - p2))
	Session.set(p, "rebirths", 0)
	ctx.expect = nil
	workspace:SetAttribute("HFB_PassOwned", nil)
	L.muteClient(ctx, false)
end

-- ------------------------------------------------------------------ phase c: Power a second (M2-26)
local function runAuto(speed, grade, cycles)
	setv("SetSpeed", speed)
	setv("SetStrength", 1)
	task.wait(0.3)
	local cyc = Config.Punch.CYCLE(speed)
	local refused = 0
	local t0 = os.clock()
	local pw0 = L.power(ctx)
	for k = 0, cycles - 1 do
		waitSince(t0, k * cyc)
		local r = L.forge(ctx, "bag", grade, { auto = true })
		if not (r and r.accepted) then refused += 1 end
	end
	waitSince(t0, cycles * cyc)
	local gained = L.power(ctx) - pw0
	local elapsed = os.clock() - t0
	return gained / elapsed, refused, gained, elapsed
end

local function phaseC()
	setv("Wipe", true)
	task.wait(0.2)
	onPad()
	setv("PassOwned", "pass_auto_punch=on,pass_perfect_auto_punch=on,pass_2x_power=off")
	AutoPunch.autoToggle(p, { on = true })
	AutoPunch.perfectToggle(p, { on = true })
	L.muteClient(ctx, true)
	task.wait(1.6)
	local want = { [1] = { good = 2.41, perfect = 4.82 }, [10] = { good = 3.92, perfect = 7.84 } }
	for _, speed in ipairs({ 1, 10 }) do
		for _, grade in ipairs({ "good", "perfect" }) do
			local rate, refused, gained, el = runAuto(speed, grade, 6)
			local w = want[speed][grade]
			L.check(ctx, ("S26 auto %s at Speed %d: %.2f Power a second (paper %.2f, within 5%%), 0 refused"):format(grade, speed, rate, w), math.abs(rate - w) / w < 0.05 and refused == 0, ("+%s in %.2f s, %d refused"):format(s(gained), el, refused))
			L.note(ctx, ("POWER_PER_SECOND speed=%d grade=%s auto rate=%.3f gained=%s seconds=%.3f"):format(speed, grade, rate, s(gained), el))
			task.wait(Config.Punch.CYCLE(speed))
		end
	end
	AutoPunch.autoToggle(p, { on = false })
	AutoPunch.perfectToggle(p, { on = false })
	workspace:SetAttribute("HFB_PassOwned", nil)
	L.muteClient(ctx, false)
end

local ok, err = pcall(function()
	if ctx.phase == "a" then phaseA()
	elseif ctx.phase == "b" then phaseB()
	elseif ctx.phase == "c" then phaseC()
	else L.check(ctx, "known phase", false, ctx.phase) end
end)
if not ok then L.check(ctx, "phase ran without a Lua error", false, tostring(err)) end
L.finish(ctx)
