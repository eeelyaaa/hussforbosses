if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-17 plain screens B check (gui-designer). Edit mode, studio lock held, after a sync:
--   require(game.ServerStorage.DevSync:Clone()).run("checks/ScreensB.lua")
-- Builds the HUD and the wave B screens (steal alerts, shield-broken alert, thief strips, lock board, steal and break-shield prompts, the sell / swap confirm)
-- into StarterGui at five viewports, drives each with the contract's payloads through the modules' own handlers (the local fake: no remote, no hook),
-- reads layout back in screen px. On-screen mode: set workspace attribute ScreensBShow to
--   owner | ownerBought | broken | thief | thiefBought | allAlerts | lockboard | lockboard2 | steal | stealQH | locked | break | breakGrey | breakCharge | sell | swapBought
-- (and ScreensBVp to phone | small | tablet | desktop | desktop2); the run builds that one screen, LEAVES it in StarterGui for a look, and clears both attributes
-- (nothing is left armed). Run once more with neither set to remove it.
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local Ui = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Ui")
local Hud = require(Ui.Hud)
local Kit = require(Ui.Kit)
local StealAlert = require(Ui.StealAlert)
local LockBoard = require(Ui.LockBoard)
local Confirm = require(Ui.Confirm)
local Prompts = require(Ui.Prompts)
local Toasts = require(Ui.Toasts)
local Counters = require(Ui.Counters)
local Skin = require(game:GetService("ReplicatedStorage").Shared.Skin)
local U, C, N = Skin.Tokens.ui, Skin.Tokens.colors, Skin.Names

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
		print(("ScreensB: FAIL %s%s"):format(what, detail and (" [" .. detail .. "]") or ""))
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
local function shown(o, stop)
	local p = o
	while p and p ~= stop do
		if p:IsA("GuiObject") and not p.Visible then
			return false
		end
		p = p.Parent
	end
	return true
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
-- every shown label under `container`: text >= 13 px on screen, fits its box, inside the screen; every shown button >= 43.5 px (touch)
local function audit(tag, root, container, touch)
	local rr = rect(root, root)
	for _, o in ipairs(container:GetDescendants()) do
		if o:IsA("TextLabel") and o.Text ~= "" and shown(o, root) then
			local px = o.TextSize * Kit.scale()
			smallest = math.min(smallest, px)
			check(px >= 13, tag .. ": text size " .. o.Name, ("%.1f px"):format(px))
			if not inScroll(o, root) then
				if o.TextWrapped then
					check(o.TextBounds.Y <= o.AbsoluteSize.Y + 1.5, tag .. ": wrapped label fits " .. o.Name .. " '" .. string.sub(o.Text, 1, 28):gsub("\n", "|") .. "'", ("%.0f > %.0f"):format(o.TextBounds.Y, o.AbsoluteSize.Y))
				else
					check(o.TextBounds.X <= o.AbsoluteSize.X + 1.5 and o.TextBounds.Y <= o.AbsoluteSize.Y + 1.5, tag .. ": label fits " .. o.Name .. " '" .. string.sub(o.Text, 1, 28):gsub("\n", "|") .. "'", ("%.0f x %.0f in %.0f x %.0f"):format(o.TextBounds.X, o.TextBounds.Y, o.AbsoluteSize.X, o.AbsoluteSize.Y))
				end
				local lr = rect(root, o)
				check(lr.x0 >= rr.x0 - 1 and lr.x1 <= rr.x1 + 1 and lr.y0 >= rr.y0 - 1 and lr.y1 <= rr.y1 + 1, tag .. ": label on screen " .. o.Name, fmt(lr))
			end
		elseif o:IsA("TextButton") and o.Name == "Face" and shown(o, root) then
			local r = rect(root, o)
			check(r.y1 - r.y0 >= 43.5 or not touch, tag .. ": touch target " .. o.Parent.Name, ("%.1f px tall"):format(r.y1 - r.y0))
			check(r.x1 - r.x0 >= 43.5 or not touch, tag .. ": touch target wide " .. o.Parent.Name, ("%.1f px wide"):format(r.x1 - r.x0))
			check(r.x0 >= rr.x0 - 1 and r.x1 <= rr.x1 + 1 and r.y0 >= rr.y0 - 1 and r.y1 <= rr.y1 + 1, tag .. ": button on screen " .. o.Parent.Name, fmt(r))
		end
	end
end

local function textOf(frame, name)
	local o = frame and frame:FindFirstChild(name, true)
	return o and o.Text or ""
end
local function disabled(frame, name)
	local b = frame and frame:FindFirstChild(name, true)
	local face = b and b:FindFirstChild("Face")
	return face ~= nil and face.BackgroundColor3 == C.disabledGrey
end
local function faceColor(frame, name)
	local b = frame and frame:FindFirstChild(name, true)
	local face = b and b:FindFirstChild("Face")
	return face and face.BackgroundColor3
end

local function setup(v)
	Hud.build(StarterGui, { viewport = v.vp, mouse = v.mouse })
	local root = Hud.root()
	-- the tile row M2-13's modules fill (REBIRTH, SETTINGS, BAG), so the alert slot is tested against the real thing
	Hud.tile("rebirth", N.ui.tiles.rebirth, 2, function() end)
	Hud.tile("settings", N.ui.tiles.settings, 3, function() end)
	Hud.tile("bag", N.ui.tiles.bag, 4, function() end)
	Toasts.build(root)
	StealAlert.build(root)
	LockBoard.destroy()
	Confirm.close()
	task.wait()
	return root
end

-- the HUD pieces an alert, the lock board or a prompt must stay clear of (screen rects)
local function hudRects(root)
	local out = {}
	local function add(name, o)
		if o and o.Visible then
			out[name] = rect(root, o)
		end
	end
	add("counters", Counters.instance())
	add("tiles", root:FindFirstChild("Tiles"))
	add("shieldPlate", root:FindFirstChild("ShieldPlate"))
	add("huss", Hud.huss.instance())
	return out
end
local function clearOf(tag, root, obj, names)
	local r = rect(root, obj)
	for name, hr in pairs(hudRects(root)) do
		if not names or table.find(names, name) then
			check(not overlap(r, hr), tag .. ": clear of " .. name, fmt(r) .. " vs " .. fmt(hr))
		end
	end
end

local function drive(show, root)
	if show == "owner" or show == "ownerBought" then
		StealAlert.showOwner({ uid = "4242-1", creatureId = "z1_t1", thiefUserId = 777, bought = show == "ownerBought" })
	elseif show == "broken" then
		StealAlert.showBroken({ plotId = 1, byUserId = nil })
	elseif show == "thief" or show == "thiefBought" then
		StealAlert.showThief({ creatureId = "z1_t1", level = 3, bought = show == "thiefBought" })
	elseif show == "allAlerts" then
		StealAlert.showOwner({ uid = "4242-1", creatureId = "z4_t5", thiefUserId = 777, bought = true })
		StealAlert.showBroken({ plotId = 1, byUserId = nil })
		StealAlert.showThief({ creatureId = "z1_t1", level = 3, bought = false })
	elseif show == "lockboard" then
		LockBoard.setShield("cooldown"); LockBoard.setPasses({}); LockBoard.show()
	elseif show == "lockboard2" then
		LockBoard.setShield("up"); LockBoard.setPasses({}); LockBoard.show()
	elseif show == "steal" or show == "stealQH" then
		Prompts.showSteal({ holdS = if show == "stealQH" then 1 else 2, quickS = 1, quickHandsOwned = show == "stealQH", glyphKind = "touch" })
	elseif show == "locked" then
		Prompts.showSteal({ locked = true, glyphKind = "touch" })
	elseif show == "break" or show == "breakGrey" or show == "breakCharge" then
		local now = workspace:GetServerTimeNow()
		Prompts.setCharges(if show == "breakCharge" then 1 else 0)
		if show == "breakGrey" then
			Prompts.setShieldInfo(2, { plotId = 2, state = "up", endsAt = now + 37, breakable = false, reason = "recent", brokenUntil = now + 200 })
		else
			Prompts.setShieldInfo(2, { plotId = 2, state = "up", endsAt = now + 37, breakable = true })
		end
		Prompts.showBreak(2, "Player2", "touch")
	elseif show == "sell" then
		Confirm.sell({ creatureId = "z1_t1", level = 3, amount = 30, bought = false })
	elseif show == "swapBought" then
		Confirm.swap({ creatureId = "z1_t1", level = 3, amount = 30, bought = "spin", spotIndex = 1 })
	end
end

local show = workspace:GetAttribute("ScreensBShow")
local vpKey = workspace:GetAttribute("ScreensBVp")
workspace:SetAttribute("ScreensBShow", nil) -- consumed: never left armed
workspace:SetAttribute("ScreensBVp", nil)
if type(show) == "string" and show ~= "" then
	local v = VPS[1]
	for _, c in ipairs(VPS) do if c.key == (vpKey or "phone") then v = c end end
	local root = setup(v)
	drive(show, root)
	print(("ScreensB: left %s on screen at %s (run again with neither attribute set to remove it)"):format(show, v.name))
else
	local ok, err = pcall(function()
		for _, v in ipairs(VPS) do
			local tag = v.name
			local touch = not v.mouse
			local root = setup(v)

			-- 1. owner alert, without and with BOUGHT
			local b = StealAlert.showOwner({ uid = "4242-1", creatureId = "z1_t1", thiefUserId = 777, bought = false })
			task.wait()
			local holder = StealAlert.instance()
			check(b ~= nil and b.row.Parent == holder, tag .. ": steal alert (owner) shows")
			check(b and b.text.Text == "YOUR CHOMP FROG IS BEING STOLEN!", tag .. ": owner text", b and b.text.Text)
			check(b and b.chip == nil, tag .. ": no BOUGHT tag on a won boss")
			check(StealAlert.isOn(), tag .. ": isOn with an owner alert")
			audit(tag .. " owner", root, holder, touch)
			clearOf(tag .. " owner alert", root, b.row)
			local rr = rect(root, root)
			local rowR = rect(root, b.row)
			check(rowR.x0 >= rr.x0 and rowR.x1 <= rr.x1, tag .. ": owner banner within the screen width", fmt(rowR))
			check(math.abs((rowR.x0 + rowR.x1) / 2 - (rr.x0 + rr.x1) / 2) < 2 or rowR.x0 > 0, tag .. ": banner centred, or pushed right of the tile row")
			StealAlert.hideOwner("4242-1")
			check(not StealAlert.isOn(), tag .. ": alert off after hideOwner")
			local b2 = StealAlert.showOwner({ uid = "4242-1", creatureId = "z1_t4", thiefUserId = 777, bought = true })
			task.wait()
			check(b2.chip ~= nil and b2.chip:FindFirstChild("Text").Text == N.ui.bought, tag .. ": BOUGHT tag on a bought boss")
			check(b2.text.Text == "YOUR HEADBUTT RAM IS BEING STOLEN!", tag .. ": bought owner text", b2.text.Text)
			audit(tag .. " owner bought", root, holder, touch)
			clearOf(tag .. " owner bought alert", root, b2.row)
			local tr, cr = rect(root, b2.text), rect(root, b2.chip)
			check(not overlap(tr, cr), tag .. ": name text clear of the BOUGHT tag", fmt(tr) .. " vs " .. fmt(cr))
			check(not overlap(tr, rect(root, b2.arrow.plate)), tag .. ": name text clear of the arrow")
			-- every creature name, with the tag, fits in two lines
			for _, id in ipairs(require(game:GetService("ReplicatedStorage").Shared.Ids).CREATURES) do
				StealAlert.showOwner({ uid = "4242-1", creatureId = id, thiefUserId = 777, bought = true })
			end
			task.wait()
			local worst = StealAlert.instance():FindFirstChild("StealOwner")
			check(worst and worst.Text.TextBounds.Y <= worst.Text.AbsoluteSize.Y + 1.5, tag .. ": every creature name fits two lines (last: " .. tostring(worst and worst.Text.Text) .. ")")
			StealAlert.hideOwner("4242-1")
			-- arrows turn
			local ar = b2.arrow
			StealAlert.setBearing(ar, 0)
			check(math.abs(ar.rot.Rotation - -90) < 0.01, tag .. ": arrow ahead points up")
			StealAlert.setBearing(ar, 90)
			check(math.abs(ar.rot.Rotation) < 0.01, tag .. ": arrow to the right points right")
			StealAlert.setBearing(ar, 180)
			check(math.abs(ar.rot.Rotation - 90) < 0.01, tag .. ": arrow behind points down")

			-- 2. shield broken
			local br = StealAlert.showBroken({ plotId = 1, byUserId = nil })
			task.wait()
			check(br and br.text.Text == "SOMEONE BROKE YOUR SHIELD!", tag .. ": broken text", br and br.text.Text)
			check(StealAlert.isOn(), tag .. ": isOn with a shield-broken alert")
			br.text.Text = "WWWWWWWWWWWWWWWWWWWW BROKE YOUR SHIELD!"
			task.wait()
			audit(tag .. " broken", root, StealAlert.instance(), touch)
			clearOf(tag .. " broken alert", root, br.row)
			StealAlert.hideBroken()

			-- 3. the thief's strips
			StealAlert.showThief({ creatureId = "z1_t1", level = 3, bought = false })
			task.wait()
			local g, info = holder:FindFirstChild("GetItHome"), holder:FindFirstChild("StolenInfo")
			check(g and g.Text.Text == "GET IT HOME!", tag .. ": thief strip text", g and g.Text.Text)
			check(info and textOf(info, "Text") == "STOLEN CHOMP FROG", tag .. ": thief info text", info and textOf(info, "Text"))
			check(info and info:FindFirstChild("Chip") and info.Chip.Text.Text == "COMMON", tag .. ": tier chip COMMON")
			check(not StealAlert.isOn(), tag .. ": the thief's strips are not an owner alert")
			audit(tag .. " thief", root, holder, touch)
			clearOf(tag .. " thief strips", root, g)
			clearOf(tag .. " thief info", root, info)
			StealAlert.showThief({ creatureId = "z4_t5", level = 3, bought = true })
			task.wait()
			audit(tag .. " thief bought long name", root, holder, touch)
			-- everything at once
			StealAlert.showOwner({ uid = "4242-1", creatureId = "z4_t5", thiefUserId = 777, bought = true })
			StealAlert.showBroken({ plotId = 1, byUserId = nil })
			task.wait()
			audit(tag .. " all alerts", root, holder, touch)
			local hr = rect(root, holder)
			check(hr.y1 <= rr.y1 - 4, tag .. ": all four banners fit on screen", fmt(hr))
			StealAlert.hideOwner("4242-1"); StealAlert.hideBroken(); StealAlert.hideThief()
			check(#holder:GetChildren() == 1, tag .. ": every banner removed (only the layout left)", tostring(#holder:GetChildren()))

			-- 4. lock board
			LockBoard.setShield("cooldown"); LockBoard.setPasses({}); LockBoard.show()
			task.wait()
			local lb = root:FindFirstChild("LockBoard")
			check(lb ~= nil, tag .. ": lock board shows while the shield is down")
			if lb then
				check(lb:FindFirstChild("Buy_pass_long_lock", true) ~= nil, tag .. ": Long Lock button")
				check(lb:FindFirstChild("Buy_product_instant_shield", true) ~= nil, tag .. ": Instant Shield button while down")
				check(lb:FindFirstChild("Buy_pass_long_lock", true).Face.Label.Text == "LONG LOCK\nR$ 199", tag .. ": Long Lock text", lb:FindFirstChild("Buy_pass_long_lock", true).Face.Label.Text)
				check(lb:FindFirstChild("Buy_product_instant_shield", true).Face.Label.Text == "INSTANT SHIELD\nR$ 19", tag .. ": Instant Shield text")
				audit(tag .. " lock board", root, lb, touch)
				clearOf(tag .. " lock board", root, lb)
			end
			LockBoard.setShield("up")
			task.wait()
			lb = root:FindFirstChild("LockBoard")
			check(lb and lb:FindFirstChild("Buy_product_instant_shield", true) == nil and lb:FindFirstChild("Buy_pass_long_lock", true) ~= nil, tag .. ": shield up: Instant Shield hidden, Long Lock stays")
			LockBoard.setPasses({ pass_long_lock = true })
			task.wait()
			check(root:FindFirstChild("LockBoard") == nil, tag .. ": shield up and Long Lock owned: board hidden")
			LockBoard.setShield("ready")
			task.wait()
			lb = root:FindFirstChild("LockBoard")
			check(lb and lb:FindFirstChild("Buy_pass_long_lock", true) == nil and lb:FindFirstChild("Buy_product_instant_shield", true) ~= nil, tag .. ": ready, Long Lock owned: only Instant Shield")
			if lb then
				audit(tag .. " lock board one button", root, lb, touch)
			end
			LockBoard.setShield("instant")
			task.wait()
			check(root:FindFirstChild("LockBoard") == nil, tag .. ": Instant Shield up: no Instant Shield offer")
			LockBoard.setShield("cooldown")
			StealAlert.showOwner({ uid = "4242-1", creatureId = "z1_t1", thiefUserId = 777, bought = false })
			LockBoard.refresh() -- in play StealAlert.onChange does this
			task.wait()
			check(root:FindFirstChild("LockBoard") == nil, tag .. ": lock board hidden while a steal alert is on")
			StealAlert.hideOwner("4242-1")
			LockBoard.refresh()
			task.wait()
			check(root:FindFirstChild("LockBoard") ~= nil, tag .. ": lock board back after the alert ends")
			StealAlert.showBroken({ plotId = 1, byUserId = nil })
			LockBoard.refresh()
			task.wait()
			check(root:FindFirstChild("LockBoard") == nil, tag .. ": lock board hidden while a shield-broken alert is on")
			StealAlert.hideBroken()
			LockBoard.hide()
			check(root:FindFirstChild("LockBoard") == nil, tag .. ": hide removes the board")
			LockBoard.destroy()

			-- 5. prompts: steal, locked, break shield
			local ps = Prompts.parts()
			local ph = Prompts.instance()
			Prompts.showSteal({ holdS = 2, quickS = 1, quickHandsOwned = false, glyphKind = "touch" })
			task.wait()
			local sb = ph:FindFirstChild("Prompt_steal")
			check(sb and sb.Visible and sb.Face.Label.Text == "HOLD TO STEAL" and not disabled(ph, "Prompt_steal"), tag .. ": steal prompt live")
			check(ps.stealInfo.Visible and ps.holdLine.Text == "Hold 2.0 s.\nQuick Hands: 1.0 s.", tag .. ": steal hold line", ps.holdLine.Text:gsub("\n", "|"))
			check(ps.quickHands.root.Visible and ps.quickHands.label.Text == "R$ 199", tag .. ": Quick Hands R$ 199 button")
			audit(tag .. " steal prompt", root, ph, touch)
			clearOf(tag .. " steal prompt", root, sb)
			clearOf(tag .. " steal info", root, ps.stealInfo)
			Prompts.showSteal({ holdS = 1, quickHandsOwned = true, glyphKind = "keyboard" })
			task.wait()
			check(ps.holdLine.Text == "Hold 1.0 s." and not ps.quickHands.root.Visible, tag .. ": Quick Hands owned: its line and button gone")
			check(ps.kinds.steal.glyphLabel.Text == "E", tag .. ": steal glyph E on keyboard")
			audit(tag .. " steal prompt owned", root, ph, touch)
			Prompts.showSteal({ locked = true, glyphKind = "touch" })
			task.wait()
			check(sb.Face.Label.Text == "CAN'T BE STOLEN", tag .. ": locked prompt text", sb.Face.Label.Text)
			check(disabled(ph, "Prompt_steal"), tag .. ": locked prompt is greyed")
			check(ps.padlock.Visible and ps.kinds.steal.glyphPlate.Visible, tag .. ": padlock shown")
			check(not ps.stealInfo.Visible, tag .. ": no info line on the locked prompt")
			local allT = {}
			for _, o in ipairs(ph:GetDescendants()) do
				if o:IsA("TextLabel") and shown(o, root) then
					table.insert(allT, string.lower(o.Text))
				end
			end
			check(not table.concat(allT, " "):find("polic"), tag .. ": no policy wording on the locked prompt")
			audit(tag .. " locked prompt", root, ph, touch)
			clearOf(tag .. " locked prompt", root, sb)
			Prompts.hideSteal()
			check(not sb.Visible and not ps.stealInfo.Visible, tag .. ": steal prompt hides")

			local now = workspace:GetServerTimeNow()
			Prompts.setCharges(0)
			Prompts.setShieldInfo(2, { plotId = 2, state = "up", endsAt = now + 37, breakable = true })
			Prompts.showBreak(2, "Player2", "touch")
			task.wait()
			local bb = ph:FindFirstChild("Prompt_breakShield")
			check(bb and bb.Visible and not disabled(ph, "Prompt_breakShield"), tag .. ": break shield live")
			check(bb.Face.Label.Text == "BREAK SHIELD R$ 39", tag .. ": break label", bb.Face.Label.Text)
			check(ps.breakCaption.Text:find("^PLAYER2'S SHIELD  0:3%d$") ~= nil, tag .. ": caption with the shield's time", ps.breakCaption.Text)
			check(bb.Face.TopLine ~= nil and faceColor(ph, "Prompt_breakShield") == C.shopGold, tag .. ": break button is Robux gold")
			audit(tag .. " break prompt", root, ph, touch)
			clearOf(tag .. " break prompt", root, bb)
			clearOf(tag .. " break caption", root, ps.breakCaption)
			Prompts.setCharges(1)
			check(bb.Face.Label.Text == "BREAK SHIELD FREE x1", tag .. ": with a charge the button is free", bb.Face.Label.Text)
			audit(tag .. " break prompt charge", root, ph, touch)
			Prompts.setCharges(0)
			local cases = {
				{ { plotId = 2, state = "joining", endsAt = now + 40, breakable = false, reason = "joining" }, "Just joined" },
				{ { plotId = 2, state = "instant", endsAt = now + 40, breakable = false, reason = "instant" }, "Instant Shield" },
				{ { plotId = 2, state = "up", endsAt = now + 40, breakable = false, reason = "recent", brokenUntil = now + 200 }, "Broken recently, 3:20" },
				{ { plotId = 2, state = "cooldown", readyAt = now + 40, breakable = false, reason = "down" }, "Shield is down" },
			}
			for _, cs in ipairs(cases) do
				Prompts.setShieldInfo(2, cs[1])
				check(bb.Face.Label.Text == cs[2], tag .. ": greyed reason '" .. cs[2] .. "'", bb.Face.Label.Text)
				check(disabled(ph, "Prompt_breakShield"), tag .. ": greyed for " .. cs[2])
				audit(tag .. " break greyed " .. cs[2], root, ph, touch)
			end
			Prompts.hideBreak()
			check(not bb.Visible and not ps.breakCaption.Visible, tag .. ": break prompt hides")
			-- the other prompts still work
			Prompts.show("place", "touch"); Prompts.show("grab", "keyboard")
			check(ph:FindFirstChild("Prompt_place").Visible and ph:FindFirstChild("Prompt_grab").Visible, tag .. ": M1 prompts unchanged")
			Prompts.hide("place"); Prompts.hide("grab")

			-- 6. the confirm dialog
			local function confirmCase(tag2, fn, want)
				fn()
				task.wait()
				local f = Hud.layer():FindFirstChild("Modal_Confirm")
				check(f ~= nil, tag2 .. ": opens")
				if not f then
					return
				end
				check(textOf(f, "Title") == want.title, tag2 .. ": title", textOf(f, "Title"))
				local body = f:FindFirstChild("ConfirmText", true)
				local t = body and body:FindFirstChild("Text", true)
				check(t and t.Text == want.text, tag2 .. ": text", t and t.Text:gsub("\n", "|"))
				local go = f:FindFirstChild("Confirm", true)
				check(go and go.Face.Label.Text == want.button, tag2 .. ": button text", go and go.Face.Label.Text)
				check(faceColor(f, "Confirm") == want.color, tag2 .. ": button colour")
				check((f:FindFirstChild("BoughtTag", true) ~= nil) == want.bought, tag2 .. ": BOUGHT tag " .. tostring(want.bought))
				check(f:FindFirstChild("Cancel", true).Face.Label.Text == "CANCEL", tag2 .. ": CANCEL")
				audit(tag2, root, f, touch)
				if t then
					check(t.TextBounds.Y <= t.Parent.AbsoluteSize.Y + 1, tag2 .. ": text needs no scrolling", ("%.0f > %.0f"):format(t.TextBounds.Y, t.Parent.AbsoluteSize.Y))
				end
				local panel = f:FindFirstChild("Panel")
				local pr = rect(root, panel)
				check(pr.x0 >= -0.5 and pr.y0 >= -0.5 and pr.x1 <= rr.x1 + 0.5 and pr.y1 <= rr.y1 + 0.5, tag2 .. ": panel inside the screen", fmt(pr))
				Confirm.close()
				check(not Confirm.isOpen(), tag2 .. ": closes")
			end
			confirmCase(tag .. " sell", function()
				Confirm.sell({ creatureId = "z1_t1", level = 3, amount = 30, bought = false })
			end, { title = "SELL THIS BOSS?", text = "Chomp Frog, level 3, is sold for $30.\n\nYou can't get it back.", button = "SELL $30", color = C.cashGreen, bought = false })
			confirmCase(tag .. " sell bought", function()
				Confirm.sell({ creatureId = "z1_t4", level = 1, amount = 240, bought = "pack" })
			end, { title = "SELL THIS BOSS?", text = "Headbutt Ram, level 1, is sold for $240.\n\nYou can't get it back.\n\nThis boss was bought with Robux.\nSelling it is for good.", button = "SELL $240", color = C.cashGreen, bought = true })
			confirmCase(tag .. " swap bought", function()
				Confirm.swap({ creatureId = "z1_t1", level = 3, amount = 30, bought = "spin", spotIndex = 1 })
			end, { title = "SWAP BOSSES?", text = "Chomp Frog, level 3, is sold for $30 and the boss you carry takes its spot.\n\nThis boss was bought with Robux.\nSelling it is for good.", button = "SWAP", color = C.alarmOrange, bought = true })
			confirmCase(tag .. " swap long", function()
				Confirm.swap({ creatureId = "z4_t5", level = 20, amount = 1.5e9, bought = "pack", spotIndex = 9 })
			end, { title = "SWAP BOSSES?", text = "Glacier Mammoth, level 20, is sold for $1.5B and the boss you carry takes its spot.\n\nThis boss was bought with Robux.\nSelling it is for good.", button = "SWAP", color = C.alarmOrange, bought = true })
			check(Confirm.estimate(1.5) == 30, tag .. ": estimate = income x 20 (the kit's $30 for $1.50/s)")
		end

		-- one refused shield action = one toast: Toasts is the only listener of Shield.Result; wave B modules must not listen to it
		for _, name in ipairs({ "StealAlert", "LockBoard", "Prompts", "Confirm" }) do
			local src = Ui[name].Source
			check(not src:find('"Shield", "Result"'), "no " .. name .. " listener on Shield.Result (Toasts is the one place)")
		end
		do
			local root = setup(VPS[1])
			Toasts.reason("joining") -- what Toasts does for one failed Shield.Result { action = 'useCharge', reason = 'joining' }
			local n = 0
			for _, c in ipairs(Toasts.instance():GetChildren()) do
				if c.Name == "Toast" then n += 1 end
			end
			check(n == 1, "one refused shield action shows exactly one toast", tostring(n))
		end
		print(("ScreensB: smallest text on screen %.1f px"):format(smallest))
	end)
	if not ok then
		failed += 1
		print("ScreensB: ERROR " .. tostring(err))
	end
	for _, g in ipairs(StarterGui:GetChildren()) do if g.Name == "HussHud" then g:Destroy() end end
	LockBoard.destroy(); Confirm.close()
	print(("ScreensB: %d passed, %d failed"):format(passed, failed))
end
