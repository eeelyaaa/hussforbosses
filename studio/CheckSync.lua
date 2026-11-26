if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M0 exit check: a studio/ script runs through the sync, and the synced src/ tree is in the place.
--   require(game.ServerStorage.DevSync:Clone()).run("CheckSync.lua")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

print("CheckSync: this studio/ script ran through the sync")
local expect = {
	{ "ReplicatedStorage.Shared.Config", ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Config"), "ModuleScript" },
	{ "ReplicatedStorage.Shared.Ids", ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Ids"), "ModuleScript" },
	{ "ReplicatedStorage.Shared.Net", ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Net"), "ModuleScript" },
	{ "ReplicatedStorage.Skins.brickbrawl", ReplicatedStorage:FindFirstChild("Skins") and ReplicatedStorage.Skins:FindFirstChild("brickbrawl"), "ModuleScript" },
	{ "ServerScriptService.Main", ServerScriptService:FindFirstChild("Main"), "Script" },
	{ "StarterPlayerScripts.Main", StarterPlayer.StarterPlayerScripts:FindFirstChild("Main"), "LocalScript" },
}
local failed = 0
for _, e in ipairs(expect) do
	local ok = e[2] ~= nil and e[2].ClassName == e[3]
	print(("CheckSync: %s %s is a %s"):format(ok and "PASS" or "FAIL", e[1], e[3]))
	if not ok then
		failed += 1
	end
end
-- Requiring the shared modules in edit mode proves they compile.
local okReq, err = pcall(function()
	local Config = require(ReplicatedStorage.Shared.Config)
	require(ReplicatedStorage.Shared.Ids)
	require(ReplicatedStorage.Shared.Net)
	require(ReplicatedStorage.Shared.Skin)
	assert(Config.SkinId == "brickbrawl", "Config.SkinId is " .. tostring(Config.SkinId))
end)
print(("CheckSync: %s shared modules require (%s)"):format(okReq and "PASS" or "FAIL", okReq and "ok" or tostring(err)))
if not okReq then
	failed += 1
end
print(("CheckSync: %s, %d failed"):format(failed == 0 and "PASS" or "FAIL", failed))
