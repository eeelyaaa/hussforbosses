"""measure.py FILE...  length, format, lead silence (to -30 dB under peak and to -50 dBFS), peak time and level,
tail (level of the last 10 ms, flag if not faded), RMS, integrated LUFS. Run: .venv-audio/Scripts/python.exe tools/audio/measure.py FILE"""
import sys, os
import numpy as np
sys.path.insert(0, os.path.dirname(__file__))
from _wav import probe, load, db, rms_env, lufs

def measure(path):
    info = probe(path); x, r = load(path)
    peak = float(np.max(np.abs(x))); pk_i = int(np.argmax(np.abs(x)))
    t, e = rms_env(x, r, 5, 1)
    emax = float(e.max())
    lead30 = float(t[np.argmax(e >= emax - 30)]); lead50 = float(t[np.argmax(e >= -50)]) if (e >= -50).any() else None
    tail = float(db(np.max(np.abs(x[-int(r * 0.010):])))); tail_cut = tail > -40
    return {"file": os.path.basename(path), "bytes": info["bytes"], "codec": info["codec"], "rate": info["rate"], "channels": info["channels"],
            "length_s": round(len(x) / r, 4), "peak_dbfs": round(float(db(peak)), 2), "peak_at_s": round(pk_i / r, 4),
            "rms_dbfs": round(float(10 * np.log10(np.mean(x.astype(np.float64) ** 2) + 1e-12)), 2),
            "lufs_integrated": lufs(path), "lead_to_-30dB_under_loudest_5ms_s": round(lead30, 4), "lead_to_-50dBFS_s": None if lead50 is None else round(lead50, 4),
            "last_10ms_peak_dbfs": round(tail, 1), "tail_cut_hard": bool(tail_cut)}

if __name__ == "__main__":
    for p in sys.argv[1:]:
        m = measure(p)
        print(m["file"]); [print("  %-36s %s" % (k, v)) for k, v in m.items() if k != "file"]
