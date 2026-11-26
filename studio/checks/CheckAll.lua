if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-16: CheckAll, the M1 gate's driver (team/requirements/m1-core-loop-gate.md, "CheckAll.lua").
-- Order: CheckSync -> CheckSkin parts 1 and 2 -> CoreLoop -> Refusals -> BurstValues -> NoDelay; one summary table
-- (saved by the runner to team/verification/m1-checkall.md).
--
-- Why it is a driver and not one call: the play-mode checks need play sessions and the Studio MCP's play-mode call
-- has a time limit (about 90 s) and returns only the server log; each play session is a fresh DataModel, and the place's
-- HttpService is off, so nothing a play session learns survives it. So CheckAll runs everything that runs in edit mode,
-- installs the play-mode checks, prints the exact play calls, and builds the summary from the CHECKALL rows those calls
-- print. EDIT MODE, holding the studio lock; the mode is the Studio-script switch Workspace.HFB_CheckAllMode
-- (team/test-hooks.md, "Studio-script switches"; this script clears it):
--
--   1. workspace:SetAttribute("HFB_CheckAllMode", "prepare"); require(game.ServerStorage.DevSync:Clone()).run("checks/CheckAll.lua")
--        sync src/, CheckSync, CheckSkin (part 2 not armed), Refusals "live" (edit mode), then installs
--        ServerStorage.TmpChecks.{CheckLib, CoreLoop, Refusals, BurstValues, NoDelay} and the client probe
--        StarterPlayer.StarterPlayerScripts.HFB_CheckProbe. Part 1 of the skin check is the repo scan, run outside
--        Studio: python tools/check_skin.py (exit 0); its result goes in the summary rows as "CheckSkin|scan|...".
--   2. the play calls it prints, one run_script_in_play_mode (start_play) each, in order.
--   3. "arm": CheckSkin with part 2 armed (HFB_ForceSkin = "stub"); then the two CoreLoop play calls with skin "stub";
--      then "disarm" (clears HFB_ForceSkin and the stub boss folder).
--   4. "summary": set Workspace.HFB_CheckAllRows to the CHECKALL rows, ";;"-separated (name|phase|pass|fail|fails), then run.
--   "install": re-installs TmpChecks and the probe only (after editing a check file).
--   5. "cleanup": removes TmpChecks and the probe, clears every HFB_ attribute. Never leave either in the place.
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local HttpService = game:GetService("HttpService")
local BASE = "http://127.0.0.1:34874"

local mode = workspace:GetAttribute("HFB_CheckAllMode")
workspace:SetAttribute("HFB_CheckAllMode", nil)
local DevSync = ServerStorage:FindFirstChild("DevSync")
assert(DevSync, "CheckAll: ServerStorage.DevSync missing (team/CLAUDE.md, recreate the loader)")

local CHECKS = { "CheckLib", "CoreLoop", "Refusals", "BurstValues", "NoDelay" }
local PLAYS = {
	{ "CoreLoop", "a" }, { "CoreLoop", "b" },
	{ "Refusals", "a" }, { "Refusals", "b" },
	{ "BurstValues", "a" }, { "BurstValues", "b" },
	{ "NoDelay", "a" },
}

local function fetch(name)
	return HttpService:GetAsync(BASE .. "/studio/checks/" .. name .. ".lua", true)
end

local function install()
	local old = ServerStorage:FindFirstChild("TmpChecks")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "TmpChecks"
	for _, name in ipairs(CHECKS) do
		local m = Instance.new("ModuleScript")
		m.Name = name
		m.Source = "return function(...)\n" .. fetch(name) .. "\nend\n"
		m.Parent = folder
	end
	folder.Parent = ServerStorage
	local sps = StarterPlayer.StarterPlayerScripts
	local oldP = sps:FindFirstChild("HFB_CheckProbe")
	if oldP then oldP:Destroy() end
	local ls = Instance.new("LocalScript")
	ls.Name = "HFB_CheckProbe"
	ls.Source = fetch("CheckProbe")
	ls.Parent = sps
	print(("CheckAll: installed ServerStorage.TmpChecks (%d modules) and StarterPlayerScripts.HFB_CheckProbe"):format(#CHECKS))
end

local function plays(skin)
	print("CheckAll: play calls, one run_script_in_play_mode (start_play) each, in this order:")
	for _, pc in ipairs(PLAYS) do
		if not skin or pc[1] == "CoreLoop" then
			print(("CheckAll:   require(game.ServerStorage.TmpChecks.%s)({ phase = %q%s })"):format(pc[1], pc[2], skin and (", skin = " .. ("%q"):format(skin)) or ""))
		end
	end
end

local function cleanup()
	local t = ServerStorage:FindFirstChild("TmpChecks")
	if t then t:Destroy() end
	local pr = StarterPlayer.StarterPlayerScripts:FindFirstChild("HFB_CheckProbe")
	if pr then pr:Destroy() end
	local f = ServerStorage:FindFirstChild("HFB_SkinCheck")
	if f then f:Destroy() end
	local n = 0
	for k in pairs(workspace:GetAttributes()) do
		if k:sub(1, 4) == "HFB_" then workspace:SetAttribute(k, nil); n += 1 end
	end
	print(("CheckAll: cleaned up (TmpChecks, probe, stub boss folder, %d HFB_ attributes)"):format(n))
end

if mode == "prepare" then
	require(DevSync:Clone())()
	print("CheckAll: --- CheckSync")
	require(DevSync:Clone()).run("CheckSync.lua")
	print("CheckAll: --- CheckSkin (Studio parts A-E; part 2 is armed later)")
	workspace:SetAttribute("HFB_CheckSkinNoArm", true)
	require(DevSync:Clone()).run("CheckSkin.lua")
	install()
	print("CheckAll: --- Refusals live (edit mode)")
	require(ServerStorage.TmpChecks.Refusals)({ phase = "live" })
	plays(nil)
	print("CheckAll: then mode 'arm'")
elseif mode == "install" then
	install() -- re-installs the play-mode checks after an edit to studio/checks/ (no sync, no edit-mode checks)
elseif mode == "arm" then
	require(DevSync:Clone()).run("CheckSkin.lua")
	print("CheckAll: part 2 armed: HFB_ForceSkin = " .. tostring(workspace:GetAttribute("HFB_ForceSkin")))
	plays("stub")
	print("CheckAll: then mode 'disarm'")
elseif mode == "disarm" then
	workspace:SetAttribute("HFB_ForceSkin", nil)
	local f = ServerStorage:FindFirstChild("HFB_SkinCheck")
	if f then f:Destroy() end
	print("CheckAll: disarmed: HFB_ForceSkin = " .. tostring(workspace:GetAttribute("HFB_ForceSkin")))
elseif mode == "summary" then
	local raw = workspace:GetAttribute("HFB_CheckAllRows")
	workspace:SetAttribute("HFB_CheckAllRows", nil)
	assert(type(raw) == "string", "CheckAll summary: set Workspace.HFB_CheckAllRows first")
	local tp, tf, rows = 0, 0, 0
	print("CheckAll: | Check | Phase | PASS | FAIL | Failed |")
	print("CheckAll: |---|---|---|---|---|")
	for row in (raw .. ";;"):gmatch("(.-);;") do
		local name, phase, ps, fs, fails = row:match("^%s*([^|]+)|([^|]*)|(%d+)|(%d+)|?(.*)$")
		if name then
			rows += 1
			tp += tonumber(ps)
			tf += tonumber(fs)
			print(("CheckAll: | %s | %s | %s | %s | %s |"):format(name, phase, ps, fs, fails ~= "" and fails or "-"))
		end
	end
	print(("CheckAll: %s, %d rows, %d PASS, %d FAIL"):format(tf == 0 and rows > 0 and "PASS" or "FAIL", rows, tp, tf))
elseif mode == "cleanup" then
	cleanup()
else
	print("CheckAll: set Workspace.HFB_CheckAllMode to prepare, arm, disarm, summary or cleanup first (see the header)")
end
