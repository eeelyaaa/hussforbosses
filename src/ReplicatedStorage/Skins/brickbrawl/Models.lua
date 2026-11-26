--!strict
-- brickbrawl / Models: model name per id (creatures, bags, hazards, gloves, props). Structure (moving-group names, pivots, heights per tier) stays in Shared/Moves
-- M1-03 (modeler-3d): creatures.z1_t1 and gloves, per contract F. Mesh ids wired at M1-17 (atlas route, B4) from the Studio import (assets.md).
-- The meshes come from tools/blender/ (build_boss.py, build_gloves.py); the pivots in numbers are in
-- assets-src/models/z1_t1.groups.json and gloves.groups.json. bags, hazards and clips are filled by their owners.
return {
	creatures = {
		z1_t1 = {
			model = "Boss_z1_t1",
			bodyType = 2,
			heightStuds = 4,
			-- mesh id per group, atlas route (one mesh per group)
			groups = {
				Body = 124930310883753, Head = 111961754367044, Sig = 110959131671988,
				FistL = 123078999255876, FistR = 109820571392209,
			},
			-- the shared atlas (boss-atlas.png, uploaded by the importer); every atlas MeshPart carries it as TextureID, Color white (B4, M1-17)
			textureId = 116542096217311,
		},
		z2_t2 = {
			model = "Boss_z2_t2",
			bodyType = 3,
			heightStuds = 5.3,
			-- M2 import 2026-11-26 (main session, Studio 3D importer, creator the group); shared atlas HFB Boss Atlas M2b (fix-pass re-import 2026-11-26)
			groups = { Body = 86635252190823, Head = 92480351659598, FistL = 110304413948016, FistR = 76594033350875, TailA = 84620791590064, TailB = 109535509730296 },
			textureId = 131662969906561,
		},
		z3_t3 = {
			model = "Boss_z3_t3",
			bodyType = 5,
			heightStuds = 6.8,
			-- M2 import 2026-11-26 (main session, Studio 3D importer, creator the group); shared atlas HFB Boss Atlas M2b (fix-pass re-import 2026-11-26)
			groups = { Body = 72958695042638, Upper = 120223582736801, Head = 101148513208139, FistL = 119929680357524, FistR = 99980588152630 },
			textureId = 131662969906561,
		},
		z4_t4 = {
			model = "Boss_z4_t4",
			bodyType = 1,
			heightStuds = 8.3,
			-- M2 import 2026-11-26 (main session, Studio 3D importer, creator the group); shared atlas HFB Boss Atlas M2b (fix-pass re-import 2026-11-26)
			groups = { Body = 121945055273244, Head = 116859351158815, FistL = 72856501334740, FistR = 87415690784851 },
			textureId = 131662969906561,
		},
		z5_t5 = {
			model = "Boss_z5_t5",
			bodyType = 3,
			heightStuds = 10.9,
			-- M2 import 2026-11-26 (main session, Studio 3D importer, creator the group); shared atlas HFB Boss Atlas M2b (fix-pass re-import 2026-11-26)
			groups = { Body = 105363820205535, Head = 73984879618041, FistL = 127795680987940, FistR = 75544402492491, TailA = 81054688719818, TailB = 91636845515290 },
			textureId = 131662969906561,
		},
		z6_t6 = {
			model = "Boss_z6_t6",
			bodyType = 1,
			heightStuds = 14,
			-- M2 import 2026-11-26 (main session, Studio 3D importer, creator the group); shared atlas HFB Boss Atlas M2b (fix-pass re-import 2026-11-26)
			groups = { Body = 80783494035999, Head = 118805192049060, FistL = 87353624750499, FistR = 120847069623083, Sig = 104123716997259 },
			textureId = 131662969906561,
		},
	},
	-- M1-24: the model names studio/BuildSlice.lua builds for the bag-1 and Rolling Log stand-ins (Plot "Bag", Zones.Z1 "Hazard_Log").
	bags = { "Bag" },
	hazards = { "Hazard_Log" },
	gloves = {
		model = "Gloves",
		groups = { GloveL = 76241603600658, GloveR = 110446020050450 },
		textureId = 116542096217311, -- same atlas; Color white
	},
	-- Avatar punch clips (M1-10): published Animation ids, 0 until published (MS-B1). R15 ids in `clips`, R6 in
	-- `clipsR6` (a clip only plays on its own rig type). Brief: team/verification/m1-10-avatar.md.
	-- M2-23: flinch, carryHold, stealLift, knockdown, stun (published 2026-11-26 under the group by the main session, Explorer Save to Roblox).
	clips = { jab3 = 107079293119205, bigThird = 85557599926728, flinch = 134871997175385, carryHold = 104908826483350, stealLift = 98967342912981, knockdown = 128104978695493, stun = 105520069391796 },
	clipsR6 = { jab3 = 131510122151794, bigThird = 112874224987934, flinch = 115934676015982, carryHold = 115818486780894, stealLift = 112279758563479, knockdown = 77300258469560, stun = 135578946454442 },
}
