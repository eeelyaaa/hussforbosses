"""Builds pitches/huss-for-bosses/base-layout/base-layout.figcraft: four boards, one per page.

  python build_plans.py <script.json>
  figcraft-cli run <script.json> --out ../base-layout.figcraft
  (export.sh writes 01-base-area-plan.png ... 04-steal-route.png)

Every number comes from layout.py, so the plans and base-layout.md cannot drift apart.
"""
import sys, math
import layout as L
from figlib import *

TIERC = [C["common"], C["uncommon"], C["rare"], C["epic"], C["legendary"], C["mythic"]]
TIERW = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"]
# occupancy used for drawings: spot number -> tier index (None = empty)
DEMO10 = {1: 0, 2: 0, 3: 1, 4: 0, 5: 2, 6: 1, 7: 3, 8: None, 9: 0, 10: None}
DEMO17 = {1: 0, 2: 1, 3: 2, 4: 0, 5: 3, 6: 1, 7: 2, 8: 4, 9: 0, 10: 1, 11: 3, 12: 2, 13: 5, 14: 4, 15: 3, 16: 2, 17: 1}


class View:
    """Maps world (s, l) to board pixels. flip: l grows upward on the board."""
    def __init__(self, ox, oy, k, s0, l0):
        self.ox, self.oy, self.k, self.s0, self.l0 = ox, oy, k, s0, l0

    def p(self, s, l):
        return self.ox + (s - self.s0) * self.k, self.oy + (l - self.l0) * self.k

    def box(self, s1, l1, s2, l2):
        (x1, y1), (x2, y2) = self.p(s1, l1), self.p(s2, l2)
        return min(x1, x2), min(y1, y2), abs(x2 - x1), abs(y2 - y1)


def local_box(n, x, y, w, d):
    a = L.to_world(n, x, y); b = L.to_world(n, x + w, y + d)
    return a[0], a[1], b[0], b[1]


def R(parent, v, n, x, y, w, d, fill, name, **kw):
    bx = v.box(*local_box(n, x, y, w, d))
    return rect(parent, name, *bx, fill, **kw)


def draw_plot(parent, v, n, spots=10, occ=None, ghosts=True, labels=True, detail=True, keys=False):
    k = v.k
    occ = occ or {}
    # driveway across the apron
    R(parent, v, n, 19, -L.APRON, 12, L.APRON, C["lane"], "Driveway (lane grey)")
    # ground with fence (kerb white)
    R(parent, v, n, 0, 0, 50, 92, C["grass"], "Plot %d ground (Brick Meadow grass)" % n)
    fw = max(1.0, k * 1.0)
    for (x, y, w, d) in [(0, 0, 1, 92), (49, 0, 1, 92), (0, 91, 50, 1), (0, 0, 19, 1), (31, 0, 19, 1)]:
        R(parent, v, n, x, y, w, d, C["kerb"], "Fence (kerb white, 3 tall, blocker to 10)", stroke=C["dis"], sw=1)
    # aisle tint (nothing built there; drawn so the walkway reads)
    # front yard pieces
    R(parent, v, n, 2, 3, 6, 6, C["gold"], "Delivery crate 6x6x6", stroke=C["ink"], sw=1)
    R(parent, v, n, 11, 3, 6, 6, C["cyan"], "Lock pad 6x6", stroke=C["white"], sw=max(1, k * 0.6))
    R(parent, v, n, 9, 3, 1, 6, C["blue"], "Lock board (owner's buy buttons)")
    if detail:
        R(parent, v, n, 2, 11, 6, 1, C["orange"], "Spots-full sign (only when full)")
    R(parent, v, n, 35, 3, 8, 8, C["kerb"], "Bag pad 8x8", stroke=C["red"], sw=max(1, k * 0.9))
    R(parent, v, n, 43, 4, 6, 6, C["pad"], "Bag plinth 6x6", stroke=C["note"], sw=1)
    R(parent, v, n, 44, 5, 4, 4, C["red"], "Punching bag (tier 1)", stroke=C["ink"], sw=1)
    R(parent, v, n, 44, 12, 1, 5, C["blue"], "Bag sign")
    R(parent, v, n, 17, 0, 16, 1, C["blue"], "Name board over the entrance")
    # spawn
    sx, sy = v.p(*L.to_world(n, *L.SPAWN_C))
    d = max(8, 4 * k)
    ellipse(parent, "Spawn (faces the bag)", sx - d / 2, sy - d / 2, d, d, fill=C["yellow"], stroke=C["ink"], sw=2)
    if k >= 5:
        text(parent, "S", sx - d / 2, sy - 8, 13 if k < 7 else 15, C["ink"], "Black", w=d, align="center")
    # spots and cash pads
    for num in range(1, 18):
        cell, sp, cash, face = L.SPOTS[num]
        unlocked = num <= spots or (spots > 10 and num <= spots)
        if num > spots:
            if ghosts and num <= 15:
                R(parent, v, n, *sp, C["grass"], "Ghost spot %d (%s)" % (num, L.UNLOCK[num]), stroke=C["dis"], sw=max(1, k * 0.35),
                  dashes=[max(3, k), max(3, k)])
            continue
        t = occ.get(num)
        rim = C["white"] if t is None else TIERC[t]
        R(parent, v, n, *sp, C["pad"], "Spot %d %s" % (num, cell), stroke=rim, sw=max(1, k * 0.9))
        R(parent, v, n, *cash, C["green"] if t is not None else C["green_lip"], "Cash pad %d" % num)
        if labels and k >= 5:
            bx = v.box(*local_box(n, *sp))
            text(parent, str(num), bx[0], bx[1] + bx[3] / 2 - (10 if k >= 7 else 8), 16 if k >= 7 else 12, C["ink"], "Black", w=bx[2], align="center")
    return


def scale_bar(parent, x, y, k, studs, label=None):
    rect(parent, "Scale bar", x, y, studs * k, 6, C["ink"])
    for i in range(0, studs + 1, 10):
        rect(parent, "Tick", x + i * k - 1, y - 4, 2, 14, C["ink"])
    text(parent, label or ("%d studs" % studs), x, y + 12, 13, C["note"], "Bold")


def legend_row(parent, x, y, fill, label, stroke=None, kind="rect", w=380):
    if kind == "rect": rect(parent, "Swatch", x, y + 2, 22, 16, fill, stroke=stroke or C["ink"], sw=2 if stroke else 1)
    elif kind == "dot": ellipse(parent, "Swatch", x + 3, y + 1, 16, 16, fill=fill, stroke=C["ink"], sw=2)
    elif kind == "line": poly(parent, "Swatch", [(x, y + 10), (x + 22, y + 10)], fill, sw=4)
    elif kind == "dash": poly(parent, "Swatch", [(x, y + 10), (x + 22, y + 10)], fill, sw=3, dashes=[5, 4])
    return text(parent, label, x + 32, y, 14, C["ink"], "Bold", w=w)


# ======================================================================================= board 1: the base area
def hub_ground(d, v, y_end=350):
    """Hub walls, yard, track, gate and the start of zone 1, in hub coordinates (X, Y)."""
    rect(d, "Zone 1 ground (Brick Meadow)", *v.box(-30, 236, 442, y_end), C["bush"])
    rect(d, "Hub yard (Brick Meadow grass)", *v.box(0, 0, 412, 234), C["grass"])
    # walls: back and sides 16 tall, front 4 tall with the gate opening
    for bx in [(-2, -2, 414, 0), (-2, 0, 0, 236), (412, 0, 414, 236)]:
        rect(d, "Hub wall 16 tall (trunk-and-brick #B5563C, studs)", *v.box(*bx), C["trunk"], stroke=C["ink"], sw=1)
    for bx in [(-2, 234, 188, 236), (224, 234, 414, 236)]:
        rect(d, "Front wall 4 tall", *v.box(*bx), C["trunk"], opacity=0.6, stroke=C["ink"], sw=1)
    # lane: starts in the hub as the track and runs out through the gate
    rect(d, "Track / lane (36 wide)", *v.box(188, L.TRACK_Y0, 224, y_end), C["lane"])
    rect(d, "Kerb", *v.box(187, L.TRACK_Y0, 188, y_end), C["kerb"]); rect(d, "Kerb", *v.box(224, L.TRACK_Y0, 225, y_end), C["kerb"])
    rect(d, "Start line (kerb white, 2 deep)", *v.box(188, L.START_LINE_Y, 224, L.START_LINE_Y + 2), C["kerb"])
    for y in (130, 170, 210, 266, 306, 346):
        x, yy = v.p(206, y)
        poly(d, "Lane arrow (arrow yellow plates)", [(x - 14 * v.k / 4, yy - 10 * v.k / 4), (x, yy + 10 * v.k / 4), (x + 14 * v.k / 4, yy - 10 * v.k / 4)], C["arrow"], sw=max(3, v.k * 1.4))
    for i, y in enumerate(range(236, 261, 2)):
        rect(d, "Hazard stripe (Rolling Log run)", *v.box(188, y, 224, y + 2), C["orange"] if i % 2 == 0 else C["ink"])
    for gx in (184, 224):
        rect(d, "Gate pillar 4x4x16", *v.box(gx, 232, gx + 4, 236), C["bush"], stroke=C["ink"], sw=2)
    for (x, y), fixed in [(L.FIXED_PAD, True)] + [(p, False) for p in L.ROLL_PADS]:
        if y + 6 > y_end: continue
        rect(d, "Boss pad 12x12", *v.box(x - 6, y - 6, x + 6, y + 6), C["pad"], stroke=C["kerb"], sw=max(2, v.k))
        if fixed:
            for dx, dy in ((-6, -6), (4, -6), (-6, 4), (4, 4)):
                rect(d, "Corner post", *v.box(x + dx, y + dy, x + dx + 2, y + dy + 2), C["trunk"])
    # corner scenery: round block trees, bushes, flowers
    for (x, y) in [(20, 20), (60, 30), (30, 66), (72, 72), (392, 20), (352, 30), (382, 66), (340, 72),
                   (30, 222), (70, 220), (382, 222), (342, 220), (150, 222), (262, 222)]:
        rect(d, "Round block tree / bush (scenery)", *v.box(x - 4, y - 4, x + 4, y + 4), C["leaf"])
        rect(d, "Flower", *v.box(x + 5, y + 2, x + 7, y + 4), C["flower"])


def board1():
    W, H = 1940, 1240
    b = board("01 Base area plan", W, H, "BASE AREA PLAN: the walled hub, 8 plots, the yard, the track and zone 1's gate",
              "Top-down, to scale (3 px = 1 stud). The manager's general layout (refs 15-17): plots stand along the walls facing one open yard, "
              "and the lane leaves through a named gate. Our twist: an outdoor stud boxing gym. Eight plots in a U, each with its bag at the front by the entrance, "
              "and the lane starts in the yard as a running track with a start line.")
    k = 3.0
    v = View(60, 150, k, -12, -12)
    d = frame(b, "Plan (clipped)", 0, 0, 1380, H)
    hub_ground(d, v, y_end=345)
    for n in range(1, 9):
        draw_plot(d, v, n, spots=10, occ=DEMO10, ghosts=True, labels=False, detail=False)
        x, y = v.p(*L.to_world(n, 25, 52))
        order = L.FILL_ORDER.index(n) + 1
        text(d, "PLOT %d" % n, x - 60, y - 22, 20, C["ink"], "Black", w=120, align="center")
        text(d, "fills %s" % ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"][order - 1], x - 60, y + 2, 13, C["note"], "Bold", w=120, align="center")
    # fallback spawn in the yard
    x, y = v.p(206, 160)
    ellipse(d, "Fallback spawn", x - 7, y - 7, 14, 14, fill=C["white"], stroke=C["ink"], sw=2)
    text(d, "fallback spawn", x + 10, y - 8, 12, C["ink"], "Bold")
    # sight lines over the low front wall
    for n in (3, 6, 1):
        a = v.p(*L.to_world(n, *L.BAG_PAD_C)); z = v.p(*L.FIXED_PAD)
        poly(d, "Sight line bag -> zone 1 fixed pad", [a, z], C["blue"], sw=2, dashes=[8, 6])
    # labels
    gx, gy = v.p(206, 236)
    f = frame(d, "Gate sign label", gx - 120, gy + 34, 240, 10)
    text(d, "ZONE 1 GATE: arch 16 tall; sign \"1 BRICK MEADOW\" and \"BOSSES FROM 25 POWER\" (a sign, not a lock)", gx - 380, gy + 8, 12, C["ink"], "Black", w=310, align="right")
    hx, hy = v.p(188, 270)
    text(d, "ROLLING LOG run: the first 25 studs of zone 1 (striped)", hx - 250, hy - 4, 12, C["ink"], "Black", w=240, align="right")
    fx, fy = v.p(239, 276)
    text(d, "FIXED PAD, 40 into zone 1\n(Chomp Frog)", fx + 6, fy - 14, 12, C["ink"], "Black", w=200)
    sx, sy = v.p(224, L.START_LINE_Y)
    text(d, "START LINE", sx + 6, sy - 9, 12, C["ink"], "Black")
    tx, ty = v.p(206, 120)
    text(d, "TRACK", tx - 40, ty - 2, 13, C["white"], "Black", w=80, align="center", outline=True)
    yx, yy = v.p(140, 165)
    text(d, "THE YARD\n(open; shared ground)", yx - 80, yy - 16, 15, C["ink"], "Black", w=160, align="center")
    wx, wy = v.p(206, -2)
    text(d, "BACK WALL 16 TALL", wx - 100, wy - 22, 13, C["ink"], "Black", w=200, align="center")
    fx2, fy2 = v.p(90, 236)
    fx2, fy2 = v.p(330, 236)
    text(d, "FRONT WALL 4 TALL (zone 1 seen over it)", fx2 - 160, fy2 + 6, 12, C["ink"], "Black", w=320, align="center")
    # dimensions
    y0 = v.p(0, -2)[1] - 34
    dim(d, v.p(0, 0)[0], y0, v.p(412, 0)[0], y0, "412 inside the walls", w=300)
    dim(d, v.p(100, 0)[0], y0 + 24, v.p(150, 0)[0], y0 + 24, "50")
    dim(d, v.p(150, 0)[0], y0 + 24, v.p(154, 0)[0], y0 + 24, "gap 4", w=60, off=0)
    xl = v.p(-2, 0)[0] - 30
    dim(d, xl, v.p(0, 0)[1], xl, v.p(0, 234)[1], "234")
    dim(d, xl + 20, v.p(0, 4)[1], xl + 20, v.p(0, 96)[1], "92", off=-46)
    xr = v.p(414, 0)[0] + 16
    dim(d, xr, v.p(0, 204)[1], xr, v.p(0, 234)[1], "30")
    dim(d, xr, v.p(0, 154)[1], xr, v.p(0, 204)[1], "50")
    yy2 = v.p(0, 100)[1] + 6
    dim(d, v.p(96, 0)[0], v.p(0, 218)[1], v.p(316, 0)[0], v.p(0, 218)[1], "", w=10)
    text(d, "yard 220 between the side plots' fronts", v.p(100, 0)[0], v.p(0, 218)[1] - 20, 13, C["note"], "Bold")
    dim(d, v.p(188, 0)[0], v.p(0, 300)[1], v.p(224, 0)[0], v.p(0, 300)[1], "lane 36")
    xz = v.p(250, 0)[0] + 70
    dim(d, xz, v.p(0, 236)[1], xz, v.p(0, 276)[1], "40")
    # legend
    lgx, lgy = 1408, 150
    rect(b, "Legend well", lgx - 16, lgy - 16, 520, 1060, C["white"], stroke=C["ink"], sw=2, r=4)
    text(b, "KEY", lgx, lgy, 18, C["ink"], "Black")
    rows = [(C["pad"], "Boss spot 8x8 (rim: white = empty, tier colour = occupied)", C["rare"], "rect"),
            (C["grass"], "Ghost spot (rebirth spots 11-15, before they unlock)", C["dis"], "rect"),
            (C["green"], "Cash pad 8x3 in front of each spot", None, "rect"),
            (C["kerb"], "Bag pad 8x8, white with a red border; red square = the bag", C["red"], "rect"),
            (C["cyan"], "Lock pad 6x6 just inside the entrance", None, "rect"),
            (C["blue"], "Name board over the entrance; lock board; bag sign", None, "rect"),
            (C["gold"], "Delivery crate 6x6x6", None, "rect"),
            (C["yellow"], "Spawn: one per plot, facing the bag", None, "dot"),
            (C["trunk"], "Hub walls: back and sides 16 tall, front 4 tall", None, "rect"),
            (C["lane"], "Track, then the lane: lane grey, kerb-white kerbs", None, "rect"),
            (C["arrow"], "Lane arrows every 40 studs, pointing to zone 1", None, "line"),
            (C["orange"], "Hazard run (zone 1's Rolling Log)", None, "rect"),
            (C["blue"], "Sight lines kept open over the front wall", None, "dash")]
    y = lgy + 36
    for fill, lab, st, kind in rows:
        legend_row(b, lgx, y, fill, lab, stroke=st, kind=kind, w=450)
        y += 40
    y += 6
    text(b, "NUMBERS", lgx, y, 18, C["ink"], "Black"); y += 30
    facts = ["Hub 412 x 234 inside the walls. Plots 50 x 92, 4 apart and 4 off the walls: 4 on the back wall, 2 on each side wall, all facing the yard.",
             "Plots are numbered clockwise from the front left. They fill nearest the gate first, then alternate sides: 1, 8, 4, 5, 2, 7, 3, 6.",
             "Bag pad to the gate: 139 to 176 studs from every plot (8.7 to 11.0 s at walk speed). The gate is in the middle of the front wall, 30 below the side plots.",
             "Neighbouring entrances: 54 apart along a wall, 41 at the two back corners (plots 2-3 and 6-7), 220 across the yard.",
             "Everyone spawns on their own plot, facing their bag. The fallback spawn in the yard is used only before a plot is given.",
             "No shared stations in the yard: the brief has none (shop and rebirth are HUD buttons). Optional stands are listed in base-layout.md, not drawn here."]
    for f_ in facts:
        text(b, f_, lgx, y, 14, C["ink"], "Bold", w=480); y += 70 if len(f_) > 110 else 52
    scale_bar(b, 60, H - 40, k, 50, "50 studs (3 px a stud)")


# ======================================================================================= board 2: one plot
KEYS = [
    (1, (14, -2.5), "Entrance, 12 wide: the only way in or out. Name board over it on two posts (16 x 3.5, letters 2.4 tall)."),
    (2, (14, 6), "Lock pad 6x6, shield cyan: the owner steps on it to raise the shield."),
    (3, (9.5, 10.5), "Lock board on the pad's back edge: shield state, and the owner's Long Lock and Instant Shield buttons (never on the pad)."),
    (4, (5, 6), "Delivery crate 6x6x6, shop gold: bought bosses wait here; never stolen."),
    (5, (5, 13.5), "Spots-full sign: shows only when every unlocked spot is full; Extra Spots button for the owner, never during a carry or alert."),
    (6, (31, 12), "Spawn 4x4, facing the bag: bag pad edge 5 studs away (0.3 s)."),
    (7, (39, 7), "Bag pad 8x8: white, Huss-red border. Standing on it starts the ring."),
    (8, (46, 7), "Punching bag on a 6x6 plinth by the front fence, frame 13 tall, seen from the yard: the gym's station. The player punches facing the plot's right side."),
    (9, (44.5, 15), "Bag sign: Strength and Speed levels; opens the bag panel."),
    (10, (-2.5, 22), "Spots 1-10 (start): two columns of 5, facing the aisle. Rim white when empty, tier colour when occupied."),
    (11, (11.5, 32), "Cash pad 8x3 on the aisle side of each spot: the owner walks down the column to collect."),
    (12, (5, 72), "Spots 11-15 (rebirths 1-5): ghost outlines with REBIRTH n until unlocked."),
    (13, (5, 86), "Spots 16-17 (Extra Spots pass): the back row's corners; not drawn unless owned."),
    (14, (25, 45), "Aisle 24 wide: room to walk past a thief and punch; straight line of sight from the entrance."),
    (15, (25, 79.5), "Back collect band: one walk collects the back row's cash pads."),
    (16, (50.5, 14), "Fence: kerb-white posts every 4, two rails, 3 tall; an invisible blocker on the fence line to 10 studs."),
    (17, (50.5, 91.5), "Shield footprint: walls on the fence line, 50 x 92, 16 tall; timer plate over the entrance."),
    (18, (25, -3), "Driveway: lane grey 12 x 4 from the entrance into the yard."),
]


def plot_plan(parent, ox, oy, k, spots, occ, title, keys=True):
    text(parent, title, ox, oy - 76, 20, C["ink"], "Black")
    n = 4                                           # a back-row plot: front at the bottom, its right (bag) side to the right
    v = View(ox, oy, k, 154, 4)
    rect(parent, "Yard grass", *v.box(150, 96, 210, 110), C["grass"])
    rect(parent, "Track edge (kerb)", *v.box(187, 100, 188, 110), C["kerb"])
    rect(parent, "Track", *v.box(188, 100, 210, 110), C["lane"])
    draw_plot(parent, v, n, spots=spots, occ=occ, ghosts=True, labels=True, detail=True)
    # shield footprint
    rect(parent, "Shield footprint (walls on the fence line)", *v.box(*local_box(4, 0, 0, 50, 92)), "#00000000", stroke=C["cyan"], sw=3,
         align="outside", dashes=[10, 6])
    # facing arrows on spots
    for num in range(1, spots + 1):
        cell, sp, cash, face = L.SPOTS[num]
        cx, cy = sp[0] + 4, sp[1] + 4
        if cell.startswith("L"): tip, frm = (cx + 3.5, cy), (cx + 1.5, cy)
        elif cell.startswith("R"): tip, frm = (cx - 3.5, cy), (cx - 1.5, cy)
        else: tip, frm = (cx, cy - 3.5), (cx, cy - 1.5)
        arrowhead(parent, v.p(*L.to_world(4, *tip)), v.p(*L.to_world(4, *frm)), C["note"], size=9)
    if keys:
        for num, (lx, ly), _ in KEYS:
            if num == 13 and spots < 16: continue
            if num == 12 and spots > 15: continue
            x, y = v.p(*L.to_world(4, lx, ly))
            marker(parent, num, x, y, d=24)
    return v


def board2():
    W, H = 1940, 1180
    b = board("02 Plot plan", W, H, "ONE PLOT, TO SCALE (7 px = 1 stud): at the start (10 spots) and fully grown (17)",
              "Plot 4 (back wall) with the yard at the bottom; the track is the grey strip at the right edge. Every plot is this same template turned to face the yard (none is mirrored): the bag is always right of the entrance seen from the yard. "
              "Every element is numbered; the key is on the right. Grey triangles show which way each boss faces.")
    k = 7.0
    vA = plot_plan(b, 110, 180, k, 10, DEMO10, "AT THE START: 10 SPOTS")
    vB = plot_plan(b, 620, 180, k, 17, DEMO17, "FULLY GROWN: 17 SPOTS", keys=False)
    # dimensions on plan A
    x0, y0 = vA.p(*L.to_world(4, 0, 92)); x1, y1 = vA.p(*L.to_world(4, 50, 0))
    dim(b, x0, y0 - 20, x1, y0 - 20, "50")
    dim(b, x0 - 50, y0, x0 - 50, y1, "92")
    ex0 = vA.p(*L.to_world(4, 19, 0))[0]; ex1 = vA.p(*L.to_world(4, 31, 0))[0]
    yb = vA.p(*L.to_world(4, 0, -4))[1] + 26
    dim(b, ex0, yb, ex1, yb, "12")
    xr = x1 + 30
    yf0 = vA.p(*L.to_world(4, 0, 0))[1]; yf1 = vA.p(*L.to_world(4, 0, 18))[1]
    dim(b, xr, yf1, xr, yf0, "front yard 18")
    yc0 = vA.p(*L.to_world(4, 0, 18))[1]; yc1 = vA.p(*L.to_world(4, 0, 28))[1]
    dim(b, xr, yc1, xr, yc0, "pitch 10")
    yb0 = vA.p(*L.to_world(4, 0, 78))[1]; yb1 = vA.p(*L.to_world(4, 0, 91))[1]
    dim(b, xr, yb1, xr, yb0, "back row 13")
    ax0 = vA.p(*L.to_world(4, 13, 0))[0]; ax1 = vA.p(*L.to_world(4, 37, 0))[0]
    ya = vA.p(*L.to_world(4, 0, 48))[1]
    dim(b, ax0, ya, ax1, ya, "aisle 24")
    sx0 = vA.p(*L.to_world(4, 1, 0))[0]; sx1 = vA.p(*L.to_world(4, 9, 0))[0]; sx2 = vA.p(*L.to_world(4, 13, 0))[0]
    ys = vA.p(*L.to_world(4, 0, 17))[1] + 0
    # plan B notes
    bx, by = vB.p(*L.to_world(4, 0, 92))
    # key
    kx, ky = 1150, 150
    rect(b, "Key well", kx - 16, ky - 14, 790 - 4, 1010, C["white"], stroke=C["ink"], sw=2, r=4)
    text(b, "KEY", kx, ky, 18, C["ink"], "Black")
    y = ky + 34
    for num, _, s in KEYS:
        marker(b, num, kx + 12, y + 11, d=24)
        t = text(b, s, kx + 34, y, 14, C["ink"], "Bold", w=700)
        y += 50 if len(s) > 95 else 32
    y += 8
    text(b, "SPOT NUMBERS", kx, y, 16, C["ink"], "Black"); y += 26
    text(b, "1-10 alternate left and right, front to back (1 = L1, 2 = R1 ... 9 = L5, 10 = R5). 11 = L6 and 12 = R6 (rebirths 1, 2); "
            "13, 14, 15 = back row centre, left, right (rebirths 3-5); 16 and 17 = back row corners (Extra Spots). "
            "Rims in the plans show a mix of tiers as an example.", kx, y, 14, C["note"], "Bold", w=740)
    scale_bar(b, 110, H - 60, k, 50, "50 studs (7 px a stud)")


# ======================================================================================= board 3: pads
def stud_rect(parent, name, x, y, w, h, fill, tile, stroke=None, sw=0, align="inside"):
    return rect(parent, name, x, y, w, h, fill, stroke=stroke, sw=sw, stud=tile, align=align)


def plate_edge(parent, x, y, w, h, fill, k, thick=1.0):
    """A plate seen from above and a little in front: its 1-stud front face as a darker strip."""
    from figlib import C as CC
    def mul(hx, f):
        hx = hx.lstrip("#"); return "#%02X%02X%02X" % tuple(int(int(hx[i:i + 2], 16) * f) for i in (0, 2, 4))
    rect(parent, "Front face (1 stud)", x, y + h, w, thick * k * 0.6, mul(fill, 0.72))


def spot_drawing(parent, x, y, k, rim, boss=None, bossbox=None, cash=None, rim_dashes=None, glow=False, lifted=False, tag=None):
    s = 8 * k
    rect(parent, "Grass around", x - k, y - k, s + 2 * k, s + 2 * k, C["grass"])
    plate_edge(parent, x, y, s, s, C["pad"], k)
    stud_rect(parent, "Spot 8x8 (pad stone, studs)", x, y, s, s, C["pad"], k)
    if rim_dashes:
        rect(parent, "Rim", x, y, s, s, "#00000000", stroke=rim, sw=k * 0.9, dashes=rim_dashes)
    else:
        rect(parent, "Rim (1 stud)", x, y, s, s, "#00000000", stroke=rim, sw=k * 0.9)
    if glow:
        rect(parent, "Neon rim pulse (glow)", x - 5, y - 5, s + 10, s + 10, "#00000000", stroke=C["yellow"], sw=4, align="center")
        rect(parent, "Neon rim", x, y, s, s, "#00000000", stroke=C["white"], sw=k * 1.2)
    if boss:
        bw, bh = fit(boss, bossbox or s * 0.95)
        oy = -k * 2.5 if lifted else 0
        image(parent, boss, x + (s - bw) / 2, y + s - bh - k * 0.6 + oy - (s * 0.05), bw, bh, name="Boss (stand-in picture)")
    if tag:
        tagf = frame(parent, "Name tag (BillboardGui)", x - 40, y - 50, s + 80, 40)
        rect(tagf, "Tag well", 0, 0, s + 80, 40, C["white"], stroke=C["ink"], sw=2, r=4)
        text(tagf, tag[0], 0, 2, 12, C["ink"], "Black", w=s + 80, align="center")
        chips = tag[1:]
        cw = sum(len(c[0]) * 7 + 10 for c in chips) + 4 * (len(chips) - 1)
        cx = (s + 80 - cw) / 2
        for word, col, ink in chips:
            w = len(word) * 7 + 10
            rect(tagf, "Chip", cx, 19, w, 16, col, stroke=C["ink"], sw=1.5, r=3)
            text(tagf, word, cx, 20, 10, C["ink"] if ink else C["white"], "Black", w=w, align="center", outline=not ink)
            cx += w + 4


def cash_drawing(parent, x, y, k, stacks, empty=False, full=False, amount=None):
    w, h = 8 * k, 3 * k
    fill = C["green_lip"] if empty else C["green"]
    rect(parent, "Grass around", x - k, y - k, w + 2 * k, h + 2 * k, C["grass"])
    plate_edge(parent, x, y, w, h, fill, k)
    stud_rect(parent, "Cash pad 8x3", x, y, w, h, fill, k)
    for i in range(stacks):
        sx = x + k * (0.6 + i * 1.5)
        rect(parent, "Cash stack (green cubes, white band)", sx, y + k * 0.6, k * 1.2, k * 1.8, C["green"], stroke=C["ink"], sw=1)
        rect(parent, "Band", sx, y + k * 1.3, k * 1.2, k * 0.35, C["white"])
    if amount:
        f = frame(parent, "Cash tag (owner only)", x + w / 2 - 50, y - 30, 100, 24)
        rect(f, "Plate", 0, 0, 100, 24, C["green"], stroke=C["ink"], sw=2, r=4)
        text(f, amount, 0, 4, 13, C["white"], "Black", w=100, align="center", outline=True)


def pad_square(parent, x, y, k, size, fill, rim, rim_w=0.6, name="Pad"):
    s = size * k
    rect(parent, "Grass around", x - k, y - k, s + 2 * k, s + 2 * k, C["grass"])
    plate_edge(parent, x, y, s, s, fill, k)
    stud_rect(parent, name, x, y, s, s, fill, k)
    rect(parent, "Rim", x, y, s, s, "#00000000", stroke=rim, sw=k * rim_w)


def caption(parent, s, x, y, w=150, size=13, color=None):
    return text(parent, s, x, y, size, color or C["ink"], "Bold", w=w, align="center")


def card(parent, x, y, w, h, title, sub):
    f = frame(parent, "Card " + title, x, y, w, h)
    rect(f, "Card well", 0, 0, w, h, C["white"], stroke=C["ink"], sw=2, r=4)
    text(f, title, 16, 12, 18, C["ink"], "Black")
    text(f, sub, 16, 38, 13, C["note"], "Bold", w=w - 32)
    return f


def lock_board(parent, x, y, k2, state):
    """Front of the lock board, 6 wide x 4.5 tall, at k2 px a stud."""
    w, h = 6 * k2, 4.5 * k2
    rect(parent, "Lock board post", x + w / 2 - k2 * 0.5, y + h, k2, k2 * 1.6, C["lane"])
    stud_rect(parent, "Lock board (plate blue, studs)", x, y, w, h, C["blue"], 12, stroke=C["ink"], sw=2)
    plate_col = {"ready": C["cyan"], "up": C["cyan"], "cool": C["dis"], "alert": C["dis"], "visitor": C["cyan"]}[state]
    plate_txt = {"ready": "READY", "up": "UP 0:42", "cool": "0:31", "alert": "0:31", "visitor": "UP 0:42"}[state]
    f = frame(parent, "State plate", x + 6, y + 6, w - 12, 30)
    rect(f, "Plate", 0, 0, w - 12, 30, plate_col, stroke=C["ink"], sw=2, r=4)
    ic = "p/icon-lock" if state != "cool" and state != "alert" else "i/shield-down"
    iw, ih = fit(ic, 26)
    image(f, ic, 4, 2, iw, ih)
    text(f, plate_txt, 30, 6, 15, C["white"] if plate_col != C["dis"] else C["dis_text"], "Black", w=w - 50, align="center", outline=True)
    by = y + 42
    if state in ("ready", "cool"):
        for lab in ("LONG LOCK  R$ 199", "INSTANT SHIELD  R$ 19"):
            bf = frame(parent, "Buy button (gold)", x + 6, by, w - 12, 26)
            rect(bf, "Lip", 0, 2, w - 12, 24, "#B78B12", stroke=C["ink"], sw=2, r=4)
            rect(bf, "Face", 0, 0, w - 12, 22, C["gold"], r=4)
            text(bf, lab, 0, 3, 11, C["ink"], "Black", w=w - 12, align="center")
            by += 30
    elif state == "up":
        bf = frame(parent, "Buy button (gold)", x + 6, by, w - 12, 26)
        rect(bf, "Lip", 0, 2, w - 12, 24, "#B78B12", stroke=C["ink"], sw=2, r=4)
        rect(bf, "Face", 0, 0, w - 12, 22, C["gold"], r=4)
        text(bf, "LONG LOCK  R$ 199", 0, 3, 11, C["ink"], "Black", w=w - 12, align="center")
    else:
        text(parent, "no buttons", x, by + 14, 12, C["white"], "Black", w=w, align="center", outline=True)


def board3():
    W, H = 1940, 2420
    b = board("03 Pads", W, H, "PADS AND BASE PIECES, WITH THEIR STATES",
              "Drawn in the approved stud look and palette, seen from above (a darker strip is each plate's 1-stud front face). "
              "Pads at 14 px a stud; boards and signs as front views. Boss pictures are the kit's stand-ins; built bosses are renders of the real models.")
    k = 14.0
    X0, Y = 32, 110
    # ---- spots
    c = card(b, X0, Y, 1876, 380, "BOSS SPOT  8 x 8 x 1 stud, pad stone #C9CED8, studs; 1-stud rim",
             "Rim: white when empty, Neon white pulsing while the owner carries a boss, the boss's tier colour when occupied, alarm orange while it is being stolen or away with a thief. "
             "No sign on the spot itself; the boss's name tag (BillboardGui, 16 px name, 14 px chips, income line) floats over it. Bosses face the aisle.")
    sx, sy = 40, 150
    states = [("EMPTY", dict(rim=C["white"])),
              ("EMPTY, YOU CARRY A BOSS\n(rim Neon white, pulsing; Place prompt)", dict(rim=C["white"], glow=True)),
              ("OCCUPIED, COMMON", dict(rim=C["common"], boss="s/chomp-frog", tag=("CHOMP FROG  $1/s", ("COMMON", C["common"], False)))),
              ("OCCUPIED, BOUGHT\n(gold BOUGHT tag on the name tag)", dict(rim=C["epic"], boss="s/frost-byte", bossbox=118, tag=("FROST BYTE  $3.6K/s", ("EPIC", C["epic"], False), ("BOUGHT", C["gold"], True)))),
              ("BEING STOLEN\n(2 s hold; boss lifts, rim orange)", dict(rim=C["orange"], boss="s/snap-scorpion", lifted=True)),
              ("AWAY WITH A THIEF\n(reserved; snaps back on a punch)", dict(rim=C["orange"], rim_dashes=[10, 6])),
              ("LOCKED, NOT YET UNLOCKED\n(ghost outline, REBIRTH 3)", None)]
    for i, (lab, kw) in enumerate(states):
        x = sx + i * 262
        if kw is None:
            rect(c, "Ghost spot (flush with grass)", x, sy + 40, 8 * k, 8 * k, C["grass"], stroke=C["dis"], sw=4, dashes=[8, 6])
            f = frame(c, "REBIRTH plate", x + 16, sy + 40 + 8 * k / 2 - 12, 8 * k - 32, 24)
            rect(f, "Plate", 0, 0, 8 * k - 32, 24, C["dis"], stroke=C["ink"], sw=2, r=3)
            text(f, "REBIRTH 3", 0, 4, 12, C["dis_text"], "Black", w=8 * k - 32, align="center", outline=True)
        else:
            spot_drawing(c, x, sy + 40, k, **kw)
        caption(c, lab, x - 50, sy + 40 + 8 * k + 20, w=8 * k + 100)
    # ---- cash pads, bag pad
    Y2 = Y + 400
    c = card(b, X0, Y2, 1100, 330, "CASH PAD  8 x 3 x 1 stud, cash green #2FB341, studs",
             "On the aisle side of each spot. Walking over it collects (owner only). One to five stacks of green cubes with a white band as it fills; "
             "the amount on a small green tag (BillboardGui, 13 px, owner only, within 40 studs). Its cash stays for the owner if the boss is picked up, sold or stolen.")
    cs = [("EMPTY (lip shade of green)", 0, True, None), ("HAS CASH", 2, False, "$1.2K"), ("CAPPED: 2 h of income", 5, False, "$7.2K  FULL")]
    for i, (lab, n, e, amt) in enumerate(cs):
        x = 40 + i * 350
        cash_drawing(c, x, 200, k, n, empty=e, amount=amt)
        caption(c, lab, x - 20, 270, w=8 * k + 40)
    c = card(b, X0 + 1120, Y2, 756, 330, "BAG PAD  8 x 8 x 1 stud, kerb white, Huss-red 1-stud border",
             "The bag hangs 1 stud past its right-side edge on a 6x6 pad-stone plinth. Standing on it starts the ring (owner only). No sign on the pad; the bag sign stands beside the bag.")
    for i, (lab, arrow) in enumerate((("IDLE", False), ("FIRST SESSION: arrow over the bag", True))):
        x = 40 + i * 360
        pad_square(c, x, 150, k, 8, C["kerb"], C["red"], 0.9, "Bag pad")
        plate_edge(c, x + 8 * k, 150 + k, 6 * k * 0.5, 6 * k, C["pad"], k)
        stud_rect(c, "Plinth", x + 8 * k, 150 + k, 6 * k * 0.5, 6 * k, C["pad"], k)
        rect(c, "Bag (seen from above)", x + 8 * k + 2, 150 + 2 * k, 4 * k * 0.5, 4 * k, C["red"], stroke=C["ink"], sw=2)
        if arrow:
            aw, ah = fit("i/arrow-yellow", 48)
            image(c, "i/arrow-yellow", x + 8 * k - 6, 150 - 10, aw, ah)
        caption(c, lab, x - 10, 290, w=8 * k + 120)
    # ---- lock pad and lock board
    Y3 = Y2 + 350
    c = card(b, X0, Y3, 1876, 420, "LOCK PAD  6 x 6 x 1 stud, shield cyan #35C8F0, studs, white rim; the Lock shield icon on a plate in its middle.  LOCK BOARD  6 x 4.5, on its back edge",
             "Step on the pad to raise the shield (owner only). Buying is never on the pad: the owner's two gold buttons are on the lock board (SurfaceGui buttons 1.5 studs tall, "
             "tappable within 10 studs). Instant Shield shows only while the shield is down; both buttons are hidden while a steal alert or a shield-broken alert is on for this owner. Visitors see the state only.")
    ps = [("READY", C["cyan"], C["white"], "p/icon-lock", None), ("UP 0:42 (time on the plate)", C["cyan"], C["cyan"], "p/icon-lock", "0:42"),
          ("COOLDOWN 0:31 (disabled grey)", C["dis"], C["white"], "i/shield-down", "0:31"), ("UP BY INSTANT SHIELD (gold rim)", C["cyan"], C["gold"], "i/instant-shield", "0:58")]
    for i, (lab, fill, rim, ic, t) in enumerate(ps):
        x = 40 + i * 200
        pad_square(c, x, 150, k, 6, fill, rim, 0.7, "Lock pad")
        iw, ih = fit(ic, 46)
        image(c, ic, x + 3 * k - iw / 2, 150 + 3 * k - ih / 2 - (8 if t else 0), iw, ih)
        if t:
            text(c, t, x, 150 + 3 * k + 14, 14, C["white"], "Black", w=6 * k, align="center", outline=True)
        caption(c, lab, x - 30, 150 + 6 * k + 18, w=6 * k + 60)
    k2 = 32
    bs = [("READY: both buttons", "ready"), ("UP: Long Lock only", "up"), ("COOLDOWN: both", "cool"), ("STEAL ALERT ON: none", "alert"), ("VISITOR: state only", "visitor")]
    for i, (lab, st) in enumerate(bs):
        x = 880 + i * 200
        lock_board(c, x, 140, k2, st)
        caption(c, lab, x - 10, 140 + 4.5 * k2 + 64, w=6 * k2 + 20)
    # ---- crate, spots-full sign, name board
    Y4 = Y3 + 440
    c = card(b, X0, Y4, 620, 360, "DELIVERY CRATE  6 x 6 x 6, shop gold, kerb-white rails and X",
             "Front-left corner of the front yard. Take-out prompt (E). Holds bought bosses; never stolen; no limit.")
    for i, (lab, full) in enumerate((("EMPTY: lid shut", False), ("HOLDING 3: lid propped, count tag", True))):
        x = 50 + i * 290
        cw = 6 * k * 1.4
        stud_rect(c, "Crate front", x, 160, cw, cw, C["gold"], 14, stroke=C["ink"], sw=2)
        rect(c, "Rail", x, 160, cw, 8, C["kerb"]); rect(c, "Rail", x, 160 + cw - 8, cw, 8, C["kerb"])
        rect(c, "Rail", x, 160, 8, cw, C["kerb"]); rect(c, "Rail", x + cw - 8, 160, 8, cw, C["kerb"])
        poly(c, "X bar", [(x + 8, 168), (x + cw - 8, 160 + cw - 8)], C["kerb"], sw=7)
        poly(c, "X bar", [(x + cw - 8, 168), (x + 8, 160 + cw - 8)], C["kerb"], sw=7)
        if full:
            rect(c, "Lid propped open", x - 6, 140, cw + 12, 14, C["gold"], stroke=C["ink"], sw=2)
            f = frame(c, "Count tag", x + cw / 2 - 22, 104, 44, 28)
            rect(f, "Plate", 0, 0, 44, 28, C["gold"], stroke=C["ink"], sw=2, r=4)
            text(f, "3", 0, 4, 16, C["ink"], "Black", w=44, align="center")
        else:
            rect(c, "Lid shut", x, 150, cw, 12, C["gold"], stroke=C["ink"], sw=2)
        caption(c, lab, x - 20, 160 + cw + 14, w=cw + 40)
    c = card(b, X0 + 640, Y4, 560, 360, "SPOTS-FULL SIGN  6 x 3, on a post by the crate",
             "Shown only while every unlocked spot is full. Gold button for the owner without the pass; hidden while carrying and during alerts.")
    for i, (lab, btn) in enumerate((("OWNER, NO PASS, NOT CARRYING", True), ("CARRYING, ALERT, OR PASS OWNED", False))):
        x = 30 + i * 260
        sw_, sh_ = 6 * 36, 3 * 36
        stud_rect(c, "Sign board (alarm orange header)", x, 150, sw_, sh_, C["panel"], 12, stroke=C["ink"], sw=2)
        rect(c, "Header", x, 150, sw_, 34, C["orange"], stroke=C["ink"], sw=2)
        text(c, "SPOTS FULL", x, 156, 17, C["white"], "Black", w=sw_, align="center", outline=True)
        if btn:
            bf = frame(c, "Buy button", x + 18, 200, sw_ - 36, 40)
            rect(bf, "Lip", 0, 3, sw_ - 36, 37, "#B78B12", stroke=C["ink"], sw=2, r=4)
            rect(bf, "Face", 0, 0, sw_ - 36, 34, C["gold"], r=4)
            text(bf, "+2 SPOTS  R$ 249", 0, 8, 14, C["ink"], "Black", w=sw_ - 36, align="center")
        else:
            text(c, "Swap or Sell\n(no buy button)", x, 200, 14, C["white"], "Black", w=sw_, align="center", outline=True)
        rect(c, "Post", x + sw_ / 2 - 6, 150 + sh_, 12, 40, C["lane"])
        caption(c, lab, x - 10, 310, w=sw_ + 20)
    c = card(b, X0 + 1220, Y4, 656, 360, "NAME BOARD  16 x 3.5 x 1, plate blue, studs",
             "Over the entrance on two kerb-white posts, bottom at 7.5. Name in white Montserrat Black with ink outline, letters 2.4 studs tall (14 px on a phone from 48 studs). Rebirth star with the count once rebirthed.")
    nk = 34
    stud_rect(c, "Name board", 24, 170, 16 * nk * 1.1, 3.5 * nk, C["blue"], 16, stroke=C["ink"], sw=3)
    text(c, "BRICKBOSS_77", 24, 170 + 30, 44, C["white"], "Black", w=16 * nk * 0.95, align="center", outline=True)
    iw, ih = fit("i/star", 70)
    image(c, "i/star", 24 + 16 * nk * 1.1 - 92, 170 + 18, iw, ih)
    text(c, "3", 24 + 16 * nk * 1.1 - 92, 170 + 40, 22, C["ink"], "Black", w=iw, align="center")
    rect(c, "Post", 24 + 10, 170 + 3.5 * nk, 16, 40, C["kerb"], stroke=C["dis"], sw=1)
    rect(c, "Post", 24 + 16 * nk * 1.1 - 26, 170 + 3.5 * nk, 16, 40, C["kerb"], stroke=C["dis"], sw=1)
    caption(c, "Example name only", 24, 330, w=16 * nk * 1.1)
    # ---- boss pads in zones
    Y5 = Y4 + 380
    c = card(b, X0, Y5, 1876, 340, "BOSS PAD (ZONES)  12 x 12 x 1, pad stone, studs, kerb-white 1-stud ring",
             "Fixed pad: four 2x2x2 corner posts in the zone's structure colour (zone 1 #B5563C); always the zone's Common, back 10 s after you beat it. Rolling pad: a sign post at its back corner "
             "with a countdown plate (4 x 2 studs, white on plate blue, letters 1.2 tall); a new boss every 45 s. Over every boss: name tag and its Power number in the difficulty colour (BillboardGui, readable to 320 studs on zone 1's pads).")
    kk = 11
    pads = [("FIXED: Chomp Frog, Power green for you", "fixed", "s/chomp-frog", None),
            ("FIXED, YOU BEAT IT: BACK IN 0:08 (you only)", "fixed", None, "BACK IN 0:08"),
            ("ROLLING: countdown 0:32", "roll", "s/bit-shark", "0:32"),
            ("ROLLING, YOU BEAT THIS ROLL: BEATEN until the next", "roll", "s/snap-scorpion", "BEATEN")]
    for i, (lab, kind, boss, plate) in enumerate(pads):
        x = 40 + i * 460
        s = 12 * kk
        plate_edge(c, x, 130, s, s, C["pad"], kk)
        stud_rect(c, "Boss pad", x, 130, s, s, C["pad"], kk)
        rect(c, "Ring (kerb white)", x, 130, s, s, "#00000000", stroke=C["kerb"], sw=kk)
        if kind == "fixed":
            for dx, dy in ((0, 0), (s - 2 * kk, 0), (0, s - 2 * kk), (s - 2 * kk, s - 2 * kk)):
                rect(c, "Corner post 2x2x2", x + dx, 130 + dy, 2 * kk, 2 * kk, C["trunk"], stroke=C["ink"], sw=1)
        else:
            rect(c, "Sign post", x + s - 2 * kk + 4, 130 + 4, kk, kk, C["lane"], stroke=C["ink"], sw=1)
        if boss:
            bw, bh = fit(boss, 96)
            image(c, boss, x + (s - bw) / 2, 130 + s - bh - 14, bw, bh)
        if plate:
            pw = 150
            col = C["blue"] if plate != "BEATEN" else C["green"]
            f = frame(c, "Plate", x + s + 14, 150, pw, 30)
            rect(f, "Plate", 0, 0, pw, 30, col if plate != "BACK IN 0:08" else C["white"], stroke=C["ink"], sw=2, r=4)
            text(f, plate, 0, 6, 14, C["ink"] if plate == "BACK IN 0:08" else C["white"], "Black", w=pw, align="center", outline=plate != "BACK IN 0:08")
        if boss and kind == "fixed":
            text(c, "25", x + s + 20, 150, 30, "#6BE04A", "Black", outline=True)
        caption(c, lab, x - 20, 130 + s + 22, w=s + 190)
    # ---- shield
    Y6 = Y5 + 360
    c = card(b, X0, Y6, 1876, 380, "LOCK SHIELD  walls on the fence line, 50 x 92 x 16 tall; seen here from the yard (front, 50 wide)",
             "Up: shield-cyan stud panels at 0.6 transparency with a solid cyan 1-stud ground rim and a timer plate over the entrance (BillboardGui, 18 px, readable from 120 studs). "
             "Down: the rim only, in white. Instant Shield: the ground rim is shop gold. Broken: cyan cube burst, rim flashes alarm-orange stripes for 1 s. The visitor's Break shield button sits on the entrance panel (2.4 studs tall, within 15 studs).")
    sk = 5.2
    shields = [("DOWN (rim white)", "down"), ("UP 0:42", "up"), ("UP BY INSTANT SHIELD (gold rim, can't be broken)", "instant"),
               ("BROKEN (1 s orange stripes, then down)", "broken"), ("VISITOR AT A BREAKABLE SHIELD", "visitor")]
    for i, (lab, st) in enumerate(shields):
        x = 30 + i * 368
        w, h = 50 * sk, 16 * sk
        base = 150 + h
        rect(c, "Grass", x - 6, base, w + 12, 26, C["grass"])
        # fence and board silhouette
        rect(c, "Fence", x, base - 3 * sk, 19 * sk, 3 * sk, C["kerb"], stroke=C["dis"], sw=1)
        rect(c, "Fence", x + 31 * sk, base - 3 * sk, 19 * sk, 3 * sk, C["kerb"], stroke=C["dis"], sw=1)
        rect(c, "Name board", x + 17 * sk, base - 11 * sk, 16 * sk, 3.5 * sk, C["blue"], stroke=C["ink"], sw=1)
        rect(c, "Post", x + 17 * sk, base - 7.5 * sk, sk, 7.5 * sk, C["kerb"]); rect(c, "Post", x + 32 * sk, base - 7.5 * sk, sk, 7.5 * sk, C["kerb"])
        rim = {"down": C["white"], "up": C["cyan"], "instant": C["gold"], "broken": C["orange"], "visitor": C["cyan"]}[st]
        if st in ("up", "instant", "visitor"):
            stud_rect(c, "Shield panel (cyan, 0.6)", x, 150, w, h, C["cyan"], 12)
            rect(c, "Shield panel tint", x, 150, w, h, "#35C8F0", opacity=0.35, stroke=C["cyan"], sw=2)
            f = frame(c, "Timer plate", x + w / 2 - 40, 150 - 34, 80, 28)
            rect(f, "Plate", 0, 0, 80, 28, C["cyan"], stroke=C["ink"], sw=2, r=4)
            text(f, "0:42" if st != "instant" else "0:58", 0, 4, 16, C["white"], "Black", w=80, align="center", outline=True)
        if st == "broken":
            for j in range(0, int(w), 16):
                rect(c, "Stripe", x + j, base - 3, 8, 6, C["orange"]); rect(c, "Stripe", x + j + 8, base - 3, 8, 6, C["ink"])
            for j in range(9):
                rect(c, "Cube burst", x + 20 + j * 26, 150 + (j % 3) * 22 + 10, 10, 10, C["cyan"], stroke=C["ink"], sw=1)
        else:
            rect(c, "Ground rim (1 stud)", x, base - 3, w, 6, rim, stroke=C["ink"], sw=1)
        if st == "visitor":
            bf = frame(c, "Break shield button", x + w / 2 - 70, base - 6 * sk, 140, 30)
            rect(bf, "Lip", 0, 3, 140, 27, "#B78B12", stroke=C["ink"], sw=2, r=4)
            rect(bf, "Face", 0, 0, 140, 24, C["gold"], r=4)
            text(bf, "BREAK SHIELD R$ 39", 0, 4, 12, C["ink"], "Black", w=140, align="center")
        caption(c, lab, x - 10, base + 34, w=w + 20)


# ======================================================================================= board 4: steal route
def board4():
    W, H = 1940, 1320
    b = board("04 Steal route", W, H, "STEAL ROUTE: thief out, owner's chase, shield footprint and timings",
              "The worst case: plot 2 robbed by plot 3, the back-corner neighbour (entrances 41 apart, the shortest carry home in the hub). 3.3 px = 1 stud. "
              "Thief carries at 12 studs/s (16 with Fast Carry); the owner chases at 20 while a boss of theirs is being carried off, and punches from 8 studs.")
    k = 3.3
    d = frame(b, "Plan (clipped)", 30, 120, 900, 1150, clip=True, fill=C["paper"])
    vv = View(14, 20, k, -4, -4)
    hub_ground(d, vv, y_end=345)
    for n in range(1, 9):
        draw_plot(d, vv, n, spots=10, occ=DEMO10, ghosts=False, labels=n in (2, 3), detail=False)
    rect(d, "Shield footprint plot 2", *vv.box(*local_box(2, 0, 0, 50, 92)), "#00000000", stroke=C["cyan"], sw=4, align="outside", dashes=[12, 6])
    td = L.door(3)
    tdx, tdy = vv.p(*td)
    for spot in (1, 9):
        inside, tot = L.thief_route(2, spot, 3)
        r = (tot / L.CARRY * L.CHASE + L.PUNCH_RANGE) * k
        ellipse(d, "Owner catch radius spot %d" % spot, tdx - r, tdy - r, 2 * r, 2 * r, stroke=C["red"], sw=2, dashes=[4, 6])
    def route(spot):
        return [vv.p(*L.to_world(2, *L.hold_point(spot))), vv.p(*L.door(2)), (tdx, tdy)]
    r9 = route(9); r1 = route(1)
    poly(d, "Thief route from spot 9", r9, C["orange"], sw=6)
    arrowhead(d, r9[-1], r9[-2], C["orange"], size=16)
    poly(d, "Thief route from spot 1", r1, C["orange"], sw=3, dashes=[8, 6])
    for pt in (r9[0], r1[0]):
        ellipse(d, "Steal hold here (2 s)", pt[0] - 9, pt[1] - 9, 18, 18, fill=C["orange"], stroke=C["ink"], sw=2)
    ob = vv.p(*L.to_world(2, *L.BAG_PAD_C)); oy_ = vv.p(206, 165); og = vv.p(*L.GATE_C); of = vv.p(*L.FIXED_PAD)
    for pts, nm in (([ob, vv.p(*L.door(2))], "from the bag"), ([oy_, (tdx, tdy)], "from the yard centre"),
                    ([og, (tdx, tdy)], "from the gate"), ([of, og], "from the fixed pad")):
        poly(d, "Owner chase " + nm, pts, C["red"], sw=4, dashes=[14, 6])
        arrowhead(d, pts[-1], pts[-2], C["red"], size=14)
        ellipse(d, "Owner start", pts[0][0] - 9, pts[0][1] - 9, 18, 18, fill=C["red"], stroke=C["ink"], sw=2)
    def lab(s, x, y, w=170, col=None):
        text(d, s, x, y, 13, col or C["ink"], "Black", w=w)
    p2 = vv.p(*L.to_world(2, 50, 20)); lab("PLOT 2 (victim)", p2[0] - 20, p2[1] - 22, 150)
    p3 = vv.p(*L.to_world(3, 0, 60)); lab("PLOT 3\n(thief)", p3[0] + 8, p3[1] - 10, 100)
    ps = vv.p(6, 78); lab("SHIELD: walls on plot 2's\nfence line, 16 tall", ps[0], ps[1], 220, C["blue"])
    lab("thief's door", tdx + 12, tdy + 8, 120, C["orange"])
    lab("owner at\nthe gate", og[0] - 110, og[1] - 40, 100, C["red"])
    lab("owner at the\nfixed pad", of[0] - 120, of[1] + 12, 130, C["red"])
    lab("owner at the\nyard centre", oy_[0] - 130, oy_[1] + 6, 130, C["red"])
    lab("owner at\nthe bag", ob[0] + 10, ob[1] + 8, 100, C["red"])
    c1 = 117 * k; c9 = 181 * k
    lab("catch radius, spot 1: 117", tdx - 0.17 * c1 - 60, tdy + 0.985 * c1 - 40, 130, C["red"])
    lab("catch radius, spot 9: 181", tdx - 0.17 * c9 - 60, tdy + 0.985 * c9 - 40, 130, C["red"])
    # ---- table
    tx, ty = 950, 130
    rect(b, "Table well", tx - 16, ty - 14, 990 - 8, 1160, C["white"], stroke=C["ink"], sw=2, r=4)
    text(b, "KEY", tx, ty, 18, C["ink"], "Black")
    yy = ty + 32
    for fill, s_, kind in ((C["orange"], "Thief: solid from spot 9 (deepest of the first 10), dashed from spot 1. Dot = the 2 s hold.", "line"),
                           (C["red"], "Owner's chase at 20 studs/s from four starting places. Dotted circles: catch radius around the thief's door.", "dash"),
                           (C["cyan"], "Shield footprint: the victim plot's fence line, 50 x 92, 16 tall.", "dash")):
        legend_row(b, tx, yy, fill, s_, kind=kind, w=920); yy += 30
    yy += 12
    text(b, "THIEF: CARRY FROM THE END OF THE HOLD TO CROSSING INTO THEIR OWN PLOT", tx, yy, 15, C["ink"], "Black", w=950); yy += 28
    cols = [0, 250, 380, 500, 620, 760]
    hdr = ("Case (spot)", "Inside", "To own door", "Carry 12/s", "Fast Carry 16/s", "Catch radius")
    for j, cell in enumerate(hdr):
        text(b, cell, tx + cols[j], yy, 13, C["ink"], "Black", w=(cols[j + 1] - cols[j] - 6) if j < 5 else 200)
    yy += 24
    for victim, thief, name in ((2, 3, "Back corner, 41 apart"), (3, 4, "Along a wall, 54 apart"), (2, 7, "Across the yard, 220")):
        for spot in (1, 9, 16):
            inside, tot = L.thief_route(victim, spot, thief)
            row = ("%s (%d)" % (name, spot), "%.0f" % inside, "%.0f" % tot, "%.1f s" % (tot / 12), "%.1f s" % (tot / 16),
                   "%.0f (%.0f Fast)" % (tot / 12 * 20 + 8, tot / 16 * 20 + 8))
            for j, cell in enumerate(row):
                text(b, cell, tx + cols[j], yy, 13, C["ink"], "Bold", w=(cols[j + 1] - cols[j] - 6) if j < 5 else 200)
            yy += 22
        yy += 6
    text(b, "Add the hold: 2.0 s (1.0 with Quick Hands). The owner is alerted when the hold completes; an owner at home sees the hold and can punch it off.", tx, yy, 13, C["note"], "Bold", w=950); yy += 44
    text(b, "OWNER: DISTANCE AND TIME TO THE NEAREST THIEF'S DOOR, AT 20 STUDS/S", tx, yy, 15, C["ink"], "Black", w=950); yy += 28
    cols = [0, 150, 300, 450, 600, 770]
    hdr = ("Victim (thief)", "At own bag", "Yard centre", "At the gate", "Zone 1 fixed pad", "Zone 1 last pad")
    for j, cell in enumerate(hdr):
        text(b, cell, tx + cols[j], yy, 13, C["ink"], "Black", w=(cols[j + 1] - cols[j] - 6) if j < 5 else 180)
    yy += 24
    for n in (2, 3, 1, 4):
        th = L.nearest_thief(n); tdn = L.door(th)
        vals = [L.dist(L.BAG_PAD_C, L.ENTRANCE_C) + L.dist(L.door(n), tdn), L.dist((206, 165), tdn), L.dist(L.GATE_C, tdn),
                L.dist(L.GATE_C, L.FIXED_PAD) + L.dist(L.GATE_C, tdn), L.dist(L.GATE_C, L.ROLL_PADS[-1]) + L.dist(L.GATE_C, tdn)]
        row = ("%d (%d)" % (n, th),) + tuple("%.0f  %.1f s" % (x, x / 20) for x in vals)
        for j, cell in enumerate(row):
            text(b, cell, tx + cols[j], yy, 13, C["ink"], "Bold", w=(cols[j + 1] - cols[j] - 6) if j < 5 else 180)
        yy += 22
    text(b, "Plots 6, 7, 8 and 5 mirror 3, 2, 1 and 4.", tx, yy, 13, C["note"], "Bold"); yy += 34
    text(b, "HOW TO READ IT", tx, yy, 15, C["ink"], "Black"); yy += 26
    notes = ["The owner saves the boss if they start inside the catch radius of the thief's door: they get there first and punch from 8 studs.",
             "Owner at home or in the yard: every steal can be caught, from any neighbour, even with Fast Carry.",
             "Owner at the gate (155-160 from the nearest thief's door): catches steals from the deep spots (9-17), not from spots 1-4 of a corner or wall neighbour.",
             "Owner in zone 1: catches only a deep-spot steal by a wall neighbour (spot 16: 231 radius against 205-210). Past that, only the shield protects the base.",
             "Deeper spots are safer: from spot 9 the thief needs 8.7 to 9.7 s, from spot 1 only 5.5 to 6.5 s. Owners keep their best bosses at the back.",
             "One entrance: every thief leaves past the owner's bag (bag pad centre to the entrance: 16 studs, 1.0 s).",
             "Shield 60 s (90 with Long Lock): a zone 1 trip is about 32 to 37 s from every plot; a zone 2 trip about 50 to 55 s (inside one shield, just)."]
    for s_ in notes:
        text(b, "- " + s_, tx, yy, 13, C["ink"], "Bold", w=950); yy += 40
    scale_bar(b, 40, H - 34, k, 50, "50 studs (3.3 px a stud)")


init_stud()
page("1 Base area", 0); board1()
page("2 Plot", 1); board2()
page("3 Pads", 2); board3()
page("4 Steal route", 3); board4()
add("page.select", index=0)
dump(sys.argv[1])
