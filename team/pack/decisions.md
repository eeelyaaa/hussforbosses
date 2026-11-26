# Huss for Bosses: pitch decisions

Each pitch round: what was shown, what the manager said. Newest at the bottom.

## 2026-11-25: pitch started
- Slug `huss-for-bosses`, pack created from `vault/templates/game-pack/`. Pitch pasted into `brief.md`.
- Idea said back to the manager and one batch of questions asked (see below). 
- Questions asked: (1) can other players steal the bosses on your base, (2) what a "creature" is: the bosses themselves or also something else, (3) look direction to mock up, (4) Robux products in version 1 or not, (5) how much content version 1 holds.

## 2026-11-25: first answers
- Stealing: yes, with a base lock (chase and punch to get a boss back; timed lock shield).
- Creatures: the bosses are the creatures; several per zone in rarity tiers.
- Robux: full shop in version 1 (passes, cash packs, lucky boss spin, starter pack).
- Size: 6 zones, about 36 creatures, plus rebirth.
- Next: first mockups (loop options from game-designer, look directions from art-director, including map and zone layout and a creature line-up, which the manager asked to see).

## 2026-11-25: the huss sound
- Manager sent a voice recording saying "huss" three times; copied to `sound-refs/huss-huss-huss-manager.mp3`.
- Their words (in `brief.md`): cut out one "huss" for the punch sound; punches generally come in threes, "huss huss huss"; punch speed and strength are what improve during the game.
- Goes to: game-designer (three-punch rhythm, speed and strength as the upgrade axes) and audio-specialist (cut the single huss, `sound-direction.md`) when the pack is built. `loop-options.md` was written before this and does not have it yet.

## 2026-11-25: round 1 shown (look directions and loop options)
- Shown: three look directions, each with key art, scene, labelled zone map, creature line-up, phone HUD and boss upgrade menu. Boards: `concepts/gym-zoo/board.png`, `concepts/neon-knockout/board.png`, `concepts/clay-kaiju/board.png`. File: `concepts/concepts.figcraft` (open in the FigCraft app). Details: `concepts/directions.md`.
- Shown: three loop options in `concepts/loop-options.md`: A "Power Check", B "Carry It Home", C "Timed Hits, Open Lane".
- Team recommendation: Gym Zoo look, loop B. The three-punch "huss huss huss" rhythm and punch speed/strength upgrades (manager, same day) are not yet in the loop options; they get folded into the picked one.
- Higgsfield: 27.00 credits spent (9 per direction), balance 85.21. Log: `concepts/higgsfield-log.md`.
- Known rough spots: HUD and menu numbers, creature and tier names are placeholders; fonts are stand-ins; the Neon Knockout arcade robot's screen needs a redraw (too close to a famous pixel alien) if that direction is picked; the Clay Kaiju map draws bases as a column.

## 2026-11-25: round 1 answers
- Look: not picked yet. Manager asked for two more directions: one in Roblox stud style with voxel bosses, and one more. Also said: once one is built, the game can be replicated in another style to see which advertises better.
- Loop (a mix of the options): timing ring on both the bag and the fights (from C). A boss above your Power can be beaten, but it gets much harder the further above your Power it is. Carry the boss home past one moving hazard per zone (from B).
- Shop: an auto-punch pass for the bag. Selling things that work against other players is allowed.
- Rebirth: completely resets the player's stuff, including the base.
- Offline: offline earnings are on.
- Lucky spin: odds shown, agreed.
- Main session's reading, to confirm with the manager: stealing stays at bases only (the manager took B's carry, not C's open lane); no stealing from a player who is offline (not answered).
- Next: art-director makes directions 4 (stud world, voxel bosses) and 5 (its choice), same deliverables as round 1.

## 2026-11-25: round 2 shown (two more look directions)
- Shown: Direction 4 "Brick Brawl" (stud world, voxel bosses, as the manager asked): `concepts/brick-brawl/board.png`. Direction 5 "Snack Attack" (flat outlined snack world, art-director's choice): `concepts/snack-attack/board.png`. Both added to `concepts/concepts.figcraft` (five boards). Details and ranking: `concepts/directions.md`.
- Art-director ranking: Gym Zoo, Brick Brawl, Snack Attack, Clay Kaiju, Neon Knockout. For "build one, re-skin, test ads": Brick Brawl first (cheapest), then Gym Zoo or Snack Attack as the second skin.
- Higgsfield: 18.00 credits this round, balance 67.21. Total so far 45.00.
- Flagged: Brick Brawl pictures show a toy-minifigure avatar (the build uses the real Roblox avatar and Roblox studs); Ember Drake's flame tail needs a redraw; Brick Brawl creature sheet had a glow cut from its transparency (logged); Snack Attack HUD punch button overlaps the bag.

## 2026-11-25: look picked: Brick Brawl
- Manager picked Brick Brawl, with a correction: use the stud texture Roblox games use (square inset studs on flat-coloured parts), not toy-brick round studs; the stud texture goes on UI elements too. "People call it stud slop, but I like it."
- 14 reference screenshots saved in `concepts/manager-refs/`: 1-3 are stud UI (shop list, inventory grid, rainbow shop panel with side buttons); 4-14 are stud maps (islands, palm trees, market stalls, crates, bushes, water, blue sky with soft clouds, soft shadows and slight depth blur). References are for technique; nothing is copied.
- The voxel boss mockups were good: "yes ideas like that."
- Confirmed: stealing at bases only; an offline player keeps earning and can't be stolen from.
- Look and loop are both picked. Next: step 3, build the pack. The round 2 Brick Brawl board stays as the record of what was shown; the UI kit shows the corrected stud look.

## 2026-11-25: pack in progress, two changes from the manager
- Written: `brief.md` in full (game-designer), `sound-direction.md` with huss candidates and listening page `sound-refs/candidates/index.html` (audio-specialist), `style-guide.md` (art-director, 0 credits).
- Manager: "Items bought with robux should remain." Rebirth keeps what was bought with Robux.
- Manager: "lets change that no attacking products rule then." Attacking products (such as a shield breaker) are wanted in the shop.
- UI kit (gui-designer), game page (live-ops) and build plan (producer) were started and cut off by a usage limit; resumed afterwards.
- Still open for the manager: pick a huss candidate and confirm the recording is theirs to upload; Robux prices.

## 2026-11-25: models for specialists
- Manager: the main chat (Fable) orchestrates and picks a model per specialist launch, by what the task needs; a Fable agent is allowed when needed. "it should be this one going forward."
- Applies to the rest of this pitch and to `/build`. Added as a section in `build-plan.md`.

## 2026-11-25: UI kit reviewed by the manager
- Shown: `ui-kit.figcraft`, 49 exports in `ui-kit/` (5 boards, 22 screens at phone and desktop). Higgsfield 12.25 credits, balance 46.96.
- Manager: foundations, icons, and the phone and desktop screens are "amazing". Icons accepted as they are.
- Manager, on components: the built bosses must look like the bosses in the images. Bosses get small fighting animations, and each fights with its own body: a scorpion stings with its tail and punches.
- Main session's reading: this adds per-boss fight animation to version 1 (brief, style guide, build plan, sound). The voxel bosses therefore need moving parts (at least fists, plus a signature part such as the tail), not one static mesh. Routed with the cold-read fixes.
- Fable usage ran out for the account (resets 2026-11-27 22:00 PT); the cold read and later agents run on Opus or Sonnet.

## 2026-11-25: cold read and the manager's answers
- Cold read (Opus, fresh agent): 14 questions (4 blocking, all the manager's), 26 contradictions, 14 listed/pictured gaps, 7 departures from the manager's words. Fixes routed to game-designer, art-director, audio-specialist, gui-designer, producer.
- Huss: the manager may upload it under their account ("use computer use"). Picks: slot 01 A (huss 1 as cut), slot 02 A (huss 4 levelled), slot 03 E (first group of three as recorded). "make sure the punches against bag or boss are timed against this": the three-punch combo follows the recorded rhythm (about 0.21 s then 0.19 s between husses).
- Ownership: the manager will make a group; a group icon is needed. Uploads wait until the group exists so every asset shares the owner.
- Bought bosses and stealing: copy how other steal-style games handle it; if they don't sell bosses, don't sell them. Research launched.
- What Robux purchases keep at rebirth: the team decides for the most Robux.
- Bag ring stays as in the brief (only fights get harder). Offline cap of 2 hours per spot accepted. Auto Punch at Good accepted; "maybe we sell a perfect auto puncher too".

## 2026-11-25: late answers and final passes
- Research on steal games saved in `vault/observations/2026-11-25-steal-games-paid-items-and-stealing.md`: units are sold, bought units are stealable, rebirth wipes units there. Applied: bought bosses stealable, with a policy guard for spin bosses (TEAM CALL 38).
- Punch: one graded tap launches a three-punch burst at the recorded rhythm (TEAM CALL 36). Perfect Auto Punch pass added at R$399 (the manager's "maybe"). Shop is 19 items. Bought bosses keep their levels through rebirth (decided for revenue, as asked).
- Burst voice: the manager asked for the combo without the breath at the start. `f_group1_no_breath.wav` (E minus 18 ms, 4 ms fade in) is the pick; a generated clean huss is allowed if needed.
- Group: the manager will create a group to own the game; group section added to `game-page/game-page.md`.
- Final passes done on brief (Opus), style guide (Opus), sound direction, UI kit, game page (Sonnet). Build plan, approval sheet and start prompt updated last.

## 2026-11-25: answers before approval
- Account is ID-verified. Manager will pay or advertise as needed for the 16+ / Kids and Select gate.
- Combo F (no breath) "sounds good": confirmed as the burst voice.
- "would be great if the punches were in groups of three. the hus huss huss. timed with the audio too": main session reads this as confirming the one-tap burst (one tap launches three punches timed to the recording). Said back to the manager.
- Defaults accepted: Perfect Auto Punch at R$399; bought bosses keep levels through rebirth; all three attacking products; prices; title "Huss for Bosses"; genre Simulation; sound defaults.
- Game icon carries the word HUSS (changed from the no-text default).
- Group "Huss for Bosses" created by the manager. Manager asked the team to make a group icon and upload it. Research asked for: whether stealing a spin boss counts as paid item trading.

## 2026-11-25: group icon uploaded; policy research
- Group "Huss for Bosses" exists: community id 432262304 (https://www.roblox.com/communities/432262304/Huss-for-Bosses), owned by the manager's account.
- Group icon made (art-director on Sonnet, Higgsfield 3.00 credits, balance 42.96; FigCraft file `game-page/group-icon.figcraft`) and uploaded by the main session through the manager's Chrome, at their request: Configure Community, Emblem, `game-page/group-icon.png` (512 x 512 PNG accepted). Roblox answered "Successfully updated community icon"; it showed the pending-review placeholder afterwards, so moderation is UNVERIFIED until it appears. It replaced the placeholder emblem the manager had set.
- Seen on the configure page: the cover photo must be 720x228 or 1440x456. No cover photo was uploaded.
- Spin and stealing: no official source says whether a steal is "trading". Findings and a paste-ready question for Roblox are in `vault/roblox-docs/paid-random-items-policy.md`. The trading flag covers all paid items, so the Starter Pack ram needs the same guard as spin bosses (applied in the consistency pass below).

## 2026-11-25: consistency pass over the pack
- Brief: burst voice is F everywhere; a boss emptied on punch 1 or 2 ends the fight on that beat; one burst per ring with a hand tap replacing the auto tap only if better (build plan B20, B22 now in the brief); Perfect Auto Punch's icon is already made (64 icons); the policy guard (TEAM CALL 38) covers every boss bought with Robux, spin bosses and the Starter Pack's Ram, and is removed if Roblox says stealing is not trading; open questions emptied (the manager answered them); the game icon carries the word HUSS.
- Sound direction: E to F through the body; the 10 ms lead is resolved; the manager's "9. yep" and "combo f sounds good" recorded; the huss files go to the group, owned by the manager's account.
- Style guide: 64 icons, Perfect Auto Punch described, bag panel row, jab schedule final, icon lettering rule. Game page: the group exists with its first icon, cover photo sizes, title, genre and icon text decided. Build plan, approval sheet and start prompt: group and ID verification done, answers recorded, contradictions list reduced to the beat offsets plus two kit items to verify at M0, Higgsfield balance 42.96 (pitch total 69.25).

## 2026-11-25: approval sheet answers; base layout asked for
- Boxes 1 to 5 answered yes in the manager's words (in `approval.md`); box 6 (install nothing) not answered. Status stays DRAFT: the manager wants a base area layout first.
- Perfect Auto Punch gets a Perfect sting ("maybe lets add a perfect sting"). Both thumbnails at M6; group icon only.
- Base layout: "look at how other games do it and decide". Research on how steal-style games lay out bases, then an art-director mockup: all 8 bases, one plot close-up, every pad.
- A second cold read (Opus) is running on the pack.

## 2026-11-25: base layout references from the manager
- Three screenshots saved in `concepts/manager-refs/` (15, 16, 17). What they show (main session's description): 15, a walled, flat "safe zone" with fenced rectangular plots in a row along one side, each with a station at its front edge facing an open shared area; upgrade stands (Rebirths, Money, Speed, a Trails stall) along the far wall; a painted line marks the safe zone's edge. 16, a similar hub in the stud look: fenced plots along one side, shared stations in the open area (sell, a fuse machine, a trails stall, leaderboard boards), high walls, and a gate to the next zone with its name and "LOCKED". 17, the lane: a wide walled corridor with a path line down the middle and props to the sides.
- Manager: this is the general layout, with our own twist and theme.
- This replaces the main session's earlier decision of two facing rows across a strip. The art-director was told while working.

## 2026-11-25: base layout made and accepted
- `base-layout/` (art-director on Opus): `base-layout.md`, `base-layout.figcraft` with 4 pages (`01-base-area-plan`, `02-plot-plan`, `03-pads`, `04-steal-route`), three renders (impressions only). Higgsfield 8.00 credits, balance 34.96 (pitch total 77.25).
- Layout: a walled hub, 8 plots in a U (4 along the back wall, 2 along each side) facing one open yard; the lane starts in the yard as a running track and leaves through the zone 1 arch. Twist (art-director's proposal): an outdoor stud boxing gym, each plot's bag at the front by its entrance. No safe zone, no locked gate, no shared stands (optional overlay only).
- Files were written at 16:58 to 17:04, after the manager's references (16:49). Manager, 17:04: "perfect. base-layout looks good. all 4 pages in that document."
- Second cold read (Opus): no blocking findings, 8 minor ones. Applied with the layout's changes to brief.md and style-guide.md in the last pass.

## 2026-11-25: layout written into the pack
- brief.md (Opus): hub and plot rules, re-derived first-session timings (first boss placed about 0:52), trips against one shield by zone, TEAM CALLs 40 (layout), 41 (walled corridor lanes with a centre line, from the manager's reference 17), 42 (Settings gear tile). Speeds unchanged.
- style-guide.md, build-plan.md, approval.md, START-PROMPT.md (Sonnet): hub section, plot, lock board buttons, corridor look, M1 builds the manager's plot and the track start, M3 the full hub.
- Main session: bag frame set to plate blue to match the approved kit; corridor geometry and line width aligned with the brief; update note added to `base-layout/base-layout.md`.
- Higgsfield balance 34.96; pitch total 77.25. The build's planned 24 leaves about 11; the optional boss sheets no longer fit beside it.
- The pack was complete and waiting for approval.

## 2026-11-25: APPROVED
- Manager: "yea. I think it's approved for build. i'll run it when my usage limits reset." Status set to APPROVED 2026-11-25 in `brief.md` and `approval.md`.
- Box 6 ("installing nothing new") was never answered; nothing is installed without asking.
- **The pitch ends here.** Next: the manager publishes a Baseplate place under the Huss for Bosses group (community id 432262304) with Studio API access on, then pastes `/build huss-for-bosses until M1` (or without `until M1`) into a new chat in `ro-team`.
- Still open outside the pack: the question for Roblox on whether a steal counts as paid item trading (`vault/roblox-docs/paid-random-items-policy.md`); the group icon's moderation; nothing in `ro-team` is committed (the pack, the Models rule in CLAUDE.md and playbooks, two new vault observations, the docs digest update).
