if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-11 server check: carry, the Rolling Log, base, income. Run with run_script_in_play_mode (start_play).
-- Drives the server modules directly (handlers after Net's limiter); reads module state, never the client's.
local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local SSS = game:GetService("ServerScriptService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local SH = require(game.ReplicatedStorage.Shared.Hazards)
local Punch = require(SSS.Systems.Punch)
local Fight = require(SSS.Systems.Fight)
local Zones = require(SSS.Systems.Zones)
local Carry = require(SSS.Systems.Carry)
local Hazards = require(SSS.Systems.Hazards)
local Base = require(SSS.Systems.Base)
local Income = require(SSS.Systems.Income)
local Session = require(SSS.Data.Session)

local out, pass, fail = {}, 0, 0
local function log(s) table.insert(out, s) end
local function check(name, ok, detail)
	if ok then pass += 1 else fail += 1 end
	log((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" | " .. tostring(detail)) or ""))
end
local errs = {}
local conn = LogService.MessageOut:Connect(function(m, t)
	if t == Enum.MessageType.MessageError or (t == Enum.MessageType.MessageWarning and m:find("%[HFB%]") and not m:find("TestReport")) then
		table.insert(errs, m)
	end
end)
local function f2(x) return ("%.2f"):format(x) end

local p = Players:GetPlayers()[1]
local t0 = os.clock()
while not p and os.clock() - t0 < 15 do task.wait(0.1); p = Players:GetPlayers()[1] end
local char = p.Character or p.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")
task.wait(1.5)
for _, e in ipairs(LogService:GetLogHistory()) do
	if e.messageType == Enum.MessageType.MessageError then table.insert(errs, "history: " .. e.message) end
	if e.messageType == Enum.MessageType.MessageWarning and e.message:find("%[HFB%]") and not e.message:find("TestReport") then table.insert(errs, "history: " .. e.message) end
end
local plot = workspace.Plots.Plot1
local function state() local c = Carry.get(p); return c and c.state or "none" end
local function tp(pos) char:PivotTo(CFrame.new(pos)); hrp.AssemblyLinearVelocity = Vector3.zero; Carry.resetAnchor(p) end
local function flat(a, b) return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude end
local ROOTY = hrp.Position.Y - (plot.SpawnPoint.Position.Y + plot.SpawnPoint.Size.Y / 2) -- root height above a floor

-- 1. a real win puts the boss on the head
local pad = Zones.pad("z1_fixed")
check("z1_fixed pad registered", pad ~= nil)
Session.set(p, "power", 1000)
tp(pad.ring.Position + Vector3.new(0, 0.5 + ROOTY, 0))
task.wait(0.3)
local f = Fight.begin(p, "z1_fixed")
check("fight started at Power 1000", f ~= nil)
Punch.report(p, { seq = 1, context = "fight", grade = "good", tapServerTime = workspace:GetServerTimeNow() })
local w = os.clock()
while state() ~= "carrying" and os.clock() - w < 2 do task.wait(0.05) end
local c = Carry.get(p)
check("win -> Carry carrying z1_t1", c and c.state == "carrying" and c.creatureId == "z1_t1", c and c.creatureId)
check("session.carry set with the uid", Session.get(p).carry and Session.get(p).carry.uid == (c and c.uid))
task.wait(0.1)
check("WalkSpeed 12 while carrying", hum.WalkSpeed == Config.Carry.CARRY, hum.WalkSpeed)
-- 2. refusals while carrying
check("Fight.canStart while carrying -> carrying", Fight.canStart(p, "z1_fixed") == "carrying", Fight.canStart(p, "z1_fixed"))
check("Carry.begin while carrying refused (no second boss)", Carry.begin(p, "z1_t1") == nil and Carry.get(p).uid == c.uid)

-- 3. speed enforced
hum.WalkSpeed = 40
task.wait(0.1)
check("WalkSpeed put back to 12 after a change", hum.WalkSpeed == 12, hum.WalkSpeed)
local lane = workspace.Zones.Z1:FindFirstChild("Lane")
local track = Hazards.track(1)
check("log track stamped (TrackHome attribute)", track ~= nil and typeof(workspace.Zones.Z1.Hazard_Log:GetAttribute("TrackHome")) == "CFrame")
local floorY = (lane and (lane.Position.Y + lane.Size.Y / 2)) or 0.2
-- a spot on the lane away from the log: 20 studs toward the zone from the log line
local safe = Vector3.new(track.home.Position.X, floorY + ROOTY, track.home.Position.Z + 20)
workspace:SetAttribute("HFB_LogForce", "clear")
tp(safe)
task.wait(0.7)
local pb0 = Carry.stats.pulledBack
local before = hrp.Position
char:PivotTo(CFrame.new(before + Vector3.new(0, 0, 20))) -- a 20-stud jump in one frame, not by the server's push
task.wait(0.8)
check("a 20-stud jump while carrying is pulled back", Carry.stats.pulledBack == pb0 + 1 and flat(hrp.Position, before) < 3, ("pulledBack %d, %.2f from start"):format(Carry.stats.pulledBack - pb0, flat(hrp.Position, before)))
-- legit walk: 12 studs/s
tp(safe)
task.wait(0.6)
local pb1 = Carry.stats.pulledBack
local s0 = hrp.Position
hum:MoveTo(s0 + Vector3.new(0, 0, 30))
task.wait(2)
local moved = flat(hrp.Position, s0)
check("walking while carrying is about 12 studs/s and not pulled back", Carry.stats.pulledBack == pb1 and moved > 18 and moved < 27, ("%.2f studs in 2 s"):format(moved))
hum:MoveTo(hrp.Position)

-- 4. the log: LogForce clear never hits
local onLine = Vector3.new(track.home.Position.X, floorY + ROOTY, track.home.Position.Z)
tp(onLine)
local hits0 = #Hazards.stats.hits
task.wait(SH.logPeriod() + 0.5)
check("LogForce clear: 8.5 s on the log line, never hit", state() == "carrying" and #Hazards.stats.hits == hits0, state())
workspace:SetAttribute("HFB_LogForce", nil)
-- natural hit: stand on the lane centre on the log line; the log crosses it every 4 s
tp(onLine)
local posBefore = hrp.Position
w = os.clock()
while state() == "carrying" and os.clock() - w < SH.logPeriod() + 1 do task.wait() end
local d = Carry.get(p)
local hit = Hazards.stats.hits[#Hazards.stats.hits]
task.wait(0.1)
check("the log hits the carrier: state dropped", d and d.state == "dropped", state())
if d and hit then
	local off = SH.logOffset(hit.at, track.laneWidth)
	check("hit when the log was on the carrier (offset at hit vs carrier across)", math.abs(off - (hit.pos - track.home.Position):Dot(track.across)) < Config.Hazards.LOG.thickness / 2 + SH.BODY_RADIUS, ("log offset %.2f"):format(off))
	check("graceEnds about 5 s ahead", math.abs(d.graceEnds - hit.at - Config.Carry.GRAB_S) < 0.05, f2(d.graceEnds - hit.at))
	local push = flat(hrp.Position, posBefore)
	check("carrier pushed back about 6 (4..8) along the lane", push >= 4 and push <= 8 and math.abs(hrp.Position.X - posBefore.X) < 0.5, f2(push))
	check("dropPos where the carrier stood", flat(d.dropPos, posBefore) < 1, f2(flat(d.dropPos, posBefore)))
	check("WalkSpeed back to 16 while dropped", hum.WalkSpeed == 16, hum.WalkSpeed)
	check("fight still refused during the grace (TEAM CALL M1-11b)", Fight.canStart(p, "z1_fixed") == "carrying")
	-- 5. grab rules
	workspace:SetAttribute("HFB_LogForce", "clear") -- the log must not take it again while we test
	check("grab with a wrong uid refused", Carry.tryGrab(p, "nope") == "uid")
	check("grab with a non-string uid refused", Carry.tryGrab(p, 42) == "bad")
	tp(d.dropPos + Vector3.new(0, ROOTY, 20))
	task.wait(0.1)
	check("grab 20 studs away refused (range)", Carry.tryGrab(p, d.uid) == "range")
	tp(d.dropPos + Vector3.new(0, ROOTY, 9))
	task.wait(0.1)
	check("grab 9 studs away inside the grace -> carrying", Carry.tryGrab(p, d.uid) == nil and state() == "carrying" and hum.WalkSpeed == 12, state())
	-- walk-in grab
	workspace:SetAttribute("HFB_LogForce", "hit")
	tp(onLine)
	task.wait(0.2)
	local d2 = Carry.get(p)
	check("LogForce hit drops at once on the log's path", d2 and d2.state == "dropped", state())
	workspace:SetAttribute("HFB_LogForce", "clear")
	tp(d2.dropPos + Vector3.new(0, ROOTY, 1))
	task.wait(0.2)
	check("walking into the dropped boss grabs it", state() == "carrying", state())
	-- grace runs out
	workspace:SetAttribute("HFB_LogForce", "hit")
	tp(onLine)
	task.wait(0.2)
	local d3 = Carry.get(p)
	workspace:SetAttribute("HFB_LogForce", "clear")
	tp(safe)
	task.wait(Config.Carry.GRAB_S + 0.3)
	check("not grabbed in 5 s: the boss is gone", state() == "none" and Session.get(p).carry == nil, state())
	check("late grab refused", d3 and Carry.tryGrab(p, d3.uid) == "state")
	check("after the grace a fight is no longer refused 'carrying'", Fight.canStart(p, "z1_fixed") ~= "carrying", Fight.canStart(p, "z1_fixed"))
end
workspace:SetAttribute("HFB_LogForce", nil)

-- 6. place
check("place when not carrying refused", Base.tryPlace(p, 1) == "notCarrying")
workspace:SetAttribute("HFB_GrantBoss", "z1_t1")
task.wait(0.2)
check("GrantBoss -> carrying, attribute consumed", state() == "carrying" and workspace:GetAttribute("HFB_GrantBoss") == nil, state())
local glowAll = true
for i = 1, 10 do if plot["Spot_" .. i]:GetAttribute("Glow") ~= true then glowAll = false end end
check("all 10 empty spots Glow = true while carrying", glowAll)
for _, bad in ipairs({ 0, 11, 1.5, "1", 0 / 0, math.huge }) do
	check("place spotIndex " .. tostring(bad) .. " refused bad", Base.tryPlace(p, bad) == "bad")
end
tp(safe)
task.wait(0.1)
check("place from the lane refused (range)", Base.tryPlace(p, 1) == "range")
-- another plot's spot: a temporary Plot2 copy 300 studs away, owned by someone else
local other = plot:Clone()
other.Name = "PlotTmpCheck"; other:SetAttribute("PlotId", 99); other:SetAttribute("OwnerUserId", 999)
other:PivotTo(plot:GetPivot() + Vector3.new(0, 0, -300))
other.Parent = workspace.Plots
tp(other.Spot_1.Position + Vector3.new(0, 0.5 + ROOTY, 0))
task.wait(0.1)
check("standing on another plot's Spot_1, place 1 refused (not the player's spot)", Base.tryPlace(p, 1) == "range" and Session.get(p).spots[1] == nil)
other:Destroy()
tp(plot.Spot_1.Position + Vector3.new(0, 0.5 + ROOTY, 0))
task.wait(0.1)
local cuid = Carry.get(p).uid
check("place on own empty Spot_1", Base.tryPlace(p, 1) == nil and Session.get(p).spots[1] and Session.get(p).spots[1].uid == cuid)
check("carry ends on place, WalkSpeed 16", state() == "none" and Session.get(p).carry == nil and hum.WalkSpeed == 16, hum.WalkSpeed)
local glowNone = true
for i = 1, 10 do if plot["Spot_" .. i]:GetAttribute("Glow") ~= false then glowNone = false end end
check("Glow false on every spot when not carrying", glowNone)
local pl = Base.payload(plot)
check("Base.State payload: dense 10, spot 1 filled (income 1, cap 7200), 2 false", #pl.spots == 10 and pl.spots[1].income == 1 and pl.spots[1].capSeconds == 7200 and pl.spots[2] == false and pl.ownerUserId == p.UserId, #pl.spots)
workspace:SetAttribute("HFB_GrantBoss", "z1_t1")
task.wait(0.2)
check("place on the taken Spot_1 refused", Base.tryPlace(p, 1) == "taken" and state() == "carrying")
tp(plot.Spot_2.Position + Vector3.new(0, 0.5 + ROOTY, 0))
task.wait(0.1)
check("place on Spot_2", Base.tryPlace(p, 2) == nil)

-- 7. income from stamps, collect by touch
local cash0 = Session.get(p).cash
local s1 = Session.get(p).spots[1]
check("pad 1 just after placing holds 0..2", Income.onPad(s1) <= 2, Income.onPad(s1))
workspace:SetAttribute("HFB_ClockOffset", 30)
task.wait(0.1)
local on1 = Income.onPad(s1)
check("ClockOffset +30: pad 1 holds 30..32", on1 >= 30 and on1 <= 32, on1)
tp(plot.CashPad_1.Position + Vector3.new(0, 0.5 + ROOTY, 0))
task.wait(0.3)
local col = Income.stats.collects[#Income.stats.collects]
check("touch CashPad_1 collects about 30", col and col.spotIndex == 1 and math.abs(col.amount - on1) <= 1, col and col.amount)
check("cash raised on the server by the amount", Session.get(p).cash == cash0 + (col and col.amount or -1), Session.get(p).cash)
check("pad 1 empty after the collect", Income.onPad(Session.get(p).spots[1]) <= 1)
tp(safe)
workspace:SetAttribute("HFB_ClockOffset", 30 + 9000)
task.wait(0.1)
check("pad 2 caps at 2 h (7200)", Income.onPad(Session.get(p).spots[2]) == 7200, Income.onPad(Session.get(p).spots[2]))
local cash1 = Session.get(p).cash
tp(plot.CashPad_2.Position + Vector3.new(0, 0.5 + ROOTY, 0))
task.wait(0.3)
check("collect pad 2 = 7200", Session.get(p).cash == cash1 + 7200, Session.get(p).cash - cash1)
tp(safe)
workspace:SetAttribute("HFB_ClockOffset", nil)

-- 8. death while carrying: gone
workspace:SetAttribute("HFB_GrantBoss", "z1_t1")
task.wait(0.2)
hum.Health = 0
task.wait(0.3)
check("death while carrying: the boss is gone", state() == "none")

-- cleanup and errors
for _, n in ipairs({ "LogForce", "GrantBoss", "ClockOffset" }) do workspace:SetAttribute("HFB_" .. n, nil) end
task.wait(0.2)
conn:Disconnect()
check("no errors or [HFB] warnings", #errs == 0, table.concat(errs, " || "))
log(("refused Base %s | Carry %s"):format(game.HttpService:JSONEncode(Base.stats.refused), game.HttpService:JSONEncode(Carry.stats.refused)))
log(("TOTAL %d PASS, %d FAIL"):format(pass, fail))
print(table.concat(out, "\n"))
return table.concat(out, "\n")
