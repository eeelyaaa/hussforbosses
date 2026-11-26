# M1-18: first-session times and fight lengths, measured (game-designer, 2026-11-25)

Script: `studio/checks/FirstSession.lua` (play mode, installed by hand as `ServerStorage.TmpChecks.FirstSession` next to the M1-16 checks, removed afterwards; `studio` lock as `designer-m1-18`, released). Place 139279056607944, marker true, real client, real slice, skin brickbrawl. Nothing in `src/` or Config changed. Every `HFB_` attribute cleared; `StudProofUi` still disabled; `TmpChecks` removed.

## Method (read this before the numbers)
- **Stand-in player = a zero-reaction player.** The real client taps through `AutoTap`; the server moves the character along the layout's waypoints (spawn, bag pad, door (96,179), gate (206,234), ring) at 16 studs/s, 12 carrying. The brief's times belong to a human, who reads the arrow, finds the button and picks a route. The script has none of that, so its cumulative times are a floor. The comparable figures are the **intervals** (walk, fight, carry, income), marked below.
- **Grade mix:** "typical" = `AutoMix 45,45,10` (the brief's new-player mix: 45% Perfect, 45% Good, 10% Miss) in 3 runs from a wiped session; "perfect" = `AutoTap perfect` (1 run). In-fight runs: all-Perfect (tap at +0), all-Good (tap at +70 ms) and the typical mix. A run is one random sample: three typical runs are a range, not a statistic.
- The fight is started the way a player starts it, by the client pressing Huss while standing in the ring (the hook presses once a second). Fight length is the server's `started` to `win` time. The ring edge stop is 1 stud inside the ring (the layout counts to the edge), so run distances read 1 stud (0.06 s) long.
- 25 Power is stamped when the third beat of the burst that crosses 25 lands on the server.

## Table 1: the first session (plot 1, wiped session, Speed 1, Strength 1)
| Measure | Brief | Measured (typical x3: range, mean) | Perfect x1 | Delta (mean vs brief) | Notes |
|---|---|---|---|---|---|
| Seconds to first punch (spawn to first Power) | 6 | 1.50 to 1.61 (1.57) | 1.77 | -74% | Floor: 0.6 s walk to the pad + 1.2 s ring minus the beat. The other ~4.4 s of the brief is a human finding the button; playtest, not a number to change. |
| First Perfect | 10 | 1.50 / 3.43 / 3.44 (2.79) | 1.79 | -72% | Depends on the mix roll (45% a tap). The brief's "about the third tap" is ~5.4 s at 1.81 s a cycle for a human; the script lands it on tap 1 or 2. |
| 25 Power | 16 | 7.50 to 10.93 (9.11); 5 / 5 / 4 bursts | 7.22 (4 bursts) | -43%; interval from first punch 7.5 vs 10 (-25%) | **Brief says "about six bursts"; measured 4 to 5** (25 / 5.4 = 4.6). Wording for M2. Power per burst at typical grades is as the brief's 5.4. |
| Walk bag pad to the gate | 8.7 s (139 studs) | 138.4 studs, 8.65 to 8.69 s | same | -0.3% | Matches the layout and the M1-05 greybox (138.6). |
| Run to the fixed pad ring | 11.4 s (183 studs) | 11.45 to 11.52 s (182.2 to the edge) | 11.52 | +0.7% | Within 1% of the layout. |
| First fight started | 29 | 19.02 to 22.38 (20.61) | 18.74 | cumulative -29%; interval 25 Power to fight start (walk + press): measured 11.5 to 11.9 vs brief 13 | The press starts the fight the moment the character is in the ring (0 to 1 s). Brief's extra 1.5 s = reaction. |
| Fight length, typical mix at r=1 (3 samples) | 5.4 (all Goods) | 3.53 / 5.00 / 3.60 s (2, 3, 2 bursts) | 1.65 s (1 burst, Power was 32, r=0.78) | -26% | The brief's 5.4 s is the all-Good ceiling; Perfects shorten it (a Perfect does 2x). All-Good measured 5.30 s (-2%), see table 2. |
| First boss beaten | 35 | 23.99 to 25.9 (24.6) | 20.37 | cumulative -30%; interval fight start to win is the line above | |
| First boss carried home (ring to placed) | 15.2 s carry (0:35 to 0:51) | 15.40 s (log forced clear), 15.47 s (log natural, 0 drops) | | +1.3% to +1.8% | 184 to 185 studs including the 1 stud inside the ring and the walk onto Spot_1. Carried at 12; Fast Carry (16) is the same path, 11.4 s by the layout (not run: needs the pass). The natural log did not hit a straight walker in one try; a human sees its shadow, so the drop rate is a playtest question. |
| First boss placed | 52 (50 to 55) | 24.6 + 15.4 = about 40.0 (zero reaction) | about 35.8 | -23% | The ~12 s gap is the reaction allowance spread over the whole run (6 s to the first punch, 1.5 s before the run, ~1.8 s grab and place). Not a design error. |
| First cash on the pad, $30 | 30 s after placing | 30.03 s | | 0% | $1 a second. Real clock, one run. |
| First cash collected | 1:22 (placed + 30 s) | placed + 30.03 s; stepping on CashPad_1 collected $30 in 0.03 s (cash 0 to 30) | | 0% | |

## Table 2: fight lengths and tap counts (Chomp Frog at Power set so r takes each value; Speed 1, cycle 1.81 s)
Brief: taps (bursts) all-Goods = ceil(2.5 r) = 2, 3, 4, 5, 8, 13; all-Perfects = ceil(1.25 r) = 1, 2, 2, 3, 4, 7. Seconds are the server's `started` to `win`. The real client taps; no forged reports.

| r (band) | Brief all-Goods | Measured all-Good (tap +70 ms) | Brief all-Perfect | Measured all-Perfect | Typical mix (win, s, grades, hearts lost) |
|---|---|---|---|---|---|
| 0.5 (easy 130/55) | 2 | 2 bursts, 3.20 s | 1 | 1 burst, 1.65 s | 5.08 s (g p, 1 heart lost); 1.65 s (p) |
| 1 (fair 110/45) | 3 | 3 bursts, 5.30 s (brief 5.4: -2%) | 2 | 2 bursts, 3.07 s | 5.02 s (g g p); 5.30 s (g g g) |
| 1.5 (hard 80/30) | 4 | 4 bursts, 7.38 s | 2 | 2 bursts, 3.48 s | 5.43 s (p g g); 3.48 s (p p) |
| 2 (very hard 60/22) | 5 | **not winnable by this stand-in**: every +70 ms tap is outside the 60 ms Good window, 3 Misses, loss in 5.08 s | 3 | 3 bursts, 5.10 s | not run |
| 3 (brutal 45/16) | 8 | not run (same cause) | 4 | 4 bursts, 7.09 s | not run |
| 5 (impossible 35/12) | 13 | not run (same cause) | 7 | 7 bursts, 12.13 s | not run |

Tap counts match the brief in every measured cell (all-Perfect 1/2/2/3/4/7 at all six r; all-Good 2/3/4 at the three r that the +70 ms tap can still land). Length per burst count: all-Good about 1.8 s a burst less the first ring, i.e. 3.2, 5.3, 7.4 s; all-Perfect 1.65, 3.07, 3.48, 5.10, 7.09, 12.13 s. All-Good at 13 bursts would be about 23 s (not measured; 13 x 1.81 less the first ring).

## Items more than 10% off the brief
None changes the game, so nothing goes to `manager-todo.md`. For M2 tuning (a table or wording change, no number touched here):
1. **Cumulative times (first punch, Perfect, 25 Power, fight, beaten, placed) read 23 to 74% under the brief** only because the script has no reaction time. Do not tune to them. The funnel events (M2) will give real human times; compare those to the brief, and use the script's figures as the floor (first punch >= 1.6 s, first placed >= 40 s).
2. **"About six bursts" to 25 Power is four to five** (mean 4.7; interval from the first punch 7.5 s against the brief's 10 s). Suggest the brief reads "about five bursts" and the 0:16 row's step shortens by ~2 s. No Config change: the 25 Power number and Chomp Frog's 25 are as built.
3. **First fight at typical grades takes about 4 s (3.5 to 5.0), not 5.4**; the 5.4 s is the all-Good ceiling (measured 5.30). Suggest the brief says "about 4 to 5 seconds, 5.4 when every tap is a Good".
4. **Playtest question, not a defect:** the very-hard band's Good window is 60 ms and the brutal and impossible bands 45 and 35 ms. A tap 70 ms off the landing is a Miss there (this is what the stand-in showed). Whether a phone player's real timing spread (touch latency, 60 fps frame step of 17 ms) can land Goods at r >= 2 is only answerable by the manager's playtest or the M2 funnel data. Ask: "At a red number, could you land taps, or did it feel like luck?"
5. Not measured here (needs more than one stand-in player or the pass): Fast Carry, the other seven plots' walks (layout gives 156 to 176 studs for bag to gate), the Rolling Log's hit rate on a human carrier, first upgrade (1:27, M2 buys), Starter Pack, zone 2.

## Walk numbers re-measured on the real slice (task also asked)
Bag pad to gate 138.4 studs / 8.65 to 8.69 s (layout 139, 8.7 s). Bag pad to the fixed pad ring 182.2 studs to the edge, 11.45 to 11.52 s (layout 183, 11.4 s). Carry home 15.40 and 15.47 s at 12 studs/s (layout 15.2 s). All within 2% of the layout and of the M1-05 greybox (within 2%). The walks are the script moving the character on the layout's waypoints, so they confirm the distance on the built slice, not collision detours (the greybox's PathfindingService figures, 2% shorter, stand).

## Raw lines (M118 prefix)
```
a typical #1 (start-stamp bug fixed after; fight times from the server log are unaffected): firstPunch 1.61 firstPerfect 3.43 p25 10.93 bursts 5 (P2 G3) gate 19.61 ring 22.38 run 11.45 s 182.4 studs, fight win 3.53 s 2 bursts
a typical #2: atBag 0.60 firstPunch 1.50 firstPerfect 1.50 p25 8.90 bursts 5 (P3 G2) gate 17.58 ring 20.40 run 11.50 s 183.2, fightStart 20.40 end 24.00 (win 3.60 s, 2 bursts, 0 hearts)
a typical #3: firstPunch 1.60 firstPerfect 3.44 p25 7.50 bursts 4 (P3 G1) gate 16.19 ring 19.02 run 11.52 s 183.4, fightStart 19.02 end 23.99 (win 5.00 s, 3 bursts, 0 hearts)
a perfect:    atBag 0.68 firstPunch 1.77 firstPerfect 1.79 p25 7.22 bursts 4 (P4) gate 15.90 ring 18.74 run 11.52 s 183.5, fightStart 18.74 end 20.37 (win 1.65 s, 1 burst)
b log=clear:  carry home: gate 3.75 door 14.01 placed 15.40 s, 184.2 studs, drops 0; income: $30 on the pad 30.03 s after placing; collected true cash 0.03 s after stepping on the pad (cash 0 -> 30)
b log=none:   carry home: gate 3.74 door 14.00 placed 15.47 s, 185.1 studs, drops 0, dropWait 0.00
FIGHT perfect r=0.5/1/1.5/2/3/5: 1.65 / 3.07 / 3.48 / 5.10 / 7.09 / 12.13 s; bursts 1/2/2/3/4/7; hearts lost 0
FIGHT good    r=0.5/1/1.5: 3.20 / 5.30 / 7.38 s; bursts 2/3/4. r=2: loss in 5.08 s, 0 bursts, 3 hearts lost
FIGHT mix     r=0.5: 5.08 s [gp] 1 heart lost, 1.65 s [p]; r=1: 5.02 s [ggp], 5.30 s [ggg]; r=1.5: 5.43 s [pgg], 3.48 s [pp]
every call: no errors and no [HFB] warnings, every HFB_ attribute cleared
```
(The first perfect-fight call failed with "could not start: running": the hook's own press had already started a fight; the script was changed to start fights only through the client press. That call is not in the numbers.)
