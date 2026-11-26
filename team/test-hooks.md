# Huss for Bosses: test hooks

Read only in Studio through `src/ReplicatedStorage/Shared/TestHooks.lua` (`TestHooks.get(name)` is nil on a live
server, which warns once if any is set). Each hook is a Workspace attribute `HFB_<Name>`. **This list and
`TestHooks.HOOKS` must match**; a task that adds a hook adds it to both. Tests set hooks from the play-mode script
and clear them afterwards (`TestHooks.clearAll()` clears every listed hook). (`vault/patterns/test-hooks-gated-to-studio-and-listed.md`)

Kinds (v1, M1-01, `requirements/m1-contract.md` section L):
- **state**: the server applies the value once and clears the attribute. Systems read them with
  `TestHooks.onSet(name, fn)` (fires now if set, and on every later set; clears before `fn`) or `TestHooks.consume(name)`.
- **config**: read with `TestHooks.get(name)` while set; the test clears it.
- **client**: read by the client with `TestHooks.get(name)`, never consumed; the test clears it.

The test player is the one player in a Studio play session (state hooks apply to every player in the server; a
two-player test passes the target through module seams, M2).

## In the code
| Hook | Attribute | Kind | Type | What it does | Added | Honoured by |
|---|---|---|---|---|---|---|
| ForceSkin | `HFB_ForceSkin` | config | string | Loads `Skins/<id>` instead of `Config.SkinId`; read once when `Shared/Skin` is first required, so set it **before play starts** (the skin check uses `stub`) | M0 | `Shared/Skin` |
| SaveOff | `HFB_SaveOff` | config | boolean | No DataStore reads or writes; fresh unsaved profiles | M0 | save module (M2); at M1 nothing is saved anyway |
| SetPower | `HFB_SetPower` | state | number | Power becomes this; `Profile.Changed` sent | M1 | M1-06 `Data/Session` or `Systems/Bag` |
| SetCash | `HFB_SetCash` | state | number | Cash becomes this; `Profile.Changed` sent | M1 | M1-06 |
| SetStrength | `HFB_SetStrength` | state | number | Punch Strength level (1..30) | M1 | M1-06 |
| SetSpeed | `HFB_SetSpeed` | state | number | Punch Speed level (1..10); `Punch.Schedule` re-sent | M1 | M1-06 |
| Wipe | `HFB_Wipe` | state | boolean | Session becomes a fresh profile (contract K) | M1 | M1-06 `Data/Session` |
| GrantBoss | `HFB_GrantBoss` | state | string | A creature id: that boss goes on the player's head as if beaten (`Carry.State carrying`) | M1 | M1-11 `Systems/Carry` |
| PadFastBack | `HFB_PadFastBack` | config | number | Seconds; replaces `Config.Fight.FIXED_BACK_S` | M1 | M1-06 `Systems/Zones` |
| LogForce | `HFB_LogForce` | config | string | `hit` = the log is on the carrier's path now; `clear` = it never reaches the carrier | M1 | M1-11 `Systems/Hazards` |
| ClockOffset | `HFB_ClockOffset` | config | number | Seconds added to the server's hazard and pad clock (income stamps, pad timers) | M1 | M1-11 `Systems/Hazards`, `Systems/Income`; M1-06 `Systems/Zones` |
| AutoTap | `HFB_AutoTap` | client | string | `perfect` / `good` / `miss` / `mix` / `busy` / `early` / `lag`: the real client path taps at landing + 0 (Perfect), + 70 ms (Good), not at all (Miss); busy = Good tap then a tap 100 ms into the burst (ignored); early = a tap 0.5 s before landing (ignored) then Good; lag = Good tap then one frame held 0.45 s (beats 2 and 3 fire together); with AutoTap set, standing in a boss ring with no fight presses Huss once a second (starts the fight) | M1 | M1-07 `Controllers/TestClient` |
| AutoMix | `HFB_AutoMix` | client | string | Percentages `perfect,good,miss` for `AutoTap = mix`, e.g. `45,45,10` | M1 | M1-07 |
| ForceInput | `HFB_ForceInput` | client | string | `touch` / `gamepad` / `keyboard`: `Input.kind()` returns this | M1 | M1-07 `Controllers/Input` |
| FrameCap | `HFB_FrameCap` | client | number | 60, 30 or 15: a busy-wait in Heartbeat holds each frame to at least 1/cap s (RenderStepped runs too rarely in a Studio play client) | M1 | M1-07 `Controllers/TestClient` |
| AutoInteract | `HFB_AutoInteract` | client | boolean | The client presses interact through `Input.fire("interact", "auto")` every 0.6 s: sends Grab or Place only when the prompt is up | M1 (M1-14) | `Controllers/TestClient` |
| ReportBeats | `HFB_ReportBeats` | client | boolean | After each burst the client sends `Profile.TestReport` `beats` with `BurstClock.log`; M1-14 adds `carry`, `base`, `log` reports every 0.4 s | M1 | M1-07, M1-14 |

## Reports from the client (`Profile.TestReport`)
Studio only. `Main.server.lua` calls `TestHooks.listenReports(Net)` once after `Net.serverInit()`; each report is
stored as `TestHooks.reports[name] = { userId, json, at }` (json at most 1 KB) and `warn`ed with `[HFB] TestReport`.
`TestHooks.reports._dropped["Family.Name"]` counts calls dropped by the rate limit in `Net.onServerEvent`.

## Studio-script switches (read only by `studio/` scripts, not by game code; not in `TestHooks.HOOKS`)
| Attribute | Read by | What it does |
|---|---|---|
| `HFB_CheckSkinNoArm` | `studio/CheckSkin.lua` | `true`: run the checks without arming part 2 (the script clears it) |
| `HFB_CheckAllMode` | `studio/checks/CheckAll.lua` | `prepare` / `install` / `arm` / `disarm` / `summary` / `cleanup` (M1-16; the script clears it) |
| `HFB_M126Spots` | `studio/checks/FightCameraProbe.client.lua` | `a` / `b`: which set of fight start spots the probe walks to (M1-26b; the runner clears it) |
| `HFB_CheckAllRows` | `studio/checks/CheckAll.lua` | the CHECKALL rows for `summary`, `;;`-separated (cleared by the script) |
| `HFB_CheckProbe` | `StarterPlayerScripts.HFB_CheckProbe` (installed by CheckAll from `studio/checks/CheckProbe.lua`, removed by `cleanup`) | `fuzz` / `rate` / `moves`: the client probe of Refusals phase b and NoDelay (the checks clear it) |

## Planned (build plan, "Test hooks"); added by the task that builds each
- Set bought cash, rebirths, zones beaten; grant a boss by id to a spot or the crate, with or without a bought mark
  and buyer.
- Force a pad's roll; the offline clock, shield, safe time and break timer through `ClockOffset` or their own hooks.
- Force a save error between the two writes of a transfer.
- A stand-in second player (owner or thief) through module seams.
- A fake receipt for any product key; pass ownership on or off; both policy flags on or off, or the call failing.
