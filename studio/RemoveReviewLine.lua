if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- Takes the Studio-only review line out of the place (run before publishing; BuildReviewLine.lua puts it back).
local o = workspace:FindFirstChild("ReviewLine") if o then o:Destroy() end
for _, p in ipairs({ { game.StarterPlayer.StarterPlayerScripts, "HFB_ReviewLine" }, { game.StarterPlayer.StarterPlayerScripts, "HFB_ReviewLineDriver" }, { game.ServerScriptService, "HFB_ReviewLineGuard" } }) do
	local x = p[1]:FindFirstChild(p[2]) if x then x:Destroy() end
end
print("RemoveReviewLine: PASS review line removed")
