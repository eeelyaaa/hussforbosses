# Carryover from M1 to later milestones (producer, M1-23, 2026-11-25)

What M1's evidence marked for later, one line each, with owner and milestone. Nothing here changes the brief or the
pack; wording and number suggestions are for the manager to accept (the brief is the manager's words). Source file in
brackets, all under `verification/` unless noted. The M2 planner reads this first.

## Brief wording and tuning (M2, game-designer and producer; manager accepts)
| Item | Owner | When |
|---|---|---|
| "About six bursts" to 25 Power is 4 to 5 bursts (mean 4.7; 7.5 s from the first punch against the brief's 10 s). Suggest "about five bursts" and the 0:16 row 2 s earlier. No Config change [m1-first-session] | game-designer, manager | M2 |
| The first fight at typical grades is 3.5 to 5.0 s at r = 1; 5.4 s is the all-Good ceiling (measured 5.30). Suggest "about 4 to 5 seconds, 5.4 when every tap is a Good" [m1-first-session] | game-designer, manager | M2 |
| Cumulative first-session times read 23 to 74% under the brief only because the script has no reaction time: use them as a floor (first punch >= 1.6 s, first placed >= 40 s) and compare with the M2 funnel events' real human times, never tune to the script [m1-first-session] | game-designer | M2 |
| Good windows at r >= 2 are 60 / 45 / 35 ms: a +70 ms tap is a Miss there. Whether a phone player's real timing spread (touch latency, one 60 fps frame is 17 ms) can land Goods at r >= 2 is a human-playtest question; ask the manager at the first playtest, and read the funnel data [m1-first-session] | manager, game-designer | M2 funnel, M5 playtest |
| Not measured at M1: Fast Carry on the real slice, the other seven plots' walks (156 to 176 studs), the Rolling Log's hit rate on a human carrier (the natural log did not hit a straight walker), the first upgrade (1:27), Starter Pack, zone 2 [m1-first-session] | game-designer, builder | M2 (upgrade), M3 (plots, log) |

## Systems and checks (M2, scripter / qa-exploit-reviewer / data-engineer)
| Item | Owner | When |
|---|---|---|
| Skin check part 3: a save made under the real skin loads under the stub [m1-core-loop-gate requirement] | data-engineer, scripter | M2 (saving) |
| `defeat` is played twice per win, in the same frame (Fight controller and a second caller); `play` restarts the same move so it is invisible, but remove the duplicate [m1-sync-test finding 1, m1-20] | scripter | M2 |
| Watching clients (other players see a burst, boss reactions and the jabs) are M2 by TEAM CALL M1-P2; the second-client test of gloves and punches, and a respawn while carrying, were not run at M1 [m1-14, m1-20] | scripter, animator-vfx | M2 |
| Real key, touch and gamepad presses were never run (everything went through `Input.fire` via `AutoTap` and `AutoInteract`) [m1-16-gate] | scripter, gui-designer | M2 checks; phone in M5 |
| The 12 funnel events and the first-session funnel are M2's; the funnel feeds the Good-window and first-session questions above | scripter | M2 |
| Checks: warm up 4 s before timing any move; the AutoTap hook starts a fight itself when standing in the ring; the client clock offset settles only after about 3 s; SetPower while a bag burst runs gets the later beats. Keep each in the check scripts' headers (also in `lessons.md`) [m1-20, m1-16, m1-06] | scripter | every check from M2 |
| Re-run the stub-skin `CoreLoop` calls after any change under `Skins/` (last run before M1-24) [m1-26] | scripter, haiku | M2 start |
| The sync test ran the fight phase at 60 fps only; run a fight at 30 and 15, a Perfect fight burst (`hitPerfect`) and a fight Miss through the probe [m1-sync-test] | audio-specialist | M4 |
| The 3D copy of the burst sound for other players is M4 / not asked for [m1-04] | audio-specialist | M4 |

## Boss art and models (M2 six-boss pass, then M3; modeler-3d, animator-vfx, art-director)
| Item | Owner | When |
|---|---|---|
| Chomp Frog notes for the six-boss pass: the outer brow ends read like ear bumps; the eyes are set wide; nostril dots are a whole cube where the picture's are smaller [m1-chomp-frog, build-state] | modeler-3d | M2 |
| Triangle budget B6: Chomp Frog is 6,584 triangles against the Common budget of 600 (the picture wins, per the plan); gloves 1,544. Count after the first six bosses, measure with 136 placed bosses and 24 on pads on a weak phone, and raise the budget to what measures acceptable [m1-chomp-frog, m1-17] | modeler-3d, performance-optimizer | M2 count, M3/M5 measure |
| Atlas crispness at fight-camera distance (15 to 25 studs) and on a phone: no colour fringes or bleed (B4 risk, checked only in the desktop view) [m1-17] | modeler-3d, performance-optimizer | M3 |
| Moves in Body space for `hitBig` and `defeat` were not re-measured (`hitBig` showed the head 2.1 studs back, a designed knock-back); look at them on screen [m1-17, m1-20] | animator-vfx | M2 (first six) |
| One test boss per body type at the smallest and largest tier: the offsets fit a Common and a Mythic [style guide 13] | modeler-3d, animator-vfx | M2 |
| Fight-move reads on a phone-size capture; the placed boss flashes white on the thump (TEAM CALL M1-14d): judge on screen [m1-14] | animator-vfx, manager | M4 |

## Feel and look (M4, M5; animator-vfx, gui-designer, art-director)
| Item | Owner | When |
|---|---|---|
| The avatar reads large up close in the fight camera; a diagonal start puts the camera at the `MIN_DIST_H` floor (6.1 studs) with the avatar large at the lower left [m1-26, m1-onscreen] | animator-vfx, gui-designer | M4 Feel, M5 Look |
| The snap to the fight spot: does it read fine, or does it want a short slide (not built; new feel work) [m1-26] | animator-vfx | M4 |
| Contact markers are clip-timed (about 0 / 0.200 / 0.400 s) and the thuds beat-timed (0 / 0.213 / 0.401 s): up to 15 ms apart (11 ms early on marker 2 at 30 and 15 fps). Inside the 20 ms rule; whether it reads as one hit is the manager's ear [m1-sync-test] | animator-vfx, manager | M4, playtest |
| Sound still to judge by ear: F against the jabs; the soft swish on a bag Miss (none on a fight Miss: the boss wind-up cue is M4, coded but not run); the stand-in thuds are one bag tier; whether 01 A (x1.25) matches the level of 02 A when they alternate (thief punch, M2) [m1-13] | audio-specialist, manager | M4 listening page |
| Audio permissions: if a sound is silent in a published test, add the experience to the sound's permissions (ids in `manager-todo.md` item 7) | manager | first published test |
| Skull icon for "Near impossible" has no skin key (the icon set has none); add the key and the icon with the M3 icon set [m1-24] | gui-designer | M3 |
| The 640 x 300 HUD: the plate touched the Huss ring in a read-back that kept the desktop's 58 px bar; with a phone's own bar (about 36 px) it computes clear, so look in the device emulator at 874 x 402, 640 x 300, a notch phone [m1-25, m1-onscreen] | gui-designer | M3 build, M5 Friction |
| Montserrat Heavy (= Black) next to the type board; the UI stud tile at 12 px on a real phone and whether its 30% dark L is too busy under text (cheap fix: lower the L to about 20% in the art) [m1-ui-stud] | gui-designer, manager | M3, M5 |
| World sign text sizes on a phone (name board, bag sign, lock board) and the lock board's buttons at 44 px [style guide 13] | gui-designer, builder | M3 |
| Gloves on R6 in a live server, on avatars with accessories on the hands and scaled bodies [m1-10, m1-20] | animator-vfx | M4 |
| Easy and Fair share one colour (#6BE04A) per the style guide; check the pad number reads by word and colour together [m1-24] | gui-designer | M5 Friction |

## World (M3, builder, modeler-3d, art-director, lighting-specialist)
| Item | Owner | When |
|---|---|---|
| The manager's note: the zone lanes are walled corridors with high walls, voxel trees along the top, a different ground colour per zone in sequence, big mountains behind the walls. M1's lane is a flat open strip, so the M3 builder brief carries the note and the reference (`team/manager-todo.md`, "Your notes") | builder, art-director | M3 |
| The manager's note: the Rolling Log should look better. The M1 log is a plain 12 x 6 x 6 cylinder stand-in; its real look is a voxel log in the style guide's look with its warning (0.6 s) | builder, modeler-3d, animator-vfx | M3 / M4 |
| The plot's own name board and bag frame are over 4 studs tall in front of the bag pad, against the layout's "nothing over 4 studs" rule; plots 2 to 8 are not built. Windmill position (TEAM CALL M1-05-3) avoids it for plot 1 only [m1-greybox] | art-director, builder | M3 |
| Raycasts hit parts with `CanQuery = false` when `CanCollide` is on; code in the hub must exclude the fence and wall blockers by name or tag (contract B said CanQuery off) [m1-greybox] | builder, scripter | M3 |
| Stud looks not taken at M1: tiles across neighbouring parts, on rotated parts, at quality levels 1, 5 and 10, the 1-stud tile down the full lane at phone size (if noisy, a 2-stud ground variant); the lane has no stud yet [m1-stud] | builder, performance-optimizer | M3 |
| Sight line on screen from the bag pad at phone size, and the camera pull-in at the bag (greybox looks owed); the number's legibility over the wall at 874 x 402 [m1-greybox, m1-24] | builder, gui-designer | M3 |
| Fight spots near walls were not exercised (zone 1's pad has none in reach; the ray code ran and never hit): test on a zone with a wall near a pad [m1-26] | scripter, builder | M3 |
| Hazard looks against "always leaves a way through" and the 0.6 s warning, for all six [style guide 13] | builder, game-designer | M3 |
| Part counts and frame time of 136 placed bosses on the half idle: measure on a weak phone [style guide 13] | performance-optimizer | M3 / M5 |

## Housekeeping
- `studio/checks/FightCameraProbe.client.lua` is not wired into `CheckAll` (install by hand as in `m1-26-fight-camera.md`); wire it if the camera changes again.
- Evidence files not written under the planned names: `m1-skin-check.md` (see `m1-26-fight-camera.md`, `m1-24-pads-and-keys.md`) and `m1-envelope-probe.md` (see `m1-13-audio.md`).
- The hand-built-in-the-place list (marker, loader, imported meshes, uploaded clips) is in `build-state.md`; the manager saves the place (`manager-todo.md` item 2).

## Added 2026-11-25 from the manager's M1 playtest (see `decisions.md`, "the manager's decisions after playing M1"; these are the manager's words, so they are spec)
| # | Item | Owner | Milestone |
|---|---|---|---|
| P1 | World labels scale with distance (no constant-pixel BillboardGui over world objects); fix the pad number; scan the repo for any other | gui-designer + scripter | M2 |
| P2 | Ring a little quicker in general; timing a little easier | game-designer (numbers) + scripter | M2 |
| P3 | Untimed tap = one punch (bag +1; boss damage by Strength); timed = the three-punch burst, PERFECT floats above the button, more damage. Replaces "a Miss launches no burst" | game-designer, scripter (server), gui-designer, audio (single huss on an untimed tap: 02A/01A already uploaded), qa-exploit-reviewer (rate caps) | M2 |
| P4 | Better fight angle for the player (avatar reads large lower-left) | scripter + art-director look | M2 |
| P5 | Bosses patrol back and forth along their region; player walks up to start the fight | scripter, animator-vfx, builder | M2 design, M3 world |
| P6 | More intense huss animation and fighting | animator-vfx, audio-specialist | M4 |
| P7 | Stud texture vanishes and returns with distance: find cause, fix | builder + tech-lead | M2 |
| P8 | Create the 10 passes and 9 developer products by computer use at the brief's prices; set the server size to 8; most other dashboard setup | main session (computer use) | M2 start |
| P9 | Audio: upload everything at M4, the manager's yes covers the license agreement ticks | main session | M4 |
