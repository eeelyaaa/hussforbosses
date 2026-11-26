# Huss for Bosses: look directions (three in round 1, two more in round 2)

Pitch step 2, first mockups. 2026-11-25, art-director. Nothing is built in Roblox. The manager picks; the pick becomes
`style-guide.md`.

What is the same in all three (it comes from the brief): a punching bag at your base, a row of bases at the start of one
long straight lane, six zones in order, bosses that are the creatures, boss spots at base, a base lock.

What is a mockup and not a decision: every number on the HUD and menu, the creature names, the six rarity tier names
(Common, Uncommon, Rare, Epic, Legendary, Mythic) and which tier sits in which zone. Those are the game-designer's.
The pictures are generated concepts: they show the look, not the final models or map.

Design file, all five boards: `concepts.figcraft` (opened in the FigCraft app on 2026-11-25). Each board is also
exported as `<direction>/board.png`. Rebuild: `build_concepts.py` with `parts.json`.

Type on the boards is a stand-in from the fonts FigCraft has on this PC. The Roblox font is chosen with the style guide.

**Round 2, same day:** the manager asked for "one in roblox stud style, with like voxel type bosses" and "one more look
direction". Those are directions 4 and 5 below, boards 4 and 5 in the same `concepts.figcraft`. Boards 1 to 3 were not
changed. The two new HUDs also show what the manager decided after round 1: the timing ring around the punch button and
three pips for punches that come in threes. Directions 1 to 3 would get the same ring; their boards predate it.

---

## 1. Gym Zoo (`gym-zoo/`)

Sunny, chunky, sporty. A toy-box backyard gym in bright daylight: glossy vinyl-toy shapes, thick rounded forms, grass,
wood fences and a blue sky. The bosses are buff cartoon animals. It reads at a glance on a small screen, it is the
closest of the three to what the top games in this genre look like, and "punch the bag, fight the gym animals" explains
itself without a word.

**Palette**
| Hex | Job |
|---|---|
| `#3EC1F3` | Sky blue: panels, the world's base colour |
| `#FF3B3B` | Punch red: the Huss button, Power |
| `#39B54A` | Go green: cash, upgrade, accept |
| `#FFC928` | Gold: shop, premium, the impact burst |
| `#3E8BFF` | Shield blue: the base lock |
| `#FFFFFF` | White: text and wells |
| `#1B1F3B` | Navy ink: every outline and hard shadow |

**Zones, in order**
1. Backyard Gym: grass, tyres, dumbbells, wooden frames.
2. Boardwalk Beach: sand, palms, striped umbrellas, a pier hut.
3. Jungle Dojo: vines, a waterfall, a wooden dojo.
4. Frost Peak: snow, pines, ice.
5. Magma Forge: lava rivers, anvils, chains.
6. Sky Arena: a golden arena on clouds, laurels.

**Creature rule:** a real animal built like a bodybuilder (huge fists and chest, tiny legs), two or three flat colours,
wearing exactly one piece of fight gear that names it (gloves, sweatband, headband, weight belt, knuckle-dusters,
champion belt). The animal comes from its zone. Tier shows in size and in the gear's material.
Line-up shown: Jab Rooster, Clamp Champ (crab), Sensei Silverback, Blizzard Bear, Magma Bull, Golden Mane (lion).

**UI shape rule:** rounded plates with a thick navy outline and a darker lip under anything pressable; italic heavy
type; the yellow impact star is the one motif (behind the punch button and behind a featured boss).

**Downstream cost:** medium. Organic animal bodies need real meshes: about 36 generated or modelled creatures, each
cleaned and reduced in Blender. The muscle shapes are what make them, so they cannot be built from parts. One shared
rig would not fit a crab and a lion; expect three or four body types to animate. The world is cheap: grass, wood and
simple props, daylight lighting. Higgsfield, rough: 36 creatures at 25 to 31 credits each for text-to-3D is about
900 to 1,100 credits (the vault's unverified estimate; check before spending), plus concept sheets for the other
30 creatures (5 sheets, about 10) and icons and page art (about 20).

---

## 2. Neon Knockout (`neon-knockout/`)

Electric, loud, night. A rain-wet night city in four neon colours on dark indigo: flat low-poly blocks with glowing
trim and reflections. The bosses are boxy robots, each built from one everyday machine with a screen for a face. It
looks the least like the other games in the genre, and the robots are funny because you know the machine.

**Palette**
| Hex | Job |
|---|---|
| `#1B1147` | Night indigo: the world and panel base |
| `#FF2E9A` | Hot magenta: the Huss button, panel trim |
| `#23E6F2` | Cyan: Power, the base lock |
| `#B6FF3C` | Lime: cash, upgrade, accept |
| `#FFB020` | Amber: shop, premium |
| `#FFFFFF` | White: text |
| `#07051A` | Black indigo: every outline and hard shadow |

**Zones, in order**
1. Arcade Alley: arcade cabinets, tokens, claw games.
2. Night Market: striped stalls, lanterns, snacks.
3. Scrap Yard: junk stacks, a crane, gears.
4. Subway Line: tracks, a platform, a train.
5. Laser Foundry: robot arms, sparks, pipes.
6. The Mainframe: a server tower with a halo ring.

**Creature rule:** a box robot that is clearly one machine you know (arcade cabinet, vending machine, washing machine,
traffic light, furnace, server rack), dark body, one neon trim colour, a screen face with two eyes and a mouth, block
fists. The machine comes from its zone. Tier shows in size and trim colour.
Line-up shown: Coin-Op, Fizz Fridge, Spin Cycle, Red Light, Weld King, Halo Server.

**UI shape rule:** cut corners (the hexagon pads' angle) on every plate and button, upright condensed type, panels in
saturated indigo with a magenta trim line; cards are filled with neon, never left dark.

**Downstream cost:** lowest for models, highest for lighting and performance care. Robots are boxes: a builder can make
most of them from Roblox parts with Neon material and a decal face, and all 36 can share one blocky rig and one
animation set. Higgsfield, rough: little or no 3D (0 to 150 credits for a few hero bosses), screen-face and icon art
about 30. Risks to weigh: a dark world is harder to read on a phone in daylight; many glowing parts, wet reflections
and bloom cost frames on weak phones and need the lighting-specialist and performance-optimizer early; and the audience
for this genre skews young and bright. One thing to redraw: the arcade robot's screen shows a pixel alien that is too
close to a famous one; the final face would be its own glyph.

---

## 3. Clay Kaiju (`clay-kaiju/`)

Handmade, warm, goofy. A stop-motion clay diorama in storybook colours: matte, soft, thumb-pressed. The bosses are round
ball-bodied monsters with huge mouths, each made of its zone's element. It is the most charming and the most
collectable-looking of the three, and the zones are the most different from each other.

**Palette**
| Hex | Job |
|---|---|
| `#FFF3DC` | Cream: panels, rims, the paper of the world |
| `#E8663C` | Terracotta: the Huss button |
| `#2FA8A0` | Teal: Power |
| `#F5B83D` | Honey: cash |
| `#7DB96A` | Moss: upgrade, accept, the base lock |
| `#D6457A` | Berry: shop, premium |
| `#4A2C4F` | Plum ink: every outline and hard shadow |

**Zones, in order**
1. Mushroom Meadow: giant red mushrooms, daisies.
2. Honey Hive: honeycomb, honey falls, bees.
3. Coral Cove: teal water, pink coral.
4. Crystal Cavern: blue and violet crystals.
5. Thunder Peaks: storm clouds, lightning.
6. Star Void: a galaxy swirl, a star altar.

**Creature rule:** one ball for a body, a mouth half its width, stubby limbs, one or two big eyes, and one element from
its zone growing out of it (a cap, honeycomb, coral, crystals, lightning, stars). No clothes, no gear. Tier shows in
size and in how much of the element it carries.
Line-up shown: Capper, Honeygob, Coralump, Shardle, Thunderpuff, Nebulug.

**UI shape rule:** soft pill and blob shapes in cream with a plum outline and a clay-coloured lip; heavy upright type;
icons are little clay tokens with a cream rim.

**Downstream cost:** medium for creatures, highest for the world. The shared ball body is a real saving: one base mesh,
one rig and one animation set, with the element as an add-on, so 36 creatures is closer to 6 body variants plus
36 toppers. But the clay look depends on texture and soft light, which Roblox materials do not give for free: props and
terrain need custom meshes and textures to avoid looking like plain plastic, and the look in the pictures will be
softer than the build. Higgsfield, rough: 6 base bodies and 36 toppers at text-to-3D prices is about 400 to 600 credits,
plus zone props (about 150 to 300) and icons and page art (about 20).

---

## 4. Brick Brawl (`brick-brawl/`)

Blocky, bright, classic. The manager's request: a classic Roblox stud world, with voxel bosses. Everything is studded
bricks and plates in primary colours on a green baseplate, with a blocky avatar. The bosses are creatures built from
visible cubes, so they read as a different kind of thing from the smooth brick world they stand in. It looks native to
Roblox, it is the cheapest of the five to build, and the cube bosses get bigger and more detailed in an obvious way.

**Palette**
| Hex | Job |
|---|---|
| `#E02A2A` | Brick red: the Huss button, Power |
| `#1F6FD6` | Brick blue: the base lock, frames |
| `#FFD21F` | Brick yellow: shop, premium, the timing ring |
| `#2FB341` | Brick green: cash, upgrade, the baseplate |
| `#B4BBC6` | Stone grey: panels, the road, pedestals |
| `#FFFFFF` | White: text and wells |
| `#101820` | Black: every outline and hard shadow |

**Zones, in order**
1. Brick Meadow: green baseplate, block trees, brick flowers.
2. Sand Blocks: a stepped pyramid, cactus, sand bricks.
3. Pirate Plates: water bricks, a brick ship, palms.
4. Ice Blocks: snow bricks, clear ice crystals.
5. Lava Bricks: a brick volcano, glowing lava.
6. Space Baseplate: dark plates, a rocket, stars.

**Creature rule:** a creature built only from cubes of one size, in two or three colours plus one accent, with block
fists and a flat pixel face (two eyes, a mouth with square teeth). No smooth parts and no studs on a boss: studs are the
world, cubes are the bosses. The creature comes from its zone. Tier shows in size, in cube count, and from Legendary up
in glowing cubes.
Line-up shown: Chomp Frog, Snap Scorpion, Bit Shark, Frost Byte (yeti), Ember Drake, Star Golem.

**UI shape rule:** square brick plates with a row of studs along the top edge, a darker lip under anything pressable,
grey panels like a baseplate, heavy upright type; icons are flat pixel-block stickers with a white rim.

**Downstream cost:** lowest of the five. The world is Roblox parts with a stud texture: a builder makes it in Studio with
no modelling, and it is light on phones if studs are a texture and not geometry. Voxel bosses do not need Higgsfield 3D:
they can be built from a cube grid by a headless Blender script (the team has that route) and merged into one mesh each,
so 36 bosses is mostly design time. Higgsfield, rough: 0 to 100 credits for 3D (only if a hero boss is generated and
then voxelised), concept sheets for the other 30 creatures (5 sheets, about 10), icons and page art (about 20). Animation
is cheap: cube creatures can bob, squash and swing block fists without a skinned rig. Things to weigh: the generated
pictures lean toward a well-known toy brand (the yellow cylinder head most of all), so the build must use the real
Roblox avatar and Roblox's own stud look, not the pictures' minifigure; many Roblox games already use the classic stud
look, so it stands out less on the shelf than directions 1 or 5; a boss must never be one part per cube (part count);
and how studs are best made today (texture or material variant) is for the builder to check in the docs. One thing to
redraw: Ember Drake's flame-tipped tail is too close to a famous dragon; the final design drops it.

---

## 5. Snack Attack (`snack-attack/`)

Flat, loud, tasty. The art-director's pick for the fifth. A flat cartoon snack world drawn like a sticker sheet: thick
chocolate outlines, flat colour with one shadow tone, pink, mustard, red, mint and cream. The bosses are living snacks
with angry faces and big gloved fists. Why this one: food is the theme young players name and share fastest (every boss
is a thing they already know and find funny), it is the only direction of the five that is flat and outlined instead of
shaded 3D, so it looks like nothing else in the set or next to it on the shelf, and "collect them all" is easy to want
when the collection is a menu.

**Palette**
| Hex | Job |
|---|---|
| `#FFF6E0` | Cream: the sky, wells, text |
| `#F23B45` | Ketchup red: the Huss button, Power |
| `#FFC42E` | Mustard: shop, premium, the timing ring |
| `#6FD8A0` | Mint: cash, upgrade, accept |
| `#FF6FA5` | Bubblegum: panels, the road's checks |
| `#5AB4F0` | Blueberry: the base lock |
| `#4A1F1A` | Chocolate ink: every outline and hard shadow |

**Zones, in order**
1. Breakfast Diner: giant pancakes, fried eggs, booths.
2. Burger Drive-In: giant fries, a little car.
3. Pizza Plaza: slice roofs, umbrellas.
4. Sushi Dock: a pier, giant rolls, chopsticks.
5. Candy Canyon: lollipops, gumdrops, a syrup fall.
6. Cake Castle: a three-tier cake with candles.

**Creature rule:** one snack you can name at a glance, its own shape kept whole, with an angry face on its front, thick
arms, cream gloved fists and small shoes, and at most one accessory (a headband, a bow tie, candles for a crown). The
snack comes from its zone. Tier shows in size and in how dressed-up the snack is (plain, then toppings, then a crown).
Line-up shown: Flapjack Jack, Sir Patty, Pepperoni Tony, Maki Mauler, Jawbreaker Joe, King Cake.

**UI shape rule:** flat round sticker plates with a thick chocolate outline and a hard chocolate drop under anything
pressable; no gradients and no sheen; heavy upright type in cream; icons are flat stickers with a cream rim.

**Downstream cost:** medium for creatures, high for matching the pictures. The snacks are simple shapes with one shared
set of arms, gloves and shoes, so 36 creatures is 36 bodies plus one limb kit and one rig, cheaper than Gym Zoo's
animals. Higgsfield, rough: 36 bodies at text-to-3D prices is about 600 to 1,000 credits (the vault's unverified
estimate), fewer if the simple ones (pancakes, sushi roll, jawbreaker, cake) are modelled in Blender; concept sheets
about 10; icons and page art about 20. The risk is the look itself: the pictures are flat 2D with ink outlines, and
Roblox draws lit 3D. Outlines need an extra shell on every mesh (Roblox's Highlight is capped and costs frames), and
flat colour needs careful lighting. Built without that work, this direction turns into glossy 3D food, which is close
to Gym Zoo's rendering with a different theme. The UI, icons and page art keep the flat look at no extra cost. Also to
weigh: food worlds are a familiar theme on the platform, and the gloved fists and shoes are a long-used cartoon
convention, so each snack needs its own face and silhouette to stay the team's own.

---

## Files

Per direction, in `pitches/huss-for-bosses/concepts/<direction>/`:

| File | What | Made in |
|---|---|---|
| `key-art.png` | Key art | Higgsfield |
| `scene.png` | In-game scene: base, boss spots, bag, lane into zone 1 | Higgsfield |
| `map.png` | The lane, bases and six zones, labelled | FigCraft over `map-raw.png` |
| `map-raw.png` | The map picture with no lettering | Higgsfield |
| `creatures.png` | Six bosses, one per zone, named with tier and zone | FigCraft over `creatures-raw.png` |
| `creatures-raw.png` | The line-up on a transparent ground | Higgsfield |
| `hud-phone.png` | HUD at 874 x 402 (exported at 2x) over the scene | FigCraft |
| `menu.png` | Boss upgrade panel, same phone | FigCraft |
| `board.png` | The whole board: palette, HUD, menu, buttons, key art, map, creatures | FigCraft |
| `icons-sheet.png` | Nine UI icons in the direction's style | Higgsfield |
| `parts/` | Icons and creatures cut from the sheets (crop only) | ffmpeg |

Shared: `concepts.figcraft`, `build_concepts.py`, `parts.json`, `higgsfield-log.md`, this file.

## What the UI mockups were checked against
- The generated-looking tells: no dark same-coloured cards, no hairline strokes, no pill tags, no soft glows, no
  see-through panels. The boss card is filled with its rarity colour and names the rarity in words; the price sits on
  the button with the cash icon; one hero per screen (the punch button on the HUD, the upgrade button in the menu).
- Icons are generated, in one style per direction, none drawn from shapes. Directions 1 and 2 use flat sticker icons
  with a rim, not glossy 3D ones (the look the manager turned down twice in deja-kill). Direction 3's are matte clay
  tokens, which is that direction's whole point but is closer to a 3D icon: judge it on the HUD picture.
- Phone: text is 14 px or larger at 874 x 402, touch targets are 44 px or larger, and the HUD keeps clear of Roblox's
  top bar buttons, thumbstick and jump button (drawn as grey reference shapes).
- The boss in each menu is one from that direction's own line-up.
- Not checked: motion and sound (stills only), a real phone, and the worst-background text test in a built world.
- Round 2: the same checks were run on boards 4 and 5. The timing ring and the three punch pips are drawn, not animated:
  how fast the ring closes and whether three pips read as "huss huss huss" are questions for the manager's playtest.

## Known rough edges
- The menu shows a Common boss in directions 1 and 3 and a Rare in direction 2, because only some creatures could be
  cut from the sheet with a plain rectangle. It is not a design difference.
- Some long zone names wrap to two lines under the creature labels.
- The clay map draws the bases as a column on the left, the other two as a row. The build would follow the brief.
- Maps and scenes are concept pictures: zone widths, gate count and base count are not to scale.
- Round 2: both new menus show the Common zone-1 boss, as asked. Both new maps draw the bases as a row.
- Brick Brawl: the avatar in the pictures is a toy minifigure, not a Roblox avatar; the map's bases have small houses
  the brief does not ask for; the creature sheet came with a coloured glow behind each boss, which was cut by raising
  the transparency threshold (nothing else in the picture was changed).
- Snack Attack: on the HUD the punch button sits over the bag and part of the third boss, and the punch pips are hard
  to see against the white fence; the map title is cream on cream and relies on its outline.
- Boards 4 and 5 use Arial Black and Segoe UI Black as stand-in type.

## Recommendation

Updated after round 2. Ranked, all five:

1. **Gym Zoo (1).** Still the one that says the game in one picture: gloves, a red bag, a road, a buff rooster. The
   name, the action and the bosses are the same joke. Bright and readable on a phone, a cheap world, and the cost sits
   in the creatures, which is where the manager wants the value.
2. **Brick Brawl (4).** A close second, and first on cost and speed. The world is parts and a stud texture, the voxel
   bosses can be scripted in Blender with little or no Higgsfield 3D, and it looks at home on Roblox. It is the fastest
   route to a game the manager can playtest. It ranks below Gym Zoo because cube bosses carry less character than buff
   animals, the look is shared with many Roblox games, and the build has to stay clear of the toy-brand look the
   pictures drift toward.
3. **Snack Attack (5).** The strongest characters and the best thumbnails of the five, and the theme young players
   share fastest. It is third because the flat inked look is the hardest of all five to reproduce in a Roblox world;
   without that work it becomes Gym Zoo's rendering with food in it.
4. **Clay Kaiju (3).** The most charming, with the cheapest creature pipeline after Brick Brawl (one ball body), but
   the clay world is hard to match in Roblox and the bosses say "cute" more than "fight me".
5. **Neon Knockout (2).** Cheap to model, but dark worlds read worst on phones outdoors, glow and reflections cost
   frames, and the audience skews young and bright.

The manager's plan to build once and re-skin the game to see which look advertises best changes how to use this list:
the first build should be the cheapest to make and to re-skin. That is Brick Brawl first (days of world building, no
creature generation), then Gym Zoo or Snack Attack as the second skin, because both are mostly a creature swap on the
same lane, bases and UI layout. If only one look is built, Gym Zoo.

Mixes that would work, the manager's call: Snack Attack's snacks as the bosses in Gym Zoo's world and rendering (the
food theme with none of the flat-look risk); or Brick Brawl's world with Gym Zoo's creature rule turned into voxels
(a voxel animal plus one piece of fight gear).
