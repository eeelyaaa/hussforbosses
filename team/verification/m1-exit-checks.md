# M1 exit checks (producer, M1-23, 2026-11-25)

Source of the checks: `pack/build-plan.md`, M1 "Exit checks"; owners and evidence map: `requirements/m1-core-loop-gate.md`.
Strict reading: a check that ran only by script, where the plan asks for a look or a listen, is PASS for the script
part and a separate UNVERIFIED line for the look. Nothing here was heard by anyone; sound is judged only by the manager.

## Gate result: "Core loop" PASSES
`CoreLoop` passes in play mode (a 22 + b 36, and under the stub skin 22 + 36) and the server owns every result
(Power, damage, win, drop, place, cash; each carried by its remote). Latest full `CheckAll`: `m1-26-fight-camera.md`,
M1-26b "Gate" section: CheckSync 8/0, CheckSkin 13/0, Refusals live 6/0, a 19/0, b 32/0, CoreLoop a 22/0, b 36/0,
BurstValues a 31/0, b 26/0, NoDelay a 9/0, no `[HFB]` warning; `check_skin.py` 0 hits; `check_guard.py` 0 unguarded.
Not re-run in that final pass: the two stub-skin CoreLoop calls (last run in M1-16, before M1-24 added the keys;
nothing skin-related changed since). The M1-22 haiku re-run is not on file: this file and M1-26b stand in for it.
`m1-checkall.md` is the older M1-16 summary (2 FAIL, since fixed by M1-24).

## The checks

| # | Exit check | Status | Evidence | Note |
|---|---|---|---|---|
| 1 | Gate "Core loop": loop end to end, server owns every result | PASS | `m1-core-loop.md`, `m1-16-gate.md`, `m1-26-fight-camera.md` | Scripted, real client through `AutoTap` |
| 2 | Refusals: fast report, wrong place, no fight, carrying, ring, cooldown, tap in a burst, wrong/taken/far spot, malformed payloads, rate limits, `TestReport` outside Studio | PASS | `m1-refusals.md` (6 + 19 + 32, 0 FAIL) | Each case asserts no state change |
| 3 | Burst values: Good 4, Perfect 8 at 0 / 0.213 / 0.401; Miss no burst, restart 0.61 s; cycles 1.81 / 1.11; tap counts at r 0.5 to 5; windows per band; B22 | PASS | `m1-burst-values.md` (31 + 26, 0 FAIL); tap counts also in `m1-first-session.md` table 2 | |
| 4 | Sync test at 60, 30, 15 fps, 20 bursts each: F once per burst, three beats in order, none dropped, each within one frame | PASS | `m1-sync-test.md` | Worst lateness 16 / 32 / 66 ms (limits 20.7 / 37.3 / 70.7); F Play() 0.08 ms after t0. Avatar markers (clip-timed, within about 15 ms of the beats) and boss reactions (same call as each beat) counted |
| 4b | Sync test as seen and heard (F's peaks on the three contacts; a phone at 30/15 fps) | UNVERIFIED | `m1-sync-test.md` "Not covered" | Manager's ear and a real phone; fight phase run at 60 fps only; Perfect fight burst and a fight Miss not in the sync run |
| 5 | Envelope probe on the uploaded F; B21 | PASS | `m1-13-audio.md` section 2 | Off the beat -6 / +14 / +7 ms against the 20 ms rule. **B21 not triggered**; `Config.Punch.BEAT` unchanged; `F_BEAT_IN_FILE = {0.004, 0.237, 0.418}`. Evidence file is `m1-13-audio.md`, not the planned `m1-envelope-probe.md`. Analyzer path, one block (about 5 ms) of resolution |
| 6 | No fight move delays the ring (Misses and big husses at Speed 10; a running reaction cut by the next result) | PASS | `m1-nodelay.md`, `m1-20-moves-avatar.md` | All 23 fight rings 0.610 s; 88 moves, 31 cuts, each new move at once. The "2 losses, 1 lastHeart" was the check's buffer read, fixed |
| 6b | No-delay as seen (the cut reads clean in a real fight) | UNVERIFIED | `m1-20-moves-avatar.md` on-screen list | The overlay and Huss button were seen clear (`m1-onscreen/fight-camera-fixed.jpg`); the moves themselves were not watched |
| 7a | Skin check part 1: `python tools/check_skin.py` | PASS | `m1-26-fight-camera.md` (0 hits), `m1-16-gate.md` | The planned `m1-skin-check.md` was not written |
| 7b | Skin check part 2: `CheckSkin` and `CoreLoop` under the stub | PASS | `m1-24-pads-and-keys.md` (CheckSkin 13/13), `m1-core-loop.md` (stub 22 + 36) | Stub CoreLoop last run before M1-24 (see gate note). Part 3 (a save made under the real skin loads under the stub) is M2, saving, not an M1 check |
| 8 | First-session times and fight lengths against the brief | PASS (measured) | `m1-first-session.md` | Cumulative times are a zero-reaction floor (23 to 74% under the brief); walks and carry within 2%; tap counts match the brief in every measured cell. Nothing needs a manager decision; tuning notes in `requirements/m2-carryover.md` |
| 9a | Layout: bag pad to the gate | PASS | `m1-greybox.md`, `m1-first-session.md` | 138.6 vs 139 studs (8.66 vs 8.7 s) |
| 9b | Layout: run to zone 1's fixed pad | PASS | same | 182.6 / 182.2 vs 183 studs (11.4 s) |
| 9c | Layout: carry home, with and without Fast Carry | PASS | same | Greybox 15.21 s (layout 15.2) at 12, Fast Carry 11.41 s (layout 11.4); real slice 15.40 / 15.47 s, Fast Carry not run (needs the pass) |
| 9d | Sight line over the 4-stud wall from the bag pad: number anchor and windmill | PASS (raycast) | `m1-greybox.md` | Anchor and windmill clear; the flat pad ring is hidden by design (the number is read over the wall). Flag for M3: the plot's own name board and bag frame are over 4 tall |
| 9e | The same sight line on screen, at phone size and desktop, and the camera pull-in at the bag | UNVERIFIED | `m1-greybox.md`, `m1-24-pads-and-keys.md` | The number was seen over the frog from the fight position (`m1-onscreen/pad-number-25.jpg`), not from the bag pad |
| 10a | Style guide 13: normal-map direction | PASS | `m1-stud.md`, `m1-onscreen.md` row 7 | Manager: "B on both"; `MaterialService.Stud` uses the flipped normal 95643445290942 |
| 10b | `BasePart.Color` tints the variant (route A holds) | PASS | `m1-onscreen.md` row 7 | Red, green, blue, gold cubes read their colours |
| 10c | Tiles line up across neighbouring parts | UNVERIFIED | `m1-stud.md` | Aligned by construction (StudsPerTile 4, corners on the grid); the seam shot was not taken |
| 10d | Tiles on rotated parts | UNVERIFIED | `m1-stud.md` | `RotatedWall` built (90 and 45 degrees), not looked at; no rotated parts are planned at M1 |
| 10e | Stud depth at quality levels 1, 5, 10 | UNVERIFIED | `m1-stud.md`, `m1-onscreen.md` | The level can be set from `run_code`; no captures at the three levels |
| 10f | The 1-stud tile at distance down the 40-stud strip, shimmer on a phone | UNVERIFIED | `m1-stud.md` | Wide shot only; the 40-stud and phone-size looks are owed; the lane has no stud yet (M3) |
| 10g | `TileSize` under `UIScale`, under the 4 px corner, and on the round Huss button | PASS | `m1-ui-stud.md`, `m1-onscreen.md` row 7 | Tile 12 / 16 / 26.4 px at 0.75 / 1.0 / 1.65; clipped to the circle at all three |
| 10h | Montserrat Black's weight name | PASS | `m1-ui-stud.md` | `Enum.FontWeight.Heavy` (900) selects Montserrat Black; `Black` is not an enum member. Heavy renders in the HUD seen; no side-by-side with the type board |
| 10i | Boss atlas vs per-role colour (B4) | PASS | `m1-17-chomp-frog-studio.md` | Atlas: 5 parts vs 23, same 6,584 tris, texel-exact colour (TEAM CALL M1-17a). Cream reads cream after the Color fix (seen) |
| 10j | One FBX per boss (B5) | PASS | `m1-17-chomp-frog-studio.md` | Merge Meshes off kept 5 MeshParts in one FBX (TEAM CALL M1-17c) |
| 10k | Chomp Frog's groups animate without re-pivoting | PASS (numbers) | `m1-17-chomp-frog-studio.md`, `m1-20-moves-avatar.md` | Pivot drift 0.0000; every Motor6D C0/C1 identical after all moves and rapid cuts; jaw chomps down (no sign flip). Look: row 11.6 |
| 10l | Upload size and moderation of the tile images | PASS | `m1-stud.md`, `m1-ui-stud.md`, `m1-onscreen.md` row 7 | 256 px maps 0.4 to 1.9 KB; the maps and the UI tile render in the place, so they loaded and passed (the moderation state itself is not visible to agents) |
| 10m | Jab rhythm: scripted half | PASS | `m1-sync-test.md` section 2, `m1-20-moves-avatar.md` | Hit markers within a frame of the beats on R15 and R6. Whether it reads as one hit is the manager's (4b) |
| 10n | `UIStroke` at each scale | PASS | `m1-onscreen.md` row 7 | Strokes follow `UIScale` (thicker at 1.65) |
| 11.1 | On screen: Huss button, ring, pips and GOOD pop, desktop | PASS | `m1-onscreen/bag-good-pop-desktop.jpg`, `bag-pips-desktop.jpg` | Pips fill, pops show, avatar jabs with the red gloves |
| 11.2 | On screen: HUD under the Roblox top bar, RUN clear of the plates (after M1-25, M1-25b) | PASS | `m1-onscreen.md`, `m1-25-hud-inset.md` | Two FAILs found by the look and fixed |
| 11.3 | On screen: the HUD at 874 x 402 and 640 x 300 in the device emulator, clear of jump and thumbstick | UNVERIFIED | `m1-onscreen.md` row 2, `m1-25-hud-inset.md` | The 640 x 300 read-back kept the desktop's 58 px bar and the plate touched the ring; with a phone's own bar it computes clear |
| 11.4 | On screen: Chomp Frog beside its picture, and beside an avatar for size | PASS | `m1-chomp-frog/z1_t1_vs_picture.png`, `m1-onscreen/fight-camera-fixed.jpg` | Accepted by the orchestrator's look after one redo; the avatar reads large up close (carryover) |
| 11.5 | On screen: the fight camera (frog whole, avatar clear) | PASS | `m1-onscreen.md` rows 5, 5 re-look, 5 re-look 2 | Failed twice (avatar hid the frog), fixed by the server fight spot (M1-26b); 32/32 by probe at two sizes |
| 11.6 | On screen: the frog's guard, a hit, the bite on a Miss, last heart, defeat and hop at the fight camera | UNVERIFIED | `m1-20-moves-avatar.md` on-screen list | Numbers only (lengths, jaw direction, cuts); not watched |
| 11.7 | On screen: gloves on an R15 avatar | PASS | `m1-onscreen.md` row 9 (part) | Red gloves seen on the jabs |
| 11.8 | On screen: gloves on an R6 avatar | UNVERIFIED | `m1-20-moves-avatar.md` | Welds and size read back (1.05 x head on four rigs) |
| 11.9 | On screen: studs close on wall, ground, tint cubes, button and panel at three scales | PASS | `m1-stud/stud-proof-sheet.png`, `m1-onscreen.md` row 7 | |
| 11.10 | On screen: one whole play-through: carried frog, the Rolling Log and its warning, drop and grab, the Place prompt and placed half idle, the cash pop | UNVERIFIED | `m1-onscreen.md` last row | Scripted end to end only; the carry half has never been on screen; two clients unlooked |
| 12 | Quality passes: Function only | PASS | board (archived), `board-archive.md` | Friction, Feel, Look and the manager's playtest are M3 to M5 by plan |

## Tally
41 rows: **30 PASS, 0 FAIL, 11 UNVERIFIED** (4b, 6b, 9e, 10c, 10d, 10e, 10f, 11.3, 11.6, 11.8, 11.10).
Every UNVERIFIED is a look or a listen; each has an owner and milestone in `requirements/m2-carryover.md` or is in the
manager's optional "play the M1 strip". No FAIL. Skin check part 3 is M2 and not counted.

## Not an M1 check, listed so it is not lost
Funnel events, a UI for the checks and any balance change were not asked for at M1.
