# M1: the Core loop gate, the checks that prove it, the skin check, and the exit checks mapped to owners

Gate (`vault/playbooks/autonomous-build.md`): **a play-mode script plays the loop end to end with no errors; the
server owns every result.** Quality pass: Function (this is the Function pass for the whole slice).

## The smoke-loop script, `studio/checks/CoreLoop.lua` (written by M1-16 scripter, opus, wave 4)
Runs in play mode through the Studio MCP from a play-mode call that requires the check as a temporary
ModuleScript loaded over the sync (pattern `long-check-scripts-loaded-over-localhost.md`); starts with the place
guard; prints `PASS`/`FAIL` lines and a final count; clears every hook it sets; saves the log to
`team/verification/m1-core-loop.md`. Driven by the real client through `AutoTap` and read through
`Profile.TestReport`; server state is read directly from the Systems' modules. It also accepts a `skin` argument
(`brickbrawl` or `stub`) so the skin check can reuse it.

Steps and what each asserts (server-side values read, never the client's):
1. **Join.** Plot 1 is the player's (`OwnerUserId`), the character is at `SpawnPoint`, `Zones.Pads` lists `z1_fixed`
   -> `z1_t1` with Power 25, `Zones.Clock` arrived. No errors in the output yet.
2. **Punch.** `Wipe`, `AutoTap = "good"`; stand on `BagPad`: `Punch.Schedule` arrives with ring 1.20 and cycle 1.81;
   one burst: a `Punch.Result accepted`, Power rises by exactly 4 x strength value (1) after the third beat
   applied, applied at 0, 0.213, 0.401 s (+/- 20 ms on the server clock).
3. **Burst.** With `AutoTap = "perfect"` Power rises by 8; with `"miss"` no burst, no Power, the next ring 0.61 s later.
4. **25 Power.** `SetPower 24` then one Good burst: Power >= 25; `Zones.Pads` number is "green" for the player's
   ratio (band `easy`/`fair`, computed by the check from the same `Config.Fight.BANDS`).
5. **Fight.** `SetPower 25` (exactly), move into the ring, `Fight.Start`: `Fight.State started` with the right band (Power 25 against the frog's
   25 is r = 1.0, `fair`, 110/45 ms), health 250 (10 x 25), hearts 3. Three Good bursts at equal Power: damage per
   punch 25, 25, 50 (100 a burst): after burst 2 health is 50, in burst 3 punch 1 leaves 25 and **punch 2 empties
   the bar**, so assert `won = true` on burst 3, punch 2, punch 3 sends nothing and deals nothing (the B22 path is
   the normal path at equal Power), then `Fight.State win` and `Zones.PadBeaten backIn = 10`. The check sets only the
   client's reported grade; it never sends a win, and it asserts the server's health numbers beat by beat.
6. **Carry.** `Carry.State carrying`, speed 12. Walk the character onto the log's path with `LogForce = "hit"`:
   state `dropped`, pushed back about 6 studs (4 to 8), `graceEnds` ~5 s ahead; `Carry.Grab` -> `carrying` again.
7. **Place.** At the plot, `Base.Place` on spot 1: `Base.State` shows it, carry is `none`; a second place on the
   same spot is refused (no state change).
8. **Earn and collect.** Advance `ClockOffset` by 30 s: the pad shows 30 x $1 on the client's computation; step
   on `CashPad_1`: `Base.Collected` amount 30 (+/- 1), cash += 30 on the server.
9. **Server authority asserted at each step:** the check records, for Power, damage, win, drop, place and cash,
   the module-level value that changed and the remote that carried it, and fails if a result changed without a
   server-side cause (it also attempts the forged versions in `Refusals`, below).
Pass = all PASS, 0 FAIL, 0 errors or warnings from `[HFB]` code in the output.

## The other scripted checks (M1-16, same wave, same style)
- **`Refusals.lua`:** a report faster than `CYCLE x 0.8`; a bag report off the pad; a fight report with no fight; a
  fight started while carrying; started outside the ring; started on the 5 s cooldown; a tap during a burst
  (ignored, not refused, no penalty); a `Base.Place` on a spot that is not the player's, on a taken spot, out of
  range, when not carrying; malformed payloads (wrong types, NaN, huge numbers, missing keys) to every c2s remote;
  the rate limits; the stall rule; the `Profile.TestReport` ignored when not Studio (simulated through a flag).
  Each case asserts no state changed.
- **`BurstValues.lua`:** Good = 4 punches and Perfect = 8, times; the Miss restart 0.61 s; cycles 1.81 and 1.11 s;
  fight tap counts at r = 0.5, 1, 1.5, 2, 3, 5 (all-Good ceil(2.5 r) = 2, 3, 4, 5, 8, 13; all-Perfect ceil(1.25 r)
  = 1, 2, 2, 3, 4, 7) by setting Power so r takes each value; windows per band; B22 on punch 1 and 2.
- **`NoDelay.lua`:** Misses and big husses back to back at Speed 10 (`SetSpeed 10`, `AutoTap = "mix"`): every ring
  starts on schedule (client ring log), and a reaction still running is cut by the next result (BossMoves log).
- **`CheckAll.lua`:** `CheckSync` -> `CheckSkin` parts 1 and 2 -> `CoreLoop` -> `Refusals` -> `BurstValues` ->
  `NoDelay`; one summary table in `team/verification/m1-checkall.md`.
- **Short calls:** each play-mode call stays short (the MCP has a time limit); long checks are split into calls.

## The skin check (built by M1-01, run by M1-22 haiku and by `CheckAll`)
1. `python tools/check_skin.py`: scans `src/` outside `Skins/` (and `Skins/stub` is exempt) for `rbxassetid`,
   `Color3.fromRGB`/`fromHex`, hex colour literals, and the creature, zone, hazard and product names the active
   skin holds (it reads the names from `Skins/brickbrawl/Names.lua`, the 36 creatures, 6 zones, 6 hazards, 19
   products as far as they exist at M1; the full 36/6/6/19 is checked at M3). Output: a count and a file list; 0 to pass.
2. `studio/CheckSkin.lua`: sets `HFB_ForceSkin = "stub"` and runs `CoreLoop` with it (punch, fight, carry, place,
   collect pass with the grey boxes); clears the hook. Part 3 (a save made under the real skin loads under the stub)
   is M2.

## The exit checks, each mapped to its owner and its evidence file (build plan, M1)
| # | Exit check | Owner (task) | Evidence |
|---|---|---|---|
| 1 | Gate "Core loop": loop end to end, server owns every result | M1-16 (script), M1-22 (re-run) | `m1-core-loop.md` |
| 2 | Refusals (fast taps, wrong place, carrying, tap in a burst, wrong spot) | M1-16 | `m1-refusals.md` |
| 3 | Good 4, Perfect 8 at 0 / 0.213 / 0.401; Miss no burst, restart 0.61 s; cycles 1.81 / 1.11; fight tap counts | M1-16 | `m1-burst-values.md` |
| 4 | The sync test at 60, 30, 15 fps, 20 bursts each | M1-13 (script), M1-19 (run) | `m1-sync-test.md` |
| 5 | Envelope probe on the uploaded F | M1-13 (needs MS-A upload) | `m1-envelope-probe.md` |
| 6 | No fight move delays the ring | M1-16 (script), M1-20 (run, look) | `m1-nodelay.md` |
| 7 | Skin check parts 1 and 2 | M1-01 (built), M1-22 (run) | `m1-skin-check.md` |
| 8 | First-session times measured, against the brief | M1-18 game-designer | `m1-first-session.md` |
| 9 | Layout's M1 check: bag to gate, run to fixed pad, carry home with and without Fast Carry, sight line over the 4-stud wall | M1-05 (greybox), re-measured by M1-18 on the real slice | `m1-greybox.md` |
| 10 | Style guide section 13 settled (normal-map direction, Color tint, tiles line up, stud depth at quality 1/5/10, 1-stud tile at distance, TileSize under UIScale and corner and the Huss button, Montserrat Black weight, boss atlas vs per-role (B4), Chomp Frog's groups animate without re-pivoting, upload size and moderation of tiles, jab rhythm scripted half, `UIStroke` at each scale) | M1-21 (stud items), M1-15 (UI items), M1-17 (boss items), M1-20 (moves, jab) | `m1-stud.md`, `m1-ui-stud.md`, `m1-chomp-frog/`, `m1-nodelay.md` |
| 11 | On-screen looks (list in `m1-main-session.md`) | main session | `team/verification/m1-onscreen.md` |
| 12 | Quality passes: Function only; each M1 feature's later passes are M3 to M5 | producer | board, "Quality" column |

## Measured by the game-designer (M1-18, sonnet, wave 4, `studio` lock)
With the `AutoTap` hook using a typical player's mix (45% Perfect, 45% Good, 10% Miss) and a perfect player, from a
wiped session on plot 1, a script times: first punch, first Perfect, 25 Power, first fight started, first boss
beaten, first boss placed, first collect, against the brief's targets (6, 10, 16, 29, 35, 52 s; 1:22 collect). The
brief's run and carry numbers are by plot (plot 1: 11.4 s run, 15.2 s carry); the script reports the greybox's
real walk time. A difference of more than 10% goes into the report with a proposed table change; tuning waits for
M2. It also reports fight lengths for the six tap counts of check 3 in seconds.

## Not asked for (do not build)
A UI for the checks; a leaderboard of times; funnel events (M2 builds the 12 server events); any balance change;
coverage of anything outside the slice.
