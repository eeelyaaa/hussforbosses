--!strict
-- Controllers/Avatar (M1-10; m1-contract.md section J; style guide section 7).
-- The player's own Roblox avatar gets voxel gloves that follow each hand, and plays the jab clips.
--
-- Everything here is cosmetic and local: each client builds the gloves on every character it can see (nothing is
-- replicated, nothing is trusted) and plays the clips on the character it is told to. The server decides results.
--
-- API (every `character` argument defaults to the local player's character):
--   Avatar.start()                         hook every player's character: gloves at spawn (Main.client calls this once)
--   Avatar.equipGloves(character) -> Model?  gloves on R15 and R6; welded to each hand; safe to call twice
--   Avatar.startJab(grade, t0, character?) -> boolean  plays jab3 (contacts on BEAT 1..3); the third contact is the
--                                          big huss: bigThird is started BIG_LEAD before beat 3 and replaces jab3's own
--                                          third jab. Seeks to os.clock() - t0 if it starts late. Id 0 = no-op, warns once
--   Avatar.cancel(character?)              stops both clips (fade 0.04 s)
--   Avatar.carryHold(on, character?)       arms straight up while carrying (procedural, written after the animation)
--   Avatar.playClip(name, opts?, character?) -> AnimationTrack?  name: flinch | carryHold | stealLift | knockdown | stun
--                                          (M2-23). opts: { hold = seconds } stretches stealLift to the hold; { speed }.
--                                          Id 0 = no-op, warns once. Markers: see team/verification/m2-23-avatar-clips.md
--   Avatar.stopClip(name, character?)      stops one of those clips (fade 0.1 s)
--   Avatar.flinch()                        = playClip("flinch")
--   Avatar.hitLog                          { {n, elapsed, track} } for the "Hit" markers that fired (sync test)
--   Avatar.setClipIds(t?)                  test seam: { R15 = {jab3, bigThird}, R6 = {...} } of ids or full content
--                                          strings (e.g. KeyframeSequenceProvider ids); nil restores Skin.Models
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Skin = require(Shared:WaitForChild("Skin"))

local CFG = Config.Avatar
local BEAT: { number } = Config.Punch.BEAT

local Avatar = {} :: any
Avatar.hitLog = {} :: { { n: number, elapsed: number, track: string } }

local GLOVES_NAME = "HFB_Gloves"
local warned: { [string]: boolean } = {}
local function warnOnce(key: string, msg: string)
	if not warned[key] then
		warned[key] = true
		warn("[HFB] Avatar: " .. msg)
	end
end

local clipOverride: any = nil
function Avatar.setClipIds(t: any)
	clipOverride = t
end

-- ---------------------------------------------------------------- helpers
local function localCharacter(): Model?
	local lp = Players.LocalPlayer
	return if lp then lp.Character else nil
end

local function humanoidOf(character: Model): Humanoid?
	return character:FindFirstChildOfClass("Humanoid")
end

local function rigOf(character: Model): string?
	local h = humanoidOf(character)
	if not h then
		return nil
	end
	return if h.RigType == Enum.HumanoidRigType.R6 then "R6" else "R15"
end

-- ---------------------------------------------------------------- gloves
local function makePart(name: string, size: { number }, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(size[1], size[2], size[3])
	p.Color = color
	p.Material = Enum.Material.Plastic -- matte: no studs because every surface is Smooth
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	return p
end

-- A stand-in glove (until the imported mesh is wired by studio/SetupGloves.lua): a yellow cuff at the wrist (the
-- pivot) and a red fist block hanging from it, in the Huss red and band yellow of the approved glove icon.
local function buildStandIn(side: string): Model
	local red = Skin.need("Tokens.colors.hussRed") :: Color3
	local yellow = Skin.need("Tokens.colors.arrowYellow") :: Color3
	local m = Instance.new("Model")
	m.Name = "Glove" .. side
	local cuff = makePart("Cuff", CFG.STANDIN_CUFF, yellow)
	local fist = makePart("Fist", CFG.STANDIN_FIST, red)
	cuff.CFrame = CFrame.new(0, 0, 0)
	fist.CFrame = CFrame.new(0, -(CFG.STANDIN_CUFF[2] + CFG.STANDIN_FIST[2]) / 2 + 0.05, 0)
	local w = Instance.new("WeldConstraint")
	w.Part0 = cuff
	w.Part1 = fist
	w.Parent = cuff
	cuff.Parent = m
	fist.Parent = m
	m.PrimaryPart = cuff -- the wrist is the pivot
	m.WorldPivot = cuff.CFrame
	return m
end

-- The glove for one side: the imported model's GloveL / GloveR when ReplicatedStorage holds it (built by
-- studio/SetupGloves.lua from Models.gloves, pivot at the wrist), else the stand-in.
local function gloveFor(side: string): Model
	local name = Skin.get("Models.gloves.model")
	local template = if type(name) == "string" then ReplicatedStorage:FindFirstChild(name) else nil
	local src = if template then template:FindFirstChild("Glove" .. side) else nil
	if src then
		local c = src:Clone()
		if c:IsA("BasePart") then
			local m = Instance.new("Model")
			m.Name = c.Name
			c.Parent = m
			m.PrimaryPart = c
			m.WorldPivot = c:GetPivot()
			c = m
		end
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = false
				d.CanCollide = false
				d.CanTouch = false
				d.CanQuery = false
				d.Massless = true
				d.CastShadow = false
			end
		end
		return c :: Model
	end
	return buildStandIn(side)
end

local function rootPart(m: Model): BasePart?
	return m.PrimaryPart
end

function Avatar.equipGloves(character: Model?): Model?
	local char = character or localCharacter()
	if not char then
		return nil
	end
	local old = char:FindFirstChild(GLOVES_NAME)
	if old then
		old:Destroy()
	end
	local rig = rigOf(char)
	local head = char:FindFirstChild("Head")
	if not rig or not head or not head:IsA("BasePart") then
		return nil
	end
	local hands: { L: BasePart?, R: BasePart? } = { L = nil, R = nil }
	if rig == "R15" then
		hands.L = char:FindFirstChild("LeftHand") :: BasePart?
		hands.R = char:FindFirstChild("RightHand") :: BasePart?
	else
		hands.L = char:FindFirstChild("Left Arm") :: BasePart?
		hands.R = char:FindFirstChild("Right Arm") :: BasePart?
	end
	if not hands.L or not hands.R then
		return nil
	end
	local scale = math.clamp(head.Size.Y / CFG.GLOVE_REF_HEAD, CFG.GLOVE_SCALE_MIN, CFG.GLOVE_SCALE_MAX)
	local folder = Instance.new("Model")
	folder.Name = GLOVES_NAME
	folder:SetAttribute("Scale", scale)
	for _, side in ipairs({ "L", "R" }) do
		local hand = (hands :: any)[side] :: BasePart
		local glove = gloveFor(side)
		glove.Name = "Glove" .. side
		if scale ~= 1 then
			glove:ScaleTo(scale)
		end
		local root = rootPart(glove)
		if root then
			-- wrist point in the hand's space
			local wy = if rig == "R15" then CFG.R15_WRIST_Y else CFG.R6_WRIST_Y
			local attName = if side == "L" then "LeftWristRigAttachment" else "RightWristRigAttachment"
			local att = hand:FindFirstChild(attName)
			local wrist = if rig == "R15" and att and att:IsA("Attachment")
				then att.CFrame
				else CFrame.new(0, wy, 0)
			-- Part1 = Part0 * C0 * C1^-1: C1 is the root's pivot offset, so the glove's pivot (wrist) sits at `wrist`.
			local weld = Instance.new("Weld")
			weld.Name = "GloveWeld"
			weld.Part0 = hand
			weld.Part1 = root
			weld.C0 = wrist * CFrame.new(0, 0, 0)
			weld.C1 = root.PivotOffset
			-- Move the whole glove (every part, rigidly) to its place before it is parented, so internal welds are
			-- captured at the right offsets.
			glove:PivotTo(hand.CFrame * weld.C0)
			weld.Parent = root
		end
		glove.Parent = folder
	end
	folder.Parent = char
	return folder
end

-- ---------------------------------------------------------------- clips
type Tracks = { jab3: AnimationTrack?, bigThird: AnimationTrack?, conn: RBXScriptConnection?, burst: number }
local tracksOf: { [Model]: Tracks } = setmetatable({}, { __mode = "k" }) :: any

local function clipIds(rig: string): any
	if clipOverride and clipOverride[rig] then
		return clipOverride[rig]
	end
	return Skin.get(if rig == "R6" then "Models.clipsR6" else "Models.clips")
end

local function contentOf(id: any): string?
	if type(id) == "number" then
		return Skin.assetUrl(id)
	elseif type(id) == "string" and id ~= "" then
		return id
	end
	return nil
end

local function animatorOf(character: Model): Animator?
	local h = humanoidOf(character)
	if not h then
		return nil
	end
	local a = h:FindFirstChildOfClass("Animator")
	if not a then
		a = Instance.new("Animator")
		a.Parent = h
	end
	return a
end

local function loadTrack(character: Model, which: string): AnimationTrack?
	local rig = rigOf(character)
	local animator = animatorOf(character)
	if not rig or not animator then
		return nil
	end
	local ids = clipIds(rig)
	local content = if ids then contentOf(ids[which]) else nil
	if not content then
		warnOnce(rig .. which, ("clip %s (%s) has no id yet (not published): the punch plays without it"):format(which, rig))
		return nil
	end
	local anim = Instance.new("Animation")
	anim.Name = "HFB_" .. which
	anim.AnimationId = content
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok then
		warnOnce(rig .. which .. "load", "LoadAnimation failed for " .. which .. ": " .. tostring(track))
		return nil
	end
	local t = track :: AnimationTrack
	t.Priority = Enum.AnimationPriority.Action
	t.Looped = false
	t:GetMarkerReachedSignal("Hit"):Connect(function(value: string)
		local n = tonumber(value) or 0
		table.insert(Avatar.hitLog, { n = n, elapsed = os.clock(), track = which })
		if #Avatar.hitLog > 200 then
			table.remove(Avatar.hitLog, 1)
		end
	end)
	return t
end

local function stateOf(character: Model): Tracks
	local s = tracksOf[character]
	if not s then
		s = { jab3 = nil, bigThird = nil, conn = nil, burst = 0 }
		tracksOf[character] = s
	end
	return s
end

-- Loads (and caches) both tracks so the switch on beat 3 costs no load time.
function Avatar.preload(character: Model?)
	local char = character or localCharacter()
	if not char then
		return
	end
	local s = stateOf(char)
	if not s.jab3 then
		s.jab3 = loadTrack(char, "jab3")
	end
	if not s.bigThird then
		s.bigThird = loadTrack(char, "bigThird")
	end
end

function Avatar.cancel(character: Model?)
	local char = character or localCharacter()
	if not char then
		return
	end
	local s = tracksOf[char]
	if not s then
		return
	end
	s.burst += 1
	if s.conn then
		s.conn:Disconnect()
		s.conn = nil
	end
	if s.jab3 then
		s.jab3:Stop(0.04)
	end
	if s.bigThird then
		s.bigThird:Stop(0.04)
	end
end

function Avatar.startJab(grade: string, t0: number, character: Model?): boolean
	local char = character or localCharacter()
	if not char then
		return false
	end
	Avatar.cancel(char)
	Avatar.preload(char)
	local s = stateOf(char)
	local jab = s.jab3
	if not jab then
		return false
	end
	local burst = s.burst
	local elapsed = os.clock() - t0
	jab:Play(0, 1, 1)
	if elapsed > 0.001 then
		jab.TimePosition = math.min(elapsed, math.max(jab.Length - 0.001, 0))
	end
	local big = s.bigThird
	if big then
		local switchAt = BEAT[3] - CFG.BIG_LEAD
		local started = false
		s.conn = RunService.Heartbeat:Connect(function()
			if s.burst ~= burst then
				return
			end
			local e = os.clock() - t0
			if not started and e >= switchAt then
				started = true
				jab:Stop(CFG.SWITCH_FADE)
				big:Play(CFG.SWITCH_FADE, 1, 1)
				local late = e - switchAt
				if late > 0.001 then
					big.TimePosition = math.min(late, math.max(big.Length - 0.001, 0))
				end
				if s.conn then
					s.conn:Disconnect()
					s.conn = nil
				end
			end
		end)
	end
	return true
end

-- ---------------------------------------------------------------- M2-23 clips (flinch, carryHold, stealLift, knockdown, stun)
local otherTracks: { [Model]: { [string]: AnimationTrack } } = setmetatable({}, { __mode = "k" }) :: any
local CLIP_LOOP = { carryHold = true }

function Avatar.playClip(name: string, opts: any?, character: Model?): AnimationTrack?
	local char = character or localCharacter()
	if not char then
		return nil
	end
	local set = otherTracks[char]
	if not set then
		set = {}
		otherTracks[char] = set
	end
	local track = set[name]
	if not track then
		track = loadTrack(char, name)
		if not track then
			return nil
		end
		track.Looped = CLIP_LOOP[name] == true
		set[name] = track
	end
	local speed = 1
	if opts and opts.hold and opts.hold > 0 and name == "stealLift" then
		speed = track.Length / opts.hold -- 2.0 s clip stretched to the hold (1.0 s with Quick Hands = 2x)
	elseif opts and opts.speed then
		speed = opts.speed
	end
	track:Play(0.05, 1, speed)
	return track
end

function Avatar.stopClip(name: string, character: Model?)
	local char = character or localCharacter()
	local t = char and otherTracks[char] and otherTracks[char][name]
	if t then
		t:Stop(0.1)
	end
end

function Avatar.flinch()
	Avatar.playClip("flinch")
end

-- ---------------------------------------------------------------- carry hold
-- Procedural: both shoulders raised straight up while carrying. Written after the animation each frame
-- (Animator overwrites Motor6D.Transform before that), on the local character only.
local carrying = false
local carryAlpha = 0
local carryConn: RBXScriptConnection? = nil

local function shoulderMotors(char: Model): (Motor6D?, Motor6D?, string?)
	local rig = rigOf(char)
	if rig == "R15" then
		local ut = char:FindFirstChild("UpperTorso")
		return ut and ut:FindFirstChild("LeftShoulder") :: Motor6D?, ut and ut:FindFirstChild("RightShoulder") :: Motor6D?, rig
	elseif rig == "R6" then
		local t = char:FindFirstChild("Torso")
		return t and t:FindFirstChild("Left Shoulder") :: Motor6D?, t and t:FindFirstChild("Right Shoulder") :: Motor6D?, rig
	end
	return nil, nil, nil
end

function Avatar.carryHold(on: boolean, character: Model?)
	carrying = on
	if carryConn then
		return
	end
	local char = character
	carryConn = RunService.RenderStepped:Connect(function(dt: number)
		local c = char or localCharacter()
		local target = if carrying then 1 else 0
		carryAlpha = math.clamp(carryAlpha + (target - carryAlpha) * math.min(1, dt / (CFG.CARRY_RAISE_S / 3)), 0, 1)
		if c then
			local l, r, rig = shoulderMotors(c)
			if l and r and carryAlpha > 0.001 then
				local a = math.rad(CFG.CARRY_SHOULDER_DEG) * carryAlpha
				if rig == "R15" then
					l.Transform = CFrame.Angles(a, 0, 0)
					r.Transform = CFrame.Angles(a, 0, 0)
				else
					l.Transform = CFrame.Angles(0, 0, -a)
					r.Transform = CFrame.Angles(0, 0, a)
				end
			end
		end
		if not carrying and carryAlpha <= 0.001 and carryConn then
			carryConn:Disconnect()
			carryConn = nil
		end
	end)
end

-- ---------------------------------------------------------------- start
local started = false
function Avatar.start()
	if started then
		return
	end
	started = true
	local function onCharacter(char: Model)
		task.spawn(function()
			char:WaitForChild("Humanoid", 10)
			char:WaitForChild("Head", 10)
			local rig = rigOf(char)
			if rig == "R15" then
				char:WaitForChild("RightHand", 10)
				char:WaitForChild("LeftHand", 10)
			elseif rig == "R6" then
				char:WaitForChild("Right Arm", 10)
				char:WaitForChild("Left Arm", 10)
			end
			Avatar.equipGloves(char)
			if char == localCharacter() then
				Avatar.preload(char)
			end
		end)
	end
	local function onPlayer(p: Player)
		p.CharacterAdded:Connect(onCharacter)
		if p.Character then
			onCharacter(p.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
end

return Avatar
