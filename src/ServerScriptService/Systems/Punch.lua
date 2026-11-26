--!strict
-- Systems/Punch: the ring schedule, Punch.Report validation, the Heartbeat beat queue, and the stall rule
-- (brief systems 1 and 4; m1-contract.md sections C and D, "Server (Systems/Punch)").
--
-- The one client value believed is the report's grade (and tap time, sanity-bounded), bounded by place, state and
-- rate. M2 (the manager's P3, m2-contract.md B, m2-punch-numbers.md section 2), all on receipt time:
--   any report      refused 'busy' while the player's burst runs; 'place'/'state' outside its context.
--   good / perfect  the burst: CYCLE(speed) x RATE_TOLERANCE since the last accepted TIMED report and
--                   UNTIMED_MIN_GAP_S since the last accepted report of any grade, else 'rate'. On accept t0 =
--                   receipt time and punch n applies at t0 + BEAT[n] from one Heartbeat queue (never task.delay).
--   untimed         one punch at once (bag: Bag.value(.., 'untimed', 1); fight: Power x 1), no burst, no BUSY:
--                   UNTIMED_MIN_GAP_S since the last accepted report of any grade (after an untimed one, plus the
--                   context's Good window: TEAM CALL M2-06-1, one report per ring), else 'untimedBusy'. In a fight it
--                   must also fall inside the server's current ring (M2-02 S6, TEAM CALL M2-06-5); the expected
--                   landing then moves on one ring (that ring's landing + MISS_RESTART + RING) and, from the band
--                   Config.Fight.UNTIMED_HEART_FROM up (PROVISIONAL Q1), the punch costs a heart after it lands.
--   miss            as M1 (TEAM CALL M1-06b): not during a burst, Net's 4 a second; in a fight one heart.
--   auto = true     Systems/AutoPunch.refuse (M2-10): never untimed or miss ('grade'); 'pass' without the pass and the
--                   toggle (perfect: Perfect Auto Punch); then every timed rule above (one burst per ring, B20). Auto
--                   bursts mark no funnel event and carry auto = true in Punch.Result and Punch.Burst.
-- Refusal reasons (contract C): rate, place, state, grade, busy, untimedBusy, pass. A malformed payload is dropped
-- and counted (Punch.stats.dropped), never answered and never an error.
-- Every accepted burst or untimed punch is also sent to other players within 150 studs (Punch.Burst, unreliable).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Ids = require(Shared.Ids)
local Session = require(script.Parent.Parent.Data.Session)
local Bag = require(script.Parent.Bag)
local Fight = require(script.Parent.Fight)
local Funnel = require(script.Parent.Funnel)
local AutoPunch = require(script.Parent.AutoPunch)

-- Other players who see a burst (contract C, Punch.Burst: unreliable, 150 studs, not the owner).
local BURST_SEEN_STUDS = 150

type Burst = {
	seq: number,
	context: string,
	grade: string,
	t0: number,
	endsAt: number,
	nextBeat: number, -- 1..3, the next beat to apply; 4 = done
	fightId: number,
	dead: boolean, -- B22: the fight was won on an earlier beat
}

type State = {
	lastReport: number?, -- receipt time of the last accepted report (any grade)
	lastTimed: number?, -- receipt time of the last accepted good/perfect report
	lastGrade: string?, -- grade of the last accepted report
	burst: Burst?,
	-- fight ring tracking for the stall rule
	nextLanding: number?,
}

local Punch = {}

local states: { [Player]: State } = {}

-- What checks read (server-side truth): refusals by reason, dropped payloads, and every applied beat.
Punch.stats = {
	refused = {} :: { [string]: number },
	dropped = 0,
	accepted = 0,
	stalls = 0,
	schedules = 0,
	lastSchedule = {} :: { [number]: any },
	lastResult = {} :: { [number]: any },
	log = {} :: { any },
}

local function logBeat(e: any)
	table.insert(Punch.stats.log, e)
	if #Punch.stats.log > 300 then
		table.remove(Punch.stats.log, 1)
	end
end

local function state(player: Player): State
	local s = states[player]
	if not s then
		s = {}
		states[player] = s
	end
	return s
end

local function speedLevel(player: Player): number
	local p = Session.get(player)
	return if p then p.speedLevel else Config.Bag.DEFAULT_SPEED
end

local function ring(player: Player): number
	local lv = math.clamp(math.floor(speedLevel(player)), 1, #Config.Punch.RING)
	return Config.Punch.RING[lv]
end

-- The Punch.Schedule payload for the player's Speed level.
function Punch.schedule(player: Player): any
	local lv = speedLevel(player)
	return {
		speedLevel = lv,
		ringClose = ring(player),
		burstLen = Config.Punch.BURST_LEN,
		cycle = Config.Punch.CYCLE(lv),
	}
end

function Punch.sendSchedule(player: Player)
	if player.Parent ~= Players then
		return
	end
	local payload = Punch.schedule(player)
	Punch.stats.schedules += 1
	Punch.stats.lastSchedule[player.UserId] = payload
	Net.get("Punch", "Schedule"):FireClient(player, payload)
end

local function result(player: Player, seq: number, accepted: boolean, reason: string?, context: string, grade: string, gains: { number }?, t0: number?, auto: boolean?)
	if not accepted and reason then
		Punch.stats.refused[reason] = (Punch.stats.refused[reason] or 0) + 1
	end
	local payload = {
		seq = seq,
		accepted = accepted,
		reason = reason,
		context = context,
		grade = grade,
		gains = gains,
		t0 = t0,
		auto = if auto then true else nil,
	}
	Punch.stats.lastResult[player.UserId] = payload
	Net.get("Punch", "Result"):FireClient(player, payload)
end

-- Applies every due beat of the player's burst, in order (a late Heartbeat applies all missed beats).
local function drain(player: Player, now: number)
	local s = states[player]
	local b = s and s.burst
	if not b then
		return
	end
	while b.nextBeat <= 3 do
		local n = b.nextBeat
		local due = b.t0 + Config.Punch.BEAT[n]
		if now < due then
			break
		end
		b.nextBeat = n + 1
		local value = 0
		local contact = false
		if not b.dead then
			if b.context == "bag" then
				value = Bag.applyBeat(player, b.grade, n)
				contact = true
			else
				local won
				contact, won = Fight.applyBeat(player, b.fightId, b.seq, b.grade, n)
				if won then
					b.dead = true
				end
			end
		end
		logBeat({
			userId = player.UserId,
			seq = b.seq,
			context = b.context,
			grade = b.grade,
			n = n,
			t0 = b.t0,
			due = due,
			appliedAt = now,
			late = now - due,
			value = value,
			contact = contact,
		})
	end
end

local function isTimed(grade: string): boolean
	return grade == "good" or grade == "perfect"
end

-- The Good window (s) of the context the report is in: the bag's, or the running fight's band.
local function goodWindow(context: string, fight: Fight.FightT?): number
	if context == "fight" and fight then
		return fight.goodMs / 1000
	end
	return Config.Punch.BAG_WINDOWS.goodMs / 1000
end

local function showOthers(player: Player, context: string, grade: string, t0: number, auto: boolean?)
	local r = Bag.root(player)
	if r then
		Net.fireNear("Punch", "Burst", r.Position, BURST_SEEN_STUDS, player, {
			userId = player.UserId,
			context = context,
			grade = grade,
			auto = if auto then true else nil,
			t0 = t0,
		})
	end
end

local function handleReport(player: Player, p: any)
	-- Shape first: a malformed payload is dropped silently and counted.
	if not Net.isInt(p.seq, 0, 2 ^ 31) or not Net.isOneOf(p.context, Ids.CONTEXTS) or not Net.isOneOf(p.grade, Ids.REPORT_GRADES) then
		Punch.stats.dropped += 1
		return
	end
	if p.tapServerTime ~= nil and not Net.isNumber(p.tapServerTime) then
		Punch.stats.dropped += 1
		return
	end
	if p.auto ~= nil and typeof(p.auto) ~= "boolean" then
		Punch.stats.dropped += 1
		return
	end
	local seq: number, context: string, grade: string = p.seq, p.context, p.grade
	local now = workspace:GetServerTimeNow()
	local s = state(player)

	-- Place: the context the player is actually in (TEAM CALL M1-01: wrong context = place).
	local fight = Fight.get(player)
	if Bag.root(player) == nil then
		return result(player, seq, false, "state", context, grade)
	end
	if context == "bag" and not Bag.onOwnPad(player) then
		return result(player, seq, false, "place", context, grade)
	end
	if context == "fight" and not fight then
		return result(player, seq, false, "place", context, grade)
	end
	if context == "bag" and fight then
		return result(player, seq, false, "state", context, grade)
	end
	-- Auto Punch (contract C, M2-10): only good/perfect, the pass owned and the toggle on, on the own bag pad.
	local auto = p.auto == true
	if auto then
		local why = AutoPunch.refuse(player, grade, context)
		if why then
			AutoPunch.stats.refused[why] = (AutoPunch.stats.refused[why] or 0) + 1
			return result(player, seq, false, why, context, grade, nil, nil, true)
		end
	end
	-- Busy: a burst of the player's is still running (every grade, untimed too).
	if s.burst and now < s.burst.endsAt then
		return result(player, seq, false, "busy", context, grade)
	end

	if grade == "miss" then
		s.lastReport = now
		s.lastGrade = grade
		Punch.stats.accepted += 1
		if context == "fight" then
			s.nextLanding = now + Config.Punch.MISS_RESTART + ring(player)
			Fight.miss(player, "report")
		end
		return result(player, seq, true, nil, context, grade)
	end

	-- Rate (m2-punch-numbers.md section 2).
	local sinceAny = if s.lastReport then now - s.lastReport else math.huge
	if grade == "untimed" then
		local need = Config.Punch.UNTIMED_MIN_GAP_S
		if s.lastGrade == "untimed" then
			need += goodWindow(context, fight) -- TEAM CALL M2-06-1: a second untimed in the same ring
		end
		if sinceAny < need then
			return result(player, seq, false, "untimedBusy", context, grade)
		end
		-- In a fight (M2-02 S6, TEAM CALL M2-06-5): only inside the server's current ring, from RING_GRACE_S after
		-- it opens (less the clock slack) to its landing (plus the latency slack). Outside it: 'untimedBusy'. So
		-- every accepted untimed spends one server ring and the expected landing can never run ahead of the clock.
		if context == "fight" and s.nextLanding then
			local landing = s.nextLanding :: number
			local opens = landing - ring(player)
			if now < opens + Config.Punch.RING_GRACE_S - Config.Punch.UNTIMED_EARLY_SLACK_S or now > landing + Config.Punch.UNTIMED_LATE_SLACK_S then
				return result(player, seq, false, "untimedBusy", context, grade)
			end
		end
	else
		local minTimed = Config.Punch.CYCLE(speedLevel(player)) * Config.Punch.RATE_TOLERANCE
		if (s.lastTimed and now - s.lastTimed < minTimed) or sinceAny < Config.Punch.UNTIMED_MIN_GAP_S then
			return result(player, seq, false, "rate", context, grade)
		end
	end
	-- Grade: a landed tap (timed or untimed) carries a sane tap time.
	local tap = p.tapServerTime
	if tap == nil or tap - now > Config.Punch.TAP_TIME_FUTURE_S or now - tap > Config.Punch.TAP_TIME_PAST_S then
		return result(player, seq, false, "grade", context, grade)
	end

	-- Accepted.
	s.lastReport = now
	s.lastGrade = grade
	Punch.stats.accepted += 1
	if auto then
		AutoPunch.stats.accepted += 1
	else
		if context == "bag" then
			Funnel.mark(player, "FirstBagPunch")
		end
		if grade == "perfect" then
			Funnel.mark(player, "FirstPerfectLanded")
		end
	end

	if grade == "untimed" then
		-- One punch, applied now (beat 0); no burst, so no busy time.
		local value = 0
		local contact = false
		if context == "bag" then
			local gains = { Bag.value(player, grade, 1) }
			result(player, seq, true, nil, context, grade, gains, now)
			value = Bag.applyBeat(player, grade, 1)
			contact = true
		else
			local ff = fight :: Fight.FightT
			-- the server's expected landing moves on one ring: THIS ring's landing + MISS_RESTART + RING (never the
			-- previous estimate pushed again: the window check above keeps this ring's landing within the clock)
			local landing = s.nextLanding or now
			s.nextLanding = landing + Config.Punch.MISS_RESTART + ring(player)
			result(player, seq, true, nil, context, grade, { ff.playerPower * Config.Punch.GRADE_VALUE.untimed }, now)
			local won
			contact, won = Fight.applyBeat(player, ff.fightId, seq, grade, 1)
			if not won and Fight.get(player) == ff and Config.Fight.untimedCostsHeart(ff.band) then
				Fight.miss(player, "untimed")
			end
		end
		logBeat({
			userId = player.UserId,
			seq = seq,
			context = context,
			grade = grade,
			n = 1,
			t0 = now,
			due = now,
			appliedAt = now,
			late = 0,
			value = value,
			contact = contact,
		})
		showOthers(player, context, grade, now)
		return
	end

	s.lastTimed = now
	local gains
	if context == "bag" then
		gains = Bag.gains(player, grade)
	else
		local f = fight :: Fight.FightT
		local gv = Config.Punch.GRADE_VALUE[grade]
		gains = { f.playerPower * gv, f.playerPower * gv, f.playerPower * gv * Config.Punch.BIG_MULT }
		s.nextLanding = now + Config.Punch.BURST_LEN + ring(player)
	end
	s.burst = {
		seq = seq,
		context = context,
		grade = grade,
		t0 = now,
		endsAt = now + Config.Punch.BURST_LEN,
		nextBeat = 1,
		fightId = if fight then fight.fightId else 0,
		dead = false,
	}
	result(player, seq, true, nil, context, grade, gains, now, auto)
	showOthers(player, context, grade, now, auto)
	drain(player, now) -- beat 1 (BEAT[1] = 0) applies at once
end

-- The stall rule (TEAM CALL M1-P4): in a fight, no report by RING[level] + STALL_SLACK_S after the time a ring
-- should have landed counts one Miss on the server.
local function stallCheck(player: Player, s: State, now: number)
	if not s.nextLanding then
		return
	end
	if not Fight.get(player) then
		s.nextLanding = nil
		return
	end
	if s.burst and now < s.burst.endsAt then
		return
	end
	local deadline = s.nextLanding + ring(player) + Config.Fight.STALL_SLACK_S
	if now >= deadline then
		Punch.stats.stalls += 1
		s.nextLanding = now + Config.Punch.MISS_RESTART + ring(player)
		Fight.miss(player, "stall")
	end
end

function Punch.state(player: Player): State?
	return states[player]
end

-- Check seam: the Punch.Report handler after Net's rate limiter (server checks call it with a forged payload).
Punch.report = handleReport

function Punch.start()
	Net.onServerEvent("Punch", "Report", handleReport)

	Fight.onStart(function(player, _f)
		local s = state(player)
		s.nextLanding = workspace:GetServerTimeNow() + ring(player)
		Punch.sendSchedule(player)
	end)
	Fight.onEnd(function(player, _f, _state)
		local s = states[player]
		if s then
			s.nextLanding = nil
		end
	end)
	Bag.onEnter(Punch.sendSchedule)
	Session.onJoin(Punch.sendSchedule)
	Session.onChanged(function(player, key, _v)
		if key == "speedLevel" then
			Punch.sendSchedule(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		states[p] = nil
	end)

	RunService.Heartbeat:Connect(function()
		local now = workspace:GetServerTimeNow()
		for player, s in pairs(states) do
			if s.burst then
				drain(player, now)
				if s.burst.nextBeat > 3 and now >= s.burst.endsAt then
					s.burst = nil
				end
			end
			stallCheck(player, s, now)
		end
	end)
end

return Punch
