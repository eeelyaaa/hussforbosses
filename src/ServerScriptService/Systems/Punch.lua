--!strict
-- Systems/Punch: the ring schedule, Punch.Report validation, the Heartbeat beat queue, and the stall rule
-- (brief systems 1 and 4; m1-contract.md sections C and D, "Server (Systems/Punch)").
--
-- The one client value believed is the burst report's grade (and tap time, sanity-bounded). A Good or Perfect is
-- accepted only when the player is in the context's place (own bag pad / a running fight), no burst of theirs is
-- running, and the receipt time is at least CYCLE(speed) x RATE_TOLERANCE after the last report (TEAM CALL
-- M1-06b: a Miss is held only to "not during a burst" and by Net's 4 a second, since it gains nothing; every
-- report, Miss included, anchors the next cycle). On accept, t0 = receipt time and punch n applies at
-- t0 + BEAT[n] from one Heartbeat queue (never task.delay), beat 1 at once.
-- Refusal reasons (contract C): rate, place, state, grade, busy. A malformed payload is dropped and counted
-- (Punch.stats.dropped), never answered and never an error.
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

local function result(player: Player, seq: number, accepted: boolean, reason: string?, context: string, grade: string, gains: { number }?, t0: number?)
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

local function handleReport(player: Player, p: any)
	-- Shape first: a malformed payload is dropped silently and counted.
	if not Net.isInt(p.seq, 0, 2 ^ 31) or not Net.isOneOf(p.context, Ids.CONTEXTS) or not Net.isOneOf(p.grade, Ids.GRADES) then
		Punch.stats.dropped += 1
		return
	end
	if p.tapServerTime ~= nil and not Net.isNumber(p.tapServerTime) then
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
	-- Busy: a burst of the player's is still running.
	if s.burst and now < s.burst.endsAt then
		return result(player, seq, false, "busy", context, grade)
	end

	if grade == "miss" then
		s.lastReport = now
		Punch.stats.accepted += 1
		if context == "fight" then
			s.nextLanding = now + Config.Punch.MISS_RESTART + ring(player)
			Fight.miss(player, "report")
		end
		return result(player, seq, true, nil, context, grade)
	end

	-- Rate: at least CYCLE x RATE_TOLERANCE since the last report.
	local minGap = Config.Punch.CYCLE(speedLevel(player)) * Config.Punch.RATE_TOLERANCE
	if s.lastReport and now - s.lastReport < minGap then
		return result(player, seq, false, "rate", context, grade)
	end
	-- Grade: a landed tap carries a sane tap time.
	local tap = p.tapServerTime
	if tap == nil or tap - now > Config.Punch.TAP_TIME_FUTURE_S or now - tap > Config.Punch.TAP_TIME_PAST_S then
		return result(player, seq, false, "grade", context, grade)
	end

	-- Accepted.
	s.lastReport = now
	Punch.stats.accepted += 1
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
	result(player, seq, true, nil, context, grade, gains, now)
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
