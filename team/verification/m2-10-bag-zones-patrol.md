# M2-10: bag, Auto Punch, six zones, rolls, zones beaten, patrol (evidence)
Scripter (opus), 2026-11-25. Gate rows S2, S3, S4 (zones-beaten half), S5 (`requirements/m2-gate.md`), plus Power a
second for M2-26. Quality pass: **Function** only. Built to brief systems 2 to 5 and 14, `m2-contract.md` C ("Bag",
"Punch.Report with auto", "Zones"), D, E, the manager's P5. TEAM CALLs M2-10-1 to -8 are in `decisions.md`.

## What changed (game repo `projects/huss-for-bosses`, nothing committed)
- New `src/ReplicatedStorage/Shared/Patrol.lua`: the contract E ping-pong, the djb2 phase, and `Patrol.anchor` (a
  `PatrolAnchor` part if the pad has one, else the BossAnchor facing the lane). Pure, for server and client alike.
- `Config/Zones.lua`: 24 pads (`z<n>_fixed`, `z<n>_roll1..3`), `ROLL_S` 45, `ROLL_STAGGER`, `ROLL_ODDS` (brief table),
  `PATROL` {14, 4, 1.0, slack 1.5}, `LANE`. `Config/Bag.lua`: the brief's cost tables, `PAD_RANGE` 14, `TIER`.
  `Config/AutoPunch.lua`: pass keys, grades, purchase re-check.
- `Systems/Bag.lua`: `BuyStrength` / `BuySpeed` (range, cap, cash, spend then level, refund if the level write fails),
  `Bag.State` (join, 1 s after each spawn, on pad entry, on change), plot attribute `BagTier`, the pass cache
  (`Bag.owns`, delegates to `Systems/Passes.owns` once it exists), rebirth x(1 + n) and 2x Power in `Bag.value`,
  funnel `FirstStrengthBought`, `ReachedFirstBossPower`.
- New `Systems/AutoPunch.lua`: `AutoToggle` / `PerfectToggle` and `AutoPunch.refuse` for auto reports.
- `Systems/Punch.lua` (M2-06's file; the auto branch handed to M2-10 by TEAM CALL M2-06-2): the `pass` stub replaced by
  `AutoPunch.refuse`, then every timed rule as a hand burst; auto bursts mark no funnel and carry `auto` in
  `Punch.Result` / `Punch.Burst`. Nothing else in the file changed.
- `Systems/Zones.lua`: rolls on the server clock, `ForceRoll`, `PadsFast`, `SetZonesBeaten`, per-player beaten,
  `Zones.Pads` per player with `zone`, `rollEndsAt`, `beaten`, `patrol`, `Zones.bossPosition`, `zonesBeaten` written
  in `markBeaten` (fight wins only) through `Session.addZoneBeaten`.
- Checks: `studio/checks/Bag.lua` (a, b, c), `studio/checks/Zones.lua` (a, b, c).

## What ran (Studio MCP, `studio` lock held by `scripter-bagzones`, released after; play stopped; cleanup left no
TmpChecks, no stand-in pads, no `HFB_` attribute)
Edit mode: `require(game.ServerStorage.DevSync:Clone())()` (103 files; M2-09's new `Data/*` was in the sync), then
`HFB_CheckAllMode = "install"` + `checks/CheckAll.lua`, and `Bag`, `Zones` (later `Punch2`) added to `TmpChecks` from
the sync server. Each row is one `run_script_in_play_mode` (start_play), `require(game.ServerStorage.TmpChecks.<C>)({ phase = "<p>" })`.

| Check | Phase | Result | Notes |
|---|---|---|---|
| Zones | a | 19 / 0 | run 1: 18/1, a float tolerance in the check (step 0.04000001 vs 0.04 + 1e-9) |
| Zones | b | 7 / 0 | |
| Zones | c | 16 / 0 | run 1: 15/1, the check expected `state` for an auto bag report in a fight; it is `place` (the fighter is off the pad), which is the same rule |
| Bag | a | 23 / 0 | |
| Bag | b | 25 / 0 | run 1: 15/10, the Studio account OWNS the passes (below); the check now forces them off with `PassOwned` |
| Bag | c | 6 / 0 | |
| Punch2 (M2-06) | a | 25 / 10 | every FAIL is a doubled value (+2 for +1, +8 for +4): the account's real 2x Power now applies. Not a regression; the check needs `PassOwned` off |

Final: **Bag 54/54, Zones 42/42.**

## Patrol numbers (stand-ins, PROVISIONAL Q3)
14 studs each way at 4 studs/s, 1.0 s pause at each end: a 7 s leg, a 16 s period. The phase is the djb2 hash of the
pad id: z1_fixed is 251135, so 2.16 s. The boss walks along the lane, which runs along world Z, and faces the lane at
the turns. z1_fixed walks from Z 262 to Z 290 at X 233. Fight.Start accepts within ring 6 + `RING_SLACK` 2 +
`PATROL.slack` 1.5 = 9.5 studs of where the boss is now: 9.0 was accepted and 10.5 was refused `ring`. With the boss
12 studs along its walk, standing on the pad centre is refused (the player walks up to the boss). `Fight.State.bossPos`
is on the walk line.

## Power a second (for M2-26; forged auto reports at the exact cycle, Strength 1, no multipliers)
| | Speed 1 | Speed 10 | paper (`m2-punch-numbers.md` 4) |
|---|---|---|---|
| Auto Punch (Good) | 2.408 | 3.914 | 2.41 / 3.92 |
| Perfect Auto Punch | 4.816 | 7.827 | 4.82 / 7.84 |
No report was refused. The hand-play curves (real client, AutoPlayer) are still M2-26's.

## Gate rows
- **S2:** both cost tables match the brief: Strength totals 9,669,146,250 and Speed 8,634,600. The from-L6 formula holds.
  Buying covers the cash, cap and place (14 studs) refusals; one level per call; a forged `{ level, cost }` is ignored.
  The tier changes at 6 and is 6 at 30. A Speed buy resends Punch.Schedule. For Auto Punch: no pass gives `pass`, the
  toggle off gives `pass`, an auto Good is 4 and an auto Perfect is 8. Perfect needs Perfect Auto Punch, which works on
  its own (the web buyer) and also allows an auto Good. Auto untimed and auto miss give `grade`. Off the pad gives
  `place`. In a fight both contexts are refused. B20: a second auto tap or a hand tap during the auto burst gives `busy`.
  The multipliers apply through `Bag.value`: 2 rebirths with 2x Power make an untimed tap worth 6.
- **S3:** no buy or refusal changed Power. `ReachedFirstBossPower` fires at 25.
- **S4 (zones beaten):** a win adds the zone once, a second win does not add it again, and a loss writes nothing.
  `markBeaten` (fight win) was the only writer in the run (3 writes, 3 wins).
- **S5:** 24 pads. 100,000 rolls per zone came within 3.19 standard deviations of the odds. Every roll is from its own
  zone, from the first second. Timers are 15 s apart (M2-10-2). Rolls advance on the clock (PadsFast), and each roll
  sends Zones.Pads. ForceRoll works. A roll is the same for everyone. A beaten roll is closed until the pad rolls; a
  beaten fixed pad comes back after PadFastBack. The Zones.Pads payload is 4,231 bytes of JSON.

## Not verified / open
- **The world for zones 2 to 6 is not built.** The world has only `z1_fixed`, and the checks add stand-in pads. The
  builder must add 23 pad Models (below).
- **Fight spot (M2-06's `Fight.fightSpot` / `standAtSpot`):** these place the fighter from the server's boss model,
  which stands at the pad anchor, not from `bossPos`. Measured: with the boss 10.1 studs along its walk, the fighter
  was placed 5.0 studs from the pad centre (5.1 from the walking boss). At the 14-stud end the gap is about 9 studs.
  Request to the owner of `Fight.lua`: build the spot from `f.bossPos` (offset the bounding box by
  `bossPos - anchor`) and test the ring bound against `bossPos`.
- The client auto ring (B23: ring, burst and sound on the owner's client) and the drawn patrol are client work; no
  client code was written. Nothing was looked at on screen.
- `SetZonesBeaten` can only add zones: Data/Session has no claim for `zonesBeaten`. Request to M2-09: a Studio-only
  writer (`Session.setZonesBeatenForTest`, which Zones already calls if it exists).
- Toggles reset on join (code: `Session.onJoin` resets them); a real rejoin was not run.
- The check runs saved `zonesBeaten = {2}` into the Studio-env record of account 28683760 (M2-09's store).

## What the builder must add (the plain six-zone strip; `studio/BuildSlice.lua` is not M2-10's)
23 pad Models, built like `Zones.Z1.Pads.Fixed`: tag `HFB_BossPad`; attributes `PadId`, `ZoneId`, `Kind`
(`fixed`|`roll`); a `Ring` part 12 x 1 x 12 with `RingRadius` 6; an invisible `BossAnchor` at the ring top; and a
`NumberAnchor`. Ids: `z1_roll1..3` and `z<n>_fixed`, `z<n>_roll1..3` for n = 2..6, under `Workspace.Zones.Z<n>.Pads.<Fixed|Roll1|Roll2|Roll3>`.
Proposed layout, the one the checks' stand-ins use: zone n starts at Z = 236 + 120 (n - 1). Pads sit 40 / 60 / 80 / 100
studs in (fixed, roll1, roll2, roll3), alternating east X 233 and west X 179. Each zone needs ground and the lane to
Z 956. Each boss walks 14 studs either way along Z, so leave 15 studs of clear bay on both sides of each pad along the
lane. An optional `PatrolAnchor` part on a pad overrides the walk line (M3).

## 2026-11-26 M2-27 SF4 (by M2-18, scripter)
`Systems/Bag.lua` `buy`: the spend and the level are now ONE `Session.mutate` (`Session.ops.spendCash` keeps the
bought-cash rule; the `spend` / `setLevel` / `refund` helpers are gone, so a failure can no longer hand back bought cash
as earned cash). Bag a 23/0 and b 25/0 rerun after the change; new rows Robux a 52-55 (`team/verification/m2-18-robux.md`).
