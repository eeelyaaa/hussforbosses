# M0 Setup: exit checks

Run 2026-11-25 by tech-lead (agent id `tech-lead-m0`), holding the `studio` lock, through the Studio MCP
(older server: `run_code`, `run_script_in_play_mode`, `get_console_output`). Sync server: `python tools/devsync.py`
on port 34874. Studio was in `stop` mode before and after.

| # | Check (build plan, M0) | Result | How |
|---|---|---|---|
| 1 | Right place, owned by the group: `CreatorType = Group`, `CreatorId = 432262304` | PASS | `studio/CheckPlace.lua` through the sync (also PlaceId 139279056607944, GameId 10779089797) |
| 2 | The place guard refuses without the marker | PASS | Before the marker was set: the loader refused the sync and `run("CheckPlace.lua")`; `CheckDataStore.lua` pasted past the loader stopped on its own first line |
| 3 | Marker set once, after re-checking the owner | PASS | `studio/SetPlaceMarker.lua` (checks CreatorType, CreatorId, PlaceId, GameId before setting) |
| 4 | Sync: `src/` reaches the place | PASS | 17 files, 16 updated, 0 removed; a second sync: 17, 0 changed, 0 removed. `init.lua` folders became ModuleScripts with children (Config, Skins.brickbrawl) |
| 5 | A `studio/` script runs through the sync | PASS | `studio/CheckSync.lua`: 7 of 7 (instances and classes, shared modules require in edit mode) |
| 6 | A synced server script prints from the server in play mode | PASS | `run_script_in_play_mode` (start_play): `[HFB] server up: env=Studio skin=brickbrawl place=139279056607944`; `ReplicatedStorage.Remotes` holds the 13 families; 1 player; 0 errors |
| 7 | DataStore write and read in Studio | PASS | `studio/CheckDataStore.lua`: wrote and read `HFB_Studio_M0Check/probe` (Studio API access is on) |
| 8 | Every `studio/` script carries the guard line | PASS | `python tools/check_guard.py`: 4 scripts, 0 without the guard (SetPlaceMarker exempt by design) |
| 9 | Blender runs headless; earshot present | PASS | `D:/Games/steamapps/common/Blender/blender.exe -b --version`: Blender 5.3.0 (build 2026-11-10); `.venv-audio/Scripts/earshot.exe` exists (not run) |

Also measured: `HttpService.HttpEnabled` is **false** in this place and the sync still works from the Studio MCP
(`HttpService:GetAsync` from the plugin context), as deja-kill found. Nobody needs to turn it on.

## Console (excerpt, as printed)
```
CreatorType=Enum.CreatorType.Group CreatorId=432262304 PlaceId=139279056607944 GameId=10779089797 marker=nil HttpEnabled=false DevSync=nil
loader installed, bytes=5585
sync without marker: ok=false err=DevSync: place guard refused the sync: Workspace has no HussForBosses = true. This is not the Huss for Bosses place.
run CheckPlace without marker: ok=false err=DevSync: place guard refused studio/CheckPlace.lua: Workspace has no HussForBosses = true. This is not the Huss for Bosses place.
PLACE-GUARD: not the Huss for Bosses place; refusing to run
SetPlaceMarker: CreatorType=Enum.CreatorType.Group CreatorId=432262304 PlaceId=139279056607944 GameId=10779089797
SetPlaceMarker: Workspace.HussForBosses = true (save the place so it stays)
DevSync: 17 files, 16 updated, 0 removed
CheckSync: PASS, 0 failed
CheckPlace: PASS, 0 failed
CheckDataStore: PASS wrote and read HFB_Studio_M0Check/probe
resync total=17 changed=0 removed=0; brickbrawl=ModuleScript children=Dressing,Effects,Icons,Lighting,Models,Names,Sounds,Tokens
[HFB] server up: env=Studio skin=brickbrawl place=139279056607944
[M0 play check] IsServer=true Remotes families=13 (Bag,Base,Boss,Carry,Fight,Offline,Profile,Punch,Rebirth,Shield,Shop,Steal,Zones) players=1
```

## Not seen
- The client's `[HFB] client up` line: `run_script_in_play_mode` returns the server's log only and the console was
  empty afterwards. The LocalScript is synced to `StarterPlayerScripts.Main` with the right class; that it runs on
  the client is `UNVERIFIED` until the M1 play test (which reads client state through a reporting remote).
- Nothing on screen was looked at (nothing player-facing exists). No on-screen checks owed for M0.

## Exists only in the place until saved
`Workspace.HussForBosses = true`, `ServerStorage.DevSync` (the loader), and the synced scripts. The scripts come
back with one sync; the marker and the loader need the bootstrap in `team/CLAUDE.md` if the place is not saved.
Listed in `team/manager-todo.md` ("Save the place").
