if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-11: gate row S9 (brief system 9): boss upgrades to level 20. PLAY MODE, installed into ServerStorage.TmpChecks:
--   { phase = "a" }  the curve against the brief's table (income multiplier and the cost of the next level at levels 1, 2,
--                    3, 5, 10, 15, 19, 20; the sum 1..20 = 14,519 x base); the Chomp Frog example $30, $39, $51; upgrades
--                    in play from level 1 to 20 (cash spent exactly, the pad settled at the old level first, Boss.Result
--                    level and nextCost, Base.State level); refusals (cash, cap, range, notYours, malformed, carried) with
--                    nothing changed; the bought-cash rule holds after spending; the level travels with a pick up and a
--                    move; funnel FirstBossUpgraded.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Carry, Base, Income, Session, Zones = L.Config, L.Carry, L.Base, L.Income, L.Session, L.Zones
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Upgrades = require(SSS.Systems.Upgrades)
local Ids = require(RS.Shared.Ids)
local s = L.s

local ctx = L.begin("Upgrades", ARGS)
local p = ctx.p
L.rootY(ctx)
local function near(a, b, tol) return math.abs(a - b) <= (tol or 1e-6) end
local function prof() return Session.get(p) end
local plot = Session.plot(p)
local function spot(i) return Base.spotPart(plot, i) end
local function standAt(part) L.tp(ctx, L.onPart(ctx, part)); task.wait(0.05) end
local function at(i) return (Base.bossAt(prof(), i)) end
local function clearCarry() if Carry.get(p) then Carry.lose(p, "check") end; task.wait(0.05) end
local function setCash(n) L.hook(ctx, "SetCash", n); task.wait(0.2) end
local offset = 0
local function addTime(sec) offset += sec; L.hook(ctx, "ClockOffset", offset); task.wait(0.05) end

local parts = {}
for _, k in ipairs(Ids.SHOP_KEYS) do if Ids.isPass(k) then table.insert(parts, k .. "=off") end end
L.hook(ctx, "PassOwned", table.concat(parts, ","))
L.hook(ctx, "Wipe", true)
task.wait(0.5)

-- the curve on paper
local rows = { { 1, 1.00, 30 }, { 2, 1.25, 39 }, { 3, 1.50, 50.7 }, { 5, 2.00, 85.7 }, { 10, 3.25, 318 }, { 15, 4.50, 1181 }, { 19, 5.50, 3374 } }
local bad = {}
for _, r in ipairs(rows) do
	local m = Config.Income.LEVEL_MULT(r[1])
	local c = Config.Upgrades.COST(1, r[1])
	if not near(m, r[2], 1e-9) or math.abs(c - r[3]) > 0.5 + 1e-9 then table.insert(bad, ("L%d x%s cost %s"):format(r[1], s(m), s(c))) end
end
L.check(ctx, "the brief's table: income x1.00 .. x5.50 and the next-level cost 30 .. 3,374 (x base, rounded to whole cash)", #bad == 0, table.concat(bad, "; "))
L.check(ctx, "level 20: x5.75 and no next cost (cap)", near(Config.Income.LEVEL_MULT(20), 5.75) and Config.Upgrades.COST(1, 20) == nil)
local exact = 0
for lv = 1, 19 do exact += 30 * 1.3 ^ (lv - 1) end
local rounded = 0
for lv = 1, 19 do rounded += Config.Upgrades.COST(1, lv) end
L.check(ctx, "total 1 -> 20 = 14,519 x base (exact sum; whole-cash costs add to within $10)", math.floor(exact + 0.5) == 14519 and math.abs(rounded - 14519) <= 10, ("exact %s, rounded %s"):format(s(exact), s(rounded)))
L.check(ctx, "Chomp Frog (base $1): $30, then $39, then $51", Upgrades.cost("z1_t1", 1) == 30 and Upgrades.cost("z1_t1", 2) == 39 and Upgrades.cost("z1_t1", 3) == 51)
L.check(ctx, "a $60 base boss (z3_t1): $1,800 for level 2", Upgrades.cost("z3_t1", 1) == 1800)

-- in play
clearCarry()
Carry.begin(p, "z1_t1")
standAt(spot(1))
Base.tryPlace(p, 1)
local uid = at(1).uid
local before = s(prof().cash) .. "/" .. at(1).level
L.check(ctx, "no cash: refused 'cash', nothing changed", Upgrades.tryUpgrade(p, uid) == "cash" and s(prof().cash) .. "/" .. at(1).level == before)
addTime(100)
setCash(30)
local r1 = Upgrades.tryUpgrade(p, uid)
local b1 = at(1)
L.check(ctx, "with $30: level 2, cash 0, the pad settled at level 1 first ($100 for 100 s)", r1 == nil and b1.level == 2 and near(prof().cash, 0) and near(b1.padCash, 100, 1), ("%s pad %s"):format(tostring(r1), s(b1.padCash)))
L.check(ctx, "funnel FirstBossUpgraded marked", (function() for _, e in ipairs(L.TestHooks.reports.funnel or {}) do if e.name == "FirstBossUpgraded" and e.userId == p.UserId then return true end end return false end)())
local pay = Base.payload(plot).spots[1]
L.check(ctx, "Base.State: level 2, income 1.25/s, nextCost 39", pay.level == 2 and near(pay.income, 1.25) and pay.nextCost == 39)
-- the bought-cash rule: spending earned cash first, boughtCash never above cash
L.hook(ctx, "SetBoughtCash", 39)
task.wait(0.2)
setCash(60)
local bc0 = prof().boughtCash
Upgrades.tryUpgrade(p, uid)
L.check(ctx, "spend $39 of $60 with $39 bought: earned spent first, boughtCash drops to cash ($21)", at(1).level == 3 and near(prof().cash, 21) and near(prof().boughtCash, math.min(bc0, 21)), ("cash %s bought %s"):format(s(prof().cash), s(prof().boughtCash)))
-- to level 20, each step costs exactly the curve
setCash(30000)
local spentOk = true
for lv = 3, 19 do
	local c0, cost = prof().cash, Upgrades.cost("z1_t1", lv)
	local w = Upgrades.tryUpgrade(p, uid)
	if w ~= nil or at(1).level ~= lv + 1 or not near(c0 - prof().cash, cost) then spentOk = false end
end
L.check(ctx, "levels 3 -> 20: each upgrade spends exactly the server's cost", spentOk and at(1).level == 20, at(1).level)
before = s(prof().cash) .. "/" .. at(1).level
L.check(ctx, "at level 20: refused 'cap', nothing changed", Upgrades.tryUpgrade(p, uid) == "cap" and s(prof().cash) .. "/" .. at(1).level == before)
-- refusals
Carry.begin(p, "z1_t2")
standAt(spot(2))
Base.tryPlace(p, 2)
local uid2 = at(2).uid
standAt(spot(9))
before = s(prof().cash) .. "/" .. at(2).level
L.check(ctx, "40 studs from the spot: refused 'range'", Upgrades.tryUpgrade(p, uid2) == "range" and s(prof().cash) .. "/" .. at(2).level == before)
standAt(spot(2))
L.check(ctx, "a uid that is not on the caller's spots: 'notYours'; malformed: 'bad'", Upgrades.tryUpgrade(p, "1-999999") == "notYours" and Upgrades.tryUpgrade(p, 42) == "bad" and Upgrades.tryUpgrade(p, ("x"):rep(80)) == "bad")
Base.tryPickUp(p, 2)
L.check(ctx, "a boss on the owner's head (picked up): refused 'state'", Upgrades.tryUpgrade(p, uid2) == "state")
standAt(spot(3))
Base.tryPlace(p, 3)
L.check(ctx, "the level travels with the boss: picked up from 2, placed on 3, still level 1 with the same uid; upgradable there", at(3) and at(3).uid == uid2 and at(3).level == 1 and Upgrades.tryUpgrade(p, uid2) == nil and at(3).level == 2)

clearCarry()
L.hook(ctx, "Wipe", true)
task.wait(0.3)
workspace:SetAttribute("HFB_ClockOffset", nil)
L.finish(ctx)
