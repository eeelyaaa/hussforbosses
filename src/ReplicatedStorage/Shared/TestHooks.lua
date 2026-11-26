--!strict
-- TestHooks: values tests set as Workspace attributes, read only in Studio
-- (vault/patterns/test-hooks-gated-to-studio-and-listed.md). Every hook is named in HOOKS below AND in
-- team/test-hooks.md; a name not on the list errors. A live server warns once if any is set in the place.
--
-- Attribute name on Workspace: "HFB_" .. hook name, e.g. Workspace.HFB_SaveOff = true.
-- Tests set hooks from the play-mode script and clear them afterwards.
--
-- v1 (M1-01, team/requirements/m1-contract.md section L). Three kinds:
--   state  : the SERVER applies the value once and clears the attribute (TestHooks.consume / onSet).
--   client : read by the client, never consumed; the test clears it.
--   config : read by whoever needs it while set; the test clears it.
-- This module is a leaf: it requires nothing of ours (Net and Skin require it).
local RunService = game:GetService("RunService")

local PREFIX = "HFB_"

export type Hook = { kind: "state" | "client" | "config", type: string, doc: string }

-- The list. Add a hook here and in team/test-hooks.md in the same change.
local HOOKS: { [string]: Hook } = {
	-- M0
	ForceSkin = { kind = "config", type = "string", doc = "a skin id under ReplicatedStorage.Skins; read once when Shared/Skin is first required (the skin check uses 'stub'). Set it BEFORE play starts" },
	SaveOff = { kind = "config", type = "boolean", doc = "no DataStore reads or writes; profiles start fresh and are not saved" },

	-- M1 state hooks (server applies, then clears the attribute)
	SetPower = { kind = "state", type = "number", doc = "the test player's Power becomes this" },
	SetCash = { kind = "state", type = "number", doc = "the test player's cash becomes this" },
	SetStrength = { kind = "state", type = "number", doc = "Punch Strength level (1..30)" },
	SetSpeed = { kind = "state", type = "number", doc = "Punch Speed level (1..10); the server re-sends Punch.Schedule" },
	Wipe = { kind = "state", type = "boolean", doc = "true: the test player's session becomes a fresh profile" },
	GrantBoss = { kind = "state", type = "string", doc = "a creature id: that boss is put on the player's head as if beaten (Carry.State carrying)" },

	-- M1 config hooks (read while set; the test clears them)
	PadFastBack = { kind = "config", type = "number", doc = "seconds; replaces Config.Fight.FIXED_BACK_S" },
	LogForce = { kind = "config", type = "string", doc = "'hit' = the log is on the carrier's path now; 'clear' = it never reaches the carrier" },
	ClockOffset = { kind = "config", type = "number", doc = "seconds added to the server's hazard and pad clock (income, pad timers)" },

	-- M1 client hooks (read by the client, never consumed)
	AutoTap = { kind = "client", type = "string", doc = "'perfect' | 'good' | 'miss' | 'mix' | 'busy' | 'early' | 'lag': the real client path taps at landing + 0 (Perfect), + 70 ms (Good), not at all (Miss); busy = Good tap then a tap 100 ms into the burst (ignored); early = a tap 0.5 s before landing (ignored) then Good; lag = Good tap then one frame held 0.45 s (beats 2 and 3 fire together); with AutoTap set, standing in a boss ring with no fight presses Huss once a second (starts the fight)" },
	AutoMix = { kind = "client", type = "string", doc = "'perfect,good,miss' percentages for AutoTap = 'mix', e.g. '45,45,10'" },
	ForceInput = { kind = "client", type = "string", doc = "'touch' | 'gamepad' | 'keyboard': Input.kind() returns this" },
	FrameCap = { kind = "client", type = "number", doc = "60, 30 or 15: a busy-wait in Heartbeat holds each frame to at least 1/cap s (RenderStepped runs too rarely in a Studio play client)" },
	AutoInteract = { kind = "client", type = "boolean", doc = "true: the client presses interact (E) through Input.fire every 0.6 s (Grab and Place prompts, M1-14)" },
	ReportBeats = { kind = "client", type = "boolean", doc = "true: after each burst the client sends Profile.TestReport 'beats' with BurstClock.log" },
}

local TestHooks = {}
TestHooks.HOOKS = HOOKS
TestHooks.PREFIX = PREFIX

-- Server-side store of what tests and the client reported (Profile.TestReport) and of dropped calls
-- (Net's rate limiter counts into _dropped["Family.Name"]). Studio only in practice.
TestHooks.reports = { _dropped = {} :: { [string]: number } } :: { [string]: any }

local function check(name: string): Hook
	local h = HOOKS[name]
	assert(h, "TestHooks: unknown hook " .. tostring(name) .. " (add it to HOOKS and team/test-hooks.md)")
	return h
end

-- The hook's value, or nil (always nil outside Studio).
function TestHooks.get(name: string): any
	check(name)
	if not RunService:IsStudio() then
		return nil
	end
	return workspace:GetAttribute(PREFIX .. name)
end

-- Server, state hooks: the value once, and the attribute cleared. nil when unset or outside Studio.
function TestHooks.consume(name: string): any
	local h = check(name)
	assert(h.kind == "state", "TestHooks.consume: " .. name .. " is not a state hook")
	assert(RunService:IsServer(), "TestHooks.consume is server only")
	if not RunService:IsStudio() then
		return nil
	end
	local v = workspace:GetAttribute(PREFIX .. name)
	if v ~= nil then
		workspace:SetAttribute(PREFIX .. name, nil)
	end
	return v
end

-- Calls fn(value) whenever the hook is set (and once now if it is already set). For state hooks the
-- attribute is consumed (cleared) before fn runs. Studio only: returns nil outside Studio.
function TestHooks.onSet(name: string, fn: (any) -> ()): RBXScriptConnection?
	local h = check(name)
	if not RunService:IsStudio() then
		return nil
	end
	local busy = false
	local function fire()
		if busy then
			return
		end
		local v = workspace:GetAttribute(PREFIX .. name)
		if v == nil then
			return
		end
		busy = true
		if h.kind == "state" then
			workspace:SetAttribute(PREFIX .. name, nil)
		end
		busy = false
		fn(v)
	end
	local conn = workspace:GetAttributeChangedSignal(PREFIX .. name):Connect(fire)
	task.defer(fire)
	return conn
end

-- Server, called once by Main.server.lua after Net.serverInit(): listens to Profile.TestReport
-- (Studio only; max 1 KB; stored in TestHooks.reports[name] and warned). Net is passed in so this module
-- stays a leaf (no require cycle).
function TestHooks.listenReports(Net: any)
	if not RunService:IsStudio() then
		return
	end
	Net.onServerEvent("Profile", "TestReport", function(player: Player, p: any)
		if typeof(p.name) ~= "string" or typeof(p.json) ~= "string" then
			return
		end
		if #p.name > 40 or #p.json > 1024 or p.name == "_dropped" then
			return
		end
		TestHooks.reports[p.name] = { userId = player.UserId, json = p.json, at = workspace:GetServerTimeNow() }
		warn(("[HFB] TestReport %s from %d: %s"):format(p.name, player.UserId, p.json))
	end)
end

-- Called once by Main.server.lua. On a live server, warns about hooks saved into the place by mistake.
function TestHooks.warnIfSetLive()
	if RunService:IsStudio() then
		return
	end
	local set = {}
	for name in pairs(HOOKS) do
		if workspace:GetAttribute(PREFIX .. name) ~= nil then
			table.insert(set, name)
		end
	end
	if #set > 0 then
		warn("TestHooks: set in the place (ignored on a live server): " .. table.concat(set, ", "))
	end
end

-- For tests: clears every listed hook (run at the end of a check).
function TestHooks.clearAll()
	for name in pairs(HOOKS) do
		workspace:SetAttribute(PREFIX .. name, nil)
	end
end

return TestHooks
