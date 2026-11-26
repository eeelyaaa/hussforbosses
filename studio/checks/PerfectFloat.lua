if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-08 PERFECT float check (gui-designer). Edit mode, studio lock held, after a sync:
--   require(game.ServerStorage.DevSync:Clone()).run("checks/PerfectFloat.lua")
-- Builds the HUD at four viewports, fires landed("perfect") / ("good") / ("untimed"), reads the floating label's rectangle
-- (screen px, relative to the HUD root) at start, mid float and end, and prints PASS/FAIL lines. Removes what it built.
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local Ui = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Ui")
local Hud = require(Ui.Hud)
local Kit = require(Ui.Kit)
local Skin = require(game:GetService("ReplicatedStorage").Shared.Skin)
local U = Skin.Tokens.ui

local passed, failed = 0, 0
local function check(ok, what, detail)
	if ok then passed += 1 else failed += 1 end
	print(("PerfectFloat: %s %s%s"):format(ok and "PASS" or "FAIL", what, detail and (" [" .. detail .. "]") or ""))
end
local function rect(root, o)
	local p = o.AbsolutePosition - root.AbsolutePosition
	return { x0 = p.X, y0 = p.Y, x1 = p.X + o.AbsoluteSize.X, y1 = p.Y + o.AbsoluteSize.Y }
end
local function fmt(r) return ("x %.0f..%.0f y %.0f..%.0f"):format(r.x0, r.x1, r.y0, r.y1) end
local function overlap(a, b) return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1 end
local function floats(P) local n = {} for _, c in ipairs(P.holder:GetChildren()) do if c.Name == "PerfectFloat" then table.insert(n, c) end end return n end
-- the text's real box: TextBounds is in screen px; the label is anchored bottom-centre
local function textRect(root, l)
	local r = rect(root, l)
	local w, h = l.TextBounds.X, l.TextBounds.Y
	local cx = (r.x0 + r.x1) / 2
	return { x0 = cx - w / 2, x1 = cx + w / 2, y0 = r.y1 - h - (r.y1 - r.y0 - h) / 2, y1 = r.y1 - (r.y1 - r.y0 - h) / 2 }
end

local VIEWPORTS = {
	{ name = "phone 874x402", vp = Vector2.new(874, 402), mouse = false },
	{ name = "small phone 640x300", vp = Vector2.new(640, 300), mouse = false },
	{ name = "desktop 1280x720", vp = Vector2.new(1280, 720), mouse = true },
	{ name = "desktop 1920x1080", vp = Vector2.new(1920, 1080), mouse = true },
}

local ok, err = pcall(function()
	for _, v in ipairs(VIEWPORTS) do
		local tag = v.name
		Hud.build(StarterGui, { viewport = v.vp, mouse = v.mouse })
		local root, huss = Hud.root(), Hud.huss
		local P = huss.parts()
		local s = Kit.scale()
		huss.setMode("fight")
		Hud.fight.show({ creatureId = "z1_t1", band = "hard", health = 150, maxHealth = 250, hearts = 2 })

		local button = rect(root, P.face)
		local bandTop = button.y0 - (huss.diameter() * (U.bandOuter - 1) / 2 + 9) * s
		huss.landed("perfect")
		local fl = floats(P)
		check(#fl == 1, tag .. ": landed('perfect') makes one floating label", tostring(#fl))
		local l = fl[1]
		check(l ~= nil and l.Text == Skin.Names.grades.perfect, tag .. ": its word comes from the skin")
		check(P.popLabel.Visible == false, tag .. ": no second PERFECT in the small pop slot")
		local r0 = textRect(root, l)
		check(r0.y1 <= button.y0 + 1, tag .. ": starts above the button", fmt(r0) .. " button " .. fmt(button))
		check(r0.x0 >= 0 and r0.x1 <= v.vp.X, tag .. ": start inside the screen width", fmt(r0))
		check(l.TextSize * s >= 14 or l.TextSize >= 14, tag .. ": text size >= 14 px", tostring(l.TextSize))
		local c0 = l.Position.Y.Offset
		task.wait(U.perfectFloatS * 0.5)
		if l.Parent then
			local rm = textRect(root, l)
			check(l.Position.Y.Offset < c0, tag .. ": rising at mid float", ("%.1f -> %.1f"):format(c0, l.Position.Y.Offset))
			check(rm.y0 >= 0, tag .. ": mid float on screen", fmt(rm))
		else
			check(false, tag .. ": label gone at mid float")
		end
		task.wait(U.perfectFloatS * 0.5 + 0.1)
		check(not l.Parent, tag .. ": label removed after the float")
		-- end position is where the tween was aimed: start - perfectRisePx (read from the destroyed label's last value when still there)
		local top = r0.y0 - U.perfectRisePx * s
		check(top >= 0, tag .. ": top of the float stays on screen (needs room above the button)", ("end top %.0f"):format(top))
		-- the fight plate (kit: x 244..630 design, y 46..128) clear of the float column at the end
		local plateR = { x0 = 244 * s, x1 = 630 * s, y0 = 46 * s, y1 = 128 * s }
		if not v.mouse then
			local endR = { x0 = r0.x0 + U.perfectDriftPx * s, x1 = r0.x1 + U.perfectDriftPx * s, y0 = top, y1 = top + (r0.y1 - r0.y0) }
			check(not overlap(endR, plateR), tag .. ": the float clears the fight plate", fmt(endR) .. " plate " .. fmt(plateR))
		end
		-- two Perfects in a row do not cut each other
		huss.landed("perfect"); task.wait(0.2); huss.landed("perfect")
		check(#floats(P) == 2, tag .. ": a second Perfect inside the first one's float keeps both", tostring(#floats(P)))
		task.wait(U.perfectFloatS + 0.2)
		check(#floats(P) == 0, tag .. ": all floats removed")
		-- good: the small pop in the slot, no float
		huss.landed("good")
		check(#floats(P) == 0 and P.popLabel.Visible and P.popLabel.Text == Skin.Names.grades.good, tag .. ": Good keeps the small GOOD pop")
		task.wait(0.6)
		check(P.popLabel.Visible == false, tag .. ": GOOD gone after 0.5 s")
		-- untimed: no word at all
		huss.landed("untimed")
		check(#floats(P) == 0 and not P.popLabel.Visible, tag .. ": untimed single shows no word")
		task.wait(0.35)
		check(P.starHolder.Visible == false, tag .. ": untimed star gone")
		local normal = P.face.BackgroundColor3
		huss.setSpent(true)
		check(P.face.BackgroundColor3 ~= normal and P.label.TextTransparency > 0, tag .. ": setSpent(true) dims the face and label")
		huss.setSpent(false)
		check(P.face.BackgroundColor3 == normal and P.label.TextTransparency == 0, tag .. ": setSpent(false) restores them")
		Hud.destroy()
	end
end)
if not ok then print("PerfectFloat: FAIL error " .. tostring(err)) failed += 1 pcall(function() Hud.destroy() end) end
print(("PerfectFloat: %d passed, %d failed"):format(passed, failed))
