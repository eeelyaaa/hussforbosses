if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-18: gate row S17's spin part and S20's spin mark. PLAY MODE, installed into ServerStorage.TmpChecks next to
-- CheckLib.
--   { phase = "a" }  the one odds table (40/28/17/10/4/1, total 100, in Shared so the screen reads the same module);
--                    100,000 server rolls within Config.Spin.TOLERANCE (a fixed seed, the SpinSeed hook, and unseeded);
--                    the server rolls from that table; the zone picker's list is the saved zonesBeaten (empty: refused,
--                    the screen's "Beat a boss first"); tickets; restricted; malformed zones; every outcome gives a boss
--                    with the spin mark and the buyer, in the crate, ticket -1 in the same mutate, saved at once (S11).
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Ids = require(RS.Shared.Ids)
local SpinTable = require(RS.Shared.SpinTable)
local Spin = require(SSS.Systems.Spin)
local BoughtMark = require(SSS.Systems.BoughtMark)
local Config = L.Config
local Session, Carry = L.Session, L.Carry
local s = L.s

local ctx = L.begin("Spin", ARGS)
local p = ctx.p
local function C(label, ok, detail) return L.check(ctx, label, ok, detail) end
local function prof() return Session.get(p) end

local origPick = SpinTable.pick
local origSave = Session.save
local saves = 0

local ok, err = pcall(function()
	if Carry.get(p) then Carry.lose(p, "check") end
	L.hook(ctx, "Wipe", true)
	task.wait(0.6)
	L.hook(ctx, "PolicyRandom", "off")
	task.wait(0.1)
	-- the table
	local want = { 40, 28, 17, 10, 4, 1 }
	local okT = #SpinTable.ODDS == 6 and SpinTable.total() == 100
	for i, o in ipairs(SpinTable.ODDS) do okT = okT and o.tier == i and o.percent == want[i] end
	C("1 one odds table: tiers 1..6 at 40/28/17/10/4/1, total 100", okT)
	C("2 the table lives in ReplicatedStorage.Shared (the Spin screen requires the same module)", RS.Shared:FindFirstChild("SpinTable") ~= nil and RS.Shared.SpinTable:IsA("ModuleScript"))
	C("3 pick covers [0, 1): no roll gives nothing", SpinTable.pick(0) == 1 and SpinTable.pick(0.3999) == 1 and SpinTable.pick(0.4) == 2 and SpinTable.pick(0.99) == 6 and SpinTable.pick(0.999999) == 6)
	-- distribution
	local N = Config.Spin.CHECK_ROLLS
	local function within(counts)
		local worst, parts = 0, {}
		for i, o in ipairs(SpinTable.ODDS) do
			local share = counts[o.tier] / N * 100
			worst = math.max(worst, math.abs(share - o.percent))
			table.insert(parts, ("%d:%.2f"):format(o.tier, share))
		end
		return worst <= Config.Spin.TOLERANCE, ("worst %.3f pts; %s"):format(worst, table.concat(parts, " "))
	end
	local t0 = os.clock()
	local okA, dA = within(Spin.distribution(N, 20261126))
	C(("4 %d server rolls (seed 20261126) within %.1f points of the table"):format(N, Config.Spin.TOLERANCE), okA, dA .. (" (%.2f s)"):format(os.clock() - t0))
	L.hook(ctx, "SpinSeed", 777)
	task.wait(0.05)
	local okB, dB = within(Spin.distribution(N))
	C("5 the same through the live Random with the SpinSeed hook", okB, dB)
	L.hook(ctx, "SpinSeed", nil)
	task.wait(0.05)
	local okC, dC = within(Spin.distribution(N))
	C("6 and unseeded", okC, dC)
	SpinTable.pick = function() return 6 end
	local forced = Spin.rollTier(Random.new())
	SpinTable.pick = origPick
	C("7 the server's roll goes through Shared/SpinTable (replacing pick changes the roll)", forced == 6)
	-- the zone picker and the refusals
	Session.save = function(pl, reason)
		if pl == p and reason == "spin" then saves += 1 end
		return origSave(pl, reason)
	end
	L.hook(ctx, "SetTickets", 3)
	task.wait(0.3)
	C("8 setup: no zone beaten yet, 3 tickets", #prof().zonesBeaten == 0 and prof().spinTickets == 3)
	C("9 no zone beaten: zone 1 refused 'zone' (the screen shows zone 1 locked, 'Beat a boss first'), nothing spent", Spin.trySpin(p, 1) == "zone" and prof().spinTickets == 3 and #prof().crate == 0)
	L.hook(ctx, "SetZonesBeaten", "1,3")
	task.wait(0.3)
	C("10 setup: zones beaten 1 and 3", table.find(prof().zonesBeaten, 1) ~= nil and table.find(prof().zonesBeaten, 3) ~= nil and #prof().zonesBeaten == 2)
	C("11 a zone not beaten (2): 'zone'", Spin.trySpin(p, 2) == "zone" and prof().spinTickets == 3)
	local bad = { 7, 0, "1", 1.5, 0 / 0, math.huge }
	local allBad = true
	for _, z in ipairs(bad) do if Spin.trySpin(p, z) ~= "bad" then allBad = false end end
	C("12 malformed zones (7, 0, '1', 1.5, NaN, inf): 'bad', nothing changed", allBad and prof().spinTickets == 3 and #prof().crate == 0)
	local g0 = #BoughtMark.stats.grants
	local r = Spin.trySpin(p, 3)
	local last = Spin.stats.results[#Spin.stats.results].payload
	local b = prof().crate[1]
	C("13 zone 3: one boss of zone 3 to the crate, ticket 3 -> 2", r == nil and last.ok and b and Ids.parseCreature(b.creatureId) == 3 and b.creatureId == last.creatureId and prof().spinTickets == 2, last.creatureId)
	C("14 the boss has the spin mark with the buyer (through BoughtMark)", b and b.bought and b.bought.source == "spin" and b.bought.buyer == p.UserId and #BoughtMark.stats.grants == g0 + 1)
	task.wait(0.5)
	C("15 S11: the spin is saved at once", saves >= 1, saves)
	L.hook(ctx, "PolicyRandom", "on")
	task.wait(0.2)
	C("16 restricted: 'restricted', nothing spent", Spin.trySpin(p, 1) == "restricted" and prof().spinTickets == 2)
	L.hook(ctx, "PolicyRandom", "off")
	task.wait(0.2)
	-- every outcome gives a boss
	L.hook(ctx, "SetTickets", 6)
	task.wait(0.3)
	local allTiers = true
	for tier = 1, 6 do
		SpinTable.pick = function() return tier end
		local rr = Spin.trySpin(p, 1)
		local pl = Spin.stats.results[#Spin.stats.results].payload
		if rr ~= nil or pl.creatureId ~= Ids.creature(1, tier) or pl.tier ~= tier then allTiers = false end
	end
	SpinTable.pick = origPick
	C("17 each of the six outcomes gives its boss (z1_t1..z1_t6), tickets 6 -> 0", allTiers and prof().spinTickets == 0 and #prof().crate == 7)
	C("18 no tickets: 'tickets'", Spin.trySpin(p, 1) == "tickets" and #prof().crate == 7)
	local marks = true
	for _, cb in ipairs(prof().crate) do if not (cb.bought and cb.bought.source == "spin" and cb.bought.buyer == p.UserId) then marks = false end end
	C("19 every spin boss carries { source = spin, buyer }", marks)
end)
if not ok then C("the check ran to the end", false, tostring(err)) end
SpinTable.pick = origPick
Session.save = origSave
workspace:SetAttribute("HFB_Wipe", true)
task.wait(0.4)
L.finish(ctx)
