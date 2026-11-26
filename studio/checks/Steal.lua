if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-15: gate rows S10 / S16 (stealing) and the build plan's M2 exit check "stealing". PLAY MODE, installed into
-- ServerStorage.TmpChecks next to CheckLib. A stand-in second player through the Systems/Plots seam
-- (Session.standIn, memory store only). Two check plots are cloned from Plot1 as PlotId 2 and 8 and removed at the end.
--   { phase = "a" }  the real player steals FROM a stand-in: fill order; refusals (bad args, own plot, range, shield,
--                    crate boss, a second hold); the policy guard (bought boss locked when either flag is false or the
--                    call fails, earned boss never; Steal.Flag per viewer); the 2.0 s hold timed by the server, 1.0 s
--                    with Quick Hands; moving away cancels; the lift (lock, alert, carry origin stolen); teleport home,
--                    a hazard, a respawn and the over-fast walk (min travel) return it; Grab refused; a real success
--                    keeps level and bought mark, pays the owner's pad, uid in one profile and one record; the boss is a
--                    crate carry the thief places; 60 s safe time.
--   { phase = "b" }  a stand-in steals FROM the real player: the owner's spot actions refused 'locked'; the owner's
--                    punch cancels a hold, returns a carried boss (stun), the 0.8 s gap, range; chase speed 20; Iron Grip
--                    (stagger, then a drop within 10 s; a hit after 10 s staggers again; nothing against a hazard or
--                    the shield); the shield rising returns a boss still inside and pushes the thief out.
--   { phase = "c" }  a stand-in steals from the real player and walks home; SaveFailBetween errors between the owner's
--                    and the thief's write: the uid in exactly one profile, in no record until the thief's next write
--                    (the known window, Data/Transfer), then in exactly one; the hook is one-shot.
-- Every pass forced off with PassOwned first. Leaves the profile wiped, the stand-ins removed and every hook cleared.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Carry, Base, Session, Zones = L.Config, L.Carry, L.Base, L.Session, L.Zones
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Steal = require(SSS.Systems.Steal)
local Shield = require(SSS.Systems.Shield)
local Plots = require(SSS.Systems.Plots)
local BoughtMark = require(SSS.Systems.BoughtMark)
local Rebirth = require(SSS.Systems.Rebirth)
local Upgrades = require(SSS.Systems.Upgrades)
local Transfer = require(SSS.Data.Transfer)
local Ids = require(RS.Shared.Ids)
local TestHooks = L.TestHooks
local seam = Plots.seam
local s = L.s

local ctx = L.begin("Steal", ARGS)
local p = ctx.p
local function C(label, ok, detail) return L.check(ctx, label, ok, detail) end

local function passes(extra)
	local parts = {}
	for _, k in ipairs(Ids.SHOP_KEYS) do
		if Ids.isPass(k) then table.insert(parts, k .. "=" .. ((extra and extra[k]) or "off")) end
	end
	L.hook(ctx, "PassOwned", table.concat(parts, ","))
	task.wait(0.1)
end

local PlotsRoot = workspace.Plots
local Plot1 = PlotsRoot.Plot1
local made = {}
local function clonePlot(id, dz)
	local old = PlotsRoot:FindFirstChild("CheckPlot" .. id)
	if old then old:Destroy() end
	local m = Plot1:Clone()
	m.Name = "CheckPlot" .. id
	m:SetAttribute("PlotId", id)
	m:SetAttribute("OwnerUserId", 0)
	m:PivotTo(Plot1:GetPivot() + Vector3.new(0, 0, dz))
	m.Parent = PlotsRoot
	table.insert(made, m)
	return m
end

local stands = {}
local function addStand(id, opts)
	local f = seam.addPlayer(id, opts or { shield = "ready" })
	stands[id] = f
	return f
end

local function clearCarry() if Carry.get(p) then Carry.lose(p, "check") end; task.wait(0.05) end
local function fresh()
	clearCarry()
	L.hook(ctx, "Wipe", true)
	task.wait(0.5)
	passes()
	L.hook(ctx, "PolicyTrading", "on")
	Shield.forceState(Plot1, "ready")
end

local function put(who, cid, spot, level, padCash)
	local uid = Session.newUid(who)
	local ok = Session.mutate(who, function(q)
		table.insert(q.bosses, { uid = uid, creatureId = cid, level = level or 1, spot = spot, padCash = padCash or 0, padStamp = Zones.now() })
		table.sort(q.bosses, function(x, y) return x.spot < y.spot end)
	end)
	assert(ok, "put failed")
	return uid
end
local function bossOf(who, uid)
	local q = Session.get(who)
	for _, b in ipairs(q.bosses) do if b.uid == uid then return b end end
	return nil
end
local function inCrate(who, uid)
	local q = Session.get(who)
	for _, b in ipairs(q.crate) do if b.uid == uid then return b end end
	return nil
end
local function countIn(rec, uid)
	local n = 0
	if type(rec) ~= "table" then return 0 end
	for _, list in ipairs({ rec.bosses or {}, rec.crate or {} }) do
		for _, b in ipairs(list) do if b.uid == uid then n += 1 end end
	end
	return n
end

-- a raw record (Studio check helper): the real player's Studio store or a stand-in's memory store
local function rec(id) local okR, a, b = pcall(Session._test.rawRead, id); if not okR then return nil end; return type(a) == "table" and a or b end

local function resIdx() return #Steal.stats.results end
-- the first result for userId after index i0 with that state (any state when nil)
local function resAfter(i0, userId, state)
	for i = i0 + 1, #Steal.stats.results do
		local r = Steal.stats.results[i]
		if r.userId == userId and (state == nil or r.state == state) then return r end
	end
	return nil
end
local function waitRes(i0, userId, state, timeout)
	return L.waitFor(function() return resAfter(i0, userId, state) end, timeout or 3)
end

-- a standing position next to a plot's spot (flat offset towards the aisle), for the real player or a stand-in
local function nearSpot(plot, i, dx)
	local part = Base.spotPart(plot, i)
	return part.Position + Vector3.new(dx or 0, part.Size.Y / 2 + L.rootY(ctx), 0)
end
local function moveP(pos) L.tp(ctx, pos); task.wait(0.05) end
local function moveS(f, pos) seam.moveTo(f, pos); task.wait(0.05) end
local function inside(plot, x, y)
	return seam.plotPoint(plot, x, y, Base.spotPart(plot, 1).Position.Y + 0.5 + L.rootY(ctx))
end

-- walks home the way a player must: round the outside to the plot's entrance, then in (anchored PivotTo steps pass
-- through fences, so a straight line would enter through the side fence, which no player can)
local function walkHome(who, plot, speed, viaYard)
	local r = who.Character.HumanoidRootPart
	local y = r.Position.Y
	if viaYard then
		if not seam.walkTo(who, Vector3.new(130, y, r.Position.Z), speed) then return false end
	end
	for _, pt in ipairs({ { 60, -10 }, { 25, -3 }, { 25, 4 } }) do
		local w = seam.plotPoint(plot, pt[1], pt[2], y)
		if not seam.walkTo(who, w, speed) then return false end
	end
	return true
end

local ok, err = pcall(function()
	fresh()
	local P2 = clonePlot(2, -60)
	local P8 = clonePlot(8, -120)
	task.wait(0.2)

	if ctx.phase == "a" then
		-- ---------------------------------------------------------------- plots
		local list = {}
		for id = 1, 8 do table.insert(list, { PlotId = id, OwnerUserId = 0 }) end
		local order = {}
		for _ = 1, 8 do local m = Plots.pick(list); table.insert(order, m.PlotId); m.OwnerUserId = 1 end
		C("1 fill order for 8 plots", table.concat(order, ",") == "1,8,4,5,2,7,3,6", table.concat(order, ","))
		C("2 no free plot: pick is nil (S8: the base remotes then refuse 'state')", Plots.pick(list) == nil)
		list[7].OwnerUserId = 0
		C("3 a freed plot is picked again", Plots.pick(list).PlotId == 7)
		C("4 the real player owns Plot1 (Plots.of)", Plots.of(p) == Plot1)
		local A = addStand(-51)
		C("5 stand-in -51 gets plot 8 (fill order), not the lower free id 2", Plots.of(A) == P8, Plots.of(A) and Plots.of(A).Name)
		local B = addStand(-52)
		C("6 the next stand-in gets plot 2", Plots.of(B) == P2)
		C("7 Plots.ownerOf / byUserId find the stand-in", Plots.ownerOf(P8) == A and Plots.byUserId(-51) == A)
		local st = seam.removePlayer(B)
		stands[-52] = nil
		C("8 removing a stand-in frees its plot", P2:GetAttribute("OwnerUserId") == 0 and Plots.ownerOf(P2) == nil, st)
		local okId = pcall(seam.addPlayer, 5, {})
		C("9 the seam refuses a real-looking user id (S9)", okId == false)

		-- ---------------------------------------------------------------- the stand-in's bosses
		local uE = put(A, "z1_t2", 3, 4, 50)
		BoughtMark.grantFromHook(A, { creatureId = "z1_t3", bought = "spin", buyer = "-51", to = "5", level = "2" })
		local uB
		for _, b in ipairs(Session.get(A).bosses) do if b.spot == 5 then uB = b.uid end end
		local uC = Session.newUid(A)
		Session.mutate(A, function(q) table.insert(q.crate, { uid = uC, creatureId = "z1_t1", level = 1 }) end)
		C("10 setup: earned boss on spot 3 (level 4), bought spin boss on spot 5, one in the crate", uE ~= nil and uB ~= nil and inCrate(A, uC) ~= nil)

		-- ---------------------------------------------------------------- refusals
		local function hold(plotId, uid) local i = resIdx(); local why = Steal.tryHold(p, plotId, uid); return why, resAfter(i, p.UserId) end
		moveP(nearSpot(P8, 3, 3))
		local w1 = hold("8", uE)
		local w2 = hold(8, 12345)
		local w3 = hold(8.5, uE)
		local w4 = hold(8, string.rep("x", 60))
		C("11 malformed HoldStart refused 'state' (plotId string, uid number, plotId 8.5, uid 60 bytes)", w1 == "state" and w2 == "state" and w3 == "state" and w4 == "state")
		C("12 own plot refused", hold(1, uE) == "state")
		C("13 a crate boss cannot be stolen", hold(8, uC) == "state")
		C("14 an unknown uid refused", hold(8, "nope") == "state")
		Shield.forceState(P8, "up")
		C("15 shield up: refused 'shield'", hold(8, uE) == "shield")
		Shield.forceState(P8, "ready")
		moveP(nearSpot(P8, 3, 9))
		local wr, rr = hold(8, uE)
		C("16 9 studs from the spot: refused 'range' (Steal.Result refused)", wr == "range" and rr and rr.state == "refused" and rr.reason == "range")
		moveP(nearSpot(P8, 3, 3))
		C("17 every refusal left the boss unlocked and on its spot", not Steal.isLocked(uE) and bossOf(A, uE) and bossOf(A, uE).spot == 3)

		-- ---------------------------------------------------------------- the policy guard (TEAM CALL 38)
		local bb = bossOf(A, uB)
		moveP(nearSpot(P8, 5, 3))
		L.hook(ctx, "PolicyTrading", "off")
		task.wait(0.2)
		C("18 trading off for both: the bought boss is refused 'locked'", hold(8, uB) == "locked")
		C("19 Steal.flagFor shows it greyed for this viewer", Steal.flagFor(p, A, bb) == true)
		L.hook(ctx, "PolicyTrading", "on,-51:off")
		task.wait(0.2)
		C("20 only the OWNER's flag false: still locked (for everyone)", hold(8, uB) == "locked" and Steal.flagFor(p, A, bb) == true)
		L.hook(ctx, "PolicyTrading", "on," .. p.UserId .. ":fail")
		task.wait(0.2)
		C("21 the thief's call failed: locked", hold(8, uB) == "locked")
		local sentLocked
		for i = #Steal.stats.flags, 1, -1 do local f = Steal.stats.flags[i]; if f.viewer == p.UserId and f.uid == uB then sentLocked = f.locked; break end end
		C("22 Steal.Flag sent to the viewer: locked=true", sentLocked == true)
		moveP(nearSpot(P8, 3, 3))
		local we = hold(8, uE)
		C("23 an earned boss stays stealable with the flags off", we == nil and Steal.isLocked(uE))
		Steal.tryCancel(p)
		task.wait(0.05)
		L.hook(ctx, "PolicyTrading", "on")
		task.wait(0.3)
		local sentOpen
		for i = #Steal.stats.flags, 1, -1 do local f = Steal.stats.flags[i]; if f.viewer == p.UserId and f.uid == uB then sentOpen = f.locked; break end end
		C("24 both flags true: Flag re-sent locked=false, flagFor false", sentOpen == false and Steal.flagFor(p, A, bb) == false)

		-- ---------------------------------------------------------------- the hold
		local i0 = resIdx()
		local t0 = os.clock()
		local wh = hold(8, uE)
		local rH = resAfter(i0, p.UserId, "held")
		C("25 HoldStart accepted: 'held' to thief and owner with holdEndsAt = +2.0", wh == nil and rH ~= nil and resAfter(i0, -51, "held") ~= nil)
		C("26 the uid is locked; the owner cannot rebirth (Rebirth.refusal 'state')", Steal.isLocked(uE) and (function() Session.set(A, "power", 1e12); return Rebirth.refusal(A) == "state" end)())
		C("27 a second HoldStart on it is refused 'state'", hold(8, uE) == "state")
		task.wait(1.2)
		C("28 at 1.2 s: still held, not carried", Steal.holdOf(p) ~= nil and Carry.get(p) == nil)
		local rC, dt = waitRes(i0, p.UserId, "carried", 2)
		local took = os.clock() - t0
		C("29 lifted by the server's own timer at about 2.0 s", rC ~= nil and math.abs(took - 2.0) < 0.2, s(took))
		local c = Carry.get(p)
		C("30 the carry: origin stolen, stolenFrom 8, level 4, the right uid", c and c.origin == "stolen" and c.stolenFrom == 8 and c.level == 4 and c.uid == uE)
		local al = Steal.stats.alerts[#Steal.stats.alerts]
		C("31 the owner's Steal.Alert from the moment of the lift (thief id, bought=false)", al and al.owner == -51 and al.uid == uE and al.thief == p.UserId and al.bought == false)
		C("32 the boss is still in the owner's profile at spot 3 (not saved anywhere else)", bossOf(A, uE) and bossOf(A, uE).spot == 3 and countIn(Session.get(p), uE) == 0)
		C("33 Carry.Grab is refused for a stolen carry", Carry.tryGrab(p, uE) == "state")
		-- a teleport home
		local i1 = resIdx()
		moveP(inside(Plot1, 25, 30))
		local rT = waitRes(i1, p.UserId, "returned", 1.5)
		C("34 teleport home: the boss goes back ('returned', speed)", rT and rT.reason == "speed" and Carry.get(p) == nil and not Steal.isLocked(uE) and bossOf(A, uE).spot == 3)

		-- moving away cancels the hold
		moveP(nearSpot(P8, 3, 3))
		local i2 = resIdx()
		hold(8, uE)
		task.wait(0.3)
		moveP(nearSpot(P8, 3, 3 + 8))
		local rM = waitRes(i2, p.UserId, "cancelled", 1)
		C("35 moving 8 studs away cancels the hold ('moved'), lock gone", rM and rM.reason == "moved" and not Steal.isLocked(uE))
		-- HoldCancel
		moveP(nearSpot(P8, 3, 3))
		hold(8, uE)
		C("36 HoldCancel cancels only the caller's own hold", Steal.tryCancel(A) == "state" and Steal.tryCancel(p) == nil and not Steal.isLocked(uE))

		-- Quick Hands
		passes({ pass_quick_hands = "on" })
		local i3 = resIdx()
		local t3 = os.clock()
		hold(8, uE)
		local rQ = waitRes(i3, p.UserId, "carried", 2)
		local tq = os.clock() - t3
		C("37 Quick Hands: lifted at about 1.0 s", rQ ~= nil and math.abs(tq - 1.0) < 0.2, s(tq))
		passes()
		-- a hazard
		local i4 = resIdx()
		Carry.drop(p, ctx.hrp.Position, "hazard")
		local rZ = waitRes(i4, p.UserId, "returned", 1)
		C("38 a hazard hit returns it at once (never 'dropped' on the lane)", rZ and rZ.reason == "hazard" and Carry.get(p) == nil and bossOf(A, uE).spot == 3)
		-- a respawn
		moveP(nearSpot(P8, 3, 3))
		hold(8, uE)
		waitRes(resIdx() - 1, p.UserId, "carried", 3)
		local i5 = resIdx()
		Carry.lose(p, "respawn")
		local rR = waitRes(i5, p.UserId, "returned", 1)
		C("39 a fall or reset (respawn) returns it", rR ~= nil and not Steal.isLocked(uE) and bossOf(A, uE).spot == 3)

		-- home faster than the carry speed allows, without a teleport step: min travel ([M2-02 M7])
		moveP(nearSpot(P8, 3, 3))
		local factor0 = Config.Steal.TRAVEL_FACTOR
		Config.Steal.TRAVEL_FACTOR = 1.0 -- runtime override: the full straight-line time at carry speed
		local i6 = resIdx()
		hold(8, uE)
		waitRes(i6, p.UserId, "carried", 3)
		local o = Steal.offOf(p)
		local i7 = resIdx()
		local tp0, os0 = Carry.stats.teleports, Carry.stats.overSpeed
		walkHome(p, Plot1, 16.4, false)
		local rS = waitRes(i7, p.UserId, "returned", 1)
		Config.Steal.TRAVEL_FACTOR = factor0
		C("40 walking home at 16.4 studs/s (within the 1 s window) is refused by the minimum travel time ('speed')", rS and rS.reason == "speed" and bossOf(A, uE) ~= nil and Carry.stats.teleports == tp0 and Carry.stats.overSpeed == os0,
			(o and s(o.minTravel) or "-") .. " carry flags " .. s(Carry.stats.teleports - tp0) .. "/" .. s(Carry.stats.overSpeed - os0))

		-- ---------------------------------------------------------------- a real success (the bought boss)
		Session.mutate(A, function(q) for _, b in ipairs(q.bosses) do if b.uid == uB then b.padCash = 75; b.padStamp = Zones.now() end end end)
		local cashA0 = Session.get(A).cash
		moveP(nearSpot(P8, 5, 3))
		local i8 = resIdx()
		hold(8, uB)
		waitRes(i8, p.UserId, "carried", 3)
		local al2 = Steal.stats.alerts[#Steal.stats.alerts]
		C("41 the bought boss lifts with both flags true; the alert says bought", al2 and al2.uid == uB and al2.bought == true)
		local tp1, os1 = Carry.stats.teleports, Carry.stats.overSpeed
		local walked = walkHome(p, Plot1, nil, false)
		local rOk = waitRes(i8, p.UserId, "success", 4)
		local seen = {}
		for k = i8 + 1, #Steal.stats.results do local r = Steal.stats.results[k]; table.insert(seen, s(r.userId) .. ":" .. tostring(r.state) .. "/" .. tostring(r.reason)) end
		C("42 carried home at carry speed: 'success' to thief and owner", walked and rOk ~= nil and resAfter(i8, -51, "success") ~= nil,
			tostring(walked) .. " " .. table.concat(seen, ",") .. " saving " .. tostring(Session.isSaving(A)) .. "/" .. tostring(Session.isSaving(p)) .. " state " .. tostring(Session.state(A)) .. " carry flags " .. s(Carry.stats.teleports - tp1) .. "/" .. s(Carry.stats.overSpeed - os1))
		L.waitFor(function() local tr = Steal.stats.transfers[#Steal.stats.transfers]; return tr and tr.uid == uB end, 5)
		task.wait(0.2)
		local mine = inCrate(p, uB)
		C("43 the boss is the thief's: in the crate with level 2 and the mark { spin, buyer -51 } unchanged", mine and mine.level == 2 and mine.bought and mine.bought.source == "spin" and mine.bought.buyer == -51)
		C("44 and gone from the owner's profile, with the owner's transferNote", bossOf(A, uB) == nil and (function() for _, n in ipairs(Session.get(A).transferNote) do if n.uid == uB and n.to == p.UserId then return true end end return false end)())
		C("45 the owner's pad cash (75) was paid to the owner", Session.get(A).cash - cashA0 >= 75, s(Session.get(A).cash - cashA0))
		local tr = TestHooks.reports.transfer
		C("46 written owner first then thief, nothing pending", tr and tr.uid == uB and tr.pending == false, tr and (tostring(tr.owner) .. "/" .. tostring(tr.thief)))
		local nO, nT = countIn(rec(-51), uB), countIn(rec(p.UserId), uB)
		C("47 the uid is in exactly one record (the thief's)", nO == 0 and nT == 1, s(nO) .. "/" .. s(nT))
		local c2 = Carry.get(p)
		C("48 still on the thief's head as a crate carry", c2 and c2.origin == "crate" and c2.uid == uB and c2.stolenFrom == nil)
		local spotFree = Base.freeSpot(p, Session.get(p))
		moveP(nearSpot(Plot1, spotFree, 0))
		local wp = Base.tryPlace(p, spotFree)
		local placed = bossOf(p, uB)
		C("49 the thief places it like any carried boss; the mark stays", wp == nil and placed and placed.spot == spotFree and placed.bought and placed.bought.buyer == -51)
		local su = Steal.safeUntil(uB)
		C("50 60 s safe time after the steal", su and math.abs(su - Shield.clock() - 60) < 15, su and s(su - Shield.clock()))
		moveS(A, nearSpot(Plot1, spotFree, 3))
		C("51 the stand-in cannot steal it back inside the safe time ('safe')", Steal.tryHold(A, 1, uB) == "safe")
		L.hook(ctx, "ShieldClock", 61)
		task.wait(0.1)
		Shield.forceState(Plot1, "ready")
		local wBack = Steal.tryHold(A, 1, uB)
		C("52 after 60 s it can be held again (by an owner whose flags are true)", wBack == nil, wBack)
		Steal.tryCancel(A)
		L.hook(ctx, "ShieldClock", nil)
	elseif ctx.phase == "b" then
		local T = addStand(-61)
		local u2 = put(p, "z1_t2", 2, 3, 0)
		Session.set(p, "power", 1e12)
		moveS(T, nearSpot(Plot1, 2, 3))
		moveP(nearSpot(Plot1, 2, -4))
		local i0 = resIdx()
		C("1 the stand-in holds the real player's boss", Steal.tryHold(T, 1, u2) == nil and Steal.isLocked(u2))
		C("2 owner Pick Up refused 'locked'", Base.tryPickUp(p, 2) == "locked")
		Session.set(p, "cash", 1e6)
		local wu = Upgrades.tryUpgrade(p, u2)
		C("3 owner Upgrade refused 'locked' while held (cash and range fine)", wu == "locked", wu)
		C("4 owner Rebirth refused 'state'", Rebirth.refusal(p) == "state")
		local wp = Steal.tryPunch(p, -61)
		local rP = waitRes(i0, -61, "cancelled", 1)
		C("5 the owner's punch cancels the hold ('punched')", wp == nil and rP and rP.reason == "punched" and not Steal.isLocked(u2))
		C("6 a second punch inside 0.8 s is refused (gap)", Steal.tryPunch(p, -61) == "gap")
		task.wait(0.85)
		C("7 a punch at nobody holding is refused", Steal.tryPunch(p, -61) == "notYours")
		-- lift
		local i1 = resIdx()
		Steal.tryHold(T, 1, u2)
		waitRes(i1, -61, "carried", 3)
		task.wait(0.15)
		C("8 lifted: the owner chases at 20 studs/s", ctx.hum.WalkSpeed == 20, ctx.hum.WalkSpeed)
		C("9 Steal.alertOn(owner) for the Base / Shop seams", Steal.alertOn(p) == true)
		moveS(T, nearSpot(Plot1, 2, 3 + 12))
		C("10 a punch from 12+ studs is refused 'range'", Steal.tryPunch(p, -61) == "range")
		moveS(T, nearSpot(Plot1, 2, -2))
		task.wait(0.05)
		local i2 = resIdx()
		local wd = Steal.tryPunch(p, -61)
		local rD = waitRes(i2, -61, "dropped", 1)
		task.wait(0.1)
		C("11 a hit: 'dropped', the boss back on its spot, unlocked", wd == nil and rD and rD.reason == "punched" and bossOf(p, u2).spot == 2 and not Steal.isLocked(u2) and Carry.get(T) == nil)
		C("12 the thief is stunned 1.5 s (WalkSpeed 0) and cannot hold", Steal.stunned(T) and T.Character.Humanoid.WalkSpeed == 0 and Steal.tryHold(T, 1, u2) == "state")
		C("13 the owner's chase speed ends", ctx.hum.WalkSpeed == 16, ctx.hum.WalkSpeed)
		local pun = Steal.stats.punches[#Steal.stats.punches]
		C("14 Steal.Punch sent (hit drop)", pun and pun.hit == "drop" and pun.to == -61)
		task.wait(1.6)
		C("15 the stun ends", not Steal.stunned(T) and T.Character.Humanoid.WalkSpeed == 16)

		-- Iron Grip
		passes({ pass_iron_grip = "on" })
		moveS(T, nearSpot(Plot1, 2, 3))
		local i3 = resIdx()
		Steal.tryHold(T, 1, u2)
		waitRes(i3, -61, "carried", 3)
		moveS(T, nearSpot(Plot1, 2, -2))
		task.wait(0.9)
		local i4 = resIdx()
		Steal.tryPunch(p, -61)
		local rG = waitRes(i4, -61, "stagger", 1)
		C("16 Iron Grip: the first hit staggers, no drop", rG ~= nil and Carry.get(T) and Carry.get(T).origin == "stolen" and Steal.staggered(T))
		task.wait(0.1)
		local wsSlow = T.Character.Humanoid.WalkSpeed
		local carrySp = Carry.speed(T)
		C("16b the stagger slows the thief on the server: WalkSpeed = carry speed x STAGGER_SLOW", math.abs(wsSlow - carrySp * Config.Steal.STAGGER_SLOW) < 0.01, s(wsSlow) .. " of " .. s(carrySp))
		task.wait(Config.Steal.STAGGER_S + 0.1)
		C("16c and returns to the carry speed after STAGGER_S", math.abs(T.Character.Humanoid.WalkSpeed - carrySp) < 0.01 and Carry.get(T) ~= nil, s(T.Character.Humanoid.WalkSpeed))
		task.wait(0.85)
		local i5 = resIdx()
		Steal.tryPunch(p, -61)
		local rG2 = waitRes(i5, -61, "dropped", 1)
		C("17 a second hit within 10 s drops it", rG2 ~= nil and bossOf(p, u2).spot == 2 and Carry.get(T) == nil)
		task.wait(1.6)
		moveS(T, nearSpot(Plot1, 2, 3))
		local i6 = resIdx()
		Steal.tryHold(T, 1, u2)
		waitRes(i6, -61, "carried", 3)
		moveS(T, nearSpot(Plot1, 2, -2))
		task.wait(0.9)
		Steal.tryPunch(p, -61)
		task.wait(10.3)
		local i7 = resIdx()
		Steal.tryPunch(p, -61)
		local rG3 = waitRes(i7, -61, nil, 1)
		C("18 a hit more than 10 s after the stagger staggers again (no drop)", rG3 and rG3.state == "stagger" and Carry.get(T) ~= nil, rG3 and rG3.state)
		-- Iron Grip does nothing against a hazard
		local i8 = resIdx()
		Carry.drop(T, T.Character.HumanoidRootPart.Position, "hazard")
		local rH = waitRes(i8, -61, "returned", 1)
		C("19 Iron Grip: a hazard still returns it at once", rH and rH.reason == "hazard" and bossOf(p, u2).spot == 2)
		-- the shield rising while the thief is still inside (Iron Grip on)
		moveS(T, nearSpot(Plot1, 2, 3))
		local i9 = resIdx()
		Steal.tryHold(T, 1, u2)
		waitRes(i9, -61, "carried", 3)
		local i10 = resIdx()
		local wr = Shield.raise(p, "button")
		local rSh = waitRes(i10, -61, "returned", 1)
		task.wait(0.1)
		local tr = T.Character.HumanoidRootPart.Position
		C("20 the owner's shield rising returns a boss still inside the base ('shield'), Iron Grip or not", wr == nil and rSh and rSh.reason == "shield" and bossOf(p, u2).spot == 2)
		C("21 and the thief is pushed out of the base", not Carry.insidePlot(Plot1, tr, 0))
		C("22 a hold on a shielded base is refused 'shield'", Steal.tryHold(T, 1, u2) == "shield")
		Shield.forceState(Plot1, "ready")
		passes()
	elseif ctx.phase == "c" then
		local T = addStand(-62)
		local u4 = put(p, "z1_t1", 4, 1, 0)
		-- a transfer with an error between the two writes
		L.hook(ctx, "SaveFailBetween", true)
		moveS(T, nearSpot(Plot1, 4, 3))
		local i11 = resIdx()
		Steal.tryHold(T, 1, u4)
		waitRes(i11, -62, "carried", 3)
		local walked = walkHome(T, Plots.of(T), nil, true)
		local rOk = waitRes(i11, -62, "success", 4)
		L.waitFor(function() local t = Steal.stats.transfers[#Steal.stats.transfers]; return t and t.uid == u4 end, 6)
		task.wait(0.2)
		local rep = TestHooks.reports.transfer or {}
		local inProfiles = countIn(Session.get(p), u4) + countIn(Session.get(T), u4)
		C("1 stolen home with SaveFailBetween: success, the thief's write errored", walked and rOk ~= nil and tostring(rep.thief):find("SaveFailBetween") ~= nil, tostring(rep.thief))
		C("2 the uid is in exactly one profile (the thief's)", inProfiles == 1 and countIn(Session.get(T), u4) == 1)
		local nO1, nT1 = countIn(rec(p.UserId), u4), countIn(rec(-62), u4)
		C("3 records now: owner 0 (written), thief 0 (its write failed): the known window", nO1 == 0 and nT1 == 0, s(nO1) .. "/" .. s(nT1))
		local okS = Session.save(T, "check")
		local nO2, nT2 = countIn(rec(p.UserId), u4), countIn(rec(-62), u4)
		C("4 after the thief's next write: in exactly one record", okS and nO2 + nT2 == 1 and nT2 == 1, s(nO2) .. "/" .. s(nT2))
		C("5 the hook is one-shot", workspace:GetAttribute("HFB_SaveFailBetween") == nil)
		C("6 the thief carries it as a crate carry (not pending)", Carry.get(T) and Carry.get(T).origin == "crate" and not Transfer.isPending(T, u4))
		Carry.lose(T, "check")
	end
end)
if not ok then C("the check ran to the end", false, tostring(err)) end

-- cleanup: stand-ins, check plots, carry, profile
pcall(function()
	if Carry.get(p) then Carry.lose(p, "check") end
	for id, f in pairs(stands) do pcall(seam.removePlayer, f); stands[id] = nil end
	for _, m in ipairs(made) do m:Destroy() end
	L.hook(ctx, "Wipe", true)
	task.wait(0.4)
	Shield.forceState(Plot1, "ready")
end)
L.hook(ctx, "SaveFailBetween", nil)
L.finish(ctx)
