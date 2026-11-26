--!strict
-- Systems/Passes: who owns which of the 10 game passes (brief system 13; m2-contract.md C "Purchases", [M2-02 M4]).
-- The one owner of pass ownership: Systems/Bag.owns (and through it Base, Carry, Income, Shield, Steal) reads
-- Passes.owns once this module exists. Built by M2-18.
--
--   Passes.owns(player, key) -> boolean      never yields (remote handlers read this, contract C S5)
--   Passes.ownedKeys(player) -> { [key]: true }
--   Passes.onChanged(fn(player, key, owned))  a pass's answer changed (join, a confirmed purchase, the hook)
--   Passes.hint(player, key)                 a purchase hint (PromptGamePassPurchaseFinished(true), or the FakeReceipt
--                                            hook): confirmed with UserOwnsGamePassAsync, retried (Config.Shop.VERIFY_*)
--   Passes.source(player, key) -> "hook" | "roblox" | "none"   where the current answer comes from
-- On join every pass with an id is asked of Roblox in parallel (pcall). A failure is "unknown" (read as not owned)
-- and asked again in the background with a growing gap, and on demand (Passes.retryFailed, from Shop.Open) (M2-27 SF3). A pass bought on the web page while away is seen on the next join. Studio: the PassOwned hook
-- ('<key>=on|off,...') replaces Roblox's answer for the keys it names (the test account owns every real pass).
-- After a change: Base.refresh (spots), Carry.refreshSpeed (Fast Carry), Bag.sendState (the bag panel), and the
-- listeners (Shop.State, the Starter Pack grant).
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Ids = require(Shared.Ids)
local TestHooks = require(Shared.TestHooks)
local Session = require(script.Parent.Parent.Data.Session)

local Passes = {}

local cache: { [any]: { [string]: boolean } } = {}
local listeners: { (any, string, boolean) -> () } = {}
local lastHook: string? = nil

Passes.stats = { asks = 0, failures = 0, hints = {} :: { any }, roblox = {} :: { [number]: { [string]: boolean } } }

function Passes.id(key: string): number
	local ids = (Config :: any).Shop and (Config :: any).Shop.IDS
	local id = ids and ids[key]
	return if typeof(id) == "number" then id else 0
end

function Passes.keyFor(passId: number): string?
	for _, k in ipairs(Ids.PASSES) do
		if Passes.id(k) == passId and passId ~= 0 then
			return k
		end
	end
	return nil
end

local function parseHook(v: any): { [string]: boolean }
	local out = {}
	if typeof(v) ~= "string" then
		return out
	end
	for k, state in string.gmatch(v, "([%w_]+)%s*=%s*(%a+)") do
		out[k] = state == "on"
	end
	return out
end

local function hookOwned(key: string): boolean?
	return parseHook(TestHooks.get("PassOwned"))[key]
end

function Passes.source(player: any, key: string): string
	if hookOwned(key) ~= nil then
		return "hook"
	end
	local c = cache[player]
	if c and c[key] ~= nil then
		return "roblox"
	end
	return "none"
end

function Passes.owns(player: any, key: string): boolean
	local h = hookOwned(key)
	if h ~= nil then
		return h
	end
	local c = cache[player]
	return c ~= nil and c[key] == true
end

function Passes.ownedKeys(player: any): { [string]: boolean }
	local out = {}
	for _, k in ipairs(Ids.PASSES) do
		if Passes.owns(player, k) then
			out[k] = true
		end
	end
	return out
end

function Passes.onChanged(fn: (any, string, boolean) -> ())
	table.insert(listeners, fn)
end

local function lazy(name: string): any
	local m = script.Parent:FindFirstChild(name)
	if not m then
		return nil
	end
	local ok, mod = pcall(require, m)
	return if ok and type(mod) == "table" then mod else nil
end

-- Everything that reads a pass is told once (spots, carry speed, the bag panel, then the listeners).
local function changed(player: any, key: string, owned: boolean)
	if typeof(player) == "Instance" and player.Parent == Players then
		local Base, Carry, Bag = lazy("Base"), lazy("Carry"), lazy("Bag")
		if Base and Base.refresh then
			pcall(Base.refresh, player)
		end
		if Carry and Carry.refreshSpeed then
			pcall(Carry.refreshSpeed, player)
		end
		if Bag and Bag.sendState then
			pcall(Bag.sendState, player)
		end
	end
	for _, fn in ipairs(table.clone(listeners)) do
		task.spawn(fn, player, key, owned)
	end
end

-- Asks Roblox for one pass. Yields. nil on a failed call.
-- Roblox's call, replaceable by checks (Passes.setAskFn) to make it fail: (player, passId) -> (ok, owned).
local function robloxAsk(player: any, id: number): (boolean, any)
	return pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
end
local askFn: (any, number) -> (boolean, any) = robloxAsk
function Passes.setAskFn(fn: ((any, number) -> (boolean, any))?)
	askFn = fn or robloxAsk
end

local function ask(player: any, key: string): boolean?
	local id = Passes.id(key)
	if id <= 0 or typeof(player) ~= "Instance" or player.UserId <= 0 then
		return false
	end
	Passes.stats.asks += 1
	local ok, owned = askFn(player, id)
	if not ok then
		Passes.stats.failures += 1
		return nil
	end
	local log = Passes.stats.roblox[player.UserId] or {}
	Passes.stats.roblox[player.UserId] = log
	log[key] = owned == true
	return owned == true
end

-- Sets the cached answer and tells the readers if what owns() returns changed.
local function store(player: any, key: string, value: boolean)
	local c = cache[player]
	if not c then
		c = {}
		cache[player] = c
	end
	local before = Passes.owns(player, key)
	c[key] = value
	local after = Passes.owns(player, key)
	if before ~= after then
		changed(player, key, after)
	end
end

-- Keys whose last ask failed (unknown, read as not owned until an answer comes: M2-27 SF3).
local failed: { [any]: { [string]: boolean } } = {}
local retrying: { [any]: boolean } = {}

function Passes.unknown(player: any, key: string): boolean
	local f = failed[player]
	return f ~= nil and f[key] == true
end

local function askAndStore(player: any, key: string)
	local v = ask(player, key)
	if cache[player] == nil or player.Parent ~= Players then
		return
	end
	if v == nil then
		failed[player] = failed[player] or {}
		failed[player][key] = true
		return
	end
	if failed[player] then
		failed[player][key] = nil
	end
	store(player, key, v)
end

-- Asks the failed keys again in the background: Config.Shop.PASS_RETRY_TRIES times, PASS_RETRY_GAP_S apart (the
-- gap doubles each try). Also called on demand (Shop.Open). Never yields the caller.
function Passes.retryFailed(player: any)
	if retrying[player] then
		return
	end
	local f = failed[player]
	if not f or next(f) == nil then
		return
	end
	retrying[player] = true
	task.spawn(function()
		local gap = Config.Shop.PASS_RETRY_GAP_S
		for i = 1, Config.Shop.PASS_RETRY_TRIES do
			local keys = {}
			for k in pairs(failed[player] or {}) do
				table.insert(keys, k)
			end
			if #keys == 0 or cache[player] == nil then
				break
			end
			for _, k in ipairs(keys) do
				askAndStore(player, k)
			end
			if i < Config.Shop.PASS_RETRY_TRIES and next(failed[player] or {}) ~= nil then
				task.wait(gap)
				gap *= 2
			end
		end
		retrying[player] = nil
	end)
end

local function fetchAll(player: any)
	local left = #Ids.PASSES
	for _, k in ipairs(Ids.PASSES) do
		task.spawn(function()
			askAndStore(player, k)
			left -= 1
			if left == 0 then
				Passes.retryFailed(player)
			end
		end)
	end
end

-- Asks every pass again as on a join, from an empty cache (the checks' stand-in for a join).
function Passes.refetch(player: any)
	cache[player] = {}
	failed[player] = nil
	fetchAll(player)
end

-- A purchase hint: owned only once Roblox (or the hook, in Studio) says so. Yields in a spawned thread.
function Passes.hint(player: any, key: string)
	if not Ids.isPass(key) then
		return
	end
	table.insert(Passes.stats.hints, { userId = player.UserId, key = key, at = os.clock() })
	if #Passes.stats.hints > 50 then
		table.remove(Passes.stats.hints, 1)
	end
	task.spawn(function()
		for i = 1, Config.Shop.VERIFY_TRIES do
			if cache[player] == nil then
				return
			end
			if hookOwned(key) ~= nil then
				-- Studio: the hook is the answer; still tell the readers (a hint after the hook was set)
				changed(player, key, Passes.owns(player, key))
				return
			end
			local v = ask(player, key)
			if v == true then
				if failed[player] then
					failed[player][key] = nil
				end
				store(player, key, true)
				return
			end
			if i < Config.Shop.VERIFY_TRIES then
				task.wait(Config.Shop.VERIFY_GAP_S)
			end
		end
		warn(("[HFB] Passes: %s purchase hint for %d not confirmed by Roblox after %d tries"):format(key, player.UserId, Config.Shop.VERIFY_TRIES))
	end)
end

function Passes.start()
	local function joined(player: any)
		if cache[player] == nil then
			cache[player] = {}
		end
		fetchAll(player)
	end
	-- Ownership is a Roblox fact, not a save: asked when the player arrives (in parallel with the profile load).
	Players.PlayerAdded:Connect(joined)
	for _, p in ipairs(Players:GetPlayers()) do
		joined(p)
	end
	-- And once more when the profile is live, so listeners that need the profile (the Starter Pack) see the answers.
	Session.onJoin(function(player)
		for _, k in ipairs(Ids.PASSES) do
			if Passes.owns(player, k) then
				changed(player, k, true)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		cache[p] = nil
		failed[p] = nil
		retrying[p] = nil
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local key = Passes.keyFor(passId)
		if key then
			Passes.hint(player, key)
		end
	end)
	-- Studio: a PassOwned change is a change for every player whose answer it flips.
	lastHook = TestHooks.get("PassOwned")
	workspace:GetAttributeChangedSignal(TestHooks.PREFIX .. "PassOwned"):Connect(function()
		local old = parseHook(lastHook)
		lastHook = TestHooks.get("PassOwned")
		local new = parseHook(lastHook)
		for _, p in ipairs(Players:GetPlayers()) do
			for _, k in ipairs(Ids.PASSES) do
				local c = cache[p]
				local cached = c ~= nil and c[k] == true
				local before = if old[k] ~= nil then old[k] else cached
				local after = Passes.owns(p, k)
				if before ~= after then
					changed(p, k, after)
				end
			end
		end
	end)
end

return Passes
