--!strict
-- Config.Hazards: the zone hazards (brief system 6; m1-contract.md section E). M1: zone 1's Rolling Log.
local Hazards = {}

-- Rolling Log: 12 studs long, about 6 thick, crosses the lane in 3 s, waits 1 s at each side.
Hazards.LOG = { length = 12, thickness = 6, cross_s = 3, wait_s = 1 }
-- Studs of slack in the player's favour in the server's hit test (contract E).
Hazards.HAZARD_TOLERANCE = 1.0
-- Every hazard shows where it will be at least 0.6 s ahead (brief system 6).
Hazards.WARN_S = 0.6

-- A hazard hit on a player who is not carrying: a small push (brief: "a small push only"), studs, and the
-- fewest seconds between two such pushes on one player (TEAM CALL M1-11d; the brief gives no number).
Hazards.SMALL_PUSH = 2
Hazards.PUSH_COOLDOWN_S = 1

return Hazards
