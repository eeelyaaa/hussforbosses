--!strict
-- Config.Punch: the burst timing contract (build plan, "The burst timing contract"; brief systems 1 and 2;
-- m1-contract.md sections C, D, E). Every number is the brief's or the contract's; tests override at runtime.
local Punch = {}

-- Seconds after the tap at which punches 1, 2, 3 land (brief system 1; B21 may reset from the F probe at M1).
Punch.BEAT = { 0, 0.213, 0.401 }
-- The burst's length: the next ring starts this long after a landed tap (brief system 1).
Punch.BURST_LEN = 0.61
-- Ring close time by Punch Speed level 1..10 (M2, the manager's P2 "a little quicker"; m2-punch-numbers.md section 1;
-- M1 was 1.20 .. 0.50). Cycle spread Speed 1 / Speed 10 = 1.66 / 1.02.
Punch.RING = { 1.05, 0.98, 0.91, 0.84, 0.77, 0.70, 0.63, 0.56, 0.48, 0.41 }
-- After a Miss the ring restarts after the same 0.61 s (brief system 1, "Miss"); after an untimed tap the next ring
-- opens at that ring's scheduled landing + MISS_RESTART (m2-punch-numbers.md section 2).
Punch.MISS_RESTART = 0.61
-- Server rate rules (m2-punch-numbers.md section 2, replacing contract B4; all on receipt time):
-- a timed report (good/perfect) needs CYCLE x RATE_TOLERANCE since the last accepted TIMED report, and
-- UNTIMED_MIN_GAP_S since the last accepted report of any grade; an untimed report needs UNTIMED_MIN_GAP_S since
-- the last accepted report of any grade (plus the context's Good window after an untimed one: TEAM CALL M2-06-1,
-- "one report per ring"), else 'untimedBusy'.
Punch.RATE_TOLERANCE = 0.75
Punch.UNTIMED_MIN_GAP_S = 0.66
-- In a fight an untimed report must arrive inside the server's current ring (M2-02 S6, TEAM CALL M2-06-5): no earlier
-- than ring open + RING_GRACE_S - UNTIMED_EARLY_SLACK_S, no later than its landing + UNTIMED_LATE_SLACK_S (a tap
-- before the Good edge plus up to two one-way latencies at the fight's first ring).
Punch.UNTIMED_EARLY_SLACK_S = 0.10
Punch.UNTIMED_LATE_SLACK_S = 0.25
-- Client: taps in the first RING_GRACE_S of a ring are ignored (a stray tap just after a burst never spends a ring).
Punch.RING_GRACE_S = 0.15
-- Punch value per grade; the third punch of a burst counts BIG_MULT times (1 + 1 + 2 = 4 Good, 8 Perfect).
-- untimed = one punch at value 1, applied once at accept time (no burst, no BIG_MULT; the manager's P3).
Punch.GRADE_VALUE = { perfect = 2, good = 1, untimed = 1, miss = 0 }
Punch.BIG_MULT = 2
-- Bag windows in ms either side of the landing (M2, P2 "a little easier"). Fight windows: Config.Fight.BANDS.
Punch.BAG_WINDOWS = { perfectMs = 55, goodMs = 130 }
-- EARLY_TAP_S (M1: a tap earlier than landing - 0.35 s ignored) is no longer used for grading (contract B1, P3:
-- clicking works anywhere in the ring after RING_GRACE_S); removed at M2-06.
-- Server sanity bounds on tapServerTime against the receipt time.
Punch.TAP_TIME_FUTURE_S = 0.25
Punch.TAP_TIME_PAST_S = 1.0

-- Rate limits per player per remote, calls per second (contract C). Over the limit: dropped silently, counted
-- in TestHooks.reports._dropped. Net.onServerEvent requires an entry for every c2s remote.
Punch.MAX_REPORTS_PER_SEC = 4
Punch.RATE = {
	["Punch.Report"] = 4,
	["Fight.Start"] = 2,
	["Fight.Run"] = 2, -- TEAM CALL (M1-01): the contract gives none; same as Fight.Start
	["Carry.Grab"] = 4,
	["Base.Place"] = 4,
	["Profile.TestReport"] = 10,
}

-- Combo cycle at a Speed level: ring close time + the burst (brief system 2: 1.81 s at level 1).
function Punch.CYCLE(level: number): number
	local ring = Punch.RING[math.clamp(math.floor(level), 1, #Punch.RING)]
	return ring + Punch.BURST_LEN
end

return Punch
