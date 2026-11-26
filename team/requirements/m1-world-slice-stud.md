# M1: the flat test strip (the manager's plot, the track start, zone 1 start) and proof 2, the stud

Build to `m1-contract.md` section B and F (`Tokens.stud`); layout from `team/pack/base-layout/base-layout.md`
sections 2 to 5 (the plans `01` to `04` are the spec). Quality pass: **Function only**.

## The brief
"One flat test strip built by `studio/BuildSlice.lua`, to `base-layout/`: the manager's own plot (the plot template
at its real size, entrance, bag at its front right with its pad and sign, lock pad and board, crate, spots with
cash pads), the track start (the 36-wide track with its start line) in front of it, 40 studs of lane, the zone 1
gate, one pad, the log." The builder **greyboxes this slice first and measures** the bag pad to the gate, the run
to zone 1's fixed pad and the carry home, and the sight line from the bag pad over a 4-stud wall to the fixed pad
and the windmill, at the default camera. **Proof 2, the stud:** the `Stud` MaterialVariant (three maps made by
script from `style/make_stud_refs.py`'s height map) on a test strip: a wall, a floor, a crate and one UI button,
beside the manager's references 8, 13, 14, 1 and 2, built both ways for the normal map. Until the manager says
yes, the `Stud` variant in the world is a plain stand-in under the same name, so the yes changes one instance.
Studs are applied on every face of every built part (style guide section 2) only after that yes: M1's slice
carries the stand-in variant name on its parts.

## Tasks
- **M1-05 builder (sonnet), wave 1, `studio` lock:** (a) runs `team/pack/style/make_stud_refs.py` (or its copy)
  into `assets-src/stud/`: `stud-color-256.png`, `stud-normal-256.png` and a flipped normal, `stud-rough-256.png`,
  `stud-ui-overlay-64.png`; (b) `studio/BuildSlice.lua` greybox: plot 1 (50 x 92, rotated to face +X per the
  hub frame, plot 1 at X 4 to 96, Y 154 to 204), the fence and its invisible blockers, entrance, spawn, bag pad
  and bag stand-in, spots 1 to 10 with cash pads, lock pad and board, crate, spots-full sign, name board; the
  track (X 188 to 224, from Y 100), start line (Y 226 to 228), the 4-stud front wall with the invisible blocker to
  10 and the 36-wide gate opening, the gate arch stand-in, the lane to Y 300, the fixed pad at (233, 276), the
  windmill stand-in (a tall grey tower, position as the layout's plan 01) and the log stand-in; all instance names
  and tags per contract B; (c) measures and writes `team/verification/m1-greybox.md`: bag pad centre to the gate,
  to the fixed pad's ring, carry home from the pad to the entrance (walk 16, carry 12, Fast Carry 16 as times),
  the default-camera sight line over the 4-stud wall from the bag pad to the fixed pad's number anchor and the
  windmill, all against `base-layout.md` section 5 (plot 1: 139 to the gate, 183 to the fixed pad, 15.2 s carry).
  A difference over 10% goes to the game-designer in the report, not absorbed; any dimension changed goes in
  `decisions.md`.
- **MS-A (main session):** uploads the three world maps and the UI tile to the group (`team/assets.md`).
- **M1-12 builder (sonnet), wave 3, `studio` lock:** the real `BuildSlice.lua` (colours from `Skin.Tokens`,
  part sizes unchanged from the greybox, the `Stud` MaterialVariant created by `SetupStud.lua` as a stand-in
  without studs until the manager's yes), `SetupBosses.lua`, `SetupGloves.lua`, the log model; both normal-map
  directions on the proof strip (wall, floor, crate, one UI button via the Kit), `studio/SetupStud.lua`
  (creates `MaterialService.Stud` with the three ids, `StudsPerTile = 4`, base SmoothPlastic); the strip is
  `Workspace.StudProof` (separate from the game slice, can be deleted). The script runs again on an empty place.
- **M1-21 builder (sonnet), wave 4, `studio` lock:** style guide section 13's builder items, each a PASS/FAIL line in
  `team/verification/m1-stud.md`: normal-map direction (both ways, pick); `BasePart.Color` tints the variant (one part,
  three colours; else route B and say so); tiles line up across neighbouring parts and on rotated parts (a wall of
  mixed part sizes); stud depth at quality levels 1, 5 and 10; the 1-stud tile at distance down the 40-stud strip
  (a 2-stud ground tile only if it shimmers, and then a request, not a build); upload size and moderation state of
  the four images; the proof sheet inputs list for the main session's captures.

## Acceptance criteria
1. `BuildSlice.lua` run twice gives the same instances (idempotent) and runs on an empty place; instance names and
   tags exactly as contract B (a script asserts them: PASS lines).
2. The greybox numbers are in `m1-greybox.md` and within 10% of `base-layout.md` section 5 for plot 1, or sent to the
   game-designer. The sight line over the 4-stud wall from the bag pad sees the fixed pad's number anchor and the
   windmill stand-in at the default camera (on-screen capture by the main session).
3. The stud proof strip exists with both normal directions; the proof sheet (captures beside references 8, 13, 14,
   1, 2) is ready for the manager (`manager-todo.md`, "stud proof").
4. Nothing outside the proof strip carries a stud look until the manager says yes; one instance
   (`MaterialService.Stud`) changes when they do.

## Risks
The MaterialVariant not tinting by `BasePart.Color` (route B: `Texture` per visible face); normal map facing the
wrong way (two builds); tiles misaligned on rotated parts (plot 1 is rotated); a greybox that disagrees with the
layout's paper numbers.

## Suggestions from the vault (optional)
None added.

## Not asked for (do not build)
The other seven plots, the hub's back and side walls, the yard scenery (trees, bushes, flowers), the zone 1
corridor walls and centre line, the other five zone gates, other hazards, props and landmarks, boss pads other than
the fixed one, lighting or atmosphere beyond Studio's defaults and the one plain sun, water, sky, the shield walls,
the lock shield visuals, a 2-stud tile unless the shimmer test demands it (then a request).
