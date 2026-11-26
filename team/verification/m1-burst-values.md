# M1 exit check 3: burst values and fight tap counts (BurstValues, M1-16), 2026-11-25

Final run, two `run_script_in_play_mode` calls (start_play). Server log filtered to the check's own lines. Summary and context: `m1-16-gate.md`.

## Phase a
```
[HFB] server up: env=Studio skin=brickbrawl place=139279056607944
CHECK BurstValues/a start: player 28683760, skin brickbrawl
PASS BurstValues/a good: a burst was applied
PASS BurstValues/a good = 4: values 1/1/2 at 0 / 0.213 / 0.401 s, each applied within 20 ms | 1/1/2 0.000(+0.0) 0.213(+4.0) 0.401(+15.5)
PASS BurstValues/a perfect: a burst was applied
PASS BurstValues/a perfect = 8: values 2/2/4 at 0 / 0.213 / 0.401 s, each applied within 20 ms | 2/2/4 0.000(+0.0) 0.213(+5.0) 0.401(+0.4)
PASS BurstValues/a Miss: no burst, the next ring 0.61 s later (two misses) | 0.61,0.61
PASS BurstValues/a Speed 1: Punch.Schedule cycle 1.81 | 1.810
PASS BurstValues/a Speed 1: four bursts in a row
PASS BurstValues/a Speed 1: one cycle = 1.81 s burst to burst (+/- 35 ms) | 1.817,1.818
PASS BurstValues/a Speed 10: Punch.Schedule cycle 1.11 | 1.110
PASS BurstValues/a Speed 10: four bursts in a row
PASS BurstValues/a Speed 10: one cycle = 1.11 s burst to burst (+/- 35 ms) | 1.117,1.117
PASS BurstValues/a r=0.500 (Power 50): the fight starts
PASS BurstValues/a r=0.500: band easy, windows 130/55 ms | r=0.5000 easy 130/55
PASS BurstValues/a r=0.500: all-perfect wins in 1 bursts | won true, bursts 1, refused 0, hearts 3
PASS BurstValues/a r=1 (Power 25): the fight starts
PASS BurstValues/a r=1: band fair, windows 110/45 ms | r=1.0000 fair 110/45
PASS BurstValues/a r=1: all-perfect wins in 2 bursts | won true, bursts 2, refused 0, hearts 3
PASS BurstValues/a r=1.500 (Power 16.670): the fight starts
PASS BurstValues/a r=1.500: band hard, windows 80/30 ms | r=1.4997 hard 80/30
PASS BurstValues/a r=1.500: all-perfect wins in 2 bursts | won true, bursts 2, refused 0, hearts 3
PASS BurstValues/a r=2 (Power 12.500): the fight starts
PASS BurstValues/a r=2: band veryHard, windows 60/22 ms | r=2.0000 veryHard 60/22
PASS BurstValues/a r=2: all-perfect wins in 3 bursts | won true, bursts 3, refused 0, hearts 3
PASS BurstValues/a r=3 (Power 8.340): the fight starts
PASS BurstValues/a r=3: band brutal, windows 45/16 ms | r=2.9976 brutal 45/16
PASS BurstValues/a r=3: all-perfect wins in 4 bursts | won true, bursts 4, refused 0, hearts 3
PASS BurstValues/a r=5 (Power 5): the fight starts
PASS BurstValues/a r=5: band impossible, windows 35/12 ms | r=5.0000 impossible 35/12
PASS BurstValues/a r=5: all-perfect wins in 7 bursts | won true, bursts 7, refused 0, hearts 3
PASS BurstValues/a no errors and no [HFB] warnings in the server output
PASS BurstValues/a every HFB_ attribute the check set is cleared
CHECK BurstValues/a TOTAL pass=31 fail=0
CHECKALL row BurstValues|a|31|0|
-- skipped 161 TestReport warnings; duration 43.66376540000783 timeout False error nil
```

## Phase b
```
CHECK BurstValues/b start: player 28683760, skin brickbrawl
PASS BurstValues/b r=0.500 (Power 50): the fight starts
PASS BurstValues/b r=0.500: band easy, windows 130/55 ms | r=0.5000 easy 130/55
PASS BurstValues/b r=0.500: all-good wins in 2 bursts | won true, bursts 2, refused 0, hearts 3
PASS BurstValues/b r=1 (Power 25): the fight starts
PASS BurstValues/b r=1: band fair, windows 110/45 ms | r=1.0000 fair 110/45
PASS BurstValues/b r=1: all-good wins in 3 bursts | won true, bursts 3, refused 0, hearts 3
PASS BurstValues/b r=1.500 (Power 16.670): the fight starts
PASS BurstValues/b r=1.500: band hard, windows 80/30 ms | r=1.4997 hard 80/30
PASS BurstValues/b r=1.500: all-good wins in 4 bursts | won true, bursts 4, refused 0, hearts 3
PASS BurstValues/b r=2 (Power 12.500): the fight starts
PASS BurstValues/b r=2: band veryHard, windows 60/22 ms | r=2.0000 veryHard 60/22
PASS BurstValues/b r=2: all-good wins in 5 bursts | won true, bursts 5, refused 0, hearts 3
PASS BurstValues/b r=3 (Power 8.340): the fight starts
PASS BurstValues/b r=3: band brutal, windows 45/16 ms | r=2.9976 brutal 45/16
PASS BurstValues/b r=3: all-good wins in 8 bursts | won true, bursts 8, refused 0, hearts 3
PASS BurstValues/b r=5 (Power 5): the fight starts
PASS BurstValues/b r=5: band impossible, windows 35/12 ms | r=5.0000 impossible 35/12
PASS BurstValues/b r=5: all-good wins in 13 bursts | won true, bursts 13, refused 0, hearts 3
PASS BurstValues/b B22 punch 1 (Power 250): the fight starts
PASS BurstValues/b B22: one burst, the bar empties on punch 1, 1 Fight.Beat sent | 1:0W
PASS BurstValues/b B22: punches after 1 made no contact and dealt nothing | false/0,false/0
PASS BurstValues/b B22 punch 2 (Power 125): the fight starts
PASS BurstValues/b B22: one burst, the bar empties on punch 2, 2 Fight.Beat sent | 1:125 2:0W
PASS BurstValues/b B22: punches after 2 made no contact and dealt nothing | false/0
PASS BurstValues/b no errors and no [HFB] warnings in the server output
PASS BurstValues/b every HFB_ attribute the check set is cleared
CHECK BurstValues/b TOTAL pass=26 fail=0
```
r = 1.5 and 3 use Power 16.67 and 8.34 (r 1.4997 and 2.9976) so a float ratio cannot tip a band edge; the tap counts
are unchanged by it. Fight tap counts are the server's damage rule under forged grades (TEAM CALL M1-16c).
