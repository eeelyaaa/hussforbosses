--!strict
-- Controllers/Ring: the timing ring and the graded tap (m1-contract.md section D, "Client ring").
-- A ring starts when the player stands on the own bag pad (or a fight is started) and the previous burst has
-- ended. Ring n starts at local r0 and lands at r0 + ringClose. A tap at t (os.clock()) is graded by
-- d = |t - landing|: d <= perfect -> Perfect, d <= good -> Good (both launch the three-punch burst). M2 (P3,
-- m2-contract.md B2, m2-punch-numbers.md section 2): a tap anywhere else in the ring, from RING_GRACE_S after it
-- opens, is "untimed": ONE report, ONE punch (the single huss, no burst, no F, no pips) and the ring is spent (it
-- finishes closing, drawn dimmed; later taps in it are ignored). The next ring after an untimed tap opens at the
-- ring's landing + MISS_RESTART. A tap in the first RING_GRACE_S, during a burst or in the wait is ignored (button
-- feedback only, no report); a tap after landing + good finds the ring passed (ignored). No tap by landing + good is
-- a Miss reported with no tapServerTime. After a Good or Perfect the next ring starts at t0 + BURST_LEN; after a
-- Miss at missTime + MISS_RESTART. Ring starts are scheduled times, not frame times, so a late frame never pushes
-- the schedule back.
--
-- API:
--   Ring.init(view?)                 Heartbeat loop and the Punch.Schedule / Punch.Result listeners
--   Ring.setView(view)               the Huss button view (Ui/HussButton, contract I): setRing, landed, missed
--   Ring.tap(t, source)              a punch input at t (Input.onPunch handlers call it)
--   Ring.setFight(windows?)          { goodMs, perfectMs } while a fight runs, nil when it ends (Controllers/Fight)
--   Ring.onBagPad() -> boolean       the player stands on the own bag pad (same radius as the server's test)
--   Ring.current() -> state          { phase, context, n, r0, landing, ringClose, windows } (TestClient reads it)
--   Ring.onEvent(fn)                 fn(kind, data) for "start", "graded", "ignored", "refused"
--   Ring.setSinglePunch(fn)          fn(context, t) called in the tap's frame for an untimed punch (Main plays the huss,
--                                    the jab and the Power pop; the view gets landed("untimed"), then setSpent(true) if it has it)
--   Ring.log, Ring.ignored, Ring.schedule
-- Seams: Ring.setSender(fn) (default Net Punch.Report), Ring.setBagPadTest(fn) (edit-mode test).
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BurstClock = require(script.Parent:WaitForChild("BurstClock"))

local P = Config.Punch
local LOG_MAX = 60

export type Phase = "off" | "ring" | "spent" | "wait"

local Ring = {}

Ring.schedule = {
	speedLevel = Config.Bag.DEFAULT_SPEED,
	ringClose = P.RING[Config.Bag.DEFAULT_SPEED],
	burstLen = P.BURST_LEN,
	cycle = P.CYCLE(Config.Bag.DEFAULT_SPEED),
	fromServer = false,
}
Ring.log = {} :: { any }
Ring.ignored = { early = 0, busy = 0, wait = 0, off = 0, grace = 0, spent = 0, late = 0 }

local state = {
	phase = "off" :: Phase,
	context = nil :: string?,
	n = 0,
	r0 = 0,
	landing = 0,
	ringClose = Ring.schedule.ringClose,
	windows = P.BAG_WINDOWS,
	nextStart = nil :: number?,
	nextCause = "first",
	prevEvent = nil :: number?,
	inBurstUntil = 0,
	missUntil = 0,
}
local fightWindows: { goodMs: number, perfectMs: number }? = nil
local view: any = nil
local seq = 0
local singlePunch: ((string, number) -> ())? = nil
function Ring.setSinglePunch(fn: (string, number) -> ())
	singlePunch = fn
end
local events: { (string, any) -> () } = {}

local sender: ((any) -> ())? = nil
function Ring.setSender(fn: (any) -> ())
	sender = fn
end
local function sendReport(report: any)
	if sender then
		sender(report)
		return
	end
	local Net = require(Shared:WaitForChild("Net"))
	Net.get("Punch", "Report"):FireServer(report)
end

local function emit(kind: string, data: any)
	for _, fn in ipairs(table.clone(events)) do
		task.spawn(fn, kind, data)
	end
end
function Ring.onEvent(fn: (string, any) -> ()): () -> ()
	table.insert(events, fn)
	return function()
		local i = table.find(events, fn)
		if i then
			table.remove(events, i)
		end
	end
end

local function callView(method: string, ...: any)
	if view and type(view[method]) == "function" then
		local ok, err = pcall(view[method], ...)
		if not ok then
			warn("[HFB] Ring view." .. method .. " failed: " .. tostring(err))
		end
	end
end

function Ring.setView(v: any)
	view = v
end

-- The own bag pad: the plot whose OwnerUserId is ours, its BagPad, horizontal distance <= Config.Bag.PAD_RADIUS.
local cachedPad: BasePart? = nil
local cachedAt = -math.huge
local function ownBagPad(): BasePart?
	local now = os.clock()
	if cachedPad and cachedPad.Parent and now - cachedAt < 1 then
		return cachedPad
	end
	cachedAt = now
	cachedPad = nil
	local plots = workspace:FindFirstChild("Plots") -- stream-ok: re-read every second until found
	local me = Players.LocalPlayer
	if not plots or not me then
		return nil
	end
	for _, plot in ipairs(plots:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == me.UserId then
			local pad = plot:FindFirstChild("BagPad")
			if pad and pad:IsA("BasePart") then
				cachedPad = pad
			end
			break
		end
	end
	return cachedPad
end

local bagPadTest: () -> boolean = function()
	local pad = ownBagPad()
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not pad or not root then
		return false
	end
	local d = root.Position - pad.Position
	return Vector2.new(d.X, d.Z).Magnitude <= Config.Bag.PAD_RADIUS
end
function Ring.setBagPadTest(fn: () -> boolean)
	bagPadTest = fn
end
function Ring.onBagPad(): boolean
	return bagPadTest()
end

function Ring.setFight(windows: { goodMs: number, perfectMs: number }?)
	fightWindows = windows
end

function Ring.current()
	return {
		phase = state.phase,
		context = state.context,
		n = state.n,
		r0 = state.r0,
		landing = state.landing,
		ringClose = state.ringClose,
		windows = state.windows,
		nextStart = state.nextStart,
		inBurst = os.clock() < state.inBurstUntil,
	}
end

local function pushLog(entry: any)
	table.insert(Ring.log, entry)
	if #Ring.log > LOG_MAX then
		table.remove(Ring.log, 1)
	end
end

local function startRing(at: number)
	state.n += 1
	state.phase = "ring"
	state.r0 = at
	state.ringClose = Ring.schedule.ringClose
	state.landing = at + state.ringClose
	state.windows = if state.context == "fight" and fightWindows then fightWindows else P.BAG_WINDOWS
	local entry = {
		n = state.n,
		ctx = state.context,
		r0 = at,
		close = state.ringClose,
		cause = state.nextCause,
		gap = if state.prevEvent then at - state.prevEvent else nil,
		goodMs = state.windows.goodMs,
		perfectMs = state.windows.perfectMs,
	}
	pushLog(entry)
	state.nextStart = nil
	emit("start", entry)
end

local function lastEntry(): any
	return Ring.log[#Ring.log]
end

local function report(grade: string, tapServer: number?): any
	seq += 1
	return { seq = seq, context = state.context, grade = grade, tapServerTime = tapServer }
end

local function miss(missTime: number, tapped: boolean, tapServer: number?, dMs: number?, offMs: number?)
	local entry = lastEntry()
	if entry then
		entry.grade = "miss"
		entry.dMs = dMs
		entry.tapped = tapped
	end
	local r = report("miss", tapServer)
	local ok, err = pcall(sendReport, r)
	if not ok then
		warn("[HFB] Ring miss report failed: " .. tostring(err))
	end
	state.phase = "wait"
	state.prevEvent = missTime
	state.nextStart = missTime + P.MISS_RESTART
	state.missUntil = state.nextStart
	state.nextCause = "miss"
	callView("setRing", nil)
	callView("missed")
	emit("graded", { n = state.n, grade = "miss", tapped = tapped, dMs = dMs, offMs = offMs, seq = r.seq })
end

local function ignore(why: string, source: string)
	Ring.ignored[why] = (Ring.ignored[why] or 0) + 1
	emit("ignored", { why = why, source = source, n = state.n })
end

function Ring.tap(t: number, source: string?)
	local src = source or "code"
	if state.phase == "spent" then
		ignore("spent", src)
		return
	end
	if state.phase ~= "ring" then
		ignore(if os.clock() < state.inBurstUntil then "busy" elseif state.phase == "wait" then "wait" else "off", src)
		return
	end
	if t < state.r0 + (P.RING_GRACE_S or 0.15) then
		ignore("grace", src)
		return
	end
	local w = state.windows
	if t > state.landing + w.goodMs / 1000 then
		ignore("late", src) -- the ring has passed; the step reports the Miss
		return
	end
	local tapServer = workspace:GetServerTimeNow()
	local dMs = math.abs(t - state.landing) * 1000
	local grade = if dMs <= w.perfectMs then "perfect" elseif dMs <= w.goodMs then "good" else "untimed"
	local entry = lastEntry()
	if entry then
		entry.grade = grade
		entry.dMs = dMs
		entry.tapped = true
	end
	local r = report(grade, tapServer)
	if grade == "untimed" then
		-- One punch now; the ring is spent and the next one opens on the schedule a perfect tap would have given.
		state.phase = "spent"
		state.prevEvent = t
		state.nextStart = state.landing + P.MISS_RESTART
		state.missUntil = state.nextStart
		state.nextCause = "untimed"
		if entry then
			entry.seq = r.seq
		end
		local ok, err = pcall(sendReport, r)
		if not ok then
			warn("[HFB] Ring untimed report failed: " .. tostring(err))
		end
		callView("landed", "untimed")
		callView("setSpent", true)
		if singlePunch then
			local okS, errS = pcall(singlePunch, state.context :: string, t)
			if not okS then
				warn("[HFB] Ring single punch failed: " .. tostring(errS))
			end
		end
		emit("graded", { n = state.n, grade = grade, dMs = dMs, offMs = (t - state.landing) * 1000, seq = r.seq })
		return
	end
	state.phase = "wait"
	callView("setRing", nil)
	callView("landed", grade)
	local _id, t0 = BurstClock.start(grade, state.context :: string, r)
	state.inBurstUntil = t0 + P.BURST_LEN
	state.prevEvent = t0
	state.nextStart = t0 + P.BURST_LEN
	state.nextCause = "burst"
	if entry then
		entry.t0 = t0
		entry.seq = r.seq
	end
	emit("graded", { n = state.n, grade = grade, dMs = dMs, offMs = (t - state.landing) * 1000, seq = r.seq, t0 = t0 })
end

-- One step of the ring; exposed for the edit-mode test (pass a fake now).
function Ring.step(now: number)
	local want: string? = if fightWindows then "fight" elseif bagPadTest() then "bag" else nil
	if want ~= state.context then
		state.context = want
		if state.phase == "ring" or state.phase == "spent" then
			callView("setRing", nil)
			callView("setSpent", false)
		end
		if want == nil then
			state.phase = "off"
			state.nextStart = nil
		else
			-- Entering a context: the ring starts now, or when the running burst ends (contract D).
			state.phase = "wait"
			state.nextStart = math.max(now, state.inBurstUntil, state.missUntil)
			state.nextCause = "first"
			state.prevEvent = nil
		end
	end
	if state.phase == "wait" and state.context and state.nextStart and now >= state.nextStart then
		-- Keep the schedule: start at the scheduled time unless the ring was held off for a while.
		local at = if now - state.nextStart < 0.1 then state.nextStart else now
		startRing(at)
	end
	if state.phase == "spent" then
		-- the spent ring finishes closing, dimmed; at its landing it is gone and the wait to the next one runs
		if now >= state.landing then
			callView("setRing", nil)
			callView("setSpent", false)
			state.phase = "wait"
		else
			callView("setRing", math.clamp((now - state.r0) / state.ringClose, 0, 1))
		end
	end
	if state.phase == "ring" then
		local deadline = state.landing + state.windows.goodMs / 1000
		if now > deadline then
			miss(deadline, false, nil, nil)
		else
			callView("setRing", math.clamp((now - state.r0) / state.ringClose, 0, 1))
		end
	end
end

local function onSchedule(p: any)
	if typeof(p) ~= "table" then
		return
	end
	local close = p.ringClose
	if typeof(close) ~= "number" or close ~= close or close < 0.2 or close > 5 then
		return
	end
	Ring.schedule = {
		speedLevel = if typeof(p.speedLevel) == "number" then p.speedLevel else Ring.schedule.speedLevel,
		ringClose = close,
		burstLen = if typeof(p.burstLen) == "number" then p.burstLen else P.BURST_LEN,
		cycle = if typeof(p.cycle) == "number" then p.cycle else close + P.BURST_LEN,
		fromServer = true,
	}
	emit("schedule", Ring.schedule)
end
Ring.applySchedule = onSchedule

Ring.results = {} :: { any }
local function onResult(p: any)
	if typeof(p) ~= "table" or typeof(p.seq) ~= "number" then
		return
	end
	table.insert(Ring.results, { seq = p.seq, accepted = p.accepted, reason = p.reason, grade = p.grade })
	if #Ring.results > LOG_MAX then
		table.remove(Ring.results, 1)
	end
	if p.accepted == false then
		local id = BurstClock.findBySeq(p.seq)
		if id then
			BurstClock.cancel(id, "refused")
		end
		emit("refused", { seq = p.seq, reason = p.reason, burstId = id })
	end
end
Ring.applyResult = onResult

local started = false
function Ring.init(v: any?)
	if started then
		return
	end
	started = true
	if v then
		view = v
	end
	local Net = require(Shared:WaitForChild("Net"))
	Net.get("Punch", "Schedule").OnClientEvent:Connect(onSchedule)
	Net.get("Punch", "Result").OnClientEvent:Connect(onResult)
	RunService.Heartbeat:Connect(function()
		Ring.step(os.clock())
	end)
end

return Ring
