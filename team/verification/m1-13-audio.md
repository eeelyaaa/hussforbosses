# M1-13 audio: the Audio controller, load check, envelope probe on the uploaded F, sync test (audio-specialist, 2026-11-25)

Studio MCP, `studio` lock held as `audio-m1-13` (released). Edit-mode sync, then play-mode runs. **How anything sounds is `UNVERIFIED`**
(agents can't hear); everything below is counts, times and load results. `check_skin.py` 0 hits; `check_guard.py` 18 scripts guarded.

## Files
`src/StarterPlayer/StarterPlayerScripts/Controllers/Audio.lua` (new), `studio/checks/Probe.lua` (new), `studio/checks/SyncTest.lua` (new),
`src/ReplicatedStorage/Skins/brickbrawl/Sounds.lua` (`F_BEAT_IN_FILE` final), `team/assets.md` (Checked column), `team/decisions.md`
(TEAM CALLs M1-13a to d), `team/manager-todo.md` item 7. `Main.client.lua` was not touched: it already `init`s and `setAudio`s the controller
(proved by the runs: F plays came from BurstClock's call).

## 1. Every id loads (ContentProvider:PreloadAsync on a Sound per id, edit mode)
| Slot | Id | Status | IsLoaded | TimeLength | Local file |
|---|---|---|---|---|---|
| F | 127740860120528 | Success | true | 0.5940 | 0.594 |
| 02 A | 133382295573645 | Success | true | 0.2390 | 0.239 |
| 01 A | 87792871818595 | Success | true | 0.2400 | 0.240 |
| thud 1 | 100565015513028 | Success | true | 0.1505 | 0.151 |
| thud 2 | 108906304686894 | Success | true | 0.1506 | 0.151 |
| thud 3 | 131000564218509 | Success | true | 0.1412 | 0.141 |
| swish | 120181524699792 | Success | true | 0.2145 | 0.214 |
| sting | 92977560674627 | Success | true | 0.4000 | 0.400 |
The controller's own preload (edit-mode unit run) also read Success for all nine of its Sounds (F1, F2, two singles, three thuds, sting, swish). Lengths equal the local files to the rounding, so the
re-encode added or removed no padding. Limit: Studio plays under the group owner's account; it cannot show whether the live experience is
permitted to play a group asset (manager-todo 7 lists the names). Moderation state is not visible to agents.

## 2. Envelope probe on the uploaded F (`studio/checks/Probe.lua`, edit mode)
**Method, plainly:** an `AudioPlayer` (the uploaded asset) wired by a `Wire` only into an `AudioAnalyzer` (no output, nothing audible) plays at
`PlaybackSpeed` 0.25 (twice) and 0.1; each Heartbeat records `TimePosition` and the analyzer's `PeakLevel` (one value per audio block, about 21 ms real,
so about 5 ms of file at 0.25 and 2 ms at 0.1). Onset of a part = the last sample before the part's peak that is 20 dB under that part's peak (the pack's
method; the local `probe.py` uses a 5 ms RMS window, the in-Studio one a block peak, so the two differ by a few ms). Parts searched in windows around
the local onsets. Limits: time resolution of one block; an unknown constant lag between `TimePosition` and the analysed block (not measurable here;
the gaps between parts do not carry it). I did not record a loopback; this is the analyzer path.

| | Part 1 | Part 2 | Part 3 |
|---|---|---|---|
| Peak at (0.1x pass) | 0.032 | 0.254 | 0.459 |
| Onset, -20 dB (0.1x pass, final) | **0.004** | **0.237** | **0.418** |
| Onset, -20 dB (0.25x passes, both) | 0.000 (ramp inside 5 ms) | 0.235 | 0.416 |
| Local file (probe.py, -20 dB) | 0.007 | 0.233 | 0.420 |
| BEAT + F_LEAD (0 / 0.213 / 0.401 + 0.010) | 0.010 | 0.223 | 0.411 |
| **Off the beat (ms)** | **-6** | **+14** | **+7** |
| Rule (20 ms) | PASS | PASS | PASS |
Other: TimeLength 0.5940; lead to -30 dB 2 ms (0.1x) / 5 ms (0.25x); loudest block peak 0.705 (linear). Raw envelopes (time:peak x1000) are in the
console of the run and reproducible with `run("checks/Probe.lua")`; the script prints `PASS Probe part n`.
Reading: part 2 is the nearest to the limit (+14 ms) and part 1 the earliest (-6 ms); the spread (20 ms) comes from where on the ramp "onset" is read,
as the local numbers also showed (-10 dB gives 0.021, 0.237, 0.425). Between parts the gaps are 0.233 s and 0.181 s at -20 dB (brief 0.213, 0.188);
at -10 dB 0.216 and 0.188. **B21 outcome: not triggered. `Config.Punch.BEAT` unchanged; `F_BEAT_IN_FILE = {0.004, 0.237, 0.418}` written.**

## 3. Sync test (`studio/checks/SyncTest.lua`; play mode, real client path, AutoTap good, ReportBeats, Speed 10)
One cap per MCP call (a single 3-phase call timed out at the tool). 20 bursts judged per cap (21 collected).
| FrameCap | Result | Worst beat lateness (limit 1/cap + 4 ms) | F plays per burst | F Play() after t0 (worst) | thuds per burst | Reports dropped |
|---|---|---|---|---|---|---|
| 60 | **PASS** (script line) | 16.0 ms (20.7) | 1 on all 20 | 0.167 ms | 3 | 0 |
| 30 | PASS read from the raw reports (the script's summary line was not returned by the tool): beats 2 and 3 at 0.233 and 0.433 on every burst = +20 and +32 ms (37.3) | 32 ms | 1 on all 20 | 0.095 ms | 3 | 0 |
| 15 | **PASS** (script line) | 66.0 ms (70.7) | 1 on all 20 | 0.089 ms | 3 | 0 |
All beats arrived in order 1, 2, 3, never early; `BurstClock.starts` was 1 per burst; `Sound.Played` events equalled F plays (21 of 21). The late beats
at 30 and 15 fps are the frame-quantised schedule (`lateFrames` 1 and 3), not drift. M1-19 re-runs this at its own wave.
Not counted: Avatar's contact frame and BossMoves' reaction (no counters at M1; they subscribe to the same `BurstClock.onBeat` the thud does, and the
thud count of 3 per burst shows that event fired three times). Listed UNVERIFIED.

## 4. Controller checks
- Edit-mode unit run of the module: F handle has `PlaybackSpeed` 1, group `HFB_Burst`, volume 0.55; `fadeBurst(handle, 30)` then 0.15 s later the Sound is
  not playing and its Volume is back at 0.55; the pool alternates F2 / F1 (two distinct voices); `singleHuss()` x4 = 02A@0.5500, 01A@0.6875 (= 0.55 x 1.25),
  02A, 01A (strict alternation); groups `HFB_Burst` (4 Sounds: F1, F2, two singles) and `HFB_Effects` (5: three thuds, sting, swish).
- Play-mode mix run (AutoTap mix 30/30/40, 10 bursts): 6 Perfect bursts -> 6 stings; 4 Good -> no sting; every burst `f = 1`; 9 bag Misses before the last
  report -> 9 swishes (10 misses reported by the client rings; the tenth came after the last audio report); thuds 30 = 3 x 10.
- Fade on a refused tap: unit-checked above (30 ms tween then stop and restore); not triggered by a real server refusal in play mode (the server accepted all
  reports). `BurstClock.cancel` calls `Audio.fadeBurst` (40 ms for Run/knockdown). UNVERIFIED end to end.
- No swish on a fight Miss: coded (`Ring.current().context == "bag"`); not run (no Boss model in the place at this wave). UNVERIFIED.

## Ear and screen checks for the manager (nothing here can be heard by an agent)
1. Stand on the bag pad, tap on the ring: one "huss huss huss" (F) per tap, starting with the tap, each huss landing with a punch contact and a thud; says nothing about
   feel yet. Question: does each huss line up with its punch, at 60 fps and on a phone?
2. A Perfect adds a short bright tick on top of F and the thuds are a little harder; a Good does not. Question: is the sting too loud or too sharp over F?
3. A missed ring on the bag gives a soft air swish (no huss); in a boss fight a Miss gives no swish (the boss wind-up cue is M4).
4. Are the stand-in thuds (all one bag tier) acceptable as a placeholder? Is 01 A (x1.25) the same level as 02 A when they alternate (not played at M1 until the thief punch, M2)?
5. Levels: F 0.55, thud 0.5, sting 0.4, swish 0.25 are starting numbers, not tuned by ear.
Fairness: all cues are the player's own, 2D, and play only on their own client; no cue lets one player hear another's timing at M1.
