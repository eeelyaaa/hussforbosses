if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-19: client probe for Controllers/Shop and Spin. Installed as StarterPlayerScripts.HFB_ShopClientProbe for the check only, removed after.
-- Feeds contract-shaped payloads through the controllers' test seams, sends each line as Profile.TestReport "shc_line", then "shc_done".
-- Buys and spins are sent with _noSend(true): no Shop.Buy or Shop.Spin ever reaches the server, so no prompt and no purchase. Shop.Open (harmless) is sent for real.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local C = script.Parent:WaitForChild("Controllers")
local Shop = require(C:WaitForChild("Shop"))
local Spin = require(C:WaitForChild("Spin"))
local Fight = require(C:WaitForChild("Fight"))
local Carry = require(C:WaitForChild("Carry"))
local Net = require(RS.Shared.Net)
local lp = Players.LocalPlayer
local out = {}
local function chk(ok, label, detail) table.insert(out, { ok = ok == true, l = label, d = tostring(detail or "") }) end
local function send(name, data)
	local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
	if ok then Net.get("Profile", "TestReport"):FireServer({ name = name, json = json:sub(1, 950) }) end
	task.wait(0.15)
end
repeat task.wait(0.5) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and Net.get("Profile", "TestReport")
task.wait(8)
local origFight, origCarry = Fight.active, Carry.info
local ok, err = pcall(function()
	local S0 = Shop.state()
	chk(S0 ~= nil and Spin.state() ~= nil, "a0 both controllers started (AUTO_START)")
	Shop._reset(); Spin._reset()
	Shop._noSend(true); Spin._noSend(true)
	-- z. M2-27-1: before Shop.State everything spin is hidden
	chk(Shop.restricted() and not Spin.available() and select(2, Spin.open()) == "restricted" and select(2, Shop.buy("product_spin_1")) == "restricted", "z1 before Shop.State: restricted, no spin UI, spin product refused")
	Shop._onState({ passes = {}, policy = { randomItemsRestricted = false, tradingAllowed = true }, starterPackGiven = false, promptOpen = false }); Spin._onState({ policy = { randomItemsRestricted = false, tradingAllowed = true } })
	chk(not Shop.restricted() and Spin.available(), "z2 Shop.State unrestricted opens the spin UI")
	-- a. open / close, the real Shop.Open
	Shop._noSend(false)
	local o0 = Shop.state().stats.openSent
	Shop.open()
	chk(Shop.isOpen() and Shop.state().stats.openSent == o0 + 1, "a1 open() marks open and sends Shop.Open once", Shop.state().stats.openSent - o0)
	Shop.close()
	chk(not Shop.isOpen(), "a2 close() closes")
	Shop.toggle(); Shop.toggle()
	chk(not Shop.isOpen(), "a3 toggle twice = closed")
	Shop._noSend(true)
	Fight.active = function() return { fake = true } end
	chk(Shop.open() == false and not Shop.isOpen(), "a4 not opened during a fight")
	Fight.active = origFight
	-- b. quotes and cash packs
	local now = workspace:GetServerTimeNow()
	Shop._onQuotes({ packs = { product_cash_small = { amount = 1234, quoteKey = "qk-live", expiresAt = now + 300 }, product_cash_large = { amount = 99, quoteKey = "qk-old", expiresAt = now - 5 }, junk = 5 } })
	local q = Shop.quoteFor("product_cash_small")
	chk(q and q.amount == 1234 and q.quoteKey == "qk-live", "b1 a live quote is kept as sent", q and q.quoteKey)
	chk(Shop.quoteFor("product_cash_large") == nil, "b2 an expired quote is not offered")
	local b0 = Shop.state().stats.buySent
	local sent, why = Shop.buy("product_cash_large")
	chk(sent == false and why == "stale" and Shop.state().stats.buySent == b0, "b3 buy on an expired quote sends nothing (re-asks)", tostring(why))
	sent, why = Shop.buy("product_cash_medium")
	chk(sent == false and why == "stale", "b4 buy with no quote sends nothing", tostring(why))
	sent = Shop.buy("product_cash_small")
	chk(sent == true and Shop.state().stats.buySent == b0 + 1 and Shop.pending() == "product_cash_small", "b5 buy with a live quote is sent (noSend: not to the server) and pending")
	chk(select(2, Shop.buy("product_cash_small")) == "busy", "b6 a second buy while one is pending is refused (never two)")
	Shop._onGrant({ key = "product_cash_small", ok = false, reason = "cancelled" })
	chk(Shop.pending() == nil and Shop.canAsk() == true, "b7 Shop.Grant clears pending")
	-- c. refusals
	local function reasonOf(key) local _, r = Shop.buy(key) return r end
	chk(reasonOf("not_a_key") == "unknown", "c1 unknown key")
	chk(reasonOf("product_shield_breaker") == "atShield", "c2 Shield Breaker is not bought from the shop")
	Shop._onState({ passes = { pass_auto_punch = true }, policy = { randomItemsRestricted = false, tradingAllowed = true }, starterPackGiven = false, promptOpen = false })
	chk(reasonOf("pass_auto_punch") == "owned" and Shop.owns("pass_auto_punch"), "c3 owned pass refused locally")
	Shop._onState({ passes = {}, policy = { randomItemsRestricted = true, tradingAllowed = true }, starterPackGiven = false, promptOpen = false })
	chk(reasonOf("product_spin_3") == "restricted" and Shop.restricted(), "c4 spin product refused while random items are restricted")
	Shop._onState({ passes = {}, policy = { randomItemsRestricted = false, tradingAllowed = true }, starterPackGiven = false, promptOpen = false })
	chk(Shop.buy("pass_iron_grip") == true, "c5 a pass not owned is sent")
	Shop._onGrant({ key = "pass_iron_grip", ok = true })
	chk(Shop.owns("pass_iron_grip"), "c6 a granted pass is owned at once")
	-- d. the prompt guard
	Fight.active = function() return { fake = true } end
	chk(select(2, Shop.canAsk()) == "fight" and reasonOf("pass_quick_hands") == "fight", "d1 no ask in a fight")
	Fight.active = origFight
	Carry.info = function() return { state = "carrying" } end
	chk(select(2, Shop.canAsk()) == "carry" and reasonOf("pass_quick_hands") == "carry", "d2 no ask while carrying")
	Carry.info = origCarry
	local alert = require(script.Parent.Ui.StealAlert)
	alert.showBroken({ byUserId = lp.UserId })
	task.wait(0.2)
	chk(select(2, Shop.canAsk()) == "alert", "d3 no ask while the shield-broken alert shows", select(2, Shop.canAsk()))
	alert.hideBroken()
	task.wait(0.2)
	chk(Shop.canAsk() == true, "d4 asks again once the alert is gone")
	Shop._onState({ promptOpen = true })
	chk(select(2, Shop.canAsk()) == "busy", "d5 no ask while the server says a prompt is open")
	Shop._onState({ promptOpen = false })
	chk(Shop.canAsk() == true, "d6 asks again after the prompt closed")
	-- e. profile fields
	Shop._onProfile({ spinTickets = 4, breakerCharges = 2, zonesBeaten = { 3, 1, 2, 2, 9 } })
	chk(Shop.spinTickets() == 4 and Shop.breakerCharges() == 2, "e1 Profile.Changed tickets and charges", Shop.spinTickets() .. "/" .. Shop.breakerCharges())
	local z = Shop.zonesBeaten()
	chk(#z == 3 and z[1] == 1 and z[3] == 3, "e2 zonesBeaten sorted, deduped, range-checked", table.concat(z, ","))
	-- f. the starter pack offer
	local drawn = 0
	Shop._onOffer({ key = "pass_starter_pack" })
	task.wait(1.2)
	local hasScreen = script.Parent.Ui:FindFirstChild("StarterOffer") ~= nil
	chk(Shop.state().offerWanted == true or hasScreen, "f1 an offer waits for its screen (not drawn without Ui/StarterOffer)", tostring(hasScreen))
	chk(Shop.state().stats.offerSeenSent == 0 or hasScreen, "f2 OfferSeen is not sent for an offer that was not drawn")
	Shop._onState({ passes = { pass_starter_pack = true } })
	chk(Shop.state().offerWanted == false, "f3 owning the pack drops the waiting offer")
	-- g. Spin controller
	Shop._reset(); Spin._reset()
	Shop._onState({ policy = { randomItemsRestricted = false, tradingAllowed = true } }); Spin._onState({ policy = { randomItemsRestricted = false, tradingAllowed = true } })
	Spin.open(); task.wait(0.5) -- the Spin screen (M2-20) refuses a spin until its odds list is drawn: open it first
	chk(select(2, Spin.spin(1)) == "zone", "g1 no spin with no zone beaten", tostring(select(2, Spin.spin(1))) .. "/" .. tostring(Spin.state().available))
	Spin._onProfile({ zonesBeaten = { 1, 2 }, spinTickets = 0 })
	chk(Spin.selectedZone() == 2 and #Spin.zones() == 2, "g2 zone picker reads zonesBeaten, default the furthest", tostring(Spin.selectedZone()))
	chk(select(2, Spin.spin()) == "tickets", "g3 no ticket, no spin")
	Spin._onProfile({ spinTickets = 2 })
	chk(select(2, Spin.spin(5)) == "zone", "g4 a zone not beaten is refused")
	chk(Spin.selectZone(1) and Spin.selectedZone() == 1 and not Spin.selectZone(6), "g5 selectZone only from the list")
	local s0 = Spin.state().stats.spinSent
	chk(Spin.spin() == true and Spin.state().stats.spinSent == s0 + 1 and Spin.waiting(), "g6 spin sent for the selected zone (noSend)")
	chk(select(2, Spin.spin()) == "busy", "g7 one spin in flight at a time")
	local got
	Spin.onResult(function(r) got = r end)
	Spin._onResult({ ok = true, zone = 1, creatureId = "z1_t4", tier = 4, uid = "u1" })
	task.wait(0.1)
	chk(not Spin.waiting() and got and got.tier == 4 and got.creatureId == "z1_t4", "g8 SpinResult clears waiting and reaches onResult")
	local odds = Spin.odds()
	chk(odds == require(RS.Shared.SpinTable).ODDS and #odds == 6, "g9 the odds list is the server's table itself")
	Spin.close()
	Shop._onState({ policy = { randomItemsRestricted = true, tradingAllowed = true } }); Spin._onState({ policy = { randomItemsRestricted = true, tradingAllowed = true } })
	chk(not Spin.available() and select(2, Spin.open()) == "restricted" and select(2, Spin.spin()) == "restricted", "g10 restricted: Spin UI unavailable, open and spin refused")
	-- h. bad payloads change nothing
	local before = Shop.state().tickets
	Shop._onProfile({ spinTickets = "x" }); Shop._onQuotes("x"); Shop._onGrant(5); Shop._onOffer(nil); Spin._onResult({ ok = "no" })
	chk(Shop.state().tickets == before, "h1 malformed payloads are ignored")
end)
Fight.active, Carry.info = origFight, origCarry
Shop._noSend(false); Spin._noSend(false)
pcall(function() Shop._reset(); Spin._reset() end)
if not ok then chk(false, "probe ran without an error", tostring(err):sub(1, 200)) end
for _, l in ipairs(out) do send("shc_line", { ok = l.ok, l = l.l:sub(1, 120), d = l.d:sub(1, 80) }) end
send("shc_done", { n = #out })
print("SHC|done")
