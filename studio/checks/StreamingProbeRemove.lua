if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-34: removes everything checks/StreamingProbe.lua installed. Run after play is stopped.
local n = 0
for _, p in ipairs({ { game.StarterPlayer.StarterPlayerScripts, "HFB_StreamingProbe" }, { game.ServerScriptService, "HFB_StreamingProbeSrv" }, { game.ReplicatedStorage, "StreamProbe" } }) do
	local o = p[1]:FindFirstChild(p[2]) if o then o:Destroy() n += 1 end
end
print("StreamingProbeRemove: PASS removed " .. n .. " of 3")
