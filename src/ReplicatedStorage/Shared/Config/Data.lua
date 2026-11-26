--!strict
-- Config.Data: saving (brief system 14; m2-contract.md section D; build plan "Data schema outline and save rules").
-- Owned by M2-09 (data-engineer). Tests override at runtime (the Saving check points STORE_BASE at a check store
-- and shortens the timers); never edit this file for a test.
local Data = {}

-- Store name = "HFB_" .. Config.Env .. "_" .. STORE_BASE (Data/Store builds it), so a Studio session never reads
-- or writes the live store. Key = KEY_PREFIX .. UserId (the user id stays a plain substring: erasure requests match).
Data.STORE_BASE = "Players"
Data.KEY_PREFIX = "player_"

-- Timers (seconds).
Data.AUTOSAVE_S = 60 -- B9: every live profile is written this often (also renews the lock)
Data.LOCK_LEASE_S = 300 -- a lock whose stamp is older than this is stale and may be taken
Data.LOAD_TRIES = 4 -- the first load and 3 retries ...
Data.LOAD_GAP_S = 5 -- ... 5 s apart (15 s), then a temp profile (Profile.Notice notSaving)
Data.BG_RETRY_S = 15 -- M2-02 S2: a temp profile keeps trying in the background this often ...
Data.BG_RETRY_FOR_S = 330 -- ... for this long (the lease plus a margin), then swaps the real profile in
Data.WRITE_TRIES = 3 -- one UpdateAsync per write; a call that errors is tried again up to this many times
Data.WRITE_BACKOFF_S = { 1, 2, 4 }
Data.BUDGET_WAIT_S = 5 -- wait up to this long for DataStore request budget before a call
Data.SHUTDOWN_BUDGET_S = 25 -- BindToClose has 30 s (docs); everything is saved within 25

-- Studio only: a play session's join takes a lock an earlier Studio play session left (Studio's stop does not
-- always finish the release, and a 5-minute wait would break every other check). The Saving check sets it false
-- to test locks exactly as a live server does. Ignored outside Studio.
Data.STUDIO_TAKE_LOCK_ON_JOIN = true

-- Sizes.
Data.PURCHASES_KEPT = 200 -- B9: handled purchase ids kept (newest)
Data.TRANSFER_NOTES_KEPT = 20 -- contract D: transferNote keeps the last 20 "left" notes whose boss has been resolved
-- M2-27 MF1: arrival evidence is kept by age, not count. An arrival note ({ uid, from, at }) stays this long; a "left"
-- note that still carries its boss and is older than this is taken as landed (its evidence would have expired).
Data.ARRIVAL_KEEP_S = 60 * 86400
Data.ARRIVAL_MAX = 500 -- a safety cap on arrival notes (oldest dropped first; ~60 bytes each)

-- Validation bounds for saved values (Session.mutate refuses a change that leaves the profile outside them).
-- Strength and Speed caps are Config.Bag.STRENGTH_MAX / SPEED_MAX (one source).
Data.LIMITS = {
	rebirthsMax = 10, -- brief system 13
	bossLevelMax = 20, -- brief system 8
	spots = 17, -- brief system 7 (base 8 + rebirth spots + Extra Spots)
	zones = 6,
}

return Data
