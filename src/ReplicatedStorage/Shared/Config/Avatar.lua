--!strict
-- Config.Avatar: the avatar's gloves and punch clips (m1-contract.md section J; style guide section 7).
-- Numbers only; the colours and asset ids are in Skins/<skinId>/ (Tokens, Models.clips).
return {
	-- Gloves: size follows the head ("about the size of the avatar's head"). The stand-in glove is built for a head
	-- of GLOVE_REF_HEAD studs and scaled by head.Size.Y / GLOVE_REF_HEAD, so every body shape gets a fitting pair.
	GLOVE_REF_HEAD = 1.2,
	GLOVE_SCALE_MIN = 0.7,
	GLOVE_SCALE_MAX = 1.5,
	-- Where the glove's pivot (the wrist) sits in the hand's space, studs (unscaled). R15: the hand's wrist
	-- attachment is used when present (about +0.13); this is the fallback. R6 has no hand: the arm's lower end.
	R15_WRIST_Y = 0.13,
	R6_WRIST_Y = -0.35,
	-- Stand-in glove dimensions (studs, for the reference head): cuff band and fist block.
	STANDIN_CUFF = { 0.95, 0.30, 0.95 },
	STANDIN_FIST = { 1.25, 1.00, 1.25 },
	-- The clip pair. bigThird is a separate clip started this long before beat 3 so its contact frame (at this
	-- time in the clip) lands on BEAT[3]; it replaces the jab3 clip's own third jab.
	BIG_LEAD = 0.08,
	SWITCH_FADE = 0.02,
	-- Carry hold: arms straight up (degrees at the shoulder) and the raise time in seconds.
	CARRY_SHOULDER_DEG = 175,
	CARRY_RAISE_S = 0.15,
}
