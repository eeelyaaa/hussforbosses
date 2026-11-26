# M1-07: the client punch (scripter, 2026-11-25)

Task: `board.md` row M1-07; spec `requirements/m1-contract.md` A, C, D, H, I, L and `m1-punch-and-fight.md`.
Quality pass: Function. Files: `src/StarterPlayer/StarterPlayerScripts/Main.client.lua`, `Controllers/Input.lua`,
`Ring.lua`, `BurstClock.lua`, `Fight.lua`, `TestClient.lua`.

How it was run: Studio MCP, `studio` lock held as `scripter-m1-07`. Edit mode `require(game.ServerStorage.DevSync:Clone())()`,
then three `run_script_in_play_mode` (start_play) server scripts that set hooks, place the character, and collect
every `Profile.TestReport` the real client sends (`ReportBeats`). The real server (M1-06) answered every report.
The scripts are in this report's "Scripts" section in outline; full text was kept in the session scratchpad.
After the runs: Studio back in edit mode, no `HFB_` attribute left in the edit place, marker still true.

## Results
| Check | What was seen (client reports; server numbers where named) | Result |
|---|---|---|
| Beats fire in order with the right offsets (60 fps) | 13 bursts: beat 1 at 0.000, beat 2 at 0.215 to 0.218, beat 3 at 0.401 to 0.417 s from t0 (Heartbeat quantised, under one frame late, `lateFrames` 0). One F start per burst (`starts = 1`) | PASS |
| A late frame fires every missed beat, in order | `AutoTap = lag` (one 0.45 s frame after the tap): beat 1 at 0.000 (frame 1180), beats 2 and 3 both at 0.468 in frame 1182, in order, none dropped | PASS |
| Frame caps | `FrameCap = 15`: beats at 0, 0.267, 0.467; `FrameCap = 30`: 0, 0.233, 0.433; never early, never reordered | PASS |
| Grading | `AutoTap good`: taps at +63 to +74 ms, graded Good (bag window 45/110); `perfect`: +3 to +7 ms (-10 ms at 30 fps), Perfect | PASS (after a fix, below) |
| A Miss launches no burst; the ring restarts after 0.61 s | `AutoTap miss`: three rings timed out, no `beats` report, each next ring `cause = miss`, `gap = 0.61` | PASS |
| After a Good/Perfect the next ring starts at t0 + 0.61 | every ring after a burst: `cause = burst`, `gap = 0.61` | PASS |
| A tap during a burst is ignored | `AutoTap busy`: the second tap 100 ms into the burst -> `ignored busy`, one burst, no report sent | PASS |
| A tap earlier than landing - 0.35 s is ignored | `AutoTap early`: `ignored early`, then the Good tap of the same ring graded normally | PASS |
| Speed 10 schedule | `SetSpeed 10`: the server's `Punch.Schedule` arrived, rings ran with `close = 0.5`, mixed grades, gaps 0.61 | PASS |
| Server agreement | bag run: server `accepted = 20`, `refused = {}`, `dropped = 0` over Good, Perfect, Miss, busy, early, lag, caps, Speed 10 | PASS |
| Fight started from the Huss press in the ring | standing in `Z1.Pads.Fixed.Ring`, the press sent `Fight.Start`; server log `started`, band `fair`, health 250; the client's rings switched to `ctx = fight` with windows 110/45 | PASS |
| Fight to a win, B22 | 3 Good bursts; server beats 225, 200, 150, 125, 100, 50, 25, 0 (`won` on burst 3 punch 2); the client's burst 3 beat 3 carried `noContact = true` (cutContact landed before it fired); `win` ended the client's fight (ring stopped) | PASS |
| Fight to a loss | no taps: the client reported three timed-out Misses (gaps 0.61), server hearts 2, 1, 0, `loss`; server WalkSpeed back to 16 | PASS |
| Inputs per `docs/controls.md` | `Input.route`: F, MouseButton1, ButtonR2 -> punch; E, ButtonX -> interact; Backspace, ButtonB -> run; touch: HussButton, PromptButton, RunButton (Ui calls `Input.fire`) | PASS (routing) |
| `ForceInput` | `touch`, `gamepad`, `keyboard` each reported back by `Input.kind()` | PASS |
| `check_skin.py`, `check_guard.py` | 0 hits, 0 lex errors; 10 studio scripts guarded | PASS |

## Fixed during the check
- `AutoTap good` first graded Perfect (dMs 40 to 49; M1-06 saw the same). Cause: the tap went out on the frame where
  `now + dt/2 >= target`, with `dt` taken from RenderStepped, which ran at about 6 to 12 a second in the Studio play
  client against Heartbeat's 25 to 60 (reported `rsPerS`, `hbPerS`). `dt` now comes from Heartbeat, and `FrameCap`
  and the lag frame hold the Heartbeat step (TEAM CALL M1-07g). After the fix Good taps landed at +63 to +74 ms.

## Not checked (owed)
- Real key presses, gamepad and touch: the MCP cannot press keys; routing and `Input.kind()` were checked, the presses
  were made through `Input.fire`. The touch path is `HussButton.onTap -> Input.fire("punch")`; not pressed.
- `Fight.Run` (Backspace, B, the Run button): wired, not sent in a check (it needs a real press).
- The boss's moves: `Z1.Pads.Fixed` has no `Boss` model in the place yet (M1-12), so no BossMoves call ran.
- The burst voice: no `Controllers/Audio` yet (M1-13); BurstClock counts F starts through its no-op.
- The avatar clip: Avatar's clip ids are 0, so `startJab` is a no-op that warns once.
- The fight camera and the held movement on the client, the HUD driven by the controllers: on screen only (below).

## On-screen checks for the main session (computer use)
1. Play solo, stand on the bag pad: the Huss button shows (mode bag), the ring shrinks and lands at 1.2 s; press F or
   left mouse as it lands: the band flashes, GOOD/PERFECT pops, three pips fill on the three punches and clear, the
   Power number pops three times (third bigger) and the counter climbs by 4 (Good) or 8 (Perfect).
2. Tap well before the ring lands: no punch; tap during the punches: nothing happens.
3. Let a ring pass without tapping: the ring greys, the button shakes, a new ring starts about 0.6 s later.
4. Walk into Chomp Frog's ring with 25 Power (`HFB_SetPower = 25`): the button reads HUSS! (start) and the prompt
   shows F; switch to a gamepad: the glyph changes to RT. Press: the camera moves behind the player facing the boss and
   stays put, the player cannot walk or jump, the fight overlay shows health 250 and three hearts.
5. In the fight press Backspace (and once the Run button): the fight ends, the camera returns to normal, walking works.
6. Win a fight: the overlay hides, the camera returns, walking works. Lose one (no taps): hearts go 3, 2, 1, 0, then the same.
7. Device emulator (a phone): the Huss button tap punches on the ring landing.

## Scripts (outline)
1. Bag: `Wipe`, `ReportBeats`; character to `Plot1.BagPad`; phases `AutoTap` good 3.7 s, perfect 1.9, miss 3.0, busy
   1.9, early 1.9, lag 1.9, good at `FrameCap 15`, perfect at `FrameCap 30`, `SetSpeed 10` + mix 5 s; read
   `Systems.Punch.stats`.
2. Grading re-check after the fix: good 5.6 s, perfect 3.6 s, `ForceInput touch`.
3. Fight: `SetPower 25`, `PadFastBack 1`, character into `Z1.Pads.Fixed.Ring`; `AutoTap good` 9 s; back into the ring,
   no taps 7 s; read `Systems.Fight.stats.log`.
