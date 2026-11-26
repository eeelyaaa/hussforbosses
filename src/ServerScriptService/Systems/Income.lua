--!strict
-- Systems/Income: what a placed boss earns and collecting it (brief system 8; m1-contract.md sections C, E, K).
-- No loop per boss: a spot holds `stamp` (Zones.now() of its last collect, or of its placing); the cash on its pad
-- is computed from it whenever it is needed.
--
-- Income per second = Config.Zones.INCOME[creatureId] x Config.Income.LEVEL_MULT(level) x 1 (rebirth and the 2x
-- Cash pass are M2). The pad fills once a second (brief: "adds cash to the pad once a second"): the cash on a pad
-- at server time `now` is   income x min(floor(now - stamp), Config.Base.PAD_CAP_S)   (TEAM CALL M1-11e: whole
-- seconds, so the client's count and the server's agree to the dollar; the client floors (now - stamp) too).
-- Collect: when the plot owner's root is within COLLECT_RANGE of the cash pad (flat, server-side test each
-- Heartbeat step), the whole seconds go to cash; the stamp moves on by those seconds (the part-second carries
-- over), or to `now` when the pad was full. Sends Base.Collected (owner) and Profile.Changed { cash } (through
-- Data/Session); Systems/Base re-sends Base.State on the spots change.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Session = require(script.Parent.Parent.Data.Session)
local Zones = require(script.Parent.Zones)
local Bag = require(script.Parent.Bag)

local Income = {}

-- Studs above the cash pad's top the root may be and still collect (a jump onto the pad counts).
local PAD_HEIGHT = 8

Income.stats = { collects = {} :: { any } }

-- Cash a second of one boss.
function Income.perSecond(creatureId: string, level: number): number
	local base = Config.Zones.INCOME[creatureId]
	if typeof(base) ~= "number" then
		return 0
	end
	return base * Config.Income.LEVEL_MULT(level)
end

-- Whole seconds the pad has filled for, capped. Pure.
function Income.secondsOn(stamp: number, now: number): number
	return math.clamp(math.floor(now - stamp), 0, Config.Base.PAD_CAP_S)
end

-- Cash waiting on a spot's pad now.
function Income.onPad(spot: { creatureId: string, level: number, stamp: number }, now: number?): number
	return Income.perSecond(spot.creatureId, spot.level) * Income.secondsOn(spot.stamp, now or Zones.now())
end

-- Collects one spot's pad for its owner. Returns the amount (0 when the pad is empty).
function Income.collect(player: Player, spotIndex: number): number
	local p = Session.get(player)
	local spot = p and p.spots[spotIndex]
	if not p or not spot then
		return 0
	end
	local now = Zones.now()
	local secs = Income.secondsOn(spot.stamp, now)
	if secs <= 0 then
		return 0
	end
	local amount = Income.perSecond(spot.creatureId, spot.level) * secs
	if secs >= Config.Base.PAD_CAP_S then
		spot.stamp = now -- full: it stopped filling at the cap; nothing carries over
	else
		spot.stamp += secs
	end
	Session.set(player, "cash", p.cash + amount)
	Session.set(player, "spots", p.spots) -- Systems/Base re-sends Base.State
	table.insert(Income.stats.collects, { userId = player.UserId, spotIndex = spotIndex, amount = amount, secs = secs, at = now })
	if #Income.stats.collects > 100 then
		table.remove(Income.stats.collects, 1)
	end
	if player.Parent == Players then
		Net.get("Base", "Collected"):FireClient(player, { spotIndex = spotIndex, amount = amount })
	end
	return amount
end

-- The cash pads of a plot by SpotIndex (cached per plot model).
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
	plot.AncestryChanged:Connect(function()
		padCache[plot] = nil
	end)
	return c
end

local function step()
	for _, player in ipairs(Players:GetPlayers()) do
		local p = Session.get(player)
		local plot = Session.plot(player)
		if p and plot and plot:GetAttribute("OwnerUserId") == player.UserId and next(p.spots) ~= nil then
			local r = Bag.root(player)
			if r then
				for i, pad in pairs(padsOf(plot)) do
					if p.spots[i] then
						local d = r.Position - pad.Position
						local above = r.Position.Y - (pad.Position.Y + pad.Size.Y / 2)
						if Vector3.new(d.X, 0, d.Z).Magnitude <= Config.Base.COLLECT_RANGE and above >= -1 and above <= PAD_HEIGHT then
							Income.collect(player, i)
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
