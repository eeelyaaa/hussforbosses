-- M1-14 client check: run with run_script_in_play_mode (start_play). Drives the server like the m1-11 check and reads the REAL client's
-- Profile.TestReport "carry" / "base" / "log" reports (HFB_ReportBeats). Press-paths go through HFB_AutoInteract (Input.fire "interact").
if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local SH = require(RS.Shared.Hazards)
local TestHooks = require(RS.Shared.TestHooks)
local Punch = require(SSS.Systems.Punch)
local Fight = require(SSS.Systems.Fight)
local Zones = require(SSS.Systems.Zones)
local Carry = require(SSS.Systems.Carry)
local Hazards = require(SSS.Systems.Hazards)
local Session = require(SSS.Data.Session)

local out, pass, fail = {}, 0, 0
local function check(name, ok, detail)
	if ok then pass += 1 else fail += 1 end
	table.insert(out, (ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" | " .. tostring(detail)) or ""))
end
local errs = {}
LogService.MessageOut:Connect(function(m, t)
	if t == Enum.MessageType.MessageError or (t == Enum.MessageType.MessageWarning and m:find("%[HFB%]") and not m:find("TestReport")) then table.insert(errs, m) end
end)
local function rep(name)
	local r = TestHooks.reports[name]
	if not r then return nil end
	return HttpService:JSONDecode(r.json), workspace:GetServerTimeNow() - r.at
end
local function fresh(name, secs) -- wait for a report newer than now
	local t0 = workspace:GetServerTimeNow()
	local w = os.clock()
	while os.clock() - w < (secs or 2) do
		local r = TestHooks.reports[name]
		if r and r.at > t0 then return rep(name) end
		task.wait(0.05)
	end
	return rep(name)
end
local function untilState(want, secs)
	local w = os.clock()
	while os.clock() - w < secs do
		local c = Carry.get(Players:GetPlayers()[1])
		if (c and c.state or "none") == want then return true end
		task.wait(0.05)
	end
	return false
end

local p = Players:GetPlayers()[1]
local t0 = os.clock()
while not p and os.clock() - t0 < 15 do task.wait(0.1); p = Players:GetPlayers()[1] end
local char = p.Character or p.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
task.wait(2)
workspace:SetAttribute("HFB_ReportBeats", true)
local plot = workspace.Plots.Plot1
local function state() local c = Carry.get(p); return c and c.state or "none" end
local function tp(pos) char:PivotTo(CFrame.new(pos)); hrp.AssemblyLinearVelocity = Vector3.zero; Carry.resetAnchor(p) end
local ROOTY = hrp.Position.Y - (plot.SpawnPoint.Position.Y + plot.SpawnPoint.Size.Y / 2)
local track = Hazards.track(1)
local floorY = 0.2
local onLine = Vector3.new(track.home.Position.X, floorY + ROOTY, track.home.Position.Z)
local function refusedTotal() local n = 0 for _, v in pairs(Carry.stats.refused) do n += v end return n end

-- 1. the log drawn on the client against the server's pure function at the same clock time
local lg = fresh("log", 2)
check("client sends log reports", lg ~= nil)
if lg then
	local want = SH.logOffset(lg.t, track.laneWidth)
	check("drawn log offset equals the server's logOffset(t) (<= 0.05 studs)", math.abs(lg.meas - want) < 0.05, ("meas %.3f server %.3f at t %.3f"):format(lg.meas, want, lg.t))
	check("client clock offset 0 with no hook", math.abs(lg.co) < 0.01, lg.co)
	-- a sample while moving: wait for a moving phase
	local w = os.clock(); local moving
	repeat lg = fresh("log", 1); local _, _, v = SH.logOffset(lg.t, track.laneWidth); moving = v ~= 0 until moving or os.clock() - w > 6
	local want2 = SH.logOffset(lg.t, track.laneWidth)
	check("moving sample matches too", moving and math.abs(lg.meas - want2) < 0.05, ("meas %.3f server %.3f"):format(lg.meas, want2))
end
workspace:SetAttribute("HFB_ClockOffset", 2.3)
task.wait(1.2)
lg = fresh("log", 1)
check("ClockOffset 2.3 reaches the client's clock", lg and math.abs(lg.co - 2.3) < 0.05, lg and lg.co)
if lg then check("the drawn log follows the shifted clock", math.abs(lg.meas - SH.logOffset(lg.t, track.laneWidth)) < 0.05) end
workspace:SetAttribute("HFB_ClockOffset", nil)
task.wait(1.2)
lg = fresh("log", 1)
check("clock back to 0", lg and math.abs(lg.co) < 0.01, lg and lg.co)

-- 2. win -> carrying
workspace:SetAttribute("HFB_LogForce", "clear")
local pad = Zones.pad("z1_fixed")
Session.set(p, "power", 1000)
tp(pad.ring.Position + Vector3.new(0, 0.5 + ROOTY, 0))
task.wait(0.3)
local f = Fight.begin(p, "z1_fixed")
check("fight started", f ~= nil)
Punch.report(p, { seq = 1, context = "fight", grade = "good", tapServerTime = workspace:GetServerTimeNow() })
check("server state carrying", untilState("carrying", 3))
local c1 = fresh("carry", 1.5)
check("carry: server state seen by the client", c1 and c1.st == "carrying", c1 and c1.st)
task.wait(2)
local c2 = fresh("carry", 1.5) or rep("carry")
check("carried clone exists, on the head (<0.3 studs), carryRock playing, pad boss hidden", c2 and c2.carried and c2.headDist and c2.headDist < 0.3 and c2.rock == "carryRock" and c2.hidden, HttpService:JSONEncode(c2))
check("not mid-hop after 2 s", c2 and not c2.hop)

-- 3. the log hits: dropped, plate, grab prompt gating
workspace:SetAttribute("HFB_LogForce", "hit")
tp(onLine)
check("server: dropped", untilState("dropped", 3))
workspace:SetAttribute("HFB_LogForce", "clear")
task.wait(0.5)
local d1 = fresh("carry", 1.5) or rep("carry")
check("client: dropped boss lying, plate 1..5, Grab prompt up, carried gone", d1 and d1.dropped and tonumber(d1.plate) and tonumber(d1.plate) >= 1 and tonumber(d1.plate) <= 5 and d1.grab and not d1.carried, HttpService:JSONEncode(d1))
-- far away: no prompt, and the client sends nothing even with E pressed
local dp = Carry.get(p).dropPos
local refused0 = refusedTotal()
tp(dp + Vector3.new(0, ROOTY, 30))
task.wait(0.6)
workspace:SetAttribute("HFB_AutoInteract", true)
task.wait(1.6)
local d2 = rep("carry")
check("30 studs away: Grab prompt down, no Carry.Grab sent (server refusals unchanged), still dropped", d2 and not d2.grab and refusedTotal() == refused0 and state() == "dropped", ("grab %s refused %d->%d"):format(tostring(d2 and d2.grab), refused0, refusedTotal()))
tp(dp + Vector3.new(0, ROOTY, 9))
check("9 studs away + E: the client's Carry.Grab puts it back on the head", untilState("carrying", 3))
workspace:SetAttribute("HFB_AutoInteract", nil)
task.wait(0.6)
local g1 = fresh("carry", 1.5) or rep("carry")
check("after the grab: carried, no plate, no prompt", g1 and g1.carried and not g1.dropped and not g1.grab and g1.headDist < 0.3, HttpService:JSONEncode(g1))

-- 4. grace over
workspace:SetAttribute("HFB_LogForce", "hit")
tp(onLine)
untilState("dropped", 3)
workspace:SetAttribute("HFB_LogForce", "clear")
tp(Carry.get(p).dropPos + Vector3.new(0, ROOTY, 30))
check("grace over: server none", untilState("none", 7))
task.wait(0.8)
local n1 = fresh("carry", 1.5) or rep("carry")
check("client: nothing carried or dropped, prompts down", n1 and n1.st == "none" and not n1.carried and not n1.dropped and not n1.grab, HttpService:JSONEncode(n1))

-- 5. place
workspace:SetAttribute("HFB_GrantBoss", "z1_t1")
check("GrantBoss -> carrying", untilState("carrying", 3))
tp(onLine + Vector3.new(0, 0, 25))
task.wait(0.8)
local b0 = fresh("base", 1.5) or rep("base")
check("carrying but far from the plot: no Place prompt", b0 and not b0.place, b0 and tostring(b0.place))
tp(plot.Spot_1.Position + Vector3.new(0, 0.5 + ROOTY, 0))
task.wait(0.8)
local b1 = fresh("base", 1.5) or rep("base")
check("at the plot: Place prompt up and all 10 empty spots glow", b1 and b1.place and b1.glowOn == 10, HttpService:JSONEncode(b1))
workspace:SetAttribute("HFB_AutoInteract", true)
local w = os.clock()
while not (Session.get(p).spots and Session.get(p).spots[1]) and os.clock() - w < 3 do task.wait(0.05) end
workspace:SetAttribute("HFB_AutoInteract", nil)
check("E on the Place prompt: the server placed on a spot", Session.get(p).spots and Session.get(p).spots[1] ~= nil)
task.wait(1.6)
local b2 = fresh("base", 1.5) or rep("base")
local c3 = rep("carry")
check("client: a placed boss on the spot playing halfIdle, glow off, no prompt, carried gone", b2 and b2.placed == 1 and b2.glowOn == 0 and not b2.place and c3 and not c3.carried and b2.uids["1:1"] and b2.uids["1:1"][2] == "halfIdle", HttpService:JSONEncode(b2))

-- 6. cash on the pad and collect
workspace:SetAttribute("HFB_ClockOffset", 30)
task.wait(1.5)
local b3 = fresh("base", 1.5) or rep("base")
local shown = b3 and b3.pads["1:1"]
check("pad 1 cash shown on the client matches the server (income 1 x floor secs)", shown and shown[1] >= 30 and shown[1] <= 33 and shown[2] == "$" .. shown[1] and shown[3] >= 1, HttpService:JSONEncode(shown))
local cash0 = Session.get(p).cash
tp(plot.CashPad_1.Position + Vector3.new(0, 0.5 + ROOTY, 0))
task.wait(1.2)
check("collected: server cash up by about 30", Session.get(p).cash - cash0 >= 30 and Session.get(p).cash - cash0 <= 34, Session.get(p).cash - cash0)
local b4 = fresh("base", 1.5) or rep("base")
check("pad cash shown is empty after the collect", b4 and not b4.pads["1:1"], HttpService:JSONEncode(b4 and b4.pads))
workspace:SetAttribute("HFB_ClockOffset", nil)
workspace:SetAttribute("HFB_LogForce", nil)
workspace:SetAttribute("HFB_ReportBeats", nil)
task.wait(0.5)
check("no errors or [HFB] warnings", #errs == 0, table.concat(errs, " || "):sub(1, 600))
print(("M1-14 client check: %d PASS, %d FAIL"):format(pass, fail))
for _, l in ipairs(out) do print(l) end
