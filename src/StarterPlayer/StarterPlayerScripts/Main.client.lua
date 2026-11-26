-- Client entry point. Starts the controllers (StarterPlayerScripts.Controllers) and the UI (Ui/), added from M1.
-- The client shows what the server decided; it never decides a result (build plan, "Client and server boundaries").
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Skin = require(Shared.Skin)

-- Controllers and UI start here. Added by the M1 scripter and gui-designer.

print(("[HFB] client up: skin=%s"):format(Skin.Id or Config.SkinId))
