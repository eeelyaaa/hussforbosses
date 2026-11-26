# M1-24: the pad Power number and the missing skin keys (scripter, 2026-11-25)

## What changed (game repo `projects/huss-for-bosses/`)
- New `src/StarterPlayer/StarterPlayerScripts/Controllers/Pads.lua`: a screen-pixel BillboardGui "PowerNumber" on each
  `HFB_BossPad` model's `NumberAnchor` (AlwaysOnTop, MaxDistance 400, 33 px Montserrat Heavy via `Kit.Font`, ink outline).
  Text = boss Power (commas), colour = `Skin.Tokens.colors.band[Config.Fight.band(boss / own Power).id]`. Updates on
  `Zones.Pads`, `Profile.Changed` (own Power; starts at 1), `Zones.PadBeaten` (hidden, back after `backIn`).
- `Main.client.lua`: Pads required and started in the M1-14 controller loop (pcall); `TestClient.setProbes` gets it as 4th arg.
- `TestClient.lua`: `pads` report (text, colour hex, band, shown, boss, mine) with ReportBeats on, when changed.
- `Skins/brickbrawl/Models.lua`: `bags = { "Bag" }`, `hazards = { "Hazard_Log" }` (names `BuildSlice.lua` builds).
- `Skins/brickbrawl/Effects.lua`: `stars = {}`, `cubeBurst = {}`.
- `team/decisions.md`: M1-24a, M1-24b.

## Checks (Studio MCP, lock `scripter-m1-24`, released)
- DevSync 65 files; `CheckAll prepare`: CheckSkin **A2 PASS, B PASS** (13 passed, 0 failed), CheckSync 8/0, Refusals live 6/0.
  Then `arm`, `disarm`, `cleanup` run: HFB_ForceSkin nil, HFB_SkinCheck gone, 0 HFB_ attributes.
- Play mode (ReportBeats on, SetPower hook), `pads` reports against Chomp Frog (boss 25):
  | SetPower | band | text | colour |
  |---|---|---|---|
  | 1 (start) | impossible | 25 | ff4b4b |
  | 10 | brutal (r 2.5) | 25 | ff4b4b |
  | 25 | fair (r 1.0) | 25 | 6be04a |
  | 60 | easy (r 0.42) | 25 | 6be04a |
  All `shown: true`. The hide/return on `Zones.PadBeaten` was not run here (code path only; the gate's M1-16 step 4 covers the server side).
- `python tools/check_skin.py`: 0 hits, 0 files that do not lex. `python tools/check_guard.py`: 25 scripts, 0 without the guard.

## Not done / owed
- ON-SCREEN, UNVERIFIED: the number over the 4-stud wall from the bag pad at phone size (874 x 402). Main session to look.
- Skull beside "Near impossible" (style guide): no skull icon key in Skin.Icons; not drawn. Needs an icon from the icon owner.
- No server changes needed.
