# M1-01b fixes (tech-lead), 2026-11-25

1. `Skin.assetUrl(id)` added to `Shared/Skin.lua`; `tools/check_skin.py` exempts only the `function Skin.assetUrl ... end` lines of that file. `Controllers/Avatar.lua` now uses it (SCHEME split string removed). BurstClock.lua untouched (owned by M1-07).
2. DevSync swaps every synced ModuleScript for a fresh instance (name, attributes, tags, children carried) whenever a sync changed anything. Rule documented in `team/CLAUDE.md`.

Checks
- `python tools/check_skin.py`: 0 hits, 0 lex errors. `python tools/check_guard.py`: 10 scripts, 0 without the guard.
- Studio (edit mode, studio lock): loader refreshed from /loader. Probe module `Shared/ZzCacheProbe` v=1, require -> 1. Changed file on disk to v=2, synced (changed 1, swapped 52): require -> 2. DevSync-attribute instances 61 before and after; no duplicate siblings in Shared. Probe removed and resynced (gone).
- `Skin.assetUrl(70915382854444)` -> `rbxassetid://70915382854444`; 0 and nil -> nil.

## M1-01c (tech-lead), 2026-11-25: hook docs and Config values
- FrameCap text now says Heartbeat (contract L, `TestHooks.HOOKS`, `team/test-hooks.md`); AutoTap docs list `busy`, `early`, `lag` and the boss-ring Huss press once a second (M1-07e), identical in the three places (HOOKS and test-hooks.md word for word).
- `Config.Hazards.SMALL_PUSH = 2`, `PUSH_COOLDOWN_S = 1`; `Config.Carry.WALK_IN_GRAB = 3`, `SPEED_WINDOW = 0.5`, `SPEED_SLACK = 1.5`, `SPEED_PAD = 2.5`. `Systems/Hazards.lua` and `Systems/Carry.lua` read them (local constants removed; same numbers, each file written once).
- Checks: `check_skin.py` 0 hits, 0 lex errors; `check_guard.py` 18 scripts, 0 without the guard. Studio (studio lock, released): DevSync returned changed 0, total 64 (a sync by another agent had already carried the files, so the loaded modules were read to confirm); play-mode server start (run_server): Config values read 2 1 3 0.5 1.5 2.5, both Systems modules required, `[HFB] server up`, no errors.
