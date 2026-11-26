# M1: carry home, the Rolling Log, one base plot, placing, income and collecting

Build to `m1-contract.md` sections B, C (`Carry.*`, `Base.*`, `Zones.Clock`), E (`Carry`, `Hazards`, `Base`, `Income`),
K, L. Quality pass: **Function only**.

## The brief
"Carry the beaten boss home past each zone's hazard, place it on your base where it earns cash" (brief, "The
idea"). Systems 6, 7, 8: carrying is 12 studs/s (16 with Fast Carry); a hazard hit drops the boss, pushes the
carrier about 6 studs back, no stun; a dropped boss lies where it fell for 5 s and only its dropper can grab it,
else it is gone and the player may fight for another; one plot with spots, a cash pad in front of each, the Place
prompt on an empty glowing spot; a placed boss adds cash to its pad once a second (computed from a time stamp, no
per-boss loop), pad holds 2 h, walking over the pad collects.

## Goal and player outcome
After winning, the frog shrinks onto the player's head; they walk home through the gate past the Rolling Log; a
hit drops the frog and a Grab prompt lets them pick it up within 5 s; at the plot an empty spot glows; Place puts
the frog on it with a thump; $1 a second starts stacking on its pad; walking over the pad collects.

## Tasks
- **M1-11 scripter (opus), server** (wave 3): `Shared/Hazards.lua` (the log's position as a pure function of
  `GetServerTimeNow() + ClockOffset`: 12 studs long, crosses the 36-wide lane in 3 s, waits 1 s each side; also
  `Hazards.hits(pos, t)` with `Config.Hazards.HAZARD_TOLERANCE` in the player's favour), `Systems/Hazards` (the
  server tests each carrier each Heartbeat step, 0.6 s warning is the model's, not the server's), `Systems/Carry`
  (state on win from `Fight`, drop on hit with the 6-stud push, the 5 s grace, `Carry.Grab`, loss of the boss
  when the grace ends or the carrier resets or leaves, speed set to `Config.Carry.CARRY` while carrying;
  `GrantBoss` hook), `Systems/Base` (plot 1 owner, `Base.State`, `Base.Place` rules, empty-spot glow state is a
  `Spot` attribute `Glow = true` the client reads), `Systems/Income` (income = base x `LEVEL_MULT` x 1, stamp,
  cap, `Base.Collected` on pad touch within `COLLECT_RANGE`, `Profile.Changed cash`), test hooks `LogForce`,
  `GrantBoss`.
- **M1-14 scripter (sonnet), client** (wave 3): `Controllers/Carry` (the boss clone on the head: scaled so it is
  never over 6 studs, feet 0.5 stud above the head, leans back 8 degrees and rocks 4 degrees; calls
  `BossMoves.loop(model, "carryRock")` and `Avatar.carryHold(true)`; the dropped boss lying on its back with a
  white square timer plate for the grace time; the Grab prompt; the hop onto the head on a win is
  `BossMoves.play(..., "defeat")` followed by the carry), `Controllers/Hazards` (animates `Hazard_Log` from
  `Shared/Hazards` and the server clock, the 0.6 s warning shadow on the ground), `Controllers/Base` (glow on empty
  spots while carrying, the Place prompt, the thump on landing = a 0.1 s squash of Body, cash stacks on pads from
  `Base.State`, the cash fly to the counter via `Ui/Counters`), prompts through `Ui/Prompts`.
- **M1-12 builder** places the log model, spots and pads (see `m1-world-slice-stud.md`).

## Acceptance criteria
1. A won fight puts the boss on the head (server `Carry.State carrying`) and the player's speed is 12.
2. The log hits a carrier on its path: the boss drops, the carrier is pushed back about 6 studs, the state is
   `dropped` with `graceEnds` 5 s ahead; with `LogForce = "clear"` it never hits. A grab inside 5 s returns the
   state to `carrying`; after 5 s the boss is gone and the player may fight again. Only the dropper can grab.
3. `Base.Place` on an own empty spot while carrying puts the boss on the spot (`Base.State`), carry ends; refused
   on a taken spot, a spot of another plot, out of range, when not carrying (no state change).
4. A placed Common earns $1 a second from its stamp; collecting at the pad gives the amount since the stamp (to the
   cent of the second), resets the stamp, raises cash on the server; a pad holds 2 h at most (`CapSeconds`).
5. The client never decides: remove the client's cash and it still arrives from `Profile.Changed`.
6. Carry home measured by the builder and the game-designer (`m1-core-loop-gate.md`, times).

## Risks
The hazard tolerance (a visible hit that the server missed, or the reverse); the push moving the carrier outside the
walls; the dropped boss's grab range; a carrier jumping over the log (jump allowed, brief team call).

## Suggestions from the vault (optional)
None added.

## Not asked for (do not build)
Other hazards (M3, zones 2 to 6); Fast Carry as a purchase (the config speed exists, the pass is M2); stealing,
the shield, lock pad behaviour, crate behaviour, spots-full sign states, selling, swapping, picking up, the boss
panel and upgrades (M2); spots 11 to 17 and ghost outlines' unlocks; offline earnings; saving; boss name tags beyond
the Power number; the cube confetti on placing (M4); other players' plots.
