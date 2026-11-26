if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-20 plain screens C check (gui-designer). Edit mode, studio lock held, after a sync:
--   require(game.ServerStorage.DevSync:Clone()).run("checks/ScreensC.lua")
-- Builds the HUD and the wave C screens (shop, Lucky Spin, Starter Pack offer, the bag panel's Perfect Auto Punch row) into StarterGui at five
-- viewports, drives each with the contract's payloads through the modules' own handlers (Shop.onState / onQuotes / onProfile, Spin.onResult,
-- StarterOffer.onOffer: no remote, no hook, no purchase), reads layout back in screen px.
-- On-screen mode: set workspace attribute ScreensCShow to
--   shop | shopNoAuto | shopRestricted | spin | spinNone | spinResult | spinRestricted | starter | bag | bagNoAuto
-- (and ScreensCVp to phone | small | tablet | desktop | desktop2); the run builds that one screen, LEAVES it in StarterGui for a look, and clears
-- both attributes (nothing is left armed). Run once more with neither set to remove it.
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SPS = StarterPlayer:WaitForChild("StarterPlayerScripts")
local Ui = SPS:WaitForChild("Ui")
local ShopCtl = require(SPS.Controllers.Shop) -- the M2-19 controller the screens are views over (driven through its _on* seams, never a remote)
local SpinCtl = require(SPS.Controllers.Spin)
local Hud = require(Ui.Hud)
local Kit = require(Ui.Kit)
local Shop = require(Ui.Shop)
local Spin = require(Ui.Spin)
local StarterOffer = require(Ui.StarterOffer)
local BagPanel = require(Ui.BagPanel)
local Toasts = require(Ui.Toasts)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skin = require(Shared.Skin)
local Ids = require(Shared.Ids)
local SpinTable = require(Shared.SpinTable)
local Config = require(Shared.Config)
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
		print(("ScreensC: FAIL %s%s"):format(what, detail and (" [" .. tostring(detail) .. "]") or ""))
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

local smallest = math.huge
-- every shown label under `container`: text >= 13 px on screen, fits its box, inside its parent (cards and wells), every shown button >= 43.5 px.
-- Content inside the scrolling list is checked against its own card, not the screen (the list scrolls).
local function audit(tag, root, container, touch)
	for _, o in ipairs(container:GetDescendants()) do
		if o:IsA("TextLabel") and o.Text ~= "" and shown(o, root) then
			local px = o.TextSize * Kit.scale()
			smallest = math.min(smallest, px)
			local short = string.sub(o.Text, 1, 28):gsub("\n", "|")
			check(px >= 13, tag .. ": text size " .. o.Name, ("%.1f px"):format(px))
			if o.TextWrapped then
				check(o.TextBounds.Y <= o.AbsoluteSize.Y + 1.5, tag .. ": wrapped label fits " .. o.Name .. " '" .. short .. "'", ("%.0f > %.0f"):format(o.TextBounds.Y, o.AbsoluteSize.Y))
			else
				check(o.TextBounds.X <= o.AbsoluteSize.X + 1.5 and o.TextBounds.Y <= o.AbsoluteSize.Y + 1.5, tag .. ": label fits " .. o.Name .. " '" .. short .. "'", ("%.0f x %.0f in %.0f x %.0f"):format(o.TextBounds.X, o.TextBounds.Y, o.AbsoluteSize.X, o.AbsoluteSize.Y))
			end
			local par = o.Parent
			if par and par:IsA("GuiObject") and not par:IsA("ScrollingFrame") then
				local lr, pr = rect(root, o), rect(root, par)
				check(lr.x0 >= pr.x0 - 1.5 and lr.x1 <= pr.x1 + 1.5 and lr.y0 >= pr.y0 - 1.5 and lr.y1 <= pr.y1 + 1.5, tag .. ": label inside its box " .. o.Name .. " '" .. short .. "'", fmt(lr) .. " in " .. fmt(pr))
			end
		elseif o:IsA("TextButton") and o.Name == "Face" and shown(o, root) then
			local r = rect(root, o)
			check(r.y1 - r.y0 >= 43.5 or not touch, tag .. ": touch target " .. o.Parent.Name, ("%.1f px tall"):format(r.y1 - r.y0))
			check(r.x1 - r.x0 >= 43.5 or not touch, tag .. ": touch target wide " .. o.Parent.Name, ("%.1f px wide"):format(r.x1 - r.x0))
		end
	end
end

local function disabled(frame, name)
	local b = frame and frame:FindFirstChild(name, true)
	local face = b and b:FindFirstChild("Face")
	return face ~= nil and face.BackgroundColor3 == C.disabledGrey
end
local function btnText(frame, name)
	local b = frame and frame:FindFirstChild(name, true)
	local face = b and b:FindFirstChild("Face")
	return face and face.Label.Text or ""
end
local function modalFrame(name)
	return Hud.layer() and Hud.layer():FindFirstChild("Modal_" .. name)
end

local started = false
local function ST(st) -- Shop.State
	ShopCtl._onState(st)
	SpinCtl._onState(st)
end
local function PR(p) -- Profile.Changed
	ShopCtl._onProfile(p)
	SpinCtl._onProfile(p)
	Shop.onProfile(p)
end
local function setup(v)
	ShopCtl._reset(); SpinCtl._reset()
	ShopCtl._noSend(true); SpinCtl._noSend(true) -- nothing reaches a remote, no prompt, no purchase
	StarterOffer.reset()
	Hud.build(StarterGui, { viewport = v.vp, mouse = v.mouse })
	local root = Hud.root()
	Shop.build()
	Hud.tile("shop", N.ui.tiles.shop, 1, ShopCtl.toggle) -- the controller builds this tile in the game (Names.ui.tiles.shop)
	if not started and not ShopCtl._screensCWired then -- listeners stay on the cached controller: wire once per sync
		started = true
		ShopCtl._screensCWired = true
		ShopCtl.onChange(Shop.refresh)
		ShopCtl.onGrant(Shop.onGrant)
	end
	Hud.tile("rebirth", N.ui.tiles.rebirth, 2, function() end)
	Hud.tile("settings", N.ui.tiles.settings, 3, function() end)
	Hud.tile("bag", N.ui.tiles.bag, 4, function() end)
	Toasts.build(root)
	Spin.build()
	if not SpinCtl._screensCWired then
		SpinCtl._screensCWired = true
		SpinCtl.onResult(Spin.onResult)
		SpinCtl.onChange(Spin.refresh)
	end
	StarterOffer.build()
	BagPanel.build()
	task.wait()
	return root
end

local QUOTES = { packs = {
	product_cash_small = { amount = 4500, quoteKey = "q1", expiresAt = workspace:GetServerTimeNow() + 300 },
	product_cash_medium = { amount = 18000, quoteKey = "q2", expiresAt = workspace:GetServerTimeNow() + 300 },
	product_cash_large = { amount = 72000, quoteKey = "q3", expiresAt = workspace:GetServerTimeNow() + 300 },
	product_cash_huge = { amount = 216000, quoteKey = "q4", expiresAt = workspace:GetServerTimeNow() + 300 },
} }
local function state(passes, restricted, starterGiven)
	return { passes = passes, policy = { randomItemsRestricted = restricted, tradingAllowed = true }, starterPackGiven = starterGiven or false, promptOpen = false }
end
local function drive(show)
	Shop.setPlot(nil)
	Shop.onShieldState({ plotId = 3, state = "ready" })
	ShopCtl._onQuotes(QUOTES)
	local owned = { pass_auto_punch = true, pass_2x_power = true }
	if show == "shopNoAuto" or show == "bagNoAuto" then
		owned = { pass_2x_power = true }
	end
	ST(state(owned, show == "shopRestricted" or show == "spinRestricted"))
	PR({ boughtCash = 5000, spinTickets = if show == "spinNone" then 0 else 2, breakerCharges = 0, zonesBeaten = if show == "spinNone" then {} else { 1, 2 } })
	if show == "shop" or show == "shopNoAuto" or show == "shopRestricted" then
		ShopCtl.open()
	elseif show == "spin" or show == "spinNone" or show == "spinResult" or show == "spinRestricted" then
		SpinCtl.selectZone(1)
		SpinCtl.open()
		if show == "spinResult" then
			SpinCtl._onResult({ ok = true, zone = 1, creatureId = "z1_t3", tier = 3, uid = "u1" })
		end
	elseif show == "starter" then
		StarterOffer.show(true)
	elseif show == "bag" or show == "bagNoAuto" then
		BagPanel.onState({ strengthLevel = 1, speedLevel = 1, autoOn = false, perfectOn = false, autoOwned = show == "bag", perfectOwned = false, nextStrengthCost = 100, nextSpeedCost = 200 })
		BagPanel.open()
	end
end

local show = workspace:GetAttribute("ScreensCShow")
local vpKey = workspace:GetAttribute("ScreensCVp")
workspace:SetAttribute("ScreensCShow", nil) -- consumed: never left armed
workspace:SetAttribute("ScreensCVp", nil)
if type(show) == "string" and show ~= "" then
	local v = VPS[1]
	for _, c in ipairs(VPS) do if c.key == (vpKey or "phone") then v = c end end
	setup(v)
	drive(show)
	print(("ScreensC: left %s on screen at %s (run again with neither attribute set to remove it)"):format(show, v.name))
else
	local ok, err = pcall(function()
		local EXPECT_CARDS = {}
		for _, k in ipairs(Ids.SHOP_KEYS) do
			if not table.find(Ids.SPIN_PRODUCTS, k) then
				EXPECT_CARDS[k] = true
			end
		end
		local function cardKeys(frame)
			local out, n = {}, 0
			for _, o in ipairs(frame:GetDescendants()) do
				if o.Name:sub(1, 5) == "Card_" then
					out[o.Name:sub(6)] = o
					n += 1
				end
			end
			return out, n
		end

		for _, v in ipairs(VPS) do
			local tag = v.name
			local touch = not v.mouse
			local root = setup(v)
			local rr = rect(root, root)

			-- ===================================================== before Shop.State arrives (fresh controller): no spin UI
			do
				check(Shop.restricted() and not SpinCtl.available(), tag .. ": before State the controllers count the player as restricted")
				ShopCtl.open()
				task.wait()
				local f0 = modalFrame("Shop")
				local k0, n0 = cardKeys(f0)
				check(k0.spin_card == nil and n0 == 15, tag .. ": before State: no Spin card (15 cards, no Perfect)", n0)
				local w0 = {}
				for _, o in ipairs(f0:GetDescendants()) do
					if o:IsA("TextLabel") then table.insert(w0, string.lower(o.Text)) end
				end
				check(not table.concat(w0, " "):find("spin") and not table.concat(w0, " "):find("odds"), tag .. ": before State: no spin wording in the shop")
				SpinCtl.open()
				Spin.open()
				task.wait()
				check(modalFrame("Spin") == nil and not Spin.isOpen(), tag .. ": before State: the Spin screen does not open")
				ShopCtl.close()
			end

			-- ===================================================== the shop, an Auto Punch owner
			Shop.setPlot(nil)
			ShopCtl._onQuotes(QUOTES)
			ST(state({ pass_auto_punch = true, pass_2x_power = true }, false))
			PR({ boughtCash = 5000, spinTickets = 2, breakerCharges = 0, zonesBeaten = { 1, 2 } })
			check(Hud.layer() ~= nil and root:FindFirstChild("Tiles") and root.Tiles:FindFirstChild("Tile_shop") ~= nil, tag .. ": SHOP tile in the tile row")
			ShopCtl.open()
			task.wait()
			local f = modalFrame("Shop")
			check(f ~= nil and Shop.isOpen(), tag .. ": shop opens")
			if f then
				local keys, n = cardKeys(f)
				check(n == 17, tag .. ": 17 cards (16 products + the Lucky Spin card), Auto Punch owner", n)
				for k in pairs(EXPECT_CARDS) do
					check(keys[k] ~= nil, tag .. ": card for " .. k)
				end
				check(keys.spin_card ~= nil, tag .. ": Lucky Spin card shown (not restricted)")
				check(f:FindFirstChild("BoughtCash", true) ~= nil, tag .. ": the bought-cash well")
				check(f:FindFirstChild("BoughtCash", true).Value.Text == "$5,000", tag .. ": bought cash $5,000", f:FindFirstChild("BoughtCash", true).Value.Text)
				-- the three spin products complete the 19: their buttons are on the Spin screen (below)
				local function cb(k) return btnText(keys[k], "Buy") end
				local function cdis(k) return disabled(keys[k], "Buy") end
				check(cb("pass_auto_punch") == "OWNED" and cdis("pass_auto_punch"), tag .. ": Auto Punch OWNED, greyed", cb("pass_auto_punch"))
				check(cb("pass_2x_power") == "OWNED" and cdis("pass_2x_power"), tag .. ": 2x Power OWNED")
				check(cb("pass_perfect_auto_punch") == "R$ 399" and not cdis("pass_perfect_auto_punch"), tag .. ": Perfect Auto Punch R$ 399 for an Auto Punch owner", cb("pass_perfect_auto_punch"))
				local want = { pass_2x_cash = 349, pass_fast_carry = 149, pass_extra_spots = 249, pass_starter_pack = 99, pass_long_lock = 199, pass_quick_hands = 199, pass_iron_grip = 299, product_instant_shield = 19 }
				for k, p in pairs(want) do
					check(cb(k) == "R$ " .. p and not cdis(k), tag .. ": " .. k .. " R$ " .. p, cb(k))
				end
				check(cb("product_cash_small") == "$4,500  R$ 29", tag .. ": small pack amount and price", cb("product_cash_small"))
				check(cb("product_cash_medium") == "$18K  R$ 79", tag .. ": medium pack", cb("product_cash_medium"))
				check(cb("product_cash_large") == "$72K  R$ 199", tag .. ": large pack", cb("product_cash_large"))
				check(cb("product_cash_huge") == "$216K  R$ 399", tag .. ": huge pack", cb("product_cash_huge"))
				check(cb("product_shield_breaker") == "BUY AT A SHIELD" and cdis("product_shield_breaker"), tag .. ": Shield Breaker explained, bought at a shield")
				check(cb("spin_card") == "SEE THE ODDS" and not cdis("spin_card"), tag .. ": Lucky Spin card SEE THE ODDS")
				-- text from the skin: titles
				check(keys.pass_2x_power.Title.Text == "2X POWER" and keys.product_cash_medium.Title.Text == "MEDIUM CASH PACK", tag .. ": card titles from the skin")
				check(keys.pass_starter_pack.DescWell.Desc.Text == "$5,000 and a Headbutt Ram. Kept through rebirth.", tag .. ": Starter Pack text")
				-- the list scrolls and ends inside its canvas
				local sc = f:FindFirstChild("Scroll", true)
				local lastY = 0
				for _, o in pairs(keys) do
					lastY = math.max(lastY, o.Position.Y.Offset + o.Size.Y.Offset)
				end
				check(sc ~= nil and sc.CanvasSize.Y.Offset >= lastY, tag .. ": canvas holds every card", sc and sc.CanvasSize.Y.Offset)
				local pr = rect(root, f.Panel)
				check(pr.x0 >= -0.5 and pr.y0 >= -0.5 and pr.x1 <= rr.x1 + 0.5 and pr.y1 <= rr.y1 + 0.5, tag .. ": shop panel inside the screen", fmt(pr))
				check(f.Panel:FindFirstChild("Close", true) ~= nil, tag .. ": close button")
				audit(tag .. " shop", root, f, touch)
				-- the fresh quote is sent with a cash pack Buy; a card is a view: sending is Shop.buy (no remote in edit mode, so just no error)
				-- an expired quote greys the button
				ShopCtl._onQuotes({ packs = { product_cash_small = { amount = 4500, quoteKey = "q1", expiresAt = workspace:GetServerTimeNow() - 1 } } })
				task.wait()
				local f2 = modalFrame("Shop")
				local k2 = cardKeys(f2)
				check(btnText(k2.product_cash_small, "Buy") == "..." and disabled(k2.product_cash_small, "Buy"), tag .. ": no live quote: greyed, no amount")
				ShopCtl._onQuotes(QUOTES)
				-- an own shield up greys Instant Shield
				Shop.setPlot(3)
				Shop.onShieldState({ plotId = 3, state = "up", endsAt = workspace:GetServerTimeNow() + 40, breakable = true })
				task.wait()
				k2 = cardKeys(modalFrame("Shop"))
				check(btnText(k2.product_instant_shield, "Buy") == "SHIELD IS UP" and disabled(k2.product_instant_shield, "Buy"), tag .. ": Instant Shield greyed 'Shield is up'")
				Shop.onShieldState({ plotId = 3, state = "cooldown", readyAt = workspace:GetServerTimeNow() + 40 })
				task.wait()
				k2 = cardKeys(modalFrame("Shop"))
				check(btnText(k2.product_instant_shield, "Buy") == "R$ 19", tag .. ": Instant Shield buyable again with the shield down")
				-- a stored Shield Breaker charge is told
				PR({ breakerCharges = 2 })
				task.wait()
				k2 = cardKeys(modalFrame("Shop"))
				check(k2.product_shield_breaker.DescWell.Desc.Text:find("You have 2 stored.", 1, true) ~= nil, tag .. ": stored Shield Breaker charges shown")
				PR({ breakerCharges = 0 })
			end

			-- no Auto Punch: no Perfect card
			ST(state({ pass_2x_power = true }, false))
			task.wait()
			do
				local keys, n = cardKeys(modalFrame("Shop"))
				check(keys.pass_perfect_auto_punch == nil and n == 16, tag .. ": no Perfect Auto Punch card without Auto Punch", n)
				check(btnText(keys.pass_auto_punch, "Buy") == "R$ 249" and not disabled(keys.pass_auto_punch, "Buy"), tag .. ": Auto Punch buyable when not owned")
			end
			-- Perfect owned: it shows OWNED
			ST(state({ pass_auto_punch = true, pass_perfect_auto_punch = true }, false))
			task.wait()
			do
				local keys = cardKeys(modalFrame("Shop"))
				check(btnText(keys.pass_perfect_auto_punch, "Buy") == "OWNED", tag .. ": Perfect owned shows OWNED")
			end
			-- Starter Pack given: OWNED
			ST(state({ pass_auto_punch = true }, false, true))
			task.wait()
			do
				local keys = cardKeys(modalFrame("Shop"))
				check(btnText(keys.pass_starter_pack, "Buy") == "OWNED", tag .. ": Starter Pack given shows OWNED")
			end

			-- ===================================================== restricted: the Spin card, screen and spin products are gone, the rest unchanged
			ST(state({ pass_auto_punch = true }, false))
			task.wait()
			local before = cardKeys(modalFrame("Shop"))
			ST(state({ pass_auto_punch = true }, true))
			task.wait()
			local fr = modalFrame("Shop")
			local after, na = cardKeys(fr)
			check(after.spin_card == nil and na == 16, tag .. ": restricted: no Spin card", na)
			for k in pairs(before) do
				if k ~= "spin_card" then
					check(after[k] ~= nil, tag .. ": restricted: card kept " .. k)
				end
			end
			local words = {}
			for _, o in ipairs(fr:GetDescendants()) do
				if o:IsA("TextLabel") then
					table.insert(words, string.lower(o.Text))
				end
			end
			local all = table.concat(words, " ")
			check(not all:find("spin") and not all:find("odds"), tag .. ": restricted: no spin wording in the shop")
			audit(tag .. " shop restricted", root, fr, touch)
			SpinCtl.open()
			task.wait()
			check(modalFrame("Spin") == nil and not Spin.isOpen(), tag .. ": restricted: the Spin screen does not open")
			ST(state({ pass_auto_punch = true }, false))
			check(not Shop.restricted(), tag .. ": restricted = false opens the Spin card")
			ShopCtl.close()

			-- ===================================================== the Spin screen
			PR({ spinTickets = 2, zonesBeaten = { 1, 2 } })
			SpinCtl.selectZone(1)
			SpinCtl.open()
			task.wait()
			local sf = modalFrame("Spin")
			check(sf ~= nil and Spin.isOpen(), tag .. ": Spin screen opens")
			if sf then
				local body = sf.Panel.Body
				local kids = body:GetChildren()
				local idx = {}
				for i, o in ipairs(kids) do
					idx[o.Name] = i
				end
				-- the odds list comes first: six columns from SpinTable.ODDS, and every Buy / Spin button is made after them
				check(Spin.oddsListed(), tag .. ": the odds list is complete (6 outcomes, 100%)")
				local lastOdds, firstBtn = 0, math.huge
				for _, o in ipairs(SpinTable.ODDS) do
					local col = body:FindFirstChild("Outcome" .. o.tier)
					check(col ~= nil, tag .. ": outcome column " .. o.tier)
					if col then
						lastOdds = math.max(lastOdds, idx[col.Name])
						check(col.Percent.Text == o.percent .. "%", tag .. ": odds " .. o.tier .. " = SpinTable " .. o.percent .. "%", col.Percent.Text)
						local nm = col:FindFirstChild("Name")
						check(nm.Text == string.upper(N.creatures[Ids.creature(1, o.tier)]), tag .. ": outcome name zone 1 tier " .. o.tier, nm.Text)
						check(col.TierChip.Tier.Text == string.upper(N.tiers[o.tier]), tag .. ": tier chip " .. o.tier)
						check(col.BackgroundColor3 == C.tier[o.tier], tag .. ": tier colour " .. o.tier)
					end
				end
				for _, nme in ipairs({ "Spin", "Buy1", "Buy3", "Buy10" }) do
					firstBtn = math.min(firstBtn, idx[nme] or math.huge)
				end
				check(lastOdds > 0 and lastOdds < firstBtn, tag .. ": every odds column is built before any Spin or Buy button", ("%d < %d"):format(lastOdds, firstBtn))
				check(btnText(sf, "Spin") == "SPIN" and not disabled(sf, "Spin"), tag .. ": SPIN enabled with a ticket on a beaten zone")
				check(btnText(sf, "Buy1") == "x1  R$ 49" and btnText(sf, "Buy3") == "x3  R$ 129" and btnText(sf, "Buy10") == "x10  R$ 399", tag .. ": the three ticket products with prices", btnText(sf, "Buy1") .. "|" .. btnText(sf, "Buy3") .. "|" .. btnText(sf, "Buy10"))
				check(not disabled(sf, "Buy1") and not disabled(sf, "Buy3") and not disabled(sf, "Buy10"), tag .. ": ticket buttons enabled once the odds are listed")
				check(body.Tickets.Text.Text == "TICKETS 2", tag .. ": tickets owned", body.Tickets.Text.Text)
				check(not disabled(sf, "Zone1") and not disabled(sf, "Zone2") and disabled(sf, "Zone3") and disabled(sf, "Zone6"), tag .. ": zones beaten are pressable, the rest greyed")
				check(body.Note.Text.Text == "Every spin gives one of these six bosses. The odds never change.", tag .. ": the note", body.Note.Text.Text)
				-- all 19 products are reachable: 16 shop cards + the 3 ticket products above
				local pr = rect(root, sf.Panel)
				check(pr.x0 >= -0.5 and pr.y0 >= -0.5 and pr.x1 <= rr.x1 + 0.5 and pr.y1 <= rr.y1 + 0.5, tag .. ": spin panel inside the screen", fmt(pr))
				audit(tag .. " spin", root, sf, touch)
				-- bottom row: no overlap
				local rects = {}
				for _, nme in ipairs({ "Tickets", "Spin", "Buy1", "Buy3", "Buy10" }) do
					rects[nme] = rect(root, body[nme])
				end
				local names = { "Tickets", "Spin", "Buy1", "Buy3", "Buy10" }
				for i = 1, #names do
					for j = i + 1, #names do
						check(not overlap(rects[names[i]], rects[names[j]]), tag .. ": " .. names[i] .. " clear of " .. names[j])
					end
					check(rects[names[i]].x1 <= pr.x1 and rects[names[i]].y1 <= pr.y1, tag .. ": " .. names[i] .. " inside the panel")
				end
				local lastCol = rect(root, body.Outcome6)
				check(lastCol.y1 <= rects.Spin.y0 + 0.5, tag .. ": odds columns above the buttons")
				-- the zone picker changes the names (zone 2), odds stay the same
				SpinCtl.selectZone(2)
				task.wait()
				sf = modalFrame("Spin")
				body = sf.Panel.Body
				for _, o in ipairs(SpinTable.ODDS) do
					local col = body["Outcome" .. o.tier]
					check(col:FindFirstChild("Name").Text == string.upper(N.creatures[Ids.creature(2, o.tier)]) and col.Percent.Text == o.percent .. "%", tag .. ": zone 2 outcome " .. o.tier)
				end
				audit(tag .. " spin zone2", root, sf, touch)
				-- a result: the won line and the won column marked
				SpinCtl._onResult({ ok = true, zone = 2, creatureId = "z2_t3", tier = 3, uid = "u1" })
				task.wait()
				sf = modalFrame("Spin")
				body = sf.Panel.Body
				check(body.Note.Text.Text == "You won Prickle Gecko! It is in your crate.", tag .. ": result line", body.Note.Text.Text)
				check(body.Outcome3.Outline.Color == C.flashYellow and body.Outcome1.Outline.Color ~= C.flashYellow, tag .. ": the won outcome is marked")
				audit(tag .. " spin result", root, sf, touch)
				-- a refusal gives one toast with the skin's words
				local nT = 0
				SpinCtl._onResult({ ok = false, reason = "tickets", zone = 2 })
				task.wait()
				for _, c in ipairs(Toasts.instance():GetChildren()) do
					if c.Name == "Toast" then nT += 1 end
				end
				check(nT == 1, tag .. ": a refused spin gives exactly one toast", nT)
				-- no tickets: SPIN greyed, odds still listed, tickets buyable
				PR({ spinTickets = 0 })
				SpinCtl.selectZone(1)
				task.wait()
				sf = modalFrame("Spin")
				check(disabled(sf, "Spin") and not disabled(sf, "Buy1"), tag .. ": no tickets: SPIN greyed, Buy still there")
				check(Spin.oddsListed() and sf.Panel.Body:FindFirstChild("Outcome6") ~= nil, tag .. ": no tickets: the odds are still listed")
				-- nothing beaten: "Beat a boss first", zone 1 greyed, odds listed, SPIN greyed
				PR({ spinTickets = 2, zonesBeaten = {} })
				task.wait()
				sf = modalFrame("Spin")
				body = sf.Panel.Body
				check(body.Note.Text.Text == "Beat a boss first", tag .. ": no zone beaten: 'Beat a boss first'", body.Note.Text.Text)
				check(disabled(sf, "Zone1") and disabled(sf, "Spin"), tag .. ": no zone beaten: zone 1 locked, SPIN greyed")
				check(body:FindFirstChild("Outcome1") ~= nil and body:FindFirstChild("Outcome6") ~= nil, tag .. ": no zone beaten: the six outcomes are shown")
				audit(tag .. " spin none beaten", root, sf, touch)
				-- the policy flips while open: the screen closes
				ST(state({}, true))
				task.wait()
				check(modalFrame("Spin") == nil, tag .. ": restricted while open: the Spin screen closes")
				ST(state({ pass_auto_punch = true }, false))
				PR({ zonesBeaten = { 1, 2 } })
			end

			-- ===================================================== the Starter Pack offer
			ST(state({}, false))
			ShopCtl.open()
			task.wait()
			check(StarterOffer.show() == false and not StarterOffer.isOpen(), tag .. ": the offer is not drawn while another screen is open (show -> false)")
			ShopCtl._onOffer({ key = "pass_starter_pack" }) -- the controller retries until the screens clear; OfferSeen is not sent (noSend)
			task.wait(0.8)
			check(not StarterOffer.isOpen(), tag .. ": the offer waits for the shop to close")
			ShopCtl.close()
			task.wait(1.3)
			check(StarterOffer.isOpen(), tag .. ": the offer appears after the screens close (controller -> Ui/StarterOffer.show)")
			local of = modalFrame("StarterOffer")
			check(of ~= nil and StarterOffer.isOpen(), tag .. ": the offer shows")
			if of then
				local labels = {}
				for _, o in ipairs(of:GetDescendants()) do
					if o:IsA("TextLabel") and o.Text ~= "" then
						table.insert(labels, o.Text)
					end
				end
				local joined = table.concat(labels, " | ")
				check(of:FindFirstChild("Title", true).Text == "STARTER PACK", tag .. ": title")
				check(of.Panel.Body.CashWell.Amount.Text == "$5,000" and of.Panel.Body.CashWell.Label.Text == "CASH", tag .. ": the cash")
				check(of.Panel.Body.BossWell:FindFirstChild("Name").Text == "HEADBUTT RAM" and of.Panel.Body.BossWell.TierChip.Tier.Text == "EPIC" and of.Panel.Body.BossWell.Income.Text == "$8/s", tag .. ": the Headbutt Ram, EPIC, $8/s", joined)
				check(of.Panel.Body.Note.Text.Text == "Bought once. Both are kept through rebirth.", tag .. ": note")
				check(btnText(of, "Buy") == "BUY R$ 99" and not disabled(of, "Buy"), tag .. ": BUY R$ 99", btnText(of, "Buy"))
				local low = string.lower(joined)
				check(not low:find("%%") and not low:find(" off") and not low:find("%d:%d%d") and not low:find("left") and not low:find("hurry") and not low:find("limited") and not low:find("only"), tag .. ": no countdown, no % off, no urgent wording", joined)
				local pr = rect(root, of.Panel)
				check(pr.x0 >= -0.5 and pr.y0 >= -0.5 and pr.x1 <= rr.x1 + 0.5 and pr.y1 <= rr.y1 + 0.5, tag .. ": offer panel inside the screen", fmt(pr))
				audit(tag .. " starter offer", root, of, touch)
			end
			StarterOffer.close()
			-- once a session: a second offer is ignored
			check(StarterOffer.show() == false and not StarterOffer.isOpen(), tag .. ": the offer comes once a session (show -> false)")
			ST(state({ pass_starter_pack = true }, false))
			StarterOffer.reset()
			check(StarterOffer.show() == false, tag .. ": never shown when the pack is owned")

			-- a refused purchase: one toast (owned), none for cancelled
			do
				local function toasts()
					local n = 0
					for _, c in ipairs(Toasts.instance():GetChildren()) do
						if c.Name == "Toast" then n += 1 end
					end
					return n
				end
				local n0 = toasts()
				ShopCtl._onGrant({ key = "pass_2x_cash", ok = false, reason = "cancelled" })
				task.wait()
				check(toasts() == n0, tag .. ": a cancelled purchase gives no toast")
				ShopCtl._onGrant({ key = "pass_2x_cash", ok = false, reason = "needAuto" })
				task.wait()
				check(toasts() == n0 + 1, tag .. ": a refused purchase gives one toast", toasts() - n0)
				for _, r in ipairs({ "cancelled", "stale", "busy", "owned", "restricted", "needAuto", "state", "shieldUp", "unknown" }) do
					check(N.ui.reasons[r] ~= nil, tag .. ": Names.ui.reasons." .. r)
				end
			end

			-- ===================================================== the bag panel's Perfect Auto Punch row
			local function bagRows(autoOwned, perfectOwned)
				BagPanel.onState({ strengthLevel = 1, speedLevel = 1, autoOn = false, perfectOn = false, autoOwned = autoOwned, perfectOwned = perfectOwned, nextStrengthCost = 100, nextSpeedCost = 200 })
				BagPanel.open()
				task.wait()
				local bf = modalFrame("Bag")
				local rows = {}
				for _, o in ipairs(bf:GetDescendants()) do
					if o.Name == "Row" then
						rows[#rows + 1] = o
					end
				end
				return bf, rows
			end
			local bf, rows = bagRows(false, false)
			check(#rows == 3, tag .. ": bag panel: 3 rows without Auto Punch (no Perfect row)", #rows)
			bf, rows = bagRows(true, false)
			check(#rows == 4, tag .. ": bag panel: Perfect row for an Auto Punch owner", #rows)
			if rows[4] then
				check(rows[4].Title.Text == N.ui.bag.perfect, tag .. ": Perfect row title")
				check(rows[4].Right.Buy.Face.Label.Text == "R$ 399", tag .. ": Perfect row shows R$ 399", rows[4].Right.Buy.Face.Label.Text)
				audit(tag .. " bag perfect row", root, rows[4], touch)
			end
			BagPanel.close()
			BagPanel.onState({ autoOwned = false, perfectOwned = false })

			-- the HUD is rebuilt for the next viewport
		end

		-- ===================================================== once: prices, the skins, scans
		do
			local root = setup(VPS[1])
			ST(state({ pass_auto_punch = true }, false))
			ShopCtl._onQuotes(QUOTES)
			-- Config.Shop.PRICES wins over the skin's fallback
			local had = Config.Shop.PRICES
			Config.Shop.PRICES = { pass_2x_power = 111 }
			ShopCtl.open()
			task.wait()
			local keys = cardKeys(modalFrame("Shop"))
			check(btnText(keys.pass_2x_power, "Buy") == "R$ 111", "Config.Shop.PRICES wins over the skin's price", btnText(keys.pass_2x_power, "Buy"))
			check(btnText(keys.pass_fast_carry, "Buy") == "R$ 149", "a price missing from Config.Shop.PRICES falls back to the skin")
			Config.Shop.PRICES = had
			ShopCtl.close()
			-- both skins have the same keys in every new table
			local stub = Skin.load("stub").Names.ui
			local function same(a, b, path)
				for k, v in pairs(a) do
					check(b[k] ~= nil, "stub skin has " .. path .. "." .. tostring(k))
					if type(v) == "table" and type(b[k]) == "table" then
						same(v, b[k], path .. "." .. tostring(k))
					end
				end
				for k in pairs(b) do
					check(a[k] ~= nil, "brickbrawl skin has " .. path .. "." .. tostring(k))
				end
			end
			for _, k in ipairs({ "shop", "spin", "starter", "prices", "tiles", "reasons" }) do
				same(N.ui[k], stub[k], "ui." .. k)
			end
			-- every shop key has a price and a description
			for k in pairs(EXPECT_CARDS) do
				check(N.ui.prices[k] ~= nil, "price for " .. k)
				check(N.ui.shop.desc[k] ~= nil, "description for " .. k)
			end
			for _, k in ipairs(Ids.SPIN_PRODUCTS) do
				check(N.ui.prices[k] ~= nil, "price for " .. k)
			end
			check(N.ui.shop.desc.spin_card ~= nil, "description for the Spin card")
			-- no urgent, discount or countdown wording anywhere in the new text
			local function walk(t, out)
				for _, v in pairs(t) do
					if type(v) == "string" then
						table.insert(out, string.lower(v))
					elseif type(v) == "table" then
						walk(v, out)
					end
				end
			end
			local texts = {}
			walk(N.ui.shop, texts); walk(N.ui.spin, texts); walk(N.ui.starter, texts)
			local joined = table.concat(texts, " | ")
			for _, bad in ipairs({ "%% off", "limited", "hurry", "last chance", "countdown", "expires", "sale", "discount", "best value", "don't miss", "now or never" }) do
				check(not joined:find(bad), "no '" .. bad .. "' wording in the shop, spin and offer text")
			end
			-- source scans: Shop.Grant is M2-19's remote; no view fires purchases or spins by itself
			local function src(name) return Ui[name].Source end
			check(not src("Shop"):find('"Shop", "Grant"'), "Ui/Shop has no Shop.Grant listener (M2-19's controller wires onGrant)")
			for _, name in ipairs({ "Shop", "Spin", "StarterOffer" }) do
				check(not src(name):find("PromptProductPurchase") and not src(name):find("PromptGamePassPurchase"), "Ui/" .. name .. " never prompts a purchase itself")
			end
			check(src("Spin"):find("SpinTable.ODDS", 1, true) ~= nil, "Ui/Spin reads the one odds table (Shared/SpinTable)")
			check(not src("Spin"):find("percent%s*=%s*%d"), "Ui/Spin holds no odds number of its own")
			for _, name in ipairs({ "Shop", "Spin", "StarterOffer" }) do
				check(not src(name):find("FireServer"), "Ui/" .. name .. " sends no remote itself (the controllers do)")
			end
		end
		print(("ScreensC: smallest text on screen %.1f px"):format(smallest))
	end)
	if not ok then
		failed += 1
		print("ScreensC: ERROR " .. tostring(err))
	end
	for _, g in ipairs(StarterGui:GetChildren()) do if g.Name == "HussHud" then g:Destroy() end end
	print(("ScreensC: %d passed, %d failed"):format(passed, failed))
end
