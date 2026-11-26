--!strict
-- Config.Carry: carrying a beaten boss home (brief system 6; style guide "Carried" and "Carry rock";
-- m1-contract.md section E). Speeds in studs a second.
local Carry = {}

Carry.WALK = 16 -- Roblox default walk speed
Carry.CARRY = 12 -- 75% while carrying
Carry.FAST_CARRY = 16 -- with the Fast Carry pass
Carry.DROP_PUSH = 6 -- a hazard hit while carrying: boss drops, carrier pushed back about 6 studs
Carry.GRAB_S = 5 -- the dropper has 5 s to grab it again
Carry.GRAB_RANGE = 12 -- Carry.Grab: within 12 studs of the dropped boss
Carry.WALK_IN_GRAB = 3 -- walking into a dropped boss grabs it: studs, flat (brief: "by walking into it")
-- Speed check (TEAM CALL M1-11c): over each window the carrier may move speed x window x SLACK + PAD studs on
-- the ground plane; more is pulled back. Lenient on purpose (lag, slopes).
Carry.SPEED_WINDOW = 0.5
Carry.SPEED_SLACK = 1.5
Carry.SPEED_PAD = 2.5
-- The look on the head (style guide): feet 0.5 above the head, never taller than 6, leans back 8, rocks 4 each way.
Carry.HEAD_GAP = 0.5
Carry.MAX_HEIGHT = 6
Carry.LEAN_DEG = 8
Carry.ROCK_DEG = 4

return Carry
