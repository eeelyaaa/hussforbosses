# M2 gate "Systems": one passing check per row (producer, 2026-11-25)
Gate (`vault/playbooks/autonomous-build.md`): every system in the brief has a passing check; data saves and loads; the first session runs
from a fresh profile. Owner of the wiring: M2-28 (scripter, sonnet) in `studio/checks/CheckAll.lua` and `Gate.lua`; the report is
`verification/m2-gate.md` (PASS, FAIL, UNVERIFIED counts). Evidence names are `verification/m2-<task>-<name>.md`.

## Scripted rows (one passing check each)
| # | Row | Task | Check file |
|---|---|---|---|
| S1 | System 1: untimed, Good, Perfect, Miss values; windows; rate (P3) | M2-06 | `Punch2` |
| S2 | System 2: buy Strength (30) and Speed (10), costs, six bag tiers, Auto Punch and Perfect Auto Punch rules | M2-10 | `Bag` |
| S3 | System 3: Power only rises, never spent; milestones | M2-10, M2-26 | `Bag` |
| S4 | System 4: fight ratio, band, health, hearts, B22, win writes zones beaten, loss rules | M2-06, M2-10 | `Punch2`, `Zones` |
| S5 | System 5: 6 zones, pads, rolls, 45 s timers, per-player beaten, patrol | M2-10 | `Zones` |
| S6 | System 6: six hazards, carry speed, drop, grab, Fast Carry | M2-11 | `Hazards` |
| S7 | System 7: spots, place, pick up, duplicates, sell, swap, crate | M2-11 | `Base` |
| S8 | System 8: income from stamps, 2-hour cap, collect | M2-11 | `Base` |
| S9 | System 9: boss upgrades to 20 | M2-11 | `Upgrades` |
| S10 | System 10: stealing, shield (stealing and attacking sets below) | M2-15 | `Steal`, `Shield` |
| S11 | System 11: offline earnings at 30 s (nothing), 10 min, 3 h (capped 2 h a pad) | M2-14 | `Offline` |
| S12 | System 12: rebirth reset and kept lists | M2-14 | `Rebirth` |
| S13 | System 13: shop, receipts, spin | M2-18 | `Robux`, `Spin` |
| S14 | System 14: saving set | M2-09 | `Saving` |
| S15 | Saving: save, leave, rejoin same profile; locked profile refused; shutdown saves; version bump migrates; content by id | M2-09 | `Saving` |
| S16 | Stealing: hold cancelled by moving or the owner's punch; teleport or over-speed drops; punch returns it; steal keeps level and mark; uid never in two profiles even with a forced error between the writes; shielded base pushes out; bought boss: working Steal prompt while both flags true, greyed and refused when a flag is false or the call fails; earned boss stays stealable | M2-15 | `Steal`, `Policy` |
| S17 | Robux: same purchase id granted once; cash pack amount and stale key refused; 100,000 spin rolls within tolerance; screen list from the same table; zone picker from zones beaten and "Beat a boss first" when empty; restricted hook removes spin; no prompt during fight, carry, alert; never two prompts; Perfect Auto Punch offered only to Auto Punch owners, works for a web buyer | M2-18 | `Robux`, `Spin` |
| S18 | Attacking set: Quick Hands halves the hold; Iron Grip needs two hits in 10 s, not against hazards, falls or the shield; Shield Breaker refusals, 15 studs, stored charge when late, used free next, kept through rebirth | M2-15 | `Shield` |
| S19 | Rebirth: reset and kept lists exact; buyer's bosses back lowest first, the rest crated, pad cash cleared; stolen-bought reset, stolen-back kept; cash = bought-cash rule through buy, earn, spend, rebirth; zones beaten survive | M2-14 | `Rebirth` |
| S20 | Bought mark: only Spin and Starter Pack set it (source and buyer); no remote writes it or `boughtCash`. **Code read: PASS (M2-27, 2026-11-26, paper; unchanged by the re-check): marks created only in `BoughtMark` (Spin) and the Starter Pack op inside `recordPurchase`, moved unchanged by Transfer/Base/Rebirth; `boughtCash` raised only by `ops.addCash(.., true)` in the cash-pack and Starter Pack grants; no remote touches either; `audits/m2-27-exploit-review.md`.** The `Rebirth`/`Robux` checks still run it | M2-14, M2-18, M2-27 | `Rebirth`, `Robux` |
| S21 | First session: fresh profile reaches `FirstBossUpgraded` and `Zone2BossPlaced`; 12 events once, in order; arrow gone; offer once | M2-21 | `FirstSession` |
| S22 | Six bosses: groups and pivots named exactly; one set of offsets for smallest and largest of a body type; triangle counts reported | M2-25, M2-ART | `BodyTypeExtremes` |
| S23 | Skin check, all three parts (part 3: a save under brickbrawl loads under stub); stub CoreLoop re-run at M2 start | M2-09, M2-29 | `SkinCheck3`, `CheckSkin` |
| S24 | P1 label scan clean; P7 stud distance check; P3 and P4 checks | M2-05, M2-04, M2-07 | `check_labels.py`, `StudDistance`, `FightAngle` |
| S25 | Exploit review of the contract (before B, C) and of the code (after) has no must-fix. **Contract half: PASS (M2-02, 2026-11-25): 10 must-fix found and applied to `m2-contract.md` `[M2-02 M1..M10]`, 11 should-fix routed; `audits/m2-02-contract-review.md`.** **Code half: PASS (M2-27 re-check, 2026-11-26, paper): M2-02 M1..M10 landed; M2-27 MF1 (M2-09, Saving 34/0) and MF2 (M2-11b, Base 39/0) fixed, SF1..SF4 fixed; no must-fix open; two residual notes R1, R2 for M5; `audits/m2-27-exploit-review.md` "Re-check".** | M2-02, M2-27 | review files |
| S26 | Measured by the game-designer: Power a second at Speed 1 and 10, fight lengths and win rates per band, income at 3, 10 and 30 minutes, time to zone 2, against the brief's tables | M2-26 | `verification/m2-26-curves.md` |
| S27 | The M1 CheckAll still passes (30 PASS) | M2-28 | `CheckAll` |

## On-screen rows (main session, `computer` lock; phone size; recorded or `UNVERIFIED`)
O1 PERFECT floats above the button; the fight camera angle at 874 x 402 and 640 x 300 (M2-08, M2-07).
O2 The odds list on the Spin screen before any Buy or Spin button is active (M2-20).
O3 The rebirth confirm's wording with the player's numbers (M2-13).
O4 The steal alert with and without the BOUGHT tag; the greyed "Can't be stolen" prompt (M2-17).
O5 The six bosses' renders beside `creatures.png`, same angle and order (M2-24); each boss in a fight at the camera (M2-22).
O6 Pad numbers and world labels shrink with distance; the stud at 5, 40, 100 studs (M2-05, M2-04).
O7 Two real Studio clients: gloves and punches seen by the second, a respawn while carrying (M2-16).
O8 Real key, touch and gamepad presses (the M1 carryover) (M2-07).

## Gate rule
A milestone with open must-fix findings is not done. Anything not looked at is `UNVERIFIED` on the board. M2 closes with
`manager-todo.md` "look at": the first six bosses.
