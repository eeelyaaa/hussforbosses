if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-18: first-session times and fight lengths (game-designer). PLAY MODE ONLY; measures, changes no numbers.
-- Installed by hand as ServerStorage.TmpChecks.FirstSession (wrapped like the others; see m1-first-session.md).
--   { phase = "a", mix = "45,45,10" | "perfect" }   wiped join -> first punch, first Perfect, 25 Power, walk, first fight, win
--   { phase = "b", log = "clear" | "none" }          carried boss from the ring edge -> home, placed, 30 s of income, collected
--   { phase = "f", grade = "perfect"|"good"|"mix", cases = {1,2,3} }  fight lengths at r = .5,1,1.5,2,3,5 (index into CASES)
-- Walking is the server moving the character along the layout's waypoints at 16 (carry 12) studs/s.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Punch, Fight, Zones, Carry, Base, Income, Session = L.Config, L.Punch, L.Fight, L.Zones, L.Carry, L.Base, L.Income, L.Session
local ctx = L.begin("FirstSession", ARGS)
local p, hrp = ctx.p, ctx.hrp
local plot = workspace.Plots.Plot1
local ringPart = workspace.Zones.Z1.Pads.Fixed.Ring
local function P(...) print("M118", ...) end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end

local function walkTo(target, speed, stopFn)
	local last = os.clock()
	local dist = 0
	while true do
		task.wait()
		local now = os.clock(); local dt = now - last; last = now
		local go = flat(target) - flat(hrp.Position)
		if go.Magnitude < 0.3 then break end
		if stopFn and stopFn() then break end
		local step = math.min(go.Magnitude, speed * dt)
		ctx.char:PivotTo(CFrame.new(hrp.Position + go.Unit * step))
		dist += step
	end
	return dist
end

local bp = plot.BagPad
local door = Vector3.new(96, 0, plot.Entrance.Position.Z)
local gate = Vector3.new(206, 0, 234)
local ringC = ringPart.Position
local dir = (flat(ringC) - flat(gate)).Unit
local ringEdge = Vector3.new(ringC.X - dir.X * 5, 0, ringC.Z - dir.Z * 5)

local function phaseA()
	L.rootY(ctx)
	local mix = ARGS.mix or "45,45,10"
	L.hook(ctx, "Wipe", true)
	L.waitFor(function() return L.power(ctx) == 0 and workspace:GetAttribute("HFB_Wipe") == nil end, 2)
	local sp = plot.SpawnPoint
	L.tp(ctx, Vector3.new(sp.Position.X, hrp.Position.Y, sp.Position.Z))
	local y = hrp.Position.Y
	task.wait(0.3)
	local led0 = #ctx.ledger
	if mix == "perfect" then L.hook(ctx, "AutoTap", "perfect") else L.hook(ctx, "AutoMix", mix); L.hook(ctx, "AutoTap", "mix") end
	local T0 = os.clock()
	local ev = {}
	-- walk spawn -> bag pad centre, while a watcher stamps the events
	local fightLog0 = #Fight.stats.log
	local plog0 = #Punch.stats.log
	local stage = "bag"
	local fpTime, perfT, p25T, firstPunchT
	local function watch()
		if not firstPunchT then
			for i = led0 + 1, #ctx.ledger do if ctx.ledger[i].key == "power" and ctx.ledger[i].value > 0 then firstPunchT = ctx.ledger[i].at - T0; break end end
		end
		if not perfT then
			for i = plog0 + 1, #Punch.stats.log do local e = Punch.stats.log[i]; if e.context == "bag" and e.grade == "perfect" and e.n == 1 then perfT = os.clock() - T0; break end end
		end
		if not p25T and L.power(ctx) >= 25 then p25T = os.clock() - T0 end
		return p25T ~= nil
	end
	walkTo(Vector3.new(bp.Position.X, y, bp.Position.Z), 16)
	ev.atBagPad = os.clock() - T0
	local nb, n25 = 0, nil
	while not watch() and os.clock() - T0 < 60 do task.wait(0.02) end
	ev.firstPunch, ev.firstPerfect, ev.power25 = firstPunchT, perfT, p25T
	-- bursts counted
	local bursts = L.burstsSince(ctx, plog0, "bag")
	local g = { perfect = 0, good = 0 }
	for _, b in ipairs(bursts) do local gr = b.beats[1].grade; g[gr] = (g[gr] or 0) + 1 end
	ev.burstsTo25 = #bursts; ev.perfects = g.perfect; ev.goods = g.good
	-- let a burst in flight land (the player would have the power when the last beat lands): p25T is that moment
	local tWalk = os.clock()
	local tw = {}
	local d1 = walkTo(Vector3.new(door.X, y, door.Z), 16)
	ev.toDoor = d1
	local d2 = walkTo(Vector3.new(gate.X, y, gate.Z), 16)
	ev.gateT = os.clock() - T0; ev.bagToGate = d1 + d2
	local d3 = walkTo(Vector3.new(ringEdge.X, y, ringEdge.Z), 16)
	ev.atRing = os.clock() - T0; ev.runDist = d1 + d2 + d3; ev.runS = os.clock() - tWalk
	-- standing in the ring: AutoTap presses Huss once a second
	local started = L.waitFor(function()
		for i = fightLog0 + 1, #Fight.stats.log do if Fight.stats.log[i].kind == "started" then return Fight.stats.log[i] end end
	end, 8)
	ev.fightStarted = os.clock() - T0
	if not started then
		-- the edge may be outside the ring; step in
		walkTo(Vector3.new(ringC.X, y, ringC.Z), 16)
		started = L.waitFor(function()
			for i = fightLog0 + 1, #Fight.stats.log do if Fight.stats.log[i].kind == "started" then return Fight.stats.log[i] end end
		end, 8)
		ev.fightStarted = os.clock() - T0
	end
	local f = Fight.get(p)
	local fid = started and started.fightId
	local res = L.waitFor(function()
		for i = fightLog0 + 1, #Fight.stats.log do
			local e = Fight.stats.log[i]
			if e.fightId == fid and e.kind ~= "started" and e.kind ~= "beat" and e.kind ~= "heart" then return e end
		end
	end, 40)
	ev.fightEndKind = res and res.kind
	ev.fightEnded = os.clock() - T0
	ev.fightSecs = res and started and (res.at - started.at)
	local nbeats, hearts = 0, 0
	for i = fightLog0 + 1, #Fight.stats.log do local e = Fight.stats.log[i]; if e.fightId == fid then if e.kind == "beat" then nbeats += 1 elseif e.kind == "heart" then hearts += 1 end end end
	ev.hearts = hearts
	local fb = L.burstsSince(ctx, plog0, "fight")
	ev.fightBursts = #fb
	for k, v in pairs(ev) do P(k, type(v) == "number" and ("%.2f"):format(v) or tostring(v)) end
	P(("SUMMARY a mix=%s | atBag %.2f firstPunch %.2f firstPerfect %s p25 %s bursts %d(P%d G%d) | gate %.2f ring %.2f run %.2fs %.1f studs | fightStart %.2f end %.2f (%s %.2fs, bursts %d, hearts %d)"):format(
		mix, ev.atBagPad, ev.firstPunch or -1, ev.firstPerfect and ("%.2f"):format(ev.firstPerfect) or "none", ev.power25 and ("%.2f"):format(ev.power25) or "none", ev.burstsTo25, ev.perfects, ev.goods,
		ev.gateT, ev.atRing, ev.runS, ev.runDist, ev.fightStarted, ev.fightEnded, tostring(ev.fightEndKind), ev.fightSecs or -1, ev.fightBursts, ev.hearts))
	workspace:SetAttribute("HFB_AutoTap", nil)
end

local function phaseB()
	L.rootY(ctx)
	L.hook(ctx, "Wipe", true)
	L.waitFor(function() return L.power(ctx) == 0 and workspace:GetAttribute("HFB_Wipe") == nil end, 2)
	L.hook(ctx, "PadFastBack", 0)
	if ARGS.log == "clear" then L.hook(ctx, "LogForce", "clear") end
	local y = hrp.Position.Y
	L.tp(ctx, Vector3.new(ringEdge.X, y, ringEdge.Z))
	task.wait(0.3)
	L.hook(ctx, "GrantBoss", "z1_t1")
	L.waitFor(function() return L.carryState(ctx) == "carrying" end, 2)
	L.hook(ctx, "ReportBeats", true)
	L.hook(ctx, "AutoInteract", true)
	local T0 = os.clock()
	local drops = 0
	local lastState = "carrying"
	local function track() local s = L.carryState(ctx); if s == "dropped" and lastState ~= "dropped" then drops += 1 end; lastState = s; return false end
	local spot = plot.Spot_1
	local seq = { Vector3.new(gate.X, y, gate.Z), Vector3.new(door.X, y, door.Z) }
	local tot = 0
	local mark = {}
	for _, w in ipairs(seq) do
		-- a dropped boss waits for the Grab (AutoInteract); the walk goes on only while carrying
		while true do
			local d = walkTo(w, Config.Carry.CARRY, function() track(); return L.carryState(ctx) ~= "carrying" end)
			tot += d
			if L.carryState(ctx) == "carrying" then break end
			local t = os.clock(); L.waitFor(function() return L.carryState(ctx) == "carrying" end, 6); mark.dropWait = (mark.dropWait or 0) + os.clock() - t
			if L.carryState(ctx) ~= "carrying" then break end
		end
		mark[#mark + 1] = os.clock() - T0
	end
	local d = walkTo(Vector3.new(spot.Position.X, y, spot.Position.Z), Config.Carry.CARRY, function() track(); return L.prof(ctx).spots[1] ~= nil end)
	tot += d
	local placedAt
	L.waitFor(function() if L.prof(ctx).spots[1] ~= nil then placedAt = os.clock() - T0; return true end end, 6)
	P(("carry home: gate %.2f door %.2f placed %s s, %.1f studs, drops %d, dropWait %.2f, log=%s"):format(mark[1] or -1, mark[2] or -1, placedAt and ("%.2f"):format(placedAt) or "NO", tot, drops, mark.dropWait or 0, tostring(ARGS.log)))
	workspace:SetAttribute("HFB_AutoInteract", nil)
	if placedAt and not ARGS.skipCollect then
		local tp0 = os.clock()
		local at30 = L.waitFor(function() return Income.onPad(L.prof(ctx).spots[1]) >= 30 end, 40)
		P(("income: $30 on the pad %.2f s after placing (real clock)"):format(os.clock() - tp0))
		local cash0 = L.prof(ctx).cash
		local t1 = os.clock()
		L.tp(ctx, L.onPart(ctx, plot.CashPad_1))
		local col = L.waitFor(function() return L.prof(ctx).cash > cash0 end, 3)
		P(("collected %s cash %.2f s after stepping on the pad (cash %s -> %s)"):format(tostring(col ~= nil), os.clock() - t1, tostring(cash0), tostring(L.prof(ctx).cash)))
	end
end

local CASES = { { 0.5, 50 }, { 1, 25 }, { 1.5, 16.67 }, { 2, 12.5 }, { 3, 8.34 }, { 5, 5 } }
local function phaseF()
	L.hook(ctx, "Wipe", true)
	task.wait(0.3)
	L.hook(ctx, "PadFastBack", 0)
	local y = hrp.Position.Y
	local grade = ARGS.grade or "perfect"
	if grade == "mix" then L.hook(ctx, "AutoMix", "45,45,10"); L.hook(ctx, "AutoTap", "mix") else L.hook(ctx, "AutoTap", grade) end
	task.wait(0.5)
	for _, idx in ipairs(ARGS.cases or { 1, 2, 3, 4, 5, 6 }) do
		local c = CASES[idx]
		L.tp(ctx, Vector3.new(ringC.X + 40, y, ringC.Z + 40))
		task.wait(0.6)
		if Carry.get(p) then Carry.lose(p, "check") end
		Session.set(p, "power", c[2])
		task.wait(0.3)
		local plog0 = #Punch.stats.log
		local f0 = #Fight.stats.log
		L.tp(ctx, Vector3.new(ringC.X + 1, y, ringC.Z + 1))
		local started = L.waitFor(function()
			for i = f0 + 1, #Fight.stats.log do if Fight.stats.log[i].kind == "started" then return Fight.stats.log[i] end end
		end, 6)
		if not started then P(("r=%s: no fight started: %s"):format(c[1], tostring(Fight.canStart(p, "z1_fixed")))) else
			local res = L.waitFor(function()
				for i = f0 + 1, #Fight.stats.log do
					local e = Fight.stats.log[i]
					if e.fightId == started.fightId and e.kind ~= "started" and e.kind ~= "beat" and e.kind ~= "heart" then return e end
				end
			end, 40)
			local hearts = 0
			for i = f0 + 1, #Fight.stats.log do local e = Fight.stats.log[i]; if e.fightId == started.fightId and e.kind == "heart" then hearts += 1 end end
			local bs = L.burstsSince(ctx, plog0, "fight")
			local gs = {}
			for _, b in ipairs(bs) do table.insert(gs, b.beats[1].grade:sub(1, 1)) end
			P(("FIGHT %s r=%s band=%s power=%s: %s in %.2f s, bursts %d [%s], hearts lost %d"):format(grade, tostring(c[1]), started.band, tostring(L.power(ctx)), res and res.kind or "TIMEOUT", res and (res.at - started.at) or -1, #bs, table.concat(gs, ""), hearts))
		end
		task.wait(1.5)
		if Fight.get(p) then task.wait(2) end
	end
	workspace:SetAttribute("HFB_AutoTap", nil)
end

local ok, err = xpcall(function()
	if ARGS.phase == "b" then phaseB() elseif ARGS.phase == "f" then phaseF() else phaseA() end
end, debug.traceback)
if not ok then P("SCRIPT ERROR", tostring(err):sub(1, 600)) end
L.finish(ctx)
