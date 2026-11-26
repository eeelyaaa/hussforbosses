if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-13 / M1-19: the sync test (m1-sound-proof.md "The sync test"; sound-direction.md step 7).
-- NOT a loader-run script: it needs play mode. Sync src/ in edit mode first, then run this file's text with the Studio MCP
-- run_script_in_play_mode (mode start_play, timeout 100), ONE cap per call (prefix the text with _G.HFB_SYNC_CAPS = { 60 }, then 30, then 15). It is a SERVER script: it sets the client hooks, stands the
-- player on the bag pad, collects every Profile.TestReport the real client sends (ReportBeats: "beats" from BurstClock,
-- "audio" from Controllers/Audio), and judges 20 bursts at FrameCap 60, 30 and 15.
-- Per burst, PASS needs: F started exactly once (audio.f == 1, and BurstClock.starts == 1); beats 1, 2, 3 in order, none
-- dropped; each beat's firedAt - scheduled >= -0.0005 (never early) and <= 1/FrameCap + 0.004; F's Play() within 2 ms of
-- t0 (same frame); three thuds per burst (the Audio controller's beat subscriber saw the same three events). Over a phase:
-- Sound.Played events == F plays; no report dropped by the rate limit.
-- Avatar's contact and BossMoves' hit reaction have no counters at M1 (they subscribe to the same BurstClock.onBeat);
-- this test cannot count them: listed UNVERIFIED in the report.
-- Prints "SYNC ..." lines and PASS/FAIL per phase. Clears every hook it sets.
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestHooks = require(ReplicatedStorage.Shared.TestHooks)

local CAPS = _G.HFB_SYNC_CAPS or { 60, 30, 15 } -- the MCP call times out near 100 s: run one cap per call with _G.HFB_SYNC_CAPS = { 60 }
local BURSTS = 20
local SPEED = 10 -- Punch Speed level: the shortest cycle (0.5 s ring + 0.61 s), so 20 bursts take about 25 s a phase
local PHASE_TIMEOUT = 70
local BEAT = require(ReplicatedStorage.Shared.Config).Punch.BEAT

local function setHook(name, v) workspace:SetAttribute("HFB_" .. name, v) end
local function clearHooks()
	for _, n in ipairs({ "ReportBeats", "AutoTap", "FrameCap", "SetSpeed", "AutoMix" }) do setHook(n, nil) end
end

local player = Players:GetPlayers()[1]
local t = os.clock()
while not player and os.clock() - t < 20 do task.wait(0.2); player = Players:GetPlayers()[1] end
assert(player, "SyncTest: no player")
local char = player.Character or player.CharacterAdded:Wait()
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Profile"):WaitForChild("TestReport")

local cur = nil -- the phase being collected
local conn = remote.OnServerEvent:Connect(function(p, payload)
	if p ~= player or not cur or type(payload) ~= "table" or type(payload.json) ~= "string" then return end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, payload.json)
	if not ok then return end
	if payload.name == "beats" then
		table.insert(cur.beats, data)
	elseif payload.name == "audio" then
		cur.audio[data.id] = data
	elseif payload.name == "sprobe" then
		cur.sp[data.id] = data
	end
end)

local results = {}
local function run(cap)
	cur = { beats = {}, audio = {}, sp = {} }
	setHook("ReportBeats", true)
	setHook("FrameCap", cap)
	setHook("SetSpeed", SPEED)
	task.wait(0.5)
	local pad = workspace.Plots.Plot1.BagPad
	char = player.Character or char
	char:PivotTo(pad.CFrame * CFrame.new(0, 3, 0))
	task.wait(0.7)
	if _G.HFB_SYNC_FIGHT then
		-- fight phase: Power 25, the client's Huss press starts the fight (about 3 bursts to the win)
		setHook("Wipe", true); task.wait(0.5); setHook("SetPower", 25); task.wait(0.5)
		local ring = workspace.Zones.Z1.Pads.Fixed.Ring
		char:PivotTo(CFrame.new(ring.Position + Vector3.new(1, ring.Size.Y / 2 + 3, 1)))
		task.wait(0.4)
	end
	setHook("AutoTap", "good")
	local t0 = os.clock()
	local want = if _G.HFB_SYNC_FIGHT then 3 else BURSTS + 1
	while #cur.beats < want and os.clock() - t0 < PHASE_TIMEOUT do task.wait(0.25) end
	setHook("AutoTap", nil)
	task.wait(1.5) -- the last audio report
	setHook("FrameCap", nil)
	local ph = cur
	do -- sprobe summary: avatar Hit markers and boss reactions against the beat schedule
		local avN, avWorst, avOff, bmN, bmWorst, bmKinds, spN = 0, 0, { {}, {}, {} }, 0, 0, {}, 0
		for _, b in ipairs(ph.beats) do
			local sp = ph.sp[b.id]
			if sp then
				spN += 1
				for _, h in ipairs(sp.av) do
					avN += 1
					local k = h[1]
					if k >= 1 and k <= 3 then
						local d = h[2] - BEAT[k] * 1000
						table.insert(avOff[k], d)
						avWorst = math.max(avWorst, math.abs(d))
					end
				end
				for _, m in ipairs(sp.bm) do
					bmN += 1
					bmKinds[m[1]] = (bmKinds[m[1]] or 0) + 1
					local best = math.huge
					for _, e in ipairs(b.b) do best = math.min(best, math.abs(m[2] - e[3] * 1000)) end
					bmWorst = math.max(bmWorst, best)
				end
			end
		end
		local function avg(t) local s2 = 0 for _, v in ipairs(t) do s2 += v end return #t > 0 and s2 / #t or 0 end
		local kinds = {}
		for k, v in pairs(bmKinds) do table.insert(kinds, k .. "=" .. v) end
		table.sort(kinds)
		print(("SYNCPROBE cap %d: sprobe reports %d of %d bursts; avatar Hit markers %d (mean offset from BEAT ms: n1 %.1f, n2 %.1f, n3 %.1f; worst %.1f); BossMoves.play calls %d (%s), worst distance from the nearest beat firedAt %.1f ms"):format(
			cap, spN, #ph.beats, avN, avg(avOff[1]), avg(avOff[2]), avg(avOff[3]), avWorst, bmN, table.concat(kinds, " "), bmWorst))
		for i = math.max(1, #ph.beats - 2), #ph.beats do
			local sp = ph.sp[ph.beats[i].id]
			if sp then print("SYNCPROBE   sample " .. HttpService:JSONEncode(sp)) end
		end
	end
	cur = nil

	-- the first burst of a phase is dropped when more than BURSTS arrived (the cap hook takes a frame to settle)
	local list = ph.beats
	local first = math.max(1, #list - BURSTS + 1)
	local bad, n, worstLate, worstFDt = {}, 0, -1, 0
	local prevThuds, thudsOk = nil, true
	for i = first, #list do
		local b = list[i]
		n += 1
		local tag = ("burst %d (id %s)"):format(n, tostring(b.id))
		if b.starts ~= 1 then table.insert(bad, tag .. ": BurstClock.starts = " .. tostring(b.starts)) end
		if #b.b ~= 3 then table.insert(bad, tag .. ": " .. #b.b .. " beats") end
		for k, e in ipairs(b.b) do -- { n, scheduled, firedAt, lateFrames, frame, noContact }
			local late = e[3] - BEAT[k]
			if e[1] ~= k then table.insert(bad, tag .. (": beat order %d at slot %d"):format(e[1], k)) end
			if late < -0.0005 then table.insert(bad, tag .. (": beat %d early by %.1f ms"):format(k, -late * 1000)) end
			if late > 1 / cap + 0.004 then table.insert(bad, tag .. (": beat %d late by %.1f ms (limit %.1f)"):format(k, late * 1000, (1 / cap + 0.004) * 1000)) end
			worstLate = math.max(worstLate, late)
		end
		local a = ph.audio[b.id]
		if not a then
			table.insert(bad, tag .. ": no audio report")
		else
			if a.f ~= 1 then table.insert(bad, tag .. ": F plays = " .. tostring(a.f)) end
			if a.dMs == nil or a.dMs > 2 or a.dMs < 0 then table.insert(bad, tag .. ": F start minus t0 = " .. tostring(a.dMs) .. " ms") end
			worstFDt = math.max(worstFDt, a.dMs or 0)
			if prevThuds and a.thuds - prevThuds ~= 3 then thudsOk = false; table.insert(bad, tag .. ": thuds " .. (a.thuds - prevThuds)) end
			prevThuds = a.thuds
			if a.played ~= a.fPlays and a.played ~= a.fPlays - 1 then
				-- Played fires from the engine a frame after Play(): the last one may trail by one
				table.insert(bad, tag .. (": Sound.Played %d vs F plays %d"):format(a.played, a.fPlays))
			end
		end
	end
	if n < BURSTS then table.insert(bad, ("only %d bursts collected (wanted %d)"):format(n, BURSTS)) end
	local dropped = TestHooks.reports._dropped["Profile.TestReport"] or 0
	print(("SYNC cap %d: bursts %d, worst beat lateness %.1f ms (limit %.1f), worst F start after t0 %.3f ms, reports dropped so far %d"):format(
		cap, n, worstLate * 1000, (1 / cap + 0.004) * 1000, worstFDt, dropped))
	for _, s in ipairs(bad) do print("SYNC   " .. s) end
	print(("%s SyncTest FrameCap %d"):format(#bad == 0 and n >= BURSTS and "PASS" or "FAIL", cap))
	table.insert(results, #bad == 0 and n >= BURSTS)
end

local ok, err = xpcall(function()
	setHook("Wipe", true)
	task.wait(1)
	for _, cap in ipairs(CAPS) do run(cap) end
end, debug.traceback)
conn:Disconnect()
clearHooks()
if not ok then print("FAIL SyncTest crashed: " .. tostring(err)) end
local passed = 0
for _, r in ipairs(results) do if r then passed += 1 end end
print(("%s SyncTest overall (%d of %d phases passed)"):format(ok and passed == #CAPS and "PASS" or "FAIL", passed, #CAPS))
print("SYNC UNVERIFIED: Avatar contact / BossMoves reaction counts (no counters at M1); how the sound feels against the picture on a phone")
