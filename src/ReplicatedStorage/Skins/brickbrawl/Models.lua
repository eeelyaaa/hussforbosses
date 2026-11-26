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
	clips = { jab3 = 107079293119205, bigThird = 85557599926728 },
	clipsR6 = { jab3 = 131510122151794, bigThird = 112874224987934 },
}
