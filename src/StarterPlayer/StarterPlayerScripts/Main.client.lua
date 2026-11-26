-- Client entry point. Starts the controllers (StarterPlayerScripts.Controllers) and the UI views (Ui/).
-- The client shows what the server decided; it never decides a result (build plan, "Client and server boundaries").
-- M1-07: wires Input -> Ring -> BurstClock, the Fight controller, the views (contract I), and the seams other
-- tasks plug into: Controllers/Audio (M1-13), Controllers/Avatar (M1-10), Controllers/BossMoves (M1-09).
-- A module that is not there yet is replaced by a no-op and named once in the output.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Skin = require(Shared.Skin)
local Net = require(Shared.Net)

local here = script.Parent
local Controllers = here:WaitForChild("Controllers")
local UiFolder = here:FindFirstChild("Ui")

local Input = require(Controllers:WaitForChild("Input"))
local BurstClock = require(Controllers:WaitForChild("BurstClock"))
local Ring = require(Controllers:WaitForChild("Ring"))
local Fight = require(Controllers:WaitForChild("Fight"))
local TestClient = require(Controllers:WaitForChild("TestClient"))
local Clock = require(Controllers:WaitForChild("Clock"))
local CarryCtl = require(Controllers:WaitForChild("Carry"))
local HazardsCtl = require(Controllers:WaitForChild("Hazards"))
local BaseCtl = require(Controllers:WaitForChild("Base"))
local PadsCtl = require(Controllers:WaitForChild("Pads"))

local missing = {}

-- A view or controller owned by another task: the module, or a no-op that accepts every call.
local function nullModule(name: string)
	table.insert(missing, name)
	return setmetatable({ _null = true }, {
		__index = function()
			return function() end
		end,
	})
end

local function optional(folder: Instance?, name: string)
	local m = folder and folder:FindFirstChild(name)
	if not (m and m:IsA("ModuleScript")) then
		return nullModule(name)
	end
	local ok, mod = pcall(require, m)
	if not ok then
		warn(("[HFB] client: %s failed to load: %s"):format(name, tostring(mod)))
		return nullModule(name)
	end
	return mod
end

-- The views (contract I) are built by Ui/Hud (M1-08) into one ScreenGui; Hud.start() is called once here.
local Hud = optional(UiFolder, "Hud")
if not rawget(Hud, "_null") then
	local ok, err = pcall(Hud.start)
	if not ok then
		warn("[HFB] client: Hud.start failed: " .. tostring(err))
	end
end
local function view(field: string, name: string)
	local v = rawget(Hud, field)
	if type(v) == "table" then
		return v
	end
	return nullModule(name)
end
local views = {
	HussButton = view("huss", "HussButton"),
	Counters = view("counters", "Counters"),
	FightOverlay = view("fight", "FightOverlay"),
	Prompts = view("prompts", "Prompts"),
}
local Audio = optional(Controllers, "Audio")
local Avatar = optional(Controllers, "Avatar")
local BossMoves = optional(Controllers, "BossMoves")

-- Controllers with their own start call it here (Avatar hooks every character's gloves; Audio, BossMoves if they
-- have one): init or start, whichever they have.
for _, mod in ipairs({ Audio, Avatar, BossMoves }) do
	if not rawget(mod, "_null") then
		local f = rawget(mod, "init") or rawget(mod, "start")
		if type(f) == "function" then
			local ok, err = pcall(f)
			if not ok then
				warn("[HFB] client: init failed: " .. tostring(err))
			end
		end
	end
end

-- Seams.
if not rawget(Audio, "_null") and type(Audio.playBurst) == "function" then
	BurstClock.setAudio(Audio)
end
if not rawget(Avatar, "_null") then
	BurstClock.setAvatar(Avatar)
end

Input.start()
BurstClock.init()
Ring.init(views.HussButton)
Fight.init(views, { BossMoves = BossMoves })
TestClient.init()

-- M1-14: the carried, dropped and placed boss, the Rolling Log from the server clock, the base. Each is a client
-- visual of server state; Clock first (the log, the drop timer and the pad cash read it). pcall: a visual failing must
-- not take the punch with it.
local carryDeps = { views = views, Avatar = Avatar, BossMoves = BossMoves, Carry = CarryCtl }
for _, step in ipairs({
	{ "Clock", function() Clock.init() end },
	{ "Carry", function() CarryCtl.init(carryDeps) end },
	{ "Hazards", function() HazardsCtl.init() end },
	{ "Base", function() BaseCtl.init(carryDeps) end },
	{ "Pads", function() PadsCtl.init() end }, -- M1-24: the boss Power number over each pad
}) do
	local ok, err = pcall(step[2])
	if not ok then
		warn(("[HFB] client: %s controller failed: %s"):format(step[1], tostring(err)))
	end
end
TestClient.setProbes(CarryCtl, BaseCtl, HazardsCtl, PadsCtl)

-- The Huss action: next to a thief carrying your boss it punches the thief (M2-16, Controllers/Steal); in a boss ring with
-- no fight it starts the fight; otherwise it is a ring tap.
local StealCtl = optional(Controllers, "Steal")
Input.onPunch(function(source: string, t: number)
	if not Fight.active() and StealCtl.tryPunch(source, t) then
		return
	end
	if not Fight.active() and Fight.inStartRing() then
		Fight.requestStart()
	else
		Ring.tap(t, source)
	end
end)
Input.onPressed(function(down: boolean)
	views.HussButton.pressed(down)
end)
views.HussButton.onTap(function()
	Input.fire("punch", "button")
end)

-- The Huss button's job follows where the player stands (docs/controls.md).
local mode = nil
RunService.Heartbeat:Connect(function()
	local m = if Fight.active() then "fight" elseif StealCtl.thiefInRange() then "start" elseif Fight.inStartRing() then "start" elseif Ring.onBagPad() then "bag" else "hidden"
	if m ~= mode then
		mode = m
		views.HussButton.setMode(m)
	end
end)

-- Pips and the Power pop hang off the beats. The pop on the bag is display only: the counter itself is set
-- from Profile.Changed, the server's number.
local strengthLevel = Config.Bag.DEFAULT_STRENGTH
BurstClock.onBeat(function(ev)
	if ev.noContact then
		return
	end
	views.HussButton.pips(ev.n)
	if ev.n == 3 then
		task.delay(0.15, function()
			views.HussButton.clearPips()
		end)
	end
	if ev.context == "bag" then
		local P = Config.Punch
		local amount = Config.Bag.STRENGTH_VALUE(strengthLevel) * (P.GRADE_VALUE[ev.grade] or 0) * (if ev.big then P.BIG_MULT else 1)
		views.Counters.popPower(amount, ev.big)
	end
end)

-- M2-07 (P3): an untimed tap is ONE punch. Ring calls this in the tap's frame: the single huss (02 A / 01 A
-- alternating), one jab (the first punch of the jab clip, cut before the second), and on the bag the Power pop
-- (display only: the server's number arrives in Profile.Changed). In a fight the boss's hit reaction is Fight.lua's.
local singleGen = 0
Ring.setSinglePunch(function(context: string, t: number)
	if not rawget(Audio, "_null") and type(Audio.singleHuss) == "function" then
		pcall(Audio.singleHuss)
	end
	if not rawget(Avatar, "_null") and type(Avatar.startJab) == "function" then
		singleGen += 1
		local gen = singleGen
		local ok = pcall(Avatar.startJab, "good", t)
		if ok then
			-- the clip's second punch begins at BEAT[2]; stop just before it (a new burst can not start for 0.6 s)
			task.delay(Config.Punch.BEAT[2] - 0.015, function()
				if gen == singleGen and not BurstClock.running() then
					pcall(Avatar.cancel)
				end
			end)
		end
	end
	if context == "bag" then
		local P = Config.Punch
		views.Counters.popPower(Config.Bag.STRENGTH_VALUE(strengthLevel) * (P.GRADE_VALUE.untimed or 1), false)
	end
end)

Net.get("Profile", "Changed").OnClientEvent:Connect(function(p)
	if typeof(p) ~= "table" then
		return
	end
	if typeof(p.power) == "number" then
		views.Counters.setPower(p.power)
	end
	if typeof(p.cash) == "number" then
		views.Counters.setCash(p.cash)
	end
	if typeof(p.strengthLevel) == "number" then
		strengthLevel = p.strengthLevel
	end
end)

-- M2-01 seam (m2-contract.md section A): a module ADDED at M2 or later in Controllers/ or Ui/ that sets
-- AUTO_START = true gets start(ctx) once, in name order, after everything above, so a new screen or controller needs
-- no edit here. The M1 modules below are never auto-started (they are wired above by hand).
local M1_MODULES = {
	Audio = true, Avatar = true, Base = true, BossMoves = true, BossVisuals = true, BurstClock = true, Carry = true,
	Clock = true, Fight = true, Hazards = true, Input = true, Pads = true, Ring = true, TestClient = true,
	Counters = true, FightOverlay = true, Hud = true, HussButton = true, Kit = true, Prompts = true, WorldLabel = true,
}
local ctx = { views = views, Hud = Hud, Input = Input, Ring = Ring, Fight = Fight, BurstClock = BurstClock,
	Avatar = Avatar, BossMoves = BossMoves, Audio = Audio, Carry = CarryCtl, Base = BaseCtl, Pads = PadsCtl, Clock = Clock }
local autoList = {}
for _, folder in ipairs({ Controllers, UiFolder }) do
	if folder then
		for _, m in ipairs(folder:GetChildren()) do
			if m:IsA("ModuleScript") and not M1_MODULES[m.Name] then
				table.insert(autoList, m)
			end
		end
	end
end
table.sort(autoList, function(a, b)
	return a.Name < b.Name
end)
for _, m in ipairs(autoList) do
	local ok, err = pcall(function()
		local mod = require(m) :: any
		if type(mod) == "table" and mod.AUTO_START == true and type(mod.start) == "function" then
			mod.start(ctx)
		end
	end)
	if not ok then
		warn(("[HFB] client: %s failed to start: %s"):format(m.Name, tostring(err)))
	end
end

if #missing > 0 then
	print("[HFB] client: not there yet, running as no-ops: " .. table.concat(missing, ", "))
end
print(("[HFB] client up: skin=%s"):format(Skin.Id or Config.SkinId))
