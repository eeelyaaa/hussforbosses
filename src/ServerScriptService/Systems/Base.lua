--!strict
-- Systems/Base: the plot's spots, placing a carried boss, and the plot's state for every client
-- (brief system 7; m1-contract.md sections B, C, E, K). M1: one plot, spots 1..SPOTS_AT_START, placing only
-- (pick up, swap, sell, the crate, the lock and the spots-full sign are M2).
--
-- The plot owner is set by Data/Session on join (Plot attribute OwnerUserId, 0 when free).
-- Glow: while the owner is CARRYING (not dropped), every empty spot of their plot has the attribute Glow = true;
-- otherwise Glow = false. The client draws the glow from the attribute (M1-14).
--
-- c2s: Base.Place { spotIndex }. Rules (contract C): carrying (not dropped), the plot is the player's, the spot
-- exists on it and is empty, the player's root within PLACE_RANGE of the spot (flat, and at most PLACE_HEIGHT
-- above or below it). A refused place changes nothing and sends nothing (TEAM CALL M1-11f: the contract has no
-- refusal remote; the reason is counted in Base.stats.refused for checks).
-- s2c: Base.State { plotId, ownerUserId, spots } to every player, on join (every plot) and on any change.
--   spots is a DENSE array 1..SPOTS_AT_START (TEAM CALL M1-11g: a sparse table loses entries after the first nil
--   on a remote); an empty spot is `false`, a filled one { uid, creatureId, level, income, stamp, capSeconds }.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Session = require(script.Parent.Parent.Data.Session)
local Zones = require(script.Parent.Zones)
local Bag = require(script.Parent.Bag)
local Carry = require(script.Parent.Carry)
local Income = require(script.Parent.Income)

local Base = {}

local PLACE_HEIGHT = 10

Base.stats = { refused = {} :: { [string]: number }, placed = {} :: { any } }
local function refuse(reason: string): string
	Base.stats.refused[reason] = (Base.stats.refused[reason] or 0) + 1
	return reason
end

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

-- The spot part with SpotIndex i on a plot.
function Base.spotPart(plot: Model, i: number): BasePart?
	local s = plot:FindFirstChild("Spot_" .. i)
	if s and s:IsA("BasePart") and s:GetAttribute("SpotIndex") == i then
		return s
	end
	return nil
end

-- The Base.State payload for a plot.
function Base.payload(plot: Model): any
	local owner = ownerOf(plot)
	local p = owner and Session.get(owner)
	local spots = table.create(Config.Base.SPOTS_AT_START, false) :: { any }
	if p then
		for i = 1, Config.Base.SPOTS_AT_START do
			local s = p.spots[i]
			if s then
				spots[i] = {
					uid = s.uid,
					creatureId = s.creatureId,
					level = s.level,
					income = Income.perSecond(s.creatureId, s.level),
					stamp = s.stamp,
					capSeconds = Config.Base.PAD_CAP_S,
				}
			end
		end
	end
	return {
		plotId = plot:GetAttribute("PlotId"),
		ownerUserId = if owner then owner.UserId else 0,
		spots = spots,
	}
end

local function setGlow(plot: Model)
	local owner = ownerOf(plot)
	local p = owner and Session.get(owner)
	local carrying = owner ~= nil and Carry.isCarrying(owner)
	for i = 1, Config.Base.SPOTS_AT_START do
		local s = Base.spotPart(plot, i)
		if s then
			local glow = carrying and p ~= nil and p.spots[i] == nil
			if s:GetAttribute("Glow") ~= glow then
				s:SetAttribute("Glow", glow)
			end
		end
	end
end

function Base.broadcast(plot: Model)
	setGlow(plot)
	Net.get("Base", "State"):FireAllClients(Base.payload(plot))
end

local function broadcastFor(player: Player)
	local plot = Session.plot(player)
	if plot then
		Base.broadcast(plot)
	end
end

-- Places the carried boss on spot i of the player's plot. Returns nil on success or the refusal reason.
function Base.tryPlace(player: Player, spotIndex: any): string?
	if not Net.isInt(spotIndex, 1, Config.Base.SPOTS_AT_START) then
		return refuse("bad")
	end
	local p = Session.get(player)
	if not p then
		return refuse("state")
	end
	if not Carry.isCarrying(player) then
		return refuse("notCarrying")
	end
	local plot = Session.plot(player)
	if not plot or plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return refuse("plot")
	end
	local part = Base.spotPart(plot, spotIndex)
	if not part then
		return refuse("spot")
	end
	if p.spots[spotIndex] then
		return refuse("taken")
	end
	local r = Bag.root(player)
	if not r then
		return refuse("state")
	end
	local d = r.Position - part.Position
	if Vector3.new(d.X, 0, d.Z).Magnitude > Config.Base.PLACE_RANGE or math.abs(d.Y) > PLACE_HEIGHT then
		return refuse("range")
	end
	local c = Carry.take(player)
	if not c then
		return refuse("notCarrying")
	end
	p.spots[spotIndex] = { uid = c.uid, creatureId = c.creatureId, level = Config.Income.DEFAULT_LEVEL, stamp = Zones.now() }
	table.insert(Base.stats.placed, { userId = player.UserId, spotIndex = spotIndex, uid = c.uid, creatureId = c.creatureId, at = Zones.now() })
	Session.set(player, "spots", p.spots) -- the listener below broadcasts
	return nil
end

function Base.start()
	Net.onServerEvent("Base", "Place", function(player, payload)
		Base.tryPlace(player, payload.spotIndex)
	end)

	-- Any change to a player's spots (place, collect, wipe) re-sends their plot.
	Session.onChanged(function(player, key, _value)
		if key == "spots" then
			broadcastFor(player)
		end
	end)
	-- Carrying starts or ends: the glow follows.
	Carry.onChanged(function(player, _state, _c)
		local plot = Session.plot(player)
		if plot then
			setGlow(plot)
		end
	end)

	-- Join: every plot's state to the joiner, and the joiner's plot (now owned) to everyone.
	Session.onJoin(function(player)
		for _, plot in ipairs(plots()) do
			Net.get("Base", "State"):FireClient(player, Base.payload(plot))
		end
		broadcastFor(player)
	end)
	-- Leave: Data/Session frees the plot (OwnerUserId 0); everyone gets the empty plot.
	for _, plot in ipairs(plots()) do
		plot:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
			if (plot:GetAttribute("OwnerUserId") or 0) == 0 then
				task.defer(Base.broadcast, plot)
			end
		end)
		setGlow(plot)
	end
end

return Base
