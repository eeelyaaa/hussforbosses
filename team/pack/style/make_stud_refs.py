"""Stud tile references for the Huss for Bosses style guide. Needs numpy only (the repo's .venv-audio has it).
Run from the repo root: .venv-audio/Scripts/python.exe pitches/huss-for-bosses/style/make_stud_refs.py

The tile follows the manager's screenshots (concepts/manager-refs 1-3, 8, 10, 13, 14): a small, sharp-cornered
square, the same colour as the surface, drawn by its edges only: a dark L on its left and bottom edges and a faint
light line on its top and right edges.

Writes, next to this script (names and sizes are fixed; the UI kit tiles the overlay):
  stud-height-64.png      64 x 64 grey. Height map, one stud per tile: white = the surface, dark square = the stud,
                          set in. Source for the world normal map.
  stud-ui-overlay-64.png  64 x 64 RGBA. The UI tile: transparent, baked dark and light edges. Tile it over a flat fill.
  stud-preview.png        the UI tile over the UI palette: row 1 at 16 px per tile (phone), row 2 at 32 px (2x),
                          row 3 one button at 2x (ink outline, flat fill, studs, darker lip, hard shadow).
                          Swatch order: panel grey, plate blue, Huss red, cash green, shop gold, shield cyan,
                          alarm orange, meadow grass.
Technical reference made by script, not a production asset: the gui-designer and builder make the final files."""
import os, struct, zlib
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
T, SS = 64, 8                      # tile px, supersample
PAD = 0.28                         # stud inset from the tile edge: the square is 44% of the tile
R = 0.02                           # corner radius: sharp
DARK_W, DARK_A = 0.07, 0.30        # dark L on the left and bottom edges: width (of the tile), opacity
LIGHT_W, LIGHT_A = 0.045, 0.16     # light line on the top and right edges
FACE_A = 0.04                      # the face is a touch darker than the surface
DEPTH = 0.55                       # height map: grey level of the stud floor (1 = surface)

def save(name, a):
    a = np.clip(np.rint(a), 0, 255).astype(np.uint8)
    if a.ndim == 2: a = a[:, :, None]
    h, w, c = a.shape
    ct = {1: 0, 3: 2, 4: 6}[c]
    raw = b"".join(b"\x00" + a[y].tobytes() for y in range(h))
    def ch(t, d): return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    with open(os.path.join(HERE, name), "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, ct, 0, 0, 0)) + ch(b"IDAT", zlib.compress(raw, 9)) + ch(b"IEND", b""))

def body(s, grow=0.0):
    """Square mask (0..1) at s x s, corners rounded by R."""
    y, x = np.mgrid[0:s, 0:s] + 0.5
    lo, hi, r = (PAD - grow) * s, (1 - PAD + grow) * s, R * s
    dx = np.maximum(np.maximum(lo + r - x, x - (hi - r)), 0)
    dy = np.maximum(np.maximum(lo + r - y, y - (hi - r)), 0)
    inside = (x >= lo) & (x <= hi) & (y >= lo) & (y <= hi)
    return (inside & (dx * dx + dy * dy <= r * r)).astype(np.float64)

def down(a, k):
    h, w = a.shape[0] // k, a.shape[1] // k
    return a.reshape(h, k, w, k, *a.shape[2:]).mean(axis=(1, 3))

def shift(a, dx, dy):
    return np.roll(np.roll(a, dy, axis=0), dx, axis=1)

def layers(s):
    """(grey, alpha mask) layers of the UI overlay, bottom to top."""
    b = body(s); d, l = int(DARK_W * s), int(LIGHT_W * s)
    dark = np.clip(b - shift(b, d, -d), 0, 1)     # left and bottom edges of the square
    light = np.clip(b - shift(b, -l, l), 0, 1)    # top and right edges
    light = light * (1 - dark)
    return [(0.0, b * FACE_A), (255.0, light * LIGHT_A), (0.0, dark * DARK_A)]

def overlay(px=T):
    s = px * SS
    col = np.zeros((s, s)); alpha = np.zeros((s, s))          # premultiplied grey + alpha
    for c, a in layers(s):
        col = c * a + col * (1 - a); alpha = a + alpha * (1 - a)
    col, alpha = down(col, SS), down(alpha, SS)
    grey = np.where(alpha > 1e-6, col / np.maximum(alpha, 1e-6), 0)   # zero colour under clear pixels
    return np.dstack([grey, grey, grey, alpha * 255])

def height():
    s = T * SS; steps = 4; wall = 0.03                        # a short wall so the normal map has an edge to light
    b = sum(body(s, -wall * i / steps) for i in range(steps)) / steps
    return down(1 - b * (1 - DEPTH), SS) * 255

def hexrgb(h): return [int(h[i:i + 2], 16) for i in (1, 3, 5)]

def studded(hx, w, h, px):
    t = overlay(px)
    reps = np.tile(t, (h // px + 1, w // px + 1, 1))[:h, :w]
    a = reps[..., 3:4] / 255
    return np.array(hexrgb(hx), float) * (1 - a) + reps[..., :3] * a

def main():
    save("stud-height-64.png", height())
    save("stud-ui-overlay-64.png", overlay())
    ink = hexrgb("#101820")
    cols = ["#B4BBC6", "#1F6FD6", "#E02A2A", "#2FB341", "#FFC21A", "#35C8F0", "#FF6A00", "#A9D86B"]
    cw, chh = 144, 96
    sheet = np.full((400, 30 + len(cols) * 156, 3), (232, 236, 242), float)
    for i, hx in enumerate(cols):
        x = 30 + i * 156
        for row, px in enumerate((16, 32)):
            y = 24 + row * 120
            sheet[y - 3:y + chh + 3, x - 3:x + cw + 3] = ink
            sheet[y:y + chh, x:x + cw] = studded(hx, cw, chh, px)
    bx, by, bw, bh = 36, 280, 288, 96                      # button at 2x: outline 6, lip 10, tile 32
    sh = sheet[by + 6:by + bh + 16, bx - 6:bx + bw + 6]
    sheet[by + 6:by + bh + 16, bx - 6:bx + bw + 6] = sh * 0.65 + np.array(ink) * 0.35
    sheet[by - 6:by + bh + 6, bx - 6:bx + bw + 6] = ink
    sheet[by:by + bh, bx:bx + bw] = np.array(hexrgb("#2FB341")) * 0.72
    sheet[by:by + bh - 10, bx:bx + bw] = studded("#2FB341", bw, bh - 10 + 22, 32)[:bh - 10]
    save("stud-preview.png", sheet)

main()
