if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local SSS = game:GetService("ServerScriptService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Net = require(game.ReplicatedStorage.Shared.Net)
local Punch = require(SSS.Systems.Punch)
local Fight = require(SSS.Systems.Fight)
local Bag = require(SSS.Systems.Bag)
local Zones = require(SSS.Systems.Zones)
local Session = require(SSS.Data.Session)

local out, pass, fail = {}, 0, 0
local function log(s) table.insert(out, s) end
local function check(name, ok, detail)
	if ok then pass += 1 else fail += 1 end
	log((ok and "PASS " or "FAIL ") .. name .. (detail and (" | " .. tostring(detail)) or ""))
end
local errs = {}
local conn = LogService.MessageOut:Connect(function(m, t)
	if t == Enum.MessageType.MessageError or (t == Enum.MessageType.MessageWarning and m:find("%[HFB%]") and not m:find("TestReport")) then
		table.insert(errs, m)
	end
end)

local p = Players:GetPlayers()[1]
local t = os.clock()
while not p and os.clock() - t < 15 do task.wait(0.1); p = Players:GetPlayers()[1] end
local char = p.Character or p.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
task.wait(1)
local now = function() return workspace:GetServerTimeNow() end
local seq = 0
local function rep(context, grade, tapOff, extra)
	seq += 1
	local pl = { seq = seq, context = context, grade = grade }
	if tapOff ~= false then pl.tapServerTime = now() + (tapOff or 0) end
	for k, v in pairs(extra or {}) do pl[k] = v end
	Punch.report(p, pl)
	return Punch.stats.lastResult[p.UserId], seq
end
local function power() return Session.get(p).power end

-- 0. boot
local booted = false
for _, e in ipairs(LogService:GetLogHistory()) do
	if e.message:find("%[HFB%] server up") then booted = e.message end
	if e.messageType == Enum.MessageType.MessageError then table.insert(errs, "history: " .. e.message) end
end
check("server up printed", booted ~= false, booted)

-- 1. join: plot and spawn
local plot = workspace.Plots.Plot1
check("Plot1 OwnerUserId = player", plot:GetAttribute("OwnerUserId") == p.UserId, plot:GetAttribute("OwnerUserId"))
local sp = plot.SpawnPoint
local dsp = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(sp.Position.X, 0, sp.Position.Z)).Magnitude
check("character at SpawnPoint (flat < 3)", dsp < 3, ("%.2f"):format(dsp))
check("schedule sent on join", Punch.stats.lastSchedule[p.UserId] ~= nil)

-- 2. schedule per Speed
local okAll, rows = true, {}
for lv = 1, 10 do
	Session.set(p, "speedLevel", lv)
	local s = Punch.stats.lastSchedule[p.UserId]
	local want = Config.Punch.RING[lv]
	local cyc = want + 0.61
	if not (s and s.speedLevel == lv and math.abs(s.ringClose - want) < 1e-9 and math.abs(s.cycle - cyc) < 1e-9 and s.burstLen == 0.61) then okAll = false end
	table.insert(rows, ("%d:%.2f/%.2f"):format(lv, s.ringClose, s.cycle))
end
check("Punch.Schedule re-sent per Speed 1..10 (ring/cycle)", okAll, table.concat(rows, " "))
Session.set(p, "speedLevel", 1)

-- 3. on the bag pad
local pad = plot.BagPad
char:PivotTo(pad.CFrame + Vector3.new(0, pad.Size.Y / 2 + 3, 0))
local n0 = Punch.stats.schedules
task.wait(0.4)
check("Bag.onOwnPad after moving onto BagPad", Bag.onOwnPad(p))
check("schedule sent on entering the pad", Punch.stats.schedules > n0)
workspace:SetAttribute("HFB_Wipe", true)
task.wait(0.2)
check("Wipe -> power 0", power() == 0, power())
task.wait(1.6)

-- 4. Good = 4, beat times
local r, s1 = rep("bag", "good")
check("Good accepted, gains 1/1/2", r.accepted and r.gains[1] == 1 and r.gains[2] == 1 and r.gains[3] == 2, r.reason)
check("beat 1 applied at accept (power 1)", power() == 1, power())
task.wait(0.65)
check("Good burst = +4", power() == 4, power())
local lateMax, cnt = 0, 0
for _, e in ipairs(Punch.stats.log) do
	if e.seq == s1 and e.userId == p.UserId then
		cnt += 1
		lateMax = math.max(lateMax, e.late)
		check(("good beat %d at t0+%.3f (late %.1f ms)"):format(e.n, e.due - e.t0, e.late * 1000), e.late >= 0 and e.late <= 0.020)
	end
end
check("three beats logged", cnt == 3, cnt)

-- 5. refusals on the bag
local r2 = rep("bag", "perfect") -- 0.65 s after the Good: under CYCLE x 0.8 = 1.448
check("report 0.65 s after accept refused 'rate'", not r2.accepted and r2.reason == "rate", r2.reason)
task.wait(0.85) -- 1.5 s since the Good
local r3, s3 = rep("bag", "perfect")
check("Perfect accepted at 1.5 s", r3.accepted, r3.reason)
local rb = rep("bag", "good")
check("report during a burst refused 'busy'", not rb.accepted and rb.reason == "busy", rb.reason)
task.wait(0.65)
check("Perfect burst = +8 (power 12)", power() == 12, power())
for _, e in ipairs(Punch.stats.log) do
	if e.seq == s3 then
		lateMax = math.max(lateMax, e.late)
		check(("perfect beat %d at t0+%.3f (late %.1f ms) value %s"):format(e.n, e.due - e.t0, e.late * 1000, tostring(e.value)), e.late >= 0 and e.late <= 0.020)
	end
end
task.wait(1.0)
local rg = rep("bag", "good", false)
check("Good with no tapServerTime refused 'grade'", not rg.accepted and rg.reason == "grade", rg.reason)
local rf = rep("bag", "good", 1.0)
check("tapServerTime 1 s in the future refused 'grade'", not rf.accepted and rf.reason == "grade", rf.reason)
local rpst = rep("bag", "good", -1.5)
check("tapServerTime 1.5 s old refused 'grade'", not rpst.accepted and rpst.reason == "grade", rpst.reason)
local d0 = Punch.stats.dropped
rep("bag", "good", 0, { seq = "x" }); rep("bag", "great"); rep("cake", "good"); rep("bag", "good", 0, { tapServerTime = 0/0 }); rep("bag", "good", 0, { seq = math.huge })
check("5 malformed payloads dropped, no reply", Punch.stats.dropped - d0 == 5, Punch.stats.dropped - d0)
check("power unchanged by refusals (12)", power() == 12, power())
local rm = rep("bag", "miss", false)
check("bag Miss accepted, no gains", rm.accepted and rm.gains == nil)
task.wait(0.7)
check("Miss added nothing (power 12)", power() == 12, power())
check("Net rate limiter: 6 calls at 4/s allows 4", (function()
	local ok = 0
	for _ = 1, 6 do if Net.rateOk(p, "check.m106", 4) then ok += 1 end end
	return ok == 4
end)())

-- off the pad
local fixed = workspace.Zones.Z1.Pads.Fixed
local ringPart = fixed.Ring
char:PivotTo(ringPart.CFrame + Vector3.new(0, 12, 0) + Vector3.new(0, 0, -30))
task.wait(1.6)
local ro = rep("bag", "good")
check("bag report off the pad refused 'place'", not ro.accepted and ro.reason == "place", ro.reason)
local rnf = rep("fight", "good")
check("fight report with no fight refused 'place'", not rnf.accepted and rnf.reason == "place", rnf.reason)
check("Fight.Start outside the ring refused 'ring'", Fight.canStart(p, "z1_fixed") == "ring", Fight.canStart(p, "z1_fixed"))
check("Fight.Start bad padId refused", Fight.canStart(p, 5) == "bad" and Fight.canStart(p, "nope") == "pad")

-- 6. fight by hand at Power 25 vs Chomp Frog
workspace:SetAttribute("HFB_SetPower", 25)
workspace:SetAttribute("HFB_PadFastBack", 1)
task.wait(0.2)
check("SetPower hook -> 25", power() == 25, power())
char:PivotTo(ringPart.CFrame + Vector3.new(1, ringPart.Size.Y / 2 + 3, 1))
task.wait(0.3)
Session.set(p, "carry", { uid = "t", creatureId = "z1_t1" })
check("Fight.Start while carrying refused 'carrying'", Fight.canStart(p, "z1_fixed") == "carrying")
Session.set(p, "carry", nil)
local f = Fight.begin(p, "z1_fixed")
check("fight started", f ~= nil)
check("r = 1, band fair, 110/45 ms", f.ratio == 1 and f.band == "fair" and f.goodMs == 110 and f.perfectMs == 45, ("%s %s %d/%d"):format(tostring(f.ratio), f.band, f.goodMs, f.perfectMs))
check("health 250, hearts 3", f.health == 250 and f.maxHealth == 250 and f.hearts == 3)
check("held in place (WalkSpeed 0)", char.Humanoid.WalkSpeed == 0)
check("Fight.Start during a fight refused 'running'", Fight.canStart(p, "z1_fixed") == "running")
local rbf = rep("bag", "good")
check("bag report during a fight refused", not rbf.accepted, rbf.reason)
local hs = {}
local fid = f.fightId
task.wait(1.5)
for b = 1, 3 do
	local rr = rep("fight", "good")
	if b == 1 then check("fight Good accepted, gains 25/25/50", rr.accepted and rr.gains[1] == 25 and rr.gains[3] == 50, rr.reason) end
	task.wait(0.65)
	table.insert(hs, f.health)
	if b < 3 then task.wait(0.9) end
end
check("health after bursts 150, 50, 0", hs[1] == 150 and hs[2] == 50 and hs[3] == 0, table.concat(hs, ","))
local beats = {}
for _, e in ipairs(Fight.stats.log) do
	if e.fightId == fid and e.kind == "beat" then table.insert(beats, ("%d.%d:%d%s"):format(e.burstSeq, e.n, e.health, e.won and "W" or "")) end
end
check("B22: 8 Fight.Beat, won on burst 3 punch 2, none after", #beats == 8 and beats[8]:sub(-1) == "W", table.concat(beats, " "))
local third
for _, e in ipairs(Punch.stats.log) do
	if e.context == "fight" and e.seq == seq and e.n == 3 then third = e end
end
check("burst 3 punch 3 dealt nothing (no contact)", third and third.contact == false)
check("win: fight over, released", Fight.get(p) == nil and char.Humanoid.WalkSpeed > 0)
local open, left = Zones.isOpen(p, "z1_fixed")
check("pad closed after win (PadFastBack 1 s)", not open and left <= 1, ("%.2f"):format(left))
task.wait(1.1)
check("pad back after PadFastBack", (Zones.isOpen(p, "z1_fixed")))
workspace:SetAttribute("HFB_PadFastBack", nil)

-- 7. hearts: reported Miss, stall rule, loss
task.wait(1.6)
local f2 = Fight.begin(p, "z1_fixed")
check("second fight started", f2 ~= nil)
local rmiss = rep("fight", "miss", false)
check("fight Miss -> hearts 2", rmiss.accepted and f2.hearts == 2, f2.hearts)
local st0 = Punch.stats.stalls
local tw = os.clock()
while f2.hearts == 2 and os.clock() - tw < 6 do task.wait(0.05) end
local waited = os.clock() - tw
check("stall rule: no report -> server counts a Miss (hearts 1)", f2.hearts == 1 and Punch.stats.stalls == st0 + 1, ("after %.2f s (expect ~ 0.61+1.2+1.2+0.5 = 3.51)"):format(waited))
task.wait(0.3)
rep("fight", "miss", false)
check("last heart -> loss", f2.over and f2.hearts == 0 and Fight.get(p) == nil)
check("knocked down 2 s", Fight.knockedDown(p) and Fight.canStart(p, "z1_fixed") == "knocked")
local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(ringPart.Position.X, 0, ringPart.Position.Z)).Magnitude
check("knocked out of the ring", dist > 8, ("%.1f"):format(dist))
task.wait(2.1)
check("after knockdown: released, pad closed or out of ring", char.Humanoid.WalkSpeed > 0, Fight.canStart(p, "z1_fixed"))
char:PivotTo(ringPart.CFrame + Vector3.new(1, ringPart.Size.Y / 2 + 3, 1))
task.wait(0.2)
check("in the ring, pad closed (5 s cooldown)", Fight.canStart(p, "z1_fixed") == "closed", Fight.canStart(p, "z1_fixed"))
task.wait(3.0)
check("cooldown over: may start", Fight.canStart(p, "z1_fixed") == nil, Fight.canStart(p, "z1_fixed"))
local f3 = Fight.begin(p, "z1_fixed")
Fight.finish(p, f3, "run")
check("Run ends the fight, no knockdown, released", f3.over and not Fight.knockedDown(p) and char.Humanoid.WalkSpeed > 0)

workspace:SetAttribute("HFB_Wipe", true)
task.wait(0.3)
conn:Disconnect()
check("no errors or [HFB] warnings in the run", #errs == 0, table.concat(errs, " || "))
log(("max beat lateness on the bag: %.1f ms"):format(lateMax * 1000))
log(("TOTAL pass=%d fail=%d"):format(pass, fail))
print(table.concat(out, "\n"))
