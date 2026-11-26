--!strict
-- Config.Hazards: the six zone hazards (brief system 6; m1-contract.md E; m2-contract.md C). Shapes and timings
-- are the brief's draft numbers; where the brief gives none the value is a TEAM CALL (M2-11, team/decisions.md).
-- Positions are pure functions of the server clock in Shared/Hazards. Tests override at runtime, never by editing.
local Hazards = {}

-- 1 Rolling Log: 12 studs long, about 6 thick, crosses the lane in 3 s, waits 1 s at each side.
Hazards.LOG = { length = 12, thickness = 6, cross_s = 3, wait_s = 1 }
-- 2 Tumble Cactus: 8 wide, 14 studs/s down the throat toward the bases in a zigzag, one every 6 s.
--   run = studs of throat it crosses (the 30-stud throat); zigs = side-to-side legs over the run (TEAM CALL M2-11-1);
--   bounce = how high it hops, studs (look and hit both; a hop is in the player's favour).
Hazards.CACTUS = { width = 8, speed = 14, every_s = 6, run = 30, zigs = 2, bounce = 1.5 }
-- 3 Swinging Anchor: covers the middle 24 of 36 studs, one swing (side to side) every 3 s. The head is a box
--   across x along x tall, its bottom `lift` above the lane (TEAM CALL M2-11-1).
Hazards.ANCHOR = { cover = 24, swing_s = 3, head_across = 4, head_along = 3, head_height = 5, lift = 0.5, pivot_height = 18 }
-- 4 Sliding Ice Block: 10 x 10, 20 studs/s side to side, waits 1 s each side; `height` tall.
Hazards.ICE = { size = 10, height = 6, speed = 20, wait_s = 1 }
-- 5 Lava Burst Row: six tiles across the lane; each glows 0.8 s then erupts 0.6 s, one after another; a sweep takes 4 s
--   and the next sweep runs back. tile_along = tile depth along the lane; height = how high an eruption reaches.
Hazards.LAVA = { tiles = 6, tile_along = 6, glow_s = 0.8, erupt_s = 0.6, sweep_s = 4, height = 8 }
-- 6 Orbit Meteor: circles low over the lane, radius 14, a lap every 4 s; the rock is a ball `radius`, its centre
--   `height` above the lane. The circle is centred in the middle of the throat.
Hazards.METEOR = { circle_r = 14, lap_s = 4, radius = 3, height = 3.5 }

-- Studs of slack in the player's favour in the server's hit test (contract E).
Hazards.HAZARD_TOLERANCE = 1.0
-- Every hazard shows where it will be at least 0.6 s ahead (brief system 6): the client draws the pose at t + WARN_S.
Hazards.WARN_S = 0.6

-- A hazard hit on a player who is not carrying: a small push (brief: "a small push only"), studs, and the
-- fewest seconds between two such pushes on one player (TEAM CALL M1-11d; the brief gives no number).
Hazards.SMALL_PUSH = 2
Hazards.PUSH_COOLDOWN_S = 1

-- The check's "always leaves a way through" rule: at every moment, at every slice of the throat, a stretch of lane at
-- least this many studs wide is clear of the hazard (a carrier is about 2 to 3 wide: brief system 6).
Hazards.MIN_WAY = 3

return Hazards
