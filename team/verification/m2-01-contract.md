# M2-01: the M2 contract and its skeletons (tech-lead, 2026-11-25)

## What was done
- `requirements/m2-contract.md` completed: A (owned files, batch check), B (P3/P2/P4 with M2-03's rate rules), C
  (every remote with validation, rate, owner), D (schema v1, the `Data/Session` API), E (patrol formula), F (12
  funnel events and who marks each), G (hooks), H (policy), I (ids).
- Code: `Shared/Net.lua` (63 remotes in 13 families; M2 entries carry `rate` and `owner`; `Net.rateFor`, `Net.fire`,
  `fireAll`, `fireNear`), `Shared/Ids.lua` (`REPORT_GRADES`, `BOUGHT_SOURCES`, `PAD_KINDS`, `FUNNEL`, `NOTICES`,
  `SHOP_KEYS`, `CASH_PACKS`, `SPIN_PRODUCTS`, `isPass`, `isProduct`, `parseCreature`), `Shared/TestHooks.lua` (+21
  hooks, 38 in all), 13 empty `Config/*` skeletons, `Config/ShopIds.lua` with the 19 real ids from `assets.md`
  (M2-00), `Config/init.lua` seams (`Shop.IDS`, `FightCamera`), `Systems/Funnel.lua` (API skeleton),
  `Main.client.lua` auto-start seam, `docs/controls.md` action-to-remote table, `team/test-hooks.md`.

## Checks (Studio MCP, holding the `studio` lock; DevSync on 127.0.0.1:34874)
| Check | Result |
|---|---|
| `python tools/check_skin.py` (repo scan) | PASS, 0 hits, 65 files |
| `python tools/check_guard.py` | PASS, 35 studio scripts |
| `TestHooks.HOOKS` against `test-hooks.md` (script compare) | 38 = 38, no difference |
| Sync (`CheckAll prepare`): 80 files, 22 updated, 78 modules swapped | OK |
| CheckSync | PASS 7/7 |
| CheckSkin Studio parts | 12 PASS, **1 FAIL (B: brickbrawl has `Models.creatures.z2_t2 .. z6_t6`, stub does not)**. Not this task's files: the M2-ART boss models were added to the brickbrawl skin without stub entries. Owner: M2-ART / M2-29 (stub skin) |
| Refusals live (edit mode) | PASS 6/0 |
| CoreLoop phase a (play) | PASS 22/0 (server up, join, schedule, Good / Perfect / Miss bursts, beats at 0 / 0.213 / 0.401, pad colour) |
| Refusals phase a (play) | PASS 19/0 (rate, busy, place, ring, carrying, stall, cooldown, authority) |
| In the same play session | 63 remote specs = 63 instances in 13 folders; every c2s remote has a rate (`Net.rateFor`); `Config.Shop.IDS` reads the real ids; `Config.Fight.CAMERA` unchanged (SIDE_DEG 60) |
| `CheckAll cleanup` | run; TmpChecks and the probe removed |

Not run: CoreLoop b, Refusals b, BurstValues, NoDelay, the armed skin part 2 (the full gate is M2-28's). The client's
own output was not read (the MCP returns the server log); the client path ran, since CoreLoop's bursts went through
`Punch.Report` from the real client. Nothing is player-facing in this task, so there are no on-screen checks.
The place was synced (scripts changed in the open place); the manager saves it as usual (`manager-todo.md`).

## Review fixes from M2-02 (S5, S7, N3), 2026-11-25
- S5: contract C now says there is no yield between the first state check and the mutate, and that pass and policy answers are read from the cache, never an `...Async` call inside a handler.
- S7: contract B5 now includes TEAM CALL M2-06-1 (an untimed report right after an accepted untimed one needs 0.66 s plus the context's Good window, else `untimedBusy`).
- N3: `Profile.TestReport` is `studioOnly` in `Net.lua`, so `Net.serverInit` skips it on a live server; Studio still creates it.
- Checks (studio lock; `HFB_ForceSkin` nil before and after): skin scan 0 hits; `CheckAll prepare` ran (sync and install; its console lines were not captured); Refusals phase a in play PASS 19/0; 63 specs = 63 instances, TestReport present in Studio with `studioOnly = true`; cleanup run. The live-server skip itself can't run in Studio (it is the `IsStudio` branch); its effect is that the remote is absent on a published server.
