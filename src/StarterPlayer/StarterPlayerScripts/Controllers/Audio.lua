--!strict
-- Controllers/Audio (M1-13, audio-specialist). The player's own sounds for the punch family (m1-contract.md D, F;
-- sound-direction.md, "The punch family" and "Keeping sound and the three hit frames together").
--   * ONE F voice per burst: a pool of two Sounds created once and preloaded; playBurst(grade) is called by
--     BurstClock in the same frame as t0 and calls Play() at once. PlaybackSpeed is 1.0 and never changed (the
--     fatigue rule and Auto Punch, later, change Volume only).
--   * A refused tap (BurstClock.cancel "refused") fades F over 30 ms, Run or knockdown over 40 ms.
--   * Perfect: the stand-in sting at the same instant as F; the three thuds 2 dB louder.
--   * A thud on every beat that touches (not on a B22 noContact beat); takes rotate, never the same twice in a row.
--   * A soft swish on a bag Miss; none on a fight Miss (the boss's wind-up marks it, M4).
--   * Audio.singleHuss(): strict alternation 02 A / 01 A, 01 A at x singleHuss01Gain (exported for the M2 thief punch).
-- Mix groups (M1-04): "Burst" (F and the singles) and "Effects" (thuds, sting, swish), SoundGroups under SoundService.
-- Own-player cues only, all 2D. Ids come only through Shared/Skin (Skin.Sounds, Skin.assetUrl).
-- Test seam: when the ReportBeats hook is on, each finished burst sends a Profile.TestReport "audio" (below).
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared:WaitForChild("Skin"))
local TestHooks = require(Shared:WaitForChild("TestHooks"))
local BurstClock = require(script.Parent:WaitForChild("BurstClock"))
local Ring = require(script.Parent:WaitForChild("Ring"))

local PERFECT_THUD_GAIN = 10 ^ (2 / 20) -- +2 dB (sound-direction, "The punch family")

local Audio = {}
Audio.stats = { fPlays = 0, played = 0, fades = 0, thuds = 0, stings = 0, swishes = 0, singles = 0 }
Audio.fLog = {} :: { { at: number, grade: string, burstId: number? } } -- every F Play() (for the sync test)
Audio.loadReport = {} :: { [string]: { status: string, length: number } } -- name -> PreloadAsync result
Audio.groups = {} :: { [string]: SoundGroup }

type Handle = { sound: Sound, gen: number, base: number }

local Sounds: any = Skin.Sounds
local volumes: any = Sounds.volumes

local built = false
local fVoices: { Sound } = {}
local fGen: { [Sound]: number } = {}
local nextVoice = 1
local thudSounds: { Sound } = {}
local lastThud = 0
local swishSound: Sound? = nil
local stingSound: Sound? = nil
local singleSounds: { Sound } = {}
local nextSingle = 1
local pendingF: { count: number, at: number }? = nil -- F plays since the last beat 1
local fByBurst: { [number]: { count: number, at: number } } = {}

local function group(name: string, volume: number): SoundGroup
	local g = SoundService:FindFirstChild("HFB_" .. name)
	if not g then
		local ng = Instance.new("SoundGroup")
		ng.Name = "HFB_" .. name
		ng.Volume = volume
		ng.Parent = SoundService
		g = ng
	end
	Audio.groups[name] = g :: SoundGroup
	return g :: SoundGroup
end

local function makeSound(name: string, id: any, volume: number, g: SoundGroup): Sound?
	local url = Skin.assetUrl(id)
	if not url then
		return nil -- 0 = not uploaded: not wired, never a silent default
	end
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = url
	s.Volume = volume
	s.PlaybackSpeed = 1
	s.RollOffMaxDistance = 0
	s.SoundGroup = g
	s.Parent = g
	return s
end

local function build()
	if built then
		return
	end
	built = true
	local burstG = group("Burst", 1)
	local fxG = group("Effects", 1)
	local all: { Sound } = {}
	local function add(s: Sound?)
		if s then
			table.insert(all, s)
		end
	end
	for i = 1, 2 do
		local s = makeSound("F" .. i, Sounds.burstVoice, volumes.burst, burstG)
		if s then
			table.insert(fVoices, s)
			fGen[s] = 0
			s.Played:Connect(function()
				Audio.stats.played += 1
			end)
			add(s)
		end
	end
	for i, id in ipairs(Sounds.singleHuss) do
		local s = makeSound("Single" .. i, id, volumes.single, burstG)
		if s then
			singleSounds[i] = s
			add(s)
		end
	end
	for i, id in ipairs(Sounds.thud.bag1) do
		local s = makeSound("Thud" .. i, id, volumes.thud, fxG)
		if s then
			table.insert(thudSounds, s)
			add(s)
		end
	end
	swishSound = makeSound("Swish", Sounds.swish, volumes.swish, fxG)
	stingSound = makeSound("Sting", Sounds.sting, volumes.sting, fxG)
	add(swishSound)
	add(stingSound)
	task.spawn(function()
		local ok, err = pcall(ContentProvider.PreloadAsync, ContentProvider, all, function(contentId: string, status: Enum.AssetFetchStatus)
			for _, s in ipairs(all) do
				if s.SoundId == contentId then
					Audio.loadReport[s.Name] = { status = status.Name, length = s.TimeLength }
				end
			end
		end)
		if not ok then
			warn("[HFB] Audio: PreloadAsync failed: " .. tostring(err))
		end
		for _, s in ipairs(all) do
			local r = Audio.loadReport[s.Name]
			if r then
				r.length = s.TimeLength
			end
		end
		Audio.loaded = true
	end)
end

-- The F voice. Called by BurstClock in the same frame as t0 (step 2 of the burst order).
function Audio.playBurst(grade: string): Handle?
	build()
	if #fVoices == 0 then
		return nil
	end
	local s = fVoices[nextVoice]
	nextVoice = nextVoice % #fVoices + 1
	fGen[s] += 1
	local base = volumes.burst
	s:Stop()
	s.Volume = base
	s.TimePosition = 0
	s:Play()
	local at = os.clock()
	Audio.stats.fPlays += 1
	table.insert(Audio.fLog, { at = at, grade = grade })
	if #Audio.fLog > 300 then
		table.remove(Audio.fLog, 1)
	end
	if pendingF then
		pendingF.count += 1
	else
		pendingF = { count = 1, at = at }
	end
	if grade == "perfect" and stingSound then
		stingSound.Volume = volumes.sting
		stingSound:Play()
		Audio.stats.stings += 1
	end
	return { sound = s, gen = fGen[s], base = base }
end

-- A refused tap (30 ms) or Run / knockdown (40 ms): fade F to nothing, then stop it and put its volume back.
function Audio.fadeBurst(handle: Handle?, ms: number)
	if not handle then
		return
	end
	local s = handle.sound
	if fGen[s] ~= handle.gen then
		return -- the voice has been reused since
	end
	Audio.stats.fades += 1
	local tween = TweenService:Create(s, TweenInfo.new(ms / 1000, Enum.EasingStyle.Linear), { Volume = 0 })
	tween.Completed:Once(function()
		if fGen[s] == handle.gen then
			s:Stop()
			s.Volume = handle.base
		end
	end)
	tween:Play()
end

-- One thud per beat that touches; takes rotate, never the same twice in a row.
local function thud(perfect: boolean)
	if #thudSounds == 0 then
		return
	end
	local i = math.random(1, #thudSounds)
	if #thudSounds > 1 and i == lastThud then
		i = i % #thudSounds + 1
	end
	lastThud = i
	local s = thudSounds[i]
	s.Volume = volumes.thud * (if perfect then PERFECT_THUD_GAIN else 1)
	s:Play()
	Audio.stats.thuds += 1
end

-- Single huss for a punch thrown alone (the M2 thief punch): 02 A then 01 A, strictly alternating; 01 A is x gain.
function Audio.singleHuss(): Sound?
	build()
	if #singleSounds == 0 then
		return nil
	end
	local i = nextSingle
	nextSingle = nextSingle % #singleSounds + 1
	local s = singleSounds[i]
	s.Volume = volumes.single * (if i == 2 then Sounds.singleHuss01Gain else 1)
	s:Play()
	Audio.stats.singles += 1
	return s
end

local started = false
function Audio.init()
	if started then
		return
	end
	started = true
	build()
	local lastBurst = 0
	BurstClock.onBeat(function(ev)
		if ev.n == 1 then
			if pendingF then
				fByBurst[ev.burstId] = pendingF
				pendingF = nil
			end
		end
		if not ev.noContact then
			thud(ev.grade == "perfect")
		end
	end)
	BurstClock.onDone(function(burstId: number, entries: { any })
		local rec = fByBurst[burstId]
		fByBurst[burstId] = nil
		lastBurst = burstId
		if TestHooks.get("ReportBeats") ~= true then
			return
		end
		local ok, TestClient = pcall(function()
			return require(script.Parent:WaitForChild("TestClient", 2))
		end)
		if ok and TestClient and TestClient.report then
			local first = entries[1]
			TestClient.report("audio", {
				id = burstId,
				f = rec and rec.count or 0, -- F Play() calls attributed to this burst
				dMs = rec and first and math.floor((rec.at - first.t0) * 1000000 + 0.5) / 1000 or nil, -- F start minus t0
				played = Audio.stats.played, -- Sound.Played events so far (all F voices)
				fPlays = Audio.stats.fPlays,
				thuds = Audio.stats.thuds,
				stings = Audio.stats.stings,
				swishes = Audio.stats.swishes,
				fades = Audio.stats.fades,
			})
		end
	end)
	-- A bag Miss: a soft swish. A fight Miss: nothing (the boss's wind-up marks it).
	Ring.onEvent(function(kind: string, data: any)
		if kind == "graded" and data.grade == "miss" then
			local cur = Ring.current()
			if cur and cur.context == "bag" and swishSound then
				swishSound.Volume = volumes.swish
				swishSound:Play()
				Audio.stats.swishes += 1
			end
		end
	end)
end

return Audio
