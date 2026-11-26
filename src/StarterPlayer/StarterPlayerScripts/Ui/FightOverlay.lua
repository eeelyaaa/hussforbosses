--!nonstrict
-- Ui/FightOverlay: the plate across the top of a fight (style guide 6, screen 2; ui-kit/phone-hud-fight.png) and the Run button.
--   show(info)   setHealth(h, max)   setHearts(n)   setBand(band)   hide()   onRun(fn)
-- info = the Fight.State payload (creatureId, band, health, maxHealth, hearts ...) plus bossName, tierWord (and tier, 1..6, optional:
-- when absent it is read from the creature id "z<zone>_t<tier>"). Names, tier words and band words come from Skin.Names.
-- The plate: boss name, tier chip, band word in its difficulty colour; the health bar (14 px, the boss's tier colour on an ink
-- track); three square-built hearts (a lost heart is pipEmpty) and "150 / 250" beside them. Run is a white button top left,
-- never under 44 px on screen. Nothing here sits over the Huss button (plate bottom y = 128 design px, ring top is below it).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Skin = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Skin"))
local C, U, N, TY = Skin.Tokens.colors, Skin.Tokens.ui, Skin.Names, Skin.Tokens.type

local FightOverlay = {}
local S = nil

local PLATE_W, PLATE_H = 385, 82
local PLATE_TOP = 46 -- below the counter row
local RUN_POS = Vector2.new(12, 59)
local RUN_W, RUN_H = 108, 50
local HEART_CELL = 3

local function tierOf(info): number?
	if info.tier then
		return info.tier
	end
	local id = info.creatureId
	if type(id) == "string" then
		local t = string.match(id, "_t(%d+)$")
		return t and tonumber(t) or nil
	end
	return nil
end

function FightOverlay.build(parent: Instance)
	FightOverlay.destroy()
	S = { runCallbacks = {}, hearts = 3, health = 0, max = 1 }

	local group = Instance.new("Folder")
	group.Name = "FightOverlay"
	group.Parent = parent
	S.group = group

	local plate = Kit.Panel(group, {
		name = "Plate",
		fill = C.panelGrey,
		size = UDim2.fromOffset(PLATE_W, PLATE_H),
		position = UDim2.new(0.5, 0, 0, PLATE_TOP),
		anchor = Vector2.new(0.5, 0),
	})
	plate.Visible = false
	S.plate = plate

	-- row 1: name, tier chip, band word (centred, laid out by a UIListLayout)
	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, -2 * U.panelPad, 0, 30)
	row.Position = UDim2.fromOffset(U.panelPad, 6)
	row.ZIndex = 3
	row.Parent = plate
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, U.gap)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row

	S.name = Kit.Text(row, { name = "BossName", text = "", size = TY.button, sizeU = UDim2.fromOffset(0, 30) })
	S.name.AutomaticSize = Enum.AutomaticSize.X
	S.name.LayoutOrder = 1

	local chip = Kit.Plate(row, { name = "TierChip", fill = C.tier[1], size = UDim2.fromOffset(0, U.tierChipH), outline = U.wellOutlinePx, studs = false })
	chip.AutomaticSize = Enum.AutomaticSize.X
	chip.LayoutOrder = 2
	local chipPad = Instance.new("UIPadding")
	chipPad.PaddingLeft = UDim.new(0, 8)
	chipPad.PaddingRight = UDim.new(0, 8)
	chipPad.Parent = chip
	S.chip = chip
	S.chipText = Kit.Text(chip, { name = "Word", text = "", size = TY.small, sizeU = UDim2.fromOffset(0, U.tierChipH) })
	S.chipText.AutomaticSize = Enum.AutomaticSize.X

	S.bandWord = Kit.Text(row, { name = "BandWord", text = "", size = TY.button, sizeU = UDim2.fromOffset(0, 30) })
	S.bandWord.AutomaticSize = Enum.AutomaticSize.X
	S.bandWord.LayoutOrder = 3

	-- row 2: health bar on an ink track
	local track = Instance.new("Frame")
	track.Name = "HealthTrack"
	track.BackgroundColor3 = C.ink
	track.BorderSizePixel = 0
	track.Size = UDim2.new(1, -2 * U.panelPad, 0, U.healthBarH)
	track.Position = UDim2.fromOffset(U.panelPad, 42)
	track.ZIndex = 3
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, U.radiusPx)
	tc.Parent = track
	local ts = Instance.new("UIStroke")
	ts.Color = C.ink
	ts.Thickness = U.wellOutlinePx
	ts.Parent = track
	track.Parent = plate
	local fill = Instance.new("Frame")
	fill.Name = "HealthFill"
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = C.tier[1]
	fill.Size = UDim2.fromScale(1, 1)
	fill.ZIndex = 4
	local fcorner = Instance.new("UICorner")
	fcorner.CornerRadius = UDim.new(0, U.radiusPx)
	fcorner.Parent = fill
	fill.Parent = track
	S.track, S.fill = track, fill

	-- row 3: hearts and the health number
	S.hearts = {}
	for i = 1, 3 do
		local h = Kit.PixelHeart(plate, C.hussRed, HEART_CELL)
		h.holder.Name = "Heart" .. i
		h.holder.Position = UDim2.fromOffset(U.panelPad + (i - 1) * (HEART_CELL * 7 + 8), 62)
		h.holder.ZIndex = 3
		S.hearts[i] = h
	end
	S.healthText = Kit.Text(plate, {
		name = "HealthNumber",
		text = "",
		size = TY.small,
		align = Enum.TextXAlignment.Right,
		anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -U.panelPad, 0, 58),
		sizeU = UDim2.fromOffset(150, 20),
	})
	S.healthText.ZIndex = 3

	-- Run (white), top left, touch target never under 44 px on screen
	local run = Kit.Button(group, {
		name = "Run",
		text = N.hudWords.run,
		fill = C.white,
		ink = true,
		textSize = TY.button,
		size = UDim2.fromOffset(RUN_W, RUN_H),
		position = UDim2.fromOffset(RUN_POS.X, RUN_POS.Y),
	})
	run.root.Visible = false
	run.onActivated(function()
		for _, fn in ipairs(S.runCallbacks) do
			task.spawn(fn)
		end
	end)
	S.run = run

	S.scaleConn = Kit.onScale(function()
		if S then
			local h = math.max(RUN_H, Kit.minDesign(U.touchMin))
			run.root.Size = UDim2.fromOffset(math.max(RUN_W, Kit.minDesign(U.touchMin)), h)
		end
	end)
	run.root.Size = UDim2.fromOffset(math.max(RUN_W, Kit.minDesign(U.touchMin)), math.max(RUN_H, Kit.minDesign(U.touchMin)))
	return group
end

function FightOverlay.destroy()
	if S then
		if S.scaleConn then
			S.scaleConn.Disconnect()
		end
		S.group:Destroy()
		S = nil
	end
end

function FightOverlay.instance()
	return S and S.group
end

function FightOverlay.parts()
	return S
end

function FightOverlay.setHealth(h: number, max: number)
	if not S then
		return
	end
	S.health, S.max = h, max
	local frac = max > 0 and math.clamp(h / max, 0, 1) or 0
	Kit.tween(S.fill, { Size = UDim2.fromScale(frac, 1) }, 0.1)
	S.healthText.Text = Kit.commas(math.max(0, h)) .. " / " .. Kit.commas(max)
end

function FightOverlay.setHearts(n: number)
	if not S then
		return
	end
	n = math.clamp(math.floor(n), 0, 3)
	S.heartN = n
	for i, h in ipairs(S.hearts) do
		h.setColor(i <= n and C.hussRed or C.pipEmpty)
	end
end

function FightOverlay.setBand(band: string)
	if not S then
		return
	end
	S.band = band
	S.bandWord.Text = string.upper(N.bands[band] or band)
	S.bandWord.TextColor3 = C.band[band] or C.white
end

function FightOverlay.show(info)
	if not S then
		return
	end
	local tier = tierOf(info)
	local name = info.bossName or (N.creatures and N.creatures[info.creatureId]) or ""
	local word = info.tierWord or (tier and N.tiers[tier]) or ""
	S.name.Text = string.upper(name)
	S.chipText.Text = string.upper(word)
	local tc = (tier and C.tier[tier]) or C.tier[1]
	S.chip.BackgroundColor3 = tc
	S.fill.BackgroundColor3 = tc
	if info.band then
		FightOverlay.setBand(info.band)
	end
	if info.health and info.maxHealth then
		S.fill.Size = UDim2.fromScale(math.clamp(info.health / math.max(info.maxHealth, 1), 0, 1), 1)
		S.health, S.max = info.health, info.maxHealth
		S.healthText.Text = Kit.commas(info.health) .. " / " .. Kit.commas(info.maxHealth)
	end
	FightOverlay.setHearts(info.hearts or 3)
	S.plate.Visible = true
	S.run.root.Visible = true
end

-- Hud places the overlay under the real top bar: Run sits under the Power/cash plates (kit: top left, below the counter row),
-- the plate's top is never above plateTop (design px). Called by Hud.place on every scale or TopbarInset change.
function FightOverlay.place(runX: number, runY: number, plateTop: number?, plateMinLeft: number?, rootW: number?)
	if not S then
		return
	end
	S.run.root.Position = UDim2.fromOffset(runX, runY)
	-- the plate stays centred, but is pushed right when the counter row (plateMinLeft, design px) would reach it
	local dx = 0
	if plateMinLeft and rootW then
		dx = math.max(0, plateMinLeft - (rootW / 2 - PLATE_W / 2))
	end
	S.plate.Position = UDim2.new(0.5, dx, 0, math.max(PLATE_TOP, plateTop or 0))
end

function FightOverlay.hide()
	if not S then
		return
	end
	S.plate.Visible = false
	S.run.root.Visible = false
end

function FightOverlay.onRun(fn)
	if S then
		table.insert(S.runCallbacks, fn)
	end
end

return FightOverlay
