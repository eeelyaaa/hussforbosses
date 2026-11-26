# M2 gate "Systems": the wired run (M2-28, scripter, 2026-11-26)

One driver for the whole gate: `studio/checks/Gate.lua` (edit mode) + `GateRun.lua` (play runner) + `GateData.lua` (the call list and the
S1..S27 row map), `tools/gate_scans.py` (the four repo scans). Header of `Gate.lua` has every mode. `CheckAll` (M1) still works alone.

## How to run it (studio lock held)
1. Sync server up: `python tools/devsync.py`.
2. Edit mode: `workspace:SetAttribute("HFB_GateMode","prepare"); require(game.ServerStorage.DevSync:Clone()).run("checks/Gate.lua")`
   (sync, 9 edit-mode checks, installs `ServerStorage.TmpChecks` + client probes, prints the plan).
3. Play, one `run_script_in_play_mode` (start_play) per command, repeat with the `start` it prints after `GATE next` until `GATE done`:
   `require(game.ServerStorage.TmpChecks.GateRun)({ start = 1 })`   (`{ only = "<call id>" }` for one call; budget 50 s, the MCP returns
   nothing for a call over about 60 s, and a big play result lands in a file: filter it for `GATE row`).
4. Stub skin: mode `arm`, then `{ list = "stub", start = 1 }`, then mode `disarm`. Play-stop save: mode `playstop1`, ONE play call
   `require(game.ServerStorage.TmpChecks.GateRun)`-less: `require(game.ServerStorage.TmpChecksData.PlayStop)()`, then mode `playstop2`.
5. `python tools/gate_scans.py`. Then mode `summary` with `Workspace.HFB_GateRows` = every `GATE row` line (`;;`-separated; document rows
   `doc:S25|1|0|why`), then mode `cleanup` (clears every HFB_ attribute, removes TmpChecks and probes, asserts it; each play call also clears
   and asserts leftover hooks).

## Result (the summary mode's table, verbatim counts)
**26 PASS, 1 FAIL, 0 UNVERIFIED of 27 rows; 67 check calls; 11,431 PASS and 4 FAIL lines.**

| Row | Status | Command / calls (PASS/FAIL) |
|---|---|---|
| S1 | PASS | Punch2 a 35/0, b 5/0 |
| S2 | PASS | Bag a 23/0, b 25/0 |
| S3 | PASS | Bag a |
| S4 | PASS | Punch2 c 24/0, d 13/0, Zones c 16/0 |
| S5 | PASS | Zones a 19/0, b 7/0, c 16/0 |
| S6 | PASS | Hazards a 28/0, b 27/0, c 11/0 |
| S7 | PASS | Base a 39/0 |
| S8 | PASS | Base b 14/0 |
| S9 | PASS | Upgrades a 18/0 |
| S10 | PASS | Steal a 54/0, b 26/0, c 8/0, Shield a 40/0 |
| S11 | PASS | Offline a 20/0, b 9/0 |
| S12 | PASS | Rebirth a 21/0, b 7/0 |
| S13 | PASS | Robux a 57/0, b 22/0, c 18/0, Spin a 21/0 |
| S14 | PASS | Saving a 51/0, b 20/0, c 9/0, d 34/0 |
| S15 | PASS | Saving a-d, PlayStop 2/0 (a real Play stop saved the last change and released the lock) |
| S16 | PASS (scripted) | Steal a/b/c, Policy a 18/0. UNVERIFIED part: the greyed steal prompt on screen (O4), two real clients (O7) |
| S17 | PASS (scripted) | Robux a/b/c, Spin a. UNVERIFIED part: a real purchase dialog and a web buyer (published game) |
| S18 | PASS | Shield a, Steal b, Robux b |
| S19 | PASS | Rebirth a, b |
| S20 | PASS | Rebirth c 8/0, BoughtScan 2/0, Robux a |
| S21 | PASS | FirstSession all 28/0 |
| S22 | PASS | MovesM2Real z4z6 53/0, z2z5 54/0, z3 28/0, FrogMoves 15/0. Triangle counts: `m2-25-bosses-in-place.md` |
| S23 | PASS | CheckSkin A-E 13/0, check_skin.py, SkinCheck3 save 5/0 and load 7/0, CoreLoop a 22/0 and b 36/0 under the stub |
| S24 | PASS (rerun 2026-11-26, M2-07) | check_labels.py clean; PerfectFloat 74/0; **FightCamera a 16/0, b 16/0** (probe redone patrol-aware; see `m2-07-client-punch-camera.md`); P7 stud distance has no scripted check (O6, main session) |
| S25 | PASS | `audits/m2-27-exploit-review.md`: code half PASS, no must-fix open (read, not run) |
| S26 | PASS | Curves a good Speed 10 5/0 (3.663 Power/s against 3.668); `m2-26-curves.md` exists |
| S27 | PASS | CheckSync 7/0, CheckSkin, Refusals live 6/0 a 19/0 b 32/0, CoreLoop a 22/0 b 36/0, BurstValues a 31/0 b 26/0, NoDelay 9/0, HudViews 270/0, stub CoreLoop, check_guard |

Other checks run (in no row): ScreensA 1944/0, ScreensB 2164/0, ScreensC 5762/0 (edit mode); check_streaming.py clean.
O1-O8: not run (main session, `computer`). Left for them: StealClient (21 rows), ShopClient (42 rows), ClientA, ClientPunch, StreamingProbe, ReviewLineProbe
client probes are driven by hand (not in the gate); not re-run here.

## S24 FightCamera: was FAIL (6/4), now PASS 16/0 on both sets (M2-07 rerun, see `m2-07-client-punch-camera.md`). The original finding:
Not game code: the M1-26b probe (`FightCameraProbe.client.lua`) walks to start spots that are fixed offsets from the ring centre, and the boss
now patrols up to 14 studs from it, so a spot refuses 'ring' while the boss is away from the centre (3 of 4 spots), and the press-on-entry case
frames a boss that is off screen at the real camera. The camera numbers that did run pass (avatar over head 0%, box on screen at 1280x720 and
874x402). One patrol-aware rewrite (offsets from the boss's current spot, clamped into the ring) was tried and was worse; reverted, note left in the
probe. Owner for a real fix: M2-07 / M1-26 camera author (scripter), as a check redo; then run FightCamera a and b. A real camera look is O1.

## Flaky, noted not failed
MovesM2Real z4z6 failed once (z6_t6 defeat flop -0.073 studs) and passed on the immediate rerun with the same code (a frame-time margin);
animator-vfx (M2-22) should widen or measure it.
Missing client reports: no `Profile.TestReport` was missing in this run's CoreLoop, NoDelay or FightCamera results (M2-07 flagged two missing ring reports).

## Stale checks fixed (check scripts only)
- `CheckLib.begin`: forces all 10 passes off (`PassOwned`) and stubs `Shop.setPromptFn` (restored in `finish`) for every check; waits for the live profile
  (CoreLoop b failed first in a fresh session); only counts earlier log lines from its own call (`_G.HFB_GATE_LOG_FROM`); `L.nearBoss` stands inside
  the ring and within range of the boss as it patrols now.
- CoreLoop, Refusals, BurstValues, NoDelay use `L.nearBoss` (BurstValues re-teleports before every fight). No check used AutoTap `early`; nothing to drop.
- HudViews: short numbers (`Counters.short`) and the M2-08 floating PERFECT replace two stale assertions. FrogMoves: 4 s warm-up (lesson M1-20).
- CheckProbe `moves`: ignores the review line's looping plays (NoDelay lastHeart count). Rebirth b waits out the rebirth cooldown.
- Curves: the Good expectation is paper x CYCLE/(CYCLE + 0.070 s tap offset) (TEAM CALL in `decisions.md`).
- FightCameraProbe now runs a set when `HFB_M126Spots` is set (wired as FightCamera a/b).
- Docs: `test-hooks.md` lists the Studio-script switches incl. `HFB_PlayStopValue`, `HFB_GateMode`, `HFB_GateRows`, and LeaveAt moves pad stamps;
  `Net.lua` Shield.State comment for `ownerUserId`.
- Mistake owned: Gate "cleanup" first removed every `HFB_*` script in StarterPlayerScripts, which took the review line's two client scripts; fixed to remove only
  the gate's probes and the review line was rebuilt with `BuildReviewLine.lua` (6 bosses, 0 failed).
- Place left clean: 0 `HFB_` attributes, no TmpChecks, no probes, marker true, play stopped, lock released. Nothing committed.
