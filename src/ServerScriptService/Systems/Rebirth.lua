--!strict
-- Systems/Rebirth: rebirth as one save operation (brief system 12; m2-contract.md C "Rebirth.*", C2, D
-- "[M2-02 M2] Rebirth, every key"). M2-14.
--
-- Rebirth.Request { confirmed = true } (the confirm screen's second press). Refused, with nothing changed, and
-- Rebirth.Result { ok = false, reason }:
--   'state'    confirmed is not exactly true; no profile; carrying anything (a fight boss, a picked-up boss, a stolen
--              one); in a fight; any of the player's bosses held or carried off by a thief (Base.isLocked) or still
--              pending arrival from a steal (Data/Transfer)
--   'save'     the profile is not saving (a temp profile: a rebirth there would be lost)
--   'max'      10 rebirths already            'power'  Power below Config.Rebirth.REQUIRED[rebirths + 1]
--   'cooldown' an accepted rebirth less than COOLDOWN_S ago
-- Accepted: ONE Session.mutate applies the whole reset (Rebirth.op, the table in Config.Rebirth.RESET / KEPT), then
-- Session.save writes it at once. Reset: Power, cash to min(cash, boughtCash) (bought cash not spent comes with you,
-- earned cash does not), Strength 1, Speed 1, every boss beaten or stolen wherever it is (a bought boss stolen from
-- its buyer too), the shield cooldown (shieldReadyAt). Kept: the player's OWN bought bosses (bought.buyer == this
-- player, which includes one the buyer stole back) at their levels, put back on spots lowest first (placed ones in
-- spot order, then the crate's in crate order) with their pads at 0 from now, the rest into the crate; and every key
-- in KEPT (rebirths + 1). A plain mutate is enough: no mark is changed, the bought ones move with their marks as they
-- are, the others leave with theirs.
-- After it: Rebirth.Result { ok, rebirths, placed, crated }; Base re-sends the plot and the crate (Session.onChanged),
-- Bag its tier; Offline.cancel closes a pending "While you were away" (its pads are gone); listeners of
-- Rebirth.onRebirth(fn(player, info)) run (M2-18: drop the player's cash-pack quotes, [M2-02 S4]; M2-15: the shield's
-- runtime cooldown).
-- Hook SetRebirths (state, Studio): the rebirth count becomes n (0..10).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)
local Session = require(script.Parent.Parent.Data.Session)
local Transfer = require(script.Parent.Parent.Data.Transfer)
local Zones = require(script.Parent.Zones)
local Carry = require(script.Parent.Carry)
local Fight = require(script.Parent.Fight)
local Base = require(script.Parent.Base)
local Offline = require(script.Parent.Offline)
local BoughtMark = require(script.Parent.BoughtMark)

local Rebirth = {}

Rebirth.stats = { results = {} :: { any } }

local lastAt: { [Player]: number } = {}
local listeners: { (Player, any) -> () } = {}

function Rebirth.onRebirth(fn: (Player, any) -> ())
	table.insert(listeners, fn)
end

-- Power needed for the next rebirth (nil at the maximum).
function Rebirth.required(rebirths: number): number?
	if rebirths >= Config.Rebirth.MAX then
		return nil
	end
	return Config.Rebirth.REQUIRED[rebirths + 1]
end

function Rebirth.keptCount(player: Player): number
	return BoughtMark.keptCount(Session.get(player), player.UserId)
end

-- The whole reset on a profile-shaped table (pure). unlockedFor(rebirths) -> dense { boolean } 1..MAX_SPOTS.
-- Returns placed, crated (the kept bought bosses).
function Rebirth.op(q: any, userId: number, now: number, unlockedFor: (number) -> { boolean }): (number, number)
	local kept = {}
	local placed = table.clone(q.bosses)
	table.sort(placed, function(a, b)
		return a.spot < b.spot
	end)
	for _, b in ipairs(placed) do
		if BoughtMark.isBuyer(b, userId) then
			table.insert(kept, b)
		end
	end
	for _, b in ipairs(q.crate) do
		if BoughtMark.isBuyer(b, userId) then
			table.insert(kept, b)
		end
	end
	q.power = Config.Bag.START_POWER
	q.cash = math.min(q.cash, q.boughtCash)
	q.strengthLevel = Config.Bag.DEFAULT_STRENGTH
	q.speedLevel = Config.Bag.DEFAULT_SPEED
	q.shieldReadyAt = 0
	q.rebirths += 1
	local unlocked = unlockedFor(q.rebirths)
	local bosses, crate = {}, {}
	local nextSpot = 1
	for _, b in ipairs(kept) do
		while nextSpot <= Config.Base.MAX_SPOTS and not unlocked[nextSpot] do
			nextSpot += 1
		end
		if nextSpot <= Config.Base.MAX_SPOTS then
			table.insert(bosses, { uid = b.uid, creatureId = b.creatureId, level = b.level, spot = nextSpot, padCash = 0, padStamp = now, bought = table.clone(b.bought) })
			nextSpot += 1
		else
			table.insert(crate, { uid = b.uid, creatureId = b.creatureId, level = b.level, bought = table.clone(b.bought) })
		end
	end
	q.bosses = bosses
	q.crate = crate
	return #bosses, #crate
end

local function lockedBoss(player: Player, p: any): boolean
	for _, list in ipairs({ p.bosses, p.crate }) do
		for _, b in ipairs(list) do
			if Base.isLocked(b.uid) or Transfer.isPending(player, b.uid) then
				return true
			end
		end
	end
	return false
end

-- Why a rebirth would be refused now, or nil.
function Rebirth.refusal(player: Player): string?
	local p = Session.get(player)
	if not p then
		return "state"
	end
	if not Session.isSaving(player) then
		return "save"
	end
	if p.rebirths >= Config.Rebirth.MAX then
		return "max"
	end
	local need = Rebirth.required(p.rebirths)
	if not need or p.power < need then
		return "power"
	end
	if Carry.get(player) ~= nil or p.carry ~= nil or Fight.get(player) ~= nil or lockedBoss(player, p) then
		return "state"
	end
	local last = lastAt[player]
	if last and os.clock() - last < Config.Rebirth.COOLDOWN_S then
		return "cooldown"
	end
	return nil
end

local function answer(player: Player, r: any)
	table.insert(Rebirth.stats.results, { userId = player.UserId, ok = r.ok, reason = r.reason, rebirths = r.rebirths, placed = r.placed, crated = r.crated, at = os.clock() })
	if #Rebirth.stats.results > 50 then
		table.remove(Rebirth.stats.results, 1)
	end
	TestHooks.reports.rebirth = r
	if player.Parent == Players then
		Net.get("Rebirth", "Result"):FireClient(player, r)
	end
	return r
end

-- The Rebirth.Request handler (also the check's entry point). Returns the Result sent.
function Rebirth.request(player: Player, payload: any): any
	if type(payload) ~= "table" or payload.confirmed ~= true then
		return answer(player, { ok = false, reason = "state" })
	end
	local why = Rebirth.refusal(player)
	if why then
		return answer(player, { ok = false, reason = why })
	end
	local userId = player.UserId
	local now = Zones.now()
	local placed, crated = 0, 0
	local ok = Session.mutate(player, function(q)
		placed, crated = Rebirth.op(q, userId, now, function(n)
			return (Base.unlocked(player, { rebirths = n }))
		end)
	end)
	if not ok then
		return answer(player, { ok = false, reason = "state" })
	end
	lastAt[player] = os.clock()
	local p = Session.get(player)
	local info = { rebirths = p and p.rebirths or 0, placed = placed, crated = crated }
	print(("[HFB][rebirth] %d rebirth %d: %d bought bosses placed, %d to the crate, cash $%s kept"):format(userId, info.rebirths, placed, crated, tostring(p and p.cash)))
	Offline.cancel(player)
	for _, fn in ipairs(listeners) do
		task.spawn(fn, player, info)
	end
	-- the reset is written at once (one record, one UpdateAsync); a failed write is retried by autosave and the leave
	task.spawn(function()
		local okS, st = Session.save(player, "rebirth")
		if not okS then
			warn(("[HFB] Rebirth: save after rebirth failed for %d (%s); autosave retries"):format(userId, tostring(st)))
		end
	end)
	return answer(player, { ok = true, rebirths = info.rebirths, placed = placed, crated = crated })
end

function Rebirth.start()
	Net.onServerEvent("Rebirth", "Request", function(player, payload)
		Rebirth.request(player, payload)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastAt[player] = nil
	end)
	TestHooks.onSet("SetRebirths", function(v)
		if not Net.isInt(v, 0, Config.Rebirth.MAX) then
			if v ~= nil then
				warn("[HFB] hook SetRebirths ignored: " .. tostring(v))
			end
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if Session.get(player) then
				Session.set(player, "rebirths", v)
			end
		end
	end)
end

return Rebirth
