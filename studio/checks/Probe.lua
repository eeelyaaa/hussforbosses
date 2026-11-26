if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
local _lines = {}
local _print = print
local function print(...)
	local t = table.pack(...)
	for i = 1, t.n do t[i] = tostring(t[i]) end
	table.insert(_lines, table.concat(t, " "))
	_print(...)
end
-- M1-13 envelope probe on the UPLOADED burst voice F (contract D step 5, m1-sound-proof.md criterion 3).
-- Run in EDIT mode through the sync:  require(game.ServerStorage.DevSync:Clone()).run("checks/Probe.lua")
-- Method (the same as deja-kill's, vault/patterns/audio-envelope-probe-before-trimming.md): an AudioPlayer wired only
-- into an AudioAnalyzer (no AudioDeviceOutput: nothing is heard) plays the asset slowly; every Heartbeat records the
-- player's TimePosition and the analyzer's PeakLevel (one value per audio block, about 21 ms of real time, so about
-- 5 ms of the file at PlaybackSpeed 0.25 and 2 ms at 0.1). From the samples: the length, the lead (first sample 30 dB
-- under the file's loudest), and the onset of each of the three loud parts (the last sample before the part's peak that
-- is 20 dB under that part's peak, the pack's method). The three parts are searched in windows around the local file's
-- onsets (tools/audio/probe.py: 0.007, 0.233, 0.420). Limits: a time resolution of one block, and an unknown constant
-- bias between TimePosition and the block the analyzer reports; the GAPS between parts do not carry that bias.
-- Prints one table, and also leaves it in ServerStorage._HFBProbeOut (a StringValue) for a caller that cannot see the
-- console: read it, then destroy it. Never returns (the loader appends one).
local RunService = game:GetService("RunService")
local Skin = require(game.ReplicatedStorage.Shared.Skin)
local Sounds = Skin.Sounds
local url = Skin.assetUrl(Sounds.burstVoice)
local LOCAL = { 0.007, 0.233, 0.420 } -- local-file onsets (search windows only)
local BRIEF = { 0, 0.213, 0.401 } -- Config.Punch.BEAT
local LEAD = Sounds.F_LEAD
local SPEEDS = { 0.25, 0.25, 0.1 }

local function scan(speed)
	local folder = Instance.new("Folder")
	folder.Name = "_HFBProbe"
	folder.Parent = game:GetService("ServerStorage")
	local p = Instance.new("AudioPlayer")
	p.Asset = url
	p.PlaybackSpeed = speed
	p.Parent = folder
	local a = Instance.new("AudioAnalyzer")
	a.Parent = folder
	local w = Instance.new("Wire")
	w.SourceInstance = p
	w.TargetInstance = a
	w.Parent = folder
	local t0 = os.clock()
	while not p.IsReady and os.clock() - t0 < 8 do
		task.wait(0.05)
	end
	local ready = p.IsReady
	local len = p.TimeLength
	p.TimePosition = 0
	p:Play()
	local out, last = {}, nil
	while p.IsPlaying and os.clock() - t0 < 40 do
		RunService.Heartbeat:Wait()
		local tp = p.TimePosition
		if last and tp < last then
			break -- the player wrapped to 0 at the end of the file
		end
		if tp ~= last then
			last = tp
			table.insert(out, { tp, a.PeakLevel })
		end
	end
	p:Stop()
	folder:Destroy()
	return { ready = ready, len = len, s = out }
end

local function analyse(r)
	local s = r.s
	local gmax = 0
	for _, v in ipairs(s) do
		gmax = math.max(gmax, v[2])
	end
	local res = { len = r.len, ready = r.ready, n = #s, gmax = gmax, onsets = {}, peaks = {} }
	for _, v in ipairs(s) do
		if v[2] >= gmax * 0.0316 then
			res.lead = v[1]
			break
		end
	end
	for k = 1, 3 do
		local lo, hi = LOCAL[k] - 0.03, LOCAL[k] + 0.12
		local pk, pkT = 0, nil
		for _, v in ipairs(s) do
			if v[1] >= lo and v[1] <= hi and v[2] > pk then
				pk, pkT = v[2], v[1]
			end
		end
		local onset = nil
		if pkT then
			onset = 0
			for _, v in ipairs(s) do
				if v[1] <= pkT and v[2] < pk * 0.1 then
					onset = v[1]
				end
			end
		end
		res.onsets[k], res.peaks[k] = onset, pkT
	end
	return res
end

if not url then
	print("FAIL Probe: Sounds.burstVoice has no id")
else
	local all = {}
	for i, sp in ipairs(SPEEDS) do
		local r = scan(sp)
		local a = analyse(r)
		all[i] = a
		local env = {}
		for _, v in ipairs(r.s) do
			table.insert(env, string.format("%.3f:%.0f", v[1], v[2] * 1000))
		end
		print(("PROBE pass %d speed %.2f ready=%s len=%.4f samples=%d peakmax=%.3f lead(-30dB)=%s"):format(
			i, sp, tostring(a.ready), a.len or -1, a.n, a.gmax, a.lead and string.format("%.3f", a.lead) or "nil"))
		print(("PROBE pass %d onsets(-20dB) = %s | peaks at = %s"):format(
			i,
			table.concat({ a.onsets[1] and string.format("%.3f", a.onsets[1]) or "nil", a.onsets[2] and string.format("%.3f", a.onsets[2]) or "nil", a.onsets[3] and string.format("%.3f", a.onsets[3]) or "nil" }, ", "),
			table.concat({ a.peaks[1] and string.format("%.3f", a.peaks[1]) or "nil", a.peaks[2] and string.format("%.3f", a.peaks[2]) or "nil", a.peaks[3] and string.format("%.3f", a.peaks[3]) or "nil" }, ", ")))
		print(("PROBE pass %d envelope (time:peak x1000) %s"):format(i, table.concat(env, " ")))
	end
	-- verdict from the finest pass that found all three parts
	local best = all[#all]
	if best.onsets[1] and best.onsets[2] and best.onsets[3] then
		for k = 1, 3 do
			local expect = BRIEF[k] + LEAD
			local off = (best.onsets[k] - expect) * 1000
			print(("%s Probe part %d: onset %.3f s, beat %.3f + lead %.3f = %.3f, off %+.0f ms (rule 20 ms)"):format(
				math.abs(off) <= 20 and "PASS" or "FAIL", k, best.onsets[k], BRIEF[k], LEAD, expect, off))
		end
	else
		print("FAIL Probe: not all three loud parts were found in the finest pass")
	end
end
local sv = Instance.new("StringValue")
sv.Name = "_HFBProbeOut"
sv.Value = table.concat(_lines, "\n")
sv.Parent = game:GetService("ServerStorage")
