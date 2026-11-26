--!strict
-- Systems/BoughtMark: the ONLY writer of a boss's bought mark (brief systems 12 and 13; m2-contract.md D "The bought
-- mark and boughtCash", [M2-02 M1]). Built by M2-14.
--
-- A bought mark is `{ source = "spin" | "pack", buyer = <userId> }` on a saved boss (in `bosses` or `crate`). It is
-- set once, here, when the Lucky Spin (M2-18 Systems/Spin) or the Starter Pack (M2-18) grants a boss, and it never
-- changes afterwards: Session.mutate refuses any change to an existing mark without this module's claim, and this
-- module only ever adds NEW bosses with a mark. A stolen boss carries its mark unchanged (Session.transfer moves the
-- entry as it is). A boss beaten in a fight never has one. No remote reads or writes it.
--
-- API (server):
--   BoughtMark.grant(player, creatureId, source, opts?) -> uid?
--       One claimed mutate: the boss goes to the crate (opts.to = "crate", the default and the only target a real
--       grant uses) with `bought = { source, buyer = player.UserId }`. opts.level (default 1), opts.uid (default a new
--       uid, taken first with Session.newUid), opts.extra(q) runs inside the SAME mutate (the Spin's ticket -1), and
--       an error there applies nothing. Returns the uid, or nil with nothing applied.
--   BoughtMark.op(q, userId, creatureId, source, opts?) -> uid
--       The same as a pure op on a profile-shaped table, for a receipt grant inside Session.recordPurchase (the
--       Starter Pack: ops.addCash(q, 5000, true), BoughtMark.op(q, ...), q.starterPackGiven = true). Takes a uid with
--       Session.ops.newUid when opts.uid is absent. Errors on a bad argument (the grant then applies nothing).
--   BoughtMark.isBuyer(boss, userId) -> boolean     BoughtMark.keptCount(profile, userId) -> number (what rebirth keeps)
--   BoughtMark.grantFromHook(player, opts)          Studio only: GrantBoss with bought= (called by Systems/Base).
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Ids = require(Shared.Ids)
local Session = require(script.Parent.Parent.Data.Session)
local Zones = require(script.Parent.Zones)

local BoughtMark = {}

-- The claim stays inside this module (Session.claim hands the same token to any caller that names it; only this
-- file and the Starter Pack grant may name "BoughtMark", contract D).
local TOKEN = Session.claim("BoughtMark")

BoughtMark.stats = { grants = {} :: { any } }

local function checkArgs(userId: any, creatureId: any, source: any, level: any)
	assert(Net.isInt(userId) and userId ~= 0, "BoughtMark: bad buyer")
	assert(typeof(creatureId) == "string" and Ids.parseCreature(creatureId) ~= nil and Config.Zones.INCOME[creatureId] ~= nil, "BoughtMark: bad creatureId " .. tostring(creatureId))
	assert(Net.isOneOf(source, Ids.BOUGHT_SOURCES), "BoughtMark: bad source " .. tostring(source))
	assert(Net.isInt(level, 1, Config.Data.LIMITS.bossLevelMax), "BoughtMark: bad level")
end

local function hasUid(q: any, uid: string): boolean
	for _, list in ipairs({ q.bosses, q.crate }) do
		for _, b in ipairs(list) do
			if b.uid == uid then
				return true
			end
		end
	end
	return false
end

-- Inserts the boss with its mark (pure). to = "crate" or a spot number (Studio hook only).
local function insert(q: any, uid: string, creatureId: string, level: number, mark: any, to: any, now: number)
	assert(not hasUid(q, uid), "BoughtMark: uid already in the profile " .. uid)
	if to == nil or to == "crate" then
		table.insert(q.crate, { uid = uid, creatureId = creatureId, level = level, bought = mark })
		return
	end
	local spot = tonumber(to)
	assert(spot and Net.isInt(spot, 1, Config.Base.MAX_SPOTS), "BoughtMark: bad to=" .. tostring(to))
	for _, b in ipairs(q.bosses) do
		assert(b.spot ~= spot, "BoughtMark: spot taken")
	end
	table.insert(q.bosses, { uid = uid, creatureId = creatureId, level = level, spot = spot, padCash = 0, padStamp = now, bought = mark })
	table.sort(q.bosses, function(x, y)
		return x.spot < y.spot
	end)
end

function BoughtMark.op(q: any, userId: number, creatureId: string, source: string, opts: { [string]: any }?): string
	local o = opts or {}
	local level = o.level or Config.Income.DEFAULT_LEVEL
	checkArgs(userId, creatureId, source, level)
	local uid = o.uid or Session.ops.newUid(q, userId)
	insert(q, uid, creatureId, level, { source = source, buyer = userId }, o.to, o.now or Zones.now())
	return uid
end

local function log(player: Player, uid: string, creatureId: string, source: string, buyer: number)
	table.insert(BoughtMark.stats.grants, { userId = player.UserId, uid = uid, creatureId = creatureId, source = source, buyer = buyer, at = os.clock() })
	if #BoughtMark.stats.grants > 100 then
		table.remove(BoughtMark.stats.grants, 1)
	end
	print(("[HFB][bought] %s %s to %d (buyer %d, %s)"):format(creatureId, uid, player.UserId, buyer, source))
end

-- buyer: the real grants never pass one (the buyer is the player); the Studio hook may.
local function grantAs(player: Player, buyer: number, creatureId: string, source: string, opts: { [string]: any }?): string?
	local o = opts or {}
	local level = o.level or Config.Income.DEFAULT_LEVEL
	local okArgs, why = pcall(checkArgs, buyer, creatureId, source, level)
	if not okArgs then
		warn("[HFB] BoughtMark.grant refused: " .. tostring(why))
		return nil
	end
	if not Session.get(player) then
		return nil
	end
	local uid = o.uid or Session.newUid(player)
	if not uid then
		return nil
	end
	local now = Zones.now()
	local ok = Session.mutate(player, function(q)
		insert(q, uid, creatureId, level, { source = source, buyer = buyer }, o.to, now)
		if type(o.extra) == "function" then
			o.extra(q)
		end
	end, TOKEN)
	if not ok then
		warn("[HFB] BoughtMark.grant: mutate refused, nothing applied (" .. creatureId .. ")")
		return nil
	end
	log(player, uid, creatureId, source, buyer)
	return uid
end

function BoughtMark.grant(player: Player, creatureId: string, source: string, opts: { [string]: any }?): string?
	if typeof(player) ~= "Instance" and not (RunService:IsStudio() and type(player) == "table") then
		return nil
	end
	local o = table.clone(opts or {})
	o.to = "crate" -- every real grant is delivered to the crate (brief 13)
	return grantAs(player, (player :: any).UserId, creatureId, source, o)
end

function BoughtMark.isBuyer(boss: any, userId: number): boolean
	return type(boss) == "table" and type(boss.bought) == "table" and boss.bought.buyer == userId
end

-- How many bosses this player keeps through a rebirth (own bought bosses on spots and in the crate; brief 12).
function BoughtMark.keptCount(p: any, userId: number): number
	local n = 0
	if type(p) ~= "table" then
		return 0
	end
	for _, list in ipairs({ p.bosses or {}, p.crate or {} }) do
		for _, b in ipairs(list) do
			if BoughtMark.isBuyer(b, userId) then
				n += 1
			end
		end
	end
	return n
end

-- Studio only: Systems/Base's GrantBoss hook with bought=spin|pack[,buyer=<userId>][,to=crate|<spot>][,level=n][,uid=].
-- to=head is refused: a carried boss is a beaten one, and a beaten boss never has the mark (brief 12).
function BoughtMark.grantFromHook(player: Player, o: { [string]: string })
	if not RunService:IsStudio() then
		return
	end
	local to = o.to or "crate"
	if to == "head" then
		warn("[HFB] hook GrantBoss: a bought boss goes to=crate or to=<spot>, never to=head (a carried boss is a beaten one); ignored")
		return
	end
	local buyer = tonumber(o.buyer) or player.UserId
	grantAs(player, buyer, o.creatureId, o.bought, { level = tonumber(o.level), uid = o.uid, to = to })
end

return BoughtMark
