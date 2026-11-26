# M2-26: the curves against the brief's tables (game-designer, 2026-11-26)

Gate row S26. Script `studio/checks/Curves.lua` (new; phases a, b, c), installed next to CheckLib with CheckAll `install`,
run one `run_script_in_play_mode` (start_play) per line, `studio` lock as `gamedesign-curves`, released; play stopped;
CheckAll `cleanup` left no TmpChecks and only the `HussForBosses` attribute. Every pass forced off by `L.begin`
(PassOwned), the Shop prompt stubbed. Code synced with DevSync first. No file in `src/` changed. All 21 play calls: 0
refusals in any legit run, 0 errors, 1 FAIL (Speed 10 Good, below).

Method: `m2-punch-numbers.md` section 6, scaled down to fit the MCP's play-call limit (a call over about 60 s times out
here, so each player ran 30 s once, not 60 s three times; the 3-run repeat is not done). Paper = `m2-punch-numbers.md`
sections 4 and 5 (P2/P3 numbers); brief = `pack/brief.md`.

## 1. Power a second on the bag (Strength 1, real client through AutoTap, 30 s after a 4 s warm-up)
| Speed | Player | Brief (M1 ring) | Paper (M2) | Measured | vs paper | Inside what the brief leaves open? |
|---|---|---|---|---|---|---|
| 1 | Good every ring | 2.2 (Auto Punch) | 2.41 | 2.396 (10 s run: 6 bursts) | -0.6% | yes |
| 1 | Perfect every ring | 4.4 | 4.82 | 4.798 (18 bursts) | -0.5% | yes |
| 1 | Mix 45/45/10 (client's mix misses, it does not click) | **2.98** | 3.25 | 2.93 (18 rings, one random sample; 1 SD = 11%) | -10%, inside noise | yes |
| 1 | Untimed, one click per ring | (none) | 0.60 | 0.600 (18) | 0% | yes |
| 1 | Mash, a click every 0.1 s | (none) | 0.60 | 0.600 (18 accepted, 0 refused) | 0% | yes |
| 10 | Good every ring | 3.9 (Auto Punch) | 3.92 | **3.665** (27 bursts), twice | **-6.5% FAIL** | see note |
| 10 | Perfect every ring | 7.8 | 7.84 | 7.796 (30) | -0.6% | yes |
| 10 | Mix 45/45/10 | **4.86** | 5.31 | 5.264 (28) | -0.9% | yes |
| 10 | Untimed | (none) | 0.98 | 0.999 (30) | +2% | yes |
| 10 | Mash | (none) | 0.98 | 1.000 (30 accepted, 0 refused) | +2% | yes |

Against the brief's typical column (2.98 at Speed 1, 4.86 at Speed 10, both on the M1 ring): the P2 ring gives +9% to +11%
(paper 3.25 / 5.31 with Misses, 3.31 / 5.39 with clicks). That follows from the manager's P2, not a tuning.
Mashing equals one click per ring at both Speeds: the server's one-report-per-ring rule holds, mashing never beats Good
(a quarter of it), acceptance 2 holds on the real client.

**The one FAIL (Speed 10, Good stand-in):** beats came every 1.02 s, but about one ring in ten the next beat came 1.53 s
later (seen 3 times in 30 s, both runs), with no refusal on the server, so the client sent nothing for that ring. Perfect
at Speed 10 and Good at Speed 1 show no gap. So it is on the client side, with a tap 70 ms late on a 0.41 s ring; the
cause is not found (TestClient or `Ring`). A human tapping late Goods at Speed 10 could meet the same skipped ring
("a click did nothing"). Not tuned (code, not Config): **for the scripter (owner of `Controllers/Ring` / TestClient)**, on
the board.

## 2. Fights (Chomp Frog, Power set for each r, Speed 1, real client; seconds = server `started` to end)
| r (band) | Paper all Good: bursts, s | Measured all Good | Paper all Perfect | Measured all Perfect | Paper untimed | Measured untimed |
|---|---|---|---|---|---|---|
| 0.5 (easy) | 2, 3.1 | 2, 2.90 (-6%) | 1, 1.5 | 1, 1.52 (+1%) | 5 clicks, 7.7, no heart | 5, 7.00 (-9%), win, 3 hearts left |
| 1 (fair) | 3, 4.6 | 3, 4.85 (+5%) | 2, 3.1 | 2, 2.77 (-11%) | 10, 16.0, no heart | 10, 15.50 (-3%), win, 3 left |
| 1.5 (hard) | 4, 6.4 | 4, 6.78 (+6%) | 2, 3.1 | 2, 3.19 (+3%) | loses after 3 | loss in 3.88 s, 0 left |
| 2 (very hard) | 5, 8.1 | 5, 8.52 / 8.72 (+5% / +8%) | 3, 4.8 | 3, 4.65 (-3%) | loses after 3 | loss in 3.67 s |
| 3 (brutal) | 8, 13.1 | stand-in cannot: its +70 ms tap is outside the 65 ms window (loss, 3 bursts landed) | 4, 6.4 | 4, 6.50 (+2%) | loses after 3 | loss in 3.90 s |
| 5 (impossible) | 13, 21.4 | stand-in cannot (55 ms window): loss, 0 bursts | 7, 11.4 | 7, 11.08 (-3%) | loses after 3 | loss in 3.88 s |

Tap counts match the paper in every cell the stand-in can play. Seconds are within 2 to 11% of the paper, without a
consistent direction: the paper counts the first ring from fight start, and the server adds the start and the frame
step. The heart rule (Q1 default) works as written: clicking wins Easy and Fair with no heart lost, and loses from Hard
up after three hearts.

**Win rates per band (stand-in mix 45/45/10, 2 fights per r):** r 1: 2/2 (4.94 s mean), r 1.5: 2/2 (4.71 s), r 2: 2/2
(5.68 s), r 3: 1/2 (the stand-in's Goods miss Brutal's window, so it plays as 45% Perfect and 55% Miss), r 5: not run
(the fight after a win would not start: `running`, a check-timing issue, not the game). These are too few fights to give
a rate. The exact odds for a fixed grade mix (3 hearts; damage 8 / 4 / 0 a tap):
| Grade mix (Perfect / Good / missed) | r 0.5 | r 1 | r 1.5 | r 2 | r 3 | r 5 |
|---|---|---|---|---|---|---|
| 45 / 45 / 10 (the brief's new player, at every band) | 99.8% | 99.5% | 99.2% | 98.7% | 96.7% | 91.2% |
| 30 / 45 / 25 | 96% | 93% | 89% | 84% | 69% | 43% |
| 15 / 35 / 50 | 74% | 60% | 46% | 35% | 13% | 2% |
"Much harder the further above you it is" therefore rests entirely on a player's grades getting worse as the windows narrow.
If a phone player kept 45/45/10 at every band, an r = 5 boss would fall 9 times in 10. Only the playtest settles this
(section 6.5's `offMs` shares per band). This is a playtest question below, not a change.

## 3. Income, zones and the first upgrade (phase c: the 30-minute run with Power gating)
What the run does, all on the ClockOffset clock: Power comes at 5.4 a ring (the brief's typical mix; measured 4.9 to 5.4
above) x Strength value / the cycle at the player's real Speed level. A boss is fought only when its r is 1 or less (a green
number), so zones open by Power as they must. The trip time comes from the base layout: walk 16 and carry 12 studs/s, 200
studs to zone 1's fixed pad, +120 a zone and +20 a pad, plus the fight's seconds and 4 s to place. The run never drops a
boss to a hazard, and rolling pads use the brief's odds with a seeded random. These are real server calls: place, swap,
collect, upgrade, Strength and Speed. Buying rule: Strength when affordable, Speed when it costs no more than the next
Strength, upgrades whose cost pays back within 10 minutes. Two policies:
- **half**: the player keeps bag time equal to trip time (the brief's own assumption, system 3: "about half the session at
  the bag").
- **greedy**: a trip whenever a green boss would add income, the bag otherwise.
`tools/econ_model.py` runs the same policy without Studio over 40 seeds for a spread. It is a cross-check only: its
greedy run reads lower at minute 10 than Studio's ($54 vs $104), and I did not reconcile the two.

| Measure | Brief | Studio, half, seed 0 | Studio, half, seed 1 | Studio, greedy, seed 0 | Model, half, 40 seeds (median, range) | vs brief | Inside what the brief leaves open? |
|---|---|---|---|---|---|---|---|
| Income at minute 3 | $5/s | $3 | $6 | $5 | $6.2 (3 to 10) | on target | yes |
| Income at minute 10 | $80/s | $91 | $188 | $104 | $150 (85 to 766) | **+14% to +135%** | the brief calls it "for sizing costs, unmeasured" |
| Income at minute 30 | $800/s | **$5,066** | **$5,522** | **$2,992** | $6,100 (3,388 to 12,551) | **3.7x to 6.9x** | same; changing it means income or prices: **not open** -> Q4 |
| Cash unspent at minute 30 | (none) | $174,517 | $364,889 | $125,332 | | | upgrades stop at level 8 (the 10-minute payback rule) |
| Power at minute 30 | 25,000 (zone 4) | 48,717 | 50,953 | 10,221 | 51,505 | half: ~2x | |
| First zone 2 boss placed | ~4:00, placed by 4:40 | 4:33 | 3:33 | 9:41 | 4:43 (3:29 to 6:00) | half: on target; greedy +2x | |
| First zone 3 boss placed | 11:00 (Power 2,500) | 15:57 | 14:45 | 18:48 | 12:40 | **+15% to +45%** | Power milestones are on paper; see Q4 |
| First zone 4 boss placed | 30:00 | 28:35 | 30:11 | not by 30:00 | 27:33 | on target (half) | |
| First upgrade | 1:27 | 1:51 | 1:59 | 1:22 | 1:16 | -6% to +37% (no reaction time) | yes |
| First Strength level | 1:32 to 3:40 | 4:33 | 3:33 | 3:10 | 3:14 | half run late by up to 53 s | yes |

What the numbers say:
1. **The time to zone 2 and zone 4 lands on the brief when a player trains half the time,** as the brief assumes. Zone 3
   comes 4 to 5 minutes late. The greedy player, who fills spots before training, reaches zone 2 at about 9:40.
2. **Income is far above the brief's sizing line from minute 10 on, in every run.** The cause is in the brief's own
   tables: by minute 30 a player at zone 3 Power holds 10 zone 2 and 3 bosses at level 8 (x2.75). Zone 3 pays $60 to
   $480 a boss at level 1, so $800 a second is about 10 zone 3 Commons at level 1 with no upgrades, which no run looks
   like. M2-11's $3,630 (no Power gating) was not the cause: with real gating it is $3,000 to $5,500.
3. **Cash piles up** ($125k to $365k unspent at minute 30) after the payback rule stops upgrades at level 8. A human
   would likely upgrade further, which raises income again. There is no sink between upgrades and the next Strength level.
4. The first-session floor (zero reaction) matches M1 and M2-21: fight started 0:22 (brief 0:29, the brief's 6 s to find
   the button plus 1.5 s of reaction), first boss placed 0:46 (0:52). The interval from placed to the first cash is 30 s by
   design. Intervals, not the cumulative times, are what the funnel should be read against (`m1-first-session.md`). The 25
   Power interval from the first punch is 6.8 s at the mix (phase a funnel stamps: 5.9 -> 12.7 s; paper 7.0), 4.9 s all
   Perfect, 10.4 s all Good.

## 4. What I tuned
**Nothing.** Every number that moves these curves is a brief table: zone income, upgrade costs, Strength and Speed costs,
the Power milestones, or the bands set by the manager's P2/P3. None of them is left open, and price changes are not
asked for. The punch and fight numbers measure within noise of `m2-punch-numbers.md` and need no change.

## 5. Reported to the manager instead (`manager-todo.md`)
- **Q4 (new): income is 4x to 7x the brief's expected-income line at minute 30.** PROVISIONAL default: change nothing in
  the game. The brief's line ("about $5 at minute 3, $80 at 10, $800 at 30") is replaced by the measured ranges as a
  sizing note, and the curve is checked again against the funnel and the Creator Dashboard after the first real
  sessions. The other choices are: lower the zone income table, or make upgrades and Strength dearer from zone 2 on.
  Either one changes the brief's tables.

## 6. For others
- **Scripter (Ring / TestClient):** the Speed 10 late-Good skipped ring in section 1 (about 1 ring in 10, 0.5 s lost, no
  server refusal).
- **M2-28 / check owners:** each `run_script_in_play_mode` here timed out at about 60 s of script time, under the 85 s
  `timeout` asked for. `Curves` phase a takes one player per call for that reason.

## 7. Questions only the playtest settles (for the manager's M2 playtest)
1. On a yellow or orange boss (r 1 to 2), how many of your taps were Perfect, Good, or missed? The game logs `offMs`. If
   you still win most of them easily, high bosses are not "much harder" yet.
2. At Speed 10 on the bag, did a tap ever do nothing when you tapped a little late?
3. After about 20 to 30 minutes: did cash pile up with nothing worth buying? Did zone 3 feel far away (it came at 15 to 16
   minutes in the runs)?
4. Did you split your time between bag and trips about evenly? The zone timings depend on it: a player who only runs
   trips reaches zone 2 at about 9:40, not 4:30.

## Not measured / UNVERIFIED
- Hazard drops on trips (no carrier was hit in the run). Real trips will be slower; the run is a floor.
- Rebirth, offline earnings, passes (all off), stealing: outside the 30-minute first-session curve.
- Rate rules under replication lag (section 6.2): not set up here, so UNVERIFIED. Read refusal counts from the playtest log.
- 3 runs per player and 5 mix fights per band (section 6): one run and two fights were done, because of the play-call limit.
