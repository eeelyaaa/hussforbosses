if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M1-16: the check probe, a CLIENT script. CheckAll ("prepare") installs this file as the LocalScript
-- StarterPlayer.StarterPlayerScripts.HFB_CheckProbe for the checks and "cleanup" removes it (it must never ship).
-- It idles until the Studio-script switch Workspace.HFB_CheckProbe is set (team/test-hooks.md, "Studio-script switches"):
--   "fuzz"  : malformed payloads to every c2s remote, paced under each remote's rate limit (Refusals phase b)
--   "rate"  : 10 calls of each c2s remote in one frame (Refusals phase b, the rate limits)
--   "moves" : wraps the client's BossMoves.play and reports every play: the move, the overlay it cut, the overlay after
--             (NoDelay). The wrapper stays until the play session ends.
-- Reports go out as Profile.TestReport "probe" (Studio only, <= 1 KB). Never runs outside Studio.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local function report(data)
	local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
	if ok then
		if #json > 1000 then json = json:sub(1, 1000) end
		Net.get("Profile", "TestReport"):FireServer({ name = "probe", json = json })
	end
end

local NAN, INF = 0 / 0, math.huge
local junk = { 5, "x", true, {}, { 1, 2, 3 }, { nested = { deep = {} } } } -- plus nil, sent first
local FUZZ = {
	{ "Punch", "Report", {
		{ seq = "1", context = "bag", grade = "good", tapServerTime = 1 },
		{ seq = NAN, context = "bag", grade = "good" },
		{ seq = INF, context = "bag", grade = "good" },
		{ seq = 1e308, context = "bag", grade = "good" },
		{ seq = -1, context = "bag", grade = "good" },
		{ seq = 1.5, context = "bag", grade = "good" },
		{ seq = 7, context = "cake", grade = "good" },
		{ seq = 8, context = "bag", grade = "great" },
		{ seq = 9, context = "bag" },
		{ seq = 10, grade = "good" },
		{ seq = 11, context = "bag", grade = "good", tapServerTime = NAN },
		{ seq = 12, context = "bag", grade = "good", tapServerTime = "now" },
		{ seq = 13, context = { "bag" }, grade = "good" },
	} },
	{ "Fight", "Start", { { padId = 5 }, { padId = NAN }, { padId = true }, { padId = { "z1_fixed" } }, { padId = string.rep("z", 500) }, { pad = "z1_fixed" }, { padId = "nope" } } },
	{ "Fight", "Run", { { 1, 2 }, { x = NAN } } },
	{ "Carry", "Grab", { { uid = 42 }, { uid = NAN }, { uid = true }, { uid = string.rep("u", 500) }, { id = "x" }, { uid = { "x" } } } },
	{ "Base", "Place", { { spotIndex = 0 }, { spotIndex = 11 }, { spotIndex = 1.5 }, { spotIndex = "1" }, { spotIndex = NAN }, { spotIndex = INF }, { spotIndex = 1e308 }, { spot = 1 }, { spotIndex = { 1 } } } },
	{ "Profile", "TestReport", { { name = 5, json = "{}" }, { name = "fz", json = 5 }, { name = string.rep("n", 41), json = "{}" }, { name = "fz", json = string.rep("j", 1100) }, { name = "_dropped", json = "{}" }, { json = "{}" } } },
}

local function fuzz()
	local sent = {}
	local threads = 0
	for _, fr in ipairs(FUZZ) do
		threads += 1
		task.spawn(function()
			local key = fr[1] .. "." .. fr[2]
			local remote = Net.get(fr[1], fr[2])
			local list = {}
			for _, j in ipairs(junk) do table.insert(list, { v = j }) end
			table.insert(list, 1, { v = nil })
			for _, pl in ipairs(fr[3]) do table.insert(list, { v = pl }) end
			local gap = if key == "Profile.TestReport" then 0.35 else 1.05 / (require(ReplicatedStorage.Shared.Config).Punch.RATE[key] or 1) -- TestReport shares its 10/s with the TestClient reports
			local n = 0
			for _, item in ipairs(list) do
				remote:FireServer(item.v)
				n += 1
				task.wait(gap)
			end
			sent[key] = n
			threads -= 1
		end)
	end
	local t = os.clock()
	while threads > 0 and os.clock() - t < 22 do task.wait(0.1) end
	task.wait(1.2) -- the TestReport window empties before the done report
	report({ done = "fuzz", sent = sent })
end

local function rate()
	local sent = {}
	for _, fr in ipairs({ { "Punch", "Report", { seq = "x" } }, { "Fight", "Start", { padId = 5 } }, { "Fight", "Run", {} }, { "Carry", "Grab", { uid = 42 } }, { "Base", "Place", { spotIndex = 0 } } }) do
		local remote = Net.get(fr[1], fr[2])
		for _ = 1, 10 do remote:FireServer(fr[3]) end
		sent[fr[1] .. "." .. fr[2]] = 10
	end
	task.wait(0.3)
	report({ done = "rate", sent = sent })
end

local movesOn = false
local function moves()
	if movesOn then return end
	movesOn = true
	local ps = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")
	local BM = require(ps:WaitForChild("Controllers"):WaitForChild("BossMoves"))
	local orig = BM.play
	local buf = {}
	local t0 = os.clock()
	BM.play = function(model, name, opts)
		local _, before = BM.current(model)
		local r = orig(model, name, opts)
		local _, after = BM.current(model)
		-- M2-28: the review line (M2-32) loops every move on its own bosses all the time; only the fight's boss counts
		local rl = workspace:FindFirstChild("ReviewLine")
		if not (rl and typeof(model) == "Instance" and model:IsDescendantOf(rl)) then
			table.insert(buf, { name, before or false, after or false, math.floor((os.clock() - t0) * 1000) })
		end
		return r
	end
	task.spawn(function()
		while true do
			task.wait(1)
			if #buf > 0 then
				local out = {}
				while #buf > 0 and #out < 14 do table.insert(out, table.remove(buf, 1)) end
				report({ moves = out })
			end
		end
	end)
	report({ done = "moves" })
end

local function onMode()
	local m = workspace:GetAttribute("HFB_CheckProbe")
	if m == "fuzz" then task.spawn(fuzz)
	elseif m == "rate" then task.spawn(rate)
	elseif m == "moves" then task.spawn(moves) end
end
workspace:GetAttributeChangedSignal("HFB_CheckProbe"):Connect(onMode)
onMode()
