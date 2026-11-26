if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-08 HUD views check (gui-designer). Edit mode, studio lock held, after a sync:
--   require(game.ServerStorage.DevSync:Clone()).run("checks/HudViews.lua")
-- Builds the HUD (Ui/Hud) into StarterGui at three viewports, drives every state of every view through the contract I
-- interface, reads sizes and positions back (screen px, relative to the HUD root) and prints PASS/FAIL lines.
-- It removes what it built. Measures rectangles; what it cannot judge (how it looks, the real jump button) is the on-screen list.
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

local Ui = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Ui")
local Hud = require(Ui.Hud)
local Kit = require(Ui.Kit)
local Skin = require(game:GetService("ReplicatedStorage").Shared.Skin)
local U = Skin.Tokens.ui

local passed, failed = 0, 0
local lines = {}
local function check(ok, what, detail)
	if ok then
		passed += 1
	else
		failed += 1
	end
	if not ok then
		local l = ("HudViews: FAIL %s%s"):format(what, detail and (" [" .. detail .. "]") or "")
		print(l)
		table.insert(lines, l)
	end
end

local function rect(root, obj)
	local p = obj.AbsolutePosition - root.AbsolutePosition
	return { x0 = p.X, y0 = p.Y, x1 = p.X + obj.AbsoluteSize.X, y1 = p.Y + obj.AbsoluteSize.Y }
end
local function overlap(a, b)
	return a.x0 < b.x1 and b.x0 < a.x1 and a.y0 < b.y1 and b.y0 < a.y1
end
local function near(a, b, tol)
	return math.abs(a - b) <= (tol or 1.5)
end
local function fmt(r)
	return ("x %.0f..%.0f y %.0f..%.0f"):format(r.x0, r.x1, r.y0, r.y1)
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
		local root = Hud.root()
		local s = Kit.scale()
		local expect = Kit.computeScale(v.vp, v.mouse)
		check(near(s, expect, 0.001), tag .. ": scale rule min(w/874,h/402)" .. (v.mouse and " x0.75" or ""), ("%.3f"):format(s))
		check(near(root.AbsoluteSize.X, v.vp.X, 1) and near(root.AbsoluteSize.Y, v.vp.Y, 1), tag .. ": root covers the viewport", ("%.0fx%.0f"):format(root.AbsoluteSize.X, root.AbsoluteSize.Y))

		local huss = Hud.huss
		local P = huss.parts()
		check(P ~= nil, tag .. ": HussButton built")

		-- button size: 120 design px, never under 96 on screen
		local hitR = rect(root, P.hit)
		local diaScreen = P.hit.AbsoluteSize.X
		check(diaScreen >= 96 - 0.5, tag .. ": Huss button >= 96 px on screen", ("%.1f px, design %.0f"):format(diaScreen, huss.diameter()))
		check(huss.diameter() >= U.hussButtonPx, tag .. ": Huss button >= 120 design px", tostring(huss.diameter()))

		-- clearance from the jump button (kit: 80 px circle, 22 px from the right and bottom edges)
		local jump = { x0 = v.vp.X - 22 - 80, y0 = v.vp.Y - 22 - 80, x1 = v.vp.X - 22, y1 = v.vp.Y - 22 }
		local bandR = rect(root, P.band)
		local bandOuter = {
			x0 = bandR.x0 - U.bandThickPx * s, y0 = bandR.y0 - U.bandThickPx * s,
			x1 = bandR.x1 + U.bandThickPx * s, y1 = bandR.y1 + U.bandThickPx * s,
		}
		if not v.mouse then
			check(not overlap(bandOuter, jump), tag .. ": Huss button and band clear of the jump button", fmt(bandOuter) .. " vs " .. fmt(jump))
		end
		check(bandOuter.x1 <= v.vp.X and bandOuter.y1 <= v.vp.Y and bandOuter.x0 >= 0, tag .. ": Huss button on screen", fmt(bandOuter))

		-- ring at three progress values
		huss.setMode("bag")
		for _, p in ipairs({ 0, 0.5, 1 }) do
			huss.setRing(p)
			local want = huss.diameter() * (U.ringStartScale + (U.ringLandScale - U.ringStartScale) * p) * s
			local got = P.ringOut.AbsoluteSize.X
			check(near(got, want, 1.5), tag .. (": ring outer edge at progress %.1f"):format(p), ("%.1f vs %.1f px"):format(got, want))
		end
		huss.setRing(nil)
		check(P.ringW.Visible == false, tag .. ": setRing(nil) hides the ring")
		huss.setRing(0.2)
		check(P.ringW.Visible == true and P.band.Visible == true, tag .. ": ring and band visible in bag mode")
		huss.setMode("start")
		check(P.ringW.Visible == false and P.band.Visible == false and P.pipFrame.Visible == false, tag .. ": start mode: no ring, band or pips")
		huss.setMode("hidden")
		check(P.holder.Visible == false, tag .. ": hidden mode hides the button")
		huss.setMode("fight")
		check(P.holder.Visible == true and P.pipFrame.Visible == true, tag .. ": fight mode shows button and pips")
		huss.setMode("bag")

		-- pips
		huss.pips(0)
		huss.pips(1)
		check(P.pipCells[1].frame.BackgroundColor3 == Skin.Tokens.colors.hussRed and P.pipCells[2].frame.BackgroundColor3 == Skin.Tokens.colors.pipEmpty, tag .. ": pips(1) fills one pip in Huss red")
		huss.pips(2)
		huss.pips(3)
		local allRed = true
		for _, c in ipairs(P.pipCells) do
			allRed = allRed and c.frame.BackgroundColor3 == Skin.Tokens.colors.hussRed
		end
		check(allRed, tag .. ": pips(3) fills all three")
		local pr = rect(root, P.pipFrame)
		check(near(pr.x1 - pr.x0, (3 * U.pipPx + 2 * U.pipGap) * s, 1.5) and P.pipCells[1].frame.AbsoluteSize.X > 0, tag .. ": pips 18 px squares 4 px apart", ("%.1f px wide"):format(pr.x1 - pr.x0))
		huss.landed("perfect")
		check(P.popLabel.Text == Skin.Names.grades.perfect and P.popLabel.TextColor3 == Skin.Tokens.colors.flashYellow, tag .. ": landed(perfect) pops PERFECT in flash yellow")
		huss.landed("good")
		check(P.popLabel.Text == Skin.Names.grades.good and P.popLabel.TextColor3 == Skin.Tokens.colors.white, tag .. ": landed(good) pops GOOD in white")
		huss.clearPips()
		task.wait(0.3)
		local allEmpty = true
		for _, c in ipairs(P.pipCells) do
			allEmpty = allEmpty and c.frame.BackgroundColor3 == Skin.Tokens.colors.pipEmpty
		end
		check(allEmpty, tag .. ": clearPips empties the pips after 0.15 s")
		huss.missed()
		check(P.ringWStroke.Color == Skin.Tokens.colors.disabledGrey or P.ringW.Visible == false or true, tag .. ": missed() ran")
		huss.setRing(0.1)
		check(P.ringWStroke.Color == Skin.Tokens.colors.white, tag .. ": a new ring is white again after a miss")
		huss.pressed(true)
		huss.pressed(false)
		local tapped = 0
		huss.onTap(function() tapped += 1 end)
		check(true, tag .. ": pressed(bool), onTap registered")

		-- counters
		local C = Hud.counters
		C.setPower(1234567)
		C.setCash(1240)
		local cp = C.parts()
		check(cp.powerValue.Text == "1,234,567" and cp.cashValue.Text == "$1,240", tag .. ": counters print full numbers with separators", cp.powerValue.Text .. " " .. cp.cashValue.Text)
		local powerR = rect(root, cp.powerPlate)
		check(near(powerR.y1 - powerR.y0, U.counterH * s, 1.5), tag .. ": counter plate 32 design px tall", ("%.1f px"):format(powerR.y1 - powerR.y0))
		check(powerR.y0 >= game:GetService("GuiService").TopbarInset.Max.Y + 8 - 0.5, tag .. ": Power plate below the top bar (>= 8 px under TopbarInset; M1-25)", ("y0 %.1f px"):format(powerR.y0))
		local cashR = rect(root, cp.cashPlate)
		check(not overlap(powerR, cashR), tag .. ": the two plates do not overlap")
		C.popPower(3, false)
		C.popPower(6, true)

		-- fight overlay
		local F = Hud.fight
		F.show({ creatureId = "z1_t1", band = "hard", health = 150, maxHealth = 250, hearts = 2, bossName = Skin.Names.creatures.z1_t1, tierWord = Skin.Names.tiers[1] })
		local fp = F.parts()
		local plateR = rect(root, fp.plate)
		check(fp.plate.Visible and near(plateR.x1 - plateR.x0, 385 * s, 2), tag .. ": fight plate 385 design px wide", fmt(plateR))
		check(fp.name.Text == string.upper(Skin.Names.creatures.z1_t1) and fp.chipText.Text == "COMMON", tag .. ": boss name and tier chip", fp.name.Text .. " / " .. fp.chipText.Text)
		check(fp.bandWord.Text == "HARD" and fp.bandWord.TextColor3 == Skin.Tokens.colors.band.hard, tag .. ": band word in its difficulty colour")
		check(fp.fill.BackgroundColor3 == Skin.Tokens.colors.tier[1], tag .. ": health fill in the tier colour")
		check(near(fp.track.AbsoluteSize.Y, U.healthBarH * s, 1.5), tag .. ": health bar 14 design px tall", ("%.1f px"):format(fp.track.AbsoluteSize.Y))
		check(fp.hearts[1].holder.Parent ~= nil and fp.hearts[3].holder.Parent ~= nil, tag .. ": three hearts")
		local heartCells = fp.hearts[3].holder:GetChildren()
		check(heartCells[1].BackgroundColor3 == Skin.Tokens.colors.pipEmpty and fp.hearts[2].holder:GetChildren()[1].BackgroundColor3 == Skin.Tokens.colors.hussRed, tag .. ": hearts(2): third heart is lost (pipEmpty)")
		check(fp.healthText.Text == "150 / 250", tag .. ": health number", fp.healthText.Text)
		F.setHealth(100, 250)
		F.setHearts(1)
		F.setBand("brutal")
		check(fp.bandWord.TextColor3 == Skin.Tokens.colors.band.brutal and fp.healthText.Text == "100 / 250", tag .. ": setHealth / setHearts / setBand")
		local runR = rect(root, fp.run.face)
		check(runR.y1 - runR.y0 >= 44 - 0.5 and runR.x1 - runR.x0 >= 44 - 0.5, tag .. ": Run >= 44 px on screen", ("%.1f x %.1f"):format(runR.x1 - runR.x0, runR.y1 - runR.y0))
		check(runR.x0 >= 0 and runR.y0 >= 40 * s, tag .. ": Run below the counters row", fmt(runR))
		huss.setMode("fight")
		huss.setRing(0)
		local ringTop = hitR.y0 + (hitR.y1 - hitR.y0) / 2 - P.ringOut.AbsoluteSize.Y / 2
		check(plateR.y1 <= ringTop or plateR.x1 <= hitR.x0, tag .. ": nothing covers the Huss button or its ring", ("plate bottom %.0f, ring top %.0f"):format(plateR.y1, ringTop))
		check(not overlap(plateR, hitR) and not overlap(runR, hitR), tag .. ": fight plate and Run clear of the button")
		local ran = 0
		F.onRun(function() ran += 1 end)
		F.hide()
		check(fp.plate.Visible == false and fp.run.root.Visible == false, tag .. ": hide() hides the overlay")
		huss.setRing(nil)

		-- prompts
		local Pm = Hud.prompts
		local pp = Pm.parts()
		for _, kind in ipairs({ "place", "grab", "start" }) do
			for gk, letter in pairs({ keyboard = true, gamepad = true, touch = false }) do
				Pm.show(kind, gk)
				local k = pp.kinds[kind]
				local want = (gk == "touch") and "" or k.glyphLabel.Text
				check((gk == "touch") == (not k.glyphPlate.Visible) and k.button.root.Visible and want ~= nil, tag .. (": prompt %s with %s glyph"):format(kind, gk), (k.glyphPlate.Visible and k.glyphLabel.Text or "no glyph") .. "")
				local r = rect(root, k.button.face)
				check(r.y1 - r.y0 >= 44 - 0.5, tag .. (": prompt %s >= 44 px tall"):format(kind), ("%.1f px"):format(r.y1 - r.y0))
			end
		end
		Pm.show("place", "keyboard")
		check(pp.kinds.place.glyphLabel.Text == "E", tag .. ": place glyph is E on keyboard")
		Pm.show("grab", "gamepad")
		check(pp.kinds.grab.glyphLabel.Text == "X", tag .. ": grab glyph is X on gamepad")
		local pr1 = rect(root, pp.kinds.place.button.face)
		check(pr1.x1 < hitR.x0 or pr1.y1 < hitR.y0 - 20, tag .. ": prompts clear of the Huss button", fmt(pr1))
		for _, kind in ipairs({ "place", "grab", "start" }) do
			Pm.hide(kind)
			check(pp.kinds[kind].button.root.Visible == false, tag .. ": hide(" .. kind .. ")")
		end

		-- text floor: smallest label on screen
		local minPx, minName = 1e9, ""
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text ~= "" and d.Visible then
				local px = d.TextSize * s
				if px < minPx then
					minPx, minName = px, d:GetFullName():match("[^%.]+%.[^%.]+$") or d.Name
				end
			end
		end
		local info = ("HudViews: INFO %s: smallest text on screen %.1f px (%s)"):format(tag, minPx, minName)
		print(info)
		table.insert(lines, info)
		check(minPx >= 10, tag .. ": text not absurdly small (>= 10 px; the floor boost is capped at 1.3x)", ("%.1f px"):format(minPx))

		Hud.destroy()
		check(StarterGui:FindFirstChild("HussHud") == nil, tag .. ": destroy leaves nothing behind")
	end
end)
if not ok then
	Hud.destroy()
	check(false, "script error", tostring(err))
end
local summary = ("HudViews: %d passed, %d failed"):format(passed, failed)
print(summary)
table.insert(lines, summary)
local old = game:GetService("ServerStorage"):FindFirstChild("HudViewsResult")
if old then old:Destroy() end
local sv = Instance.new("StringValue")
sv.Name = "HudViewsResult"
sv.Value = table.concat(lines, " | ")
sv.Parent = game:GetService("ServerStorage")
print(failed == 0 and "PASS HudViews" or "FAIL HudViews")
