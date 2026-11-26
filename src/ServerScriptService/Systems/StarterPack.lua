--!strict
-- Systems/StarterPack: the Starter Pack's contents and its once-a-session offer (brief system 13; m2-contract.md C
-- "Receipt rules" [M2-02 M4], "Shop.OfferSeen"). Built by M2-18.
--
-- The Starter Pack is a game pass (Roblox stops a second purchase). Its contents ($5,000 bought cash and the zone 1
-- Epic to the crate with the bought mark { source = "pack", buyer }) are granted ONCE, whenever the pass is owned
-- (Systems/Passes: Roblox's answer, confirmed; never the Finished event alone) and starterPackGiven is false: after a
-- confirmed purchase, and on join for a web-page buyer. The grant is one write first (Session.recordPurchase under
-- "<STARTER_RECORD_ID>:<uid>", which never writes into a temp, loading or leaving profile), then the live profile;
-- starterPackGiven, checked inside the write and again live, is the once-guard
-- (TEAM CALL M2-18-1: stricter than "a mutate then a save"). A grant that could not be written is tried again every
-- STARTER_RETRY_S while the player stays.
-- The offer: Shop.Offer { key = "pass_starter_pack" } once per session, after the session's first boss upgrade, until
-- bought; it waits for the prompt guard (no fight, carry, alert or open prompt). Shop.OfferSeen { key } is accepted
-- once, only after the offer was sent, and marks the funnel's StarterPackShown.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Session = require(script.Parent.Parent.Data.Session)
local Passes = require(script.Parent.Passes)
local Shop = require(script.Parent.Shop)
local BoughtMark = require(script.Parent.BoughtMark)
local Funnel = require(script.Parent.Funnel)

local StarterPack = {}

local KEY = "pass_starter_pack"

local busy: { [any]: boolean } = {}
local retrying: { [any]: boolean } = {}
local offered: { [any]: boolean } = {}
local seen: { [any]: boolean } = {}
local levels: { [any]: { [string]: number } } = {}

StarterPack.stats = { grants = {} :: { any }, skipped = {} :: { any }, offers = {} :: { any } }

local function isReal(player: any): boolean
	return typeof(player) == "Instance" and player.Parent == Players
end

-- The grant as a pure op (uid taken before the write so the record and the live profile get the same boss).
function StarterPack.op(userId: number, uid: string): (any) -> ()
	return function(q)
		if q.starterPackGiven then
			return
		end
		Session.ops.addCash(q, Config.Shop.STARTER_CASH, true)
		BoughtMark.op(q, userId, Config.Shop.STARTER_CREATURE, "pack", { uid = uid })
		q.starterPackGiven = true
	end
end

-- Grants the contents if they are owed. Yields (one write). Returns "granted" | "already" | "retry" | "notOwed".
function StarterPack.check(player: any): string
	local p = Session.get(player)
	if not p or p.starterPackGiven or not Passes.owns(player, KEY) then
		return "notOwed"
	end
	if RunService:IsStudio() and not Config.Shop.STUDIO_STARTER_FROM_ROBLOX and Passes.source(player, KEY) ~= "hook" then
		table.insert(StarterPack.stats.skipped, { userId = player.UserId, at = os.clock() })
		return "notOwed" -- TEAM CALL M2-18-3: the Studio account's real pass never grants in Studio
	end
	if busy[player] then
		return "retry"
	end
	busy[player] = true
	local status = "retry"
	local ok, err = pcall(function()
		local uid = Session.newUid(player)
		if not uid then
			return
		end
		status = Session.recordPurchase(player, Config.Shop.STARTER_RECORD_ID .. ":" .. uid, StarterPack.op(player.UserId, uid))
		if status == "granted" then
			table.insert(StarterPack.stats.grants, { userId = player.UserId, uid = uid, at = os.clock() })
			print(("[HFB][starter] contents granted to %d (%s)"):format(player.UserId, uid))
			Shop.grant(player, { key = KEY, ok = true, amount = Config.Shop.STARTER_CASH, uid = uid, creatureId = Config.Shop.STARTER_CREATURE })
			if isReal(player) then
				Net.fire("Profile", "Notice", player, { kind = "crateDelivered" })
			end
		end
	end)
	busy[player] = nil
	if not ok then
		warn("[HFB] StarterPack.check errored: " .. tostring(err))
		status = "retry"
	end
	if status == "retry" and not retrying[player] then
		retrying[player] = true
		task.delay(Config.Shop.STARTER_RETRY_S, function()
			retrying[player] = nil
			if isReal(player) then
				StarterPack.check(player)
			end
		end)
	end
	return status
end

-- ------------------------------------------------------------------------------------------------ the offer
local function snapshot(player: any): { [string]: number }
	local out = {}
	local p = Session.get(player)
	if p then
		for _, b in ipairs(p.bosses) do
			out[b.uid] = b.level
		end
	end
	return out
end

local function offerOwed(player: any): boolean
	local p = Session.get(player)
	return p ~= nil and not p.starterPackGiven and not Passes.owns(player, KEY) and Shop.id(KEY) > 0
end

-- The offer once this session, when the guard is clear (waits up to OFFER_WAIT_S).
function StarterPack.offer(player: any)
	if offered[player] or not offerOwed(player) then
		return
	end
	offered[player] = true
	task.spawn(function()
		local t0 = os.clock()
		while isReal(player) and Shop.busyReason(player) ~= nil and os.clock() - t0 < Config.Shop.OFFER_WAIT_S do
			task.wait(Config.Shop.OFFER_POLL_S)
		end
		if not isReal(player) or Shop.busyReason(player) ~= nil or not offerOwed(player) then
			offered[player] = nil -- not shown: the next upgrade tries again
			return
		end
		table.insert(StarterPack.stats.offers, { userId = player.UserId, at = os.clock() })
		Net.fire("Shop", "Offer", player, { key = KEY })
	end)
end

function StarterPack.offeredThisSession(player: any): boolean
	return offered[player] == true
end

-- Shop.OfferSeen: once, only after the offer was sent. Returns true when accepted.
function StarterPack.offerSeen(player: any, payload: any): boolean
	if payload.key ~= KEY or not offered[player] or seen[player] then
		return false
	end
	seen[player] = true
	Funnel.mark(player, "StarterPackShown")
	return true
end

function StarterPack.start()
	Net.onServerEvent("Shop", "OfferSeen", function(player, payload)
		StarterPack.offerSeen(player, payload)
	end)
	Passes.onChanged(function(player, key, owned)
		if key == KEY and owned then
			StarterPack.check(player)
		end
	end)
	Session.onJoin(function(player)
		levels[player] = snapshot(player)
		StarterPack.check(player)
	end)
	-- The session's first boss upgrade: a boss already on a spot whose level went up.
	Session.onChanged(function(player, key, _v)
		if key ~= "bosses" then
			return
		end
		local before = levels[player] or {}
		local after = snapshot(player)
		levels[player] = after
		for uid, lv in pairs(after) do
			if before[uid] ~= nil and lv > before[uid] then
				StarterPack.offer(player)
				return
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		busy[p] = nil
		offered[p] = nil
		seen[p] = nil
		levels[p] = nil
	end)
end

return StarterPack
