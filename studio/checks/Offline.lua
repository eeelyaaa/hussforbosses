if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-14: gate row S11 (brief system 11: offline earnings) and the build plan's M2 exit check "offline with the clock
-- hook at 30 s (nothing shown), 10 minutes, 3 hours (capped at 2 h a pad)". PLAY MODE, installed into
-- ServerStorage.TmpChecks next to CheckLib:
--   { phase = "a" }  LeaveAt 30 s: nothing; 10 min: the pads' fill, per boss, summary sent; Collect pays exactly that
--                    once (a second Collect 'none'); 3 h: each pad capped at 2 h with the cash already on it counting;
--                    [M2-02 M9] no double pay: a pad walked over first pays only what is left, a boss moved off its
--                    spot pays 0, the total paid never exceeds the pads' fill; rebirth multiplier; no bosses: nothing.
--   { phase = "b" }  the real path: Leave (saves leftAt), ClockOffset +15 min, Rejoin: the summary from the SAVED
--                    leave time; Collect; cash survives a second leave and rejoin.
-- Every pass forced off with PassOwned first. Leaves the profile wiped and every hook cleared.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Carry, Base, Income, Session, Zones = L.Config, L.Carry, L.Base, L.Income, L.Session, L.Zones
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Offline = require(SSS.Systems.Offline)
local Ids = require(RS.Shared.Ids)
local HttpService = game:GetService("HttpService")
local s = L.s
local TestHooks = L.TestHooks

local ctx = L.begin("Offline", ARGS)
local p = ctx.p

local function passesOff()
	local parts = {}
	for _, k in ipairs(Ids.SHOP_KEYS) do
		if Ids.isPass(k) then table.insert(parts, k .. "=off") end
	end
	L.hook(ctx, "PassOwned", table.concat(parts, ","))
	task.wait(0.1)
end
local function prof() return Session.get(p) end
local function clearCarry() if Carry.get(p) then Carry.lose(p, "check") end; task.wait(0.05) end
local function grant(v) L.hook(ctx, "GrantBoss", v); task.wait(0.25) end
local function at(i) return (Base.bossAt(prof(), i)) end
local function fresh()
	clearCarry()
	L.hook(ctx, "Wipe", true)
	task.wait(0.5)
	workspace:SetAttribute("HFB_ClockOffset", nil)
	workspace:SetAttribute("HFB_LeaveAt", nil)
	passesOff()
	Offline.cancel(p)
end
local function leaveAt(n)
	workspace:SetAttribute("HFB_LeaveAt", nil)
	task.wait(0.05)
	L.hook(ctx, "LeaveAt", n)
	task.wait(0.3)
	return TestHooks.reports.offline
end
local function rate(i) local b = at(i); return Income.rate(prof(), b, Income.mult(p)) end
local function near(a, b, tol) return math.abs(a - b) <= (tol or 1e-6) end

fresh()

if ctx.phase == "a" then
	-- no bosses: nothing to show even after 10 minutes
	local r0 = leaveAt(600)
	L.check(ctx, "away 10 min with no bosses: nothing shown (earned 0)", r0 and r0.shown == false and Offline.pending(p) == nil, r0 and r0.away)

	grant("z1_t1,to=1")
	grant("z1_t3,to=2,level=3")
	local r1, r2 = rate(1), rate(2)
	L.check(ctx, "two bosses on spots 1 and 2 earning", r1 > 0 and r2 > 0, ("%s/s and %s/s"):format(s(r1), s(r2)))

	-- 30 s: nothing
	local a = leaveAt(30)
	L.check(ctx, "LeaveAt 30 s: nothing shown (under 60 s)", a and a.shown == false and a.away >= 30 and a.away < 60 and Offline.pending(p) == nil, a and a.away)

	-- 10 minutes
	local cash0 = prof().cash
	local b = leaveAt(600)
	local sum = b and b.summary
	local exp1, exp2 = math.floor(600 * r1), math.floor(600 * r2)
	L.check(ctx, "LeaveAt 10 min: summary shown, seconds 600", b and b.shown == true and sum and sum.seconds >= 600 and sum.seconds <= 601, sum and sum.seconds)
	local u1, u2 = at(1).uid, at(2).uid
	L.check(ctx, "10 min: per boss = 600 s x its income (whole cash), total = their sum",
		sum and near(sum.perBoss[u1], exp1, r1 + 1) and near(sum.perBoss[u2], exp2, r2 + 1) and sum.total == sum.perBoss[u1] + sum.perBoss[u2],
		sum and HttpService:JSONEncode(sum))
	L.check(ctx, "10 min: no cash was paid by the summary itself (the money is on the pads)", prof().cash == cash0, prof().cash)
	local padBefore = Income.onPad(prof(), at(1), Zones.now(), Income.mult(p)) + Income.onPad(prof(), at(2), Zones.now(), Income.mult(p))
	local paid = Offline.collect(p)
	L.check(ctx, "Collect pays exactly the summary's total, as earned cash", paid == sum.total and near(prof().cash, cash0 + sum.total) and prof().boughtCash == 0, ("paid %s cash %s"):format(s(paid), s(prof().cash)))
	local padAfter = Income.onPad(prof(), at(1), Zones.now(), Income.mult(p)) + Income.onPad(prof(), at(2), Zones.now(), Income.mult(p))
	L.check(ctx, "[M9] the collect came off the pads: pads before - pads after = paid (no new money)", near(padBefore - padAfter, paid, r1 + r2 + 1), ("%s - %s vs %s"):format(s(padBefore), s(padAfter), s(paid)))
	L.check(ctx, "a second Collect is refused (nothing pending, nothing paid)", Offline.collect(p) == nil and near(prof().cash, cash0 + sum.total), prof().cash)

	-- [M9] walk-over first: the pad already collected pays only what is left
	local c = leaveAt(600)
	local cashA = prof().cash
	local got1 = Income.collect(p, 1) -- what walking onto CashPad_1 does
	local paid2 = Offline.collect(p)
	local per2 = c.summary.perBoss[u2]
	L.check(ctx, "[M9] pad 1 walked over first: Collect pays pad 2's share and at most what is left on pad 1 (never twice)",
		got1 > 0 and paid2 ~= nil and paid2 <= per2 + 1 and near(prof().cash, cashA + got1 + paid2),
		("walk %s, collect %s, pad 2 share %s"):format(s(got1), s(paid2), s(per2)))

	-- [M9] a boss moved off its spot pays 0
	local d = leaveAt(600)
	Session.mutate(p, function(q)
		for _, bb in ipairs(q.bosses) do if bb.uid == u2 then bb.spot = 5 end end
	end)
	local cashB = prof().cash
	local paid3 = Offline.collect(p)
	L.check(ctx, "[M9] a boss no longer on the spot it was summarised on pays 0; the other pays its share",
		paid3 ~= nil and near(paid3, d.summary.perBoss[u1], 1) and near(prof().cash, cashB + paid3), ("paid %s, boss 1 share %s"):format(s(paid3), s(d.summary.perBoss[u1])))
	Session.mutate(p, function(q)
		for _, bb in ipairs(q.bosses) do if bb.uid == u2 then bb.spot = 2 end end
	end)

	-- 3 hours: capped at 2 h a pad, cash already on the pad counting toward the cap
	fresh()
	grant("z1_t1,to=1")
	grant("z1_t2,to=2")
	Session.mutate(p, function(q)
		for _, bb in ipairs(q.bosses) do if bb.spot == 1 then bb.padCash = 100 end end
	end)
	local q1, q2 = rate(1), rate(2)
	local e = leaveAt(3 * 3600)
	local es = e and e.summary
	local cap1, cap2 = Config.Base.PAD_CAP_S * q1, Config.Base.PAD_CAP_S * q2
	L.check(ctx, "LeaveAt 3 h: shown, seconds 10,800", e and e.shown and es.seconds >= 10800 and es.seconds <= 10801, es and es.seconds)
	L.check(ctx, "3 h: pad 2 capped at 2 h of its income (7,200 s x rate), not 3 h", near(es.perBoss[at(2).uid], math.floor(cap2), 1), ("%s vs cap %s (3 h would be %s)"):format(s(es.perBoss[at(2).uid]), s(cap2), s(10800 * q2)))
	L.check(ctx, "3 h: pad 1 had $100 on it: earned = cap - 100 (the cash on the pad counts toward the cap)", near(es.perBoss[at(1).uid], math.floor(cap1 - 100), 1), ("%s vs %s"):format(s(es.perBoss[at(1).uid]), s(cap1 - 100)))
	local cashC = prof().cash
	local paid4 = Offline.collect(p)
	L.check(ctx, "3 h: Collect pays the capped total; pad 1 keeps its old $100 (only the offline share moves)",
		paid4 == es.total and near(prof().cash, cashC + es.total) and near(Income.onPad(prof(), at(1), Zones.now(), Income.mult(p)), 100, q1 + 1),
		("paid %s, pad 1 now %s"):format(s(paid4), s(Income.onPad(prof(), at(1), Zones.now(), Income.mult(p)))))

	-- the rebirth multiplier applies (2 rebirths: x2)
	fresh()
	grant("z1_t1,to=1")
	L.hook(ctx, "SetRebirths", 2)
	task.wait(0.2)
	local f = leaveAt(600)
	local base = Income.perSecond("z1_t1", 1)
	L.check(ctx, "2 rebirths: the offline amount follows the income multiplier (x2)", f and f.shown and near(f.summary.total, math.floor(600 * base * 2), 2), f and f.summary and f.summary.total)
	Offline.cancel(p)
	L.check(ctx, "Offline.cancel (rebirth): nothing pending, a Collect then pays nothing", Offline.pending(p) == nil and Offline.collect(p) == nil)
	L.check(ctx, "Auto Punch and Power never run offline: Power unchanged by the away time", prof().power == 0, prof().power)
elseif ctx.phase == "b" then
	grant("z1_t2,to=1")
	local r = rate(1)
	Session.save(p, "check")
	L.hook(ctx, "Leave", true)
	local lv = L.waitFor(function() local x = TestHooks.reports.leave; return x and x.userId == p.UserId and x end, 15)
	L.check(ctx, "Leave: final save written with leftAt", lv and lv.status == "saved", lv and lv.status)
	local _, rec = Session._test.rawRead(p.UserId)
	L.check(ctx, "the saved record holds leftAt (server time)", type(rec) == "table" and type(rec.leftAt) == "number" and rec.leftAt > 0, rec and rec.leftAt)
	L.hook(ctx, "ClockOffset", 900)
	task.wait(0.1)
	TestHooks.reports.offline = nil
	L.hook(ctx, "Rejoin", true)
	local rj = L.waitFor(function() local x = TestHooks.reports.offline; return x and x.userId == p.UserId and x end, 20)
	local sum = rj and rj.summary
	L.check(ctx, "Rejoin after 15 min (clock hook): the summary comes from the saved leave time (about 900 s)", rj and rj.shown and sum.seconds >= 899 and sum.seconds <= 905, sum and sum.seconds)
	L.check(ctx, "and it is the pad's fill for that time (900 s x income)", sum and near(sum.total, math.floor(900 * r), r * 5 + 1), sum and sum.total)
	local sent = L.waitFor(function() return Offline.pending(p) ~= nil end, 3)
	L.check(ctx, "the summary is held for the client (resent at 2, 6 and 15 s until collected)", sent == true)
	local cash0 = prof().cash
	local paid = Offline.collect(p)
	L.check(ctx, "Collect after the rejoin pays it once", paid == sum.total and near(prof().cash, cash0 + paid), paid)
	Session.save(p, "check")
	workspace:SetAttribute("HFB_Leave", nil)
	workspace:SetAttribute("HFB_Rejoin", nil)
	task.wait(0.1)
	L.hook(ctx, "Leave", true)
	L.waitFor(function() local x = TestHooks.reports.leave; return x and x ~= lv and x end, 15)
	workspace:SetAttribute("HFB_ClockOffset", nil)
	TestHooks.reports.offline = nil
	L.hook(ctx, "Rejoin", true)
	local rj2 = L.waitFor(function() local x = TestHooks.reports.offline; return x and x.userId == p.UserId and x end, 20)
	L.check(ctx, "the collected cash survives a second leave and rejoin; rejoining at once shows nothing (under 60 s)",
		near(prof().cash, cash0 + paid) and rj2 and rj2.shown == false, ("cash %s, shown %s"):format(s(prof() and prof().cash), tostring(rj2 and rj2.shown)))
	workspace:SetAttribute("HFB_Leave", nil)
	workspace:SetAttribute("HFB_Rejoin", nil)
end

clearCarry()
fresh()
workspace:SetAttribute("HFB_SetRebirths", nil)
L.finish(ctx)
