# M1-01: the contract in code (tech-lead, 2026-11-25)

Task: `board.md` row M1-01; spec `requirements/m1-contract.md` sections B to F and L; skin check from
`requirements/m1-core-loop-gate.md`. Quality pass: Function (no player-facing feature).

## Checked
| Check | How | Result |
|---|---|---|
| Place guard on every `studio/` script | `python tools/check_guard.py` | PASS: 7 studio scripts, 0 without the guard |
| Skin rule, repo scan | `python tools/check_skin.py` | PASS, exit 0: 16 files outside `Skins/`, 0 hits, 0 files that fail to lex; names read from `Names.lua`: creatures 36, zones 6, hazards 6, products 19. 5 comment notes (`--verbose`), which do not fail (TEAM CALL M1-01b) |
| The scan catches what it should | probe file with `Color3.fromRGB`, `"#FF00AA"`, `rbxassetid://`, `SoundId = "1234567"`, `Image = 9876543`, "Chomp Frog" in a string, "Tumble Cactus" in a long string; then a file with an unbalanced bracket | 7 hits, exit 1; lex error, exit 2. Probe deleted |
| Sync loads | Studio MCP `run_code`: `require(game.ServerStorage.DevSync:Clone())()` | `DevSync: 31 files, 3 updated, 0 removed`, no errors |
| Every module compiles | edit mode, required a clone of every ModuleScript under `Shared` and `Skins` (others' half-written files included) | 27 required; the only failure was my stub `Names` reading a stale cached `Ids` (fixed, see lessons); M1-02's `Tokens`, `Names`, `Icons` and M1-04's `Sounds` load with no error |
| Config values | edit mode | `Punch.CYCLE(1) = 1.81`, `Fight.band(1.0) = fair`, `Bag.STRENGTH_VALUE(2) = 1.35`, `Zones.POWER.z1_t1 = 25` |
| 13 families and the M1 remotes after a play-mode server start | `run_script_in_play_mode` (start_play) | `families in contract 13, folders 13, remotes ok 20, missing 0`; no errors in the log |
| Rate limiter | same session, `Net.rateOk` x6 at 4/s | allowed 4, `TestHooks.reports._dropped["Punch.Report"] = 2` |
| Validation helpers | same session | `isNumber(NaN) = false`, `isNumber(inf) = false`, `isInt(3, 1, 10) = true` |
| State hook consumed | same session, `HFB_SetPower = 24`, `TestHooks.onSet` | handler got 24, attribute cleared |
| `studio/CheckSkin.lua` | `run("CheckSkin.lua")`, prints collected through `LogService.MessageOut` | 11 PASS, 2 FAIL (below). PASS: active skin brickbrawl; stub has all 128 schema keys; `get` nil on a missing key; `need` errors naming it; `need` returns a present key; `ForceSkin = stub` loads the stub (names are ids, model `Boss_z1_t1_stub`); stub boss built with the five groups and `PrimaryPart = Body` |
| ForceSkin in play | armed by CheckSkin, then `run_script_in_play_mode` | `hook stub; server Skin.Id stub; z1_t1 name z1_t1; model Boss_z1_t1_stub; remotes families 13`, no errors. Disarmed after: 0 `HFB_` attributes left, marker still true, no scratch folders |

## Issues found
CheckSkin's two FAILs are keys owed by other tasks, not errors in the code:
- **A2, brickbrawl misses 11 M1 keys:** `Models.creatures.z1_t1.{model, bodyType, heightStuds, groups}`,
  `Models.bags[1]`, `Models.hazards[1]`, `Models.gloves.model`, `Models.clips.{jab3, bigThird}` (M1-03 modeler,
  `Models.lua` is still the M0 skeleton), and `Effects.stars`, `Effects.cubeBurst` (declared empty at M1, contract F;
  `Effects.lua` is the M0 skeleton; owner M1-12 builder).
- **B, shape:** the same keys from the stub's side (the stub already has them). Everything M1-02 and M1-04 added
  matches the stub.
- `Main.server.lua` prints `Config.SkinId`, so under the stub it still says `skin=brickbrawl`; the server's
  `Skin.Id` is `stub`. For M1-06 (owner of Main): print `Skin.Id`.

## Not checked / needs the manager
- The client under the stub: `run_script_in_play_mode` returns only the server's log (M0 lesson); the client's
  `Main.client.lua` requires `Skin` and its print was not read. CoreLoop (M1-16) reads the client through
  `Profile.TestReport`. UNVERIFIED until then.
- Skin check part 2 (CoreLoop under the stub) waits for M1-16's `checks/CoreLoop.lua`; run by M1-22.
- Nothing on screen; no computer use needed for this task.

## Commands
```
python tools/check_guard.py
python tools/check_skin.py            (--verbose for comment notes)
require(game.ServerStorage.DevSync:Clone())()
require(game.ServerStorage.DevSync:Clone()).run("CheckSkin.lua")     -- arms part 2; set HFB_CheckSkinNoArm = true to skip
workspace:SetAttribute("HFB_ForceSkin", nil); local f = game.ServerStorage:FindFirstChild("HFB_SkinCheck"); if f then f:Destroy() end
```
