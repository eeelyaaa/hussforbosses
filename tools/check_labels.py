"""World-label scan (M2-05; the manager's rule, 2026-11-25): no world-attached UI may keep its screen size with distance.

Run from anywhere:  python tools/check_labels.py      (exit 1 on any hit)

Scans src/ and studio/ for every BillboardGui (Instance.new, "BillboardGui" strings) and fails when, in the 25 lines after
its creation, the gui
  - gets a Size from UDim2.fromOffset, or a UDim2.new whose Offset parts (2nd and 4th argument) are not a literal 0
    (Offset is pixels; the Scale part of a BillboardGui Size is studs),
  - sets AlwaysOnTop = true,
  - sets MaxDistance above 150 (or math.huge / 0 = unlimited is not accepted either),
  - or never sets a Size (the default is 0, 0 pixels).
SurfaceGui is not scanned: it lives on a part and shrinks with it. Build world labels with Ui/WorldLabel.lua.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WINDOW = 25
MAX_DISTANCE = 150
CREATE = re.compile(r'Instance\.new\(\s*["\']BillboardGui["\']|ClassName\s*=\s*["\']BillboardGui["\']')
SIZE = re.compile(r'\.Size\s*=\s*(.+)')
UDIM_NEW = re.compile(r'UDim2\.new\((.*)\)')


def split_args(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{":
            depth += 1
        if ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur.strip())
            cur = ""
        else:
            cur += ch
    out.append(cur.strip())
    return out


def check_window(lines):
    """Return problems for one BillboardGui creation window (list of strings)."""
    problems = []
    sized = False
    for line in lines:
        code = line.split("--", 1)[0]
        m = SIZE.search(code)
        if m and not re.search(r"\b(label|plate|frame|bar|track|stroke)\w*\.Size", code, re.I):
            sized = True
            val = m.group(1).strip()
            if "fromOffset" in val:
                problems.append("Size uses UDim2.fromOffset (pixels): " + code.strip())
            u = UDIM_NEW.search(val)
            if u:
                a = split_args(u.group(1))
                if len(a) == 4 and (a[1] != "0" or a[3] != "0"):
                    problems.append("Size has a pixel Offset part: " + code.strip())
        if re.search(r"\.AlwaysOnTop\s*=\s*true", code):
            problems.append("AlwaysOnTop = true: " + code.strip())
        d = re.search(r"\.MaxDistance\s*=\s*([^\s]+)", code)
        if d:
            v = d.group(1)
            if v in ("math.huge", "0") or (re.fullmatch(r"[\d.]+", v) and float(v) > MAX_DISTANCE):
                problems.append(f"MaxDistance above {MAX_DISTANCE}: " + code.strip())
    if not sized:
        problems.append("no Size set (default is 0 pixels)")
    return problems


def main():
    hits, total = [], 0
    for base in ("src", "studio"):
        for p in sorted((ROOT / base).rglob("*.lua")):
            lines = p.read_text(encoding="utf-8").splitlines()
            for i, line in enumerate(lines):
                if line.split("--", 1)[0] and CREATE.search(line.split("--", 1)[0]):
                    total += 1
                    for prob in check_window(lines[i + 1 : i + 1 + WINDOW]):
                        hits.append(f"{p.relative_to(ROOT).as_posix()}:{i + 1}: {prob}")
    for h in hits:
        print("WORLD-LABEL: " + h)
    print(f"check_labels: {total} BillboardGui creations, {len(hits)} problems")
    return 1 if hits else 0


if __name__ == "__main__":
    sys.exit(main())
