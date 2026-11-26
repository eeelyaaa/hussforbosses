if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-15: gate rows S10 (the lock shield) and S18 (the attacking set's Shield Breaker part; Quick Hands and Iron Grip
-- are in Steal a/b), the build plan's M2 exit check "attacking set" for the parts that need no purchase. PLAY MODE,
-- installed into ServerStorage.TmpChecks next to CheckLib. A stand-in owner on a cloned check plot (PlotId 8).
--   { phase = "a" }  joining shield 60 s (unbreakable) then the cooldown, then ready; the lock pad raises it (60 s,
--                    90 s with Long Lock); a visitor inside is pushed out; a hold is cancelled when it rises; the
--                    Shield.State payload (breakable, reason, brokenUntil); Shield Breaker with a stored charge:
--                    refusals ('range' past 15 studs, 'state' when down, 'charge', 'joining', 'instant', 'recent'
--                    inside 5 minutes), a break (cooldown, Broken, charge -1, brokenUntil), breakable again after
--                    300 s; BuyBreaker through Systems/Shop with its prompt stubbed (Shop.setPromptFn; Roblox's
--                    dialog never opens): the target held, the receipt (Receipts.process) breaks the shield, a stale
--                    target becomes one stored charge; the M2-18 seam (held target re-checked: breaks, or false for a
--                    stale owner); Instant Shield in the cooldown and over a
--                    running shield; the saved readyAt survives a rejoin; a rebirth's reset clears the cooldown.
-- Every pass forced off with PassOwned first. Leaves the profile wiped, the stand-ins removed and every hook cleared.
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local L = {}
require(game.ServerStorage.TmpChecks.CheckLib)(L)
local Config, Carry, Base, Session = L.Config, L.Carry, L.Base, L.Session
local SSS = game:GetService("ServerScriptService")
local RS = game:GetService("ReplicatedStorage")
local Steal = require(SSS.Systems.Steal)
local Shield = require(SSS.Systems.Shield)
local Plots = require(SSS.Systems.Plots)
local Ids = require(RS.Shared.Ids)
local Shop = require(SSS.Systems.Shop)
local Receipts = require(SSS.Systems.Receipts)
local seam = Plots.seam
local s = L.s

local ctx = L.begin("Shield", ARGS)
local p = ctx.p
local function C(label, ok, detail) return L.check(ctx, label, ok, detail) end

local function passes(extra)
	local parts = {}
	for _, k in ipairs(Ids.SHOP_KEYS) do
		if Ids.isPass(k) then table.insert(parts, k .. "=" .. ((extra and extra[k]) or "off")) end
	end
	L.hook(ctx, "PassOwned", table.concat(parts, ","))
	task.wait(0.1)
end

local PlotsRoot = workspace.Plots
local Plot1 = PlotsRoot.Plot1
local made = {}
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
local stands = {}
local clockAdd = 0
local function clock(n) clockAdd = n; L.hook(ctx, "ShieldClock", n); task.wait(0.1) end

local function rootAt(plot, x, y)
	return seam.plotPoint(plot, x, y, Base.spotPart(plot, 1).Position.Y + 0.5 + L.rootY(ctx))
end
local function resLast(userId, action)
	for i = #Shield.stats.results, 1, -1 do
		local r = Shield.stats.results[i]
		if r.userId == userId and r.action == action then return r end
	end
	return nil
end

-- Roblox's purchase dialog is never opened by this check: the prompt is a stub that records the call
local prompted = {}
Shop.setPromptFn(function(pl, kind, id) table.insert(prompted, { userId = pl.UserId, kind = kind, id = id }) end)
local runTag = game:GetService("HttpService"):GenerateGUID(false):sub(1, 8)
local function fakeReceipt(n)
	local id = Shop.id("product_shield_breaker")
	local d = Receipts.process({ PlayerId = p.UserId, ProductId = id, PurchaseId = "shieldcheck-" .. runTag .. "-" .. n, CurrencySpent = 0 }, { key = "product_shield_breaker" })
	Shop.promptClosed(p, id, true) -- the Finished event a real dialog would send
	return d == Enum.ProductPurchaseDecision.PurchaseGranted
end

local ok, err = pcall(function()
	if Carry.get(p) then Carry.lose(p, "check") end
	L.hook(ctx, "Wipe", true)
	task.wait(0.5)
	passes()
	local P8 = clonePlot(8, -120)
	task.wait(0.2)
	local t0 = Shield.clock()
	local A = seam.addPlayer(-71, {}) -- the normal joining shield
	stands[-71] = A
	C("1 the stand-in owner's base starts with the joining shield", Shield.stateOf(P8) == "joining")
	local pl = Shield.payload(P8)
	C("2 Shield.State: joining, endsAt +60, not breakable ('joining')", pl.state == "joining" and math.abs(pl.endsAt - t0 - 60) < 1 and pl.breakable == false and pl.reason == "joining", s(pl.endsAt - t0))
	-- pushed out
	L.tp(ctx, rootAt(P8, 25, 40))
	task.wait(0.15)
	C("3 a visitor inside a shielded base is pushed out at the entrance", not Carry.insidePlot(P8, ctx.hrp.Position, 0) and Shield.distToPlot(P8, ctx.hrp.Position) < 8, s(Shield.distToPlot(P8, ctx.hrp.Position)))
	-- breaker refusals while joining
	L.hook(ctx, "SetCharges", 3)
	task.wait(0.3)
	C("4 setup: 3 Shield Breaker charges", Session.get(p).breakerCharges == 3)
	C("5 UseCharge on a joining shield: 'joining', no charge used", Shield.tryUseCharge(p, 8) == "joining" and Session.get(p).breakerCharges == 3)
	clock(61)
	task.wait(0.1)
	pl = Shield.payload(P8)
	C("6 after 60 s: cooldown 60 s, readyAt saved", pl.state == "cooldown" and math.abs(pl.readyAt - t0 - 120) < 1.5 and math.abs(Session.get(A).shieldReadyAt - pl.readyAt) < 0.01, s((pl.readyAt or 0) - t0))
	C("7 UseCharge on a shield that is down: 'state'", Shield.tryUseCharge(p, 8) == "state")
	clock(121)
	C("8 after the cooldown: ready", Shield.stateOf(P8) == "ready")
	-- the lock pad
	seam.moveTo(A, P8.LockPad.Position + Vector3.new(0, P8.LockPad.Size.Y / 2 + 3, 0))
	task.wait(0.15)
	local t1 = Shield.clock()
	pl = Shield.payload(P8)
	C("9 the owner steps on the lock pad: up 60 s, breakable", pl.state == "up" and math.abs(pl.endsAt - t1 - 60) < 1 and pl.breakable == true, s((pl.endsAt or 0) - t1))
	seam.moveTo(A, rootAt(P8, 25, 40))
	-- range
	L.tp(ctx, rootAt(P8, 25, -20))
	task.wait(0.1)
	C("10 20 studs from the shield: 'range'", Shield.tryUseCharge(p, 8) == "range")
	C("11 the own plot / a bad id: 'state'", Shield.tryUseCharge(p, 1) == "state" and Shield.tryUseCharge(p, "8") == "state")
	L.tp(ctx, rootAt(P8, 25, -10))
	task.wait(0.1)
	local n0 = #prompted
	local wb = Shield.tryBuyBreaker(p, 8)
	C("12a BuyBreaker in range: the Shop prompts (stub) for the Shield Breaker product", wb == nil and #prompted == n0 + 1 and prompted[#prompted].id == Shop.id("product_shield_breaker"), wb)
	C("12b while that prompt is open a second BuyBreaker is refused 'busy'", Shield.tryBuyBreaker(p, 8) == "busy")
	Shop.promptClosed(p, Shop.id("product_shield_breaker"), false)
	C("12c a cancelled dialog drops the held target", Shield.takeBreakerTarget(p) == nil)
	Shield.tryBuyBreaker(p, 8)
	local charges0 = Session.get(p).breakerCharges
	Shield.forceState(P8, "ready") -- the shield went down while the dialog was open
	Shield.raise(A, "button")
	Shield.forceState(P8, "ready")
	local g1 = fakeReceipt(1)
	C("12d a receipt whose target is no longer breakable: granted as one stored charge", g1 and Session.get(p).breakerCharges == charges0 + 1 and Shield.stateOf(P8) == "ready", s(Session.get(p).breakerCharges - charges0))
	Session.mutate(p, function(q) q.breakerCharges = charges0 end)
	Shield.raise(A, "button")
	Shield.tryBuyBreaker(p, 8)
	local g2 = fakeReceipt(2)
	C("12e a receipt with the held target still breakable: the shield breaks, no charge stored", g2 and Shield.stateOf(P8) == "cooldown" and Session.get(p).breakerCharges == charges0)
	Shield.forceState(P8, "up") -- forceState clears the break record: the UseCharge rows below start fresh
	local tb = Shield.clock()
	C("13 UseCharge 10 studs away: the shield breaks", Shield.tryUseCharge(p, 8) == nil)
	pl = Shield.payload(P8)
	C("14 broken: cooldown at once, charge 3 -> 2, brokenUntil +300", pl.state == "cooldown" and Session.get(p).breakerCharges == 2 and pl.brokenUntil and math.abs(pl.brokenUntil - tb - 300) < 1, s((pl.brokenUntil or 0) - tb))
	local br = Shield.stats.broken[#Shield.stats.broken]
	C("15 Shield.Broken recorded for the owner (by the visitor)", br and br.plotId == 8 and br.by == p.UserId)
	C("16 the owner's shield-broken alert is on (Steal.alertOn)", Steal.alertOn(A) == true)
	clock(121 + 61)
	Shield.raise(A, "button")
	pl = Shield.payload(P8)
	C("17 raised again within 5 minutes: up but not breakable ('recent')", pl.state == "up" and pl.breakable == false and pl.reason == "recent")
	C("18 UseCharge: 'recent', no charge used", Shield.tryUseCharge(p, 8) == "recent" and Session.get(p).breakerCharges == 2)
	C("19 the alert is over after 10 s", Steal.alertOn(A) == false)
	clock(121 + 301)
	task.wait(0.2) -- the old shield ran out and cooled down on the shifted clock
	local wr2 = Shield.raise(A, "button")
	C("20 after 5 minutes: raised and breakable again", wr2 == nil and (Shield.breakable(P8)) == true, wr2)
	-- the M2-18 seam
	local held = { plotId = 8, ownerUserId = -71, at = Shield.clock() }
	C("21 a held target for another owner is not breakable (stored charge instead)", Shield.breakFor(p, { plotId = 8, ownerUserId = -99, at = 0 }) == false)
	C("22 the held target still that owner's and breakable: breakFor breaks it", Shield.canBreakTarget(held) and Shield.breakFor(p, held) == true and Shield.stateOf(P8) == "cooldown")
	-- no charge
	Shield.forceState(P8, "up")
	L.hook(ctx, "SetCharges", 0)
	task.wait(0.3)
	C("23 no charge: 'charge'", Shield.tryUseCharge(p, 8) == "charge")
	L.hook(ctx, "SetCharges", 2)
	task.wait(0.3)
	-- Instant Shield
	Shield.forceState(P8, "cooldown")
	local ti = Shield.clock()
	C("24 Instant Shield during the cooldown: up at once as 'instant', 60 s", Shield.raiseInstant(A) and Shield.stateOf(P8) == "instant" and math.abs(Shield.payload(P8).endsAt - ti - 60) < 1)
	C("25 an Instant Shield cannot be broken ('instant')", Shield.tryUseCharge(p, 8) == "instant" and Session.get(p).breakerCharges == 2)
	Shield.forceState(P8, "ready")
	Shield.raise(A, "button")
	clock(clockAdd + 30)
	local t2 = Shield.clock()
	Shield.raiseInstant(A)
	pl = Shield.payload(P8)
	C("26 an Instant Shield landing on a running shield turns it into one, restarted at 60 s", pl.state == "instant" and math.abs(pl.endsAt - t2 - 60) < 1 and pl.breakable == false)
	C("27 Shield.isUp(owner) for M2-18's 'shieldUp' refusal", Shield.isUp(A) == true)
	-- Long Lock
	passes({ pass_long_lock = "on" })
	Shield.forceState(P8, "ready")
	local t3 = Shield.clock()
	Shield.raise(A, "button")
	C("28 Long Lock: 90 s", math.abs(Shield.payload(P8).endsAt - t3 - 90) < 1)
	passes()
	-- a hold cancelled by the shield rising
	Shield.forceState(P8, "ready")
	local uid = Session.newUid(A)
	Session.mutate(A, function(q) table.insert(q.bosses, { uid = uid, creatureId = "z1_t1", level = 1, spot = 3, padCash = 0, padStamp = L.Zones.now() }) end)
	local sp = Base.spotPart(P8, 3)
	L.tp(ctx, sp.Position + Vector3.new(3, sp.Size.Y / 2 + L.rootY(ctx), 0))
	task.wait(0.1)
	L.hook(ctx, "PolicyTrading", "on")
	local wh = Steal.tryHold(p, 8, uid)
	Shield.raise(A, "pad")
	task.wait(0.15)
	local last
	for i = #Steal.stats.results, 1, -1 do local r = Steal.stats.results[i]; if r.userId == p.UserId then last = r; break end end
	C("29 the shield rising cancels a hold in progress ('shield') and pushes the thief out", wh == nil and last and last.state == "cancelled" and last.reason == "shield" and not Carry.insidePlot(P8, ctx.hrp.Position, 0))
	-- saved cooldown across a rejoin
	Shield.forceState(P8, "ready")
	clock(0)
	Session.mutate(A, function(q) q.shieldReadyAt = Shield.clock() + 500 end)
	seam.removePlayer(A)
	stands[-71] = nil
	local t4 = Shield.clock()
	A = seam.addPlayer(-71, {})
	stands[-71] = A
	C("30 rejoin: the saved readyAt is kept (joining shield first)", Shield.stateOf(P8) == "joining" and Session.get(A).shieldReadyAt > t4 + 400)
	clock(61)
	pl = Shield.payload(P8)
	C("31 after the joining shield the cooldown runs to the saved time, not +60", pl.state == "cooldown" and pl.readyAt and pl.readyAt - t4 > 400, s((pl.readyAt or 0) - t4))
	Shield.resetCooldown(A)
	C("32 a rebirth's reset (Rebirth.onRebirth -> resetCooldown) makes it ready", Shield.stateOf(P8) == "ready")
	-- the real player's own Raise
	Shield.forceState(Plot1, "ready")
	L.tp(ctx, Plot1.SpawnPoint.Position + Vector3.new(0, Plot1.SpawnPoint.Size.Y / 2 + L.rootY(ctx), 0))
	task.wait(0.1)
	C("33 Shield.raise for the real owner inside the base", Shield.raise(p, "button") == nil and Shield.stateOf(Plot1) == "up")
	C("34 Raise when not ready: 'state'", Shield.raise(p, "button") == "state")
	Shield.forceState(Plot1, "ready")
	local _ = resLast
end)
if not ok then C("the check ran to the end", false, tostring(err)) end

Shop.setPromptFn(nil) -- Roblox's dialog again
pcall(function()
	L.hook(ctx, "ShieldClock", nil)
	for id, f in pairs(stands) do pcall(seam.removePlayer, f); stands[id] = nil end
	for _, m in ipairs(made) do m:Destroy() end
	L.hook(ctx, "Wipe", true)
	task.wait(0.4)
	Shield.forceState(Plot1, "ready")
end)
L.finish(ctx)
