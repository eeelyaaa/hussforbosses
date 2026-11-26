"""The screens of the Huss for Bosses UI kit: the 13 screens of brief.md's content table, at phone and desktop size.
Every word and number is from brief.md (draft numbers, as read 2026-11-25 14:20) and style-guide.md section 6."""
import kitlib as k
from kitlib import *

OTHER = "PLAYER2"      # stands for another player's name


class C:
    """A screen canvas in design px. Phone: 874 x 402 at scale 1. Desktop: 1165 x 655 at scale 1.648 = 1920 x 1080."""
    def __init__(s, desktop):
        s.desktop = desktop
        s.S = 1920 / 1165.0 if desktop else 1.0
        s.W, s.H = (1165, 655) if desktop else (874, 402)
        s.pw, s.ph = (1920, 1080) if desktop else (874, 402)


def screen(name, c, x, y, scene, oy=-45):
    """Root frame at page position x, y, with a generated scene behind it (a backdrop, not the game)."""
    k.set_scale(1.0)
    root = F(None, name, x, y, c.pw, c.ph, fill=INK, clip=True)
    ih = c.pw * 1520 / 2688.0
    add("image.place", path=HERE + scene + ".png", parent=root, x=0, y=0 if c.desktop else oy, width=c.pw, height=ih,
        name="BACKDROP generated scene (not the game)")
    k.set_scale(c.S)
    return root


def dim(root, c):
    R(root, "Dim (ink 45%, the only see-through thing)", 0, 0, c.W, c.H, "#10182073", r=0)


def ghost(root, name, x, y, d):
    node("ellipse", root, "REFERENCE " + name, x, y, d, d, fill="#00000040", stroke="#FFFFFF66", strokeWeight=2, strokeAlign="inside")


def hud(root, c, mode="base", quiet=False, power=None):
    """The HUD. mode: base | fight | beaten | carry | place | steal_owner | steal_thief | shield_broken |
    visitor_shield | visitor_steal."""
    W, H, dk = c.W, c.H, c.desktop
    for i in range(2):
        R(root, "REFERENCE Roblox top bar button", 14 + i * 44, 8, 36, 36, "#00000066", r=10)
    if not dk:
        ghost(root, "thumbstick (Roblox)", 34, 262, 110)
        ghost(root, "jump button (Roblox)", 772, 300, 80)
    power = power or {"fight": "20", "beaten": "20"}.get(mode, "312")
    plate(root, "Power (counter; only goes up)", 118, 10, 104, "red", "p/icon-power", power)
    plate(root, "Cash (counter)", 246, 10, 118, "green", "p/icon-cash", "$1,240")
    zw = 250
    zone_strip(root, (W - zw) / 2 if dk else 406, 6, zw, 1)
    sx = W - 14 - 112
    if mode in ("steal_owner", "shield_broken", "carry"):
        plate(root, "ShieldPlate (cooldown, disabled grey)", sx, 10, 112, "dis", "i/shield-down", "0:58" if mode == "shield_broken" else "0:31")
    elif mode in ("fight", "beaten"):
        plate(root, "ShieldPlate (time left, cyan)", sx, 10, 112, "cyan", "p/icon-lock", "0:18")
    else:
        plate(root, "ShieldPlate (time left, cyan)", sx, 10, 112, "cyan", "p/icon-lock", "0:42")
    if mode == "fight":
        button(root, "Run (white, top left; ends the fight as a loss)", 14, 60, 104, 48, "white", [("i", "i/run", 26), "RUN"], size=18)
        if dk: keycap(root, 106, 52, "BKSP", w=44)
    else:
        button(root, "Shop (gold, icon over word)", 14, 60, 56, 50, "gold", [("i", "p/icon-shop", 34)])
        T(root, "SHOP", 2, 110, 14, w=80, align="center")
        button(root, "Rebirth (white, a plate-blue bar under it)", 14, 136, 56, 50, "white", [("i", "p/icon-rebirth", 34)])
        T(root, "REBIRTH", 2, 186, 14, w=80, align="center")
        bar(root, "RebirthBar (Power toward 10M, plate blue)", 10, 206, 64, 10, 1.0 if power == "10.4M" else 0.04, COL["blue"])
        if dk:
            keycap(root, 58, 52, "B"); keycap(root, 58, 128, "N")
    if quiet: return
    hx, hy = (W - 184, 262) if not dk else (W - 150, H - 150)
    key = "F" if dk else None
    mid = lambda w: (W - w) / 2
    if mode == "base":
        huss(root, hx, hy, "closing", n=1, key=key)
        button(root, "ShieldButton (cyan = shield up, matches the cyan plate; grey is cooldown only; only inside your own base)", W - 14 - 56, 54, 56, 50, "cyan",
               [("i", "p/icon-lock", 34)])
        T(root, "LOCK", W - 14 - 68, 104, 14, w=80, align="center")
        if dk: keycap(root, W - 26, 46, "Q")
        r = row(root, "PowerGain (flies to the Power counter)", hx - 190, hy - 96, 130, 30, gap=4)
        I(r, "p/icon-power", 26); T(r, "+3", size=18)
    elif mode == "fight":
        huss(root, hx, hy, "closing", n=2, key=key, ring=1.22)
        fight_overlay(root, mid(380), 48)
    elif mode == "beaten":
        huss(root, hx, hy, "disabled", key=key)
        beaten_banner(root, mid(400), 54)
    elif mode == "carry":
        huss(root, hx, hy, "disabled", key=key)
        carry_tag(root, mid(300), 54, 300)
        banner(root, "HazardWarning (0.6 s before the hazard arrives)", mid(220), 106, 220, "orange", "i/hazard", "ROLLING LOG", h=36)
    elif mode == "place":
        huss(root, hx, hy, "disabled", key=key)
        carry_tag(root, mid(300), 54, 300)
        px_, py_ = (290, 190) if not dk else (W * 0.30, H * 0.47)
        I(root, "i/arrow-yellow", 40, px_ + 45, py_ - 46, name="ImageLabel/FirstSessionArrow (bounces over its target)")
        prompt(root, "Prompt/Place (on the glowing empty spot)", px_, py_, 130, "E" if dk else None, "PLACE", icon="i/place")
        button(root, "Sell (green, price on it; only while carrying inside your own base)", W - 14 - 132, 126, 132, 48, "green",
               [("i", "i/sell", 26), "SELL $30"], size=16)
        button(root, "ShieldButton (cyan: the shield is up, as the plate shows; grey is cooldown only)", W - 14 - 56, 54, 56, 50, "cyan",
               [("i", "p/icon-lock", 34)])
        T(root, "LOCK", W - 14 - 68, 104, 14, w=80, align="center")
    elif mode == "steal_owner":
        huss(root, hx, hy, "plain", label="PUNCH!", key=key)
        banner(root, "StealAlert (owner; from the moment the hold completes)", mid(470), 54, 470, "orange", "i/alarm",
               "YOUR CHOMP FROG IS BEING STOLEN!", arrow=20)
    elif mode == "steal_thief":
        huss(root, hx, hy, "disabled", key=key)
        banner(root, "ThiefStrip (cash green)", mid(300), 54, 300, "green", "i/steal", "GET IT HOME!", size=18, arrow=-90)
        carry_tag(root, mid(300), 104, 300, stolen=True)
    elif mode == "shield_broken":
        huss(root, hx, hy, "idle", key=key)
        banner(root, "ShieldBrokenAlert (owner; arrow home)", mid(420), 54, 420, "orange", "i/shield-broken",
               OTHER + " BROKE YOUR SHIELD!", arrow=180)
    elif mode == "visitor_shield":
        huss(root, hx, hy, "idle", key=key)
        bx_, by_ = mid(250), H * 0.36
        T(root, OTHER + "'S SHIELD  0:37", bx_ - 40, by_ - 28, 16, w=330, align="center")
        button(root, "BreakShield (gold Robux button on the other player's shield)", bx_, by_, 250, 48, "gold",
               [("i", "i/shield-breaker", 30), ("t", "BREAK SHIELD", 16), ("t", "R$ 39", 16)], size=16)
    elif mode == "visitor_steal":
        huss(root, hx, hy, "idle", key=key)
        bx_, by_ = mid(190), H * 0.27
        prompt(root, "Prompt/Steal (hold 2.0 s; the frame fills clockwise in alarm orange)", bx_, by_, 190, "E" if dk else None, "HOLD TO STEAL",
               hold=0.5, icon="i/steal")
        f = F(root, "StealInfoLine (the one place Quick Hands is offered)", bx_ - 75, by_ + 58, 340, 54)
        R(f, "Well", 0, 0, 340, 54, WHITE, sw=2, shadow=3)
        body(f, "Hold 2.0 s.\nQuick Hands: 1.0 s.", 10, 9, 170)
        button(f, "QuickHands", 186, 5, 148, 44, "gold", [("i", "i/quick-hands", 26), ("t", "R$ 199", 16)], size=16, lip=4)


def steal_alert_bought(parent, name, x, y, w=540):
    """The owner's steal alert when the boss was bought: the BOUGHT tag sits beside the name (brief, system 10)."""
    f = F(parent, name, x, y, w, 40)
    R(f, "Plate", 0, 0, w, 40, COL["orange"], sw=3, studded=True, shadow=4)
    r = row(f, "Content", 0, 0, w, 40, gap=8)
    I(r, "i/alarm", 32)
    T(r, "YOUR CHOMP FROG", size=16)
    tag(r)
    T(r, "IS BEING STOLEN!", size=16)
    arrow_chip(r, 20)
    return f


def carry_tag(root, x, y, w, stolen=False):
    f = F(root, "CarryIndicator", x, y, w, 44)
    R(f, "Plate", 0, 0, w, 44, COL["panel"], sw=3, studded=True, shadow=4)
    R(f, "Portrait well (tier colour)", 4, 4, 36, 36, TIERS[0][1], sw=2)
    I(f, "s/chomp-frog", 32, 6, 6, name="ImageLabel/Portrait (STAND-IN)")
    T(f, "STOLEN" if stolen else "CARRYING", 48, 3, 14)
    T(f, "CHOMP FROG", 48, 20, 16)
    r = row(f, "ChipRow", w - 110, 11, 104, 22, main="max")
    chip(r, 0)
    return f


def beaten_banner(root, x, y, w=400):
    """Not one of the brief's 13 screens: a non-blocking banner for the moment a boss is beaten (README, questions)."""
    f = F(root, "BossBeatenBanner (non-blocking; clears when the player moves)", x, y, w, 96)
    R(f, "Plate", 0, 0, w, 96, COL["panel"], sw=3, studded=True, shadow=5)
    R(f, "Header", 0, 0, w, 36, COL["blue"], r=[4, 4, 0, 0], studded=True)
    R(f, "HeaderLine", 0, 36, w, 3, INK, r=0)
    r = row(f, "Title", 0, 0, w, 36, gap=8)
    I(r, "i/trophy", 28); T(r, "CHOMP FROG BEATEN!", size=18)
    R(f, "Portrait well (tier colour)", 8, 45, 44, 44, TIERS[0][1], sw=2)
    I(f, "s/chomp-frog", 40, 10, 47, name="ImageLabel/Portrait (STAND-IN)")
    well(f, 60, 45, w - 68, 44)
    body(f, "Carry it home and place it on a spot.\nIt earns $1 a second.", 68, 49, w - 84)
    return f


def fight_overlay(root, x, y, w=380, band="HARD", hearts=2):
    """A plate across the top: name, tier chip, the band word in its colour, health in the boss's tier colour, hearts."""
    f = F(root, "FightOverlay", x, y, w, 78)
    R(f, "Plate", 0, 0, w, 78, COL["panel"], sw=3, studded=True, shadow=4)
    r = row(f, "NameRow", 0, 4, w, 24, gap=8)
    T(r, "CHOMP FROG", size=16); chip(r, 0); T(r, band, size=14, color=DIFF[band], name="TextLabel/DifficultyBand")
    bar(f, "BossHealth (14 px, the boss's tier colour, on an ink track)", 10, 32, w - 20, 14, 0.6, TIERS[0][1])
    h = row(f, "Hearts (3 per fight; a Miss costs one)", 10, 49, 90, 26, gap=4, main="min")
    for i in range(3): I(h, "i/heart" if i < hearts else "i/heart-lost", 24)
    T(f, "150 / 250", w - 130, 53, 14, w=120, align="right")
    return f


# ---------------------------------------------------------------------------------------------- modal screens
def centre(c, w, h):
    return (c.W - w) / 2, (c.H - h) / 2


def boss_panel(root, c):
    w, h = 600, 318; x, y = centre(c, w, h)
    p = panel(root, "Panel/Boss", x, y, w, h, "CHOMP FROG")
    boss_card(p, "Chomp Frog", 12, 57, 190, 249, 0, "s/chomp-frog")
    cx = 216; cw = w - cx - 12
    r = row(p, "ZoneRow (zone, tier chip; the gold BOUGHT tag sits right of the chip when it applies)", cx, 57, cw, 22, main="min", gap=8)
    T(r, "ZONE 1  BRICK MEADOW", size=14); chip(r, 0)
    T(p, "LEVEL 3", cx, 86, 16)
    level_pips(p, cx + 92, 89, 3, size=11)
    well(p, cx, 114, cw, 70)
    I(p, "p/icon-cash", 44, cx + 8, 127)
    body(p, "Earns now", cx + 60, 120)
    T(p, "$1.50/s", cx + 60, 140, 22, INK, name="TextLabel/Now")
    I(p, "p/icon-up", 30, cx + 180, 134)
    body(p, "After", cx + 220, 120)
    T(p, "$1.75/s", cx + 220, 140, 22, INK, name="TextLabel/Next")
    button(p, "Upgrade (the only green button; the price is on it)", cx, 196, cw, 54, "green",
           [("t", "UPGRADE", 20), ("i", "p/icon-cash", 32), ("t", "$51", 20)], size=20, lip=6)
    button(p, "PickUp (white)", cx, 262, 150, 44, "white", [("i", "i/pickup", 26), "PICK UP"], size=16)
    return p


def toggle(parent, x, y, on):
    """The Auto Punch switch: a square switch, cash green when on, disabled grey when off."""
    f = F(parent, "Toggle/" + ("on" if on else "off"), x, y, 64, 32)
    R(f, "Track", 0, 0, 64, 32, COL["green"] if on else COL["dis"], sw=3)
    R(f, "Knob (square)", 34 if on else 2, 2, 28, 28, WHITE, sw=2, r=3)
    return f


def bag_panel(root, c, owned=True):
    """owned: Auto Punch is owned, so row 3 is its switch and the Perfect Auto Punch upgrade is offered as row 4
    (brief, system 13: offered on the bag sign once Auto Punch is owned). Not owned: row 3 is its Buy button, no row 4."""
    w, h = 620, (391 if owned else 320); x, y = centre(c, w, h)
    p = panel(root, "Panel/Bag", x, y, w, h, "PUNCHING BAG", "i/bag")
    rows = [("i/strength", "PUNCH STRENGTH  LEVEL 2", "Each bag punch gives x1.35 Power.\nNext level: x1.82.", "green",
             [("i", "p/icon-cash", 28), "$400"]),
            ("i/speed", "PUNCH SPEED  LEVEL 1", "The ring closes in 1.20 s.\nNext level: 1.12 s, on the bag and in fights.", "green",
             [("i", "p/icon-cash", 28), "$100"]),
            ("i/auto-punch", "AUTO PUNCH", "The bag punches itself while you\nstand on your bag pad.", "gold", ["R$ 249"])]
    if owned:
        rows.append(("i/perfect-auto-punch", "PERFECT AUTO PUNCH", "Every auto tap is a Perfect:\ntwice Auto Punch's Power.", "gold", ["R$ 399"]))
    for i, (ic, title, text, kind, items) in enumerate(rows):
        yy = 57 + i * (82 if owned else 86)
        well(p, 10, yy, w - 20, 78)
        I(p, ic, 54, 20, yy + 12)
        T(p, title, 86, yy + 8, 16, INK)
        body(p, text, 86, yy + 30, w - 20 - 86 - 170)
        if i == 2 and owned:
            toggle(p, w - 10 - 116, yy + 23, True)
        else:
            button(p, "Buy/" + title, w - 10 - 158, yy + 15, 148, 48, kind, items, size=18)
    return p


def spin_panel(root, c):
    w, h = 680, 376; x, y = centre(c, w, h)
    p = panel(root, "Panel/LuckySpin", x, y, w, h, "LUCKY BOSS SPIN", "p/icon-spin")
    cw = (w - 20 - 5 * 4) / 6.0; g = 4
    # zone picker: six zone badges; only zones the player has beaten a boss in can be picked
    for i in range(6):
        tx = 10 + i * (cw + g)
        if i == 0:
            f = F(p, "ZoneTab/1 selected", tx, 55, cw, 44)
            R(f, "Lip", 0, 0, cw, 44, mul(COL["blue"], 0.72), sw=3)
            R(f, "Face", 0, 0, cw, 40, COL["blue"], studded=True)
            content(f, [("i", "i/zone1", 28), ("t", "ZONE 1", 14)], "blue", 14, w=cw, h=40)
        elif i == 1:
            button(p, "ZoneTab/2", tx, 55, cw, 44, "white", [("i", "i/zone2", 28), ("t", "ZONE 2", 14)], size=14, lip=4)
        else:
            button(p, "ZoneTab/%d greyed (beat a boss there first)" % (i + 1), tx, 55, cw, 44, "white",
                   [("i", "i/zone%d" % (i + 1), 26), ("t", "ZONE %d" % (i + 1), 14)], state="disabled", size=14, lip=4)
    names = ["CHOMP\nFROG", "BOP\nBUNNY", "BUMBLE\nBRUTE", "HEADBUTT\nRAM", "TIMBER\nBEAR", "BLOOM\nSTAG"]
    odds = ["40%", "28%", "17%", "10%", "4%", "1%"]
    for i in range(6):
        boss_card(p, "Outcome %d" % (i + 1), 10 + i * (cw + g), 108, cw, 170, i, "s/chomp-frog" if i == 0 else None,
                  title=names[i], sub=odds[i])
    well(p, 10, 286, w - 20, 26)
    body(p, "Every spin gives one of these six bosses. The odds never change.", 10, 290, w - 20, align="center")
    yy = 320
    plate(p, "Tickets owned (gold plate)", 18, yy + 6, 76, "gold", "i/ticket", "2")
    button(p, "Spin (gold, the hero; spends 1 ticket)", 104, yy, 148, 48, "gold", [("t", "SPIN", 22), ("i", "i/ticket", 28)], size=22, lip=6)
    for i, (n, pr, ic) in enumerate([("x1", "R$ 49", "i/spin1"), ("x3", "R$ 129", "i/spin3"), ("x10", "R$ 399", "i/spin10")]):
        button(p, "BuyTickets/" + n, 262 + i * 138, yy + 2, 132, 44, "gold", [("i", ic, 28), ("t", n, 14), ("t", pr, 14)], size=14, lip=4)
    return p


CONF = [(-150, 20, 14, 12), (-120, 96, 10, -20), (-158, 150, 12, 30), (118, 10, 12, 25), (146, 70, 14, -10), (112, 140, 10, 40),
        (-96, -6, 10, 45), (90, -10, 10, 10), (-134, 196, 10, 15), (140, 190, 12, -30)]


def spin_result(root, c):
    w, h = 420, 340; x, y = centre(c, w, h)
    p = panel(root, "Panel/SpinResult", x, y, w, h, "YOU GOT A BOSS!", "p/icon-spin", close=False)
    for i, (dx, dy, s_, rot) in enumerate(CONF):
        R(p, "CubeBurst %d (tier colour and white; particles in the build)" % i, w / 2 + dx, 62 + dy, s_, s_,
          TIERS[0][1] if i % 2 == 0 else WHITE, sw=2, r=1, rotation=rot)
    boss_card(p, "Result", (w - 190) / 2, 58, 190, 192, 0, "s/chomp-frog", title="CHOMP FROG", bought=True)
    well(p, 10, 258, w - 20, 26)
    body(p, "Earns $1 a second. It is in your delivery crate.", 10, 262, w - 20, align="center")
    button(p, "OK (white)", 10, 290, 130, 44, "white", ["OK"], size=18)
    button(p, "SpinAgain (gold; 1 ticket left)", 150, 290, w - 160, 44, "gold", [("t", "SPIN AGAIN", 18), ("i", "i/ticket", 26)], size=18)
    return p


def offline_panel(root, c):
    w, h = 400, 226; x, y = centre(c, w, h)
    p = panel(root, "Panel/WhileYouWereAway", x, y, w, h, "WHILE YOU WERE AWAY", close=False)
    well(p, 10, 57, w - 20, 96)
    I(p, "p/icon-cash", 64, 20, 73)
    body(p, "Away for 1 h 12 min.\nYour bosses earned", 96, 64, w - 116)
    T(p, "$21,600", 96, 104, 22, INK, name="TextLabel/Amount (counts up)")
    button(p, "Collect (green)", 10, 162, w - 20, 54, "green", [("t", "COLLECT", 20)], size=20, lip=6)
    return p


def confirm_panel(root, c, kind="sell"):
    """One shared dialog. kind: sell | swap_bought | rebirth."""
    w, h = 460, 262; x, y = centre(c, w, h)
    title = {"sell": "SELL THIS BOSS?", "swap_bought": "SWAP BOSSES?", "rebirth": "REBIRTH NOW?"}[kind]
    p = panel(root, "Panel/Confirm " + kind, x, y, w, h, title, close=False)
    tx = 124
    if kind == "rebirth":
        I(p, "p/icon-rebirth", 84, 20, 86); tx = 124
    else:
        boss_card(p, "Chomp Frog", 12, 57, 100, 142, 0, "s/chomp-frog")
    well(p, tx, 57, w - tx - 12, 142)
    bw = (w - 32) / 2
    if kind == "sell":
        body(p, "Chomp Frog, level 3, is sold for $30.\n\nYou can't get it back.", tx + 10, 66, w - tx - 32)
        btn, colr = [("i", "i/sell", 26), "SELL $30"], "green"
    elif kind == "swap_bought":
        r = row(p, "TagRow", tx + 10, 64, 120, 22, main="min"); tag(r)
        body(p, "Chomp Frog, level 3, is sold for $30 and the boss you carry takes its spot.\n\nThis boss was bought with Robux. Selling it is for good.", tx + 10, 92, w - tx - 32)
        btn, colr = [("i", "i/swap", 26), "SWAP"], "orange"
    else:
        body(p, "Your run starts again from zero Power.\nYou keep your passes, spin tickets, bought bosses at their levels, Shield Breaker charges and unspent bought cash.\nThis can't be undone.", tx + 10, 66, w - tx - 32)
        btn, colr = [("i", "p/icon-rebirth", 26), "REBIRTH"], "orange"
    button(p, "Cancel (white, same size)", 12, 208, bw, 46, "white", ["CANCEL"], size=18)
    button(p, "Confirm", 20 + bw, 208, bw, 46, colr, btn, size=18)
    return p


def settings_panel(root, c):
    w, h = 440, 196; x, y = centre(c, w, h)
    p = panel(root, "Panel/Settings", x, y, w, h, "SETTINGS", "i/settings")
    for i, (ic, lab, frac, val) in enumerate([("i/music", "MUSIC", 0.8, "80%"), ("i/sound", "EFFECTS", 1.0, "100%")]):
        yy = 57 + i * 66
        well(p, 10, yy, w - 20, 58)
        I(p, ic, 38, 18, yy + 10)
        T(p, lab, 66, yy + 19, 16, INK)
        tx, tw = 170, 180
        R(p, "SliderTrack", tx, yy + 22, tw, 14, COL["empty"], sw=2)
        R(p, "SliderFill (plate blue)", tx, yy + 22, tw * frac, 14, COL["blue"])
        R(p, "SliderHandle (square; 44 px touch area)", tx + tw * frac - 14, yy + 15, 28, 28, WHITE, sw=3, shadow=2)
        T(p, val, 370, yy + 19, 16, INK, w=54, align="right")
    return p


def starter_panel(root, c):
    w, h = 520, 312; x, y = centre(c, w, h)
    p = panel(root, "Panel/StarterPack", x, y, w, h, "STARTER PACK", "i/starter-pack", head="gold")
    cw = (w - 28) / 2
    f = F(p, "Card/Cash (cash green)", 10, 57, cw, 156)
    R(f, "Fill", 0, 0, cw, 156, COL["green"], sw=3, studded=True, shadow=4)
    I(f, "i/cash-large", 84, (cw - 84) / 2, 8, rot=6)
    T(f, "$5,000", 0, 98, 22, w=cw, align="center")
    T(f, "CASH", 0, 128, 14, w=cw, align="center")
    boss_card(p, "Headbutt Ram", 18 + cw, 57, cw, 156, 3, None, title="HEADBUTT RAM", sub="$8/s")
    well(p, 10, 221, w - 20, 26)
    body(p, "Bought once. Both are kept through rebirth.", 10, 225, w - 20, align="center")
    button(p, "Buy (the one gold button; the price is on it)", 10, 255, w - 20, 50, "gold", [("t", "BUY", 20), ("t", "R$ 99", 20)], size=20, lip=6)
    return p


def rebirth_panel(root, c):
    w, h = 700, 372; x, y = centre(c, w, h)
    p = panel(root, "Panel/Rebirth", x, y, w, h, "REBIRTH 1", "p/icon-rebirth")
    bar(p, "RequirementBar (plate blue)", 10, 57, w - 20, 22, 1.0, COL["blue"], "POWER 10.4M / 10M")
    cw = (w - 36) / 3
    cols = [("REBIRTH RESETS", "Your Power\nYour earned cash and the cash on your pads\nPunch Strength and Speed\nEvery boss you beat or stole, with its levels"),
            ("YOU KEEP", "Your passes\nYour 2 spin tickets\nYour 2 bought bosses at their levels (they go back on your spots; collect their pads first, pad cash resets)\nYour 2 Shield Breaker charges\n$5,000 bought cash (bought cash you already spent is not returned)"),
            ("YOU GET", "Bag Power x2\nBoss income x1.5\n+1 boss spot (11 spots)\nA rebirth star by your name")]
    cws = [180, 310, 174]        # the YOU KEEP well is the longest text in the brief, so it gets the width
    cx = 10
    for i, (hd, tx) in enumerate(cols):
        cw = cws[i]
        well(p, cx, 89, cw, 214)
        T(p, hd, cx + 10, 97, 16, INK)
        R(p, "Rule", cx + 10, 120, cw - 20, 2, INK, r=0)
        body(p, tx, cx + 10, 130, cw - 20)
        cx += cw + 8
    button(p, "Rebirth (white, with the Rebirth arrows; the shared confirm comes after it)", (w - 260) / 2, 312, 260, 52, "white",
           [("i", "p/icon-rebirth", 30), ("t", "REBIRTH", 20)], size=20, lip=6)
    return p


# ---------------------------------------------------------------------------------------------- the shop
PRODUCTS = [  # (key, name, line, R$, card colour kind, state)
    ("auto-punch", "AUTO\nPUNCH", "The bag punches itself\nwhile you stand on its pad.", "R$ 249", "panel", "owned"),
    ("perfect-auto-punch", "PERFECT\nAUTO PUNCH", "Every auto tap is a Perfect. Includes Auto Punch.", "R$ 399", "panel", None),
    ("power2x", "2X\nPOWER", "Every bag punch gives\ndouble Power.", "R$ 349", "panel", "owned"),
    ("cash2x", "2X\nCASH", "Every boss you own\nearns double.", "R$ 349", "panel", None),
    ("fast-carry", "FAST\nCARRY", "Carry at full run speed,\non the lane and stealing.", "R$ 149", "panel", None),
    ("extra-spots", "EXTRA\nSPOTS", "+2 boss spots.", "R$ 249", "panel", None),
    ("starter-pack", "STARTER\nPACK", "$5,000 and a Headbutt Ram.\nKept through rebirth.", "R$ 99", "panel", None),
    ("long-lock", "LONG\nLOCK", "Your lock shield lasts 90 seconds, not 60.", "R$ 199", "cyan", None),
    ("quick-hands", "QUICK\nHANDS", "Your steal hold takes 1 second, not 2.", "R$ 199", "orange", None),
    ("iron-grip", "IRON\nGRIP", "A first punch only staggers you. A second makes you drop it.", "R$ 299", "orange", None),
]
CASH = [("cash-small", "SMALL\nCASH PACK", "15 minutes of your\nboss income.", "$4,500", "R$ 29"),
        ("cash-medium", "MEDIUM\nCASH PACK", "1 hour of your\nboss income.", "$18,000", "R$ 79"),
        ("cash-large", "LARGE\nCASH PACK", "4 hours of your\nboss income.", "$72,000", "R$ 199"),
        ("cash-huge", "HUGE\nCASH PACK", "12 hours of your\nboss income.", "$216K", "R$ 399")]
CARD_W, CARD_H = 208, 182


def card(parent, x, y, key, name, line, kind, btn_items, btn_kind="gold", state="default", w=CARD_W):
    f = F(parent, "ProductCard/" + name.replace("\n", " "), x, y, w, CARD_H)
    R(f, "Fill (%s, by kind)" % kind, 0, 0, w, CARD_H, COL[kind], sw=3, studded=True, shadow=4)
    I(f, "i/" + key, 54, 8, 6, rot=6)
    T(f, name, 70, 12, 16, INK if kind in INK_TEXT_ON else WHITE)
    well(f, 8, 66, w - 16, 58)
    body(f, " ".join(line.split()), 14, 70, w - 28)
    button(f, "Price", 8, 132, w - 16, 44, btn_kind, btn_items, state=state, size=16, lip=5)
    return f


def shop_content(parent, w):
    """The whole shop as one scrolling column. Returns its height."""
    cols = 3; gx = (w - cols * CARD_W) / (cols - 1)
    y = 0
    T(parent, "PASSES: BOUGHT ONCE, KEPT THROUGH REBIRTH", 0, y, 16); y += 26
    for i, (key, name, line, price, kind, st) in enumerate(PRODUCTS):
        if st == "owned":
            card(parent, (i % cols) * (CARD_W + gx), y + (i // cols) * (CARD_H + 12), key, name, line, kind,
                 [("i", "i/check", 24, True), ("t", "OWNED", 16)], "white", "disabled")
        else:
            card(parent, (i % cols) * (CARD_W + gx), y + (i // cols) * (CARD_H + 12), key, name, line, kind, [("t", price, 16)])
    y += 4 * (CARD_H + 12) + 6
    T(parent, "CASH PACKS: THE AMOUNT YOU GET IS ON THE BUTTON", 0, y, 16); y += 26
    for i, (key, name, line, amt, price) in enumerate(CASH):
        card(parent, (i % cols) * (CARD_W + gx), y + (i // cols) * (CARD_H + 12), key, name, line, "green",
             [("i", "p/icon-cash", 24), ("t", amt, 16), ("t", price, 16)])
    bx = CARD_W + gx; bw = w - bx
    f = F(parent, "BoughtCash (the number that comes with you through rebirth)", bx, y + CARD_H + 12, bw, CARD_H)
    R(f, "Well", 0, 0, bw, CARD_H, WHITE, sw=2)
    I(f, "p/icon-cash", 44, 12, 12)
    T(f, "BOUGHT CASH", 66, 12, 16, INK); T(f, "$5,000", 66, 32, 22, INK)
    body(f, "Bought cash you have not spent comes with you through rebirth. Earned cash is always spent first.", 12, 70, bw - 24)
    y += 2 * (CARD_H + 12) + 6
    T(parent, "SHIELDS AND THE LUCKY BOSS SPIN", 0, y, 16); y += 26
    card(parent, 0, y, "instant-shield", "INSTANT\nSHIELD", "Raises your shield for 60 seconds now. It cannot be broken.", "cyan", [("t", "R$ 19", 16)])
    card(parent, CARD_W + gx, y, "shield-breaker", "SHIELD\nBREAKER", "Breaks the shield of the base you stand at. Costs R$ 39.", "orange",
         [("t", "BUY AT A SHIELD", 14)], "gold", "disabled")
    card(parent, 2 * (CARD_W + gx), y, "spin1", "LUCKY\nBOSS SPIN", "Six bosses a zone. See\nthe odds, then spin.", "gold",
         [("t", "SEE THE ODDS", 16)], "white")
    y += CARD_H
    return y


def shop_panel(root, c, full=False):
    """One panel, gold header. The list scrolls; `full` draws the whole list for the kit sheet."""
    cw = 3 * CARD_W + 2 * 12
    w = cw + 20 + 16
    ch = 1244 + CARD_H + 12
    if full:
        h = 57 + ch + 14; x, y = 30, 30
    else:
        h = c.H - (26 if not c.desktop else 60); x, y = centre(c, w, h)
    p = panel(root, "Panel/Shop", x, y, w, h, "SHOP", "p/icon-shop", head="gold")
    view = F(p, "ScrollingFrame (the list scrolls)", 10, 53, cw + 8, h - 60, clip=True)
    inner = F(view, "Content", 4, 6, cw, ch)
    shop_content(inner, cw)
    if not full:
        R(p, "ScrollBar/track", w - 16, 55, 8, h - 64, COL["empty"], r=2)
        R(p, "ScrollBar/thumb", w - 16, 55, 8, (h - 64) * (h - 60) / ch, WHITE, sw=2, r=2)
    return p
