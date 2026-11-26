--!strict
-- Config.FightCamera: the fight camera framing (P4). While CAMERA is set here, Config/init uses it as Config.Fight.CAMERA, so M2-06 keeps Config/Fight.lua and M2-07 tunes the camera without sharing a file (TEAM CALL M2-01-4).
-- Owned by M2-07 (team/requirements/m2-contract.md section A). Tests override at runtime; never edit this file for a test.
--
-- P4 (the manager: "the fight angle should be a little better for the player"; the avatar read large in the lower left).
-- M1 values were SIDE 60, ELEV 25, band .06 to .76 x .28 to .93: the camera sat 8.2 studs from Chomp Frog and about 7 from the
-- avatar, so the avatar was 0.88 of the screen height (cut off at the left and bottom) beside a boss box 0.65 tall.
-- M2 (TEAM CALL M2-07-1, numbers from a projection model of frameBoss checked against the M1-26b measurements): the camera
-- is higher and further round (SIDE 65, ELEV 38) and the boss band is smaller and moved right, so the solved distance is
-- about 10.6 studs for the frog (23.8 for a H 10 boss) and the avatar is about 0.45 of the screen height, whole, centre-left,
-- with the boss right of it (box about 0.54 tall) and clear of the Huss button (u .78 to .93).
-- The keys are the ones Controllers/Fight.frameBoss reads (see Config/Fight.lua's CAMERA block for what each means).
local FightCamera = {}

FightCamera.CAMERA = {
	SIDE_DEG = 65, -- turn from the player-boss line; positive puts the avatar at the left of the frame (Huss button is lower right)
	ELEV_DEG = 38, -- raise above the boss's centre height (more top-down: the avatar sits low and in front, not over the boss)
	BAND_LEFT = 0.30, -- the boss's screen box is centred in this band: leaves the left third to the avatar
	BAND_RIGHT = 0.76, -- left of the Huss button (measured u .78 to .93, M1-26b)
	BAND_TOP = 0.31, -- below the fight overlay
	BAND_BOTTOM = 0.85,
	MIN_DIST_H = 1.5, -- never closer than this many boss heights (the camera stays clear of the pad's ring)
	FIT_ITERATIONS = 22, -- bisection steps on the distance
	PAN_ITERATIONS = 6, -- centring steps at each distance
	AVOID_OVERLAP = 0.04, -- when the avatar would cover more than this share of the boss's screen box, turn the camera further round
	SIDE_STEP = 8, -- degrees per try
	SIDE_MAX = 90, -- never past a pure side view
}

return FightCamera
