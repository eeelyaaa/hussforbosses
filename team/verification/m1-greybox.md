# M1-05: greybox slice, measured (builder, 2026-11-25)

Built by `studio/BuildSlice.lua` (greybox: plain parts, no skin, no variant). Measured by `studio/checks/GreyboxMeasure.lua` in Studio edit mode (lock held, released). Layout figures: `team/pack/base-layout/base-layout.md` section 5, plot 1, from `src/layout.py` (walk 16, carry 12, Fast Carry 16; path = bag pad centre, door at (96, 179), gate centre (206, 234), fixed pad centre minus the ring radius 6).

## Build
- `BuildSlice.lua`: 33 PASS lines, 0 failed (names, tags, attributes as contract B; bag pad centre hub (89, 165); entrance centre (95.5, 179)). Run twice: 74 descendants both times, 10 `HFB_Spot` (idempotent). Ran on a place that already holds only Baseplate, SpawnLocation and Terrain.
- Not run on an empty place (the Baseplate was present); the script destroys and recreates only `Plots`, `Hub`, `Zones`, `Sight`.

## Numbers against the layout (plot 1)
| Measure | Layout | Built, same method | Built, PathfindingService | Difference |
|---|---|---|---|---|
| Bag pad centre to the entrance | 16 | 15.7 | | -2% |
| Bag pad to the gate | 139 (8.7 s) | 138.6 (8.66 s) | 138.1 | -0.3% |
| Bag pad to zone 1's fixed pad ring (run) | 183 (11.4 s) | 182.6 (11.41 s) | 179.3 (11.21 s) | -0.2% / -2% |
| Carry home, walk-speed path, carry 12 | 15.2 s | 15.21 s | 14.94 s | 0% / -2% |
| Carry home, Fast Carry 16 | 11.4 s | 11.41 s | 11.21 s | 0% / -2% |

All inside 10%. Nothing flagged for the game-designer on the numbers. (Pathfinding is shorter because it cuts the door corner.) Gate to the fixed pad centre: 49.9 (the 44 "in" is from the wall's outer face, Y 236 to 276 is 40, and the gate line Y 234 to 276 is 42 deep; the diagonal is 49.9).

## Sight line, plot 1 bag pad, over the 4-stud front wall (raycast in edit mode)
Eye = standing on the bag pad, 5.5 high. Camera = the default third-person camera turned to the target (12.5 behind the head, 2 above). Invisible blockers excluded (the camera does not see them).
- Fixed pad **number anchor** (Y 13.5): eye CLEAR, camera CLEAR. The line crosses the wall at X 179.8, height 10.5, clearance 6.5 over the 4-stud wall.
- Fixed pad **ring centre** (ground, Y 2.5): BLOCKED by the front wall (eye) and by the log stand-in (camera). So the flat pad is hidden behind the wall; the Power number and a boss standing on it (anything above about 3 studs over the pad) are in view. This matches what the layout promises (the number is read over the wall), not a visible floor ring.
- **Windmill stand-in** (130, 340), 44 tall: CLEAR at 10, 20, 30, 40 and 44 studs from the standing eye; the line crosses the wall about 16 studs above its top. At the first position (150, 340) the **name board** (Y 7.5..11, 16 wide over the entrance) blocked everything above 30 studs. The camera estimate for the windmill is blocked by plot 1's own **bag frame** (14 tall); the engine pulls the camera in then (UNVERIFIED on screen).
- Flag for the art-director (not a number): the name board and the bag frame are the only things over 4 tall between a bag pad and the front wall, and they sit on the windmill's bearing from plot 1; the layout's rule "nothing taller than 4 studs between the plot fronts and the front wall" is not true of the plot's own front. The windmill position (TEAM CALL M1-05-3) avoids it for plot 1 only; plots 2 to 8 are not built.

## Measured surprise
`Workspace:Raycast` hits a part with `CanQuery = false` when `CanCollide` is on (the invisible fence and wall blockers were hit). Contract B says "CanQuery off"; code that raycasts in the hub must exclude them by name or tag.

## On-screen checks owed (main session, `computer`, then `studio`; run `BuildSlice.lua` first)
1. Overview from above the hub (camera over X 206, Z 190): plot 1 at the left wall facing +X, the track, start line, front wall, gate, lane, fixed pad, log, windmill tower. Confirms the plot is turned the right way (bag at the plot's right as seen from the yard: the bag pad is the red pad on the gate-side, hub Z 165, with the spawn beside it).
2. Play from plot 1's `SpawnPoint`: default camera, standing on the bag pad, facing the bag, then turned toward the gate: is the fixed pad's number anchor (a small invisible part at Y 13.5 over (233, 276)) in frame over the front wall, and the windmill tower above the wall? Phone-size viewport (874 x 402) too.
3. The camera at the bag pad: does the bag frame or the name board pull the camera in?
4. Walk the intended route: spawn, bag pad, entrance, track, gate: no collision trap at the fence ends or the driveway; the fence blockers stop a jump over the 3-tall fence.
5. The wall blocker: can a character hop the 4-stud front wall (it should not: blocker to 10).

## Files
`studio/BuildSlice.lua`, `studio/checks/GreyboxMeasure.lua`, `assets-src/stud/` (below), decisions M1-05-1 to 5.
