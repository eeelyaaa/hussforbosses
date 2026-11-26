# M2 art track: the first six bosses, their moves, the avatar's clips
Touches none of the systems' files. Quality pass: **Function** (the picture match is the art-director's review; Look and Feel
follow in M3 and M4). Source: `pack/build-plan.md` "Art track", `style-guide.md` sections 5 and 13, `concepts/brick-brawl/creatures.png`.

## The brief
The five other pictured bosses (Snap Scorpion, Bit Shark, Frost Byte, Ember Drake, Star Golem) are built from `creatures.png` so the manager
can look at all six before the other 30 are made. Moves for the four body types the six cover plus their six signatures
(the scorpion's tail sting then pincer punch first), and the avatar's other five clips.
Ember Drake: dark-basalt rock-club tail, no flame.

## Tasks
- **M2-ART (running, modeler-3d, sonnet):** the five bosses in Blender; own files `tools/blender/*`, `assets-src/models/*`, `art/`,
  `studio/` boss setup data, `Skins/brickbrawl/Models.lua` entries for the new bosses; renders of guard and signature impact;
  triangle counts at the pictures' density (B6). Not re-planned here.
- **M2-22 (animator-vfx, sonnet):** move sets for tailed striker, rearing swayer, biped bruiser (as the squat set in `Shared/Moves/squat.lua`, fractions of H,
  the schema check) and six signatures (`z1_t1` exists; scorpion, shark, Frost Byte, Ember Drake, Star Golem, Chomp Frog kept).
  Needs the models for the on-screen look; the scripted schema check can run first.
- **M2-23 (animator-vfx, sonnet):** the avatar's five other clips (flinch, carry hold, steal lift stretched to the hold, knockdown, stun),
  published under the group (Studio publish; the approval covers uploads on the asset list; computer use or the MCP by the main session).
  Hooks for flinch and stun in `Controllers/Avatar.lua` are called by M2-16.
- **M2-24 (art-director, opus):** the six bosses' renders beside `creatures.png`, same angle, same order; a list of mismatches; the
  modeler fixes what fails twice (opus rule). Writes `verification/m2-24-six-bosses.md` with the manager's "look at" renders.
- **M2-25 (modeler-3d, sonnet, then animator-vfx):** one test boss per body type at the smallest and largest tier (tailed, swayer,
  biped, squat): one set of offsets drives both without re-pivoting; `studio/checks/BodyTypeExtremes.lua`; fixes the M1 notes
  (Chomp Frog brow ends, wide eyes, nostril cube size) and re-measures `hitBig` and `defeat` in Body space.

## Acceptance criteria
Each of the six has its body type's groups and pivots, named exactly; the smallest and largest of a body type use one set of offsets;
triangle counts are reported against the tier budgets; the six renders stand beside their pictures; the art-director's mismatch list is closed or listed.

## Not asked for (do not build)
The other 30 bosses (they wait for the manager's yes after the six); Higgsfield 3D; new body types; bosses' real world placement (M3);
boss sounds (M4); the more-intense fight animation (P6, M4).
