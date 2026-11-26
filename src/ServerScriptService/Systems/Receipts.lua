--!strict
-- Systems/Receipts: the ONE MarketplaceService.ProcessReceipt (brief system 13; m2-contract.md C "Receipt rules",
-- [M2-02 M3]). Built by M2-18.
--
-- Every developer product is granted here and only here, through Session.recordPurchase (Data/Purchases): the grant is
-- a pure op written with the purchase id in one UpdateAsync, then applied to the live profile; a handled id is never
-- granted again ("already" -> PurchaseGranted); anything that could not be written ("retry": the player is not here,
-- the profile is loading, temp or leaving, or the write failed) -> NotProcessedYet, and Roblox delivers it again.
-- Effects outside the profile (a shield raised or broken, Shop.Grant, toasts) happen only after the write.
-- A receipt never depends on a server-opened prompt (a client can open one itself):
--   cash pack      the amount held when the server prompted it (Shop.peekHeld; cleared only after the write), else the
--                  formula now (Shop.amountFor)
--   spin bundle    tickets (a restricted player keeps them unspent: TEAM CALL M2-01-8)
--   Instant Shield a fresh unbreakable 60 s shield after the write (Shield.raiseInstant)
--   Shield Breaker the target held at the prompt, only if that plot still has that owner and is breakable now; else one
--                  stored charge (also when the shield changed during the write)
-- Receipts.process(receipt, opts?) is the handler (checks call it through the FakeReceipt hook).
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Ids = require(Shared.Ids)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)
local Session = require(script.Parent.Parent.Data.Session)
local Shop = require(script.Parent.Shop)
local Shield = require(script.Parent.Shield)
local Plots = require(script.Parent.Plots)
local Passes = require(script.Parent.Passes)

local Receipts = {}

local GRANTED = Enum.ProductPurchaseDecision.PurchaseGranted
local NOT_YET = Enum.ProductPurchaseDecision.NotProcessedYet

Receipts.stats = { log = {} :: { any } }

local function keyFor(productId: any): string?
	if typeof(productId) ~= "number" or productId <= 0 then
		return nil
	end
	for _, k in ipairs(Ids.PRODUCTS) do
		if Shop.id(k) == productId then
			return k
		end
	end
	return nil
end
Receipts.keyFor = keyFor

local function notice(player: any, kind: string, n: number?)
	if typeof(player) == "Instance" and player.Parent == Players then
		Net.fire("Profile", "Notice", player, { kind = kind, n = n })
	end
end

local function log(e: { [string]: any })
	e.at = os.clock()
	table.insert(Receipts.stats.log, e)
	if #Receipts.stats.log > 100 then
		table.remove(Receipts.stats.log, 1)
	end
end

-- (grant op, after-write effect) for a product key, decided before the write. nil = not now (NotProcessedYet).
local function plan(player: any, key: string): (((any) -> ())?, (() -> ())?)
	if Config.Shop.PACKS[key] then
		local amount = Shop.peekHeld(player, key) or Shop.amountFor(player, key)
		return function(q)
			Session.ops.addCash(q, amount, true)
		end, function()
			Shop.grant(player, { key = key, ok = true, amount = amount })
		end
	end
	local n = Config.Shop.SPIN_TICKETS[key]
	if n then
		return function(q)
			q.spinTickets += n
		end, function()
			Shop.grant(player, { key = key, ok = true, amount = n })
		end
	end
	if key == "product_instant_shield" then
		if not Plots.of(player) then
			return nil -- no base to shield yet: delivered again later
		end
		return function(_q) end, function()
			Shield.raiseInstant(player)
			Shop.grant(player, { key = key, ok = true })
		end
	end
	if key == "product_shield_breaker" then
		local target = Shield.takeBreakerTarget(player)
		local breakNow = target ~= nil and Shield.canBreakTarget(target)
		return function(q)
			if not breakNow then
				q.breakerCharges += 1
			end
		end, function()
			if breakNow and Shield.breakFor(player, target) then
				Shop.grant(player, { key = key, ok = true })
				return
			end
			if breakNow then
				-- breakable when the receipt came, not any more after the write: the purchase is kept as a charge
				Session.mutate(player, function(q)
					q.breakerCharges += 1
				end)
				task.spawn(Session.save, player, "breakerCharge")
			end
			local p = Session.get(player)
			local charges = p and p.breakerCharges or 0
			Shop.grant(player, { key = key, ok = true, charge = true })
			notice(player, "breakerCharged", charges)
		end
	end
	return nil
end

-- The handler. opts.player: a stand-in (checks); opts.key: the shop key when the id is a stand-in 0.
function Receipts.process(receipt: any, opts: { [string]: any }?): Enum.ProductPurchaseDecision
	local o = opts or {}
	local key = o.key or keyFor(receipt.ProductId)
	local pid = tostring(receipt.PurchaseId)
	local player = o.player or Players:GetPlayerByUserId(receipt.PlayerId)
	if not key or not Ids.isProduct(key) then
		warn(("[HFB] Receipts: unknown product %s (purchase %s), not granted"):format(tostring(receipt.ProductId), pid))
		log({ key = key, purchaseId = pid, decision = "notYet", why = "unknown" })
		return NOT_YET
	end
	if not player then
		log({ key = key, purchaseId = pid, decision = "notYet", why = "noPlayer" })
		return NOT_YET
	end
	local p = Session.get(player)
	if p and table.find(p.purchases, pid) then
		if Config.Shop.PACKS[key] then
			Shop.clearHeld(player, key)
		end
		log({ key = key, purchaseId = pid, decision = "granted", status = "already", userId = player.UserId })
		return GRANTED
	end
	if not Session.isSaving(player) then
		log({ key = key, purchaseId = pid, decision = "notYet", why = "notLive", userId = player.UserId })
		return NOT_YET
	end
	local grant, after = plan(player, key)
	if not grant then
		log({ key = key, purchaseId = pid, decision = "notYet", why = "plan", userId = player.UserId })
		return NOT_YET
	end
	local status = Session.recordPurchase(player, pid, grant)
	if (status == "granted" or status == "already") and Config.Shop.PACKS[key] then
		Shop.clearHeld(player, key) -- written: the held amount is used up (kept on "retry", M2-27 SF2)
	end
	if status == "granted" then
		local ok, err = pcall(after :: () -> ())
		if not ok then
			warn("[HFB] Receipts: after-write effect failed: " .. tostring(err))
		end
		log({ key = key, purchaseId = pid, decision = "granted", status = status, userId = player.UserId })
		print(("[HFB][receipt] %s %s granted to %d"):format(key, pid, player.UserId))
		return GRANTED
	elseif status == "already" then
		log({ key = key, purchaseId = pid, decision = "granted", status = status, userId = player.UserId })
		return GRANTED
	end
	log({ key = key, purchaseId = pid, decision = "notYet", status = status, userId = player.UserId })
	return NOT_YET
end

function Receipts.start()
	MarketplaceService.ProcessReceipt = function(receipt)
		local ok, decision = pcall(Receipts.process, receipt)
		if not ok then
			warn("[HFB] Receipts.process errored: " .. tostring(decision))
			return NOT_YET
		end
		return decision
	end

	-- Studio: FakeReceipt '<shopKey>[,purchaseId]' (team/test-hooks.md). A product runs the one handler with a fake
	-- receipt; a pass acts as PromptGamePassPurchaseFinished(true) (a hint, confirmed by the PassOwned hook).
	TestHooks.onSet("FakeReceipt", function(v)
		if not RunService:IsStudio() or typeof(v) ~= "string" then
			return
		end
		local key, pid = v:match("^%s*([%w_]+)%s*,?%s*([^,]*)%s*$")
		local player = Players:GetPlayers()[1]
		if not key or not player then
			warn("[HFB] hook FakeReceipt ignored: " .. tostring(v))
			return
		end
		if Ids.isPass(key) then
			Passes.hint(player, key)
			TestHooks.reports.receipt = { key = key, decision = "hint", at = os.clock() }
			return
		end
		if not Ids.isProduct(key) then
			warn("[HFB] hook FakeReceipt: not a shop key: " .. key)
			return
		end
		local purchaseId = if pid and #pid > 0 then pid else ("fake-" .. HttpService:GenerateGUID(false))
		local d = Receipts.process({ PlayerId = player.UserId, ProductId = Shop.id(key), PurchaseId = purchaseId, CurrencySpent = 0 }, { key = key })
		TestHooks.reports.receipt = { key = key, purchaseId = purchaseId, decision = if d == GRANTED then "granted" else "notYet", at = os.clock() }
	end)
end

return Receipts
