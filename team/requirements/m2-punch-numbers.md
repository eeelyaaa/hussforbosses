# M2-03: punch numbers for P2 (ring and windows) and P3 (untimed tap), and the curve method for M2-26
Game-designer, 2026-11-25. Numbers only, no code. Every number here is **on paper**: nothing has run (Studio not
connected for this task). M2-06 copies section 1 into `Config`; M2-07 builds the client rules in section 2; M2-26
measures with section 6. Source of the rules: the manager's P2 and P3 (`decisions.md`, "the manager's decisions after
playing M1", items 2 and 3), `m2-punch-p3-p2-p4.md`, `m2-contract.md` section B.

The manager's words, built as written:
- P2: the huss timing is "a little hard", and "the ring should be a little quicker in general."
- P3: "just clicking the huss button should work. but if you don't time it it obviously doesn't do the three in a row,
  which is considered perfect (perfect text should float up above the button). and does more damage when timed. if they
  just click it just does 1 on the punching bag and depends on strength level on fighting bosses."

## 1. The Config table (M2-06 copies these values)
| Config key | M1 value | M2 value | Why |
|---|---|---|---|
| `Punch.RING` (Speed 1..10, s) | 1.20 1.12 1.04 0.96 0.88 0.80 0.72 0.64 0.57 0.50 | **1.05 0.98 0.91 0.84 0.77 0.70 0.63 0.56 0.48 0.41** | P2 "a little quicker": 12.5% shorter at Speed 1, 18% at Speed 10. Cycle spread Speed 1 / Speed 10 = 1.66 / 1.02 = 1.627 (M1 1.631), so Speed costs stay |
| `Punch.BURST_LEN` | 0.61 | 0.61 (unchanged) | burst timing contract, never moves |
| `Punch.BEAT` | 0, 0.213, 0.401 | unchanged | same |
| `Punch.MISS_RESTART` | 0.61 | 0.61 (unchanged) | also the wait after an untimed ring (section 2) |
| `Punch.BAG_WINDOWS` | perfect 45, good 110 ms | **perfect 55, good 130 ms** | P2 "a little easier": +22% / +18%; the bag stays equal to the Fair band, as at M1 |
| `Punch.GRADE_VALUE` | perfect 2, good 1, miss 0 | **perfect 2, good 1, untimed 1, miss 0** | untimed = one punch at value 1, applied once (no burst, no `BIG_MULT`) |
| `Punch.BIG_MULT` | 2 | 2 (unchanged) | timed bursts only |
| `Punch.RATE_TOLERANCE` | 0.8 | **0.75** | rechecked (B5): at Speed 10 a timed tap after a late timed tap arrives `cycle - goodMs` later; with the new 1.02 s cycle and Easy's 150 ms, 0.8 leaves 54 ms for network jitter, 0.75 leaves 105 ms (M1 had about 90) |
| `Punch.RING_GRACE_S` (new) | (none) | **0.15** | taps in the first 0.15 s of a ring are ignored: a stray second tap just after a burst, and the server's burst end arriving late, never spend a ring |
| `Punch.UNTIMED_MIN_GAP_S` (new) | (none) | **0.66** | server: an untimed report needs this long since the last accepted report of any grade. Fastest legit gap is a burst then an untimed tap: 0.61 + 0.15 = 0.76 s; 0.10 s slack for jitter |
| `Punch.EARLY_TAP_S` | 0.35 | **no longer used for grading** (M2-07 stops using it; M2-06 may delete the key) | with it, the first 0.70 s of a 1.05 s ring would ignore a click, and P3 says clicking works |
| `Punch.TAP_TIME_FUTURE_S` / `PAST_S` | 0.25 / 1.0 | unchanged | |
| `Punch.MAX_REPORTS_PER_SEC`, `RATE["Punch.Report"]` | 4 | 4 (unchanged) | the fastest legit stream is about 1.3 a second |
| `Fight.STALL_SLACK_S` | 0.5 | 0.5 (unchanged) | |
| `Fight.UNTIMED_HEART_FROM` (new, PROVISIONAL Q1) | (none) | **`"hard"`**: an untimed tap in band Hard or above costs a heart; Easy and Fair cost none | section 3 |
| `Fight.HEALTH_PER_POWER` | 10 | 10 (unchanged) | |
| `Fight.HEARTS` | 3 | 3 (unchanged) | |

`Fight.BANDS` (ms either side of the landing; `maxRatio` unchanged):
| Band | r | M1 Good / Perfect | **M2 Good / Perfect** | Change |
|---|---|---|---|---|
| `easy` | up to 0.5 | 130 / 55 | **150 / 65** | +15% / +18% |
| `fair` | 0.5 to 1.0 | 110 / 45 | **130 / 55** | +18% / +22% (= bag) |
| `hard` | 1.0 to 1.5 | 80 / 30 | **100 / 40** | +25% / +33% |
| `veryHard` | 1.5 to 2.0 | 60 / 22 | **80 / 30** | +33% / +36% |
| `brutal` | 2.0 to 3.0 | 45 / 16 | **65 / 24** | +44% / +50% |
| `impossible` | over 3.0 | 35 / 12 | **55 / 20** | +57% / +67% |

Why the high bands widen more (the M1 finding, `m1-first-session.md` item 4): a phone at 30 fps sees a tap only on a
frame, 33 ms apart, so a 35 ms Good window is about one frame either side and lands by luck. M2's floor is **no Good
window under 55 ms** (about 1.7 frames at 30 fps, 3.3 at 60). High bosses stay hard through health (10 x r punches'
worth), the narrower windows, and the heart rule in section 3. The Good spread across bands is now 2.7x (M1 3.7x).

**Stand-in tap offsets for checks** (the M1 +70 ms "Good" tap is now untimed in no band but would sit at the edge of
Brutal): Perfect = +0 ms; Good = halfway between the band's Perfect and Good edges, rounded: bag and Fair +92, Easy
+107, Hard +70, Very hard +55, Brutal +45, Impossible +38; untimed = landing - (Good + 100) ms, or ring start + 0.20 s.

## 2. What counts as timed and untimed (client grading, M2-07; server rules, M2-06)
A ring opens, closes over `RING[speed]`, and lands. For a tap at time t, with d = |t - landing|:
| Tap | Grade | What happens |
|---|---|---|
| During a burst, during the wait before a ring, or in the first `RING_GRACE_S` (0.15 s) of a ring | ignored | button squish only, no report (as M1's ignore) |
| d <= Perfect window | `perfect` | the burst, 2 + 2 + 4 = 8; PERFECT floats above the button (M2-08) |
| d <= Good window | `good` | the burst, 1 + 1 + 2 = 4; the small GOOD pop |
| Anywhere else in the ring from 0.15 s after it opens up to the Good window's early edge | `untimed` | **one punch at once** (value 1, the single huss 02A / 01A alternating, the plain pop, no pips, no F) |
| No tap by landing + Good window | `miss` | bag: nothing; fight: a heart and the boss's attack (as M1) |

- **One report per ring, whatever its grade** (confirms TEAM CALL M2-P1). After an untimed tap the ring is spent: it
  keeps closing to its landing, drawn dimmed (M2-07, quality bar "feedback on actions": the player sees why the next
  tap does nothing), and a second tap in it is ignored (`untimedBusy` if one reaches the server). A timed tap after an
  untimed one in the same ring is also ignored: otherwise mashing would catch the Good window and beat timing.
- **The next ring after an untimed tap opens at the ring's scheduled landing + `MISS_RESTART` (0.61 s)**, the same
  moment a perfectly timed tap would have given, so the rhythm never changes whatever the player does. (After a timed
  tap it is tap + `BURST_LEN`, after a no-tap Miss it is landing + Good + `MISS_RESTART`, both as M1.)
- A late tap, after landing + Good, finds the ring already passed (as M1) and is ignored.
- `FirstBagPunch` fires on the first timed or untimed bag punch (contract F).

**Server rate rules (replace contract B4; M2-06 builds, M2-27 re-checks).** Contract B4 as written ("untimed at most one
per `CYCLE x RATE_TOLERANCE`") refuses legit play: a burst then an untimed tap 0.15 s into the next ring is 0.76 s
apart, and 0.8 x 1.66 = 1.33 s at Speed 1 (even Speed 10 needs 0.82 s). The rules instead, all on receipt time:
1. **Any report** must not arrive while the player's burst runs (`busy`, as M1).
2. **`untimed`**: at least `UNTIMED_MIN_GAP_S` (0.66 s) since the last accepted report of any grade, else `untimedBusy`.
   Needs a sane `tapServerTime` like a timed report. Gains on the bag `{ strengthValue x rebirthMult x passMult }`; in a
   fight `{ playerPower }`, applied at accept time (beat 0). It does not start `BURST_LEN`. In a fight the server moves
   its expected landing on by one ring: `nextLanding = nextLanding + MISS_RESTART + RING[speed]` (the stall rule then
   works unchanged).
3. **`good` / `perfect`**: at least `CYCLE x RATE_TOLERANCE` (0.75) since the last accepted **timed** report, and at
   least `UNTIMED_MIN_GAP_S` since the last accepted report of any grade (stops an untimed and a burst in one ring).
4. **`miss`**: as M1 (not during a burst, Net's 4 a second).
5. With `auto`: only `good` or `perfect` (contract C), never `untimed`.

Legit gaps against these rules (no jitter): timed after timed >= cycle - Good (1.51 s at Speed 1 vs 1.25 needed; 0.87 s
at Speed 10 vs 0.77); untimed after anything >= 0.76 s vs 0.66; timed after untimed >= 0.61 + RING (>= 1.02 s).
**Cheat bound:** a client that forges every report, Perfect every 0.75 cycle plus an untimed between, gets about 7.2
Power a second at Speed 1 Strength 1 against 4.8 for flawless real play: 1.5x (M1 bound 1.25x on Perfects alone). The
rate ceiling is bounded; the remaining exposure is the known one (a client can claim Perfect), on M2-27's list.

## 3. Hearts and damage (P3 in fights; Q1)
| In a fight | Damage | Heart |
|---|---|---|
| Perfect | player Power x 8 (2 + 2 + 4 at the three beats) | none |
| Good | player Power x 4 (1 + 1 + 2) | none |
| Untimed | **player Power x 1**, at once | **Easy, Fair (green numbers): none. Hard and above (yellow, orange, red): one, and the boss's attack plays after the punch** (PROVISIONAL, Q1) |
| No tap (ring passed) | 0 | one (as M1) |

- "Depends on strength level": Power is what Strength builds, and Power is what a fight reads, so the untimed punch
  does one Good punch's damage, Power x 1 (confirms TEAM CALL M2-P3). A literal Strength value (1 to 6,000) would do
  1/250th of a first boss's health; that is not what "just clicking should work" means.
- "Just does 1 on the punching bag": one punch, which is +1 Power at Strength 1 and the Strength value above it (x
  rebirth, x 2x Power pass), the same unit a Good punch adds (confirms contract B2 and the check "+1 at Strength 1, x1.35
  at Strength 2"). A flat +1 forever would make the plain click worthless after the first Strength level.
- **Why not "never a heart" (the producer's default M2-P2):** if an untimed tap is free at every band, hearts only fall
  when a player stops tapping, so clicking wins every fight given time: r = 5 takes 50 clicks, about 83 s; a 250-Power
  player beats a zone 3 boss (2,500, r = 10) in about 2 min 46 s of clicking and skips about 7 minutes of training
  (brief system 3: zone 3 at 11 min). That undoes "much harder the further above you it is" and the Power gate on
  zones. With the heart from Hard up, clicking always works on green bosses (every fight in the first session is green)
  and a yellow or red boss needs timing, which is what the number colours already say. Changing the band costs one Config
  value; "never" is `UNTIMED_HEART_FROM = nil`, "always" is `"easy"`.

## 4. Power a second (on paper; M2-26 measures)
Strength 1, no multipliers. Cycle = RING + 0.61. Typical mix = 45% Perfect, 45% Good, 10% untimed = **5.5** a ring
(M1's 5.4 counted the 10% as a Miss worth 0). Auto Punch = Good every ring; Perfect Auto Punch = Perfect every ring.
| Speed | Ring | Cycle | Rings a minute | All untimed (mash) | All Good / Auto Punch | Typical | All Perfect / Perfect Auto | M1 typical | Change |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 1.05 | 1.66 | 36.1 | 0.60 | 2.41 | 3.31 | 4.82 | 2.98 | +11% |
| 2 | 0.98 | 1.59 | 37.7 | 0.63 | 2.52 | 3.46 | 5.03 | 3.12 | +11% |
| 3 | 0.91 | 1.52 | 39.5 | 0.66 | 2.63 | 3.62 | 5.26 | 3.27 | +11% |
| 4 | 0.84 | 1.45 | 41.4 | 0.69 | 2.76 | 3.79 | 5.52 | 3.44 | +10% |
| 5 | 0.77 | 1.38 | 43.5 | 0.72 | 2.90 | 3.99 | 5.80 | 3.62 | +10% |
| 6 | 0.70 | 1.31 | 45.8 | 0.76 | 3.05 | 4.20 | 6.11 | 3.83 | +10% |
| 7 | 0.63 | 1.24 | 48.4 | 0.81 | 3.23 | 4.44 | 6.45 | 4.06 | +9% |
| 8 | 0.56 | 1.17 | 51.3 | 0.85 | 3.42 | 4.70 | 6.84 | 4.32 | +9% |
| 9 | 0.48 | 1.09 | 55.0 | 0.92 | 3.67 | 5.05 | 7.34 | 4.58 | +10% |
| 10 | 0.41 | 1.02 | 58.8 | 0.98 | 3.92 | 5.39 | 7.84 | 4.86 | +11% |

**Untimed stays below the Good burst at every Speed** (a quarter of it). Acceptance 2 (10 s at Speed 1): mashing about
6 Power, Good bursts about 24. Even a forged untimed stream at the 0.66 s floor (1.5 a second) is below Good.
Speed costs are unchanged. Every Power milestone in brief system 3 arrives about 10% sooner on top of the 15% the brief
already notes; that is the cost of P2's quicker ring, not retuned here (economy retune not asked; M2-26 measures).

## 5. First session and fights, re-derived (on paper)
Fights at Speed 1 (first ring 1.05 s, then a cycle per tap; the win lands on the last needed beat):
| r (band) | All Good: taps, s | All Perfect: taps, s | All untimed: taps, s | M1 all Good s |
|---|---|---|---|---|
| 0.5 (easy) | 2, 3.1 | 1, 1.5 | 5, 7.7 (no heart) | 3.4 |
| 1 (fair) | 3, 4.6 (win on burst 3 punch 2) | 2, 3.1 | 10, 16.0 (no heart) | 5.2 (measured 5.30) |
| 1.5 (hard) | 4, 6.4 | 2, 3.1 | loses after 3 (Q1 default) | 7.0 |
| 2 (very hard) | 5, 8.1 | 3, 4.8 | loses after 3 | 8.8 |
| 3 (brutal) | 8, 13.1 | 4, 6.4 | loses after 3 | 14.3 |
| 5 (impossible) | 13, 21.4 | 7, 11.4 | loses after 3 | 23.3 |
Tap counts are unchanged (Good ceil(2.5 r), Perfect ceil(1.25 r)); untimed is ceil(10 r).

First session (brief's table; human times keep the brief's reaction allowances, only the ring changed):
| Step | Brief | M2 on paper | How |
|---|---|---|---|
| First punch | 0:06 | 0:06 | a human finding the button; any click in the ring now counts |
| 25 Power | 0:16, "about six bursts" | **about 0:13, about five bursts** (typical 5.5 a ring: 5; all Perfect: 4; all Good: 7) | first punch + 4 cycles of 1.66 + 0.4 = 7.0 s (M1 floor measured 7.5 s at the old ring) |
| A pure clicker reaches 25 | (not in the brief) | about 0:46 (25 clicks, 41 s) | the price of not timing; not a block |
| First fight started | 0:29 | about 0:26 | 13 s run and press, unchanged |
| First boss beaten | 0:35 | about 0:30 (typical 3 to 4.5 s; all Good 4.6) | the frog at r about 0.9 to 1 |
| First boss placed | 0:52 (50 to 55) | **about 0:47 (45 to 51 by plot)** | carry unchanged |
| First cash, first upgrade | 1:22, 1:27 | about 1:17, 1:22 | +30 s, +5 s |
| Zone 2 boss placed | about 4:40 | about 4:20 (rough: the bag share of the time is about 10% faster) | M2-26 measures |
The 12 funnel events and their order are unchanged.

**Brief cells this changes** (the producer applies them to `pack/brief.md` as following from P2 and P3, and logs it):
system 1's table (ring 1.20 -> 1.05, cycle 1.81 / 1.11 -> 1.66 / 1.02, bag windows 45 / 110 -> 55 / 130, the Miss row
-> untimed and Miss rows, "A Miss launches no burst" -> section 2 here, typical 5.4 -> 5.5); system 2's Speed table
(every column but cost), Auto Punch 2.2 -> 2.4 and Perfect Auto Punch 4.4 -> 4.8 a second; system 3's "about 3.0 a
second, 180 a minute" -> 3.3, 199; system 4's band windows, "5.4 seconds" -> 4.6, and the hearts row (section 3); the
first-session rows above.

## 6. Curve-measurement method for M2-26 (`verification/m2-26-curves.md`)
Play mode, `studio` lock, real client tapping through `Ring.tap` (never forged reports; the forged cases belong to
`Punch2` and M2-27). Hook `AutoPlayer` (contract G) drives it with the stand-in offsets in section 1. Keep the M1
warm-ups (4 s before timing; clock offset settles after about 3 s). Every run logs accepted and refused reports by
reason; a legit run with any refusal is a FAIL to explain.
1. **Power a second**, Strength 1, at Speed 1 and Speed 10, four players: `untimed` (a tap every 0.125 s, mashing),
   `good`, `perfect`, `mix` (45 / 45 / 10 seeded). 60 s each after the warm-up, 3 runs each; Power delta / 60. Pass:
   within 5% of section 4. Add Strength 2 for `untimed` and `good` (x1.35). Acceptance 2 = the 10 s mash vs 10 s Good.
2. **Rate rules under jitter**: the same four players at Speed 10 with Studio's incoming replication lag at 0.1 s if
   the main session can set it; else mark `UNVERIFIED` and read refusal counts from the manager's playtest log. Target
   0 refusals at no lag, under 1% with lag.
3. **Fights**: Chomp Frog at Power set for r = 0.5, 1, 1.5, 2, 3, 5 (hook `SetPower`): all Good, all Perfect, all
   untimed, and `mix` x 5 runs. Record win or loss, seconds (`started` to `win`), bursts, untimed punches, hearts lost.
   Pass: taps as section 5 exactly, seconds within 5%; untimed loses at Hard and above after 3 hearts, wins without a
   heart at Easy and Fair.
4. **First session**: M2-21's `FirstSession` check (zero-reaction floor) for 25 Power, fight, placed; compare the
   intervals (not the cumulative times) with section 5, as at M1.
5. **Human timing** (the only thing that settles P2): M2-07's ring log keeps the signed offset (`offMs`) of every tap.
   From the manager's playtest, per band: share of Perfect / Good / untimed, and the median signed offset. A median more
   than 30 ms late on a phone means touch latency is shifting taps, and the windows should be moved, not widened
   (a question for M5, not now).

## 7. Questions only a playtest settles (for the manager's M2 playtest)
1. On the bag at Speed 1: does the ring feel "a little quicker", or now too quick to read?
2. Is the timing now "a little" easier, or so easy that every tap is a Perfect? (Answer from feel; section 6.5 gives the
   numbers.)
3. When you just click without timing: is it clear that you punched once, and that timing gives three?
4. On a yellow or red boss (r above 1): could you land Goods by timing, or did it still feel like luck?
5. Did it ever feel like a click did nothing? (The ring's first 0.15 s and the spent ring are ignored on purpose.)

## Suggestions from the vault
None. `vault/patterns/INDEX.md` has no pattern on timing windows or input latency; the window floor above is reasoning
from frame times (unverified until the playtest and M2-26).

## Not asked for (do not build)
Economy retune (Strength and Speed costs, milestones), new upgrades, a combo counter, a mash penalty, an asymmetric
window or latency offset, code (M2-06 and M2-07 own it).
