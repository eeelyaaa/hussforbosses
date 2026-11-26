--!strict
-- brickbrawl / Tokens: every colour, the font, corner radius, outline, lip and shadow sizes. Source: style-guide.md and the UI kit's foundations board
-- Filled at M1-02 (gui-designer) from style-guide.md sections 3 and 6, in the key shape of m1-contract.md section F.
-- Colours are hex in this file only (the skin rule); read them as Skin.Tokens.colors.<job>.
local function hex(h: string): Color3
	return Color3.fromHex(h)
end

local colors = {
	-- UI (style guide 3, "UI")
	panelGrey = hex("#B4BBC6"), -- panel bodies
	plateBlue = hex("#1F6FD6"), -- header bars, titles, progress bars
	hussRed = hex("#E02A2A"), -- the punch: Huss button, Power plate, pips, hearts
	cashGreen = hex("#2FB341"), -- earned cash, ordinary yes
	shopGold = hex("#FFC21A"), -- Robux
	shieldCyan = hex("#35C8F0"), -- the lock
	alarmOrange = hex("#FF6A00"), -- warning, can't be undone, hazards
	flashYellow = hex("#FFF36B"), -- hit feedback only
	white = hex("#FFFFFF"), -- text, wells, secondary buttons
	ink = hex("#101820"), -- outlines, hard shadows, dark text
	disabledGrey = hex("#8A919C"), -- a button that can't be used now
	disabledText = hex("#D5D9DF"), -- text on disabledGrey
	pipEmpty = hex("#3A4250"), -- empty combo pip, lost heart (style guide 6, pips and fight overlay)

	-- World: shared (style guide 3)
	laneGrey = hex("#9AA3B2"),
	kerbWhite = hex("#F2F4F7"),
	arrowYellow = hex("#FFD84A"),
	padStone = hex("#C9CED8"),
	dirt = hex("#7A4B33"),
	bagRed = hex("#E02A2A"), -- same as Huss red

	-- Rarity tiers 1..6: Common, Uncommon, Rare, Epic, Legendary, Mythic
	tier = {
		hex("#A9B2BD"),
		hex("#5DBB2F"),
		hex("#2E8BFF"),
		hex("#9B4DFF"),
		hex("#FF9F1A"),
		hex("#FF3D7F"),
	},

	-- Fight difficulty (text colours only). Easy and Fair share a green; Brutal and Near impossible share a red.
	band = {
		easy = hex("#6BE04A"),
		fair = hex("#6BE04A"),
		hard = hex("#FFE14A"),
		veryHard = hex("#FF9A2E"),
		brutal = hex("#FF4B4B"),
		impossible = hex("#FF4B4B"),
	},

	-- World: zones (style guide 3, "World: zones"). Same six keys per zone; zones 5 and 6 carry one extra each.
	zone1 = { ground = hex("#A9D86B"), ground2 = hex("#8FD13B"), structure = hex("#B5563C"), foliage = hex("#3F8A3F"), dark = hex("#5C6BA8"), accent = hex("#FF7FB6") },
	zone2 = { ground = hex("#F0DFA0"), ground2 = hex("#D9B36A"), structure = hex("#C8643C"), foliage = hex("#4FA36A"), dark = hex("#9C7A4D"), accent = hex("#2FC4B8") },
	zone3 = { ground = hex("#F3E7B6"), ground2 = hex("#57BDE6"), structure = hex("#8A5A3C"), foliage = hex("#3E9A4A"), dark = hex("#2E7FC2"), accent = hex("#C8443A") },
	zone4 = { ground = hex("#F1F6FB"), ground2 = hex("#9FD8F5"), structure = hex("#6F7FA3"), foliage = hex("#2F7F6E"), dark = hex("#5AA9E0"), accent = hex("#B58CFF") },
	zone5 = { ground = hex("#8C7B80"), ground2 = hex("#5E5560"), structure = hex("#A2402E"), foliage = hex("#D9CFC2"), dark = hex("#3E3842"), accent = hex("#FF8A1F"), accentCore = hex("#FFC83D") }, -- accent is Neon lava
	zone6 = { ground = hex("#5566C4"), ground2 = hex("#7A63D6"), structure = hex("#B9C0D4"), foliage = hex("#F3F5FA"), dark = hex("#2C3A78"), accent = hex("#FFE36E"), accentCyan = hex("#4FE3E0") }, -- accent is a Neon star
}

return {
	colors = colors,

	-- One family (style guide 6, "Type"). The weight name is verified in M1-15; Kit.Font reads these two.
	font = { family = "Montserrat", weight = "Heavy" }, -- Montserrat Black: titles, labels, buttons, numbers
	-- TEAM CALL (M1-02): body text is Bold per the type table; contract F lists only `font`, so the body face is a sibling key.
	fontBody = { family = "Montserrat", weight = "Bold" },

	-- Type scale in design px (874 x 402 frame; desktop is the same scale through UIScale, "about 1.6x" is the 1080p result of it)
	type = { title = 22, huss = 20, button = 18, name = 16, small = 14, body = 14 },

	-- Style guide 6 and 6 "Scaling". Design px in the 874 x 402 frame.
	ui = {
		outlinePx = 3, -- panel and button outline
		radiusPx = 4, -- nothing in the UI is a pill
		lipPx = 5, -- the darker edge under a pressable thing
		shadowPx = 5, -- hard shadow offset, down
		shadowAlpha = 0.35, -- ink at 35%
		panelPad = 10,
		gap = 8,
		header = 44,
		buttonH = 48,
		touchMin = 44,
		designW = 874,
		designH = 402,
		mouseScale = 0.75, -- UIScale factor on mouse-and-keyboard
		studTilePx = 16,
		studTileMin = 12,
		studTileMax = 32,
		hussButtonPx = 120,
		hussButtonMinPx = 96,
		ringStartScale = 1.6,
		ringThickPx = 6,
		bandInner = 1.0,
		bandOuter = 1.15,
		bandThickPx = 10,
		-- TEAM CALL (gui-designer, M1-02): the scale at which the white ring's outer edge meets the hit band's centre.
		-- The kit draws the band at 1.0 to 1.15 and says nothing else, so its centre, (1.0 + 1.15) / 2.
		ringLandScale = 1.075,
		pipPx = 18,
		pipGap = 4,

		-- Sizes the style guide gives that M1-08 would otherwise have to hard-code
		wellOutlinePx = 2, -- wells, tier chip, bought tag
		hussOutlinePx = 4, -- the Huss button's outline
		hussLipPx = 6, -- the Huss button's lip
		ringLineOutlinePx = 2, -- ink line each side of the white ring
		pipOutlinePx = 2,
		pipPopScale = 1.25, -- a pip's pop; the third is pipBigPopScale
		pipBigPopScale = 1.4,
		counterH = 32, -- counter plates
		counterIconPx = 36,
		counterIconOverlapPx = 8,
		healthBarH = 14,
		tierChipH = 22,
		textOutlinePx = 2, -- phone; textOutlineDesktopPx on desktop
		textOutlineDesktopPx = 3,
		textShadowPx = 2, -- hard ink shadow under outlined text
		lipFactor = 0.72, -- lip = fill x 0.72
		topLineLighten = 0.25, -- the 2 px line of lightened fill along a button's top
		hoverLighten = 0.08,
		pressedFill = 0.9, -- fill x 0.9
		pressedDropPx = 4,
		dimAlpha = 0.45, -- the ink dim behind an open panel
		glyphPx = 28, -- icon inside a button
		cardIconPx = 64, -- icon on a shop card
	},

	-- The stud tile (style guide 2). Ids are 0 until uploaded (M1-12, section 13); the Kit draws a plain fill while uiTileId is 0.
	stud = {
		uiTileId = 70915382854444,
		worldColorMapId = 106741057264448,
		worldNormalMapId = 106077758301166,
		worldNormalMapFlippedId = 95643445290942, -- green inverted; the proof picks one (M1-12)
		worldRoughMapId = 106124900748892,
		studsPerTile = 4,
		variantName = "Stud",
		normalFlip = true, -- the manager chose B (flipped) for walls and ground, 2026-11-25
	},
}
