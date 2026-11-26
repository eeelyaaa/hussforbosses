# Huss for Bosses: waiting on the manager

The one place things wait for you. The build keeps going around every item. Short lines, exact steps.
Groups: do first, set up, look at or listen to, questions, confirm, done. Updated at the M1 close (2026-11-25).

## Do first (unblocks the most)
1. **Create the 10 passes and 9 developer products under the group's game and paste their ids here.**
   Creator Dashboard, switch to the group Huss for Bosses, Creations, Huss for Bosses, Monetization. Prices are
   the brief's starting figures (system 13); prices are yours.
   - Passes: Create a Pass, name, description, create; open it, Sales, switch on "Item for sale", set the price,
     save. Until the ids are here the game runs on stand-ins and no purchase can be tested.

     | Key | Pass | Price | Id |
     |---|---|---|---|
     | pass_auto_punch | Auto Punch | R$249 | |
     | pass_perfect_auto_punch | Perfect Auto Punch | R$399 | |
     | pass_2x_power | 2x Power | R$349 | |
     | pass_2x_cash | 2x Cash | R$349 | |
     | pass_fast_carry | Fast Carry | R$149 | |
     | pass_long_lock | Long Lock | R$199 | |
     | pass_extra_spots | Extra Spots | R$249 | |
     | pass_quick_hands | Quick Hands | R$199 | |
     | pass_iron_grip | Iron Grip | R$299 | |
     | pass_starter_pack | Starter Pack | R$99 | |

   - Developer Products: Create a Developer Product, name, price, save.

     | Key | Product | Price | Id |
     |---|---|---|---|
     | product_cash_small | Small Cash Pack | R$29 | |
     | product_cash_medium | Medium Cash Pack | R$79 | |
     | product_cash_large | Large Cash Pack | R$199 | |
     | product_cash_huge | Huge Cash Pack | R$399 | |
     | product_spin_1 | Lucky Boss Spin x1 | R$49 | |
     | product_spin_3 | Lucky Boss Spin x3 | R$129 | |
     | product_spin_10 | Lucky Boss Spin x10 | R$399 | |
     | product_instant_shield | Instant Shield | R$19 | |
     | product_shield_breaker | Shield Breaker | R$39 | |

   - The 19 icons are on UI kit board 04 and can be added at creation or later.
2. **Save the place** (File, Save to Roblox, or Ctrl+S) when convenient. Since M0 the place holds the sync loader
   (`ServerStorage.DevSync`), the place marker (`Workspace.HussForBosses = true`) and the synced scripts, and since M1
   the built slice, the imported frog and gloves and the stud material. Without a save the team re-creates the loader
   (one line, `team/CLAUDE.md`), but the hand-imported meshes would need re-importing, so save before closing Studio.

## Set up
3. **Set the server size to 8.** Creator Dashboard, the game, its place's settings, Maximum Visitors: 8
   (`UNVERIFIED`: the exact page; the team names it when it asks).
4. **Each future audio upload** needs the Audio Upload License Agreement ticked in the Creator Dashboard, which needs
   your yes in chat; the yes at M1 covered its 8 files only (M4 uploads more).

## Look at or listen to
5. **Play the M1 strip** (optional, no gate; the team has checked the timing by numbers, only you can judge feel).
   In Studio press Play, then:
   - Walk to the bag pad on your plot (the red pad by the bag, near the spawn).
   - The ring shows around the Huss button: tap the Huss button (or F, or click) as the ring lands. Do it a few times.
   - To fight, you need Power 25 (about five bursts). Keep punching until the counter reads 25. (Setting Power by the
     test hook is not possible from your side.)
   - Walk out the plot entrance, down the track, through the zone 1 gate to the pad with Chomp Frog. The number over
     it turns green when you are strong enough. Step into the ring and press Huss: the camera frames the frog.
   - Tap as each ring lands; win by emptying its bar. Pick the frog up (the carry starts on its own), walk home past
     the Rolling Log. If the log hits you the frog drops: walk back to it or press E to grab it.
   - At your plot stand on a glowing spot and press E to place it, wait about 30 seconds, step on the cash pad to collect.
   What to judge, in your words: the ring's speed (too fast or slow), the three pips filling, whether the huss sound lands
   with the three jabs (the team can only match them to about 15 ms by numbers), the fight camera, and how the frog's bite
   and flinches look. Nothing here gates the next milestone.
6. **The first six bosses** (after M2), rendered beside their pictures. The other 30 are made after your yes.
7. **Listen and pick.** Each sound family arrives as a listening page; answer with one letter per slot.
7. **Audio permissions.** If an uploaded sound is silent in the game, open that sound's page in the Creator
   Dashboard, Permissions, and add the experience. The team lists which.
   M1-13 (2026-11-25): all eight ids load in Studio, but Studio plays under the account that owns the group, so it cannot show
   whether the live experience is allowed to play them. If any is silent in a published test, add the experience to: HFB Burst
   Voice F (127740860120528), HFB Single Huss 02A (133382295573645), HFB Single Huss 01A (87792871818595), HFB Standin Thud Bag1
   1/2/3 (100565015513028, 108906304686894, 131000564218509), HFB Standin Swish (120181524699792), HFB Standin Perfect Sting
   (92977560674627). Not known to be needed.
8. **Higgsfield top-up**, only if the team reports the balance won't cover what is left.

## Questions
(none open; each one here would have a default the build is using, marked `PROVISIONAL` on the board)

## Confirm
9. **The pack's media is not backed up in any git repo in full.** The game repo commits the spec media (UI kit,
   base-layout plans, the Brick Brawl concepts, your references, the huss recording) but ignores about 280 MB of
   exploration (the four other look directions, game page concepts, layout renders): TEAM CALL M0-1. Those stay
   on disk in `projects/huss-for-bosses/team/pack/` and `pitches/huss-for-bosses/` (ro-team doesn't track
   `pitches/` either). If you want them kept somewhere, copy the folder to a backup drive; nothing in the build
   needs them.
10. **Delete a stray folder:** `C:/team/verification/m1-chomp-frog/` (4 duplicate renders written by a wrong path in
    M1-03; the delete was blocked by a safety check). Harmless; remove it by hand when you like.

## Your notes for later milestones (2026-11-25, your words; not questions)
- M3, the zones: "hopefully the map will have walls and stuff (the part with the different world types and monsters) ... with voxel style too some parts especially." You showed a reference: a long lane walled on both sides by high walls with voxel trees along the top, each zone a different ground colour in sequence down the lane, big mountains behind the walls. The base layout already makes the zone lanes walled corridors; the M3 builder brief carries this note and that look (`requirements/m2-carryover.md`).
- M3/M4, the log: "I know log will be functional but it should look better." The M1 log is a plain cylinder stand-in; its real look (a voxel log in the style guide's look, with its warning) is M3/M4 work.
- Workflow: if M1 works as intended you start the next milestone in a new chat, and give feedback at certain parts of the game.

## Done
- 2026-11-25, M0: the open place is the group's (CreatorType Group, 432262304) and saving works in Studio
  (DataStore write and read passed). `verification/m0-setup.md`.
- 2026-11-25, M1: **the stud proof** answered, "B on both" (applied: `MaterialService.Stud` uses the flipped normal).
  Sheet: `team/verification/m1-stud/stud-proof-sheet.png`.
- 2026-11-25, M1: the two Studio-window steps (publish the 4 avatar clips under the group, import Chomp Frog and the
  gloves) were done by the main session with your go-ahead ("yes, you can use computer access for those two"); ids in `assets.md`.
- 2026-11-25, M1: your yes in chat for the Audio Upload License Agreement on the 8 M1 audio files; uploaded, all load.
