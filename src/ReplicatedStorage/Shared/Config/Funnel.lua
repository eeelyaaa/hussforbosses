--!strict
-- Config.Funnel: the first-session arrow and the funnel log (contract F). Owned by M2-21. Numbers in studs and seconds; no colours
-- (the arrow's yellow is Skin.Tokens.colors.arrowYellow). Tests override at runtime; never edit this file for a test.
local Funnel = {}

-- The arrow is a real part in the world, sized in studs, so it shrinks with distance like everything else (world-label rule).
Funnel.ARROW = {
	POLL_S = 0.25, -- how often the step and its target are looked up again (the bounce runs every frame)
	HEAD = 2.8, -- the head is a cube standing on its corner, this many studs a side
	SHAFT = { 1.4, 3, 1.4 }, -- studs
	BOB = 1.2, -- studs up and down
	BOB_S = 0.9, -- seconds per bounce
	-- studs from the target part's top (a model's pivot) to the arrow's tip, by step
	LIFT = { bag = 6, boss = 22, home = 8, cash = 6, upgrade = 12 },
}

return Funnel
