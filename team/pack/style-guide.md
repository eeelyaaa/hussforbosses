# Huss for Bosses: style guide

Status: DRAFT for the manager's approval with the pack. Written 2026-11-25 by the art-director from the picked look
(Direction 4, Brick Brawl, as corrected by the manager on 2026-11-25), and reconciled the same day with the finished
`brief.md`. At build time this file is copied to `projects/huss-for-bosses/team/style-guide.md` and kept current.
Updated 2026-11-25 after the manager's review of the UI kit ("foundations, amazing / components, make sure bosses
look like that [...] should have small fighting animations too [...] icons, all amazing / screens desktop and phone
look aamzing"): the kit as exported is approved reference, so where this guide and the kit differed the guide now
describes the kit; the six pictured bosses are the approved look (section 5); boss fight animation (section 5) and
avatar animation (section 7) were added.
Updated 2026-11-25 (evening) with the manager's approval of the base layout ("perfect. base-layout looks good. all 4
pages in that document."): the hub, the base plot, the walled zone lanes, the lock board buttons and the Settings tile
(sections 4 and 6). `base-layout/base-layout.md` and its four plans are the spec for every dimension of the hub and the
plot; this guide gives the look and points there for numbers.

Order of authority: the manager's words and their 14 reference screenshots, then `brief.md` (rules, names, counts,
sizes), then the approved pictures (`concepts/brick-brawl/creatures.png` for the six bosses, `ui-kit/` for the UI),
then this guide. Where this guide gives a size the brief also gives, the brief's number is used here.

The manager's words this guide carries out: "I like brick brawl. we need to use the stud texture that roblox games
all use. It should also be in UI elements. not look like a lego brick but like this [...] people call it stud slop,
but I like it. also the mockups of the bosses were good. yes ideas like that."

Every number below is a starting value. Where it has not been seen in Studio it is listed in section 13.

## 1. The look

**One sentence:** a bright daytime Roblox stud world, where every block is one flat colour covered in the square
stud tile and the same tile covers the UI, and the bosses are creatures made of plain cubes that stand out against it.

**Three words:** studded, sunny, chunky.

**How the player should feel:** at home on Roblox at first glance, and able to read the whole screen on a phone
without squinting.

**The motif:** the stud tile. It is on world surfaces and on UI panels and buttons. Cubes (no studs) mean "boss".

**What the round 2 board got right and wrong.** Right: the palette jobs, the square plates with a darker lip, the heavy
upright type, the HUD layout idea, the timing ring and three pips, the cube bosses. Wrong, and replaced here: round
raised studs, glossy plastic, the toy-figure avatar (the game uses the player's real Roblox avatar), the row of round
studs along the top edge of buttons (the stud tile now covers the whole face), and Ember Drake's tail.

## 2. The stud rule

### What the tile is
Taken from the manager's screenshots (`concepts/manager-refs/1.png` to `3.png` for UI; `8.webp`, `10.webp`,
`13.webp`, `14.webp` for the world), looked at full size.

- One square tile holds one stud: the **square inset stud**. It is a **small square with sharp corners**, centred,
  **44% of the tile wide**. It is never a circle and never a tall peg.
- It is the **same colour as the surface**. It has no fill of its own, no gloss, no ring, no logo, no letter. It is
  drawn by its edges only.
- **In the UI** (as in references 1 to 3) the edges are baked: a **dark L along the left and bottom edges** of the
  square, about 7% of the tile thick, and a faint light line along the top and right edges. On a small tile the dark L
  is most of what is seen.
- **In the world** the edges come from the sun on a normal map, so which edges are dark changes with the light and
  the face, as it does in references 8, 13 and 14 (the same stud shows a dark L on a wall and a dark corner on the
  ground). The step is shallow: about 0.04 studs.
- Reference files, made by script (not production assets): `style/stud-ui-overlay-64.png` (the UI tile),
  `style/stud-height-64.png` (height map: white surface, the stud set in), `style/stud-preview.png` (the UI tile over
  the UI palette at 16 px and 32 px, and one button). Rebuild: `style/make_stud_refs.py`.
- **The manager confirms the stud against their screenshots at the M1 stud proof:** a wall, a floor, a crate and one
  UI button built with the real assets, shown beside references 8, 13, 14, 1 and 2. If the world stud reads as a peg
  or a dent in the wrong way, the builder flips the normal map and shows it again. Nothing else is studded before that
  yes.

### Colour
Flat colour first, stud tile second. A surface is one palette colour; the tile only adds light and shade. No colour
is ever painted into the tile, so any palette colour can be studded and a recolour is one property.

### Two assets, one design
The world tile and the UI tile are drawn from the same square, so they match, but they are two files because the
world's studs are lit by the sun and the UI's are baked.

| | World | UI |
|---|---|---|
| Asset | `MaterialVariant` named `Stud` | `stud-ui-overlay` PNG, transparent |
| Contents | Colour map: flat near-white `#F2F2F2`, 256 x 256, 4 x 4 studs. Normal map from the height map. Roughness map flat at 0.75 (matte). No metalness | Black L on the left and bottom edges at 30%, white line on the top and right edges at 16%, the face black at 4%, clear elsewhere |
| Scale | **1 stud tile = 1 Roblox stud** (`StudsPerTile` 4 for the 4 x 4 image; 64 px per stud) | **16 px per tile at phone size** (the 874 x 402 design frame); about 26 px on desktop |
| Colour comes from | `BasePart.Color` | The fill colour of the frame under it |
| Applied by | `BasePart.MaterialVariant = "Stud"` on each part | An `ImageLabel` over the fill, `ScaleType = Tile`, `TileSize = UDim2.fromOffset(16, 16)` |

### Where it appears in the world
On **every face of every built part**: ground, lane, cliffs, trees, props, buildings, fences, gates, boss pads, spots,
cash pads, the lock pad, the delivery crate, the punching bag, hazards, water.

Smooth, with no studs, and only these:
- The player's avatar and anything it wears (Roblox's own).
- Bosses (plain cubes; see section 5).
- Neon parts: lava, stars, glowing boss cubes, a glowing spot rim.
- Effects: particles, cube bursts, confetti.
- Text plates in the world (signs carry a `SurfaceGui` built to the UI rules).

### Where it appears in the UI
On panels, header bars, buttons and counter plates. Not on: wells (the smooth plates that hold body text or a list
row), tier chips, the bought tag, icons, text, or anything less than 28 px tall at phone size. A stud tile is never
drawn smaller than 12 px or larger than 32 px on screen: below that it is noise, above it the panel looks zoomed in.
This is how the manager approved the UI kit on 2026-11-25 (studs on panels, headers, buttons and counter plates;
smooth wells, chips, tags and icons), so it carries out "it should also be in UI elements" as approved.

### How it is made in Roblox today
Checked against the official Creator docs on 2026-11-25 (pages read through a summarizing fetch, so property
defaults and limits were mostly not visible).

Verified in the docs:
- `MaterialVariant` has `ColorMap`, `NormalMap`, `RoughnessMap`, `MetalnessMap`, `StudsPerTile` ("Determines the scale
  of textures. Larger values [...] lead to the textures appearing larger") and `MaterialPattern`. It only works as a
  descendant of `MaterialService`. It is applied per part through `BasePart.MaterialVariant`, or globally by setting
  it as the override for a built-in material. (reference/engine/classes/MaterialVariant; parts/materials)
- A part stores the variant's **name**, not the instance, so swapping the `MaterialVariant` that carries that name
  changes every part at once ("adaptive materials", parts/materials). This is what makes a second skin cheap.
- `Texture` tiles an image on **one face** of a part (`Face`), sized by `StudsPerTileU` / `StudsPerTileV`, with a
  `Color3` tint and `Transparency`. (reference/engine/classes/Texture)
- `SurfaceAppearance` overrides the look of a `MeshPart`; `SurfaceAppearance.Color` tints its `ColorMap`; most of
  its properties cannot be changed by scripts at run time. (reference/engine/classes/SurfaceAppearance)
- `ImageLabel.ScaleType = Tile` repeats the image at `TileSize` (a `UDim2`, default `1,0,1,0`); "Tiling starts at the
  top-left corner"; `ImageColor3` tints. (reference/engine/classes/ImageLabel)

Decided:
- **World: route A, one `Stud` MaterialVariant** (base material SmoothPlastic), set per part, not as a global
  override, so smooth parts stay possible. No extra instances per part.
- **Fallback, route B:** if part colour does not tint the variant, or the studs do not line up across parts, use a
  `Texture` on each visible face with the UI overlay image, `StudsPerTileU = StudsPerTileV = 1`. It costs up to six
  instances a part, so the builder skips faces nobody sees.
- **UI:** the tiled `ImageLabel` above.

Not in the docs read; the builder confirms in Studio at the M1 stud proof (see section 13): that `BasePart.Color`
tints a MaterialVariant's colour map; that tiles line up across neighbouring parts; which way the normal map has to
face; how the tile looks at distance on the lane; whether `TileSize` in Offset follows a `UIScale`.

## 3. Palette

Hex values, one job each. A colour is not used for anything but its job.

### UI
| Name | Hex | Job | Text on it |
|---|---|---|---|
| Panel grey | `#B4BBC6` | Panel bodies | White with ink outline |
| Plate blue | `#1F6FD6` | Header bars, screen titles, progress bars (rebirth bar, zone strip) | White with ink outline (4.9:1 before the outline) |
| Huss red | `#E02A2A` | Your punch: the Huss button, the Power plate, filled combo pips, the three hearts, the boxing gloves on every avatar, the bag's red band | White with ink outline (4.6:1) |
| Cash green | `#2FB341` | Earned cash and ordinary yes: the cash plate, cash pads, price buttons that spend earned cash (Upgrade, Strength, Speed), Collect, the confirm of an ordinary sell or swap, Auto Punch on, level pips, "Get it home!", the "purchase done" toast | White with ink outline |
| Shop gold | `#FFC21A` | Robux: the shop header, every Robux price button, the Lucky Spin card and Spin button (a ticket is bought with Robux), the spin-ticket plate, the bought tag, the delivery crate | Ink, no outline (11.1:1) |
| Shield cyan | `#35C8F0` | The lock: shield plate while up, lock button, lock pad, shield in the world, defending product cards | White with ink outline |
| Alarm orange | `#FF6A00` | Warning: anything aimed at another player's base or at yours (steal alerts, "shield broken", the Steal hold fill, the three attacking product cards), anything that can't be undone and loses something bought or a whole run (the confirm on selling or swapping a bought boss, the rebirth confirm), the "can't do that" toasts ("Spots full", "Not enough cash"), and hazards (stripes, the hazard warning) | White with ink outline |
| Flash yellow | `#FFF36B` | Hit feedback only: the timing band, a Perfect, the impact star | Ink, no outline |
| White | `#FFFFFF` | Text, wells, secondary buttons (Pick Up, Run, Rebirth, Back, See the odds, cancel), the close plate, prompts | Ink, no outline (17.9:1) |
| Ink | `#101820` | Every outline, hard shadow and dark text; the input-glyph plates | |
| Disabled grey | `#8A919C` | A button that can't be used now: locked by progress, greyed with a reason, owned, and the lock while on cooldown | `#D5D9DF`, ink outline |
| Lip | fill x 0.72 | The darker edge under a pressable thing, computed from its fill | |

Text contrast, measured (WCAG ratio): white alone fails on panel grey (1.9), cash green (2.8), shield cyan (2.0),
alarm orange (2.9), shop gold (1.6) and most tier colours. So the rule is fixed: **white text always carries a 2 px
ink outline and a hard ink shadow**, and on shop gold, flash yellow and white the text is ink instead. Body text
longer than one line sits in a white well in ink. Check the HUD on the Ice Blocks ground and the lane, the two
brightest backgrounds in the game.

**Red, exactly.** Red as a fill is the punch alone: the Huss button, the Power plate, filled pips, hearts, the
gloves, the bag band. Red also appears inside icons where the object is red: the glove and fist icons (Huss glove,
Power, Punch Strength, Punch Speed, Auto Punch, 2x Power), the red-and-white bag of the Shop icon (on its gold
tile), the red bag of the Bag panel icon and the Timer stopwatch. No button, plate, panel or toast is red except the
Huss button and the Power plate, and nothing that closes, cancels or warns is red.

**Close** is a text glyph, not an icon: an "X" in Montserrat Black, ink on a white plate (36 px, ink outline, inside
a 44 px touch area), or white on an ink plate where the plate sits on white. The BOUGHT tag and the OWNED label are
text too.

**Icon colours.** Icons are coloured by their object (a red glove, a green bill stack, purple rebirth arrows, a gold
trophy), not by the button jobs above. Purple in an icon is not the Epic tier. Two job rules hold inside icons:
attacking products carry alarm orange, defending products carry shield cyan.

### Rarity tiers
Used only on tier chips, boss cards, boss name tags, the health bar of that boss, and the rim of the spot it stands
on. Never on a button, a fence or a plot. The tier is always also written as a word.

| Tier | Hex | Text |
|---|---|---|
| Common | `#A9B2BD` | White, ink outline |
| Uncommon | `#5DBB2F` | White, ink outline |
| Rare | `#2E8BFF` | White, ink outline |
| Epic | `#9B4DFF` | White, ink outline |
| Legendary | `#FF9F1A` | White, ink outline |
| Mythic | `#FF3D7F` | White, ink outline |

### Fight difficulty (the number over a boss, and the band on the fight overlay)
Used only on a boss's Power number and the band word. The band is also written as a word on the fight overlay.

| Band (brief, system 4) | Hex | Extra |
|---|---|---|
| Easy, Fair | `#6BE04A` | |
| Hard | `#FFE14A` | |
| Very hard | `#FF9A2E` | |
| Brutal | `#FF4B4B` | |
| Near impossible | `#FF4B4B` | A skull icon beside the number |

All are text colours with the ink outline, never fills.

### World: shared
| Name | Hex | Job |
|---|---|---|
| Lane grey | `#9AA3B2` | The lane surface, the whole length |
| Kerb white | `#F2F4F7` | The 1-stud kerb each side of the lane, plot borders and fences |
| Arrow yellow | `#FFD84A` | Direction arrows on the lane, nothing else |
| Pad stone | `#C9CED8` | Boss pads in the zones, spots at base, the bag's plinth |
| Dirt | `#7A4B33` | The underside and cliff sides of every island |
| Bag red | `#E02A2A` | The Starter Bag's body, and the red band on every bag tier (same as Huss red) |

Zone reds, oranges and blues are shifted away from Huss red, alarm orange and shield cyan so those three keep their
meaning in the world. The interactive base pieces use the UI colour of their job (cash green cash pads, shield cyan
lock pad, shop gold delivery crate), so the world and the HUD say the same thing.

### World: zones
Muted but fresh: ground colours sit at 60 to 90% value and under 60% saturation; accents may be stronger.

| Zone | Ground | Second ground | Structure | Foliage or feature | Dark | Accent |
|---|---|---|---|---|---|---|
| 1 Brick Meadow | `#A9D86B` grass | `#8FD13B` lime bush | `#B5563C` trunk and brick | `#3F8A3F` leaf | `#5C6BA8` slate cliff | `#FF7FB6` flower |
| 2 Sand Blocks | `#F0DFA0` sand | `#D9B36A` sandstone | `#C8643C` terracotta | `#4FA36A` cactus | `#9C7A4D` shade stone | `#2FC4B8` turquoise |
| 3 Pirate Plates | `#F3E7B6` beach | `#57BDE6` water | `#8A5A3C` plank | `#3E9A4A` palm | `#2E7FC2` deep water | `#C8443A` sail red |
| 4 Ice Blocks | `#F1F6FB` snow | `#9FD8F5` ice | `#6F7FA3` rock | `#2F7F6E` pine | `#5AA9E0` deep ice | `#B58CFF` aurora |
| 5 Lava Bricks | `#8C7B80` ash | `#5E5560` basalt | `#A2402E` scorched brick | `#D9CFC2` bone | `#3E3842` dark basalt (walls only) | `#FF8A1F` lava (Neon), core `#FFC83D` |
| 6 Space Baseplate | `#5566C4` plate blue-violet | `#7A63D6` violet plate | `#B9C0D4` moon rock | `#F3F5FA` rocket white | `#2C3A78` navy (walls only) | `#FFE36E` star (Neon), `#4FE3E0` cyan |

## 4. World

Terms are the brief's: a **boss pad** is where a boss stands in a zone; a **spot** is where a placed boss stands at a
base; a **cash pad** lies in front of each spot; the **bag pad** is where you stand to punch; the **lock pad** raises
the shield; the **delivery crate** holds bought bosses.

### Scale and blocks
- Everything is boxes. Sizes are whole studs and positions sit on a 1-stud grid, so stud tiles stay whole.
- Three block heights: plate (1 stud), brick (2 studs), block (4 studs). Footprints in multiples of 2 studs; 1-stud
  parts only for posts, kerbs, fence rails and one-cell accents.
- The avatar is about 5 studs tall. A door is 8 high, a fence 3, a kerb 1.
- Curves are stepped. Rotation is allowed only for: palm fronds and trunk lean (multiples of 15 degrees), awnings,
  the X bars on crates, and hazards that roll, swing or orbit.
- Every island or raised area ends in a ragged edge: a top layer in the ground colour over a thicker dirt layer whose
  bottom varies by 1 to 3 studs.
- Detail comes from stacking and offsetting blocks, never from textures or decals.

### How things are built (technique taken from the references; no layout or prop is copied)
- **Tree:** trunk of stacked square plates, each 1 stud tall, narrowing from 4 x 4 to 2 x 2 and stepping sideways so
  it leans. Canopy of 1-stud-thick slabs: palms fan out six to eight slabs that step down toward the tip; round trees
  are three slabs stacked and offset. Two greens per tree at most.
- **Bush:** two or three overlapping boxes (about 4 x 2 x 4) in the zone's two foliage colours.
- **Rock or cliff:** stacked slabs that shrink upward, with patches of ground colour spilling 1 or 2 studs down the
  sides.
- **Crate:** 4 x 4 x 4 block with a frame of 1-stud rails and an X of two thin bars on each side.
- **Building or stall:** 1-stud or 2-stud posts, walls of bricks, a counter slab, and a roof or awning of alternating
  1-stud-wide slabs in two colours with a stepped, scalloped front edge.
- **Flower and small accent:** one to three 1-stud cubes. Three to six scattered near every prop.

### Signature props per zone
Scenery only: none of these is a thing the player uses, and none is pictured in the UI.

| Zone | Props |
|---|---|
| 1 Brick Meadow | Round block tree, bush pair, flower cluster, picket fence, hay block, striped market stall, windmill, pond |
| 2 Sand Blocks | Stepped pyramid, cactus, sandstone arch, clay pot stack, palm, tent with striped awning, dune ridge, obelisk |
| 3 Pirate Plates | Brick ship, dock with posts, palm, treasure chest, barrel stack, cannon, rope bridge, lighthouse |
| 4 Ice Blocks | Ice crystal cluster, snow-capped pine, igloo, snow block wall, frozen pond, icicle arch, sled, snow fort tower |
| 5 Lava Bricks | Stepped volcano, lava channel, basalt column cluster, forge with chimney, chain bridge, bone pile, cracked ground plates, ember brazier |
| 6 Space Baseplate | Rocket on a pad, crater, satellite dish, moon rock cluster, star pylon, dome module, floating plate steps, antenna mast |

Each zone has one **landmark** at least 40 studs tall (windmill, pyramid, ship, snow fort, volcano, rocket), placed
so it is visible from the gate of the zone before it.

### The lane
- One straight lane, **36 studs wide** (the brief's width; each zone is about 120 studs long), in lane grey with a
  1-stud kerb-white kerb each side. Its colour never changes; the ground beside it changes with the zone. It starts
  inside the hub as the track (see "The hub" below) and runs on through the zone 1 arch.
- An arrow-yellow arrow built from plates every 40 studs, pointing away from the bases. (The first-session arrows
  that point home are UI, not these.)
- **Each zone's lane is a walled corridor with a centre line**, as in the manager's reference
  `concepts/manager-refs/17.png`. The brief sets the rule (TEAM CALL 41: each zone opens with a 36-wide, 30-stud hazard throat, then
  a 76-wide pad room; walls 16 tall in zones 2 to 6, and 4 tall with an invisible blocker in zone 1 so the hub keeps its
  sight line); this guide gives the look. The wall is studded and built in 4-stud bands from the zone's palette with a 1-stud top band
  in the zone's ground colour; the centre line is a 2-stud strip (the brief's width) of 4-stud dashes down the middle of the lane in the
  zone's second ground colour (never arrow yellow, which is for arrows only, and never orange or ink, which are
  hazard stripes). Zone 5 and 6 walls use their dark colours, which the palette allows for walls. A wall never
  carries stripes and never hides a hazard's warning (the 0.6 s rule). `TEAM CALL` (art-director's, the manager sees
  it at the Look review):

  | Zone | Wall | Top band | Centre-line dashes |
  |---|---|---|---|
  | 1 Brick Meadow | `#B5563C` trunk and brick | `#A9D86B` grass | `#8FD13B` lime |
  | 2 Sand Blocks | `#C8643C` terracotta | `#F0DFA0` sand | `#D9B36A` sandstone |
  | 3 Pirate Plates | `#8A5A3C` plank | `#F3E7B6` beach | `#57BDE6` water |
  | 4 Ice Blocks | `#6F7FA3` rock | `#F1F6FB` snow | `#5AA9E0` deep ice |
  | 5 Lava Bricks | `#3E3842` dark basalt | `#8C7B80` ash | `#5E5560` basalt |
  | 6 Space Baseplate | `#2C3A78` navy | `#5566C4` plate blue-violet | `#7A63D6` violet plate |
- Scenery stays at least 4 studs off the kerb (outside the corridor walls). Only hazards cross the lane.

### The hub
The base area is one walled yard at the start of the lane, a boxing gym in the open air. **Every dimension, position
and number is in `base-layout/base-layout.md` and its plans `01` to `04`; the plans are the spec.** The look:
- **Shape:** a walled yard with 8 plots in a U (4 along the back wall, 2 along each side wall), every entrance
  facing one open yard of Brick Meadow grass. Nothing stands in the yard but the track, the start line and
  scenery. No shared stands, no safe zone (the white line is the start of the lane, not a safety line).
- **Walls:** back and side walls 16 tall, the **front wall 4 tall** so every plot sees zone 1's first pads and the
  windmill over it. Trunk-and-brick `#B5563C`, studded, with a grass-coloured 1-stud top band; the ragged dirt layer
  below the hub's outer edge as for every island. An invisible blocker on the front wall line (and on each plot's
  fence line) stops anyone hopping it: it is not seen.
- **The track:** the lane's first stretch inside the yard, 36 wide in lane grey with kerb-white kerbs, arrow-yellow
  chevrons every 40 studs pointing to zone 1, and a **kerb-white start line** across it 6 studs inside the gate.
- **The gate:** zone 1's arch (see "Zone gates") in the middle of the front wall. Its sign's second line reads
  "BOSSES FROM [Common Power] POWER": a sign, never a lock.
- **Scenery:** Brick Meadow props only (round block trees, bush pairs, flower clusters), in the two back corners and
  along the front wall, 4 studs off every fence and every kerb.
- **Which plot fills first:** nearest the gate, alternating sides (`base-layout.md`, TEAM CALL 2).

### Boss pads (in the zones)
- Four a zone, beside the lane on alternating sides, where the brief puts them. A pad is a 12 x 12 pad-stone plate, 1
  stud tall, with a kerb-white border 1 stud wide: the border is the **ring** the player stands in to start a fight.
- The **fixed pad** (always the zone's Common) has four 2-stud corner posts in the zone's structure colour.
- A **rolling pad** has a sign post at its back corner with a countdown plate (UI type, white on plate blue).
- Over the boss: its name tag (name, tier chip) and its Power number, 1.5 times the name's size, in the fight
  difficulty colour for the player looking at it.
- A new roll arrives with a cube burst in its tier colour. Zone 1's fixed pad is in sight from the bases, **over the
  hub's 4-stud front wall**; its Power number is a BillboardGui readable to 320 studs so every plot sees it.

### The base plot
One per player, **8 plots** in a U along the walls of the base hub, each opening onto its shared yard
(`base-layout/`). All eight look the same: one template, turned to face the yard and never mirrored, so the bag is
always to the right of the entrance as seen from the yard. Sizes, positions and the numbered plan are
`base-layout/02-plot-plan.png` and `base-layout.md` sections 3 and 4; every pad's states are `03-pads.png`.

- **Ground and border:** a pad of Brick Meadow grass with a kerb-white border. One fence look for every plot:
  kerb-white 1-stud posts 3 high every 4 studs, two kerb-white rails, on all four edges with a 12-wide entrance in
  the front fence and a lane-grey driveway into the yard. An invisible blocker on the fence line makes the entrance
  the only way in. No per-plot colours.
- **Owner's name:** the **name board**, a studded plate-blue board (16 x 3.5) on two kerb-white posts over the
  entrance, the name in white Montserrat Black with ink outline, big enough to read across most of the yard, with the
  gold rebirth star and count at its right end once the player has rebirthed. This marker is the only place the gold
  Rebirth star icon is used; the Rebirth button and screen use the purple Rebirth arrows (section 6).
- **Punching bag:** at the front of the plot, **right of the entrance as seen from the yard**, on a 6 x 6 plinth just
  past the bag pad's right edge; the spawn faces it, the bag pad 5 studs ahead and the bag 16. It hangs from a frame
  of plate-blue posts 12 studs tall on a pad-stone plinth, as the approved kit draws it (`ui-kit/phone-hud-base.png`;
  the manager approved the kit's screens on 2026-11-25, so the picture wins). Its six tiers are below.
- **Bag pad:** an 8 x 8 plate in front of the bag, kerb white with a 1-stud Huss-red border. Standing on it starts the
  ring. States: idle; owner on it (the ring runs); first session, the cube arrow over the bag. Visitors get nothing.
- **Bag sign:** the **bag sign**, a 5 x 4 studded board on a post beside the bag pad facing the aisle and the spawn,
  plate-blue header, showing Strength and Speed levels in UI type. When a level is affordable a cash-green square
  plate lights on its corner and pulses.
- **Spots:** 10 to 17 a plot (the brief's count), in **two columns of 6 facing a 24-wide aisle and a back row of 5
  facing the entrance**: spots 1 to 10 at the front, the rebirth spots next, the Extra Spots pass spots at the back
  corners. A spot is an 8 x 8 pad-stone plate, 1 stud tall, 2 studs from the next. An empty spot has a white rim.
  While its owner carries a boss, empty spots' rims turn Neon white and pulse. An occupied spot's rim takes the
  boss's tier colour, and the boss's name tag floats above it; bosses on spots face the aisle (the back row faces the
  entrance). Rebirth spots not yet unlocked are **ghost outlines** at grass level in disabled grey `#8A919C` with a
  "REBIRTH n" plate; the two pass spots are not drawn at all until the pass is owned. An opened ghost spot becomes an
  ordinary empty spot.
- **Cash pad:** an 8 x 3 cash-green plate on the **aisle side** of each spot (in front of each back-row spot). Cash
  shows on it as stacks of small cash-green cubes with a white band, one to five stacks as the pad fills toward its
  cap, and the amount on a small tag (owner only; the tag reads "FULL" at the cap). An empty pad is the lip shade of
  green. Collected cash flies to the cash counter as cubes.
- **Lock pad:** a 6 x 6 shield-cyan plate just inside the entrance, left of it, with a white rim and the Lock shield
  icon (the padlock on a shield, board 04) on a plate in its middle. Ready: cyan with a white rim. Up: cyan rim and
  the time left. Cooldown: disabled grey with the time left. Raised by Instant Shield: shop-gold rim.
- **Lock board:** a 6 x 4.5 plate-blue studded board on two legs along the lock pad's back edge, facing the pad and
  the entrance. It carries the state plate (READY, UP 0:42, cooldown time) and the owner's two buy buttons, below. A
  visitor sees the state plate only.
  - **The two buttons** are in-world SurfaceGui buttons 1.5 studs tall, built as the kit's price button (flat fill,
    stud tile, 3 px ink outline, lip, price on it) and shown to the owner only. Both are **shop gold with ink text**
    because both spend Robux, each with its shop icon (Long Lock, Instant Shield) at 28 px. Long Lock shows until it
    is owned; Instant Shield shows only while the shield is down (ready or on cooldown). **Both are hidden while a
    steal alert or a shield-broken alert is on** and come back when it ends. The pad itself never buys anything.
- **Delivery crate:** in the **front-left corner of the front yard**, beside the lock board. The crate recipe at
  6 x 6 x 6 in shop gold with kerb-white rails and X. Gold means bought. When it holds bosses its lid is propped open
  and a tag shows the count; empty, it is shut.
- **Spots-full sign:** a 6 x 3 board on a post by the crate, alarm-orange header and panel-grey body, "SPOTS FULL".
  Shown only while every unlocked spot is full; for an owner without the pass, not carrying and with no alert, it
  carries a gold "+2 SPOTS R$ 249" button; otherwise it reads "Swap or Sell".
- **Lock shield:** when up, walls of shield-cyan stud panels **on the fence line, 16 tall**, Transparency 0.6, with a
  solid cyan 1-stud rim on the ground and a timer plate over the entrance readable across the yard. Down: only the
  rim, in white. A shield raised by Instant Shield has a shop-gold ground rim, so a visitor can see it cannot be
  broken. A broken shield shatters into a cyan cube burst and its rim flashes alarm-orange stripes for 1 s. No bubble,
  no glow, no ForceField material.
- **Text on world signs:** a letter `h` studs tall read from `d` studs needs `h >= d / 20` on a phone (a tappable
  world button `h >= d x 0.153`); text that must read from far is a BillboardGui sized in pixels (`base-layout.md`,
  section 4). The builder checks the sign sizes on a phone (section 13).

### The six bag tiers
One silhouette for all six, so it is always "the bag": a stepped octagon of slabs, 4 studs wide, hanging by a short
chain of ink-dark cubes. Every tier keeps a **bag-red band** two slabs tall around its middle: red means punch here.
The material comes from the zones, in zone order. A new tier arrives with a cube burst and stud confetti.

| Tier | Name | Strength levels | Height | Body | Detail |
|---|---|---|---|---|---|
| 1 | Starter Bag | 1 to 5 | 8 studs | Bag red all over | Its red band is the same red as the body, so it shows as the slab seams only, as `ui-kit/phone-hud-base.png` and `phone-bag-panel.png` draw it (no white band); kerb-white top cap optional |
| 2 | Sand Bag | 6 to 10 | 8 | Sand `#F0DFA0` | Sandstone `#D9B36A` cap and base, one terracotta patch |
| 3 | Plank Bag | 11 to 15 | 9 | Vertical plank-brown `#8A5A3C` slabs | Two basalt-grey `#5E5560` iron hoops, square bolt cubes |
| 4 | Ice Bag | 16 to 20 | 9 | Ice `#9FD8F5`, Transparency 0.2 | Snow `#F1F6FB` cap, three deep-ice crystals on top |
| 5 | Lava Bag | 21 to 25 | 10 | Dark basalt `#3E3842` | Neon lava cracks `#FF8A1F` down the sides, ash cap |
| 6 | Star Bag | 26 to 30 | 10 | Violet plate `#7A63D6` | Neon star-yellow cubes scattered on it, moon-rock cap, a square ring of four floating star cubes |

### Zone gates
An arch over the lane: two 4 x 4 pillars 16 studs tall and a 4-stud lintel 36 studs across, in the two ground
colours of the zone being entered, striped in 4-stud bands. A sign on the lintel carries the zone's number and name in
the UI's type, and under it a second line, "BOSSES FROM [the zone's Common Power] POWER": a sign, never a lock. The
landmark of the zone shows through the gate. Zone 1's arch is the hub's front gate (`base-layout.md`, section 2).

### Hazards
**The rule.**
- A hazard is built from its zone's own stud blocks, and it is the biggest moving thing in the zone.
- It wears **alarm orange and ink** in 2-stud diagonal bands: on the whole moving part where that suits it, and
  always on its ends or its mount. Orange-and-ink stripes mean "this knocks the boss off your head" and are used for
  nothing else in the world.
- Its path is drawn on the ground: a strip of plates along the whole track, striped the same.
- It shows where it will be at least 0.6 s ahead (the brief's rule), with a hard-edged shadow plate or a Neon
  warm-up, never a soft glow. Its real shadow is on.
- It never uses the zone's ground colour, a tier colour, or Huss red.

**The six, by the brief's names and sizes.**
| Zone | Hazard | Look |
|---|---|---|
| 1 | Rolling Log | A log 12 studs long built from stepped octagon slabs in trunk brown, with pale ring-ends and a striped band at each end. A striped strip across the lane marks its run; kerb-white stop blocks at both sides |
| 2 | Tumble Cactus | A round block cactus 8 studs wide: a stepped ball in cactus green with white spike cubes and one flower cube, a striped belt around its middle. Its zigzag is marked by striped chevron plates down the lane |
| 3 | Swinging Anchor | A brick anchor in basalt grey on a chain of ink-dark cubes, hung from a plank gantry over the lane; the flukes are striped. A striped strip marks the middle 24 studs it sweeps |
| 4 | Sliding Ice Block | A 10 x 10 block of ice (Transparency 0.2) with a snow cap and a striped collar of plates around its base. It runs on a slick strip of deep-ice plates edged with stripes |
| 5 | Lava Burst Row | Six cracked dark-basalt tiles across the lane in a striped frame. A tile about to erupt turns Neon lava for 0.8 s; the eruption is a column of Neon lava and core cubes 8 studs tall for 0.6 s |
| 6 | Orbit Meteor | A stepped ball of moon rock and violet plates with Neon star-yellow cracks and a striped band, circling on a thin mast arm. A hard-edged dark square travels under it; the circle is marked in striped plates |

### Water
Flat stud-tiled parts, not Terrain water: `#57BDE6`, Transparency 0.25, with a second opaque plane in deep water 2
studs below. A kerb-white foam line of 1-stud bricks where water meets land. No waves; an optional slow texture
drift is the animator's call.

### Sky
Bright blue with soft white cumulus clouds, as in the references. A stock skybox with clouds, or Roblox's `Clouds`
object (start: Cover 0.55, Density 0.35, white). Sun visible, no moon. A skybox asset needs the manager's yes.

### Lighting and atmosphere: base look
Clear early afternoon, soft-edged shadows that are blue rather than black, a slight haze and a slight far blur.

| Property | Value |
|---|---|
| Technology | ShadowMap. Where the place shows the newer properties: `LightingStyle = Soft`, `PrioritizeLightingQuality = true` |
| `ClockTime` | 14.5 |
| `GeographicLatitude` | 35 |
| `Brightness` | 3 |
| `ExposureCompensation` | 0.1 |
| `Ambient` | `#7F8699` |
| `OutdoorAmbient` | `#A3B0CC` |
| `ColorShift_Top` | `#FFF4D6` |
| `GlobalShadows` | on |
| `EnvironmentDiffuseScale` / `EnvironmentSpecularScale` | 1 / 0.2 (low specular keeps blocks matte) |
| Atmosphere | Density 0.28, Offset 0.1, Color `#C9E4FF`, Decay `#9DBBE0`, Glare 0.1, Haze 1.2 |
| Bloom | Intensity 0.3, Size 24, Threshold 0.95 |
| DepthOfField | FocusDistance 60, InFocusRadius 90, FarIntensity 0.18, NearIntensity 0 |
| ColorCorrection | Brightness 0.02, Contrast 0.08, Saturation 0.12, TintColor `#FFFBF2` |
| SunRays | off |

### How each zone shifts it
Lighting is global, so the shift is done on each player's client as they pass a gate: tween over 1.0 s. Only the
values in this table change. Shadows, brightness and the sun stay.

| Zone | Atmosphere Color | Density | ColorCorrection Tint | OutdoorAmbient |
|---|---|---|---|---|
| Bases and 1 Brick Meadow | `#C9E4FF` | 0.28 | `#FFFBF2` | `#A3B0CC` |
| 2 Sand Blocks | `#FFE9C2` | 0.32 | `#FFF3DC` | `#C4B49A` |
| 3 Pirate Plates | `#BFEFFF` | 0.26 | `#F2FCFF` | `#9FC2D6` |
| 4 Ice Blocks | `#E3F1FF` | 0.36 | `#EEF6FF` | `#B4C4E0` |
| 5 Lava Bricks | `#FFC9A8` | 0.38 | `#FFE8D6` | `#C09A90` |
| 6 Space Baseplate | `#B7A8FF` | 0.34 | `#EDE6FF` | `#A9A3E0` |

No zone is dark. Lava Bricks and Space Baseplate get their mood from colour, Neon parts and props, with the same sun
overhead. Dark basalt and navy are for walls and backdrops, never the ground. Space may try `ClockTime` 20 with
`Ambient` raised to `#9A9AD0` for a starry sky only if a phone screenshot of the HUD and a Common boss stays as
readable as in Brick Meadow; otherwise it stays daytime.

### Phone-safe fallback
On a touch device: DepthOfField off, Bloom Intensity 0.15, zone tweens kept (they are cheap), shadows left to
Roblox's quality scaling. The look must hold with every post effect off: flat colours, studs and the sky carry it.

## 5. Voxel bosses

The 36 creatures, their names, tiers and looks are the brief's table. This section is how each of those is drawn.

### The approved pictures (manager, 2026-11-25: "make sure bosses look like that. amazing in the images")
- The six pictured bosses in `concepts/brick-brawl/creatures.png`, as shown on the boss cards of
  `ui-kit/02-components-buttons-panels.png`, are **the approved look**: Chomp Frog, Snap Scorpion, Bit Shark,
  Frost Byte, Ember Drake and Star Golem. The built models match them: silhouette, proportions, colours (sampled from
  the picture), face, fists, cube density and signature part.
- **The one required difference:** Ember Drake's tail ends in a dark-basalt rock club with no flame (its picture has
  a flame). Everything else about the drake follows its picture.
- **Where a picture and a rule in this guide disagree, the picture wins** for that boss. The rules below were checked
  against the pictures on 2026-11-25 and changed where the pictures break them; any disagreement found later is
  settled the same way.
- **The other 30** follow the same design language: the cube size and density, the faces, the oversized block fists,
  the matte cubes with a few glowing ones, and the proportions of the six, to the rule below.
- **Acceptance:** a built boss that does not match its approved picture is not accepted. The six are built first; the
  manager looks at renders of them beside their pictures (same angle, same order as `creatures.png`) before the other
  30 are made.

### What the six pictures show
| Boss | Read from its picture |
|---|---|
| Chomp Frog | Squat and wide, almost no neck: the head is the top of the body. Big green fists with a yellow wrist band, cream belly, wide open mouth with pink inside, angry eyes on top |
| Snap Scorpion | Low orange body with cream-tan bands, tan legs, two big orange claws with a yellow band as fists, the face on the front of the body, a segmented tail curling up and over with a red stinger |
| Bit Shark | Blue shark standing on its tail, white belly and jaw, a huge open mouth of white teeth taking most of the head, dorsal fin, fin fists |
| Frost Byte | White-and-lavender fur, a pale-blue face plate with an angry brow and a square-tooth grin, big blue fists and blue feet, arms hanging forward |
| Ember Drake | Bright red with a cream-gold belly of plates, yellow horns, wings of red bone with a yellow-orange membrane, glowing lava cracks on chest, arms and legs, red fists; tail as the required difference above |
| Star Golem | Huge purple body with gold armour bands, a gold halo ring over a small head, glowing yellow slit eyes, a glowing star on the chest and stars over the body, gold-capped feet, oversized purple fists. Floating gold star cubes around the halo |

### The creature rule
- Built only from **cubes**, with no studs, no smooth curves and no geometric bevels. Every cube face shows a thin
  darker edge so the cubes read, which does in the build what the soft edges do in the pictures.
- **Cube size and density, as in the pictures:** the cubes are small against the body, about 20 cubes from feet to
  crown on a Common and about 34 on a Mythic, so the cube size grows a little with the tier (table below). Bigger
  bosses have both more and slightly bigger cubes. (The earlier rule of one 0.5-stud cube for every boss, 8 cubes
  tall on a Common, is replaced: the frog in its picture is about 19 cubes tall.)
- **Colours:** three or four flat body colours plus one accent, as the brief describes each creature. Two or three
  close shades of one body colour may be scattered cube by cube, as the fur and scales are in the pictures. Glow
  colours are counted apart: at most three. A word like "shiny" in a description is drawn as a row of lighter cubes,
  never as gloss. Matte, never glossy.
- **Zone colours (the other 30):** at least one body colour or the accent is a hex from the creature's zone palette.
  Where a description names a zone material (bark, sandstone, plank, ice, lava, rock, star), it uses that zone's
  exact hex. The six use the colours of their pictures.
- **Silhouette:** recognisable as its creature filled in solid black at 64 px tall. The head, with its hood, crown,
  horns or ears, is about a third of the height on Common to Epic, as in the frog, scorpion, shark and yeti; a big
  Legendary or Mythic may have a smaller head on a massive body, down to a sixth, as Star Golem does.
- **Fists:** at least two block fists, or the creature's own version (claws, fins, flippers, wingtips, hooves,
  tentacle ends), each at least 1.5 times as wide as the limb behind it; the pictures make them nearly as wide as
  the head. This is a punching game: every boss can punch. Where a description gives more (Tidal Kraken's four), it
  has more. Where it gives no limbs (Magma Hydra), the two outer heads do the punching.
- **Face:** flat, on the front of the head (or of the body, where the head is the body: frog, scorpion), the biggest
  thing on it. Two eyes, white with an ink pupil, each at least 3 x 3 cubes at the picture's density, or one large eye
  where the description says so (Moon Mite). A stepped angry brow. An open mouth with square white teeth and a pink
  inside, or a square beak where the creature has one. No nose, unless the description names one, and then it is a
  single cube (Bop Bunny). A boss with several heads has a full face on each. Glowing eyes with no pupil only where a
  picture or description says so (Star Golem's yellow slits, Timber Bear's amber, Void Mantis's magenta).

### Glow
Two different things, so that tier still reads and the brief's descriptions all fit.

**1. Element glow: any tier.** Neon cubes that are part of the creature's own description: lava cracks, embers, a
fuse, eyes, flowers, ice, a turquoise pattern, stars, a sun disc. They sit on the body, they are the zone's element,
and their share of the boss's outside cubes is capped by tier:

| Tier | Element glow, at most |
|---|---|
| Common, Uncommon | 3% |
| Rare, Epic | 6% |
| Legendary | 10% |
| Mythic | 15% |

A face is never Neon (Neon has no shading, so a Neon face cannot be read), except the eyes where the description
or the approved picture says the eyes glow (Star Golem).

**2. Tier aura: Legendary and Mythic only.** Extra to the description, the same for every creature of the tier:
Legendary has 6 small cubes in its tier colour drifting slowly around it; Mythic has 12 and a slow pulse on its
element glow. On a spot or a boss pad the rim also throws a tier-colour cube every second. Nothing below Legendary
has an aura. The aura is an effect around the model, not part of it, so Ember Drake's picture (no aura) does not
rule it out. Star Golem's picture already shows its aura: the floating glowing gold star cubes around the halo are
its 12 aura cubes, gold in place of the Mythic pink. The manager confirms both at the first-six review.

**Detached parts** that a description names (Orbit Jelly's ring of yellow cubes, Sun Sphinx's sun disc, Star Golem's
halo) are part of the body at any tier: at most 8 cubes below Legendary, matte unless they are that creature's
element glow and inside its share.

Checked against all 36 descriptions on 2026-11-25. Glow named below Legendary, all inside the caps: Cinder Newt's
ember row (Common), Coal Boar's flank cracks (Rare), Molten Gorilla's chest and knuckles (Epic). Orbit Jelly's ring
(Uncommon) is a matte detached part of 8 cubes. Comet Hound's tail (Rare) is matte white-blue; it may take a few Neon
cubes inside 6%. One needs a reading, given under "Notes on single creatures": Magma Hydra.

### Tier: size, cube count and budget
Sizes are for the boss standing on its boss pad. The avatar is about 5 studs.

| Tier | Height | Cubes tall (about) | Cube size (about) | Triangle budget (all its meshes) |
|---|---|---|---|---|
| Common | 4 studs | 20 | 0.2 studs | 600 |
| Uncommon | 5 | 22 | 0.23 | 1,000 |
| Rare | 6.5 | 25 | 0.26 | 1,600 |
| Epic | 8 | 28 | 0.29 | 2,500 |
| Legendary | 11 | 31 | 0.35 | 4,000 |
| Mythic | 14 | 34 | 0.41 | 6,000 |

Cube counts are read from the pictures (frog about 19 tall, shark about 26, yeti about 30, golem about 34 without
its halo); the picture wins over this table for the six.

Tier shows in size, cube count, glow share and the aura. What a creature wears or carries comes from its description
in the brief, not from its tier. Budgets count outside faces only; inside faces are removed. Roblox's limit
is 20,000 triangles a mesh; the budget is far under it because the worst case is **8 players x 17 spots = 136 placed
bosses** in view of the bases, plus 24 on boss pads. The pictures' cube density may not fit these budgets: the
modeler counts the first six, and if they do not fit, the picture wins and the performance-optimizer measures a
raised budget (section 13).

### Notes on single creatures
- **Ember Drake (z5_t5), as its approved picture shows it:** bright red body and fists, a cream-gold belly of
  stepped plates, yellow horns (matte), wings of red bone with a yellow-orange membrane, colours sampled from the
  picture. **The tail ends in a dark-basalt `#3E3842` rock club with no flame on it**, about the size of one of its
  fists, in place of the picture's flame. Its glow is the picture's Neon lava cracks on the chest, arms and legs,
  inside the Legendary 10%. No flame cubes anywhere: not on the tail, not in the mouth.
- **Magma Hydra (z5_t6):** "all glowing" is drawn as Neon cracks, eyes and mouth-insides on all three heads and down
  the body, inside the Mythic 15%, with the three heads in three matte shades (red, orange, gold). The heads are not
  solid Neon. Its two outer heads are its fists.
- **Roll Beetle (z2_t1):** the "shiny" shell is flat turquoise `#2FC4B8` with one row of lighter cubes.
- **Glacier Mammoth (z4_t5):** "clear glowing ice" tusks are Neon in ice blue; they are not see-through.
- **Aurora Owl (z4_t6):** the shifting colours are the feather-tip cubes only, stepping between green, pink and
  violet every 2 s, inside 15%.

### How they are made
- One **voxel builder script per boss**, run in headless Blender (`blender -b --factory-startup --python ...`), from
  a grid of layers written as data. 1 Blender unit = 1 stud. It removes hidden faces, exports FBX and prints the
  triangle count and size. No Higgsfield 3D is needed. The six are built from their approved pictures, viewed side
  by side with a render of the build until they match. Higgsfield is optional for concept sheets of the 30 creatures
  not yet drawn (about 2 credits a sheet), made with `creatures.png` as the style reference, which the builder
  follows by eye.
- **Moving groups:** named groups per body type, each its own mesh with its own pivot, so it can move without a
  skinned rig. The list and pivots are under "Fight animation: what the modeler delivers". The whole model's pivot is
  at the middle of the feet.
- **Colour:** preferred: one shared texture for all bosses, `boss-atlas` (256 x 256, cells of 32 px, each cell one
  flat colour with a 2 px edge 12% darker); every cube face maps to the cell of its colour, UVs inset 1 px. One mesh
  per moving group, and a re-skin is one image. Fallback, the team's proven route: one mesh per colour role, coloured
  by `MeshPart.Color` in a Studio setup script, with no edge lines. The modeler picks after one test boss.
- Neon cubes are separate parts in Neon material.
- Every picture of a boss in the UI (boss panel, Lucky Spin outcomes, Starter Pack offer, shop) is a render of its
  real mesh, never generated art.

### Carried, placed, idle
- **Beaten:** the boss shrinks and hops onto the player's head.
- **Carried:** upright above the head, facing forward, its feet 0.5 studs above the head, scaled so it is never taller
  than 6 studs. It leans back 8 degrees and rocks 4 degrees each way in time with the run. A stolen boss is carried
  the same way.
- **Dropped** (hazard hit): it lies on its back where it fell with a white square timer plate over it for the 5 s it
  can be grabbed, then bursts into cubes.
- **On a spot:** centred, facing the plot's aisle (the back row faces the entrance), scaled so it is never taller than 9 studs (so Legendary and Mythic fit an
  8 x 8 spot). It lands with a thump and confetti cubes. Full size is for the boss pad in the zone.
- **Idle, hit and every fight move:** under "Fight animation" below.

### Fight animation (brief, system 4; manager: "should have small fighting animations too. and if its like a scorpion it should use its tail to stin")
Every boss fights with its own body, in small, quick moves. The moves are made once per body type (the brief's 7)
and the signature move once per creature. All of it is client-side dressing of results the server already decided.

**How a cube boss moves**
- **Rigid groups only.** Each moving group (below) moves as one solid piece: it turns, shifts and scales about its
  own pivot. Nothing bends, stretches along a curve, or is skinned; no single cube moves on its own. A curl (a
  scorpion's tail) is two rigid segments turning at their joints.
- **Snappy and stepped.** A move is two to four key poses. The boss snaps between poses in 0.04 to 0.08 s (Quad Out,
  or Back Out for a strike landing) and holds each pose; it never floats from one to the next. Only the loops (idle
  bob, guard bounce, hover, sway) use Sine.
- **Sizes are fractions of the boss's height (H)** from each group's own pivot, so one set of moves fits a Common and
  a Mythic. A "step" is 0.2 H.
- **Squash and stretch by scale, within limits.** Body group: never under 0.85 or over 1.15 on any axis, and a squash
  in one axis is a stretch in the others (0.9 tall goes with 1.1 wide). A fist or signature part may pop to 1.2 on
  its impact frame. The head is never scaled. These sit inside the guide's motion limits (section 6, Motion).
- **Anticipation, strike, impact, recover.** Every strike has the same four beats: a wind-up pose pulling the other
  way (the body dips 0.05 H and leans back, the striking part draws back), held; the strike, reached in 0.05 to
  0.06 s; the impact pose held 0.06 s with the striking part at 1.2 scale; the recover to guard with Back Out. The
  impact frame is where the hit lands: the flash-yellow impact star (section 7) appears at the striking part, the
  avatar flinches and the heart breaks on that frame.
- **Hits taken use the VFX language already set:** a white flash of 0.05 s on the whole boss and a cube burst in the
  boss's own colours from the point hit (section 7: 6 to 8 cubes on a Good, 10 on a Perfect, 12 on the big huss,
  never over 24 particles a hit on a phone). A strike by the boss throws 3 or 4 cubes in the striking part's colours
  at the impact point. The camera shakes only on a clean big huss and on beating a boss, as in section 7.

**The moves, with the brief's lengths**
| Move | Length | Poses and timing |
|---|---|---|
| Idle (on a boss pad, nobody fighting) | loop | Body bobs 0.03 H on a 1.2 s Sine; head bobs the other way. Every 2.5 to 4 s the fists throw three jabs at the rhythm of the manager's recording (about 0.21 s, then 0.19 s between jabs): each fist out 0.08 H in 0.05 s and back in 0.08 s. Detached parts orbit once every 6 s |
| Guard (fight start and between punches) | loop for the fight | Turns to face the player in 0.12 s, Back Out; body-type guard pose (table below), fists or signature part up. A bounce of 0.02 H that lands as each ring lands, so the boss breathes with the ring |
| Hit reaction, Good | 0.15 s | Frame 1: head snaps back 15 degrees, body squashes to 0.9 tall and 1.1 wide, white flash, cube burst. Recover 0.1 s Back Out |
| Hit reaction, Perfect | 0.2 s | As Good, twice as far: head 30 degrees, squash 0.85 and 1.15, body slides back half a step (0.1 H) in 0.05 s |
| Hit reaction, big huss | 0.3 s | Knocked back a full step (0.2 H) in 0.06 s; staggers (body tilts 12 degrees back, then 6 forward); fists drop below the waist for 0.1 s, then back up to guard |
| Attack (a Miss): the signature move | 0.45 s | Wind-up 0.15 s (held for its last 0.05 s so it reads), strike 0.06 s, impact at about 0.21 s held 0.06 s (heart breaks), recover to guard by 0.45 s. A two-beat signature (sting then pincer) lands its second beat 0.12 s after the first and recovers in the time left; the heart breaks on the first |
| Last heart lost: signature and gloat | 1.0 s | The signature once more with the striking part at 1.2 and the wind-up 0.2 s; the avatar goes down; then a 0.35 s gloat (fists pumped up twice, or its own version: tail raised high, hood flared, wings spread, tentacles up), then idle |
| Defeat | 0.8 s | Wobbles 10 degrees each way twice (0.2 s), fists drop (0.1 s), flops down onto its back or face (0.15 s) with a cube burst, flashes white (0.05 s), then shrinks to carry size and hops onto the player's head (0.3 s, Back Out) |
| Half idle (placed on a spot) | loop | The idle at half: bob 0.015 H, one jab triplet every 6 to 8 s, detached parts orbit. Never a guard, reaction, attack or signature |
| Carry rock (on a head, every boss) | loop | Leans back 8 degrees and rocks 4 degrees each way in time with the run; no other move |

A reaction still playing when the next result arrives is cut and the new one starts from its first frame (brief).

**Body types: guard pose and attack template** (the brief's table; the signature part leads)
| Body type | Guard | Attack template (0.45 s) |
|---|---|---|
| Biped bruiser | Upright, fists up at the chin, bouncing | Wind-up: weight back, striking fist (or signature part) drawn back past the head. Strike: body slides a step in, the blow comes down or straight through |
| Squat stomper | Low and wide, fists out to the sides, a small hop on each ring | Wind-up: squashes to 0.88 tall. Strike: a hop of a step forward (0.05 H high), landing on the impact frame with a short strike of mouth, shell or fist |
| Tailed striker | Body low, tail raised high behind, segments held in an S | Wind-up: body dips, tail segments cock back. Strike: the tail swings over or around the body to land in front, then a fist as the second beat |
| Charger | Head down, a front foot pawing (one 0.05 H tap every 0.6 s) | Wind-up: backs off half a step, head lowers. Strike: a rush of one step and the head or a front paw lands |
| Rearing swayer | Upright on tail or base, swaying 6 degrees on a 1.0 s Sine | Wind-up: the upper body rears back 20 degrees. Strike: lunges forward from the base, 0.25 H, head or jaw first |
| Flyer | Hovering 0.1 H off the pad, wings beating in two snapped poses every 0.12 s | Wind-up: rises 0.1 H, wings up. Strike: a dive of a step, down and forward, landing the blow at the player's chest height |
| Tentacled floater | Floating 0.08 H up, tentacles curling in two poses every 0.3 s | Wind-up: tentacle fists swing back. Strike: one lash, or both, one after the other |

**How a signature part reads.** The signature part moves most and lands the hit; the rest of the body only leads
into it and follows it. It is the brightest or most distinctive part of the boss already (a stinger, horns, a hood,
a halo, a rock club), and it keeps its shape: it turns about its root, it never bends. The manager's example, frame by
frame:
- **Snap Scorpion, "stings with its tail over its head, then a pincer punch":** 0.00 to 0.15 s, body dips and leans
  back, both tail segments cock back, claws open; 0.15 to 0.21 s, the tail whips over the body so the red stinger
  lands in front of the head at the player's chest; impact held to 0.27 s (heart breaks, star at the stinger);
  0.27 to 0.33 s, the right claw punches out 0.25 H and pops to 1.2; 0.33 to 0.45 s, claw and tail back to guard.
- **Ember Drake:** turns 90 degrees away (wind-up), swings back so the rock club lands (first beat), then a red fist
  (second beat). No flame at any frame.
- **Star Golem:** its halo flashes once (a Neon pulse inside its glow share) on the wind-up, then one hammer punch.
- Effects named in a signature (Cannon Turtle's smoke cubes, Cinder Newt's ember spray, Bloom Stag's petal cubes,
  Flurry Fox's snow cubes) are cube bursts at the boss's own striking part that land on the impact frame. Nothing
  flies across the pad or leaves the boss pad.

**What never happens**
- No slow motion, no hit pause that slows the game (the 0.06 s impact hold is a pose of the boss, not a pause), no
  freeze frame.
- No camera takeover: no cut, zoom, orbit or close-up for any move. The fight camera frames the boss as the brief
  says and stays put; shake only as in section 7.
- Nothing hides, covers or delays the timing ring or the Huss button: no effect in screen space over the bottom
  right, no boss part or burst drawn over the UI, no screen flash. The next punch's ring starts on schedule whatever
  the boss is doing.
- No bending meshes, no skinned rigs, no projectiles, no move that leaves the boss pad, no fight move or signature on
  a placed or carried boss.

**Staying cheap with 136 placed bosses**
- Bosses on spots play only the half idle (brief, system 4, Cost), with each boss's loop started at a random phase so
  a row never bobs in step. It runs on the client, updated about 15 times a second (stepped motion does not need
  more), only for bosses on screen and within 150 studs; beyond that they stand still.
- Fight moves play only on bosses on boss pads within 150 studs of the camera. The performance-optimizer may tune
  the distances and the update rate and reports the frame time measured.
- Moves are tweens of group offsets, not Animation assets: no `Animator`, no keyframe sequences to load per boss.
  The animator-vfx picks the route (a group's pivot `CFrame`, or `Motor6D.Transform`, per the animator-vfx playbook).

**What the modeler delivers for it.** Every boss model has these groups, each its own mesh (Neon cubes are separate
parts welded to their group), named exactly as below, with its pivot where it turns:

| Body type | Groups and pivots |
|---|---|
| All | `Body` (pivot at the middle of the feet, or of the base for floaters); `Head` (pivot at the neck); `FistL`, `FistR` (pivot at the shoulder or claw root, so a fist swings from it) |
| Biped bruiser | plus `Sig` where the move uses a part apart from the fists (horns, antlers, halo, blade forearms; pivot at its root) |
| Squat stomper | plus `Sig` (jaw, shell, cannon, tusks, antennae). Where the head is the body (Chomp Frog), `Head` is the upper face and jaw block, pivot at the back of the jaw |
| Tailed striker | plus `TailA` (pivot at the tail root) and `TailB` (pivot at the joint between the two segments; holds the stinger, club, spikes or comet tip) |
| Charger | `Head` carries the horns or tusks and is the striking part; plus `Sig` for a detached part (Sun Sphinx's disc) |
| Rearing swayer | `Body` is the lower body or tail base; `Upper` (pivot where it rears) carries `Head`; Magma Hydra: `HeadMid`, and `FistL`, `FistR` are the outer heads |
| Flyer | plus `WingL`, `WingR` (pivot at the wing root) |
| Tentacled floater | plus `Legs` (the curled tentacles below, pivot at their root); Tidal Kraken adds `FistL2`, `FistR2` |

Groups nest in the order they move (`Head` in `Upper` in `Body`, `TailB` in `TailA`). Each boss is delivered with a
render of its guard pose and of its signature's impact pose, so the art-director can check the move reads before any
code is written.

### Originality
No boss resembles a known character from any game, film, show or toy line, in shape, colours, face or name. If a
design brings one to mind, change the silhouette first, then the colours. The six pictured bosses are approved as
they are (above); this rule is checked for each of the other 30 before its builder script is written.

## 6. UI style

Design frame: **874 x 402** (phone, landscape). All sizes below are in that frame.

### Panel
- Fill panel grey, stud tile over it, **3 px ink outline**, **corner radius 4 px** (square reads as built from
  blocks; nothing in the UI is a pill), hard shadow: ink at 35%, offset 5 px down, no blur.
- Header bar: 44 px tall, plate blue with studs, 3 px ink line under it, title on the left, a 36 px white close
  button on the right inside a 44 px touch area.
- Content sits in **wells**: white, smooth, 2 px ink outline, radius 4 px. A list row is a well.
- A boss card is filled with its tier colour (smooth), the boss render on top, the tier chip under it.
- Padding 10 px, gap 8 px. One hero per screen: the biggest, brightest thing is the one main button.
- Nothing is see-through except the 45% ink dim behind an open panel.

### Buttons
| State | Look |
|---|---|
| Default | Flat fill in its job colour, stud tile, 3 px ink outline, radius 4 px, a 5 px lip (fill x 0.72) along the bottom, a 2 px line of fill lightened 25% along the top. 48 px tall, never under 44 |
| Hover (mouse) | Fill lightened 8%, lifts 1 px |
| Pressed | Face drops 4 px so the lip is 1 px, fill x 0.9, in 0.06 s. On release it pops to 1.06 and settles in 0.12 s |
| Disabled | Disabled grey fill, studs stay, no lip (2 px), text `#D5D9DF`. A tap shakes it 6 px twice in 0.15 s |
| Locked by progress | Disabled look plus the Locked icon (grey padlock) on the left and the requirement as the label ("Power 500") |
| Greyed with a reason | Disabled look with the reason as its label ("Just joined", "Instant Shield", "Broken recently, 3:20") |
| Robux | Shop gold fill, ink text, the Robux price on the button. A cash pack's button shows the cash icon, the exact cash it gives, then the Robux price. Never grey unless it truly cannot be used |
| Owned | A pass already bought: disabled look with the Done check and "OWNED" |

Button colours mean one thing each, as the kit draws them: red is Huss; green spends earned cash, collects, or
confirms an ordinary action; gold is Robux (spending it, or a ticket bought with it); cyan is the lock; orange
confirms something that can't be undone and loses a bought boss or a run (selling or swapping a bought boss, the
rebirth confirm); white is everything else. A screen may have more than one green button (the bag panel has two);
the hero rule still holds: one button is biggest and brightest.

### The lock button and shield plate
The HUD has two lock pieces top right, drawn on board 03: the **shield plate** (a counter plate) and under it the
**lock button** (a square studded tile with the Lock shield icon, "LOCK" in outlined caps under it), shown only inside
your own base. Their states:

| State | Shield plate | Lock button |
|---|---|---|
| Shield up | Shield cyan, Lock shield icon, time left counting down | Shield cyan with its lip, as on `hud-base`. A tap while up only pops the plate's time (it is already on) |
| Cooldown (shield down, can't be raised yet) | Disabled grey, the grey cracked Shield down icon, cooldown time counting down | Disabled grey, grey Lock shield icon; a tap shakes it |
| Ready (shield down, can be raised) | Not shown, or the plate in disabled grey reading "0:00" until raised (gui-designer's call, one way everywhere) | Shield cyan with its lip, as in the button-states row of board 02 |

Grey always and only means cooldown here; cyan always means the shield is up or can be raised. The button is never
grey while the shield is up.

### Tier chip
A smooth rectangle, 22 px tall, radius 4 px, tier colour, 2 px ink outline, the tier word in 14 px caps, white with
ink outline. Never a dot or a strip.

### Bought tag
The small gold tag on a bought boss. A smooth rectangle 22 px tall, radius 4 px, shop gold, 2 px ink outline, the
word "BOUGHT" in 14 px caps in ink. It sits to the right of the tier chip, on the boss's name tag in the world and on
its boss panel. Same shape as the tier chip so the two read as a pair; gold so it reads as Robux.

### Counter plates (Power, cash, shield, spin tickets)
A studded rectangle 32 px tall, radius 4 px, 3 px ink outline, in its job colour (Huss red, cash green, shield cyan,
and shop gold for the spin-ticket plate on the Lucky Spin screen, with ink text). Its icon is 36 px and overlaps the
left edge by 8 px. The number is 18 px, white with ink outline. Not pressable, so no lip. The shield plate's states
are in the table above.

### The bought-cash number
Not a counter plate and not a button: a plain white well (smooth, 2 px ink outline, radius 4 px) with the cash icon
at 36 px on the left, "BOUGHT CASH" in 14 px ink caps, the amount under it in 22 px Montserrat Black in ink, and one
line of body text in ink ("Bought cash you have not spent comes with you through rebirth. Earned cash is always spent
first."). It sits beside the cash packs in the shop (it fills the empty cells of that band) and in the YOU KEEP well
of the rebirth screen as one line. No stud, no gold, no lip: it is information, not something to press or buy.

### The Huss button, timing ring and pips
- The Huss button is the only round thing in the UI, so it cannot be mistaken: 120 px across, Huss red with studs,
  4 px ink outline, 6 px lip, the glove icon and "HUSS!".
- **Timing ring:** a white ring, 6 px thick with a 2 px ink line each side, that starts at 1.6 times the button's
  width and closes onto it. The **hit band** is a flash-yellow ring 10 px thick sitting just outside the button
  (1.0 to 1.15 times its width). A hit: the band and button flash flash-yellow for 0.08 s, an 8-point hard-edged
  impact star pops behind the button, and "GOOD" or "PERFECT" pops above it (20 px caps; GOOD in white, PERFECT in
  flash yellow, both outlined). A Miss: the ring turns disabled grey and the button shakes.
- **Pips:** three squares, 18 px, 4 px apart, 2 px ink outline, centred above the button. Empty: `#3A4250`. Filled:
  Huss red with a 2 px lighter top line. Each fills on its punch with a pop to 1.25 in 0.08 s. The third, the big
  huss, pops to 1.4 with a bigger star; then all three flash flash-yellow and clear after 0.15 s.
- When the owner is beside a thief the same button punches with no ring: the ring and band are hidden.
- How fast the ring closes and whether three pips read as "huss huss huss" are questions for the manager's playtest.

### The 13 screens
Every screen is built from the pieces above. This is what is particular to each.

| # | Screen (brief) | Look |
|---|---|---|
| 1 | HUD | Power plate and cash plate top left; the zone strip top centre; the shield plate top right. Huss button with ring and pips bottom right, beside the jump button. On the left edge, square studded tiles with the word under them in outlined caps: Shop (gold tile, the red-and-white Shop bag icon) and Rebirth (white tile, the purple Rebirth arrows icon, a plate-blue bar under it), and **Settings** under Rebirth (white tile, the grey gear icon from board 04, the same tile component; it opens screen 13; added by the brief as a TEAM CALL; the gui-designer checks it clears the thumbstick on the smallest phone). The lock button (cyan tile, under the shield plate, states above) shows only inside your base; the Sell button (green, price on it) only while carrying inside your base. One hero: the Huss button |
| 2 | Fight overlay | A plate across the top: boss name, tier chip, health bar 14 px tall in the boss's tier colour on an ink track. Three hearts (square-built, Huss red; a lost heart is `#3A4250`). The band word in its difficulty colour. Run is a white button top left. Nothing covers the Huss button |
| 3 | Boss panel | Boss card on its tier colour at left; name, zone, tier chip, bought tag; level as square pips in cash green; a well with "earns now" and "after"; Upgrade (green, price on it) as the hero; Pick Up (white) |
| 4 | Bag panel | Two wells, Punch Strength and Punch Speed, each with level, now and next, and a green price button. A third row: the Auto Punch toggle (a square switch: cash green when on, disabled grey when off), or its gold Buy button. A fourth row, once Auto Punch is owned: the Perfect Auto Punch gold Buy button, or, once it is owned, the toggle shows PERFECT |
| 5 | Shop | One scrolling panel, gold header with the Shop bag icon, bands with outlined captions (passes; cash packs; shields and the Lucky Boss Spin). Product cards filled with a colour by kind: passes and the Starter Pack panel grey, cash packs cash green, the Lucky Boss Spin card shop gold, Long Lock and Instant Shield shield cyan, the three attacking products (Quick Hands, Iron Grip, Shield Breaker) alarm orange. Each card: icon, name, one line in a white well, the price on a gold button; an owned pass shows the Owned button. Shield Breaker's button is greyed "BUY AT A SHIELD"; the spin card's button is white "SEE THE ODDS" and opens screen 6. The bought-cash well (above) sits beside the cash packs |
| 6 | Lucky Spin | Zone picker as six zone badges; the six outcomes as boss cards on their tier colours with name, render and percentage in 18 px, always on screen before Spin or Buy; tickets owned on the gold spin-ticket plate; Spin (gold, it spends a ticket bought with Robux) as the hero; ticket bundles on gold Robux buttons. The round Lucky Spin wheel icon. The reveal uses the boss card, the BOUGHT tag, a cube burst in the tier colour and the tier word |
| 7 | Rebirth | Plate-blue header with the purple Rebirth arrows icon; requirement and plate-blue bar; three wells: "REBIRTH RESETS", "YOU KEEP", "YOU GET", with the brief's text and the player's own numbers; the Rebirth button white with the Rebirth arrows icon. Its second press opens **its own "REBIRTH NOW?" panel**, as `ui-kit/phone-rebirth-confirm.png` draws it, not the shared boss-card confirm: a plate-blue header with the title, the large purple Rebirth arrows on the panel at left, one white well with the brief's text (what the run resets, what you keep, "This can't be undone."), and a white Cancel and an **orange** Rebirth button (with the Rebirth arrows icon) of equal size, orange because a rebirth can't be undone. The gold star appears only in the "YOU GET" line's words, never as the button's icon |
| 8 | While you were away | Small panel: the cash icon, the amount counting up in 22 px, Collect (green) |
| 9 | Starter Pack offer | Gold header; two cards (the cash amount on green, Headbutt Ram's render on Epic purple); the price on one gold button; a white close button the same size as any other. No timer, no "% off", no struck-out price |
| 10 | Steal and shield alerts | Banners are alarm-orange studded plates 40 px tall across the top centre, ink outline, white outlined caps, with a square arrow chip pointing to the thief or home. "Get it home!" for the thief is the same plate in cash green. The "Break shield R$39" button is a gold Robux button on the other player's shield, or greyed with its reason |
| 11 | Confirm | One small panel: the boss card, one line in a well (it says so when the boss was bought), a confirm and a white cancel of equal size. The confirm is **green** for selling or swapping an earned boss (an ordinary action) and **alarm orange** for selling or swapping a bought boss (can't be undone, loses something bought). The rebirth confirm is not this panel: it is screen 7's own "REBIRTH NOW?" panel, with an orange confirm of the same meaning |
| 12 | Toasts and prompts | A prompt is a white studded plate with the input glyph on a small ink plate (on touch, the action's icon) and the word. The Steal hold fills a square frame around the glyph clockwise in alarm orange over 2 s (it is aimed at another player). Toasts are 32 px studded plates bottom centre: grey for information ("Sent to your crate"), orange for "can't do that" ("Spots full", "Not enough cash"), green for a purchase done; the Extra Spots offer under "Spots full" is a gold Robux toast ("+2 SPOTS R$ 249") the player chooses to press |
| 13 | Settings | Opened by the HUD's Settings tile. A small panel with two rows in wells: music and effects, each a square-handled slider with a plate-blue fill |

The first-session arrow is a chunky arrow built from cubes in flash yellow with an ink outline, bouncing over its
target; the trail home is the same arrow, small, repeated along the lane.

### Type
One family: **Montserrat**, which is built into Roblox (`rbxasset://fonts/families/Montserrat.json`; the legacy
`Enum.Font.GothamBlack` and `GothamBold` map to it). Upright, never italic.

| Use | Weight | Phone (design px) | Desktop (about 1.6x) | Style |
|---|---|---|---|---|
| Screen title | Black | 22 | 35 | Caps, white, 2 px ink outline, ink shadow 2 px down |
| Huss label, GOOD and PERFECT | Black | 20 | 32 | Caps, same |
| Button, counter number | Black | 18 | 29 | Caps for buttons, same |
| Boss name, row title | Black | 16 | 26 | Same |
| Tier chip, bought tag, small label | Black | 14 | 22 | Caps |
| Body, descriptions, odds, rebirth lists | Bold | 14 | 22 | Sentence case, ink on a white well, no outline |

**Game icon lettering.** The game icon carries the word HUSS (the manager: "lets do work huss yes"): set in FigCraft in Montserrat Black caps, white with an ink outline and ink shadow as the Huss label, never generated by an image model.

No text renders under 14 px on any device. Outlines are 2 px on phone and 3 px on desktop. Numbers shorten at four
digits and up (48.2K, 1.25M). If the manager wants a rounder face, the alternates that exist in Roblox are Fredoka
One and Luckiest Guy (caps only); swapping is one token.

### Icons
- Generated in Higgsfield, never drawn from shapes, in one style: **a chunky object built from cubes and stud
  blocks, seen from the front and slightly above, flat palette colours with one shadow tone, a thick ink outline and
  a white rim (about 40 px at 1024), on a clear ground.** No gloss, no gradients, no glow, no soft shadow.
- **The set is board 04 (`ui-kit/04-icons.png`), approved by the manager on 2026-11-25 ("icons, all amazing").**
  Exactly these 64 icons exist (8 stats, 20 HUD and actions, 11 status, 6 zone badges, 19 shop products); one not on the board is not made, and every new or remade icon uses the board as its
  style reference. The list, in the board's order:
  - **Stats (8):** Power (a red fist in a yellow burst), Cash (a green bill stack with a gold coin), Punch Strength (a
    red flexed arm), Punch Speed (a red glove with speed lines), Spin ticket (a gold ticket), Heart (red), Heart lost
    (dark grey), Rebirth star (gold; only for the marker by the player's name).
  - **HUD and actions (20):** Huss glove (red glove, yellow cuff), Shop (a red-and-white bag), Rebirth (purple
    circular arrows), Upgrade (a green arrow up), Pick up (a hand lifting a green cube), Place (a tray with a green
    arrow down), Grab (a hand gripping a green cube), Steal (an orange grabbing hand), Sell (a gold price tag), Swap
    (blue and purple arrows), Run (a running shoe with speed lines), Done (a green check), Settings (a grey gear),
    Music (white notes), Effects (a white speaker), Bag panel (a red punching bag on a blue stand), Lucky Spin (a
    round colour wheel), First-session arrow (a yellow arrow down), Pointer arrow (a white arrow), Boss beaten (a gold
    trophy).
  - **Status (11):** Lock shield (a padlock on a cyan shield), Shield (cyan), Shield down (a grey cracked shield),
    Shield broken (a cyan shield split), Locked (a grey padlock), Timer (a red stopwatch), Steal alert (an orange
    siren), Hazard (an orange-and-ink warning triangle), Near impossible (a skull), Offline earnings (a blue moon with
    cash), Delivery crate (a brown crate).
  - **Zone badges (6):** a tree, a pyramid with a cactus, a ship, ice crystals, a volcano, a rocket.
  - **Shop products (19):** Auto Punch (a glove on a spring), Perfect Auto Punch (the same glove on a spring with a yellow-and-orange starburst behind it, so the two read as a pair), 2x Power (two red gloves), 2x Cash (two bill stacks),
    Fast Carry (a winged boot), Long Lock (a cyan padlock with a clock), Extra Spots (two grey plates with a green
    plus), Quick Hands (an orange open hand with speed lines), Iron Grip (a grey fist gripping an orange cube),
    Starter Pack (an open gold chest), Small, Medium, Large and Huge Cash Pack (one stack, three, a crate, a pile),
    Lucky Boss Spin x1, x3, x10 (the round wheel with one, three and a fan of gold tickets), Instant Shield (a cyan
    shield with a gold rim), Shield Breaker (an orange hammer cracking a cyan shield).
  - Attacking products (Quick Hands, Iron Grip, Shield Breaker) carry alarm orange; defending ones (Long Lock,
    Instant Shield) carry shield cyan.
- **Wheels are round.** The Lucky Spin wheel is a round wheel built of blocks, as on the board.
- **Not icons:** the close X (a text glyph on a plate), the BOUGHT tag and OWNED label (text), the stud tile. There is
  no close, bought-cash or Shield Breaker charge icon; the bought-cash well uses the Cash icon, and a stored charge
  is shown in words on the Break shield button (the gui-designer's wording), not with a new icon.
- There is no boss index in version 1, so no index icon and no index pictures.
- Boss pictures are renders of the real boss, not icons.
- Sizes: 36 px on counters, 28 px inside buttons, 64 px on shop cards. Judged pasted onto a HUD screenshot over the
  Ice Blocks ground, not on a board.

### Motion
| Thing | Rule |
|---|---|
| Panel opens | 0.18 s, from 0.85 scale and 12 px low, Back Out |
| Panel closes | 0.12 s, to 0.9 scale, Quad In |
| Button | As in the state table |
| A number rises | Counts up in 0.4 s, one pop to 1.12 at the start |
| A reward arrives | Its icon flies to its counter in 0.35 s, Quad In; the counter pops when it lands |
| A banner | Drops in from the top in 0.15 s, shakes 4 px once, leaves after its event ends |
| Attention pulse | 1.0 to 1.06 and back, 0.8 s, Sine. One pulsing thing on screen at a time |
| Squash and stretch | Never past 1.4 (the big huss only; 1.25 elsewhere) or under 0.85 |

Things snap and pop; nothing fades slowly, drifts or glows. The only loops on the HUD are the timing ring and one
attention pulse.

### Scaling
- Everything is built in Scale inside one full-screen container, with a `UIScale`:
  `min(width / 874, height / 402)`, times 0.75 on mouse-and-keyboard screens. That gives about 1.0 on a phone, 1.35
  on a tablet and 1.65 on a 1080p desktop.
- Touch targets never under 44 px on screen. The Huss button never under 96 px.
- Keep clear of Roblox's top bar (read `GuiService.TopbarInset`), the thumbstick (bottom left) and the jump button
  (bottom right). The Huss button sits beside the jump button, not over it, within reach of the right thumb.
- The stud tile follows the scale and stays inside 12 to 32 px on screen.
- Outline, lip and shadow sizes scale with the UI and are rounded to whole pixels.
- Prompts show the glyph of the input in use (keyboard, gamepad, touch).

## 7. Effects and avatar animation

Everything that bursts is made of the same two shapes as the world: cubes and flat square studs. A hit throws 6 to
12 cubes, 0.4 studs across, in the colours of the thing that was hit; they fly 4 to 8 studs, fall, spin and shrink to
nothing in 0.35 to 0.5 s. A placed boss, an upgrade, a new bag tier or a rare roll throws stud confetti: flat square
plates 0.3 studs across in the tier's colour and white, up to 60 pieces, for under a second. The impact mark is a
hard-edged 8-point star in flash yellow that lasts 0.08 s, bigger on the third punch of a combo. Trails are rows of
shrinking squares. Dust is three or four grey cubes, not a puff. Rebirth is the one big moment: every cube of the
base's bosses flies up and bursts, then confetti.

Nothing is soft. Particle textures are hard-edged squares with LightEmission 0; there are no blurred sprites, no
halos, no light beams, no screen-wide flashes and no PointLight glow. The only things that glow are Neon parts
(lava, stars, boss element cubes, a spot rim waiting for a boss), held in check by the low bloom. A phone shows at
most 24 particles for a hit and 60 for a celebration. Camera shake is at most 0.3 studs for 0.15 s, and only on a
clean big huss and on beating a boss.

### Avatar animation (brief, Content: "Avatar gear" and "Avatar animations")
The avatar is the player's own Roblox avatar; the game adds the gloves and seven clips, in the same snappy style as
the bosses (section 5, "Fight animation"): quick moves into held poses, a held contact frame, no floaty easing, no
slow motion and no camera move.

**The gloves.** A pair of voxel boxing gloves on every avatar, put on at spawn, the same for everyone: built from
cubes like the bosses (no studs, the cube edge line, matte), Huss red `#E02A2A` with the yellow cuff band of the
approved Huss glove icon, each about the size of the avatar's head. They follow the hand, so they work on every body
shape; they are never sold, recoloured or removed.

**The clips**
| Clip | Look and timing |
|---|---|
| Jab x3 | Left, right, left. Each jab: the glove snaps out in about 0.05 s, holds the contact pose for one beat (the contact frame lands exactly on the punch's result, with a `Hit` marker in the clip so the huss, the burst and the star fire on it), and pulls back in about 0.1 s. The shoulders turn into each jab 10 degrees; the legs stay planted. **The rhythm follows the manager's recording**, chosen as the combo reference ("make sure the punches against bag or boss are timed against this"): about 0.21 s from the first punch to the second and 0.19 s from the second to the third, a slightly quickening triple. The schedule is final (brief, system 1): one tap launches the burst and the three jabs land at 0, 0.213 and 0.401 s after it; the clips are stretched to those times in code |
| Big third punch (the big huss) | The third jab replaced by a wider wind-up (the arm draws back past the shoulder, torso twists 25 degrees, 0.08 s) and a half-stud step in, the contact pose held a beat longer than a jab, then back to stance in about 0.2 s. The bigger impact star and cube burst of section 7 sit on its contact frame |
| Flinch | On the boss's impact frame: head and torso snap back, one small step back, back to guard in about 0.25 s. No fall |
| Carry hold | Both arms straight up, gloves flat under the boss, held for the whole carry; the body rocks with the run in step with the boss's carry rock |
| Steal lift | Over the 2 s hold (1 s with Quick Hands): reach for the boss, grip, lift it in steps that keep pace with the orange hold fill, so the boss is visibly off its spot only when the hold completes. Stretched to the hold time in code |
| Knockdown | After a lost fight, 2 s: falls back in 0.2 s with three or four grey dust cubes, lies still, gets up in the last 0.4 s |
| Stun | A thief punched by the owner, 1.5 s: standing wobble, arms down, three small white cubes circling the head; no fall |

The owner's plain punch at a thief reuses one jab. Per the animator-vfx playbook, the player's own clips play on
their own client on the server-made `Animator`, and are checked on a second client and on R15 and R6 avatars of
different sizes.

## 8. Never

- Round raised studs, hollow tubes, logos on studs, or anything that reads as a toy-brick brand.
- Toy figures: cylinder heads, claw hands, printed torso faces. The avatar is the player's own.
- Glossy or shiny plastic, reflections, metal sheen. Surfaces are matte.
- A boss with studs, or a world block without them (outside the smooth list in section 2).
- Flat dark cards, hairline strokes, pill tags, thin outlined chips, tiny wide-spaced caps, accent bars beside
  headings, see-through panels, soft glows, blurred shadows, gradients.
- Rarity shown by a strip or a dot. Prices as plain text. Icons drawn from basic shapes, or line icons, or glossy 3D
  icons.
- Default grey Roblox frames, the default font, a second font family, italic type.
- A dark zone, a dark ground, night that hides the lane, fog that hides the next gate.
- A zone colour that copies Huss red, alarm orange or shield cyan. Orange-and-ink stripes on anything that is not a
  hazard. A tier colour on a fence, a plot or a button.
- A boss, prop, name or layout that resembles a known character or another game's. No removed watermarks.
- A flame on Ember Drake's tail. A solid-Neon head or face on any boss. An aura below Legendary.
- A built boss that does not match its approved picture. One of the other 30 made before the manager has seen the
  first six.
- Boss or avatar moves that bend a mesh, use slow motion or a long hit pause, take over the camera, leave the boss
  pad, or hide or delay the timing ring. A fight or signature move on a placed or carried boss.
- A gold star on the Rebirth button or screen header (the star is the marker by the player's name). A square spin
  wheel. A red close button, red toast or red panel.
- A picture of a boss, zone or product that is not in the brief's content tables. An index or collection picture.
- Urgent offer dressing: timers, "% off", struck-out prices, flashing on a Robux button, a close button smaller than
  the rest.
- Studs drawn as geometry (one part per stud), or a boss built as one part per cube.
- Terrain water, Terrain grass, realistic textures, decals for detail.
- More than one thing pulsing, more than one pop-up, text under 14 px.

## 9. For a second skin

The manager may rebuild the game in another look to test which advertises better. The brief keeps rules by id
(`zone 1..6`, `tier 1..6`, creature `z3_t3`, `hazard 1..6`) and puts names, models, colours, icons and sounds in one
skin table. This is the art side of that table.

**Skin (swap these):**
- The `Stud` MaterialVariant and the UI stud tile (parts hold the variant by name, so replacing it re-skins every
  part; a skin with no studs swaps in a plain variant and an empty tile).
- Every colour in section 3, kept as one token table on the Roblox side and one set of styles in FigCraft.
- The font family, corner radius, outline width, lip and shadow tokens.
- Boss meshes and the boss atlas, the six bag models, hazard models, zone prop models, base piece models, the icon
  set, the skybox, the lighting and zone-shift tables.
- Effect shapes and textures (cube and stud become the new skin's shapes).
- Names: zones, creatures, bag tiers, hazards. Game page art.
- **Sounds** (the brief's skin table includes them; see `sound-direction.md` for which are the game's own, such as
  the manager's "huss").

**Structure (stays):**
- The hub (its walls, 8 plots in a U, the yard, the track and the gate), the lane, its 36-stud width, zone order and lengths, gate and boss pad positions, plot layout and spot grid,
  hazard tracks, sizes and timing.
- Each prop's footprint and collision box, and each landmark's position and height.
- Boss heights per tier, the carry and spot scale caps, the moving-group names and pivots, the body types and the
  timing of every boss and avatar move.
- HUD and screen layouts, sizes, touch areas, the timing ring and pips, motion timings.
- The job of every colour (which thing is "the Huss colour", "the bought colour"), even when the colour changes.
- All code, rules, ids and numbers.

For this to work: props and bosses are placed by id from a per-skin folder, colours are never typed into a script
or an instance outside the token table, and no layout depends on a stud being visible.

## 10. Optional suggestions (not in the spec; the manager picks)
- A small gold plus button on the cash counter that opens the shop at the cash packs. The brief has no such button.
  Pattern: `vault/playbooks/gui-designer.md`, "Entry points at the point of need" (docs). Cost: small, gui-designer.

## 11. References

| File | What | Status |
|---|---|---|
| `concepts/manager-refs/1.png` to `3.png` | Stud UI: a studded panel with smooth list rows and tier plates, a studded inventory grid, studded header and side buttons | Reference only, technique |
| `concepts/manager-refs/4.png` to `7.png`, `8.webp` to `14.webp` | Stud maps: stepped trees, stalls, crates, bushes, stud water, blue sky, soft shadows | Reference only, technique |
| `concepts/brick-brawl/board.png` and its PNGs | The round 2 board the manager picked from | Ours; superseded where section 1 says so |
| `concepts/brick-brawl/creatures.png` | The six pictured bosses, also on the boss cards of `ui-kit/02-components-buttons-panels.png` | Ours; **approved look** (manager, 2026-11-25): the built six match them, Ember Drake's tail excepted (section 5) |
| `sound-refs/huss-huss-huss-manager.mp3` (first group of three, slot 03 E; the burst voice is its trimmed version, slot 03 F) | The manager's combo rhythm: about 0.21 s then 0.19 s between husses (`sound-direction.md`) | The manager's; the reference for the jab x3 and the boss idle jabs (sections 5 and 7), the brief's numbers win |
| `style/stud-preview.png`, `stud-ui-overlay-64.png`, `stud-height-64.png` | The stud tile pinned down | Ours; script reference, confirmed by the manager at the M1 stud proof |
| `base-layout/` (`base-layout.md`, plans `01` to `04`, `base-layout.figcraft`) | The hub, the plot, every pad and its states, the steal route and timings | Ours; **approved** (manager, 2026-11-25: "perfect. base-layout looks good. all 4 pages in that document."); the plans are the spec for dimensions. Its three `view-*.png` renders are impressions only |
| `ui-kit/` | The UI kit (FigCraft, `ui-kit.figcraft`, and its PNG exports) | Ours; **approved reference** (manager, 2026-11-25); this guide describes it. Its boss portraits stay stand-ins until renders of the built models replace them |

Docs read 2026-11-25: create.roblox.com/docs/reference/engine/classes/MaterialVariant, /classes/Texture,
/classes/SurfaceAppearance, /classes/ImageLabel, /enums/Font, /datatypes/Font, and /docs/parts/materials.
Lighting property names from `vault/roblox-docs/lighting-and-atmosphere.md` (checked 2026-11-03).

## 12. Vault entries applied
- `vault/playbooks/art-director.md`: a small palette where every colour has a job; the UI kit sheet is part of the
  style guide; judge icons where they will sit.
- `vault/patterns/generated-looking-ui-tells-and-what-replaces-them.md`: the Never list and the UI rules.
- `vault/patterns/code-built-voxel-props-one-construction-rule.md` (unverified): the prop recipe.
- `vault/patterns/headless-blender-builders-and-studio-setup-scripts.md` and `vault/playbooks/modeler-3d.md`: the
  boss pipeline. The shared boss atlas departs from "one mesh per colour role"; the fallback is that entry as written.
- `vault/playbooks/gui-designer.md`: text floor and outlines, phone scaling rules, safe areas, offer wording.

## 13. Unverified, and who checks it

| What | Who | How |
|---|---|---|
| The stud itself matches the manager's screenshots, in the world and in the UI | manager | The M1 stud proof (section 2), beside references 8, 13, 14, 1 and 2 |
| Which way the normal map must face for the world stud to read as in the references | builder | Both ways at the stud proof |
| `BasePart.Color` tints the `Stud` MaterialVariant's colour map (the docs read do not say) | builder | One part, three colours, in Studio. If not: route B |
| Stud tiles line up across neighbouring parts and on rotated parts | builder | A wall of mixed part sizes on the grid |
| The 1-stud tile at distance on the lane: shimmer or noise on a phone | builder, performance-optimizer | Phone-size screenshot down the lane. If noisy: a second variant at 2 studs a tile for ground only |
| Normal-map stud depth reads under ShadowMap lighting and at low quality levels | builder, lighting-specialist | Quality 1, 5 and 10 screenshots. If flat: bake a faint dark L into the colour map |
| Every lighting, atmosphere and post-effect number, and the zone tints | lighting-specialist | Tuned in Studio against references 8 and 12 to 14; the digest warns no number is docs-verified |
| `LightingStyle` and `PrioritizeLightingQuality` exist on the manager's Studio build | lighting-specialist | Read the property panel |
| Phone cost of Bloom, DepthOfField and the zone tweens | performance-optimizer | Undocumented; measure on a real low-end phone |
| Space Baseplate at `ClockTime` 20 | art-director, from a phone screenshot | Readability test in section 4; default is daytime |
| `TileSize` in Offset follows `UIScale`; tiled images under a 4 px `UICorner` clip cleanly | gui-designer | One studded button at three scales |
| The UI tile at 16 px on a real phone, and whether the 30% dark L is too busy under text | gui-designer, then the manager | Kit sheet at phone size; `style/stud-preview.png` is the starting point |
| Montserrat Black's weight name (`Enum.FontWeight.Heavy`) and that it renders as on the board | gui-designer | Set it in Studio; the docs page read did not list the weights |
| Boss atlas: cell edges stay crisp and do not bleed at distance | modeler-3d | One Common boss both ways (atlas, per-role colour); pick one |
| Triangle budgets with a full server on a phone: 136 placed bosses (8 x 17 spots) plus 24 on boss pads, at the pictures' cube density (about 20 to 34 cubes tall) | modeler-3d, performance-optimizer | Count after the first six bosses; measure with 136 placed. If the pictures' density does not fit, the picture wins and the budget is raised to what measures acceptable |
| The first six built bosses match their approved pictures (Ember Drake with its rock-club tail); Ember Drake's aura and Star Golem's gold stars as its aura | manager, from renders by the modeler-3d | Renders beside `creatures.png`, same angle; the other 30 wait for the yes |
| Each body type's groups and pivots animate without re-pivoting, and one set of offsets fits a Common and a Mythic | modeler-3d, animator-vfx | One test boss per body type, smallest and largest tier, guard and signature impact renders |
| Rigid-group moves read as fighting on a phone at the fight camera: the scorpion's sting then pincer, every signature's impact frame | animator-vfx, then the manager | Studio play-mode checks and a phone-size capture; the manager's playtest for feel |
| No fight move hides or delays the ring: a new result cuts a running reaction, nothing draws over the Huss button | animator-vfx | Play mode with Misses and big huss back to back at Speed 10 |
| Frame time of 136 placed bosses on the half idle (15 updates a second, random phase) and of fight moves within 150 studs | performance-optimizer | Low-end phone, full server; tune the distance and update rate |
| Avatar clips on R15 and R6 avatars of different sizes, gloves following every hand, clips replicated to a second client | animator-vfx | Lab rigs and a two-client test in Studio |
| The jab x3 rhythm (about 0.21 s then 0.19 s, as recorded) against the brief's final ring schedule; contact frames on the huss | manager | Playtest; the brief's numbers win |
| Spot, cash pad, lock pad, crate and boss pad sizes and the plot layout for 17 spots | builder, game-designer | Greybox; the brief's counts and run times win |
| The hub's run and carry times (bag pad to the gate 139 to 176 studs, run to zone 1's fixed pad 11.4 to 13.7 s, carry home 15.2 to 18.3 s) and the sight lines over the 4-stud front wall from all 8 bag pads to zone 1's fixed pad and the windmill | builder | Greybox the hub first, measure at the default camera; every figure in `base-layout.md` is on paper |
| World sign text sizes on a phone (name board, bag sign, lock board, spots-full sign, timer plate, gate sign) | builder, gui-designer | Phone-size captures at the default camera and the distances in `base-layout.md` section 4 |
| Part counts: about 210 a plot, about 1,700 for 8 plots plus about 60 for the walls, track, gate and scenery; all 8 plots streamed in | performance-optimizer | Measure on a weak phone; estimates only |
| Whether players read the 3-stud fence plus invisible blocker as closed; whether the yard feels too big and empty; bag first or gate first for a new player | manager | Playtest |
| Whether a steal from the corner neighbour (plots 2 and 3, 6 and 7; doors 41 apart) is too easy; every steal is catchable from the yard, from the gate only deep-spot ones | manager | Playtest; the timing tables are on paper (`base-layout.md` section 5) |
| The zone corridor walls and centre-line colours per zone (section 4, "The lane") | art-director, then the manager | Look review at M3 |
| World buttons on the lock board tappable at 44 px within 10 studs; the Settings tile clears the thumbstick | gui-designer | Phone-size check in the emulator |
| Magma Hydra read as cracks on three matte heads, with its outer heads as fists | game-designer | Confirm or reword the description |
| Hazard looks against the brief's "always leaves a way through" and the 0.6 s warning | builder, game-designer | Play-mode check of each hazard |
| Roblox's upload size limit for the 256 px maps and image moderation of the tile | builder | On upload |
| Board 04's icons judged in place on a real play screenshot (the approved set, made against generated backdrops) | art-director, gui-designer | Paste at 36 and 28 px onto phone screenshots of the built game; any icon remade uses board 04 as its reference |
| Motion, the ring's speed, the feel of three pips, boss and avatar moves, any sound | manager | Playtest; stills can't show it |
| The other 30 designs against the originality rule and the six pictures' design language | art-director | Review each sheet before a builder script is written |
