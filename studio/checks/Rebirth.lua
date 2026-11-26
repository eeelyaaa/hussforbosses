if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-14: gate rows S12 / S19 (brief system 12: rebirth as one save operation) and S20 (the bought mark), and the build
-- plan's M2 exit checks "rebirth" and "the bought mark". PLAY MODE, installed into ServerStorage.TmpChecks:
--   { phase = "a" }  Config.Rebirth.RESET / KEPT name every schema key once [M2-02 M2]; refusals (confirmed not exactly
--                    true, power, max, carrying, a boss locked by a thief [M5], a uid pending from a steal, cooldown)
--                    with nothing changed; the rebirth itself: every reset key, every kept key, the buyer's own bought
--                    bosses (a spin boss on a spot, a pack boss in the crate, one stolen from a stand-in and stolen
--                    back) at their levels re-placed lowest spot first, pad cash 0, the earned bosses and a bought
--                    boss stolen from the stand-in's buyer removed; written to the store at once; multipliers and spots.
--   { phase = "b" }  overflow: 15 own bought bosses, rebirth 2 with Extra Spots: spots 1..12, 16, 17 then the crate;
--                    the bought-cash rule through buy, earn, spend, rebirth [M2-02 M1].
--   { phase = "c" }  the bought mark [S20]: BoughtMark.grant sets { source, buyer } and puts the boss in the crate; a bad
--                    source or creature is refused; a plain mutate cannot add, change or clear a mark or write
--                    boughtCash; Session.set refuses boughtCash; the GrantBoss hook's bought= path (to=head refused);
--                    the mark moves unchanged with a transfer; no remote's payload names bought or boughtCash; no
--                    script outside Data/ and Systems/BoughtMark claims "BoughtMark" or writes a mark.
-- Every pass forced off with PassOwned first. Leaves the profile wiped and every hook cleared.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Carry, Base, Income, Session, Zones, Bag = L.Config, L.Carry, L.Base, L.Income, L.Session, L.Zones, L.Bag
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Rebirth = require(SSS.Systems.Rebirth)
local BoughtMark = require(SSS.Systems.BoughtMark)
local Offline = require(SSS.Systems.Offline)
local Schema = require(SSS.Data.Schema)
local Ids = require(RS.Shared.Ids)
local TestHooks = L.TestHooks
local s = L.s

local ctx = L.begin("Rebirth", ARGS)
local p = ctx.p
local me = p.UserId

local function passes(extra)
	local parts = {}
	for _, k in ipairs(Ids.SHOP_KEYS) do
		if Ids.isPass(k) then table.insert(parts, k .. "=" .. ((extra and extra[k]) or "off")) end
	end
	L.hook(ctx, "PassOwned", table.concat(parts, ","))
	task.wait(0.15)
end
local function prof() return Session.get(p) end
local function clearCarry() if Carry.get(p) then Carry.lose(p, "check") end; task.wait(0.05) end
local function fresh()
	clearCarry()
	L.hook(ctx, "Wipe", true)
	task.wait(0.5)
	workspace:SetAttribute("HFB_ClockOffset", nil)
	passes()
end
local function j(x) local ok, v = pcall(HttpService.JSONEncode, HttpService, x); return ok and v or tostring(x) end
local function snapshot() local q = Schema.copy(prof()); q.spots = nil; q.carry = nil; return q end
local function same(a, b) return Schema.equal(a, b) end
local function req(payload) return Rebirth.request(p, payload) end
local function find(list, uid) for _, b in ipairs(list) do if b.uid == uid then return b end end return nil end
local function setPower(n) Session.set(p, "power", n); task.wait(0.05) end
-- a bought boss for `buyer` straight into this player's spot (as the hook would), returns its uid
local function boughtAt(cid, spot, level, source, buyer)
	local uid = BoughtMark.grant(p, cid, source or "spin", { level = level })
	assert(uid, "grant failed")
	if spot then
		Session.mutate(p, function(q)
			for k, b in ipairs(q.crate) do
				if b.uid == uid then
					table.remove(q.crate, k)
					table.insert(q.bosses, { uid = b.uid, creatureId = b.creatureId, level = b.level, spot = spot, padCash = 0, padStamp = Zones.now(), bought = b.bought })
					break
				end
			end
		end)
	end
	return uid
end
local function earnedAt(cid, spot, level, padCash)
	local uid = Session.newUid(p)
	Session.mutate(p, function(q)
		if spot then
			table.insert(q.bosses, { uid = uid, creatureId = cid, level = level or 1, spot = spot, padCash = padCash or 0, padStamp = Zones.now() })
		else
			table.insert(q.crate, { uid = uid, creatureId = cid, level = level or 1 })
		end
	end)
	return uid
end

fresh()

if ctx.phase == "a" then
	-- [M2-02 M2] the lists cover the schema exactly once
	local keys, seen, dup = {}, {}, {}
	for k in pairs(Schema.DEFAULTS) do keys[k] = true end
	keys.lock = true
	for _, list in ipairs({ Config.Rebirth.RESET, Config.Rebirth.KEPT }) do
		for _, k in ipairs(list) do
			if seen[k] then table.insert(dup, k) end
			seen[k] = true
		end
	end
	local missing, extra = {}, {}
	for k in pairs(keys) do if not seen[k] then table.insert(missing, k) end end
	for k in pairs(seen) do if not keys[k] then table.insert(extra, k) end end
	L.check(ctx, "[M2] RESET + KEPT name every schema key (and lock) exactly once", #missing == 0 and #extra == 0 and #dup == 0,
		("missing %s extra %s dup %s"):format(table.concat(missing, ","), table.concat(extra, ","), table.concat(dup, ",")))
	L.check(ctx, "the table: 10 rebirths, 10M .. 650M; multipliers x(1+n) bag, x(1+0.5n) income",
		#Config.Rebirth.REQUIRED == 10 and Config.Rebirth.REQUIRED[1] == 10e6 and Config.Rebirth.REQUIRED[10] == 650e6 and Config.Rebirth.POWER_MULT(3) == 4 and Config.Rebirth.INCOME_MULT(3) == 2.5)

	-- build the run
	local stand = Session.standIn(-31)
	L.waitFor(function() return Session.get(stand) ~= nil end, 5)
	Session.addCash(p, 5000, true) -- bought (as the Starter Pack would)
	Session.addCash(p, 45000) -- earned
	Session.mutate(p, function(q)
		q.strengthLevel, q.speedLevel = 7, 4
		q.spinTickets, q.breakerCharges = 3, 2
		q.shieldReadyAt = Zones.now() + 40
		q.flags.FirstBossPlaced = true
		q.settings = { music = 0.5, effects = 0.75 }
	end)
	Session.addZoneBeaten(p, 1)
	Session.addZoneBeaten(p, 2)
	Session.mutate(p, function(q) q.starterPackGiven = true end, Session.claim("StarterPack"))
	local uEarned1 = earnedAt("z1_t1", 1, 5, 300)
	local uSpin = boughtAt("z2_t3", 4, 7, "spin")
	Session.mutate(p, function(q) for _, b in ipairs(q.bosses) do if b.uid == uSpin then b.padCash = 200 end end end)
	local uPack = boughtAt("z1_t4", nil, 3, "pack")
	local uEarnedCrate = earnedAt("z1_t2", nil, 2)
	-- a boss bought by the stand-in, stolen by this player: reset at this player's rebirth
	local uTheirs = BoughtMark.grant(stand, "z3_t2", "spin", { level = 4 })
	local okT1 = Session.transfer(uTheirs, stand, p, function(q, e)
		e.spot = 2; e.padCash = 0; e.padStamp = Zones.now(); table.insert(q.bosses, e)
	end)
	-- a boss this player bought, stolen by the stand-in, then stolen back: kept
	local uBack = boughtAt("z2_t5", 6, 9, "spin")
	local okT2 = Session.transfer(uBack, p, stand, function(q, e)
		e.spot = 1; e.padCash = 0; e.padStamp = Zones.now(); table.insert(q.bosses, e)
	end)
	local inStand = find(Session.get(stand).bosses, uBack)
	L.check(ctx, "the stand-in stole a bought boss: the mark moved unchanged (buyer still this player)", okT1 and okT2 and inStand and inStand.bought and inStand.bought.buyer == me and inStand.bought.source == "spin", inStand and j(inStand.bought))
	local okT3 = Session.transfer(uBack, stand, p, function(q, e)
		table.insert(q.crate, { uid = e.uid, creatureId = e.creatureId, level = e.level, bought = e.bought })
	end)
	L.waitFor(function()
		local T = SSS.Data:FindFirstChild("Transfer") and require(SSS.Data.Transfer)
		return T and not T.isPending(p, uTheirs) and not T.isPending(p, uBack)
	end, 10)
	L.check(ctx, "setup: 4 own/other bought bosses and 2 earned ones in place", okT3 and find(prof().bosses, uTheirs) and find(prof().crate, uBack) and #prof().bosses == 3 and #prof().crate == 3,
		("bosses %d crate %d"):format(#prof().bosses, #prof().crate))

	-- refusals, each with nothing changed
	setPower(12e6)
	local before = snapshot()
	local r1 = req({})
	local r2 = req({ confirmed = "true" })
	local r3 = req({ confirmed = 1 })
	L.check(ctx, "confirmed missing, 'true' or 1: refused 'state'", not r1.ok and r1.reason == "state" and r2.reason == "state" and r3.reason == "state" and same(before, snapshot()))
	setPower(9999999)
	before = snapshot()
	local r4 = req({ confirmed = true })
	L.check(ctx, "Power 9,999,999 < 10M: refused 'power', nothing changed", not r4.ok and r4.reason == "power" and same(before, snapshot()), r4.reason)
	setPower(12e6)
	Carry.begin(p, "z1_t1", { level = 1 })
	task.wait(0.05)
	before = snapshot()
	local r5 = req({ confirmed = true })
	clearCarry()
	L.check(ctx, "carrying a boss: refused 'state', nothing changed", not r5.ok and r5.reason == "state" and same(before, snapshot()), r5.reason)
	Base.setLockCheck(function(uid) return uid == uSpin end)
	before = snapshot()
	local r6 = req({ confirmed = true })
	Base.setLockCheck(require(game:GetService("ServerScriptService").Systems.Steal).isLocked) -- the real seam back (M2-15)
	L.check(ctx, "[M5] a boss held or carried off by a thief: refused 'state', nothing changed", not r6.ok and r6.reason == "state" and same(before, snapshot()), r6.reason)
	L.hook(ctx, "SetRebirths", 10)
	task.wait(0.1)
	local r7 = req({ confirmed = true })
	L.check(ctx, "10 rebirths: refused 'max'", not r7.ok and r7.reason == "max", r7.reason)
	L.hook(ctx, "SetRebirths", 0)
	task.wait(0.1)
	setPower(12e6)

	-- the rebirth
	before = snapshot()
	local t0 = Zones.now()
	local r = req({ confirmed = true })
	local q = prof()
	L.check(ctx, "accepted: Rebirth.Result ok, rebirths 1, 3 placed, 0 crated", r.ok and r.rebirths == 1 and r.placed == 3 and r.crated == 0, j(r))
	L.check(ctx, "reset: Power 0, Strength 1, Speed 1, shield cooldown 0", q.power == 0 and q.strengthLevel == 1 and q.speedLevel == 1 and q.shieldReadyAt == 0, ("%s %d %d %s"):format(s(q.power), q.strengthLevel, q.speedLevel, s(q.shieldReadyAt)))
	L.check(ctx, "cash = min(cash, boughtCash): $50,000 with $5,000 bought -> $5,000; boughtCash 5,000 kept", q.cash == 5000 and q.boughtCash == 5000, ("%s / %s"):format(s(q.cash), s(q.boughtCash)))
	local keptOk, keptBad = true, {}
	for _, k in ipairs(Config.Rebirth.KEPT) do
		if k ~= "rebirths" and k ~= "lock" and not same(before[k], q[k]) then keptOk = false; table.insert(keptBad, k) end
	end
	L.check(ctx, "kept exactly: version, boughtCash, zonesBeaten {1,2}, 3 tickets, 2 charges, starterPackGiven, purchases, transferNote, nextUid, leftAt, flags, settings",
		keptOk and q.rebirths == before.rebirths + 1 and j(q.zonesBeaten) == "[1,2]" and q.spinTickets == 3 and q.breakerCharges == 2 and q.starterPackGiven == true and q.settings.music == 0.5,
		table.concat(keptBad, ","))
	local b1, b2, b3 = Base.bossAt(q, 1), Base.bossAt(q, 2), Base.bossAt(q, 3)
	L.check(ctx, "own bought bosses back lowest spot first: the spin boss (was spot 4) on 1, then the crate's in order: pack boss on 2, stolen-back boss on 3",
		b1 and b1.uid == uSpin and b2 and b2.uid == uPack and b3 and b3.uid == uBack and #q.bosses == 3 and #q.crate == 0,
		("%s %s %s"):format(tostring(b1 and b1.uid), tostring(b2 and b2.uid), tostring(b3 and b3.uid)))
	L.check(ctx, "at their levels (7, 3, 9), marks unchanged (spin/pack, buyer me), pads 0 from now",
		b1.level == 7 and b2.level == 3 and b3.level == 9 and b1.bought.source == "spin" and b2.bought.source == "pack" and b3.bought.buyer == me
			and b1.padCash == 0 and b2.padCash == 0 and b1.padStamp >= t0 - 1 and b1.padStamp <= Zones.now() + 0.1)
	L.check(ctx, "removed: the earned bosses (spot and crate) and the bought boss stolen from its buyer",
		not find(q.bosses, uEarned1) and not find(q.crate, uEarnedCrate) and not find(q.bosses, uTheirs) and not find(q.crate, uTheirs))
	L.check(ctx, "after: income x1.5, bag Power x2, 11 spots", Income.mult(p) == 1.5 and Bag.mult(p) == 2 and select(2, Base.unlocked(p)) == 11, ("%s %s %s"):format(s(Income.mult(p)), s(Bag.mult(p)), s(select(2, Base.unlocked(p)))))
	local rec = L.waitFor(function()
		local _, x = Session._test.rawRead(me)
		return type(x) == "table" and x.rebirths == 1 and x
	end, 8)
	L.check(ctx, "one save operation: the store's record already holds the rebirth (rebirths 1, 3 bosses, cash 5,000)", rec and #rec.bosses == 3 and rec.cash == 5000 and #rec.crate == 0, rec and ("%d bosses cash %s"):format(#rec.bosses, s(rec.cash)))
	setPower(20e6)
	local rc = req({ confirmed = true })
	L.check(ctx, "a second request within 5 s: refused 'cooldown'", not rc.ok and rc.reason == "cooldown", rc.reason)
	Session.removeStandIn(stand)
elseif ctx.phase == "b" then
	-- M2-28: the per-player rebirth cooldown lives in memory and survives a Wipe: phase a (the same play session in the gate run) just rebirthed
	task.wait(Config.Rebirth.COOLDOWN_S + 0.2)
	-- overflow with Extra Spots: rebirth 1 -> 2 unlocks 1..12 and 16, 17
	passes({ pass_extra_spots = "on" })
	L.hook(ctx, "SetRebirths", 1)
	task.wait(0.1)
	local uids = {}
	for i = 1, 15 do table.insert(uids, boughtAt("z1_t" .. ((i - 1) % 6 + 1), nil, (i % 20) + 1, "spin")) end
	setPower(17e6)
	local r = req({ confirmed = true })
	local q = prof()
	local spots = {}
	for _, b in ipairs(q.bosses) do table.insert(spots, b.spot) end
	table.sort(spots)
	L.check(ctx, "15 own bought bosses, rebirth 2 with Extra Spots: 14 placed on 1..12, 16, 17; 1 to the crate", r.ok and r.placed == 14 and r.crated == 1 and table.concat(spots, ",") == "1,2,3,4,5,6,7,8,9,10,11,12,16,17" and #q.crate == 1, j(r) .. " " .. table.concat(spots, ","))
	L.check(ctx, "in order: the crate's first 14 on the spots in order, the 15th in the crate", Base.bossAt(q, 1).uid == uids[1] and Base.bossAt(q, 12).uid == uids[12] and Base.bossAt(q, 16).uid == uids[13] and Base.bossAt(q, 17).uid == uids[14] and q.crate[1].uid == uids[15])
	L.check(ctx, "levels kept through the move", Base.bossAt(q, 5).level == (5 % 20) + 1 and q.crate[1].level == (15 % 20) + 1)

	-- the bought-cash rule through buy, earn, spend, rebirth
	fresh()
	Session.addCash(p, 1000, true)
	local a = prof().cash == 1000 and prof().boughtCash == 1000
	Session.addCash(p, 500)
	local b = prof().cash == 1500 and prof().boughtCash == 1000
	Session.spendCash(p, 400)
	local c = prof().cash == 1100 and prof().boughtCash == 1000
	Session.spendCash(p, 300)
	local d = prof().cash == 800 and prof().boughtCash == 800
	Session.addCash(p, 200)
	setPower(11e6)
	task.wait(Config.Rebirth.COOLDOWN_S + 0.2) -- the cooldown from the overflow rebirth above
	local r2 = req({ confirmed = true })
	L.check(ctx, "[M1] bought-cash rule: buy 1000 (1000/1000), earn 500 (1500/1000), spend 400 earned first (1100/1000), spend 300 (800/800), earn 200, rebirth -> cash 800",
		a and b and c and d and r2.ok and prof().cash == 800 and prof().boughtCash == 800, ("%s/%s %s"):format(s(prof().cash), s(prof().boughtCash), tostring(r2.reason)))
	fresh()
	Session.addCash(p, 300)
	setPower(11e6)
	task.wait(Config.Rebirth.COOLDOWN_S + 0.2)
	local r3 = req({ confirmed = true })
	L.check(ctx, "no bought cash: rebirth leaves cash 0 (earned cash never carries)", r3.ok and prof().cash == 0, s(prof().cash) .. " " .. tostring(r3.reason))
elseif ctx.phase == "c" then
	local uid = BoughtMark.grant(p, "z1_t4", "pack")
	local e = uid and find(prof().crate, uid)
	L.check(ctx, "[S20] BoughtMark.grant: the boss in the crate with { source = 'pack', buyer = me }", e and e.bought and e.bought.source == "pack" and e.bought.buyer == me, e and j(e))
	local uid2 = BoughtMark.grant(p, "z2_t2", "spin", { level = 4, extra = function(q) q.spinTickets += 2 end })
	local e2 = uid2 and find(prof().crate, uid2)
	L.check(ctx, "grant with extra(q) runs in the same mutate (the Spin's ticket change)", e2 and e2.level == 4 and prof().spinTickets == 2 and e2.bought.source == "spin")
	local before = snapshot()
	local bad1 = BoughtMark.grant(p, "z1_t1", "gift")
	local bad2 = BoughtMark.grant(p, "z9_t9", "spin")
	local bad3 = BoughtMark.grant(p, "z1_t1", "spin", { extra = function() error("boom") end })
	L.check(ctx, "bad source, bad creature, an erroring extra: refused with nothing applied", bad1 == nil and bad2 == nil and bad3 == nil and #prof().crate == #before.crate)
	-- a plain mutate cannot add, change or clear a mark, nor write boughtCash
	local m1 = Session.mutate(p, function(q) table.insert(q.crate, { uid = "x-1", creatureId = "z1_t1", level = 1, bought = { source = "spin", buyer = me } }) end)
	local m2 = Session.mutate(p, function(q) for _, b in ipairs(q.crate) do if b.uid == uid then b.bought.buyer = 1 end end end)
	local m3 = Session.mutate(p, function(q) for _, b in ipairs(q.crate) do if b.uid == uid then b.bought = nil end end end)
	local m4 = Session.mutate(p, function(q) q.boughtCash = 99 end)
	Session.set(p, "boughtCash", 99)
	L.check(ctx, "[S20] plain mutate: adding, changing or clearing a mark and writing boughtCash all refused; Session.set refuses boughtCash",
		m1 == false and m2 == false and m3 == false and m4 == false and prof().boughtCash == 0 and find(prof().crate, uid).bought.buyer == me)
	-- the hook path (Studio)
	L.hook(ctx, "GrantBoss", "z1_t5,to=3,level=6,bought=spin,buyer=-77")
	task.wait(0.3)
	local h = Base.bossAt(prof(), 3)
	L.check(ctx, "GrantBoss bought=spin,buyer=-77,to=3: placed with that mark (the steal-test seam)", h and h.level == 6 and h.bought and h.bought.buyer == -77 and h.bought.source == "spin", h and j(h))
	local nBefore = #prof().crate
	L.hook(ctx, "GrantBoss", "z1_t5,to=head,bought=pack")
	task.wait(0.3)
	L.check(ctx, "GrantBoss bought= to=head: refused (a carried boss is a beaten one, never bought)", Carry.get(p) == nil and #prof().crate == nBefore)
	-- the refusals above warn by design: those lines are expected, not errors
	local kept = {}
	for _, m in ipairs(ctx.errs) do
		if not (m:find("BoughtMark.grant", 1, true) or m:find("protected", 1, true) or m:find("boom", 1, true) or m:find("never to=head", 1, true)) then table.insert(kept, m) end
	end
	ctx.errs = kept
	-- the static half of S20 (no remote payload or script outside Data/ and BoughtMark writes a mark) is the edit-mode
	-- scan studio/checks/BoughtScan.lua (a running server cannot read script sources)
end

clearCarry()
fresh()
workspace:SetAttribute("HFB_SetRebirths", nil)
L.finish(ctx)
