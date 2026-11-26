if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-26b: client probe for the fight spot and camera. Installed as StarterPlayerScripts.HFB_FightCamProbe for the check
-- only, removed after. It starts fights the way a player does: from outside the ring it WALKS (Humanoid:MoveTo) to a
-- start spot inside the ring and presses Huss (Fight.requestStart, what the Huss button calls in start mode), or presses
-- the moment it enters the ring while still walking. After the server has stood it at the fight spot it projects the
-- boss box, the boss's head, the avatar and the HUD for the real camera and for Fight.frameBoss at 1280x720 and 874x402,
-- prints "M126|" lines and sends them as Profile.TestReport (m126_<n>, then m126_done). Then Run, wait out the pad cooldown.
-- Workspace.HFB_M126Spots (check-only switch, read here only): "a" or "b", which set of start spots; the probe runs a set when the
-- switch is set and again after it was cleared (M2-28: Gate.lua / GateRun.lua drive it, FightCamera/a and /b).
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer
local Controllers = script.Parent:WaitForChild("Controllers")
local Fight = require(Controllers:WaitForChild("Fight"))
local Config = require(ReplicatedStorage.Shared:WaitForChild("Config"))
local Net = require(ReplicatedStorage.Shared:WaitForChild("Net"))
local cam = workspace.CurrentCamera

local n = 0
local function report(line: string)
	n += 1
	print(line)
	Net.get("Profile", "TestReport"):FireServer({ name = "m126_" .. n, json = HttpService:JSONEncode({ line = line:sub(1, 900) }) })
	task.wait(0.3)
end

-- start spots, world offsets from the ring centre (x, z); the players' track arrives from -Z
local SETS = {
	a = {
		{ "zneg-near-face", 0, -3.0 },
		{ "zneg-press-on-entry", 0, -9, true },
		{ "zneg-ring-edge", 0, -5.0 },
		{ "xpos-side", 5, 0 },
	},
	b = {
		{ "xneg-side-near", -4.2, 0 },
		{ "zpos-ring-edge", 0, 5.0 },
		{ "diag-xpos-zneg", 3.6, -3.6 },
		{ "zpos-near", 0, 2.0 },
	},
}

local function cornersOf(cf, size)
	local t = {}
	for _, sx in { -0.5, 0.5 } do for _, sy in { -0.5, 0.5 } do for _, sz in { -0.5, 0.5 } do
		table.insert(t, (cf * CFrame.new(size.X * sx, size.Y * sy, size.Z * sz)).Position)
	end end end
	return t
end
local BODY = { Head = true, Torso = true, UpperTorso = true, LowerTorso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
	LeftUpperArm = true, RightUpperArm = true, LeftLowerArm = true, RightLowerArm = true, LeftHand = true, RightHand = true,
	LeftUpperLeg = true, RightUpperLeg = true, LeftLowerLeg = true, RightLowerLeg = true, LeftFoot = true, RightFoot = true }
local function avatarPoints(char)
	local t = {}
	for _, d in char:GetChildren() do
		if d:IsA("BasePart") and BODY[d.Name] then
			for _, c in cornersOf(d.CFrame, d.Size) do table.insert(t, c) end
		end
	end
	return t
end
local function rectOf(points, proj)
	local minU, maxU, minV, maxV = math.huge, -math.huge, math.huge, -math.huge
	local allIn = true
	for _, p in points do
		local u, v, ok = proj(p)
		if not ok then allIn = false end
		minU, maxU, minV, maxV = math.min(minU, u), math.max(maxU, u), math.min(minV, v), math.max(maxV, v)
	end
	return { minU, minV, maxU, maxV }, allIn
end
local function inter(a, b)
	local w = math.min(a[3], b[3]) - math.max(a[1], b[1])
	local h = math.min(a[4], b[4]) - math.max(a[2], b[2])
	return (w > 0 and h > 0) and w * h or 0, (a[3] - a[1]) * (a[4] - a[2])
end
local function fmt(r) return ("%.2f,%.2f,%.2f,%.2f"):format(r[1], r[2], r[3], r[4]) end

-- HUD rects as viewport fractions (real viewport; the kit scales, so they stand in for the other sizes)
local function hudRects()
	local vp = cam.ViewportSize
	local gui = lp.PlayerGui
	local inset = game:GetService("GuiService"):GetGuiInset()
	local huds = {}
	local function union(root)
		local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
		local list = root:GetDescendants()
		if root:IsA("GuiObject") then table.insert(list, root) end
		for _, d in list do
			if d:IsA("GuiObject") and d.Visible and d.AbsoluteSize.X > 0 and (d.BackgroundTransparency < 1 or d:IsA("TextLabel") or d:IsA("ImageLabel") or d:IsA("ImageButton") or d:IsA("TextButton")) then
				local sg = d:FindFirstAncestorWhichIsA("ScreenGui")
				local dy = (sg and not sg.IgnoreGuiInset) and inset.Y or 0
				minX, minY = math.min(minX, d.AbsolutePosition.X), math.min(minY, d.AbsolutePosition.Y + dy)
				maxX, maxY = math.max(maxX, d.AbsolutePosition.X + d.AbsoluteSize.X), math.max(maxY, d.AbsolutePosition.Y + d.AbsoluteSize.Y + dy)
			end
		end
		if minX == math.huge then return nil end
		return { minX / vp.X, minY / vp.Y, maxX / vp.X, maxY / vp.Y }
	end
	local ov = gui:FindFirstChild("FightOverlay", true)
	if ov then huds.overlay = union(ov) end
	local hb = gui:FindFirstChild("HussButton", true)
	if hb then huds.huss = union(hb) end
	return huds
end

local function evaluate(label, vpSize, camCf, fov, boss, char, huds)
	local tanV = math.tan(math.rad(fov) / 2)
	local tanH = tanV * vpSize.X / vpSize.Y
	local function proj(p)
		local l = camCf:PointToObjectSpace(p)
		local d = -l.Z
		local dc = math.max(d, 0.3)
		return 0.5 + l.X / (dc * tanH) / 2, 0.5 - l.Y / (dc * tanV) / 2, d > 0
	end
	local bb, bs = boss:GetBoundingBox()
	local bossR, allIn = rectOf(cornersOf(bb, bs), proj)
	local onScreen = allIn and bossR[1] >= 0 and bossR[2] >= 0 and bossR[3] <= 1 and bossR[4] <= 1
	local avR = rectOf(avatarPoints(char), proj)
	local head = boss:FindFirstChild("Head", true)
	local headR = bossR
	if head and head:IsA("BasePart") then headR = rectOf(cornersOf(head.CFrame, head.Size), proj) end
	local hOv, hA = inter(avR, headR)
	local bOv, bA = inter(avR, bossR)
	local headPct, boxPct = 100 * hOv / math.max(hA, 1e-9), 100 * bOv / math.max(bA, 1e-9)
	local hudTxt, hudOk = {}, true
	for name, r in huds do
		local o = inter(r, bossR)
		if o > 0 then hudOk = false end
		table.insert(hudTxt, ("%s %.0f%%"):format(name, 100 * o / math.max(bA, 1e-9)))
	end
	local pass = onScreen and headPct < 0.5 and boxPct < 15 and hudOk
	return pass, ("%s box[%s] on=%s head[%s] avatar[%s] avatarOnHead %.0f%% avatarOnBox %.0f%% hudOnBox %s"):format(
		label, fmt(bossR), tostring(onScreen), fmt(headR), fmt(avR), headPct, boxPct, table.concat(hudTxt, " "))
end

local function flatDist(a, b) return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude end

-- M2-28: runs a start-spot set when the server driver (Gate FightCamera/<set>) sets HFB_M126Spots, once per set,
-- so the probe can stay installed for a whole play session and one session can run both sets.
local function runSet(set)
	local char = lp.Character or lp.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local root = char:WaitForChild("HumanoidRootPart")
	-- wait for the server's SetPower and the pad
	local pad
	for _ = 1, 40 do
		for _, p in game:GetService("CollectionService"):GetTagged("HFB_BossPad") do
			if p:GetAttribute("PadId") == "z1_fixed" then pad = p end
		end
		if pad then break end
		task.wait(0.25)
	end
	task.wait(2)
	local ring = pad:FindFirstChild("Ring")
	-- the boss that patrols is the pad's client clone "Boss" (M2-12, what Controllers/Fight.bossOf returns); the tagged one under it is
	-- the static template, so wait for the clone and use it
	local boss
	for _ = 1, 40 do
		local b = pad:FindFirstChild("Boss")
		if b and b:IsA("Model") then boss = b break end
		task.wait(0.25)
	end
	if not boss then
		for _, d in pad:GetDescendants() do
			if d:IsA("Model") and game:GetService("CollectionService"):HasTag(d, "HFB_Boss") then boss = d end
		end
	end
	local bb0, bs0 = boss:GetBoundingBox()
	local centre = bb0.Position -- updated per spot to the boss's live centre
	local head = boss:FindFirstChild("Head", true)
	report(("M126|setup|boss %s H=%s box %.1fx%.1fx%.1f centre (%.1f,%.1f) head offset (%.1f,%.1f) ring r=%s viewport %dx%d fov %d"):format(
		boss.Name, tostring(boss:GetAttribute("H")), bs0.X, bs0.Y, bs0.Z, centre.X, centre.Z,
		head and head.Position.X - centre.X or 0, head and head.Position.Z - centre.Z or 0,
		tostring(ring:GetAttribute("RingRadius")), cam.ViewportSize.X, cam.ViewportSize.Y, cam.FieldOfView))
	local total, passed = 0, 0
	for _, s in set do
		local name, dx, dz, pressOnEntry = s[1], s[2], s[3], s[4]
		-- M2-07 (patrol-aware): the boss walks up to 14 studs from the ring centre and the server tests Fight.Start against where it
		-- is now, so every start spot is an offset from the boss's LIVE centre, taken the moment it is used (as Punch2 phase c's
		-- nearBoss does), never from the ring centre. Spots stay within 5.8 studs of the boss, inside any ring radius.
		local function live() return (boss:GetBoundingBox()).Position end
		local function spotAt(bc) return Vector3.new(bc.X + dx, root.Position.Y, bc.Z + dz) end
		local dir = Vector3.new(dx, 0, dz).Unit
		local pressAt
		-- a real player whose press is refused 'ring' (the server saw the position or the boss a little differently while the boss walks)
		-- presses again: up to 3 presses, each placed from the boss's live centre
		for attempt = 1, 3 do
			if attempt > 1 then task.wait(0.3) end
			local bc = live()
			centre = bc
			if pressOnEntry then
				-- start 9 studs out on that side and walk at the boss, re-aiming at its live centre; press the moment inStartRing is true
				local from = Vector3.new(bc.X, root.Position.Y, bc.Z) + dir * 9
				char:PivotTo(CFrame.lookAt(from, Vector3.new(bc.X, from.Y, bc.Z)))
				root.AssemblyLinearVelocity = Vector3.zero
				task.wait(0.4)
				local t0 = os.clock()
				while not Fight.inStartRing() and os.clock() - t0 < 4 do
					local c = live()
					hum:MoveTo(Vector3.new(c.X, root.Position.Y, c.Z))
					RunService.Heartbeat:Wait()
				end
				centre = live()
				pressAt = root.Position
				Fight.requestStart()
			else
				-- appear at the spot (an offset from the boss's live centre), settle so the server has the position, re-place once
				-- (the boss moved about 1.6 studs meanwhile), press
				char:PivotTo(CFrame.lookAt(spotAt(bc), Vector3.new(bc.X, root.Position.Y, bc.Z)))
				root.AssemblyLinearVelocity = Vector3.zero
				task.wait(0.35)
				bc = live()
				char:PivotTo(CFrame.lookAt(spotAt(bc), Vector3.new(bc.X, root.Position.Y, bc.Z)))
				root.AssemblyLinearVelocity = Vector3.zero
				task.wait(0.15)
				centre = live()
				pressAt = root.Position
				Fight.requestStart() -- the Huss press
			end
			local t0 = os.clock()
			while not Fight.active() and os.clock() - t0 < 2.5 do task.wait(0.05) end
			if Fight.active() then break end
			report(("M126|%s|note attempt %d: no fight yet (inStartRing %s)"):format(name, attempt, tostring(Fight.inStartRing())))
		end
		if not Fight.active() then
			local why = "no reply"
			for i = #Fight.log, 1, -1 do
				local e = Fight.log[i]
				if e.kind == "state" then why = tostring(e.data.state) .. " " .. tostring(e.data.reason); break end
				if e.kind == "request" then why = "request sent, no state"; break end
			end
			report(("M126|%s|FAIL the fight did not start (pressed at %.1f from the boss centre, %.1f from the ring centre, inStartRing %s): %s"):format(
				name, flatDist(pressAt, centre), flatDist(pressAt, ring.Position), tostring(Fight.inStartRing()), why))
			total += 1
		else
			task.wait(0.8)
			local bb, bs = boss:GetBoundingBox()
			local toBoss = Vector3.new(bb.Position.X - root.Position.X, 0, bb.Position.Z - root.Position.Z)
			local facing = root.CFrame.LookVector:Dot(toBoss.Unit)
			local d = flatDist(root.Position, bb.Position)
			local dRing = flatDist(root.Position, ring.Position)
			report(("M126|%s|pressed at %.1f from boss centre -> stood at %.2f (ring centre %.2f, r %s), facing dot %.2f, root (%.1f,%.1f,%.1f), cam %.1f from boss"):format(
				name, flatDist(pressAt, centre), d, dRing, tostring(ring:GetAttribute("RingRadius")), facing,
				root.Position.X, root.Position.Y, root.Position.Z, (cam.CFrame.Position - bb.Position).Magnitude))
			local huds = hudRects()
			local results = {
				{ evaluate(("real %dx%d"):format(cam.ViewportSize.X, cam.ViewportSize.Y), cam.ViewportSize, cam.CFrame, cam.FieldOfView, boss, char, huds) },
			}
			for _, sz in { Vector2.new(1280, 720), Vector2.new(874, 402) } do
				local cf = Fight.frameBoss(boss, root.Position, { ViewportSize = sz, FieldOfView = cam.FieldOfView } :: any)
				table.insert(results, { evaluate(("%dx%d"):format(sz.X, sz.Y), sz, cf, cam.FieldOfView, boss, char, huds) })
			end
			for _, r in results do
				total += 1
				if r[1] then passed += 1 end
				report(("M126|%s|%s %s"):format(name, r[1] and "PASS" or "FAIL", r[2]))
			end
			-- also the real viewport check by WorldToViewportPoint
			local outside = 0
			for _, p in cornersOf(bb, bs) do
				local v, ok = cam:WorldToViewportPoint(p)
				if not ok or v.X < 0 or v.Y < 0 or v.X > cam.ViewportSize.X or v.Y > cam.ViewportSize.Y then outside += 1 end
			end
			total += 1
			if outside == 0 then passed += 1 end
			report(("M126|%s|%s real camera: boss box corners outside the viewport by WorldToViewportPoint: %d"):format(name, outside == 0 and "PASS" or "FAIL", outside))
			Fight.run()
			local t1 = os.clock()
			while Fight.active() and os.clock() - t1 < 3 do task.wait(0.05) end
			task.wait(0.5)
			report(("M126|%s|after Run: active=%s WalkSpeed %.1f JumpPower %.1f AutoRotate %s"):format(name, tostring(Fight.active() ~= nil), hum.WalkSpeed, hum.JumpPower, tostring(hum.AutoRotate)))
		end
		task.wait(Config.Fight.PAD_COOLDOWN_S + 0.3)
	end
	report(("M126|summary|%d pass, %d fail"):format(passed, total - passed))
	Net.get("Profile", "TestReport"):FireServer({ name = "m126_done", json = "{}" })
end

task.spawn(function()
	local last = nil
	while true do
		local k = workspace:GetAttribute("HFB_M126Spots")
		if k == nil then
			last = nil
		elseif k ~= last and SETS[tostring(k)] then
			last = k
			n = 0
			runSet(SETS[tostring(k)])
		end
		task.wait(0.25)
	end
end)
