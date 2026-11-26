--!strict
-- Systems/Income: what a placed boss earns and collecting it (brief systems 8, 9, 12; m2-contract.md C, D).
-- No loop per boss: each saved boss holds `padCash` (cash settled on its pad) and `padStamp` (server time it was last
-- settled). The cash on its pad at server time `now`, in whole seconds (TEAM CALL M1-11e) and capped at two hours of
-- its income (brief 8):
--     rate   = Config.Zones.INCOME[creatureId] x LEVEL_MULT(level) x REBIRTH_MULT(rebirths) x (2 with 2x Cash)
--     secs   = clamp(floor(now - padStamp), 0, PAD_CAP_S)      (a stamp from the future counts 0: M2-02 N7)
--     onPad  = max(padCash, min(padCash + rate x secs, rate x PAD_CAP_S))
-- Settling writes onPad into padCash and moves padStamp on by secs (or to now when the pad is full, so it stopped
-- filling at the cap). The multipliers apply to the whole unsettled stretch when it settles (M2-02 N5, design).
-- A boss its owner is carrying (picked up, origin "spot") earns nothing while carried: its rate is 0.
-- Collect: the owner's root within COLLECT_RANGE of the cash pad (server-side test each Heartbeat): one mutate settles
-- that pad and moves its padCash to cash (Session.ops.addCash, earned). Sends Base.Collected; the first collect > 0
-- marks the funnel's FirstCashCollected.
-- For other systems (Offline M2-14, Steal M2-15, Rebirth M2-14): Income.mult, Income.rate, Income.settleOp (pure, on a
-- profile table inside their own mutate), Income.onPad.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Session = require(script.Parent.Parent.Data.Session)
local Zones = require(script.Parent.Zones)
local Bag = require(script.Parent.Bag)
local Funnel = require(script.Parent.Funnel)

local Income = {}

-- Studs above the cash pad's top the root may be and still collect (a jump onto the pad counts).
local PAD_HEIGHT = 8

Income.stats = { collects = {} :: { any } }

-- Cash a second of one boss at a level, before the player's multipliers (M1 name).
function Income.perSecond(creatureId: string, level: number): number
	local base = Config.Zones.INCOME[creatureId]
	if typeof(base) ~= "number" then
		return 0
	end
	return base * Config.Income.LEVEL_MULT(level)
end

-- The rebirth multiplier for a rebirth count (Config.Rebirth.INCOME_MULT wins when M2-14 sets one).
function Income.rebirthMult(rebirths: number): number
	local R = (Config :: any).Rebirth
	if R and type(R.INCOME_MULT) == "function" then
		return R.INCOME_MULT(rebirths)
	end
	return Config.Income.REBIRTH_MULT(rebirths)
end

-- The player's multiplier on every boss: rebirth x 2x Cash (from the pass cache; never yields).
function Income.mult(player: Player?, p: any?): number
	local prof = p or (player and Session.get(player))
	local n = if prof and typeof(prof.rebirths) == "number" then prof.rebirths else 0
	local pass = player ~= nil and Bag.owns(player, Config.Income.CASH_PASS)
	return Income.rebirthMult(n) * (if pass then Config.Income.CASH_PASS_MULT else 1)
end

-- Is this boss on its owner's head (picked up)? Reads the profile's runtime carry.
local function carried(p: any, boss: any): boolean
	local c = p and p.carry
	return c ~= nil and c.origin == "spot" and c.uid == boss.uid
end

-- Cash a second of a saved boss for its owner now (0 while the owner carries it).
function Income.rate(p: any, boss: any, mult: number): number
	if carried(p, boss) then
		return 0
	end
	return Income.perSecond(boss.creatureId, boss.level) * mult
end

-- Whole seconds the pad has filled for, capped. Pure.
function Income.secondsOn(stamp: number, now: number): number
	return math.clamp(math.floor(now - stamp), 0, Config.Base.PAD_CAP_S)
end

-- Settles one boss's pad in place (pure on the table; call inside a mutate). Returns the cash now on the pad.
function Income.settleOp(p: any, boss: any, now: number, mult: number): number
	if now <= boss.padStamp then
		return boss.padCash
	end
	local secs = Income.secondsOn(boss.padStamp, now)
	local rate = Income.rate(p, boss, mult)
	local cap = rate * Config.Base.PAD_CAP_S
	local full = boss.padCash + rate * secs
	if full >= cap then
		boss.padCash = math.max(boss.padCash, cap)
		boss.padStamp = now
	else
		boss.padCash = full
		boss.padStamp += secs
	end
	return boss.padCash
end

-- Cash on a boss's pad now, without changing anything. onPad(p, boss, now, mult); the M1 form onPad(spotView, now?)
-- (a `spots` view entry { uid, creatureId, level, stamp }, as M1's checks call it) is still answered, for that boss
-- found in its owner's profile, at multiplier 1.
function Income.onPad(p: any, boss: any, now: number?, mult: number?): number
	if boss == nil or type(boss) == "number" then
		local view = p
		if type(view) ~= "table" then
			return 0
		end
		local t = (boss :: number?) or Zones.now()
		local entry = { uid = view.uid, creatureId = view.creatureId, level = view.level, padCash = view.padCash or 0, padStamp = view.stamp or view.padStamp or t }
		return Income.settleOp(nil, entry, t, 1)
	end
	now = now or Zones.now()
	mult = mult or 1
	local copy = { uid = boss.uid, creatureId = boss.creatureId, level = boss.level, padCash = boss.padCash, padStamp = boss.padStamp }
	return Income.settleOp(p, copy, now, mult)
end

local function bossAt(p: any, spotIndex: number): any
	for _, b in ipairs(p.bosses) do
		if b.spot == spotIndex then
			return b
		end
	end
	return nil
end

local function record(player: Player, spotIndex: number, amount: number, now: number)
	table.insert(Income.stats.collects, { userId = player.UserId, spotIndex = spotIndex, amount = amount, at = now })
	if #Income.stats.collects > 100 then
		table.remove(Income.stats.collects, 1)
	end
	if player.Parent == Players then
		Net.get("Base", "Collected"):FireClient(player, { spotIndex = spotIndex, amount = amount })
	end
	if amount > 0 then
		Funnel.mark(player, "FirstCashCollected")
	end
end

-- Base calls this after a mutate that took a pad's cash (a sale, a swap, a boss leaving its spot): the same
-- Base.Collected, the stats and the funnel as a walk-over collect.
function Income.collected(player: Player, spotIndex: number, amount: number)
	if amount > 0 then
		record(player, spotIndex, amount, Zones.now())
	end
end

-- Collects one spot's pad for its owner. Returns the amount (0 when the pad is empty).
function Income.collect(player: Player, spotIndex: number): number
	local p = Session.get(player)
	if not p then
		return 0
	end
	local b = bossAt(p, spotIndex)
	if not b then
		return 0
	end
	local now = Zones.now()
	local mult = Income.mult(player, p)
	if Income.onPad(p, b, now, mult) <= 0 then
		return 0
	end
	local amount = 0
	local ok = Session.mutate(player, function(q)
		local qb = bossAt(q, spotIndex)
		if not qb then
			return
		end
		amount = Income.settleOp(q, qb, now, mult)
		qb.padCash = 0
		if amount > 0 then
			Session.ops.addCash(q, amount, false)
		end
	end)
	if not ok or amount <= 0 then
		return 0
	end
	record(player, spotIndex, amount, now)
	return amount
end

-- The cash pads of a plot by SpotIndex (cached per plot model; re-read when one is added).
local padCache: { [Instance]: { [number]: BasePart } } = {}
local function padsOf(plot: Model): { [number]: BasePart }
	local c = padCache[plot]
	if c then
		return c
	end
	c = {}
	for _, d in ipairs(plot:GetChildren()) do
		local i = d:GetAttribute("SpotIndex")
		if d:IsA("BasePart") and typeof(i) == "number" and d.Name == "CashPad_" .. i then
			c[i] = d
		end
	end
	padCache[plot] = c
	local conns = {}
	local function drop()
		padCache[plot] = nil
		for _, k in ipairs(conns) do
			k:Disconnect()
		end
	end
	table.insert(conns, plot.ChildAdded:Connect(drop))
	table.insert(conns, plot.ChildRemoved:Connect(drop))
	table.insert(conns, plot.AncestryChanged:Connect(drop))
	return c
end

local function step()
	local now = Zones.now()
	for _, player in ipairs(Players:GetPlayers()) do
		local p = Session.get(player)
		local plot = Session.plot(player)
		if p and plot and plot:GetAttribute("OwnerUserId") == player.UserId and #p.bosses > 0 then
			local r = Bag.root(player)
			if r then
				local mult: number? = nil
				for i, pad in pairs(padsOf(plot)) do
					local d = r.Position - pad.Position
					local above = r.Position.Y - (pad.Position.Y + pad.Size.Y / 2)
					if Vector3.new(d.X, 0, d.Z).Magnitude <= Config.Base.COLLECT_RANGE and above >= -1 and above <= PAD_HEIGHT then
						local b = bossAt(p, i)
						if b then
							mult = mult or Income.mult(player, p)
							if Income.onPad(p, b, now, mult :: number) > 0 then
								Income.collect(player, i)
							end
						end
					end
				end
			end
		end
	end
end

function Income.start()
	RunService.Heartbeat:Connect(step)
end

return Income
