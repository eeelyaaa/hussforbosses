# M1: the Huss button, ring, pips, counters, fight overlay, prompts, and the studded button proof

Build to `m1-contract.md` sections F (`Tokens`, `Names`), I. Quality pass: **Function only**; the same screens get
Friction, Feel and Look in M3 to M5 (so M1 builds them right, to the kit, but does not polish beyond it).

## The brief
The style guide's "The Huss button, timing ring and pips" (120 px round Huss red button with studs, 4 px ink
outline, 6 px lip, glove icon and "HUSS!"; white ring 6 px thick starting at 1.6 x the button and closing onto it;
flash-yellow hit band 10 px thick at 1.0 to 1.15 x; GOOD in white and PERFECT in flash yellow, 20 px caps; pips
three 18 px squares 4 px apart, empty `#3A4250`, filled Huss red), counter plates (32 px tall, studded, job
colour), the fight overlay (top plate, health bar 14 px in the boss's tier colour, three hearts, band word, Run),
`UIScale = min(w/874, h/402)` (x0.75 on mouse and keyboard), touch targets at least 44 px, the Huss button never
under 96 px, clear of the jump button and the top bar, **proof 4: the Huss button (stud tile clipped to the
circle) and one panel with the tiled overlay at three UIScales**.

## Tasks
- **M1-02 gui-designer (sonnet), wave 1:** `Tokens.lua` (every colour of style guide section 3 for jobs M1 uses,
  plus the full table so later tasks add nothing; `Tokens.ui`, `Tokens.stud` per contract F), `Names.lua` (the M1
  keys), `Icons.lua` (keys declared for the glove, Power, cash, hearts, Run, the 64-icon names are M3; id 0 means
  the Kit draws a plain stand-in). **Icons are M3 uploads (plan, "UI art and icons")**: at M1 the Huss button shows
  "HUSS!" with no glove image (TEAM CALL; the plan's M1 list has no icon upload).
- **M1-08 gui-designer (sonnet), wave 2:** `Ui/Kit`, `Ui/HussButton`, `Ui/Counters`, `Ui/FightOverlay`,
  `Ui/Prompts`, `Ui/Hud` (assembles the HUD inside one full-screen container and the `UIScale`; Power plate and cash
  plate top left; the Huss button bottom right beside the jump button, clear of `GuiService.TopbarInset`, the
  thumbstick and the jump button), built from `ui-kit/phone-hud-base.png` and the style guide. Reads the
  `Tokens` only; no literal hex. The ring is drawn in code from `setRing(progress)`: **TEAM CALL (gui-designer):
  how the ring is drawn (rotated `UIStroke` frame vs `ImageLabel` circle), `ringLandScale`**, logged.
- **M1-15 gui-designer (sonnet), wave 3:** the stud proof in the UI (needs the uploaded UI tile id): the Huss
  button and one panel at `UIScale` 0.75, 1.0 and 1.65: tile in Offset follows the scale (clamped 12 to 32 px),
  clips under a 4 px `UICorner` and to the round button, `UIStroke` thickness at each scale, Montserrat Black's
  weight name (`Enum.FontWeight.Heavy` or what Studio accepts), the dark L under text not too busy at 16 px.
  Evidence `team/verification/m1-ui-stud.md`; screenshots are the main session's (on-screen list).

## Acceptance criteria
1. Every size and colour in the list above is read from `Tokens`; the repo scan (`tools/check_skin.py`) finds no
   hex or display name in `Ui/`.
2. The HUD builds with no errors at 874 x 402 (phone), 1280 x 720 and 1920 x 1080; the Huss button is 120 design px
   (never under 96 px on screen) and does not overlap the jump button, the top bar or the thumbstick on the smallest
   phone emulation. [on-screen, main session]
3. `setRing(progress)` draws the ring from 1.6x to the landing scale; `landed`, `missed`, `pips` behave as in the
   style guide; the pips fill on the three beats (driven by BurstClock events) and clear 0.15 s after the third.
4. The fight overlay shows boss name, tier chip, health bar, three hearts, the band word in its difficulty colour,
   and Run; nothing covers the Huss button.
5. The Place and Grab prompts show the glyph for `Input.kind()` (keyboard E, gamepad X, touch: the on-screen
   prompt button).
6. Stud proof items (M1-15): `TileSize` in Offset follows `UIScale`; tiled images clip under a 4 px corner and the
   circle; tile never under 12 or over 32 px on screen; `UIStroke` thickness at each scale; the font weight.

## Risks
Round clipping of a tiled image (circular clip via `UICorner` radius 0.5 on a container with `ClipsDescendants`
is the likely route; the gui-designer measures and reports); the tile at 16 px looking busy; a ring that
overdraws the jump button.

## Suggestions from the vault (optional)
None added.

## Not asked for (do not build)
The shop, rebirth, settings tiles, the zone strip, the shield plate and lock button, the spin ticket plate, the
boss panel, the bag panel, toasts, banners, offers, the settings screen (all M2/M3); the 64 icons; the glove icon;
transitions, panel open/close tweens, hover polish (M4); any Look pass; number shortening; boss name tags in the
world; sound on UI.
