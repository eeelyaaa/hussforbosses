"""Huss for Bosses: base area layout, as data. One source for the plans (build_plans.py) and the timings in
base-layout.md. Units are Roblox studs. Run `python layout.py` to print the timing tables.

Hub frame used everywhere (the manager's references 15-17, 2026-11-25):
  X = across the hub, 0 at the inside face of the left wall; Y = from the inside face of the back wall toward the
  front wall and zone 1's gate. 8 plots in a U along the back and side walls, all facing the open yard.
Plot local frame (every plot is the same template, rotated to face the yard; nothing is mirrored):
  x = 0..50 across the plot's width; x = 50 is the RIGHT side as seen from the yard (the bag side).
  y = 0..92 depth; y = 0 is the front fence with the entrance, facing the yard.
"""
import math

# ---- fixed by the brief / style guide -------------------------------------------------------------------
WALK, CARRY, FAST_CARRY, CHASE = 16.0, 12.0, 16.0, 20.0     # studs per second (brief systems 5, 6, 10, 13)
HOLD, HOLD_QUICK = 2.0, 1.0                                 # steal hold, Quick Hands (system 10)
PUNCH_RANGE = 8.0                                           # owner's punch reaches a thief within 8 studs
LANE_W = 36                                                 # grey lane surface; 1-stud kerb-white kerb outside each edge
SHIELD_UP, SHIELD_CD, SHIELD_LONG = 60, 60, 90

# ---- TEAM CALL numbers (this file) ------------------------------------------------------------------------
# The hub (manager's refs 15-17, 2026-11-25): a walled yard; 8 plots stand along three walls facing it (a U):
# 4 along the back wall, 2 along each side wall; the gate to zone 1 is in the middle of the front wall.
# Hub frame: X right, Y down (toward the gate), 0,0 = the inside corner of the back-left wall.
PLOT_W, PLOT_D = 50, 92        # outer, fence lines included
GAP = 4                        # grass between neighbouring plots, and between a plot and a hub wall
APRON = 4                      # a 12-wide lane-grey driveway crosses it in front of each entrance
HUB_W, HUB_D = 412, 234        # inside the walls
WALL_BACK, WALL_FRONT = 16, 4  # wall heights: back and side walls 16; front wall 4 (zone 1 seen over it)
GATE_X = (188, 224)            # 36-wide opening in the front wall = the lane's width
GATE_C = (206, 234)
TRACK_X = (188, 224)           # the lane starts inside the hub as a 36-wide track from the back row to the gate
TRACK_Y0 = 100
START_LINE_Y = 226             # kerb-white start line across the track, 2 deep (226..228)
ENTRANCE = (19, 31)            # local x of the 12-stud entrance gap in the front fence

# plot placement: (kind, a) -- back: X origin of local x=0; left/right: Y extent start
PLOTS = {1: ("left", 154), 2: ("left", 100), 3: ("back", 100), 4: ("back", 154), 5: ("back", 208), 6: ("back", 262),
         7: ("right", 100), 8: ("right", 154)}
FILL_ORDER = [1, 8, 4, 5, 2, 7, 3, 6]        # nearest the gate first, then alternate sides


def to_world(n, lx, ly):
    """Plot local (x across, 0..50, x = 50 is the RIGHT side seen from the yard; y depth from the front) to hub X, Y."""
    kind, a = PLOTS[n]
    if kind == "back": return (a + lx, 96 - ly)
    if kind == "left": return (96 - ly, a + 50 - lx)
    return (316 + ly, a + lx)


# ---- one plot, local coordinates (x, y, w, d) --------------------------------------------------------------
SPOT, SPOT_GAP, CASH_D = 8, 2, 3
COL_Y0 = 18                    # first column spot starts here
LEFT_SPOT_X, LEFT_CASH_X = 1, 10           # back-side column: spot x 1..9, cash pad x 10..13
RIGHT_SPOT_X, RIGHT_CASH_X = 41, 37        # gate-side column: spot x 41..49, cash pad x 37..40
BACK_CASH_Y, BACK_SPOT_Y = 78, 82          # back row: cash pads y 78..81, spots y 82..90
BACK_X = [1, 11, 21, 31, 41]


def col_y(k):                  # k = 1..6
    return COL_Y0 + (k - 1) * (SPOT + SPOT_GAP)


# spot number -> (cell name, spot rect, cash rect, faces)
SPOTS = {}
for k in range(1, 7):
    SPOTS_L = ("L%d" % k, (LEFT_SPOT_X, col_y(k), 8, 8), (LEFT_CASH_X, col_y(k), 3, 8), "+x (aisle)")
    SPOTS_R = ("R%d" % k, (RIGHT_SPOT_X, col_y(k), 8, 8), (RIGHT_CASH_X, col_y(k), 3, 8), "-x (aisle)")
    if k <= 5:
        SPOTS[2 * k - 1], SPOTS[2 * k] = SPOTS_L, SPOTS_R
    else:
        SPOTS[11], SPOTS[12] = SPOTS_L, SPOTS_R
for num, b in ((13, 2), (14, 1), (15, 3), (16, 0), (17, 4)):
    SPOTS[num] = ("B%d" % (b + 1), (BACK_X[b], BACK_SPOT_Y, 8, 8), (BACK_X[b], BACK_CASH_Y, 8, 3), "-y (entrance)")
UNLOCK = {11: "Rebirth 1", 12: "Rebirth 2", 13: "Rebirth 3", 14: "Rebirth 4", 15: "Rebirth 5",
          16: "Extra Spots pass", 17: "Extra Spots pass"}

PIECES = {   # name: (x, y, w, d, height)
    "Entrance gap": (19, 0, 12, 1, 0),
    "Name board (on 2 posts)": (17, 0, 16, 1, 11),
    "Driveway (lane grey)": (19, -4, 12, 4, 0),
    "Lock pad": (11, 3, 6, 6, 1),
    "Lock board": (9, 3, 1, 6, 6.5),
    "Delivery crate": (2, 3, 6, 6, 6),
    "Spots-full sign": (2, 11, 6, 1, 4),
    "Spawn": (29, 10, 4, 4, 0),
    "Bag pad": (35, 3, 8, 8, 1),
    "Bag plinth": (43, 4, 6, 6, 1),
    "Bag frame": (45, 4, 2, 6, 13),
    "Bag": (44, 5, 4, 4, 8),
    "Bag sign": (44, 12, 1, 5, 6),
}
SPAWN_C = (31, 12)
BAG_C = (46, 7)
BAG_PAD_C = (39, 7)
ENTRANCE_C = (25, 0)

# ---- zone 1 (brief system 5, style guide section 4) ---------------------------------------------------------
ZONE1_Y = 236                  # zone 1 starts past the front wall
FIXED_PAD = (233, 276)         # 40 studs into zone 1, beside the lane, 12 x 12
ROLL_PADS = [(179, 296), (233, 316), (179, 336)]
HAZARD = (236, 261)


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def path_len(pts):
    return sum(dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))


def door(n):
    return to_world(n, *ENTRANCE_C)


def nearest_thief(n):
    return min((m for m in PLOTS if m != n), key=lambda m: dist(door(n), door(m)))


def farthest_thief(n):
    return max((m for m in PLOTS if m != n), key=lambda m: dist(door(n), door(m)))


# thief stands in the aisle beside the boss's cash pad to hold Steal
def hold_point(num):
    cell, sp, cash, _ = SPOTS[num]
    if cell.startswith("L"): return (14, sp[1] + 4)
    if cell.startswith("R"): return (36, sp[1] + 4)
    return (sp[0] + 4, 77)


def thief_route(victim, spot, thief=None):
    thief = thief or nearest_thief(victim)
    inside = dist(hold_point(spot), ENTRANCE_C)
    return inside, inside + dist(door(victim), door(thief))


def report():
    out = []
    p = out.append
    p("Walk times (walk 16, carry 12, Fast Carry 16 studs/s)")
    inside_bag = dist(BAG_PAD_C, ENTRANCE_C)
    for n in range(1, 9):
        to_gate = inside_bag + dist(door(n), GATE_C)
        to_pad = inside_bag + dist(door(n), GATE_C) + dist(GATE_C, FIXED_PAD) - 6
        p("plot %d: bag->gate %.0f (%.1fs); bag->zone1 fixed pad ring %.0f (run %.1fs, carry home %.1fs, Fast Carry %.1fs); nearest thief plot %d at %.0f, farthest %d at %.0f"
          % (n, to_gate, to_gate / WALK, to_pad, to_pad / WALK, to_pad / CARRY, to_pad / FAST_CARRY,
             nearest_thief(n), dist(door(n), door(nearest_thief(n))), farthest_thief(n), dist(door(n), door(farthest_thief(n)))))
    d_bag = dist(SPAWN_C, BAG_PAD_C) - 4
    p("spawn->bag pad edge %.0f (%.1fs); bag pad centre -> entrance %.0f (%.1fs)" % (d_bag, d_bag / WALK, inside_bag, inside_bag / WALK))
    far = max(path_len([ENTRANCE_C, hold_point(s)]) for s in range(1, 11))
    far17 = max(path_len([ENTRANCE_C, hold_point(s)]) for s in range(1, 18))
    p("entrance->furthest of the first 10 spots %.0f (walk %.1fs); of all 17 %.0f (%.1fs)" % (far, far / WALK, far17, far17 / WALK))
    p("")
    for victim, thief, label in ((2, 3, "corner pair (worst case)"), (3, 4, "neighbours along the back row"), (1, 2, "neighbours along a side"), (2, 7, "across the yard")):
        p("Thief %d -> victim %d (%s), doors %.0f apart" % (thief, victim, label, dist(door(victim), door(thief))))
        for spot in (1, 9, 16):
            inside, tot = thief_route(victim, spot, thief)
            p("  spot %d (%s): inside %.0f, to own door %.0f -> %.1fs (Fast %.1fs); catch radius %.0f (%.0f Fast)"
              % (spot, SPOTS[spot][0], inside, tot, tot / CARRY, tot / FAST_CARRY, tot / CARRY * CHASE + PUNCH_RANGE, tot / FAST_CARRY * CHASE + PUNCH_RANGE))
    p("")
    p("Owner's distance to the nearest thief's door from where they might be")
    for n in range(1, 9):
        td = door(nearest_thief(n))
        places = {"own bag": inside_bag + dist(door(n), td), "yard centre": dist((206, 165), td), "gate": dist(GATE_C, td),
                  "zone1 fixed pad": dist(GATE_C, FIXED_PAD) + dist(GATE_C, td), "zone1 last rolling pad": dist(GATE_C, ROLL_PADS[-1]) + dist(GATE_C, td)}
        p("victim plot %d (thief %d): " % (n, nearest_thief(n)) + "; ".join("%s %.0f (%.1fs)" % (k, v, v / CHASE) for k, v in places.items()))
    return out


if __name__ == "__main__":
    print(chr(10).join(report()))
    for n in range(1, 9):
        print(n, PLOTS[n], "door", door(n))
