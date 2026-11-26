--!nonstrict
-- Controllers/Watchers (M2-16; m2-contract.md C "Punch.Burst", "Fight.Watch", "Steal.Punch"): what a client shows of OTHER players,
-- and the respawn-while-carrying carryover from M1. Everything here is cosmetic, local and unreliable by design; no result
-- comes from it.
--   * Punch.Burst { userId, context, grade, auto, t0 } (players within 150 studs, not the puncher): their avatar throws the
--     jab clip on their character (a single cut after the first punch for 'untimed'), the burst voice plays from them at a lowered
--     level (VOICE_GAIN of the burst volume, spatial) with at most two watcher voices at once, and in a
--     fight the boss they face reacts on the beats (hitGood / hitPerfect, the third hitBig) at most once per 0.3 s per boss.
--   * Fight.Watch { padId, userId, kind, size } (reserved: the server does not send it yet): the same boss reaction by pad.
--   * Steal.Punch { fromUserId, toUserId, hit } (players within 150 studs of the thief): the owner's jab and the single huss
--     (not for the local player's own punch: Controllers/Steal played it at the tap); the thief's flinch (hit 'stagger') or the
--     stun clip (hit 'drop') on any character, the local one included.
--   * A respawn while carrying: the server ends the carry (Carry.lose 'respawn' / 'died'); here the carry-hold arms follow the
--     state again on the new character and the local clips stop.
-- API: Watchers.start(ctx) (AUTO_START), Watchers.state(), Watchers.onBurst(p), Watchers.onSteal(p) (also the check's seams).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))
local Skin = require(Shared:WaitForChild("Skin"))

local Watchers = { AUTO_START = true }

local VOICE_GAIN = 0.4 -- of the burst volume: a watcher's F sits under the local player's own
local MAX_VOICES = 2
local REACT_GAP_S = 0.3 -- at most one boss reaction per boss per 0.3 s
local WATCH_RANGE = 30 -- the boss a burster faces: the nearest pad boss within this many studs of them (flat)
local MAX_LATE_S = 0.5 -- a burst older than this on arrival plays from its latest beat on
local queue = {} -- { at, boss, name, perfect }
local lastReact = {} -- boss -> os.clock
local voices = {} -- { sound, kind }
local jabGen = {} -- character -> number
local ctx = nil
local built = false
local stats = { bursts = 0, jabs = 0, voices = 0, voiceSkipped = 0, reactions = 0, reactSkipped = 0, stealPunch = 0, clips = 0, respawns = 0, noBoss = 0 }

local function call(target, method, ...)
	if target and type(target[method]) == "function" then
		local ok, err = pcall(target[method], ...)
		if not ok then
			warn(("[HFB] Watchers: %s failed: %s"):format(method, tostring(err)))
		end
		return ok
	end
	return false
end

local function now(): number
	local ok, Clock = pcall(function()
		return require(script.Parent.Clock)
	end)
	return if ok then Clock.now() else workspace:GetServerTimeNow()
end

local function rootOf(userId: number): (BasePart?, Model?)
	local plr = Players:GetPlayerByUserId(userId)
	local c = plr and plr.Character
	return c and c:FindFirstChild("HumanoidRootPart"), c
end

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- ------------------------------------------------------------------ the voice (two at most)
local function build()
	if built then
		return
	end
	built = true
	local S: any = Skin.Sounds
	if not S then
		return
	end
	local group = nil
	if ctx.Audio and ctx.Audio.groups then
		group = ctx.Audio.groups.Burst
	end
	local function make(name: string, id: any, volume: number, kind: string)
		local url = Skin.assetUrl(id)
		if not url then
			return -- 0 = not uploaded: not wired
		end
		local s = Instance.new("Sound")
		s.Name = "Watch_" .. name
		s.SoundId = url
		s.Volume = volume * VOICE_GAIN
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = 12
		s.RollOffMaxDistance = 90
		if group then
			s.SoundGroup = group
		end
		-- each voice sits on its own invisible anchored Part moved to the puncher (a Sound parented to a character would
		-- die with it)
		local emitter = Instance.new("Part")
		emitter.Name = "Watch_Emitter_" .. name
		emitter.Anchored = true
		emitter.CanCollide = false
		emitter.CanQuery = false
		emitter.CanTouch = false
		emitter.Transparency = 1
		emitter.Size = Vector3.new(0.2, 0.2, 0.2)
		emitter.Parent = workspace
		s.Parent = emitter
		table.insert(voices, { sound = s, kind = kind, emitter = emitter })
	end
	local vol = S.volumes or {}
	for i = 1, 2 do
		make("F" .. i, S.burstVoice, vol.burst or 0.5, "burst")
	end
	for i, id in ipairs(S.singleHuss or {}) do
		make("Single" .. i, id, vol.single or 0.5, "single")
	end
end

local function playing(): number
	local n = 0
	for _, v in ipairs(voices) do
		if v.sound.IsPlaying then
			n += 1
		end
	end
	return n
end

local function playVoice(kind: string, from: BasePart?, single: number?): boolean
	build()
	if playing() >= MAX_VOICES then
		stats.voiceSkipped += 1
		return false
	end
	for _, v in ipairs(voices) do
		if v.kind == kind and not v.sound.IsPlaying and (kind == "burst" or single == nil or v.sound.Name == "Watch_Single" .. single) then
			if from then
				v.emitter.Position = from.Position -- 3D: heard from the puncher
			end
			v.sound:Play()
			stats.voices += 1
			return true
		end
	end
	stats.voiceSkipped += 1
	return false
end

local singleNext = 1
local function playSingle(from: BasePart?)
	local i = singleNext
	if playVoice("single", from, i) then
		singleNext = singleNext % 2 + 1
	end
end

-- ------------------------------------------------------------------ the jab on another character
local function throwJab(char: Model, grade: string, localT0: number, single: boolean)
	local avatar = ctx.Avatar
	if not (avatar and type(avatar.startJab) == "function") then
		return
	end
	jabGen[char] = (jabGen[char] or 0) + 1
	local gen = jabGen[char]
	local ok = pcall(avatar.startJab, if grade == "perfect" then "perfect" else "good", localT0, char)
	if not ok then
		return
	end
	stats.jabs += 1
	if single then
		local cutAt = localT0 + Config.Punch.BEAT[2] - 0.015
		task.delay(math.max(0, cutAt - os.clock()), function()
			if jabGen[char] == gen and char.Parent then
				pcall(avatar.cancel, char)
			end
		end)
	end
end

-- ------------------------------------------------------------------ the boss they face
local function bossOf(pad: Instance): Model?
	local b = pad:FindFirstChild("Boss")
	if b and b:IsA("Model") then
		return b
	end
	for _, d in ipairs(pad:GetDescendants()) do
		if d:IsA("Model") and CollectionService:HasTag(d, "HFB_Boss") then
			return d
		end
	end
	return nil
end

local function isMyFightBoss(boss: Model): boolean
	local cur = ctx.Fight and ctx.Fight.active and ctx.Fight.active()
	return cur ~= nil and cur.boss == boss
end

local function bossNear(pos: Vector3): Model?
	local best, bestD = nil, WATCH_RANGE
	for _, pad in ipairs(CollectionService:GetTagged("HFB_BossPad")) do
		local boss = bossOf(pad)
		if boss and boss.Parent and not isMyFightBoss(boss) then
			local d = flat(pos, boss:GetPivot().Position)
			if d <= bestD then
				best, bestD = boss, d
			end
		end
	end
	return best
end

local function padBoss(padId: string): Model?
	for _, pad in ipairs(CollectionService:GetTagged("HFB_BossPad")) do
		if pad:GetAttribute("PadId") == padId then
			return bossOf(pad)
		end
	end
	return nil
end

local function react(boss: Model, name: string, perfect: boolean)
	local t = os.clock()
	if t - (lastReact[boss] or -1) < REACT_GAP_S then
		stats.reactSkipped += 1
		return
	end
	lastReact[boss] = t
	stats.reactions += 1
	call(ctx.BossMoves, "play", boss, name, { perfect = perfect })
end

local function step()
	if #queue == 0 then
		return
	end
	local t = os.clock()
	local keep = {}
	for _, q in ipairs(queue) do
		if t >= q.at then
			if q.boss.Parent then
				react(q.boss, q.name, q.perfect)
			end
		else
			table.insert(keep, q)
		end
	end
	queue = keep
end

-- ------------------------------------------------------------------ remotes
function Watchers.onBurst(p)
	if typeof(p) ~= "table" or typeof(p.userId) ~= "number" or typeof(p.grade) ~= "string" or typeof(p.t0) ~= "number" then
		return
	end
	if p.userId == Players.LocalPlayer.UserId then
		return
	end
	local r, char = rootOf(p.userId)
	if not (r and char) then
		return
	end
	stats.bursts += 1
	local single = p.grade == "untimed"
	local age = math.clamp(now() - p.t0, 0, MAX_LATE_S)
	local localT0 = os.clock() - age
	throwJab(char, p.grade, localT0, single)
	if single then
		playSingle(r)
	else
		playVoice("burst", r)
	end
	if p.context == "fight" then
		local boss = bossNear(r.Position)
		if not boss then
			stats.noBoss += 1
			return
		end
		local perfect = p.grade == "perfect"
		local beats = if single then { 1 } else { 1, 2, 3 }
		for _, n in ipairs(beats) do
			local at = localT0 + Config.Punch.BEAT[n]
			if at >= os.clock() - 0.05 then
				table.insert(queue, {
					at = at,
					boss = boss,
					name = if n == 3 and not single then "hitBig" elseif perfect then "hitPerfect" else "hitGood",
					perfect = perfect,
				})
			end
		end
	end
end

function Watchers.onWatch(p)
	if typeof(p) ~= "table" or typeof(p.padId) ~= "string" or typeof(p.kind) ~= "string" then
		return
	end
	if p.userId == Players.LocalPlayer.UserId or p.kind ~= "hit" then
		return
	end
	local boss = padBoss(p.padId)
	if boss and not isMyFightBoss(boss) then
		local size = p.size
		react(boss, if size == "big" then "hitBig" elseif size == "perfect" then "hitPerfect" else "hitGood", size == "perfect")
	end
end

-- The owner's punch at a thief, and what it did to the thief.
function Watchers.onSteal(p)
	if typeof(p) ~= "table" or typeof(p.fromUserId) ~= "number" or typeof(p.toUserId) ~= "number" then
		return
	end
	stats.stealPunch += 1
	local me = Players.LocalPlayer.UserId
	if p.fromUserId ~= me then
		local r, char = rootOf(p.fromUserId)
		if r and char then
			throwJab(char, "good", os.clock(), true)
			playSingle(r)
		end
	end
	local _, thiefChar = rootOf(p.toUserId)
	if thiefChar then
		local clip = if p.hit == "drop" then "stun" elseif p.hit == "stagger" then "flinch" else nil
		if clip then
			stats.clips += 1
			call(ctx.Avatar, "playClip", clip, nil, thiefChar)
		end
	end
end

-- ------------------------------------------------------------------ respawn while carrying
local function onRespawn(char: Model)
	stats.respawns += 1
	task.spawn(function()
		char:WaitForChild("HumanoidRootPart", 10)
		char:WaitForChild("Head", 10)
		for _, name in ipairs({ "stealLift", "stun", "flinch", "knockdown" }) do
			call(ctx.Avatar, "stopClip", name, char)
		end
		-- the arms follow the server's carry state on the new character (the server ends the carry on a respawn, but a
		-- stolen boss lifted just as the character loads arrives after this: the next Carry.State sets it again)
		local carry = ctx.Carry
		local s = carry and carry.state and carry.state()
		call(ctx.Avatar, "carryHold", s == "carrying")
	end)
end

function Watchers.state()
	return { stats = stats, queued = #queue, voicesPlaying = playing(), voiceCount = #voices }
end

function Watchers.start(c)
	if ctx then
		return
	end
	ctx = c
	Net.get("Punch", "Burst").OnClientEvent:Connect(Watchers.onBurst)
	local okW, watch = pcall(Net.get, "Fight", "Watch")
	if okW then
		watch.OnClientEvent:Connect(Watchers.onWatch)
	end
	Net.get("Steal", "Punch").OnClientEvent:Connect(Watchers.onSteal)
	RunService.Heartbeat:Connect(step)
	local lp = Players.LocalPlayer
	lp.CharacterAdded:Connect(onRespawn)
	Players.PlayerRemoving:Connect(function(plr)
		local char = plr.Character
		if char then
			jabGen[char] = nil
		end
	end)
	task.defer(build)
end

return Watchers
