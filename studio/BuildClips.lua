if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-10 (animator-vfx), B14: the avatar's punch clips, built from the numbers below as KeyframeSequences.
-- Edit mode, holding the studio lock:  require(game.ServerStorage.DevSync:Clone()).run("BuildClips.lua")
-- Run again any time: it deletes and rebuilds ServerStorage.HFB_Clips.
--
-- Builds, per rig type (R15 and R6):
--   Jab3_<rig>      left, right, left; contact (Hit markers 1, 2, 3) on Config.Punch.BEAT = {0, 0.213, 0.401}.
--                   Clip time 0 IS the first contact: the tap and the first contact are the same instant (brief
--                   system 1), so jab 1's snap-out is not played; jabs 2 and 3 snap out 0.05 s before their beat.
--   BigThird_<rig>  the wide third punch alone: guard -> wind-up (draws back past the shoulder, torso twists 25)
--                   -> contact at Config.Avatar.BIG_LEAD (Hit 3) -> held a beat longer -> back to stance in 0.2 s.
--                   The Avatar starts it BIG_LEAD before beat 3, so its contact lands on BEAT[3].
-- Output (all in ServerStorage.HFB_Clips): KeyframeSequences/<name>, and one rig per type
-- (HFB_ClipRig_R15, HFB_ClipRig_R6) whose AnimSaves holds the sequences, ready for the Animation Editor to load and
-- publish (team/verification/m1-10-avatar.md, "Publish brief"). Nothing is uploaded here.
-- Then reads every sequence back: keyframe times, contact times against BEAT, and the punching hand's reach by
-- forward kinematics on the rig (PASS/FAIL lines).

local ServerStorage = game:GetService("ServerStorage")
local REPORT = {}
local function log(s) table.insert(REPORT, s) print(s) end
local Players = game:GetService("Players")

local BEAT = { 0, 0.213, 0.401 }
local BIG_LEAD = 0.08
do
	local ok, Config = pcall(function() return require(game.ReplicatedStorage.Shared.Config:Clone()) end) -- a clone: edit-mode require caches
	if ok and Config and Config.Punch and Config.Avatar then
		BEAT = Config.Punch.BEAT
		BIG_LEAD = Config.Avatar.BIG_LEAD
	else
		print("NOTE: Config not loadable here; using BEAT {0, 0.213, 0.401}, BIG_LEAD 0.08")
	end
end

-- ------------------------------------------------------------------ the numbers (degrees, studs)
-- A pose: arms { sh = shoulder swing forward, el = elbow bend, sh6 = shoulder on R6 (no elbow there) }, tw = torso
-- twist (positive turns the left side back, so the right shoulder comes forward), step = studs the body moves in.
local function arm(sh, el, sh6) return { sh = sh, el = el, sh6 = sh6 or sh } end
local GUARD_ARM = arm(35, 110, 40)
local NEUTRAL = { R = arm(0, 0), L = arm(0, 0), tw = 0, step = 0 }
local GUARD = { R = GUARD_ARM, L = GUARD_ARM, tw = 0, step = 0 }
local JAB_L = { R = GUARD_ARM, L = arm(88, 0), tw = -10, step = 0 }   -- left glove out, shoulders turn 10
local JAB_R = { R = arm(88, 0), L = GUARD_ARM, tw = 10, step = 0 }
local WINDUP = { R = GUARD_ARM, L = arm(-40, 95, -40), tw = 25, step = -0.15 } -- left arm drawn back, torso twists 25
local BIG_CONTACT = { R = GUARD_ARM, L = arm(92, 0), tw = -22, step = 0.5 }   -- half-stud step in

local SNAP = { Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.Out }
local RETRACT = { Enum.PoseEasingStyle.Cubic, Enum.PoseEasingDirection.Out }

-- { time, pose, easing (into this key), hit number or nil }
local JAB3 = {
	{ 0.000, JAB_L, SNAP, 1 },
	{ 0.030, JAB_L, SNAP },            -- held contact
	{ 0.110, GUARD, RETRACT },         -- pull back in about 0.1 s
	{ BEAT[2] - 0.05, GUARD, RETRACT },
	{ BEAT[2], JAB_R, SNAP, 2 },       -- snap out in 0.05 s, contact on beat 2
	{ BEAT[2] + 0.03, JAB_R, SNAP },
	{ BEAT[2] + 0.11, GUARD, RETRACT },
	{ BEAT[3] - 0.05, GUARD, RETRACT },
	{ BEAT[3], JAB_L, SNAP, 3 },       -- the plain third jab (replaced by BigThird once that clip has an id)
	{ BEAT[3] + 0.03, JAB_L, SNAP },
	{ BEAT[3] + 0.13, GUARD, RETRACT },
	{ BEAT[3] + 0.22, NEUTRAL, RETRACT },
}
local BIG = {
	{ 0.000, GUARD, RETRACT },
	{ BIG_LEAD / 2, WINDUP, SNAP },    -- wind-up: draws back past the shoulder (0.04 s)
	{ BIG_LEAD, BIG_CONTACT, SNAP, 3 },-- contact on the beat (0.04 s of snap)
	{ BIG_LEAD + 0.05, BIG_CONTACT, SNAP }, -- held a beat longer than a jab (0.05 s against 0.03)
	{ BIG_LEAD + 0.05 + 0.20, NEUTRAL, RETRACT }, -- back to stance in about 0.2 s
}

-- ------------------------------------------------------------------ pose trees
local function rx(d) return CFrame.Angles(math.rad(d), 0, 0) end
local function ry(d) return CFrame.Angles(0, math.rad(d), 0) end
local function rz(d) return CFrame.Angles(0, 0, math.rad(d)) end

-- part name -> CFrame (the joint's Transform) for a pose, per rig
local function transforms(rigType, p)
	if rigType == "R15" then
		return {
			LowerTorso = CFrame.new(0, 0, -p.step),
			UpperTorso = ry(p.tw),
			RightUpperArm = rx(p.R.sh), RightLowerArm = rx(p.R.el),
			LeftUpperArm = rx(p.L.sh), LeftLowerArm = rx(p.L.el),
		}
	end
	-- R6: the RootJoint's C0 turns joint axes (joint Z is world up, joint Y is world forward-back), so the torso
	-- twist is Rz and a step forward is -Y; the arms swing about Z, forward is +Z on the right, -Z on the left.
	return {
		Torso = CFrame.new(0, -p.step, 0) * rz(p.tw),
		["Right Arm"] = rz(p.R.sh6), ["Left Arm"] = rz(-p.L.sh6),
	}
end

-- the pose hierarchy, root first: { name, weight 0 container?, children }
local TREE = {
	R15 = { "HumanoidRootPart", true, {
		{ "LowerTorso", false, {
			{ "UpperTorso", false, {
				{ "RightUpperArm", false, { { "RightLowerArm", false, {} } } },
				{ "LeftUpperArm", false, { { "LeftLowerArm", false, {} } } },
			} },
		} },
	} },
	R6 = { "HumanoidRootPart", true, {
		{ "Torso", false, {
			{ "Right Arm", false, {} },
			{ "Left Arm", false, {} },
		} },
	} },
}

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

local function buildSequence(name, rigType, keys)
	local ks = Instance.new("KeyframeSequence")
	ks.Name = name
	ks.Loop = false
	ks.Priority = Enum.AnimationPriority.Action
	for i, k in ipairs(keys) do
		local kf = Instance.new("Keyframe")
		kf.Name = if k[4] then ("Contact" .. k[4]) else ("K" .. i)
		kf.Time = k[1]
		addPoses(kf, TREE[rigType], transforms(rigType, k[2]), k[3])
		if k[4] then
			local m = Instance.new("KeyframeMarker")
			m.Name = "Hit"
			m.Value = tostring(k[4])
			m.Parent = kf
		end
		kf.Parent = ks
	end
	return ks
end

-- ------------------------------------------------------------------ rigs
local function makeRig(rigType)
	local rig = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType[rigType])
	rig.Name = "HFB_ClipRig_" .. rigType
	return rig
end

-- forward kinematics: world CFrame of a part with the given joint transforms applied
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
	if partName == "HumanoidRootPart" then
		return rig.HumanoidRootPart.CFrame
	end
	local j = joints[partName]
	return worldOf(rig, joints, j.parent, tf) * j.c0 * (tf[partName] or CFrame.identity) * j.c1:Inverse()
end

-- ------------------------------------------------------------------ build
local old = ServerStorage:FindFirstChild("HFB_Clips")
if old then old:Destroy() end
local root = Instance.new("Folder")
root.Name = "HFB_Clips"
local seqFolder = Instance.new("Folder")
seqFolder.Name = "KeyframeSequences"
seqFolder.Parent = root

local fails = 0
local function check(cond, msg)
	if cond then log("PASS " .. msg) else fails += 1 log("FAIL " .. msg) end
end

for _, rigType in ipairs({ "R15", "R6" }) do
	local jab = buildSequence("Jab3_" .. rigType, rigType, JAB3)
	local big = buildSequence("BigThird_" .. rigType, rigType, BIG)
	jab.Parent = seqFolder
	big.Parent = seqFolder

	local rig = makeRig(rigType)
	local saves = Instance.new("Folder")
	saves.Name = "AnimSaves"
	jab:Clone().Parent = saves
	big:Clone().Parent = saves
	saves.Parent = rig
	rig.Parent = root

	-- read-back 1: contact markers sit on the beats
	local hits = {}
	for _, kf in ipairs(jab:GetChildren()) do
		for _, m in ipairs(kf:GetChildren()) do
			if m:IsA("KeyframeMarker") and m.Name == "Hit" then hits[tonumber(m.Value)] = kf.Time end
		end
	end
	for n = 1, 3 do
		check(hits[n] ~= nil and math.abs(hits[n] - BEAT[n]) < 1e-6,
			("%s Jab3 Hit %d at %s (BEAT %s)"):format(rigType, n, tostring(hits[n]), tostring(BEAT[n])))
	end
	local bigHit
	for _, kf in ipairs(big:GetChildren()) do
		for _, m in ipairs(kf:GetChildren()) do if m:IsA("KeyframeMarker") then bigHit = kf.Time end end
	end
	check(bigHit ~= nil and math.abs(bigHit - BIG_LEAD) < 1e-6,
		("%s BigThird Hit at %s (BIG_LEAD %s); started at BEAT[3] - BIG_LEAD = %.3f it lands on %.3f"):format(
			rigType, tostring(bigHit), tostring(BIG_LEAD), BEAT[3] - BIG_LEAD, BEAT[3] - BIG_LEAD + (bigHit or 0)))
	local lastJab, lastBig = 0, 0
	for _, kf in ipairs(jab:GetChildren()) do lastJab = math.max(lastJab, kf.Time) end
	for _, kf in ipairs(big:GetChildren()) do lastBig = math.max(lastBig, kf.Time) end
	log(("INFO %s lengths: Jab3 %.3f s, BigThird %.3f s (burst 0.61 s)"):format(rigType, lastJab, lastBig))

	-- read-back 2: the punching hand's reach at each contact keyframe, forward kinematics on the rig
	local joints = jointsOf(rig)
	local rootCF = rig.HumanoidRootPart.CFrame
	local handName = if rigType == "R15" then { R = "RightHand", L = "LeftHand" } else { R = "Right Arm", L = "Left Arm" }
	local function reach(side, p)
		local part = handName[side]
		local cf = worldOf(rig, joints, part, transforms(rigType, p))
		local tip = if rigType == "R6" then cf * CFrame.new(0, -1, 0) else cf
		return rootCF:PointToObjectSpace(tip.Position)
	end
	local function show(label, side, p)
		local v = reach(side, p)
		log(("INFO %s %s %s hand rel root: x %.2f y %.2f z %.2f"):format(rigType, label, side, v.X, v.Y, v.Z))
		return v
	end
	local g = show("guard", "L", GUARD)
	local jl = show("jab L contact", "L", JAB_L)
	local jr = show("jab R contact", "R", JAB_R)
	local bc = show("big contact", "L", BIG_CONTACT)
	local bw = show("big windup", "L", WINDUP)
	check(jl.Z < g.Z - 0.6 and jr.Z < -1.0, rigType .. " jab contact: glove reaches forward of guard (z " .. string.format("%.2f", jl.Z) .. " vs " .. string.format("%.2f", g.Z) .. ")")
	check(bw.Z > jl.Z + 1.0, rigType .. " big wind-up draws the left hand back past the jab line (z " .. string.format("%.2f", bw.Z) .. ")")
	check(bc.Z <= jl.Z - 0.3, rigType .. " big contact is wider/further in than a jab (z " .. string.format("%.2f", bc.Z) .. ")")
end

log(fails == 0 and "PASS BuildClips: 4 sequences + 2 rigs in ServerStorage.HFB_Clips" or ("FAIL BuildClips: " .. fails .. " check(s) failed"))
root:SetAttribute("Report", table.concat(REPORT, "\n")) -- read back without the console
root.Parent = ServerStorage
