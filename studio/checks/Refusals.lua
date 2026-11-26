if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-16: refusals (team/requirements/m1-core-loop-gate.md, "The other scripted checks"). Each case asserts no state
-- changed (L.snap: power, cash, spots, carry, fight, hearts, health). Phases, one call each:
--   { phase = "live" }  EDIT MODE (CheckAll runs it): Profile.TestReport and the hooks ignored when not Studio, simulated
--                       by a copy of Shared/TestHooks whose RunService says IsStudio() = false (the flag).
--   { phase = "a" }     PLAY: punch and fight refusals, a tap during a burst, the stall rule.
--   { phase = "b" }     PLAY: Base.Place refusals, malformed payloads to every c2s remote and the rate limits, sent by
--                       the real client through the check probe (StarterPlayerScripts.HFB_CheckProbe, CheckAll installs it).
-- Forged punch reports go through Punch.report (the handler after Net's limiter) while the real client's reports are
-- held off by a full limiter (L.muteClient); Fight.begin and Base.tryPlace are the handlers' bodies.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end

-- ---------------------------------------------------------------- edit mode: the live simulation
if ARGS.phase == "live" then
	local pass, fail, fails = 0, 0, {}
	local function check(label, ok, detail)
		if ok then pass += 1 else fail += 1; table.insert(fails, label) end
		print(("%s Refusals/live %s%s"):format(ok and "PASS" or "FAIL", label, detail ~= nil and (" | " .. tostring(detail)) or ""))
	end
	local src = game.ReplicatedStorage.Shared.TestHooks.Source
	local n
	src, n = src:gsub('local RunService = game:GetService%("RunService"%)', 'local RunService = { IsStudio = function() return false end, IsServer = function() return true end, IsClient = function() return false end }', 1)
	check("the TestHooks copy has its RunService replaced (flag: not Studio)", n == 1, n)
	local folder = Instance.new("Folder")
	folder.Name = "HFB_RefusalsLive"
	local m = Instance.new("ModuleScript")
	m.Name = "TestHooksLive"
	m.Source = src
	m.Parent = folder
	folder.Parent = game.ServerStorage
	local ok, err = pcall(function()
		local TH = require(m)
		local registered = 0
		local fakeNet = { onServerEvent = function() registered += 1 end }
		TH.listenReports(fakeNet)
		check("listenReports registers no Profile.TestReport handler when not Studio", registered == 0, registered)
		workspace:SetAttribute("HFB_SetPower", 99)
		workspace:SetAttribute("HFB_AutoTap", "good")
		check("TestHooks.get is nil when not Studio (AutoTap set)", TH.get("AutoTap") == nil, TH.get("AutoTap"))
		check("TestHooks.consume is nil when not Studio and leaves the attribute (SetPower set)", TH.consume("SetPower") == nil and workspace:GetAttribute("HFB_SetPower") == 99)
		check("TestHooks.onSet does not listen when not Studio", TH.onSet("SetPower", function() end) == nil)
		local warned = {}
		local c = game:GetService("LogService").MessageOut:Connect(function(msg, t)
			if t == Enum.MessageType.MessageWarning and msg:find("TestHooks: set in the place", 1, true) then table.insert(warned, msg) end
		end)
		TH.warnIfSetLive()
		task.wait(0.1)
		c:Disconnect()
		check("warnIfSetLive warns about hooks left in the place", #warned == 1 and warned[1]:find("SetPower", 1, true) ~= nil and warned[1]:find("AutoTap", 1, true) ~= nil, warned[1])
	end)
	workspace:SetAttribute("HFB_SetPower", nil)
	workspace:SetAttribute("HFB_AutoTap", nil)
	folder:Destroy()
	if not ok then check("the live simulation ran without a script error", false, tostring(err)) end
	print(("CHECK Refusals/live TOTAL pass=%d fail=%d"):format(pass, fail))
	print(("CHECKALL row Refusals|live|%d|%d|%s"):format(pass, fail, table.concat(fails, "; ")))
else

local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Punch, Fight, Zones, Carry, Base, Session, Net = L.Config, L.Punch, L.Fight, L.Zones, L.Carry, L.Base, L.Session, L.Net
local s = L.s
local HttpService = game:GetService("HttpService")

local ctx = L.begin("Refusals", ARGS)
local p, hrp = ctx.p, ctx.hrp
local plot = workspace.Plots.Plot1
local ringPart = workspace.Zones.Z1.Pads.Fixed.Ring
L.rootY(ctx)

local function refusedCount() local n = 0; for _, v in pairs(Punch.stats.refused) do n += v end; return n end
local function clearCarry() if Carry.get(p) then Carry.lose(p, "check") end; task.wait(0.1) end
local function waitRate() task.wait(Config.Punch.CYCLE(L.prof(ctx).speedLevel) * Config.Punch.RATE_TOLERANCE + 0.1) end

local function phaseA()
	L.hook(ctx, "Wipe", true)
	task.wait(0.3)
	L.tp(ctx, L.onPart(ctx, plot.BagPad))
	task.wait(0.5)
	L.muteClient(ctx, true)
	task.wait(1.6)

	-- a report faster than CYCLE x 0.8
	local r1 = L.forge(ctx, "bag", "good")
	L.check(ctx, "setup: a Good report on the pad is accepted", r1 and r1.accepted, r1 and r1.reason)
	task.wait(0.65)
	local before = L.snap(ctx)
	local r2 = L.forge(ctx, "bag", "good")
	L.check(ctx, "a timed report 0.65 s after an accept (under 0.66 s and CYCLE x 0.75 = 1.245) refused 'rate', no state change", r2 and not r2.accepted and r2.reason == "rate" and L.snap(ctx) == before, r2 and r2.reason)
	waitRate()
	-- a report during a burst
	local r3 = L.forge(ctx, "bag", "good")
	task.wait(0.1)
	local midPower = L.power(ctx)
	local r4 = L.forge(ctx, "bag", "perfect")
	task.wait(0.6)
	L.check(ctx, "a forged report during a burst refused 'busy'; the burst it hit is unchanged (+4)", r3.accepted and r4 and not r4.accepted and r4.reason == "busy" and L.power(ctx) == midPower + 3, ("%s, power +%s after the refusal"):format(r4 and tostring(r4.reason), s(L.power(ctx) - midPower)))
	-- off the pad
	L.tp(ctx, plot.BagPad.Position + Vector3.new(0, 3, 40))
	task.wait(0.3)
	waitRate()
	before = L.snap(ctx)
	local r5 = L.forge(ctx, "bag", "good")
	L.check(ctx, "a bag report off the pad refused 'place', no state change", r5 and not r5.accepted and r5.reason == "place" and L.snap(ctx) == before, r5 and r5.reason)
	local r6 = L.forge(ctx, "fight", "good")
	L.check(ctx, "a fight report with no fight refused 'place', no state change", r6 and not r6.accepted and r6.reason == "place" and L.snap(ctx) == before, r6 and r6.reason)
	local r6m = L.forge(ctx, "fight", "miss")
	L.check(ctx, "a fight Miss with no fight refused 'place' (no heart to lose)", r6m and not r6m.accepted and r6m.reason == "place" and L.snap(ctx) == before, r6m and r6m.reason)

	-- a tap during a burst through the real client: ignored on the client, nothing refused, no penalty
	L.muteClient(ctx, false)
	L.tp(ctx, L.onPart(ctx, plot.BagPad))
	task.wait(0.4)
	local ref0, rep0, log0 = refusedCount(), #ctx.reports, #Punch.stats.log
	local pw0 = L.power(ctx)
	L.hook(ctx, "ReportBeats", true) -- only here: the client's "ignored" report
	L.hook(ctx, "AutoTap", "busy")
	local ign = L.waitFor(function()
		for _, r in ipairs(L.reportsSince(ctx, rep0, "ignored")) do if r.data.why == "busy" then return r.data end end
	end, 5)
	task.wait(0.7)
	workspace:SetAttribute("HFB_AutoTap", nil)
	workspace:SetAttribute("HFB_ReportBeats", nil)
	task.wait(0.7)
	local bursts = L.burstsSince(ctx, log0, "bag")
	local gained = 0
	for _, b in ipairs(bursts) do for _, e in ipairs(b.beats) do gained += e.value end end
	L.check(ctx, "a tap during a burst (real client, AutoTap busy) is ignored on the client", ign ~= nil, ign and ign.why)
	L.check(ctx, "... not refused by the server and no penalty (each burst still +4)", refusedCount() == ref0 and #bursts >= 1 and gained == 4 * #bursts and L.power(ctx) - pw0 == gained,
		("refused +%d, bursts %d, gained %s"):format(refusedCount() - ref0, #bursts, s(gained)))

	-- fights
	L.muteClient(ctx, true)
	ctx.expect = "hook"
	L.hook(ctx, "SetPower", 25)
	task.wait(0.3)
	ctx.expect = nil
	-- outside the ring
	L.tp(ctx, ringPart.Position + Vector3.new(0, 3, -30))
	task.wait(0.3)
	before = L.snap(ctx)
	L.check(ctx, "Fight.Start outside the ring refused 'ring', no fight", Fight.begin(p, "z1_fixed") == nil and Fight.stats.refused.ring ~= nil and L.snap(ctx) == before, L.snap(ctx))
	-- while carrying
	L.hook(ctx, "GrantBoss", "z1_t1")
	L.waitFor(function() return L.carryState(ctx) == "carrying" end, 2)
	L.tp(ctx, L.nearBoss(ctx, "z1_fixed", ringPart)) -- next to where the boss patrols now (M2-28)
	task.wait(0.3)
	before = L.snap(ctx)
	L.check(ctx, "Fight.Start while carrying refused 'carrying', still carrying the same boss", Fight.canStart(p, "z1_fixed") == "carrying" and Fight.begin(p, "z1_fixed") == nil and L.snap(ctx) == before, Fight.canStart(p, "z1_fixed"))
	clearCarry()
	-- the stall rule: a fight with no reports at all (the client's are dropped by the full limiter)
	local stalls0 = Punch.stats.stalls
	local f = Fight.begin(p, "z1_fixed")
	if L.check(ctx, "setup: a fight starts in the ring", f ~= nil) then
		local t0 = os.clock()
		local got = L.waitFor(function() return f.hearts < 3 end, 6)
		local dt = os.clock() - t0
		local expectS = Config.Punch.RING[L.prof(ctx).speedLevel] * 2 + Config.Fight.STALL_SLACK_S
		local last = Fight.stats.log[#Fight.stats.log]
		L.check(ctx, "stall rule: no report -> the server counts one Miss", got and f.hearts == 2 and Punch.stats.stalls == stalls0 + 1 and last.kind == "heart" and last.why == "stall",
			("after %.2f s (expected %.2f), why %s"):format(dt, expectS, tostring(last.why)))
		L.check(ctx, "stall rule: timed at ring + ring + 0.5 s after the start (+/- 0.1)", math.abs(dt - expectS) <= 0.1, ("%.2f"):format(dt))
		-- a fight started while one is running
		L.check(ctx, "Fight.Start during a fight refused 'running'", Fight.canStart(p, "z1_fixed") == "running")
		Fight.finish(p, f, "run")
		task.wait(0.2)
	end
	-- on the 5 s cooldown
	before = L.snap(ctx)
	local why = Fight.canStart(p, "z1_fixed")
	L.check(ctx, "Fight.Start on the 5 s cooldown refused 'closed', no fight", why == "closed" and Fight.begin(p, "z1_fixed") == nil and L.snap(ctx) == before, why)
	local _, left = Zones.isOpen(p, "z1_fixed")
	L.check(ctx, "the cooldown is about 5 s", left > 4 and left <= 5, ("%.2f"):format(left))
	L.authority(ctx, 0, "phase a")
end

local function phaseB()
	L.hook(ctx, "Wipe", true)
	task.wait(0.3)
	local sp1 = plot.Spot_1 -- no ReportBeats here: the probe reports on its own
	-- Base.Place refusals
	L.tp(ctx, L.onPart(ctx, sp1))
	task.wait(0.3)
	local before = L.snap(ctx)
	L.check(ctx, "Base.Place when not carrying refused 'notCarrying', no state change", Base.tryPlace(p, 1) == "notCarrying" and L.snap(ctx) == before)
	L.hook(ctx, "GrantBoss", "z1_t1")
	L.waitFor(function() return L.carryState(ctx) == "carrying" end, 2)
	L.tp(ctx, sp1.Position + Vector3.new(0, 3, 40))
	task.wait(0.3)
	before = L.snap(ctx)
	L.check(ctx, "Base.Place out of range (40 studs) refused 'range', still carrying", Base.tryPlace(p, 1) == "range" and L.snap(ctx) == before)
	for _, bad in ipairs({ 0, 11, 1.5, -1, "1", 0 / 0, math.huge, true }) do
		local w = Base.tryPlace(p, bad)
		L.check(ctx, "Base.Place spotIndex " .. tostring(bad) .. " refused 'bad', no state change", w == "bad" and L.snap(ctx) == before, w)
	end
	-- a spot that is not the player's: a temporary copy of the plot owned by someone else, 300 studs away
	local other = plot:Clone()
	other.Name = "PlotTmpRefusals"
	other:SetAttribute("PlotId", 99)
	other:SetAttribute("OwnerUserId", 999)
	other:PivotTo(plot:GetPivot() + Vector3.new(0, 0, -300))
	other.Parent = workspace.Plots
	L.tp(ctx, L.onPart(ctx, other.Spot_1))
	task.wait(0.3)
	before = L.snap(ctx)
	local w = Base.tryPlace(p, 1)
	L.check(ctx, "Base.Place standing on another player's Spot_1 refused, own spot 1 still empty", w ~= nil and L.prof(ctx).spots[1] == nil and L.snap(ctx) == before, w)
	other:Destroy()
	-- a taken spot
	L.tp(ctx, L.onPart(ctx, sp1))
	task.wait(0.3)
	L.check(ctx, "setup: place on own Spot_1", Base.tryPlace(p, 1) == nil)
	L.hook(ctx, "GrantBoss", "z1_t1")
	L.waitFor(function() return L.carryState(ctx) == "carrying" end, 2)
	before = L.snap(ctx)
	L.check(ctx, "Base.Place on a taken spot refused 'taken', still carrying", Base.tryPlace(p, 1) == "taken" and L.snap(ctx) == before)
	-- Carry.Grab when not dropped (carrying)
	local cu = Carry.get(p).uid
	L.check(ctx, "Carry.Grab while carrying (not dropped) refused 'state'", Carry.tryGrab(p, cu) == "state" and L.snap(ctx) == before)

	-- malformed payloads to every c2s remote, from the real client (the probe), paced under each limit
	L.tp(ctx, sp1.Position + Vector3.new(0, 3, 14))
	task.wait(0.3)
	before = L.snap(ctx)
	local d0 = Punch.stats.dropped
	local fb0 = Fight.stats.refused.bad or 0
	local cb0 = Carry.stats.refused.bad or 0
	local bb0 = Base.stats.refused.bad or 0
	local keys0 = {}
	for k in pairs(L.TestHooks.reports) do keys0[k] = true end
	local errs0 = #ctx.errs
	local rem0 = table.clone(ctx.remotes)
	local rep0 = #ctx.reports
	workspace:SetAttribute("HFB_CheckProbe", "fuzz")
	local done = L.waitFor(function()
		for _, r in ipairs(L.reportsSince(ctx, rep0, "probe")) do if r.data.done == "fuzz" then return r.data end end
	end, 25, 0.1)
	workspace:SetAttribute("HFB_CheckProbe", nil)
	task.wait(0.5)
	L.check(ctx, "the probe sent every malformed payload", done ~= nil, done and HttpService:JSONEncode(done.sent))
	local recv = {}
	for k, v in pairs(ctx.remotes) do recv[k] = v - (rem0[k] or 0) end
	L.note(ctx, "fuzz calls received per remote: " .. HttpService:JSONEncode(recv))
	L.check(ctx, "malformed: no state changed (power, cash, spots, carry, fight)", L.snap(ctx) == before, L.snap(ctx))
	L.check(ctx, "malformed: no server error and no [HFB] warning from any handler", #ctx.errs == errs0, ctx.errs[errs0 + 1])
	L.check(ctx, "malformed Punch.Report payloads dropped by the shape check", Punch.stats.dropped > d0, Punch.stats.dropped - d0)
	L.check(ctx, "malformed Fight.Start padIds refused 'bad'", (Fight.stats.refused.bad or 0) > fb0, (Fight.stats.refused.bad or 0) - fb0)
	L.check(ctx, "malformed Carry.Grab uids refused 'bad'", (Carry.stats.refused.bad or 0) > cb0, (Carry.stats.refused.bad or 0) - cb0)
	L.check(ctx, "malformed Base.Place spotIndexes refused 'bad'", (Base.stats.refused.bad or 0) > bb0, (Base.stats.refused.bad or 0) - bb0)
	local newKeys = {}
	for k in pairs(L.TestHooks.reports) do if not keys0[k] and k ~= "probe" and k ~= "ring" and k ~= "beats" and k ~= "carry" and k ~= "base" and k ~= "log" and k ~= "input" and k ~= "ignored" and k ~= "refused" and k ~= "audio" then table.insert(newKeys, k) end end
	L.check(ctx, "malformed Profile.TestReport payloads stored nothing", #newKeys == 0 and typeof(L.TestHooks.reports._dropped) == "table", table.concat(newKeys, ","))

	-- the rate limits: the probe sends 10 of each in one frame
	task.wait(1.2)
	local drop0 = table.clone(L.TestHooks.reports._dropped)
	before = L.snap(ctx)
	rep0 = #ctx.reports
	workspace:SetAttribute("HFB_CheckProbe", "rate")
	local rd = L.waitFor(function()
		for _, r in ipairs(L.reportsSince(ctx, rep0, "probe")) do if r.data.done == "rate" then return r.data end end
	end, 8, 0.1)
	workspace:SetAttribute("HFB_CheckProbe", nil)
	task.wait(0.5)
	L.check(ctx, "the probe sent the rate bursts", rd ~= nil)
	for _, key in ipairs({ "Punch.Report", "Fight.Start", "Fight.Run", "Carry.Grab", "Base.Place" }) do
		local lim = Config.Punch.RATE[key]
		local got = (L.TestHooks.reports._dropped[key] or 0) - (drop0[key] or 0)
		L.check(ctx, ("rate limit %s: 10 in one frame -> %d dropped (limit %d/s)"):format(key, 10 - lim, lim), got == 10 - lim, got)
	end
	L.check(ctx, "rate bursts: no state changed", L.snap(ctx) == before, L.snap(ctx))
	clearCarry()
	L.authority(ctx, 0, "phase b")
end

local ok, err = xpcall(function()
	if ARGS.phase == "b" then phaseB() else phaseA() end
end, debug.traceback)
if not ok then L.check(ctx, "the check ran without a script error", false, tostring(err):sub(1, 500)) end
L.finish(ctx)
end
