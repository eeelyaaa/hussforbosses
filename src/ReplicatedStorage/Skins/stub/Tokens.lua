--!strict
-- stub / Tokens: brickbrawl's key shape, all greys. Sizes are structure, so they match brickbrawl's.
local function g(v: number): Color3
	return Color3.new(v, v, v)
end
local function zone(extra: string?): { [string]: Color3 }
	local z = { ground = g(0.6), ground2 = g(0.55), structure = g(0.45), foliage = g(0.4), dark = g(0.3), accent = g(0.7) }
	if extra then
		z[extra] = g(0.75)
	end
	return z
end

return {
	colors = {
		panelGrey = g(0.7), plateBlue = g(0.4), hussRed = g(0.35), cashGreen = g(0.5), shopGold = g(0.8),
		shieldCyan = g(0.65), alarmOrange = g(0.45), flashYellow = g(0.9), white = g(1), ink = g(0.08),
		disabledGrey = g(0.55), disabledText = g(0.85), pipEmpty = g(0.25),
		laneGrey = g(0.6), kerbWhite = g(0.95), arrowYellow = g(0.85), padStone = g(0.78), dirt = g(0.3), bagRed = g(0.35),
		tier = { g(0.6), g(0.55), g(0.5), g(0.45), g(0.4), g(0.35) },
		band = { easy = g(0.8), fair = g(0.8), hard = g(0.7), veryHard = g(0.6), brutal = g(0.5), impossible = g(0.5) },
		zone1 = zone(), zone2 = zone(), zone3 = zone(), zone4 = zone(), zone5 = zone("accentCore"), zone6 = zone("accentCyan"),
	},
	font = { family = "Montserrat", weight = "Heavy" },
	fontBody = { family = "Montserrat", weight = "Bold" },
	type = { title = 22, huss = 20, button = 18, name = 16, small = 14, body = 14 },
	ui = {
		outlinePx = 3, radiusPx = 4, lipPx = 5, shadowPx = 5, shadowAlpha = 0.35, panelPad = 10, gap = 8, header = 44,
		buttonH = 48, touchMin = 44, designW = 874, designH = 402, mouseScale = 0.75, studTilePx = 16, studTileMin = 12,
		studTileMax = 32, hussButtonPx = 120, hussButtonMinPx = 96, ringStartScale = 1.6, ringThickPx = 6, bandInner = 1.0,
		bandOuter = 1.15, bandThickPx = 10, ringLandScale = 1.075, pipPx = 18, pipGap = 4,
		wellOutlinePx = 2, hussOutlinePx = 4, hussLipPx = 6, ringLineOutlinePx = 2, pipOutlinePx = 2, pipPopScale = 1.25,
		pipBigPopScale = 1.4, perfectRisePx = 44, spentFill = 0.6, spentTextAlpha = 0.35, perfectDriftPx = 36, perfectFloatS = 0.85, perfectFadeFrom = 0.55, perfectPopScale = 1.35,
		untimedPopScale = 1.08, untimedStarScale = 0.75, counterH = 32, counterIconPx = 36, counterIconOverlapPx = 8, healthBarH = 14, tierChipH = 22,
		textOutlinePx = 2, textOutlineDesktopPx = 3, textShadowPx = 2, lipFactor = 0.72, topLineLighten = 0.25,
		hoverLighten = 0.08, pressedFill = 0.9, pressedDropPx = 4, dimAlpha = 0.45, glyphPx = 28, cardIconPx = 64,
	},
	stud = {
		uiTileId = 0, worldColorMapId = 0, worldColorBakedMapId = 0, worldNormalMapId = 0, worldNormalMapFlippedId = 0, worldRoughMapId = 0,
		studsPerTile = 4, variantName = "Stud", normalFlip = false,
	},
}
