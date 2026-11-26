# M2-05: world labels shrink with distance (gui-designer, 2026-11-25)
Rule (manager, 2026-11-25): no world-attached UI keeps its screen size with distance. Studs, or not there.

## Scan: every hit in src/ and studio/ (before -> after)
| Where | Before | After |
|---|---|---|
| `Controllers/Pads.lua` PowerNumber (pad number) | BillboardGui 6 x 1.6 x 33 px, AlwaysOnTop, MaxDistance 400 | `Ui/WorldLabel`, 14 x 6 studs, TextScaled, not on top, MaxDistance 150 |
| `Controllers/Base.lua` cash on pads | 110 x 30 px, offset 3.5 up, MaxDistance 150 | WorldLabel 4 x 1.2 studs, offset 3.5 up, 150 |
| `Controllers/Carry.lua` DropPlate (grab timer) | 64 x 64 px, AlwaysOnTop, MaxDistance 400 | WorldLabel 4 x 4 studs, not on top, 150 |
| `studio/SetupStud.lua` x2 SurfaceGui | PixelsPerStud 24 / 20 on a part | unchanged (on a part, shrinks with it) |
| `Ui/Prompts.lua` | screen UI (comment only) | unchanged |
New `Ui/WorldLabel.lua`: `WorldLabel.new{adornee, studsW, studsH, offset, maxDistance<=150, enabled}`; Size = UDim2.new(studs,0,studs,0).

## Scan check
`python tools/check_labels.py` (exit 1): fails on a BillboardGui with fromOffset / non-zero Offset Size, AlwaysOnTop true, MaxDistance > 150 or unlimited, or no Size. Now: 1 creation (WorldLabel), 0 problems. Run on the old code: 4 creations, 6 problems (proves it catches them).

## Sizes (computed)
Phone 874 x 402, FOV 70: px per stud = 201 / (d * tan 35) = 287 / d. Pad label 6 studs tall: 33 px at 52 studs, 17 px at 100 studs (digit height about 70% of that). Bag pad to number anchor is not recorded in m1-greybox.md (anchor Y 13.5, line clears the wall by 6.5); the label is legible to about 100 studs, a design limit of the rule. MaxDistance 150 (rule), so beyond that it is not drawn.
Known: UIStroke thickness is in pixels and does not shrink; text outline stays 2-3 px at range.

## Checks (Studio MCP, lock gui-worldlabels, released)
DevSync sync ok; WorldLabel requires, `new` gives Size {14,0},{6,0}, AlwaysOnTop false, MaxDistance 150; Pads/Base/Carry sources use WorldLabel.new, no fromOffset; 0 BillboardGuis live in edit mode. Play mode not run.

## On-screen checks owed (main session, UNVERIFIED)
1. Phone 874x402, play: stand on plot 1 bag pad; the fixed pad Power number reads over the wall (digits legible; note distance). Walk away to about 100 studs: it visibly shrinks and gets smaller than the old fixed size; gone past 150.
2. Same at tablet and desktop: number shrinks with distance, never stays the same size.
3. Cash on a base pad: readable at 10 studs, shrinks when walking off.
4. Carry: drop a boss; timer plate on it shrinks with distance and is hidden by walls (no longer on top); seconds and bar still readable at 10-15 studs.
5. Number does not clip into the 4-stud wall from the bag pad.
