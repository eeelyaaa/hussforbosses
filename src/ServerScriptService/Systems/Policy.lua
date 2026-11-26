--!strict
-- Systems/Policy: each player's PolicyService answer, cached for the session (m2-contract.md H; build plan
-- "PolicyService checks"; M2-02 S10). Read by Systems/Steal (the bought-boss guard, TEAM CALL 38) and M2-18 (spins).
--
-- Policy.get(player) -> { randomItemsRestricted: boolean, tradingAllowed: boolean }   never yields.
--   One GetPolicyInfoForPlayerAsync per player on join, in a pcall, with Config.Policy.TIMEOUT_S. Until it answers,
--   and when it fails or times out: { randomItemsRestricted = true, tradingAllowed = false }. A missing field counts
--   as restrictive: tradingAllowed = IsPaidItemTradingAllowed == true; randomItemsRestricted =
--   ArePaidRandomItemsRestricted ~= false (S10). Stand-ins (user id <= 0) never call Roblox: the default, or the hooks.
-- Policy.isAnswered(player) -> boolean   (the answer or the timeout has come)
-- Policy.onReady(player, fn(player))     fn once, when that player's first answer (or the timeout) arrives; at once
--                                        if it already has.
-- Policy.onChange(fn(player))            every time a player's answer changes (first answer, a late answer, a hook).
-- Hooks (Studio): PolicyTrading / PolicyRandom 'on' | 'off' | 'fail', or '<userId>:<v>' per player, comma-separated;
-- a per-player entry wins over a global one. Read at every get (config hooks).
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local TestHooks = require(Shared.TestHooks)

local Policy = {}

export type Answer = { randomItemsRestricted: boolean, tradingAllowed: boolean }

type Entry = { restricted: boolean, trading: boolean, answered: boolean, failed: boolean, source: string }
local cache: { [any]: Entry } = {}
local readyFns: { [any]: { (any) -> () } } = {}
local changeFns: { (any) -> () } = {}

Policy.stats = { calls = 0, failures = 0, timeouts = 0, log = {} :: { any } }

local function default(): Entry
	return { restricted = Config.Policy.DEFAULT_RESTRICTED, trading = Config.Policy.DEFAULT_TRADING, answered = false, failed = false, source = "default" }
end

-- The hook's value for this user id ('on' | 'off' | 'fail'), or nil.
local function hookFor(name: string, userId: number): string?
	local v = TestHooks.get(name)
	if typeof(v) ~= "string" then
		return nil
	end
	local global: string? = nil
	for _, tok in ipairs(string.split(v, ",")) do
		local id, val = tok:match("^%s*(%-?%d+)%s*:%s*(%a+)%s*$")
		if id and tonumber(id) == userId then
			return val:lower()
		end
		local g = tok:match("^%s*(%a+)%s*$")
		if g then
			global = g:lower()
		end
	end
	return global
end

function Policy.get(player: any): Answer
	local e = cache[player] or default()
	local out = { randomItemsRestricted = e.restricted, tradingAllowed = e.trading }
	local uid = player and player.UserId
	if typeof(uid) == "number" then
		local t = hookFor("PolicyTrading", uid)
		if t then
			out.tradingAllowed = t == "on"
		end
		local r = hookFor("PolicyRandom", uid)
		if r then
			out.randomItemsRestricted = r ~= "off"
		end
	end
	return out
end

function Policy.isAnswered(player: any): boolean
	local e = cache[player]
	return e ~= nil and e.answered
end

local function changed(player: any)
	for _, fn in ipairs(table.clone(changeFns)) do
		task.spawn(fn, player)
	end
end

local function ready(player: any)
	local fns = readyFns[player]
	readyFns[player] = nil
	for _, fn in ipairs(fns or {}) do
		task.spawn(fn, player)
	end
end

function Policy.onReady(player: any, fn: (any) -> ())
	if Policy.isAnswered(player) then
		task.spawn(fn, player)
		return
	end
	readyFns[player] = readyFns[player] or {}
	table.insert(readyFns[player], fn)
end

function Policy.onChange(fn: (any) -> ())
	table.insert(changeFns, fn)
end

local function settle(player: any, e: Entry)
	local old = cache[player]
	cache[player] = e
	table.insert(Policy.stats.log, { userId = player.UserId, source = e.source, trading = e.trading, restricted = e.restricted })
	if #Policy.stats.log > 100 then
		table.remove(Policy.stats.log, 1)
	end
	if not old or old.trading ~= e.trading or old.restricted ~= e.restricted or old.answered ~= e.answered then
		changed(player)
	end
	ready(player)
end

-- The answer from a PolicyService table (S10: a missing field counts as restrictive). Pure.
function Policy.fromInfo(info: any): Answer
	local t = type(info) == "table"
	return {
		tradingAllowed = t and info.IsPaidItemTradingAllowed == true,
		randomItemsRestricted = not t or info.ArePaidRandomItemsRestricted ~= false,
	}
end

-- Reads the answer once (join). Never called from a remote handler (contract C: no yield in handlers).
function Policy.fetch(player: any)
	if cache[player] and cache[player].answered then
		return
	end
	cache[player] = cache[player] or default()
	if typeof(player) ~= "Instance" or player.UserId <= 0 then
		-- a stand-in: no Roblox call; the restrictive default counts as its answer (hooks override)
		local e = default()
		e.answered, e.source = true, "standIn"
		settle(player, e)
		return
	end
	local done = false
	task.spawn(function()
		Policy.stats.calls += 1
		local ok, info = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
		if player.Parent ~= Players then
			return
		end
		local e = default()
		e.answered = true
		if ok and type(info) == "table" then
			local a = Policy.fromInfo(info)
			e.trading, e.restricted = a.tradingAllowed, a.randomItemsRestricted
			e.source = "roblox"
		else
			Policy.stats.failures += 1
			e.failed, e.source = true, "failed"
			warn("[HFB] Policy: GetPolicyInfoForPlayerAsync failed for " .. tostring(player.UserId) .. ": " .. tostring(info))
		end
		done = true
		settle(player, e)
	end)
	task.delay(Config.Policy.TIMEOUT_S, function()
		if not done and player.Parent == Players and not Policy.isAnswered(player) then
			Policy.stats.timeouts += 1
			local e = default()
			e.answered, e.failed, e.source = true, true, "timeout"
			settle(player, e) -- a later real answer still replaces it (settle again)
		end
	end)
end

function Policy.forget(player: any)
	cache[player] = nil
	readyFns[player] = nil
end

function Policy.start()
	Players.PlayerAdded:Connect(Policy.fetch)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(Policy.fetch, p)
	end
	Players.PlayerRemoving:Connect(Policy.forget)
	-- a hook change is a change of answer for every player (Studio only; nil connection live)
	for _, name in ipairs({ "PolicyTrading", "PolicyRandom" }) do
		workspace:GetAttributeChangedSignal(TestHooks.PREFIX .. name):Connect(function()
			if TestHooks.get(name) == nil and workspace:GetAttribute(TestHooks.PREFIX .. name) ~= nil then
				return -- live server: hooks are ignored
			end
			for p in pairs(cache) do
				changed(p)
			end
		end)
	end
end

return Policy
