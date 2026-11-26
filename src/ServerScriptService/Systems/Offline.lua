--!strict
-- Systems/Offline: "While you were away" (brief system 11; m2-contract.md C "Offline.*" with [M2-02 M9]). M2-14.
--
-- The amount is the fill of the player's own pads while away, never new money. On join (and on the Rejoin and LeaveAt
-- hooks) the server works out, for each boss on a spot, with the saved leave time `leftAt` and its own clock
-- (Zones.now(): server time + the ClockOffset hook, the same clock the pads fill on):
--     earned = onPad(now) - onPad(leftAt)      (Income.onPad: whole seconds, the 2-hour pad cap, cash already on the
--                                               pad counting toward the cap, rebirth and 2x Cash multipliers)
-- floored to whole cash. Shown (Offline.Summary) only when away >= MIN_AWAY_S and the total > 0.
-- Offline.Collect {} (only while a summary is pending, once): ONE mutate settles each listed boss's pad and moves
-- min(earned, padCash) from that pad to cash (earned cash). A boss no longer on the same spot (sold, picked up and
-- placed elsewhere, stolen, rebirth) pays 0, and a pad already walked over pays only what is left on it, so the
-- summary can never pay on top of the pads. Auto Punch and Power never run offline (nothing here touches them).
--
-- API: Offline.compute(player) -> summary?   Offline.pending(player) -> summary?   Offline.collect(player) -> number?
--      Offline.cancel(player)  (Systems/Rebirth: a rebirth clears the pads, so the pending summary closes, pays 0)
-- Hook LeaveAt (state, Studio): seconds n: leftAt and every pad stamp move back n seconds (as if the player had left
--      n seconds ago with the pads as they are), then the join's computation runs again (summary if >= 60 s).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)
local Session = require(script.Parent.Parent.Data.Session)
local Zones = require(script.Parent.Zones)
local Income = require(script.Parent.Income)

local Offline = {}

type Entry = { amount: number, spot: number }
type Pending = { seconds: number, total: number, perBoss: { [string]: Entry }, at: number, gen: number }

local pendings: { [Player]: Pending } = {}
local gens: { [Player]: number } = {}

Offline.stats = { summaries = {} :: { any }, collects = {} :: { any } }

local function push(list: { any }, e: any)
	table.insert(list, e)
	if #list > 50 then
		table.remove(list, 1)
	end
end

local function payload(s: Pending): any
	local per = {}
	for uid, e in pairs(s.perBoss) do
		per[uid] = e.amount
	end
	return { seconds = s.seconds, total = s.total, perBoss = per }
end

local function send(player: Player, s: Pending)
	if player.Parent == Players then
		Net.get("Offline", "Summary"):FireClient(player, payload(s))
	end
end

-- Works out what the pads earned while away. Pure read; returns the summary or nil (nothing to show).
function Offline.compute(player: Player): (Pending?, number)
	local p = Session.get(player)
	if not p or type(p.leftAt) ~= "number" or p.leftAt <= 0 then
		return nil, 0
	end
	local now = Zones.now()
	local away = math.floor(now - p.leftAt)
	if away < Config.Offline.MIN_AWAY_S then
		return nil, away
	end
	local mult = Income.mult(player, p)
	local per: { [string]: Entry } = {}
	local total = 0
	for _, b in ipairs(p.bosses) do
		local before = Income.onPad(p, b, p.leftAt, mult)
		local after = Income.onPad(p, b, now, mult)
		local e = math.floor(after - before)
		if e > 0 then
			per[b.uid] = { amount = e, spot = b.spot }
			total += e
		end
	end
	if total <= 0 then
		return nil, away
	end
	return { seconds = away, total = total, perBoss = per, at = now, gen = 0 }, away
end

function Offline.pending(player: Player): any
	local s = pendings[player]
	return s and payload(s)
end

-- Computes and (if there is something) holds the summary, then sends it at each SEND_AT_S while not collected.
local function begin(player: Player)
	gens[player] = (gens[player] or 0) + 1
	local gen = gens[player]
	local s, away = Offline.compute(player)
	push(Offline.stats.summaries, { userId = player.UserId, away = away, shown = s ~= nil, total = s and s.total or 0, at = os.clock() })
	TestHooks.reports.offline = { userId = player.UserId, away = away, shown = s ~= nil, summary = s and payload(s) or nil }
	if not s then
		pendings[player] = nil
		return
	end
	s.gen = gen
	pendings[player] = s
	print(("[HFB][offline] %d away %d s, earned $%d on %d pads"):format(player.UserId, away, s.total, (function()
		local n = 0
		for _ in pairs(s.perBoss) do
			n += 1
		end
		return n
	end)()))
	local t0 = 0
	for _, t in ipairs(Config.Offline.SEND_AT_S) do
		task.wait(math.max(0, t - t0))
		t0 = t
		local cur = pendings[player]
		if cur ~= s or gens[player] ~= gen then
			return
		end
		send(player, s)
	end
end

local function result(player: Player, ok: boolean, reason: string?, amount: number?)
	if player.Parent == Players then
		Net.get("Offline", "Result"):FireClient(player, { ok = ok, reason = reason, amount = amount })
	end
end

-- Collect: one mutate that takes the offline amount from the pads. Returns the amount paid (nil when refused).
function Offline.collect(player: Player): number?
	local s = pendings[player]
	if not s then
		result(player, false, "none")
		return nil
	end
	pendings[player] = nil -- collect once: a second Collect finds nothing pending
	local now = Zones.now()
	local mult = Income.mult(player)
	local paid = 0
	local ok = Session.mutate(player, function(q)
		paid = 0
		for _, b in ipairs(q.bosses) do
			local e = s.perBoss[b.uid]
			if e and b.spot == e.spot then
				local onPad = Income.settleOp(q, b, now, mult)
				local take = math.min(e.amount, onPad)
				if take > 0 then
					b.padCash = onPad - take
					Session.ops.addCash(q, take, false)
					paid += take
				end
			end
		end
	end)
	if not ok then
		pendings[player] = s -- nothing applied: the player may try again
		result(player, false, "none")
		return nil
	end
	push(Offline.stats.collects, { userId = player.UserId, shown = s.total, paid = paid, at = os.clock() })
	TestHooks.reports.offlineCollect = { userId = player.UserId, shown = s.total, paid = paid }
	result(player, true, nil, paid)
	return paid
end

-- A rebirth (or anything else that clears the pads) ends the pending summary: the screen closes, nothing is paid.
function Offline.cancel(player: Player)
	gens[player] = (gens[player] or 0) + 1
	if pendings[player] then
		pendings[player] = nil
		result(player, false, "none")
	end
end

function Offline.start()
	Net.onServerEvent("Offline", "Collect", function(player, _payload)
		Offline.collect(player)
	end)
	Session.onJoin(function(player)
		begin(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		pendings[player] = nil
		gens[player] = nil
	end)
	-- Studio: LeaveAt n -> leftAt = now - n and every pad stamp n seconds earlier, then the join's computation again.
	TestHooks.onSet("LeaveAt", function(v)
		if not Net.isNumber(v, 0, 1e7) then
			if v ~= nil then
				warn("[HFB] hook LeaveAt ignored: " .. tostring(v))
			end
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if Session.get(player) then
				local now = Zones.now()
				local ok = Session.mutate(player, function(q)
					q.leftAt = math.max(0, now - v)
					for _, b in ipairs(q.bosses) do
						b.padStamp = math.max(0, b.padStamp - v)
					end
				end)
				if ok then
					task.spawn(begin, player)
				else
					warn("[HFB] hook LeaveAt: mutate refused")
				end
			end
		end
	end)
end

return Offline
