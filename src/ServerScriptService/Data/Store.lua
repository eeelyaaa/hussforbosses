--!strict
-- Data/Store: where records live. One backend per profile, picked at load:
--   * a player (UserId > 0): DataStore "HFB_<Config.Env>_<Config.Data.STORE_BASE>", key "player_<UserId>";
--   * a stand-in second player (UserId <= 0, Studio only; M2-02 S9): an in-memory table that never touches a
--     DataStore, with the same UpdateAsync semantics (a transform returning nil cancels the write).
-- Every write is one UpdateAsync (B3). A call that errors is tried again (Config.Data.WRITE_TRIES, backoff); a
-- cancelled transform is not an error and is not retried. Studio-only fault injection: Store.failNext(key, n).
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local Store = {}

export type Backend = {
	name: string,
	kind: "datastore" | "memory",
	update: (self: Backend, key: string, transform: (any) -> (any, any)) -> (boolean, any),
	read: (self: Backend, key: string) -> (boolean, any),
	remove: (self: Backend, key: string) -> boolean,
}

local failures: { [string]: number } = {}
local memoryData: { [string]: { [string]: any } } = {}

local function copy(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local t = {}
	for k, x in pairs(v) do
		t[k] = copy(x)
	end
	return t
end

-- Studio only: the next n calls on `key` (any backend) fail as if the DataStore errored.
function Store.failNext(key: string, n: number)
	assert(RunService:IsStudio(), "Store.failNext is Studio only")
	failures[key] = n
end

local function injected(key: string): boolean
	local n = failures[key]
	if n and n > 0 then
		failures[key] = n - 1
		return true
	end
	return false
end

function Store.storeName(): string
	return ("HFB_%s_%s"):format(Config.Env, Config.Data.STORE_BASE)
end

function Store.key(userId: number): string
	return Config.Data.KEY_PREFIX .. tostring(userId)
end

local function waitBudget(kind: Enum.DataStoreRequestType)
	local t0 = os.clock()
	while os.clock() - t0 < Config.Data.BUDGET_WAIT_S do
		local ok, n = pcall(DataStoreService.GetRequestBudgetForRequestType, DataStoreService, kind)
		if not ok or n >= 1 then
			return
		end
		task.wait(0.25)
	end
end

-- Calls fn up to WRITE_TRIES times while it errors. Returns (true, results...) or (false, lastError).
local function withRetries(key: string, fn: () -> any): (boolean, any)
	local tries = Config.Data.WRITE_TRIES
	local lastErr: any = nil
	for i = 1, tries do
		if injected(key) then
			lastErr = "injected failure"
		else
			local ok, res = pcall(fn)
			if ok then
				return true, res
			end
			lastErr = res
		end
		if i < tries then
			task.wait(Config.Data.WRITE_BACKOFF_S[i] or 2)
		end
	end
	return false, tostring(lastErr)
end

local DS = {}
DS.__index = DS

function DS.update(self: any, key: string, transform: (any) -> (any, any)): (boolean, any)
	return withRetries(key, function()
		waitBudget(Enum.DataStoreRequestType.UpdateAsync)
		return (self.ds :: DataStore):UpdateAsync(key, transform)
	end)
end

function DS.read(self: any, key: string): (boolean, any)
	return withRetries(key, function()
		local opts = Instance.new("DataStoreGetOptions")
		opts.UseCache = false
		return (self.ds :: DataStore):GetAsync(key, opts)
	end)
end

function DS.remove(self: any, key: string): boolean
	local ok = withRetries(key, function()
		return (self.ds :: DataStore):RemoveAsync(key)
	end)
	return ok
end

local MEM = {}
MEM.__index = MEM

function MEM.update(self: any, key: string, transform: (any) -> (any, any)): (boolean, any)
	return withRetries(key, function()
		local data = memoryData[self.name]
		local new = transform(copy(data[key]))
		if new == nil then
			return nil
		end
		data[key] = copy(new)
		return copy(new)
	end)
end

function MEM.read(self: any, key: string): (boolean, any)
	return true, copy(memoryData[self.name][key])
end

function MEM.remove(self: any, key: string): boolean
	memoryData[self.name][key] = nil
	return true
end

-- The backend for a user id, at the current Config.Data.STORE_BASE (fixed per profile by the caller at load).
function Store.forUser(userId: number): Backend
	local name = Store.storeName()
	if userId <= 0 then
		assert(RunService:IsStudio(), "Store: a stand-in user id outside Studio")
		memoryData[name] = memoryData[name] or {}
		return setmetatable({ name = name, kind = "memory" }, MEM) :: any
	end
	return setmetatable({ name = name, kind = "datastore", ds = DataStoreService:GetDataStore(name) }, DS) :: any
end

return Store
