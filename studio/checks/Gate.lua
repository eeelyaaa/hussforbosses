if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-28: the M2 gate "Systems" (team/requirements/m2-gate.md): ONE driver for every check of the gate, rows S1..S27. It supersedes
-- CheckAll's M1 list (the M1 checks are inside it, row S27; CheckAll still works). EDIT MODE, holding the `studio` lock; the mode is the
-- Studio-script switch Workspace.HFB_GateMode (team/test-hooks.md; this script clears it):
--
--   workspace:SetAttribute("HFB_GateMode", "prepare"); require(game.ServerStorage.DevSync:Clone()).run("checks/Gate.lua")
--
--   prepare   sync src/, run the edit-mode checks (CheckSync, CheckSkin A-E, Refusals live, BoughtScan, HudViews, PerfectFloat,
--             ScreensA/B/C: one GATE row each), install ServerStorage.TmpChecks (every play-mode check, GateData, GateRun) and the
--             client probes (StarterPlayerScripts.HFB_CheckProbe, HFB_FightCamProbe), print the play calls.
--   install   install only (after editing a check file; no sync, no edit-mode checks).
--   edit      the edit-mode checks only.
--   (play)    one run_script_in_play_mode (start_play) per call, repeat until it prints "GATE done":
--               require(game.ServerStorage.TmpChecks.GateRun)({ start = 1 })     then  { start = <n it printed> } ...
--   arm       set HFB_ForceSkin = "stub" (skin check part 2); then the stub list:  require(...GateRun)({ list = "stub", start = 1 })
--   disarm    clears HFB_ForceSkin and the stub boss folder.
--   playstop1 / playstop2   the Play-stop save check (PlayStop.lua): step 1 installs and arms; then ONE play call
--               require(game.ServerStorage.TmpChecksData.PlayStop)() and stop play with the MCP (not after other calls: the stop is
--               the test); step 2 reads the record back and prints the row.
--   summary   set Workspace.HFB_GateRows to every `GATE row` line (the play calls', this script's, tools/gate_scans.py's, ';;'-separated;
--             a document row: `doc:S25|<pass>|<fail>|<why>`) and run: the per-row table S1..S27 with PASS / FAIL / UNVERIFIED and the counts.
--   cleanup   removes TmpChecks, TmpChecksData, the probes and the stub boss folder, clears EVERY HFB_ attribute and asserts that nothing
--             of the gate is left in the place. Never leave the gate installed.
-- Row line: GATE row <call id>|<PASS>|<FAIL>|<failed labels>|<seconds>.
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local BASE = "http://127.0.0.1:34874"

local mode = workspace:GetAttribute("HFB_GateMode")
workspace:SetAttribute("HFB_GateMode", nil)
local DevSync = ServerStorage:FindFirstChild("DevSync")
assert(DevSync, "Gate: ServerStorage.DevSync missing (team/CLAUDE.md, recreate the loader)")

-- play-mode check modules (each wrapped as `return function(...) <file> end`)
local MODULES = { "CheckLib", "CoreLoop", "Refusals", "BurstValues", "NoDelay", "Punch2", "Bag", "Zones", "Hazards", "Base", "Upgrades", "Offline",
	"Rebirth", "Steal", "Shield", "Policy", "Robux", "Spin", "FirstSession", "Saving", "SkinCheck3", "MovesM2Real", "FrogMoves", "Curves" }
local GUARD = 'if workspace:GetAttribute("HussForBosses")'

local function fetch(name)
	return HttpService:GetAsync(BASE .. "/studio/checks/" .. name .. ".lua", true)
end

local function stripGuard(src) -- a real client may run before the attribute replicates (M2-32 lesson): client copies lose the guard line
	if src:sub(1, #GUARD) == GUARD then
		local nl = src:find("\n", 1, true)
		return nl and src:sub(nl + 1) or ""
	end
	return src
end

local function mk(parent, name, source)
	local m = Instance.new("ModuleScript")
	m.Name = name
	m.Source = source
	m.Parent = parent
	return m
end

local function install()
	local old = ServerStorage:FindFirstChild("TmpChecks")
	if old then old:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = "TmpChecks"
	for _, name in ipairs(MODULES) do
		mk(folder, name, "return function(...)\n" .. fetch(name) .. "\nend\n")
	end
	mk(folder, "GateData", "local GATE_DATA\n" .. fetch("GateData") .. "\nreturn GATE_DATA\n")
	mk(folder, "GateRun", "return function(...)\n" .. fetch("GateRun") .. "\nend\n")
	folder.Parent = ServerStorage
	local sps = StarterPlayer.StarterPlayerScripts
	for _, p in ipairs({ { "HFB_CheckProbe", "CheckProbe" }, { "HFB_FightCamProbe", "FightCameraProbe.client" } }) do
		local o = sps:FindFirstChild(p[1])
		if o then o:Destroy() end
		local ls = Instance.new("LocalScript")
		ls.Name = p[1]
		ls.Source = stripGuard(fetch(p[2]))
		ls.Parent = sps
	end
	print(("Gate: installed ServerStorage.TmpChecks (%d modules + GateData + GateRun) and the client probes HFB_CheckProbe, HFB_FightCamProbe"):format(#MODULES))
end

local function data()
	if not (ServerStorage:FindFirstChild("TmpChecks") and ServerStorage.TmpChecks:FindFirstChild("GateData")) then install() end
	return require(ServerStorage.TmpChecks.GateData)
end

-- the tally of one run: PASS / FAIL lines, and the check's own totals when it prints them (same rules as GateRun)
local function feed(t, m)
	if m:sub(1, 5) == "GATE " then return end
	local a, b = m:match("pass=(%d+) fail=(%d+)")
	if a and (m:sub(1, 6) == "CHECK " or m:find("TOTAL", 1, true)) then t.sumPass, t.sumFail = tonumber(a), tonumber(b) return end
	local fl = m:match("^CHECKALL row [^|]*|[^|]*|%d+|%d+|(.*)$")
	if fl then t.sumFails = fl return end
	a, b = m:match("(%d+) passed, (%d+) failed")
	if a then t.sumPass, t.sumFail = tonumber(a), tonumber(b) return end
	local kind
	if m:sub(1, 5) == "PASS " then kind = "pass" elseif m:sub(1, 5) == "FAIL " then kind = "fail" else
		local w = m:match("^[%w_%.]+: (%u+) ")
		if w == "PASS" then kind = "pass" elseif w == "FAIL" then kind = "fail" end
	end
	if kind == "pass" then t.pass += 1 elseif kind == "fail" then t.fail += 1; table.insert(t.fails, (m:gsub("|", "/")):sub(1, 110)) end
end

local function runEdit(e)
	local t = { pass = 0, fail = 0, fails = {} }
	local started = os.clock()
	local conn = LogService.MessageOut:Connect(function(m) feed(t, m) end)
	if e.noArm then workspace:SetAttribute("HFB_CheckSkinNoArm", true) end
	local ok, err = pcall(function()
		if e.file then
			require(DevSync:Clone()).run(e.file)
		else
			require(ServerStorage.TmpChecks[e.tmp])(e.arg or {})
		end
	end)
	task.wait(0.1)
	conn:Disconnect()
	workspace:SetAttribute("HFB_CheckSkinNoArm", nil)
	local p, f = t.sumPass or t.pass, t.sumFail or t.fail
	local fails = (t.sumFails and t.sumFails ~= "") and t.sumFails or table.concat(t.fails, "; ")
	if not ok then f += 1; fails = ("script error: %s; %s"):format(tostring(err):sub(1, 160), fails) end
	if p + f == 0 then f = 1; fails = "no PASS or FAIL lines (the check did not run)" end
	print(("GATE row %s|%d|%d|%s|%.0f"):format(e.id, p, f, (fails:gsub("|", "/")):sub(1, 330), os.clock() - started))
end

local function runEdits()
	local D = data()
	for _, e in ipairs(D.EDIT) do runEdit(e) end
end

local function plan()
	local D = data()
	print(("Gate: %d play calls in the main list, %d in the stub list. One run_script_in_play_mode (start_play) per command, repeat until it prints GATE done:"):format(#D.PLAY, #D.STUB))
	print("Gate:   require(game.ServerStorage.TmpChecks.GateRun)({ start = 1 })      then start = <the number it prints after GATE next>")
	print("Gate: then mode 'arm' (stub skin), the stub list { list = \"stub\", start = 1 }, then mode 'disarm'; playstop1 / playstop2; the scans: python tools/gate_scans.py")
	print("Gate: then mode 'summary' (HFB_GateRows = every GATE row line, ';;'-separated), then mode 'cleanup'")
end

local function cleanup()
	local gone = {}
	for _, n in ipairs({ "TmpChecks", "TmpChecksData", "HFB_SkinCheck", "HFB_SkinCheck_tmp", "HFB_RefusalsLive" }) do
		local o = ServerStorage:FindFirstChild(n)
		if o then o:Destroy(); table.insert(gone, n) end
	end
	-- only the probes the gate installs (HFB_ReviewLine* in StarterPlayerScripts belong to the boss review line, M2-32)
	for _, nme in ipairs({ "HFB_CheckProbe", "HFB_FightCamProbe", "HFB_ClientPunchProbe", "HFB_ClientAProbe", "HFB_ShopClientProbe", "HFB_StealClientProbe" }) do
		local o = StarterPlayer.StarterPlayerScripts:FindFirstChild(nme)
		if o then table.insert(gone, o.Name); o:Destroy() end
	end
	local n = 0
	for k in pairs(workspace:GetAttributes()) do
		if k:sub(1, 4) == "HFB_" then workspace:SetAttribute(k, nil); n += 1 end
	end
	local left = {}
	for k in pairs(workspace:GetAttributes()) do
		if k:sub(1, 4) == "HFB_" then table.insert(left, k) end
	end
	for _, nme in ipairs({ "HFB_CheckProbe", "HFB_FightCamProbe" }) do
		if StarterPlayer.StarterPlayerScripts:FindFirstChild(nme) then table.insert(left, nme) end
	end
	for _, nme in ipairs({ "TmpChecks", "TmpChecksData", "HFB_SkinCheck" }) do
		if ServerStorage:FindFirstChild(nme) then table.insert(left, nme) end
	end
	print(("Gate: cleaned up (%s; %d HFB_ attributes cleared)"):format(#gone > 0 and table.concat(gone, ", ") or "nothing installed", n))
	print(("Gate: %s nothing of the gate is left in the place (HFB_ attributes, TmpChecks, probes)%s; marker %s"):format(#left == 0 and "PASS" or "FAIL", #left > 0 and (": " .. table.concat(left, ", ")) or "", tostring(workspace:GetAttribute("HussForBosses"))))
end

local function summary()
	local D = data()
	local raw = workspace:GetAttribute("HFB_GateRows")
	workspace:SetAttribute("HFB_GateRows", nil)
	assert(type(raw) == "string", "Gate summary: set Workspace.HFB_GateRows first (the GATE row lines, ';;'-separated)")
	local res = {}
	for row in (raw .. ";;"):gmatch("(.-);;") do
		row = row:gsub("^%s*GATE row%s+", "")
		local id, ps, fs, fails, secs = row:match("^%s*([^|]+)|(%d+)|(%d+)|?([^|]*)|?(.*)$")
		if id then res[id] = { pass = tonumber(ps), fail = tonumber(fs), fails = fails or "", secs = secs } end
	end
	local used, counts, tp, tf = {}, { PASS = 0, FAIL = 0, UNVERIFIED = 0 }, 0, 0
	print("GATE | Row | Status | Detail |")
	print("GATE |---|---|---|")
	for _, row in ipairs(D.ROWS) do
		local failing, missing, parts = {}, {}, {}
		for _, id in ipairs(row.needs) do
			used[id] = true
			local r = res[id]
			if not r then
				table.insert(missing, id)
			else
				table.insert(parts, ("%s %d/%d"):format(id, r.pass, r.fail))
				if r.fail > 0 then table.insert(failing, ("%s: %s"):format(id, r.fails ~= "" and r.fails or (r.fail .. " fail"))) end
			end
		end
		local status, detail
		if #failing > 0 then
			status, detail = "FAIL", table.concat(failing, " || "):sub(1, 400)
		elseif row.blocking then
			status, detail = "UNVERIFIED", row.blocking .. "; scripted parts: " .. table.concat(parts, ", ")
		elseif #missing > 0 then
			status, detail = "UNVERIFIED", "not run: " .. table.concat(missing, ", ")
		else
			status, detail = "PASS", table.concat(parts, ", ")
		end
		if status ~= "FAIL" and #missing > 0 and row.blocking then detail ..= "; not run: " .. table.concat(missing, ", ") end
		if row.unverified and status == "PASS" then detail ..= " | not scripted (UNVERIFIED part): " .. row.unverified end
		counts[status] += 1
		print(("GATE | %s | %s | %s |"):format(row.id, status, detail))
	end
	local extra = {}
	for id, r in pairs(res) do
		tp += r.pass
		tf += r.fail
		if not used[id] then table.insert(extra, ("%s %d/%d"):format(id, r.pass, r.fail)) end
	end
	table.sort(extra)
	print(("GATE other checks (in no row): %s"):format(#extra > 0 and table.concat(extra, ", ") or "none"))
	print(("GATE %s: %d PASS, %d FAIL, %d UNVERIFIED rows of %d; %d check calls, %d PASS and %d FAIL lines in all"):format(
		counts.FAIL == 0 and counts.UNVERIFIED == 0 and "PASS" or "NOT PASSING", counts.PASS, counts.FAIL, counts.UNVERIFIED, #D.ROWS, (function() local c = 0 for _ in pairs(res) do c += 1 end return c end)(), tp, tf))
end

if mode == "prepare" then
	require(DevSync:Clone())()
	install()
	print("Gate: --- edit-mode checks")
	runEdits()
	plan()
elseif mode == "install" then
	install()
	plan()
elseif mode == "edit" then
	runEdits()
elseif mode == "arm" then
	data()
	workspace:SetAttribute("HFB_ForceSkin", "stub")
	print("Gate: armed HFB_ForceSkin = stub; now start play (the skin is read when Shared/Skin is first required) and run { list = \"stub\", start = 1 }, then mode 'disarm'")
elseif mode == "disarm" then
	workspace:SetAttribute("HFB_ForceSkin", nil)
	local f = ServerStorage:FindFirstChild("HFB_SkinCheck")
	if f then f:Destroy() end
	print("Gate: disarmed: HFB_ForceSkin = " .. tostring(workspace:GetAttribute("HFB_ForceSkin")))
elseif mode == "playstop1" then
	local old = workspace:GetAttribute("HFB_PlayStopValue")
	workspace:SetAttribute("HFB_PlayStopValue", nil)
	require(DevSync:Clone()).run("checks/PlayStop.lua")
	print("Gate: PlayStop armed (HFB_PlayStopValue " .. tostring(workspace:GetAttribute("HFB_PlayStopValue")) .. "); now ONE play call require(game.ServerStorage.TmpChecksData.PlayStop)() and stop play with the MCP, then mode 'playstop2'" .. (old and " (an old value was cleared)" or ""))
elseif mode == "playstop2" then
	runEdit({ id = "edit:PlayStop", file = "checks/PlayStop.lua" })
elseif mode == "summary" then
	summary()
elseif mode == "cleanup" then
	cleanup()
else
	print("Gate: set Workspace.HFB_GateMode to prepare, install, edit, arm, disarm, playstop1, playstop2, summary or cleanup first (see the header)")
end
