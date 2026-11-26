--!strict
-- Config: every tunable number in the brief, by system. Ids only; no display names, colours or asset ids
-- (those live in Skins/<skinId>/). One child module per system (Punch, Ring, Fight, Zones, Carry, Base,
-- Income, Upgrades, Steal, Shield, Offline, Rebirth, Shop, Spin, ...), each returning a table, read here as
-- Config.<ChildName>. The burst timing contract (BEAT, BURST_LEN, RING, windows) is in Config.Punch (M1).
-- Who owns each child: team/requirements/m2-contract.md section A (M2-01 created the M2 skeletons).
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

-- M2-01 seams that keep two tasks out of one file (m2-contract.md section A; TEAM CALLs M2-01-4 and M2-01-5).
local C = Config :: any
-- The pass and product ids live in Config/ShopIds (main session, M2-00); read everywhere as Config.Shop.IDS.
if C.Shop and C.ShopIds and C.Shop.IDS == nil then
	C.Shop.IDS = C.ShopIds
end
-- The fight camera: Config/FightCamera (M2-07) replaces Config.Fight.CAMERA once it sets CAMERA.
if C.Fight and C.FightCamera and type(C.FightCamera.CAMERA) == "table" then
	C.Fight.CAMERA = C.FightCamera.CAMERA
end

return Config
