--!strict
-- Skin "brickbrawl" (the approved look: team/pack/style-guide.md, ui-kit/, concepts/brick-brawl/).
-- Everything a player sees or hears for an id comes from these tables; rules, numbers and saves never do.
-- Read it through Shared/Skin, never by requiring this folder directly.
return {
	Names = require(script.Names),
	Tokens = require(script.Tokens),
	Models = require(script.Models),
	Icons = require(script.Icons),
	Sounds = require(script.Sounds),
	Lighting = require(script.Lighting),
	Effects = require(script.Effects),
	Dressing = require(script.Dressing),
}
