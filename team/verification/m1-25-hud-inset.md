# M1-25 HUD under the Roblox top bar (gui-designer, 2026-11-25)

Fix: Power and cash plates now sit BELOW the real top bar: `y = GuiService.TopbarInset.Max.Y + 10` screen px (design px = /scale), left = 16 design px
(+ `GetSafeZoneOffsets().Min.X` when the API returns a notch, pcall-guarded). `Hud` re-lays out on `TopbarInset` change and on scale change.
`Counters` pops clamp their start point to 10 px under the bar. `Counters.build` default position now (16, 48). Files: `Ui/Hud.lua`, `Ui/Counters.lua`,
`studio/checks/HudViews.lua` (the old "x >= 108" assertion became "y0 >= TopbarInset.Max.Y + 8"; that check was NOT re-run, edit-mode viewport has no inset).

Read-back in play mode (Studio window 1235x479, TopbarInset real = y 0..58, x 208..1235). Gap = plate top (screen px) - TopbarInset.Max.Y:
| viewport | scale | Power plate | Cash plate | gap |
|---|---|---|---|---|
| real 1235x479 | 0.89 | x 14.3, h 28.6 | x 123.3 | 10.8 px |
| phone 874x402 override | 1.0 | x 16.0, h 32.0 | x 138.0 | 10.0 px |
| small 640x300 override | 0.73 | x 11.7, h 23.4 | x 101.1 | 10.1 px |
| desktop 1280x720 override (mouse) | 0.75 | x 17.6, h 35.1 | x 151.6 | 10.1 px |
Pop start clamped from design y 2 to 67.9 px (>= 58 + 10). First read after load showed inset 0..0 (core UI not yet up) and the plates then moved when it populated.
Notes: `AbsolutePosition` is 58 px higher than screen position under IgnoreGuiInset (engine quirk), so the read-back adds `GetGuiInset().Y`.
Overrides only change the HUD's viewport; the inset stays the real window's 58 px (a phone emulation's own ~36 px inset is untested). `check_skin.py`: 0 hits.
Probe LocalScript used for read-back was removed from the place; StudProofUi stays off.

## On-screen re-look (main session)
1. Desktop play: plates under the Roblox logo/menu/chat row, clear of it; bag-good-pop shot again.
2. Phone emulator (874x402 and a smaller one, and one with a notch): plates not under the bar or notch; the +N pop flies from below the bar.
3. Plates now no longer share the top row with Roblox's buttons; fight plate (y 46) vs the bar not touched here.

## M1-25b: RUN no longer on the Power plate (gui-designer, 2026-11-25)
Cause: M1-25 moved the plates under the top bar to y = bar + 10 but RUN stayed at design (12, 59), on top of them.
Fix (`Ui/Hud.lua` `place`, `Ui/FightOverlay.lua` new `FightOverlay.place`): RUN sits directly under the counter plates, same left edge
(x = plates' x, y = plates' y + counterH 32 + 4 + 8 gap), as the kit draws it (top left, below the first row). The fight plate's top is
`max(46, TopbarInset.Max.Y + 8 screen px)`; it stays centred and is pushed right only when the counter row would touch it
(re-laid out on scale, TopbarInset and counter-width change). `check_skin.py`: 0 hits.
Play-mode read-back (screen px = AbsolutePosition + GetGuiInset().Y 58; real bar = y 0..58; fight plate shown):
| viewport | RUN | fight plate | counters | Huss | result |
|---|---|---|---|---|---|
| real 1235x479 | 14,108-111,153 | 445,66-789,139 | 14,69-220,101 | 962,255-1155,448 | PASS |
| desktop 1280x720 | 18,116-136,171 | 428,67-851,157 | 18,68-270,108 | 971,445-1208,682 | PASS |
| phone 874x402 | 16,112-124,162 | 254,66-638,148 | 16,68-246,104 | 582,152-798,368 | PASS |
| small 640x300 | 12,100-91,145 | 186,67-468,127 | 12,68-180,94 | 384,109-557,282 | FAIL plate/huss (see below) |
PASS = no pairwise overlap among RUN, plate, counters, Huss and every one of RUN/plate/counters >= bar bottom + 8 (all gaps 8..10 px).
Fight plate (design y 46) did NOT clear the bar at scale 1 (46 < 58): now moved to y 66-67 screen px, 8+ px under it.
640x300 caveat: the override shrinks only the HUD's viewport, the real Studio window's 58 px desktop bar stays, so the plate (bottom 127)
reaches the Huss ring (top 109). With a phone's own ~36 px bar the plate bottom is about 105 < 109 (computed, not measured). Needs the phone
emulator on screen to confirm.
Probe LocalScript removed from the place; StudProofUi untouched.
## On-screen re-look (main session)
Fight on desktop and in the phone emulator (874x402 and 640x300): RUN under the Power/cash plates, plate under the bar, nothing touching Huss.
