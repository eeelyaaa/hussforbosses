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
| GrantBoss | `HFB_GrantBoss` | state | string | `<creatureId>[,key=value...]`: that boss goes on the player's head as if beaten (`Carry.State carrying`). M2 keys: `to=head\|crate\|<spot 1..17>`, `level=<1..20>`, `bought=spin\|pack`, `buyer=<userId>` (default the player), `uid=<uid>` | M1, extended M2 | M1-11 `Systems/Carry`; M2-11 (spot, crate, level), M2-14 (bought, via `BoughtMark`) |
| PadFastBack | `HFB_PadFastBack` | config | number | Seconds; replaces `Config.Fight.FIXED_BACK_S` | M1 | M1-06 `Systems/Zones` |
| LogForce | `HFB_LogForce` | config | string | `hit` = the log is on the carrier's path now; `clear` = it never reaches the carrier | M1 | M1-11 `Systems/Hazards` |
| ClockOffset | `HFB_ClockOffset` | config | number | Seconds added to the server's hazard and pad clock (income stamps, pad timers) | M1 | M1-11 `Systems/Hazards`, `Systems/Income`; M1-06 `Systems/Zones` |
| AutoTap | `HFB_AutoTap` | client | string | `perfect` / `good` / `miss` / `mix` / `busy` / `early` / `lag` / `untimed` / `mash` (M2: untimed = one tap 0.3 s after landing, outside Good; mash = a tap every 0.1 s; honoured by M2-07): the real client path taps at landing + 0 (Perfect), + 70 ms (Good), not at all (Miss); busy = Good tap then a tap 100 ms into the burst (ignored); early = a tap 0.5 s before landing (ignored) then Good; lag = Good tap then one frame held 0.45 s (beats 2 and 3 fire together); with AutoTap set, standing in a boss ring with no fight presses Huss once a second (starts the fight) | M1 | M1-07 `Controllers/TestClient` |
| AutoMix | `HFB_AutoMix` | client | string | Percentages `perfect,good,miss` for `AutoTap = mix`, e.g. `45,45,10` | M1 | M1-07 |
| ForceInput | `HFB_ForceInput` | client | string | `touch` / `gamepad` / `keyboard`: `Input.kind()` returns this | M1 | M1-07 `Controllers/Input` |
| FrameCap | `HFB_FrameCap` | client | number | 60, 30 or 15: a busy-wait in Heartbeat holds each frame to at least 1/cap s (RenderStepped runs too rarely in a Studio play client) | M1 | M1-07 `Controllers/TestClient` |
| AutoInteract | `HFB_AutoInteract` | client | boolean | The client presses interact through `Input.fire("interact", "auto")` every 0.6 s: sends Grab or Place only when the prompt is up | M1 (M1-14) | `Controllers/TestClient` |
| ReportBeats | `HFB_ReportBeats` | client | boolean | After each burst the client sends `Profile.TestReport` `beats` with `BurstClock.log`; M1-14 adds `carry`, `base`, `log` reports every 0.4 s | M1 | M1-07, M1-14 |
| SetBoughtCash | `HFB_SetBoughtCash` | state | number | `boughtCash` becomes this (cash raised to it if lower) | M2 | M2-09 `Data/Session` |
| SetRebirths | `HFB_SetRebirths` | state | number | Rebirth count 0..10; multipliers and spot count follow | M2 | M2-14 `Systems/Rebirth` |
| SetZonesBeaten | `HFB_SetZonesBeaten` | state | string | `1,2,3` (or empty for none): the saved `zonesBeaten` | M2 | M2-10 `Systems/Zones` |
| SetTickets | `HFB_SetTickets` | state | number | `spinTickets` becomes this | M2 | M2-18 `Systems/Spin` |
| SetCharges | `HFB_SetCharges` | state | number | `breakerCharges` becomes this | M2 | M2-15 `Systems/Shield` |
| ForceRoll | `HFB_ForceRoll` | state | string | `<padId>=<creatureId>`: that rolling pad rolls this creature now (for every player) | M2 | M2-10 `Systems/Zones` |
| LeaveAt | `HFB_LeaveAt` | state | number | Seconds: saved `leftAt` becomes now - n, every placed boss's pad stamp moves back by the same n (M2-14), and the join's offline computation runs again (`Offline.Summary` if >= 60 s) | M2 | M2-14 `Systems/Offline` |
| ForceSave | `HFB_ForceSave` | state | boolean | Save the test player's profile now; result in `TestHooks.reports.save` | M2 | M2-09 |
| Leave | `HFB_Leave` | state | boolean | The leave path for the test player (carried or stolen boss returned, `leftAt`, final save, lock released); the player stays without a profile until `Rejoin` | M2 | M2-09 |
| Rejoin | `HFB_Rejoin` | state | boolean | Load the test player's profile again as a join (lock, migrations, offline) | M2 | M2-09 |
| Shutdown | `HFB_Shutdown` | state | boolean | The `BindToClose` save-all path without closing; result in `TestHooks.reports.shutdown` | M2 | M2-09 |
| FakeReceipt | `HFB_FakeReceipt` | state | string | `<shopKey>[,purchaseId]`: a product key calls the one `ProcessReceipt` with a fake receipt (same id twice = granted once); a pass key acts as `PromptGamePassPurchaseFinished(true)`; result in `TestHooks.reports.receipt` | M2 | M2-18 `Systems/Receipts` |
| Steal2 | `HFB_Steal2` | state | string | Stand-in second player seam command: `add <userId>`, `hold <userId> <plotId> <uid>`, `cancel <userId>`, `home <userId>`, `punch <fromUserId> <toUserId>`, `remove <userId>`; result in `TestHooks.reports.steal2` (M2-15 may add commands, listed here) | M2 | M2-15 `Systems/Plots` |
| PadsFast | `HFB_PadsFast` | config | number | Seconds; replaces the rolling pads' roll period (45 s) | M2 | M2-10 |
| SaveFailBetween | `HFB_SaveFailBetween` | config | boolean | The next steal transfer errors after the owner's write and before the thief's | M2 | M2-09 `Data/Transfer` |
| PassOwned | `HFB_PassOwned` | config | string | `<passKey>=on\|off[,...]`: replaces Roblox's answer for those passes | M2 | M2-18 `Systems/Passes` |
| PolicyRandom | `HFB_PolicyRandom` | config | string | `ArePaidRandomItemsRestricted`: `on` = restricted, `off` = not, `fail` = the call fails (= restricted); `<userId>:on` targets one player, comma-separated | M2 | M2-15 `Systems/Policy` |
| PolicyTrading | `HFB_PolicyTrading` | config | string | `IsPaidItemTradingAllowed`: `on` = allowed, `off` = not, `fail` = fails (= not allowed); `<userId>:off` targets one player | M2 | M2-15 `Systems/Policy` |
| SpinSeed | `HFB_SpinSeed` | config | number | Seed for the spin's `Random` (the 100,000-roll test only) | M2 | M2-18 `Systems/Spin` |
| ShieldClock | `HFB_ShieldClock` | config | number | Seconds added to the clock the shield, the 60 s safe time and the 5-minute break timer read | M2 | M2-15 |
| AutoPlayer | `HFB_AutoPlayer` | client | string | `perfect` / `good` / `mix` / `untimed`: the TestClient plays the first session itself at that grade (bag until the nearest beatable boss, fight, carry home, place, collect, upgrade, buy Strength, on into zone 2) | M2 | M2-21 `Controllers/TestClient` |

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
| `HFB_GateMode` | `studio/checks/Gate.lua` | `prepare` / `install` / `arm` / `disarm` / `summary` / `cleanup` / `list` (M2-28; the script clears it) |
| `HFB_GateRows` | `studio/checks/Gate.lua` | the `GATE row` lines of the play calls for `summary`, `;;`-separated (cleared by the script) |
| `HFB_PlayStopValue` | `studio/checks/PlayStop.lua` | a fresh random Power the PlayStop play copy sets and the next edit-mode run reads back (M2-09; the script clears it) |
| `HFB_M207Phase` | `studio/checks/ClientPunch.client.lua` | `bag` / `fight`: which half of the M2-07 client probe runs (the runner clears it) |
| `HFB_CA_Step`, `HFB_CA_Arg` | `studio/checks/ClientA.client.lua` | `<step>:<n>` and its argument: the M2-12 client probe's step switch (the driver clears them) |
| `HFB_CheckProbe` | `StarterPlayerScripts.HFB_CheckProbe` (installed by CheckAll from `studio/checks/CheckProbe.lua`, removed by `cleanup`) | `fuzz` / `rate` / `moves`: the client probe of Refusals phase b and NoDelay (the checks clear it) |

## Reports kept on the server (Studio)
`TestHooks.reports` also holds `funnel` (list of `{ name, userId, t }`, `Systems/Funnel`), `save`, `shutdown`,
`receipt`, `steal2` (each written by the hook's owner above).

All hooks the build plan's "Test hooks" planned are now listed (M2-01, `requirements/m2-contract.md` section G).
