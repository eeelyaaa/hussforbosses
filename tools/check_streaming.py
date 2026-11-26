"""Streaming scan (M2-34): flags one-shot lookups of streamed Workspace content in client code.

Run from anywhere:  python tools/check_streaming.py      (exit 1 on any hit)

With StreamingEnabled, anything under Workspace can be missing on the client at join, or stream out and back. Scans src/StarterPlayer and
src/ReplicatedFirst (client code) for
  - workspace.X.Y / workspace:FindFirstChild("X") / workspace:WaitForChild("X") chains reaching into a named Workspace child, other than the
    engine members (CurrentCamera, Terrain, Raycast, GetServerTimeNow, GetAttribute...), and
  - game.Workspace.X.Y.
Allowed: a line carrying the marker `-- stream-ok: <why>` (it waits, polls, or reacts), or any line inside a function the file polls each frame
(mark that with the same comment). A lookup that is repeated until it succeeds (the Base/Ring/Fight pattern: re-read every refresh, or CollectionService
tags with GetInstanceAddedSignal) is the accepted way: mark it. Anything else is a bug waiting for a far-away player.
Also fails when a Boss_* model is built in studio/ without a ModelStreamingMode line.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLIENT = [ROOT / "src" / "StarterPlayer", ROOT / "src" / "ReplicatedFirst"]
ENGINE = {"CurrentCamera", "Terrain", "Raycast", "GetServerTimeNow", "GetAttribute", "GetAttributeChangedSignal", "SetAttribute", "StreamingEnabled",
          "GetPartBoundsInBox", "GetPartBoundsInRadius", "GetPartsInPart", "Spherecast", "Blockcast", "FindPartOnRay", "DescendantAdded", "ChildAdded",
          "PersistentLoaded", "Gravity", "DistributedGameTime", "IsA", "GetFullName", "Name", "Parent", "ClassName"}
DOT = re.compile(r'\b(?:game\.Workspace|workspace)\.([A-Za-z_]\w*)')
CALL = re.compile(r'\b(?:game\.Workspace|workspace):(FindFirstChild|WaitForChild|FindFirstDescendant)\(\s*["\']([^"\']+)["\']')
MARK = "stream-ok"

hits = []
for base in CLIENT:
    for p in sorted(base.rglob("*.lua")):
        lines = p.read_text(encoding="utf-8").splitlines()
        for i, line in enumerate(lines, 1):
            code = line.split("--")[0] if "stream-ok" not in line else line
            if MARK in line or line.strip().startswith("--"):
                continue
            code = line.split("--")[0]
            for m in DOT.finditer(code):
                if m.group(1) in ENGINE:
                    continue
                # workspace:Method(...) is a colon call, caught by CALL; workspace.Name is a property/child read
                hits.append((p, i, line.strip()))
                break
            else:
                if CALL.search(code):
                    hits.append((p, i, line.strip()))

bad_studio = []
for name in ("SetupBosses.lua", "BuildReviewLine.lua"):
    t = (ROOT / "studio" / name).read_text(encoding="utf-8")
    if "ModelStreamingMode" not in t:
        bad_studio.append(name)

for p, i, l in hits:
    print(f"ONE-SHOT STREAMED LOOKUP {p.relative_to(ROOT).as_posix()}:{i}: {l}")
for n in bad_studio:
    print(f"NO ModelStreamingMode: studio/{n}")
print(f"check_streaming: {len(hits)} unmarked one-shot lookups, {len(bad_studio)} boss builders without a streaming mode")
sys.exit(1 if hits or bad_studio else 0)
