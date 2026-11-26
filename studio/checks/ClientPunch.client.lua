if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-07: client probe for the untimed punch, the ring rules, the routing of every input source, and the fight camera numbers.
-- Installed as StarterPlayerScripts.HFB_ClientPunchProbe for the check only, removed after. The server side of the run
-- (set Power, stand the player on the bag pad, then at Power 25 in Chomp Frog's ring) is in the check's play-mode calls.
-- Workspace.HFB_M207Phase (check-only switch): "bag" (ring rules) or "fight" (camera). Results go out as
-- Profile.TestReport m207_<n> (the server prints them) and print().
-- LIMIT: real key/mouse/touch events can not be injected from Studio scripts (VirtualInputManager needs RobloxScript
-- capability, measured M2-07): every source goes through Input.fire (what the InputBegan handler and the Huss button call)
-- and the routing table through Input.route (what the handler calls); a real F / click / tap is on the manager's checklist.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local C = script.Parent:WaitForChild("Controllers")
local Ring = require(C:WaitForChild("Ring"))
local Fight = require(C:WaitForChild("Fight"))
local Input = require(C:WaitForChild("Input"))
local BurstClock = require(C:WaitForChild("BurstClock"))
local Audio = require(C:WaitForChild("Audio"))
local Config = require(RS.Shared:WaitForChild("Config"))
local Net = require(RS.Shared:WaitForChild("Net"))
local lp = Players.LocalPlayer
local n = 0
local function report(line)
	n += 1
	print("M207|" .. line)
	Net.get("Profile", "TestReport"):FireServer({ name = "m207_" .. n, json = HttpService:JSONEncode({ line = line:sub(1, 900) }) })
	task.wait(0.25)
end
local function waitUntil(t) while os.clock() < t do RunService.Heartbeat:Wait() end end
local function waitRing(nAfter)
	repeat RunService.Heartbeat:Wait() until Ring.current().phase == "ring" and Ring.current().n > nAfter
	return Ring.current()
end
local function lastLog() return Ring.log[#Ring.log] end
local phase = tostring(workspace:GetAttribute("HFB_M207Phase") or "bag")
repeat task.wait(0.5) until lp.Character and Net.get("Punch", "Report")
task.wait(1)

if phase == "bag" then
	report(("config RING1=%s GRACE=%s untimedValue=%s"):format(tostring(Config.Punch.RING[1]), tostring(Config.Punch.RING_GRACE_S), tostring(Config.Punch.GRADE_VALUE.untimed)))
	-- routing table (the handler's own function)
	local r = {}
	for _, kc in ipairs({ Enum.KeyCode.F, Enum.KeyCode.ButtonR2, Enum.KeyCode.E, Enum.KeyCode.Backspace }) do r[kc.Name] = Input.route(kc, Enum.UserInputType.Keyboard) or "none" end
	r.MouseButton1 = Input.route(Enum.KeyCode.Unknown, Enum.UserInputType.MouseButton1) or "none"
	report("route " .. HttpService:JSONEncode(r))
	local cur = waitRing(0)
	-- ring A: grace tap (ignored), untimed (keyboard), spent tap (ignored)
	local ig0 = Ring.ignored.grace
	waitUntil(cur.r0 + 0.04); Input.fire("punch", "keyboard")
	report(("A grace tap: ignored.grace +%d, log grade %s, phase %s"):format(Ring.ignored.grace - ig0, tostring(lastLog().grade), Ring.current().phase))
	local s0 = Audio.stats.singles
	local bursts0 = #BurstClock.log
	waitUntil(cur.r0 + 0.30); Input.fire("punch", "keyboard")
	task.wait(0.05)
	report(("A untimed: grade %s phase %s singles +%d burstBeats +%d (0 expected) results-sent seq %s"):format(tostring(lastLog().grade), Ring.current().phase, Audio.stats.singles - s0, #BurstClock.log - bursts0, tostring(lastLog().seq)))
	local sp0 = Ring.ignored.spent
	waitUntil(cur.r0 + 0.45); Input.fire("punch", "keyboard")
	report(("A second tap in the spent ring: ignored.spent +%d, phase %s"):format(Ring.ignored.spent - sp0, Ring.current().phase))
	waitUntil(cur.landing + 0.05); Input.fire("punch", "keyboard")
	local landing = cur.landing
	local nxt = waitRing(cur.n)
	report(("A next ring opens at landing+%.3f (want 0.610 = MISS_RESTART), cause %s"):format(nxt.r0 - landing, tostring(lastLog().cause)))
	-- ring B: perfect via the button source (burst)
	waitUntil(nxt.landing); Input.fire("punch", "button")
	task.wait(0.05)
	report(("B perfect (button): grade %s dMs %.1f beats %d"):format(tostring(lastLog().grade), lastLog().dMs or -1, #BurstClock.log - bursts0))
	local nb = waitRing(nxt.n)
	report(("B next ring after burst: gap %.3f (want 0.61), cause %s"):format(lastLog().gap or -1, tostring(lastLog().cause)))
	-- ring C: untimed (gamepad), ring D: good (touch)
	waitUntil(nb.r0 + 0.3); Input.fire("punch", "gamepad")
	report(("C untimed (gamepad): grade %s"):format(tostring(lastLog().grade)))
	local nd = waitRing(nb.n)
	waitUntil(nd.landing + 0.07); Input.fire("punch", "touch")
	task.wait(0.05)
	report(("D good (touch): grade %s dMs %.1f"):format(tostring(lastLog().grade), lastLog().dMs or -1))
	local ne = waitRing(nd.n)
	-- ring E: no tap: miss
	waitUntil(ne.landing + Config.Punch.BAG_WINDOWS.goodMs / 1000 + 0.1)
	report(("E no tap: grade %s"):format(tostring(Ring.log[ne.n] and Ring.log[#Ring.log].grade)))
	report("counts " .. HttpService:JSONEncode(Input.counts) .. " ignored " .. HttpService:JSONEncode(Ring.ignored))
	report("done")
elseif phase == "win" then
	-- one defeat per win (m1-sync-test.md finding 1): wrap BossMoves.play and count "defeat" calls on a win
	local BM = require(C:WaitForChild("BossMoves"))
	local calls = {}
	local orig = BM.play
	BM.play = function(model, name, opts) table.insert(calls, { name = name, t = os.clock() }) return orig(model, name, opts) end
	repeat task.wait(0.2) until Fight.inStartRing()
	Input.fire("punch", "keyboard")
	local t0 = os.clock()
	repeat task.wait(0.1) until Fight.active() or os.clock() - t0 > 4
	local lastTapped = -1
	while Fight.active() and os.clock() - t0 < 20 do
		local ring = Ring.current()
		if ring.phase == "ring" and ring.n ~= lastTapped then
			lastTapped = ring.n
			waitUntil(ring.landing); Input.fire("punch", "keyboard")
		end
		RunService.Heartbeat:Wait()
	end
	task.wait(2.5)
	local d = 0
	for _, c in ipairs(calls) do if c.name == "defeat" then d += 1 end end
	report(("win: fight active %s, defeat calls %d (want 1); all plays %s"):format(tostring(Fight.active() ~= nil), d, (function() local t = {} for _, c in ipairs(calls) do table.insert(t, c.name) end return table.concat(t, ",") end)()))
	report("done")
else
	local cam = workspace.CurrentCamera
	repeat task.wait(0.2) until Fight.inStartRing()
	Input.fire("punch", "keyboard")
	local t0 = os.clock()
	repeat task.wait(0.1) until Fight.active() or os.clock() - t0 > 4
	task.wait(1)
	local f = Fight.active()
	if not f then report("FAIL no fight started") report("done") return end
	local boss = f.boss
	local bbCf, bbSize = boss:GetBoundingBox()
	local function rectOf(points, camLike, cf)
		local vp, fov = camLike.ViewportSize, camLike.FieldOfView
		local tanV = math.tan(math.rad(fov) / 2); local tanH = tanV * vp.X / vp.Y
		local u0, v0, u1, v1 = 9, 9, -9, -9
		for _, p in ipairs(points) do
			local l = cf:PointToObjectSpace(p)
			local d = math.max(-l.Z, 0.1)
			local u = 0.5 + l.X / (d * tanH) / 2; local v = 0.5 - l.Y / (d * tanV) / 2
			u0, v0, u1, v1 = math.min(u0, u), math.min(v0, v), math.max(u1, u), math.max(v1, v)
		end
		return u0, v0, u1, v1
	end
	local bossPts = {}
	for _, sx in { -0.5, 0.5 } do for _, sy in { -0.5, 0.5 } do for _, sz in { -0.5, 0.5 } do
		table.insert(bossPts, (bbCf * CFrame.new(bbSize.X * sx, bbSize.Y * sy, bbSize.Z * sz)).Position) end end end
	local avPts = {}
	for _, part in ipairs(lp.Character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			for _, sx in { -0.5, 0.5 } do for _, sy in { -0.5, 0.5 } do for _, sz in { -0.5, 0.5 } do
				table.insert(avPts, (part.CFrame * CFrame.new(part.Size.X * sx, part.Size.Y * sy, part.Size.Z * sz)).Position) end end end
		end
	end
	local head = boss:FindFirstChild("Head", true)
	local root = lp.Character.HumanoidRootPart
	report(("boss %s H %s box %.1f x %.1f x %.1f, stood %.2f from box centre, real cam %.1f from boss"):format(boss.Name, tostring(boss:GetAttribute("H")), bbSize.X, bbSize.Y, bbSize.Z, (Vector3.new(root.Position.X - bbCf.Position.X, 0, root.Position.Z - bbCf.Position.Z)).Magnitude, (cam.CFrame.Position - bbCf.Position).Magnitude))
	for _, vp in ipairs({ Vector2.new(874, 402), Vector2.new(640, 300), Vector2.new(1280, 720), Vector2.new(cam.ViewportSize.X, cam.ViewportSize.Y) }) do
		local fake = { ViewportSize = vp, FieldOfView = cam.FieldOfView }
		local cf = Fight.frameBoss(boss, root.Position, fake)
		local b = { rectOf(bossPts, fake, cf) }
		local a = { rectOf(avPts, fake, cf) }
		local h = head and { rectOf({ head.Position }, fake, cf) } or nil
		local ox = math.max(0, math.min(a[3], b[3]) - math.max(a[1], b[1])); local oy = math.max(0, math.min(a[4], b[4]) - math.max(a[2], b[2]))
		local ov = ox * oy / ((b[3] - b[1]) * (b[4] - b[2]))
		local headIn = h and (h[1] > a[1] and h[1] < a[3] and h[2] > a[2] and h[2] < a[4])
		report(("vp %dx%d box u %.2f-%.2f v %.2f-%.2f (h %.2f) | avatar u %.2f-%.2f v %.2f-%.2f (h %.2f) | avatar over box %.0f%% head covered %s | cam %.1f studs"):format(vp.X, vp.Y, b[1], b[3], b[2], b[4], b[4] - b[2], a[1], a[3], a[2], a[4], a[4] - a[2], ov * 100, tostring(headIn), (cf.Position - bbCf.Position).Magnitude))
	end
	-- the real camera, projected with WorldToViewportPoint
	local outside = 0
	for _, p in ipairs(bossPts) do local _, on = cam:WorldToViewportPoint(p); if not on then outside += 1 end end
	report(("real camera: %d boss corners off screen, camType %s"):format(outside, cam.CameraType.Name))
	-- one untimed in the fight: boss hit
	local ring = waitRing(0)
	waitUntil(ring.r0 + 0.3); Input.fire("punch", "keyboard")
	task.wait(0.4)
	local lg = lastLog()
	report(("fight untimed: grade %s ring.phase %s; boss plays %s"):format(tostring(lg.grade), Ring.current().phase, tostring(select(2, require(C:WaitForChild("BossMoves")).current(boss)))))
	Input.fire("run", "keyboard")
	task.wait(1)
	report("done")
end
