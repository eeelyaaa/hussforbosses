"""probe.py FILE [--parts N] [--drop DB]  the envelope probe: finds the loud parts of a file (the huss bursts).
5 ms RMS windows, 1 ms hop. A loud part = a peak of the envelope within `--floor` dB (default 14) of the file's loudest,
at least 100 ms from the next. Its onset = the last time before the peak the envelope was `--drop` dB (default 20) under
that part's own peak (the pack's own method, so numbers compare). Also prints onsets at 10 and 30 dB under.
Compares with the brief's BEAT (0, 0.213, 0.401) when --beat is given, after removing the file's own lead (--lead)."""
import sys, os, argparse
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
from _wav import load, rms_env

def loud_parts(path, floor=14.0, min_gap=0.100, drop=20.0):
    x, r = load(path); t, e = rms_env(x, r, 5, 1)
    emax = e.max(); parts = []
    cand = [i for i in range(1, len(e) - 1) if e[i] >= e[i - 1] and e[i] > e[i + 1] and e[i] >= emax - floor]
    for i in cand:  # keep the highest of peaks closer than min_gap
        if parts and t[i] - t[parts[-1]] < min_gap:
            if e[i] > e[parts[-1]]: parts[-1] = i
        else: parts.append(i)
    out = []
    for k, i in enumerate(parts):
        lo = parts[k - 1] if k else 0
        # search back no further than the valley between this and the previous part
        seg = slice(lo, i + 1); valley = lo + int(np.argmin(e[seg])) if k else 0
        def onset(d):
            idx = np.where(e[valley:i + 1] < e[i] - d)[0]
            return float(t[valley + idx[-1] + 1]) if len(idx) else float(t[valley])
        out.append({"peak_at": round(float(t[i]), 3), "peak_db": round(float(e[i]), 1), "onset_10": round(onset(10), 3), "onset_20": round(onset(drop), 3), "onset_30": round(onset(30), 3)})
    return out, float(len(x) / r)

if __name__ == "__main__":
    ap = argparse.ArgumentParser(); ap.add_argument("file"); ap.add_argument("--floor", type=float, default=14.0)
    ap.add_argument("--drop", type=float, default=20.0); ap.add_argument("--beat", default="0,0.213,0.401")
    ap.add_argument("--lead", type=float, default=0.010, help="the file's own lead (contract F_LEAD)")
    a = ap.parse_args(); parts, ln = loud_parts(a.file, a.floor, drop=a.drop)
    print("%s  length %.3f s, %d loud parts" % (os.path.basename(a.file), ln, len(parts)))
    beats = [float(b) for b in a.beat.split(",")]
    for n, p in enumerate(parts):
        line = "  part %d: peak %.3f s (%.1f dB)  onset -10dB %.3f  -20dB %.3f  -30dB %.3f" % (n + 1, p["peak_at"], p["peak_db"], p["onset_10"], p["onset_20"], p["onset_30"])
        if n < len(beats):
            line += "   | brief beat %.3f + lead %.3f = %.3f ; onset20 - that = %+.0f ms" % (beats[n], a.lead, beats[n] + a.lead, (p["onset_20"] - beats[n] - a.lead) * 1000)
        print(line)
    if len(parts) > 1: print("  gaps (onset_20): " + ", ".join("%.3f" % (parts[i + 1]["onset_20"] - parts[i]["onset_20"]) for i in range(len(parts) - 1)))
