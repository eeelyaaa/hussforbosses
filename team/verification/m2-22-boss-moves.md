# M2-22 verification: boss move sets for three body types and five signatures (animator-vfx, 2026-11-25)

Studio lock `animator-bossmoves` held and released. Synced with DevSync (module-swap rule respected), play-mode runs through `run_script_in_play_mode`, the check module installed in `ServerStorage.TmpChecks` and deleted after (0 `HFB_` attributes, no rigs left, no test hook used, play stopped). Nothing committed. Check: `studio/checks/MovesM2.lua` (box rigs built from the real group boxes of the five FBX files, read in headless Blender, and the pivots of `<id>.groups.json`; the meshes are not imported, so what is proved is the maths and the poses on boxes, not how the mesh looks). The frog's check `FrogMoves.lua` was re-run after the one engine fix below: all PASS.

## Files
- `src/ReplicatedStorage/Shared/Moves/`: `init.lua` (more groups, `get(bodyType, creatureId)`), `_lib.lua`, `_geo.lua` (new helpers, not move sets), `tailed.lua` (body type 3), `swayer.lua` (5), `biped.lua` (1), `sig/z2_t2.lua`, `sig/z3_t3.lua`, `sig/z4_t4.lua`, `sig/z5_t5.lua`, `sig/z6_t6.lua`. The frog's `squat.lua` and `sig/z1_t1.lua` are unchanged.
- `studio/checks/MovesM2.lua` (new). One engine fix in `Controllers/BossMoves.lua` (below).

## Moves per body type (all 11 names each: idle, guard, hitGood, hitPerfect, hitBig, attack, lastHeart, gloat, defeat, halfIdle, carryRock)
Lengths are the brief's: hitGood 0.15, hitPerfect 0.20, hitBig 0.30, attack 0.45 (impact 0.21), lastHeart 1.0 (impact 0.26), gloat 0.35, defeat 0.8; guard and carryRock loop 1.0 s; idle and halfIdle loop 7.2 s (tailed, swayer) or 6.0 s (biped: so the golem's halo circles once in 6 s, as the style guide says).
| Body type | Guard | Template attack |
|---|---|---|
| Tailed striker (3): Body, Head, FistL/R, TailA, TailB | squashed 1.05/0.95, claws forward, tail raised in an S, 0.02 H hop at the ring | body dips and leans back, both tail segments cock back (claws open); the tail whips round to land in front (impact 0.21, TailB at 1.2); the right claw bops out 0.25 H (second beat 0.33); back to guard by 0.45 |
| Rearing swayer (5): Body, Upper, Head, FistL/R | upright, Body sways 6 degrees on a 1.0 s Sine about the feet, fins up | Upper rears 20 degrees (wind-up), lunges 0.25 H from the base with the head snapping down (impact 0.21), no scale on the head |
| Biped bruiser (1): Body, Head, FistL/R, optional Sig | fists at the chin (arms 60 degrees), 0.03 H bounce | weight back, the right fist raised behind the head (arm 200 plus 0.1 H lifted), body slides a step in, the fist comes down through (impact 0.21, fist at 1.2) |
Own gloats (0.35 s): tailed = tail raised high and quivering, claws pump twice; swayer = rears up proud, fins pump twice; biped = fists pump twice. Defeat (0.8 s, all): wobble 10 degrees twice, fists drop, flop onto the back (Body lifted by `lie` so no mesh goes under the pad), white flash at 0.45, hop onto the head over 0.5 to 0.8; the flop's tail/upper-body pose is per body type.

## The five signatures (attack 0.45 s, lastHeart 1.0 s = the same with a 0.2 s wind-up then the gloat)
- **Snap Scorpion (z2_t2):** tail sting then pincer punch, as the manager said and the style guide frames it: wind-up 0 to 0.15 (stinger up and behind), whip over the body, impact 0.21 (stinger in front of the face at chest height), a small stab, right claw bop 0.27 to 0.33 and pops to 1.2.
- **Bit Shark (z3_t3):** rears back with the jaw wide, lunges, bites at 0.21, re-opens at 0.25 and bites again at 0.29 (the heart breaks on the first).
- **Frost Byte (z4_t4):** pounds its chest (0.04; twice on the lastHeart), both arms up behind the head, both fists smash down at 0.21.
- **Ember Drake (z5_t5):** turns 75 degrees away (wind-up), spins back to +45 with the tail whipping 24 more, the rock club lands in front at 0.21 (TailB at 1.2, no flame), body turns back to face as the right fist punches at 0.33.
- **Star Golem (z6_t6):** halo pulses (scale 1.2) and spins one turn on the wind-up, one huge hammer punch with the right fist at 0.21. Its idle and half idle carry the halo orbit (360 degrees per 6 s, 12 steps).
Frog (M1) unchanged: jaw chomp then fist bop.

## Measured (play mode, box rigs, `studio/checks/MovesM2.lua`; every line PASS in the last runs: z4+z6, z3+z2, and z5 earlier with the same code)
- Schema (`Moves.check`): 0 problems for every set and signature; every creature resolves all 11 moves; `_geo.lua` pivots equal `groups.json` within 0.03 stud. `Lib.follow` (the nested-group maths) equals parent-then-child turning to 1e-6.
- Lengths: every move within 0.04 s of the brief (the Heartbeat poll adds one to two frames; the same as the frog's M1-20 numbers). impactAt 0.21 / 0.26 on all.
- Positions (studs from the feet, at the key times): Scorpion stinger tip rest (0, 3.75, -0.61), wind-up end (0, 4.63, 4.13) up and behind, impact (0, 2.53, -3.15) in front of the face and about at the claws; second beat 0.33 back near rest. Drake club rest (4.9, 1.8, 1.0), wind-up (-1.3, 1.2, 6.1) swung away behind, impact (2.4, 1.8, -5.6) in front. Shark snout rest (0.2, 5.2, -3.7), wind-up (-0.4, 6.8, -1.0) rears up and back, impact (-0.2, 2.2, -5.9) lunged 2.1 forward and bitten down 3 studs. Frost Byte right fist rest (2.7, 4.2, -0.9), wind-up (3.0, 6.5, 1.2), impact (3.0, 4.2, -3.0). Golem fist rest (5.6, 6.8, -1.2), wind-up (6.1, 10.5, 1.6), impact (6.2, 6.6, -4.8).
- Nested groups stay attached to their parent: worst joint shear 0.076 H (Scorpion), 0.044 H (Drake), 0.024 H (Shark) over all moves (limit 0.08 H; with the mid-swing key the tail stays on its arc).
- No mesh under the pad: the flop of the defeat stays within 0.1 stud of the pad on all five (the Body is lifted by `lie`, measured from the group boxes at 85 degrees); other moves dip at most 0.12 H (the template's dip of 0.05 H and 6 degree lean; the box corners overstate real meshes).
- Cuts: eight reactions cut by the next result on every rig; each new move is the overlay at once; after `stop` every Transform is identity, Body at rest, C0/C1 unchanged, sizes restored, nothing running.
- **S22 (smallest and largest tier, as far as box rigs allow):** biped, the same table drives Frost Byte (H 8.3) and Star Golem (H 14): the right fist travels 0.250 H and 0.263 H by the impact (within 4 percent); no part under the pad on either. Tailed: one builder and the same fractions drive Snap Scorpion (H 5.3) and Ember Drake (H 10.9): the posing is mutual (see TEAM CALL below), both land where the style guide puts the striking part. Swayer has one boss at M2 (Bit Shark); Dune Cobra, Nebula Ray, Magma Hydra come at M3 and re-run this check.

## Engine fix found by the check (BossMoves, my M1-09 file)
`BossMoves` carried every group's pivot along with a Body squash by `(scale-1) x its offset from the feet`, but the joints hang off the Body PART, whose centre had already moved by `(scale-1) x its own offset`. Every group was dragged down by `(1-sy) x the Body centre height` during a squash: 0.9 stud on the Drake, 0.14 on the frog. Fixed with one subtraction in `initState` (`pivotFromBody` minus the Body centre). The frog's `FrogMoves.lua` re-run after the fix: all PASS. No other BossMoves change.

## UNVERIFIED (owed, not judged by an agent)
- The meshes are not imported (mesh ids 0): directions, silhouettes and clipping on the real models, and the real position of the stinger and the club, are unverified. Box rigs prove the maths.
- Feel, timing and how the tail whip, the double bite, the smash and the spin read: the manager's playtest.
- Golem halo: only a scale pulse and a spin. A real Neon flash of the halo alone needs `BossMoves` to flash one group (it flashes the whole boss for 0.05 s); `haloFlashAt` on the golem's moves says when. Optional.
- The Drake's 120 degree spin in 0.06 s is 3 to 4 frames: it will read as a flick. If it blurs, make the wind-up -60 and the strike +40 (`sig/z5_t5.lua` OPTS).
- Fist wind-up on a short block fist (Frost Byte) is a rotation plus a lift: look at whether it reads as past the head.

## On-screen checks for the main session (after M2-24/25 put the real models on a pad; hold `computer`, then `studio`; fight camera, phone and desktop size)
From the command bar in play mode with the model cloned to an empty spot: `local BM = require(game.StarterPlayer.StarterPlayerScripts.Controllers.BossMoves)`, then `BM.loop(model,"guard")` and `BM.play(model, "<name>")` (`defeat` with `{hopTo = a position}`). The model needs the attributes `CreatureId`, `BodyType` (1, 3, 5) and `H` (the tier height) as `SetupBosses` sets them.
1. Snap Scorpion, `attack`: tail cocks up and behind with the claws open; at 0.21 s the stinger lands in front of the face at chest height; the right claw punches at 0.33. Then `lastHeart` (gloat: tail raised and quivering).
2. Ember Drake, `attack`: spins away, whips round, the club lands in front, then the red fist; no flame. Check the spin does not clip the wings or look like a glitch.
3. Bit Shark, `attack`: rears back with the jaw wide, lunges, two bites 0.08 s apart. `lastHeart` gloat rears up.
4. Frost Byte, `attack`: chest pound, arms up behind the head, both fists smash down. Star Golem, `attack`: the halo pulses and spins, one hammer punch; `idle`: the halo circles.
5. All five: `hitGood`, `hitPerfect`, `hitBig` (squash, head snap, white flash, nothing detaches at the tail joint or the shark's shoulders), `defeat` (the flop does not sink into the pad; the Scorpion and Drake tails lie clear), `gloat`, `idle` on a pad and a row out of step, `carryRock`.
6. Smallest versus largest tier of a body type side by side (M2-25): the same move should read the same.

## Addendum 2026-11-26: hitBig claw dip on the real Scorpion (orchestrator request)
Tailed set `hitBig` (`Moves/tailed.lua`): the fist drop was -0.2 H, now -0.1 H (keys 0.06, 0.15, 0.16). Length 0.3 s, impact and recover timing unchanged. Real-mesh Scorpion hitBig FistR lowest was -0.727 stud (0.137 H); now -0.113 stud (0.021 H, Body corner). Re-runs under lock `animator-bossmoves`: `MovesM2Real` all five bosses PASS (0 failures; Scorpion+Drake, Shark+Frost Byte, Golem in three calls); `MovesM2` Scorpion+Drake box rigs PASS. Drake hitBig lowest -0.171 stud (0.016 H). TmpChecks removed, lock released.

## Addendum 2026-11-26 (2): Golem defeat-flop flake
Cause: a real margin shortfall, not sampling (flop low was +0.03 to -0.07 stud, varying with the frame the first sample landed on). `Moves/biped.lua` defeat flop lift is now `lie + 0.02` (0.28 stud on the Golem); length and look unchanged. Flop low now +0.18 to +0.30 (Golem), +0.24 (Frost Byte) in 4 runs. A second marginal flake showed once (Frost Byte wind-up fist raise 1.98 vs 2.0 studs): `sig/z4_t4.lua` wind-up lift 0.16 H -> 0.19 H; since then 2 clean runs. MovesM2Real biped pair (Frost Byte + Golem): 3 runs PASS after the changes (Golem alone also once). Tailed and shark sets untouched since their last pass, so not re-run 3x. Lock released.
