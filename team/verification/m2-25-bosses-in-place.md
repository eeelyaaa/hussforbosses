# M2-25 bosses in place and S22 on real meshes (modeler-3d, 2026-11-26)

Studio MCP, edit mode then play mode, `studio` lock held and released. No computer use (subagent): on-screen items are UNVERIFIED until the main session looks.

## Setup (`studio/SetupBosses.lua`, extended; re-runnable; place guard first)
Six models built, one per zone Fixed pad, standing on `Zones.Z<n>.Pads.Fixed.BossAnchor`: Boss_z1_t1 (stomper: Body Head Sig FistL FistR), Boss_z2_t2 and Boss_z5_t5 (tailed striker: + TailA TailB), Boss_z3_t3 (swayer: Body Upper Head FistL FistR), Boss_z4_t4 (biped: Body Head FistL FistR), Boss_z6_t6 (biped + Sig). Run result: PASS, 0 failed (about 130 checks: groups equal the groups.json keys, rest pose of every joint, identity-rotation joints, exact group names, PrimaryPart Body anchored, others unanchored/massless/no collision, N-1 Motor6Ds named after their group, pivot at BossAnchor, attributes + HFB_Boss tag, lowest corner on the pad top within 0.05).
Bounding boxes (studs, with halo/tails/fists): z2 5.70x5.32x5.89, z3 7.04x6.82x7.70, z4 8.32x8.32x4.94, z5 14.00x11.20x8.96, z6 15.20x16.40x7.60 (halo to 16.4).
Importer's Body pivot is the feet on all five (Body pivot y = lowest corner), so the M1 assumption holds.
TextureID is set from Models.lua `creatures.<id>.textureId` (108529045034445), not the importer's own copy; Color white, SmoothPlastic, Reflectance 0.
Joints are flat (Part0 Body), as `_geo.lua` and `_lib.expand` expect; TailB-on-TailA and Head/fists-on-Upper are computed, not nested.
Re-import: run again; source is the Model in `BossScratch` whose name starts with the id (delete the old scratch model first so two do not match).

## S22 on real meshes (`studio/checks/MovesM2Real.lua`, play mode; clones of the placed bosses on a pad slab)
0 failures in all three runs (z4+z6, z2+z5, z3). Real MeshPart rest boxes equal the FBX bounds (gap 0.000 studs), real joint pivots equal groups.json (worst 0.0001).
- Biped, one move set, no re-pivot: right fist travels 0.252 H on Frost Byte (H 8.3) and 0.263 H on Star Golem (H 14), within 25%. Lowest corner: hitGood 0.007 / 0.005 H, hitBig 0.003 / -0.030 H, defeat -0.060 / -0.084 H (box-corner overstatement; flop check passes).
- Tailed: striking tail part travels 0.518 H on Snap Scorpion (H 5.3) and 0.641 H on Ember Drake (H 10.9) by 0.21 s; stinger lands z -3.06 y 2.70, club lands z -5.54, both as the style guide says. Joint shear worst 0.077 H (scorpion lastHeart), 0.043 H (drake).
- Swayer: snout rears (-0.72, 6.73, -0.97) then lunges to (-0.22, 2.23, -5.87), nested Head/Upper shear 0.023 H.
- Every move length within 2 frames of the brief, all 11 moves resolve, eight cuts in a row land, rest pose restored exactly. Note z3 idle loop dips 0.153 studs under the pad (0.022 H, inside the 0.12 H tolerance).

## Triangles (groups.json, atlas route) against the style guide tier budgets (the picture wins, B6)
| id | tris | tier budget | x budget |
|---|---|---|---|
| z1_t1 frog | 6,584 | 600 | 11.0 |
| z2_t2 scorpion | 9,604 | 1,000 | 9.6 |
| z3_t3 shark | 10,636 | 1,600 | 6.6 |
| z4_t4 yeti | 9,920 | 2,500 | 4.0 |
| z5_t5 drake | 17,700 | 4,000 | 4.4 |
| z6_t6 golem | 13,324 | 6,000 | 2.2 |
All under Roblox's 20,000 per mesh (largest single mesh: drake Body 8,020). Six bosses total 67,768; the 136-placed worst case is a performance-optimizer measurement (B6), not done here.

## On-screen checks for the main session (UNVERIFIED until looked at)
Camera 12 to 20 studs in front (+Z of the model looks toward -Z, the creature faces -Z) and 6 up, each Z<n>.Pads.Fixed.BossAnchor: z1 about (142.5, 1, 223.3), the rest at x 205.8, z 229.6 (their zone y differs; use the Boss_ model position).
1. Each of the six, front and 3/4 view: textured (not grey), feet on the pad, no mesh under the ring, no seams where Head/fists/tail meet the Body.
2. Drake: tail runs round the right (+x) side and lies low; scorpion: tail curls up behind.
3. Play `BossMoves` attack/hitBig/defeat on one boss per type (the play-mode check does it on clones; look at it once for feel).
4. Frog notes below, after the art-director's pass.

## Frog M1 notes (brow ends read as ear bumps, eyes too wide, nostrils one cube too big)
Not done: all three need the model re-cut in `tools/blender/build_boss.py` and a re-import (new mesh ids), not a setup-script change. Not asked for in M2-25 (no re-modelling). Listed for the next modeler pass.

## Files
`studio/SetupBosses.lua` (extended), `studio/checks/MovesM2Real.lua` (new). Test leftovers removed (M225Check module, attributes, probes); no hook armed.

## Re-run after the fix pass (2026-11-26, re-imported meshes, atlas 131662969906561)
`MovesM2Real.lua` now reads rest boxes and probe points from the placed meshes (the old FBX numbers were pre-fix; drift reported as INFO: z2 0.113 H, z3 0.194 H, z4 0.063 H, z5 0.238 H, z6 0.029 H). Pivots equal groups.json (0.0000). Added: rearmost reach vs `_geo.lua back` (all equal to back: 0.538, 0.582, 0.188, 0.360, 0.257 H).
Result: 1 failure of the five bosses.
- FAIL z2_t2 hitBig: FistR lowest corner -0.727 studs = 0.137 H under the pad (tolerance 0.12 H; was -0.226 before the claws sat lower). Everything else on the scorpion passes.
- S22 biped: fist travel 0.247 H (Frost Byte) vs 0.263 H (Star Golem), PASS. S22 tailed: tail part 0.533 H (scorpion), 0.754 H (drake; longer club radius), stinger lands (0, 2.61, -3.11), club lands (2.91, 4.01, -6.33), both PASS. Shark snout path PASS (impact (-0.17, 2.05, -5.72)); 15 degree head yaw changes nothing that fails.
- `lie`: flop never under the pad on any of the five (lowest +0.101, +0.025, +0.074, -0.010, +0.033 studs). `back` unchanged. No `_geo.lua` numbers need changing.
- Animator change (not made): Snap Scorpion hitBig (tailed striker set, claws): raise the fists' dip by about 0.1 H or lift the Body about 0.1 H at 0.15 s so FistR stays above -0.12 H; or accept it (the dip is the claw tips only, 0.09 studs over tolerance).
