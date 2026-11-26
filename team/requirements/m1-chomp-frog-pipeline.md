# M1: proof 3, one boss with moving groups (Chomp Frog), the gloves, the boss pipeline

Build to `m1-contract.md` section G (groups, pivots, joints, model names) and H. Quality pass: **Function only**
(the picture match is the exit check; Look review of all bosses is M2/M3).

## The brief
"Make sure bosses look like that. Amazing in the images" (manager, 2026-11-25). Chomp Frog (`z1_t1`, squat
stomper) is built to its approved picture (`concepts/brick-brawl/creatures.png`, about 19 cubes tall) through the
headless builder, FBX, the Studio importer, a setup script, onto the pad, with groups `Body`, `Head`, `FistL`,
`FistR`, `Sig` named and pivoted as the style guide's table; built both ways (shared atlas, one mesh per colour
role) and one picked (B4). Render beside its picture, same angle. The voxel boxing gloves: Huss red `#E02A2A`,
yellow cuff band of the approved glove icon, about head size, matte, no studs, put on at spawn.

## Tasks
- **M1-03 modeler-3d (sonnet), wave 1:** `tools/blender/build_boss.py` (layers of cubes from data, hidden faces
  removed, one mesh per moving group, FBX, prints triangle count and size; 1 Blender unit = 1 stud; the whole
  model's pivot at the middle of the feet; group pivots set per contract G), `tools/blender/bosses/z1_t1.json`
  (the layer data; colours sampled from the picture, as hex in the data file, which is outside `src/`),
  `tools/blender/build_gloves.py` + `gloves.json`, `tools/blender/render_boss.py` (guard-pose render at the
  picture's angle, and a signature impact-pose render when the animator's poses exist), the `boss-atlas` image (256
  x 256, 32 px cells, 2 px edge 12% darker) and both FBX routes into `assets-src/models/`, `Skins/brickbrawl/Models.lua`
  (the keys of contract F, ids 0). Renders to `team/verification/m1-chomp-frog/`.
  Return: triangle count per route, group list with pivots as numbers, what the importer needs (the import brief
  for the main session: which files, scale, names).
- **MS-A (main session, computer use):** the Studio 3D importer on both routes into a scratch folder in the place
  (not `Workspace.Zones`), reads back the mesh ids into `team/assets.md`.
- **M1-17 modeler-3d (sonnet), wave 3, `studio` lock:** with the imported scratch models: B4 (atlas edges crisp,
  no bleed at distance vs per-role colour; pick one, log why), B5 (do the groups stay apart in one FBX; per boss or
  per zone file), the groups animate without re-pivoting (rotate each group about its pivot in a script and read
  back), triangle count against the tier budget (Common 600; the plan says the picture wins), final renders beside
  the picture and beside an avatar for size (`team/verification/m1-chomp-frog/`).
- **M1-12 builder, wave 3:** `studio/SetupBosses.lua` (names the groups, welds, Motor6Ds per contract G, applies
  colour for the picked route, anchors it at `Fixed.BossAnchor`, tags), `studio/SetupGloves.lua` (builds the
  `Gloves` model), wiring the mesh ids into `Models.lua`.

## Acceptance criteria
1. The built Chomp Frog matches its picture: silhouette, proportions, colours, face, fists, cube density; the
   render is beside `creatures.png`, same angle, and the main session reads both images side by side before
   calling it passed. [M1-03, then main session on-screen/image look]
2. Groups exactly `Body, Head, Sig, FistL, FistR`, pivots as contract G, each its own mesh; the model's pivot at the
   feet.
3. Both colour routes were built and checked in Studio; one is picked with the reason in `decisions.md` (B4); B5
   answered the same way. [M1-17]
4. The Chomp Frog placed on the fixed pad is `Boss_z1_t1` with the attributes of contract G; the setup script runs
   again on an empty slice and rebuilds it. [M1-12]
5. The gloves exist as `Gloves` (about head size, Huss red, yellow cuff), mirrored for the left hand. [M1-12]
6. Triangle count reported against 600; any overshoot is reported to the performance-optimizer's M2 count (B6),
   not cut.

## Risks
The importer merging groups into one mesh (then the per-role or per-zone fallback); the atlas bleeding at distance;
a pivot lost by the FBX round trip (the builder sets `PivotOffset` or the Motor6D C0/C1 from numbers, not from the
file).

## Suggestions from the vault (optional)
None added. (Higgsfield 3D is not used, per the plan.)

## Not asked for (do not build)
Any other boss (the other five pictured bosses are M2, the 30 more M3); any other body type; Neon on Chomp Frog;
concept sheets; boss pictures for UI panels (M2); atlases for other bosses; Higgsfield anything; a skinned rig or
an `Animator` for the boss.
