# M2-06: the punch server after P3 and P2 (evidence)
Scripter (opus), 2026-11-25. Gate rows S1 and S4 (`requirements/m2-gate.md`). Quality pass: **Function** only.
Built to `m2-contract.md` B, `m2-punch-numbers.md` sections 1 to 3, the burst timing contract (unchanged), and the
contract review's S6 (`audits/m2-02-contract-review.md`). TEAM CALLs M2-06-1 to -5 are in `decisions.md`.

## What changed (game repo `projects/huss-for-bosses`, nothing committed)
- `src/ReplicatedStorage/Shared/Config/Punch.lua`: M2 `RING`, bag windows 130/55, `GRADE_VALUE.untimed = 1`,
  `RATE_TOLERANCE` 0.75, new `UNTIMED_MIN_GAP_S` 0.66, `RING_GRACE_S` 0.15, `UNTIMED_EARLY_SLACK_S` 0.10,
  `UNTIMED_LATE_SLACK_S` 0.25; `EARLY_TAP_S` removed (no code used it).
- `src/ReplicatedStorage/Shared/Config/Fight.lua`: M2 bands, `UNTIMED_HEART_FROM = "hard"` (PROVISIONAL Q1),
  `Fight.untimedCostsHeart(bandId)`. `CAMERA` left as it was (dead once `Config/FightCamera` sets one).
- `src/ServerScriptService/Systems/Punch.lua`: validates `Ids.REPORT_GRADES` and `auto`. Untimed is one punch at
  accept time, with no burst and no busy time. The rate rules from `m2-punch-numbers.md` section 2 apply, plus
  M2-06-1 (an untimed after an untimed needs the Good window too) and M2-06-5 (S6: in a fight, only inside the
  server's current ring, and the next landing is anchored to that ring). Hearts from Hard up come after the punch.
  `auto` refusals (M2-06-2). `Punch.Burst` goes to players within 150 studs. Funnel: `FirstBagPunch`,
  `FirstPerfectLanded`.
- `src/ServerScriptService/Systems/Fight.lua`: `Fight.Beat.size = 'single'` for untimed;
  `Fight.bossCentre` (the `Zones.bossPosition` seam with `PATROL.slack`, else the pad ring) for the Fight.Start
  ring test; `Fight.State.bossPos`; funnel `FirstFightStarted`, `FirstBossBeaten`.
- No duplicate server `defeat` caller exists (searched `src/ServerScriptService`).
- Checks: new `studio/checks/Punch2.lua` (phases a, b, c). Updated for M2 numbers: `CoreLoop.lua` (ring 1.05,
  cycle 1.66, Fair 130/55), `BurstValues.lua` (cycles 1.66 / 1.02), `Refusals.lua` (rate label), `NoDelay.lua`
  (band comment; ends a running fight when it stops tapping, so the lastHeart count covers the same fights).

## What ran (Studio MCP, `studio` lock held by `scripter-punchserver`, released after; play mode stopped)
Edit mode: `require(game.ServerStorage.DevSync:Clone())()` (86 files, 84 modules swapped), then
`HFB_CheckAllMode = "install"` + `checks/CheckAll.lua`. Punch2 was added to `ServerStorage.TmpChecks` the same way,
from `/studio/checks/Punch2.lua`, because `CheckAll`'s list is M2-28's. At the end: `"cleanup"`, which left no
TmpChecks, no probe and no `HFB_` attribute. Each line below is one `run_script_in_play_mode` (start_play) call,
`require(game.ServerStorage.TmpChecks.<Check>)({ phase = "<p>" })`. These are the final runs on the final code.

| Check | Phase | Result | Notes |
|---|---|---|---|
| Punch2 | a (bag rules) | 35 / 0 | run 1 had one FAIL from a float `==` in the check (`+1.350` was right); fixed with a tolerance |
| Punch2 | b (mash vs Good) | 5 / 0 | mash: 100 forged untimed in 10 s gave +12 Power (88 refused `untimedBusy`); Good at the real cadence: 7 bursts, +28 |
| Punch2 | c (fights, heart rule, S6) | 24 / 0 | 22/2 before the check paced fights 0.9 s apart and sent the S6 early tap at ring open (both were check timing) |
| Refusals | a | 19 / 0 | stall rule 2.63 s (expected 2.60) |
| Refusals | b | 32 / 0 | Punch.Report limiter: 10 in one frame -> 6 dropped |
| BurstValues | a | 31 / 0 | cycles 1.667/1.666 (Speed 1), 1.018/1.016 (Speed 10); every band's windows |
| BurstValues | b | 26 / 0 | all-Good tap counts 2, 3, 4, 5, 8, 13; B22 on punches 1 and 2 |
| CoreLoop | a | 22 / 0 | 21/1 before the stale `close 1.2` line was updated (the client drew 1.05, which is right) |
| CoreLoop | b | 36 / 0 | Fair fight won on burst 3 punch 2, as M1 |
| NoDelay | a | 9 / 0 | run 1: 21 burst / 3 miss rings (sample under the 4-miss floor); run 2: one lastHeart report landed 0.24 s after the count; run 3, after the check fix: pass |

Total on the final code: **Punch2 64/64; M1 server checks 175/175.** Refusals, BurstValues and CoreLoop were run
before the S6 change. That change touches only the untimed branch in a fight, and none of those checks sends an
untimed report. Punch2 a and c were rerun after it.

## What the checks show (gate rows)
- **S1:** untimed on the bag +1 at Strength 1 and +1.35 at Strength 2, applied at once with no burst. A second
  untimed in the ring is refused `untimedBusy` (0.2 s and 0.72 s later) and accepted 0.92 s later. A timed report
  0.3 s after an untimed is refused `rate` and accepted at 0.72 s. An untimed during a burst is refused `busy`.
  A forged Perfect 0.9 s after a Good is refused `rate`. Good is 4 and Perfect 8, unchanged. `auto` with untimed or
  miss is refused `grade`, and an auto Good is refused `pass`. Bad tap times are refused `grade`. 20 reports a
  second: the limiter passes 4 and the handler accepts 1. Mashing 10 s gives +12 against +28 for Good bursts
  (acceptance 2).
- **S4:** untimed fight damage is Power x 1 (Fair 25, Easy 50; five clicks win at Easy with no heart). From Hard
  up, the punch lands and then costs a heart, and the third is the loss. Good is x4 and Perfect x8 (the win lands
  on punch 3 of the Perfect). A no-tap ring after an untimed costs a heart at 4.28 s (expected 4.26). A reported
  Miss still costs a heart. `bossPos` is in `Fight.State`. All four funnel marks fire.
- **S6 (M2-02):** an untimed at the first ring's open is refused. 6 s of untimed every 0.1 s gave 4 accepted, and
  the expected landing was at most 2.62 s ahead of the clock (bound 2.71). Once the mashing stopped, the next
  ring cost a heart 0.03 s from the stall deadline.

## Not verified here
- Rebirth and 2x Power multipliers on the untimed bag gain: they ride on `Bag.value`, which is M2-10's. Recheck at
  M2-10.
- The untimed path through the real client (`AutoTap untimed / mash`) is M2-07's. The forged-report rows above
  are the server's rule. Gate S1's real-input row and the PERFECT float stay with M2-07 and M2-08 (on screen).
- `Fight.Beat.size = 'single'` reaches the client: the server sets it (code), but no server check can read a
  `FireClient` payload. M2-07's ReportBeats should confirm it.
- `Punch.Burst` to other players needs two clients: `UNVERIFIED`, on the two-device list.
- Fight.Watch (M2-06 sends, M2-16 plays) is not built: the brief for this task did not include it.

## Follow-up after M2-10 (patrol and real passes), 2026-11-25
- `Systems/Fight.lua`: the fight spot is built around `bossPos` (TEAM CALL M2-06-6). `Fight.fightSpot(.., bossAt)`
  moves the boss box and the ring by the flat offset from the model's rest pivot (capped at halfLen + 1).
  `standAtSpot` validates against the moved ring.
- `Punch2`: every phase sets `PassOwned` to `pass_auto_punch=off,pass_perfect_auto_punch=off,pass_2x_power=off`
  (the Studio account owns them for real). Phase c fights start 3 studs off the boss's live position. The new phase d
  covers the two walk ends.
- Ran (lock `scripter-punchserver`, released, play stopped, cleanup clean): **Punch2 a 35/0, b 5/0, c 24/0, d 13/0**.
  Phase d: the rest pivot is on the patrol anchor (0.00 studs). At -14.0 and +14.0 studs along the walk the fighter
  stood 5.50 studs from the walking boss, the same as at rest (5.50), and the root was 0.00 from the spot. Earlier
  runs: d 10/1 `closed`, because the check moved the patrol clock backwards between the ends (it now visits them in
  clock order); c 2/2 (`ring`, then a nil fight in the helper), because the helper teleported to the pad centre
  while the boss walks.
- Not rerun after the patrol: Refusals, BurstValues, CoreLoop, NoDelay. They teleport to the pad's ring centre, and
  a walking boss can now be up to 14 studs from it (`ring` refusals possible). They need the same near-boss
  teleport (M2-28 or the owner of those checks).
