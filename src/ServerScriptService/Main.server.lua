-- Server entry point. Starts the systems in order; each system is a ModuleScript in ServerScriptService.Systems
-- (and Data/) with a start() function, added from M1. Nothing here holds game rules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local TestHooks = require(Shared.TestHooks)

TestHooks.warnIfSetLive()
Net.serverInit()

-- Systems start here in dependency order (Data first). Added by the M1 scripter.

print(("[HFB] server up: env=%s skin=%s place=%d"):format(Config.Env, Config.SkinId, game.PlaceId))
