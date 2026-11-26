"""Builds pitches/huss-for-bosses/ui-kit.figcraft (pitch step 3, the UI kit). Rebuilding replaces the file.

Run from anywhere:
  python ui-kit/src/build_kit.py <script.json>
  figcraft-cli run <script.json> --out pitches/huss-for-bosses/ui-kit.figcraft
  bash ui-kit/src/export.sh          (PNG of every board and screen into ui-kit/)

Pages: 1 Foundations, 2 Components, 3 Icons, 4 Screens phone (874 x 402), 5 Screens desktop (1920 x 1080).
Top-level frames are placed on a grid per page so nothing overlaps. Pictures: icons and scenes are Higgsfield
generations (concepts/higgsfield-log.md, round 3); boss portraits are STAND-INS cut from the round 2 mock line-up.
The stud tile is read from style/stud-ui-overlay-64.png at build time, so a new tile only needs a rebuild.
"""
import json, sys
import kitlib as k
from kitlib import *
import screens as sc
from screens import C

PAPER, NOTE = "#E9ECF3", "#4A5263"
ICE, LANE = "#9FD8F5", "#9AA3B2"       # the two brightest grounds in the game (style guide): the worst backgrounds
DS = 1920 / 1165.0


def cap(parent, s, x, y, size=13, w=None, color=NOTE):
    """Board annotation, not game UI."""
    props = dict(fontFamily=FONT, fontStyle="Bold", fontSize=size, fill=color)
    if w: props.update(textAutoResize="height")
    return node("text", parent, "Note/" + s[:24], x, y, w, None, text=s, **props)


def head(parent, s, x, y):
    return node("text", parent, "Heading/" + s[:24], x, y, None, None, text=s, fontFamily=FONT, fontStyle="Black", fontSize=22, fill=INK)


def board(name, w, h, x=0, y=0, title=None, sub=None):
    k.set_scale(1.0)
    b = F(None, name, x, y, w, h, fill=PAPER, clip=True)
    if title:
        node("text", b, "Title", 32, 22, None, None, text=title, fontFamily=FONT, fontStyle="Black", fontSize=30, fill=INK)
        if sub: cap(b, sub, 32, 62, 14, w=w - 64)
    return b


# ============================================================================================ page 1: foundations
add("page.rename", name="1 Foundations")
init_stud()
b = board("01-foundations", 1500, 1590, title="HUSS FOR BOSSES  UI KIT  1 FOUNDATIONS",
          sub="From style-guide.md (draft). Design frame 874 x 402, phone landscape. Every colour has one job. The stud tile is the motif: the square inset Roblox stud, never a round toy-brick stud.")
head(b, "PALETTE: ONE JOB EACH", 32, 104)
pal = [("panel", "Panel grey", "#B4BBC6", "Panel bodies", True), ("blue", "Plate blue", "#1F6FD6", "Header bars, screen titles, progress bars", True),
       ("red", "Huss red", "#E02A2A", "Your punch: Huss button, Power, filled pips, hearts", True), ("green", "Cash green", "#2FB341", "Earned cash, price buttons, Collect, ordinary confirms", True),
       ("gold", "Shop gold", "#FFC21A", "Robux: shop, Robux prices, Spin, bought tag", True), ("cyan", "Shield cyan", "#35C8F0", "The lock: shield, lock button, lock pad", True),
       ("orange", "Alarm orange", "#FF6A00", "Warnings, steal alerts, hazards, can't-be-undone confirms", True), ("yellow", "Flash yellow", "#FFF36B", "Hit feedback only: band, Perfect, impact star", False),
       ("white", "White", "#FFFFFF", "Text, wells, secondary buttons (Pick Up, Run, Back, cancel), close", False), (None, "Ink", "#101820", "Every outline, hard shadow, dark text", False),
       ("dis", "Disabled grey", "#8A919C", "A button that can't be used now", True), (None, "Empty", "#3A4250", "Empty pips, lost hearts, bar tracks", False)]
for i, (key, nm, hx, job, st) in enumerate(pal):
    x = 32 + (i % 6) * 240; y = 140 + (i // 6) * 150
    R(b, "Swatch/" + nm, x, y, 220, 64, hx, sw=3, studded=st)
    if hx == INK or hx == "#3A4250": T(b, "Aa 123", x + 12, y + 20, 18, WHITE, ol=False)
    elif key in INK_TEXT_ON: T(b, "Aa 123", x + 12, y + 20, 18, INK)
    else: T(b, "AA 123", x + 12, y + 20, 18, "#D5D9DF" if key == "dis" else WHITE)
    cap(b, nm + "  " + hx, x, y + 72, 14, color=INK)
    cap(b, job, x, y + 92, 13, w=220)
cap(b, "Text rule: white text always carries a 2 px ink outline and a hard ink shadow. On shop gold, flash yellow and white the text is ink with no outline. Lip = fill x 0.72.", 32, 440, 14, w=1430)

head(b, "RARITY TIERS: CHIPS, BOSS CARDS, NAME TAGS, THAT BOSS'S HEALTH BAR AND SPOT RIM. NEVER A BUTTON", 32, 486)
for i, (word, hx) in enumerate(TIERS):
    x = 32 + i * 240
    R(b, "TierSwatch/" + word, x, 522, 220, 44, hx, sw=3)
    r = row(b, "ChipRow", x, 533, 220, 22); chip(r, i)
    cap(b, word.capitalize() + "  " + hx, x, 574, 14, color=INK)
head(b, "FIGHT DIFFICULTY: TEXT COLOURS ONLY (THE NUMBER OVER A BOSS, THE BAND WORD)", 32, 616)
R(b, "Ground/lane", 32, 650, 1436, 44, LANE, sw=0)
dx = 48
for wd in ["EASY", "FAIR", "HARD", "VERY HARD", "BRUTAL", "NEAR IMPOSSIBLE"]:
    T(b, wd, dx, 662, 16, DIFF[wd]); cap(b, DIFF[wd], dx, 700, 12, color=INK)
    dx += 60 + len(wd) * 13
I(b, "i/skull", 26, dx - 50, 659)

Y0 = 742
head(b, "TYPE: MONTSERRAT, UPRIGHT, ONE FAMILY", 32, Y0)
types = [("Screen title", 22, "BOSS UPGRADE", "Black"), ("Huss label, GOOD, PERFECT", 20, "HUSS!", "Black"), ("Button, counter number", 18, "UPGRADE  $1,240", "Black"),
         ("Boss name, row title", 16, "CHOMP FROG", "Black"), ("Tier chip, bought tag, small label", 14, "LEGENDARY", "Black"),
         ("Body, descriptions, odds, lists", 14, "Earns $1 a second.", "Bold")]
R(b, "TypeGround/phone", 32, Y0 + 36, 700, 330, COL["panel"], sw=3, studded=True)
R(b, "TypeGround/desktop", 752, Y0 + 36, 716, 330, COL["panel"], sw=3, studded=True)
cap(b, "PHONE (design px, scale 1.0)", 32, Y0 + 374); cap(b, "DESKTOP 1080p (scale 1.65; outline 3 px)", 752, Y0 + 374)
yy = Y0 + 50
for nm, size, sample, wt in types:
    for (bx, s_) in ((32, 1.0), (752, DS)):
        k.set_scale(s_)
        gx, gy = (bx + 16) / s_, yy / s_
        if wt == "Bold":
            R(b, "Well", gx, gy - 2 / s_, 230, 26, WHITE, sw=2)
            body(b, sample, gx + 8, gy + 2 / s_)
        else:
            T(b, sample, gx, gy, size)
        k.set_scale(1.0)
        cap(b, "%s  %d px  %s" % (nm, round(size * s_), wt), bx + 420, yy + 6, 12, color=INK)
    yy += 30 + size * 1.25
cap(b, "No text under 14 px on any device. Numbers shorten at four digits and up: 48.2K, 1.25M. Body text longer than a line sits in a white well.", 32, Y0 + 396, 14, w=1430)

Y1 = Y0 + 444
head(b, "THE STUD TILE ON A PANEL", 32, Y1)
for i, (lab, s_) in enumerate([("PHONE: 16 px a tile", 1.0), ("DESKTOP: about 26 px a tile", DS)]):
    bx = 32 + i * 480
    k.set_scale(s_)
    pw = 440 / s_; ph_ = 200 / s_
    p = panel(b, "PanelSample/" + lab, bx / s_, (Y1 + 36) / s_, pw, ph_, "PANEL")
    well(p, 10, 57, pw - 20, 34 if s_ > 1 else 40)
    body(p, "A well is smooth and white.", 18, 64 if s_ > 1 else 68)
    if s_ == 1:
        button(p, "Sample", 10, 108, 200, 48, "green", [("i", "p/icon-cash", 28), "$400"])
        button(p, "Sample2", 220, 108, 150, 48, "white", ["PICK UP"])
    k.set_scale(1.0)
    cap(b, lab, bx, Y1 + 246, 13)
f = F(b, "TileCloseUp", 1000, Y1 + 36, 468, 200)
for i, kk in enumerate(["panel", "blue", "red", "green", "gold", "cyan", "orange", "dis"]):
    node("rectangle", f, "Tile32/" + kk, (i % 4) * 117, (i // 4) * 100, 110, 92, cornerRadius=4, fills=stud(COL[kk], 32), stroke=INK,
         strokeWeight=3, strokeAlign="outside")
cap(b, "Close-up at 32 px a tile (the largest allowed). One small sharp-cornered inset square a tile, 44% of the tile wide, the same colour as the surface, drawn by its edges: a dark L on the left and bottom, a faint light line on the top and right. Never under 12 px or over 32 px on screen. File: style/stud-ui-overlay-64.png.", 1000, Y1 + 246, 13, w=468)

Y2 = Y1 + 330
head(b, "SPACING, CORNERS, EDGES", 32, Y2)
rules = ["Corner radius 4 px everywhere. Nothing is a pill. The Huss button is the only round thing.",
         "Outline 3 px ink (2 px on chips, tags and wells, 4 px on the Huss button). Hard shadow: ink 35%, 5 px down, no blur.",
         "Panel padding 10 px, gap 8 px. Header bar 44 px with a 3 px ink line under it. Close: 36 px white button in a 44 px touch area.",
         "Buttons 48 px tall, never under 44. Lip 5 px. Huss button 120 px, never under 96 on screen. Tier chip and bought tag 22 px. Counter plate 32 px.",
         "Studs go on panels, header bars, buttons and counter plates. Not on wells, chips, the bought tag, icons, text, or anything under 28 px tall.",
         "Scale: one UIScale = min(width / 874, height / 402), x 0.75 on mouse-and-keyboard screens. About 1.0 on a phone, 1.35 on a tablet, 1.65 on a 1080p desktop."]
for i, s_ in enumerate(rules):
    cap(b, s_, 32, Y2 + 34 + i * 20, 14, color=INK)

# ============================================================================================ page 2: components
add("page.add", name="2 Components")
add("page.select", index=1)
b = board("02-components-buttons-panels", 1500, 1470, title="2 COMPONENTS: BUTTONS, PANELS, CHIPS, CARDS",
          sub="Phone scale. One meaning per button colour: red is Huss, green spends earned cash, collects or confirms an ordinary action, gold costs Robux, cyan is the lock, orange confirms what can't be undone, white is everything else.")
head(b, "BUTTON STATES", 32, 100)
kinds = [("green", [("i", "p/icon-cash", 28), "$400"]), ("gold", ["R$ 249"]), ("cyan", [("i", "p/icon-lock", 28), "LOCK"]), ("white", ["PICK UP"])]
states = [("default", "Default"), ("hover", "Hover (mouse): fill +8%, lifts 1 px"), ("pressed", "Pressed: face drops 4 px, fill x 0.9"),
          ("disabled", "Disabled: grey, 2 px lip; a tap shakes it")]
for j, (st, lab) in enumerate(states):
    cap(b, lab, 32, 152 + j * 70, 13, w=190)
    for i, (kind, items) in enumerate(kinds):
        if kind == "gold" and st == "disabled":
            cap(b, "Robux buttons are never grey unless they truly can't be used.", 250 + i * 200, 142 + j * 70, 12, w=176); continue
        button(b, "Button/%s/%s" % (kind, st), 250 + i * 200, 136 + j * 70, 170, 48, kind, items, state=st)
cap(b, "GREEN: earned cash, collect, ok", 250, 114, 12); cap(b, "GOLD: costs Robux", 450, 114, 12); cap(b, "CYAN: the base lock", 650, 114, 12); cap(b, "WHITE: everything else", 850, 114, 12)
cap(b, "Locked by progress: disabled look, a padlock, the requirement as the label.", 32, 428, 13, w=190)
button(b, "Button/locked", 250, 424, 190, 48, "white", [("i", "i/padlock", 26), "POWER 500"], state="disabled")
button(b, "Button/locked rebirth", 460, 424, 210, 48, "white", [("i", "i/padlock", 26), "POWER 10M"], state="disabled")
cap(b, "Greyed with a reason: disabled look, the reason as the label.", 32, 498, 13, w=190)
for i, (lab, w_) in enumerate([("JUST JOINED", 170), ("INSTANT SHIELD", 200), ("BROKEN RECENTLY, 3:20", 280)]):
    button(b, "Button/reason/" + lab, 250 + [0, 190, 410][i], 494, w_, 48, "gold", [("t", lab, 16)], state="disabled", size=16)

head(b, "EVERY PRICE IS ON A BUTTON", 1060, 100)
button(b, "Price/cash", 1060, 136, 150, 48, "green", [("i", "p/icon-cash", 28), "$51"])
button(b, "Price/cash big", 1230, 136, 238, 54, "green", [("t", "UPGRADE", 20), ("i", "p/icon-cash", 32), ("t", "$51", 20)], size=20, lip=6)
button(b, "Price/robux", 1060, 206, 150, 48, "gold", ["R$ 249"])
button(b, "Price/cash pack", 1230, 206, 238, 48, "gold", [("i", "p/icon-cash", 24), ("t", "$4,500", 16), ("t", "R$ 29", 16)], size=16)
button(b, "Price/break shield", 1060, 270, 250, 48, "gold", [("i", "i/shield-breaker", 30), ("t", "BREAK SHIELD", 16), ("t", "R$ 39", 16)], size=16)
cap(b, "Cash: the cash icon and the amount. Robux: gold, ink text; a cash pack shows the exact cash it gives. R$ is a stand-in for Roblox's own Robux glyph, which the build uses. No struck-out prices, no \"% off\", no countdowns.", 1060, 330, 13, w=408)
head(b, "SMALL CONTROLS", 1060, 410)
k.close_btn(b, 1060, 446); cap(b, "Close: white with an ink X.\nNothing that closes, cancels or warns is red.", 1106, 448, 13)
sc.toggle(b, 1060, 540, True); sc.toggle(b, 1134, 540, False)
cap(b, "Auto Punch switch (bag panel): on, off", 1210, 548, 13)
k.keycap(b, 1060, 502, "F"); k.keycap(b, 1090, 502, "E"); k.keycap(b, 1120, 502, "Q"); cap(b, "Input glyph on a small ink plate (keyboard).\nGamepad shows the platform's glyph.", 1152, 500, 13)

Y = 590
head(b, "PANEL, HEADER BAR, WELLS, LIST ROWS", 32, Y)
p = panel(b, "Panel/Sample", 32, Y + 40, 520, 250, "PUNCHING BAG", "i/bag")
well(p, 10, 57, 500, 78)
I(p, "i/strength", 54, 20, 69); T(p, "PUNCH STRENGTH  LEVEL 2", 86, 65, 16, INK)
body(p, "Each punch gives x1.35 Power.\nNext level: x1.82.", 86, 87, 260)
button(p, "Buy", 352, 72, 148, 48, "green", [("i", "p/icon-cash", 28), "$400"])
well(p, 10, 143, 500, 44); body(p, "A list row is a well: white, smooth, 2 px ink outline, radius 4.", 20, 156)
button(p, "Other", 10, 195, 150, 46, "white", ["BACK"])
p = panel(b, "Panel/Sample gold", 32, Y + 310, 520, 60, "SHOP", "p/icon-shop", head="gold")
cap(b, "Panel grey with the stud tile, 3 px ink outline, radius 4, hard shadow. The shop and the Starter Pack carry a gold header (Robux). One hero per screen. Nothing is see-through except the 45% ink dim behind an open panel.", 32, Y + 384, 13, w=520)

head(b, "TIER CHIPS AND THE BOUGHT TAG", 600, Y)
for i in range(6):
    chip(b, i, 600 + (i % 3) * 150, Y + 40 + (i // 3) * 34)
r = row(b, "ChipAndTag", 600, Y + 112, 240, 22, main="min", gap=6); chip(r, 3); tag(r)
cap(b, "Smooth, 22 px, the tier colour, the word in 14 px caps. Never a dot or a strip. The gold BOUGHT tag sits right of the chip on a boss that came from the shop (the Lucky Spin or the Starter Pack). It can be stolen like any boss; its buyer keeps it through rebirth.", 600, Y + 144, 13, w=440)
head(b, "COUNTER PLATES", 600, Y + 230)
plate(b, "Power", 612, Y + 272, 104, "red", "p/icon-power", "312")
plate(b, "Cash", 746, Y + 272, 118, "green", "p/icon-cash", "$1,240")
plate(b, "Lock", 894, Y + 272, 112, "cyan", "p/icon-lock", "0:42")
plate(b, "Power big", 612, Y + 322, 120, "red", "p/icon-power", "48.2K")
plate(b, "Cash big", 762, Y + 322, 130, "green", "p/icon-cash", "$1.25M")
plate(b, "Tickets", 922, Y + 322, 76, "gold", "i/ticket", "2")
cap(b, "Studded, 32 px, icon 36 px overlapping the left edge by 8. Not pressable, so no lip.", 600, Y + 366, 13, w=440)

head(b, "REWARD DISPLAY", 1090, Y)
R(b, "Ground", 1090, Y + 40, 378, 120, ICE, sw=0)
r = row(b, "Reward/cash", 1100, Y + 52, 120, 34, gap=4); I(r, "p/icon-cash", 30); T(r, "+$30", size=18)
r = row(b, "Reward/power", 1230, Y + 52, 110, 34, gap=4); I(r, "p/icon-power", 30); T(r, "+3", size=18)
r = row(b, "Reward/power big", 1340, Y + 48, 120, 40, gap=4); I(r, "p/icon-power", 36); T(r, "+6", size=22, color=COL["yellow"])
r = row(b, "Reward/boss", 1100, Y + 100, 360, 44, gap=8); I(r, "s/chomp-frog", 40); T(r, "CHOMP FROG", size=16); chip(r, 0)
cap(b, "A gain pops at its source and flies to its counter in 0.35 s; the counter counts up. The big huss (third punch of a clean combo) is flash yellow. Shown on the Ice Blocks blue, the brightest ground.", 1090, Y + 168, 13, w=378)
head(b, "LEVEL PIPS", 1090, Y + 250)
level_pips(b, 1090, Y + 290, 3, size=11); cap(b, "Boss level: 20 square pips in cash green.", 1090, Y + 310, 13)

Y = 1040
head(b, "BOSS CARDS: FILLED WITH THE TIER COLOUR", 32, Y)
cards = [(0, "s/chomp-frog", "CHOMP FROG"), (1, "s/snap-scorpion", "SNAP SCORPION"), (2, "s/bit-shark", "BIT SHARK"), (3, "s/frost-byte", "FROST BYTE"),
         (4, None, "EMBER DRAKE"), (5, "s/star-golem", "STAR GOLEM")]
for i, (t, key, nm) in enumerate(cards):
    boss_card(b, nm, 32 + i * 176, Y + 40, 160, 206, t, key, title=nm)
well(b, 1100, Y + 40, 368, 206)
body(b, "STAND-IN: final portraits are renders of the built models.\n\nThese five pictures are crops of the round 2 mock line-up. Ember Drake has no stand-in: its mock has the flame tail the brief forbids, so its well reads MODEL RENDER.\n\nThe UI never shows a picture of a boss that is not built.", 1112, Y + 50, 344)
head(b, "BOSS NAME TAG (WORLD)", 32, Y + 270)
R(b, "Ground", 32, Y + 306, 760, 80, LANE, sw=0)
for i, (band, num, extra) in enumerate([("FAIR", "25", None), ("HARD", "400", None), ("VERY HARD", "650", None), ("NEAR IMPOSSIBLE", "1,500", "i/skull")]):
    f = row(b, "NameTag/%d" % i, 40 + i * 186, Y + 312, 178, 68, vertical=True, gap=2)
    T(f, ["CHOMP FROG", "SNAP SCORPION", "PRICKLE GECKO", "DUNE COBRA"][i], size=14)
    r = row(f, "PowerRow", None, None, None, 26, gap=4, sizingH="hug")
    I(r, "p/icon-power", 22); T(r, num, size=18, color=DIFF[band])
    if extra: I(r, extra, 22)
    r2 = row(f, "ChipRow", None, None, None, 22, gap=4, sizingH="hug"); chip(r2, [0, 1, 2, 4][i])
    if i == 1: tag(r2)
cap(b, "The number over a boss is its Power, coloured by how hard the fight would be for you: green (easy, fair), yellow (hard), orange (very hard), red (brutal), red with a skull (near impossible). On a placed boss the tag also carries BOUGHT when it applies.", 810, Y + 310, 13, w=650)

# ---------------------------------------------------------------------------------------------- HUD parts
b = board("03-components-hud", 1500, 1640 + 70 + 32, x=1600, title="2 COMPONENTS: THE HUSS BUTTON, TIMING RING, PIPS AND HUD PARTS",
          sub="Phone scale, drawn on the two brightest grounds in the game (Ice Blocks blue and the lane grey) so the outline rule is tested where it is hardest.")
head(b, "THE HUSS BUTTON AND THE TIMING RING", 32, 100)
R(b, "Ground/ice", 32, 136, 1436, 300, ICE, sw=0)
hs = [("idle", 0, "Idle: the hit band waits", {}), ("closing", 1, "Closing: the white ring shrinks from 1.6 x onto the band", {}),
      ("perfect", 2, "Perfect: band and face flash, impact star, pop in flash yellow", {}), ("good", 2, "Good: impact star, white pop, the three-punch burst starts", {}),
      ("miss", 0, "Miss: ring turns grey, button shakes, no burst, pips clear", {}), ("disabled", 0, "Disabled: carrying a boss", {}),
      ("plain", 0, "Beside a thief: plain punch, no ring, no band", {"label": "PUNCH!"})]
for i, (st, n, lab, kw) in enumerate(hs):
    cx = 32 + 104 + i * 205
    huss(b, cx, 300, st, n=n, **kw)
    cap(b, lab, cx - 92, 444, 12, w=186)
head(b, "THE THREE PIPS: HUSS HUSS HUSS", 32, 500)
R(b, "Ground/lane", 32, 536, 700, 70, LANE, sw=0)
for i, (n, cl, lab) in enumerate([(0, False, "0 of 3"), (1, False, "1: huss"), (2, False, "2: huss huss"), (3, False, "3: the big huss (x2)"), (3, True, "Clean combo: all flash, then clear")]):
    k.pips(b, 100 + i * 140, 552, n, clean=cl)
    cap(b, lab, 100 + i * 140 - 62, 582, 12, w=126, color=INK)
cap(b, "18 px squares, 4 px apart, centred above the button. Empty #3A4250. One timed tap launches the burst, and the pips fill with its three punches: each pops to 1.25 in 0.08 s; the third (the big huss) pops to 1.4 with a bigger star. A Miss launches no burst and the pips clear.", 750, 540, 13, w=700)

head(b, "ZONE STRIP, REBIRTH BAR, PROGRESS BARS (PLATE BLUE)", 32, 640)
R(b, "Ground/ice2", 32, 676, 1436, 120, ICE, sw=0)
zone_strip(b, 48, 686, 250, 1); zone_strip(b, 330, 686, 250, 4)
cap(b, "Zone strip: six segments; reached zones are plate blue; the glove is you.", 48, 740, 12, w=530, color=INK)
button(b, "Rebirth", 640, 684, 56, 50, "white", [("i", "p/icon-rebirth", 34)]); T(b, "REBIRTH", 628, 734, 14, w=80, align="center")
bar(b, "RebirthBar", 636, 756, 64, 10, 0.42, COL["blue"])
bar(b, "RebirthBar/wide", 730, 700, 300, 22, 0.42, COL["blue"], "POWER 4.2M / 10M")
cap(b, "Rebirth bar: Power toward the next rebirth.", 730, 732, 12, w=300, color=INK)
bar(b, "HealthBar/common", 1070, 700, 180, 14, 0.6, TIERS[0][1]); bar(b, "HealthBar/epic", 1070, 724, 180, 14, 0.35, TIERS[3][1])
cap(b, "Boss health: 14 px, the boss's tier colour", 1070, 746, 12, color=INK)
level_pips(b, 1270, 700, 3, total=10, size=11); cap(b, "Level pips: cash green", 1270, 722, 12, color=INK)

head(b, "BASE LOCK: SHIELD PLATE, COOLDOWN, BUTTON, BREAK SHIELD", 32, 830)
R(b, "Ground/lane2", 32, 866, 1436, 190, LANE, sw=0)
plate(b, "Lock/up", 52, 880, 112, "cyan", "p/icon-lock", "0:42"); cap(b, "Shield up:\ntime left", 44, 920, 12, color=INK)
plate(b, "Lock/cooldown", 200, 880, 112, "dis", "i/shield-down", "0:31"); cap(b, "Shield down:\ncooldown", 192, 920, 12, color=INK)
button(b, "ShieldButton", 350, 874, 56, 50, "cyan", [("i", "p/icon-lock", 34)]); T(b, "LOCK", 338, 924, 14, w=80, align="center")
cap(b, "Up: cyan", 338, 944, 12, w=80, color=INK)
button(b, "ShieldButton/disabled", 440, 874, 56, 50, "cyan", [("i", "p/icon-lock", 34)], state="disabled"); T(b, "LOCK", 428, 924, 14, w=80, align="center")
cap(b, "Cooldown: grey", 428, 944, 12, w=80, color=INK)
cap(b, "READY (shield down, can be raised): no shield plate is drawn, and the lock button is cyan with its lip, as when the shield is up. Grey always and only means cooldown; the button is never grey while the shield is up.", 130, 984, 12, w=700, color=INK)
button(b, "ShieldButton/ready", 52, 976, 56, 50, "cyan", [("i", "p/icon-lock", 34)]); T(b, "LOCK", 40, 1026, 14, w=80, align="center")
button(b, "BreakShield", 540, 876, 250, 48, "gold", [("i", "i/shield-breaker", 30), ("t", "BREAK SHIELD", 16), ("t", "R$ 39", 16)], size=16)
for i, (lab, w_) in enumerate([("JUST JOINED", 160), ("INSTANT SHIELD", 190), ("BROKEN RECENTLY, 3:20", 270)]):
    button(b, "BreakShield/greyed " + lab, 810 + [0, 170, 370][i], 876, w_, 48, "gold", [("t", lab, 16)], state="disabled", size=16)
cap(b, "Break shield shows on another player's shield when you stand at it: gold when it can be broken, greyed with the reason when it can't.", 540, 934, 12, w=900, color=INK)

k.SHIFT.update(parent=b, **{"from": 1000, "by": 70})   # the lock section above grew by 70: everything below moves down
head(b, "FIGHT OVERLAY, HEARTS, DIFFICULTY BANDS", 32, 1020)
R(b, "Ground/ice3", 32, 1056, 1436, 110, ICE, sw=0)
sc.fight_overlay(b, 48, 1070, 380)
dx = 460
for wd in ["EASY", "FAIR", "HARD", "VERY HARD", "BRUTAL", "NEAR IMPOSSIBLE"]:
    T(b, wd, dx, 1072, 14, DIFF[wd]); dx += 26 + len(wd) * 11
I(b, "i/skull", 20, dx - 14, 1070 + 70)
h = row(b, "Hearts/3", 460, 1108, 90, 28, gap=4, main="min"); I(h, "i/heart", 26); I(h, "i/heart", 26); I(h, "i/heart", 26)
h = row(b, "Hearts/1", 580, 1108, 90, 28, gap=4, main="min"); I(h, "i/heart", 26); I(h, "i/heart-lost", 26); I(h, "i/heart-lost", 26)
button(b, "Run", 720, 1102, 104, 48, "white", [("i", "i/run", 26), "RUN"])
cap(b, "The band is read once, when the fight starts, and is written as a word in its colour. Run sits top left; nothing covers the Huss button.", 850, 1104, 12, w=600, color=INK)

head(b, "STEAL AND SHIELD ALERTS, CARRY INDICATOR, HAZARD WARNING, BOSS BEATEN", 32, 1200)
R(b, "Ground/lane3", 32, 1236, 1436, 170, LANE, sw=0)
banner(b, "StealAlert", 48, 1248, 470, "orange", "i/alarm", "YOUR CHOMP FROG IS BEING STOLEN!", arrow=20)
banner(b, "ShieldBroken", 48, 1300, 420, "orange", "i/shield-broken", sc.OTHER + " BROKE YOUR SHIELD!", arrow=180)
banner(b, "ThiefStrip", 48, 1352, 300, "green", "i/steal", "GET IT HOME!", size=18, arrow=-90)
sc.steal_alert_bought(b, "StealAlert/bought (the BOUGHT tag beside the name)", 356, 1352, 512)
sc.carry_tag(b, 560, 1250, 300)
banner(b, "HazardWarning", 600, 1310, 220, "orange", "i/hazard", "ROLLING LOG", h=36)
sc.beaten_banner(b, 900, 1248)
cap(b, "Banners: alarm-orange studded plates, 40 px, top centre, with a square arrow chip that turns toward the thief or home. \"Get it home!\" for the thief is the same plate in cash green. Never an offer on or beside an alert. When the stolen boss was bought, the BOUGHT tag sits beside its name (second row, middle).", 900, 1354, 12, w=540, color=INK)

head(b, "PROMPTS AND TOASTS", 32, 1440)
R(b, "Ground/ice4", 32, 1476, 1436, 172, ICE, sw=0)
k.prompt(b, "Prompt/Place touch", 48, 1490, 130, None, "PLACE", icon="i/place")
k.prompt(b, "Prompt/PickUp key", 192, 1490, 140, "E", "PICK UP")
k.prompt(b, "Prompt/Grab", 346, 1490, 140, None, "GRAB  5 s", icon="i/grab")
k.prompt(b, "Prompt/Steal 0", 500, 1490, 190, None, "HOLD TO STEAL", hold=0.0, icon="i/steal")
k.prompt(b, "Prompt/Steal 75", 704, 1490, 190, "E", "HOLD TO STEAL", hold=0.75)
k.prompt(b, "Prompt/Steal greyed (Can't be stolen, padlock)", 500, 1584, 236, None, "CAN'T BE STOLEN", icon="i/padlock", greyed=True)
cap(b, "Can't be stolen: the Steal prompt greyed, with a padlock, for a thief who can't take this boss (a bought boss where paid-item trading is off). No reason is shown.", 48, 1586, 12, w=430, color=INK)
cap(b, "A prompt is a white studded plate: the input glyph on a small ink plate (on touch, the action's icon), then the word. The Steal hold fills a square frame around the glyph clockwise in alarm orange over 2 s.", 48, 1548, 12, w=850, color=INK)
toast(b, "Toast/Info", 930, 1488, 250, "panel", "i/crate", "SENT TO YOUR CRATE")
toast(b, "Toast/NotEnoughCash", 1200, 1488, 250, "orange", "p/icon-cash", "NOT ENOUGH CASH")
toast(b, "Toast/SpotsFull", 930, 1530, 250, "orange", None, "SPOTS FULL")
toast(b, "Toast/PurchaseDone", 1200, 1530, 250, "green", "i/check", "PURCHASE DONE")
button(b, "ExtraSpots (offered on the Spots full message)", 930, 1570, 250, 44, "gold", [("i", "i/extra-spots", 26), ("t", "+2 SPOTS", 14), ("t", "R$ 249", 14)], size=14, lip=4)
cap(b, "Toasts: 32 px plates, bottom centre. Grey: information. Orange: can't. Green: purchase done.", 1200, 1572, 12, w=250, color=INK)

# the whole shop list, unclipped, so every product card can be read
k.SHIFT.update(parent=None, **{"from": 0, "by": 0})
b = board("05-shop-full-list", 760, 1480 + 194, x=3200, title="THE SHOP: THE WHOLE SCROLLING LIST", sub="Phone scale. 19 products: 10 passes (the Starter Pack is one), 9 developer products. Shown for an Auto Punch owner, the only player offered Perfect Auto Punch.")
h_ = F(b, "Holder", 0, 80, 760, 1400 + 194)
sc.shop_panel(h_, C(False), full=True)

# ============================================================================================ page 3: icons
add("page.add", name="3 Icons")
add("page.select", index=2)
ICONS = [("STATS", [("p/icon-power", "Power"), ("p/icon-cash", "Cash"), ("i/strength", "Punch Strength"), ("i/speed", "Punch Speed"), ("i/ticket", "Spin ticket"), ("i/heart", "Heart"), ("i/heart-lost", "Heart lost"), ("i/star", "Rebirth star")]),
         ("HUD AND ACTIONS", [("p/icon-glove", "Huss glove"), ("p/icon-shop", "Shop"), ("p/icon-rebirth", "Rebirth"), ("p/icon-up", "Upgrade"), ("i/pickup", "Pick up"), ("i/place", "Place"), ("i/grab", "Grab"), ("i/steal", "Steal"), ("i/sell", "Sell"), ("i/swap", "Swap"), ("i/run", "Run"), ("i/check", "Done"),
                              ("i/settings", "Settings"), ("i/music", "Music"), ("i/sound", "Effects"), ("i/bag", "Bag panel"), ("p/icon-spin", "Lucky Spin"), ("i/arrow-yellow", "First-session arrow"), ("i/arrow-white", "Pointer arrow"), ("i/trophy", "Boss beaten")]),
         ("STATUS", [("p/icon-lock", "Lock shield"), ("i/shield", "Shield"), ("i/shield-down", "Shield down"), ("i/shield-broken", "Shield broken"), ("i/padlock", "Locked"), ("i/timer", "Timer"), ("i/alarm", "Steal alert"), ("i/hazard", "Hazard"), ("i/skull", "Near impossible"), ("i/offline", "Offline earnings"), ("i/crate", "Delivery crate")]),
         ("ZONE BADGES", [("i/zone%d" % (i + 1), "%d %s" % (i + 1, ZONES[i][0].title())) for i in range(6)]),
         ("SHOP PRODUCTS (19)", [("i/auto-punch", "Auto Punch"), ("i/perfect-auto-punch", "Perfect Auto Punch"), ("i/power2x", "2x Power"), ("i/cash2x", "2x Cash"), ("i/fast-carry", "Fast Carry"), ("i/long-lock", "Long Lock"), ("i/extra-spots", "Extra Spots"), ("i/quick-hands", "Quick Hands"), ("i/iron-grip", "Iron Grip"), ("i/starter-pack", "Starter Pack"),
                                 ("i/cash-small", "Small Cash Pack"), ("i/cash-medium", "Medium Cash Pack"), ("i/cash-large", "Large Cash Pack"), ("i/cash-huge", "Huge Cash Pack"), ("i/spin1", "Lucky Boss Spin x1"), ("i/spin3", "Lucky Boss Spin x3"), ("i/spin10", "Lucky Boss Spin x10"), ("i/instant-shield", "Instant Shield"), ("i/shield-breaker", "Shield Breaker")])]
rows_ = sum((len(v) + 11) // 12 for _, v in ICONS)
bh = 130 + rows_ * 262 + len(ICONS) * 44
b = board("04-icons", 1500, bh, title="3 ICONS",
          sub="Generated in Higgsfield in one style (cube-built objects, flat colours, thick ink outline, white rim), cut and placed here. Icon check: each icon at 60, 36 and 28 px on white, on ink, and on the Ice Blocks blue, the brightest ground in the game.")
y = 110
for fam, items in ICONS:
    head(b, fam, 32, y); y += 40
    for i, (key, lab) in enumerate(items):
        cx = 32 + (i % 12) * 120; cy = y + (i // 12) * 262
        for j, (g, bx_) in enumerate([(WHITE, 60), (INK, 36), (ICE, 28)]):
            R(b, "Check/%s/%d" % (lab, j), cx, cy + j * 70, 108, 66, g, sw=2 if j == 0 else 0, r=4)
            I(b, key, bx_, cx + (108 - bx_) / 2, cy + j * 70 + (66 - bx_) / 2)
        cap(b, lab, cx, cy + 214, 12, w=110, color=INK)
    y += ((len(items) + 11) // 12) * 262 + 4

# ============================================================================================ pages 4 and 5: screens
def modal(fn, **kw):
    power = kw.pop("power", None)
    return lambda r, c: (sc.hud(r, c, "base", quiet=True, power=power), sc.dim(r, c), fn(r, c, **kw))

SCREENS = [
    ("hud-base", "scene-base", lambda r, c: sc.hud(r, c, "base")),
    ("hud-fight", "scene-fight", lambda r, c: sc.hud(r, c, "fight")),
    ("hud-boss-beaten", "scene-fight", lambda r, c: sc.hud(r, c, "beaten")),
    ("hud-carry-hazard", "scene-carry", lambda r, c: sc.hud(r, c, "carry")),
    ("hud-place-sell", "scene-base", lambda r, c: sc.hud(r, c, "place")),
    ("alert-steal-owner", "scene-base", lambda r, c: sc.hud(r, c, "steal_owner")),
    ("alert-steal-thief", "scene-carry", lambda r, c: sc.hud(r, c, "steal_thief")),
    ("alert-shield-broken", "scene-fight", lambda r, c: sc.hud(r, c, "shield_broken")),
    ("prompt-break-shield", "scene-base", lambda r, c: sc.hud(r, c, "visitor_shield")),
    ("prompt-steal-hold", "scene-base", lambda r, c: sc.hud(r, c, "visitor_steal")),
    ("boss-panel", "scene-base", modal(sc.boss_panel)),
    ("bag-panel", "scene-base", modal(sc.bag_panel)),
    ("shop", "scene-base", modal(sc.shop_panel)),
    ("starter-pack", "scene-base", modal(sc.starter_panel)),
    ("lucky-spin", "scene-base", modal(sc.spin_panel)),
    ("lucky-spin-result", "scene-base", modal(sc.spin_result)),
    ("rebirth", "scene-base", modal(sc.rebirth_panel, power="10.4M")),
    ("rebirth-confirm", "scene-base", modal(sc.confirm_panel, kind="rebirth", power="10.4M")),
    ("offline-earnings", "scene-base", modal(sc.offline_panel)),
    ("confirm-sell", "scene-base", modal(sc.confirm_panel, kind="sell")),
    ("confirm-swap-bought", "scene-base", modal(sc.confirm_panel, kind="swap_bought")),
    ("settings", "scene-base", modal(sc.settings_panel)),
]
OY = {"scene-fight": 0, "scene-carry": -80, "scene-base": -62}
for pi, (desktop, pname, cols) in enumerate([(False, "4 Screens phone 874x402", 4), (True, "5 Screens desktop 1920x1080", 4)]):
    add("page.add", name=pname)
    add("page.select", index=3 + pi)
    c = C(desktop)
    for i, (name, scene, fn) in enumerate(SCREENS):
        x = (i % cols) * (c.pw + (160 if desktop else 80)); y = (i // cols) * (c.ph + (160 if desktop else 80))
        root = sc.screen(("desktop-" if desktop else "phone-") + name, c, x, y, scene, OY[scene])
        fn(root, c)
add("page.select", index=0)

json.dump(cmds, open(sys.argv[1], "w"))
print(len(cmds), "commands")
