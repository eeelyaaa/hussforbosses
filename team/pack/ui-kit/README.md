# Huss for Bosses: UI kit

Built 2026-11-25 by the gui-designer (pitch step 3). Status: approved by the manager (foundations, icons, screens); a final small pass on 2026-11-25 added Perfect Auto Punch, the current rebirth text, the lock and steal-prompt states and the BOUGHT-on-alert (see the Final pass section).

- Design file: `pitches/huss-for-bosses/ui-kit.figcraft` (FigCraft; five pages). Open it in the FigCraft app.
- Exports: the PNGs in this folder. Boards and phone screens are exported at 2x, desktop screens at 1x (1920 x 1080).
- Built from: `brief.md` and `style-guide.md` section 6 as they stood at the final pass (19 shop products, bought bosses stealable and
  kept at their levels through rebirth, one timed tap launching a three-punch burst), and `style/stud-ui-overlay-64.png`.
- Rebuild: `bash ui-kit/src/rebuild.sh` (writes the file again from `src/build_kit.py`, `src/kitlib.py`,
  `src/screens.py` and re-exports every PNG). The stud tile is read from `style/` at build time, so a changed tile
  only needs a rebuild. **Rebuilding replaces the file: edits made by hand in the FigCraft app are lost.**
- Numbers on the screens are the brief's draft numbers. Nothing here has been built or seen in Roblox.

## Boards

| File | What it is |
|---|---|
| `01-foundations.png` | Palette with the job of each colour, tier colours, fight-difficulty text colours, the type scale at phone and desktop size, the stud tile on a panel at 16 px (phone) and 26 px (desktop) with a 32 px close-up, spacing and corner rules |
| `02-components-buttons-panels.png` | Buttons in every state for each colour job (default, hover, pressed, disabled, locked by progress, greyed with a reason), price buttons (cash, Robux, cash pack, Break shield), close, key glyphs, the Auto Punch switch, panel with blue and gold header, wells, tier chips x6, the BOUGHT tag, counter plates, reward display, level pips, boss cards x6, world name tags |
| `03-components-hud.png` | The Huss button in seven states (idle, closing, Perfect, Good, Miss, disabled, plain punch), the three pips (0, 1, 2, 3, clean combo), zone strip, rebirth bar, health bar, shield plate and lock button (up, cooldown, ready), Break shield and its three greyed reasons, fight overlay, hearts, difficulty words, steal alert (and its BOUGHT-tag variant), shield-broken alert, thief strip, carry indicator, hazard warning, boss-beaten banner, prompts (Place, Pick Up, Grab, Steal hold, and the greyed "Can't be stolen" Steal prompt with a padlock), toasts |
| `04-icons.png` | Every icon at 60, 36 and 28 px on white, on ink and on the Ice Blocks blue (the icon check): stats, HUD and actions, status, six zone badges, 19 shop products (Perfect Auto Punch is the 19th) |
| `05-shop-full-list.png` | The whole scrolling shop list at phone scale (for an Auto Punch owner), so all 19 product cards can be read |

## Screens

Each exists as `phone-<name>.png` (874 x 402, exported 1748 x 804) and `desktop-<name>.png` (1920 x 1080).

| File name | Brief screen | Shows |
|---|---|---|
| `hud-base` | 1 HUD | At base on the bag: Power, cash, zone strip, shield plate, Shop, Rebirth with its bar, the Huss button with the ring closing and one pip, the lock button (cyan, as the shield is up and counting; grey is cooldown only) |
| `hud-fight` | 2 Fight overlay | Boss name, tier chip, band word, health bar in the tier colour, three hearts, Run top left; Shop and Rebirth are hidden in a fight |
| `hud-boss-beaten` | (none: see questions) | A non-blocking banner at the moment a boss is beaten |
| `hud-carry-hazard` | 1 HUD, 12 | Carrying past the Rolling Log: carry indicator, hazard warning, Huss disabled, shield on cooldown |
| `hud-place-sell` | 1 HUD, 12 | Carrying inside your base: the Place prompt with the first-session arrow, the Sell button, the lock button cyan (the plate shows the shield up) |
| `alert-steal-owner` | 10 | "Your Chomp Frog is being stolen!" with the arrow chip; Huss becomes a plain PUNCH |
| `alert-steal-thief` | 10 | "Get it home!" in cash green, and what is being carried |
| `alert-shield-broken` | 10 | "[name] broke your shield!" with the arrow home; shield plate on cooldown |
| `prompt-break-shield` | 10 | The gold "Break shield R$ 39" button on another player's shield (greyed reasons are on board 03) |
| `prompt-steal-hold` | 12 | The Steal hold prompt and its info line, the one place Quick Hands is offered |
| `boss-panel` | 3 Boss panel | Card on the tier colour, zone, tier, level pips, earns now and after, Upgrade with its price, Pick Up |
| `bag-panel` | 4 Bag panel | Punch Strength, Punch Speed, Auto Punch (drawn owned: its switch on) and the Perfect Auto Punch upgrade row, R$ 399. Without Auto Punch the panel has three rows and Auto Punch shows its Buy button, no Perfect row |
| `shop` | 5 Shop | The top of the list as the player sees it, for an Auto Punch owner (Auto Punch OWNED, Perfect Auto Punch R$ 399 beside it); the whole list is `05-shop-full-list.png` |
| `starter-pack` | 9 Starter Pack offer | $5,000 on green, Headbutt Ram on Epic purple, one gold Buy button, white close |
| `lucky-spin` | 6 Lucky Spin | Zone picker, six outcomes with names, tier and odds (40, 28, 17, 10, 4, 1%), tickets, Spin, Buy tickets |
| `lucky-spin-result` | 6 Lucky Spin | The reveal: boss card, tier, BOUGHT tag, where it went |
| `rebirth` | 7 Rebirth | Requirement bar; RESETS, YOU KEEP (passes, spin tickets, bought bosses at their levels, Shield Breaker charges, bought cash), YOU GET with the player's own numbers, all in the brief's system 12 words; Rebirth button with the Rebirth arrows |
| `rebirth-confirm` | 7, 11 | The second press: what is kept, in short; orange confirm with the Rebirth arrows |
| `offline-earnings` | 8 While you were away | Time away, amount, Collect |
| `confirm-sell` | 11 Confirm | Sell |
| `confirm-swap-bought` | 11 Confirm | Swap, where the placed boss was bought (it says so; orange confirm) |
| `settings` | 13 Settings | Music and effects sliders |

Toasts (screen 12: "Spots full", "Not enough cash", purchase done) are on board 03 only, not on a screen.

## Component to Roblox instance, where it is not obvious

| Piece | Build it as |
|---|---|
| Stud surface (panel, header, button, counter plate) | A `Frame` in the job colour, and over it an `ImageLabel` with the stud tile: `ScaleType = Tile`, `TileSize = UDim2.fromOffset(16, 16)`, `BackgroundTransparency = 1`. Colour stays on the frame so a recolour is one property. Whether `TileSize` in Offset follows `UIScale` is unverified (below) |
| Ink outline | `UIStroke`, 3 px, on the frame (2 px on chips, tags, wells; 4 px on the Huss button). `UIStroke` thickness is in pixels and does not follow `UIScale` by itself: set it from the scale and round to whole pixels |
| Corner | `UICorner` 4 px. Whether a tiled image clips cleanly under it is unverified |
| Lip under a button | A second frame behind the face, fill x 0.72, 5 px taller. Pressed: move the face down 4 px, do not resize it |
| Top line on a button | A 2 px frame, fill lightened 25% |
| Hard shadow | A frame in ink at 35%, offset 5 px down, behind the panel. Not a blurred image |
| Text | `TextLabel`, Montserrat (`rbxasset://fonts/families/Montserrat.json`), weight Black or Bold, with a `UIStroke` (2 px phone, 3 px desktop) for the outline and a second label 2 px lower in ink for the hard shadow. No text is baked into an image |
| Panels | Native frames. No 9-slice image is needed: every edge is a `UIStroke` and every corner a `UICorner`. A 9-slice would only be needed if the stroke fails on a phone |
| Huss button | A round `ImageButton` (`UICorner` at 50%), the stud tile clipped to the circle (check: a tiled image under a round corner may need a `CanvasGroup`, which costs memory) |
| Timing ring, hit band | Two `UIStroke`s on round frames, or one ring image scaled; the playbook's gotcha list says to draw paired rings as strokes from one edge |
| Impact star, cube burst | One small image each, or particles in a `ViewportFrame`-free layer; the animator-vfx decides |
| Tier chip, BOUGHT tag | `Frame` + `UIStroke` + `TextLabel`, `AutomaticSize = X` with 8 px padding |
| Level pips, combo pips | Frames in a `UIListLayout` |
| Boss portrait | A render of the built model (an image per boss, or a `ViewportFrame`). Never art for a boss that is not built |
| Shop list | A `ScrollingFrame` with a `UIGridLayout` (three columns) per band |
| Prompts | `BillboardGui` on the object; the glyph plate shows the key, the gamepad glyph, or on touch the action's icon |
| Scale | One `UIScale` on the full-screen container: `min(width / 874, height / 402)`, x 0.75 on mouse-and-keyboard. Lay out in Scale and layout objects, never one UI per device |

Touch and safe areas, as drawn: nothing sits under Roblox's top bar buttons (top left), the thumbstick (bottom left)
or the jump button (bottom right); movement is the left thumb, the Huss button the right thumb, 22 px left of the
jump button. Every pressable thing is 44 px or taller (the close button is 36 px inside a 44 px touch area).

## Stand-ins

- **Boss portraits.** Chomp Frog, Snap Scorpion, Bit Shark, Frost Byte and Star Golem are crops of the round 2 mock
  line-up (`concepts/brick-brawl/creatures-raw.png`; cut files in `src/standins/`). Final portraits are renders of
  the built models. Where no mock exists (Bop Bunny, Bumble Brute, Headbutt Ram, Timber Bear, Bloom Stag) or the
  mock breaks the brief (Ember Drake's flame tail) the well reads "MODEL RENDER" and shows no picture.
- **Backdrops.** `src/scene-base.png`, `scene-fight.png`, `scene-carry.png` are generated pictures behind the HUD,
  not the game. Known misses: the Rolling Log is round (the style guide wants stepped boxes), the carry scene's
  fences are brown, the frog differs between scenes, and the avatar is not shown carrying on `hud-place-sell`.
- **Built bosses must match the approved boss pictures** (brief, content section). The portraits here are stand-ins;
  the built models are made to match the approved pictures, and the final portraits are renders of those models.
- **"R$"** stands for Roblox's own Robux glyph, which the build uses.
- **"PLAYER2"** stands for another player's name.
- **Icons** are generated candidates (Higgsfield, `concepts/higgsfield-log.md`, round 3: 12.25 credits, and the final pass: 1 credit for the Perfect Auto Punch icon), plus eight
  kept from the round 2 Brick Brawl sheet (Power, cash, glove, lock shield, shop, rebirth, spin wheel, upgrade
  arrow). None is uploaded. The cut script (`src/cut_icons.sh`) removed the soft glow from the transparency and
  added the white rim; nothing inside an icon was redrawn. The untouched sheets are `src/icons-*-sheet.png`.

## Checks run, and results

- **Looked at every export** (boards at full size; screens singly or six to a sheet). Fixed along the way: captions
  under buttons, text wrapping out of wells, a chip wider than its card, icons cut across a cell edge, pips shown on
  a disabled Huss button, touch targets under 44 px.
- **Scripted** (`src/check_kit.py` on a dump of the file): on both screen pages, 0 text under 14 px (23 px at desktop
  scale), 0 light text without an outline, 0 pressable things under 44 px, 0 text outside its parent, 0 overlapping
  top-level frames. 347 text nodes and 109 pressable things per phone page.
- **Outline rule:** all white text carries the 2 px ink outline and hard shadow; text on gold, yellow and white is
  ink. Board 03 draws the HUD parts on the Ice Blocks blue and the lane grey, the two brightest grounds.
- **Generated-looking tells** (vault pattern): no dark same-colour cards, no hairlines, no pills, no see-through
  panels except the dim, no glows or gradients, every price on a button, one hero per screen, rarity as a filled card
  plus the word. Icons are one generated flat style, not glossy 3D; the manager has twice called generated icons "too
  AI" in another game, so the icon board is the thing to look at hardest.
- **Policy:** the six spin outcomes and their odds are on screen before Spin or Buy; the shop's spin card only leads
  to that screen; no "% off", no struck-out price, no countdown, no urgent wording; no offer on or beside an alert.
- **Not checked, because nothing is built:** anything in Studio, on a real phone, or in motion.

## Unverified

| What | Who | How |
|---|---|---|
| `TileSize` in Offset follows `UIScale`; a tiled image clips cleanly under a 4 px `UICorner` and under the round Huss button | gui-designer, first build milestone | One studded button and the Huss button at three scales |
| The inset stud at 16 px on a real phone, and whether the dark L is too busy under text | gui-designer, then the manager | This kit at phone size is the starting point; `phone-*.png` at 2x |
| Montserrat Black's weight name (`Enum.FontWeight.Heavy`) and that it renders as drawn | gui-designer | Set it in Studio |
| `UIStroke` thickness at each scale; the 2 px text outline on a small phone | gui-designer | Device emulator, small phone |
| Top bar and safe-area insets on real phones (`GuiService.TopbarInset`) | gui-designer | Emulator and the manager's phone; no docs digest covers it yet |
| The ring's speed, the feel of three pips, every motion and sound | manager | Playtest |
| Icons judged in place on a real play screenshot (the team's rule) | art-director, gui-designer | Here they sit on generated backdrops only |
| Instance count of the shop (19 studded cards) on a low-end phone | performance-optimizer | Count and measure |
| Gamepad glyphs and selection order on every screen | gui-designer | Controls table at build start |

## Questions and contradictions

1. **ANSWERED (manager, 2026-11-25): the boss-beaten banner is part of the HUD.** It is the non-blocking banner in the
   brief's screen 1 (`hud-boss-beaten`); it is not a separate screen and adds no step.
2. **Sell and Swap confirm colour.** The style guide says "a green or orange confirm" without saying when. Drawn:
   green for an ordinary sale, orange when the boss was bought with Robux and for the rebirth confirm.
3. **Spin button colour.** A spin spends a ticket, not Robux. Drawn gold (the style guide's screen 6 says gold),
   which stretches "gold costs Robux" to "gold is anything from Robux".
4. **ANSWERED (style guide section 6, buttons): a screen may have more than one green button** (the bag panel has two); the
   hero rule still holds, so one button is biggest and brightest. Drawn that way.
5. **Shield Breaker in the shop.** The brief says it is "explained here; bought at a shield". Drawn as an orange card
   with a greyed button "BUY AT A SHIELD" and the price in its line, since a price must sit on a button but this one
   cannot be pressed here.
6. **Spin tickets are not sold from the shop list.** The shop's Lucky Boss Spin card opens the spin screen, where the
   odds are, and the three ticket bundles are bought there. This keeps the odds on screen before any purchase. The
   brief lists the bundles as shop products but does not say where their buttons are.
7. **ANSWERED (manager, 2026-11-25): the icons are accepted as they are, including the round spin wheel.** No further
   generation is needed.
8. **No plus button on the cash counter** (style guide), though the playbook's "entry points at the point of need"
   suggests one. Drawn without.
9. **Passes in the shop are grouped by card colour** (grey, then cyan Long Lock, then the two orange attacking
   passes), not in the brief's table order, so the Starter Pack sits sixth. Say if the brief's order matters.
10. **Fight overlay hides Shop and Rebirth.** The brief forbids prompts during a fight; the style guide puts Run top
    left where Shop sits. Drawn with both hidden in a fight.
11. **Health bar number.** The style guide's 14 px bar cannot hold a 14 px label, so "150 / 250" sits beside the
    hearts.
12. **Players restricted from paid random items** see no spin card, spin screen or ticket buttons (brief). Not drawn
    as its own screen: it is the same shop with one card missing.

## Final pass (2026-11-25, after the manager approved the kit)

Only these were changed; every other PNG is byte-identical to before.
- **Perfect Auto Punch** (R$ 399): shop card (shop, board 05) after Auto Punch, a row on the bag panel under Auto Punch,
  and one new icon on board 04 (`src/icons/perfect-auto-punch.png`, sheet `src/icons-e-sheet.png`: Higgsfield
  `gpt_image_2_6`, 1:1, 1k, medium, transparent, the round 2 icon sheet and sheet B as references, 1 credit). In the game only
  Auto Punch owners are offered it, so the shop and bag panel are drawn in that state (Auto Punch OWNED / switch on). The
  10 pass cards now fill four rows; the fourth holds Iron Grip alone.
- **Rebirth** and its confirm use the brief's system 12 wording; the Rebirth button, the confirm button and the confirm panel
  carry the purple Rebirth arrows, never the gold star.
- **Lock button** follows the style guide table on every HUD variant; board 03 draws the ready state (no plate, cyan button).
- **Steal prompt**: the greyed "Can't be stolen" state with a padlock is on board 03. The owner's steal alert has a BOUGHT-tag
  variant on board 03. Nothing in the kit says a bought boss is protected: the BOUGHT tag means "from the shop".
- Board 02 captions follow the style guide's green and red rules; board 03 pip and Huss captions say one timed tap launches
  the burst.

## Text fixes (2026-11-25)

- Bag panel Speed row now reads the brief's table for level 1 and 2: "The ring closes in 1.20 s. Next level: 1.12 s".
- Board 01 palette captions now follow the style guide's current jobs (green: earned cash, price buttons, Collect, ordinary
  confirms; orange: warnings, steal alerts, hazards, can't-be-undone confirms; and so on). Only `01-foundations.png`,
  `phone-bag-panel.png` and `desktop-bag-panel.png` changed.
- Board 03 "Can't be stolen" caption now says "a bought boss where paid-item trading is off" (was "a spin boss"), matching system 10 and TEAM CALL 38: the guard covers every boss bought with Robux, the Starter Pack's Headbutt Ram included. Only `03-components-hud.png` changed.
