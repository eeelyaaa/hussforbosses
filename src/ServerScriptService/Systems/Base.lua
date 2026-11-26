--!strict
-- Systems/Base: the plot's spots, place, pick up, swap, sell, the delivery crate, and the plot's state for every
-- client (brief system 7; m2-contract.md C "Base", C2, D with [M2-02 M5, M8]).
--
-- Spots: 1..10 always; 11..15 one per rebirth (up to 5); 16 and 17 with the Extra Spots pass (Bag.owns, cached).
-- Duplicates are allowed (each copy its own uid and level). Every boss op is ONE Session.mutate; refused requests
-- change nothing and answer Base.Result { action, ok = false, reason } with a reason from Net's list.
-- The boss being stolen ([M2-02 M5]): Systems/Steal (M2-15) registers Base.setLockCheck(fn(uid) -> boolean); while
-- it says true, PickUp, Swap (as the placed boss), Upgrade and Place onto that spot are refused 'locked'.
--
-- Where a boss's pad cash goes (TEAM CALL M2-11-2): the save keeps pad cash per boss (padCash), not per spot, so when
-- a boss leaves its spot for good (placed on another spot, swapped out, sold) the cash on its old pad is collected for
-- the owner in the same mutate (Base.Collected is sent, as for a walk-over). While a picked-up boss is carried it stays
-- on its spot in the save, its pad keeps its cash and can be collected, and it does not fill.
--
-- c2s: Base.Place { spotIndex }, PickUp { spotIndex }, Swap { spotIndex }, Sell {}, TakeCrate { uid }.
-- s2c: Base.State (all players) { plotId, ownerUserId, spotsCap, crateCount, rebirthSpots, extraSpots, unlocked,
--        spots } where spots and unlocked are DENSE arrays 1..17 (TEAM CALL M1-11g); an empty spot is `false`, a
--        filled one { uid, creatureId, level, income, stamp, padCash, capSeconds, bought, carried, nextCost };
--      Base.Crate (owner) { items }; Base.Result (caller); Profile.Notice spotsFull / spotsFullOffer.
-- Hook GrantBoss (state, Studio): '<creatureId>[,to=head|crate|<spot>][,level=n][,uid=..][,bought=..,buyer=..]'.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Ids = require(Shared.Ids)
local TestHooks = require(Shared.TestHooks)
local Session = require(script.Parent.Parent.Data.Session)
-- A stolen boss whose transfer is not yet saved on both sides (Data/Transfer.isPending: the thief's arrival note is
-- still waiting for the owner's write) cannot be sold or swapped away (M2-11b): a sale then a crash could leave the
-- cash with the thief and the boss with the owner.
local Transfer = require(script.Parent.Parent.Data.Transfer)
local Zones = require(script.Parent.Zones)
local Bag = require(script.Parent.Bag)
local Carry = require(script.Parent.Carry)
local Income = require(script.Parent.Income)
local Funnel = require(script.Parent.Funnel)

local Base = {}

Base.stats = { refused = {} :: { [string]: number }, placed = {} :: { any }, results = {} :: { any } }

-- Internal reasons (kept for the checks; M1 names) -> the reason the client sees (Net: Base.Result).
local CLIENT_REASON = {
	bad = "state", state = "state", notCarrying = "state", taken = "spot", spot = "spot", plot = "notYours",
	notYours = "notYours", range = "range", locked = "locked", full = "full",
}

local lockCheck: (string) -> boolean = function(_uid)
	return false
end
local alertCheck: (Player) -> boolean = function(_player)
	return false
end

-- Systems/Steal: fn(uid) -> true while that boss is held or carried off by a thief.
function Base.setLockCheck(fn: (string) -> boolean)
	lockCheck = fn
end
-- Systems/Steal: fn(player) -> true while that player has a steal or shield-broken alert on (the Extra Spots offer
-- is never shown then).
function Base.setAlertCheck(fn: (Player) -> boolean)
	alertCheck = fn
end
function Base.isLocked(uid: string): boolean
	local ok, v = pcall(lockCheck, uid)
	return ok and v == true
end

local function result(player: Player, action: string, reason: string?, spotIndex: number?, amount: number?): string?
	if reason then
		Base.stats.refused[reason] = (Base.stats.refused[reason] or 0) + 1
	end
	local r = { action = action, ok = reason == nil, reason = reason and (CLIENT_REASON[reason] or "state"), spotIndex = spotIndex, amount = amount }
	table.insert(Base.stats.results, { userId = player.UserId, action = action, ok = r.ok, reason = reason, spotIndex = spotIndex, amount = amount })
	if #Base.stats.results > 200 then
		table.remove(Base.stats.results, 1)
	end
	if player.Parent == Players then
		Net.get("Base", "Result"):FireClient(player, r)
	end
	return reason
end

-- ------------------------------------------------------------------------------------------------ plots and spots
local function plots(): { Model }
	local out = {}
	local root = workspace:FindFirstChild("Plots")
	if root then
		for _, m in ipairs(root:GetChildren()) do
			if m:IsA("Model") and typeof(m:GetAttribute("PlotId")) == "number" then
				table.insert(out, m)
			end
		end
	end
	return out
end

local function ownerOf(plot: Model): Player?
	local uid = plot:GetAttribute("OwnerUserId")
	if typeof(uid) ~= "number" or uid == 0 then
		return nil
	end
	return Players:GetPlayerByUserId(uid)
end

function Base.spotPart(plot: Model, i: number): BasePart?
	local s = plot:FindFirstChild("Spot_" .. i)
	if s and s:IsA("BasePart") and s:GetAttribute("SpotIndex") == i then
		return s
	end
	return nil
end

-- Which spots the player has: a dense array 1..17 of booleans, and how many.
function Base.unlocked(player: Player, p: any?): ({ boolean }, number)
	local prof = p or Session.get(player)
	local out = table.create(Config.Base.MAX_SPOTS, false) :: { boolean }
	local n = 0
	for i = 1, Config.Base.SPOTS_AT_START do
		out[i] = true
		n += 1
	end
	local r = if prof then math.clamp(prof.rebirths or 0, 0, Config.Base.REBIRTH_SPOTS) else 0
	for i = 1, r do
		out[Config.Base.SPOTS_AT_START + i] = true
		n += 1
	end
	if Bag.owns(player, Config.Base.EXTRA_PASS) then
		for _, i in ipairs(Config.Base.EXTRA_SPOTS) do
			out[i] = true
			n += 1
		end
	end
	return out, n
end

function Base.bossAt(p: any, spotIndex: number): (any, number?)
	for k, b in ipairs(p.bosses) do
		if b.spot == spotIndex then
			return b, k
		end
	end
	return nil, nil
end

local function byUid(list: { any }, uid: string): (any, number?)
	for k, b in ipairs(list) do
		if b.uid == uid then
			return b, k
		end
	end
	return nil, nil
end

-- A free unlocked spot for this player (the carried picked-up boss's own spot counts as free), or nil.
function Base.freeSpot(player: Player, p: any): number?
	local unlocked = Base.unlocked(player, p)
	local carriedUid = p.carry and p.carry.origin == "spot" and p.carry.uid
	for i = 1, Config.Base.MAX_SPOTS do
		if unlocked[i] then
			local b = Base.bossAt(p, i)
			if not b or b.uid == carriedUid then
				return i
			end
		end
	end
	return nil
end

local function inRange(player: Player, part: BasePart): boolean
	local r = Bag.root(player)
	if not r then
		return false
	end
	local d = r.Position - part.Position
	return Vector3.new(d.X, 0, d.Z).Magnitude <= Config.Base.PLACE_RANGE and math.abs(d.Y) <= Config.Base.PLACE_HEIGHT
end

local function ownPlot(player: Player): Model?
	local plot = Session.plot(player)
	if plot and plot:GetAttribute("OwnerUserId") == player.UserId then
		return plot
	end
	return nil
end

-- ------------------------------------------------------------------------------------------------ state payloads
function Base.payload(plot: Model): any
	local owner = ownerOf(plot)
	local p = owner and Session.get(owner)
	local spots = table.create(Config.Base.MAX_SPOTS, false) :: { any }
	local unlocked = table.create(Config.Base.MAX_SPOTS, false) :: { boolean }
	local cap, crateCount, rebirthSpots, extra = 0, 0, 0, false
	if owner and p then
		unlocked, cap = Base.unlocked(owner, p)
		crateCount = #p.crate
		rebirthSpots = math.clamp(p.rebirths or 0, 0, Config.Base.REBIRTH_SPOTS)
		extra = Bag.owns(owner, Config.Base.EXTRA_PASS)
		local mult = Income.mult(owner, p)
		local carriedUid = p.carry and p.carry.origin == "spot" and p.carry.uid
		for _, b in ipairs(p.bosses) do
			if b.spot >= 1 and b.spot <= Config.Base.MAX_SPOTS then
				local base = Config.Zones.INCOME[b.creatureId] or 0
				spots[b.spot] = {
					uid = b.uid,
					creatureId = b.creatureId,
					level = b.level,
					income = Income.rate(p, b, mult),
					stamp = b.padStamp,
					padCash = b.padCash,
					capSeconds = Config.Base.PAD_CAP_S,
					bought = if b.bought then b.bought.source else false,
					carried = b.uid == carriedUid,
					nextCost = Config.Upgrades.COST(base, b.level),
				}
			end
		end
	end
	return {
		plotId = plot:GetAttribute("PlotId"),
		ownerUserId = if owner then owner.UserId else 0,
		spotsCap = cap,
		crateCount = crateCount,
		rebirthSpots = rebirthSpots,
		extraSpots = extra,
		unlocked = unlocked,
		spots = spots,
	}
end

local function setGlow(plot: Model)
	local owner = ownerOf(plot)
	local p = owner and Session.get(owner)
	local c = owner and Carry.get(owner)
	local carrying = c ~= nil and c.state == "carrying" and c.origin ~= "stolen"
	local unlocked = if owner and p then (Base.unlocked(owner, p)) else table.create(Config.Base.MAX_SPOTS, false)
	for i = 1, Config.Base.MAX_SPOTS do
		local s = Base.spotPart(plot, i)
		if s then
			local b = p and Base.bossAt(p, i)
			local glow = carrying and unlocked[i] and (b == nil or b.uid == (c :: any).uid)
			if s:GetAttribute("Glow") ~= glow then
				s:SetAttribute("Glow", glow)
			end
			if s:GetAttribute("Unlocked") ~= unlocked[i] then
				s:SetAttribute("Unlocked", unlocked[i])
			end
		end
	end
end

function Base.broadcast(plot: Model)
	setGlow(plot)
	Net.get("Base", "State"):FireAllClients(Base.payload(plot))
end

local dirty: { [Model]: boolean } = {}
local function markDirty(plot: Model?)
	if not plot or dirty[plot] then
		return
	end
	dirty[plot] = true
	task.defer(function()
		dirty[plot] = nil
		if plot.Parent then
			Base.broadcast(plot)
		end
	end)
end

function Base.sendCrate(player: Player)
	local p = Session.get(player)
	if not p or player.Parent ~= Players then
		return
	end
	local items = {}
	for _, b in ipairs(p.crate) do
		table.insert(items, { uid = b.uid, creatureId = b.creatureId, level = b.level, bought = if b.bought then b.bought.source else false })
	end
	Net.get("Base", "Crate"):FireClient(player, { items = items })
end

-- Re-sends the player's plot and crate (Systems/Passes calls it after a pass purchase changes the spots).
function Base.refresh(player: Player)
	markDirty(Session.plot(player))
	Base.sendCrate(player)
end

-- ------------------------------------------------------------------------------------------------ pure ops
-- Takes a boss's pad cash (settled) for its owner inside a mutate; adds { spot, amount } to `collected`.
local function takePad(q: any, b: any, now: number, mult: number, collected: { any })
	local amount = Income.settleOp(q, b, now, mult)
	b.padCash = 0
	if amount > 0 then
		Session.ops.addCash(q, amount, false)
		table.insert(collected, { spot = b.spot, amount = amount })
	end
end

-- The carried boss goes onto spot `spotIndex` (inside a mutate). Errors when the profile does not hold what the
-- carry says (the mutate then applies nothing).
local function placeOp(q: any, c: any, spotIndex: number, now: number, mult: number, collected: { any })
	if c.origin == "fight" then
		table.insert(q.bosses, { uid = c.uid, creatureId = c.creatureId, level = c.level, spot = spotIndex, padCash = 0, padStamp = now })
	elseif c.origin == "crate" then
		local e, k = byUid(q.crate, c.uid)
		assert(e and k, "crate boss missing")
		table.remove(q.crate, k)
		table.insert(q.bosses, { uid = e.uid, creatureId = e.creatureId, level = e.level, spot = spotIndex, padCash = 0, padStamp = now, bought = e.bought })
	elseif c.origin == "spot" then
		local b = byUid(q.bosses, c.uid)
		assert(b, "picked-up boss missing")
		if b.spot ~= spotIndex then
			takePad(q, b, now, mult, collected)
			b.spot = spotIndex
			b.padCash = 0
			b.padStamp = now
		else
			b.padStamp = math.max(b.padStamp, now)
		end
	else
		error("origin " .. tostring(c.origin) .. " is not placed by Base")
	end
	table.sort(q.bosses, function(x, y)
		return x.spot < y.spot
	end)
end

local function markPlaced(player: Player, creatureId: string)
	Funnel.mark(player, "FirstBossPlaced")
	local zone = Ids.parseCreature(creatureId)
	if zone == 2 then
		Funnel.mark(player, "Zone2BossPlaced")
	end
end

local function sendCollected(player: Player, collected: { any })
	for _, e in ipairs(collected) do
		Income.collected(player, e.spot, e.amount)
	end
end

-- Sale value of a boss: 20 x its income per second now (level, rebirth, 2x Cash), never 0 for a carried one.
function Base.sellValue(player: Player, p: any, creatureId: string, level: number): number
	return Config.Base.SELL_MULT * Income.perSecond(creatureId, level) * Income.mult(player, p)
end

-- ------------------------------------------------------------------------------------------------ requests
-- Each returns nil on success or the internal refusal reason.

function Base.tryPlace(player: Player, spotIndex: any): string?
	if not Net.isInt(spotIndex, 1, Config.Base.MAX_SPOTS) then
		return result(player, "place", "bad")
	end
	local p = Session.get(player)
	if not p then
		return result(player, "place", "state", spotIndex)
	end
	local c = Carry.get(player)
	if not c or c.state ~= "carrying" then
		return result(player, "place", "notCarrying", spotIndex)
	end
	if c.origin == "stolen" then
		return result(player, "place", "state", spotIndex) -- a steal completes through Systems/Steal
	end
	local plot = ownPlot(player)
	if not plot then
		return result(player, "place", "plot", spotIndex)
	end
	local unlocked = Base.unlocked(player, p)
	if not unlocked[spotIndex] then
		return result(player, "place", "bad", spotIndex)
	end
	local part = Base.spotPart(plot, spotIndex)
	if not part then
		return result(player, "place", "spot", spotIndex)
	end
	local occ = Base.bossAt(p, spotIndex)
	if occ and occ.uid ~= c.uid then
		return result(player, "place", if Base.isLocked(occ.uid) then "locked" else "taken", spotIndex)
	end
	if not inRange(player, part) then
		return result(player, "place", "range", spotIndex)
	end
	local now = Zones.now()
	local mult = Income.mult(player, p)
	local collected = {}
	table.insert(Base.stats.placed, { userId = player.UserId, spotIndex = spotIndex, uid = c.uid, creatureId = c.creatureId, origin = c.origin, at = now })
	local cc = table.clone(c)
	if not Session.mutate(player, function(q)
		placeOp(q, cc, spotIndex, now, mult, collected)
	end) then
		return result(player, "place", "state", spotIndex)
	end
	Carry.take(player)
	sendCollected(player, collected)
	markPlaced(player, c.creatureId)
	return result(player, "place", nil, spotIndex)
end

function Base.tryPickUp(player: Player, spotIndex: any): string?
	if not Net.isInt(spotIndex, 1, Config.Base.MAX_SPOTS) then
		return result(player, "pickUp", "bad")
	end
	local p = Session.get(player)
	if not p or Carry.get(player) then
		return result(player, "pickUp", "state", spotIndex)
	end
	local plot = ownPlot(player)
	if not plot then
		return result(player, "pickUp", "plot", spotIndex)
	end
	local b = Base.bossAt(p, spotIndex)
	if not b then
		return result(player, "pickUp", "spot", spotIndex)
	end
	if Base.isLocked(b.uid) then
		return result(player, "pickUp", "locked", spotIndex)
	end
	local part = Base.spotPart(plot, spotIndex)
	if not part then
		return result(player, "pickUp", "spot", spotIndex)
	end
	if not inRange(player, part) then
		return result(player, "pickUp", "range", spotIndex)
	end
	local now = Zones.now()
	local mult = Income.mult(player, p)
	local uid = b.uid
	-- the pad keeps its cash (brief 8); settle it now so the carried stretch adds nothing
	if not Session.mutate(player, function(q)
		local qb = byUid(q.bosses, uid)
		assert(qb, "boss missing")
		Income.settleOp(q, qb, now, mult)
	end) then
		return result(player, "pickUp", "state", spotIndex)
	end
	if not Carry.begin(player, b.creatureId, { origin = "spot", uid = uid, level = b.level, bought = b.bought, spot = spotIndex }) then
		return result(player, "pickUp", "state", spotIndex)
	end
	return result(player, "pickUp", nil, spotIndex)
end

function Base.trySwap(player: Player, spotIndex: any): string?
	if not Net.isInt(spotIndex, 1, Config.Base.MAX_SPOTS) then
		return result(player, "swap", "bad")
	end
	local p = Session.get(player)
	if not p then
		return result(player, "swap", "state", spotIndex)
	end
	local c = Carry.get(player)
	if not c or c.state ~= "carrying" then
		return result(player, "swap", "notCarrying", spotIndex)
	end
	if c.origin == "stolen" then
		return result(player, "swap", "state", spotIndex)
	end
	local plot = ownPlot(player)
	if not plot then
		return result(player, "swap", "plot", spotIndex)
	end
	local b = Base.bossAt(p, spotIndex)
	if not b or b.uid == c.uid then
		return result(player, "swap", "spot", spotIndex)
	end
	if Base.isLocked(b.uid) or Transfer.isPending(player, b.uid) then
		return result(player, "swap", "locked", spotIndex)
	end
	local part = Base.spotPart(plot, spotIndex)
	if not part then
		return result(player, "swap", "spot", spotIndex)
	end
	if not inRange(player, part) then
		return result(player, "swap", "range", spotIndex)
	end
	local now = Zones.now()
	local mult = Income.mult(player, p)
	local value = Base.sellValue(player, p, b.creatureId, b.level)
	local soldUid = b.uid
	local collected = {}
	table.insert(Base.stats.placed, { userId = player.UserId, spotIndex = spotIndex, uid = c.uid, creatureId = c.creatureId, origin = c.origin, at = now, swap = soldUid })
	local cc = table.clone(c)
	if not Session.mutate(player, function(q)
		local qb, k = byUid(q.bosses, soldUid)
		assert(qb and k, "placed boss missing")
		takePad(q, qb, now, mult, collected)
		table.remove(q.bosses, k)
		Session.ops.addCash(q, value, false)
		placeOp(q, cc, spotIndex, now, mult, collected)
	end) then
		return result(player, "swap", "state", spotIndex)
	end
	Carry.take(player)
	sendCollected(player, collected)
	markPlaced(player, c.creatureId)
	return result(player, "swap", nil, spotIndex, value)
end

function Base.trySell(player: Player): string?
	local p = Session.get(player)
	if not p then
		return result(player, "sell", "state")
	end
	local c = Carry.get(player)
	if not c or c.state ~= "carrying" then
		return result(player, "sell", "notCarrying")
	end
	if c.origin == "stolen" then
		return result(player, "sell", "state")
	end
	if Transfer.isPending(player, c.uid) then -- any origin: a stolen boss arrives in the crate or on the head (M2-27 MF2)
		return result(player, "sell", "locked")
	end
	if not ownPlot(player) or not Carry.insideOwnPlot(player) then
		return result(player, "sell", "range")
	end
	local now = Zones.now()
	local mult = Income.mult(player, p)
	local value = Base.sellValue(player, p, c.creatureId, c.level)
	local collected = {}
	local cc = table.clone(c)
	if not Session.mutate(player, function(q)
		if cc.origin == "crate" then
			local _, k = byUid(q.crate, cc.uid)
			assert(k, "crate boss missing")
			table.remove(q.crate, k)
		elseif cc.origin == "spot" then
			local qb, k = byUid(q.bosses, cc.uid)
			assert(qb and k, "picked-up boss missing")
			takePad(q, qb, now, mult, collected)
			table.remove(q.bosses, k)
		end
		Session.ops.addCash(q, value, false)
	end) then
		return result(player, "sell", "state")
	end
	Carry.take(player)
	sendCollected(player, collected)
	return result(player, "sell", nil, nil, value)
end

function Base.tryTakeCrate(player: Player, uid: any): string?
	if not Net.isShortString(uid, 40) then
		return result(player, "takeCrate", "bad")
	end
	local p = Session.get(player)
	if not p or Carry.get(player) then
		return result(player, "takeCrate", "state")
	end
	if not ownPlot(player) or not Carry.insideOwnPlot(player) then
		return result(player, "takeCrate", "range")
	end
	local e = byUid(p.crate, uid)
	if not e then
		return result(player, "takeCrate", "notYours")
	end
	if Transfer.isPending(player, uid) then
		return result(player, "takeCrate", "locked") -- its steal is not saved on both sides yet (M2-27 MF2)
	end
	if not Base.freeSpot(player, p) then
		local offer = not Bag.owns(player, Config.Base.EXTRA_PASS) and not alertCheck(player)
		Net.get("Profile", "Notice"):FireClient(player, { kind = if offer then "spotsFullOffer" else "spotsFull" })
		return result(player, "takeCrate", "full")
	end
	if not Carry.begin(player, e.creatureId, { origin = "crate", uid = e.uid, level = e.level, bought = e.bought }) then
		return result(player, "takeCrate", "state")
	end
	return result(player, "takeCrate", nil)
end

-- ------------------------------------------------------------------------------------------------ the GrantBoss hook
local function parseGrant(v: string): { [string]: string }
	local out = {}
	local parts = string.split(v, ",")
	out.creatureId = parts[1]
	for i = 2, #parts do
		local k, val = parts[i]:match("^%s*([%w]+)%s*=%s*(.-)%s*$")
		if k then
			out[k] = val
		end
	end
	return out
end

local function grantOne(player: Player, o: { [string]: string })
	local level = tonumber(o.level) or Config.Income.DEFAULT_LEVEL
	local to = o.to or "head"
	if o.bought then
		local m = script.Parent:FindFirstChild("BoughtMark")
		local ok, BM = pcall(function()
			return m and require(m) :: any
		end)
		if ok and BM and type(BM.grantFromHook) == "function" then
			BM.grantFromHook(player, o) -- M2-14 owns the bought mark
		else
			warn("[HFB] hook GrantBoss: bought= needs Systems/BoughtMark.grantFromHook (M2-14); ignored")
		end
		return
	end
	if to == "head" then
		local c = Carry.get(player)
		if c then
			Carry.lose(player, "granted")
		end
		Carry.begin(player, o.creatureId, { uid = o.uid, level = level })
		return
	end
	local uid = o.uid or Session.newUid(player)
	if not uid then
		warn("[HFB] hook GrantBoss: no profile")
		return
	end
	local now = Zones.now()
	local spot = tonumber(to)
	local ok = Session.mutate(player, function(q)
		if to == "crate" then
			table.insert(q.crate, { uid = uid, creatureId = o.creatureId, level = level })
		else
			assert(spot and Net.isInt(spot, 1, Config.Base.MAX_SPOTS), "bad to=")
			assert(Base.bossAt(q, spot) == nil, "spot taken")
			table.insert(q.bosses, { uid = uid, creatureId = o.creatureId, level = level, spot = spot, padCash = 0, padStamp = now })
			table.sort(q.bosses, function(x, y)
				return x.spot < y.spot
			end)
		end
	end)
	if not ok then
		warn("[HFB] hook GrantBoss refused: " .. tostring(o.creatureId) .. " to=" .. tostring(to))
	end
end

-- ------------------------------------------------------------------------------------------------ start
function Base.start()
	Net.onServerEvent("Base", "Place", function(player, payload)
		Base.tryPlace(player, payload.spotIndex)
	end)
	Net.onServerEvent("Base", "PickUp", function(player, payload)
		Base.tryPickUp(player, payload.spotIndex)
	end)
	Net.onServerEvent("Base", "Swap", function(player, payload)
		Base.trySwap(player, payload.spotIndex)
	end)
	Net.onServerEvent("Base", "Sell", function(player, _payload)
		Base.trySell(player)
	end)
	Net.onServerEvent("Base", "TakeCrate", function(player, payload)
		Base.tryTakeCrate(player, payload.uid)
	end)

	-- Any change to a player's bosses, crate, rebirths (spot count) or carry re-sends their plot.
	Session.onChanged(function(player, key, _value)
		if key == "bosses" or key == "spots" or key == "rebirths" or key == "carry" or key == "crate" then
			markDirty(Session.plot(player))
		end
		if key == "crate" then
			Base.sendCrate(player)
		end
	end)
	Carry.onChanged(function(player, _state, _c)
		markDirty(Session.plot(player))
	end)

	-- Join: every plot's state to the joiner, the joiner's plot to everyone, the crate to the joiner.
	Session.onJoin(function(player)
		for _, plot in ipairs(plots()) do
			Net.get("Base", "State"):FireClient(player, Base.payload(plot))
		end
		markDirty(Session.plot(player))
		Base.sendCrate(player)
	end)
	local function watchPlot(plot: Instance)
		if not plot:IsA("Model") then
			return
		end
		plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			markDirty(plot :: Model)
		end)
		setGlow(plot :: Model)
	end
	for _, plot in ipairs(plots()) do
		watchPlot(plot)
	end
	local root = workspace:FindFirstChild("Plots")
	if root then
		root.ChildAdded:Connect(watchPlot)
	end

	-- Carrying into a full base: the orange "Spots full" toast, no offer (brief 7). Checked 4 times a second.
	local wasInside: { [Player]: boolean } = {}
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, player in ipairs(Players:GetPlayers()) do
				local c = Carry.get(player)
				local inside = c ~= nil and c.state == "carrying" and c.origin == "fight" and Carry.insideOwnPlot(player)
				if inside and not wasInside[player] then
					local p = Session.get(player)
					if p and not Base.freeSpot(player, p) then
						Net.get("Profile", "Notice"):FireClient(player, { kind = "spotsFull" })
					end
				end
				wasInside[player] = inside or nil
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		wasInside[p] = nil
	end)

	TestHooks.onSet("GrantBoss", function(v)
		if typeof(v) ~= "string" then
			warn("[HFB] hook GrantBoss ignored: " .. tostring(v))
			return
		end
		local o = parseGrant(v)
		if Config.Zones.POWER[o.creatureId] == nil then
			warn("[HFB] hook GrantBoss ignored: " .. tostring(v))
			return
		end
		for _, p in ipairs(Players:GetPlayers()) do
			if Session.get(p) then
				grantOne(p, o)
			end
		end
	end)
end

return Base
