# M2-11: hazards, carry, base, income, upgrades (scripter, opus, 2026-11-26)

Brief systems 6 to 9; contract `requirements/m2-contract.md` C, C2, D with `[M2-02 M1, M5, M7, M8]`. Quality pass: Function.
Game repo, nothing committed.

## Files
- `src/ReplicatedStorage/Shared/Hazards.lua`: all six hazards as pure functions of the server clock (`volumes`, `hitsId`,
  `inStripId`, `clearWidth`, `lavaTiles`, `cactusAt`, `anchorOffset`, `iceOffset`, `meteorAt`, `toWorld`); M1 log API kept.
- `Config/Hazards.lua`, `Carry.lua`, `Base.lua`, `Income.lua`, `Upgrades.lua`: the brief's numbers plus TEAM CALL M2-11-1.
- `Systems/Hazards.lua` (six hazards, drop + 6-stud push, small push), `Carry.lua` (origins fight/crate/spot/stolen, movement
  check, base confinement, Fast Carry), `Income.lua` (padCash/padStamp, 2 h cap, rebirth and 2x Cash), `Base.lua` (17 spots,
  place, pick up, swap, sell, crate, GrantBoss hook, lock seam), new `Upgrades.lua` (Boss.Upgrade to 20).
- `studio/BuildHazards.lua`: stand-in hazards 2..6 in each throat and spots 11..17 on every plot. Run after BuildSlice + BuildStrip.
- `studio/checks/Hazards.lua`, `Base.lua`, `Upgrades.lua`.

## What ran (Studio MCP, `studio` lock as `scripter-hazardsbase`, released)
Edit mode: `DevSync()` sync; `run("BuildHazards.lua")` -> **11 PASS, 0 FAIL** (one model per hazard id in its throat, 7 spots +
7 pads on Plot1, no overlaps, ZFIGHT 0 pairs over 22 built boxes). `HFB_CheckAllMode = install` + CheckAll, then Hazards, Base,
Upgrades added to `TmpChecks` from the sync. Each row is one `run_script_in_play_mode` (start_play).

| Gate row | Check / phase | Result | What it shows |
|---|---|---|---|
| S6 | Hazards a | 28 PASS, 0 FAIL | six models registered; each path against the brief (log 30/15 free, cactus 14 studs/s every 6 s within +-14, anchor covers the middle 24, ice waits at -13 and slides 20/s, lava 0.8 glow + 0.6 erupt per tile, never more than 2 erupting, meteor r 14 lap 4 s); a way through at every 0.05 s and every stud of the band (narrowest longest gap: log 15, cactus 14, anchor 16, ice 13, lava 12, meteor 15); tolerance 0.9 into a shape = no hit, 1.1 = hit, all six |
| S6 | Hazards b | 27 PASS, 0 FAIL | each of the six drops a carried boss on the server, pushes 6.00 studs along the lane, WalkSpeed 16, graceEnds +5.00 s, dropPos where the carrier stood; grab (wrong uid 'uid', right uid 7 studs away -> carrying); not grabbed in 5 s -> gone, nothing in the profile; non-carrier small push; LogForce clear 6 s never hit; LogForce hit drops at once; a stolen carry ends instead of dropping (listener why = hazard), Grab refused 'state' |
| S6 | Hazards c | 8 PASS, 0 FAIL | carry speed 12, 16 with Fast Carry (PassOwned); a 30-stud teleport pulled back to 0.00 studs; 30 studs/s in small steps held to 17.0 studs (the window rule); a real 2.2 s MoveTo walk (23.2 studs) not pulled back |
| S7 | Base a | 36 PASS, 0 FAIL | 10 / 12 / 15 / 17 spots; place (uid, level 1, pad 0, Result ok, FirstBossPlaced), glow; duplicates; refusals taken / locked spot / range / 7 malformed with nothing changed; pick up keeps the boss saved on its spot, pad 60 stays and does not fill; moved to spot 4 collects the old pad's 60; sell +$40 inside, 'range' outside; swap sells the placed one ($20 + pad) and places the carried one; crate: take out (stays in the crate), cannot leave the base, a lost crate carry leaves it in the crate, placed with uid and level 3 (Zone2BossPlaced); steal lock seam refuses Pick Up, Swap, Place, Upgrade 'locked'; spots full -> 'full'; a picked-up boss whose carrier dies is back on its spot |
| S8 | Base b | 14 PASS, 0 FAIL | income 1/s from the stamp; walk onto CashPad_1 collects $30 (FirstCashCollected); whole seconds; cap 7,200 at 9,000 s; level 5 x2; 2 rebirths x2; 2x Cash x2 (Base.State income 8/s); a future stamp pays 0; authority: every cash change has a collect behind it |
| S9 | Upgrades a | 18 PASS, 0 FAIL | the brief's table (x1.00..x5.75; 30, 39, 50.7->51, 85.7->86, 318, 1,181, 3,374; cap); sum 14,519.2 exact, 14,521 in whole-cash steps; Frog $30/$39/$51; 'cash' refusal; upgrade settles the pad at the old level first; Base.State level/income/nextCost; bought-cash rule (cash 21, bought 21); levels 3->20 each spend exactly the cost; 'cap', 'range', 'notYours', 'bad', carried 'state'; level travels with a pick up and move |
| M2-26 | Base c (scripted run) | 4 PASS, 0 FAIL | see below |

Regression on the M1 checks my files touch: **Refusals b 32/0; CoreLoop b 36/0** (one earlier run failed on my `Income.onPad`
signature change, fixed by accepting the M1 form; one run's fight never started, the 6 Fight.Start presses not accepted, which is
upstream of these files, and passed on the rerun). **CoreLoop a 20/2**: verbatim
`FAIL CoreLoop/a 2 Power 1, 2, then 4 after the third beat (4 x strength value 1) | 2,4,8` and
`FAIL CoreLoop/a 3 Perfect: Power +8 (2/2/4) | 4/4/8, power 8 -> 24`. These are bag values doubled by the Studio account's real
2x Power pass (CoreLoop doesn't set PassOwned off; the M2-10 lesson). Not in M2-11's files; for M2-28.

Cleanup: TmpChecks and the probe removed, Workspace attributes only `HussForBosses`, mode stop. The 19 BuildHazards pieces stay in
the place: **the manager must save the place** (or rerun `BuildHazards.lua` after BuildSlice + BuildStrip).

## Scripted income run (M2-26)
Plan (a stand-in for hand play): a boss home every 35 s in zone 1 (0:52 to 3:40), 53 s in zone 2 (to 15:00), 75 s in zone 3 after;
tiers 1, 2, 1, 3 in turn; every 10 s collect all pads and buy upgrades paid back within 10 minutes; a full base swaps out the
lowest earner. No Strength, passes or rebirth; no Power gating. All real server calls on ClockOffset time.

| Minute | Income/s | Bosses | Brief target |
|---|---|---|---|
| 3 | $11.75 | 4 (z1, levels 2-4) | $5 |
| 10 | $340.50 | 10 (z2 mostly, levels 6-8) | $80 |
| 30 | $3,630 | 10 (z3, level 8) | $800 |

The run is 2.4x to 4.5x the targets because it reaches zones 2 and 3 on a schedule without Power. Cash piles up ($1.42 M unspent at
minute 30) once the payback rule stops upgrades at level 8. M2-26 should measure it with Power gating (AutoPlayer).

## Not checked / on-screen (UNVERIFIED)
- Nothing drawn yet: hazard motion and the 0.6 s warning, ghost spots 11 to 15, spots 16 and 17 hidden without the pass, the crate
  count, carried spot shown empty with its pad cash (M2-12).
- `Profile.Notice spotsFull` and `spotsFullOffer` reaching the client (the server-side refusal 'full' is checked).
- Leaving while carrying a crate or spot boss: covered by code (`Session.onLeaving` ends the carry before the final save; the
  profile already holds the boss) but not run with the Leave/Rejoin hooks.
- Remotes fired from a real client for PickUp, Swap, Sell, TakeCrate, Boss.Upgrade (the handlers are one line into the functions
  checked; M2-12/M2-13 send them).

## M2-11b follow-ups from M2-15 (scripter, 2026-11-26)
- **Server slow seam for the Iron Grip stagger.** `Carry.setSlow(player, factor, seconds)` in `Systems/Carry.lua`: WalkSpeed =
  carry speed x factor until `os.clock() + seconds`. factor must be in (0, 1); NaN, 0, >= 1 or seconds <= 0 clear it. A later call
  replaces the earlier one; the carry ending clears it. The movement check keeps the unslowed `Carry.speed`. `Carry.walkSpeed(p)`
  is the speed now, and `Carry.State.slowSpeed` is sent while a slow runs. M2-15: call
  `Carry.setSlow(thief, Config.Steal.STAGGER_SLOW, Config.Steal.STAGGER_S)` at the stagger. M2-16: stop slowing the client yourself
  and read `slowSpeed` for the look only.
- **A pending stolen boss cannot be sold or swapped away.** In `Systems/Base.lua`, `trySell` (a picked-up boss) and `trySwap` (the
  placed boss) refuse with `locked` while `Data/Transfer.isPending(player, uid)` is true. That is while the thief's arrival is still
  waiting for the owner's write. Pick Up and moving the boss stay allowed.
- **Re-run** (lock `scripter-hazardsbase`, released; the place was clean after, attributes only `HussForBosses`):
  - BuildHazards 11/0.
  - Hazards a 28/0, b 27/0, c 11/0 (+3 rows for the slow).
  - Base a 37/0 (+1 row: pending, with `Transfer.isPending` stubbed for one uid), b 14/0, c 4/0 (same income figures).
  - Upgrades 18/0.
  - Steal a 54/0.
  - None of these checks reaches `Shop.prompt`; all 10 passes are forced with `PassOwned`.

## M2-27 MF2 fix (scripter, 2026-11-26)
- Problem (`audits/m2-27-exploit-review.md` MF2): a pending stolen boss sits in the thief's crate. The thief could take it out and
  sell it, because Sell only refused pending bosses picked up from a spot.
- Fix in `Systems/Base.lua`:
  - `trySell` now refuses a pending uid (`Transfer.isPending`) for every origin, as `locked`.
  - `tryTakeCrate` refuses a pending uid as `locked`.
  - Swap-away of a pending placed boss was already refused (M2-11b).
- New check rows in Base a: crate take-out refused while pending; a crate carry's Sell refused while pending, with the crate and
  cash unchanged; once the boss is no longer pending it can be taken out.
- Re-run (lock `scripter-hazardsbase`, released; the place was clean after):
  - BuildHazards PASS.
  - Base a 39/0, b 14/0, c 4/0.
  - Steal a 54/0.
