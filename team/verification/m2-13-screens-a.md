# M2-13 plain screens A (gui-designer, sonnet, 2026-11-25)
Pass: Function (plain, not the kit polish). Files: `Ui/Hud.lua` (modal frame, tile row, shield plate, text box), `Counters.lua` (`short`, B16), `Toasts.lua`, `BossPanel.lua`, `BagPanel.lua`, `Offline.lua`, `Rebirth.lua`, `Settings.lua`; text in `Skins/brickbrawl|stub/Names.lua` `ui` (same keys, stub values = key names); check `studio/checks/ScreensA.lua`. TEAM CALLs M2-13-1 to -8 in `decisions.md`.

## How they are driven
Each module listens to its contract remote (`Bag.State/Result`, `Boss.Result`, `Base.State/Crate`, `Offline.Summary/Result`, `Profile.Changed/Notice/Settings`, `Rebirth.Result`, `Shield.State`) and exposes the same handler (`onState`, `onResult`, `onProfile`, `show`...). The check calls those with contract-shaped tables (the local fake, no remote, no hook). Sends only: `Boss.Upgrade {uid}`, `Base.PickUp {spotIndex}`, `Bag.BuyStrength/BuySpeed {}`, `Bag.AutoToggle/PerfectToggle {on}`, `Shop.Buy {key}` (BUY rows), `Offline.Collect {}`, `Rebirth.Request {confirmed=true}` (only from the confirm's second REBIRTH), `Profile.Settings {music,effects}`. No price or amount is ever sent.
Entry: tile row under the counters (REBIRTH, SETTINGS, BAG only on the own bag pad; hidden in a fight), keys N / M, D-pad right / left, B closes. `BossPanel.open(info)` and `BagPanel.open()` are the seams for M2-12's Interact.

## Scripted (Studio MCP, edit mode, studio lock held): `ScreensA` 1929 passed, 0 failed
Viewports phone 874x402, small phone 640x300, tablet 1024x768, desktop 1280x720 and 1920x1080 (scale rule from Hud). Read back in screen px: every panel inside the screen; every label fits its box (wrapped ones too) and sits inside its panel; smallest text 13.2 px (small phone; boost cap 1.3x, the M1 limit); every button >= 43.5 px tall and wide on the touch viewports; header and X follow the 44 px rule. Content: boss title, Earns now $1.50/s and After $1.75/s (L3 to L4), price $51 (brief curve), upgrade disabled at cash 10 and enabled at 1240, Boss.Result level 4 and cost $66 shown, panel closes when its boss leaves; bag: 3 rows without Auto Punch (no Perfect row), 4 for owners, caps show MAX LEVEL, strength x1.35 / x1.82, ring 1.05 s / 0.98 s from Config; away: "Away for 1 h 12 min.", $21,600, COLLECT, no X, Offline.Result closes; rebirth: button disabled at 312 and enabled at 10.4M, "POWER 10.4M / 10M", 2 spin tickets, 2 bought bosses, 2 Shield Breaker charges, $5,000 bought cash, Bag Power x2, Boss income x1.5, +1 boss spot (11 spots), confirm stacks over it with the brief's text and the same numbers, CANCEL / REBIRTH; settings 80% / 100%; toasts max 3 and clear of the Huss button, ring, counters, tile row, prompts, shield plate; shield plate grey "0:00" ready, cyan countdown up; numbers 0, 999, 1,240, 9,999, 10K, 48.2K, 999.9K, 1M, 10.4M, 9.9M (from 9,999,999), 1.3B, 650M, 1T. `check_skin.py` 0 hits; `check_guard.py` clean.
Not run: play mode (no server side for these screens yet; real remotes untested), a click on any button (Activated cannot be fired from a script), drag of a slider.

## On-screen checks owed (main session; gate row O3 and the rest) UNVERIFIED until looked at
Set attribute `ScreensAShow` on Workspace (boss, bag, bag2, away, rebirth, confirm, settings, toasts, shield) and `ScreensAVp` (phone, small, tablet, desktop), run `checks/ScreensA.lua`; it leaves that screen in StarterGui. Beside `ui-kit/phone-*.png`:
1. `confirm` at phone and small: the wording is the brief's with the player's numbers (2 spin tickets, 2 bought bosses, 2 charges, $5,000, x2, x1.5, 11 spots); text readable, not clipped (it scrolls if long); CANCEL and orange REBIRTH.
2. `rebirth`: three columns readable at small phone (14 px text, scrolls); bar "POWER 10.4M / 10M".
3. `bag` / `bag2`: rows, toggle look, the gold BUY on a not-owned pass; `boss`, `away`, `settings`.
4. Tile row under the counters at 640x300 against Roblox's real top bar, thumbstick and Run (hidden in fight); shield plate top right against the menu button.
5. `toasts` top centre: not over the counters or the Huss button.
6. In play: a drag on a slider, the N / M keys, B on a gamepad, taps on every button.

## Open items for other tasks
- M2-12: call `BossPanel.open({uid, creatureId, level, income, spot})` and `BagPanel.open()` from Interact; do not add a second toast for Result failures.
- M2-10 / M2-14: `Bag.State` and `Offline.Summary` are sent once on join; the client modules connect shortly after it starts and could miss them. Resend `Bag.State` when the player steps on the pad, and send `Offline.Summary` a moment after the client is up (or on a client "ready").
- M2-14: fill `Config.Rebirth.REQUIRED`, `BAG_MULT_STEP`, `INCOME_STEP`, `Config.Base.SPOTS_BASE` (screens read them first). Exact kept-bought count if wanted.
- M2-20: Shop tile slot is order 1 (`Hud.tile`); the Perfect Auto Punch row's price and polish.
- HudViews (M1): its expectation of separators on 10,000+ is now shortened numbers.

## Follow-up 2026-11-26 (orchestrator, from a real Play session)
- **Rebirth.onBaseState error ("index boolean with 'bought'")**: empty spots arrive as `false`; guarded in `Rebirth` and in `BossPanel.onBaseState` (same bug). N6: the kept-bought count takes only a boss whose uid carries the player's own id (`<userId>-<n>`; a bought boss is granted to its buyer), so a bought boss stolen from someone else is not counted and one of the player's own stolen and stolen back is. Spots base read as `Config.Base.SPOTS_BASE` or `SPOTS_AT_START` or 10.
- **Two tall empty white panels under the plates**: the tile row's tiles (REBIRTH, SETTINGS). Their height was `Kit.minDesign(44)` taken once at build time, and at spawn the camera viewport is unsettled (tiny scale), which made it huge. Now `Hud.tile` re-sizes on every scale change and caps at 64 design px. Nothing else draws unless open (panels are built on open and destroyed on close).
- **Offline resend**: `Offline.show` returns at once while its panel is open.
- **Toasts vs steal / shield-broken alert**: `Toasts.place()` puts the holder under `StealAlert.instance()` while an alert is on (and again on its change), under the fight plate in a fight.
- ScreensA rerun (studio lock, edit mode): **1944 passed, 0 failed**, now including: tiles stay small after a late scale change, boolean spots do not error, only own bought bosses count, a resent summary leaves the panel alone, toast clear of the steal alert at phone, small phone and desktop. Skin scan 0 hits.
- Not seen in play: the real spawn (the fix is by cause and by the late-scale read-back). Note for M2-17: StealAlert also toasts Result failures, and Ui/Toasts already toasts Shield.Result failures, so a refused shield action may show twice.
