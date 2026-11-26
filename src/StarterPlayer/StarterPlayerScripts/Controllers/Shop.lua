--!nonstrict
-- Controllers/Shop (M2-19; brief system 13; m2-contract.md C "Shop", TEAM CALL M2-P5): the client of the shop. It asks and shows;
-- the SERVER prompts every purchase and decides every refusal (Shop.Buy). Nothing here is a price, an amount or a grant.
--   * Open / close: B (keyboard), D-pad up (gamepad), the Shop tile (touch / mouse; the tile's text is Names.ui.tiles.shop, built
--     here only when the skin has it, else Ui/Shop builds its own tile and calls Shop.toggle). Gamepad B closes. Opening sends
--     Shop.Open {} (the server answers Shop.Quotes and Shop.State). Not opened during a fight (the tiles hide then too).
--   * Quotes: Shop.quoteFor(key) -> { amount, quoteKey, expiresAt } for a cash pack. Refreshed while the shop is open when a quote is
--     about to run out; Buy on an expired quote re-asks instead of sending a stale key.
--   * Buy: Shop.buy(key) -> ok, reason. Local checks only spare a round trip (key known, pass owned, spin while restricted, a cash
--     pack with no live quote, the prompt guard below); the server re-checks every one.
--   * The client half of the prompt guard: Shop.canAsk() -> ok, reason is false in a fight, while carrying a boss, while a steal alert or
--     the shield-broken alert shows (Ui/StealAlert.isOn), while one prompt is already open or just asked. The server enforces it too.
--   * Starter Pack: on Shop.Offer, Ui/StarterOffer.show() once the boss panel is closed and nothing blocks; when it reports drawn, send
--     Shop.OfferSeen {key} once. Never shown when the pass is owned.
--   * Profile.Changed: spinTickets, breakerCharges, zonesBeaten (Spin reads them through here too).
-- The screens (Ui/Shop, Ui/StarterOffer, M2-20) subscribe and read: Shop.onChange(fn) (any state, quote, ticket or pending change),
-- Shop.onGrant(fn(p)) (a Shop.Grant payload), Shop.onOpenChanged(fn(open)). A screen module may expose open()/close()/isOpen() (called
-- here; its X and the tile call Shop.close()/toggle()), and StarterOffer.show() -> drawn: boolean, StarterOffer.hide().
-- API: Shop.start(ctx) (AUTO_START), open, close, toggle, isOpen, refresh, buy, canAsk, quotes, quoteFor, owns, policy, restricted,
-- starterPackGiven, promptOpen, pending, spinTickets, breakerCharges, zonesBeaten, state(), plus test seams _onQuotes/_onState/_onGrant/
-- _onOffer/_onProfile/_noSend/_reset.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Ids = require(Shared:WaitForChild("Ids"))
local Skin = require(Shared:WaitForChild("Skin"))

local N = Skin.Names
local Shop = { AUTO_START = true }

local PENDING_MAX_S = 90 -- a client-side backstop only: the server's promptOpen / Grant is the truth
local REFRESH_MIN_S = 3 -- Shop.Open is rate limited (2 per second); the client asks far less
local REFRESH_BEFORE_S = 20 -- re-ask when a shown quote has less than this left
local STARTER_KEY = "pass_starter_pack"

local ctx = nil
local started = false
local opened = false
local passes: { [string]: boolean } = {}
local policy = { randomItemsRestricted = true, tradingAllowed = true } -- restricted until Shop.State says otherwise (M2-27-1: a slow or failed check counts as restricted)
local starterGiven = false
local serverPromptOpen = false
local packs: { [string]: any } = {} -- the quotes' packs, keyed by shop key
local tickets, charges = 0, 0
local zones: { number } = {}
local pendingKey: string? = nil
local pendingAt = 0
local lastRefresh = -math.huge
local lastGrant = nil
local offerWanted = false
local offerToken = 0
local offerSent = false
local noSend = false
local listeners = { change = {}, grant = {}, open = {} }
local stats = { openSent = 0, buySent = 0, spinTicketsSeen = 0, offerSeenSent = 0, buyRefusedLocal = 0, lastRefusal = nil :: string? }

local function fire(list, ...)
	for _, fn in ipairs(table.clone(list)) do
		task.spawn(fn, ...)
	end
end

local function changed()
	fire(listeners.change)
end

local function now(): number
	local c = ctx and ctx.Clock
	if c and type(c.now) == "function" then
		local ok, t = pcall(c.now)
		if ok and typeof(t) == "number" then
			return t
		end
	end
	return workspace:GetServerTimeNow()
end

-- A module of Ui/ that another task builds: nil until it exists, never an error.
local function ui(name: string)
	local folder = script.Parent.Parent:FindFirstChild("Ui")
	local m = folder and folder:FindFirstChild(name)
	if m and m:IsA("ModuleScript") then
		local ok, mod = pcall(require, m)
		if ok and type(mod) == "table" then
			return mod
		end
	end
	return nil
end

local function callUi(mod, method: string, ...)
	if mod and type(mod[method]) == "function" then
		local ok, res = pcall(mod[method], ...)
		if not ok then
			warn(("[HFB] Shop: %s.%s failed: %s"):format("Ui", method, tostring(res)))
			return nil
		end
		return res
	end
	return nil
end

local function send(family: string, name: string, payload)
	if noSend then
		return
	end
	local ok, r = pcall(Net.get, family, name)
	if ok and r then
		r:FireServer(payload)
	else
		warn(("[HFB] Shop: Net.%s.%s not there: %s"):format(family, name, tostring(r)))
	end
end

-- ------------------------------------------------------------------ the prompt guard (client half)
local function inFight(): boolean
	local f = ctx and ctx.Fight
	return f ~= nil and type(f.active) == "function" and f.active() ~= nil and f.active() ~= false
end

local function carrying(): boolean
	local c = ctx and ctx.Carry
	local info = c and type(c.info) == "function" and c.info()
	return info ~= nil and info ~= false and info.state ~= nil and info.state ~= "none"
end

local function alertShowing(): boolean
	local a = ui("StealAlert")
	return a ~= nil and type(a.isOn) == "function" and a.isOn() == true
end

local function isPending(): boolean
	if pendingKey and os.clock() - pendingAt > PENDING_MAX_S then
		pendingKey = nil
	end
	return pendingKey ~= nil
end

-- true, nil = a purchase may be asked now. false, reason: "fight" | "carry" | "alert" | "busy".
function Shop.canAsk(): (boolean, string?)
	if inFight() then
		return false, "fight"
	end
	if carrying() then
		return false, "carry"
	end
	if alertShowing() then
		return false, "alert"
	end
	if serverPromptOpen or isPending() then
		return false, "busy"
	end
	return true, nil
end

-- ------------------------------------------------------------------ reads
function Shop.isOpen(): boolean
	local s = ui("Shop")
	if s and type(s.isOpen) == "function" then
		local ok, v = pcall(s.isOpen)
		if ok then
			return v == true
		end
	end
	return opened
end
function Shop.owns(key: string): boolean
	return passes[key] == true
end
function Shop.policy()
	return policy
end
function Shop.restricted(): boolean
	return policy.randomItemsRestricted == true
end
function Shop.starterPackGiven(): boolean
	return starterGiven
end
function Shop.promptOpen(): boolean
	return serverPromptOpen
end
function Shop.pending(): string?
	return if isPending() then pendingKey else nil
end
function Shop.spinTickets(): number
	return tickets
end
function Shop.breakerCharges(): number
	return charges
end
function Shop.zonesBeaten(): { number }
	return table.clone(zones)
end
function Shop.quotes()
	return packs
end
function Shop.lastGrant()
	return lastGrant
end

-- A live quote for a cash pack key, else nil (expired or none). The amount shown is the amount the server fixed with this key.
function Shop.quoteFor(key: string)
	local q = packs[key]
	if q and typeof(q.expiresAt) == "number" and q.expiresAt > now() then
		return q
	end
	return nil
end

function Shop.onChange(fn)
	table.insert(listeners.change, fn)
end
function Shop.onGrant(fn)
	table.insert(listeners.grant, fn)
end
function Shop.onOpenChanged(fn)
	table.insert(listeners.open, fn)
end

-- ------------------------------------------------------------------ open / close
function Shop.refresh(force: boolean?)
	if not force and os.clock() - lastRefresh < REFRESH_MIN_S then
		return
	end
	lastRefresh = os.clock()
	stats.openSent += 1
	send("Shop", "Open", {})
end

function Shop.open(): boolean
	if Shop.isOpen() then
		return true
	end
	if inFight() then
		return false
	end
	opened = true
	Shop.refresh(true)
	callUi(ui("Shop"), "open")
	fire(listeners.open, true)
	changed()
	return true
end

function Shop.close()
	local wasOpen = opened or Shop.isOpen()
	opened = false
	callUi(ui("Shop"), "close")
	if wasOpen then
		fire(listeners.open, false)
	end
end

function Shop.toggle()
	if Shop.isOpen() then
		Shop.close()
	else
		Shop.open()
	end
end

-- ------------------------------------------------------------------ buy
local function refuse(reason: string): (boolean, string)
	stats.buyRefusedLocal += 1
	stats.lastRefusal = reason
	return false, reason
end

-- Ask the server to prompt the purchase of `key`. Returns true when the request was sent (the result arrives as Shop.Grant),
-- else false and why. reasons here: unknown | owned | restricted | atShield | stale | fight | carry | alert | busy.
function Shop.buy(key: string): (boolean, string?)
	if typeof(key) ~= "string" or not table.find(Ids.SHOP_KEYS, key) then
		return refuse("unknown")
	end
	if Ids.isPass(key) and passes[key] then
		return refuse("owned")
	end
	if table.find(Ids.SPIN_PRODUCTS, key) and policy.randomItemsRestricted then
		return refuse("restricted")
	end
	if key == "product_shield_breaker" then
		return refuse("atShield") -- bought at an enemy shield (Shield.BuyBreaker, Ui/Prompts), never from the shop
	end
	local ok, why = Shop.canAsk()
	if not ok then
		return refuse(why :: string)
	end
	local quoteKey = nil
	if table.find(Ids.CASH_PACKS, key) then
		local q = Shop.quoteFor(key)
		if not q then
			Shop.refresh(true) -- a stale key is never sent; the new quote reaches the screen through onChange
			return refuse("stale")
		end
		quoteKey = q.quoteKey
	end
	pendingKey = key
	pendingAt = os.clock()
	stats.buySent += 1
	send("Shop", "Buy", { key = key, quoteKey = quoteKey })
	changed()
	return true, nil
end

-- ------------------------------------------------------------------ server messages
function Shop._onQuotes(p)
	if typeof(p) ~= "table" or typeof(p.packs) ~= "table" then
		return
	end
	local fresh = {}
	for key, q in pairs(p.packs) do
		if typeof(key) == "string" and typeof(q) == "table" and typeof(q.amount) == "number" and typeof(q.quoteKey) == "string" and typeof(q.expiresAt) == "number" then
			fresh[key] = { amount = q.amount, quoteKey = q.quoteKey, expiresAt = q.expiresAt }
		end
	end
	packs = fresh
	changed()
end

function Shop._onState(p)
	if typeof(p) ~= "table" then
		return
	end
	if typeof(p.passes) == "table" then
		local owned = {}
		for k, v in pairs(p.passes) do
			if typeof(k) == "string" and v == true then
				owned[k] = true
			end
		end
		passes = owned
	end
	if typeof(p.policy) == "table" then
		policy = {
			randomItemsRestricted = p.policy.randomItemsRestricted == true,
			tradingAllowed = p.policy.tradingAllowed ~= false,
		}
	end
	if typeof(p.starterPackGiven) == "boolean" then
		starterGiven = p.starterPackGiven
	end
	if typeof(p.promptOpen) == "boolean" then
		serverPromptOpen = p.promptOpen
		if not p.promptOpen then
			pendingKey = nil
		end
	end
	if passes[STARTER_KEY] or starterGiven then
		offerWanted = false
		callUi(ui("StarterOffer"), "hide")
	end
	changed()
end

function Shop._onGrant(p)
	if typeof(p) ~= "table" or typeof(p.key) ~= "string" then
		return
	end
	pendingKey = nil
	lastGrant = p
	if p.ok == true and Ids.isPass(p.key) then
		passes[p.key] = true
	end
	if p.ok == false and p.reason == "stale" then
		Shop.refresh(true)
	end
	fire(listeners.grant, p)
	changed()
end

function Shop._onProfile(p)
	if typeof(p) ~= "table" then
		return
	end
	if typeof(p.spinTickets) == "number" then
		tickets = math.max(0, math.floor(p.spinTickets))
		stats.spinTicketsSeen += 1
	end
	if typeof(p.breakerCharges) == "number" then
		charges = math.max(0, math.floor(p.breakerCharges))
	end
	if typeof(p.zonesBeaten) == "table" then
		local list = {}
		for _, z in pairs(p.zonesBeaten) do
			if typeof(z) == "number" and z % 1 == 0 and z >= 1 and z <= 6 and not table.find(list, z) then
				table.insert(list, z)
			end
		end
		table.sort(list)
		zones = list
	end
	changed()
end

-- ------------------------------------------------------------------ the Starter Pack offer
local function offerBlocked(): boolean
	local bp = ui("BossPanel")
	if bp and type(bp.isOpen) == "function" and bp.isOpen() then
		return true -- "shown after the boss panel closes"
	end
	if Shop.isOpen() then
		return true
	end
	local ok = Shop.canAsk()
	return not ok
end

function Shop._onOffer(p)
	if typeof(p) ~= "table" or p.key ~= STARTER_KEY or passes[STARTER_KEY] or starterGiven then
		return
	end
	offerWanted = true
	offerToken += 1
	local token = offerToken
	task.spawn(function()
		local waited = 0
		while token == offerToken and offerWanted and waited < 300 do
			local screen = ui("StarterOffer")
			if screen and not offerBlocked() then
				local drawn = callUi(screen, "show", Shop)
				if drawn == true then
					offerWanted = false
					if not offerSent then
						offerSent = true
						stats.offerSeenSent += 1
						send("Shop", "OfferSeen", { key = STARTER_KEY })
					end
					return
				end
			end
			task.wait(0.5)
			waited += 0.5
		end
	end)
end

-- ------------------------------------------------------------------ input
local function onKey(io: InputObject, processed: boolean)
	if processed then
		return
	end
	if io.KeyCode == Enum.KeyCode.B and io.UserInputType == Enum.UserInputType.Keyboard then
		Shop.toggle()
	elseif io.KeyCode == Enum.KeyCode.DPadUp then
		Shop.toggle()
	elseif io.KeyCode == Enum.KeyCode.ButtonB and Shop.isOpen() then
		Shop.close() -- gamepad: B closes a menu (docs/controls.md)
	end
end

function Shop._noSend(on: boolean)
	noSend = on == true
end

function Shop._onOpenKey(io, processed)
	onKey(io, processed)
end

-- Reset to a fresh session (the check only).
function Shop._reset()
	opened = false
	passes, packs, zones = {}, {}, {}
	policy = { randomItemsRestricted = true, tradingAllowed = true }
	starterGiven, serverPromptOpen, offerWanted, offerSent = false, false, false, false
	tickets, charges = 0, 0
	pendingKey, lastGrant = nil, nil
	changed()
end

function Shop.state()
	return {
		open = Shop.isOpen(),
		passes = passes,
		policy = policy,
		starterGiven = starterGiven,
		promptOpen = serverPromptOpen,
		pending = Shop.pending(),
		tickets = tickets,
		charges = charges,
		zones = zones,
		packs = packs,
		offerWanted = offerWanted,
		offerSent = offerSent,
		stats = stats,
	}
end

local function listen(family: string, name: string, fn)
	task.spawn(function()
		local ok, r = pcall(Net.get, family, name)
		if ok and r then
			r.OnClientEvent:Connect(fn)
		else
			warn(("[HFB] Shop: Net.%s.%s not there: %s"):format(family, name, tostring(r)))
		end
	end)
end

function Shop.start(c)
	if started then
		return
	end
	started = true
	ctx = c
	listen("Shop", "Quotes", Shop._onQuotes)
	listen("Shop", "State", Shop._onState)
	listen("Shop", "Grant", Shop._onGrant)
	listen("Shop", "Offer", Shop._onOffer)
	listen("Profile", "Changed", Shop._onProfile)
	-- Input: the "shop" action once Controllers/Input has it (M2-07), else the keys are read here
	local Input = c.Input
	if Input and type(Input.on) == "function" then
		Input.on("shop", Shop.toggle)
		UserInputService.InputBegan:Connect(function(io, processed)
			if not processed and io.KeyCode == Enum.KeyCode.ButtonB and Shop.isOpen() then
				Shop.close()
			end
		end)
	else
		UserInputService.InputBegan:Connect(onKey)
	end
	-- the Shop tile (touch and mouse): built here only when the skin names it; Ui/Shop may build its own (same tile name replaces)
	local Hud = c.Hud
	local label = N.ui and N.ui.tiles and N.ui.tiles.shop
	if label and Hud and type(Hud.tile) == "function" then
		pcall(Hud.tile, "shop", label, 1, Shop.toggle)
	end
	-- keep quotes fresh while the shop is open; close it when a fight starts
	task.spawn(function()
		while true do
			task.wait(1)
			if opened or Shop.isOpen() then
				if inFight() then
					Shop.close()
				else
					local soonest = math.huge
					for _, q in pairs(packs) do
						soonest = math.min(soonest, q.expiresAt - now())
					end
					if soonest < REFRESH_BEFORE_S then
						Shop.refresh()
					end
				end
			end
		end
	end)
	Players.LocalPlayer.CharacterAdded:Connect(function()
		pendingKey = nil
	end)
end

return Shop
