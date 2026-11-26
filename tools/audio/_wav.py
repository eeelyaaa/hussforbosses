"""Shared helpers for tools/audio: decode any audio file to mono float32 through ffmpeg (no extra packages beyond numpy)."""
import subprocess, json, sys
import numpy as np

def probe(path):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "stream=codec_name,sample_rate,channels,duration", "-show_entries", "format=size,duration", "-of", "json", path])
    j = json.loads(out)
    s = j["streams"][0]
    return {"codec": s["codec_name"], "rate": int(s["sample_rate"]), "channels": int(s["channels"]),
            "duration": float(s.get("duration") or j["format"]["duration"]), "bytes": int(j["format"]["size"])}

def load(path, rate=44100):
    """Returns (mono float32 array, rate). Mono is the plain channel mean (no ffmpeg downmix gain)."""
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", path, "-af", "pan=mono|c0=0.5*c0+0.5*c1" if probe(path)["channels"] == 2 else "anull", "-f", "f32le", "-ac", "1", "-ar", str(rate), "-"])
    return np.frombuffer(raw, dtype="<f4").copy(), rate

def db(x):
    return 20.0 * np.log10(np.maximum(x, 1e-9))

def rms_env(x, rate, win_ms=5.0, hop_ms=1.0):
    """RMS in dBFS over win_ms windows every hop_ms. Returns (times_s of window starts, dB)."""
    w = max(1, int(rate * win_ms / 1000)); h = max(1, int(rate * hop_ms / 1000))
    c = np.concatenate([[0.0], np.cumsum(x.astype(np.float64) ** 2)])
    starts = np.arange(0, max(1, len(x) - w + 1), h)
    ms = (c[starts + w] - c[starts]) / w
    return starts / rate, 10.0 * np.log10(np.maximum(ms, 1e-12))

def lufs(path):
    p = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af", "ebur128=peak=true", "-f", "null", "-"], capture_output=True, text=True)
    last = None
    for line in p.stderr.splitlines():
        if "I:" in line and "LUFS" in line: last = line
    txt = p.stderr
    i = txt.rfind("Integrated loudness:")
    try:
        val = float(txt[i:].split("I:")[1].split("LUFS")[0])
        return val
    except Exception:
        return None
