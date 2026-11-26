# M2-08 PERFECT float (gui-designer, 2026-11-25)
Pass: Function. Files: `Ui/HussButton.lua` (`landed("perfect"|"good"|"untimed")`), `perfect*`/`untimed*` keys in `Skins/brickbrawl/Tokens.lua` and `Skins/stub/Tokens.lua`, check `studio/checks/PerfectFloat.lua` (new, mine).
Not touched: Ring/Main (M2-07 must call `HussButton.landed(grade)` with `"untimed"` for an untimed single; the view needs no other change), `FightOverlay.lua` (nothing in this task needed it).
## Behaviour
- Perfect: label "PERFECT" (Names.grades.perfect), flash yellow, 22 design px (floor-boosted like all text), starts above the pips, pops 1.35x, rises 44 px and drifts 36 px right over 0.85 s, fades over the last 45%, removed. One label per Perfect, so two close together both float.
- Good: unchanged small GOOD pop (white, 0.5 s). Untimed: no word; star 0.75x, button squash 1.08x.
## Scripted (Studio MCP, edit mode, lock held)
`checks/PerfectFloat.lua` at 874x402, 640x300, 1280x720, 1920x1080: 66 passed, 0 failed (final run). First run 65/1: at 640x300 the float ended over the fight plate's right edge (plate to x 461, text from 443); fixed by the 26 px drift.
Phone 874x402 readings (screen px): button x 634..746 y 204..316; PERFECT starts x 652..728 y 134..156, mid y 99..121, ends y 90..112 (plate x 244..630 y 46..128: clear). Small phone: starts y 99..115, ends y 67..83, clear of the plate with the drift. Desktop 1280x720: y 425..449 start, 377 top at the end.
`check_skin.py`: 0 hits. `check_guard.py`: clean. CheckSkin B (key shape) passed on the sync after my edit; one earlier FAIL in the log was other tasks' clips/creatures keys, not mine.
## On-screen checks owed (main session)
1. Phone 874x402, fight, `Hud.huss.landed("perfect")`: PERFECT rises above the button in yellow with ink outline, readable, not under the Roblox jump button or the fight plate; three in a row at the burst pace (about 0.6 s apart) overlap without mess.
2. 640x300 emulation: the float stays clear of the plate's right edge; desktop 1920x1080 size.
3. `landed("good")` small GOOD pop; `landed("untimed")` small pop, no word, button not left squashed.
4. Not measured: the look and timing feel of the float (the Feel pass).

## Addendum: setSpent (M2-07's request)
`HussButton.setSpent(bool)`: dims the face (fill x `Tokens.ui.spentFill` 0.6) and the label (`spentTextAlpha` 0.35) while the ring is spent after an untimed tap; taps still fire; `setSpent(false)` restores. Keys in both skins.
`checks/PerfectFloat.lua` now also covers setSpent at all four viewports: 74 passed, 0 failed. The Perfect drift was raised from 26 to 36 design px (`perfectDriftPx`): the wider text measured on a later run overlapped the fight plate by 4 px at 640x300 with 26. `HFB_ForceSkin` was nil after the check. Studio lock released.
On-screen: the dimmed button reads as spent but still tappable-looking, and restores when the next ring opens.
