# M1-14: client Carry, Hazards (the Rolling Log), Base and prompts (scripter, 2026-11-25)

Quality pass: Function. Spec: `requirements/m1-contract.md` B, C, I; `requirements/m1-carry-base-income.md`; API from `verification/m1-11-server.md`.

## Files (game repo `projects/huss-for-bosses/`)
- New in `src/StarterPlayer/StarterPlayerScripts/Controllers/`: `Clock.lua`, `BossVisuals.lua`, `Carry.lua`, `Hazards.lua`, `Base.lua`.
- Edited: `Main.client.lua` (starts Clock, Carry, Hazards, Base in a pcall loop after `TestClient.init()`; structure kept), `Controllers/TestClient.lua`
  (`setProbes`: `carry`/`base`/`log` reports, `AutoInteract`), `Ui/Counters.lua` (`popCash`), `Shared/TestHooks.lua` + `team/test-hooks.md` (`AutoInteract`),
  `team/decisions.md` (M1-14a..g), `team/lessons.md`.
- Check script: `team/verification/m1-14-client/client-check.lua` (full first version; the last runs were trimmed copies, see below).
- No server file changed.

## How it was run
Studio MCP, lock `studio` as `scripter-m1-14` (released). Edit mode `DevSync()`; then `run_script_in_play_mode` (start_play, the real client running, `HFB_ReportBeats = true`)
with a server script driving the real server modules (like the M1-11 check) and reading the real client's `Profile.TestReport` `carry` / `base` / `log` reports.
Press paths ran through `HFB_AutoInteract` (`Input.fire "interact"`), so the client's own prompt gating and `Carry.Grab` / `Base.Place` sends were exercised.

## Results (play mode, real client; all values read from client reports)
| Area | Result |
|---|---|
| Log drawn from the server clock | Drawn offset (measured on the model's pivot at render time) equals `SharedHazards.logOffset(t)` evaluated by the server at the report's own t: 0.000 studs difference at a waiting sample (15.000) and at moving samples (12.465, 9.977, ...): **PASS** (within 0.05 asked, exact in practice) |
| Clock | no hook: client offset 0; `HFB_ClockOffset = 2.3`: client offset 2.268 (33 ms latency, within 0.05) and the drawn log followed the shifted clock; back to 0 after clearing: **PASS** |
| Win -> carrying | server `carrying`; client report `hop = true` (pad boss `defeat` hop), then `carried = true`, `rock = carryRock`, pad boss hidden (`hidden`), within 2 s: **PASS** |
| Clone on the head | after the write in RenderStepped the clone's pivot is 0.00 studs from the head target (while standing and while walking 14 studs: clone at (84, 186.2), head (84.0, 186.2), max error 0.000): **PASS** |
| LogForce = hit | server `dropped`; client: `carried` gone, dropped boss exists, plate "5" then 4, 3, 2 counting down, Grab prompt up at 6.7 studs: **PASS** |
| Prompt gating | 30 studs from `dropPos` with E held: Grab prompt down and **no** `Carry.Grab` sent (server refusal counters unchanged 0 -> 0): **PASS** |
| Grab | 9 studs away with `AutoInteract`: the client sent `Carry.Grab`, server `carrying`, client `carried`, `carryRock`, no plate, no prompt: **PASS** |
| Grace over | not grabbed: server `none`, client st `none`, nothing carried or dropped, prompts down: **PASS** |
| Place prompt | carrying and 25+ studs from the plot: no Place prompt; at Spot_1: prompt up, all 10 spots glow (`glowOn 10`): **PASS** |
| Place | `AutoInteract` sent `Base.Place`: server placed spot 1; client: `placed 1`, glow off (`glowOn 0`), prompt down, carry `placed`, placed boss playing `halfIdle`: **PASS** |
| Pad cash | `ClockOffset 30`: pad 1 shows `$32`..`$34` with a 1-slab stack and label equal to the number; the server collected 35 one second later (within the 1 s of display lag, floored seconds); pad empty on the client after the collect: **PASS** |
| Errors | no `[HFB]` warning or error on the server log across all runs; client warns do not reach the MCP (see lessons), so client-side warnings are `UNVERIFIED` except what the reports show |
| `check_skin.py` | 0 hits (49 files) |
| `check_guard.py` | clean (18 studio scripts) |

Run history: first run found two real faults, both fixed (a template taken before the pad boss's children had arrived, so `BossMoves.loop` returned false; headDist read
before the render-step re-base). The tables above are from the runs after the fixes (full run B 14 pass; its one failure, headDist while walking, was the measurement point, re-measured
after the write in a third run: error 0.000). The log-drawing, clock, drop and cash checks passed in the first full run too (24 pass; its pad-cash tolerance 30..33 was set too tight, 34 shown).

## Not checked
- Anything on screen (below). Walk-in grab (server side, M1-11), the thump's look, the slab stack look, the warning shadow, the Highlight glow, the plate billboard.
- Real key presses, gamepad, touch (routing only, via `Input.fire`).
- Two players; another player's plot; a respawn while carrying (handled: `CharacterAdded` clears the visuals; not run).
- The `Counters.popCash` fly (view code; ran without error but its position and tween are on screen only).

## On-screen checks owed (main session, computer use; `UNVERIFIED` until looked at)
1. Win Chomp Frog at 1000 Power (`HFB_SetPower`): the frog does its defeat rattle, hops onto the head, and the one on the pad disappears; the carried frog stands 0.5 stud above the head, leans back and rocks; the avatar's arms are up.
2. Walk the lane with `HFB_LogForce` unset: the log rolls across; about 0.6 s before it moves, an orange slab on the ground shows where it will be; the roll looks like rolling (the stand-in is a 36-long cylinder whose axis is across the lane, so its roll will look wrong until the real log mesh lands).
3. Be hit (`HFB_LogForce = hit`): the frog drops lying on its back at the spot, the white square plate counts 5 to 1 with a draining orange bar; the GRAB prompt at the bottom centre; walking into it or pressing E / X / the plate picks it up; after 5 s it vanishes.
4. At the base carrying: empty spots glow yellow and pulse; the PLACE prompt shows only within range; the frog drops 4 studs onto the spot with a squash (it flashes white on the thump: see TEAM CALL M1-14d) and then idles bobbing halfway.
5. A placed frog faces its cash pad; the pad shows `$N` and a green slab stack growing; stepping on the pad flies `+$N` into the cash plate and the plate bumps.
6. The pad boss returns on the pad after `backIn` seconds (`HFB_PadFastBack`), idling.

## Server issues found
None blocking. `Base.State` and `Zones.Clock` behaved as documented. Note for the builder (M1-12, still open): the stand-in log's rest pivot sits at Y 2.2 with a 4-stud thickness, so the log is drawn 0.8 stud lower than the real 6-stud log will be; the warning slab's ground height comes from a raycast, not from the log, so it is right either way.
