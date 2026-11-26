# M1-17 verification: Chomp Frog in Studio (modeler-3d, 2026-11-25)

Studio lock held (`modeler-m1-17`), released. Edit-mode checks through `run_code`; moves in play mode through `run_script_in_play_mode`
(script: `m1-17-real-model-moves.lua`, a cleaned copy of what was run; the run used a clone of `Fixed.Boss_z1_t1` at y 300, destroyed after).
Nothing uploaded, nothing committed. Scratch folders `ServerStorage.BossScratch` and `BossScratchPerRole` are both left in place.

## Colour: cream reads grey-green (finding and fix)
- Cause: `MeshPart.Color`. The importer leaves the default (163,162,165), and Color multiplies the texture, so all cells were about 64% dark.
- Ruled out: texture (read back 256 x 256 from asset 116542096217311 with EditableImage: cell 0 = 58,190,35; cell 3 = 236,207,151 cream; cell 5 = 241,151,186 pink: exact hexes), UVs (cells land on the right colours in Blender), filtering.
  Lighting was not changed. The per-role import has the same default grey on every part, which would dull it the same way; its colours come from a `Color` table (not applied).
- Fix (in the repo, ran in Studio): `studio/SetupBosses.lua`, `studio/SetupGloves.lua` set Color white, SmoothPlastic, Reflectance 0 on textured MeshParts. Read back after re-run: Body, Head, Sig, FistL, FistR and GloveL, GloveR all Color 1,1,1, SmoothPlastic, TextureID set. No re-import needed.
- Still UNVERIFIED by eye: that the belly now reads cream on screen (below).

## B4: atlas picked (numbers, Studio read-back with EditableMesh)
| | atlas | per-role |
|---|---|---|
| MeshParts per frog | 5 | 23 |
| Triangles | 6,584 (Body 1,980, Head 1,668, Sig 1,128, FistL 904, FistR 904) | 6,584 |
| Vertices | 13,168 | 9,517 |
| Texture | one 256 x 256 (about 0.26 MB raw) | none |
| Colour | texel-exact, no Color table | needs a Color per role |
Gloves atlas: 2 meshes, 1,544 triangles (772 each). Budget: Common 600 does not fit the picture (6,584); reported to B6, not cut; the largest mesh is 1,980 (limit 20,000).
Pick and reason: TEAM CALL M1-17a in `decisions.md`.

## B5: one FBX per boss
Merge Meshes off kept five separate MeshParts in one FBX (names Body, Head, Sig, FistL, FistR), size 6.8 x 4.0 x 3.0 studs (SetupBosses bounding box), Body origin = middle of the feet (feet y 0). Per-zone not tried. TEAM CALL M1-17c.

## Moves on the real model through `BossMoves` (play mode)
- Joint pivots in Body-centre space as read: Head and Sig (0, 1.1, 0.8), FistL (-1.4, 0.7, -0.8), FistR (1.4, 0.7, -0.8). The Body centre is 1.1 up and 0.2 toward the front (-Z) of the feet pivot, so from the feet that is 2.2 / 0.6 for the hinge and 1.8 / -1.0 for the fists, as groups.json.
- Each of Head, Sig, FistL, FistR rotated 40/20/15 degrees by Transform: part rotated, pivot point drift 0.00000 to 0.00003 stud (PASS x4).
- After all moves (hitGood, attack, lastHeart, defeat, plus the earlier run's hitPerfect, hitBig, gloat): every Motor6D C0 and C1 identical to before = no re-pivoting (PASS); sizes restored after `stop` (PASS).
- Jaw direction: Transform Sig x = -25 moves the jaw front-bottom dy -0.874, dz +0.46 (down and back); x = +25 gives dy +0.986 (up). The `attack` move's jaw front in Body space: min dy -1.152 at 0.234 s, max 0.000 (never above rest): jaw chomps DOWN (PASS). lastHeart the same (min -1.152 at 0.283 s). **No sign flip needed.**
- Fist bop: attack moves FistR forward 0.984 stud, FistL 0.105 (PASS). Durations on the real model: hitGood 0.167 s, attack 0.467 s, lastHeart 1.033 s, defeat 0.816 s (frame-rounded, as M1-09).
- First pass of the first run showed hitBig lifting the jaw tip +0.57 and the head 2.2 studs back (a knock-back step with Body moving); that run measured in world space, so it is not evidence of a wrong turn. Not re-measured in Body space for hitBig and defeat (UNVERIFIED by number; look at them on screen).
- Caveat: Transform changes apply a frame later (a direct read in the same frame shows 0).

## Wired (`Skins/brickbrawl/Models.lua`)
creatures.z1_t1.groups = Body 124930310883753, Head 111961754367044, Sig 110959131671988, FistL 123078999255876, FistR 109820571392209; textureId 116542096217311.
gloves.groups = GloveL 76241603600658, GloveR 110446020050450; textureId 116542096217311. Stub mirrors the keys at 0.
CheckSkin: A1, C, D, E pass; A2 (bags, hazards, Effects stars/cubeBurst missing) and B differences in bags and hazards are other owners' keys and were there before; B no longer differs on creatures or gloves. `python tools/check_skin.py`: 0 hits. CheckSkin leaves `HFB_ForceSkin` armed; I disarmed it (reads nil, `HFB_SkinCheck` folder removed).
Also fixed: the stale "6.0 x 4.0 x 3.2" print in `SetupBosses.lua` (now says expected 6.8 x 4.0 x 3.0).

## Renders (Blender, `team/verification/m1-chomp-frog/`)
Earlier (M1-03b): `z1_t1_vs_picture.png`, `z1_t1_render.png`, front, side, back, top34, pivots. New: `z1_t1_size_front.png`, `z1_t1_size_side.png`
(frog beside an R15-sized block avatar, 5.2 studs; the frog is 4.0 tall, 6.8 wide: about avatar chest height, much wider than the avatar; made by `tools/blender/render_size.py`). The avatar in these is boxes, not the real rig.

## On-screen checks owed (main session, `computer` + `studio`; I could not look)
1. Select `Workspace.Zones.Z1.Pads.Fixed.Boss_z1_t1` in the Explorer, press F, look from the side and front: belly and jaw cream (about 236,207,151 under lighting), green body, pink tongue, white eyes; no grey-green cast. If still dull: lighting, not Color.
2. Same view for `ReplicatedStorage.Gloves` (red with yellow cuff) after a SetupGloves run; the colours on the red glove should match Huss red.
3. Atlas crispness: zoom out to the fight camera distance (about 15 to 25 studs) and in a phone-size emulator: no coloured fringes at cube edges, no neighbouring-colour bleed (B4 risk).
4. Beside an avatar (Test > Play, or insert a rig next to the pad): size, feet on the pad, nothing sunk.
5. Play moves from the command bar (`BossMoves.play(model, "attack")` etc.): jaw chomps down at about 0.21 s, no hole where Head and Sig meet, hitBig and defeat look (not measured in Body space), the flop does not sink into the pad.
6. Compare with `creatures.png` side by side (the main session's call, M1-03).
