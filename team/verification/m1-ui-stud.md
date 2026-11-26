# M1-15 UI stud proof (gui-designer, 2026-11-25)

Pass: Function. Files: `studio/checks/UiStudProof.lua` (builds + reads back), `Ui/Kit.lua` (optional `fixedScale` on `StudTile` and `Plate`; proof only).
Tile: `Tokens.stud.uiTileId = 70915382854444`. `python tools/check_skin.py`: 0 hits, 38 files. `python tools/check_guard.py`: clean.

## Where the proof is
`StarterGui.StudProofUi` is built in the open place (edit mode; it also shows in play mode). Three sections left to right, each a design
frame 300 x 280 under its own UIScale: **0.75, 1.00, 1.65**. Each has a caption, one panel (280 x 96 design px, 4 px `UICorner`, 3 px ink
outline, tile, "POWER 1,234" in 16 px Montserrat Heavy over the studs) and the round Huss button below it. Needs a viewport at least
1100 x 500 px (the 1.65 section is 495 x 462 px): use the 1280 x 720 or 1920 x 1080 view, not the 874 x 402 phone view.
- Show: Studio edit mode, open the 3D viewport (StarterGui GUIs draw over it), or press Play. Rebuild: sync, then
  `require(game.ServerStorage.DevSync:Clone()).run("checks/UiStudProof.lua")`.
- **Remove with one call:** `game.StarterGui.StudProofUi:Destroy()`.

## Read-backs (Studio MCP, edit mode, studio lock held; script output)
| | 0.75 | 1.00 | 1.65 |
|---|---|---|---|
| Panel AbsoluteSize (px) | 210.0 x 72.0 | 280.0 x 96.0 | 462.0 x 158.4 |
| Panel tile `TileSize` (design Offset) | 16 x 16 | 16 x 16 | 16 x 16 |
| Tile on screen (Offset x UIScale), clamp 12..32 | 12.0 PASS | 16.0 PASS | 26.4 PASS |
| Studs across the panel (w x h) | 17.5 x 6.0 | 17.5 x 6.0 | 17.5 x 6.0 |
| Tile `ScaleType`; `AbsoluteSize` equals panel | Tile; true | Tile; true | Tile; true |
| Panel `UICorner` / tile `UICorner` (design px) | 4 / 4 | 4 / 4 | 4 / 4 |
| Huss button design px (on screen; floor 96) | 128 (96.0) | 120 (120.0) | 120 (198.0) |
| Round face AbsoluteSize | 90.0 | 112.0 | 184.8 |
| Face `UICorner` / tile `UICorner` (Scale) | 0.5 / 0.5 | 0.5 / 0.5 | 0.5 / 0.5 |
| `UIStroke.Thickness` (design px): panel / Huss face / text | 3 / 4 / 2 | 3 / 4 / 2 | 3 / 4 / 2 |
| Expected on screen if strokes follow UIScale | 2.25 / 3.0 / 1.5 | 3 / 4 / 2 | 4.95 / 6.6 / 3.3 |

What this shows:
- `TileSize` in Offset is in **design px under the section's UIScale**: the same Offset 16 renders 12, 16, 26.4 px, so the tile follows the
  scale and the panel shows 17.5 x 6 studs at every scale. The Kit rule (clamp 16 x scale to 12..32 on screen, divide by scale) holds; at
  these three scales the clamp is not reached (it is at scale below 0.75 or above 2.0).
- The tile image is a child with the same size as its surface and its own `UICorner` (4 px design on the panel, 0.5 Scale on the round
  face). `UICorner` clips an `ImageLabel`'s image, so no `ClipsDescendants` container is needed; the pixel result is the on-screen check.
- API cannot read rendered stroke width. `Thickness` stays at the design value; that it scales with the UIScale is the on-screen check
  (compare the ink outline of the 1.65 button with 1.0: 6.6 px vs 4 px).
- At 0.75 the Huss button is built at 128 design px so it is 96 px on screen (the HUD's floor); at 1.0 and 1.65, 120.

## Font weight
- `Tokens.font = { family = "Montserrat", weight = "Heavy" }`. `Enum.FontWeight.Heavy.Value = 900`; `Enum.FontWeight.Black` does not exist
  (error "not a valid member"). The Studio install's `content/fonts/families/Montserrat.json` lists the face "Black", weight 900,
  asset `rbxasset://fonts/Montserrat-Black.ttf`, so **Heavy is the name that selects Montserrat Black**. `Kit.fontHeavy` reads back
  Weight Heavy, family `rbxasset://fonts/families/Montserrat.json`. Body: Bold (700, "Bold"). Confirmed; Tokens unchanged.
- `TextService:GetTextBoundsAsync` at 40 px for "HUSS HUSS HUSS": Regular 306, Medium 306, SemiBold 306, Bold 308, ExtraBold 311,
  Heavy 311. Not usable as proof (Heavy equals ExtraBold, so the measurement context likely had not loaded the faces). Whether the label
  renders as heavy as the board is an on-screen check.

## Image load
`ContentProvider:PreloadAsync` on the panel tile ImageLabel: `rbxassetid://70915382854444 Success`, `IsLoaded = true`.

## On-screen checks owed (main session, computer use; items stay UNVERIFIED until looked at)
Setup: Studio edit mode, viewport at least 1280 x 720 (the proof ScreenGui is in StarterGui), nothing else in front. Capture the three
sections left to right, and zoom into each. Beside them: references 1 and 2 (`concepts/manager-refs/1.png`, `2.png`) and `ui-kit/phone-hud-base.png`.
1. **Studs read as references 1 and 2** on both the panel and the red button: a small square inset stud per tile, a dark L along the
   left and bottom edges, a faint light line along the top and right, same colour as the surface. No pegs, no rings, no visible seams
   between tiles. Panel is Panel grey (#B4BBC6), button is Huss red (#E02A2A).
2. **Scale**: stud size grows with the sections (about 12, 16, 26 px per tile) and each panel shows the same count, about 17 and a half
   studs across and 6 down. At 0.75 the tile is 12 px: check it is not just noise.
3. **Round clip**: the stud pattern ends on the button's circle with no square corners poking past the circular edge, at all three scales
   (zoom on the four diagonal edges of the 1.65 button). The panel tile corners follow the 4 px corner (no overhang past the outline).
4. **Stroke**: ink outline of the button and panel is visibly thicker at 1.65 than at 1.0 and thinner at 0.75 (about 6.6, 4.0, 3.0 px
   on the button). If equal at all three, strokes do not follow UIScale: report, and the Kit will multiply thickness by scale.
5. **Text over studs**: "POWER 1,234" (16 px design: 12, 16, 26 px on screen) and "HUSS!" with the 30% dark L underneath. Is it readable,
   or too busy at 0.75? If busy, the cheap fix is lowering the tile's dark L to about 20% in the art (an asset change, not mine).
6. **Weight**: HUSS! and POWER look like Montserrat Black (heavier than Bold), as on the kit's type sheet.
7. The three captions read "UIScale 0.75 / 1.00 / 1.65".
8. Backdrop is dark blue so edges read; the proof is not a design.
Then remove the proof: `game.StarterGui.StudProofUi:Destroy()`.

## Not measured
Rendered pixels (stud shape, clip, stroke width, font heaviness); the tile on a real phone (manager).
