"""Small drawing helpers for the base-layout plans (FigCraft command script). Same approach as ui-kit/src/kitlib.py
(a list of node.create / image.place commands run by figcraft-cli), written separately so the kit is untouched."""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__)).replace("\\", "/") + "/"
PITCH = HERE.rsplit("/", 3)[0] + "/"
KIT = json.load(open(PITCH + "ui-kit/src/parts.json"))
FONT = "Montserrat"

C = dict(ink="#101820", white="#FFFFFF", paper="#E9ECF3", note="#4A5263",
         grass="#A9D86B", bush="#8FD13B", leaf="#3F8A3F", trunk="#B5563C", flower="#FF7FB6", dirt="#7A4B33",
         lane="#9AA3B2", kerb="#F2F4F7", arrow="#FFD84A", pad="#C9CED8",
         green="#2FB341", green_lip="#22812F", cyan="#35C8F0", gold="#FFC21A", orange="#FF6A00", blue="#1F6FD6",
         red="#E02A2A", dis="#8A919C", dis_text="#D5D9DF", yellow="#FFF36B", panel="#B4BBC6",
         common="#A9B2BD", uncommon="#5DBB2F", rare="#2E8BFF", epic="#9B4DFF", legendary="#FF9F1A", mythic="#FF3D7F")

cmds = []
STUD = None


def add(command, **params):
    name = "n%d" % len(cmds)
    cmds.append({"command": command, "as": name, "params": params})
    return {"$ref": name}


def init_stud():
    global STUD
    r = add("image.place", path=PITCH + "style/stud-ui-overlay-64.png", x=-600, y=-600, width=64, height=64,
            name="SOURCE stud tile (style/stud-ui-overlay-64.png)")
    STUD = {"$ref": r["$ref"], "field": "image"}


def studfill(color, tile):
    return [color, {"type": "image", "image": STUD, "scale_mode": "tile", "scale": tile / 64.0}]


def node(type_, parent, name, x=None, y=None, w=None, h=None, text=None, top=None, **props):
    p = {"type": type_, "name": name, "select": False}
    if top: p.update(top)
    if parent is not None: p["parent"] = parent
    if x is not None: p["x"] = round(x, 2)
    if y is not None: p["y"] = round(y, 2)
    if w is not None: p["width"] = max(0.5, round(w, 2))
    if h is not None: p["height"] = max(0.5, round(h, 2))
    if text is not None: p["text"] = text
    if props: p["props"] = props
    return add("node.create", **p)


def frame(parent, name, x, y, w, h, fill="none", clip=False, **props):
    return node("frame", parent, name, x, y, w, h, fill=fill, clip=clip, **props)


def rect(parent, name, x, y, w, h, fill, stroke=None, sw=0, r=0, stud=None, align="inside", dashes=None, opacity=None):
    props = {}
    if stud: props["fills"] = studfill(fill, stud)
    else: props["fill"] = fill
    if stroke:
        props.update(stroke=stroke, strokeWeight=sw, strokeAlign=align)
        if dashes: props["dashes"] = dashes
    if r: props["cornerRadius"] = r
    if opacity is not None: props["opacity"] = opacity
    return node("rectangle", parent, name, x, y, w, h, **props)


def ellipse(parent, name, x, y, w, h, fill="none", stroke=None, sw=0, dashes=None):
    props = {"fill": fill}
    if stroke:
        props.update(stroke=stroke, strokeWeight=sw, strokeAlign="center")
        if dashes: props["dashes"] = dashes
    return node("ellipse", parent, name, x, y, w, h, **props)


def text(parent, s, x, y, size=14, color=None, weight="Bold", w=None, align="left", name=None, outline=False):
    props = dict(fontFamily=FONT, fontStyle=weight, fontSize=int(round(size)), fill=color or C["ink"])
    if w is not None:
        props.update(textAlign=align, textAutoResize="height")
    if outline:
        props.update(stroke=C["ink"], strokeWeight=2, strokeAlign="outside", strokeJoin="round",
                     effects=[{"type": "dropShadow", "color": C["ink"], "offset": [0, 2], "radius": 0}])
    return node("text", parent, name or ("Label/" + s[:30].replace("\n", " ")), x, y, w, None, text=s, **props)


def poly(parent, name, pts, color, sw=3, dashes=None, closed=False, fill="none"):
    props = dict(stroke=color, strokeWeight=sw, strokeAlign="center", fill=fill, strokeJoin="round", strokeCap="round")
    if dashes: props["dashes"] = dashes
    return node("vector", parent, name, top={"points": [[round(a, 2), round(b, 2)] for a, b in pts], "closed": closed},
                **props)


def arrowhead(parent, tip, frm, color, size=12):
    import math
    ang = math.atan2(tip[1] - frm[1], tip[0] - frm[0])
    a1, a2 = ang + 2.6, ang - 2.6
    pts = [tip, (tip[0] + size * math.cos(a1), tip[1] + size * math.sin(a1)),
           (tip[0] + size * math.cos(a2), tip[1] + size * math.sin(a2))]
    return poly(parent, "Arrowhead", pts, color, sw=1, closed=True, fill=color)


def image(parent, key_or_path, x, y, w, h, name=None):
    path = KIT[key_or_path][0] if key_or_path in KIT else key_or_path
    return add("image.place", parent=parent, path=path, x=round(x, 2), y=round(y, 2), width=round(w, 2),
               height=round(h, 2), name=name or ("Image/" + os.path.basename(path)))


def fit(key, box):
    _, w, h = KIT[key]
    sc = min(box / w, box / h)
    return w * sc, h * sc


def marker(parent, n, cx, cy, d=22, fill=None, color=None):
    f = frame(parent, "Key %s" % n, cx - d / 2, cy - d / 2, d, d)
    ellipse(f, "Dot", 0, 0, d, d, fill=fill or C["ink"], stroke=C["white"], sw=2)
    text(f, str(n), 0, d / 2 - 8, 13 if d < 26 else 15, color or C["white"], "Black", w=d, align="center")
    return f


def dim(parent, x1, y1, x2, y2, label, color=None, size=13, off=0, w=120):
    """A dimension line with end ticks and its label in the middle (horizontal or vertical)."""
    col = color or C["note"]
    poly(parent, "Dim " + label, [(x1, y1), (x2, y2)], col, sw=1.5)
    if y1 == y2:
        for x in (x1, x2): poly(parent, "Tick", [(x, y1 - 5), (x, y1 + 5)], col, sw=1.5)
        text(parent, label, (x1 + x2) / 2 - w / 2, y1 - 19 + off, size, col, "Bold", w=w, align="center")
    else:
        for y in (y1, y2): poly(parent, "Tick", [(x1 - 5, y), (x1 + 5, y)], col, sw=1.5)
        text(parent, label, x1 + 6 + off, (y1 + y2) / 2 - 8, size, col, "Bold")


def board(name, w, h, title, sub=None):
    b = frame(None, name, 0, 0, w, h, fill=C["paper"], clip=True)
    text(b, title, 32, 22, 30, C["ink"], "Black")
    if sub: text(b, sub, 32, 62, 14, C["note"], "Bold", w=w - 64)
    return b


def page(name, index):
    if index == 0: add("page.rename", name=name)
    else:
        add("page.add", name=name)
        add("page.select", index=index)


def dump(path):
    json.dump(cmds, open(path, "w"))
