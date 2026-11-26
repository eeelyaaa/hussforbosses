# M0 tool check (2026-11-25)

- Blender: `D:\Games\steamapps\common\Blender\blender.exe` runs headless. `-b --version` prints `Blender 5.3.0 (hash 02f0899d78e3 built 2026-11-10 01:33:43)`, exit 0.
- earshot: `.venv-audio/Scripts/earshot.exe` answers. `--version` prints `earshot 1.0.0`. `--help` lists the commands (make, sounds, recipe, pack, describe, match, rank, find, compare, realness, timeline, sheet, critique, measure), exit 0.
- Lock status (`scripts/lock.sh status`): computer free, studio free.
- Python: `python --version` prints `Python 3.9.1` (the bare `python` on PATH, not the earshot venv).
- ffmpeg: `ffmpeg version 9.1-full_build-www.gyan.dev` (Copyright 2000-2026 the FFmpeg developers).
- Note: the Roblox_Studio MCP reported CONNECTION_CLOSED when this session started. Not tested here; Studio was not used.
