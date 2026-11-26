--!strict
-- Config.Punch: the burst timing contract (build plan, "The burst timing contract"; brief systems 1 and 2;
-- m1-contract.md sections C, D, E). Every number is the brief's or the contract's; tests override at runtime.
local Punch = {}

-- Seconds after the tap at which punches 1, 2, 3 land (brief system 1; B21 may reset from the F probe at M1).
Punch.BEAT = { 0, 0.213, 0.401 }
-- The burst's length: the next ring starts this long after a landed tap (brief system 1).
Punch.BURST_LEN = 0.61
-- Ring close time by Punch Speed level 1..10 (brief system 2 table).
Punch.RING = { 1.20, 1.12, 1.04, 0.96, 0.88, 0.80, 0.72, 0.64, 0.57, 0.50 }
-- After a Miss the ring restarts after the same 0.61 s (brief system 1, "Miss").
Punch.MISS_RESTART = 0.61
-- The server accepts a report no sooner than CYCLE x RATE_TOLERANCE after the last accepted one ("20% tolerance").
Punch.RATE_TOLERANCE = 0.8
-- Punch value per grade; the third punch counts BIG_MULT times (1 + 1 + 2 = 4 Good, 8 Perfect).
Punch.GRADE_VALUE = { perfect = 2, good = 1, miss = 0 }
Punch.BIG_MULT = 2
-- Bag windows in ms either side of the landing (brief system 1). Fight windows: Config.Fight.BANDS.
Punch.BAG_WINDOWS = { perfectMs = 45, goodMs = 110 }
-- Client: a tap earlier than landing - EARLY_TAP_S is ignored (button feedback only, no report).
Punch.EARLY_TAP_S = 0.35
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
