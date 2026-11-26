--!strict
-- Systems/Bag: the own-bag-pad test, the Strength value and the Power each bag punch adds
-- (brief systems 2 and 3; m1-contract.md sections D, E). Systems/Punch decides when a beat applies; this module
-- decides what it is worth and applies it through Data/Session (which sends Profile.Changed { power }).
-- Buying Strength and Speed is M2 (levels come from the session, set by config defaults or the test hooks).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Session = require(script.Parent.Parent.Data.Session)

local Bag = {}

-- Studs above the pad's top the root may be and still count as standing on it (a jump stays on the pad).
local PAD_HEIGHT = 8

local function root(player: Player): BasePart?
	local c = player.Character
	local hum = c and c:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r else nil
end
Bag.root = root

-- True when the player stands on the bag pad of the plot they own (centre distance on the ground plane).
function Bag.onOwnPad(player: Player): boolean
	local plot = Session.plot(player)
	if not plot or plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return false
	end
	local pad = plot:FindFirstChild("BagPad")
	local r = root(player)
	if not (pad and pad:IsA("BasePart")) or not r then
		return false
	end
	local d = r.Position - pad.Position
	local flat = Vector3.new(d.X, 0, d.Z).Magnitude
	local above = r.Position.Y - (pad.Position.Y + pad.Size.Y / 2)
	return flat <= Config.Bag.PAD_RADIUS and above >= -1 and above <= PAD_HEIGHT
end

-- Value of punch n (1..3) of a burst on the bag at the player's Strength level.
function Bag.value(player: Player, grade: string, n: number): number
	local p = Session.get(player)
	local level = if p then p.strengthLevel else Config.Bag.DEFAULT_STRENGTH
	local gv = Config.Punch.GRADE_VALUE[grade] or 0
	return Config.Bag.STRENGTH_VALUE(level) * gv * (if n == 3 then Config.Punch.BIG_MULT else 1)
end

function Bag.gains(player: Player, grade: string): { number }
	return { Bag.value(player, grade, 1), Bag.value(player, grade, 2), Bag.value(player, grade, 3) }
end

-- Applies one bag punch; returns the value added.
function Bag.applyBeat(player: Player, grade: string, n: number): number
	local p = Session.get(player)
	if not p then
		return 0
	end
	local v = Bag.value(player, grade, n)
	if v > 0 then
		Session.set(player, "power", p.power + v)
	end
	return v
end

-- Entering the own bag pad: Bag.onEnter(fn(player)) (Systems/Punch re-sends the schedule).
local enterFns: { (Player) -> () } = {}
function Bag.onEnter(fn: (Player) -> ())
	table.insert(enterFns, fn)
end

local onPad: { [Player]: boolean } = {}
function Bag.isOnPad(player: Player): boolean
	return onPad[player] == true
end

function Bag.start()
	Players.PlayerRemoving:Connect(function(p)
		onPad[p] = nil
	end)
	-- Pad entry poll, 10 times a second (cheap: one distance per player).
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		for _, p in ipairs(Players:GetPlayers()) do
			local now = Bag.onOwnPad(p)
			if now and not onPad[p] then
				onPad[p] = true
				for _, fn in ipairs(enterFns) do
					task.spawn(fn, p)
				end
			elseif not now and onPad[p] then
				onPad[p] = nil
			end
		end
	end)
end

return Bag
