if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-11: gate rows S7 (brief system 7: spots, place, pick up, duplicates, sell, swap, the crate) and S8 (system 8:
-- income from stamps, the 2-hour cap, collect), plus the scripted income run for M2-26. PLAY MODE, one call per phase,
-- installed into ServerStorage.TmpChecks next to CheckLib:
--   { phase = "a" }  spots 10 / +rebirths / +Extra Spots; place, duplicates, refusals with nothing changed, glow; pick up
--                    (the boss stays saved on its spot while carried, its pad stops filling, its old pad's cash is
--                    collected when it moves); sell; swap; the crate (take out, kept in the base, a lost carry leaves it
--                    in the crate, placed with its uid and level); spots full; the steal lock seam [M2-02 M5]; a spot
--                    carry that ends by death puts the boss back [M2-02 M8].
--   { phase = "b" }  income: whole seconds from the stamp, collect by walking on the pad, the 2-hour cap, level,
--                    rebirth and 2x Cash multipliers, a carried boss does not fill, a stamp from the future pays 0.
--   { phase = "c" }  the scripted run (M2-26): 30 game minutes on ClockOffset, real place / collect / upgrade calls,
--                    income per second at minutes 3, 10 and 30 (NOTE lines; the brief's targets are $5, $80, $800).
-- Needs studio/BuildHazards.lua (spots 11..17). Every pass forced off with PassOwned first.
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

local ctx = L.begin("Base", ARGS)
local p = ctx.p
L.rootY(ctx)

local function passesOff(extra)
	local parts = {}
	for _, k in ipairs(Ids.SHOP_KEYS) do
		if Ids.isPass(k) then table.insert(parts, k .. "=" .. ((extra and extra[k]) or "off")) end
	end
	L.hook(ctx, "PassOwned", table.concat(parts, ","))
	task.wait(0.1)
end
local function near(a, b, tol) return math.abs(a - b) <= (tol or 1e-6) end
local function clearCarry() if Carry.get(p) then Carry.lose(p, "check") end; task.wait(0.05) end
local function prof() return Session.get(p) end
local plot = Session.plot(p)
local function spot(i) return Base.spotPart(plot, i) end
local function standAt(part) L.tp(ctx, L.onPart(ctx, part)); task.wait(0.05) end
local function at(i) return (Base.bossAt(prof(), i)) end
local function bossesKey()
	local t = {}
	for _, b in ipairs(prof().bosses) do table.insert(t, b.spot .. ":" .. b.uid .. ":" .. b.level) end
	local c = {}
	for _, b in ipairs(prof().crate) do table.insert(c, b.uid) end
	return table.concat(t, ",") .. "|" .. table.concat(c, ",") .. "|" .. s(prof().cash)
end
local function lastResult() return Base.stats.results[#Base.stats.results] end
local function carryFight(cid, lvl) clearCarry(); return Carry.begin(p, cid, { level = lvl }) end
local yard = Vector3.new(206, 0.2 + L.rootY(ctx), 170)
local function funnelHas(name)
	for _, e in ipairs(L.TestHooks.reports.funnel or {}) do if e.name == name and e.userId == p.UserId then return true end end
	return false
end
local offset = 0
local function addTime(sec) offset += sec; L.hook(ctx, "ClockOffset", offset); task.wait(0.05) end
local function grant(v) L.hook(ctx, "GrantBoss", v); task.wait(0.25) end
local function fresh()
	clearCarry()
	L.hook(ctx, "Wipe", true)
	task.wait(0.5)
	offset = 0
	workspace:SetAttribute("HFB_ClockOffset", nil)
	passesOff()
end

assert(plot and spot(17), "Base check: run studio/BuildHazards.lua first (Spot_17 missing on the player's plot)")
fresh()

if ctx.phase == "a" then
	-- spot counts
	local _, n0 = Base.unlocked(p)
	local pay = Base.payload(plot)
	L.check(ctx, "10 spots at the start; Base.State spots and unlocked are dense 1..17", n0 == 10 and pay.spotsCap == 10 and #pay.spots == 17 and #pay.unlocked == 17 and pay.unlocked[11] == false, ("%d, spots %d"):format(n0, #pay.spots))
	Session.mutate(p, function(q) q.rebirths = 2 end)
	local u2, n2 = Base.unlocked(p)
	Session.mutate(p, function(q) q.rebirths = 7 end)
	local u7, n7 = Base.unlocked(p)
	passesOff({ pass_extra_spots = "on" })
	local u7x, n7x = Base.unlocked(p)
	L.check(ctx, "+1 spot per rebirth up to +5 (2 -> 12 with 11, 12; 7 -> 15), +2 with Extra Spots (16, 17): 17 most", n2 == 12 and u2[11] and u2[12] and not u2[13] and n7 == 15 and u7[15] and not u7[16] and n7x == 17 and u7x[16] and u7x[17], ("%d %d %d"):format(n2, n7, n7x))
	Session.mutate(p, function(q) q.rebirths = 0 end)
	passesOff()
	-- place and glow
	local c1 = carryFight("z1_t1")
	task.wait(0.1)
	L.check(ctx, "while carrying: empty unlocked spots glow, locked spot 11 does not", spot(1):GetAttribute("Glow") == true and spot(10):GetAttribute("Glow") == true and spot(11):GetAttribute("Glow") == false and spot(11):GetAttribute("Unlocked") == false)
	standAt(spot(1))
	local w = Base.tryPlace(p, 1)
	task.wait(0.1)
	L.check(ctx, "place on spot 1: saved in bosses with the carry's uid, level 1, pad 0; carry ends; Result ok", w == nil and at(1) and at(1).uid == c1.uid and at(1).level == 1 and at(1).padCash == 0 and Carry.get(p) == nil and lastResult().ok, tostring(w))
	L.check(ctx, "funnel FirstBossPlaced marked", funnelHas("FirstBossPlaced"))
	L.check(ctx, "glow off once placed", spot(2):GetAttribute("Glow") == false)
	local c2 = carryFight("z1_t1")
	standAt(spot(2))
	Base.tryPlace(p, 2)
	L.check(ctx, "duplicates: a second z1_t1 on spot 2 with its own uid", at(2) and at(2).creatureId == "z1_t1" and at(2).uid == c2.uid and c2.uid ~= c1.uid)
	-- refusals change nothing
	local c3 = carryFight("z1_t2")
	local before = bossesKey()
	standAt(spot(1))
	local r1 = Base.tryPlace(p, 1)
	local res1 = lastResult()
	local r2 = Base.tryPlace(p, 11)
	local r3 = Base.tryPlace(p, 9)
	local bads = {}
	for _, bad in ipairs({ 0, 18, 1.5, "1", 0 / 0, math.huge, true }) do table.insert(bads, tostring(Base.tryPlace(p, bad))) end
	L.check(ctx, "place refused: taken spot 'taken' (client 'spot'), locked spot 11 'bad', 40 studs away 'range', malformed 'bad'; nothing changed, still carrying", r1 == "taken" and res1.reason == "taken" and r2 == "bad" and r3 == "range" and table.concat(bads, ",") == "bad,bad,bad,bad,bad,bad,bad" and bossesKey() == before and Carry.isCarrying(p), ("%s %s %s [%s]"):format(tostring(r1), tostring(r2), tostring(r3), table.concat(bads, ",")))
	standAt(spot(3))
	Base.tryPlace(p, 3)
	L.check(ctx, "placed z1_t2 on spot 3", at(3) and at(3).uid == c3.uid)

	-- pick up
	addTime(60)
	local u1 = at(1).uid
	standAt(spot(1))
	local cashBefore = prof().cash
	local pk = Base.tryPickUp(p, 1)
	local cc = Carry.get(p)
	L.check(ctx, "pick up spot 1: carrying it (origin spot, same uid); it stays saved on spot 1 [M2-02 M8]; pad cash 60 stays", pk == nil and cc and cc.origin == "spot" and cc.uid == u1 and at(1) and at(1).uid == u1 and near(at(1).padCash, 60) and prof().cash == cashBefore, ("%s pad %s"):format(tostring(pk), s(at(1) and at(1).padCash)))
	local pay1 = Base.payload(plot).spots[1]
	L.check(ctx, "Base.State: spot 1 shows carried, income 0", pay1 and pay1.carried == true and pay1.income == 0)
	L.check(ctx, "pick up while carrying refused 'state'", Base.tryPickUp(p, 2) == "state")
	addTime(60)
	L.check(ctx, "a carried boss's pad does not fill (still 60 after 60 s)", near(Income.onPad(prof(), at(1), Zones.now(), Income.mult(p)), 60))
	standAt(spot(4))
	local cash0 = prof().cash
	local pl4 = Base.tryPlace(p, 4)
	L.check(ctx, "placed on spot 4: same uid and level there, spot 1 free, its old pad's 60 collected (TEAM CALL M2-11-2)", pl4 == nil and at(4) and at(4).uid == u1 and at(1) == nil and near(prof().cash - cash0, 60) and at(4).padCash == 0, ("cash +%s"):format(s(prof().cash - cash0)))
	Base.tryPickUp(p, 4)
	Base.tryPlace(p, 4)
	L.check(ctx, "pick up and put back on the same spot: still there", at(4) and at(4).uid == u1 and Carry.get(p) == nil)
	L.check(ctx, "pick up an empty spot refused 'spot'; malformed 'bad'", Base.tryPickUp(p, 1) == "spot" and Base.tryPickUp(p, "1") == "bad" and Base.tryPickUp(p, 0 / 0) == "bad")

	-- sell
	carryFight("z1_t2")
	standAt(spot(5))
	cash0 = prof().cash
	local n0b = #prof().bosses
	local sw = Base.trySell(p)
	L.check(ctx, "sell inside the own base: +20 x income/s (z1_t2: $40), Result amount 40, no boss added", sw == nil and near(prof().cash - cash0, 40) and lastResult().amount == 40 and #prof().bosses == n0b and Carry.get(p) == nil, s(prof().cash - cash0))
	carryFight("z1_t2")
	L.tp(ctx, yard)
	task.wait(0.1)
	L.check(ctx, "sell outside the base refused 'range', still carrying", Base.trySell(p) == "range" and Carry.isCarrying(p))
	clearCarry()
	L.check(ctx, "sell with nothing carried refused 'notCarrying'", Base.trySell(p) == "notCarrying")

	-- swap
	local old2 = at(2).uid
	local c4 = carryFight("z1_t3")
	standAt(spot(2))
	cash0 = prof().cash
	local pad2 = Income.onPad(prof(), at(2), Zones.now(), Income.mult(p))
	local sv = Base.trySwap(p, 2)
	L.check(ctx, "swap on spot 2: the placed z1_t1 sold ($20) plus its pad, the carried z1_t3 takes the spot, one mutate", sv == nil and at(2) and at(2).uid == c4.uid and near(prof().cash - cash0, 20 + pad2) and lastResult().amount == 20 and Carry.get(p) == nil, ("cash +%s, pad %s"):format(s(prof().cash - cash0), s(pad2)))
	local gone = true
	for _, b in ipairs(prof().bosses) do if b.uid == old2 then gone = false end end
	L.check(ctx, "the swapped-out boss is gone from the profile", gone)
	carryFight("z1_t1")
	standAt(spot(5))
	L.check(ctx, "swap on an empty spot refused 'spot'; with nothing carried 'notCarrying'", Base.trySwap(p, 5) == "spot" and (function() clearCarry(); return Base.trySwap(p, 2) == "notCarrying" end)())

	-- the crate
	grant("z2_t1,to=crate,level=3")
	local ce = prof().crate[1]
	L.check(ctx, "GrantBoss to=crate: one crate boss, level 3, with its own uid", #prof().crate == 1 and ce and ce.creatureId == "z2_t1" and ce.level == 3)
	L.tp(ctx, yard)
	task.wait(0.1)
	L.check(ctx, "take from the crate outside the base refused 'range'", ce and Base.tryTakeCrate(p, ce.uid) == "range")
	standAt(spot(5))
	L.check(ctx, "take a uid not in the crate refused 'notYours'; malformed 'bad'", Base.tryTakeCrate(p, "1-999") == "notYours" and Base.tryTakeCrate(p, 5) == "bad")
	local tk = ce and Base.tryTakeCrate(p, ce.uid)
	local ccr = Carry.get(p)
	L.check(ctx, "take out: carrying it (origin crate, level 3); it stays in the crate until placed [M2-02 M8]", tk == nil and ccr and ccr.origin == "crate" and ccr.level == 3 and #prof().crate == 1)
	local kept0 = Carry.stats.keptInBase
	-- one step out through the entrance: 3 studs in front of the front fence line, mid-entrance (plot frame x 25, y -3)
	local f = Carry.plotFrame(plot)
	local inn = f.o + f.ex * 25 + f.ey * 1
	local out = f.o + f.ex * 25 - f.ey * 3
	L.tp(ctx, Vector3.new(inn.X, ctx.hrp.Position.Y, inn.Z))
	task.wait(0.3) -- samples inside first; the 4-stud step out is under the teleport limit
	ctx.char:PivotTo(CFrame.new(out.X, ctx.hrp.Position.Y, out.Z))
	task.wait(0.2)
	L.check(ctx, "an own boss cannot leave the base: stepping out puts the carrier back inside (TEAM CALL M2-11-3)", Carry.stats.keptInBase > kept0 and Carry.insideOwnPlot(p, 1) and Carry.isCarrying(p), Carry.stats.keptInBase - kept0)
	Carry.lose(p, "hazard")
	L.check(ctx, "a crate carry that ends without placing: the boss is still in the crate", #prof().crate == 1 and prof().crate[1].uid == ce.uid and Carry.get(p) == nil)
	standAt(spot(5))
	Base.tryTakeCrate(p, ce.uid)
	Base.tryPlace(p, 5)
	L.check(ctx, "placed from the crate: crate empty, spot 5 holds that uid at level 3", #prof().crate == 0 and at(5) and at(5).uid == ce.uid and at(5).level == 3)
	L.check(ctx, "funnel Zone2BossPlaced marked (a zone 2 creature placed)", funnelHas("Zone2BossPlaced"))

	-- the steal lock seam
	local lockUid = at(3).uid
	Base.setLockCheck(function(uid) return uid == lockUid end)
	standAt(spot(3))
	local lp = Base.tryPickUp(p, 3)
	carryFight("z1_t1")
	local ls = Base.trySwap(p, 3)
	local lpl = Base.tryPlace(p, 3)
	clearCarry()
	Session.mutate(p, function(q) q.cash = 1e6 end)
	local lu = Upgrades.tryUpgrade(p, lockUid)
	Base.setLockCheck(require(game:GetService("ServerScriptService").Systems.Steal).isLocked) -- the real seam back (M2-15)
	L.check(ctx, "a boss locked by a steal: Pick Up, Swap, Place onto its spot and Upgrade refused 'locked' [M2-02 M5]", lp == "locked" and ls == "locked" and lpl == "locked" and lu == "locked", ("%s %s %s %s"):format(tostring(lp), tostring(ls), tostring(lpl), tostring(lu)))
	Session.mutate(p, function(q) q.cash = 0 end)

	-- M2-11b: a stolen boss whose transfer is still pending (Data/Transfer.isPending, stubbed for this uid) cannot be
	-- sold or swapped away; it can still be picked up and moved
	local Transfer = require(SSS.Data.Transfer)
	local realPending = Transfer.isPending
	local pendUid = at(3).uid
	Transfer.isPending = function(pl, uid) return (pl == p and uid == pendUid) or realPending(pl, uid) end
	local okP, errP = pcall(function()
		standAt(spot(3))
		carryFight("z1_t1")
		local before3 = bossesKey()
		local sw3 = Base.trySwap(p, 3)
		clearCarry()
		local pk3 = Base.tryPickUp(p, 3)
		local sl3 = Base.trySell(p)
		local still = at(3) and at(3).uid == pendUid
		Carry.lose(p, "check")
		L.check(ctx, "a pending stolen boss: Swap away and Sell refused 'locked' (client 'locked'), Pick Up allowed, nothing lost (M2-11b)", sw3 == "locked" and pk3 == nil and sl3 == "locked" and lastResult().reason == "locked" and still and bossesKey() == before3, ("%s %s %s"):format(tostring(sw3), tostring(pk3), tostring(sl3)))
	end)
	Transfer.isPending = realPending
	if not okP then L.check(ctx, "pending section ran", false, errP) end
	-- M2-27 MF2: a pending stolen boss in the crate: Take out refused; a pending boss already on the head as a crate carry
	-- (how a steal arrives) cannot be sold
	grant("z1_t2,to=crate,level=2")
	local cu = prof().crate[#prof().crate].uid
	Transfer.isPending = function(pl, uid) return (pl == p and uid == cu) or realPending(pl, uid) end
	local okC, errC = pcall(function()
		standAt(spot(5))
		local before = bossesKey()
		local tk = Base.tryTakeCrate(p, cu)
		local tkRes = lastResult().reason
		clearCarry()
		Carry.begin(p, "z1_t2", { origin = "crate", uid = cu, level = 2 })
		local sl = Base.trySell(p)
		local stillCarry = Carry.isCarrying(p)
		clearCarry()
		L.check(ctx, "a pending stolen boss in the crate: Take out refused 'locked'; carried from the crate, Sell refused 'locked'; still in the crate, cash unchanged (M2-27 MF2)", tk == "locked" and tkRes == "locked" and sl == "locked" and stillCarry and bossesKey() == before, ("%s %s"):format(tostring(tk), tostring(sl)))
	end)
	Transfer.isPending = realPending
	if not okC then L.check(ctx, "pending crate section ran", false, errC) end
	L.check(ctx, "once no longer pending: the same crate boss can be taken out", Base.tryTakeCrate(p, cu) == nil and Carry.get(p) and Carry.get(p).uid == cu)
	clearCarry()
	Session.mutate(p, function(q) for k, b in ipairs(q.crate) do if b.uid == cu then table.remove(q.crate, k) break end end end)

	-- spots full
	for i = 1, 10 do if not at(i) then grant(("z1_t1,to=%d"):format(i)) end end
	grant("z1_t2,to=crate")
	standAt(spot(5))
	local fullR = Base.tryTakeCrate(p, prof().crate[1].uid)
	L.check(ctx, "every spot full: take from the crate refused 'full' (Notice spotsFullOffer without the pass)", fullR == "full" and lastResult().reason == "full" and #prof().crate == 1, tostring(fullR))

	-- a spot carry that ends by death: the boss back on its spot
	local u6 = at(6).uid
	standAt(spot(6))
	Base.tryPickUp(p, 6)
	local died = Carry.get(p) and Carry.get(p).origin == "spot"
	ctx.hum.Health = 0
	local ch = L.waitFor(function() local c = p.Character; return c ~= ctx.char and c and c:FindFirstChild("HumanoidRootPart") and c end, 12)
	if ch then ctx.char = ch; ctx.hrp = ch.HumanoidRootPart; ctx.hum = ch:WaitForChild("Humanoid"); task.wait(0.5) end
	L.check(ctx, "a picked-up boss whose carrier dies goes back to its spot (still saved there) [M2-02 M8]", died and ch ~= nil and Carry.get(p) == nil and at(6) and at(6).uid == u6)
	-- the remotes are wired (each handler is one line into the functions above)
	local fam = require(RS.Shared.Net)
	L.check(ctx, "Base.PickUp, Swap, Sell, TakeCrate and Boss.Upgrade remotes exist", fam.get("Base", "PickUp") and fam.get("Base", "Swap") and fam.get("Base", "Sell") and fam.get("Base", "TakeCrate") and fam.get("Boss", "Upgrade") and true or false)

elseif ctx.phase == "b" then
	local c = carryFight("z1_t1")
	standAt(spot(1))
	Base.tryPlace(p, 1)
	local b1 = at(1)
	local pay = Base.payload(plot).spots[1]
	L.check(ctx, "placed: income 1/s, pad 0, capSeconds 7200, stamp = server time", b1 and b1.uid == c.uid and pay.income == 1 and pay.padCash == 0 and pay.capSeconds == 7200 and near(pay.stamp, Zones.now(), 1))
	local now0 = Zones.now()
	addTime(30)
	L.check(ctx, "30 s later the pad holds $30 (from the stamp, no loop)", near(Income.onPad(prof(), at(1), Zones.now(), 1), 30), s(Income.onPad(prof(), at(1), Zones.now(), 1)))
	local cash0 = prof().cash
	local col0 = #Income.stats.collects
	L.tp(ctx, L.onPart(ctx, plot.CashPad_1))
	local got = L.waitFor(function() return #Income.stats.collects > col0 end, 1)
	L.check(ctx, "walking onto the cash pad collects it: +$30, Base.Collected, pad empty", got and near(prof().cash - cash0, 30, 1) and at(1).padCash == 0, s(prof().cash - cash0))
	L.check(ctx, "funnel FirstCashCollected marked", funnelHas("FirstCashCollected"))
	standAt(spot(1))
	cash0 = prof().cash
	addTime(10.7)
	local whole = Income.onPad(prof(), at(1), Zones.now(), 1)
	L.check(ctx, "whole seconds: 10.7 s fills $10 or $11 (the part-second carries over)", whole == 10 or whole == 11, s(whole))
	addTime(9000)
	L.check(ctx, "the 2-hour cap: after 9,000 s the pad holds 7,200 (2 h x $1)", near(Income.onPad(prof(), at(1), Zones.now(), 1), 7200))
	L.check(ctx, "Collect pays the cap", near(Income.collect(p, 1), 7200))
	-- level and multipliers
	grant("z1_t1,to=2,level=5")
	addTime(100)
	L.check(ctx, "level 5 earns x2.0: $200 in 100 s", near(Income.onPad(prof(), at(2), Zones.now(), Income.mult(p)), 200))
	Income.collect(p, 2)
	Session.mutate(p, function(q) q.rebirths = 2 end)
	addTime(10)
	L.check(ctx, "2 rebirths: income x2.0 (1 + 0.5 x 2): $40 in 10 s at level 5", near(Income.mult(p), 2) and near(Income.onPad(prof(), at(2), Zones.now(), Income.mult(p)), 40), s(Income.mult(p)))
	passesOff({ pass_2x_cash = "on" })
	L.check(ctx, "2x Cash doubles it: $80 for the same 10 s; Base.State income 8/s", near(Income.mult(p), 4) and near(Income.onPad(prof(), at(2), Zones.now(), Income.mult(p)), 80) and Base.payload(plot).spots[2].income == 8)
	passesOff()
	Income.collect(p, 2)
	Session.mutate(p, function(q) q.rebirths = 0 end)
	-- a stamp from the future pays nothing (another server's clock, M2-02 N7)
	ctx.expect = "check"
	Session.mutate(p, function(q) for _, b in ipairs(q.bosses) do if b.spot == 1 then b.padStamp = Zones.now() + 100; b.padCash = 0 end end end)
	ctx.expect = nil
	L.check(ctx, "a stamp 100 s in the future: the pad holds 0, never negative", Income.onPad(prof(), at(1), Zones.now(), 1) == 0)
	-- the server decides: a Base.Collected-style claim from the client does not exist; cash only moved by collects here
	L.authority(ctx, 0, "income phase")

elseif ctx.phase == "c" then
	-- The scripted run. Plan (stand-in for hand play, for M2-26 to compare): a boss home every trip (zone 1: one every
	-- 35 s from 0:52 to 3:40; zone 2: one every 53 s to 15:00; zone 3: one every 75 s after), tiers in the order 1, 2, 1,
	-- 3 (rolling pads give the odd better one); every 10 s it collects every pad and buys upgrades whose cost is paid back
	-- within 10 minutes, cheapest payback first; a new boss into a full base swaps out the lowest earner if it earns more.
	-- No Strength buys, no passes, no rebirth. Every action is a real server call (place, swap, collect, upgrade).
	local zoneOf = function(t) if t < 220 then return 1, 35 elseif t < 900 then return 2, 53 else return 3, 75 end end
	local tiers = { 1, 2, 1, 3 }
	local nextTrip, tripN = 52, 0
	local serverStart = workspace:GetServerTimeNow()
	local function goTo(simT)
		offset = simT - (workspace:GetServerTimeNow() - serverStart)
		workspace:SetAttribute("HFB_ClockOffset", offset)
		ctx.hooks.ClockOffset = true
	end
	local function incomeNow()
		local sum = 0
		local m = Income.mult(p)
		for _, b in ipairs(prof().bosses) do sum += Income.rate(prof(), b, m) end
		return sum
	end
	local earned = 0
	local marks = { [180] = false, [600] = false, [1800] = false }
	local t = 0
	while t <= 1800 do
		goTo(t)
		while t >= nextTrip do
			tripN += 1
			local zone, every = zoneOf(nextTrip)
			local cid = ("z%d_t%d"):format(zone, tiers[(tripN - 1) % 4 + 1])
			carryFight(cid)
			local free = Base.freeSpot(p, prof())
			if free then
				standAt(spot(free))
				Base.tryPlace(p, free)
			else
				local low, lowI = math.huge, nil
				for _, b in ipairs(prof().bosses) do
					local r = Income.perSecond(b.creatureId, b.level)
					if r < low then low, lowI = r, b.spot end
				end
				if lowI and Income.perSecond(cid, 1) > low then
					standAt(spot(lowI))
					local v = Base.sellValue(p, prof(), at(lowI).creatureId, at(lowI).level)
					if Base.trySwap(p, lowI) == nil then earned += v end
				else
					standAt(spot(5))
					local v = Base.sellValue(p, prof(), cid, 1)
					if Base.trySell(p) == nil then earned += v end
				end
			end
			clearCarry()
			nextTrip += every
		end
		if t % 10 == 0 then
			for _, b in ipairs(table.clone(prof().bosses)) do earned += Income.collect(p, b.spot) end
			local bought = true
			while bought do
				bought = false
				local best, bestPay
				for _, b in ipairs(prof().bosses) do
					local cost = Upgrades.cost(b.creatureId, b.level)
					local gain = (Config.Zones.INCOME[b.creatureId] or 0) * 0.25 * Income.mult(p)
					if cost and gain > 0 and cost / gain <= 600 and cost <= prof().cash and (not bestPay or cost / gain < bestPay) then
						best, bestPay = b, cost / gain
					end
				end
				if best then
					standAt(spot(best.spot))
					if Upgrades.tryUpgrade(p, best.uid) == nil then bought = true end
				end
			end
		end
		if marks[t] == false then
			marks[t] = true
			local lv = {}
			for _, b in ipairs(prof().bosses) do table.insert(lv, b.creatureId .. "@" .. b.level) end
			L.note(ctx, ("RUN minute %d: income $%s/s, %d bosses, cash $%s, earned so far $%s | %s"):format(t / 60, s(incomeNow()), #prof().bosses, s(prof().cash), s(earned), table.concat(lv, " ")))
		end
		t += 5
	end
	L.check(ctx, "the scripted run reached minute 30 with income measured at 3, 10, 30 (NOTE lines; targets $5, $80, $800)", marks[180] and marks[600] and marks[1800])
	L.check(ctx, "no upgrade or place was refused for a server reason during the run (state, range)", (Base.stats.refused.state or 0) == 0 and (Upgrades.stats.refused.range or 0) == 0 and (Upgrades.stats.refused.state or 0) == 0,
		("Base state %s, Upgrades range %s state %s"):format(tostring(Base.stats.refused.state), tostring(Upgrades.stats.refused.range), tostring(Upgrades.stats.refused.state)))
end

clearCarry()
L.hook(ctx, "Wipe", true)
task.wait(0.3)
workspace:SetAttribute("HFB_ClockOffset", nil)
L.finish(ctx)
