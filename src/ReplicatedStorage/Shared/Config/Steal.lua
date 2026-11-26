--!strict
-- Config.Steal: stealing, the owner's punch, the chase, Iron Grip and the plot fill order (brief systems 7 and 10;
-- m2-contract.md C "Steal", C2 with [M2-02 M5, M7]). Owned by M2-15 (contract section A).
-- Tests override at runtime; never edit this file for a test.
local Steal = {}

-- The hold (brief 10: "hold the Steal prompt on a placed boss for 2.0 s"; Quick Hands 1.0 s).
Steal.HOLD_S = 2.0
Steal.QUICK_HOLD_S = 1.0
Steal.QUICK_PASS = "pass_quick_hands"
Steal.HOLD_RANGE = 6 -- HoldStart: the thief's root within 6 studs (flat) of the boss's spot
Steal.HOLD_CANCEL_SLACK = 1 -- the hold is cancelled ('moved') beyond HOLD_RANGE + 1
Steal.HOLD_HEIGHT = 10 -- and at most this far above or below the spot

-- After a successful steal that boss cannot be stolen again for 60 s (TEAM CALL in the brief).
Steal.SAFE_S = 60

-- The owner's punch (brief 10): within 8 studs of the thief, 0.8 s between punches.
Steal.PUNCH_RANGE = 8
Steal.PUNCH_HEIGHT = 6
Steal.PUNCH_GAP_S = 0.8
Steal.STUN_S = 1.5 -- a hit: the thief drops the boss and is stunned 1.5 s
Steal.IRON_PASS = "pass_iron_grip"
Steal.STAGGER_S = 0.5 -- Iron Grip: the first hit staggers (0.5 s slow, no drop)
Steal.STAGGER_SLOW = 0.5 -- the stagger's walk speed factor (Carry.setSlow, held by the server)
Steal.IRON_WINDOW_S = 10 -- a second hit within 10 s of the stagger drops the boss

-- The chase (brief 10): while one of your bosses is carried off you run at 20 studs/s instead of 16.
Steal.CHASE_SPEED = 20
Steal.WALK = 16
-- The chase is sampled like a carry ([M2-02 M7], N2): over these limits the owner's punches are refused 'speed' for
-- CHASE_FLAG_S. Limits as Config.Carry (step: speed x dt x 2 + 4; window: speed x 1.25 + 2 over 1 s).
Steal.CHASE_STEP_MULT = 2
Steal.CHASE_STEP_PAD = 4
Steal.CHASE_WINDOW_S = 1
Steal.CHASE_WINDOW_MULT = 1.25
Steal.CHASE_WINDOW_PAD = 2
Steal.CHASE_FLAG_S = 1

-- [M2-02 M7] A steal succeeds no sooner than TRAVEL_FACTOR x (straight-line distance from the spot to the thief's
-- plot entrance) / carry speed after the lift. Home sooner = a teleport: the boss goes back ('speed').
Steal.TRAVEL_FACTOR = 0.8

-- Steal.Punch (unreliable) goes to players within this radius of the thief.
Steal.PUNCH_RADIUS = 150

-- Plot fill order (base-layout.md: nearest the gate first, then alternating sides). Systems/Plots.pick reads it.
Steal.PLOT_FILL_ORDER = { 1, 8, 4, 5, 2, 7, 3, 6 }

return Steal
