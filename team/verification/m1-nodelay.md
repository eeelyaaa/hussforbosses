# M1 exit check 6: no fight move delays the ring (NoDelay; script M1-16, look M1-20), 2026-11-25

Final run, `run_script_in_play_mode` (start_play), `require(game.ServerStorage.TmpChecks.NoDelay)({ phase = "a" })`; server log filtered to the check's own lines (the `[HFB] TestReport` warnings were skipped). Summary and context: `m1-16-gate.md`. The on-screen look is M1-20's (UNVERIFIED until then).

```
[HFB] server up: env=Studio skin=brickbrawl place=139279056607944
CHECK NoDelay/a start: player 28683760, skin brickbrawl
PASS NoDelay/a the probe wrapped BossMoves.play on the client
NOTE NoDelay/a fights won 8, lost 2; fight rings after a burst 17, after a miss 6
NOTE NoDelay/a ring gaps b:0.610 b:0.610 m:0.610 m:0.610 b:0.610 b:0.610 b:0.610 b:0.610 b:0.610 b:0.610 b:0.610 m:0.610 b:0.610 b:0.610 b:0.610 b:0.610 b:0.610 m:0.610 b:0.610 b:0.610 b:0.610 m:0.610 m:0.610
PASS NoDelay/a enough mixed play: >= 10 rings after bursts and >= 4 after misses | 17/6
PASS NoDelay/a every fight ring starts 0.61 s after the burst or miss before it (+/- 35 ms)
NOTE NoDelay/a BossMoves plays 88 (attack=6 defeat=16 hitBig=20 hitGood=24 hitPerfect=21 lastHeart=1); cuts 31
PASS NoDelay/a the boss reacted: hitBig and attack (Miss) moves played | hitBig 20, attack 6
PASS NoDelay/a reactions still running were cut by the next result (>= 1 cut seen) | 31
PASS NoDelay/a every cut started the new move at once (overlay after the call = the new move)
PASS NoDelay/a no errors and no [HFB] warnings in the server output
PASS NoDelay/a every HFB_ attribute the check set is cleared
CHECK NoDelay/a TOTAL pass=8 fail=0
CHECKALL row NoDelay|a|8|0|
-- skipped 250 TestReport warnings; duration 49.569632500002626 timeout False error nil
```
