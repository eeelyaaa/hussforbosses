"""Place-guard check: every studio/ script must start with the guard line.

Run from anywhere:  python tools/check_guard.py      (exit 1 if a script is missing it)

The guard line (copy it as the first line of every new studio/ script):
    if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end

The only exempt script is studio/SetPlaceMarker.lua, which checks the owner and place id itself.
"""
import sys
from pathlib import Path

GUARD = 'if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end'
EXEMPT = {"SetPlaceMarker.lua"}
STUDIO = Path(__file__).resolve().parent.parent / "studio"

bad = []
count = 0
for p in sorted(STUDIO.rglob("*.lua")):
    count += 1
    rel = p.relative_to(STUDIO).as_posix()
    if rel in EXEMPT:
        continue
    first = p.read_text(encoding="utf-8").splitlines()[:1]
    if not first or first[0].strip() != GUARD:
        bad.append(rel)

for rel in bad:
    print(f"MISSING GUARD: studio/{rel}")
print(f"check_guard: {count} studio scripts, {len(bad)} without the guard")
sys.exit(1 if bad else 0)
