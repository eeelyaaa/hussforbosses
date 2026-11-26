# M1 exit check 1: the Core loop gate (CoreLoop, M1-16), 2026-11-25

Final run, `run_script_in_play_mode` (start_play): `require(game.ServerStorage.TmpChecks.CoreLoop)({ phase = "a"|"b", skin = ... })`.
Server log filtered to the check's own lines (the `[HFB] TestReport` warnings from the real client are left out).
Summary, method and findings: `m1-16-gate.md`. Totals: brickbrawl a 22/0, b 36/0; stub a 22/0, b 36/0.

## brickbrawl, phase a (steps 1-4, authority)
```
[HFB] server up: env=Studio skin=brickbrawl place=139279056607944
PASS CoreLoop/a server skin is brickbrawl | brickbrawl
PASS CoreLoop/a 1 join: Plot1 OwnerUserId is the player | 28683760
PASS CoreLoop/a 1 join: character at SpawnPoint (flat < 3) | 0.00 studs, after 0.18 s
PASS CoreLoop/a 1 join: Zones.Pads lists z1_fixed -> z1_t1, Power 25 | z1_t1 25
PASS CoreLoop/a 1 join: Zones.Clock arrived on the client (ClockOffset 5 moved the client's offset off 0) | 4.939
NOTE CoreLoop/a client clock offset 4.939 for ClockOffset 5 (error -0.061 s; the client's GetServerTimeNow this soon after joining)
PASS CoreLoop/a 1 join: no errors in the output yet
PASS CoreLoop/a 2 Punch.Schedule sent on the bag pad: ring 1.20, cycle 1.81 | 1.200/1.810
PASS CoreLoop/a 2 the client's ring was drawn from that schedule (close 1.2) | 1.200
PASS CoreLoop/a 2 one Good burst applied by the server | good
PASS CoreLoop/a 2 beats applied at 0 / 0.213 / 0.401 s (+/- 20 ms, server clock) | 0.000(+0.0ms) 0.213(+2.8ms) 0.401(+15.1ms)
PASS CoreLoop/a 2 Punch.Result accepted for the burst | true
PASS CoreLoop/a 2 Power 1, 2, then 4 after the third beat (4 x strength value 1) | 1,2,4
PASS CoreLoop/a 2 the burst came through the Punch.Report remote | 1
PASS CoreLoop/a 3 one Perfect burst applied | perfect
PASS CoreLoop/a 3 Perfect: Power +8 (2/2/4) | 2/2/4, power 4 -> 12
PASS CoreLoop/a 3 Miss: the next ring starts 0.61 s after the miss | 0.610
PASS CoreLoop/a 3 Miss: no burst applied and no Power | bursts 0, power 12 -> 12
PASS CoreLoop/a 4 SetPower 24 then one Good burst: Power >= 25 | 28
PASS CoreLoop/a 4 the pad's number is green for the player (band easy or fair from Config.Fight.BANDS) | r=0.89 fair
PASS CoreLoop/a authority: steps 1-4 (12 profile changes, each with a server-side cause)
PASS CoreLoop/a no errors and no [HFB] warnings in the server output
PASS CoreLoop/a every HFB_ attribute the check set is cleared
CHECK CoreLoop/a TOTAL pass=22 fail=0
```

## brickbrawl, phase b (steps 5-9)
```
[HFB] server up: env=Studio skin=brickbrawl place=139279056607944
PASS CoreLoop/b server skin is brickbrawl | brickbrawl
PASS CoreLoop/b 5 Power is exactly 25 before the fight | 25
PASS CoreLoop/b 5 the client's Huss press sent Fight.Start (remote) | 1
PASS CoreLoop/b 5 Fight.State started
PASS CoreLoop/b 5 r = 1.0, band fair, windows 110/45 ms | 1 fair 110/45
PASS CoreLoop/b 5 health 250 (10 x 25), hearts 3 | 250/250 hearts 3
PASS CoreLoop/b 5 the fight ended in a win | win
PASS CoreLoop/b 5 server health beat by beat: 225 200 150 | 125 100 50 | 25 0W (won on burst 3 punch 2) | 1.1:225 1.2:200 1.3:150 2.1:125 2.2:100 2.3:50 3.1:25 3.2:0W
PASS CoreLoop/b 5 no Miss in the fight (all bursts Good) | 0
PASS CoreLoop/b 5 the client reported Good on every burst (grade only) | good,good,good
PASS CoreLoop/b 5 B22: burst 3 punch 3 dealt nothing (no contact, value 0) | false
PASS CoreLoop/b 5 B22 on the client: the last fight burst's beat 3 carried noContact | true
PASS CoreLoop/b 5 the client's fight rings used the band's windows 110/45 | 110/45
PASS CoreLoop/b 5 Zones.PadBeaten backIn = 10 (pad closed to the player ~10 s) | 9.37
PASS CoreLoop/b 6 Carry.State carrying z1_t1 after the win | z1_t1
PASS CoreLoop/b 6 carry speed 12 (server WalkSpeed) | 12
PASS CoreLoop/b 6 the client shows the boss carried | carrying
PASS CoreLoop/b 6 the log's track is stamped
NOTE CoreLoop/b walked 2.81 studs toward the log line in 0.75 s; speed-check pull-backs 0
PASS CoreLoop/b 6 walking onto the log's path with LogForce hit: dropped | dropped
PASS CoreLoop/b 6 pushed back about 6 studs (4 to 8) | 6.00
PASS CoreLoop/b 6 graceEnds about 5 s ahead | 5.00
PASS CoreLoop/b 6 the client shows the boss dropped | dropped
PASS CoreLoop/b 6 Carry.Grab from the client -> carrying again | state carrying, Grab sent 1
PASS CoreLoop/b 7 Base.Place from the client on spot 1: placed with the carried uid | Place sent 1
PASS CoreLoop/b 7 carry is none after the place | none
PASS CoreLoop/b 7 Base.State shows spot 1
PASS CoreLoop/b 7 the client shows one boss placed | 1
PASS CoreLoop/b 7 a second place on the same spot is refused (no state change) | taken
PASS CoreLoop/b 8 ClockOffset +30: the client's pad shows 30 x $1 | 30 $30
PASS CoreLoop/b 8 stepping on CashPad_1: Base.Collected amount 30 (+/- 1) | 30
PASS CoreLoop/b 8 server cash += the amount | 0 -> 30
PASS CoreLoop/b authority: steps 5-8 (2 profile changes, each with a server-side cause)
PASS CoreLoop/b 9 every fight damage beat has an applied Punch beat (server queue) behind it
PASS CoreLoop/b 9 results carried by remotes: Punch.Report, Fight.Start, Carry.Grab, Base.Place each > 0 | 3/1/1/1
PASS CoreLoop/b no errors and no [HFB] warnings in the server output
PASS CoreLoop/b every HFB_ attribute the check set is cleared
CHECK CoreLoop/b TOTAL pass=36 fail=0
```

## stub skin (skin check part 2; CheckSkin armed `HFB_ForceSkin = stub`, disarmed after)
Server: `[HFB] server up: env=Studio skin=stub`. Every line was the same as above apart from timings:
- Phase a: `PASS CoreLoop/a server skin is stub | stub`; beats +0.0 / +3.5 / +0.3 ms; clock offset 4.936.
  `CHECK CoreLoop/a TOTAL pass=22 fail=0`.
- Phase b: `PASS CoreLoop/b server skin is stub | stub`; health `1.1:225 1.2:200 1.3:150 2.1:125 2.2:100 2.3:50 3.1:25 3.2:0W`;
  push 6.00, grace 5.00, Grab sent 1, Place sent 1, `$30` shown, collected 30. `CHECK CoreLoop/b TOTAL pass=36 fail=0`.
- The client's audio reports showed `f 0, thuds 0` under the stub (its sounds are 0 ids), which is what the stub should do.
