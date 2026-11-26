--!strict
-- Controllers/TestClient: the client test hooks (m1-contract.md section L; team/test-hooks.md). Studio only:
-- every hook is read through Shared/TestHooks, which returns nil outside Studio, so nothing here runs live.
--   AutoTap   "perfect" | "good" | "miss" | "mix" (weights from AutoMix "p,g,m"): taps through the real path
--             (Input.fire "punch") at landing + 0 (Perfect), + 70 ms (Good), never (Miss). The tap goes out on
--             the frame nearest the target time (now + half a frame >= target), so a 15 fps frame errs <= 33 ms.
--             Two extra values for the client's own checks (M1-07): "busy" = a Good tap, then one tap 100 ms
--             into the burst (must be ignored); "early" = a tap 0.5 s before landing (ignored), then a Good tap;
--             "lag" = a Good tap, then one frame held 0.45 s right after it, so beats 2 and 3 fire late, together.
--             With AutoTap set, standing in a boss ring with no fight presses Huss once a second (starts the fight).
--   ForceInput read by Input.kind(); on every change (with ReportBeats on) the "input" report is sent.
--   FrameCap  60, 30 or 15: a busy-wait in Heartbeat holds each frame to at least 1/cap s (see init: RenderStepped
--             runs too rarely in a Studio play client to hold anything).
--   ReportBeats true: Profile.TestReport "beats" after each burst (BurstClock entries), "ring" after each graded
--             ring (cause, gap since the burst or miss, grade), "ignored" on an ignored tap, "input" on a
--             ForceInput change. Payloads stay under 1 KB.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TestHooks = require(Shared:WaitForChild("TestHooks"))
local Net = require(Shared:WaitForChild("Net"))
local BurstClock = require(script.Parent:WaitForChild("BurstClock"))
local Ring = require(script.Parent:WaitForChild("Ring"))
local Input = require(script.Parent:WaitForChild("Input"))

local OFFSET = { perfect = 0, good = 0.070 }

local TestClient = {}
TestClient.sent = 0
TestClient.renderFrames = 0
TestClient.heartbeats = 0
local startedAt = os.clock()

local function r3(x: number?): number?
	return x and math.floor(x * 1000 + 0.5) / 1000
end

local function report(name: string, data: any)
	if TestHooks.get("ReportBeats") ~= true then
		return
	end
	local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
	if not ok then
		return
	end
	if #json > 1000 then
		json = string.sub(json, 1, 1000)
	end
	TestClient.sent += 1
	Net.get("Profile", "TestReport"):FireServer({ name = name, json = json })
end
TestClient.report = report

local function pickMix(): string
	local mix = TestHooks.get("AutoMix")
	local p, g, m = 45, 45, 10
	if typeof(mix) == "string" then
		local a, b, c = string.match(mix, "^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
		if a then
			p, g, m = tonumber(a) :: number, tonumber(b) :: number, tonumber(c) :: number
		end
	end
	local roll = math.random() * math.max(p + g + m, 1)
	if roll < p then
		return "perfect"
	elseif roll < p + g then
		return "good"
	end
	return "miss"
end

-- AutoTap: one plan per ring.
local plannedRing = -1
local plan: { any } = {}
local lagPending = false
local lastStartPress = -math.huge
local lastDt = 1 / 60

local function planFor(mode: string, landing: number): { any }
	local grade = if mode == "mix" then pickMix() else mode
	if grade == "perfect" or grade == "good" then
		return { { at = landing + OFFSET[grade], done = false } }
	elseif grade == "busy" then
		return { { at = landing + OFFSET.good, done = false }, { at = landing + OFFSET.good + 0.100, done = false } }
	elseif grade == "lag" then
		return { { at = landing + OFFSET.good, done = false, lag = true } }
	elseif grade == "early" then
		return { { at = landing - 0.5, done = false }, { at = landing + OFFSET.good, done = false } }
	end
	return {} -- "miss": no tap; the ring times out and reports a Miss with no tap time
end

local function autoTap(now: number)
	local mode = TestHooks.get("AutoTap")
	if typeof(mode) ~= "string" then
		plannedRing = -1
		plan = {}
		return
	end
	-- Standing in a boss ring with no fight: the Huss press that starts it, once a second at most.
	local Fight = require(script.Parent:WaitForChild("Fight")) :: any
	if not Fight.active() and Fight.inStartRing() and now - lastStartPress > 1 then
		lastStartPress = now
		Input.fire("punch", "auto", now)
		return
	end
	local ring = Ring.current()
	if ring.phase == "ring" and ring.n ~= plannedRing then
		plannedRing = ring.n
		plan = planFor(mode, ring.landing)
	end
	for _, step in ipairs(plan) do
		if not step.done and now + lastDt / 2 >= step.at then
			step.done = true
			Input.fire("punch", "auto", now)
			if step.lag then
				lagPending = true
			end
		end
	end
end

local function inputReport()
	local routes = {}
	for _, name in ipairs({ "F", "E", "Backspace", "ButtonR2", "ButtonX", "ButtonB" }) do
		routes[name] = Input.route((Enum.KeyCode :: any)[name], Enum.UserInputType.None) or "none"
	end
	routes.MouseButton1 = Input.route(Enum.KeyCode.Unknown, Enum.UserInputType.MouseButton1) or "none"
	local Fight = require(script.Parent:WaitForChild("Fight")) :: any
	report("input", {
		kind = Input.kind(),
		forced = TestHooks.get("ForceInput"),
		glyph = Fight.lastGlyph,
		routes = routes,
		touch = { punch = Input.BINDINGS.punch.touch[1], interact = Input.BINDINGS.interact.touch[1], run = Input.BINDINGS.run.touch[1] },
		counts = Input.counts,
		rsPerS = math.floor(TestClient.renderFrames / math.max(os.clock() - startedAt, 0.001) + 0.5),
		hbPerS = math.floor(TestClient.heartbeats / math.max(os.clock() - startedAt, 0.001) + 0.5),
	})
end
TestClient.inputReport = inputReport

local started = false
function TestClient.init()
	if started or not RunService:IsStudio() then
		return
	end
	started = true
	startedAt = os.clock()

	-- FrameCap and the lag frame hold the Heartbeat step, not RenderStepped: in a Studio play client RenderStepped
	-- ran at about 12 a second against Heartbeat's 50 to 60 (measured, M1-07), so a RenderStepped wait held nothing.
	local lastFrame = os.clock()
	RunService.RenderStepped:Connect(function()
		TestClient.renderFrames += 1
	end)
	RunService.Heartbeat:Connect(function(dt: number)
		if lagPending then
			lagPending = false
			local until_ = os.clock() + 0.45
			while os.clock() < until_ do
				-- busy-wait: one long frame inside a burst (the late-frame check)
			end
		end
		local cap = TestHooks.get("FrameCap")
		if typeof(cap) == "number" and cap >= 5 and cap < 240 then
			local target = 1 / cap
			while os.clock() - lastFrame < target do
				-- busy-wait: holds this frame so the next one is at least 1/cap after the last
			end
		end
		local now = os.clock()
		lastDt = math.max(dt, now - lastFrame)
		lastFrame = now
		TestClient.heartbeats += 1
		autoTap(now)
	end)

	BurstClock.onDone(function(burstId: number, entries: { any })
		local beats = {}
		for _, e in ipairs(entries) do
			table.insert(beats, { e.n, r3(e.scheduled), r3(e.firedAt), e.lateFrames, e.frame, e.noContact })
		end
		local first = entries[1]
		report("beats", {
			id = burstId,
			g = first and first.grade,
			c = first and first.context,
			starts = BurstClock.starts[burstId],
			cap = TestHooks.get("FrameCap"),
			b = beats, -- { n, scheduled, firedAt, lateFrames, frame, noContact }
		})
	end)

	Ring.onEvent(function(kind: string, data: any)
		if kind == "graded" then
			local e = Ring.log[#Ring.log] or {}
			report("ring", {
				n = e.n,
				ctx = e.ctx,
				cause = e.cause,
				gap = r3(e.gap),
				close = r3(e.close),
				grade = data.grade,
				tapped = data.tapped,
				dMs = data.dMs and math.floor(data.dMs + 0.5),
				off = data.offMs and math.floor(data.offMs + 0.5),
				dt = math.floor(lastDt * 1000 + 0.5),
				win = { e.goodMs, e.perfectMs },
				ign = Ring.ignored,
				kind = Input.kind(),
			})
		elseif kind == "ignored" then
			report("ignored", { why = data.why, src = data.source, n = data.n, ign = Ring.ignored })
		elseif kind == "refused" then
			report("refused", { seq = data.seq, reason = data.reason, burst = data.burstId })
		end
	end)

	local prefix = TestHooks.PREFIX
	workspace:GetAttributeChangedSignal(prefix .. "ForceInput"):Connect(function()
		task.defer(inputReport)
	end)
	workspace:GetAttributeChangedSignal(prefix .. "ReportBeats"):Connect(function()
		task.defer(inputReport)
	end)
end

-- M1-14: with ReportBeats on, every 0.4 s: "carry" (Carry.snapshot), "base" (Base.snapshot), "pads" (Pads.snapshot: text, colour hex, band, shown, boss and own Power) when they changed, and "log"
-- (the drawn log's measured offset across the lane, the clock time it was drawn at, the clock offset in use).
function TestClient.setProbes(carry: any, base: any, hazards: any, pads: any?)
	local lastJson: { [string]: string } = {}
	local acc = 0
	local lastInteract = 0
	RunService.Heartbeat:Connect(function(dt: number)
		if RunService:IsStudio() and TestHooks.get("AutoInteract") == true and os.clock() - lastInteract > 0.6 then
			lastInteract = os.clock()
			Input.fire("interact", "auto")
		end
		if not RunService:IsStudio() or TestHooks.get("ReportBeats") ~= true then
			return
		end
		acc += dt
		if acc < 0.4 then
			return
		end
		acc = 0
		local function emit(name: string, data: any)
			local ok, j = pcall(HttpService.JSONEncode, HttpService, data)
			if ok and lastJson[name] ~= j then
				lastJson[name] = j
				report(name, data)
			end
		end
		emit("carry", carry.snapshot())
		emit("base", base.snapshot())
		if pads then
			emit("pads", pads.snapshot())
		end
		local s = hazards.state()
		if s.meas then
			report("log", { t = s.t, off = r3(s.off), meas = r3(s.meas), co = r3(require(script.Parent:WaitForChild("Clock")).offset()) })
		end
	end)
end

return TestClient
