if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-18: gate rows S13, S17, S20 (Robux part) and the build plan's M2 "Robux" and "attacking set" (Shield Breaker)
-- exit checks. PLAY MODE, installed into ServerStorage.TmpChecks next to CheckLib (CheckAll "install", then this file
-- added from the sync server). No real purchase: Shop.setPromptFn replaces Roblox's dialog for the whole check, and
-- grants go through the FakeReceipt hook (the one ProcessReceipt handler) and the PassOwned hook.
--   { phase = "a" }  receipts (same id once), cash pack quotes (held amount, formula without a prompt, stale and
--                    expired keys), one prompt at a time (cancel and the S3 timeout free it), the guard (carry real;
--                    fight and alert through their module seams), owned / needAuto / Perfect Auto Punch alone, every
--                    pass read through Systems/Passes, a purchase hint confirmed by Roblox, Instant Shield, the
--                    restricted hook (spin products gone, rest unchanged), bad keys.
--   { phase = "b" }  Shield Breaker at the shield: prompt, receipt breaks, 'recent', a late receipt stores a charge, a
--                    client-opened prompt stores a charge, the charge used free, 'joining', 'instant', 'range'; a real
--                    "shield broken" alert blocks prompts; charges kept by rebirth (Config.Rebirth.KEPT).
--   { phase = "c" }  the Starter Pack: offer once after the session's first upgrade, waiting for the guard; OfferSeen
--                    once (StarterPackShown); contents once (cash bought, the Ram with the pack mark); web buyer on
--                    join; the Studio guard (TEAM CALL M2-18-3); a rebirth drops the quotes (S4).
-- Every pass forced through PassOwned (the Studio account owns every real pass). Leaves the profile wiped, stand-ins
-- removed, the prompt seam restored and every hook cleared.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Ids = require(RS.Shared.Ids)
local Config = L.Config
local Net = L.Net
local Session, Carry, Base, Bag, Income = L.Session, L.Carry, L.Base, L.Bag, L.Income
local Shop = require(SSS.Systems.Shop)
local Passes = require(SSS.Systems.Passes)
local Receipts = require(SSS.Systems.Receipts)
local StarterPack = require(SSS.Systems.StarterPack)
local Shield = require(SSS.Systems.Shield)
local Steal = require(SSS.Systems.Steal)
local Plots = require(SSS.Systems.Plots)
local Policy = require(SSS.Systems.Policy)
local Funnel = require(SSS.Systems.Funnel)
local Upgrades = require(SSS.Systems.Upgrades)
local Rebirth = require(SSS.Systems.Rebirth)
local seam = Plots.seam
local s = L.s

local ctx = L.begin("Robux", ARGS)
local p = ctx.p
local function C(label, ok, detail) return L.check(ctx, label, ok, detail) end
local RUN = HttpService:GenerateGUID(false):sub(1, 8)

-- every Shop s2c payload and notice to the real player, in order
local sent = {}
local origFire = Net.fire
Net.fire = function(family, name, player, payload)
	if player == p and (family == "Shop" or (family == "Profile" and name == "Notice")) then
		table.insert(sent, { name = family .. "." .. name, payload = payload, at = os.clock() })
	end
	return origFire(family, name, player, payload)
end
local function lastSent(name, pred, since)
	for i = #sent, (since or 0) + 1, -1 do
		if sent[i].name == name and (not pred or pred(sent[i].payload)) then return sent[i].payload end
	end
	return nil
end
local opened = {}
Shop.setPromptFn(function(pl, kind, id)
	table.insert(opened, { userId = pl.UserId, kind = kind, id = id })
end)

local function passes(extra, omit)
	local parts = {}
	for _, k in ipairs(Ids.PASSES) do
		if k ~= omit then table.insert(parts, k .. "=" .. ((extra and extra[k]) or "off")) end
	end
	L.hook(ctx, "PassOwned", table.concat(parts, ","))
	task.wait(0.15)
end
local function fake(key, pid)
	L.TestHooks.reports.receipt = nil
	L.hook(ctx, "FakeReceipt", key .. (pid and ("," .. pid) or ""))
	return L.waitFor(function()
		local r = L.TestHooks.reports.receipt
		return r and r.key == key and (pid == nil or r.purchaseId == pid) and r or nil
	end, 12)
end
local function prof() return Session.get(p) end
local function close(key, purchased)
	Shop.promptClosed(p, Shop.id(key), purchased == true)
end
local function quote(key) return Shop.quoteOf(p, key) end
local function buy(key, qk) return Shop.buy(p, { key = key, quoteKey = qk }) end
local function freshCheckState()
	if Carry.get(p) then Carry.lose(p, "check") end
	L.hook(ctx, "Wipe", true)
	task.wait(0.6)
	passes()
	L.hook(ctx, "PolicyRandom", "off")
	task.wait(0.1)
end

local PlotsRoot = workspace.Plots
local Plot1 = PlotsRoot.Plot1
local made, stands = {}, {}
local function clonePlot(id, dz)
	local old = PlotsRoot:FindFirstChild("CheckPlot" .. id)
	if old then old:Destroy() end
	local m = Plot1:Clone()
	m.Name = "CheckPlot" .. id
	m:SetAttribute("PlotId", id)
	m:SetAttribute("OwnerUserId", 0)
	m:PivotTo(Plot1:GetPivot() + Vector3.new(0, 0, dz))
	m.Parent = PlotsRoot
	table.insert(made, m)
	return m
end
local function rootAt(plot, x, y)
	return seam.plotPoint(plot, x, y, Base.spotPart(plot, 1).Position.Y + 0.5 + L.rootY(ctx))
end
local function clock(n) L.hook(ctx, "ShieldClock", n); task.wait(0.12) end

local phase = ctx.phase
local ok, err = pcall(function()
	freshCheckState()
	if phase == "a" then
		-- ------------------------------------------------------------------ receipts
		local t0 = prof().spinTickets
		local pid1 = "chk-" .. RUN .. "-1"
		local r1 = fake("product_spin_1", pid1)
		local r2 = fake("product_spin_1", pid1)
		local n = 0
		for _, id in ipairs(prof().purchases) do if id == pid1 then n += 1 end end
		C("1 the same purchase id twice: granted once (tickets +1), both answers PurchaseGranted, the id recorded once", r1 and r2 and r1.decision == "granted" and r2.decision == "granted" and prof().spinTickets == t0 + 1 and n == 1, ("%d -> %d, id x%d"):format(t0, prof().spinTickets, n))
		local lg = Receipts.stats.log[#Receipts.stats.log]
		C("2 the second delivery was answered from the handled list ('already')", lg and lg.purchaseId == pid1 and lg.status == "already", lg and lg.status)
		local r3 = fake("product_spin_10", "chk-" .. RUN .. "-2")
		C("3 Lucky Boss Spin x10: +10 tickets", r3 and r3.decision == "granted" and prof().spinTickets == t0 + 11, prof().spinTickets)
		-- ------------------------------------------------------------------ quotes
		Shop.sendQuotes(p)
		local q = lastSent("Shop.Quotes")
		local okQ = q ~= nil
		local want = { product_cash_small = 2500, product_cash_medium = 10000, product_cash_large = 40000, product_cash_huge = 120000 }
		local detail = {}
		for k, v in pairs(want) do
			local e = q and q.packs[k]
			okQ = okQ and e ~= nil and e.amount == v and #e.quoteKey <= 40 and math.abs(e.expiresAt - workspace:GetServerTimeNow() - 300) < 2
			table.insert(detail, k:sub(14) .. "=" .. (e and e.amount or "nil"))
		end
		C("4 Shop.Quotes: four packs at their minimums (no bosses), each with a key valid 300 s", okQ, table.concat(detail, " "))
		-- with income: the formula is seconds x income (2x Cash and rebirth included)
		L.hook(ctx, "GrantBoss", "z3_t3,to=1,level=5")
		L.waitFor(function() return #prof().bosses == 1 end, 3)
		local ips = Shop.incomePerSecond(p)
		local exp = math.max(2500, math.floor(ips * 900))
		C("5 a pack's amount is 15 min of the placed bosses' income, at least the minimum", ips > 0 and Shop.amountFor(p, "product_cash_small") == exp and Shop.amountFor(p, "product_cash_huge") == math.max(120000, math.floor(ips * 43200)), ("%s/s -> small %s"):format(s(ips), s(exp)))
		passes({ pass_2x_cash = "on" })
		C("6 2x Cash doubles the income the packs read", math.abs(Shop.incomePerSecond(p) - 2 * ips) < 1e-6, s(Shop.incomePerSecond(p)))
		passes()
		L.hook(ctx, "Wipe", true)
		task.wait(0.6)
		passes()
		-- held amount
		Shop.sendQuotes(p)
		local qs = quote("product_cash_small")
		local nOpen = #opened
		local cash0, bought0 = prof().cash, prof().boughtCash
		C("7 Buy a cash pack with its live key: the server prompts (product, the pack's id)", buy("product_cash_small", qs.quoteKey) == nil and #opened == nOpen + 1 and opened[#opened].id == Shop.id("product_cash_small") and opened[#opened].kind == "product")
		local st = lastSent("Shop.State")
		C("8 Shop.State says a prompt is open", st and st.promptOpen == true)
		local qm = quote("product_cash_medium")
		C("9 never two prompts: a second Buy while one is open is 'busy', nothing opened", buy("product_cash_medium", qm.quoteKey) == "busy" and #opened == nOpen + 1 and lastSent("Profile.Notice", function(x) return x.kind == "promptBusy" end) ~= nil)
		local oldMin = Config.Shop.PACKS.product_cash_small.min
		Config.Shop.PACKS.product_cash_small.min = 7777
		local r4 = fake("product_cash_small", "chk-" .. RUN .. "-3")
		close("product_cash_small", true)
		C("10 the receipt grants the amount held at the prompt (2,500), not today's formula (7,777); as bought cash", r4 and r4.decision == "granted" and prof().cash == cash0 + 2500 and prof().boughtCash == bought0 + 2500, ("cash +%s bought +%s"):format(s(prof().cash - cash0), s(prof().boughtCash - bought0)))
		local g = lastSent("Shop.Grant", function(x) return x.key == "product_cash_small" end)
		C("11 Shop.Grant ok with the amount", g and g.ok == true and g.amount == 2500)
		local r5 = fake("product_cash_small", "chk-" .. RUN .. "-4")
		C("12 a receipt with no server prompt (client-opened) grants the formula at receipt time", r5 and r5.decision == "granted" and prof().cash == cash0 + 2500 + 7777, s(prof().cash - cash0))
		Config.Shop.PACKS.product_cash_small.min = oldMin
		C("13 the prompt closed: no prompt open", Shop.promptOpen(p) == nil)
		-- stale and expired keys
		Shop.sendQuotes(p)
		local before = quote("product_cash_small").quoteKey
		nOpen = #opened
		C("14 a wrong key: 'stale', new quotes sent, quoteStale notice, nothing opened", buy("product_cash_small", "not-the-key") == "stale" and quote("product_cash_small").quoteKey ~= before and #opened == nOpen and lastSent("Profile.Notice", function(x) return x.kind == "quoteStale" end) ~= nil)
		C("15 no key at all: 'stale'", buy("product_cash_small", nil) == "stale" and #opened == nOpen)
		local qe = quote("product_cash_small")
		qe.expiresAt = workspace:GetServerTimeNow() - 1
		C("16 the right key after 5 minutes: 'stale'", buy("product_cash_small", qe.quoteKey) == "stale" and #opened == nOpen)
		-- cancel and timeout free the prompt
		local qm2 = quote("product_cash_medium")
		C("17 Buy medium opens", buy("product_cash_medium", qm2.quoteKey) == nil and #opened == nOpen + 1)
		close("product_cash_medium", false)
		local gc = lastSent("Shop.Grant", function(x) return x.key == "product_cash_medium" end)
		C("18 cancelled: Shop.Grant 'cancelled', the held amount dropped, the prompt free", gc and gc.ok == false and gc.reason == "cancelled" and Shop.takeHeld(p, "product_cash_medium") == nil and Shop.promptOpen(p) == nil)
		C("19 Buy again after the cancel opens", buy("product_cash_medium", quote("product_cash_medium").quoteKey) == nil)
		local oldT = Config.Shop.PROMPT_TIMEOUT_S
		Config.Shop.PROMPT_TIMEOUT_S = 0.3
		task.wait(0.45)
		C("20 S3: a Finished event that never comes frees the player after the timeout", Shop.promptOpen(p) == nil and buy("pass_2x_power") == nil)
		Config.Shop.PROMPT_TIMEOUT_S = oldT
		close("pass_2x_power", false)
		-- the guard
		L.hook(ctx, "GrantBoss", "z1_t1")
		L.waitFor(function() return Carry.get(p) ~= nil end, 3)
		nOpen = #opened
		C("21 no prompt during a carry: 'busy' (real carry)", Carry.get(p) ~= nil and Shop.busyReason(p) == "carry" and buy("pass_2x_power") == "busy" and #opened == nOpen)
		Carry.lose(p, "check")
		task.wait(0.1)
		local origGet = L.Fight.get
		L.Fight.get = function() return { fightId = 0 } end
		C("22 no prompt during a fight: 'busy' (Fight.get seam)", Shop.busyReason(p) == "fight" and buy("pass_2x_power") == "busy" and #opened == nOpen)
		L.Fight.get = origGet
		local origAlert = Steal.alertOn
		Steal.alertOn = function() return true end
		C("23 no prompt during a steal or shield-broken alert: 'busy' (Steal.alertOn seam; real alert in phase b)", Shop.busyReason(p) == "alert" and buy("pass_2x_power") == "busy" and #opened == nOpen)
		Steal.alertOn = origAlert
		C("24 guard clear: the pass prompt opens (kind pass)", Shop.busyReason(p) == nil and buy("pass_2x_power") == nil and opened[#opened].kind == "pass" and opened[#opened].id == Shop.id("pass_2x_power"))
		close("pass_2x_power", false)
		C("25 Shield Breaker is never bought through Shop.Buy ('state': bought at the shield)", buy("product_shield_breaker") == "state")
		-- passes
		passes({ pass_2x_power = "on" })
		C("26 an owned pass: 'owned'", buy("pass_2x_power") == "owned")
		passes()
		nOpen = #opened
		C("27 Perfect Auto Punch without Auto Punch: 'needAuto', nothing opened", buy("pass_perfect_auto_punch") == "needAuto" and #opened == nOpen)
		passes({ pass_auto_punch = "on" })
		C("28 Perfect Auto Punch with Auto Punch: the prompt opens", buy("pass_perfect_auto_punch") == nil and opened[#opened].id == Shop.id("pass_perfect_auto_punch"))
		close("pass_perfect_auto_punch", false)
		passes({ pass_perfect_auto_punch = "on" })
		C("29 Perfect Auto Punch bought on the web, no Auto Punch: auto and Perfect both usable", Bag.autoOwned(p) and Bag.perfectOwned(p) and not Passes.owns(p, "pass_auto_punch"))
		local allOk, bad = true, {}
		for _, k in ipairs(Ids.PASSES) do
			passes({ [k] = "on" })
			local others = false
			for _, k2 in ipairs(Ids.PASSES) do if k2 ~= k and Bag.owns(p, k2) then others = true end end
			if not (Bag.owns(p, k) and Passes.owns(p, k) and not others and Passes.source(p, k) == "hook") then allOk = false; table.insert(bad, k) end
		end
		C("30 each of the 10 passes is read through Systems/Passes (Bag.owns follows it, one at a time)", allOk, table.concat(bad, ","))
		passes({ pass_fast_carry = "on", pass_2x_cash = "on", pass_extra_spots = "on" })
		local m1 = Income.mult(p)
		C("31 pass effects through the cache: Fast Carry 16, 2x Cash x2, Extra Spots unlocks 16 and 17", Carry.speed(p) == Config.Carry.FAST_CARRY and m1 == 2 * Income.rebirthMult(prof().rebirths) and Base.unlocked(p)[16] == true and Base.unlocked(p)[17] == true, ("%s %s"):format(s(Carry.speed(p)), s(m1)))
		passes()
		C("32 and back off: 12, x1, 16 locked", Carry.speed(p) == Config.Carry.CARRY and Income.mult(p) == Income.rebirthMult(prof().rebirths) and Base.unlocked(p)[16] ~= true)
		local nk = 0
		L.waitFor(function()
			nk = 0
			for _ in pairs(Passes.stats.roblox[p.UserId] or {}) do nk += 1 end
			return nk == 10
		end, 6)
		C("33 on join every pass was asked of Roblox (10 answers cached)", nk == 10, nk)
		-- a purchase hint: the hook names the pass off -> not owned; no hook entry -> Roblox confirms
		local sN = #sent
		fake("pass_iron_grip")
		task.wait(0.3)
		C("34 a purchase hint alone never makes a pass owned (PassOwned says off)", not Passes.owns(p, "pass_iron_grip") and lastSent("Shop.Grant", function(x) return x.key == "pass_iron_grip" and x.ok end, sN) == nil)
		passes(nil, "pass_iron_grip")
		local asks = Passes.stats.asks
		fake("pass_iron_grip")
		local conf = L.waitFor(function() return Passes.owns(p, "pass_iron_grip") end, 12)
		C("35 a hint confirmed by UserOwnsGamePassAsync (the test account owns it): owned, Shop.Grant ok", conf and Passes.stats.asks > asks and Passes.source(p, "pass_iron_grip") == "roblox" and lastSent("Shop.Grant", function(x) return x.key == "pass_iron_grip" and x.ok end) ~= nil, Passes.stats.asks - asks)
		passes()
		-- Instant Shield
		C("36 Instant Shield while the base's shield is up (joining): 'shieldUp'", Shield.isUp(p) and buy("product_instant_shield") == "shieldUp")
		local r6 = fake("product_instant_shield", "chk-" .. RUN .. "-5")
		C("37 an Instant Shield receipt: the base gets the unbreakable instant shield after the write", r6 and r6.decision == "granted" and Shield.stateOf(Plots.of(p)) == "instant", Shield.stateOf(Plots.of(p)))
		-- restricted
		L.hook(ctx, "PolicyRandom", "on")
		task.wait(0.3)
		st = lastSent("Shop.State")
		C("38 restricted: Shop.State carries policy.randomItemsRestricted = true", st and st.policy.randomItemsRestricted == true)
		C("39 restricted: the three spin products are refused 'restricted', nothing opened", buy("product_spin_1") == "restricted" and buy("product_spin_3") == "restricted" and buy("product_spin_10") == "restricted")
		Shop.sendQuotes(p)
		local qr = lastSent("Shop.Quotes")
		C("40 restricted: the rest of the shop is unchanged (4 quotes, a cash pack and a pass open)", qr and qr.packs.product_cash_large ~= nil and buy("product_cash_large", quote("product_cash_large").quoteKey) == nil)
		close("product_cash_large", false)
		C("41 restricted: a pass still opens", buy("pass_long_lock") == nil)
		close("pass_long_lock", false)
		local tk, cr = prof().spinTickets, #prof().crate
		local r7 = fake("product_spin_3", "chk-" .. RUN .. "-6")
		C("42 restricted: a late spin receipt becomes kept tickets (+3), never a spin", r7 and r7.decision == "granted" and prof().spinTickets == tk + 3 and #prof().crate == cr)
		L.hook(ctx, "PolicyRandom", "off")
		task.wait(0.2)
		C("43 not restricted: a spin product opens", buy("product_spin_1") == nil)
		close("product_spin_1", false)
		-- bad input
		nOpen = #opened
		local b1 = Shop.buy(p, { key = "nope" })
		local b2 = Shop.buy(p, { key = 5 })
		local b3 = Shop.buy(p, { key = "product_cash_small", quoteKey = string.rep("x", 41) })
		local b4 = Shop.buy(p, { key = "product_cash_small", quoteKey = 12 })
		C("44 malformed Buy (unknown key, number key, long or number quoteKey): 'bad', nothing opened", b1 == "bad" and b2 == "bad" and b3 == "bad" and b4 == "bad" and #opened == nOpen)
		C("45 the 19 shop keys all have a Roblox id (Config.Shop.IDS)", (function() for _, k in ipairs(Ids.SHOP_KEYS) do if Shop.id(k) <= 0 then return false end end return #Ids.SHOP_KEYS == 19 end)())
		C("46 every product id maps back to its key (the handler's lookup)", (function() for _, k in ipairs(Ids.PRODUCTS) do if Receipts.keyFor(Shop.id(k)) ~= k then return false end end return Receipts.keyFor(123) == nil end)())
		-- M2-27 SF2: the held amount survives a failed write
		L.hook(ctx, "Wipe", true)
		task.wait(0.6)
		passes()
		Shop.sendQuotes(p)
		local c1 = prof().cash
		buy("product_cash_small", quote("product_cash_small").quoteKey)
		local oldMin2 = Config.Shop.PACKS.product_cash_small.min
		Config.Shop.PACKS.product_cash_small.min = 7777
		local origRec = Session.recordPurchase
		Session.recordPurchase = function() return "retry" end
		local pidF = "chk-" .. RUN .. "-sf2"
		local rf = fake("product_cash_small", pidF)
		Session.recordPurchase = origRec
		C("47 SF2: a receipt whose write fails is NotProcessedYet, nothing granted, the held 2,500 kept", rf and rf.decision == "notYet" and prof().cash == c1 and Shop.peekHeld(p, "product_cash_small") == 2500)
		local rg = fake("product_cash_small", pidF)
		C("48 SF2: the redelivered receipt grants the held 2,500 (not the formula 7,777), then the hold is cleared", rg and rg.decision == "granted" and prof().cash == c1 + 2500 and Shop.peekHeld(p, "product_cash_small") == nil, s(prof().cash - c1))
		Config.Shop.PACKS.product_cash_small.min = oldMin2
		close("product_cash_small", true)
		-- M2-27 SF3: a failed pass check on join is unknown, retried in the background and on demand
		local oldGap, oldTries = Config.Shop.PASS_RETRY_GAP_S, Config.Shop.PASS_RETRY_TRIES
		Config.Shop.PASS_RETRY_GAP_S = 0.3
		passes(nil, "pass_2x_cash")
		local failN = 0
		Passes.setAskFn(function(_pl, id)
			if id == Shop.id("pass_2x_cash") and failN < 2 then failN += 1; return false, "test failure" end
			return true, true
		end)
		Passes.refetch(p)
		task.wait(0.1)
		C("49 SF3: the join check failed: 2x Cash unknown, read as not owned", Passes.unknown(p, "pass_2x_cash") and not Passes.owns(p, "pass_2x_cash"))
		local back = L.waitFor(function() return Passes.owns(p, "pass_2x_cash") end, 4)
		C("50 SF3: asked again in the background (gap 0.3 s, then 0.6 s): owned, no longer unknown, income doubled", back and not Passes.unknown(p, "pass_2x_cash") and failN == 2 and Income.mult(p) == 2 * Income.rebirthMult(prof().rebirths), failN)
		Config.Shop.PASS_RETRY_TRIES = 1
		failN = 0
		Passes.setAskFn(function(_pl, id)
			if id == Shop.id("pass_2x_cash") and failN < 2 then failN += 1; return false, "test failure" end
			return true, true
		end)
		Passes.refetch(p)
		task.wait(0.5)
		local stillUnknown = Passes.unknown(p, "pass_2x_cash")
		Passes.retryFailed(p) -- what Shop.Open calls
		local back2 = L.waitFor(function() return Passes.owns(p, "pass_2x_cash") end, 2)
		C("51 SF3: with the background tries spent, opening the shop asks again (on demand): owned", stillUnknown and back2 and not Passes.unknown(p, "pass_2x_cash"))
		Passes.setAskFn(nil)
		Config.Shop.PASS_RETRY_GAP_S, Config.Shop.PASS_RETRY_TRIES = oldGap, oldTries
		Passes.refetch(p) -- the real answers back
		task.wait(1.5)
		passes()
		-- M2-27 SF4 (Systems/Bag): a level is one mutate with the bought-cash rule
		L.hook(ctx, "Wipe", true)
		task.wait(0.6)
		passes()
		L.hook(ctx, "SetCash", 1000)
		task.wait(0.2)
		L.hook(ctx, "SetBoughtCash", 1000)
		task.wait(0.3)
		local origNear = Bag.nearOwnPad
		Bag.nearOwnPad = function() return true end
		local origMut = Session.mutate
		local muts = 0
		Session.mutate = function(pl, fn, tok)
			local b = Session.get(pl)
			local l0, c0 = b and b.strengthLevel, b and b.cash
			local r = origMut(pl, fn, tok)
			local a = Session.get(pl)
			if a and (a.strengthLevel ~= l0 or a.cash ~= c0) then muts += 1 end -- the funnel's flag write is not counted
			return r
		end
		local lv0, cash2, bc2 = prof().strengthLevel, prof().cash, prof().boughtCash
		local cost = Config.Bag.nextStrengthCost(lv0)
		Bag.buyStrength(p, {})
		Session.mutate = origMut
		C("52 SF4: buying a Strength level is ONE mutate that changes level or cash: level +1 and the cost spent together", muts == 1 and prof().strengthLevel == lv0 + 1 and prof().cash == cash2 - cost, ("%d mutate(s), cost %s"):format(muts, s(cost)))
		C("53 SF4: the bought-cash rule holds (all cash bought: boughtCash falls with cash)", bc2 == 1000 and prof().boughtCash == prof().cash, ("%s / %s"):format(s(prof().boughtCash), s(prof().cash)))
		Session.mutate = function() return false end
		local lv1, cash3, bc3 = prof().strengthLevel, prof().cash, prof().boughtCash
		Bag.buyStrength(p, {})
		Session.mutate = origMut
		local res = Bag.stats.lastResult[p.UserId]
		C("54 SF4: a refused mutate changes nothing (no spend, no refund as earned cash): 'state'", res and res.ok == false and res.reason == "state" and prof().strengthLevel == lv1 and prof().cash == cash3 and prof().boughtCash == bc3)
		L.hook(ctx, "SetCash", 10)
		task.wait(0.3)
		Bag.buyStrength(p, {})
		res = Bag.stats.lastResult[p.UserId]
		C("55 SF4: too little cash: 'cash', nothing changed", res and res.reason == "cash" and prof().strengthLevel == lv1)
		Bag.nearOwnPad = origNear
	elseif phase == "b" then
		local P8 = clonePlot(8, -120)
		local P2 = clonePlot(2, -240)
		task.wait(0.2)
		local A = seam.addPlayer(-91, { shield = "ready" })
		stands[#stands + 1] = A
		C("1 setup: the stand-in owner holds plot 8, shield ready", Plots.of(A) == P8 and Shield.stateOf(P8) == "ready", Shield.stateOf(P8))
		Shield.raise(A, "button")
		C("2 the owner raises the shield: up, breakable", Shield.stateOf(P8) == "up" and (Shield.breakable(P8)) == true)
		L.tp(ctx, rootAt(P8, 25, -10))
		task.wait(0.15)
		local nOpen = #opened
		C("3 Break shield at 10 studs: Shield.BuyBreaker prompts through Shop.prompt", Shield.tryBuyBreaker(p, 8) == nil and #opened == nOpen + 1 and opened[#opened].id == Shop.id("product_shield_breaker"))
		local c0 = prof().breakerCharges
		local nb = #Shield.stats.broken
		local r1 = fake("product_shield_breaker", "chk-" .. RUN .. "-b1")
		close("product_shield_breaker", true)
		local br = Shield.stats.broken[#Shield.stats.broken]
		C("4 the receipt breaks the held target after the write: cooldown, by the buyer, no charge stored", r1 and r1.decision == "granted" and #Shield.stats.broken == nb + 1 and br.plotId == 8 and br.by == p.UserId and Shield.stateOf(P8) == "cooldown" and prof().breakerCharges == c0)
		local g = lastSent("Shop.Grant", function(x) return x.key == "product_shield_breaker" end)
		C("5 Shop.Grant ok, not a charge", g and g.ok and not g.charge)
		clock(61)
		Shield.raise(A, "button")
		C("6 raised again within 5 minutes: 'recent', nothing prompted", Shield.stateOf(P8) == "up" and Shield.tryBuyBreaker(p, 8) == "recent" and #opened == nOpen + 1)
		clock(302)
		Shield.raise(A, "button")
		C("7 after 5 minutes: breakable again", Shield.stateOf(P8) == "up" and (Shield.breakable(P8)) == true)
		C("8 Break shield prompts again (target held)", Shield.tryBuyBreaker(p, 8) == nil)
		-- somebody broke it before the purchase arrived (here: the visitor's own charge)
		L.hook(ctx, "SetCharges", 1)
		task.wait(0.3)
		Shield.tryUseCharge(p, 8)
		C("9 setup: the shield broke before the receipt (a charge used, 1 -> 0)", Shield.stateOf(P8) == "cooldown" and prof().breakerCharges == 0)
		nb = #Shield.stats.broken
		local r2 = fake("product_shield_breaker", "chk-" .. RUN .. "-b2")
		close("product_shield_breaker", true)
		g = lastSent("Shop.Grant", function(x) return x.key == "product_shield_breaker" end)
		C("10 a receipt that arrives too late: saved as one Shield Breaker charge, nothing broken", r2 and r2.decision == "granted" and prof().breakerCharges == 1 and #Shield.stats.broken == nb and g and g.charge == true)
		C("11 the breakerCharged notice with the count", lastSent("Profile.Notice", function(x) return x.kind == "breakerCharged" and x.n == 1 end) ~= nil)
		local r3 = fake("product_shield_breaker", "chk-" .. RUN .. "-b3")
		C("12 a client-opened Breaker prompt (no held target): one charge (1 -> 2)", r3 and r3.decision == "granted" and prof().breakerCharges == 2)
		clock(700)
		Shield.raise(A, "button")
		nOpen = #opened
		C("13 the stored charge is used free on the next press: breaks, 2 -> 1, no prompt", Shield.tryUseCharge(p, 8) == nil and prof().breakerCharges == 1 and #opened == nOpen and Shield.stateOf(P8) == "cooldown")
		local B = seam.addPlayer(-92, {})
		stands[#stands + 1] = B
		L.tp(ctx, rootAt(P2, 25, -10))
		task.wait(0.15)
		C("14 a joining shield: 'joining', nothing prompted", Plots.of(B) == P2 and Shield.tryBuyBreaker(p, 2) == "joining" and #opened == nOpen, Plots.of(B) and Plots.of(B).Name)
		Shield.raiseInstant(A)
		L.tp(ctx, rootAt(P8, 25, -10))
		task.wait(0.15)
		C("15 an Instant Shield: 'instant'", Shield.tryBuyBreaker(p, 8) == "instant" and #opened == nOpen)
		clock(1400)
		Shield.raise(A, "button")
		L.tp(ctx, rootAt(P8, 25, -20))
		task.wait(0.15)
		C("16 20 studs from the shield: 'range'", Shield.tryBuyBreaker(p, 8) == "range" and #opened == nOpen)
		-- a real "shield broken" alert on the buyer blocks every prompt
		local myPlot = Plots.of(p)
		Shield.raise(p, "button")
		C("17 setup: the real player's own shield is up", Shield.stateOf(myPlot) == "up", Shield.stateOf(myPlot))
		Shield.breakFor(A, { plotId = myPlot:GetAttribute("PlotId"), ownerUserId = p.UserId, at = Shield.clock() })
		C("18 the real player's shield broken by a visitor: the alert is on and Buy is 'busy' (alert)", Shield.brokenAlertOn(p) and Steal.alertOn(p) and Shop.busyReason(p) == "alert" and buy("pass_2x_power") == "busy")
		clock(1412)
		C("19 the alert over: the guard clears", not Shield.brokenAlertOn(p) and Shop.busyReason(p) == nil)
		C("20 Shield Breaker charges and spin tickets are kept by rebirth (Config.Rebirth.KEPT)", table.find(Config.Rebirth.KEPT, "breakerCharges") ~= nil and table.find(Config.Rebirth.KEPT, "spinTickets") ~= nil)
	elseif phase == "c" then
		local KEY = "pass_starter_pack"
		local offers0 = #StarterPack.stats.offers
		C("1 no offer before an upgrade; OfferSeen before the offer is refused", not StarterPack.offeredThisSession(p) and StarterPack.offerSeen(p, { key = KEY }) == false)
		L.hook(ctx, "GrantBoss", "z1_t1,to=1")
		L.waitFor(function() return #prof().bosses == 1 end, 3)
		L.hook(ctx, "SetCash", 1e6)
		task.wait(0.2)
		local uid = prof().bosses[1].uid
		L.tp(ctx, L.onPart(ctx, Base.spotPart(Plots.of(p), 1), 0, 0))
		task.wait(0.2)
		local origAlert = Steal.alertOn
		Steal.alertOn = function() return true end
		local up1 = Upgrades.tryUpgrade(p, uid)
		task.wait(1.6)
		C("2 the first upgrade during an alert: no offer yet (it waits for the guard)", up1 == nil and #StarterPack.stats.offers == offers0 and lastSent("Shop.Offer") == nil, tostring(up1))
		Steal.alertOn = origAlert
		local got = L.waitFor(function() return lastSent("Shop.Offer") end, 3)
		C("3 the guard clear: Shop.Offer { key = pass_starter_pack } once", got and got.key == KEY and #StarterPack.stats.offers == offers0 + 1)
		Upgrades.tryUpgrade(p, uid)
		task.wait(1.3)
		C("4 a second upgrade: no second offer this session", #StarterPack.stats.offers == offers0 + 1)
		-- the real client (M2-19/M2-20) may already have answered the offer with Shop.OfferSeen: accepted once in all
		local firstByClient = Funnel.has(p, "StarterPackShown")
		local badRefused = StarterPack.offerSeen(p, { key = "pass_2x_power" }) == false
		local mine = StarterPack.offerSeen(p, { key = KEY })
		local again = StarterPack.offerSeen(p, { key = KEY })
		C("5 OfferSeen: a bad key refused, the right key accepted exactly once (by the client or here; StarterPackShown), a repeat refused", badRefused and (mine ~= firstByClient) and again == false and Funnel.has(p, "StarterPackShown"), firstByClient and "seen first by the real client" or "seen here")
		-- the contents
		local cash0, bought0, crate0 = prof().cash, prof().boughtCash, #prof().crate
		passes({ [KEY] = "on" })
		L.waitFor(function() return prof().starterPackGiven end, 10)
		local ram
		for _, b in ipairs(prof().crate) do if b.creatureId == "z1_t4" then ram = b end end
		C("6 Starter Pack owned: $5,000 as bought cash, starterPackGiven", prof().starterPackGiven and prof().cash == cash0 + 5000 and prof().boughtCash == bought0 + 5000, s(prof().cash - cash0))
		C("7 the Headbutt Ram (z1_t4) in the crate with the pack mark and the buyer", ram and ram.bought and ram.bought.source == "pack" and ram.bought.buyer == p.UserId and #prof().crate == crate0 + 1)
		C("8 recorded under the starter id with the Ram's uid (the write came first)", ram ~= nil and table.find(prof().purchases, Config.Shop.STARTER_RECORD_ID .. ":" .. ram.uid) ~= nil)
		local gs = lastSent("Shop.Grant", function(x) return x.key == KEY and x.uid ~= nil end)
		C("9 Shop.Grant ok with the cash and the uid", gs and gs.ok and gs.amount == 5000 and gs.uid == ram.uid)
		passes()
		passes({ [KEY] = "on" })
		task.wait(1)
		C("10 owned again (hook off then on): not granted twice", #prof().crate == crate0 + 1 and prof().cash == cash0 + 5000)
		C("11 Buy the Starter Pack when owned: 'owned'", buy(KEY) == "owned")
		C("12 no offer once bought", not (function() StarterPack.offer(p); return #StarterPack.stats.offers > offers0 + 1 end)())
		-- web buyer: owned, contents not given, joins
		L.hook(ctx, "Wipe", true)
		task.wait(0.6)
		C("13 setup: a fresh profile (starterPackGiven false) with the pass owned", prof() and prof().starterPackGiven == false)
		L.hook(ctx, "Leave", true)
		L.waitFor(function() return Session.get(p) == nil end, 10)
		L.hook(ctx, "Rejoin", true)
		L.waitFor(function() return Session.get(p) ~= nil and Session.state(p) == "live" end, 15)
		L.waitFor(function() return prof() and prof().starterPackGiven end, 10)
		local ram2
		for _, b in ipairs(prof().crate) do if b.creatureId == "z1_t4" and b.bought and b.bought.source == "pack" then ram2 = b end end
		C("14 a web-page buyer gets the contents on join (cash, the Ram, given)", prof().starterPackGiven and ram2 ~= nil and prof().boughtCash >= 5000, Session.state(p))
		-- the Studio guard: Roblox's own answer (the test account owns the pass) never grants in Studio
		passes(nil, KEY)
		L.hook(ctx, "Wipe", true)
		task.wait(0.6)
		local skipped = #StarterPack.stats.skipped
		L.hook(ctx, "Leave", true)
		L.waitFor(function() return Session.get(p) == nil end, 10)
		L.hook(ctx, "Rejoin", true)
		L.waitFor(function() return Session.get(p) ~= nil and Session.state(p) == "live" end, 15)
		task.wait(1.5)
		C("15 TEAM CALL M2-18-3: in Studio Roblox's answer alone (owned: " .. tostring(Passes.owns(p, KEY)) .. ") grants nothing", prof().starterPackGiven == false and #StarterPack.stats.skipped > skipped)
		passes()
		-- S4: a rebirth drops the quotes
		Shop.sendQuotes(p)
		local had = quote("product_cash_huge") ~= nil
		L.hook(ctx, "SetPower", Config.Rebirth.REQUIRED[1] + 1)
		task.wait(0.3)
		local rr = Rebirth.request(p, { confirmed = true })
		task.wait(0.2)
		C("16 S4: a rebirth drops the cash pack quotes (a pre-rebirth key is stale)", had and rr and rr.ok and quote("product_cash_huge") == nil, rr and tostring(rr.reason))
	end
end)
if not ok then C("the check ran to the end", false, tostring(err)) end
pcall(function()
	if Carry.get(p) then Carry.lose(p, "check") end
	for _, st in ipairs(stands) do pcall(seam.removePlayer, st) end
	for _, m in ipairs(made) do m:Destroy() end
	if Shop.promptOpen(p) then local pr = Shop.promptOpen(p); Shop.promptClosed(p, pr.id, false) end
	workspace:SetAttribute("HFB_Wipe", true)
	task.wait(0.4)
end)
Shop.setPromptFn(nil)
Net.fire = origFire
L.finish(ctx)
