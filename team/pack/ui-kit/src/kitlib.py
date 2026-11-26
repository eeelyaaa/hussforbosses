"""Drawing helpers for the Huss for Bosses UI kit (pitch step 3). Used by build_kit.py.

Every size passed in is in DESIGN pixels of the 874 x 402 phone frame (style-guide.md section 6). The module-level
scale `S` turns them into page units: 1.0 for phone frames and kit boards, 1.648 for the 1920 x 1080 desktop frames
(the style guide's UIScale: min(w/874, h/402) x 0.75 on mouse-and-keyboard screens).
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/") + "/"
PITCH = HERE.rsplit("/", 3)[0] + "/"
P = json.load(open(HERE + "parts.json"))

INK, WHITE = "#101820", "#FFFFFF"
COL = dict(panel="#B4BBC6", blue="#1F6FD6", red="#E02A2A", green="#2FB341", gold="#FFC21A", cyan="#35C8F0",
           orange="#FF6A00", yellow="#FFF36B", white="#FFFFFF", dis="#8A919C", empty="#3A4250")
INK_TEXT_ON = ("gold", "white", "yellow")          # style guide: ink text, no outline, on these fills
TIERS = [("COMMON", "#A9B2BD"), ("UNCOMMON", "#5DBB2F"), ("RARE", "#2E8BFF"), ("EPIC", "#9B4DFF"),
         ("LEGENDARY", "#FF9F1A"), ("MYTHIC", "#FF3D7F")]
ZONES = [("BRICK MEADOW", "#8FD13B"), ("SAND BLOCKS", "#F0DFA0"), ("PIRATE PLATES", "#57BDE6"),
         ("ICE BLOCKS", "#F1F6FB"), ("LAVA BRICKS", "#FF8A1F"), ("SPACE BASEPLATE", "#7A63D6")]
DIFF = {"EASY": "#6BE04A", "FAIR": "#6BE04A", "HARD": "#FFE14A", "VERY HARD": "#FF9A2E", "BRUTAL": "#FF4B4B", "NEAR IMPOSSIBLE": "#FF4B4B"}
FONT = "Montserrat"

cmds = []
S = 1.0
STUD = None
SHIFT = {"parent": None, "from": 0, "by": 0}     # moves later board content down when a section above grew


def set_scale(v):
    global S
    S = v


def add(command, **params):
    name = "n%d" % len(cmds)
    cmds.append({"command": command, "as": name, "params": params})
    return {"$ref": name}


def rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def hexs(c):
    return "#%02X%02X%02X" % tuple(max(0, min(255, int(round(v)))) for v in c)


def mul(h, f):
    return hexs([v * f for v in rgb(h)])


def lighten(h, p):
    return hexs([v + (255 - v) * p for v in rgb(h)])


def px(v):
    """A line weight: scaled, whole pixels, never under 1."""
    return max(1, int(round(v * S)))


def hard(dy, color=INK):
    return [{"type": "dropShadow", "color": color, "offset": [0, px(dy)], "radius": 0}]


def init_stud():
    """Places the art-director's stud tile once; every studded surface then tiles the same image."""
    global STUD
    r = add("image.place", path=PITCH + "style/stud-ui-overlay-64.png", x=-400, y=-400, width=64, height=64,
            name="SOURCE stud-ui-overlay-64 (the tile every studded surface repeats)")
    STUD = {"$ref": r["$ref"], "field": "image"}


def stud(color, tile=16):
    """Flat colour first, the stud tile second (style guide section 2). 16 design px per tile."""
    return [color, {"type": "image", "image": STUD, "scale_mode": "tile", "scale": tile * S / 64.0}]


def node(type_, parent, name, x=None, y=None, w=None, h=None, text=None, **props):
    p = {"type": type_, "name": name, "select": False}
    if parent is not None: p["parent"] = parent
    if x is not None: p["x"] = x * S
    if y is not None:
        if SHIFT["parent"] is not None and parent == SHIFT["parent"] and y >= SHIFT["from"]: y += SHIFT["by"]
        p["y"] = y * S
    if w is not None: p["width"] = w * S
    if h is not None: p["height"] = h * S
    if text is not None: p["text"] = text
    for k in ("cornerRadius", "gap", "padding"):
        if k in props:
            v = props[k]
            props[k] = [i * S for i in v] if isinstance(v, list) else v * S
    if "strokeWeight" in props: props["strokeWeight"] = px(props["strokeWeight"])
    if props: p["props"] = props
    return add("node.create", **p)


def F(parent, name, x=None, y=None, w=None, h=None, fill="none", clip=False, **props):
    return node("frame", parent, name, x, y, w, h, fill=fill, clip=clip, **props)


def row(parent, name, x=None, y=None, w=None, h=None, gap=6, main="center", cross="center", pad=0, vertical=False, **props):
    """An auto-layout frame: children are centred by the layout, so no text width is ever guessed."""
    props.setdefault("fill", "none")
    f = F(parent, name, x, y, w, h, layout="vertical" if vertical else "horizontal", gap=gap, mainAlign=main,
          crossAlign=cross, padding=pad, **props)
    return f


def R(parent, name, x, y, w, h, fill, r=4, sw=0, studded=False, shadow=0, **props):
    if studded: props["fills"] = stud(fill)
    else: props["fill"] = fill
    if sw: props.update(stroke=INK, strokeWeight=sw, strokeAlign="outside", strokeJoin="round")
    if shadow: props["effects"] = hard(shadow, "#10182059")
    return node("rectangle", parent, name, x, y, w, h, cornerRadius=r, **props)


def T(parent, s, x=None, y=None, size=18, color=WHITE, w=None, align="left", ol=None, weight="Black", name=None):
    """Game type. White (or any light colour) carries the 2 px ink outline and hard ink shadow; ink text carries none."""
    p = dict(fontFamily=FONT, fontStyle=weight, fontSize=int(round(size * S)), fill=color)
    if ol is None: ol = color != INK and weight == "Black"
    if ol:
        p.update(stroke=INK, strokeWeight=2, strokeAlign="outside", strokeJoin="round", effects=hard(2))
    if w is not None:
        p["textAlign"] = align; p["textAutoResize"] = "height"
    return node("text", parent, name or ("TextLabel/" + s[:26]), x, y, w, None, text=s, **p)


def body(parent, s, x=None, y=None, w=None, size=14, align="left", color=INK, name=None):
    """Body text: Bold, sentence case, ink, no outline. Sits on a white well."""
    return T(parent, s, x, y, size, color, w, align, ol=False, weight="Bold", name=name)


def I(parent, key, box, x=None, y=None, name=None, grey=False, rot=0):
    """A generated icon (or a stand-in creature) fitted, uncropped, in a box x box square."""
    path, mw, mh = P[key]
    sc = min(box / mw, box / mh)
    w, h = mw * sc, mh * sc
    kw = dict(path=path, parent=parent, width=w * S, height=h * S, name=name or ("ImageLabel/" + key.split("/")[1]))
    if x is not None:
        kw["x"] = (x + (box - w) / 2) * S; kw["y"] = (y + (box - h) / 2) * S
    r = add("image.place", **kw)
    if rot: add("node.set", ids=[r], props={"rotation": rot})
    if grey: add("image.adjust", ids=[r], preset="blackAndWhite")
    return r


# ---------------------------------------------------------------------------------------------- components
def content(parent, items, kind, size, name="Content", x=0, y=0, w=None, h=None, gap=6):
    """A centred row of icons and labels. items: "TEXT" | ("i", key, box) | ("t", text, size) | ("b", text)."""
    r = row(parent, name, x, y, w, h, gap=gap)
    col = INK if kind in INK_TEXT_ON else ("#D5D9DF" if kind == "dis" else WHITE)
    for it in items:
        if isinstance(it, str): T(r, it, size=size, color=col, name="TextLabel/Label")
        elif it[0] == "i": I(r, it[1], it[2], grey=(kind == "dis" and len(it) < 4))
        elif it[0] == "t": T(r, it[1], size=it[2], color=col)
    return r


def button(parent, name, x, y, w, h=48, kind="green", items=(), state="default", size=18, lip=5):
    """Style guide button. kind: red|green|gold|cyan|white (one job each). state: default|hover|pressed|disabled."""
    f = F(parent, name, x, y, w, h)
    fill = COL[kind]; k = kind; fy = 0; lp = lip; top = True
    if state == "hover": fill = lighten(fill, 0.08); fy = -1
    if state == "pressed": fill = mul(fill, 0.9); fy = lip - 1; lp = 1; top = False
    if state == "disabled": fill = COL["dis"]; k = "dis"; fy = lip - 2; lp = 2; top = False
    fh = h - lip
    R(f, "Lip (fill x 0.72)", 0, fy, w, fh + lp, mul(fill, 0.72), sw=3)
    R(f, "Face (stud tile over the fill)", 0, fy, w, fh, fill, studded=fh >= 28)
    if top: R(f, "Top line (fill lightened 25%)", 3, fy, w - 6, 2, lighten(fill, 0.25), r=1)
    content(f, items, k, size, y=fy, w=w, h=fh)
    return f


def close_btn(parent, x, y):
    return button(parent, "Close (ImageButton, 36 px inside a 44 px touch area)", x, y, 36, 36, "white", ["X"], size=18, lip=4)


def keycap(parent, x, y, letter, w=22):
    """The input glyph on a small ink plate (keyboard shown; gamepad shows the platform's glyph)."""
    f = F(parent, "KeyHint/" + letter, x, y, w, 22)
    R(f, "GlyphPlate (ink)", 0, 0, w, 22, INK, r=3, stroke=WHITE, strokeWeight=2, strokeAlign="outside")
    T(f, letter, 0, 2, 14, WHITE, w=w, align="center", ol=False)
    return f


def well(parent, x, y, w, h, name="Well (white, smooth)"):
    return R(parent, name, x, y, w, h, WHITE, sw=2)


def panel(parent, name, x, y, w, h, title, title_icon=None, close=True, head="blue"):
    f = F(parent, name, x, y, w, h)
    R(f, "Body (panel grey + stud tile)", 0, 0, w, h, COL["panel"], sw=3, studded=True, shadow=5)
    R(f, "HeaderBar (%s + stud tile)" % head, 0, 0, w, 44, COL[head], r=[4, 4, 0, 0], studded=True)
    R(f, "HeaderLine", 0, 44, w, 3, INK, r=0)
    tx = 12
    if title_icon:
        I(f, title_icon, 36, 8, 4); tx = 50
    T(f, title, tx, 8, 22, INK if head in INK_TEXT_ON else WHITE, name="TextLabel/Title")
    if close: close_btn(f, w - 42, 4)
    return f


def chip(parent, tier, x=None, y=None, pad=8):
    word, colr = TIERS[tier]
    c = row(parent, "TierChip/" + word, x, y, None, 22, pad=[0, pad, 0, pad], fill=colr, stroke=INK, strokeWeight=2,
            strokeAlign="outside", cornerRadius=4, sizingH="hug")
    T(c, word, size=14)
    return c


def plate(parent, name, x, y, w, kind, ic, value, plus=False, size=18, key=None):
    """Counter plate: studded, 32 tall, the 36 px icon overlaps the left edge by 8."""
    f = F(parent, name, x, y, w, 32)
    fill = COL[kind]
    R(f, "Plate", 0, 0, w, 32, fill, sw=3, studded=True, shadow=3)
    I(f, ic, 36, -8, -2, grey=(kind == "dis"))
    T(f, value, 34, 5, size, INK if kind in INK_TEXT_ON else WHITE, name="TextLabel/Value")
    if key: keycap(f, w - 11, 20, key)
    return f


def bar(parent, name, x, y, w, h, frac, color, label=None):
    f = F(parent, name, x, y, w, h)
    R(f, "Track", 0, 0, w, h, COL["empty"], sw=2)
    if frac > 0:
        R(f, "Fill", 0, 0, max(4, w * frac), h, color)
        R(f, "Fill top line", 2, 0, max(2, w * frac - 4), 2, lighten(color, 0.3), r=1)
    if label: T(f, label, 0, (h - 14 * 1.22) / 2, 14, w=w, align="center")
    return f


def boss_card(parent, name, x, y, w, h, tier, key=None, title=None, sub=None, bought=False):
    """Filled with the tier colour (smooth), the boss picture on top, the tier chip under it."""
    f = F(parent, "BossCard/" + name, x, y, w, h)
    R(f, "Fill (tier colour, smooth)", 0, 0, w, h, TIERS[tier][1], sw=3, shadow=4)
    used = 30 + (18 * len(title.split("\n")) + 4 if title else 0) + (24 if sub else 0)
    ph = h - used - 8
    if key:
        I(f, key, min(w - 12, ph), (w - min(w - 12, ph)) / 2, 6 + (ph - min(w - 12, ph)) / 2,
          name="ImageLabel/Portrait (STAND-IN: final portraits are renders of the built models)")
    else:
        T(f, "MODEL\nRENDER", 0, 6 + ph / 2 - 17, 14, w=w, align="center", name="TextLabel/No stand-in exists for this boss")
    yy = 6 + ph + 2
    if title:
        T(f, title, 0, yy, 14, w=w, align="center", name="TextLabel/BossName"); yy += 18 * len(title.split("\n")) + 4
    r = row(f, "ChipRow", 0, yy, w, 22)
    chip(r, tier, pad=3 if w < 120 else 8)
    if bought: tag(r)
    yy += 26
    if sub: T(f, sub, 0, yy - 2, 18, w=w, align="center", name="TextLabel/Big")
    return f


def pips(parent, cx, y, filled, clean=False):
    f = F(parent, "ComboPips (huss huss huss)", cx - 31, y, 62, 18)
    for i in range(3):
        on = i < filled
        colr = COL["yellow"] if clean else (COL["red"] if on else COL["empty"])
        R(f, "Pip %d %s" % (i + 1, "filled" if on else "empty"), i * 22, 0, 18, 18, colr, sw=2, r=3)
        if on and not clean: R(f, "Pip top line", i * 22 + 2, 0, 14, 2, lighten(COL["red"], 0.3), r=1)
    return f


def huss(parent, cx, cy, state="idle", n=0, label="HUSS!", key=None, d=120, ring=1.38):
    """The Huss button: the only round thing in the UI. state: idle|closing|perfect|good|miss|disabled|plain."""
    f = F(parent, "Huss (ImageButton, %s)" % state, cx - d / 2, cy - d / 2, d, d + 6)
    c = d / 2
    red = COL["dis"] if state == "disabled" else COL["red"]
    if state in ("perfect", "good"):
        node("star", f, "ImpactStar (8 points, hard edge, 0.08 s)", c - d * 0.86, c - d * 0.86, d * 1.72, d * 1.72, fill=COL["yellow"],
             stroke=INK, strokeWeight=3, strokeAlign="outside", strokeJoin="round", pointCount=8, innerRadius=0.72)
    if state not in ("disabled", "plain"):
        b = d * 1.15
        node("ellipse", f, "HitBand (flash yellow, 1.0 to 1.15 x the button)", c - b / 2, c - b / 2, b, b,
             fill="#FFFFFF" if state == "perfect" else COL["yellow"], stroke=INK, strokeWeight=2, strokeAlign="outside")
    node("ellipse", f, "Lip", 0, 6, d, d, fill=mul(red, 0.72), stroke=INK, strokeWeight=4, strokeAlign="outside")
    face = COL["yellow"] if state == "perfect" else red
    node("ellipse", f, "Face (stud tile)", 0, 0, d, d, fills=stud(face), stroke=INK, strokeWeight=4, strokeAlign="outside")
    I(f, "p/icon-glove", 58, c - 29, 10, grey=(state == "disabled"), rot=8)
    T(f, label, 0, 74, 20, "#D5D9DF" if state == "disabled" else WHITE, w=d, align="center", name="TextLabel/Huss")
    if state in ("closing", "miss"):
        k = ring if state == "closing" else 0.86
        rd = d * k
        node("ellipse", f, "TimingRing/ink edges", c - rd / 2, c - rd / 2, rd, rd, fill="none", stroke=INK, strokeWeight=10, strokeAlign="center")
        node("ellipse", f, "TimingRing (6 px; closes from 1.6 x onto the button)", c - rd / 2, c - rd / 2, rd, rd, fill="none",
             stroke=WHITE if state == "closing" else COL["dis"], strokeWeight=6, strokeAlign="center")
    if state not in ("plain", "disabled"):
        pips(f, c, -40, 3 if state == "perfect" and n == 3 else n, clean=(state == "perfect" and n == 3))
    pop = {"perfect": ("PERFECT!", COL["yellow"]), "good": ("GOOD", WHITE), "miss": ("MISS", "#D5D9DF")}.get(state)
    if pop: T(f, pop[0], -40, -70, 20, pop[1], w=d + 80, align="center", name="TextLabel/Grade pop")
    if key: keycap(f, d - 16, d - 20, key)
    return f


def zone_strip(parent, x, y, w, cur):
    f = F(parent, "ZoneStrip (where you are on the lane)", x, y, w, 40)
    T(f, "ZONE %d  %s" % (cur, ZONES[cur - 1][0]), 0, 0, 14, w=w, align="center", name="TextLabel/Zone")
    R(f, "Track", 0, 22, w, 14, INK, sw=2)
    sw_ = (w - 4 - 15) / 6.0
    for i in range(6):
        R(f, "Segment %d %s" % (i + 1, ZONES[i][0]), 2 + i * (sw_ + 3), 24, sw_, 10, COL["blue"] if i < cur else COL["empty"], r=2)
    I(f, "p/icon-glove", 22, 2 + (cur - 1) * (sw_ + 3) + sw_ / 2 - 11, 17, name="ImageLabel/Marker (the player)")
    return f


def tag(parent, word="BOUGHT", kind="gold", x=None, y=None):
    """The bought tag: the tier chip's shape in shop gold with ink text."""
    c = row(parent, "Tag/" + word, x, y, None, 22, pad=[0, 8, 0, 8], fill=COL[kind], stroke=INK, strokeWeight=2,
            strokeAlign="outside", cornerRadius=4, sizingH="hug")
    T(c, word, size=14, color=INK if kind in INK_TEXT_ON else WHITE)
    return c


def level_pips(parent, x, y, level, total=20, size=12, gap=3):
    f = F(parent, "LevelPips (%d of %d, cash green)" % (level, total), x, y, total * (size + gap) - gap, size)
    for i in range(total):
        R(f, "Pip %d" % (i + 1), i * (size + gap), 0, size, size, COL["green"] if i < level else COL["empty"], sw=2, r=2)
    return f


def arrow_chip(parent, rot=0, size=28):
    """A square chip holding the generated block arrow; it turns toward the thief or home."""
    f = F(parent, "ArrowChip (turns toward its target)", None, None, size, size)
    R(f, "Chip", 0, 0, size, size, WHITE, sw=2)
    I(f, "i/arrow-white", size - 8, 4, 4, rot=rot)
    return f


def banner(parent, name, x, y, w, kind, ic, text, h=40, size=16, arrow=None):
    """A studded strip in a job colour with an icon, one line, and an optional arrow chip."""
    f = F(parent, name, x, y, w, h)
    R(f, "Plate", 0, 0, w, h, COL[kind], sw=3, studded=True, shadow=4)
    r = row(f, "Content", 0, 0, w, h, gap=8)
    if ic: I(r, ic, h - 8)
    T(r, text, size=size, color=INK if kind in INK_TEXT_ON else WHITE)
    if arrow is not None: arrow_chip(r, arrow)
    return f


def toast(parent, name, x, y, w, kind, ic, text):
    """Toast: a 32 px studded plate, bottom centre. panel = information, orange = cannot, green = purchase done."""
    f = F(parent, name, x, y, w, 32)
    R(f, "Plate", 0, 0, w, 32, COL[kind], sw=3, studded=True, shadow=3)
    r = row(f, "Content", 0, 0, w, 32, gap=6)
    if ic: I(r, ic, 24)
    T(r, text, size=14)
    return f


def prompt(parent, name, x, y, w, glyph, label, hold=None, icon=None, greyed=False):
    """World prompt: a white studded plate, the input glyph on a small ink plate, the word.
    glyph: a key letter (keyboard) or None (touch: the action's icon sits on the ink plate)."""
    f = F(parent, name, x, y, w, 48)
    base = COL["dis"] if greyed else WHITE      # greyed: the disabled look (grey fill, studs stay, short lip)
    R(f, "Lip", 0, 0, w, 48 if not greyed else 45, mul(base, 0.72), sw=3)
    R(f, "Face (%s + stud tile)" % ("disabled grey" if greyed else "white"), 0, 0, w, 43 if not greyed else 41, base, studded=True)
    if hold is not None:
        # the Steal hold: a square frame around the glyph fills clockwise in alarm orange over the hold time
        R(f, "HoldFrame/track", 6, 5, 34, 34, COL["empty"], r=3)
        if hold >= 0.25: R(f, "HoldFrame/top", 6, 5, 34, 6, COL["orange"], r=1)
        if hold >= 0.5: R(f, "HoldFrame/right", 34, 5, 6, 34, COL["orange"], r=1)
        if hold >= 0.75: R(f, "HoldFrame/bottom", 6, 33, 34, 6, COL["orange"], r=1)
    R(f, "GlyphPlate (ink)", 10, 9, 26, 26, INK, r=3)
    if glyph: T(f, glyph, 10, 12, 16, WHITE, w=26, align="center", ol=False)
    elif icon: I(f, icon, 22, 12, 11)
    r = row(f, "Label", 44, 0, w - 50, 43 if not greyed else 41)
    T(r, label, size=16, color="#D5D9DF" if greyed else INK)
    return f
