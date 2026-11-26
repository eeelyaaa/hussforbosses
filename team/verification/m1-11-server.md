# M1-11: server carry, the Rolling Log, base, income (scripter, 2026-11-25)

Task: `board.md` row M1-11; spec `requirements/m1-contract.md` sections A, B, C, E, K, L and
`requirements/m1-carry-base-income.md`. Quality pass: Function.

## Files (game repo `projects/huss-for-bosses/`)
- `src/ReplicatedStorage/Shared/Hazards.lua`: the Rolling Log as a pure function of server time (both sides).
- `src/ServerScriptService/Systems/Carry.lua`: carry state, win -> carrying, drop, grace, `Carry.Grab`, walk-in grab,
  loss on death/reset/leave/grace end, carry speed held and checked, hook `GrantBoss`.
- `src/ServerScriptService/Systems/Hazards.lua`: the server's hit test each Heartbeat, drop + 6-stud push, small push
  for non-carriers, hook `LogForce`.
- `src/ServerScriptService/Systems/Base.lua`: `Base.State`, `Base.Place`, spot `Glow` attributes.
- `src/ServerScriptService/Systems/Income.lua`: income from stamps, collect by server-side pad touch, `Base.Collected`.
- `team/verification/m1-11-server/server-check.lua`: the play-mode check.
- Edited: `team/requirements/m1-contract.md` (row `Base.State`, see "Contract changes"), `team/decisions.md` (M1-11a..g).
- Main needs no edit: `Main.server.lua` starts `Hazards, Carry, Base, Income` in that order (ORDER_AFTER).

## Checks run (Studio MCP, holding `studio` as `scripter-m1-11`, 2026-11-25)
1. Edit mode: place 139279056607944, marker true; `require(game.ServerStorage.DevSync:Clone())()` ->
   `DevSync: 59 files, 0 updated, 0 removed, 0 modules swapped` (my files already in from an earlier wave sync;
   `Systems.Carry/Hazards/Base/Income` and `Shared.Hazards` present). Slice as built by M1-12 (log stand-in at
   (206, 2.2, 248), 7 `HFB_Blocker` parts; nothing here raycasts, so the blockers need no exclusion in my code).
2. `run_script_in_play_mode` (`start_play`, real client running) with
   `team/verification/m1-11-server/server-check.lua`: **54 PASS, 0 FAIL, 0 errors, 0 `[HFB]` warnings**, 28.9 s.

| Area | Result |
|---|---|
| Win -> carry | real fight at Power 1000 (one Good punch wins): `Carry` state `carrying z1_t1`, session `carry.uid` set, WalkSpeed 12 |
| Refusals while carrying | `Fight.canStart` -> `carrying`; a second `Carry.begin` refused (`busy`), uid unchanged |
| Speed enforced | WalkSpeed set to 40 -> back to 12 next step; a 20-stud one-frame jump -> pulled back (0.00 studs from the start); a real walk (`Humanoid:MoveTo`) 21.4 studs in 2 s (12/s with acceleration), not pulled back |
| Log, `LogForce = clear` | 8.5 s (more than a cycle) standing on the log line: never hit |
| Log, natural hit | standing on the lane centre, on the log line: hit when the log's offset was -3.15 (inside 3 + 1.25 of the carrier); `dropped`, `graceEnds` = hit + 5.00 s, pushed **6.00** studs along the lane (0 across), `dropPos` 0.00 from where the carrier stood, WalkSpeed 16, fight still refused during the grace |
| Grab | wrong uid -> `uid`; uid 42 -> `bad`; 20 studs away -> `range`; 9 studs away inside the grace -> `carrying`, WalkSpeed 12; walking within 1 stud -> grabbed by the server |
| `LogForce = hit` | drops at once on the log's strip |
| Grace over | not grabbed in 5 s -> `none`, session `carry` nil; a late grab -> `state`; a fight is no longer refused `carrying` (it said `ring`: the player was not at the pad) |
| Place refusals (no state change) | not carrying -> `notCarrying`; spotIndex 0, 11, 1.5, "1", NaN, inf -> `bad`; from the lane -> `range`; **standing on another plot's Spot_1** (a temporary owned-by-someone-else copy 300 studs away, destroyed after) -> `range`, own spot 1 still empty; on the taken Spot_1 -> `taken`, still carrying |
| Place | `GrantBoss` -> carrying, attribute consumed; all 10 spots `Glow = true`; own Spot_1 -> placed with the carried uid, carry `none`, WalkSpeed 16, every `Glow = false`; `Base.payload`: dense 10, spot 1 `income 1, capSeconds 7200`, spot 2 `false`, owner = player; Spot_2 placed |
| Income and collect | pad 1 holds 0 just after placing; `ClockOffset 30` -> 30; touching `CashPad_1` collected **30**, server cash +30, pad 1 empty after; `ClockOffset 9030` -> pad 2 **7200** (2 h cap), collect +7200 |
| Death | `GrantBoss`, then Health 0 -> `none` |
| Cleanup | 0 `HFB_` attributes left after play; Plot1 owner 0; one plot (the temporary copy gone) |

Refusal counters at the end: Base `{taken 1, notCarrying 1, bad 6, range 2}`, Carry `{state 1, uid 1, bad 1, busy 1, range 1}`.
3. `python tools/check_skin.py`: 0 hits. `python tools/check_guard.py`: 18 studio scripts, 0 without the guard.

## Not checked / on-screen
- Server-only checks through module calls after Net's limiter (the handlers are one line each: `Carry.tryGrab(player,
  payload.uid)`, `Base.tryPlace(player, payload.spotIndex)`); the client never fires `Carry.Grab`/`Base.Place` yet
  (M1-14). The real client's reception of `Carry.State`, `Base.State` (dense array with `false`), `Base.Collected` is
  M1-14's and M1-16's to read through `Profile.TestReport`.
- Nothing to look at on screen yet: the log's motion, glow, carried boss and stacks are all M1-14's client.
- Two players (a second plot does not exist in the slice); "only the dropper can grab" holds by construction (the
  drop lives in the dropper's own carry record, another player has none to grab).
- Jumping over the log: the hit test uses the body's feet (root - 3) to head (root + 2.5) against the log's radius,
  so a jump whose feet clear the log's top (6 for the real log; jump height 7.2) is not hit. Not measured.

## The API for M1-14 (client), as implemented
Server time below = `Workspace:GetServerTimeNow()` plus the server's `ClockOffset` hook; the client gets the same
timeline from `Zones.Clock { serverTime }` (offset = `serverTime - GetServerTimeNow()` at receipt).

| Remote | Dir | Payload, exactly as sent | When |
|---|---|---|---|
| `Carry.State` | s2c owner | `{ state = "none"\|"carrying"\|"dropped"\|"placed", uid = string?, creatureId = string?, dropPos = Vector3?, graceEnds = number? }` | `none` on join and when the boss is gone (grace over, death, reset, wipe); `carrying` on a win (after `Fight.State win`), on a grab, on `GrantBoss`; `dropped` on a log hit (`dropPos` = the ground under the carrier, `graceEnds` = server time + 5); `placed` (uid, creatureId) when it lands on a spot, followed by nothing (the next state is `none` implicitly) |
| `Carry.Grab` | c2s | `{ uid = string }` | Accepted only from the dropper, state `dropped`, same uid, before `graceEnds`, root within 12 studs (3D) of `dropPos`. Success -> `Carry.State carrying`. Refusal sends nothing. The server also grabs on its own when the root comes within 3 studs (flat) of `dropPos` |
| `Base.State` | s2c all | `{ plotId = number, ownerUserId = number, spots = { [1..10] = { uid, creatureId, level, income, stamp, capSeconds } or false } }` | **Dense array of 10, `false` = empty** (changed from the contract's `?`). On join (every plot to the joiner, the joiner's plot to all), on place, on every collect, on leave (owner 0, all false) |
| `Base.Place` | c2s | `{ spotIndex = integer 1..10 }` | Accepted: carrying (not dropped), own plot, spot empty, root within 14 studs flat and 10 vertical of the spot part. Success -> `Carry.State placed`, then `Base.State`. Refusal sends nothing |
| `Base.Collected` | s2c owner | `{ spotIndex = number, amount = number }` | When the server collects (root within 4 studs flat, 8 above, of `CashPad_<i>`); `Profile.Changed { cash }` and `Base.State` go out with it |

- Cash on a pad (client display): `income * math.min(math.floor(now - stamp), capSeconds)`, floored seconds (the pad
  fills once a second; TEAM CALL M1-11e). Negative -> 0.
- Glow: `Workspace.Plots.Plot1.Spot_<i>` attribute `Glow` (boolean): true on every empty spot while the owner is
  carrying (not while dropped), else false. Replicated attribute, read it; nothing else to compute.
- The log: `Shared/Hazards`. `track = Hazards.trackOf(workspace.Zones.Z1.Hazard_Log)` (reads the server-stamped
  `TrackHome` CFrame attribute: wait for it, `GetAttributeChangedSignal("TrackHome")`); each frame
  `Hazards.logCFrame(track, serverNow)` gives the log's centre (rotate the model for the roll yourself:
  angle = offset / radius about the lane axis); `Hazards.logOffset(t)` returns `(offset, phase, velocityAcross)` for
  the 0.6 s warning (`logOffset(t + Config.Hazards.WARN_S)` is where it will be). Never move the server's model.
  `Hazards.hits(track, rootPos, t)` is the server's exact test (for a local prediction, if wanted).
- `LogForce` (config hook, a replicated Workspace attribute): `hit` drops a carrier in the log's strip at once; the
  client may show the log at the carrier for it, or not (the check reads the server).
- Speed: the server sets `Humanoid.WalkSpeed` (12 carrying, 16 otherwise); the client must not set it.

## Contract changes (flag for M1-14 and the tech-lead)
1. `Base.State.spots`: dense array with `false` for empty (was `{ [number]: ...? }`). Contract C updated.
2. Pad cash is floored to whole seconds (contract C row updated with the formula).
3. No refusal remote for `Base.Place` / `Carry.Grab` (TEAM CALL M1-11f); if the client needs one, M1-01 adds it.
4. Requests to the tech-lead (Config owner): `Config.Hazards.SMALL_PUSH = 2`, `PUSH_COOLDOWN_S = 1` (constants in
   `Systems/Hazards` now); optionally `Config.Carry.WALK_IN_GRAB = 3` and the speed-check numbers (constants in
   `Systems/Carry`).
5. Request to the builder (M1-12): the real `Hazard_Log` pivot must sit on the lane's centre line at the crossing
   (X 206 in the slice), at the log's rolling-axis height (radius above the lane top), and the part(s) should be
   `CanCollide = false` (the hit test is the server's; a colliding server copy at rest would block the lane centre).
   The greybox stand-in is 36 long and 4 thick; the server uses `Config.Hazards.LOG` (12 long, 6 thick), not the
   part's size.
