--!strict
-- Config.Fight: boss fights (brief system 4; m1-contract.md sections C, D, E).
local Fight = {}

Fight.HEARTS = 3
Fight.HEALTH_PER_POWER = 10 -- boss health = 10 x the boss's Power
Fight.KNOCKDOWN_S = 2 -- a lost fight: down for 2 s
Fight.PAD_COOLDOWN_S = 5 -- after a loss, that boss can't be challenged by that player for 5 s
Fight.FIXED_BACK_S = 10 -- after a win the fixed pad is back for that player in 10 s (hook PadFastBack overrides)
Fight.RING_SLACK = 2 -- Fight.Start: inside the pad's RingRadius + 2 studs
Fight.RING_RETRY_S = 0.25 -- TEAM CALL M1-26b: a press while walking in can reach the server before the character
-- does (refused "ring"); the client asks once more after this long if it is still in the ring
Fight.STALL_SLACK_S = 0.5 -- TEAM CALL M1-P4: no report by RING[level] + 0.5 s after a landing = one Miss (kept at M2)

-- The fight camera (TEAM CALL M1-26): the boss is the subject. The eye sits on the boss-to-player line turned
-- SIDE_DEG to one side and raised ELEV_DEG, then the distance is solved so the boss's whole bounding box (8 corners,
-- so any tier's size) fits the screen band below, whatever the viewport. Fractions of the viewport, 0 = top/left.
Fight.CAMERA = {
	SIDE_DEG = 60, -- turn from the player-boss line; positive puts the avatar at the lower left of the frame (Huss button is lower right)
	ELEV_DEG = 25, -- raise above the boss's centre height
	BAND_LEFT = 0.06,
	BAND_RIGHT = 0.76, -- left of the Huss button (measured u .78 to .93, M1-26b: a diagonal start put the box under it at 0.94)
	BAND_TOP = 0.28, -- below the fight overlay
	BAND_BOTTOM = 0.93,
	MIN_DIST_H = 1.5, -- never closer than this many boss heights (the camera stays clear of the pad's ring)
	FIT_ITERATIONS = 22, -- bisection steps on the distance
	PAN_ITERATIONS = 6, -- centring steps at each distance,
}

-- The fight spot (TEAM CALL M1-26b): at fight start the SERVER moves the player to a fixed spot on the line from the
-- boss's centre toward where the player stood, facing the boss, so the camera above always has the same picture.
-- Distance from the boss centre = the boss box's half-extent along that line + GAP_H x the boss's H (bigger tiers
-- stand further), clamped to stay on the pad (RingRadius - EDGE_MARGIN) and short of any wall (AVATAR_RADIUS).
Fight.SPOT = {
	GAP_H = 0.75, -- air between the boss box and the player's root, in boss heights (H 4: 3 studs)
	MIN_GAP = 1.5, -- if the ring leaves less than this between box and root on the player's side, use the boss's front
	EDGE_MARGIN = 0.5, -- the root stays this far inside RingRadius
	AVATAR_RADIUS = 1.5, -- kept clear of walls hit by the ray (HFB_Blocker excluded, decision M1-12-3)
}

-- Difficulty bands by r = boss Power / player Power, read at fight start (brief system 4 table), in order.
-- A fight uses the first band whose maxRatio >= r. Windows in ms either side of the landing.
-- M2 (the manager's P2; m2-punch-numbers.md section 1): every window wider, no Good window under 55 ms.
Fight.BANDS = {
	{ id = "easy", maxRatio = 0.5, goodMs = 150, perfectMs = 65 },
	{ id = "fair", maxRatio = 1.0, goodMs = 130, perfectMs = 55 },
	{ id = "hard", maxRatio = 1.5, goodMs = 100, perfectMs = 40 },
	{ id = "veryHard", maxRatio = 2.0, goodMs = 80, perfectMs = 30 },
	{ id = "brutal", maxRatio = 3.0, goodMs = 65, perfectMs = 24 },
	{ id = "impossible", maxRatio = math.huge, goodMs = 55, perfectMs = 20 },
}

-- PROVISIONAL (manager-todo Q1, TEAM CALL M2-03-6): an untimed tap in this band or any later one costs a heart (the
-- boss's attack plays after the punch); bands before it cost none. nil = never a heart; "easy" = always.
Fight.UNTIMED_HEART_FROM = "hard"

-- True when an untimed tap in this band costs a heart (UNTIMED_HEART_FROM and every band after it).
function Fight.untimedCostsHeart(bandId: string): boolean
	local from = Fight.UNTIMED_HEART_FROM
	if from == nil then
		return false
	end
	local iFrom, iBand
	for i, b in ipairs(Fight.BANDS) do
		if b.id == from then
			iFrom = i
		end
		if b.id == bandId then
			iBand = i
		end
	end
	return iFrom ~= nil and iBand ~= nil and iBand >= iFrom
end

-- The band for a ratio (both sides use this; the client colours pad numbers with it).
function Fight.band(ratio: number): { id: string, maxRatio: number, goodMs: number, perfectMs: number }
	for _, b in ipairs(Fight.BANDS) do
		if ratio <= b.maxRatio then
			return b
		end
	end
	return Fight.BANDS[#Fight.BANDS]
end

return Fight
