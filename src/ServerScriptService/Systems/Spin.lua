--!strict
-- Systems/Spin: the Lucky Boss Spin (brief system 13; m2-contract.md C "Shop.Spin", [M2-02 S11]). Built by M2-18.
-- A ticket is spent on a zone the player has beaten a boss in (the saved zonesBeaten list; rebirth keeps it); the tier
-- comes from Shared/SpinTable (the one odds table the screen lists); the creature Ids.creature(zone, tier) goes to the
-- crate with the bought mark { source = "spin", buyer } in the SAME mutate that takes the ticket (BoughtMark.grant
-- with extra), then the profile is saved (S11). A restricted player (PolicyService, Policy.get) never spins.
--
-- c2s Shop.Spin { zone } (rate 1). s2c Shop.SpinResult { ok, reason?, zone, creatureId?, tier?, uid? }.
-- API: Spin.trySpin(player, zone) -> reason?   Spin.rollTier(rng) -> tier   Spin.distribution(n, seed) -> counts
-- Hooks (Studio): SetTickets (state), SpinSeed (config: the roll's Random seed).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Ids = require(Shared.Ids)
local TestHooks = require(Shared.TestHooks)
local SpinTable = require(Shared.SpinTable)
local Session = require(script.Parent.Parent.Data.Session)
local Policy = require(script.Parent.Policy)
local BoughtMark = require(script.Parent.BoughtMark)

local Spin = {}

Spin.stats = { results = {} :: { any }, refused = {} :: { [string]: number } }

local rng = Random.new()
local seeded: number? = nil

local function currentRng(): Random
	local s = TestHooks.get("SpinSeed")
	if typeof(s) == "number" then
		if seeded ~= s then
			seeded = s
			rng = Random.new(s)
		end
	elseif seeded ~= nil then
		seeded = nil
		rng = Random.new()
	end
	return rng
end

function Spin.rollTier(r: Random): number
	return SpinTable.pick(r:NextNumber())
end

-- n rolls from a Random seeded with `seed` (or the live one): counts per tier. Pure apart from the Random.
function Spin.distribution(n: number, seed: number?): { [number]: number }
	local r = if seed then Random.new(seed) else currentRng()
	local counts = {}
	for _, o in ipairs(SpinTable.ODDS) do
		counts[o.tier] = 0
	end
	for _ = 1, n do
		local t = Spin.rollTier(r)
		counts[t] += 1
	end
	return counts
end

local function reply(player: any, payload: { [string]: any }): string?
	table.insert(Spin.stats.results, { userId = player.UserId, payload = payload, at = os.clock() })
	if #Spin.stats.results > 100 then
		table.remove(Spin.stats.results, 1)
	end
	if not payload.ok then
		Spin.stats.refused[payload.reason] = (Spin.stats.refused[payload.reason] or 0) + 1
	end
	if typeof(player) == "Instance" and player.Parent == Players then
		Net.fire("Shop", "SpinResult", player, payload)
	end
	return payload.reason
end

-- nil on a spin, else 'zone' | 'tickets' | 'restricted' | 'state'.
function Spin.trySpin(player: any, zone: any): string?
	if not Net.isInt(zone, 1, 6) then
		Spin.stats.refused.bad = (Spin.stats.refused.bad or 0) + 1
		return "bad"
	end
	local p = Session.get(player)
	if not p then
		return reply(player, { ok = false, reason = "state", zone = zone })
	end
	if Policy.get(player).randomItemsRestricted then
		return reply(player, { ok = false, reason = "restricted", zone = zone })
	end
	if not table.find(p.zonesBeaten, zone) then
		return reply(player, { ok = false, reason = "zone", zone = zone })
	end
	if p.spinTickets < 1 then
		return reply(player, { ok = false, reason = "tickets", zone = zone })
	end
	local tier = Spin.rollTier(currentRng())
	local creatureId = Ids.creature(zone, tier)
	local uid = BoughtMark.grant(player, creatureId, "spin", {
		extra = function(q)
			assert(q.spinTickets >= 1, "no ticket")
			q.spinTickets -= 1
		end,
	})
	if not uid then
		return reply(player, { ok = false, reason = "state", zone = zone })
	end
	task.spawn(Session.save, player, "spin") -- S11: the ticket and the boss are saved together at once
	if typeof(player) == "Instance" and player.Parent == Players then
		Net.fire("Profile", "Notice", player, { kind = "crateDelivered" })
	end
	return reply(player, { ok = true, zone = zone, creatureId = creatureId, tier = tier, uid = uid })
end

function Spin.start()
	Net.onServerEvent("Shop", "Spin", function(player, payload)
		Spin.trySpin(player, payload.zone)
	end)
	-- SetTickets (state hook, Studio): spinTickets of every real player becomes this.
	TestHooks.onSet("SetTickets", function(v)
		if not Net.isInt(v, 0, 1e6) then
			warn("[HFB] hook SetTickets ignored: " .. tostring(v))
			return
		end
		for _, pl in ipairs(Players:GetPlayers()) do
			Session.mutate(pl, function(q)
				q.spinTickets = v
			end)
		end
	end)
end

return Spin
