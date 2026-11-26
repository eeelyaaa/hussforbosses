if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-16: the Core loop gate (team/requirements/m1-core-loop-gate.md, "The smoke-loop script"). PLAY MODE ONLY.
-- Driven by the real client (AutoTap, AutoInteract), read through Profile.TestReport (ReportBeats); every result is
-- asserted on the server's module state. The check never sends a punch, a win, a grab or a place itself: the only
-- module call that requests anything is the forged second place on a taken spot (step 7), which must be refused.
-- Installed by CheckAll ("prepare") as ServerStorage.TmpChecks.CoreLoop; one play-mode call per phase:
--   require(game.ServerStorage.TmpChecks.CoreLoop)({ phase = "a", skin = "brickbrawl" })   steps 1-4 (+ step 9 on them)
--   require(game.ServerStorage.TmpChecks.CoreLoop)({ phase = "b", skin = "brickbrawl" })   steps 5-8 (+ step 9 on them)
-- skin = "stub" for the skin check part 2 (CheckSkin armed HFB_ForceSkin = "stub" before play started).
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Punch, Fight, Zones, Carry, Hazards, Base, Income, Session = L.Config, L.Punch, L.Fight, L.Zones, L.Carry, L.Hazards, L.Base, L.Income, L.Session
local s = L.s

local ctx = L.begin("CoreLoop", ARGS)
local p, hrp, hum = ctx.p, ctx.hrp, ctx.hum
local plot = workspace.Plots.Plot1
local fixed = workspace.Zones.Z1.Pads.Fixed
local ringPart = fixed.Ring
local skin = ARGS.skin or "brickbrawl"
local Skin = require(game.ReplicatedStorage.Shared.Skin)
L.check(ctx, "server skin is " .. skin, Skin.Id == skin, Skin.Id)

local function ringReports(i0, ctxName)
	local out = {}
	for _, r in ipairs(L.reportsSince(ctx, i0, "ring")) do
		if not ctxName or r.data.ctx == ctxName then table.insert(out, r.data) end
	end
	return out
end
local function lastReport(name)
	for i = #ctx.reports, 1, -1 do if ctx.reports[i].name == name then return ctx.reports[i].data end end
	return nil
end

local function phaseA()
	-- 1. Join
	local sp = plot.SpawnPoint
	L.check(ctx, "1 join: Plot1 OwnerUserId is the player", plot:GetAttribute("OwnerUserId") == p.UserId, plot:GetAttribute("OwnerUserId"))
	-- the server moves the new character to the plot's SpawnPoint (Session.toSpawn); give it up to 3 s after the join
	local _, tSpawn = L.waitFor(function() return L.flat(hrp.Position, sp.Position) < 3 end, 3)
	local dsp = L.flat(hrp.Position, sp.Position)
	L.check(ctx, "1 join: character at SpawnPoint (flat < 3)", dsp < 3, ("%.2f studs, after %.2f s"):format(dsp, tSpawn))
	L.rootY(ctx)
	local pads = Zones.padsPayload()
	local zp
	for _, e in ipairs(pads) do if e.padId == "z1_fixed" then zp = e end end
	L.check(ctx, "1 join: Zones.Pads lists z1_fixed -> z1_t1, Power 25", zp ~= nil and zp.creatureId == "z1_t1" and zp.power == 25, zp and (zp.creatureId .. " " .. s(zp.power)))
	L.hook(ctx, "ReportBeats", true)
	ctx.expect = "hook"
	-- Zones.Clock reaches the client: a ClockOffset of 5 must come back in the client's log report as its offset
	local r0 = #ctx.reports
	L.hook(ctx, "ClockOffset", 5)
	local co = L.waitFor(function()
		for _, r in ipairs(L.reportsSince(ctx, r0, "log")) do if r.data.co and r.data.co > 2.5 then return r.data.co end end
	end, 4)
	-- arrival = the client's offset left 0 (under 0.25 s it counts as latency, TEAM CALL M1-14a); its precision is noted
	L.check(ctx, "1 join: Zones.Clock arrived on the client (ClockOffset 5 moved the client's offset off 0)", co ~= nil, co)
	if co then L.note(ctx, ("client clock offset %.3f for ClockOffset 5 (error %.3f s; the client's GetServerTimeNow this soon after joining)"):format(co, co - 5)) end
	workspace:SetAttribute("HFB_ClockOffset", nil)
	task.wait(0.3)
	L.check(ctx, "1 join: no errors in the output yet", #ctx.errs == 0, #ctx.errs > 0 and ctx.errs[1] or nil)

	-- 2. Punch
	L.hook(ctx, "Wipe", true)
	L.waitFor(function() return L.power(ctx) == 0 and workspace:GetAttribute("HFB_Wipe") == nil end, 2)
	ctx.expect = nil
	local led0 = #ctx.ledger
	local rep0 = #ctx.reports
	local sch0 = Punch.stats.schedules
	L.tp(ctx, L.onPart(ctx, plot.BagPad))
	L.waitFor(function() return Punch.stats.schedules > sch0 end, 2)
	local sch = Punch.stats.lastSchedule[p.UserId]
	L.check(ctx, "2 Punch.Schedule sent on the bag pad: ring 1.20, cycle 1.81", sch and math.abs(sch.ringClose - 1.2) < 1e-9 and math.abs(sch.cycle - 1.81) < 1e-9, sch and (s(sch.ringClose) .. "/" .. s(sch.cycle)))
	local log0 = #Punch.stats.log
	local rem0 = ctx.remotes["Punch.Report"]
	L.hook(ctx, "AutoTap", "good")
	local b1 = L.waitFor(function()
		local bs = L.burstsSince(ctx, log0, "bag")
		for _, b in ipairs(bs) do if #b.beats == 3 then return b end end
	end, 6)
	workspace:SetAttribute("HFB_AutoTap", nil)
	local rings = ringReports(rep0, "bag")
	L.check(ctx, "2 the client's ring was drawn from that schedule (close 1.2)", #rings > 0 and math.abs((rings[1].close or 0) - 1.2) < 0.001, rings[1] and rings[1].close)
	if L.check(ctx, "2 one Good burst applied by the server", b1 ~= nil and b1.beats[1].grade == "good", b1 and b1.beats[1].grade) then
		local offs, lateOk = {}, true
		for k, e in ipairs(b1.beats) do
			table.insert(offs, ("%.3f(+%.1fms)"):format(e.due - e.t0, e.late * 1000))
			if math.abs((e.due - e.t0) - Config.Punch.BEAT[k]) > 1e-6 or e.late < 0 or e.late > 0.020 then lateOk = false end
		end
		L.check(ctx, "2 beats applied at 0 / 0.213 / 0.401 s (+/- 20 ms, server clock)", lateOk, table.concat(offs, " "))
		local res = Punch.stats.lastResult[p.UserId]
		L.check(ctx, "2 Punch.Result accepted for the burst", res and res.accepted == true and (res.seq == b1.seq or res.seq > b1.seq), res and tostring(res.accepted))
		local pw = {}
		for i = led0 + 1, #ctx.ledger do
			local e = ctx.ledger[i]
			if e.key == "power" and #pw < 3 then table.insert(pw, e.value) end
		end
		L.check(ctx, "2 Power 1, 2, then 4 after the third beat (4 x strength value 1)", pw[1] == 1 and pw[2] == 2 and pw[3] == 4, table.concat(pw, ","))
	end
	L.check(ctx, "2 the burst came through the Punch.Report remote", ctx.remotes["Punch.Report"] > rem0, ctx.remotes["Punch.Report"] - rem0)

	-- 3. Burst: Perfect = 8, Miss = nothing and the next ring 0.61 s later
	task.wait(0.7)
	local pBefore = L.power(ctx)
	local log1 = #Punch.stats.log
	L.hook(ctx, "AutoTap", "perfect")
	local b2 = L.waitFor(function()
		for _, b in ipairs(L.burstsSince(ctx, log1, "bag")) do if #b.beats == 3 then return b end end
	end, 6)
	workspace:SetAttribute("HFB_AutoTap", nil)
	task.wait(0.05)
	if L.check(ctx, "3 one Perfect burst applied", b2 ~= nil and b2.beats[1].grade == "perfect", b2 and b2.beats[1].grade) then
		local v = b2.beats[1].value + b2.beats[2].value + b2.beats[3].value
		L.check(ctx, "3 Perfect: Power +8 (2/2/4)", v == 8 and L.power(ctx) - pBefore >= 8, ("%s/%s/%s, power %s -> %s"):format(s(b2.beats[1].value), s(b2.beats[2].value), s(b2.beats[3].value), s(pBefore), s(L.power(ctx))))
	end
	task.wait(0.7)
	local pMiss = L.power(ctx)
	local log2 = #Punch.stats.log
	local rep2 = #ctx.reports
	L.hook(ctx, "AutoTap", "miss")
	local mr = L.waitFor(function()
		for _, r in ipairs(ringReports(rep2, "bag")) do if r.cause == "miss" then return r end end
	end, 6)
	workspace:SetAttribute("HFB_AutoTap", nil)
	L.check(ctx, "3 Miss: the next ring starts 0.61 s after the miss", mr ~= nil and math.abs((mr.gap or 0) - 0.61) <= 0.035, mr and mr.gap)
	L.check(ctx, "3 Miss: no burst applied and no Power", #L.burstsSince(ctx, log2, "bag") == 0 and L.power(ctx) == pMiss, ("bursts %d, power %s -> %s"):format(#L.burstsSince(ctx, log2, "bag"), s(pMiss), s(L.power(ctx))))

	-- 4. 25 Power
	task.wait(0.3)
	ctx.expect = "hook"
	L.hook(ctx, "SetPower", 24)
	L.waitFor(function() return L.power(ctx) == 24 end, 2)
	ctx.expect = nil
	local log3 = #Punch.stats.log
	L.hook(ctx, "AutoTap", "good")
	L.waitFor(function()
		for _, b in ipairs(L.burstsSince(ctx, log3, "bag")) do if #b.beats == 3 then return b end end
	end, 6)
	workspace:SetAttribute("HFB_AutoTap", nil)
	task.wait(0.05)
	local pw4 = L.power(ctx)
	L.check(ctx, "4 SetPower 24 then one Good burst: Power >= 25", pw4 >= 25, pw4)
	local ratio = zp and zp.power / pw4 or math.huge
	local band = Config.Fight.band(ratio)
	L.check(ctx, "4 the pad's number is green for the player (band easy or fair from Config.Fight.BANDS)", band.id == "easy" or band.id == "fair", ("r=%.2f %s"):format(ratio, band.id))
	task.wait(0.8)
	L.authority(ctx, 0, "steps 1-4")
end

local function phaseB()
	-- 5. Fight at equal Power (the B22 path)
	ctx.expect = "hook"
	L.hook(ctx, "ReportBeats", true)
	L.hook(ctx, "Wipe", true)
	L.waitFor(function() return L.power(ctx) == 0 and workspace:GetAttribute("HFB_Wipe") == nil end, 2)
	L.hook(ctx, "SetPower", 25)
	L.waitFor(function() return L.power(ctx) == 25 end, 2)
	ctx.expect = nil
	local led0 = #ctx.ledger
	L.check(ctx, "5 Power is exactly 25 before the fight", L.power(ctx) == 25, L.power(ctx))
	L.rootY(ctx)
	local flog0 = #Fight.stats.log
	local plog0 = #Punch.stats.log
	local rep0 = #ctx.reports
	local start0 = ctx.remotes["Fight.Start"]
	L.hook(ctx, "AutoTap", "good")
	L.tp(ctx, L.onPart(ctx, ringPart, 1, 1))
	local started = L.waitFor(function()
		for i = flog0 + 1, #Fight.stats.log do if Fight.stats.log[i].kind == "started" then return Fight.stats.log[i] end end
	end, 5)
	local f = Fight.get(p)
	L.check(ctx, "5 the client's Huss press sent Fight.Start (remote)", ctx.remotes["Fight.Start"] > start0, ctx.remotes["Fight.Start"] - start0)
	if L.check(ctx, "5 Fight.State started", started ~= nil and f ~= nil) then
		L.check(ctx, "5 r = 1.0, band fair, windows 110/45 ms", f.ratio == 1 and f.band == "fair" and f.goodMs == 110 and f.perfectMs == 45, ("%s %s %s/%s"):format(s(f.ratio), f.band, s(f.goodMs), s(f.perfectMs)))
		L.check(ctx, "5 health 250 (10 x 25), hearts 3", f.health == 250 and f.maxHealth == 250 and f.hearts == 3, ("%s/%s hearts %s"):format(s(f.health), s(f.maxHealth), s(f.hearts)))
		local fid = f.fightId
		local won = L.waitFor(function()
			for i = flog0 + 1, #Fight.stats.log do local e = Fight.stats.log[i]; if e.fightId == fid and e.kind ~= "started" and e.kind ~= "beat" and e.kind ~= "heart" then return e end end
		end, 10)
		workspace:SetAttribute("HFB_AutoTap", nil)
		L.check(ctx, "5 the fight ended in a win", won ~= nil and won.kind == "win", won and won.kind)
		task.wait(0.6) -- burst 3's punch 3 is applied (or not) at t0 + 0.401, after the win on punch 2; its client report follows
		local seqs, beats, hearts = {}, {}, 0
		for i = flog0 + 1, #Fight.stats.log do
			local e = Fight.stats.log[i]
			if e.fightId == fid and e.kind == "beat" then
				if not table.find(seqs, e.burstSeq) then table.insert(seqs, e.burstSeq) end
				table.insert(beats, ("%d.%d:%s%s"):format(table.find(seqs, e.burstSeq), e.n, s(e.health), e.won and "W" or ""))
			elseif e.fightId == fid and e.kind == "heart" then
				hearts += 1
			end
		end
		local str = table.concat(beats, " ")
		L.check(ctx, "5 server health beat by beat: 225 200 150 | 125 100 50 | 25 0W (won on burst 3 punch 2)", str == "1.1:225 1.2:200 1.3:150 2.1:125 2.2:100 2.3:50 3.1:25 3.2:0W", str)
		L.check(ctx, "5 no Miss in the fight (all bursts Good)", hearts == 0, hearts)
		local grades, third = {}, nil
		for _, b in ipairs(L.burstsSince(ctx, plog0, "fight")) do
			table.insert(grades, b.beats[1].grade)
			if b.seq == seqs[3] then third = b.beats[3] end
		end
		L.check(ctx, "5 the client reported Good on every burst (grade only)", #grades == 3 and grades[1] == "good" and grades[2] == "good" and grades[3] == "good", table.concat(grades, ","))
		L.check(ctx, "5 B22: burst 3 punch 3 dealt nothing (no contact, value 0)", third ~= nil and third.contact == false and third.value == 0, third and tostring(third.contact))
		local cb
		for _, r in ipairs(L.reportsSince(ctx, rep0, "beats")) do if r.data.c == "fight" then cb = r.data end end
		L.check(ctx, "5 B22 on the client: the last fight burst's beat 3 carried noContact", cb ~= nil and cb.b[3] ~= nil and cb.b[3][6] == true, cb and cb.b[3] and tostring(cb.b[3][6]))
		local fr = ringReports(rep0, "fight")
		L.check(ctx, "5 the client's fight rings used the band's windows 110/45", #fr > 0 and fr[1].win[1] == 110 and fr[1].win[2] == 45, fr[1] and (s(fr[1].win[1]) .. "/" .. s(fr[1].win[2])))
		local open, left = Zones.isOpen(p, "z1_fixed")
		L.check(ctx, "5 Zones.PadBeaten backIn = 10 (pad closed to the player ~10 s)", not open and left > 9 and left <= 10, ("%.2f"):format(left))
	end
	workspace:SetAttribute("HFB_AutoTap", nil)

	-- 6. Carry
	local c = L.waitFor(function() local x = Carry.get(p); return x and x.state == "carrying" and x end, 2)
	L.check(ctx, "6 Carry.State carrying z1_t1 after the win", c ~= nil and c.creatureId == "z1_t1", c and c.creatureId)
	task.wait(0.2)
	L.check(ctx, "6 carry speed 12 (server WalkSpeed)", hum.WalkSpeed == Config.Carry.CARRY, hum.WalkSpeed)
	local cr = L.waitFor(function() local d = lastReport("carry"); return d and d.st == "carrying" and d.carried and d end, 3)
	L.check(ctx, "6 the client shows the boss carried", cr ~= nil, cr and cr.st)
	local track = Hazards.track(1)
	if L.check(ctx, "6 the log's track is stamped", track ~= nil) and c then
		local lane = workspace.Zones.Z1:FindFirstChild("Lane")
		local floorY = (lane and lane:IsA("BasePart") and (lane.Position.Y + lane.Size.Y / 2)) or 0.2
		local along = track.along
		local onLine = Vector3.new(track.home.Position.X, floorY + L.rootY(ctx), track.home.Position.Z)
		local away = onLine - along * 16 -- +Z, toward the zone (along is -Z), as M1-11's safe spot
		L.tp(ctx, away)
		task.wait(0.4)
		L.hook(ctx, "LogForce", "hit")
		local hits0 = #Hazards.stats.hits
		local grab0 = ctx.remotes["Carry.Grab"]
		-- walk toward the log line at carry speed, moved by the server in small steps (a Humanoid:MoveTo from the server
		-- did not move the character with the M1-14 client running; see the evidence file). The speed check is not reset:
		-- this walk must pass it.
		local pb0 = Carry.stats.pulledBack
		local startPos = hrp.Position
		local d = nil
		local tw = os.clock()
		local last = os.clock()
		while os.clock() - tw < 4 do
			local x = Carry.get(p)
			if x and x.state == "dropped" then d = x; break end
			local dt = os.clock() - last
			last = os.clock()
			local toGo = onLine - hrp.Position
			local flatGo = Vector3.new(toGo.X, 0, toGo.Z)
			if flatGo.Magnitude > 0.2 then
				local stepLen = math.min(flatGo.Magnitude, Config.Carry.CARRY * dt)
				ctx.char:PivotTo(CFrame.new(hrp.Position + flatGo.Unit * stepLen))
			end
			task.wait()
		end
		L.note(ctx, ("walked %.2f studs toward the log line in %.2f s; speed-check pull-backs %d"):format(L.flat(hrp.Position, startPos), os.clock() - tw, Carry.stats.pulledBack - pb0))
		workspace:SetAttribute("HFB_LogForce", "clear")
		local hit = Hazards.stats.hits[#Hazards.stats.hits]
		if L.check(ctx, "6 walking onto the log's path with LogForce hit: dropped", d ~= nil and #Hazards.stats.hits > hits0, L.carryState(ctx)) then
			task.wait(0.15)
			local push = L.flat(hrp.Position, hit.pos)
			L.check(ctx, "6 pushed back about 6 studs (4 to 8)", push >= 4 and push <= 8, ("%.2f"):format(push))
			L.check(ctx, "6 graceEnds about 5 s ahead", math.abs(d.graceEnds - hit.at - Config.Carry.GRAB_S) < 0.1, ("%.2f"):format(d.graceEnds - hit.at))
			local dr = L.waitFor(function() local x = lastReport("carry"); return x and x.st == "dropped" and x end, 2)
			L.check(ctx, "6 the client shows the boss dropped", dr ~= nil, dr and dr.st)
			L.hook(ctx, "AutoInteract", true)
			local g = L.waitFor(function() local x = Carry.get(p); return x and x.state == "carrying" and x end, 3)
			workspace:SetAttribute("HFB_AutoInteract", nil)
			L.check(ctx, "6 Carry.Grab from the client -> carrying again", g ~= nil and ctx.remotes["Carry.Grab"] > grab0, ("state %s, Grab sent %d"):format(L.carryState(ctx), ctx.remotes["Carry.Grab"] - grab0))
		end
		workspace:SetAttribute("HFB_LogForce", nil)
	end

	-- 7. Place
	local led7 = #ctx.ledger
	if L.carryState(ctx) == "carrying" then
		local place0 = ctx.remotes["Base.Place"]
		local placed0 = #Base.stats.placed
		local uid = Carry.get(p).uid
		L.tp(ctx, L.onPart(ctx, plot.Spot_1))
		task.wait(0.3)
		L.hook(ctx, "AutoInteract", true)
		local ok = L.waitFor(function() return L.prof(ctx).spots[1] ~= nil end, 3)
		workspace:SetAttribute("HFB_AutoInteract", nil)
		L.check(ctx, "7 Base.Place from the client on spot 1: placed with the carried uid", ok and L.prof(ctx).spots[1].uid == uid and #Base.stats.placed == placed0 + 1 and ctx.remotes["Base.Place"] > place0, ("Place sent %d"):format(ctx.remotes["Base.Place"] - place0))
		L.check(ctx, "7 carry is none after the place", L.carryState(ctx) == "none", L.carryState(ctx))
		local pl = Base.payload(plot)
		L.check(ctx, "7 Base.State shows spot 1", pl.spots[1] and pl.spots[1].uid == uid and pl.spots[2] == false)
		local br = L.waitFor(function() local x = lastReport("base"); return x and x.placed == 1 and x end, 3)
		L.check(ctx, "7 the client shows one boss placed", br ~= nil, br and br.placed)
		-- a second place on the same spot (forged: the client offers no prompt on a taken spot) is refused
		ctx.expect = "hook"
		L.hook(ctx, "GrantBoss", "z1_t1")
		L.waitFor(function() return L.carryState(ctx) == "carrying" end, 2)
		ctx.expect = nil
		local before = L.snap(ctx)
		local why = Base.tryPlace(p, 1)
		L.check(ctx, "7 a second place on the same spot is refused (no state change)", why == "taken" and L.snap(ctx) == before, tostring(why))
	else
		L.check(ctx, "7 place: not carrying, step skipped", false, L.carryState(ctx))
	end

	-- 8. Earn and collect
	if L.prof(ctx).spots[1] then
		L.tp(ctx, plot.Spot_1.Position + Vector3.new(0, 3, 12))
		ctx.expect = nil
		L.hook(ctx, "ClockOffset", 30)
		local onSrv = L.waitFor(function() local v = Income.onPad(L.prof(ctx).spots[1]); return v >= 30 and v end, 2)
		local shown = L.waitFor(function()
			local x = lastReport("base")
			if x and x.pads then for _, v in pairs(x.pads) do if v[1] >= 30 and v[1] <= 32 then return v end end end
		end, 3)
		L.check(ctx, "8 ClockOffset +30: the client's pad shows 30 x $1", shown ~= nil, shown and (s(shown[1]) .. " " .. tostring(shown[2])))
		local cash0 = L.prof(ctx).cash
		local col0 = #Income.stats.collects
		L.tp(ctx, L.onPart(ctx, plot.CashPad_1))
		local col = L.waitFor(function() return Income.stats.collects[col0 + 1] end, 2)
		L.check(ctx, "8 stepping on CashPad_1: Base.Collected amount 30 (+/- 1)", col ~= nil and col.spotIndex == 1 and math.abs(col.amount - 30) <= 1, col and col.amount)
		L.check(ctx, "8 server cash += the amount", col ~= nil and L.prof(ctx).cash == cash0 + col.amount, ("%s -> %s"):format(s(cash0), s(L.prof(ctx).cash)))
		L.tp(ctx, plot.Spot_1.Position + Vector3.new(0, 3, 12))
		workspace:SetAttribute("HFB_ClockOffset", nil)
	else
		L.check(ctx, "8 earn and collect: nothing placed, step skipped", false)
	end
	task.wait(0.3)
	-- 9. authority over steps 5-8: power and cash changes have server causes; damage, win, drop, place each came from
	-- a server log entry that followed a client remote
	L.authority(ctx, led0, "steps 5-8")
	local _ = led7
	local beatsOk = true
	for _, e in ipairs(Fight.stats.log) do
		if e.kind == "beat" then
			local found = false
			for _, b in ipairs(Punch.stats.log) do if b.userId == p.UserId and b.context == "fight" and b.seq == e.burstSeq and b.n == e.n then found = true end end
			if not found then beatsOk = false end
		end
	end
	L.check(ctx, "9 every fight damage beat has an applied Punch beat (server queue) behind it", beatsOk)
	L.check(ctx, "9 results carried by remotes: Punch.Report, Fight.Start, Carry.Grab, Base.Place each > 0",
		ctx.remotes["Punch.Report"] > 0 and ctx.remotes["Fight.Start"] > 0 and ctx.remotes["Carry.Grab"] > 0 and ctx.remotes["Base.Place"] > 0,
		("%d/%d/%d/%d"):format(ctx.remotes["Punch.Report"], ctx.remotes["Fight.Start"], ctx.remotes["Carry.Grab"], ctx.remotes["Base.Place"]))
end

local ok, err = xpcall(function()
	if ARGS.phase == "b" then phaseB() else phaseA() end
end, debug.traceback)
if not ok then L.check(ctx, "the check ran without a script error", false, tostring(err):sub(1, 500)) end
L.finish(ctx)
