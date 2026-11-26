# M1-08 HUD views (gui-designer, 2026-11-25)

Pass: Function. Files: `src/StarterPlayer/StarterPlayerScripts/Ui/` Kit, Hud, HussButton, Counters, FightOverlay, Prompts; check `studio/checks/HudViews.lua`.
Built to contract section I and style guide 6, read against `ui-kit/phone-hud-base.png` and `phone-hud-fight.png`.

## Scripted (Studio MCP, edit mode, studio lock held)
`require(game.ServerStorage.DevSync:Clone()).run("checks/HudViews.lua")` builds the HUD into StarterGui at four viewports and reads back
screen-px rectangles relative to the HUD root: **270 passed, 0 failed**.
- Viewports: phone 874x402 (scale 1.000), small phone 640x300 (0.732), desktop 1280x720 and 1920x1080 (mouse, x0.75).
- Scale rule per viewport; root covers the viewport; Huss button 120 design px (132 on the small phone, 96.7 px on screen: never under 96);
  ring outer edge at progress 0, 0.5, 1 equals 1.6x .. 1.075x the button (192 / 160 / 129 px at scale 1); band and button clear of the jump
  button rectangle (kit: 80 px at 22 px from the edges) on both phone sizes; every mode (bag, fight, start, hidden); pips 0 to 3, PERFECT in
  flash yellow, GOOD in white, clearPips empties after 0.15 s, ring grey on a miss and white on the next ring; counters 32 design px tall,
  full numbers with separators, Power plate at x >= 108 px; fight plate 385 design px wide at x 244..630, y 46..128 (kit), health bar 14 px
  tall in the tier colour, name, tier chip, band word colour, hearts (lost = pipEmpty), "150 / 250"; Run >= 44 px (79 x 45 on the small
  phone); fight plate and Run clear of the Huss button and ring; prompts place / grab / start with keyboard E (start F), gamepad X (RT), touch
  no glyph, each >= 44 px tall and clear of the button; hide / destroy leave nothing behind.
- Smallest text on screen: 14.0 px (phone), 13.2 px (small phone: the floor boost is capped at 1.3x), 15.4 and 23.1 px (desktop).
- `python tools/check_skin.py`: 0 hits, 0 files that do not lex (all of src/, 38 files). `python tools/check_guard.py`: clean.
- Not measured by script: how it looks; the real jump button and top-bar buttons; stroke thickness under the scale; motion.

## Place note
Edit-mode `require` caches per ModuleScript, and DevSync updates Source in place, so after a sync the check re-clones every ModuleScript under
`Skins`, `Shared` and `Ui` (top-level children cloned deep) before running. A first attempt that cloned each module separately duplicated child
modules in the open place; they were removed (24) and the folders re-cloned. The place now has fresh instances of the same files.
Suggest the loader does the re-clone itself (tech-lead).

## On-screen checks owed (main session, computer use)
1. Phone 874x402 in Studio's emulator, bag state: Huss button, ring (call `Hud.huss.setRing(0)`, 0.5, 1), band and three pips beside
   `phone-hud-base.png`: button position (centre 184 px from right, 142 from bottom), white ring with ink lines, yellow band, pips above.
2. Same screen: Power and cash plates top left, clear of Roblox's two top-left buttons; the plate icons are plain squares (no art yet).
3. Fight overlay (`Hud.fight.show{creatureId="z1_t1", band="hard", health=150, maxHealth=250, hearts=2}`, `Hud.huss.setMode("fight")`) beside `phone-hud-fight.png`.
4. Smallest phone (a 640x300 emulation or smaller): Huss button and its ring against Roblox's REAL jump button, the thumbstick, and the top bar;
   Power plate against the real top-bar buttons (assumed 112 px; this is the one number to confirm); Run against the thumbstick.
5. `UIStroke` thickness under the UIScale: ring lines, button outline and text outline should scale with the UI (assumed; if they stay at
   design px the ring and outline look thin at scale 1.65). M1-15 measures it properly.
6. HUSS! label at the small phone (text sized by the floor); GOOD / PERFECT pop above the pips (`landed("perfect")`); pip pops; miss shake.
7. Prompts: `Hud.prompts.show("place","touch")` etc. at the bottom centre, not under the avatar's hands or over the Huss ring.
8. Desktop 1920x1080: Huss button size 120 x 1.65 on screen.
