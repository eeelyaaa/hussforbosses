"""M2 art track: writes the layer data (bosses/<id>.json) for the five pictured bosses after Chomp Frog.
  python tools/blender/make_m2_bosses.py          (plain Python, no Blender)
Same data format as bosses/z1_t1.json (box / ball / cyl / seg fills, mirror, later fills win). Edit the numbers here,
re-run, then rebuild with build_boss.py. Cube indices: x = left/right (boss's left = +x), y = depth (front = -y),
z = up (feet z = 0). Colours are eyeballed from team/pack/concepts/brick-brawl/creatures.png, hex in the palettes."""
import json, os, math

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bosses")
fills = []

def F(g, shape, c, m=False, mg=None, only_x=None, paint=False):
    d = dict(shape); d["g"] = g; d["c"] = c if isinstance(c, list) else [c]
    if paint: d["paint"] = True  # recolour existing cubes only (build_boss.voxelize)
    if m: d["mirror"] = True
    if mg: d["mirror_group"] = mg
    if only_x: d["only_x"] = only_x
    fills.append(d)

def box(x0, y0, z0, x1, y1, z1): return {"box": [x0, y0, z0, x1, y1, z1]}
def ball(x, y, z, r): return {"ball": [x, y, z, r]}
def seg(a, b, r): return {"seg": list(a) + list(b) + [r]}
def cyl(ax, c1, c2, r, lo, hi): return {"cyl": [ax, c1, c2, r, lo, hi]}

def shift(d, dx, dy, dz):
    if "box" in d: b = d["box"]; d["box"] = [b[0]+dx, b[1]+dy, b[2]+dz, b[3]+dx, b[4]+dy, b[5]+dz]
    elif "ball" in d: b = d["ball"]; d["ball"] = [b[0]+dx, b[1]+dy, b[2]+dz, b[3]]
    elif "seg" in d: b = d["seg"]; d["seg"] = [b[0]+dx, b[1]+dy, b[2]+dz, b[3]+dx, b[4]+dy, b[5]+dz, b[6]]
    elif "cyl" in d:
        b = d["cyl"]; off = {"x": dx, "y": dy, "z": dz}; ax = b[0]; o = [k for k in "xyz" if k != ax]
        d["cyl"] = [ax, b[1] + off[o[0]], b[2] + off[o[1]], b[3], b[4] + off[ax], b[5] + off[ax]]

def P(shape, c, m=False):
    """Paint a band of colour onto cubes that already exist (lava cracks, star specks); the group stays the cube's."""
    F("Body", shape, c, m=m, paint=True)

def fist(g, x0, y0, z0, x1, y1, z1, cols, seam, mg=None, n=3, ncol=3, thumb=False):
    """M2-24 fist: a squared block, rounded at its edges, with a flat front (-y). The front layer (cubes y0) carries n
    finger rows stacked one above the other, each split into ncol knuckle blocks, all split by 1-cube seams (the seam
    colour shows on the recessed layer behind: the picture's chunky grid), optionally a shorter thumb row along the
    bottom on the inner side (low x). Given for FistL (+x);
    mirror_group makes FistR."""
    m = mg is not None
    H, D = z1 - z0, y1 - y0
    def kz(z): return 2 if z in (z0, z1 - 1) else (1 if z in (z0 + 1, z1 - 2) else 0)
    def ky(y): return 2 if y == y1 - 1 else (1 if y == y1 - 2 else 0)
    for z in range(z0, z1):
        for y in range(y0 + 1, y1):
            k = max(kz(z), ky(y), 1 if y == y0 + 1 and kz(z) else 0)
            if z in (z0, z1 - 1) and y >= y1 - 2: continue
            F(g, box(x0 + k, y, z, x1 - k, y + 1, z + 1), cols, m=m, mg=mg)
    F(g, box(x0 + 1, y0 + 1, z0 + 1, x1 - 1, y0 + 2, z1 - 1), seam, m=m, mg=mg)
    rows = n + (1 if thumb else 0)
    Hi = H - 2
    base, rem = divmod(Hi - (rows - 1), rows)
    z = z1 - 1
    for i in range(rows):
        h = base + (1 if i < rem else 0)
        last = thumb and i == rows - 1
        xa, xb = x0 + 1, (x0 + 1 + max(3, (2 * (x1 - x0 - 2)) // 3)) if last else x1 - 1
        cb, cr = divmod(xb - xa - (ncol - 1), ncol)
        x = xa
        for j in range(ncol):
            w = cb + (1 if j < cr else 0)
            F(g, box(x, y0, z - h, x + w, y0 + 1, z), cols, m=m, mg=mg)
            x += w + 1
        z -= h + 1

def crack(pts, lo, hi, axis="y", c="lava", g="Body", m=False, mg=None):
    """M2-24 lava crack: a 1-cube zig-zag line through pts (2D: (x, z) for axis y, (y, z) for axis x), painted on the
    cubes whose index along `axis` lies in [lo, hi) (the surface layers). Paint only, adds no cubes."""
    for (a0, b0), (a1, b1) in zip(pts, pts[1:]):
        n = int(2 * max(abs(a1 - a0), abs(b1 - b0))) + 1
        seen = set()
        for i in range(n + 1):
            t = i / n
            a, b = int(math.floor(a0 + (a1 - a0) * t)), int(math.floor(b0 + (b1 - b0) * t))
            if (a, b) in seen: continue
            seen.add((a, b))
            if axis == "y": F(g, box(a, lo, b, a + 1, hi, b + 1), c, m=m, mg=mg, paint=True)
            else: F(g, box(lo, a, b, hi, a + 1, b + 1), c, m=m, mg=mg, paint=True)

def finish(bid, name, btype, cube, hcubes, pal, pivots, doc, dx=0, dy=0, dz=0, extra=None):
    global fills
    for f in fills: shift(f, dx, dy, dz)
    groups = {g: {"pivot": [p[0] + dx, p[1] + dy, p[2] + dz]} for g, p in pivots.items()}
    for g, e in (extra or {}).items(): groups[g].update(e)
    # mirrored-fist pivots are given explicitly; x shift is 0 for all of them
    data = {"_doc": doc, "id": bid, "cube": cube, "height_cubes": hcubes, "palette": pal, "groups": groups, "fills": fills}
    json.dump(data, open(os.path.join(OUT, bid + ".json"), "w"), indent=0)
    print(bid, name, btype, "fills", len(fills))
    fills = []

COMMON = {"white": "#F2F5F8", "ink": "#14151C", "mouth": "#6E1E2E", "pink": "#F197BA", "yellow": "#F1D417", "cream": "#ECCF97"}

# ============================================================ Snap Scorpion (z2_t2, tailed striker, Uncommon)
# M2 redo (opus): a segmented tail arching high over the body to a red stinger, an angry face on the front (brow, eyes,
# open mouth with fangs), big pincer claws held up like fists, several tan legs splayed underneath.
def scorpion():
    # M2-24: main orange re-sampled more saturated (o4); scatter = o1 (same lightness), o2 only as the step shade (TEAM CALL M2-24-1)
    pal = dict(COMMON, o1="#E8802A", o2="#D4651C", o3="#F59C3E", tan="#D9B47A", tan2="#B98F58", brown="#8A5A33", red="#C92424",
               o4="#EE7420")
    O = ["o4", "o4", "o4", "o1"]
    # legs: four a side, thick tan, arching out from under the raised body, brown tips
    for i, yi in enumerate((-1, 2, 5, 8)):
        fy = yi + (yi - 3.5) * 0.9; ky = yi + (yi - 3.5) * 0.4
        F("Body", seg((4, yi, 8), (9.5, ky, 8.5), 1.6), ["tan", "tan", "tan2"], m=True)
        F("Body", seg((9.5, ky, 8.5), (12, fy, 2.5), 1.4), ["tan", "tan2"], m=True)
        F("Body", seg((12, fy, 2.5), (12.3, fy, 0.5), 1.3), "brown", m=True)
    # body: a rounded carapace raised on the legs, tan underside
    F("Body", box(-6, -1, 5, 6, 9, 12), O)
    F("Body", ball(0, 4, 10, 6.4), O)
    F("Body", box(-5, -1, 4, 5, 8, 6), ["tan", "tan2"])
    # head = the face on the front of the body: heavy angry brow, big eyes, tan muzzle with an open mouth and fangs
    F("Head", box(-6, -5, 5, 6, 0, 15), O)
    F("Head", box(-5, -6, 5, 5, -5, 14), O)
    F("Head", box(-4, -7, 5, 4, -6, 10), ["tan", "tan", "tan2"])
    F("Head", box(-3, -8, 5, 3, -7, 9), ["tan", "tan2"])
    F("Head", box(-3, -8, 6, 3, -6, 9), "mouth")
    F("Head", box(-2, -8, 6, 2, -7, 7), "pink")
    F("Head", box(-3, -9, 7, -2, -8, 9), "white"); F("Head", box(2, -9, 7, 3, -8, 9), "white")
    F("Head", box(-1, -8, 9, 0, -7, 10), "brown"); F("Head", box(1, -8, 9, 2, -7, 10), "brown")
    F("Head", box(-5, -7, 10, -1, -6, 13), "white", m=True)
    F("Head", box(-3, -7, 10, -1, -6, 12), "ink", m=True)
    # M2-24: carapace slab pulled back 2 cubes so the face's own stepped brow shows above the eyes
    F("Head", box(-6, -4, 14, 6, 0, 16), O)
    for (x, z) in ((-6, 13), (-5, 13), (-4, 13), (-3, 12), (-2, 12), (-1, 11)):
        F("Head", box(x, -8, z, x + 1, -6, z + 2), "o2", m=True)
    F("Head", box(-6, -8, 15, -3, -6, 16), "o2", m=True)
    # claws (M2-24): short arm, yellow band, a palm out at the side, then two open jaws making a C that opens toward
    # the face, with a clear gap: the upper jaw bigger, red on the last 3 cubes of each, the tips nearly meeting
    F("FistL", seg((5, -1, 9), (12, -6, 8.5), 2.2), O, mg="FistR", m=True)
    F("FistL", seg((11.5, -6, 8.5), (12.5, -8, 8.6), 2.8), "yellow", mg="FistR", m=True)
    F("FistL", box(13, -14, 6, 17, -9, 12), O, mg="FistR", m=True)
    F("FistL", box(14, -15, 7, 16, -14, 11), O, mg="FistR", m=True)
    F("FistL", seg((14, -12, 12.5), (11, -12.5, 14.2), 1.9), O, mg="FistR", m=True)
    F("FistL", seg((11, -12.5, 14.2), (8.5, -12.5, 12.8), 1.6), O, mg="FistR", m=True)
    F("FistL", seg((8.5, -12.5, 12.8), (7.5, -12.5, 10.8), 1.1), "red", mg="FistR", m=True)
    F("FistL", seg((14, -12, 5.8), (11, -12.5, 4.6), 1.6), O, mg="FistR", m=True)
    F("FistL", seg((11, -12.5, 4.6), (8.6, -12.5, 5.6), 1.3), O, mg="FistR", m=True)
    F("FistL", seg((8.6, -12.5, 5.6), (7.6, -12.5, 7.6), 0.95), "red", mg="FistR", m=True)
    # tail: thick banded segments up the back, arching high over the body to a red stinger hanging in front
    tail = [((0, 8, 11), "tan2", 2.9), ((0, 11, 14), "brown", 2.9), ((0, 12.5, 17), "tan", 2.8),
            ((0, 12.5, 20), "tan", 2.7), ((0, 10.5, 23), "o1", 2.7), ((0, 7, 25.3), "o3", 2.6),
            ((0, 2.5, 25.5), "o1", 2.5), ((0, -1.5, 24), "o2", 2.3)]
    for i in range(len(tail) - 1):
        g = "TailA" if i < 3 else "TailB"
        F(g, seg(tail[i][0], tail[i + 1][0], tail[i][2]), [tail[i][1]] if i % 2 else [tail[i][1], "tan2" if tail[i][1] == "tan" else tail[i][1]])
    F("TailB", ball(0, -2, 23.5, 2.3), "red")
    F("TailB", seg((0, -3, 22), (0, -4.5, 19.5), 1.3), "red")
    F("TailB", seg((0, -4.5, 19.5), (0, -4, 17.5), 0.8), "red")
    finish("z2_t2", "Snap Scorpion", "tailed striker", 0.19, 28, pal,
           {"Body": (0, 0, 0), "Head": (0, -1, 10), "FistL": (5, -1, 9), "FistR": (-5, -1, 9), "TailA": (0, 8, 11), "TailB": (0, 12.5, 20)},
           "Snap Scorpion (z2_t2), body type 3 tailed striker. Same data format as z1_t1.json. M2 redo.")

# ============================================================ Bit Shark (z3_t3, rearing swayer, Rare)
# M2 redo (opus): long tapered snout with the open jaw set into it, angry brow, forward-leaning S body, big swept
# dorsal fin, pectoral fins, white belly running up into the jaw, big blue fists.
def shark():
    # M2-24 fix pass: ear bumps gone (the brow no longer rises above the head), one tall swept dorsal fin that shows
    # over the head, an open mouth half the head high with square white teeth top and bottom and red inside, two close
    # blues only (TEAM CALL M2-24-1), squared fists with finger rows, a fin on each forearm, a taller tail fin.
    pal = dict(COMMON, b1="#2F6FD8", b2="#2458B8", b3="#4A8BEA", b4="#173F94", lb="#6FB0F0", red="#C92424", b5="#3878DC")
    B = ["b1", "b1", "b1", "b5"]
    # legs: short, bent, wide stance; three-toed feet
    F("Body", seg((3.5, 1, 9), (6.5, -2, 5), 3.0), B, m=True)
    F("Body", seg((6.5, -2, 5), (6.5, 0, 2), 2.6), B, m=True)
    F("Body", box(3, -5, 0, 10, 3, 3), B, m=True)
    for x0 in (3, 5.5, 8):
        F("Body", box(int(x0), -8, 0, int(x0) + 2, -5, 2), B, m=True)
    # hips and belly base; tail out the back to a tall crescent fin that shows beside the right leg
    F("Body", box(-5, -3, 6, 5, 5, 10), B)
    F("Body", box(-3, -4, 6, 3, -3, 10), "white"); F("Body", box(-2, -4, 4, 2, -3, 6), "white")
    F("Body", seg((0, 4, 7), (-3, 10, 4), 2.6), B)
    F("Body", seg((-3, 10, 4), (-6, 13, 3), 1.8), B)
    for z, y0, y1 in ((0, 11, 14), (1, 11, 15), (2, 12, 15), (3, 12, 15), (4, 13, 16), (5, 13, 16), (6, 14, 17),
                      (7, 14, 17), (8, 15, 18), (9, 15, 18), (10, 16, 18), (11, 16, 18), (12, 17, 18)):
        F("Body", box(-9, y0, z, -6, y1, z + 1), B)
    # upper body leaning forward (the S): each layer sits further forward than the one below
    rows = [(10, 12, -4, 4, 5), (12, 14, -5, 4, 6), (14, 16, -6, 3, 7), (16, 18, -7, 3, 7), (18, 20, -7, 2, 6)]
    for z0, z1, y0, y1, hw in rows:
        F("Upper", box(-hw, y0, z0, hw, y1, z1), B)
        bw = hw - 1 if z0 >= 14 else hw - 2
        F("Upper", box(-bw, y0 - 1, z0, bw, y0, z1), "white")
    # dorsal fin: one tall swept-back triangle on the upper back, its tip clear above the head
    for z in range(18, 35):
        t = (z - 18) / 16.0
        y0 = int(round(2 + t * 10)); y1 = int(round(11 + t * 3))
        if y1 > y0: F("Upper", box(-2 if z < 24 else -1, y0, z, 2 if z < 24 else 1, y1, z + 1), B)
    F("Upper", box(-2, 0, 18, 2, 11, 21), B)
    # head: skull over a snout; the mouth is open about half the head's height (z 17..24): white jaw rim, red inside,
    # square teeth 2 cubes tall hanging from the upper jaw and standing on the lower jaw, a small low tongue
    def HW(y): return 6 if y >= -6 else max(4, 6 - (-6 - y) // 4)
    def TOP(y):
        if y < -9: return 30 - (-9 - y) // 2
        if y <= -2: return 30
        return int(round(30 - (y + 2) * 1.2))
    for y in range(-15, 6):
        hw, top = HW(y), TOP(y)
        lip = 24 if y < -2 else 15
        F("Head", box(-hw, y, lip, hw, y + 1, top), B)
        if y < -2:
            F("Head", box(-hw, y, 24, hw, y + 1, 25), "white")
    for y in range(-14, 3):
        lw = HW(y) - 1
        F("Head", box(-lw, y, 14, lw, y + 1, 17), "white")
        if y >= -2: F("Head", box(-lw, y, 17, lw, y + 1, 19), "white")
    # the pointed snout tip overhanging the mouth, as in the picture
    F("Head", box(-4, -16, 24, 4, -15, 28), B); F("Head", box(-3, -17, 25, 3, -16, 27), B)
    F("Head", box(-4, -16, 24, 4, -15, 25), "white")
    F("Head", box(-5, -3, 17, 5, -2, 24), "red")
    for y in range(-13, -2):
        F("Head", box(-HW(y) + 2, y, 17, HW(y) - 2, y + 1, 24), "red")
    F("Head", box(-2, -8, 17, 2, -3, 18), "pink")
    # top teeth: two at the front, three down each side; bottom: three at the front, three down each side
    F("Head", box(1, -15, 22, 3, -14, 24), "white", m=True)
    for y in (-12, -9, -6):
        F("Head", box(HW(y) - 1, y, 22, HW(y), y + 2, 24), "white", m=True)
    F("Head", box(2, -14, 17, 3, -13, 19), "white", m=True); F("Head", box(-1, -14, 17, 1, -13, 19), "white")
    for y in (-11, -8, -5):
        F("Head", box(HW(y) - 2, y, 17, HW(y) - 1, y + 2, 19), "white", m=True)
    # eyes on the sides high on the snout, an ink pupil, an angry brow sloping to the snout (never above the head top)
    F("Head", box(4, -8, 26, 7, -5, 29), "white", m=True)
    F("Head", box(5, -8, 26, 7, -7, 28), "ink", m=True); F("Head", box(6, -7, 26, 7, -6, 28), "ink", m=True)
    for (y, z) in ((-9, 28), (-8, 29), (-7, 29), (-6, 29), (-5, 29), (-4, 29)):
        F("Head", box(4, y, z, 7, y + 1, z + 1 + (1 if y < -8 else 0)), "b2", m=True)
    # fists: squared blocks with finger rows on short thick arms, raised in a guard; a small fin on each forearm
    F("FistL", seg((6, -2, 16), (10, -5, 12), 2.6), B, mg="FistR", m=True)
    F("FistL", box(9, -2, 10, 11, 1, 12), B, mg="FistR", m=True)
    fist("FistL", 7, -11, 8, 16, -4, 17, B, "b2", mg="FistR", n=3)
    for i, (y0, y1) in enumerate(((-5, 1), (-5, 0), (-5, -1), (-5, -2))):
        F("FistL", box(15, y0, 10 + i, 17, y1, 11 + i), B, mg="FistR", m=True)
    finish("z3_t3", "Bit Shark", "rearing swayer", 0.22, 31, pal,
           {"Body": (0, 0, 0), "Upper": (0, 0, 9), "Head": (0, -2, 18), "FistL": (6, -2, 17), "FistR": (-6, -2, 17)},
           "Bit Shark (z3_t3), body type 5 rearing swayer. Upper carries Head, FistL, FistR. Head carries a rest yaw (M2-24). "
           "M2 redo, M2-24 fix pass.", extra={"Head": {"yaw": 15}})

# ============================================================ Frost Byte (z4_t4, biped bruiser, Epic)
def yeti():
    # M2-24 fix pass: white eyes with ink pupils under the stepped blue brow, a blue muzzle and nose block, a big open
    # mouth (fangs on top, teeth below, pink tongue, dark red behind), fur scatter kept close (w3 dropped, TEAM CALL
    # M2-24-1), squared blue fists with finger rows.
    pal = dict(COMMON, w1="#F2F2FA", w2="#DAD7EE", w3="#BDB8DE", blue="#2F8FD8", blue2="#4FA8E8", plate="#8FCDEB", rim="#3E86C9",
               blue3="#3896DB")
    W = ["w1", "w1", "w2"]; BL = ["blue", "blue", "blue3"]
    # feet with toes, thick legs angled out
    F("Body", box(3, -5, 0, 9, 3, 3), BL, m=True)
    F("Body", box(3, -8, 0, 5, -5, 2), BL, m=True)
    F("Body", box(6, -8, 0, 8, -5, 2), BL, m=True)
    F("Body", seg((4, 0, 13), (6.5, -1, 5), 4.4), W, m=True)
    F("Body", box(-8, -5, 11, 8, 5, 18), W)
    F("Body", box(-9, -5, 17, 9, 5, 22), W)
    F("Body", box(-6, -6, 11, 6, -5, 19), W)
    # head: fur dome sunk between the shoulders; a pale-blue face plate (y -6) with the face on the layer in front (y -7)
    F("Head", box(-7, -5, 20, 7, 4, 28), W)
    F("Head", ball(0, -0.5, 25, 7.0), W)
    F("Head", box(-6, -6, 17, 6, -5, 27), "plate"); F("Head", box(-5, -6, 27, 5, -5, 29), "plate")
    # mouth: x -5..5, z 18..22; a blue rim round it on the front layer, dark red behind, pink tongue low at the back
    F("Head", box(-6, -7, 17, 6, -6, 18), "rim")
    F("Head", box(-6, -7, 17, -5, -6, 23), "rim", m=True)
    F("Head", box(-6, -7, 22, 6, -6, 23), "rim")
    F("Head", box(-5, -6, 18, 5, -5, 22), "mouth")
    F("Head", box(-3, -6, 18, 3, -5, 20), "pink")
    # top teeth: an outer tooth, a long fang, a middle pair, a long fang, an outer tooth; bottom: three teeth
    for x, h in ((-5, 1), (-3, 3), (2, 3), (4, 1)):
        F("Head", box(x, -7, 22 - h, x + 1, -6, 22), "white")
    F("Head", box(-1, -7, 21, 1, -6, 22), "white")
    for x in (-4, 3):
        F("Head", box(x, -7, 18, x + 1, -6, 19), "white")
    F("Head", box(-1, -7, 18, 1, -6, 19), "white")
    # blue muzzle and nose block between the eyes and the mouth
    F("Head", box(-4, -7, 23, 4, -6, 24), "rim")
    F("Head", box(-1, -8, 23, 1, -6, 25), "blue")
    # eyes: white 3x3 with a 2x2 ink pupil on the inner, lower side
    F("Head", box(-5, -7, 24, -2, -6, 27), "white", m=True)
    F("Head", box(-4, -7, 24, -2, -6, 26), "ink", m=True)
    F("Head", box(-6, -7, 23, -5, -6, 27), "plate", m=True)
    # stepped angry brow: high at the outside, stepping down toward the nose, below the top of the dome
    for (x, z) in ((-6, 27), (-5, 27), (-4, 27), (-3, 27), (-2, 26)):
        F("Head", box(x, -8, z, x + 1, -6, z + 2), "rim", m=True)
    F("Head", box(-1, -7, 25, 1, -6, 27), "plate")
    # arms: a big shoulder mass, a thick forearm hanging forward, big squared blue fists with finger rows
    F("FistL", ball(10.5, 0, 18.5, 5.8), W, mg="FistR", m=True)
    F("FistL", seg((10, 0, 18), (11, -5, 14), 4.4), W, mg="FistR", m=True)
    fist("FistL", 6, -11, 8, 16, -3, 18, BL, "rim", mg="FistR", n=3)
    finish("z4_t4", "Frost Byte", "biped bruiser", 0.26, 31, pal,
           {"Body": (0, 0, 0), "Head": (0, -1, 21), "FistL": (10, 0, 19), "FistR": (-10, 0, 19)},
           "Frost Byte (z4_t4), body type 1 biped bruiser. M2, M2-24 fix pass.")

# ============================================================ Ember Drake (z5_t5, tailed striker, Legendary)
# M2 redo (opus): long horned snout with an open fanged jaw and angry brow, glowing lava cracks over chest, arms, legs
# and fists (atlas colour 'lava'; Neon at Studio setup), very large red fists, cream belly plates, wings rooted at the
# shoulders, and a segmented tail joined to the body that ends in the dark-basalt rock club (pack: no flame).
def drake():
    # M2-24 fix pass: a long forward snout narrower than the skull (eyes set back on the top-sides behind a stepped
    # brow, nostrils on the tip, teeth along the jaw), the head turned 15 degrees at rest as in the picture (group
    # yaw; the pivot is unchanged); the tail sweeps out from the rump beside the right leg and rises to an angular
    # basalt rock club held off the ground (pack: no flame); squared fists with finger rows; lava as 1-cube zig-zag
    # cracks; reds kept close (TEAM CALL M2-24-1).
    pal = dict(COMMON, r1="#D62828", r2="#B81E22", r3="#E8402F", gold="#E9C47E", gold2="#F3DDAA", horn="#F1B81A",
               wing="#F5A623", lava="#FFC21A", basalt="#3E3842", basalt2="#575060", cream2="#F3DDAA")
    R = ["r1", "r1", "r1", "r3"]
    # wings (Body; not a flyer): bones from the shoulder blades, membrane between, spread wide and up behind
    pts = [(4, 22), (9, 32), (15, 37), (23, 35), (25, 29), (20, 25), (14, 20), (8, 19)]
    def inside(x, z):
        n = len(pts); ins = False; j = n - 1
        for i in range(n):
            xi, zi = pts[i]; xj, zj = pts[j]
            if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi: ins = not ins
            j = i
        return ins
    for z in range(18, 38):
        xs = [x for x in range(3, 27) if inside(x + .5, z + .5)]
        if xs: F("Body", box(min(xs), 6, z, max(xs) + 1, 7, z + 1), ["wing", "wing", "horn"], m=True)
    F("Body", seg((4, 4, 23), (9, 6, 32), 1.3), "r1", m=True)
    F("Body", seg((9, 6, 32), (15, 6, 37.5), 1.1), "r1", m=True)
    for e in ((23.5, 6, 35), (25, 6, 29), (20, 6, 24.5), (14, 6, 19.5)):
        F("Body", seg((15, 6, 37), e, 0.8), "r2", m=True)
    # legs: thick, bent, wide stance; cream claws
    F("Body", seg((5, 1, 12), (7.5, -2, 7), 3.6), R, m=True)
    F("Body", seg((7.5, -2, 7), (7.5, 0, 3), 3.0), R, m=True)
    F("Body", box(4, -6, 0, 12, 3, 3), R, m=True)
    for x0 in (4, 7, 10):
        F("Body", box(x0, -8, 0, x0 + 2, -6, 2), "gold2", m=True)
    # hips, torso (broad chest), neck
    F("Body", box(-7, -4, 9, 7, 5, 14), R)
    F("Body", box(-7, -5, 13, 7, 5, 19), R)
    F("Body", box(-9, -5, 18, 9, 5, 25), R)
    F("Body", box(-7, -5, 24, 7, 4, 27), R)
    F("Body", box(-4, -6, 25, 4, 2, 28), R)
    # cream belly plates, segmented, from the crotch up the neck
    for z in range(9, 29):
        w = 2 if z < 13 else (3 if z < 24 else 2)
        F("Body", box(-w, -7 if z >= 18 else -6, z, w, -5 if z < 25 else -4, z + 1), "gold" if (z // 2) % 2 else "gold2")
    # head (built facing -y; the group yaw turns it): skull, a snout 8 wide and 11 long (skull 14 wide), mouth open
    F("Head", box(-5, -5, 24, 5, 3, 27), R)
    F("Head", box(-7, -6, 27, 7, 4, 36), R)
    F("Head", box(-6, -7, 28, 6, -6, 35), R)
    for y in range(-17, -6):
        hw = 4 if y >= -14 else 3
        top = 33 if y >= -12 else 32
        F("Head", box(-hw, y, 30, hw, y + 1, top), R)
        if -12 <= y: F("Head", box(-2, y, top, 2, y + 1, top + 1), "r2")
    for y in range(-15, -5):
        F("Head", box(-3, y, 24, 3, y + 1, 27), ["gold", "gold2"])
    F("Head", box(-3, -14, 27, 3, -6, 30), "mouth")
    F("Head", box(-2, -12, 27, 2, -7, 28), "pink")
    # teeth: hanging from the upper jaw at its sides and tip, standing on the lower jaw
    for y in (-16, -13, -10, -7):
        F("Head", box(3, y, 28, 4, y + 1, 30), "white", m=True)
    F("Head", box(1, -17, 28, 2, -16, 30), "white", m=True)
    for y in (-14, -11, -8):
        F("Head", box(2, y, 27, 3, y + 1, 29), "white", m=True)
    F("Head", box(1, -15, 27, 2, -14, 29), "white", m=True)
    # nostrils on the tip; eyes set back on the top-sides of the skull, ink pupil low and inward; stepped angry brow
    F("Head", box(1, -18, 30, 2, -17, 32), "r2", m=True)
    F("Head", box(1, -18, 31, 2, -17, 32), "ink", m=True)
    F("Head", box(4, -8, 32, 7, -6, 35), "white", m=True)
    F("Head", box(4, -8, 32, 6, -7, 34), "ink", m=True)
    for (x, z) in ((7, 35), (6, 35), (5, 35), (4, 34), (3, 34), (2, 33)):
        F("Head", box(x, -9, z, x + 1, -6, z + 2), "r2", m=True)
    # cheek spikes at the back of the head, crest, horns (big, yellow, sweeping up and back)
    for i, z in enumerate((27, 30, 33)):
        F("Head", box(7, -1 + i, z, 10 - (i == 2), 3 + i, z + 2), ["r2", "r1"], m=True)
        F("Head", box(9, 1 + i, z + 1, 11 - (i == 2), 3 + i, z + 2), "r2", m=True)
    F("Head", seg((3.5, -1, 35), (5.5, 1, 37.2), 1.7), "horn", m=True)
    F("Head", seg((5.5, 1, 37.2), (5.8, 4.5, 38.3), 1.3), "horn", m=True)
    F("Head", seg((5.8, 4.5, 38.3), (5.3, 8, 37.8), 0.9), "horn", m=True)
    F("Head", box(-1, -3, 36, 1, 4, 37), "r2")
    # arms and very large squared red fists held in front at chest height; a lava crack across each fist and down the arm
    F("FistL", seg((8, -1, 23), (10.5, -4, 18), 3.2), R, mg="FistR", m=True)
    fist("FistL", 6, -14, 12, 17, -5, 23, R, "r2", mg="FistR", n=3)
    crack([(6.5, 20.5), (8.5, 18.5), (10.5, 19.5), (12.5, 17.5), (14.5, 18.5), (16.5, 15.5)], -14, -13, g="FistL", mg="FistR", m=True)
    F("FistL", seg((11, -1, 23.5), (13.3, -4, 18.5), 0.8), "lava", mg="FistR", m=True, paint=True)
    # tail: from the rump out round the boss's right (-x), low by the leg, then rising to the club held off the ground
    F("TailA", seg((0, 5, 11), (-5, 10, 8), 3.6), R)
    F("TailA", seg((-5, 10, 8), (-10, 11, 5.5), 3.1), R)
    F("TailA", seg((-10, 11, 5.5), (-13, 10, 4.2), 2.7), R)
    F("TailB", seg((-13, 10, 4.2), (-17.5, 8.5, 4.6), 2.4), R)
    F("TailB", seg((-17.5, 8.5, 4.6), (-21, 6, 6.6), 2.1), R)
    F("TailB", seg((-21, 6, 6.6), (-22.5, 4, 8.8), 1.9), R)
    for (x, y, z) in ((-3, 9, 11), (-8, 12, 8), (-12, 11, 6), (-17, 9, 7), (-20, 7, 9)):
        F("TailA" if x > -12.5 else "TailB", box(x - 1, y - 1, z, x + 1, y + 1, z + 2), "r2")
    # the club: an angular basalt rock about a fist's size, flat faces, the lighter shade on its top facets
    F("TailB", box(-26, -1, 8, -20, 5, 14), "basalt")
    F("TailB", box(-25, -2, 9, -21, 6, 13), "basalt")
    F("TailB", box(-27, 0, 9, -19, 4, 13), "basalt")
    F("TailB", box(-25, 0, 7, -21, 4, 8), "basalt")
    F("TailB", box(-26, -1, 13, -20, 5, 14), "basalt2")
    F("TailB", box(-25, 0, 14, -21, 4, 15), "basalt2")
    F("TailB", box(-27, 0, 12, -19, 4, 13), "basalt2")
    F("TailB", box(-25, -2, 12, -21, 6, 13), "basalt2")
    F("TailB", box(-24, 0, 15, -22, 3, 17), "basalt2"); F("TailB", box(-26, 1, 14, -23, 4, 16), "basalt2")
    F("TailB", box(-28, 1, 9, -27, 3, 12), "basalt"); F("TailB", box(-21, -3, 10, -19, -2, 12), "basalt2")
    # lava cracks (paint only, 1 cube wide, zig-zag) last: chest flanks, hips, legs and feet, tail
    crack([(-8.5, 24.5), (-6.5, 22.5), (-7.5, 20.5), (-5.5, 18.5), (-6.5, 16.5), (-4.5, 14.5), (-5.5, 12.5), (-4.5, 10)], -6, -3, m=True)
    crack([(5.5, 12.5), (7.5, 10.5), (6.5, 8.5), (8.5, 6.5), (7.5, 4.5), (9.5, 2.5), (8.5, 0.5)], -8, -1, m=True)
    crack([(-1, 24.5), (1, 22.5), (-1, 20.5), (2, 18.5)], -10, -9, axis="x", m=True)
    crack([(-1, 24), (2, 22), (0, 20)], 8, 10, axis="x", m=True)
    F("TailA", seg((0, 5, 14.2), (-5, 10, 11.2), 0.7), "lava", paint=True)
    F("TailA", seg((-5, 10, 11.2), (-10, 11, 8.2), 0.7), "lava", paint=True)
    F("TailB", seg((-13, 10, 6.6), (-17.5, 8.5, 7.0), 0.7), "lava", paint=True)
    finish("z5_t5", "Ember Drake", "tailed striker", 0.28, 39, pal,
           {"Body": (0, 0, 0), "Head": (0, -2, 26), "FistL": (8, -1, 23), "FistR": (-8, -1, 23), "TailA": (0, 5, 11), "TailB": (-13, 10, 4.2)},
           "Ember Drake (z5_t5), body type 3 tailed striker. Wings stay in Body (not a flyer). Tail club is dark basalt, no flame. "
           "Palette 'lava' = the lava cracks (Neon at Studio setup). Head carries a rest yaw (M2-24). M2 redo, M2-24 fix pass.",
           extra={"Head": {"yaw": 15}})

# ============================================================ Star Golem (z6_t6, biped bruiser, Mythic)
# M2 redo (opus): a distinct domed head above the collar (angry gold brow, glowing eyes, open roaring mouth), huge gold-
# trimmed shoulder pauldrons, enormous purple fists with gold wrist bands at hip height, a gold chest plate with the
# bright star, gold belt with an octagon buckle, gold bands on thighs and boots, star specks over the purple body.
def golem():
    # M2-24 fix pass: deeper violet with close shades (TEAM CALL M2-24-1); the face is two glowing yellow slit eyes
    # under a heavy stepped purple brow and an open pink mouth with a few small teeth; stars are ~8 medium plus signs
    # and many single-cube specks in the picture's saturated gold-yellow, with one big white-hot chest star; squared
    # fists with finger rows. Proportions and pivots unchanged (the leg lengthening would move every pivot above).
    pal = dict(COMMON, p1="#6A20AC", p2="#5F1C9E", p3="#7626B8", p4="#4D1A82", gold="#F0B429", gold2="#D99A1C", gold3="#F8CF55",
               star="#FFD83A", core="#C070D8", starw="#FFF6C8")
    P_ = ["p1", "p1", "p1", "p2", "p3"]; G = ["gold", "gold2", "gold3"]
    # boots: big gold, flared, with toes
    F("Body", box(2, -7, 0, 11, 5, 3), G, m=True)
    for x0 in (2, 5, 8):
        F("Body", box(x0, -10, 0, x0 + 3, -7, 2), ["gold", "gold3"], m=True)
    F("Body", box(2, -8, 2, 11, 5, 4), ["gold3", "gold"], m=True)
    # legs: thick purple columns with a gap between, a gold knee band
    F("Body", box(3, -5, 4, 10, 4, 17), P_, m=True)
    F("Body", box(2, -6, 9, 11, 5, 12), G, m=True)
    F("Body", box(-3, -4, 13, 3, 4, 17), P_)
    # belt with an octagon buckle
    F("Body", box(-8, -6, 16, 8, 5, 18), G)
    F("Body", box(-2, -8, 14, 2, -6, 19), "gold3"); F("Body", box(-3, -8, 15, 3, -6, 18), "gold3")
    F("Body", box(-1, -9, 16, 1, -8, 18), "gold"); F("Body", box(-2, -9, 17, 2, -8, 18), "gold")
    F("Body", box(-1, -9, 17, 1, -8, 18), "core")
    # torso: broad chest above a narrower waist
    F("Body", box(-7, -5, 18, 7, 5, 21), P_)
    F("Body", box(-9, -6, 21, 9, 6, 27), P_)
    # gold yoke round the neck and a shield-shaped chest plate pointing down, the big chest star on it
    F("Body", box(-9, -7, 25, 9, 5, 27), G)
    for z in range(21, 25):
        hw = int(round(1 + (z - 21) * 1.3))
        F("Body", box(-hw, -8, z, hw, -7, z + 1), G)
    F("Body", box(-1, -9, 18, 1, -8, 26), "star"); F("Body", box(-6, -9, 22, 6, -8, 24), "star")
    F("Body", box(-2, -9, 21, 2, -8, 25), "star")
    F("Body", box(-1, -10, 20, 1, -9, 25), "star"); F("Body", box(-3, -10, 22, 3, -9, 24), "star")
    F("Body", box(-1, -10, 22, 1, -9, 24), "starw"); F("Body", box(-1, -11, 22, 1, -10, 24), "starw")
    # pauldrons: huge, rounded, gold-trimmed
    F("Body", ball(11.5, 0, 24, 5.4), P_, m=True)
    F("Body", cyl("z", 11.5, 0, 5.7, 20, 21), G, m=True)
    F("Body", cyl("z", 11.5, 0, 4.0, 28, 30), G, m=True)
    # head: domed, standing clear above the yoke
    F("Head", box(-5, -5, 25, 5, 4, 30), P_)
    F("Head", ball(0, -0.5, 29.5, 5.8), P_)
    # open pink mouth with a dark rim and a few small teeth (paint on the face's front cubes)
    F("Head", box(-4, -7, 25, 4, -4, 30), "mouth", paint=True)
    F("Head", box(-3, -7, 26, 3, -4, 29), "pink", paint=True)
    for x in (-3, 2):
        F("Head", box(x, -7, 28, x + 1, -4, 29), "white", paint=True)
    F("Head", box(-1, -7, 26, 1, -4, 27), "white", paint=True)
    # glowing yellow slit eyes (the one boss allowed glowing eyes), slanting in, under a heavy stepped brow 2 thick
    F("Head", box(-5, -7, 31, -1, -5, 32), "star", m=True)
    F("Head", box(-5, -7, 32, -3, -5, 33), "star", m=True)
    for (x, z) in ((-6, 33), (-5, 33), (-4, 33), (-3, 32), (-2, 32), (-1, 32)):
        F("Head", box(x, -8, z, x + 1, -6, z + 2), "p4", m=True)
    F("Head", box(-6, -7, 30, -5, -5, 33), "p2", m=True)
    # arms: hang from the pauldrons to enormous squared fists at belt height, gold wrist bands
    F("FistL", seg((12, 0, 21), (13.5, -2, 19), 3.4), P_, mg="FistR", m=True)
    fist("FistL", 9, -9, 9, 20, 1, 20, P_, "p4", mg="FistR", n=3)
    F("FistL", cyl("z", 14, -3, 4.6, 18, 20), G, mg="FistR", m=True)
    # stars (paint only): ~8 medium plus signs (5 cubes) and single-cube specks, all on the purple
    def star(x, z, y0, y1, m=False, g="Body"):
        F(g, box(x - 1, y0, z, x + 2, y1, z + 1), "star", m=m, paint=True, mg="FistR" if g == "FistL" else None)
        F(g, box(x, y0, z - 1, x + 1, y1, z + 2), "star", m=m, paint=True, mg="FistR" if g == "FistL" else None)
    def speck(x, z, y0, y1, m=False):
        F("Body", box(x, y0, z, x + 1, y1, z + 1), "star", m=m, paint=True)
    star(-6, 19, -7, -4); star(7, 20, -7, -4)          # torso, either side of the plate
    star(-7, 6, -6, -4, m=True); star(6, 14, -6, -4)    # legs (3)
    star(11, 25, -7, -3, m=True)                        # pauldrons (2); the big chest star makes 8
    for (x, z) in ((-5, 22), (5, 23), (-8, 24), (8, 22), (-3, 20), (4, 19), (-7, 21)):
        speck(x, z, -7, -5)
    for (x, z) in ((5, 5), (8, 8), (4, 13), (9, 15), (-4, 5), (-9, 9), (-5, 15), (-8, 13), (7, 11), (-6, 11)):
        speck(x, z, -6, -4)
    for (y, z) in ((-3, 7), (1, 13), (2, 5), (-2, 15), (0, 10)):
        F("Body", box(9, y, z, 11, y + 1, z + 1), "star", m=True, paint=True)
    for (y, z) in ((-3, 22), (2, 26), (-1, 19)):
        F("Body", box(15, y, z, 18, y + 1, z + 1), "star", m=True, paint=True)
    # halo: a ring over the head, tilted back a little
    for x in range(-12, 12):
        for y in range(-10, 10):
            q = ((x + .5) / 11.5) ** 2 + ((y + .5) / 9.5) ** 2
            if 0.70 <= q <= 1.0:
                z = 37 + int(round((y + .5) * 0.2))
                F("Sig", box(x, y, z, x + 1, y + 1, z + 2), G)
    finish("z6_t6", "Star Golem", "biped bruiser", 0.40, 35, pal,
           {"Body": (0, 0, 0), "Head": (0, 0, 25), "FistL": (12, 0, 21), "FistR": (-12, 0, 21), "Sig": (0, 0, 39)},
           "Star Golem (z6_t6), body type 1 biped bruiser. Sig = the halo ring. The floating gold star cubes of the picture are "
           "the Mythic tier aura (an effect, style guide 'Glow'), not part of the mesh. M2 redo, M2-24 fix pass.")

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    scorpion(); shark(); yeti(); drake(); golem()
