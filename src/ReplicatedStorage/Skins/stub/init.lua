--!strict
-- Skin "stub": the skin-check fixture (m1-contract.md section F; m1-core-loop-gate.md, "The skin check").
-- Same keys as brickbrawl, nothing of its look: names are the ids, colours are greys, every asset id is 0,
-- models are 5-group grey boxes built by studio/CheckSkin.lua at run time ("Boss_z1_t1_stub"), no sounds.
-- If the game runs its loop under this skin, the rules do not depend on the skin.
-- Grey literals are allowed here (Skins/ is outside the skin rule's scan). Keep its key shape equal to
-- brickbrawl's: studio/CheckSkin.lua fails on any key one has and the other lacks.
return {
	Names = require(script.Names),
	Tokens = require(script.Tokens),
	Models = require(script.Models),
	Icons = require(script.Icons),
	Sounds = require(script.Sounds),
	Lighting = {},
	Effects = { stars = {}, cubeBurst = {} },
	Dressing = {},
}
