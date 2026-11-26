if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M0 exit check: a DataStore write and read succeed in Studio ("Enable Studio Access to API Services" is on).
-- Writes one key to a Studio-only store (DataStore names carry the environment; build plan, "Data schema").
--   require(game.ServerStorage.DevSync:Clone()).run("CheckDataStore.lua")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local STORE = "HFB_Studio_M0Check"
local KEY = "probe"
local value = HttpService:GenerateGUID(false)

local ok, err = pcall(function()
	local store = DataStoreService:GetDataStore(STORE)
	store:SetAsync(KEY, { value = value, at = os.time() })
	local got = store:GetAsync(KEY)
	assert(type(got) == "table" and got.value == value, "read back a different value: " .. HttpService:JSONEncode(got))
end)
if ok then
	print(("CheckDataStore: PASS wrote and read %s/%s"):format(STORE, KEY))
else
	print("CheckDataStore: FAIL " .. tostring(err))
end
