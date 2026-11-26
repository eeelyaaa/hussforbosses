# M1-03 verification: Chomp Frog, gloves, voxel builder (modeler-3d, 2026-11-25; frog rebuilt at M1-03b)

**M1-03b (2026-11-25, retry after the orchestrator's look):** the frog's layer data was rebuilt to the picture: a domed
head whose top dips behind a heavy V brow, eyes sunk under it with pupils toward the centre, two nostrils, a cream
jaw wedge jutting forward, splayed thick legs on big flat toed feet, and round gloves with a yellow cuff round the
wrist. The builder gained two fill types (`cyl`, `seg`); colours, palette, cube size, belly, tongue and the group
names are unchanged; **pivots moved** (table below); size and triangle counts changed (below). Gloves untouched.

Scope: Blender headless only (no Studio, no locks, nothing uploaded, nothing committed). Look review beside the
picture is the main session's; Studio checks (B4, B5, pivots in Studio, budget in play) are M1-17.

## Files
- `tools/blender/build_boss.py` (builder and library), `build_gloves.py`, `render_boss.py`
- `tools/blender/bosses/z1_t1.json` (layer data, colours as hex sampled from `creatures.png`), `gloves.json`
- `tools/blender/atlas_cells.json` (append-only hex to cell registry for the shared atlas)
- Output `assets-src/models/`: `boss-atlas.png` (256 x 256, 32 px cells, 2 px edge 12% darker, UVs inset 1 px),
  `z1_t1_atlas.fbx`, `z1_t1_perrole.fbx`, `z1_t1.groups.json`, `gloves_atlas.fbx`, `gloves_perrole.fbx`,
  `gloves.groups.json` (the `*_atlas.fbm` folders are Blender's FBX texture copies; ignore them)
- `src/ReplicatedStorage/Skins/brickbrawl/Models.lua` (contract F keys, ids 0)
- Rebuild: `blender.exe -b --factory-startup --python tools/blender/build_boss.py -- tools/blender/bosses/z1_t1.json`
  (use full Windows paths; Blender resolves relative paths against its own folder, not the shell's)

## Renders (`team/verification/m1-chomp-frog/`)
- `z1_t1_vs_picture.png`: the picture's frog (left, `creatures.png` crop) beside the render (right), same angle
  (about 24 degrees toward the boss's right, 10 degrees up). `z1_t1_render.png`, `z1_t1_picture_crop.png`.
- `z1_t1_front.png`, `z1_t1_side.png`, `z1_t1_back.png`, `z1_t1_top34.png`: the M1-03b build from four more angles.
- `z1_t1_pivots.png`: Sig opened 25 degrees about its hinge, FistL raised 40 degrees and FistR turned 30 degrees about
  their shoulders (rotated about the numbers below, so the pivots are proved in Blender).
- `gloves_render.png`: GloveL and GloveR.

## Picture match (M1-03b; my own read against the orchestrator's five points; the main session decides)
| # | Point | Verdict |
|---|---|---|
| 1 | Domed head, heavy V brow meeting low in the centre, eyes narrowed under it, white with ink pupils toward the centre | **Matches.** Two brow ridges, 2 cubes proud of the eyes, step down from the outer ends (top at cube 20) to meet over the snout (top at 17); the head top behind dips between them (18). Eyes sit under the brow, 2 to 4 cubes tall, 2 x 2 pupils at the inner bottom. Still differs: the brow is stepped in 2-cube steps where the picture's slope is smoother, and from straight in front the outer brow ends read a little like ear bumps |
| 2 | Two small nostril dots between the eyes | **Matches** in place (one ink cube each on a small snout, below the V tip). Differs in size: a dot is a whole cube (0.2 stud) where the picture's are smaller than a cube |
| 3 | Cream lower jaw a big forward wedge under the wide open mouth with the pink tongue | **Matches.** The jaw juts 2 cubes past the upper lip and the belly, its underside sloping back in steps; tongue raised 2 cubes on a dark red floor; cream cheeks at the mouth's sides. Differs: the mouth opening is 2 cubes from the front, the picture's looks about 3 |
| 4 | Wide splayed stance, thick legs angled out, big flat feet with toes | **Matches.** Feet 8 cubes wide with three toes each, set wide (a 6-cube gap between them), legs narrowing and leaning in from ankle to hip. Differs: the picture's thighs show more (its body sits higher on the legs) |
| 5 | Big round boxing-glove fists with a yellow band round the wrist | **Matches.** Round gloves (radius 4.7 cubes, about 9.5 across, nearly head-width), a yellow cuff (radius 4) wrapping the wrist between glove and body, a short forearm to the shoulder. Both cuffs show from the picture's angle |
Not matched, on purpose: the pose. The picture is a fighting pose (torso turned, one fist forward low, one raised); the
rest pose follows the style guide's squat stomper ("fists out to the sides"): fists held out at the sides, raised to
jaw height and pushed forward, symmetric (TEAM CALL M1-03b-1). The picture's lighting is stronger, so its cube edges
and brow read harder than this render's.

## Model facts (blender cube = 0.2 stud, H = 4)
- Size 6.8 x 4.0 x 3.0 studs (Roblox X, Y, Z), 34 x 20 x 15 cubes (3,454 solid cubes), model pivot = middle of the feet, front = Roblox -Z. (M1-03 was 6.0 x 4.0 x 3.2.)
- Round trip (M1-03b): both FBX re-imported in a clean Blender: atlas 5 meshes `Body FistL FistR Head Sig`, perRole 23 meshes, 6,584 triangles each, bounds x -3.4..3.4, y -2.0..1.0 (Blender), z 0..4.

## Groups and pivots (numbers; Blender stud = Roblox stud; Roblox offset = (-x, z, y) from the model pivot)
| Group | Mesh (atlas) | Pivot, cubes (x,y,z) | Pivot, Blender studs | Pivot, Roblox offset from the feet |
|---|---|---|---|---|
| Body | `Body` | 0, 0, 0 | 0, 0, 0 | 0, 0, 0 (middle of the feet, on the ground) |
| Head | `Head` | 0, 3, 11 | 0, 0.6, 2.2 | **0, 2.2, 0.6** (back of the jaw hinge; was 0, 1.6, 0.6) |
| Sig | `Sig` | 0, 3, 11 | 0, 0.6, 2.2 | **0, 2.2, 0.6** (same hinge; was 0, 1.6, 0.6) |
| FistL | `FistL` | 7, -5, 9 | 1.4, -1.0, 1.8 | **-1.4, 1.8, -1.0** (frog's left shoulder, Roblox -X; was -1.4, 2.4, -0.4) |
| FistR | `FistR` | -7, -5, 9 | -1.4, -1.0, 1.8 | **1.4, 1.8, -1.0** (was 1.4, 2.4, -0.4) |
M1-03b moved the hinge up 0.6 stud (the jaw is now cubes 8 to 13, under a mouth at 11 to 13) and the shoulders down
0.6 and forward 0.6 (the gloves sit at jaw height, forward). `studio/data/z1_t1.groups.json` refreshed with
`python tools/sync_group_data.py` (identical to the source). Moves are in fractions of H, so they carry over.
Geometry stays in model space (every mesh's origin is the model origin), so with the importer's Set Pivot to Scene
Origin on, all five meshes share the model pivot; take each group's offset as `pivot:ToObjectSpace(mesh.CFrame)`
or from the numbers above, never from the file (importer positions are bounding-box centres).
Group split: Head = upper face (brow, eyes, nostrils, lip, roof and back wall of the mouth, top of head); Sig = lower
jaw wedge (cream cheeks, dark red floor, pink tongue); Body = feet, legs, belly, back behind the jaw; FistL/FistR = the round gloves with
the yellow cuff and a short forearm. Hinge rest pose is as pictured (mouth open between the lip and the jaw); a chomp is Sig turning
**+X about the hinge** (front goes down, up to about 25 degrees before it sinks into the cream belly, same colour);
it cannot turn the other way by more than about 5 degrees (it meets the lip). Fists hang from the shoulder pivot.

## Triangle counts (budget Common 600: the picture's density does not fit; the picture wins; report to B6)
| Route | Meshes | Triangles |
|---|---|---|
| atlas: one mesh per group, one material, shared atlas | 5 (Body 1,980, Head 1,668, Sig 1,128, FistL 904, FistR 904) | **6,584** |
| perRole: one mesh per colour role per group, no texture | 23 | **6,584** |
Same faces in both. M1-03b added 820 triangles over M1-03 (5,764): the dome, brow ridges, jaw wedge, toes and cuffs.
That count keeps the faces where two groups touch (needed so a turning group has no holes); dropping them would give
5,672. Merging the perRole cubes into flat rectangles would give 4,662 but loses the cube edges, so it is not built.
Roblox's limit (20,000 a mesh) is far off: the biggest mesh is 1,980. Common budget 600 does not fit the picture's
density (as at M1-03; the picture wins; reported to B6).
Gloves (cube 0.14, 1.3 x 1.0 studs each): GloveL 772 + GloveR 772 = **1,544** triangles either route (atlas 2 meshes,
perRole 6 meshes); pivot at the wrist, thumbs on the inner side, built for both sides (a real mirror).

## Import brief for MS-A (main session)
Files: `assets-src/models/z1_t1_atlas.fbx`, `z1_t1_perrole.fbx`, `gloves_atlas.fbx` (and `boss-atlas.png` for the
atlas route's texture). Importer: Merge Meshes **off**, Scale Unit **Stud**, Set Pivot to Scene Origin **on**, front/up
defaults, no animation. Expected: Model named after the file; meshes `Body, Head, Sig, FistL, FistR` (atlas) or
`<Group>_<role>` (perRole: roles g1 g2 g3 cream cream2 mouth pink yellow white ink); overall 6.8 x 4.0 x 3.0 studs.
Atlas route: set each MeshPart's `TextureID` to the uploaded `boss-atlas.png` (the FBX carries no usable texture), matte
(`Material = SmoothPlastic` or Plastic with no reflectance, `CanCollide = false` in the setup). perRole route: colours by
`MeshPart.Color` from the palette in `z1_t1.json` (hex there; the table to the setup script is the builder's M1-12).
Read back the mesh ids and the five sizes; compare with the table above. Unverified until then: that the importer
keeps five separate meshes (B5), that atlas edges stay crisp at distance (B4), UV orientation in Studio.

## Status
Blender checks PASS (names, counts, sizes, round trip, pivots by rotation render). Studio-side: UNVERIFIED (M1-17).
The look beside the picture: **UNVERIFIED until the main session has read the side-by-side**.
