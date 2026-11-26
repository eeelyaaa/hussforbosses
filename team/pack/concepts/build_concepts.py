"""Builds pitches/huss-for-bosses/concepts/concepts.figcraft: one board per look direction (pitch step 2, 2026-11-25).

Run from the ro-team root:
  python pitches/huss-for-bosses/concepts/build_concepts.py <script.json> pitches/huss-for-bosses/concepts/parts.json
  figcraft-cli run <script.json> --out pitches/huss-for-bosses/concepts/concepts.figcraft
Rebuilding replaces the file, so hand edits made in the FigCraft app are lost.

Round 2 (same day) added directions 4 and 5 to the existing file without touching boards 1 to 3:
  python .../build_concepts.py <script.json> .../parts.json brick-brawl snack-attack
  figcraft-cli run <script.json> --in .../concepts.figcraft --out .../concepts.figcraft
Slugs after parts.json choose which boards the script builds (default: all five). A board's place on the page comes
from its number, so a partial build lands below the boards already there. Directions 4 and 5 also draw the timing
ring and the three-punch pips on the HUD ("ring": True); boards 1 to 3 predate that and are left as approved for review.

Each board holds: palette with jobs, a phone HUD (874 x 402, the manager's phone in landscape), one menu (the boss
upgrade panel), the labelled map and the labelled creature line-up. All pictures are Higgsfield concept images
(gpt_image_2_6; log in higgsfield-log.md); icons are cut from each direction's generated icon sheet, never drawn from
shapes. Every word on a board is real text. Numbers on the HUD and menu are placeholders, not the economy.
"""
import json, sys

C = "C:/Users/elya/Desktop/ro-team/pitches/huss-for-bosses/concepts/"
PARTS = json.load(open(sys.argv[2]))
W, H = 874, 402

cmds = []
def add(command, **params):
    name = "n%d" % len(cmds)
    cmds.append({"command": command, "as": name, "params": params})
    return {"$ref": name}

def node(type_, parent, name, x, y, w=None, h=None, text=None, path=None, **props):
    p = {"type": type_, "name": name, "x": x, "y": y, "select": False}
    if parent is not None: p["parent"] = parent
    if w is not None: p["width"] = w
    if h is not None: p["height"] = h
    if text is not None: p["text"] = text
    if path is not None: p["path"] = path
    if props: p["props"] = props
    return add("node.create", **p)

def frame(parent, name, x, y, w, h, fill="none", **props):
    props.setdefault("clip", False)
    return node("frame", parent, name, x, y, w, h, fill=fill, **props)

def G(a, b, fr=(0.5, 0), to=(0.5, 1)):
    return [{"type": "linearGradient", "stops": [a, b], "from": list(fr), "to": list(to)}]

def HARD(color, dy):
    return [{"type": "dropShadow", "color": color, "offset": [0, dy], "radius": 0}]

# ------------------------------------------------------------------ the directions (1 to 3: round 1; 4 and 5: round 2)
T = {}
T["gym-zoo"] = dict(
    name="GYM ZOO", n=1, mood="Sunny, chunky, sporty",
    line="A toy-box backyard gym in bright daylight. Bosses are buff cartoon animals, each wearing one piece of fight gear.",
    font=("Montserrat", "ExtraBold Italic"), per=0.72, body=("Montserrat", "Bold"), bper=0.62, kind="round", r=10,
    ink="#1B1F3B", text="#FFFFFF", sub="#1B1F3B",
    panel=("#5CCBF8", "#2A9FE6", "#1A6FB3"), inset=None, well="#FFFFFF", dim="#0B1430B3",
    power=("#FF5A4A", "#D92B2B"), cash=("#62D84A", "#2FA63A"), lock=("#5AA2FF", "#2F6FE0"),
    punch=("#FF5A4A", "#D92B2B", "#8E1717"), shop=("#FFD84A", "#FFAE1A", "#B86A00"),
    go=("#6BE04F", "#2FA63A", "#1B6E25"), plain=("#FFFFFF", "#DCE6F2", "#8FA3BD"), close=("#FF6A5A", "#E0332B", "#8E1717"),
    burst="#FFE34D", track="#1B1F3B",
    zones=[("BACKYARD GYM", "Grass, tyres, dumbbells", "#5BD13B"), ("BOARDWALK BEACH", "Sand, palms, umbrellas", "#FFC94A"),
           ("JUNGLE DOJO", "Vines, waterfall, dojo", "#1FA35B"), ("FROST PEAK", "Snow, pines, ice", "#BFE8FF"),
           ("MAGMA FORGE", "Lava, anvils, chains", "#FF6A2B"), ("SKY ARENA", "Clouds, gold, laurels", "#FFD84A")],
    zx=[360, 545, 725, 905, 1085, 1275], bx=145, mapbg="#1B1F3B",
    tiers=[("COMMON", "#9AA7B8"), ("UNCOMMON", "#4CC764"), ("RARE", "#3E8BFF"), ("EPIC", "#A259FF"), ("LEGENDARY", "#FFB020"), ("MYTHIC", "#FF3B6B")],
    creatures=["JAB ROOSTER", "CLAMP CHAMP", "SENSEI SILVERBACK", "BLIZZARD BEAR", "MAGMA BULL", "GOLDEN MANE"],
    cx=[91, 276, 462, 700, 963, 1246], sheetbg=("#8FDCFF", "#3EB6F2"), floor="#2A9FE6",
    hero=(0, "creature-1"),
    palette=[("#3EC1F3", "Sky blue: panels, the world's base colour"), ("#FF3B3B", "Punch red: the Huss button, Power"),
             ("#39B54A", "Go green: cash, upgrade, accept"), ("#FFC928", "Gold: shop, premium, the impact burst"),
             ("#3E8BFF", "Shield blue: the base lock"), ("#FFFFFF", "White: text and wells"),
             ("#1B1F3B", "Navy ink: every outline and hard shadow")])
T["neon-knockout"] = dict(
    name="NEON KNOCKOUT", n=2, mood="Electric, loud, night",
    line="A rain-wet night city in four neon colours. Bosses are boxy robots, each built from one everyday machine with a screen face.",
    font=("Bahnschrift", "Bold"), per=0.6, body=("Bahnschrift", "SemiBold"), bper=0.56, kind="chamfer", r=9,
    ink="#07051A", text="#FFFFFF", sub="#E9E4FF",
    panel=("#4A2BC2", "#2C1A86", "#140B45"), inset="#FF2E9A", well="#1B1147", dim="#05031AC0",
    power=("#3CF0FA", "#0FB5D6"), cash=("#C6FF55", "#7FD41C"), lock=("#3CF0FA", "#0FB5D6"),
    punch=("#FF5CB8", "#E0127F", "#7A0A47"), shop=("#FFCB4D", "#FF9A1F", "#9A5200"),
    go=("#C6FF55", "#7FD41C", "#3F7A08"), plain=("#8F7BFF", "#5B45D6", "#2C1A86"), close=("#FF6672", "#E3263D", "#7A0A1B"),
    burst="#FFE34D", track="#07051A",
    zones=[("ARCADE ALLEY", "Cabinets, tokens, claw games", "#FF2E9A"), ("NIGHT MARKET", "Stalls, lanterns, snacks", "#FFB020"),
           ("SCRAP YARD", "Junk stacks, crane, gears", "#B6FF3C"), ("SUBWAY LINE", "Tracks, platform, train", "#23E6F2"),
           ("LASER FOUNDRY", "Robot arms, sparks, pipes", "#FF7A1F"), ("THE MAINFRAME", "Server tower, halo ring", "#F4F0FF")],
    zx=[345, 520, 700, 880, 1070, 1265], bx=140, mapbg="#140B45",
    tiers=[("COMMON", "#8D8AAE"), ("UNCOMMON", "#8EE22B"), ("RARE", "#1EC8F0"), ("EPIC", "#FF2E9A"), ("LEGENDARY", "#FFB020"), ("MYTHIC", "#F4F0FF")],
    creatures=["COIN-OP", "FIZZ FRIDGE", "SPIN CYCLE", "RED LIGHT", "WELD KING", "HALO SERVER"],
    cx=[102, 298, 500, 704, 941, 1229], sheetbg=("#3A2396", "#150B4A"), floor="#0B0630",
    hero=(2, "creature-3"),
    palette=[("#1B1147", "Night indigo: the world and panel base"), ("#FF2E9A", "Hot magenta: the Huss button, panel trim"),
             ("#23E6F2", "Cyan: Power, the base lock"), ("#B6FF3C", "Lime: cash, upgrade, accept"),
             ("#FFB020", "Amber: shop, premium"), ("#FFFFFF", "White: text"),
             ("#07051A", "Black indigo: every outline and hard shadow")])
T["clay-kaiju"] = dict(
    name="CLAY KAIJU", n=3, mood="Handmade, warm, goofy",
    line="A stop-motion clay diorama in storybook colours. Bosses are round ball-bodied monsters with huge mouths, each made of its zone's element.",
    font=("Montserrat", "Black"), per=0.74, body=("Montserrat", "Bold"), bper=0.62, kind="blob", r=14,
    ink="#4A2C4F", text="#FFF8E8", sub="#4A2C4F",
    panel=("#FFF3DC", "#F6DFB6", "#C98B5E"), inset=None, well="#FFFDF4", dim="#2B1830B3",
    power=("#52C4BA", "#2A968E"), cash=("#FFCB52", "#F0A626"), lock=("#9BD286", "#5E9E4D"),
    punch=("#F58A5F", "#D9562E", "#8E3418"), shop=("#F07BA6", "#C93C72", "#7E1F43"),
    go=("#9BD286", "#5E9E4D", "#3A6B2D"), plain=("#FFFDF4", "#EAD6B4", "#B08A66"), close=("#F0776B", "#D9453F", "#8A2420"),
    burst="#FFF3DC", track="#4A2C4F",
    zones=[("MUSHROOM MEADOW", "Giant red mushrooms, daisies", "#E8663C"), ("HONEY HIVE", "Honeycomb, honey falls", "#F5B83D"),
           ("CORAL COVE", "Teal water, pink coral", "#2FA8A0"), ("CRYSTAL CAVERN", "Blue and violet crystals", "#8B62C9"),
           ("THUNDER PEAKS", "Storm clouds, lightning", "#7C7790"), ("STAR VOID", "Galaxy swirl, star altar", "#6A2FA8")],
    zx=[335, 520, 715, 895, 1075, 1270], bx=125, mapbg="#4A2C4F",
    tiers=[("COMMON", "#B9A58C"), ("UNCOMMON", "#7DB96A"), ("RARE", "#2FA8A0"), ("EPIC", "#8B62C9"), ("LEGENDARY", "#F5B83D"), ("MYTHIC", "#D6457A")],
    creatures=["CAPPER", "HONEYGOB", "CORALUMP", "SHARDLE", "THUNDERPUFF", "NEBULUG"],
    cx=[98, 287, 469, 700, 945, 1232], sheetbg=("#FFF3DC", "#F3D9AA"), floor="#E3BF8A",
    hero=(0, "creature-1"),
    palette=[("#FFF3DC", "Cream: panels, rims, the paper of the world"), ("#E8663C", "Terracotta: the Huss button"),
             ("#2FA8A0", "Teal: Power"), ("#F5B83D", "Honey: cash"),
             ("#7DB96A", "Moss: upgrade, accept, the base lock"), ("#D6457A", "Berry: shop, premium"),
             ("#4A2C4F", "Plum ink: every outline and hard shadow")])

T["brick-brawl"] = dict(
    name="BRICK BRAWL", n=4, mood="Blocky, bright, classic",
    line="A classic studded-brick Roblox world in primary colours, with a blocky avatar. Bosses are voxel creatures built from visible cubes.",
    font=("Arial Black", "Regular"), per=0.74, body=("Arial", "Bold"), bper=0.58, kind="stud", r=4, ring=True,
    ink="#101820", text="#FFFFFF", sub="#101820",
    panel=("#DDE1E7", "#B4BBC6", "#6B7380"), inset=None, well="#FFFFFF", dim="#0A1020B3",
    power=("#FF4B3A", "#D4201C"), cash=("#4BD14B", "#1E9E2E"), lock=("#4D9BFF", "#1F66D6"),
    punch=("#FF4B3A", "#D4201C", "#8A1010"), shop=("#FFDD3C", "#FFB800", "#B37600"),
    go=("#4BD14B", "#1E9E2E", "#12661C"), plain=("#FFFFFF", "#E3E7EC", "#8C95A1"), close=("#FF5A4A", "#D4201C", "#8A1010"),
    burst="#FFE000", track="#101820",
    zones=[("BRICK MEADOW", "Baseplate, block trees", "#2FB341"), ("SAND BLOCKS", "Pyramid, cactus", "#F2C94C"),
           ("PIRATE PLATES", "Water bricks, a ship", "#2A8CE8"), ("ICE BLOCKS", "Snow bricks, crystals", "#BFE8FF"),
           ("LAVA BRICKS", "Volcano, glowing lava", "#FF6A2B"), ("SPACE BASEPLATE", "Rocket, stars", "#3D55D6")],
    zx=[397, 571, 745, 924, 1103, 1293], bx=158, mapbg="#101820",
    tiers=[("COMMON", "#9AA7B8"), ("UNCOMMON", "#4CC764"), ("RARE", "#3E8BFF"), ("EPIC", "#A259FF"), ("LEGENDARY", "#FFB020"), ("MYTHIC", "#FF3B6B")],
    creatures=["CHOMP FROG", "SNAP SCORPION", "BIT SHARK", "FROST BYTE", "EMBER DRAKE", "STAR GOLEM"],
    cx=[80, 238, 404, 609, 849, 1196], sheetbg=("#7FC8FF", "#2F8FEA"), floor="#27A33A", sheety=-34, zonew=150,
    hero=(0, "creature-1"),
    palette=[("#E02A2A", "Brick red: the Huss button, Power"), ("#1F6FD6", "Brick blue: the base lock, frames"),
             ("#FFD21F", "Brick yellow: shop, premium, the timing ring"), ("#2FB341", "Brick green: cash, upgrade, the baseplate"),
             ("#B4BBC6", "Stone grey: panels, the road, pedestals"), ("#FFFFFF", "White: text and wells"),
             ("#101820", "Black: every outline and hard shadow")])
T["snack-attack"] = dict(
    name="SNACK ATTACK", n=5, mood="Flat, loud, tasty",
    line="A flat cartoon snack world with thick chocolate outlines, like a sticker sheet. Bosses are living snacks with angry faces and big gloved fists.",
    font=("Segoe UI", "Black"), per=0.66, body=("Segoe UI", "Bold"), bper=0.58, kind="round", r=16, ring=True, sheen=False,
    ink="#4A1F1A", text="#FFF6E0", sub="#4A1F1A", zonetext="#4A1F1A",
    panel=("#FF6FA5", "#FF6FA5", "#4A1F1A"), inset=None, well="#FFF6E0", dim="#4A1F1AB3",
    power=("#F23B45", "#F23B45"), cash=("#6FD8A0", "#6FD8A0"), lock=("#5AB4F0", "#5AB4F0"),
    punch=("#F23B45", "#F23B45", "#4A1F1A"), shop=("#FFC42E", "#FFC42E", "#4A1F1A"),
    go=("#6FD8A0", "#6FD8A0", "#4A1F1A"), plain=("#FFF6E0", "#FFF6E0", "#4A1F1A"), close=("#F23B45", "#F23B45", "#4A1F1A"),
    burst="#FFC42E", track="#4A1F1A",
    zones=[("BREAKFAST DINER", "Pancakes, fried eggs", "#FFC42E"), ("BURGER DRIVE-IN", "Giant fries, a car", "#F28A2E"),
           ("PIZZA PLAZA", "Slice roofs, umbrellas", "#F23B45"), ("SUSHI DOCK", "Pier, rolls, chopsticks", "#2E8F86"),
           ("CANDY CANYON", "Lollipops, gumdrops", "#FF6FA5"), ("CAKE CASTLE", "Three tiers, candles", "#B57BEA")],
    zx=[383, 563, 723, 891, 1082, 1277], bx=155, mapbg="#4A1F1A",
    tiers=[("COMMON", "#C9B79A"), ("UNCOMMON", "#6FD8A0"), ("RARE", "#5AB4F0"), ("EPIC", "#B57BEA"), ("LEGENDARY", "#FFC42E"), ("MYTHIC", "#F23B45")],
    creatures=["FLAPJACK JACK", "SIR PATTY", "PEPPERONI TONY", "MAKI MAULER", "JAWBREAKER JOE", "KING CAKE"],
    cx=[91, 272, 448, 631, 870, 1204], sheetbg=("#FFF6E0", "#FFE3B8"), floor="#6FD8A0", sheety=-48, zonew=150,
    hero=(0, "creature-1"),
    palette=[("#FFF6E0", "Cream: the sky, wells, text"), ("#F23B45", "Ketchup red: the Huss button, Power"),
             ("#FFC42E", "Mustard: shop, premium, the timing ring"), ("#6FD8A0", "Mint: cash, upgrade, accept"),
             ("#FF6FA5", "Bubblegum: panels, the road's checks"), ("#5AB4F0", "Blueberry: the base lock"),
             ("#4A1F1A", "Chocolate ink: every outline and hard shadow")])

# ------------------------------------------------------------------ pieces
def text(t, parent, s, x, y, size, color=None, w=None, align="left", name=None, ol=None, heavy=True, shadow=True):
    """Game type: heavy, an outside outline in the direction's ink, a hard shadow. heavy=False: the body face, no outline."""
    f = t["font"] if heavy else t["body"]
    p = dict(fontFamily=f[0], fontStyle=f[1], fontSize=size, fill=color or (t["text"] if heavy else t["sub"]))
    if heavy:
        ol = max(2, round(size * 0.1)) if ol is None else ol
        if ol:
            p.update(stroke=t["ink"], strokeWeight=ol, strokeAlign="outside", strokeJoin="round")
            if shadow: p["effects"] = HARD(t["ink"], max(1.5, round(size * 0.08)))
    if w is not None:
        p["textAlign"] = align; p["textAutoResize"] = "height"
    return node("text", parent, name or ("TextLabel/" + s[:28]), x, y, w, None, text=s, **p)

def tw(t, s, size, heavy=True):
    return len(s) * size * (t["per"] if heavy else t["bper"])

def shape(t, parent, name, x, y, w, h, r=None, **props):
    """The direction's one shape: rounded (Gym Zoo), cut corners (Neon Knockout), soft blob (Clay Kaiju),
    square brick with studs on top (Brick Brawl, studs drawn by studs()), flat round sticker (Snack Attack)."""
    r = t["r"] if r is None else r
    props.setdefault("strokeJoin", "round")
    if t["kind"] == "chamfer":
        c = min(r, h * 0.32, w * 0.32)
        d = "M %g 0 L %g 0 L %g %g L %g %g L %g %g L %g %g L 0 %g L 0 %g Z" % (c, w - c, w, c, w, h - c, w - c, h, c, h, h - c, c)
        return node("vector", parent, name, x, y, path=d, **props)
    if t["kind"] == "blob":
        r = min(h / 2, w / 2, r * 1.8)
    return node("rectangle", parent, name, x, y, w, h, cornerRadius=min(r, h / 2, w / 2), **props)

def studs(t, parent, w, color, sw=3):
    """Brick Brawl only: a row of studs along the top edge. Call before the face so the face hides their feet."""
    if t["kind"] != "stud": return
    n = max(1, int((w - 10) // 26)); x0 = (w - (n * 26 - 10)) / 2
    for i in range(n):
        node("rectangle", parent, "Stud", x0 + i * 26, -6, 16, 10, cornerRadius=2, fill=color, stroke=t["ink"], strokeWeight=sw, strokeAlign="outside", strokeJoin="round")

def sheen(t, parent, x, y, w, h, r):
    if t.get("sheen", True):
        shape(t, parent, "Sheen", x, y, w, h, r=r, fill="#FFFFFF4D")

def icon(t, parent, key, x, y, box, name=None, rot=0, shadow=True):
    """A generated icon or creature cut from the direction's sheet, fitted in a box x box square."""
    _, _, mw, mh = PARTS[t["slug"]][key]
    s = min(box / mw, box / mh)
    r = add("image.place", path=C + t["slug"] + "/parts/" + key + ".png", parent=parent, x=x + (box - mw * s) / 2, y=y + (box - mh * s) / 2,
            width=mw * s, height=mh * s, name=name or ("ImageLabel/" + key))
    props = {}
    if rot: props["rotation"] = rot
    if shadow: props["effects"] = HARD(t["ink"] + "99", max(2, box * 0.05))
    if props: add("node.set", ids=[r], props=props)
    return r

def plate(t, parent, name, x, y, w, h, cols, ic, value, size=18):
    """A counter: not pressable, so no lip, only a hard shadow. The icon overhangs the left end."""
    f = frame(parent, name, x, y, w, h)
    studs(t, f, w, cols[0])
    shape(t, f, "Plate", 0, 0, w, h, fills=G(cols[0], cols[1]), stroke=t["ink"], strokeWeight=3, strokeAlign="outside", effects=HARD(t["ink"], 3))
    sheen(t, f, h * 0.5, 3, w - h * 0.75, h * 0.2, 3)
    ib = h * 1.3
    icon(t, f, ic, -ib * 0.3, (h - ib) / 2, ib)
    text(t, f, value, ib * 0.78, (h - size * 1.22) / 2, size, name="TextLabel/Value")
    return f

def btn(t, parent, name, x, y, w, h, cols, label=None, ic=None, size=None, sub=None):
    """Pressable: a darker lip under the face, a sheen on top, a thick outline."""
    lip = max(4, round(h * 0.13)); sw = max(2.5, h * 0.06)
    size = size or round(h * 0.42)
    f = frame(parent, name, x, y, w, h + lip)
    shape(t, f, "Lip", 0, lip, w, h, fill=cols[2], stroke=t["ink"], strokeWeight=sw, strokeAlign="outside")
    studs(t, f, w, cols[0], sw)
    shape(t, f, "Face", 0, 0, w, h, fills=G(cols[0], cols[1]), stroke=t["ink"], strokeWeight=sw, strokeAlign="outside")
    sheen(t, f, h * 0.3, h * 0.1, w - h * 0.6, h * 0.16, 4)
    if label and ic:
        ib = h * 0.78; lw = tw(t, label, size); x0 = (w - (ib + 6 + lw)) / 2
        icon(t, f, ic, x0, (h - ib) / 2, ib)
        text(t, f, label, x0 + ib + 6, (h - size * 1.22) / 2, size, name="TextLabel/Label")
    elif label:
        text(t, f, label, 0, (h - size * 1.22) / 2, size, w=w, align="center", name="TextLabel/Label")
    elif ic:
        ib = h * 0.8
        icon(t, f, ic, (w - ib) / 2, (h - ib) / 2, ib)
    return f

def scene_root(t, parent, name, x, y, dim=None):
    root = frame(parent, name, x, y, W, H, fill=t["ink"], clip=True)
    add("image.place", path=C + t["slug"] + "/scene.png", parent=root, x=0, y=0, width=W, height=H, name="CONCEPT scene (generated, not the game)")
    if dim:
        node("rectangle", root, "Dim behind the panel", 0, 0, W, H, fill=dim)
    return root

def ghost(parent, name, x, y, d):
    node("ellipse", parent, "REFERENCE " + name, x, y, d, d, fill="#00000040", stroke="#FFFFFF66", strokeWeight=2, strokeAlign="inside")

def hud(t, parent, x, y):
    r = scene_root(t, parent, "HUD / phone landscape 874x402", x, y)
    # Roblox's own pieces, drawn only to keep clear of them
    for i in range(2):
        node("rectangle", r, "REFERENCE Roblox top bar button", 14 + i * 44, 8, 36, 36, cornerRadius=10, fill="#00000066")
    ghost(r, "thumbstick (Roblox)", 34, 262, 110)
    ghost(r, "jump button (Roblox)", 772, 296, 80)
    # counters
    plate(t, r, "Power (counter, ticks up on every punch)", 118, 9, 122, 34, t["power"], "icon-power", "1,250")
    plate(t, r, "Cash (counter, counts up when bosses pay)", 262, 9, 132, 34, t["cash"], "icon-cash", "$48.2K")
    # zone progress: label, then a track with a pip per zone and the player's marker
    zf = frame(r, "ZoneProgress (how far down the lane; pips fill as zones are reached)", 420, 4, 292, 50)
    zn = t["zones"][0][0]
    text(t, zf, "ZONE 1  " + zn, 0, 0, 15, w=292, align="center", name="TextLabel/Zone")
    shape(t, zf, "Track", 0, 26, 292, 16, r=6, fill=t["track"], stroke=t["ink"], strokeWeight=3, strokeAlign="outside")
    for i in range(6):
        px = 4 + i * 48
        shape(t, zf, "Pip %d %s" % (i + 1, t["zones"][i][0]), px, 29, 44, 10, r=4, fill=t["zones"][i][2] if i == 0 else "#FFFFFF33")
    icon(t, zf, "icon-glove", 14, 20, 28, name="ImageLabel/Marker (the player, slides along the track)")
    # base lock
    plate(t, r, "BaseLock (timer; the shield over the base while it counts down)", 748, 9, 112, 34, t["lock"], "icon-lock", "0:42")
    # shop
    sb = btn(t, r, "Shop (ImageButton, opens the shop)", 14, 112, 60, 56, t["shop"], ic="icon-shop")
    text(t, r, "SHOP", 4, 176, 15, w=80, align="center", name="TextLabel/Shop")
    # the punch button: the one hero of the HUD
    pf = frame(r, "Punch (ImageButton: HUSS! at the bag; the biggest thing on screen)", 640, 186, 108, 120)
    node("star", pf, "Burst (pops on every punch)", -16, -16, 140, 140, fill=t["burst"], stroke=t["ink"], strokeWeight=3, strokeAlign="outside",
         strokeJoin="round", pointCount=14, innerRadius=0.78)
    node("ellipse", pf, "Lip", 6, 14, 96, 96, fill=t["punch"][2], stroke=t["ink"], strokeWeight=4, strokeAlign="outside")
    node("ellipse", pf, "Face", 6, 6, 96, 96, fills=G(t["punch"][0], t["punch"][1]), stroke=t["ink"], strokeWeight=4, strokeAlign="outside")
    if t.get("sheen", True):
        node("ellipse", pf, "Sheen", 26, 12, 56, 16, fill="#FFFFFF4D")
    icon(t, pf, "icon-glove", 22, 14, 64, rot=8)
    if t.get("ring"):
        # the timing ring (bag and fights): the white ring closes on the button; press when it meets the yellow band
        node("ellipse", pf, "TimingRing/Target edge (press when the ring lands here)", 0, 0, 108, 108, fill="none", stroke=t["ink"], strokeWeight=10, strokeAlign="center")
        node("ellipse", pf, "TimingRing/Target (yellow band)", 0, 0, 108, 108, fill="none", stroke=t["burst"], strokeWeight=5, strokeAlign="center")
        node("ellipse", pf, "TimingRing/Closing edge", -24, -24, 156, 156, fill="none", stroke=t["ink"], strokeWeight=9, strokeAlign="center")
        node("ellipse", pf, "TimingRing/Closing (shrinks onto the target, then resets)", -24, -24, 156, 156, fill="none", stroke="#FFFFFF", strokeWeight=4, strokeAlign="center")
        # punches come in threes: huss, huss, huss
        for i in range(3):
            shape(t, pf, "Combo pip %d of 3 (huss huss huss)" % (i + 1), 9 + i * 32, -50, 26, 14, r=5, fill=t["burst"] if i < 2 else t["well"],
                  stroke=t["ink"], strokeWeight=3, strokeAlign="outside")
    text(t, pf, "HUSS!", -16, 84, 22, w=140, align="center", name="TextLabel/Huss")
    return r

def menu(t, parent, x, y):
    r = scene_root(t, parent, "MENU / Boss upgrade / phone landscape 874x402", x, y, dim=t["dim"])
    hi, hkey = t["hero"]
    tier, tcol = t["tiers"][hi]
    px, py, pw, ph = 137, 40, 600, 338
    p = frame(r, "Panel/BossUpgrade", px, py, pw, ph)
    shape(t, p, "Lip", 0, 8, pw, ph, r=t["r"] * 1.6, fill=t["panel"][2], stroke=t["ink"], strokeWeight=4, strokeAlign="outside")
    studs(t, p, pw, t["panel"][0], 4)
    shape(t, p, "Body", 0, 0, pw, ph, r=t["r"] * 1.6, fills=G(t["panel"][0], t["panel"][1]), stroke=t["ink"], strokeWeight=4, strokeAlign="outside")
    if t["inset"]:
        shape(t, p, "Trim", 6, 6, pw - 12, ph - 12, r=t["r"] * 1.2, fill="none", stroke=t["inset"], strokeWeight=3, strokeAlign="inside")
    text(t, p, "BOSS UPGRADE", 22, 9, 28, name="TextLabel/Title")
    btn(t, p, "Close (TextButton, red = close)", pw - 70, 6, 52, 44, t["close"], label="X", size=22)
    # the boss card: filled with its rarity colour, the real creature large and tilted
    cw, ch = 214, 264
    cf = frame(p, "BossCard (filled with the rarity colour)", 22, 56, cw, ch)
    shape(t, cf, "Fill", 0, 0, cw, ch, fills=G(tcol, tcol + "CC"), stroke=t["ink"], strokeWeight=4, strokeAlign="outside", effects=HARD(t["ink"], 5))
    clipf = frame(cf, "BurstClip", 0, 0, cw, ch, clip=True, cornerRadius=t["r"])
    node("star", clipf, "Burst (turns slowly)", -70, -60, 354, 354, fill="#FFFFFF38", pointCount=12, innerRadius=0.42)
    icon(t, cf, hkey, 12, 8, 190, name="ImageLabel/Boss (the real model's render in the build)", rot=4)
    tl = frame(cf, "RarityPlate", 37, ch - 50, 140, 34)
    shape(t, tl, "Plate", 0, 0, 140, 34, fill=t["ink"], stroke="#FFFFFF", strokeWeight=3, strokeAlign="outside")
    text(t, tl, tier, 0, (34 - 18 * 1.22) / 2, 18, color=tcol, w=140, align="center", ol=0, name="TextLabel/Rarity")
    # the right column
    cx0 = 256; cwid = pw - cx0 - 22
    text(t, p, t["creatures"][hi], cx0, 52, 26, name="TextLabel/BossName")
    text(t, p, "ZONE %d  %s" % (hi + 1, t["zones"][hi][0]), cx0, 86, 14, heavy=False, color=t["sub"], name="TextLabel/Zone")
    # level row
    text(t, p, "LEVEL 3", cx0, 108, 18, name="TextLabel/Level")
    for i in range(5):
        shape(t, p, "LevelPip %d" % (i + 1), cx0 + 118 + i * 38, 112, 32, 16, r=5, fill=t["go"][0] if i < 3 else t["well"],
              stroke=t["ink"], strokeWeight=3, strokeAlign="outside")
    # what the upgrade does: now -> next
    sf = frame(p, "Earnings (now, and after the upgrade)", cx0, 140, cwid, 60)
    shape(t, sf, "Well", 0, 0, cwid, 60, fill=t["well"], stroke=t["ink"], strokeWeight=3, strokeAlign="outside")
    icon(t, sf, "icon-cash", 8, 7, 46)
    wc = t["ink"] if t["well"] != "#1B1147" else "#E9E4FF"
    text(t, sf, "EARNS", 62, 6, 14, heavy=False, color=wc, name="TextLabel/Earns")
    text(t, sf, "$120/s", 62, 24, 24, name="TextLabel/Now")
    icon(t, sf, "icon-up", 172, 12, 36, name="ImageLabel/Up")
    text(t, sf, "$180/s", 214, 12, 30, color=t["go"][0], name="TextLabel/Next")
    # the one main button: the price is on it
    bw = cwid
    b = btn(t, p, "Upgrade (TextButton, green = spend cash; the price is on the button)", cx0, 212, bw, 54, t["go"])
    lw = tw(t, "UPGRADE", 22)
    text(t, b, "UPGRADE", 18, (54 - 22 * 1.22) / 2, 22, name="TextLabel/Label")
    pwid = tw(t, "$2,500", 24)
    icon(t, b, "icon-cash", bw - pwid - 66, 7, 40)
    text(t, b, "$2,500", bw - pwid - 20, (54 - 24 * 1.22) / 2, 24, name="TextLabel/Price")
    btn(t, p, "PickUp (TextButton, plain = everything else)", cx0, 282, 170, 44, t["plain"], label="PICK UP", size=18)
    return r

def map_frame(t, parent, x, y):
    FW, IH, LH = 1400, 600, 120
    r = frame(parent, "MAP / bases and six zones", x, y, FW, IH + LH, fill=t["mapbg"], clip=True)
    add("image.place", path=C + t["slug"] + "/map-raw.png", parent=r, x=0, y=0, width=FW, height=IH, name="CONCEPT map (generated, no lettering)")
    text(t, r, "THE LANE: BASES, THEN SIX ZONES", 28, 16, 30, name="TextLabel/Title")
    text(t, r, "FURTHER = STRONGER BOSSES, HIGHER TIERS, MORE CASH", FW - 28 - 660, 22, 18, w=660, align="right", name="TextLabel/Rule")
    node("rectangle", r, "Legend strip", 0, IH, FW, LH, fill=t["mapbg"])
    node("rectangle", r, "Legend edge", 0, IH - 3, FW, 6, fill=t["ink"] if t["mapbg"] != t["ink"] else "#FFFFFF")
    def col(cx, num, title, sub, colr):
        cw = 172
        f = frame(r, "Legend/" + title, cx - cw / 2, IH + 10, cw, 100)
        node("ellipse", f, "Badge", cw / 2 - 17, 0, 34, 34, fill=colr, stroke="#FFFFFF", strokeWeight=3, strokeAlign="outside")
        text(t, f, num, cw / 2 - 17, (34 - 18 * 1.22) / 2, 18, w=34, align="center", name="TextLabel/Number")
        text(t, f, title, -8, 42, 14, w=cw + 16, align="center", name="TextLabel/Name", shadow=False)
        node("text", f, "TextLabel/Theme", 0, 66, cw, None, text=sub, fontFamily=t["body"][0], fontStyle=t["body"][1], fontSize=13,
             fill="#FFFFFFD9", textAlign="center", textAutoResize="height")
    col(t["bx"], "B", "BASES", "Bag, boss spots, lock", "#FFFFFF")
    for i, (zn, zs, zc) in enumerate(t["zones"]):
        col(t["zx"][i], str(i + 1), zn, zs, zc)
    return r

def creatures_frame(t, parent, x, y):
    FW, FH = 1400, 760
    r = frame(parent, "CREATURES / one per zone", x, y, FW, FH, fills=G(t["sheetbg"][0], t["sheetbg"][1]), clip=True)
    node("rectangle", r, "Floor", 0, 596, FW, FH - 596, fill=t["floor"])
    node("rectangle", r, "Floor edge", 0, 593, FW, 6, fill=t["ink"])
    add("image.place", path=C + t["slug"] + "/creatures-raw.png", parent=r, x=0, y=t.get("sheety", 20), width=FW, height=FW * 1520 / 2688, name="CONCEPT creatures (generated)")
    text(t, r, "BOSS LINE-UP: ONE PER ZONE (6 OF ABOUT 36)", 28, 16, 30, name="TextLabel/Title")
    for i in range(6):
        cw = 180; cx = t["cx"][i]
        f = frame(r, "Label/" + t["creatures"][i], cx - cw / 2, 622, cw, 130)
        text(t, f, t["creatures"][i], -10, 0, 15, w=cw + 20, align="center", name="TextLabel/Name")
        tier, tcol = t["tiers"][i]
        shape(t, f, "TierPlate", 20, 50, cw - 40, 28, r=7, fill=tcol, stroke=t["ink"], strokeWeight=3, strokeAlign="outside", effects=HARD(t["ink"], 3))
        text(t, f, tier, 20, 50 + (28 - 15 * 1.22) / 2, 15, w=cw - 40, align="center", name="TextLabel/Tier")
        zw = t.get("zonew", cw + 20)
        node("text", f, "TextLabel/Zone", (cw - zw) / 2, 90, zw, None, text="ZONE %d  %s" % (i + 1, t["zones"][i][0]), fontFamily=t["body"][0],
             fontStyle=t["body"][1], fontSize=13, fill=t.get("zonetext", "#FFFFFF" if t["slug"] != "clay-kaiju" else t["ink"]), textAlign="center", textAutoResize="height")
    return r

# ------------------------------------------------------------------ boards (one per direction, stacked; nothing overlaps)
BW, BH, GAPY = 2980, 1740, 200
INK, PAPER = "#14161F", "#F4F5F8"
def cap(parent, s, x, y):
    node("text", parent, "Caption/" + s[:30], x, y, None, None, text=s, fontFamily="Montserrat", fontStyle="Bold", fontSize=18, fill="#5A6072")

for slug in (sys.argv[3:] or ["gym-zoo", "neon-knockout", "clay-kaiju", "brick-brawl", "snack-attack"]):
    t = T[slug]; t["slug"] = slug
    b = frame(None, "BOARD %d / %s" % (t["n"], t["name"]), 0, (t["n"] - 1) * (BH + GAPY), BW, BH, fill=PAPER, clip=True)
    node("text", b, "Title", 60, 36, None, None, text="DIRECTION %d  %s" % (t["n"], t["name"]), fontFamily="Montserrat", fontStyle="ExtraBold", fontSize=64, fill=INK)
    node("text", b, "Mood", 60, 122, None, None, text=t["mood"].upper(), fontFamily="Montserrat", fontStyle="Bold", fontSize=24, fill="#5A6072")
    node("text", b, "Line", 60, 160, 1040, None, text=t["line"], fontFamily="Montserrat", fontStyle="Medium", fontSize=18, fill=INK, textAutoResize="height")
    for i, (hx, job) in enumerate(t["palette"]):
        sx = 1180 + i * 252
        node("rectangle", b, "Swatch " + hx, sx, 40, 232, 84, cornerRadius=12, fill=hx, stroke=INK, strokeWeight=3, strokeAlign="inside")
        node("text", b, "Hex " + hx, sx, 132, None, None, text=hx, fontFamily="Montserrat", fontStyle="ExtraBold", fontSize=18, fill=INK)
        node("text", b, "Job " + hx, sx, 158, 232, None, text=job, fontFamily="Montserrat", fontStyle="Medium", fontSize=15, fill="#5A6072", textAutoResize="height")
    y1 = 280
    cap(b, "HUD, PHONE LANDSCAPE 874 x 402 (numbers are placeholders)", 60, y1 - 30)
    hud(t, b, 60, y1)
    cap(b, "MENU: BOSS UPGRADE, SAME PHONE", 994, y1 - 30)
    menu(t, b, 994, y1)
    cap(b, "KEY ART (generated concept)", 1928, y1 - 30)
    kf = frame(b, "KEY ART (generated concept)", 1928, y1, 992, 558, clip=True, cornerRadius=8)
    add("image.place", path=C + slug + "/key-art.png", parent=kf, x=0, y=0, width=992, height=558, name="CONCEPT key art")
    cap(b, "TYPE AND BUTTONS: one meaning per colour", 60, y1 + 432)
    kit = frame(b, "KIT sample", 60, y1 + 462, 1808, 96, fill=t["panel"][1], cornerRadius=8, clip=True)
    kx = 20
    for lab, cols, ic in [("HUSS!", t["punch"], "icon-glove"), ("UPGRADE", t["go"], "icon-up"), ("SHOP", t["shop"], "icon-shop"),
                          ("REBIRTH", t["plain"], "icon-rebirth"), ("SPIN", t["shop"], "icon-spin"), ("CLOSE", t["close"], None)]:
        bw_ = 250 if ic else 170
        btn(t, kit, "Sample/" + lab, kx, 18, bw_, 50, cols, label=lab, ic=ic, size=22)
        kx += bw_ + 24
    icon(t, kit, "icon-gem", kx + 10, 18, 60)
    icon(t, kit, "icon-lock", kx + 84, 18, 60)
    icon(t, kit, "icon-power", kx + 158, 18, 60)
    y2 = y1 + 558 + 80
    cap(b, "MAP: labels are real text over a generated picture", 60, y2 - 30)
    map_frame(t, b, 60, y2)
    cap(b, "BOSSES: names and tiers are placeholders for the game-designer", 1520, y2 - 30)
    creatures_frame(t, b, 1520, y2)

json.dump(cmds, open(sys.argv[1], "w"))
print(len(cmds), "commands")
