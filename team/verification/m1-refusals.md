# M1 exit check 2: refusals (Refusals, M1-16), 2026-11-25

Final run. `live` ran in edit mode (inside CheckAll `prepare`); `a` and `b` each ran in one `run_script_in_play_mode`
call. Server log filtered to the check's own lines. Totals: live 6/0, a 19/0, b 32/0. Context: `m1-16-gate.md`.

## live (edit mode: a TestHooks copy whose RunService says not Studio)
```
PASS Refusals/live the TestHooks copy has its RunService replaced (flag: not Studio) | 1
PASS Refusals/live listenReports registers no Profile.TestReport handler when not Studio | 0
PASS Refusals/live TestHooks.get is nil when not Studio (AutoTap set)
PASS Refusals/live TestHooks.consume is nil when not Studio and leaves the attribute (SetPower set)
PASS Refusals/live TestHooks.onSet does not listen when not Studio
PASS Refusals/live warnIfSetLive warns about hooks left in the place | TestHooks: set in the place (ignored on a live server): SetPower, AutoTap
CHECK Refusals/live TOTAL pass=6 fail=0
```

## a (punch and fight)
```
PASS Refusals/a setup: a Good report on the pad is accepted
PASS Refusals/a a report 0.65 s after an accept (under CYCLE x 0.8 = 1.448) refused 'rate', no state change | rate
PASS Refusals/a a forged report during a burst refused 'busy'; the burst it hit is unchanged (+4) | busy, power +3 after the refusal
PASS Refusals/a a bag report off the pad refused 'place', no state change | place
PASS Refusals/a a fight report with no fight refused 'place', no state change | place
PASS Refusals/a a fight Miss with no fight refused 'place' (no heart to lose) | place
PASS Refusals/a a tap during a burst (real client, AutoTap busy) is ignored on the client | busy
PASS Refusals/a ... not refused by the server and no penalty (each burst still +4) | refused +0, bursts 1, gained 4
PASS Refusals/a Fight.Start outside the ring refused 'ring', no fight | power=25 cash=0 spots=-,-,-,-,-,-,-,-,-,- carry=none/- fight=none hearts=- health=-
PASS Refusals/a Fight.Start while carrying refused 'carrying', still carrying the same boss | carrying
PASS Refusals/a setup: a fight starts in the ring
PASS Refusals/a stall rule: no report -> the server counts one Miss | after 2.93 s (expected 2.90), why stall
PASS Refusals/a stall rule: timed at ring + ring + 0.5 s after the start (+/- 0.1) | 2.93
PASS Refusals/a Fight.Start during a fight refused 'running'
PASS Refusals/a Fight.Start on the 5 s cooldown refused 'closed', no fight | closed
PASS Refusals/a the cooldown is about 5 s | 4.80
PASS Refusals/a authority: phase a (12 profile changes, each with a server-side cause)
PASS Refusals/a no errors and no [HFB] warnings in the server output
PASS Refusals/a every HFB_ attribute the check set is cleared
CHECK Refusals/a TOTAL pass=19 fail=0
```

## b (base, malformed payloads from the real client, rate limits)
```
PASS Refusals/b Base.Place when not carrying refused 'notCarrying', no state change
PASS Refusals/b Base.Place out of range (40 studs) refused 'range', still carrying
PASS Refusals/b Base.Place spotIndex 0 / 11 / 1.5 / -1 / "1" / nan / inf / true refused 'bad', no state change   (8 lines, each PASS | bad)
PASS Refusals/b Base.Place standing on another player's Spot_1 refused, own spot 1 still empty | range
PASS Refusals/b setup: place on own Spot_1
PASS Refusals/b Base.Place on a taken spot refused 'taken', still carrying
PASS Refusals/b Carry.Grab while carrying (not dropped) refused 'state'
PASS Refusals/b the probe sent every malformed payload | {"Base.Place":16,"Profile.TestReport":13,"Carry.Grab":13,"Fight.Run":9,"Fight.Start":14,"Punch.Report":20}
NOTE Refusals/b fuzz calls received per remote: {"Base.Place":16,"Profile.TestReport":14,"Carry.Grab":13,"Punch.Report":20,"Fight.Start":14,"Fight.Run":9}
PASS Refusals/b malformed: no state changed (power, cash, spots, carry, fight) | power=0 cash=0 spots=<uid>,-,-,-,-,-,-,-,-,- carry=carrying/<uid> fight=none hearts=- health=-
PASS Refusals/b malformed: no server error and no [HFB] warning from any handler
PASS Refusals/b malformed Punch.Report payloads dropped by the shape check | 16
PASS Refusals/b malformed Fight.Start padIds refused 'bad' | 9
PASS Refusals/b malformed Carry.Grab uids refused 'bad' | 9
PASS Refusals/b malformed Base.Place spotIndexes refused 'bad' | 12
PASS Refusals/b malformed Profile.TestReport payloads stored nothing |
PASS Refusals/b the probe sent the rate bursts
PASS Refusals/b rate limit Punch.Report: 10 in one frame -> 6 dropped (limit 4/s) | 6
PASS Refusals/b rate limit Fight.Start: 10 in one frame -> 8 dropped (limit 2/s) | 8
PASS Refusals/b rate limit Fight.Run: 10 in one frame -> 8 dropped (limit 2/s) | 8
PASS Refusals/b rate limit Carry.Grab: 10 in one frame -> 6 dropped (limit 4/s) | 6
PASS Refusals/b rate limit Base.Place: 10 in one frame -> 6 dropped (limit 4/s) | 6
PASS Refusals/b rate bursts: no state changed | (same snapshot as above)
PASS Refusals/b authority: phase b (3 profile changes, each with a server-side cause)
PASS Refusals/b no errors and no [HFB] warnings in the server output
PASS Refusals/b every HFB_ attribute the check set is cleared
CHECK Refusals/b TOTAL pass=32 fail=0
```
The eight spotIndex lines and the two snapshots are shortened here (uids replaced by `<uid>`); each was a separate
PASS in the log. Each remote's malformed set opened with `nil`, `5`, `"x"` and `true` (dropped by `Net.onServerEvent`
before the handler) and went on with tables of wrong types, NaN, inf, 1e308, missing keys and nesting.
