"""Copy the modeler's *.groups.json into studio/data/ so the Studio setup scripts can read them over DevSync at run time.
The sync server serves only .lua files under studio/, so each copy is <id>.groups.lua: the place-guard line, then the JSON
inside a block comment (a valid studio/ script, so tools/check_guard.py passes). Run after the modeler changes a pivot:
    python tools/sync_group_data.py"""
from pathlib import Path

GUARD = 'if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end'
root = Path(__file__).resolve().parents[1]
dst = root / "studio" / "data"
dst.mkdir(exist_ok=True)
for old in dst.glob("*"):
    old.unlink()
for f in (root / "assets-src" / "models").glob("*.groups.json"):
    out = dst / (f.stem + ".lua")
    out.write_text(GUARD + "\n--[==[\n" + f.read_text(encoding="utf-8") + "\n]==]\n", encoding="utf-8")
    print("copied", f.name, "->", out.name)
