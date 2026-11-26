--!strict
-- Systems/Shop: quotes, the purchase prompt and its guard, Shop.State (brief system 13; m2-contract.md C "Shop",
-- "Receipt rules", [M2-02 M3, S3, S4]). Built by M2-18. Grants are Systems/Receipts (products) and Systems/Passes
-- (passes); the spin is Systems/Spin; the Starter Pack grant and offer are Systems/StarterPack.
--
-- c2s: Shop.Open {}, Shop.Buy { key, quoteKey? }. s2c: Shop.Quotes, Shop.State, Shop.Grant (owner).
-- API:
--   Shop.prompt(player, key, ctx?) -> boolean   the one way a purchase prompt opens (Shield.BuyBreaker calls it).
--                                               false when the guard says no (Shop.busyReason) or the id is 0.
--   Shop.busyReason(player) -> string?          'prompt' (one open: never two) | 'fight' | 'carry' | 'alert' (a steal
--                                               alert or a "shield broken" alert) | nil
--   Shop.amountFor(player, key) -> number       a cash pack's amount now (pure on the profile and the pass cache)
--   Shop.peekHeld / clearHeld / takeHeld        the amount held when the server prompted that cash pack (Receipts
--                                               peeks, and clears only after the grant is written: M2-27 SF2)
--   Shop.dropQuotes(player)                     quotes forgotten (rebirth, S4)
--   Shop.sendState(player), Shop.sendQuotes(player), Shop.grant(player, payload)
--   Shop.setPromptFn(fn(player, kind, id))      checks replace Roblox's dialog (playbook: never open it in a check)
-- No yield in a handler: pass ownership and policy come from their caches (Passes.owns, Policy.get).
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Ids = require(Shared.Ids)
local Session = require(script.Parent.Parent.Data.Session)
local Passes = require(script.Parent.Passes)
local Policy = require(script.Parent.Policy)
local Fight = require(script.Parent.Fight)
local Carry = require(script.Parent.Carry)
local Income = require(script.Parent.Income)
local Shield = require(script.Parent.Shield)
local Steal = require(script.Parent.Steal)

local Shop = {}

type Quote = { amount: number, quoteKey: string, expiresAt: number }
type Prompt = { key: string, kind: string, id: number, at: number }

local quotes: { [any]: { [string]: Quote } } = {}
local held: { [any]: { [string]: { amount: number, at: number } } } = {}
local prompts: { [any]: Prompt } = {}

Shop.stats = { prompts = {} :: { any }, refused = {} :: { [string]: number }, grants = {} :: { any } }

local function now(): number
	return workspace:GetServerTimeNow()
end

local function isReal(player: any): boolean
	return typeof(player) == "Instance" and player.Parent == Players
end

local function promptRoblox(player: any, kind: string, id: number)
	if kind == "pass" then
		MarketplaceService:PromptGamePassPurchase(player, id)
	else
		MarketplaceService:PromptProductPurchase(player, id)
	end
end
local promptFn: (any, string, number) -> () = promptRoblox

function Shop.setPromptFn(fn: ((any, string, number) -> ())?)
	promptFn = fn or promptRoblox
end

function Shop.id(key: string): number
	local ids = (Config :: any).Shop.IDS
	local id = ids and ids[key]
	return if typeof(id) == "number" then id else 0
end

-- ------------------------------------------------------------------------------------------------ state
function Shop.promptOpen(player: any): Prompt?
	local pr = prompts[player]
	if pr and os.clock() - pr.at > Config.Shop.PROMPT_TIMEOUT_S then
		prompts[player] = nil -- S3: a Finished event that never came frees the player after the timeout
		pr = nil
	end
	return pr
end

function Shop.sendState(player: any)
	if not isReal(player) then
		return
	end
	local p = Session.get(player)
	local pol = Policy.get(player)
	Net.fire("Shop", "State", player, {
		passes = Passes.ownedKeys(player),
		policy = { randomItemsRestricted = pol.randomItemsRestricted, tradingAllowed = pol.tradingAllowed },
		starterPackGiven = p ~= nil and p.starterPackGiven == true,
		promptOpen = Shop.promptOpen(player) ~= nil,
	})
end

function Shop.grant(player: any, payload: { [string]: any })
	table.insert(Shop.stats.grants, { userId = player.UserId, payload = payload, at = os.clock() })
	if #Shop.stats.grants > 100 then
		table.remove(Shop.stats.grants, 1)
	end
	if isReal(player) then
		Net.fire("Shop", "Grant", player, payload)
	end
end

local function notice(player: any, kind: string, n: number?)
	if isReal(player) then
		Net.fire("Profile", "Notice", player, { kind = kind, n = n })
	end
end

local function refuse(player: any, key: string, reason: string): string
	Shop.stats.refused[reason] = (Shop.stats.refused[reason] or 0) + 1
	Shop.grant(player, { key = key, ok = false, reason = reason })
	return reason
end

-- ------------------------------------------------------------------------------------------------ the guard
function Shop.busyReason(player: any): string?
	if Shop.promptOpen(player) then
		return "prompt"
	end
	if Fight.get(player) ~= nil then
		return "fight"
	end
	if Carry.get(player) ~= nil then
		return "carry"
	end
	local ok, on = pcall(Steal.alertOn, player)
	if ok and on then
		return "alert"
	end
	return nil
end

-- The one prompt opener. ctx is the caller's (Shield keeps its own Breaker target). Never yields.
function Shop.prompt(player: any, key: string, ctx: any?): boolean
	if not Net.isOneOf(key, Ids.SHOP_KEYS) or not Session.get(player) then
		return false
	end
	local id = Shop.id(key)
	if id <= 0 then
		return false
	end
	local busy = Shop.busyReason(player)
	if busy then
		Shop.stats.refused["busy:" .. busy] = (Shop.stats.refused["busy:" .. busy] or 0) + 1
		return false
	end
	local kind = if Ids.isPass(key) then "pass" else "product"
	prompts[player] = { key = key, kind = kind, id = id, at = os.clock() }
	table.insert(Shop.stats.prompts, { userId = player.UserId, key = key, kind = kind, id = id, at = os.clock() })
	if #Shop.stats.prompts > 100 then
		table.remove(Shop.stats.prompts, 1)
	end
	local ok, err = pcall(promptFn, player, kind, id)
	if not ok then
		prompts[player] = nil
		warn("[HFB] Shop.prompt: prompt call failed: " .. tostring(err))
		return false
	end
	Shop.sendState(player)
	return true
end

-- A prompt closed (Finished event, or a check standing in for it).
function Shop.promptClosed(player: any, id: number, purchased: boolean)
	local pr = prompts[player]
	if not pr or pr.id ~= id then
		return
	end
	prompts[player] = nil
	if not purchased then
		local h = held[player]
		if h then
			h[pr.key] = nil
		end
		if pr.key == "product_shield_breaker" then
			Shield.takeBreakerTarget(player) -- nothing bought: the held target is dropped
		end
		Shop.grant(player, { key = pr.key, ok = false, reason = "cancelled" })
	end
	Shop.sendState(player)
end

-- ------------------------------------------------------------------------------------------------ cash packs
-- Total income a second of the player's placed bosses now, with their multipliers (rebirth, 2x Cash).
function Shop.incomePerSecond(player: any): number
	local p = Session.get(player)
	if not p then
		return 0
	end
	local mult = Income.mult(player, p)
	local total = 0
	for _, b in ipairs(p.bosses) do
		total += Income.rate(p, b, mult)
	end
	return total
end

function Shop.amountFor(player: any, key: string): number
	local pack = Config.Shop.PACKS[key]
	if not pack then
		return 0
	end
	return math.max(pack.min, math.floor(Shop.incomePerSecond(player) * pack.seconds))
end

function Shop.sendQuotes(player: any)
	local q: { [string]: Quote } = {}
	local t = now()
	for _, key in ipairs(Ids.CASH_PACKS) do
		q[key] = { amount = Shop.amountFor(player, key), quoteKey = HttpService:GenerateGUID(false), expiresAt = t + Config.Shop.QUOTE_S }
	end
	quotes[player] = q
	if isReal(player) then
		Net.fire("Shop", "Quotes", player, { packs = q })
	end
end

function Shop.quoteOf(player: any, key: string): Quote?
	local q = quotes[player]
	return q and q[key]
end

-- The held amount for a pack receipt: peeked for the plan, cleared only once the grant is written (M2-27 SF2), so
-- a write that fails leaves it for the redelivered receipt.
function Shop.peekHeld(player: any, key: string): number?
	local h = held[player]
	local e = h and h[key]
	if not e then
		return nil
	end
	if now() - e.at > Config.Shop.HELD_S then
		h[key] = nil
		return nil
	end
	return e.amount
end
function Shop.clearHeld(player: any, key: string)
	local h = held[player]
	if h then
		h[key] = nil
	end
end
function Shop.takeHeld(player: any, key: string): number?
	local v = Shop.peekHeld(player, key)
	Shop.clearHeld(player, key)
	return v
end

-- A prompt already open keeps its held amount (the dialog shows it; TEAM CALL M2-18-4).
function Shop.dropQuotes(player: any)
	quotes[player] = nil
end

-- ------------------------------------------------------------------------------------------------ Shop.Buy
-- Returns nil when the prompt opened, else the refusal reason (also sent as Shop.Grant).
function Shop.buy(player: any, payload: any): string?
	local key = payload.key
	if not Net.isOneOf(key, Ids.SHOP_KEYS) then
		Shop.stats.refused.bad = (Shop.stats.refused.bad or 0) + 1
		return "bad"
	end
	if payload.quoteKey ~= nil and not Net.isShortString(payload.quoteKey, 40) then
		Shop.stats.refused.bad = (Shop.stats.refused.bad or 0) + 1
		return "bad"
	end
	local p = Session.get(player)
	if not p then
		return refuse(player, key, "state")
	end
	if Shop.id(key) <= 0 then
		return refuse(player, key, "unknown")
	end
	if Ids.isPass(key) and Passes.owns(player, key) then
		return refuse(player, key, "owned")
	end
	if key == "pass_starter_pack" and p.starterPackGiven then
		return refuse(player, key, "owned")
	end
	if table.find(Ids.SPIN_PRODUCTS, key) and Policy.get(player).randomItemsRestricted then
		return refuse(player, key, "restricted")
	end
	if key == "pass_perfect_auto_punch" and not Passes.owns(player, "pass_auto_punch") then
		return refuse(player, key, "needAuto") -- offered in the game only to Auto Punch owners (brief 2, 13)
	end
	if key == "product_shield_breaker" then
		return refuse(player, key, "state") -- bought at the shield: Shield.BuyBreaker
	end
	if key == "product_instant_shield" and Shield.isUp(player) then
		return refuse(player, key, "shieldUp")
	end
	local amount: number? = nil
	if Config.Shop.PACKS[key] then
		local q = Shop.quoteOf(player, key)
		if not q or payload.quoteKey ~= q.quoteKey or now() > q.expiresAt then
			Shop.sendQuotes(player)
			notice(player, "quoteStale")
			return refuse(player, key, "stale")
		end
		amount = q.amount
	end
	if not Shop.prompt(player, key) then
		notice(player, "promptBusy")
		return refuse(player, key, "busy")
	end
	if amount then
		held[player] = held[player] or {}
		held[player][key] = { amount = amount, at = now() } -- the shown offer is the granted offer ([M2-02 M3])
	end
	return nil
end

function Shop.start()
	Net.onServerEvent("Shop", "Open", function(player, _payload)
		if not Session.get(player) then
			return
		end
		Shop.sendQuotes(player)
		Shop.sendState(player)
		Passes.retryFailed(player) -- on demand: a pass check that failed on join is asked again (M2-27 SF3)
	end)
	Net.onServerEvent("Shop", "Buy", function(player, payload)
		Shop.buy(player, payload)
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, isPurchased)
		local player = Players:GetPlayerByUserId(userId)
		if player then
			Shop.promptClosed(player, productId, isPurchased == true)
		end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		Shop.promptClosed(player, passId, purchased == true)
	end)

	-- A pass confirmed (or lost, in Studio): the shop and the grant result.
	Passes.onChanged(function(player, key, owned)
		Shop.sendState(player)
		if owned and Session.get(player) then
			Shop.grant(player, { key = key, ok = true })
		end
	end)
	Session.onJoin(function(player)
		Shop.sendState(player)
		Policy.onReady(player, function()
			Shop.sendState(player)
		end)
	end)
	Session.onChanged(function(player, key, _v)
		if key == "starterPackGiven" then
			Shop.sendState(player)
		end
	end)
	Policy.onChange(function(player)
		Shop.sendState(player)
	end)
	local rb = script.Parent:FindFirstChild("Rebirth")
	if rb then
		local ok, Rebirth = pcall(require, rb)
		if ok and type(Rebirth) == "table" and type((Rebirth :: any).onRebirth) == "function" then
			(Rebirth :: any).onRebirth(function(player)
				Shop.dropQuotes(player) -- S4: a quote of the old income is never bought after a rebirth
			end)
		end
	end
	Players.PlayerRemoving:Connect(function(p)
		quotes[p] = nil
		held[p] = nil
		prompts[p] = nil
	end)
end

return Shop
