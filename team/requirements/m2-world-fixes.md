# M2: world labels (P1), the stud texture (P7), bosses that patrol (P5, server and design)
Tasks M2-05 (gui-designer, sonnet), M2-04 (builder, sonnet; tech-lead diagnoses if it fails twice), M2-10 (patrol, in the
economy requirement). Quality pass: **Function**. Contract sections A, E.

## The brief (the manager's words, 2026-11-25)
- P1: "I really don't like the UI elements over things that scale up as you get further away. make this a rule everywhere." World labels shrink with distance like the world (size in studs), or do not exist. Fix the pad number first.
- P7: "the stud texture disappears and comes back with distance ... idk something causes it." Find the cause and fix it.
- P5: bosses "walk back and forth along their region", not standing on one platform; the player walks up to a boss to start the fight, as now. M2 does the design and the server, M3 the world.

## Work
- M2-05: every `BillboardGui` in `src/` (Pads, Base, Carry, Prompts) and `studio/` is replaced by `Ui/WorldLabel`: a
  `SurfaceGui` or a `BillboardGui` with `Size` in studs (`UDim2.fromScale` with `StudsOffset`, `SizeInStudsOffset`,
  `AlwaysOnTop` false, `MaxDistance` 150) so it shrinks with distance; the pad number reads (colour and word from Skin).
  Scan report: every hit in `verification/m2-05-world-labels.md` with before and after; a repo scan script
  `tools/check_labels.py` fails on any `BillboardGui` whose `Size` uses Offset. Prompts that are screen UI stay.
- M2-04: reproduce the vanishing stud at 10, 40, 100, 200 studs and at quality levels 1, 5, 10 (Studio MCP); candidates:
  MaterialVariant normal or colour map size or mip, `StudsPerTile`, texture streaming, `SurfaceAppearance` alpha. Fix by the
  smallest change (route B, a larger or 2-stud tile, a lower contrast detail) and prove it with `studio/checks/StudDistance.lua`
  (part colour sampled by raycast-free viewport capture or the Studio screenshot at four distances). Reports cause and fix.
- Patrol design, server function and the stand-in on the test strip: M2-10 (section E of the contract); M3 builds real regions.

## Acceptance criteria
1. No world label keeps a screen size with distance: the scan is clean; the pad number is smaller at 100 studs than at 10 (measured on screen).
2. The stud ground reads as studs at 5, 40 and 100 studs at quality 1, 5 and 10 (screenshots in `verification/m2-04-stud.md`).
3. A boss on the test strip walks back and forth through its pad's patrol; fight start works from the boss's current spot (see economy requirement).

## Not asked for (do not build)
New world art, zones or walls (M3); stud on anything else; new label styles; a patrol that attacks or chases.
