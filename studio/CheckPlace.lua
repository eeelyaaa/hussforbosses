if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end
-- M0 exit check: the open place is owned by the Huss for Bosses group and is the right place.
--   require(game.ServerStorage.DevSync:Clone()).run("CheckPlace.lua")
local GROUP_ID = 432262304
local PLACE_ID = 139279056607944
local GAME_ID = 10779089797

local results = {
	{ "CreatorType is Group", game.CreatorType == Enum.CreatorType.Group, tostring(game.CreatorType) },
	{ "CreatorId is the group", game.CreatorId == GROUP_ID, tostring(game.CreatorId) },
	{ "PlaceId", game.PlaceId == PLACE_ID, tostring(game.PlaceId) },
	{ "GameId", game.GameId == GAME_ID, tostring(game.GameId) },
}
local failed = 0
for _, r in ipairs(results) do
	print(("CheckPlace: %s %s (%s)"):format(r[2] and "PASS" or "FAIL", r[1], r[3]))
	if not r[2] then
		failed += 1
	end
end
print(("CheckPlace: %s, %d failed"):format(failed == 0 and "PASS" or "FAIL", failed))
