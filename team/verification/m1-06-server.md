# M1-06: server punch, bag, Power, fight, zones, session (scripter, 2026-11-25)

Task: `board.md` row M1-06; spec `requirements/m1-contract.md` sections A, C, D, E, K, L and
`requirements/m1-punch-and-fight.md`. Quality pass: Function.

## Files (game repo `projects/huss-for-bosses/`)
- `src/ServerScriptService/Main.server.lua`: `Net.serverInit()`, `TestHooks.listenReports(Net)`, starts
  `Data/Session`, `Zones`, `Bag`, `Fight`, `Punch`, then any other `Systems/*` module with `start()` (M1-11's land
  with no edit here); prints `Skin.Id`.
- `src/ServerScriptService/Data/Session.lua`: in-memory profile (K), `get/set/onChanged/wipe/plot/onJoin`, plot
  assignment and spawn at `SpawnPoint`, hooks `SetPower SetCash SetStrength SetSpeed Wipe`.
- `src/ServerScriptService/Systems/Zones.lua`: pads from tag `HFB_BossPad` x `Config.Zones.PADS`, `Zones.Pads`,
  `Zones.PadBeaten` (hook `PadFastBack`), `Zones.Clock` (join, every 30 s, on `ClockOffset` change), per-player pad
  availability, `Zones.now()` (+`ClockOffset`).
- `src/ServerScriptService/Systems/Bag.lua`: own-pad test (`PAD_RADIUS` on the ground plane, 8 studs of height),
  Strength value, Power per beat, pad-entry signal.
- `src/ServerScriptService/Systems/Fight.lua`: `Fight.Start`/`Fight.Run`, r and band at start, health, hearts,
  B22, loss (knockback, 2 s knockdown, 5 s pad cooldown), Run, held in place (server half of B13),
  `Fight.onStart`/`Fight.onEnd` for M1-11.
- `src/ServerScriptService/Systems/Punch.lua`: `Punch.Schedule`, `Punch.Report` validation, the Heartbeat beat
  queue, stall rule; `Punch.stats` (refusals, drops, schedule and result sent, every applied beat) for checks.

## Checks run (Studio MCP, holding `studio`, 2026-11-25)
1. Sync: `require(game.ServerStorage.DevSync:Clone())()` -> `DevSync: 53 files, 0 updated, 0 removed` (already
   synced by an earlier wave sync; my six files present under `ServerScriptService`).
2. **Server check, client entry disabled** (`StarterPlayerScripts.Main.Enabled = false` in edit mode for the run so
   the real client's automatic Miss reports could not change the numbers; restored after). Script:
   `team/verification/m1-06-server/server-check.lua`, run with `run_script_in_play_mode` (`start_play`), forged
   reports through `Punch.report` (the handler after Net's rate limiter). **60 PASS, 0 FAIL, 0 errors**, 29 s:

| Area | Result |
|---|---|
| Boot | `[HFB] server up: env=Studio skin=brickbrawl place=139279056607944` |
| Join | Plot1 `OwnerUserId` = the player; character on `SpawnPoint` (0.00 studs flat); schedule sent on join |
| Schedule per Speed | re-sent on each change: 1:1.20/1.81 2:1.12/1.73 3:1.04/1.65 4:0.96/1.57 5:0.88/1.49 6:0.80/1.41 7:0.72/1.33 8:0.64/1.25 9:0.57/1.18 10:0.50/1.11 (ring/cycle), `burstLen` 0.61; sent on entering the bag pad |
| Good = 4 | gains 1/1/2; Power 1 at accept, 4 after the burst; beats at t0 + 0.000 / 0.213 / 0.401, applied 0.0 / 3.9 / 15.3 ms late |
| Perfect = 8 | Power 4 -> 12; values 2/2/4; applied 0.0 / 3.8 / 15.9 ms late (max 15.9 ms, under 20) |
| Refusals, no state change | 0.65 s after an accept -> `rate`; during a burst -> `busy`; Good without `tapServerTime`, 1 s in the future, 1.5 s old -> `grade`; off the pad -> `place`; fight report with no fight -> `place`; bag report in a fight -> `place`; 5 malformed payloads (string seq, unknown grade, unknown context, NaN tap time, infinite seq) dropped with no reply; Power stayed 12 |
| Miss on the bag | accepted, no gains, nothing added |
| Net limiter | 6 calls at 4/s -> 4 allowed |
| Fight.Start refusals | outside the ring `ring`; bad id `bad` (dropped) / unknown pad `pad`; carrying `carrying`; during a fight `running`; knocked down `knocked`; on cooldown `closed` |
| Fight at Power 25 (hook `SetPower`) vs Chomp Frog | r = 1, `fair`, 110/45 ms, health 250, hearts 3, WalkSpeed 0; gains 25/25/50; health after bursts 150, 50, 0; beats `17.1:225 17.2:200 17.3:150 18.1:125 18.2:100 18.3:50 19.1:25 19.2:0W`: **won on burst 3 punch 2, punch 3 sent and dealt nothing (no contact)**; released; pad closed then back (PadFastBack 1 s) |
| Hearts | reported Miss -> 2; **stall rule**: no report -> server Miss after 3.53 s (expected 0.61 + 1.2 + 1.2 + 0.5 = 3.51) -> 1; Miss -> 0 -> `loss`; knocked down 2 s; knocked to 10.0 studs from the ring centre; pad `closed` until 5 s, then open |
| Run | ends the fight, no knockdown, WalkSpeed restored |

3. **Real client, AutoTap = good** (client entry enabled, M1-07's files as synced): standing on the pad 9 s ->
   5 reports accepted, 0 refused, 0 dropped, Power 32 (four bursts of 8 and one Miss: the client reported
   `perfect`, see "For M1-07"); a fight started by the server at Power about 29 ended `win` in 3.6 s
   (`started:250 beat:221 192 134 76 18 0 win`), 0 server warnings or errors, no Net drops.
4. Cleanup: `HFB_AutoTap` cleared; 0 `HFB_` attributes left; marker true; client entry `Enabled = true`;
   Plot1 `OwnerUserId` 0 after play.
5. `python tools/check_skin.py`: my six files have 0 hits. The scan exits 1 on two files I do not own:
   `Controllers/Avatar.lua:215` (M1-10) and `Controllers/BurstClock.lua:108` (M1-07), each an `"rbxassetid://"`
   string.

## For M1-07 (the client), against contract C and D
- A Miss is answered `Punch.Result { accepted = true, grade = "miss" }` with no `gains`/`t0`; a refused report is
  `accepted = false` with `reason`.
- A Good or Perfect without `tapServerTime` is refused `grade`.
- A refused `Fight.Start` comes back as `Fight.State { state = "refused", fightId = 0, reason }` with the pad's
  numbers filled; reasons `pad, dead, running, knocked, carrying, closed, ring`. A malformed `padId` gets no reply.
- `ratio` is capped at 1e6 on the wire (Power 0 means r is infinite, band `impossible`).
- Observed: with `AutoTap = "good"` the client's bag reports were graded `perfect` (four of four). The fight
  reports in the same session were `good`. Worth a look in `TestClient`/`Ring` (a +70 ms tap should be Good on the
  bag's 45 ms Perfect window).

## Not checked / on-screen
- Server-only checks. No screen, so nothing for computer use. The client's own view of these events is M1-07's and
  M1-16's (through `Profile.TestReport`).
- Beat lateness is Heartbeat-bound (up to one 60 Hz step, 16.7 ms); a slow server frame could push a beat past
  20 ms. M1-16's BurstValues measures it again under load.
- Two players at once (plot 2 does not exist in the slice; a second player gets no plot and a warning).
