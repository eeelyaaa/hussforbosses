--!strict
-- Config: every tunable number in the brief, by system. Ids only; no display names, colours or asset ids
-- (those live in Skins/<skinId>/). One child module per system (Punch, Ring, Fight, Zones, Carry, Base,
-- Income, Upgrades, Steal, Shield, Offline, Rebirth, Shop, Spin, ...), each returning a table, read here as
-- Config.<ChildName>. The burst timing contract (BEAT, BURST_LEN, RING, windows) goes in a child at M1.
--
-- Tests override values at runtime from the test script (server tests share the module cache);
-- never edit a config file for a test.
local RunService = game:GetService("RunService")

local Config = {}

-- The active skin (architecture requirement: the skin is separate from the rules). Switched for the skin
-- check through the "ForceSkin" test hook, never by editing this line.
Config.SkinId = "brickbrawl"

-- Environment, for DataStore names: test data never reaches the published game.
Config.Env = if RunService:IsStudio() then "Studio" else "Live"

-- Ownership of the place (team/CLAUDE.md). Code that uploads or saves may assert these.
Config.GroupId = 432262304
Config.PlaceId = 139279056607944
Config.GameId = 10779089797

for _, child in ipairs(script:GetChildren()) do
	if child:IsA("ModuleScript") then
		assert(Config[child.Name] == nil, "Config: child module name clashes with a key: " .. child.Name)
		Config[child.Name] = require(child) :: any
	end
end

return Config
