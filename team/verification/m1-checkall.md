# M1 CheckAll summary (M1-16 final run, 2026-11-25; M1-22 re-runs it)

> Superseded 2026-11-25: this is the M1-16 run (2 FAIL, both fixed by M1-24). The latest full CheckAll is in `m1-26-fight-camera.md` (M1-26b, all rows 0 FAIL); the tally is `m1-exit-checks.md`.

Printed by `studio/checks/CheckAll.lua` in `summary` mode, verbatim:
```
CheckAll: | Check | Phase | PASS | FAIL | Failed |
CheckAll: |---|---|---|---|---|
CheckAll: | CheckSync | edit | 8 | 0 | - |
CheckAll: | CheckSkin | scan | 1 | 0 | - |
CheckAll: | CheckSkin | studio A-E | 11 | 2 | A2 brickbrawl skin has every M1 key; B brickbrawl and stub have the same key shape |
CheckAll: | CoreLoop | a | 22 | 0 | - |
CheckAll: | CoreLoop | b | 36 | 0 | - |
CheckAll: | Refusals | live | 6 | 0 | - |
CheckAll: | Refusals | a | 19 | 0 | - |
CheckAll: | Refusals | b | 32 | 0 | - |
CheckAll: | BurstValues | a | 31 | 0 | - |
CheckAll: | BurstValues | b | 26 | 0 | - |
CheckAll: | NoDelay | a | 8 | 0 | - |
CheckAll: | CoreLoop | a stub | 22 | 0 | - |
CheckAll: | CoreLoop | b stub | 36 | 0 | - |
CheckAll: FAIL, 13 rows, 258 PASS, 2 FAIL
```
- The 2 FAILs: `Skins/brickbrawl` misses `Models.bags.1`, `Models.hazards.1`, `Effects.stars` and `Effects.cubeBurst`.
  These are the skin-key owners' to fill.
- The scan row is `python tools/check_skin.py`: 0 hits.
- How to run it, and what it saw: `m1-16-gate.md`.
