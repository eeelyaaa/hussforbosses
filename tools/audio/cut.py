"""cut.py IN OUT [--start S] [--end E] [--fade-in MS] [--fade-out MS]   trims and fades with ffmpeg; keeps the rate and channels; 16-bit wav out."""
import argparse, subprocess
ap = argparse.ArgumentParser(); ap.add_argument("inp"); ap.add_argument("out")
ap.add_argument("--start", type=float, default=0.0); ap.add_argument("--end", type=float, default=None)
ap.add_argument("--fade-in", type=float, default=0.0); ap.add_argument("--fade-out", type=float, default=0.0)
a = ap.parse_args()
dur = (a.end - a.start) if a.end is not None else None
f = []
if a.fade_in: f.append("afade=t=in:st=0:d=%.4f" % (a.fade_in / 1000))
if a.fade_out and dur: f.append("afade=t=out:st=%.4f:d=%.4f" % (dur - a.fade_out / 1000, a.fade_out / 1000))
cmd = ["ffmpeg", "-y", "-v", "error", "-ss", str(a.start), "-i", a.inp] + (["-t", str(dur)] if dur else []) + (["-af", ",".join(f)] if f else []) + ["-c:a", "pcm_s16le", a.out]
subprocess.check_call(cmd); print("wrote", a.out)
