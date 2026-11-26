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

## M2: All version 1 systems, and the first six bosses (closed 2026-11-26)
Quality pass for all: Function only (Friction, Feel, Look in M3 to M5). Gate: 27/27 scripted rows PASS (`verification/m2-gate.md`, 11,000+ check lines). On screen (`verification/m2-30-onscreen.md`): O2, O3, O4, the boss review line, HUD, streaming, patrol, shutdown save PASS; O1, O5, O6, O7, O8 and the crate TAKE are UNVERIFIED and sit on the manager's M2 playtest list (`manager-todo.md`). Real purchases are UNVERIFIED until published (`verification/m2-18-robux.md`, "published game"). Questions Q1 to Q4 stay PROVISIONAL. Follow-ups: `requirements/m2-carryover.md`. Boss art: six bosses built; the other 30 wait for the manager's yes.

| Id | Task | Owner | Model | Depends on | Checks (gate) | Final status |
|---|---|---|---|---|---|---|
| M2-00 | P8: 19 items created and on sale, server size 8 (ids in `assets.md`; into `Config.Shop` by M2-01) | main session | n/a | none | read back in the dashboard | DONE |
| M2-ART | The other five pictured bosses in Blender (running; own files) | modeler-3d | sonnet | none | S22 (triangle counts), O5 | DONE (`verification/m2-six-bosses.md`; redo on opus accepted by look) |
| M2-01 | `m2-contract.md` completed; `Net`, `Ids`, `Config` skeletons, `TestHooks`, `test-hooks.md` (B8) | tech-lead | opus | none | contract and hooks list match | DONE (`verification/m2-01-contract.md`) |
| M2-02 | Review the contract before B and C are coded | qa-exploit-reviewer | opus | M2-01 | S25 | DONE (`audits/m2-02-contract-review.md`; 10 must-fix applied to the contract; code changes routed to M2-09, M2-11, M2-14, M2-15, M2-18, note to M2-06) |
| M2-03 | P2 and P3 numbers; curve method (`m2-punch-numbers.md`); manager-todo Q1 | game-designer | opus | none | numbers table | DONE (on paper; contract B4 needs M2-01's edit) |
| M2-04 L | P7 stud vanishing: cause and fix | builder | sonnet (tech-lead diagnoses after 2 fails) | none | S24, O6 | TODO |
| M2-05 | P1 world labels in studs; scan tool | gui-designer | sonnet | none | S24, O6 | DONE (`verification/m2-05-world-labels.md`; scan clean; phone-size shrink look UNVERIFIED, playtest O6) |
| M2-29 L | Re-run the stub-skin `CoreLoop` and skin parts 1 and 2 (carryover) | scripter | haiku | none | S23 | TODO |
| M2-06 | P3 server: untimed punch, rate rules, P2 values | scripter | opus | M2-01, M2-03 | S1, S4 | DONE, pass 1 (`verification/m2-06-punch-server.md`: Punch2 77/77 after M2-10, Refusals 51/51, BurstValues 57/57, CoreLoop 58/58, NoDelay 9/9 in play mode; M2-02 S6 fixed, TEAM CALLs M2-06-1 to -5) |
| M2-07 | P3 client, P4 fight camera, duplicate `defeat`, real input path | scripter | sonnet | M2-01, M2-03 (M2-06 contract B) | S24, O1, O8 | DONE, Function (`verification/m2-07-client-punch-camera.md`; FightCamera 16/0 + 16/0 after M2-07d; O1 on screen and O8 real presses UNVERIFIED, playtest) |
| M2-08 | PERFECT floats above the button; untimed pop | gui-designer | sonnet | M2-01 | O1 | DONE (Function; on-screen checks owed) |
| M2-09 | Data layer, lock, schema, migration, transfer, receipts, skin part 3 | data-engineer | opus | M2-01 | S14, S15, S23 | DONE (`verification/m2-09-data.md`: Saving a/b/c/d 50+20+9+20 PASS, SkinCheck3 5+7 PASS, 0 FAIL; Profile.Settings from a client UNVERIFIED; TEAM CALLs M2-09-1..8) |
| M2-10 L | Bag, Auto Punch, 6 zones, pads, rolls, zones beaten, patrol (P5) | scripter | opus | M2-01, M2-06, M2-09 API | S2, S3, S4, S5 | DONE, server (`verification/m2-10-bag-zones-patrol.md`; Bag 54/54, Zones 42/42 in play mode). Open: builder adds the 23 pads of the six-zone strip; Fight.fightSpot should use bossPos (M2-06 file); client auto ring + drawn patrol UNVERIFIED (M2-12); checks that read bag values must force `PassOwned` off (the Studio account owns the passes) |
| M2-11 L | Hazards (6), carry, base, income, upgrades | scripter | opus | M2-09 | S6 to S9 | DONE, server (`verification/m2-11-hazards-carry-base.md`: Hazards 28+27+8, Base 36+14+4, Upgrades 18, all PASS; regression Refusals b 32/0, CoreLoop b 36/0; CoreLoop a 2 FAIL = real 2x Power pass, not M2-11). Open: hazard visuals and ghost spots are M2-12; place save needed (BuildHazards pieces); income run at 3/10/30 min is 2.4-4.5x the brief's targets (M2-26) |
| M2-12 | Clients of A: pads, base, carry, hazards, boss visuals | scripter | sonnet | M2-10, M2-11, M2-05 | S5 to S8 | DONE (function; `verification/m2-12-client-a.md`). Open: zones 2-6 have no boss models in the place; crate TAKE trigger and on-screen looks UNVERIFIED |
| M2-13 | Plain screens A: boss, bag, away, rebirth, settings, toasts, numbers | gui-designer | sonnet | M2-01, M2-05 | O3 | DONE (scripted PASS 1929/0; on-screen O3 UNVERIFIED, see verification/m2-13-screens-a.md) |
| M2-14 L | Offline, rebirth, bought mark and cash | scripter | opus | M2-09, M2-11 | S11, S12, S19, S20 | DONE, Function (`verification/m2-14-offline-rebirth.md`: Offline a 20/0, b 9/0; Rebirth a 21/0, b 7/0, c 8/0; BoughtScan 2/0). On-screen: the away and rebirth screens with real payloads UNVERIFIED (main session) |
| M2-15 L | Wave B server: plots, stealing, shields, policy guard | scripter | opus | M2-02, M2-09, M2-11 | S10, S16, S18 | DONE (`verification/m2-15-steal-shield.md`: Steal a 54/0, b 24/0, c 8/0, Shield a 36/0, Policy a 18/0; two-client and on-screen checks UNVERIFIED for the main session; requests to M2-09, M2-11, M2-28 in the file) |
| M2-16 | Wave B client: steal, shield, watchers, respawn carrying | scripter | sonnet | M2-15 contract | O7 | DONE, Function (`verification/m2-16-steal-client.md`: client probe 20/20; two-client and on-screen checks UNVERIFIED) |
| M2-17 | Screens B: alerts, lock board, Break shield, confirm | gui-designer | sonnet | M2-01, M2-13 | O4 | DONE (function; O4 on-screen look owed) |
| M2-18 L | Wave C server: receipts, 10 passes, 9 products, spin, Starter Pack, policy for spins | scripter | opus | M2-02, M2-14, M2-15 | S13, S17, S20 | DONE, Function pass (`verification/m2-18-robux.md`: Robux a 57/0, b 22/0, c 18/0, Spin a 21/0; M2-27 SF2-SF4 fixed, BoughtScan 2/0; Shield a regression 1 FAIL for M2-15, row 12 needs the prompt stub); real purchases UNVERIFIED until published |
| M2-19 | Wave C client: shop and spin controllers | scripter | sonnet | M2-18 contract | S17 | DONE (probe 40/40) |
| M2-20 | Screens C: shop (19), spin with odds, offer, PAP row | gui-designer | sonnet | M2-13, M2-17 | O2 | DONE (Function; on-screen looks owed) |
| M2-21 | First-session arrow and the 12 funnel events | scripter | sonnet | M2-09, M2-10, M2-11, M2-18 | S21 | DONE, check PASS 28/0 (on-screen owed) |
| M2-22 L | Move sets for three body types and six signatures | animator-vfx | sonnet | M2-ART (look); schema check first | S22, O5 | DONE on box rigs (check passes); on-screen and mesh checks UNVERIFIED, see verification/m2-22-boss-moves.md |
| M2-23 L | Avatar's five other clips | animator-vfx | sonnet | none | O7 | TODO |
| M2-24 | Six bosses against `creatures.png` | art-director | opus | M2-ART, M2-22 | O5 | DONE (review; fix pass accepted by look and re-imported; `audits/m2-24-six-bosses-review.md`) |
| M2-25 L | One test boss per body type at smallest and largest tier; M1 boss notes | modeler-3d | sonnet | M2-ART, M2-22 | S22 | DONE (on-screen checks UNVERIFIED) |
| M2-26 | Curve measurements against the brief's tables | game-designer | opus | M2-10, M2-11, M2-14, M2-21 | S26 | DONE (`verification/m2-26-curves.md`, `studio/checks/Curves.lua`): bag Power/s within 1% of paper, but Speed 10 Good is -6.5% (FAIL: the client skips about 1 ring in 10 on a late Good, no server refusal; for the scripter, Ring/TestClient). Fight taps exact, seconds within 2 to 11%, heart rule as Q1. Income $3-6 / $91-188 / $3.0-5.5k at 3/10/30 min vs $5/$80/$800 (Q4, no tuning). Zone 2 3:33-4:33, zone 3 14:45-15:57 (brief 11:00). UNVERIFIED: rate rules under lag |
| M2-27 | Exploit review of A, B, C code | qa-exploit-reviewer | opus | M2-18 | S25, S20 | DONE (`audits/m2-27-exploit-review.md`; S25 and S20 PASS, no must-fix open; R1 and R2 to M5) |
| M2-28 L | Wire `CheckAll` and `Gate`; run; write `m2-gate.md` evidence | scripter | sonnet (opus if it fails) | all systems tasks | S1 to S27 | DONE (`verification/m2-gate.md`: 26 PASS, 1 FAIL S24 FightCamera stale vs patrol, 0 UNVERIFIED) |
| M2-32 L | Boss review line (the manager's ask): all imported bosses side by side in a row in the place, each looping its moves (guard, hits, signature, defeat...) with a 1 s break between moves, name plate in studs; avatar clips on an R15 and an R6 dummy at the end of the line. Built by a re-runnable `studio/` script, Studio-only (never runs in Live) | animator-vfx | sonnet | M2-22, six bosses imported (main session) | main session looks; the manager reviews | BUILT, UNVERIFIED on screen (`verification/m2-32-review-line.md`) |
| M2-30 | On-screen rows O1 to O8, recorded | main session (`computer`) | n/a | M2-28 | O1 to O8 | DONE for what can be looked at (`verification/m2-30-onscreen.md`: O2, O3, O4 PASS; O1, O5, O6, O7, O8 and crate TAKE UNVERIFIED, on the manager playtest list) |
| M2-31 | Board and state upkeep; manager-todo "look at: six bosses" | producer | sonnet | all | none | DONE (board closed 2026-11-26) |
