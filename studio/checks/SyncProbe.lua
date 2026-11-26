if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-19: the sync-test client probe. CLIENT script. The audio specialist installs it as the LocalScript
-- StarterPlayer.StarterPlayerScripts.HFB_SyncProbe for the run and removes it after (it must never ship).
-- Per finished burst (with Workspace.HFB_ReportBeats on) it sends Profile.TestReport "sprobe":
--   { id, c = context, av = { {n, ms after t0} }  the Avatar "Hit" markers that fired since this burst's t0,
--     bm = { {move, ms after t0} }                every BossMoves.play call since t0 (hit reactions hang off the beat) }
-- Times are os.clock() differences from the burst's t0, in ms (1 decimal). Studio only.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local TestHooks = require(ReplicatedStorage.Shared.TestHooks)
local C = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Controllers")
local BurstClock = require(C:WaitForChild("BurstClock"))
local Avatar = require(C:WaitForChild("Avatar"))
local BM = require(C:WaitForChild("BossMoves"))

local plays = {} -- { name, at }
local orig = BM.play
BM.play = function(model, name, opts)
	table.insert(plays, { name, os.clock() })
	if #plays > 100 then table.remove(plays, 1) end
	return orig(model, name, opts)
end

local function r1(x) return math.floor(x * 10000 + 0.5) / 10 end
BurstClock.onDone(function(id, entries)
	local first = entries[1]
	if not first then return end
	local t0, ctx = first.t0, first.context
	task.wait(0.45) -- the last Hit marker and the last reaction have fired
	if TestHooks.get("ReportBeats") ~= true then return end
	local nextT0 = math.huge
	for _, e in ipairs(BurstClock.log) do
		if e.burstId ~= id and e.t0 > t0 and e.t0 < nextT0 then nextT0 = e.t0 end
	end
	local av, bm = {}, {}
	for _, h in ipairs(Avatar.hitLog) do
		if h.elapsed >= t0 - 0.002 and h.elapsed < nextT0 then table.insert(av, { h.n, r1(h.elapsed - t0), h.track }) end
	end
	for _, p in ipairs(plays) do
		if p[2] >= t0 - 0.002 and p[2] < nextT0 then table.insert(bm, { p[1], r1(p[2] - t0) }) end
	end
	local ok, json = pcall(HttpService.JSONEncode, HttpService, { id = id, c = ctx, av = av, bm = bm })
	if ok then Net.get("Profile", "TestReport"):FireServer({ name = "sprobe", json = string.sub(json, 1, 1000) }) end
end)
print("[HFB] SyncProbe armed")
