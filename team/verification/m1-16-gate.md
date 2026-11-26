# M1-16: the M1 "Core loop" gate checks (scripter, 2026-11-25)

Spec: `requirements/m1-core-loop-gate.md`. Gate: a play-mode script plays the loop end to end with no errors; the server
owns every result. Quality pass: Function.

## Result
**Every play-mode check passed with 0 FAIL in the final run, also under the stub skin.** The CheckAll summary shows
258 PASS, 2 FAIL. Both FAILs are in CheckSkin's Studio part (A2, B): `Skins/brickbrawl` has no `Models.bags`,
`Models.hazards`, `Effects.stars` or `Effects.cubeBurst`, which the stub skin has. Those keys belong to the skin-key
owners (M1-02 skin keys / art; M1-17 already noted them). Not an M1-16 fix.

Raw summary of the final run (CheckAll `summary` mode, edit mode, printed verbatim):
```
CheckAll: | Check | Phase | PASS | FAIL | Failed |
CheckAll: |---|---|---|---|---|
CheckAll: | CheckSync | edit | 8 | 0 | - |
CheckAll: | CheckSkin | scan | 1 | 0 | - |
CheckAll: | CheckSkin | studio A-E | 11 | 2 | A2 brickbrawl skin has every M1 key; B brickbrawl and stub have the same key shape |
CheckAll: | CoreLoop | a | 22 | 0 | - |
CheckAll: | CoreLoop | b | 36 | 0 | - |
CheckAll: | Refusals | live | 6 | 0 | - |
CheckAll: | Refusals | a | 19 | 0 | - |
CheckAll: | Refusals | b | 32 | 0 | - |
CheckAll: | BurstValues | a | 31 | 0 | - |
CheckAll: | BurstValues | b | 26 | 0 | - |
CheckAll: | NoDelay | a | 8 | 0 | - |
CheckAll: | CoreLoop | a stub | 22 | 0 | - |
CheckAll: | CoreLoop | b stub | 36 | 0 | - |
CheckAll: FAIL, 13 rows, 258 PASS, 2 FAIL
```
`CheckSkin|scan` is part 1, the repo scan: `python tools/check_skin.py` -> `0 hits, 0 files that do not lex` (49 files).
`python tools/check_guard.py` -> `25 studio scripts, 0 without the guard`.

Per-check raw lines: `m1-core-loop.md`, `m1-refusals.md`, `m1-burst-values.md`, `m1-nodelay.md`; the summary alone:
`m1-checkall.md`.

## Files (game repo `projects/huss-for-bosses/`; nothing in `src/` changed)
- `studio/checks/CheckLib.lua`: shared helpers. Watchers for errors and `[HFB]` warnings, every `Profile.TestReport`,
  an observer on every c2s remote, and a ledger of every server profile change with its cause. Also the hooks, the
  client mute, forged reports, and the summary row.
- `studio/checks/CoreLoop.lua`: the nine steps. Phase `a` = steps 1-4, phase `b` = steps 5-8; step 9 runs on both.
  Arg `skin`.
- `studio/checks/Refusals.lua`: phases `live` (edit mode), `a` (punch and fight), `b` (base, malformed payloads, rate
  limits).
- `studio/checks/BurstValues.lua`: phase `a` (bag values, times, Miss restart, cycles, all-Perfect tap counts and
  windows), phase `b` (all-Good tap counts, B22 on punch 1 and 2).
- `studio/checks/NoDelay.lua`: one phase, 45 s of mixed fighting at Speed 10.
- `studio/checks/CheckProbe.lua`: a check-only client probe (fuzz, rate, BossMoves log). It is installed only for the run.
- `studio/checks/CheckAll.lua`: the driver (modes `prepare`, `install`, `arm`, `disarm`, `summary`, `cleanup`).
- Edited: `team/test-hooks.md` (three Studio-script switches), `team/decisions.md` (M1-16a..f), `team/board.md`,
  `team/lessons.md`. Curator note: `vault/inbox/notes/2026-11-25-play-mode-gate-driver-and-client-probe.md` (ro-team repo).

## How it was run (Studio MCP, `studio` lock as `scripter-m1-16`, released)
Place 139279056607944, marker true. Each step below is one MCP call:
1. `run_code`: `workspace:SetAttribute("HFB_CheckAllMode", "prepare"); require(game.ServerStorage.DevSync:Clone()).run("checks/CheckAll.lua")`.
   Output: `DevSync: 64 files, 0 updated`, CheckSync 8/0, CheckSkin 11/2, TmpChecks installed, Refusals/live 6/0.
2. Seven `run_script_in_play_mode` calls (start_play), each
   `xpcall(function() require(game.ServerStorage.TmpChecks.<Check>)({ phase = "<p>" }) end, debug.traceback)`:
   CoreLoop a, b; Refusals a, b; BurstValues a, b; NoDelay a. Durations 11.8 to 49.6 s; none timed out.
3. `arm` (CheckSkin with part 2: `HFB_ForceSkin = stub`), then CoreLoop a and b with `skin = "stub"`. The server
   printed `[HFB] server up: env=Studio skin=stub`. Then `disarm`.
4. `summary` with the 13 rows above, then `cleanup`. Read back: 0 `HFB_` attributes on Workspace, no `TmpChecks`, no
   probe, no stub boss folder, marker true, Plot1 owner 0.

Before the final run, the scripts were debugged over earlier runs. These failures were in the checks, not in game code,
and each was fixed in the check:
- Spawn read before the server moved the character (the check now waits up to 3 s; it took 0.1 to 0.5 s).
- B22 read before punch 3's time had passed (the check now waits 0.6 s after the win).
- `Humanoid:MoveTo` did not move the carrier (M1-16e).
- The ledger did not tag the opening Wipe as a hook.
- The client mute let one Miss through (M1-16c).
- NoDelay had too few rings at Power 25 (now Power 20, 45 s).

## What the gate saw (final run)
- **The loop on the real client.**
  - The Good burst applied at 0 / 0.213 / 0.401 s, +0.0 / +2.8 / +15.1 ms late, Power 1, 2, 4.
  - Perfect gave +8 (2/2/4). A Miss started the next ring 0.610 s later with no Power.
  - At Power 25 the client's Huss press sent `Fight.Start`: r 1, fair, 110/45 ms, health 250, hearts 3.
  - Server health went 225 200 150 | 125 100 50 | 25 0W, with burst 3 punch 3 dealing nothing. The client's
    beat 3 carried `noContact`.
  - The pad closed 9.4 s after the win (backIn 10).
  - Carrying at speed 12. The log hit with `LogForce = hit` pushed the carrier 6.00 studs back, with grace 5.00 s.
  - The client's `Carry.Grab` brought the boss back. The client's `Base.Place` on spot 1 placed it, and a second place
    was refused `taken`.
  - After `ClockOffset 30` the client pad read `$30`. Stepping on CashPad_1 collected 30 and server cash went 0 -> 30.
- **Server authority.**
  - Every power and cash change in the ledger had a server cause: an applied beat, a collect, or a check hook.
  - Every fight damage beat had an applied Punch beat behind it.
  - Each result came through its remote (Punch.Report, Fight.Start, Carry.Grab, Base.Place each > 0).
  - The check calls no request handler except the one forged `Base.tryPlace` that must be refused.
- **Refusals.** Rate, busy, place, carrying, ring, closed and running were each refused, with no state change.
  - The stall rule struck at 2.93 s (expected 2.90).
  - A client tap during a burst was ignored on the client: 0 refusals, +4.
  - Base.Place was refused for not carrying, out of range, 8 bad indexes, another plot's spot, and a taken spot.
  - The probe sent malformed payloads to all six c2s remotes (20, 14, 9, 13, 16, 13). No state changed and no handler
    errored. 16 Punch.Report payloads were dropped by the shape check, and `bad` was counted 9 times on Fight.Start,
    9 on Carry.Grab and 12 on Base.Place. Nothing was stored from TestReport.
  - Rate bursts of 10 in one frame were dropped exactly 6, 8, 8, 6, 6.
  - In the not-Studio simulation no TestReport handler was registered and the hooks read nil.
- **Burst values.** Cycles burst to burst were 1.817 s (Speed 1) and 1.117 / 1.116 s (Speed 10). Fight tap counts at
  r = 0.5, 1, 1.5, 2, 3, 5:
  - All-Perfect: 1, 2, 2, 3, 4, 7.
  - All-Good: 2, 3, 4, 5, 8, 13.
  - The bands were easy, fair, hard, veryHard, brutal and impossible, with windows 130/55, 110/45, 80/30, 60/22,
    45/16 and 35/12 ms.
  - B22 emptied the bar on punch 1 (Power 250) and on punch 2 (Power 125). Later punches made no contact.
- **No delay.** 8 wins and 2 losses. 23 fight rings were judged (17 after a burst, 6 after a miss), all at exactly
  0.610 s. BossMoves played 88 moves with 31 cuts, and every cut started the new move in the same call.

## Findings for other owners (no system code was edited)
1. **CheckSkin A2/B (skin-key owners, M1-02 / art):** `Skins/brickbrawl` misses `Models.bags.1`, `Models.hazards.1`,
   `Effects.stars` and `Effects.cubeBurst`. They predate this task.
2. **Nothing on the client listens to `Zones.Pads`.** There is no `OnClientEvent` for it in `StarterPlayerScripts`.
   Step 4 judges the pad number's colour from the server payload and `Config.Fight.BANDS`, as the spec asks, but no
   client draws the number. Owner: the HUD and world-number work (orchestrator to route; M1-08 or the gui-designer).
   On screen, `UNVERIFIED`.
3. **NoDelay counted 2 losses but only 1 `lastHeart` play.** One loss's last-heart reaction was not seen by the probe;
   maybe it was cut, or the loss came while another move ran. The ring timing was unaffected. For M1-20 to look at on
   screen.
4. A server `Humanoid:MoveTo` on the player's character no longer moves it with the M1-14 client running (M1-11's
   check used it). It affects only checks; noted in lessons.
5. The client's clock offset can be 0.06 to 0.87 s off within 3 s of joining. It had settled to 0.03 s by step 8.
   Only matters for checks that read it early.

## Not covered / UNVERIFIED (on-screen, for the main session)
- Nothing here looks at the screen. M1-20 owns the NoDelay look: run `NoDelay` with the Studio window visible and watch
  for the boss reaction being cut by the next hit, the attack on a Miss, and the ring never waiting.
- The stub-skin run proves the rules and the loop under grey boxes on the server and in the reports. It does not show
  how the grey boxes look on screen.
- Real key, touch and gamepad presses: everything went through `Input.fire` (AutoTap, AutoInteract).
- Two players, and a second plot.

## Re-run (M1-22)
Hold `studio`, then:
1. `prepare`.
2. The seven play calls, as printed.
3. `arm`, the two stub CoreLoop calls, `disarm`.
4. `summary` with the rows, `cleanup`.

Set each mode with `workspace:SetAttribute("HFB_CheckAllMode", ...)` before `run("checks/CheckAll.lua")`. Filter large
play-mode results (70 to 100 KB, from the `[HFB] TestReport` warnings) for lines starting `PASS`, `FAIL`, `NOTE` and
`CHECK`.
