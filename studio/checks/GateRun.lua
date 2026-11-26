if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M2-28: the M2 gate's play-mode runner. Installed by Gate.lua ("prepare" / "install") as ServerStorage.TmpChecks.GateRun, wrapped as
-- `return function(...) <this> end`. PLAY MODE, one run_script_in_play_mode (start_play) call, which runs the gate's play calls in
-- order (studio/checks/GateData.lua, PLAY) until its time budget is used, prints one row per call and says where to go on:
--   require(game.ServerStorage.TmpChecks.GateRun)({ start = 1 })              the main list (brickbrawl skin)
--   require(game.ServerStorage.TmpChecks.GateRun)({ list = "stub", start = 1 })  after Gate "arm" (HFB_ForceSkin = stub set in edit mode)
--   { only = "Punch2/c" }   one call by id;  { budget = 50 }  seconds a run may take: a call starts only if its estimated length
-- (GateData est) still fits. The MCP returns NOTHING when a call runs past about 60 s, so keep to 50 (a single call longer than that
-- cannot be run: split it into phases).
-- Row line (the Gate summary reads these):  GATE row <call id>|<PASS count>|<FAIL count>|<failed labels>|<seconds>
-- Then:  GATE next <n>  (call again with start = n)  or  GATE done <list>.  After each call every HFB_ attribute is cleared (except
-- HFB_ForceSkin, which only Gate "disarm" and "cleanup" clear) and one still set is a FAIL of that call ("hook left armed").
local ARGS = ...
if type(ARGS) ~= "table" then ARGS = {} end
local ServerStorage = game:GetService("ServerStorage")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local TMP = ServerStorage:WaitForChild("TmpChecks", 10)
assert(TMP, "GateRun: ServerStorage.TmpChecks missing (Gate mode 'prepare' or 'install' first)")
local D = require(TMP.GateData)
local list = ARGS.list == "stub" and D.STUB or D.PLAY
local budget = ARGS.budget or 50
local T0 = os.clock()
local KEEP = { HFB_ForceSkin = true, HFB_PlayStopValue = true }

local function newTally()
	return { pass = 0, fail = 0, fails = {}, sumPass = nil, sumFail = nil, sumFails = nil }
end

-- one printed line into the tally: PASS / FAIL lines, and the check's own totals (they win when present)
local function feed(t, m)
	if m:sub(1, 5) == "GATE " then return end
	local a, b = m:match("pass=(%d+) fail=(%d+)")
	if a and (m:sub(1, 6) == "CHECK " or m:find("TOTAL", 1, true)) then
		t.sumPass, t.sumFail = tonumber(a), tonumber(b)
		return
	end
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

local function leftovers()
	local left = {}
	for k in pairs(workspace:GetAttributes()) do
		if k:sub(1, 4) == "HFB_" and not KEEP[k] then table.insert(left, k) end
	end
	return left
end

local function waitPlayer()
	local p = Players:GetPlayers()[1]
	local t = os.clock()
	while not p and os.clock() - t < 20 do task.wait(0.1); p = Players:GetPlayers()[1] end
	assert(p, "no player joined in 20 s")
	if not p.Character then p.CharacterAdded:Wait() end
	return p
end

-- FightCamera/<set>: the M1-26b client probe (HFB_FightCamProbe) walks into Chomp Frog's ring from each start spot, presses Huss and
-- projects the camera; its lines come back as Profile.TestReport m126_<n> and are counted here.
local function fightCamera(set, t)
	local Net = require(ReplicatedStorage.Shared.Net)
	local p = waitPlayer()
	local done, any = false, false
	local conn = Net.get("Profile", "TestReport").OnServerEvent:Connect(function(pl, payload)
		if pl ~= p or type(payload) ~= "table" or type(payload.name) ~= "string" or type(payload.json) ~= "string" then return end
		if payload.name == "m126_done" then done = true return end
		if not payload.name:match("^m126_%d+$") then return end
		local ok, d = pcall(HttpService.JSONDecode, HttpService, payload.json)
		if not (ok and type(d) == "table" and type(d.line) == "string") then return end
		any = true
		print("M126 " .. d.line:sub(1, 300))
		if d.line:find("|PASS ", 1, true) then t.pass += 1
		elseif d.line:find("|FAIL", 1, true) then t.fail += 1; table.insert(t.fails, d.line:sub(1, 110)) end
	end)
	workspace:SetAttribute("HFB_Wipe", true)
	task.wait(0.5)
	workspace:SetAttribute("HFB_SetPower", 25)
	task.wait(0.5)
	workspace:SetAttribute("HFB_M126Spots", nil)
	task.wait(0.3)
	workspace:SetAttribute("HFB_M126Spots", set)
	local t1 = os.clock()
	while not done and os.clock() - t1 < 75 do
		if not any and os.clock() - t1 > 25 then break end
		task.wait(0.25)
	end
	workspace:SetAttribute("HFB_M126Spots", nil)
	conn:Disconnect()
	if not done then t.fail += 1; table.insert(t.fails, any and "the probe did not finish in 75 s" or "no probe report in 25 s (is StarterPlayerScripts.HFB_FightCamProbe installed?)") end
end

local function runOne(call)
	local t = newTally()
	local started = os.clock()
	local conn = LogService.MessageOut:Connect(function(m) feed(t, m) end)
	local ok, err = pcall(function()
		if call.special == "fightcamera" then
			fightCamera(call.arg, t)
			return
		end
		local mod = require(TMP[call.module])
		if call.ids then _G.M222_ONLY = call.ids end
		if call.phaseArg then mod(call.arg) else mod(call.arg or {}) end
	end)
	_G.M222_ONLY = nil
	task.wait(0.1)
	conn:Disconnect()
	local p, f = t.sumPass or t.pass, t.sumFail or t.fail
	local fails = (t.sumFails and t.sumFails ~= "") and t.sumFails or table.concat(t.fails, "; ")
	if not ok then
		f += 1
		fails = ("script error: %s; %s"):format(tostring(err):gsub("\n", " "):sub(1, 160), fails)
	end
	local left = leftovers()
	if #left > 0 then
		f += 1
		fails = ("hook left armed: %s; %s"):format(table.concat(left, ","), fails)
		for _, k in ipairs(left) do workspace:SetAttribute(k, nil) end
	end
	if p + f == 0 then f = 1; fails = "no PASS or FAIL lines (the check did not run)" end
	print(("GATE row %s|%d|%d|%s|%.0f"):format(call.id, p, f, (fails:gsub("|", "/")):sub(1, 330), os.clock() - started))
end

if ARGS.only then
	for _, call in ipairs(list) do
		if call.id == ARGS.only then runOne(call) return end
	end
	print("GATE error no call " .. tostring(ARGS.only))
	return
end

local n = ARGS.start or 1
while n <= #list do
	-- a call starts only if its measured length (GateData est, seconds) still fits in the budget; the first call of a run always starts
	if n > (ARGS.start or 1) and os.clock() - T0 + (list[n].est or 30) > budget then
		print(("GATE next %d  (%d of %d calls run in %.0f s)"):format(n, n - (ARGS.start or 1), #list, os.clock() - T0))
		return
	end
	if n > (ARGS.start or 1) then
		task.wait(1.1) -- LogService timestamps are whole seconds: the next check must start in a later second than the last line of this one
		_G.HFB_GATE_LOG_FROM = os.time()
	end
	runOne(list[n])
	n += 1
end
print(("GATE done %s list (%d calls, %.0f s in this call)"):format(ARGS.list or "play", #list, os.clock() - T0))
