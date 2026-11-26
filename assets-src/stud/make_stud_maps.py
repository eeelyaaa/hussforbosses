"""Huss for Bosses: the stud maps, made by script (M1-05). Needs numpy only (repo .venv-audio).
Run from the game repo root:  ../../.venv-audio/Scripts/python.exe assets-src/stud/make_stud_maps.py

Uses the pack's tile design (team/pack/style/make_stud_refs.py: functions overlay() and height()) unchanged, and
writes here:
  stud-color-256.png          flat #F2F2F2, 256 x 256 (4 x 4 studs; the part's Color tints it)
  stud-normal-256.png         normal map from the height map, 4 x 4 tiles. Green channel UP (OpenGL style).
  stud-normal-flipped-256.png the same with the green channel inverted (DirectX style). Upload both; the proof strip
                              shows both; the manager's yes picks one.
  stud-rough-256.png          flat 0.75 roughness (grey 191)
  stud-ui-overlay-64.png      the UI tile (transparent, baked edges)
NORMAL_STRENGTH is the one tunable: bigger = darker edges. 1.0 gives a clear step that does not saturate (4.0 did)."""
import os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
PACK = os.path.join(HERE, "..", "..", "team", "pack", "style", "make_stud_refs.py")
src = open(PACK, encoding="utf-8").read()
src = src.rsplit("\nmain()", 1)[0]          # keep the functions, skip the pack's own writes
ns = {"__file__": PACK}
exec(compile(src, PACK, "exec"), ns)
save_pack = ns["save"]
def save(name, a):
    ns["HERE"] = HERE                       # the pack's save() writes next to HERE
    save_pack(name, a)

NORMAL_STRENGTH = 1.0
h64 = ns["height"]() / 255.0                # 64 x 64, 1 = surface
h = np.tile(h64, (4, 4))                    # 256 x 256
# gradients with wraparound (the tile repeats); image y grows downward
dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) * 0.5
dy = (np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) * 0.5
# per pixel step is 1/64 of a stud-tile; scale to a slope
k = NORMAL_STRENGTH * 64 / 4
nx, ny_down, nz = -dx * k, -dy * k, np.ones_like(h)
# OpenGL: +Y (green) points up in the image = toward smaller row index, so green = -(d/drow) of height slope sign
ny = ny_down * -1.0
n = np.dstack([nx, ny, nz]); n /= np.linalg.norm(n, axis=2, keepdims=True)
rgb = (n * 0.5 + 0.5) * 255
save("stud-normal-256.png", rgb)
flip = rgb.copy(); flip[..., 1] = 255 - flip[..., 1]
save("stud-normal-flipped-256.png", flip)
save("stud-color-256.png", np.dstack([np.full((256, 256), 242.0)] * 3))
save("stud-rough-256.png", np.full((256, 256), 191.0))
save("stud-ui-overlay-64.png", ns["overlay"]())
print("wrote", sorted(f for f in os.listdir(HERE) if f.endswith(".png")))
