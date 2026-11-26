# Huss for Bosses: base area layout

> **Update, 2026-11-25 (after the manager approved this layout: "perfect. base-layout looks good. all 4 pages in that document.").** Three things changed in the pack afterwards; where this file differs, these win:
> 1. The zone lanes are walled corridors with a centre line (brief TEAM CALL 41, from the manager's reference 17), no longer optional: each zone opens with a 36-wide, 30-stud hazard throat, then a 76-wide pad room; zone 1's walls are 4 tall with an invisible blocker so the sight line from the hub is kept. Plan 01 does not draw zone 1's walls.
> 2. The bag's frame is plate blue, as the approved UI kit draws it, not lane grey.
> 3. Instant Shield: its button shows only while the shield is down; a purchase that lands while a shield is up turns it into a fresh unbreakable 60 s shield (brief, system 10).


Status: DRAFT for the manager's approval, 2026-11-25, art-director (covering the builder's layout work). Nothing is
built in Roblox. Asked for by the manager: "I want to first actually have a layout of what the base area will look
like, with layout of everyones bases and such, as well as what pads will look like etc." and "look at how other games
do it and decide"; then, with references 15 to 17: "THIS IS THEE general layout im referring to youu know. but it
should still have our own twist and theme to it obviously. but general layout."

**The plans are the spec.** `01` to `04` are drawn to scale from `src/layout.py`, which also prints every distance and
time in this file. The three `view-*.png` renders are impressions of the look only; where they differ from the plans
(listed at the end), the plans win.

| File | What |
|---|---|
| `01-base-area-plan.png` | The hub from above: walls, 8 plots, yard, track, start line, gate, zone 1's first pads, spawns, sight lines, dimensions |
| `02-plot-plan.png` | One plot at 10 spots and at 17, every element numbered with a key |
| `03-pads.png` | Every pad and base piece with its states, in the stud look and palette |
| `04-steal-route.png` | The worst-case steal: thief routes, the owner's chase, catch radii, the shield footprint, the timing tables |
| `view-area.png`, `view-plot.png`, `view-shield.png` | Higgsfield impressions (not spec) |
| `base-layout.figcraft` | The four boards, one per page. Rebuild: `bash src/export.sh` |

## 1. The decision

**A walled boxing-gym hub.** Eight identical plots stand in a U along the back and side walls (4 on the back wall, 2 on
each side), every entrance facing one open yard. The lane starts inside the yard as a 36-wide running track with a
white start line, and leaves through a named arch in the middle of the low front wall into zone 1.

Why:
- **The manager's references 15 to 17 are the general layout** (they outrank the web research): plots in a row along the
  walls facing a shared open yard, high stud walls, and a named gate out to a corridor lane. Taken as general layout
  only: no prop, sign, colour or proportion of theirs is used.
- **From the research** (`vault/observations/2026-11-25-steal-games-base-area-layout.md`, text guides only): 8 bases a
  server (high confidence), players spawn at their own base (medium), one entrance sealed by a visible timed barrier
  with the lock control as a pad inside (medium), about 10 unit slots to start (medium). The "two facing rows along a
  conveyor" arrangement (medium-low) was dropped for the manager's references.
- **Our twist (art-director's, for the manager to accept or not):** each plot is a little outdoor gym whose station is
  its punching bag, standing at the front by the entrance where the references put their plot stations, so a new
  player sees eight red bags around the yard and finds theirs at once; the lane begins as a running track with a start
  line. Why a U rather than one long row: it puts every plot within 139 to 176 studs of the gate (8.7 to 11.0 s), where
  one row of eight (428 studs long) or two rows along a strip (66 to 224) would give the far plots a 10-second handicap
  on every trip.

What the brief does not have, and so is not in the spec: no shared stations in the yard (the brief has none: Shop,
Rebirth and the spin are HUD screens; there is no leaderboard), no safe zone (stealing is allowed at every base; the
white line on the track is the start of the lane, not a safety line), and no locked gates (the gate sign shows the
zone's name and the Power of its weakest boss; nothing stops anyone walking through). Optional yard stands are in
section 9.

## 2. The hub

Hub frame: X across from the inside face of the left wall, Y from the inside face of the back wall toward the gate. 1
unit = 1 stud. Everything sits on the 1-stud grid (style guide section 4).

| Piece | Size and place |
|---|---|
| Inside the walls | 412 (X) x 234 (Y), Brick Meadow grass `#A9D86B`, studded |
| Back and side walls | 2 thick, 16 tall, trunk-and-brick `#B5563C`, studded, a grass-coloured 1-stud top band (`TEAM CALL`). Ragged dirt below the hub's outer edge as for every island |
| Front wall | 2 thick, **4 tall** (`TEAM CALL`: low so every plot sees zone 1's first pads, the windmill and the fixed pad's Power number over it, as the first session needs), with the 36-wide gate opening at X 188 to 224 |
| Invisible blocker | On the front wall line up to 10 studs (CanCollide on, transparent, CanQuery off), so nobody hops the 4-stud wall and skips the gate and the hazard |
| Plots | 8, each 50 x 92, 4 apart and 4 off the walls. Back wall: plots 3, 4, 5, 6 at X 100, 154, 208, 262 (each 50 wide), Y 4 to 96, entrances at Y 96. Left wall: plot 2 at Y 100 to 150 and plot 1 at Y 154 to 204, X 4 to 96, entrances at X 96. Right wall: plot 7 at Y 100 to 150 and plot 8 at Y 154 to 204, X 316 to 408, entrances at X 316 |
| Plot numbers | Clockwise from the front left: 1, 2 (left wall), 3 to 6 (back), 7, 8 (right wall) |
| Entrance centres (doors) | 1 (96, 179); 2 (96, 125); 3 (125, 96); 4 (179, 96); 5 (233, 96); 6 (287, 96); 7 (316, 125); 8 (316, 179) |
| The yard | Open grass: 220 wide between the side plots' fronts, from Y 96 to the front wall. Nothing in it but the track |
| Track | Lane grey `#9AA3B2`, X 188 to 224 (36, the lane's width) with 1-stud kerb-white kerbs outside, from Y 100 (in front of the back row, between plots 4 and 5's driveways) to the gate, then on as the lane |
| Start line | Kerb white `#F2F4F7`, 36 x 2, flush, across the track at Y 226 to 228, 6 studs inside the gate |
| Lane arrows | Arrow-yellow plate chevrons on the track at Y 130, 170, 210, then every 40 studs down the lane, pointing to zone 1 |
| Zone 1 gate | Arch over the gate opening: pillars 4 x 4 x 16 at X 184 to 188 and 224 to 228, lintel 4 tall 36 across, Brick Meadow colours in 4-stud bands (style guide). Sign on the lintel: "1 BRICK MEADOW" and under it "BOSSES FROM 25 POWER" (`TEAM CALL`: the zone's Common Power, the way the manager's reference gate carries its lock text; it is a sign, not a lock). Each later gate shows its own zone's Common Power |
| Zone 1 beyond | Rolling Log run Y 236 to 261 (first 25 studs); fixed pad centred at (233, 276), 40 in; rolling pads at (179, 296), (233, 316), (179, 336), alternating sides (brief system 5) |
| Spawns | One per plot (section 3). Fallback SpawnLocation at the yard centre (206, 160), used only before a plot is given; the character is moved to its plot spawn on load |
| Plot fill order | Nearest the gate first, then alternating sides: 1, 8, 4, 5, 2, 7, 3, 6 (`TEAM CALL`) |
| Scenery | Brick Meadow props only (round block trees, bush pairs, flower clusters; style guide): in the two back corners (92 x 92 each) and along the front wall. Scenery stays 4 studs off every plot fence and off the track kerbs |
| Sight lines | From every bag pad, over the low fences and the 4-stud front wall, to the zone 1 fixed pad and the windmill. Nothing taller than 4 studs between the plot fronts and the front wall except the gate arch |

## 3. One plot (identical template, turned to face the yard; never mirrored)

Plot local frame: x = 0 to 50 across (x = 50 is the right side seen from the yard), y = 0 to 92 deep (y = 0 is the
front fence). The same model is rotated for the side walls; the bag is always to the right of the entrance as seen
from the yard.

| # (plan 02) | Element | Local position (x, y, w x d) | Height | Notes |
|---|---|---|---|---|
| 16 | Fence | On all four edges, 1 thick | 3 | Kerb-white posts every 4, two rails; plus an invisible blocker on the fence line to 10 studs (`TEAM CALL`), so the entrance is the only way in or out |
| 1 | Entrance | x 19 to 31 in the front fence (12 wide) | | |
| 1 | Name board | 16 x 3.5 x 1, x 17 to 33 over the entrance, bottom at 7.5, on two kerb-white posts | 11 | Plate blue, studded; name in white Montserrat Black with ink outline, letters 2.4 tall; gold Rebirth star with the count at its right end once rebirthed |
| 18 | Driveway | x 19 to 31, y -4 to 0 | flush | Lane grey, into the yard |
| 4 | Delivery crate | x 2 to 8, y 3 to 9 (front-left corner) | 6 | Moved from the back corner to the front yard (`TEAM CALL`): bought bosses start their carry 10 studs from spot 1 |
| 3 | Lock board | x 9 to 10, y 3 to 9, on two legs | 6.5 | Faces the lock pad. Section 6 |
| 2 | Lock pad | x 11 to 17, y 3 to 9 | 1 | Just inside the entrance, left of it |
| 5 | Spots-full sign | 6 x 3 board on a post at x 2 to 8, y 11 | 4 | Section 6 |
| 6 | Spawn | 4 x 4 at x 29 to 33, y 10 to 14, facing +x (the bag) | flush | Bag pad edge 5 studs away (0.3 s); the bag 16 studs away |
| 7 | Bag pad | x 35 to 43, y 3 to 11 | 1 | |
| 8 | Bag plinth and bag | plinth x 43 to 49, y 4 to 10; bag body 4 wide centred (46, 7) | plinth 1, frame 13 | The bag hangs 1 stud past the pad's right edge; the player punches facing +x. Bag tier models from the style guide |
| 9 | Bag sign | 5 wide x 4 board on a post at x 44 to 45, y 12 to 17, facing the aisle and the spawn | 6 | |
| 14 | Aisle | x 13 to 37 (24 wide), y 1 to 77 | | Open grass from the entrance to the back |
| 10 | Spots 1 to 10 | Left column (x 1 to 9) and right column (x 41 to 49), rows at y 18, 28, 38, 48, 58 (8 x 8 each, 2 apart). 1 = left y 18, 2 = right y 18, 3 = left y 28 ... 9 = left y 58, 10 = right y 58 | 1 | Bosses face the aisle |
| 11 | Cash pads | 8 x 3 on each spot's aisle side: left x 10 to 13, right x 37 to 40, same y as the spot; back row y 78 to 81 in front of each back spot | 1 | |
| 12 | Spots 11 to 15 (rebirths) | 11 = left y 68; 12 = right y 68; 13, 14, 15 = back row centre (x 21), left (x 11), right (x 31), y 82 to 90 | 1 | Ghost outlines until unlocked |
| 13 | Spots 16, 17 (Extra Spots) | Back row corners x 1 and x 41, y 82 to 90 | 1 | Not drawn at all unless the pass is owned (an offer only lives where the brief puts it) |
| 15 | Back collect band | y 77 to 82, the full width | | One walk collects the back row |
| 17 | Shield | Walls on the fence line, 50 x 92, 16 tall | 16 | Section 5, board 03 |

Distances inside a plot: bag pad centre to the entrance 16 (1.0 s); entrance to the deepest of the first 10 spots 63
(3.9 s); to the deepest of all 17, 80 (5.0 s). Column walk along all cash pads: 58 per side.

## 4. Pads and pieces (board 03)

Text sizes for world signs follow one rule: on a phone (default 70 degree camera, 402 px design height) a letter
`h` studs tall read from `d` studs is 287 x h / d px, so 14 px needs **h >= d / 20**; a tappable world button needs
**h >= d x 0.153** for 44 px. Text that must read from far is a BillboardGui sized in pixels instead.

| Piece | Size (studs) | Colour job | Studs | Sign or label | States |
|---|---|---|---|---|---|
| Boss spot | 8 x 8 x 1, 1-stud rim | Pad stone `#C9CED8`; rim white / tier colour / alarm orange | Studded (rim smooth Neon only while pulsing) | None on the spot. Boss name tag over the boss: BillboardGui in px, name 16 px, tier chip 14 px, BOUGHT tag 14 px, income "$X/s" (`TEAM CALL`: income shown so thieves can judge value from outside); full tag within 60 studs, tier chip only from 60 to 120, nothing beyond | Empty: white rim. Empty while the owner carries: rim Neon white, pulsing, Place prompt on it. Occupied: rim in the boss's tier colour, boss centred facing the aisle (back row: facing the entrance), never taller than 9. Bought: same, plus the gold BOUGHT tag on its name tag. Being stolen (2 s hold): the boss lifts 1 stud and wobbles, rim alarm orange. Away with a thief: rim alarm orange, dashed; the spot is reserved; the boss snaps back on a punch. Locked: grass-level ghost outline in disabled grey `#8A919C` with a "REBIRTH n" plate (letters 0.6, read from 12) |
| Cash pad | 8 x 3 x 1 | Cash green `#2FB341`; empty = lip shade `#22812F` | Studded | Amount tag: BillboardGui 13 px, green plate, owner only, within 40 studs | Empty; has cash (1 to 4 stacks of green cubes with a white band); capped at 2 hours of income (5 stacks, tag reads "$7.2K FULL"). Cash stays for the owner when the boss is picked up, sold or stolen. Only the owner collects |
| Bag pad | 8 x 8 x 1, 1-stud red border | Kerb white `#F2F4F7`, Huss red `#E02A2A` border | Studded | None (the bag sign stands beside it) | Idle; owner on it (the ring runs); first session: the cube arrow over the bag. Visitors stepping on it get nothing |
| Bag sign | 5 x 4 board on a post | Plate blue header, panel grey body | Studded | "BAG", Strength and Speed levels: header letters 0.9 (read from 18), rows 0.7 (14). Green corner light when a level is affordable | Opens the bag panel by prompt (owner only) |
| Lock pad | 6 x 6 x 1, white rim | Shield cyan `#35C8F0` | Studded | Lock shield icon on a plate in its middle; the time on it while up or cooling down (letters 0.8) | Ready: cyan, white rim. Up: cyan, cyan rim, time left. Cooldown: disabled grey, time left; stepping on it shakes the plate. Up by Instant Shield: gold rim |
| Lock board | 6 wide x 4.5 tall | Plate blue | Studded | State plate (READY / UP 0:42 / 0:31) and the owner's buy buttons, section 6 | Ready: both buttons. Up: Long Lock only. Cooldown: both. Steal or shield-broken alert on: no buttons. Visitors: state only |
| Delivery crate | 6 x 6 x 6 | Shop gold `#FFC21A`, kerb-white rails and X | Studded | Count tag (BillboardGui 16 px, gold) when it holds bosses | Empty: lid shut. Holding: lid propped open, count. Take-out prompt (E). Never stolen |
| Spots-full sign | 6 x 3 on a post | Alarm orange header, panel grey body | Studded | "SPOTS FULL" (letters 0.9) | Shown only while every unlocked spot is full; gold "+2 SPOTS R$ 249" button only for the owner without the pass, only when not carrying and with no alert; otherwise "Swap or Sell" |
| Name board | 16 x 3.5 x 1 | Plate blue `#1F6FD6` | Studded | Owner's name, letters 2.4 (read from 48, across most of the yard); Rebirth star with the count | Always shown while the owner is in the server |
| Lock shield | Walls on the fence line, 50 x 92 x 16 | Shield cyan at 0.6 transparency, solid cyan 1-stud ground rim | Studded panels | Timer plate over the entrance: BillboardGui 18 px, readable to 120 studs (the whole yard). Visitor's "BREAK SHIELD R$ 39" button on the entrance panel, 2.4 tall, shown within 15 studs | Down: ground rim only, white. Up: panels, cyan rim, timer. Instant Shield: gold rim (cannot be broken). Broken: cyan cube burst, rim flashes alarm-orange stripes for 1 s, then down. Joining shield: as Up |
| Boss pad (zones) | 12 x 12 x 1, kerb-white 1-stud ring | Pad stone; fixed pad's four 2 x 2 x 2 corner posts in the zone's structure colour (zone 1 `#B5563C`) | Studded | Name tag and Power number (BillboardGui, readable to 320 studs on zone 1's pads so every plot sees Chomp Frog's number). Rolling pad: countdown plate 4 x 2 on a post at its back corner, white on plate blue, letters 1.2 | Fixed: the zone's Common. Fixed, you beat it: "BACK IN 0:08" plate, for you only, 10 s. Rolling: countdown to the next roll (45 s), cube burst on a new roll. Rolling, you beat this roll: green "BEATEN" plate until the next roll |

## 5. Timings (from `src/layout.py`; walk 16, carry 12, Fast Carry 16, owner chase 20 studs/s)

**New player.** Spawn to the bag pad edge 5 studs, 0.3 s (the bag is in front of them on spawn). Bag pad to the
entrance 16 studs, 1.0 s; the yard and the track are in view from the bag pad.

| Plot | Bag to the gate | Bag to zone 1's fixed pad (ring) | Carry it home | Fast Carry |
|---|---|---|---|---|
| 1 and 8 | 139, 8.7 s | 183, run 11.4 s | 15.2 s | 11.4 s |
| 4 and 5 | 156, 9.8 s | 200, run 12.5 s | 16.7 s | 12.5 s |
| 2 and 7 | 171, 10.7 s | 214, run 13.4 s | 17.9 s | 13.4 s |
| 3 and 6 | 176, 11.0 s | 220, run 13.7 s | 18.3 s | 13.7 s |

**Stealing** (board 04). The thief holds 2.0 s (1.0 with Quick Hands), then carries from the spot to their own door.
The owner catches the thief if they reach the thief's door first and punch from 8 studs, so the owner's **catch
radius** around the thief's door is 20 x carry time + 8.

| Thief's plot | Spot | Carry distance | Carry time (Fast Carry) | Catch radius (Fast Carry) |
|---|---|---|---|---|
| Back-corner neighbour (plots 2 and 3, 6 and 7), doors 41 apart: **the worst case** | 1 | 66 | 5.5 s (4.1) | 117 (90) |
| | 9 | 104 | 8.7 s (6.5) | 181 (138) |
| | 16 | 121 | 10.0 s (7.5) | 209 (159) |
| Neighbour along a wall, doors 54 apart | 1 | 79 | 6.5 s (4.9) | 139 (106) |
| | 9 | 117 | 9.7 s (7.3) | 203 (154) |
| | 16 | 134 | 11.1 s (8.3) | 231 (175) |
| Across the yard, doors 220 apart | 1 | 245 | 20.4 s (15.3) | 416 (314) |
| | 9 | 283 | 23.6 s (17.7) | 480 (362) |

| Owner is at | Distance to the nearest neighbour's door | Time at 20 |
|---|---|---|
| Their own bag | 57 to 70 | 2.8 to 3.5 s |
| The yard centre | 74 to 117 | 3.7 to 5.9 s |
| The gate | 141 to 160 | 7.0 to 8.0 s |
| Zone 1's fixed pad | 191 to 210 | 9.5 to 10.5 s |
| Zone 1's last rolling pad | 246 to 266 | 12.3 to 13.3 s |

Read together: an owner who is home or anywhere in the yard catches every steal, from any neighbour, even with Fast
Carry. At the gate, they catch steals from the deep spots (9 to 17) but not from the front spots of a corner or wall
neighbour. In zone 1, only a deep-spot steal by a wall neighbour is still catchable (spot 16: 231 against 205 to 210).
Deeper spots are safer, so owners keep their best bosses at the back. Every thief leaves past the owner's bag.

**Shield.** 60 s up (90 with Long Lock), 60 s cooldown. A zone 1 trip (run, a 5.4 s fight, carry) is about 32 to 37 s
from every plot; a zone 2 trip about 50 to 55 s. Both fit inside one shield, as the brief says; zone 3 does not.

## 6. The three layout questions

**Long Lock and Instant Shield beside the lock pad.** They live on the **lock board**, a 6 x 4.5 plate-blue board on two
legs along the pad's back edge, facing the pad and the entrance. The pad itself carries only the icon and the time:
stepping on it raises the shield and never buys anything. The two gold buttons are in-world SurfaceGui buttons, 1.5
studs tall, shown only to the owner and tappable within 10 studs (44 px on a phone). Instant Shield shows only while
the shield is down (ready or cooling down, which is when it is useful); Long Lock shows until owned. **Both buttons are
hidden whenever a steal alert or a shield-broken alert is on for that owner** and come back when it ends, so a buy
button never sits on or beside an alert. Visitors see the board's state plate only.

**"Spots full" and no prompt during a carry.** While carrying into a full base, the owner sees the orange "Spots full"
toast with no offer, plus the Swap prompts on placed bosses and the Sell button (brief system 7). No purchase prompt
appears during a carry. The Extra Spots offer lives in two places, both only while not carrying and with no alert: the
**spots-full sign** by the crate (its gold "+2 SPOTS R$ 249" button, shown only while every unlocked spot is full and the
pass is not owned), and the gold toast under "Spots full" when the owner tries to take a boss out of the crate with
every spot full. Pass spots 16 and 17 are not drawn before purchase.

**Settings button:** not part of this layout (skipped as asked).

## 7. Weak phones

| Per plot | Parts |
|---|---|
| Ground plate, dirt under the hub (shared) | 1 |
| Fence: build the posts and rails once, union per side | 5 unions (78 parts before) |
| Invisible blocker | 4 |
| Spots (plate + rim) and cash pads, 17 at most | 51 |
| Cash stacks: one MeshPart per pad, its mesh swapped by fill level | 17 |
| Bag (frame 3, plinth, chain, bag tier mesh), bag pad (2), bag sign (2) | 10 |
| Lock pad (2), lock board (2), crate (2), spots-full sign (2), name board and posts (3), driveway | 12 |
| Shield: 4 panels + timer, created only while up; ground rim 4 | 9 |
| Bosses: about 6 meshes each (moving groups and Neon cubes) | about 100 at 17 spots |
| **Total** | about 210 per plot, about 1,700 for 8 plots, plus about 60 for the walls, track, gate and scenery |

- Locked spots 11 to 15 are one flat part each; nothing exists for unbought pass spots.
- SurfaceGuis per plot: name board, bag sign, lock board, spots-full sign (4). Spot numbers are not shown (no
  SurfaceGui per spot). Billboards: one per occupied spot (distance-limited as in section 4), one per cash pad (owner
  only), crate count, shield timer.
- Placed bosses play only the half idle and stand still beyond 150 studs (brief system 4). The hub is 412 across, so
  bosses on the far wall are still. All 8 plots stay streamed in (plot models not streamed out); the performance-optimizer
  measures this on a weak phone.

## 8. TEAM CALLs made here

1. The walled hub: 412 x 234 inside; back and side walls 16 tall, front wall 4 tall with an invisible blocker to 10.
2. 8 plots in a U (4 back, 2 per side), 50 x 92 each, 4 apart, numbered clockwise; fill order 1, 8, 4, 5, 2, 7, 3, 6.
3. One plot template, rotated, never mirrored; the bag right of the entrance seen from the yard.
4. The track (the lane's first stretch inside the hub) and the white start line 6 studs inside the gate.
5. Gate sign second line "BOSSES FROM [Common Power] POWER": a sign, not a lock.
6. Fence and front wall get an invisible blocker to 10 studs, so the 12-wide entrance (and the gate) are the only ways through.
7. Spot arrangement: two columns of 6 facing a 24-wide aisle and a back row of 5 facing the entrance; spots 1 to 10 at the front, rebirth spots next, pass spots at the back corners.
8. Bosses on spots face the aisle (the back row faces the entrance).
9. Delivery crate moved to the front-left corner; spots-full sign beside it.
10. Lock board with the owner's buy buttons on the lock pad's back edge; buttons hidden during alerts.
11. Locked rebirth spots shown as ghost outlines with "REBIRTH n"; pass spots not shown until owned.
12. Boss name tags at base show income per second; full tag to 60 studs, tier chip to 120.
13. Fallback spawn in the yard; plot spawn facing the bag.
14. Text rule for world signs: letter height at least distance / 20; buttons at least distance x 0.153.
15. Hub wall colour: Brick Meadow's trunk-and-brick `#B5563C` with a grass-coloured top band.

## 9. Optional suggestions (not in the spec; the manager picks)

| Suggestion | Source | Cost |
|---|---|---|
| Shared stands in the yard: a shop stall (opens the shop), a Lucky Spin stand, a rebirth stand, a leaderboard board. Each would be a second door to a HUD screen, or a new feature (the leaderboard is "Not in version 1") | Manager's refs 15 and 16 (shared stations in the yard) | Small to medium each; the leaderboard is a new system |
| Walled corridor lanes in the zones (ref 17): high stud walls at the zone's edges so the lane reads as a corridor. It also stops players walking round the hazards on the grass beside the lane (see section 11) | Manager's ref 17 | Builder; changes the style guide's open zone edges |
| A painted centre line down the whole lane (ref 17) | Manager's ref 17 | Small; needs a colour job (arrow yellow is "arrows only") |
| A big boxing-ring centrepiece or giant glove statue in the yard as the hub's landmark | Our twist | Small; scenery only, not in the content tables, so it needs the manager's yes |

## 10. Renders: what they are and where they depart from the plans

Made with Higgsfield (`gpt_image_2_6`, 2k, high), reference `ui-kit/src/scene-base.png`, no lettering asked for.
Impressions only.

- `view-area.png`: the hub from above. Departs: the side-wall plots face the front wall instead of the yard; the plots
  are shallower than 50 x 92 and the back-row plots show a second crate at the back; bosses face the camera, not the
  aisle; no spot rims, ghost spots or cash stacks; the bag frame and spot count are close but not exact; the windmill
  stands just outside the front wall instead of deep in zone 1; no zone 1 pads or hazard. The first try was rejected
  (farm animals that are not in the game).
- `view-plot.png`: one plot from the player's camera, standing at the entrance. Departs: the bag frame is blue (the
  spec is lane grey); the lock board stands on the pad instead of on its back edge, and the bag sign stands on the bag
  pad; only four spots, with the cash pads between them rather than on the aisle side of each; the aisle is shorter;
  the crate is beside the lock pad, close to the plan.
- `view-shield.png`: a locked plot beside an open one, from the yard. Departs: the plots are shallow; the bag frames
  are blue; a tree and flowers stand inside each plot (scenery belongs outside the fences); the name boards sit low;
  the lock pads, crates and cash pads are missing. The shield box, its cyan ground line, the blank timer plate and the
  open neighbour's white line match the spec.

## 11. Changes needed in other files (not made here)

**brief.md**
- First session, row 0:00: "Spawns on their own base plot, facing the punching bag about 12 studs away." becomes "Spawns on their own base plot, facing their punching bag: the bag pad 5 studs ahead, the bag 16 (base-layout.md)."
- First session, rows 0:24 to 0:44, and the summary line "first boss beaten 30 seconds, first boss placed 44 seconds": the run to Chomp Frog's pad is 11.4 to 13.7 s and the carry home 15.2 to 18.3 s from the hub (the table assumed 8 s and 12 s). New targets: fight starts about 0:29, first boss beaten about 0:35, first boss placed about 0:52 (0:50 to 0:55 by plot); later rows move by about 8 s.
- System 5, layout line: add "The base area is a walled hub at the start of the lane; its front gate leads into zone 1 (`base-layout/base-layout.md`)."
- System 7, Rule: "Each player in the server gets one base plot beside the start of the lane: the punching bag and its sign, a row of boss spots with a cash pad in front of each, a lock pad, and a delivery crate." becomes "Each player in the server gets one base plot in the walled hub at the start of the lane (`base-layout/`): the punching bag and its sign, boss spots with a cash pad in front of each, a lock pad with its lock board, a delivery crate and a spots-full sign."
- System 10, Instant Shield row: "Sold in exactly two places: its card in the shop and a button on the owner's lock pad." becomes "...its card in the shop and a button on the owner's lock board, beside the lock pad (never on the pad), hidden while a steal or shield-broken alert is on."
- System 13, "Where things are offered": "Long Lock and Instant Shield on the lock pad; Extra Spots on the "spots full" message" becomes "Long Lock and Instant Shield on the lock board beside the lock pad; Extra Spots on the spots-full sign and the "Spots full" toast, never while carrying".
- Content, "Maps or zones": "Base area (8 plots)" becomes "Base area: a walled hub, 8 plots in a U around a yard, the track and start line, the zone 1 gate".
- Content, "Base pieces | 6": becomes 8: add "lock board" and "spots-full sign"; and "hub walls and gate" under world pieces.
- Team calls table: add one row, "40 | Base area layout and its 15 calls (`base-layout/base-layout.md` section 8) | 5, 7, 10, 13".

**style-guide.md**
- Section 4, "The base plot", first line: "One per player, **8 plots** in a row beside the start of the lane, each opening onto it." becomes "One per player, **8 plots** in a U along the walls of the base hub, each opening onto its shared yard (`base-layout/`)."
- Same section, punching bag: "at the front centre, about 12 studs from spawn" becomes "at the front, right of the entrance seen from the yard, on a 6x6 plinth; the spawn faces it 16 studs away". Its frame is plate blue, as the approved UI kit draws it.
- Same section, spots: "in rows behind the bag" becomes "in two columns of 6 facing a 24-wide aisle and a back row of 5 facing the entrance". Cash pad: "on the lane side of each spot" becomes "on the aisle side of each spot".
- Same section, lock pad: add "with the lock board (6 x 4.5, plate blue) on its back edge carrying the owner's Long Lock and Instant Shield buttons". Delivery crate: "at the back corner" becomes "in the front-left corner of the front yard". Lock shield: add "16 tall, on the fence line".
- Section 5, "Carried, placed, idle": "On a spot: centred, facing the lane" becomes "facing the plot's aisle (the back row faces the entrance)".
- Section 4, new subsection "The hub": walls 16 tall (front 4) in trunk-and-brick `#B5563C` with a grass top band, the track and its kerb-white start line, the gate sign's second line, scenery only in the back corners and along the front wall.
- Section 4, "Boss pads": "Zone 1's fixed pad is in sight from the bases." add "over the hub's 4-stud front wall".
- Section 4, "The lane": add "It starts inside the hub as the track."

## 12. Unverified and open

- Every distance and time is on paper. The builder greyboxes the hub first and measures the run and carry times, the
  sight lines over the front wall from all 8 bag pads, and the name board and sign text sizes on a phone, at the
  default camera.
- The invisible blockers are a team call; whether players read the 3-stud fence as "closed" needs the manager's playtest.
- Zone lanes as drawn in the brief and style guide have open grass beside the lane; a carrier could walk round a hazard
  there. Not part of this layout; flagged for the builder and the game-designer (the corridor walls in section 9 would fix it).
- Part counts are estimates; the performance-optimizer measures on a weak phone.
- Questions for the manager's playtest (agents cannot judge them): does the yard feel too big and empty with only the
  track in it; does a new player look for the bag or for the gate first; is a steal from the corner neighbour too easy.
