--!strict
-- Skin: the one way code reaches what a player sees or hears for an id.
--   local Skin = require(ReplicatedStorage.Shared.Skin)
--   Skin.Names.creatures.z1_t1, Skin.Tokens.colors.hussRed, Skin.Sounds.burstVoice ...
-- The active skin is Config.SkinId, or the ForceSkin test hook in Studio (the skin check).
-- Nothing outside Skins/ may hold a display name, a hex colour or an asset id.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)
local TestHooks = require(script.Parent.TestHooks)

local skinId = TestHooks.get("ForceSkin") or Config.SkinId
local folder = ReplicatedStorage:WaitForChild("Skins"):WaitForChild(skinId, 10)
assert(folder and folder:IsA("ModuleScript"), "Skin: no skin module ReplicatedStorage.Skins." .. tostring(skinId))

local skin = require(folder) :: any
skin.Id = skinId
return skin
