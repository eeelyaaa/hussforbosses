"""level.py IN OUT [--peak DBFS] [--lufs LUFS]  gain-only levelling (no compression, no limiter): --peak sets the sample peak (default -1.0);
--lufs sets integrated loudness instead (peak is then checked and the file refused if it would exceed -0.5 dBFS)."""
import argparse, sys, os, subprocess
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
from _wav import load, db, lufs
ap = argparse.ArgumentParser(); ap.add_argument("inp"); ap.add_argument("out"); ap.add_argument("--peak", type=float, default=None); ap.add_argument("--lufs", type=float, default=None)
a = ap.parse_args(); x, r = load(a.inp); pk = float(db(np.max(np.abs(x))))
if a.lufs is not None: gain = a.lufs - lufs(a.inp)
else: gain = (a.peak if a.peak is not None else -1.0) - pk
if pk + gain > -0.5: sys.exit("refused: peak would be %.1f dBFS" % (pk + gain))
subprocess.check_call(["ffmpeg", "-y", "-v", "error", "-i", a.inp, "-af", "volume=%.3fdB" % gain, "-c:a", "pcm_s16le", a.out]); print("gain %+.2f dB -> %s" % (gain, a.out))
