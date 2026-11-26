# M2 art track: the five other pictured bosses (modeler-3d, 2026-11-25; redo of four the same day)

Blender headless only. No Studio import, no Higgsfield, nothing uploaded or committed. Look review beside the picture is the main session's: **UNVERIFIED until it has read `m2-six-bosses/m2_sheet_vs_picture.png`**.

## Files
- Data and builders: `tools/blender/make_m2_bosses.py` (writes `tools/blender/bosses/<id>.json`), `build_boss.py` (M1 builder; redo added one backward-compatible option, `paint` fills that recolour existing cubes only, used for lava cracks and star specks; the frog's data has none), `render_six.py` (redo added a `quick` iteration mode: guard + side view), `build_m2.sh` (rebuild all and render).
- Output `assets-src/models/`: `<id>_atlas.fbx`, `<id>_perrole.fbx`, `<id>.groups.json`; shared `boss-atlas.png` (50 of 64 cells used after the redo; new cells `#FFF6C8` golem star white and one more, append-only). Copies for Studio in `studio/data/*.groups.lua` (`tools/sync_group_data.py`).
- `Skins/brickbrawl/Models.lua`: entries for the five (mesh ids 0 until import).
- Renders in `team/verification/m2-six-bosses/`: `m2_sheet.png` (all six, creatures.png order and angle, tier heights), `m2_sheet_vs_picture.png` (picture crop below the sheet), per boss `<id>_guard.png`, `<id>_impact.png` (static pose rotated about the pivots), `<id>_vs_picture.png` (picture left, render right).

## Per boss (atlas route; perRole is the same count; budget = tier budget; picture wins, B6)
**Redo 2026-11-25 (modeler-3d, opus):** Snap Scorpion, Bit Shark, Ember Drake and Star Golem rebuilt after the orchestrator's FAIL
(silhouette). Frost Byte and Chomp Frog untouched (Frost Byte's numbers below are the first pass's).

| Id | Boss | Body type | Size studs (X, height, depth) | Triangles | Budget | Largest mesh |
|---|---|---|---|---|---|---|
| z2_t2 | Snap Scorpion | tailed striker | [5.7, 5.32, 5.89] | **9604** | 1000 | Body 3856 |
| z3_t3 | Bit Shark | rearing swayer | [7.04, 6.82, 7.7] | **10636** | 1600 | Body 3000 |
| z4_t4 | Frost Byte | biped bruiser | [8.32, 8.32, 4.94] | **9920** | 2500 | 3912 |
| z5_t5 | Ember Drake | tailed striker | [14.0, 11.2, 8.96] | **17700** | 4000 | Body 8020 |
| z6_t6 | Star Golem | biped bruiser | [15.2, 16.4, 7.6] | **13324** | 6000 | Body 8224 |

All far over the tier budgets (B6 overshoot, the picture wins) and every mesh under Roblox's 20,000. Phone cost is the
performance-optimizer's to measure. Drake is 0.3 studs over its tier height (horn tips), Golem's 16.4 includes the halo.

## Groups and pivots (Roblox offset from the feet, studs) — names and conventions unchanged from the first pass
- **z2_t2**: `Body` [0,0,0]; `Head` (back of the face block) [0, 1.9, -0.19]; `FistL`/`FistR` (claw root) [-/+0.95, 1.71, -0.19]; `TailA` (root) [0, 2.09, 1.52]; `TailB` (joint) [0, 3.8, 2.375]. Meshes: Body 3856, Head 1544, FistL/R 1204, TailA 716, TailB 1080
- **z3_t3**: `Body` [0,0,0]; `Upper` (hips) [0, 1.98, 0]; `Head` (neck) [0, 3.96, -0.44]; `FistL`/`FistR` (shoulder) [-/+1.32, 3.74, -0.44]. Meshes: Body 3000, Upper 2488, Head 2884, FistL/R 1132
- **z5_t5**: `Body` [0,0,0]; `Head` (neck) [0, 7.28, -0.56]; `FistL`/`FistR` (shoulder) [-/+2.24, 6.44, -0.28]; `TailA` (root) [0, 3.08, 1.4]; `TailB` (joint) [3.64, 1.176, 2.8]. Meshes: Body 8020, Head 4220, FistL/R 1576, TailA 1312, TailB 996
- **z6_t6**: `Body` [0,0,0]; `Head` (neck) [0, 10.0, 0]; `FistL`/`FistR` (shoulder) [-/+4.8, 8.4, 0]; `Sig` (halo centre) [0, 15.6, 0]. Meshes: Body 8224, Head 1420, FistL/R 1336, Sig 1008
- Frost Byte (z4_t4) unchanged: see the first pass (`Body` [0,0,0]; `Head` [0, 5.46, -0.26]; `FistL`/`FistR` [-/+2.6, 4.94, 0]).

## Picture match, redo read (the main session decides; UNVERIFIED until it has looked)
Compared at the sheet (az 24, el 8, same as the first pass) and per boss beside its crop.
- **Snap Scorpion: close.** Body raised on four tan legs a side that arch out (brown tips), segmented banded tail rising
  behind and arching over to a red bulb stinger hanging in front, angry face on the front (stepped brow, eyes, open mouth,
  fangs, tan muzzle), big curled orange pincers with yellow bands and red tips held at face height. Still off: tail thinner
  than the picture's chunky segments; at tier size (5.3) the stinger and claws are small on the sheet.
- **Bit Shark: partial to close.** Long tapered snout with the jaw open (upper jaw lifted, white lower jaw, teeth top and
  bottom, red mouth, tongue), eyes high on the snout under a dark brow slanting to the nose, body leaning forward, white
  belly running up into the jaw, big blue fists, swept dorsal fin, tail fin low behind. Still off: at az 24 the snout is
  foreshortened (the picture's shark is turned further, about 45 degrees), so the fin shows only as a tip behind the head
  and pectoral fins barely show.
- **Ember Drake: partial to close.** Long horned head with an open fanged jaw, stepped brow and cheek spikes, big yellow
  horns, wings rooted at the shoulder blades, very large red fists, cream belly plates, lava cracks (atlas colour `lava`)
  over chest flanks, legs, arms and fists; tail now runs from the rump round the right side, segmented with ridge
  spikes, into the basalt club (no flame). Still off: from the sheet angle the snout reads head-on (side view is right);
  the fist cracks read as patches more than thin lines.
- **Star Golem: close.** Domed head clear of a gold yoke with angry brow, glowing eyes and open mouth; huge gold-trimmed
  pauldrons; enormous purple fists with gold wrist bands at belt height; shield chest plate with the bright star; belt
  with octagon buckle; knee bands, flared gold boots with toes; star specks over body, legs, pauldrons and fists; tilted
  halo (`Sig`). Still off: proportions a bit stockier than the picture; the floating star cubes stay the aura effect.
- **Shared:** the picture's creatures are turned 30 to 45 degrees; the sheet keeps one angle (24) for all six, which
  flatters the frog and yeti and foreshortens the shark and drake snouts. Side views were checked during iteration.

## Sizes in the sheet vs the picture
The sheet is true to the tier-height table (4, 5.3, 6.8, 8.3, 10.9, 14 studs), so the small ones look smaller than in the picture, where the scorpion and shark are about as tall as 1.9x the frog.

## Import brief for the main session
One FBX per boss: `assets-src/models/<id>_atlas.fbx` (+ `boss-atlas.png`, same texture as the frog, already uploaded as 116542096217311 but the atlas has more cells now: **re-upload it**, UVs depend on the new cells). Importer: Merge Meshes off, Scale Unit Stud, Set Pivot to Scene Origin on. Expected mesh names are the group names above. Then `SetupBosses` per body type; wire ids into `Models.lua` (entries exist with 0).

## Not done
Moves and animation, Studio import and checks, Neon parts, the 30 other bosses, the Chomp Frog notes. Poses in the impact renders are static and rough (the animator owns moves).

## Fix pass (M2-24, modeler-3d, 2026-11-26): the art-director's must-fixes from `audits/m2-24-six-bosses-review.md`
Data: `tools/blender/make_m2_bosses.py` (helpers `fist()`, `crack()`), `build_boss.py` (new optional group `yaw`: rest
turn about z through the group's own pivot, cubes resampled; pivots never move). Rebuilt with `build_m2.sh`. Renders
in `verification/m2-six-bosses/`: `m2_sheet_vs_picture.png` (same angle and order as before, overwritten), per boss
`_guard`, `_impact`, `_vs_picture`, and `z3_t3_az40.png`, `z5_t5_az40.png` (the picture's angle). Blender stills; Neon not lit.

**Re-import all five** (`z2_t2`..`z6_t6` `_atlas.fbx`) **and re-upload `boss-atlas.png`**: 7 cells appended (50 -> 57),
old cells unchanged (checked), so the frog and gloves keep working on the old upload. Group names and every pivot
number unchanged (checked against the pre-pass data). Frog not touched.

| Must-fix | What changed |
|---|---|
| 1 Shark fin, ear bumps | Brow no longer rises above the head top (bumps gone). One dorsal fin on the upper back, 4 wide at the root, 2 above, raked back, tip 5 cubes over the head (z 35). |
| 2 Shark mouth | Open z 17..24 (about half the head): white rim, red inside recessed 2 cubes, 2 front + 3 side square teeth (2 tall) on top, 3 front + 3 side below, small low tongue; pointed snout tip over the mouth. |
| 3 Yeti eyes | White 3x3 eyes, 2x2 ink pupils, under a stepped blue brow; blue muzzle and 2-wide nose block between eyes and mouth (the should-fix). |
| 4 Yeti mouth | Open mouth x -5..5, z 18..22: two 3-tall fangs, three short top teeth, three bottom teeth, pink tongue, dark red behind, blue rim. |
| 5 Drake head | Skull 14 wide, snout 8 wide and 11 long (1.4x), mouth open with teeth along both jaws, nostrils on the tip, eyes set back on the skull's top-sides behind a stepped brow. Head turned 15 degrees at rest (group yaw, as the picture). |
| 6 Drake tail, club | TailB now sweeps out to the side and rises, so the tail shows beside the right leg; club is an angular basalt rock (flat faces, `#3E3842` with a lighter `#575060` top and chips), about fist size, bottom 2 cubes off the ground. No flame. |
| 7 Golem face | Two glowing yellow slit eyes (5 wide, slanted in, `star` colour) under a heavy stepped dark-purple brow 2 thick; open pink mouth, dark rim, 3 small teeth. Robot grin gone. |
| 8 Golem stars, purple | 7 medium plus signs (torso 2, legs 3, pauldrons 2) + the big chest star (long arms, small white-hot core) = 8; 25 single-cube specks; star colour now saturated `#FFD83A`. Purple deepened to `#6A20AC` with shades `#5F1C9E` / `#7626B8`. Glow share 4.3% (Mythic cap 15%). |
| TEAM CALL M2-24-1 | Scatter lists now main colour on 3 of 4-5 cubes, the others within about 4% lightness: scorpion `#EE7420`+`#E8802A`, shark `#2F6FD8`+`#3878DC`, yeti fur `w1`/`w2` (w3 dropped), yeti blue `#2F8FD8`+`#3896DB`, drake `r1`x3+`r3`, golem as above. Darker shades kept only for seams and brows. |
| Should: scorpion | Each claw is a palm at the side and two open jaws forming a C that opens toward the face, upper jaw bigger, 3-4 cube hole, red tips nearly meeting. Carapace slab pulled back 2 cubes; stepped brow shows above the eyes. |
| Should: fists | Shark, yeti, drake, golem: squared fists with rounded edges, flat front, a 3x3 grid of knuckle blocks split by darker recessed seams (the picture's chunky fist). Scorpion keeps pincers. Frog not changed (its own data, accepted, uses the old upload). |
| Should: shark fins | Small pectoral fin on the outer back of each forearm; taller crescent tail fin beside the right leg. |
| Should: drake lava | Cracks are 1-cube zig-zag lines (chest flanks, legs to the feet, back, tail top, across each fist, down each arm). Glow share 3.3%. |

**Tris (atlas route):** z2 9,636 (was 9,604); z3 11,228 (10,636); z4 10,316 (9,920); z5 17,964 (17,700); z6 14,020
(13,324). Largest single mesh golem Body 8,296. All under 20,000 per mesh; still far over the tier budgets (B6).

**Sizes that changed (studs, Roblox X,Y,Z):** shark 7.48 x 7.70 x 7.70 (height was 6.82: the fin tip is 0.9 over its
6.8 tier height, like the golem's halo); drake 14.84 wide (club further out); scorpion 6.46 wide. Group bounds that
moved: scorpion fists (lower and wider), shark Upper (fin) and Head (yaw), drake Head (yaw) and TailB (x -7.8, z to 4.8).
`back` reach is unchanged on all; **M2-25's `MovesM2Real` must be re-run** after the re-import: the drake club now
swings on a longer radius (it landed z -5.54 before), the shark and drake heads are turned at rest, and the
scorpion claws sit lower. If `lie` comes out different, `_geo.lua` needs the new numbers (scripter).

**Honest match read** (sheet and beside-picture, my own look; the main session's look still decides):
- Snap Scorpion: close. Open C pincers with red tips read; brow visible. Tail still thinner than the picture (note left).
- Bit Shark: close. Reads as a shark now: fin over the head, pointed snout, wall of teeth, red mouth, eye under brow.
  Head is boxier than the picture's.
- Frost Byte: close. Face is the picture's face (eyes, brow, nose, fanged mouth, tongue). Fists hang at the hips (guard pose, animator).
- Ember Drake: close. At 24 and 40 degrees the snout, eye and brow read as the picture's dragon; tail and rock club
  show. Fist cracks read as short dashes between the knuckle blocks, not long glowing lines (Neon will help).
- Star Golem: partial to close. Face, stars and chest star now right in kind; proportions still stockier (legs not
  lengthened: that would move every pivot above the hips, so it waits for a call).
