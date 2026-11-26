--!strict
-- Data/Session: the in-memory profile per player (m1-contract.md section K) and the player's plot.
-- Nothing is saved at M1 (SaveOff is effectively always on). The M2 data-engineer replaces the storage behind
-- the same functions: get(player), set(player, key, value), changed, wipe(player), plot(player).
-- Every system reads and writes the session only through this module.
--
-- Also here (TEAM CALL M1-06a): plot assignment (the first player gets Plot1; the slice has one plot) and moving
-- the character to the plot's SpawnPoint facing the bag, on every spawn; and the state test hooks that set
-- profile values (SetPower, SetCash, SetStrength, SetSpeed, Wipe), applied to every player in the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)

export type Spot = { uid: string, creatureId: string, level: number, stamp: number }
export type Profile = {
	power: number,
	cash: number,
	strengthLevel: number,
	speedLevel: number,
	carry: { uid: string, creatureId: string }?,
	spots: { [number]: Spot },
}

local Session = {}

-- Keys the client sees in Profile.Changed (contract C).
local PUBLIC = { power = true, cash = true, strengthLevel = true, speedLevel = true }

local profiles: { [Player]: Profile } = {}
local plots: { [Player]: Model } = {}
local listeners: { (Player, string, any) -> () } = {}
local charConns: { [Player]: RBXScriptConnection } = {}

local function fresh(): Profile
	return {
		power = Config.Bag.START_POWER,
		cash = 0,
		strengthLevel = Config.Bag.DEFAULT_STRENGTH,
		speedLevel = Config.Bag.DEFAULT_SPEED,
		carry = nil,
		spots = {},
	}
end

-- changed: Session.onChanged(fn(player, key, value)); returns a disconnect function.
function Session.onChanged(fn: (Player, string, any) -> ()): () -> ()
	table.insert(listeners, fn)
	return function()
		local i = table.find(listeners, fn)
		if i then
			table.remove(listeners, i)
		end
	end
end

local function fire(player: Player, key: string, value: any)
	for _, fn in ipairs(table.clone(listeners)) do
		local ok, err = pcall(fn, player, key, value)
		if not ok then
			warn("[HFB] Session listener error: " .. tostring(err))
		end
	end
end

-- The profile (the live table; read it, change it only through set). nil before join / after leave.
function Session.get(player: Player): Profile?
	return profiles[player]
end

-- Sets one key, fires changed, and sends Profile.Changed for the public keys.
function Session.set(player: Player, key: string, value: any)
	local p = profiles[player]
	if not p then
		return
	end
	(p :: any)[key] = value
	if PUBLIC[key] and player.Parent == Players then
		Net.get("Profile", "Changed"):FireClient(player, { [key] = value })
	end
	fire(player, key, value)
end

-- Fresh profile for this player (the Wipe hook); every public key is re-sent.
function Session.wipe(player: Player)
	if not profiles[player] then
		return
	end
	local f = fresh()
	profiles[player] = f
	if player.Parent == Players then
		Net.get("Profile", "Changed"):FireClient(player, {
			power = f.power,
			cash = f.cash,
			strengthLevel = f.strengthLevel,
			speedLevel = f.speedLevel,
		})
	end
	for _, k in ipairs({ "power", "cash", "strengthLevel", "speedLevel", "carry", "spots" }) do
		fire(player, k, (f :: any)[k])
	end
end

-- The player's plot model (Workspace.Plots.PlotN), or nil when none was free.
function Session.plot(player: Player): Model?
	return plots[player]
end

local function assignPlot(player: Player)
	local root = workspace:FindFirstChild("Plots")
	if not root then
		warn("[HFB] Session: Workspace.Plots missing; no plot for " .. player.Name)
		return
	end
	local list = {}
	for _, m in ipairs(root:GetChildren()) do
		if m:IsA("Model") and typeof(m:GetAttribute("PlotId")) == "number" then
			table.insert(list, m)
		end
	end
	table.sort(list, function(a, b)
		return (a:GetAttribute("PlotId") :: number) < (b:GetAttribute("PlotId") :: number)
	end)
	for _, m in ipairs(list) do
		if (m:GetAttribute("OwnerUserId") or 0) == 0 then
			m:SetAttribute("OwnerUserId", player.UserId)
			plots[player] = m :: Model
			return
		end
	end
	warn("[HFB] Session: no free plot for " .. player.Name)
end

local function toSpawn(player: Player, character: Model)
	local plot = plots[player]
	local sp = plot and plot:FindFirstChild("SpawnPoint")
	if not (sp and sp:IsA("BasePart")) then
		return
	end
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	local hum = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hrp or not hum or character.Parent == nil then
		return
	end
	-- Root height above the pad's top: HipHeight + half the root part (R15 and R6 alike).
	local lift = sp.Size.Y / 2 + hum.HipHeight + (hrp :: BasePart).Size.Y / 2
	if hum.RigType == Enum.HumanoidRigType.R6 then
		lift = sp.Size.Y / 2 + 3
	end
	task.defer(function()
		if character.Parent then
			character:PivotTo(sp.CFrame + Vector3.new(0, lift, 0))
		end
	end)
end

local function onJoin(player: Player)
	if profiles[player] then
		return
	end
	profiles[player] = fresh()
	assignPlot(player)
	charConns[player] = player.CharacterAdded:Connect(function(c)
		toSpawn(player, c)
	end)
	if player.Character then
		toSpawn(player, player.Character)
	end
end

local function onLeave(player: Player)
	local plot = plots[player]
	if plot and plot:GetAttribute("OwnerUserId") == player.UserId then
		plot:SetAttribute("OwnerUserId", 0)
	end
	plots[player] = nil
	profiles[player] = nil
	local c = charConns[player]
	if c then
		c:Disconnect()
	end
	charConns[player] = nil
end

-- Player-joined callbacks for systems that need the profile first (run after the profile and plot exist).
local joinFns: { (Player) -> () } = {}
function Session.onJoin(fn: (Player) -> ())
	table.insert(joinFns, fn)
	for p in pairs(profiles) do
		task.spawn(fn, p)
	end
end

local function hookNumber(name: string, key: string, lo: number, hi: number, int: boolean)
	TestHooks.onSet(name, function(v)
		if not Net.isNumber(v, lo, hi) then
			warn(("[HFB] hook %s ignored: %s"):format(name, tostring(v)))
			return
		end
		local value = if int then math.floor(v) else v
		for p in pairs(profiles) do
			Session.set(p, key, value)
		end
	end)
end

function Session.start()
	Players.PlayerAdded:Connect(function(p)
		onJoin(p)
		for _, fn in ipairs(joinFns) do
			task.spawn(fn, p)
		end
	end)
	Players.PlayerRemoving:Connect(onLeave)
	for _, p in ipairs(Players:GetPlayers()) do
		onJoin(p)
	end

	-- State hooks (Studio only; consumed). Apply to every player in the server (team/test-hooks.md).
	hookNumber("SetPower", "power", 0, 1e15, false)
	hookNumber("SetCash", "cash", 0, 1e15, false)
	hookNumber("SetStrength", "strengthLevel", 1, Config.Bag.STRENGTH_MAX, true)
	hookNumber("SetSpeed", "speedLevel", 1, Config.Bag.SPEED_MAX, true)
	TestHooks.onSet("Wipe", function(v)
		if v == true then
			for p in pairs(profiles) do
				Session.wipe(p)
			end
		end
	end)
end

return Session
