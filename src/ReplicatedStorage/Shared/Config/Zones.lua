--!strict
-- Config.Zones: pads, boss Power and base income by creature id (brief system 4 and 5; m1-contract.md E).
-- The whole 36-creature table is the brief's (system 5); M1 uses z1_t1 only.
local Zones = {}

-- Pads by PadId (the builder's Workspace.Zones.Z<n>.Pads.<Kind> attribute PadId). M1: zone 1's fixed pad only.
Zones.PADS = {
	z1_fixed = { creatureId = "z1_t1", zone = 1, kind = "fixed" },
}

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
