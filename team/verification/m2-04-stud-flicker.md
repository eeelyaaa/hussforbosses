# M2-04: the stud that vanishes and returns with distance (builder, subagent, 2026-11-25)

## Read back (Studio MCP, edit mode, studio lock)
- `MaterialService.Stud`: SmoothPlastic, StudsPerTile 4, ColorMap 106741057264448, NormalMap 95643445290942 (flipped), RoughnessMap 106124900748892, Regular pattern. 54 of 104 parts use it; 2 are larger than 200 studs. QualityLevel reads Automatic.
- The colour map is a FLAT #F2F2F2 (`make_stud_maps.py`; roughness flat too). The stud exists only in the normal map. No alpha anywhere (so the known "transparent MaterialVariant swaps to a low-detail version" bug does not apply).

## Cause (confidence medium; not reproduced on screen, no agent can see)
With a flat colour map the stud is drawn by lighting the normal map alone. A normal map's effect depends on the light angle and view angle (official PBR doc: it "may fade or intensify depending on the viewing angle and lighting"), and its mips average to a flat normal as the 64 px stud shrinks, so the stud washes out at range. Near the sun's glancing angle or head-on it reappears: that is "disappears and comes back". Candidates ruled out by read-back: alpha/transparency (none), StudsPerTile vs size (4 studs = 256 px = 64 px per stud, mip-friendly), z-fighting (Baseplate deleted; `BuildSlice` ZFIGHT PASS 0 pairs, unchanged), Terrain (not used), flipped normal (direction only). Not tested: quality 1/5/10 on screen, MaterialVariant streaming.

## Fix (smallest: the colour map carries the stud too)
- `assets-src/stud/make_stud_maps.py` now also writes `stud-color-baked-256.png` (same tile, inset stud and wall foot darkened to 70 percent in the colour, blurred 2 px). Colour contrast survives mips and does not depend on light angle. Other maps are byte-identical (re-run).
- `Tokens.stud.worldColorBakedMapId` (0 until uploaded) and `studio/SetupStud.lua` uses it for all three variants when non-zero. Not yet uploaded: BLOCKED main session (group-owned image upload, listed in approval 3), then put the id in Tokens and re-run `SetupStud.lua`.

## On-screen checks owed (main session, `computer`)
Before the swap (current flat map) then after: camera in `Workspace.StudProof` set B (ox 200), faces -Z, `workspace.CurrentCamera.CFrame = CFrame.lookAt(pos, target)`:
1. Floor, looking +Z from (240, h, 401) at (240, 0, 470), h = 3, 12; distance to the target 10, 40, 100 studs: pull back along -Z or use the zone 1 ground. Repeat at sun-facing and sun-away headings.
2. Each at `settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 / Level05 / Level10`, then reset to Automatic.
3. Pass: studs visible as a dark pattern (or a clean even tone, no flashing) at 40 and 100 studs, same before/after heading; compare old vs baked.
Phone-width viewport is also owed. A real phone stays UNVERIFIED.
