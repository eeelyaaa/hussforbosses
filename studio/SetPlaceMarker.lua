-- PLACE-GUARD: exempt. The one studio/ script that runs without the marker, because it is what sets it.
-- It sets Workspace.HussForBosses = true only when the open place is the group-owned Huss for Bosses place.
-- Run once at M0 (done 2026-11-25), and again only if the marker is lost:
--   require(game.ServerStorage.DevSync:Clone()).run("SetPlaceMarker.lua")
-- Or paste this file's text into run_code if the loader itself is missing.
local GROUP_ID = 432262304
local PLACE_ID = 139279056607944
local GAME_ID = 10779089797

local ok = game.CreatorType == Enum.CreatorType.Group
	and game.CreatorId == GROUP_ID
	and game.PlaceId == PLACE_ID
	and game.GameId == GAME_ID

print(("SetPlaceMarker: CreatorType=%s CreatorId=%d PlaceId=%d GameId=%d"):format(
	tostring(game.CreatorType), game.CreatorId, game.PlaceId, game.GameId))
if not ok then
	error("SetPlaceMarker: refused; this place is not the group-owned Huss for Bosses place (see team/CLAUDE.md)", 0)
end
workspace:SetAttribute("HussForBosses", true)
print("SetPlaceMarker: Workspace.HussForBosses = true (save the place so it stays)")
