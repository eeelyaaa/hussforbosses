# Huss for Bosses: board archive

Finished milestones, moved from `board.md` with final statuses. Evidence: `verification/`. Exit-check tally for M1:
`verification/m1-exit-checks.md` (30 PASS, 0 FAIL, 11 UNVERIFIED looks).

## M0: Setup (closed 2026-11-25, commit 96bbb68)
| Id | Task | Owner | Model | Status | Evidence |
|---|---|---|---|---|---|
| M0-1 | Repo, `team/` files, layout, sync, place guard, exit checks | tech-lead | opus | DONE | `verification/m0-setup.md` |
| M0-2 | Board from the plan | producer | sonnet | DONE | board |

## M1: Core feel and the four proofs (closed 2026-11-25)
Quality passes: Function only for every M1 feature (proof slice, by plan). Friction, Feel, Look and the manager's playtest are M3 to M5.
Final status key: DONE = evidence in `verification/`; DONE (look UNVERIFIED) = scripted checks pass, an on-screen look is owed (see `m1-exit-checks.md`).

| Id | Task | Owner | Model | Final status | Evidence |
|---|---|---|---|---|---|
| M1-01 | Contract in code, Net, Config, Skin API check, stub skin, TestHooks v1, `check_skin.py`, `CheckSkin.lua` | tech-lead | opus | DONE (+ M1-01b, M1-01c follow-ups) | `m1-01-contract.md`, `m1-01b-fixes.md` |
| M1-02 | Skin tokens, names, icon keys | gui-designer | sonnet | DONE | `m1-02-skin-keys.md` |
| M1-03 | Voxel builder, Chomp Frog, gloves, renders, atlas | modeler-3d | sonnet then opus (redo M1-03b) | DONE (picture match failed once, redone on opus, accepted by the orchestrator's look) | `m1-chomp-frog.md`, `m1-chomp-frog/` |
| M1-04 | Audio tools, measurements, stand-in thud set, `Sounds.lua`, upload list | audio-specialist | sonnet | DONE | `m1-04-audio.md` |
| M1-05 | Stud maps, greybox slice, measurements | builder | sonnet | DONE (all within 2% of the layout; sight line on screen UNVERIFIED) | `m1-greybox.md` |
| M1-06 | Server: Punch, Bag, Power, Fight, Zones, Session | scripter | opus | DONE (60/60) | `m1-06-server.md` |
| M1-07 | Client: Input, Ring, BurstClock, Fight controller and camera | scripter | opus | DONE (look UNVERIFIED for real presses) | `m1-07-client.md` |
| M1-08 | HUD: Kit, Huss button, ring view, pips, counters, fight overlay, prompts | gui-designer | sonnet | DONE (270 PASS at 4 sizes; phone emulator look UNVERIFIED) | `m1-08-hud.md` |
| M1-09 | Chomp Frog's moves, `BossMoves` | animator-vfx | sonnet | DONE | `m1-09-moves.md` |
| M1-10 | Avatar: gloves, jab x3 and big third clips, `Avatar` | animator-vfx | sonnet | DONE (clips published by MS-B1) | `m1-10-avatar.md` |
| M1-11 | Server: Carry, log hazard, Base, Income | scripter | opus | DONE (54/54) | `m1-11-server.md` |
| M1-12 | Real slice, `SetupStud`, `SetupBosses`, `SetupGloves`, stud proof strip | builder | sonnet | DONE (0 z-fight pairs) | `m1-12-slice.md` |
| M1-13 | `Audio` controller, envelope probe on the uploaded F, `SyncTest.lua` | audio-specialist | sonnet | DONE (B21 not triggered) | `m1-13-audio.md` |
| M1-14 | Client: Carry, Hazards, Base controllers | scripter | sonnet | DONE (carry half never on screen) | `m1-14-client.md` |
| M1-15 | UI stud proof at three UIScales, font weight, stroke | gui-designer | sonnet | DONE | `m1-ui-stud.md` |
| M1-16 | Check scripts and `CheckAll` (the Core loop gate) | scripter | opus | DONE (gate passes) | `m1-16-gate.md`, `m1-core-loop.md`, `m1-refusals.md`, `m1-burst-values.md`, `m1-nodelay.md`, `m1-checkall.md` |
| M1-17 | Chomp Frog in Studio: B4, B5, no re-pivot, tris | modeler-3d | sonnet | DONE (B4 atlas, B5 one FBX) | `m1-17-chomp-frog-studio.md` |
| M1-18 | First-session times, fight lengths, layout re-measure | game-designer | sonnet | DONE (floor times; notes to M2) | `m1-first-session.md` |
| M1-19 | Sync test at 60, 30, 15 | audio-specialist | sonnet | DONE (listen UNVERIFIED) | `m1-sync-test.md` |
| M1-20 | Moves, no-delay, gloves R15/R6 on real assets | animator-vfx | sonnet | DONE (look UNVERIFIED) | `m1-20-moves-avatar.md` |
| M1-21 | Stud checks of style guide section 13 | builder | sonnet | DONE (looks 10c to 10f UNVERIFIED) | `m1-stud.md` |
| M1-22 | Re-run `CheckAll` and `check_skin.py` | haiku | | Superseded: the M1-26b gate run (full CheckAll) and `check_skin.py` 0 hits cover it | `m1-26-fight-camera.md` |
| M1-23 | Close M1 | producer | sonnet | DONE | `m1-exit-checks.md`, this file |
| M1-24 | Pad Power number on the client, missing skin keys (added from the gate's findings) | scripter | sonnet | DONE (CheckSkin 13/13) | `m1-24-pads-and-keys.md` |
| M1-25, 25b | HUD below the top bar, RUN off the plate (added from the on-screen look) | gui-designer | sonnet | DONE (640 x 300 UNVERIFIED) | `m1-25-hud-inset.md` |
| M1-26, 26b | Fight camera and server fight spot (added from the on-screen look, two retries) | scripter | opus | DONE (looked at, PASS) | `m1-26-fight-camera.md` |
| MS-A1..A3 | Uploads and imports (audio, stud images, models) | main session | | DONE | `assets.md` |
| MS-B1 | Four avatar clips published under the group | main session | | DONE | `assets.md`, `m1-10-avatar.md` |
| On-screen list | Ten looks | main session | | PARTIAL: 6 PASS, 5 UNVERIFIED | `m1-onscreen.md`, `m1-exit-checks.md` |
