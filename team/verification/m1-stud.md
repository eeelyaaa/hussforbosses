# M1-21: stud checks (style guide section 13, builder items), 2026-11-25 (builder, subagent)

Studio MCP and `studio` lock used (edit mode, no play mode). Subagents have no `computer`: every item that needs the eye is `UNVERIFIED` below, with the shot list. Nothing was uploaded; `StudProofUi` was not touched (stays `Enabled = false`: the manager's note).

## What changed in the place
- `studio/BuildSlice.lua`: Hazard_Log fix (see the end), plus one assert. Re-run in one go (replaces Hub/Plots/Zones/Sight atomically): `PASS, 0 failed`, `ZFIGHT PASS (82 visible boxes scanned, 4 rotated skipped): 0 pairs`.
- `studio/SetupStud.lua`: each proof set got a `RotatedWall` (TEAM CALL M1-21b). Re-run: proof strip is 58 descendants, 32 BaseParts. `MaterialService.Stud` is still the plain stand-in.

## Section 13 builder items

| Item | Result |
|---|---|
| Normal-map direction A vs B | **UNVERIFIED (needs the eye).** Both are built: set A (left, X 100..180) = normal as made, set B (right, X 200..280) = flipped. A script cannot read lighting. See shot list 1 and 2 for what to compare. Decision rule from the style guide: the right one shows a dark L on the left and bottom edges of a wall face and a dark corner on the ground, as in references 8, 13, 14 |
| `BasePart.Color` tints the variant | **UNVERIFIED (needs the eye).** Read back: three tint cubes (`TintRed` 0.878/0.165/0.165, `TintGreen`, `TintBlue`) plus the gold crate, one variant (`StudProof_A` / `_B`) on all, `Color` set per part, `Material` SmoothPlastic. So the setup is right; whether the renderer multiplies the near-white colour map by `Color` shows in shot 3 (cubes read red, green, blue, not white). If white or grey: route B (a `Texture` per visible face) |
| Tiles line up across neighbouring parts | **PASS by construction, look owed.** `StudsPerTile` 4; every wall brick's min corner is a multiple of 4 on X, Y and Z modulo the brick grid (R1_a/R1_b: x 104, 108, z 440 all mod 4 = 0; the second row y 2 so mod 4 = 2, a half-tile step up, which is the same on every brick). The look (shot 4) confirms the studs run continuous over the seams |
| Tiles on rotated parts | **UNVERIFIED (needs the eye).** `RotatedWall`: three 4 x 2 bricks turned 90 degrees (min corners mod 4 = 3 / 1 / 3 on X, so the edges do not sit on a tile boundary) and two 8 x 2 bricks turned 45 degrees (min corner X mod 4 = 2.46 / 0.46). Look for a break in the stud rows at the seams; compare with the axis-aligned wall at the same distance (shot 5). If rotated parts break, rotated parts in the game (none planned in M1) go on a grid or take route B |
| Stud depth at quality levels 1, 5, 10 | **Partly measured.** `settings().Rendering.QualityLevel` reads `Automatic` and accepts a write (`Level01`) from the MCP without error, restored to Automatic after. Whether the edit-mode viewport re-renders at that level is not readable. So: the main session sets the level with `settings().Rendering.QualityLevel = Enum.QualityLevel.Level01` / `Level05` / `Level10` from `run_code` (or the Studio setting) and takes shot 1 at each. `Lighting.Technology` is not readable from the MCP (needs RobloxScript capability). Note Studio's edit-mode graphics-quality setting is a different number from a phone's level; a real phone remains `UNVERIFIED` |
| The 1-stud tile at distance (lane strip) | **UNVERIFIED (needs the eye).** The proof floor is a 70-deep slab (Z 400..470), longer than the lane's 40-stud strip. Shots 6 (A and B) look down it from the south edge at a shallow angle. The lane itself has no stud yet (stand-in variant) |
| Upload size and moderation state of the four images | **Size measured, load and moderation UNVERIFIED.** Files: colour 564 B, normal 1,895 B, flipped normal 1,895 B, rough 369 B (UI overlay 245 B), all 256 x 256 (UI 64 x 64), far under Roblox limits. Variants read back the ids `106741057264448` (colour), `106077758301166` (normal), `95643445290942` (flipped normal), `106124900748892` (rough). `ContentProvider:PreloadAsync` on the variants returned without error but its callback printed nothing, so a load is not proven. Moderation state is not visible to agents (Creator Dashboard, manager). If the maps do not appear in the shots, the first suspect is moderation or the images still pending |

## Shot list for the main session (`computer`, then `studio`)
Run `workspace.CurrentCamera.CFrame = CFrame.lookAt(pos, target)` from `run_code` (works in edit mode, tested: it moved the camera). Set A has `ox = 100`, set B `ox = 200`; faces point -Z, camera stands south of them. Take each at the default camera FOV in a desktop viewport and again at 874 x 402. Default sun, no lighting change. Do not enable `StarterGui.StudProofUi`.

References: `C:\Users\elya\Desktop\ro-team\projects\huss-for-bosses\team\pack\concepts\manager-refs\` : `8.webp` (world stud, wall), `13.webp`, `14.webp` (ground corner and wall), `1.png`, `2.png` (UI studs). 10, 11, 12 are further world references if needed.

| # | Shot | pos | target | Looks for |
|---|---|---|---|---|
| 1 | Wall close, 3 studs (A: ox 100 / B: ox 200) | (ox+10, 2.5, 437) | (ox+10, 2, 440) | Which set shows a square inset stud with a dark L on the left and bottom, as in 8 and 13. Repeat at quality 1, 5, 10 (stud still visible?) |
| 2 | Wall at 40 studs | (ox+10, 5, 401) | (ox+10, 2, 440) | Studs still read as a pattern, not noise or flat |
| 3 | Tint cubes + crate | (ox+40, 4, 412) | (ox+38, 2, 422) | Red, green, blue and gold each read as their colour, with the stud on top of it |
| 4 | Brick wall seams | (ox+10, 2, 434) | (ox+10, 2, 440) | Stud rows continuous across the 4 and 8-wide bricks and the half-step between rows |
| 5 | Rotated wall (90 degrees) and (45 degrees) | (ox+14, 3, 450) then (ox+34, 3, 449) | (ox+6, 2, 456) then (ox+33, 2, 456) | Rows continuous or broken at the seams; compare with shot 4 |
| 6 | Floor down the 40-stud strip | (ox+40, 4, 401) | (ox+40, 0, 441) | No shimmer or moire at distance, ground dark corner as in 14; then (ox+40, 12, 401) to (ox+40, 0, 470) for the whole 70 |
| 7 | Floor close | (ox+40, 5, 405) | (ox+40, 0, 410) | Ground stud shape: dark corner, not a peg |
| 8 | UI button | (ox+60, 3, 418) | (ox+60, 3, 430) | The overlay tile on the button beside references 1 and 2 (this is the SurfaceGui button, 12 x 6) |

Sets side by side, a wide shot: pos (190, 22, 395), target (190, 0, 440). For an A/B decision the cleanest comparison is shots 1 and 7, A beside B.
Does the Baseplate matter? The default Baseplate was deleted by BuildSlice; the proof floor is its own slab.

## Hazard_Log fix (task 2): PASS
Old: 36-long cylinder, 4 thick, axis across the lane (X), pivot Y 2.2. New: size from `Config.Hazards.LOG` = 12 x 6 x 6, the cylinder's X turned 90 degrees about Y so the axis runs along world Z (the lane), `Hazard_Log` PrimaryPart `Log`, pivot (206, 3.2, 248): X on the lane centre line, Z the middle of the run 236..261, Y = lane top 0.2 + radius 3. CanCollide, CanQuery and CanTouch false. Why this axis: `Hazards.logCFrame` slides `track.home` along world X (`across`), and the client rolls it about `track.along` (world Z) then `home.Rotation`, so a log whose own axis lies along Z spins like a log. Asserts (new, in the log): `PASS Hazard_Log stand-in = Config size, pivot on lane centre X 206 at height 3.2, axis along Z, CanCollide off`; all older asserts PASS; `ZFIGHT PASS 0 pairs`; `BuildSlice: PASS, 0 failed, 84 descendants`. Not seen on screen (UNVERIFIED, on-screen list): the log lying along the lane at the lane centre, 3.2 above the lane, and rolling in play mode.

## Handoff
- M1-16 gate scripter: BuildSlice.lua was run three times in a row (edit mode, whole script each time, so Hub/Plots/Zones/Sight were replaced atomically each time) and ends complete. The `Hazard_Log` instance is new: any reference held from before is dead (fetch by path again). It is still at the same path, tag and attribute.
- The stand-in `Stud` variant is unchanged; promotion after the manager's yes is still the one change in `SetupStud.lua` (`PROMOTE`) and `Tokens.stud.normalFlip`.
