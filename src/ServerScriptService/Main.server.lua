-- Server entry point. Starts the systems in order; each system is a ModuleScript in ServerScriptService.Systems
-- (and Data/) with a start() function. Nothing here holds game rules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)
local Skin = require(Shared.Skin)

TestHooks.warnIfSetLive()
Net.serverInit()
TestHooks.listenReports(Net) -- Profile.TestReport (Studio only)

local Systems = ServerScriptService:WaitForChild("Systems")
local Data = ServerScriptService:WaitForChild("Data")

-- Dependency order: Data first, then the M1 systems. Any other module in Systems with a start() (M1-11's Carry,
-- Hazards, Base, Income, and later milestones') starts after these, in the order of ORDER_AFTER then by name, so
-- adding a system needs no edit here unless its order matters.
local ORDER = { Data.Session, Systems.Zones, Systems.Bag, Systems.Fight, Systems.Punch }
local ORDER_AFTER = { "Hazards", "Carry", "Base", "Income" }

local started: { [Instance]: boolean } = {}
local function startOne(m: Instance)
	if started[m] or not m:IsA("ModuleScript") then
		return
	end
	started[m] = true
	local ok, err = pcall(function()
		local sys = require(m) :: any
		if type(sys) == "table" and type(sys.start) == "function" then
			sys.start()
		end
	end)
	if not ok then
		warn(("[HFB] system %s failed to start: %s"):format(m:GetFullName(), tostring(err)))
	end
end

for _, m in ipairs(ORDER) do
	startOne(m)
end
for _, name in ipairs(ORDER_AFTER) do
	local m = Systems:FindFirstChild(name)
	if m then
		startOne(m)
	end
end
local rest = Systems:GetChildren()
table.sort(rest, function(a, b)
	return a.Name < b.Name
end)
for _, m in ipairs(rest) do
	startOne(m)
end

print(("[HFB] server up: env=%s skin=%s place=%d"):format(Config.Env, tostring(Skin.Id), game.PlaceId))
