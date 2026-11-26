--!strict
-- Config.Zones: pads, boss Power and base income by creature id (brief system 4 and 5; m1-contract.md E).
-- The whole 36-creature table is the brief's (system 5). Owned by M2-10 (m2-contract.md A).
local Zones = {}

-- Pads by PadId (brief system 5: 4 per zone, 24 in all). The world's pad Models carry the attribute PadId and the tag
-- HFB_BossPad (Workspace.Zones.Z<n>.Pads.<Fixed|Roll1|Roll2|Roll3>). The fixed pad is always the zone's Common; a
-- rolling pad's creatureId is the server's current roll (Systems/Zones). M2-10: all six zones.
Zones.PADS = {} :: { [string]: { creatureId: string?, zone: number, kind: string, slot: number } }
for zone = 1, 6 do
	Zones.PADS[("z%d_fixed"):format(zone)] = { creatureId = ("z%d_t1"):format(zone), zone = zone, kind = "fixed", slot = 0 }
	for k = 1, 3 do
		Zones.PADS[("z%d_roll%d"):format(zone, k)] = { zone = zone, kind = "roll", slot = k }
	end
end

-- Rolling pads (brief system 5): every ROLL_S seconds each pad rolls a new creature from its zone. Hook PadsFast
-- replaces ROLL_S. The three pads of a zone are staggered by ROLL_S / 3 (TEAM CALL M2-10-2) so a zone always has a
-- countdown close to its end.
Zones.ROLL_S = 45
Zones.ROLL_STAGGER = true
-- Roll odds by zone, percent for tiers 1..6 (Common .. Mythic), each row 100 (brief system 5 table).
Zones.ROLL_ODDS = {
	{ 50, 28, 14, 6, 1.7, 0.3 },
	{ 46, 28, 15, 8, 2.5, 0.5 },
	{ 42, 28, 16, 10, 3.3, 0.7 },
	{ 38, 27, 18, 12, 4, 1 },
	{ 34, 26, 20, 13, 5.5, 1.5 },
	{ 30, 25, 21, 15, 7, 2 },
}

-- Patrol (the manager's P5; m2-contract.md E; Shared/Patrol). Stand-ins until the M3 world gives each boss its region
-- (PROVISIONAL manager-todo Q3: a short walk, 14 studs each way). slack = extra studs on the Fight.Start ring test.
Zones.PATROL = { halfLen = 14, speed = 4, pauseS = 1.0, slack = 1.5 }
-- The lane's centre line (structure, the test strip's: X 206, running +Z). A pad without a PatrolAnchor part walks
-- along it, facing it at the turns (Shared/Patrol.anchor).
Zones.LANE = { origin = Vector3.new(206, 0, 0), axis = Vector3.new(0, 0, 1) }


-- Boss Power by creature id (brief system 5 table).
Zones.POWER = {
	z1_t1 = 25, z1_t2 = 40, z1_t3 = 65, z1_t4 = 100, z1_t5 = 150, z1_t6 = 225,
	z2_t1 = 250, z2_t2 = 400, z2_t3 = 650, z2_t4 = 1000, z2_t5 = 1500, z2_t6 = 2250,
	z3_t1 = 2500, z3_t2 = 4000, z3_t3 = 6500, z3_t4 = 10000, z3_t5 = 15000, z3_t6 = 22500,
	z4_t1 = 25000, z4_t2 = 40000, z4_t3 = 65000, z4_t4 = 100000, z4_t5 = 150000, z4_t6 = 225000,
	z5_t1 = 250000, z5_t2 = 400000, z5_t3 = 650000, z5_t4 = 1000000, z5_t5 = 1500000, z5_t6 = 2250000,
	z6_t1 = 2500000, z6_t2 = 4000000, z6_t3 = 6500000, z6_t4 = 10000000, z6_t5 = 15000000, z6_t6 = 22500000,
}

-- Base income, cash per second at boss level 1 (brief system 5 table).
Zones.INCOME = {
	z1_t1 = 1, z1_t2 = 2, z1_t3 = 4, z1_t4 = 8, z1_t5 = 20, z1_t6 = 60,
	z2_t1 = 8, z2_t2 = 16, z2_t3 = 32, z2_t4 = 64, z2_t5 = 160, z2_t6 = 480,
	z3_t1 = 60, z3_t2 = 120, z3_t3 = 240, z3_t4 = 480, z3_t5 = 1200, z3_t6 = 3600,
	z4_t1 = 450, z4_t2 = 900, z4_t3 = 1800, z4_t4 = 3600, z4_t5 = 9000, z4_t6 = 27000,
	z5_t1 = 3500, z5_t2 = 7000, z5_t3 = 14000, z5_t4 = 28000, z5_t5 = 70000, z5_t6 = 210000,
	z6_t1 = 28000, z6_t2 = 56000, z6_t3 = 112000, z6_t4 = 224000, z6_t5 = 560000, z6_t6 = 1680000,
}

-- Zones.Clock is re-sent every 30 s (contract C).
Zones.CLOCK_EVERY_S = 30

return Zones
