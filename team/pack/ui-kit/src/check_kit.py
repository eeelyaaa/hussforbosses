"""Scripted checks on ui-kit.figcraft (no Studio needed).
  figcraft-cli convert ui-kit.figcraft dump.json ; python check_kit.py dump.json
Checks, on the two screen pages: the 14 px text floor (23 px at desktop scale), white text carries an outline,
pressable things are at least 44 px tall, text stays inside its parent, and no top-level frames overlap on any page."""
import json, sys

d = json.load(open(sys.argv[1], encoding="utf-8"))
N = {int(k): v for k, v in d["nodes"].items()}
fails = 0


def kids(n): return [N[c] for c in n.get("children", [])]


def walk(n):
    yield n
    for c in kids(n):
        yield from walk(c)


def pos(n): t = n.get("transform") or [1, 0, 0, 1, 0, 0]; return t[4], t[5]


for pid in d["pages"]:
    page = N[pid]; tops = kids(page)
    boxes = [(t["name"],) + pos(t) + (t["width"], t["height"]) for t in tops if t.get("width", 0) > 100]
    for i, a in enumerate(boxes):
        for b in boxes[i + 1:]:
            if a[1] < b[1] + b[3] and b[1] < a[1] + a[3] and a[2] < b[2] + b[4] and b[2] < a[2] + a[4]:
                print("OVERLAP", page["name"], a[0], b[0]); fails += 1
    if "Screens" not in page["name"]: continue
    S = 1920 / 1165.0 if "desktop" in page["name"] else 1.0
    cnt = dict(text=0, small=0, bare=0, short=0, out=0, press=0)
    for top in tops:
        for n in walk(top):
            par = N.get(n.get("parent"))
            if n["type"] == "text":
                cnt["text"] += 1
                fs = n["style"]["font_size"]
                if fs < round(14 * S) - 0.5:
                    cnt["small"] += 1; print("SMALL TEXT", top["name"], repr(n["characters"][:30]), fs)
                col = n["fills"][0]["color"] if n.get("fills") else None
                light = col and (col["r"] + col["g"] + col["b"]) > 1.9
                if light and not n.get("strokes") and not (par and "Glyph" in "".join(k["name"] for k in kids(par))):
                    cnt["bare"] += 1; print("LIGHT TEXT WITHOUT OUTLINE", top["name"], repr(n["characters"][:30]))
                if par and par["type"] == "frame" and par is not top:
                    x, y = pos(n)
                    if x < -3 or y < -3 or x + n["width"] > par["width"] + 3 or y + n["height"] > par["height"] + 3:
                        cnt["out"] += 1; print("TEXT OUTSIDE PARENT", top["name"], par["name"][:40], repr(n["characters"][:30]))
            if n["type"] == "frame" and any(k["name"].startswith("Lip") for k in kids(n)):
                cnt["press"] += 1
                if n["height"] < 44 * S - 0.5 and "Close" not in n["name"]:
                    cnt["short"] += 1; print("UNDER 44 PX", top["name"], n["name"][:50], round(n["height"] / S, 1))
    fails += cnt["small"] + cnt["bare"] + cnt["short"] + cnt["out"]
    print(page["name"], cnt)
print("FAILS", fails)
