if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-21: gate row S21, the build plan's M2 "first session" exit check. PLAY MODE, installed into ServerStorage.TmpChecks next to CheckLib
-- (CheckAll "install", then this file added from the sync server). Replaces M1-18's timing script (its numbers are in
-- verification/m1-first-session.md). No real purchase: Shop.setPromptFn replaces Roblox's dialog; the Starter Pack pass is forced off with PassOwned.
--   { phase = "a" }    wiped profile -> Joined, FirstBagPunch, FirstPerfectLanded (the real client taps, AutoTap), ReachedFirstBossPower (SetPower),
--                      FirstFightStarted, FirstBossBeaten (the real fight), carry home, FirstBossPlaced, FirstCashCollected (ClockOffset),
--                      FirstBossUpgraded, the Starter Pack offer once, StarterPackShown. The arrow's step is read from the real client
--                      (Profile.TestReport "arrow") at every stage and must be gone after the first upgrade.
--   { phase = "b" }    (continues "a" in the same play session) FirstStrengthBought, Zone2BossPlaced, the 12 events once and in order, the flags saved
--                      (ForceSave, Leave, Rejoin: nothing fires again), kept through a rebirth.
--   { phase = "all" }  a then b (the default).
-- Walking is a teleport (the carry check starts over); the fight, the taps and the place are the real client unless the log says "fallback".
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Ids = require(RS.Shared.Ids)
local Config, Net, Session, Carry, Base, Income, Bag, Fight = L.Config, L.Net, L.Session, L.Carry, L.Base, L.Income, L.Bag, L.Fight
local Shop = require(SSS.Systems.Shop)
local Funnel = require(SSS.Systems.Funnel)
local StarterPack = require(SSS.Systems.StarterPack)
local Upgrades = require(SSS.Systems.Upgrades)
local Rebirth = require(SSS.Systems.Rebirth)
local Plots = require(SSS.Systems.Plots)

local ctx = L.begin("FirstSession", ARGS)
local p, hrp = ctx.p, ctx.hrp
local function C(label, ok, detail) return L.check(ctx, label, ok, detail) end
local phase = ARGS.phase or "all"
local T0 = os.clock()
local function P(...) print("M221", ...) end
local KEY = "pass_starter_pack"
local function prof() return Session.get(p) end
local function names()
	local out = {}
	for _, e in ipairs(L.TestHooks.reports.funnel or {}) do table.insert(out, e.name) end
	return out
end
local function marked(name) return table.find(names(), name) ~= nil end
local function waitMark(name, secs) return L.waitFor(function() return marked(name) end, secs or 10) end
local function arrow() -- the last "arrow" report from the real client
	local last
	for _, r in ipairs(ctx.reports) do if r.name == "arrow" then last = r.data end end
	return last
end
local function waitArrow(step, secs)
	return L.waitFor(function() local a = arrow(); return a and a.step == step and a.shown and a or nil end, secs or 4)
end
local plot = workspace.Plots.Plot1
local ringPart = workspace.Zones.Z1.Pads.Fixed.Ring
local ringC = ringPart.Position
local function flat(v) return Vector3.new(v.X, 0, v.Z) end

local sent = {}
local origFire = Net.fire
Net.fire = function(family, name, player, payload)
	if player == p and family == "Shop" then table.insert(sent, { name = family .. "." .. name, payload = payload, at = os.clock() }) end
	return origFire(family, name, player, payload)
end
Shop.setPromptFn(function() end)
local function offersSent() local n = 0; for _, e in ipairs(sent) do if e.name == "Shop.Offer" then n += 1 end end; return n end

local function stageA()
	L.waitFor(function() return Session.get(p) ~= nil and Session.state(p) == "live" end, 20)
	task.wait(1)
	L.rootY(ctx)
	L.TestHooks.reports.funnel = nil
	L.hook(ctx, "PassOwned", "pass_starter_pack=off")
	L.hook(ctx, "ReportBeats", true)
	L.hook(ctx, "Wipe", true)
	L.waitFor(function() return L.power(ctx) == 0 and workspace:GetAttribute("HFB_Wipe") == nil end, 3)
	task.wait(0.5)
	local sp = plot.SpawnPoint
	L.tp(ctx, Vector3.new(sp.Position.X, hrp.Position.Y, sp.Position.Z))
	C("1 Joined fired for the wiped profile, nothing else yet", marked("Joined") and #names() == 1 and prof().flags.Joined == true, table.concat(names(), ","))
	local a = waitArrow("bag", 5)
	local bp = plot.BagPad
	C("2 the arrow stands over the own bag pad before the first punch", a ~= nil and math.abs(a.x - bp.Position.X) < 10 and math.abs(a.z - bp.Position.Z) < 10 and a.y > bp.Position.Y, a and (a.step .. " " .. a.x .. "," .. a.y .. "," .. a.z) or "no report")
	-- the real client taps on the bag pad
	L.tp(ctx, L.onPart(ctx, bp))
	L.hook(ctx, "AutoTap", "perfect")
	C("3 FirstBagPunch and FirstPerfectLanded (real taps)", waitMark("FirstBagPunch", 20) and waitMark("FirstPerfectLanded", 20))
	L.hook(ctx, "AutoTap", nil)
	task.wait(1.5) -- let a burst in flight land
	local firstPower = Config.Zones.POWER.z1_t1 or 25
	C("4 the arrow is still on the bag below the first boss's Power", (arrow() or {}).step == "bag" or L.power(ctx) >= firstPower)
	L.hook(ctx, "SetPower", firstPower)
	C("5 ReachedFirstBossPower", waitMark("ReachedFirstBossPower", 5))
	C("6 the arrow moves to the zone 1 boss pad", waitArrow("boss", 4) ~= nil, (arrow() or {}).step)
	-- the real fight
	local ringEdge = flat(ringC) + (flat(ringC) - flat(plot.Entrance.Position)).Unit * -5
	L.tp(ctx, Vector3.new(ringEdge.X, hrp.Position.Y, ringEdge.Z))
	L.hook(ctx, "PadFastBack", 0)
	L.hook(ctx, "AutoTap", "good")
	local started = waitMark("FirstFightStarted", 12)
	if not started then
		L.tp(ctx, Vector3.new(ringC.X, hrp.Position.Y, ringC.Z))
		started = waitMark("FirstFightStarted", 12)
	end
	C("7 FirstFightStarted (the real Huss press in the ring)", started == true)
	C("8 FirstBossBeaten (three Good taps at equal Power)", waitMark("FirstBossBeaten", 40) == true)
	L.hook(ctx, "AutoTap", nil)
	L.waitFor(function() return L.carryState(ctx) == "carrying" end, 5)
	C("9 the arrow points home while the first boss is carried", waitArrow("home", 5) ~= nil, (arrow() or {}).step)
	-- carry home and place on spot 1
	local spot = plot.Spot_1
	L.tp(ctx, L.onPart(ctx, spot))
	L.hook(ctx, "AutoInteract", true)
	local placed = L.waitFor(function() return prof().spots[1] ~= nil end, 8)
	if not placed then
		P("fallback: Base.tryPlace (the client did not place in 8 s)")
		L.note(ctx, "fallback: server-side Base.tryPlace")
		Base.tryPlace(p, 1)
		placed = L.waitFor(function() return prof().spots[1] ~= nil end, 3)
	end
	L.hook(ctx, "AutoInteract", nil)
	C("10 FirstBossPlaced on spot 1", placed ~= nil and marked("FirstBossPlaced"))
	C("11 the arrow moves to the cash pad", waitArrow("cash", 4) ~= nil, (arrow() or {}).step)
	-- cash: the income clock jumps ahead, the player steps on the cash pad
	L.hook(ctx, "ClockOffset", 60)
	task.wait(0.4)
	L.tp(ctx, L.onPart(ctx, plot.CashPad_1))
	C("12 FirstCashCollected", waitMark("FirstCashCollected", 8) == true, "cash " .. L.s(prof().cash))
	L.hook(ctx, "ClockOffset", nil)
	C("13 the arrow moves to the boss for the first upgrade", waitArrow("upgrade", 4) ~= nil, (arrow() or {}).step)
	-- the first upgrade
	local boss = prof().spots[1] and prof().bosses[1]
	local cost = Upgrades.cost(boss.creatureId, boss.level + 1) or 30
	if prof().cash < cost then L.hook(ctx, "SetCash", cost); task.wait(0.3) end
	L.tp(ctx, L.onPart(ctx, plot.Spot_1))
	local offers0 = offersSent()
	local lvl0 = boss.level
	Upgrades.tryUpgrade(p, boss.uid)
	C("14 FirstBossUpgraded (a real upgrade, the level rose)", marked("FirstBossUpgraded") and prof().bosses[1].level == lvl0 + 1)
	local gone = L.waitFor(function() local a = arrow(); return a and a.done and not a.shown and a or nil end, 4)
	C("15 the arrow is gone after the first upgrade (destroyed on the client)", gone ~= nil, (arrow() or {}).step)
	local offer = L.waitFor(function() return offersSent() > offers0 end, 5)
	C("16 the Starter Pack offer was sent once, after the upgrade", offer ~= nil and offersSent() == offers0 + 1 and not marked("StarterPackShown"))
	Upgrades.tryUpgrade(p, boss.uid)
	task.wait(1.3)
	C("17 a second upgrade does not offer again", offersSent() == offers0 + 1)
	C("18 the client's OfferSeen (the screen, after the panel closes) marks StarterPackShown once", StarterPack.offerSeen(p, { key = KEY }) == true and StarterPack.offerSeen(p, { key = KEY }) == false and marked("StarterPackShown"))
end

local function stageB()
	-- FirstStrengthBought at the bag sign
	L.hook(ctx, "SetCash", 5000)
	task.wait(0.3)
	L.tp(ctx, L.onPart(ctx, plot.BagPad))
	task.wait(0.3)
	Bag.buyStrength(p, {})
	C("19 FirstStrengthBought (Bag.BuyStrength, level 2)", marked("FirstStrengthBought") and prof().strengthLevel == 2, tostring(prof().strengthLevel))
	-- zone 2: a zone 2 boss carried home and placed
	L.hook(ctx, "SetZonesBeaten", "1")
	L.hook(ctx, "SetPower", 250)
	task.wait(0.3)
	L.hook(ctx, "GrantBoss", "z2_t1,to=head")
	L.waitFor(function() return L.carryState(ctx) == "carrying" end, 4)
	local free = Base.freeSpot(p, prof()) or 2
	L.tp(ctx, L.onPart(ctx, plot["Spot_" .. free]))
	L.hook(ctx, "AutoInteract", true)
	local placed = L.waitFor(function() return marked("Zone2BossPlaced") end, 8)
	if not placed then
		P("fallback: Base.tryPlace (the client did not place in 8 s)")
		L.note(ctx, "fallback: server-side Base.tryPlace")
		Base.tryPlace(p, free)
		placed = L.waitFor(function() return marked("Zone2BossPlaced") end, 3)
	end
	L.hook(ctx, "AutoInteract", nil)
	C("20 Zone2BossPlaced", placed == true)
	-- the whole funnel
	local got = names()
	local seen, dup = {}, false
	for _, n in ipairs(got) do if seen[n] then dup = true end seen[n] = true end
	C("21 all 12 events, each once", #got == 12 and not dup, table.concat(got, ","))
	local inOrder = #got == #Ids.FUNNEL
	for i, n in ipairs(Ids.FUNNEL) do if got[i] ~= n then inOrder = false end end
	C("22 in the brief's order (Joined ... Zone2BossPlaced)", inOrder, table.concat(got, ","))
	local allFlags = true
	for _, n in ipairs(Ids.FUNNEL) do if prof().flags[n] ~= true then allFlags = false end end
	C("23 all 12 are saved as flags on the profile", allFlags)
	local ts = {}
	for _, e in ipairs(L.TestHooks.reports.funnel or {}) do table.insert(ts, ("%s=%.0f"):format(e.name, e.t)) end
	P("REAL TIMES (s since the wipe, scripted: teleports, income clock jumped 60 s): " .. table.concat(ts, " "))
	-- repeats do nothing
	local n0 = #names()
	for _, n in ipairs(Ids.FUNNEL) do Funnel.mark(p, n) end
	C("24 marking every event again logs nothing", #names() == n0)
	-- saved and kept: leave, rejoin, rebirth
	L.hook(ctx, "ForceSave", true)
	task.wait(1)
	if Carry.get(p) then Carry.lose(p, "check") end
	L.hook(ctx, "Leave", true)
	L.waitFor(function() return Session.get(p) == nil end, 10)
	L.hook(ctx, "Rejoin", true)
	L.waitFor(function() return Session.get(p) ~= nil and Session.state(p) == "live" end, 15)
	task.wait(1)
	local st = Session.state(p)
	local kept = true
	for _, n in ipairs(Ids.FUNNEL) do if not prof() or prof().flags[n] ~= true then kept = false end end
	C("25 after Leave and Rejoin the flags are still there and no event fired again", kept and #names() == n0, st .. " " .. #names())
	L.hook(ctx, "SetPower", Config.Rebirth.REQUIRED[1] + 1)
	task.wait(0.3)
	local rr = Rebirth.request(p, { confirmed = true })
	task.wait(0.5)
	local kept2 = true
	for _, n in ipairs(Ids.FUNNEL) do if prof().flags[n] ~= true then kept2 = false end end
	C("26 the flags survive a rebirth, and Joined / the rest do not fire again", rr and rr.ok and kept2 and #names() == n0, rr and tostring(rr.reason))
end

local ok, err = xpcall(function()
	if phase == "a" or phase == "all" then stageA() end
	if phase == "b" or phase == "all" then stageB() end
end, debug.traceback)
if not ok then C("the check ran to the end", false, tostring(err):sub(1, 500)) end
pcall(function()
	if Carry.get(p) then Carry.lose(p, "check") end
	workspace:SetAttribute("HFB_Wipe", true)
	task.wait(0.4)
end)
Shop.setPromptFn(nil)
Net.fire = origFire
L.finish(ctx)
