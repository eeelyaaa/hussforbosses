if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-13 plain screens A check (gui-designer). Edit mode, studio lock held, after a sync:
--   require(game.ServerStorage.DevSync:Clone()).run("checks/ScreensA.lua")
-- Builds the HUD and the screens into StarterGui at five viewports, drives each screen with the contract's payloads through the modules'
-- own handlers (the local fake: Bag.State, Boss.Result, Offline.Summary, Profile.Changed ... as tables, no remotes), reads layout back in screen px.
-- On-screen mode: set workspace attribute ScreensAShow to boss|bag|bag2|away|rebirth|confirm|settings|toasts|shield (and ScreensAVp to phone|small|tablet|desktop);
-- the run builds that one screen and LEAVES it in StarterGui for a look. Set the attribute to "" and run again to remove it.
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local Ui = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Ui")
local Hud = require(Ui.Hud)
local Kit = require(Ui.Kit)
local Counters = require(Ui.Counters)
local BossPanel = require(Ui.BossPanel)
local BagPanel = require(Ui.BagPanel)
local Offline = require(Ui.Offline)
local Rebirth = require(Ui.Rebirth)
local Settings = require(Ui.Settings)
local Toasts = require(Ui.Toasts)
local Skin = require(game:GetService("ReplicatedStorage").Shared.Skin)
local U, C = Skin.Tokens.ui, Skin.Tokens.colors

local VPS = {
	{ name = "phone 874x402", key = "phone", vp = Vector2.new(874, 402), mouse = false },
	{ name = "small phone 640x300", key = "small", vp = Vector2.new(640, 300), mouse = false },
	{ name = "tablet 1024x768", key = "tablet", vp = Vector2.new(1024, 768), mouse = false },
	{ name = "desktop 1280x720", key = "desktop", vp = Vector2.new(1280, 720), mouse = true },
	{ name = "desktop 1920x1080", key = "desktop2", vp = Vector2.new(1920, 1080), mouse = true },
}

local passed, failed = 0, 0
local function check(ok, what, detail)
	if ok then
		passed += 1
	else
		failed += 1
		print(("ScreensA: FAIL %s%s"):format(what, detail and (" [" .. detail .. "]") or ""))
	end
end
local function rect(root, obj)
	local p = obj.AbsolutePosition - root.AbsolutePosition
	return { x0 = p.X, y0 = p.Y, x1 = p.X + obj.AbsoluteSize.X, y1 = p.Y + obj.AbsoluteSize.Y }
end
local function overlap(a, b)
	return a.x0 < b.x1 - 0.5 and b.x0 < a.x1 - 0.5 and a.y0 < b.y1 - 0.5 and b.y0 < a.y1 - 0.5
end
local function fmt(r)
	return ("x %.0f..%.0f y %.0f..%.0f"):format(r.x0, r.x1, r.y0, r.y1)
end
local function inScroll(o, stop)
	local p = o.Parent
	while p and p ~= stop do
		if p:IsA("ScrollingFrame") then
			return true
		end
		p = p.Parent
	end
	return false
end

local smallest = math.huge
-- every label of an open screen: fits its box, text >= 13 px on screen, clear of nothing hidden; buttons >= 44 px tall (touch) on screen
local function audit(tag, root, frame, touch)
	local panel = frame:FindFirstChild("Panel", true)
	check(panel ~= nil, tag .. ": panel exists")
	if not panel then
		return
	end
	local pr, rr = rect(root, panel), rect(root, root)
	check(pr.x0 >= -0.5 and pr.y0 >= -0.5 and pr.x1 <= rr.x1 + 0.5 and pr.y1 <= rr.y1 + 0.5, tag .. ": panel inside the screen", fmt(pr) .. " of " .. fmt(rr))
	for _, o in ipairs(panel:GetDescendants()) do
		if o:IsA("TextLabel") and o.Visible and o.Text ~= "" and not inScroll(o, panel) then
			local px = o.TextSize * Kit.scale()
			smallest = math.min(smallest, px)
			check(px >= 13, tag .. ": text size " .. o.Name, ("%.1f px"):format(px))
			if not o.TextWrapped then
				check(o.TextBounds.X <= o.AbsoluteSize.X + 1.5, tag .. ": label fits " .. o.Name .. " '" .. o.Text .. "'", ("%.0f > %.0f"):format(o.TextBounds.X, o.AbsoluteSize.X))
			else
				check(o.TextBounds.Y <= o.AbsoluteSize.Y + 1.5, tag .. ": wrapped label fits " .. o.Name .. " '" .. string.sub(o.Text, 1, 24) .. "'", ("%.0f > %.0f"):format(o.TextBounds.Y, o.AbsoluteSize.Y))
			end
			local lr = rect(root, o)
			check(lr.x0 >= pr.x0 - 1 and lr.x1 <= pr.x1 + 1 and lr.y0 >= pr.y0 - 1 and lr.y1 <= pr.y1 + 1, tag .. ": label inside panel " .. o.Name, fmt(lr))
		elseif o:IsA("TextLabel") and o.Visible and inScroll(o, panel) then
			smallest = math.min(smallest, o.TextSize * Kit.scale())
		elseif o:IsA("TextButton") and o.Name == "Face" and o.Visible then
			local r = rect(root, o)
			check(r.y1 - r.y0 >= 43.5 or not touch, tag .. ": touch target " .. o.Parent.Name, ("%.1f px tall"):format(r.y1 - r.y0))
			check(r.x1 - r.x0 >= 43.5 or not touch, tag .. ": touch target wide " .. o.Parent.Name, ("%.1f px wide"):format(r.x1 - r.x0))
			check(r.x0 >= pr.x0 - 1 and r.x1 <= pr.x1 + 1 and r.y0 >= pr.y0 - 1 and r.y1 <= pr.y1 + 1, tag .. ": button inside panel " .. o.Parent.Name, fmt(r))
		end
	end
end

local function disabled(frame, name)
	local b = frame:FindFirstChild(name, true)
	local face = b and b:FindFirstChild("Face")
	return face ~= nil and face.BackgroundColor3 == C.disabledGrey
end
local function textOf(frame, name)
	local o = frame:FindFirstChild(name, true)
	return o and o.Text or ""
end
local function allText(frame)
	local t = {}
	for _, o in ipairs(frame:GetDescendants()) do
		if o:IsA("TextLabel") then
			table.insert(t, o.Text)
		end
	end
	return table.concat(t, "\n")
end

local BASE_FAKE = function(uid)
	return {
		plotId = 1, ownerUserId = 4242, spotsCap = 10, crateCount = 1,
		spots = {
			[1] = { uid = "4242-1", creatureId = "z1_t1", level = 3, income = 1.5, stamp = 0, padCash = 0, capSeconds = 7200, bought = false },
			[2] = { uid = "4242-2", creatureId = "z1_t4", level = 1, income = 12, stamp = 0, padCash = 0, capSeconds = 7200, bought = "pack" },
			[3] = { uid = "4242-3", creatureId = "z2_t5", level = 2, income = 40, stamp = 0, padCash = 0, capSeconds = 7200, bought = "spin" },
		},
	}
end

local function setup(v)
	Hud.build(StarterGui, { viewport = v.vp, mouse = v.mouse })
	BossPanel.build(); BagPanel.build(); Offline.build(); Rebirth.build(); Settings.build(); Toasts.build(Hud.root())
	BossPanel._testUserId, Rebirth._testUserId = 4242, 4242
	return Hud.root()
end

local function drive(show, root)
	if show == "boss" then
		Counters.setCash(1240)
		BossPanel.open({ uid = "4242-1", creatureId = "z1_t1", level = 3, income = 1.5, spot = 1 })
	elseif show == "bag" or show == "bag2" then
		Counters.setCash(1240)
		BagPanel.onState({ tier = 1, strengthLevel = 2, speedLevel = 1, nextStrengthCost = 400, nextSpeedCost = 100, autoOn = true, perfectOn = false, autoOwned = show == "bag2", perfectOwned = false })
		BagPanel.open()
	elseif show == "away" then
		Offline.show({ seconds = 4320, total = 21600, perBoss = {} })
	elseif show == "rebirth" or show == "confirm" then
		Counters.setPower(10.4e6); Rebirth.onProfile({ power = 10.4e6, rebirths = 0, spinTickets = 2, breakerCharges = 2, boughtCash = 5000, cash = 1240 })
		Rebirth.onBaseState(BASE_FAKE())
		Rebirth.onCrate({ items = {} })
		Rebirth.open()
		if show == "confirm" then Rebirth.openConfirm() end
	elseif show == "settings" then
		Settings.onProfile({ settings = { music = 0.8, effects = 1 } })
		Settings.open()
	elseif show == "toasts" then
		Toasts.notice("spotsFull"); Toasts.reason("cash"); Toasts.show("Rebirth 1! Your new run starts now.", "good")
	elseif show == "shield" then
		Hud.setShield("up", workspace:GetServerTimeNow() + 42)
	end
end

local show = workspace:GetAttribute("ScreensAShow")
if type(show) == "string" and show ~= "" then
	local vpKey = workspace:GetAttribute("ScreensAVp") or "phone"
	local v = VPS[1]
	for _, c in ipairs(VPS) do if c.key == vpKey then v = c end end
	local root = setup(v)
	drive(show, root)
	print(("ScreensA: left %s on screen at %s (set ScreensAShow to '' and run again to remove)"):format(show, v.name))
else
	local ok, err = pcall(function()
		-- numbers (B16)
		local cases = { [0] = "0", [999] = "999", [1240] = "1,240", [9999] = "9,999", [10000] = "10K", [48200] = "48.2K", [999999] = "999.9K", [1000000] = "1M", [10400000] = "10.4M", [9999999] = "9.9M", [1.3e9] = "1.3B", [4.3e9] = "4.3B", [650e6] = "650M", [1e12] = "1T" }
		for n, want in pairs(cases) do
			check(Counters.short(n) == want, "short(" .. n .. ")", Counters.short(n) .. " want " .. want)
		end
		-- follow-up: tiles built while the viewport is unsettled (tiny) must not stay tall (the two tall white panels), and a boolean spot must not error
		do
			local root = setup({ vp = Vector2.new(60, 30), mouse = true })
			Hud.setViewport(Vector2.new(1920, 1080), true)
			task.wait()
			for _, tl in ipairs(root:FindFirstChild("Tiles"):GetChildren()) do
				if tl:IsA("Frame") then
					local r = rect(root, tl)
					check(r.y1 - r.y0 <= 64 * Kit.scale() + 1 and r.x1 - r.x0 <= 90 * Kit.scale() + 1, "tile " .. tl.Name .. " stays small after a late scale change", fmt(r))
				end
			end
			local okb = pcall(function()
				Rebirth.onBaseState({ plotId = 1, ownerUserId = 4242, spotsCap = 10, crateCount = 0, spots = { [1] = false, [2] = BASE_FAKE().spots[2], [3] = { uid = "9-1", creatureId = "z1_t1", level = 1, income = 1, stamp = 0, padCash = 0, capSeconds = 1, bought = "spin" } } })
				BossPanel.onBaseState({ plotId = 1, ownerUserId = 4242, spots = { [1] = false } })
			end)
			check(okb, "boolean (empty) spots in Base.State do not error")
			Counters.setPower(10.4e6); Rebirth.onProfile({ power = 10.4e6, rebirths = 0, spinTickets = 0, breakerCharges = 0, boughtCash = 0 })
			check(Rebirth.numbers().bought == "1", "N6: only the player's own bought boss counts (uid 4242-2, not 9-1)", Rebirth.numbers().bought)
			-- a resent Offline.Summary leaves an open panel alone
			Offline.show({ seconds = 4320, total = 21600, perBoss = {} })
			local f0 = Hud.layer():FindFirstChild("Modal_Offline")
			Offline.show({ seconds = 7200, total = 99999, perBoss = {} })
			task.wait()
			check(Hud.layer():FindFirstChild("Modal_Offline") == f0 and (Hud.layer():FindFirstChild("Modal_Offline"):FindFirstChild("Collect", true) ~= nil), "a resent summary does not rebuild the open panel")
			Hud.destroy()
		end
		-- toasts under a showing steal alert (M2-17's StealAlert): never overlapping it
		for _, v in ipairs({ VPS[1], VPS[2], VPS[4] }) do
			local root = setup(v)
			local SA = require(Ui.StealAlert)
			SA.build(root)
			Toasts.show("a"); Toasts.show("b")
			SA.showOwner({ uid = "4242-1", creatureId = "z1_t1", thiefUserId = 99, bought = true })
			task.wait(0.2)
			Toasts.place()
			local ai = SA.instance()
			check(SA.isOn() and ai ~= nil and ai.AbsoluteSize.Y > 0, v.name .. ": steal alert is showing for the toast check")
			if ai then
				for _, c2 in ipairs(Toasts.instance():GetChildren()) do
					if c2:IsA("Frame") then
						check(not overlap(rect(root, c2), rect(root, ai)), v.name .. ": toast clear of the steal alert", fmt(rect(root, c2)) .. " vs " .. fmt(rect(root, ai)))
					end
				end
			end
			SA.destroy()
			Hud.destroy()
		end
		for _, v in ipairs(VPS) do
			local tag = v.name
			local root = setup(v)
			local touch = not v.mouse
			-- boss panel
			Counters.setCash(1240)
			BossPanel.open({ uid = "4242-1", creatureId = "z1_t1", level = 3, income = 1.5, spot = 1 })
			local f = Hud.layer():FindFirstChild("Modal_Boss")
			check(f ~= nil, tag .. ": boss panel opens")
			if f then
				audit(tag .. " boss", root, f, touch)
				check(textOf(f, "Title") == "CHOMP FROG", tag .. ": boss title", textOf(f, "Title"))
				local t = allText(f)
				check(t:find("%$1%.50/s") and t:find("%$1%.75/s"), tag .. ": earns now $1.50/s and after $1.75/s", t:gsub("\n", "|"))
				check(t:find("UPGRADE  %$51"), tag .. ": upgrade price from the brief's curve ($51)")
				check(not disabled(f, "Upgrade"), tag .. ": upgrade enabled with cash 1240")
				Counters.setCash(10); BossPanel.onProfile({ cash = 10 }); task.wait()
				check(disabled(Hud.layer():FindFirstChild("Modal_Boss"), "Upgrade"), tag .. ": upgrade disabled with cash 10")
				BossPanel.onProfile({ cash = 5000 })
				BossPanel.onResult({ uid = "4242-1", ok = true, level = 4, nextCost = 66 }); task.wait()
				local t2 = allText(Hud.layer():FindFirstChild("Modal_Boss"))
				check(t2:find("LEVEL 4") and t2:find("UPGRADE  %$66"), tag .. ": Boss.Result level 4 and next cost 66 shown")
				BossPanel.onBaseState({ plotId = 1, ownerUserId = 4242, spots = {} }); task.wait()
				check(not BossPanel.isOpen(), tag .. ": panel closes when its boss leaves the spot")
			end
			-- bag panel
			Counters.setCash(1240)
			BagPanel.onState({ tier = 1, strengthLevel = 2, speedLevel = 1, nextStrengthCost = 400, nextSpeedCost = 100, autoOn = false, perfectOn = false, autoOwned = false, perfectOwned = false })
			BagPanel.open()
			f = Hud.layer():FindFirstChild("Modal_Bag")
			if f then
				audit(tag .. " bag", root, f, touch)
				local rows = 0
				for _, o in ipairs(f:GetDescendants()) do if o.Name == "Row" then rows += 1 end end
				check(rows == 3, tag .. ": bag rows without Auto Punch = 3 (no Perfect row)", tostring(rows))
				local t = allText(f)
				check(t:find("LEVEL 2") and t:find("x1.35") and t:find("x1.82") and t:find("%$400") and t:find("1.05 s") and t:find("0.98 s") and t:find("%$100"), tag .. ": strength and speed texts from the config", t:gsub("\n", "|"))
				check(not disabled(f, "Buy"), tag .. ": strength buy enabled")
				BagPanel.onState({ tier = 1, strengthLevel = 2, speedLevel = 1, nextStrengthCost = 400, nextSpeedCost = 100, autoOn = true, perfectOn = false, autoOwned = true, perfectOwned = false }); task.wait()
				f = Hud.layer():FindFirstChild("Modal_Bag")
				rows = 0
				for _, o in ipairs(f:GetDescendants()) do if o.Name == "Row" then rows += 1 end end
				check(rows == 4, tag .. ": Perfect Auto Punch row appears for Auto Punch owners", tostring(rows))
				audit(tag .. " bag+perfect", root, f, touch)
				BagPanel.onState({ tier = 1, strengthLevel = 30, speedLevel = 10, autoOn = true, perfectOn = true, autoOwned = true, perfectOwned = true }); task.wait()
				f = Hud.layer():FindFirstChild("Modal_Bag")
				check(allText(f):find("MAX LEVEL") ~= nil, tag .. ": caps show MAX LEVEL")
				audit(tag .. " bag capped", root, f, touch)
				BagPanel.close()
			end
			-- offline
			Offline.show({ seconds = 4320, total = 21600, perBoss = {} })
			f = Hud.layer():FindFirstChild("Modal_Offline")
			if f then
				audit(tag .. " away", root, f, touch)
				local t = allText(f)
				check(t:find("Away for 1 h 12 min%.") and t:find("%$21,600") and t:find("COLLECT"), tag .. ": away text, amount and Collect", t:gsub("\n", "|"))
				check(f:FindFirstChild("Close", true) == nil or not f:FindFirstChild("Close", true).Visible, tag .. ": no X on the away panel")
				Offline.onResult({ ok = true, amount = 21600 }); task.wait()
				check(not Offline.isOpen(), tag .. ": Offline.Result closes it")
			end
			-- rebirth
			Counters.setPower(312); Rebirth.onProfile({ power = 312, rebirths = 0, spinTickets = 2, breakerCharges = 2, boughtCash = 5000 })
			Rebirth.onBaseState(BASE_FAKE()); Rebirth.onCrate({ items = {} })
			Rebirth.open()
			f = Hud.layer():FindFirstChild("Modal_Rebirth")
			if f then
				check(disabled(f, "Rebirth"), tag .. ": rebirth button disabled under the requirement")
				Counters.setPower(10.4e6); Rebirth.onProfile({ power = 10.4e6 }); task.wait()
				f = Hud.layer():FindFirstChild("Modal_Rebirth")
				audit(tag .. " rebirth", root, f, touch)
				local t = allText(f)
				check(not disabled(f, "Rebirth"), tag .. ": rebirth button enabled at 10.4M")
				check(t:find("POWER 10.4M / 10M") and t:find("Your 2 spin tickets") and t:find("Your 2 bought bosses") and t:find("Your 2 Shield Breaker charges") and t:find("%$5,000 bought cash") and t:find("Bag Power x2") and t:find("Boss income x1.5") and t:find("%+1 boss spot %(11 spots%)"), tag .. ": the player's own numbers on the rebirth screen", t:gsub("\n", "|"))
				check(textOf(f, "Title") == "REBIRTH 1", tag .. ": title REBIRTH 1")
				Rebirth.openConfirm()
				local cf = Hud.layer():FindFirstChild("Modal_RebirthConfirm")
				check(cf ~= nil and Rebirth.isOpen(), tag .. ": the confirm stacks over the rebirth screen")
				if cf then
					audit(tag .. " confirm", root, cf, touch)
					local ct = allText(cf)
					check(ct:find("REBIRTH RESETS: your Power") and ct:find("your 2 spin tickets") and ct:find("your 2 bought bosses at their levels") and ct:find("your 2 Shield Breaker charges and %$5,000 bought cash") and ct:find("bag Power x2, boss income x1.5, %+1 boss spot %(11 spots%), and a rebirth star") and ct:find("REBIRTH NOW%?") and ct:find("CANCEL"), tag .. ": confirm wording with the numbers", ct:gsub("\n", "|"))
					check(cf:FindFirstChild("Confirm", true) ~= nil, tag .. ": second press button exists")
				end
				Rebirth.close()
				check(not Rebirth.isOpen(), tag .. ": rebirth closes")
			end
			-- settings
			Settings.onProfile({ settings = { music = 0.8, effects = 1 } })
			Settings.open()
			f = Hud.layer():FindFirstChild("Modal_Settings")
			if f then
				audit(tag .. " settings", root, f, touch)
				local t = allText(f)
				check(t:find("MUSIC") and t:find("EFFECTS") and t:find("80%%") and t:find("100%%"), tag .. ": settings rows and percentages", t:gsub("\n", "|"))
				Settings.close()
			end
			-- toasts, shield plate, tiles
			Toasts.notice("spotsFull"); Toasts.reason("cash"); Toasts.show("a", "good"); Toasts.show("b", "warn")
			local th = Toasts.instance()
			local n = 0
			for _, c in ipairs(th:GetChildren()) do if c:IsA("Frame") then n += 1 end end
			check(n == 3, tag .. ": at most 3 toasts", tostring(n))
			task.wait(0.1)
			local huss = Hud.huss.instance()
			local tr = rect(root, th)
			-- the visible toasts only
			for _, c in ipairs(th:GetChildren()) do
				if c:IsA("Frame") then
					local r = rect(root, c)
					check(r.x0 >= 0 and r.x1 <= rect(root, root).x1, tag .. ": toast on screen", fmt(r))
					if huss then
						check(not overlap(r, rect(root, huss)), tag .. ": toast clear of the Huss button", fmt(r) .. " vs " .. fmt(rect(root, huss)))
						local ring = Hud.huss.diameter and Hud.huss.diameter() or 120
						local hc = huss.AbsolutePosition + huss.AbsoluteSize / 2 - root.AbsolutePosition
						local rr = { x0 = hc.X - ring * Kit.scale() * 0.8, x1 = hc.X + ring * Kit.scale() * 0.8, y0 = hc.Y - ring * Kit.scale() * 0.8, y1 = hc.Y + ring * Kit.scale() * 0.8 }
						check(not overlap(r, rr), tag .. ": toast clear of the Huss ring (1.6x)", fmt(r) .. " vs " .. fmt(rr))
					end
					check(not overlap(r, rect(root, Counters.instance())), tag .. ": toast clear of the counter plates", fmt(r))
					local sp0 = root:FindFirstChild("ShieldPlate")
					if sp0 then check(not overlap(r, rect(root, sp0)), tag .. ": toast clear of the shield plate", fmt(r)) end
					local pr = Hud.prompts.instance()
					if pr then
						-- prompts only draw when shown; the holder is a fixed zone
						check(not overlap(r, rect(root, pr)), tag .. ": toast clear of the prompts zone", fmt(r) .. " vs " .. fmt(rect(root, pr)))
					end
				end
			end
			-- tiles row
			BagPanel.build() -- the bag tile
			local row = root:FindFirstChild("Tiles")
			local counters = Counters.instance()
			local rr = rect(root, row)
			check(not overlap(rr, rect(root, counters)), tag .. ": tile row clear of the counter plates", fmt(rr))
			for _, tl in ipairs(row:GetChildren()) do
				if tl:IsA("Frame") and tl.Visible then
					local b = tl:FindFirstChild("Face", true)
					local r = rect(root, b)
					check(r.y1 - r.y0 >= 43.5 or not touch, tag .. ": tile touch target " .. tl.Name, ("%.1f"):format(r.y1 - r.y0))
					if huss then
						check(not overlap(r, rect(root, huss)), tag .. ": tile clear of the Huss button " .. tl.Name)
					end
					check(r.y1 <= rect(root, root).y1 * 0.72, tag .. ": tile above the thumbstick zone " .. tl.Name, fmt(r))
				end
			end
			for _, c2 in ipairs(th:GetChildren()) do
				if c2:IsA("Frame") then
					check(not overlap(rect(root, c2), rr), tag .. ": toast clear of the tile row", fmt(rect(root, c2)) .. " vs " .. fmt(rr))
				end
			end
			local sp = root:FindFirstChild("ShieldPlate")
			local sr = rect(root, sp)
			check(not overlap(sr, rect(root, counters)), tag .. ": shield plate clear of counters")
			check(sr.x1 <= rect(root, root).x1 + 0.5, tag .. ": shield plate on screen", fmt(sr))
			Hud.setShield("ready", nil)
			check(textOf(sp, "Value") == "0:00" and sp.BackgroundColor3 == C.disabledGrey, tag .. ": B12 ready = grey 0:00")
			Hud.setShield("up", workspace:GetServerTimeNow() + 42)
			check(sp.BackgroundColor3 == C.shieldCyan and textOf(sp, "Value"):match("^0:4[12]$") ~= nil, tag .. ": shield up = cyan countdown", textOf(sp, "Value"))
			Hud.destroy()
		end
	end)
	if not ok then
		failed += 1
		print("ScreensA: ERROR " .. tostring(err))
	end
	pcall(function() Hud.destroy() end)
	for _, g in ipairs(StarterGui:GetChildren()) do if g.Name == "HussHud" then g:Destroy() end end
	print(("ScreensA: %d passed, %d failed; smallest text on screen %.1f px"):format(passed, failed, smallest))
	print(failed == 0 and "ScreensA: PASS" or "ScreensA: FAIL")
end
