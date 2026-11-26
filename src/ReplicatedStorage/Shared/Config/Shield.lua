--!strict
-- Config.Shield: the lock shield (brief system 10; m2-contract.md C "Shield"). Owned by M2-15 (contract section A).
-- Tests override at runtime; never edit this file for a test.
local Shield = {}

Shield.UP_S = 60 -- up time
Shield.LONG_UP_S = 90 -- with the Long Lock pass
Shield.LONG_PASS = "pass_long_lock"
Shield.COOLDOWN_S = 60 -- after it drops (or is broken)
Shield.JOIN_S = 60 -- the joining shield (unbreakable), then the normal cooldown
Shield.INSTANT_S = 60 -- Instant Shield (unbreakable), works during the cooldown
Shield.BREAK_RANGE = 15 -- Shield Breaker: the visitor within 15 studs (flat) of the shielded plot's edge
Shield.BREAK_LOCK_S = 300 -- a base broken in the last 5 minutes cannot be broken again
Shield.BROKEN_ALERT_S = 10 -- the owner's "shield broken" alert (TEAM CALL M2-17-2; Base.setAlertCheck reads it)
Shield.PAD_HEIGHT = 8 -- the owner's root at most this far above the lock pad's top counts as on it
Shield.PUSH_OUT = 5 -- a pushed-out player lands this far outside the plot's front fence, at the entrance
Shield.INSIDE_MARGIN = 0.5 -- inside the 50 x 92 by more than this = pushed out

return Shield
