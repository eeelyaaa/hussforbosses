#!/usr/bin/env python3
"""M2-28: the M2 gate's repo scans (no Studio). Runs check_guard, check_skin, check_labels, check_streaming and prints
one `GATE row scan:<name>|<pass>|<fail>|<detail>|<secs>` line each (the same row format the Studio runner prints), then
a total. Exit 0 only when every scan exits 0. Run from the game repo root:  python tools/gate_scans.py
Paste the GATE row lines into Workspace.HFB_GateRows (';;'-separated) for the Gate summary (studio/checks/Gate.lua)."""
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCANS = ["check_guard", "check_skin", "check_labels", "check_streaming"]


def main() -> int:
    bad = 0
    for name in SCANS:
        t0 = time.time()
        r = subprocess.run([sys.executable, str(ROOT / "tools" / (name + ".py"))], cwd=ROOT, capture_output=True, text=True)
        out = (r.stdout + r.stderr).strip().splitlines()
        last = out[-1] if out else ""
        ok = r.returncode == 0
        bad += 0 if ok else 1
        for line in out:
            print("  " + line)
        print("GATE row scan:%s|%d|%d|%s|%.1f" % (name, 1 if ok else 0, 0 if ok else 1, last.replace("|", "/")[:200], time.time() - t0))
    print("GATE scans: %s (%d of %d scans clean)" % ("PASS" if bad == 0 else "FAIL", len(SCANS) - bad, len(SCANS)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
