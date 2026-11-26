--!strict
-- Config.Carry: carrying a boss (brief system 6; style guide "Carried" and "Carry rock"; m1-contract.md E,
-- m2-contract.md C2). Speeds in studs a second.
local Carry = {}

Carry.WALK = 16 -- Roblox default walk speed
Carry.CARRY = 12 -- 75% while carrying
Carry.FAST_CARRY = 16 -- with the Fast Carry pass
Carry.FAST_PASS = "pass_fast_carry"
Carry.DROP_PUSH = 6 -- a hazard hit while carrying: boss drops, carrier pushed back about 6 studs
Carry.GRAB_S = 5 -- the dropper has 5 s to grab it again
Carry.GRAB_RANGE = 12 -- Carry.Grab: within 12 studs of the dropped boss
Carry.WALK_IN_GRAB = 3 -- walking into a dropped boss grabs it: studs, flat (brief: "by walking into it")

-- Movement check ([M2-02 M7], contract C2), sampled every Heartbeat on the flat (falls are not counted):
--   a single step longer than speed x dt x STEP_MULT + STEP_PAD studs is a teleport;
--   the distance over any WINDOW_S window may not exceed speed x WINDOW_MULT + WINDOW_PAD studs.
-- A fight, crate or spot carry that breaks either is pulled back to its last good position (TEAM CALL M2-11-4);
-- a stolen carry ends (Systems/Steal returns the boss).
Carry.STEP_MULT = 2
Carry.STEP_PAD = 4
Carry.WINDOW_S = 1
Carry.WINDOW_MULT = 1.25
Carry.WINDOW_PAD = 2

-- A boss of your own (taken from the crate or picked up from a spot) cannot leave your base (brief system 7): a carrier
-- whose root goes more than BASE_MARGIN studs outside the plot's 50 x 92 is put back where it last stood inside.
Carry.BASE_MARGIN = 0.5

-- The look on the head (style guide): feet 0.5 above the head, never taller than 6, leans back 8, rocks 4 each way.
Carry.HEAD_GAP = 0.5
Carry.MAX_HEIGHT = 6
Carry.LEAN_DEG = 8
Carry.ROCK_DEG = 4

return Carry
