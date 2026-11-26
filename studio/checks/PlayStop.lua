if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-09: a normal Play stop saves the player (the build plan's "a simulated shutdown saves" in the real path:
-- PlayerRemoving and BindToClose both run on a Studio stop, in no documented order). Two steps, holding the lock:
--   1. EDIT MODE: require(game.ServerStorage.DevSync:Clone()).run("checks/PlayStop.lua")
--      installs ServerStorage.TmpChecksData.PlayStop and sets the Studio-script switch HFB_PlayStopValue (a fresh
--      random Power) on Workspace, which the play copy reads.
--   2. PLAY: run_script_in_play_mode (start_play): require(game.ServerStorage.TmpChecksData.PlayStop)()
--      waits for the live profile, sets Power to the value and returns WITHOUT saving; the MCP then stops play
--      (the real stop path).
--   3. EDIT MODE again: the same run as step 1 reads HFB_Studio_Players/player_<id> (UseCache = false) and prints
--      PASS when the record holds the value and the lock is released; then it clears the switch and the folder.
-- The record is the test player's normal Studio record (Studio store only).
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local SWITCH = "HFB_PlayStopValue"

if RunService:IsRunning() then
	local Players = game:GetService("Players")
	local Session = require(game:GetService("ServerScriptService").Data.Session)
	local v = workspace:GetAttribute(SWITCH)
	local P = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local t0 = os.clock()
	while Session.state(P) ~= "live" and os.clock() - t0 < 30 do
		task.wait(0.1)
	end
	print(("PlayStop: state %s, setting power %s; stopping without a save"):format(tostring(Session.state(P)), tostring(v)))
	if typeof(v) == "number" then
		Session.set(P, "power", v)
	end
else
	local HttpService = game:GetService("HttpService")
	local DataStoreService = game:GetService("DataStoreService")
	local Players = game:GetService("Players")
	local v = workspace:GetAttribute(SWITCH)
	if typeof(v) == "number" then
		-- step 3: read back
		local userId = (Players.LocalPlayer and Players.LocalPlayer.UserId) or game:GetService("StudioService"):GetUserId()
		local opts = Instance.new("DataStoreGetOptions")
		opts.UseCache = false
		local ok, rec = pcall(function()
			return DataStoreService:GetDataStore("HFB_Studio_Players"):GetAsync("player_" .. userId, opts)
		end)
		local saved = ok and type(rec) == "table" and rec.power == v
		local released = ok and type(rec) == "table" and rec.lock == nil
		print(("PlayStop: %s the Play stop saved the last change (power %s, want %s)"):format(saved and "PASS" or "FAIL", ok and type(rec) == "table" and tostring(rec.power) or tostring(rec), tostring(v)))
		print(("PlayStop: %s the Play stop released the lock (%s)"):format(released and "PASS" or "FAIL", ok and type(rec) == "table" and HttpService:JSONEncode(rec.lock) or "-"))
		workspace:SetAttribute(SWITCH, nil)
		local f = ServerStorage:FindFirstChild("TmpChecksData")
		if f then
			f:Destroy()
		end
	else
		-- step 1: install and arm
		local src = HttpService:GetAsync("http://127.0.0.1:34874/studio/checks/PlayStop.lua", true)
		local folder = ServerStorage:FindFirstChild("TmpChecksData") or Instance.new("Folder")
		folder.Name = "TmpChecksData"
		local old = folder:FindFirstChild("PlayStop")
		if old then
			old:Destroy()
		end
		local m = Instance.new("ModuleScript")
		m.Name = "PlayStop"
		m.Source = "return function(...)\n" .. src .. "\nend\n"
		m.Parent = folder
		folder.Parent = ServerStorage
		local value = math.random(100000, 999999) + 0.25
		workspace:SetAttribute(SWITCH, value)
		print("PlayStop: installed; armed power " .. tostring(value) .. "; now the play call, then run this again")
	end
end
