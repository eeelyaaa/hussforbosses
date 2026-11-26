--!strict
-- Controllers/BurstClock: one clock per burst (m1-contract.md section D; sound-direction.md, "Keeping sound and
-- the three hit frames together"). On a Good or Perfect, in this order, in the same frame:
--   1. t0 = os.clock()   2. audio.playBurst(grade)   3. avatar.startJab(grade, t0)   4. beat 1 at once
--   5. the Punch.Report  6. a Heartbeat loop fires beat n when os.clock() - t0 >= BEAT[n], every missed beat in
--   order on a late frame, never dropping one, never moving a later one back. Beats never wait on the server.
--
-- API (contract D):
--   BurstClock.start(grade, context, report) -> burstId, t0 (Ring calls it; report = the Punch.Report payload)
--   BurstClock.onBeat(fn) -> disconnect                      fn(event), event as in the contract plus `frame`
--   BurstClock.onDone(fn) -> disconnect                      fn(burstId, entries) after the last beat or a cancel
--   BurstClock.cancel(burstId, reason)                       "refused" fades F 30 ms; "run" / "knockdown" 40 ms
--   BurstClock.cutContact(burstId, fromBeat)                 B22: noContact on beats >= fromBeat not yet fired
--   BurstClock.log, BurstClock.starts                        every fired beat; F starts per burst (sync test)
--   BurstClock.running() -> burstId?                         the burst whose beats are still due
-- Seams (the M1-13 Audio controller and the M1-10 Avatar plug in here; Main.client wires them):
--   BurstClock.setAudio({ playBurst = fn(grade) -> handle, fadeBurst = fn(handle, ms) })
--   BurstClock.setAvatar({ startJab = fn(grade, t0), cancel = fn() })
--   BurstClock.setSender(fn(report))   default: Net Punch.Report:FireServer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local BEAT: { number } = Config.Punch.BEAT
local NOMINAL_FRAME = 1 / 60
local LOG_MAX = 300

export type BeatEvent = {
	burstId: number,
	n: number,
	big: boolean,
	grade: string,
	context: string,
	t0: number,
	scheduled: number,
	firedAt: number,
	lateFrames: number,
	noContact: boolean,
	frame: number,
}

type Burst = {
	id: number,
	grade: string,
	context: string,
	t0: number,
	seq: number?,
	nextBeat: number,
	noContactFrom: number,
	audio: any,
	entries: { BeatEvent },
	done: boolean,
}

local BurstClock = {}
BurstClock.log = {} :: { BeatEvent }
BurstClock.starts = {} :: { [number]: number }

local beatFns: { (BeatEvent) -> () } = {}
local doneFns: { (number, { BeatEvent }) -> () } = {}
local bursts: { [number]: Burst } = {}
local nextId = 0
local frame = 0

local function add(list: { any }, fn: any): () -> ()
	table.insert(list, fn)
	return function()
		local i = table.find(list, fn)
		if i then
			table.remove(list, i)
		end
	end
end

function BurstClock.onBeat(fn: (BeatEvent) -> ()): () -> ()
	return add(beatFns, fn)
end
function BurstClock.onDone(fn: (number, { BeatEvent }) -> ()): () -> ()
	return add(doneFns, fn)
end

-- Until M1-13's Controllers/Audio plugs in (setAudio), the burst voice is a no-op that counts its calls and says
-- so once (TEAM CALL M1-07a). The pooled F Sound, its preload and the fades are the Audio controller's (contract D
-- step 2); asset ids reach Sounds only there, through Shared/Skin.
local defaultAudio = { calls = 0, fades = 0 }
do
	local said = false
	function defaultAudio.playBurst(_grade: string): any
		defaultAudio.calls += 1
		if not said then
			said = true
			print("[HFB] BurstClock: no Audio controller plugged in yet; F not played (M1-13)")
		end
		return nil
	end
	function defaultAudio.fadeBurst(_handle: any, _ms: number)
		defaultAudio.fades += 1
	end
end
BurstClock.defaultAudio = defaultAudio

local audio: any = defaultAudio
local avatar: any = { startJab = function(_g: string, _t0: number) end, cancel = function() end }
local sender: ((any) -> ())? = nil

function BurstClock.setAudio(impl: any)
	audio = impl or defaultAudio
end
function BurstClock.setAvatar(impl: any)
	avatar = impl
end
function BurstClock.setSender(fn: (any) -> ())
	sender = fn
end

local function send(report: any)
	if sender then
		sender(report)
		return
	end
	local Net = require(Shared:WaitForChild("Net"))
	Net.get("Punch", "Report"):FireServer(report)
end

local function finish(b: Burst)
	if b.done then
		return
	end
	b.done = true
	bursts[b.id] = nil
	for _, fn in ipairs(table.clone(doneFns)) do
		task.spawn(fn, b.id, b.entries)
	end
end

local function fireBeat(b: Burst, n: number, now: number)
	local firedAt = now - b.t0
	local ev: BeatEvent = {
		burstId = b.id,
		n = n,
		big = n == 3,
		grade = b.grade,
		context = b.context,
		t0 = b.t0,
		scheduled = BEAT[n],
		firedAt = firedAt,
		lateFrames = math.max(0, math.floor((firedAt - BEAT[n]) / NOMINAL_FRAME)),
		noContact = n >= b.noContactFrom,
		frame = frame,
	}
	table.insert(b.entries, ev)
	table.insert(BurstClock.log, ev)
	if #BurstClock.log > LOG_MAX then
		table.remove(BurstClock.log, 1)
	end
	for _, fn in ipairs(table.clone(beatFns)) do
		local ok, err = pcall(fn, ev)
		if not ok then
			warn("[HFB] BurstClock beat subscriber failed: " .. tostring(err))
		end
	end
end

-- Fire every beat that is due, in order. Exposed for the edit-mode test (pass a fake now).
function BurstClock.step(now: number?)
	local t = now or os.clock()
	for _, b in pairs(bursts) do
		while not b.done and b.nextBeat <= #BEAT and t - b.t0 >= BEAT[b.nextBeat] do
			local n = b.nextBeat
			b.nextBeat += 1
			fireBeat(b, n, t)
		end
		if b.nextBeat > #BEAT then
			finish(b)
		end
	end
end

function BurstClock.start(grade: string, context: string, report: any?): (number, number)
	local t0 = os.clock() -- 1
	nextId += 1
	local id = nextId
	local b: Burst = {
		id = id,
		grade = grade,
		context = context,
		t0 = t0,
		seq = report and report.seq,
		nextBeat = 1,
		noContactFrom = math.huge,
		audio = nil,
		entries = {},
		done = false,
	}
	bursts[id] = b
	BurstClock.starts[id] = (BurstClock.starts[id] or 0) + 1
	local ok, handle = pcall(audio.playBurst, grade) -- 2
	if ok then
		b.audio = handle
	else
		warn("[HFB] BurstClock audio.playBurst failed: " .. tostring(handle))
	end
	local okA, errA = pcall(avatar.startJab, grade, t0) -- 3
	if not okA then
		warn("[HFB] BurstClock avatar.startJab failed: " .. tostring(errA))
	end
	BurstClock.step(t0) -- 4: beat 1 (BEAT[1] = 0) fires now
	if report then -- 5
		local okS, errS = pcall(send, report)
		if not okS then
			warn("[HFB] BurstClock report failed: " .. tostring(errS))
		end
	end
	return id, t0
end

function BurstClock.running(): number?
	for id in pairs(bursts) do
		return id
	end
	return nil
end

function BurstClock.seqOf(burstId: number): number?
	local b = bursts[burstId]
	return b and b.seq
end

function BurstClock.findBySeq(seq: number): number?
	for id, b in pairs(bursts) do
		if b.seq == seq then
			return id
		end
	end
	return nil
end

-- Server refusal: fade F 30 ms; Run or knockdown: 40 ms. Later beats do not fire.
function BurstClock.cancel(burstId: number, reason: string?)
	local b = bursts[burstId]
	if not b then
		return
	end
	local ms = if reason == "refused" then 30 else 40
	pcall(audio.fadeBurst, b.audio, ms)
	pcall(avatar.cancel)
	b.nextBeat = #BEAT + 1
	finish(b)
end

function BurstClock.cutContact(burstId: number, fromBeat: number)
	local b = bursts[burstId]
	if b then
		b.noContactFrom = math.min(b.noContactFrom, math.max(fromBeat, b.nextBeat))
	end
end

local started = false
function BurstClock.init()
	if started then
		return
	end
	started = true
	RunService.Heartbeat:Connect(function()
		frame += 1
		if next(bursts) ~= nil then
			BurstClock.step()
		end
	end)
end

return BurstClock
