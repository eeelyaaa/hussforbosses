# M1-19: the sync test at 60, 30 and 15 fps on the finished M1 build (audio-specialist, 2026-11-25)

Studio MCP, `studio` lock held as `audio-m1-19` (released). Play mode, the real client path (AutoTap good, ReportBeats, Speed 10), one cap per
MCP call, 20 bursts judged per cap (21 collected). `Studio/checks/SyncTest.lua` (extended) + new client probe `studio/checks/SyncProbe.lua`
(installed as `StarterPlayerScripts.HFB_SyncProbe` and `ServerStorage.TmpSync` for the run, both removed after; 0 `HFB_` attributes, marker true,
`StudProofUi` disabled). **How it looks and sounds is `UNVERIFIED`**: everything below is counts and times from the client's own clock.
Summary lines were captured from the `run_script_in_play_mode` log result at every cap (including 30 fps).

## 1. Per cap: F once per burst, three beats in order, none dropped, each within one frame
Limit per beat = 1/cap + 4 ms late, never early. The beat schedule is BEAT = 0 / 0.213 / 0.401 s.
| FrameCap | Result | Worst beat lateness (limit) | F plays per burst | F Play() after t0 (worst) | BurstClock.starts | Beats |
|---|---|---|---|---|---|---|
| 60 | **PASS** | 16.0 ms (20.7) | 1 on all 20 | 0.080 ms | 1 per burst | 3 per burst, in order, none early |
| 30 | **PASS** | 32.0 ms (37.3) | 1 on all 20 | 0.211 ms | 1 per burst | same |
| 15 | **PASS** | 66.0 ms (70.7) | 1 on all 20 | 0.076 ms | 1 per burst | same |
Raw summary lines (`SYNC cap N:`) as printed:
```
SYNC cap 60: bursts 20, worst beat lateness 16.0 ms (limit 20.7), worst F start after t0 0.080 ms, reports dropped so far 0
SYNC cap 30: bursts 20, worst beat lateness 32.0 ms (limit 37.3), worst F start after t0 0.211 ms, reports dropped so far 0
SYNC cap 15: bursts 20, worst beat lateness 66.0 ms (limit 70.7), worst F start after t0 0.076 ms, reports dropped so far 0
PASS SyncTest FrameCap 60 / 30 / 15
```
Also per burst at every cap: three thuds (the Audio beat subscriber), `Sound.Played` equal to F plays, no report dropped (0). The late beats at 30 and 15
fps are the frame-quantised schedule, not drift (lateness is one frame at 30 and four at 15 at most). The M1-13 30 fps line that was missed is now
captured (above); it matches the earlier raw-report reading (32 ms).

## 2. Do the avatar's contact markers hang off the same beats? (`Avatar.hitLog`, clips are published and wired)
Every burst at every cap (63 markers = 21 bursts x 3 at each cap) fired exactly 3 `Hit` markers: jab3 n1, jab3 n2, bigThird n3 (the big third
replaces jab3's own third, as `Avatar.startJab` says). Offsets are `os.clock()` at the marker minus the burst's t0, then minus BEAT[n]:
| FrameCap | Marker n1 (beat 0) | Marker n2 (beat 213) | Marker n3 (beat 401) | Worst |offset| |
|---|---|---|---|---|
| 60 | +12.4 ms mean (typically 11 to 13) | +0.1 mean (211.8 to 213.3, one 229.8) | +11.3 mean (411 to 413) | 16.8 ms |
| 30 | +2.5 mean (2.2 to 2.3) | -11.2 mean (201.5 to 201.7) | +5.8 mean (401.6 to 401.8, one outlier) | 37.0 ms (one burst) |
| 15 | +2.5 mean (2.1 to 3.2) | -10.9 mean (201.8 to 202.4) | +1.0 mean (401.8 to 402.0) | 11.2 ms |
Reading: the markers are authored at about 0 / 0.200 / 0.400 s of the clip; they fire one animation tick after the start at 60 fps (so they read
+12 / 0 / +12 against the beats) and on the clip's own times at 30 and 15 fps. So **the contact markers are tied to the clip, not to
BurstClock's beats**: the clip starts in the same frame as t0 and the marker times are within about 15 ms of the beats at every cap (marker 2 sits up to
11 ms before beat 2 at 30 and 15 fps, which is the clip's 0.200 against the beat's 0.213). The 37.0 ms worst at 30 fps is a single burst. No marker was missing or doubled.
Marker 2 and the beat-2 thud are therefore within about 15 ms of each other on screen; a thud is fired from the beat, the contact from the marker. UNVERIFIED by eye.

## 3. Do the boss hit reactions hang off the same beats? (fight phase, `_G.HFB_SYNC_FIGHT`, cap 60, Power 25, real Chomp Frog)
One fight of 3 bursts (Good), `BossMoves.play` wrapped on the client and timed from each burst's t0 (ms):
| Burst | Beat firedAt | `BossMoves.play` calls | Avatar Hit markers |
|---|---|---|---|
| 1 | 0 / 216 / 416 | hitGood 0.2, hitGood 216.3, hitBig 416.3 | 15.0, 213.7, 413.3 |
| 2 | 0 / 216 / 417 | hitGood 0.2, hitGood 216.6, hitBig 416.6 | 13.4, 212.7, 413.0 |
| 3 | 0 / 217 / 417 (beat 3 `noContact`) | hitGood 0.1, hitGood 216.7, then defeat 262.9 and defeat 263.1; no reaction on beat 3 (B22) | 13.1, 214.1, 413.7 |
Each reaction plays in the same call as its beat (within 0.5 ms of the beat's `firedAt`): beat 1 hitGood, beat 2 hitGood, beat 3 hitBig. The
win ends the fight after punch 2 of burst 3 (server `Fight.State win` arrives about 46 ms after beat 2): the boss goes to `defeat`, and beat 3 plays no
reaction, as B22 says. The thuds in burst 3 were 2 (beat 3 `noContact`), the other bursts 3. The avatar's third swing still plays on the won burst (the clip has no cut). The summary line:
`SYNCPROBE cap 60: ... BossMoves.play calls 10 (defeat=2 hitBig=2 hitGood=6), worst distance from the nearest beat firedAt 46.1 ms` (the 46 ms is the server-driven defeat, not a beat reaction).
The fight phase's own `FAIL` line ("only 3 bursts collected") is expected: it judges 20 bursts.

## Findings
1. **`BossMoves.play(boss, "defeat")` is called twice in the same frame** (262.9 and 263.1 ms) on a win. The second cuts and restarts the first at frame 0, so no
   visible harm is expected, but it is a double call from the win path (`Fight` state handler, or two paths). For M1-20 / the scripter to look at; not changed here.
2. Contact markers are clip-timed (about 0 / 0.200 / 0.400 s), the beats and thuds are BEAT-timed (0 / 0.213 / 0.401 s): up to about 15 ms apart at any cap, 11 ms
   early on marker 2 at 30 and 15 fps. Inside the 20 ms rule the F probe uses; whether it reads as one hit is for the manager's eye (listed below).
3. M1-13's "not counted" item is closed: avatar markers and boss reactions are now counted per burst (above).

## Not covered / UNVERIFIED
- How sound sits against the picture on a phone at 30 and 15 fps (manager's two-device list). The `FrameCap` hook busy-waits the client; it models a slow frame, not a phone's GPU.
- Boss reactions at 30 and 15 fps (the fight was run at 60 only), a Perfect fight burst (`hitPerfect`), a fight Miss (attack), and the avatar markers on a real touch tap.
- Whether the F file's three peaks land on the three contacts by eye and ear.

## Re-run
Hold `studio`; edit mode: sync, then install (as the run did) `ServerStorage.TmpSync` = `"return function()\n" .. SyncTest.lua .. "\nend"` and
`StarterPlayerScripts.HFB_SyncProbe` = `SyncProbe.lua` (both fetched from the DevSync server). Then per cap, `run_script_in_play_mode` (start_play):
`_G.HFB_SYNC_CAPS = { 60 }` (then 30, 15; add `_G.HFB_SYNC_FIGHT = true` for the fight phase), `require(game.ServerStorage.TmpSync)()`. The result is 80 KB (the
`[HFB] TestReport` warnings): filter its JSON for lines starting `SYNC`, `SYNCPROBE`, `PASS`, `FAIL`. Remove both instances after.
