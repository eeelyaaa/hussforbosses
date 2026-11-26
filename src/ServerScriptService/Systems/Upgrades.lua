--!strict
-- Systems/Upgrades: boss upgrades to level 20 (brief system 9; m2-contract.md C "Boss.Upgrade" with [M2-02 M5]).
--   Income at level L = base x (1 + 0.25 x (L - 1)); cost from L to L + 1 = round(30 x base x 1.3 ^ (L - 1)); cap 20.
-- The level belongs to that copy (uid) and travels with it (moves, swaps, steals, the crate).
-- c2s Boss.Upgrade { uid }: the uid is on one of the caller's spots (not on the caller's head), the caller within
-- PLACE_RANGE of that spot, not locked by a steal, level < 20, cash >= the server's cost. One mutate: the pad is
-- settled at the old level first (the new rate counts from now), then the cost is spent (earned cash first, the
-- bought-cash rule) and the level goes up. s2c Boss.Result { uid, ok, reason, level, nextCost }.
-- Funnel FirstBossUpgraded on the first accepted upgrade.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Session = require(script.Parent.Parent.Data.Session)
local Zones = require(script.Parent.Zones)
local Bag = require(script.Parent.Bag)
local Income = require(script.Parent.Income)
local Base = require(script.Parent.Base)
local Funnel = require(script.Parent.Funnel)

local Upgrades = {}

Upgrades.stats = { refused = {} :: { [string]: number }, done = {} :: { any } }

-- Cost to take a boss from `level` to level + 1 (nil at the cap).
function Upgrades.cost(creatureId: string, level: number): number?
	local base = Config.Zones.INCOME[creatureId]
	if typeof(base) ~= "number" then
		return nil
	end
	return Config.Upgrades.COST(base, level)
end

local function answer(player: Player, uid: string, reason: string?, level: number?, nextCost: number?): string?
	if reason then
		Upgrades.stats.refused[reason] = (Upgrades.stats.refused[reason] or 0) + 1
	end
	if player.Parent == Players then
		Net.get("Boss", "Result"):FireClient(player, { uid = uid, ok = reason == nil, reason = reason, level = level, nextCost = nextCost })
	end
	return reason
end

-- Returns nil on success or the refusal reason ('state'|'notYours'|'range'|'locked'|'cap'|'cash').
function Upgrades.tryUpgrade(player: Player, uid: any): string?
	if not Net.isShortString(uid, 40) then
		Upgrades.stats.refused.bad = (Upgrades.stats.refused.bad or 0) + 1
		return "bad"
	end
	local p = Session.get(player)
	if not p then
		return answer(player, uid, "state")
	end
	local plot = Session.plot(player)
	if not plot or plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return answer(player, uid, "notYours")
	end
	local boss
	for _, b in ipairs(p.bosses) do
		if b.uid == uid then
			boss = b
		end
	end
	if not boss then
		return answer(player, uid, "notYours")
	end
	if p.carry and p.carry.uid == uid then
		return answer(player, uid, "state", boss.level)
	end
	if Base.isLocked(uid) then
		return answer(player, uid, "locked", boss.level)
	end
	local part = Base.spotPart(plot, boss.spot)
	local r = Bag.root(player)
	if not part or not r then
		return answer(player, uid, "range", boss.level)
	end
	local d = r.Position - part.Position
	if Vector3.new(d.X, 0, d.Z).Magnitude > Config.Base.PLACE_RANGE or math.abs(d.Y) > Config.Base.PLACE_HEIGHT then
		return answer(player, uid, "range", boss.level)
	end
	local cost = Upgrades.cost(boss.creatureId, boss.level)
	if not cost then
		return answer(player, uid, "cap", boss.level)
	end
	if p.cash < cost then
		return answer(player, uid, "cash", boss.level, cost)
	end
	local now = Zones.now()
	local mult = Income.mult(player, p)
	local newLevel = boss.level + 1
	if not Session.mutate(player, function(q)
		for _, b in ipairs(q.bosses) do
			if b.uid == uid then
				Income.settleOp(q, b, now, mult)
				assert(Session.ops.spendCash(q, cost), "cash")
				b.level = newLevel
				return
			end
		end
		error("boss missing")
	end) then
		return answer(player, uid, "state", boss.level)
	end
	table.insert(Upgrades.stats.done, { userId = player.UserId, uid = uid, level = newLevel, cost = cost, at = now })
	if #Upgrades.stats.done > 100 then
		table.remove(Upgrades.stats.done, 1)
	end
	Funnel.mark(player, "FirstBossUpgraded")
	return answer(player, uid, nil, newLevel, Upgrades.cost(boss.creatureId, newLevel))
end

function Upgrades.start()
	Net.onServerEvent("Boss", "Upgrade", function(player, payload)
		Upgrades.tryUpgrade(player, payload.uid)
	end)
end

return Upgrades
