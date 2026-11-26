if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-23 (animator-vfx), B14: the avatar's other five clips, built from the numbers below as KeyframeSequences.
-- Edit mode, holding the studio lock:  require(game.ServerStorage.DevSync:Clone()).run("BuildClips2.lua")
-- Run again any time: it replaces only its own ten sequences (and their copies in the rigs' AnimSaves) in
-- ServerStorage.HFB_Clips; the jab clips of studio/BuildClips.lua are left alone. (BuildClips.lua deletes the whole
-- HFB_Clips folder: run it first, this one after.)
--
-- Per rig type (R15 and R6), names <Clip>_<rig>:
--   Flinch      0.25 s  on the boss's impact frame (clip time 0): head and torso snap back in 0.05 s, one small step
--                       back, held, back to stance. No fall. Marker "Impact" at the peak.
--   CarryHold   1.0 s   LOOP. Both arms straight up (Config.Avatar.CARRY_SHOULDER_DEG), the body rocks 3 degrees each
--                       way in the boss's carry-rock stride (1.0 s, Moves/squat carryRock). Trunk and head poses have
--                       weight 0, so the run animation keeps the legs and hips; R15 rocks the upper torso, R6 (whose
--                       torso is the root joint) rocks through the arms.
--   StealLift   2.0 s   reach down for the boss, grip (marker "Grip"), lift in 4 steps (marker "Step" 1..4 at the start
--                       of each rise) that end with the arms straight up at 2.0 (marker "LiftDone"). The code stretches
--                       it to the hold: track:AdjustSpeed(2.0 / holdSeconds) (1.0 s with Quick Hands = speed 2).
--   Knockdown   2.0 s   falls back in 0.2 s (marker "Dust" at the landing: the grey cubes), lies still to 1.6 s (marker
--                       "GetUp"), up in the last 0.4 s.
--   Stun        1.5 s   standing wobble, arms down, head drooped and circling; marker "Dizzy" at 0 (the three white
--                       cubes circle the head in code). No fall.
-- Output: KeyframeSequences/<name> and a copy of each in HFB_ClipRig_R15 / _R6 .AnimSaves, ready for the Animation
-- Editor to load and publish (team/verification/m2-23-avatar-clips.md, "Publish brief"). Nothing is uploaded here.
-- Then reads every sequence back: length, markers, and the body's reach / height by forward kinematics (PASS/FAIL).

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local REPORT = {}
local function log(s) table.insert(REPORT, s) print(s) end

local CARRY_DEG = 175
do
	local ok, Config = pcall(function() return require(game.ReplicatedStorage.Shared.Config:Clone()) end) -- a clone: edit-mode require caches
	if ok and Config and Config.Avatar then
		CARRY_DEG = Config.Avatar.CARRY_SHOULDER_DEG
	else
		print("NOTE: Config not loadable here; using CARRY_SHOULDER_DEG 175")
	end
end

-- ------------------------------------------------------------------ the numbers (degrees, studs)
-- A pose: R, L = arms { sh = shoulder swing forward, el = elbow bend, sh6 = shoulder on R6 }, tw = torso twist,
-- step = studs back (negative = forward), lean = degrees leaning BACK (negative = forward), roll = degrees tipped to
-- the side, lay = whole body tipped backwards about the pelvis (90 = lying on the back), drop = studs the body
-- sinks (filled in per rig for lying poses), head = head pitched back, hroll = head tipped to the side.
local function arm(sh, el, sh6) return { sh = sh, el = el, sh6 = sh6 or sh } end
local DOWN = arm(0, 0)
local function P(t)
	local p = { R = DOWN, L = DOWN, tw = 0, step = 0, lean = 0, roll = 0, lay = 0, drop = 0, head = 0, hroll = 0 }
	for k, v in pairs(t) do p[k] = v end
	return p
end
local function both(a) return { R = a, L = a } end

local SNAP = { Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.Out }
local FALL = { Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.In }
local SINE = { Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.InOut } -- no Sine pose style
local SMOOTH = { Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.InOut }

-- ---- Flinch (0.25 s)
local FL_PEAK = P({ R = arm(25, 60), L = arm(25, 60), lean = 18, head = 22, step = 0.35 })
local FLINCH = {
	{ 0.00, P({}), SNAP },
	{ 0.05, FL_PEAK, SNAP, "Impact" },       -- snap back in 0.05 s
	{ 0.09, FL_PEAK, SNAP },                 -- held
	{ 0.25, P({}), SMOOTH },                 -- back to stance
}

-- ---- Carry hold (1.0 s loop): rock = 3 degrees each way, in the carry-rock stride of 1.0 s
local function carry(roll, sh6) -- sh6: R6 shoulder offsets (R6 rocks through the arms)
	return P({ R = arm(CARRY_DEG, 0, CARRY_DEG + sh6), L = arm(CARRY_DEG, 0, CARRY_DEG + sh6), lean = 3, roll = roll })
end
local CARRYHOLD = {
	{ 0.00, carry(0, 0), SINE },
	{ 0.25, carry(3, 3), SINE },
	{ 0.50, carry(0, 0), SINE },
	{ 0.75, carry(-3, -3), SINE },
	{ 1.00, carry(0, 0), SINE },
}

-- ---- Steal lift (2.0 s): reach 0.4, grip 0.2, then 4 lift steps of 0.35 s (rise 0.12, hold 0.23)
local REACH = P({ R = arm(55, 20), L = arm(55, 20), lean = -15, step = -0.25 })
local GRIP = P({ R = arm(60, 65), L = arm(60, 65), lean = -15, step = -0.25 })
local STAGES = {
	P({ R = arm(85, 55), L = arm(85, 55), lean = -10, step = -0.2 }),
	P({ R = arm(115, 35), L = arm(115, 35), lean = -4, step = -0.1 }),
	P({ R = arm(145, 15), L = arm(145, 15), lean = 0 }),
	P({ R = arm(CARRY_DEG, 0), L = arm(CARRY_DEG, 0), lean = 3 }), -- the carry pose
}
local STEALLIFT = {
	{ 0.00, P({}), SMOOTH },
	{ 0.40, REACH, SMOOTH },
	{ 0.55, GRIP, SNAP, "Grip" },
	{ 0.60, GRIP, SNAP, "Step", 1 },                 -- marker "Step n" = the start of rise n (the ratchet click)
}
for i, pose in ipairs(STAGES) do
	local t = 0.60 + 0.35 * (i - 1)
	table.insert(STEALLIFT, { t + 0.12, pose, SNAP })                                    -- rise
	if i < #STAGES then
		table.insert(STEALLIFT, { t + 0.35, pose, SNAP, "Step", i + 1 })                -- hold, then the next rise starts
	else
		table.insert(STEALLIFT, { t + 0.35, pose, SNAP, "LiftDone" })                   -- 2.0 s: off the spot
	end
end

-- ---- Knockdown (2.0 s): the lying drop is set per rig below (DROP)
local KD_HIT = P({ R = arm(50, 40), L = arm(50, 40), lean = 10, head = 8 })
local KNOCKDOWN = { -- filled by knockdownKeys(drop)
}
local function knockdownKeys(drop)
	local LAY = P({ R = arm(20, 10), L = arm(20, 10), lay = 90, drop = drop, head = 0 })
	local SIT = P({ R = arm(40, 30), L = arm(40, 30), lay = 45, drop = drop * 0.45, lean = -10 })
	return {
		{ 0.00, KD_HIT, SNAP },
		{ 0.20, LAY, FALL, "Dust" },          -- falls back in 0.2 s
		{ 1.60, LAY, SMOOTH, "GetUp" },       -- lies still
		{ 1.80, SIT, SMOOTH },
		{ 2.00, P({}), SNAP },
	}
end

-- ---- Stun (1.5 s): arms down, drooped head circling, torso wobbling about a standing pose
local function wob(roll, tw, hroll)
	return P({ R = arm(8, 12), L = arm(8, 12), roll = roll, tw = tw, head = -12, hroll = hroll, lean = -3 })
end
local STUN = {
	{ 0.00, wob(0, 0, 0), SINE, "Dizzy" },
	{ 0.25, wob(10, 10, -14), SINE },
	{ 0.50, wob(-10, -10, 14), SINE },
	{ 0.75, wob(10, 10, -14), SINE },
	{ 1.00, wob(-10, -10, 14), SINE },
	{ 1.25, wob(4, 5, -6), SINE },
	{ 1.50, P({}), SINE },
}

-- ------------------------------------------------------------------ pose trees
local function rx(d) return CFrame.Angles(math.rad(d), 0, 0) end
local function ry(d) return CFrame.Angles(0, math.rad(d), 0) end
local function rz(d) return CFrame.Angles(0, 0, math.rad(d)) end

-- part name -> CFrame (the joint's Transform) for a pose, per rig. R15: LowerTorso is the root joint (translate and
-- lay there), the upper torso twists, leans and rolls, the Head pose pitches and tips the neck. R6: the Torso pose is the
-- RootJoint, whose C0 turns joint axes (joint Z is world up, joint Y is world back): a step back is +Y, sinking is -Z,
-- the twist is Rz, lean back is Rx(-), roll is Ry, lay is Rx(-); the neck has the same orientation.
local function transforms(rigType, p)
	if rigType == "R15" then
		return {
			LowerTorso = CFrame.new(0, -p.drop, p.step) * rx(p.lay),
			UpperTorso = rz(p.roll) * ry(p.tw) * rx(p.lean),
			Head = rx(p.head) * rz(p.hroll),
			RightUpperArm = rx(p.R.sh), RightLowerArm = rx(p.R.el),
			LeftUpperArm = rx(p.L.sh), LeftLowerArm = rx(p.L.el),
		}
	end
	return {
		Torso = CFrame.new(0, p.step, -p.drop) * rx(-p.lay) * rz(p.tw) * ry(p.roll) * rx(-p.lean),
		Head = rx(-p.head) * ry(p.hroll),
		["Right Arm"] = rz(p.R.sh6), ["Left Arm"] = rz(-p.L.sh6),
	}
end

-- the pose hierarchy, root first: { name, container(weight 0), children }
local function tree(rigType, free)
	local head = { "Head", free.head == true, {} }
	local arms15 = {
		{ "RightUpperArm", false, { { "RightLowerArm", false, {} } } },
		{ "LeftUpperArm", false, { { "LeftLowerArm", false, {} } } },
	}
	if rigType == "R15" then
		return { "HumanoidRootPart", true, {
			{ "LowerTorso", free.trunk == true, {
				{ "UpperTorso", false, { arms15[1], arms15[2], head } },
			} },
		} }
	end
	return { "HumanoidRootPart", true, {
		{ "Torso", free.trunk == true, {
			{ "Right Arm", false, {} },
			{ "Left Arm", false, {} },
			head,
		} },
	} }
end

local function addPoses(parent, node, tf, easing)
	local pose = Instance.new("Pose")
	pose.Name = node[1]
	pose.CFrame = tf[node[1]] or CFrame.identity
	pose.Weight = if node[2] then 0 else 1
	pose.EasingStyle = easing[1]
	pose.EasingDirection = easing[2]
	pose.Parent = parent
	for _, child in ipairs(node[3]) do
		addPoses(pose, child, tf, easing)
	end
end

-- keys: { time, pose, easing (into this key), marker name or nil, marker value or nil }
local function buildSequence(name, rigType, keys, loop, free)
	local ks = Instance.new("KeyframeSequence")
	ks.Name = name
	ks.Loop = loop
	ks.Priority = Enum.AnimationPriority.Action
	for i, k in ipairs(keys) do
		local kf = Instance.new("Keyframe")
		kf.Name = if k[4] then (k[4] .. (if k[5] then tostring(k[5]) else "")) else ("K" .. i)
		kf.Time = k[1]
		addPoses(kf, tree(rigType, free), transforms(rigType, k[2]), k[3])
		if k[4] then
			local m = Instance.new("KeyframeMarker")
			m.Name = k[4]
			m.Value = if k[5] then tostring(k[5]) else ""
			m.Parent = kf
		end
		kf.Parent = ks
	end
	return ks
end

-- ------------------------------------------------------------------ rigs and forward kinematics
local function makeRig(rigType)
	local rig = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType[rigType])
	rig.Name = "HFB_ClipRig_" .. rigType
	return rig
end

local function jointsOf(rig)
	local j = {}
	for _, x in ipairs(rig:GetDescendants()) do
		if x:IsA("Motor6D") then
			j[x.Part1.Name] = { parent = x.Part0.Name, c0 = x.C0, c1 = x.C1 }
		elseif x:IsA("AnimationConstraint") then
			j[x.Part1.Name] = { parent = x.Part0.Name, c0 = x.Attachment0.CFrame, c1 = x.Attachment1.CFrame }
		end
	end
	return j
end

local function worldOf(rig, joints, partName, tf)
	if partName == "HumanoidRootPart" then return rig.HumanoidRootPart.CFrame end
	local j = joints[partName]
	return worldOf(rig, joints, j.parent, tf) * j.c0 * (tf[partName] or CFrame.identity) * j.c1:Inverse()
end

-- ------------------------------------------------------------------ build
local root = ServerStorage:FindFirstChild("HFB_Clips")
if not root then
	root = Instance.new("Folder")
	root.Name = "HFB_Clips"
	root.Parent = ServerStorage
end
local seqFolder = root:FindFirstChild("KeyframeSequences")
if not seqFolder then
	seqFolder = Instance.new("Folder")
	seqFolder.Name = "KeyframeSequences"
	seqFolder.Parent = root
end

local MINE = { "Flinch", "CarryHold", "StealLift", "Knockdown", "Stun" }
local function isMine(n)
	for _, c in ipairs(MINE) do if n:sub(1, #c + 1) == c .. "_" then return true end end
	return false
end
for _, x in ipairs(seqFolder:GetChildren()) do if isMine(x.Name) then x:Destroy() end end

local fails = 0
local function check(cond, msg)
	if cond then log("PASS " .. msg) else fails += 1 log("FAIL " .. msg) end
end

local function near(a, b) return a ~= nil and math.abs(a - b) < 1e-4 end
local function lengthOf(ks)
	local m = 0
	for _, kf in ipairs(ks:GetChildren()) do m = math.max(m, kf.Time) end
	return m
end
local function markersOf(ks)
	local out = {}
	for _, kf in ipairs(ks:GetChildren()) do
		for _, m in ipairs(kf:GetChildren()) do
			if m:IsA("KeyframeMarker") then table.insert(out, { name = m.Name, value = m.Value, t = kf.Time }) end
		end
	end
	table.sort(out, function(a, b) return a.t < b.t end)
	return out
end
local function markerStr(ms)
	local s = {}
	for _, m in ipairs(ms) do table.insert(s, ("%s%s@%.3f"):format(m.name, m.value, m.t)) end
	return table.concat(s, " ")
end
local function markerAt(ms, name, value)
	for _, m in ipairs(ms) do if m.name == name and (value == nil or m.value == value) then return m.t end end
end

for _, rigType in ipairs({ "R15", "R6" }) do
	local rig = makeRig(rigType)
	local joints = jointsOf(rig)
	local rootCF = rig.HumanoidRootPart.CFrame
	local floorY = -(rig.Humanoid.HipHeight + rig.HumanoidRootPart.Size.Y / 2) -- floor, relative to the root
	local function at(partName, pose) -- R6 arms: the point is the arm's lower end (its glove end)
		local cf = worldOf(rig, joints, partName, transforms(rigType, pose))
		if rigType == "R6" and partName:find("Arm") then cf = cf * CFrame.new(0, -1, 0) end
		return rootCF:PointToObjectSpace(cf.Position)
	end
	local trunkName = if rigType == "R15" then "UpperTorso" else "Torso"
	local lowName = if rigType == "R15" then "LowerTorso" else "Torso"
	local handName = if rigType == "R15" then "RightHand" else "Right Arm"

	-- the lying drop: the lowest torso centre sits 0.5 stud (half the torso's depth) above the floor
	local lay0 = P({ lay = 90 })
	local lowest = math.min(at(trunkName, lay0).Y, at(lowName, lay0).Y)
	local DROP = lowest - (floorY + 0.5)
	log(("INFO %s floor at y %.2f rel root; lying torso centre %.2f; drop %.2f studs"):format(rigType, floorY, lowest, DROP))

	local sets = {
		{ "Flinch", FLINCH, false, {} },
		{ "CarryHold", CARRYHOLD, true, { trunk = true, head = true } },
		{ "StealLift", STEALLIFT, false, { head = true } },
		{ "Knockdown", knockdownKeys(DROP), false, {} },
		{ "Stun", STUN, false, {} },
	}
	local saves = rig:FindFirstChild("AnimSaves") or Instance.new("Folder")
	saves.Name = "AnimSaves"
	local built = {}
	for _, s in ipairs(sets) do
		local name = s[1] .. "_" .. rigType
		local ks = buildSequence(name, rigType, s[2], s[3], s[4])
		ks.Parent = seqFolder
		built[s[1]] = ks
	end

	-- the rig that goes into HFB_Clips: reuse the jab rig if BuildClips.lua made one, else this one
	local keep = root:FindFirstChild("HFB_ClipRig_" .. rigType)
	if not keep then
		rig.Parent = root
		keep = rig
	end
	local ks_saves = keep:FindFirstChild("AnimSaves")
	if not ks_saves then
		ks_saves = Instance.new("Folder")
		ks_saves.Name = "AnimSaves"
		ks_saves.Parent = keep
	end
	for _, x in ipairs(ks_saves:GetChildren()) do if isMine(x.Name) then x:Destroy() end end
	for _, ks in pairs(built) do ks:Clone().Parent = ks_saves end

	-- ---- read-back
	local lens = {}
	for _, n in ipairs(MINE) do lens[n] = lengthOf(built[n]) end
	log(("INFO %s lengths: Flinch %.3f, CarryHold %.3f (loop %s), StealLift %.3f, Knockdown %.3f, Stun %.3f"):format(
		rigType, lens.Flinch, lens.CarryHold, tostring(built.CarryHold.Loop), lens.StealLift, lens.Knockdown, lens.Stun))
	check(math.abs(lens.Flinch - 0.25) < 1e-6, rigType .. " Flinch is 0.25 s")
	check(math.abs(lens.CarryHold - 1.0) < 1e-6 and built.CarryHold.Loop, rigType .. " CarryHold is a 1.0 s loop")
	check(math.abs(lens.StealLift - 2.0) < 1e-6, rigType .. " StealLift is 2.0 s (stretched to the hold in code)")
	check(math.abs(lens.Knockdown - 2.0) < 1e-6, rigType .. " Knockdown is 2.0 s")
	check(math.abs(lens.Stun - 1.5) < 1e-6, rigType .. " Stun is 1.5 s")

	local mf, ms, mk, mst = markersOf(built.Flinch), markersOf(built.StealLift), markersOf(built.Knockdown), markersOf(built.Stun)
	log(("INFO %s markers: Flinch %s | StealLift %s | Knockdown %s | Stun %s"):format(rigType, markerStr(mf), markerStr(ms), markerStr(mk), markerStr(mst)))
	check(near(markerAt(mf, "Impact"), 0.05), rigType .. " Flinch Impact at 0.05")
	check(near(markerAt(ms, "Grip"), 0.55) and near(markerAt(ms, "LiftDone"), 2.0), rigType .. " StealLift Grip 0.55, LiftDone 2.0")
	local steps = 0
	for _, m in ipairs(ms) do if m.name == "Step" then steps += 1 end end
	check(steps == 4, rigType .. " StealLift has 4 Step markers")
	check(near(markerAt(mk, "Dust"), 0.2) and near(markerAt(mk, "GetUp"), 1.6), rigType .. " Knockdown Dust 0.2, GetUp 1.6 (up in the last 0.4 s)")

	-- ---- read-back by forward kinematics (studs rel root; forward is -z, up is +y, back is +z)
	local UP = if rigType == "R6" then 0.45 else 0.8 -- R6 arms are short: the glove end only reaches the head's top
	local rest = P({})
	local headRest, headFl = at("Head", rest), at("Head", FL_PEAK)
	check(headFl.Z > headRest.Z + 0.6, ("%s Flinch snaps the head back %.2f studs (z %.2f -> %.2f)"):format(rigType, headFl.Z - headRest.Z, headRest.Z, headFl.Z))
	local hCarry = at(handName, carry(0, 0))
	check(hCarry.Y > headRest.Y + UP, ("%s CarryHold hand is %.2f above the head (hand y %.2f, head y %.2f)"):format(rigType, hCarry.Y - headRest.Y, hCarry.Y, headRest.Y))
	local hReach, hGrip, hTop = at(handName, REACH), at(handName, GRIP), at(handName, STAGES[4])
	check(hGrip.Z < -1.2, ("%s StealLift grip: hand %.2f forward of the root"):format(rigType, -hGrip.Z))
	check(hTop.Y > headRest.Y + UP, ("%s StealLift ends with the hand above the head (y %.2f vs %.2f)"):format(rigType, hTop.Y, headRest.Y))
	local layPose = P({ lay = 90, drop = DROP })
	local lyHead, lyTrunk, lyLow = at("Head", layPose), at(trunkName, layPose), at(lowName, layPose)
	check(lyHead.Y - floorY < 1.3 and lyHead.Y - floorY > 0.2,
		("%s Knockdown lying: head centre %.2f above the floor (torso %.2f, pelvis %.2f)"):format(rigType, lyHead.Y - floorY, lyTrunk.Y - floorY, lyLow.Y - floorY))
	check(lyTrunk.Y - floorY >= 0.3, rigType .. " Knockdown lying: torso does not sink into the floor")
	local w1, w2 = at("Head", STUN[2][2]), at("Head", STUN[3][2])
	check(math.abs(w1.X - w2.X) > 0.25, ("%s Stun head swings %.2f studs side to side"):format(rigType, math.abs(w1.X - w2.X)))
	if keep ~= rig then rig:Destroy() end
end

log(fails == 0 and "PASS BuildClips2: 10 sequences (5 clips x R15, R6) in ServerStorage.HFB_Clips" or ("FAIL BuildClips2: " .. fails .. " check(s) failed"))
root:SetAttribute("Report2", table.concat(REPORT, "\n")) -- read back without the console
