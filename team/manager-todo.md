# Huss for Bosses: waiting on the manager

The one place things wait for you. The build keeps going around every item. Short lines, exact steps.
From `pack/build-plan.md`, "During the build", opened at M0 (2026-11-25).

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
   (`ServerStorage.DevSync`), the place marker (`Workspace.HussForBosses = true`) and the synced scripts. Without a
   save the team re-creates them (one line each, `team/CLAUDE.md`), so this is not urgent.

## Set up
3. **Set the server size to 8.** Creator Dashboard, the game, its place's settings, Maximum Visitors: 8
   (`UNVERIFIED`: the exact page; the team names it when it asks).

## Look at or listen to
4. **The stud proof** (after M1): say yes or what is wrong. Nothing else is studded until then.
5. **The first six bosses** (after M2), rendered beside their pictures. The other 30 are made after your yes.
6. **Listen and pick.** Each sound family arrives as a listening page; answer with one letter per slot.
7. **Audio permissions.** If an uploaded sound is silent in the game, open that sound's page in the Creator
   Dashboard, Permissions, and add the experience. The team lists which.
8. **Higgsfield top-up**, only if the team reports the balance won't cover what is left.

## Questions
(none yet; each one here has a default the build is using, marked `PROVISIONAL` on the board)

## Confirm
9. **The pack's media is not backed up in any git repo in full.** The game repo commits the spec media (UI kit,
   base-layout plans, the Brick Brawl concepts, your references, the huss recording) but ignores about 280 MB of
   exploration (the four other look directions, game page concepts, layout renders): TEAM CALL M0-1. Those stay
   on disk in `projects/huss-for-bosses/team/pack/` and `pitches/huss-for-bosses/` (ro-team doesn't track
   `pitches/` either). If you want them kept somewhere, copy the folder to a backup drive; nothing in the build
   needs them.

## Done
- 2026-11-25, M0: the open place is the group's (CreatorType Group, 432262304) and saving works in Studio
  (DataStore write and read passed). `verification/m0-setup.md`.
