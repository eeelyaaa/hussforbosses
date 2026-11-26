# Huss for Bosses: build plan

Status: APPROVED 2026-11-25 with the game pack (see `approval.md`). Written 2026-11-25 by the producer with tech-lead input; brought up to date
the same day (evening) with the pack as it stands after the cold read, the manager's answers, the UI kit approval,
the one-tap burst, the boss fight animations, the 19-item shop and the group.
Updated the same evening with the approved base layout (the manager: "perfect. base-layout looks good. all 4 pages in
that document.").
Read with: `brief.md` (the spec; "The idea, in the manager's words" outranks everything), `style-guide.md`,
`sound-direction.md`, `ui-kit.figcraft` and `ui-kit/`, `base-layout/` (`base-layout.md`, plans `01` to `04`,
`base-layout.figcraft`; the plans are the spec for the hub and the plot), `game-page/game-page.md`, `approval.md`.

This plan builds what the brief says. It adds nothing and cuts nothing. Where this plan and the brief differ, the
brief wins, and the manager's own words win over both. Things the producer or tech-lead would change are under
"Suggestions (optional)" near the end. Contradictions that are still open between the pack files (one, plus two to verify) are listed at the very end, with what the build follows until each is settled.

Nothing in this plan has been run. Every size, count and credit figure is an estimate; where its basis is weak it
says so.

## How this game is built
- Mode: **autonomous** (`vault/playbooks/autonomous-build.md`), started with `/build huss-for-bosses`.
- Owner: **the Roblox group "Huss for Bosses"** (community id 432262304, https://www.roblox.com/communities/432262304/Huss-for-Bosses;
  created by the manager, owned by their account; its first icon was uploaded on 2026-11-25, moderation pending).
  Brief, system 13 and 14; manager: "I guess I will make a group". The place is published under the group before the
  build, so data stores, passes, products and every uploaded asset belong to the group from the first day.
  Publishing the place under the group is the manager's step.
- Code reaches Studio by: **the project's own sync script** (a copy of the DevSync tool from the manager's game
  deja-kill: `python tools/devsync.py` serves `src/` and `studio/` on localhost and a loader in the place pulls
  them). `TEAM CALL` B1, reasons under "Technical shape".
- UI is built: **in code**, from the UI kit's values, in `src/`. Nothing is laid out by hand in the place.
- The world is placed by: **build scripts in the repo** (`studio/`), which can run again on an empty place.
- Bosses and the boxing gloves are made by: **a voxel builder in headless Blender** (`tools/blender/`), exported as
  FBX with one mesh per moving group and imported through Studio. Higgsfield 3D is not used.
- Boss fight moves are **tweens of the moving groups in code**, not Animation assets (style guide section 5). The
  avatar's seven clips are Animation assets published under the group.
- Stops for the manager: **only at the final handoff**, unless the manager adds `until M<n>` to the build line
  (see Suggestions, S1). Two "look at" items gate later work without stopping the build: the stud proof (M1) and
  the first six bosses (M2).

### Models: the orchestrator picks one per launch
The manager, 2026-11-25: "fable is always orchestrating new chats of different model strengths depending what it
needs. if fable needs a fable agent it can use it." Root `CLAUDE.md`, "Models": the main chat sets `model` on every
specialist it launches; no launch relies on inheriting the main chat's model.

**Fable is not available at the start.** The account's Fable usage ran out on 2026-11-25 and resets on
2026-11-27 at 22:00 PT (`decisions.md`). This plan works with **Opus as the top model**: every task marked "fable
when available" below runs on Opus until then, and the orchestrating chat runs on the manager's top available
model. Nothing in the build waits for Fable.

Starting split (`TEAM CALL` B19, the orchestrator's own judgment, changed from results and logged in
`team/decisions.md` when a role moves):

| Model | Used for | Typical task families |
|---|---|---|
| opus | A mistake is expensive or hard to see | Server authority, the punch and fight rules, saving and the session lock, stealing and transfers, the receipt handler and Robux grants, rebirth, `PolicyService`, the exploit review, architecture and the remotes contract, economy measurement and tuning, the art-director's match and originality reviews (until Fable is back) |
| sonnet | Well-specified work with exact values in the pack | World build scripts, props, hazards, the boss data files and builder runs, the gloves, the 30 bosses after the six are approved, boss move tables, avatar clips, screens from the UI kit, sound sourcing, cutting, measuring and wiring, effects, lighting, the game page kit, board and plan upkeep |
| haiku | Lookups and file checks that need no judgment | Asset inventory against `team/assets.md`, id and count checks, re-running a passing check script and reporting the numbers |
| fable | When the task needs it and the account has it again | The final Look review, `/audit`, a diagnosis two attempts have failed at, a task that came back weak on Opus |

Rules for this build:
- **At most two Opus agents in one wave.** Several top-model agents in one wave are what hit the usage limit in this
  pitch (autonomous-build playbook). Sonnet and Haiku tasks fill the rest of a wave.
- A task that fails its checks goes back one model up with what failed (Haiku to Sonnet, Sonnet to Opus, Opus to
  Fable when available, else to the tech-lead on Opus with the failure). The stuck rule then applies.
- M1 is the test of the split: a role whose M1 work fails its exit checks is moved up one model for its next task,
  and the move is logged.
- Each milestone's table below gives a suggested model per task family; the producer repeats it per task on the
  board, and the orchestrator decides.

### Architecture requirement: the skin is separate from the rules
The manager, 2026-11-25: "once we build one we can replicate the game in different style and see which one performs
better during advertising". The second skin is not built here (brief, "Not in version 1"). What is built here is
the separation, and it is checked at M1, M3 and M5:

- Rules, numbers and saves refer to content only by id: `zone 1..6`, `tier 1..6`, creature `z3_t3`, `hazard 1..6`,
  `bag 1..6`, body type `1..7`, product keys such as `pass_auto_punch`.
- Everything a player sees or hears for an id comes from **one skin table**: `src/ReplicatedStorage/Skins/<skinId>/`
  holding `Names` (game, zones, creatures, hazards, bag tiers, products), `Tokens` (every colour, the font, radius,
  outline, lip and shadow sizes), `Models` (model name per id), `Icons` (asset id per icon key), `Sounds` (asset id
  per sound slot, and the burst voice's own beat table), `Lighting` (the base table and the six zone shifts),
  `Effects` (shapes and textures), `Dressing` (props and landmarks per zone). The active skin is one constant,
  `Config.SkinId`.
- Structure stays outside the skin (style guide section 9): the lane, plot and pad layout, hazard tracks, boss
  heights per tier, the moving-group names and pivots, the seven body types, and the timing of every boss and
  avatar move (`Shared/Moves/`, in fractions of the boss's height H).
- Nothing outside `Skins/` contains a display name, a hex colour, or an asset id.

**The skin check** (`studio/CheckSkin.lua` plus a repo scan), run as an exit check:
1. A scan of `src/` outside `Skins/` finds no `rbxassetid`, no `Color3.fromRGB` / `fromHex` literal, and none of
   the 36 creature names, 6 zone names, 6 hazard names or 19 product names.
2. A stub skin (`Skins/stub`: grey boxes with the right moving groups, ids shown as names, no sounds) is switched on
   through a test hook and the smoke loop (punch, fight, carry, place, collect, upgrade) passes with it. The stub is
   a test fixture of about 50 lines, not a second look.
3. A save made under the real skin loads under the stub with every boss in place.

## Milestones
The numbering and gates are the ones `/build` and the playbook use. Sizes are in sessions (one chat, start to
usage limit), not dates. No game has been built this way yet, so every size is `UNVERIFIED`.

| # | Milestone | Goal | Roles (suggested model) | Size |
|---|---|---|---|---|
| M0 | Setup | Repo, `team/` files, sync proven, tools found, the right place (group-owned) confirmed | tech-lead (opus), producer (sonnet), a haiku tool check | under 1 |
| M1 | Core feel and the four proofs | Bag, timing ring, one-tap "huss huss huss" burst, Chomp Frog's fight with its moves, carry, place: playable end to end. The burst, the avatar jabs and the sound locked to one clock at 60, 30 and 15 fps. The stud, the boss pipeline with moving groups, and one studded button proven. The manager's own plot and the track start built to `base-layout/`, with the run and carry times measured | scripter (opus), tech-lead (opus), modeler-3d (sonnet), animator-vfx (sonnet), audio-specialist (sonnet), gui-designer (sonnet), builder (sonnet), game-designer (sonnet), producer (sonnet) | 2 to 3 |
| M2 | All version 1 systems, and the first six bosses | Every system in the brief works on the server's authority and saves; the first session runs from a fresh profile. In parallel: the five other pictured bosses built to their pictures, with their body types' moves, shown to the manager | scripter (opus), data-engineer (opus), qa-exploit-reviewer (opus), game-designer (opus), gui-designer (sonnet), modeler-3d (sonnet), animator-vfx (sonnet), art-director (opus), producer (sonnet) | 4 to 5 |
| M3 | World and UI | The six zones and the full base hub (8 plots in a U, walls, arch) built in studs, the zone lanes as walled corridors, 48 props with 6 landmarks, six hazards, six bags, the other 30 bosses and every fight move, every screen built from the UI kit, the 64 icons in place | builder (sonnet), modeler-3d (sonnet), animator-vfx (sonnet), lighting-specialist (sonnet), gui-designer (sonnet), scripter (sonnet), art-director (opus), performance-optimizer (opus), producer (sonnet) | 5 to 7 |
| M4 | Feel and sound | Every action answers back; the 19-file-set boss scheme and every other family sourced and wired; listening pages with the manager | animator-vfx (sonnet), audio-specialist (sonnet), scripter (sonnet), gui-designer (sonnet), producer (sonnet) | 2 to 3 |
| M5 | Quality passes | Friction walk-through on a phone, Look review, audit, exploit review, performance review; no must-fix left | gui-designer (sonnet), game-designer (opus), art-director (opus; fable when available), auditor (opus; fable when available), qa-exploit-reviewer (opus), performance-optimizer (opus), scripter (opus for server fixes, sonnet for UI fixes), producer (sonnet) | 2 to 3 |
| M6 | Release kit and handoff | Game page kit and group icon from real screenshots and renders, playtest script, two-device checklist, `team/handoff.md` | live-ops (sonnet), art-director (opus review), producer (sonnet) | 1 |

Total: about 17 to 23 sessions. Roles not used in the build: scout, video-ingestor, curator (the curator comes in
after the playtest, through `/retro`).

### M0: Setup
**Goal.** A game repo the team can work in and the group-owned place it can run code in.

**Built.** `projects/huss-for-bosses/` (cloned or `git init`), the pack copied to `team/pack/`, `team/` files
(`CLAUDE.md` with `Mode: autonomous`, the owner (the group), and what the approval covers; `brief.md`,
`style-guide.md`, `sound-direction.md`; `board.md`; `decisions.md` opened with the brief's 39 team calls and this
plan's B-series; `lessons.md`, `assets.md`, `manager-todo.md` (opened with the manager's "during the build" list
below), `test-hooks.md`, `requirements/`, `verification/`, `audits/`, `build-state.md`), the `src/` and `studio/`
layout below, the sync script, `docs/controls.md` from the brief's controls table.

| Task family | Role | Model | Why |
|---|---|---|---|
| Repo, `team/` files, sync, place guard, layout | tech-lead | opus | Architecture: every later task depends on the seams set here |
| Board from the plan | producer | sonnet | Upkeep from exact values |
| Tool check (Blender, earshot, lock script, Studio MCP answers) | any | haiku | Lookups |

**Exit checks.**
- Scripted: a synced server script prints from the server in play mode; a `studio/` script runs through the sync.
- Scripted: **the place guard.** Every `studio/` script and the sync loader refuse to run unless the open place
  carries the marker attribute `HussForBosses = true` on `Workspace` (set once at M0). The manager usually has
  another game's place open; no script of this game may run there.
- Scripted: the open place's `game.CreatorType` is `Group` and `game.CreatorId` is the manager's group (written to
  `team/CLAUDE.md`). If it is `User`, `BLOCKED: manager` (before-step 2 not done) and the build goes on with saving
  and uploads off, because both would land with the wrong owner.
- Scripted: Blender is found and runs headless (`blender -b --version`). On this PC it is installed through Steam
  at `D:\Games\steamapps\common\Blender`; the version is read at M0. earshot answers (`.venv-audio/`).
- Scripted: a DataStore write and read succeeds in Studio (proves "Studio access to API services" is on). If it
  fails: `BLOCKED: manager`, and M1 goes on with saving off behind a test hook.
- On-screen: none. Quality passes: none (nothing player-facing).

**The manager sees.** Nothing to look at. Two lines in the chat: where the repo is, and whether the place is the
group's and saving works.

### M1: Core feel and the four proofs
**Goal.** Prove the thing the game is about, as early as possible: stand at the bag, tap once as the ring lands,
see the avatar throw three jabs and hear "huss huss huss" on the same beats, get strong, beat Chomp Frog while it
guards, flinches and bites back with its own body, carry it home past the Rolling Log, put it on a spot and watch
it earn. And prove the pipelines everything else depends on, on one piece each, before 36 bosses and six zones are
made with them.

**Built.**
- Server: the ring schedule per Speed level and burst validation (system 1: one graded tap, three punches at 0,
  0.213 and 0.401 s, 1 + 1 + 2, x2 on a Perfect; ring 1.20 s at Speed 1 to 0.50 s at Speed 10); bag and Power (2,
  3; Strength and Speed levels read from config, buying them comes in M2); one fight with bands, hearts, win and
  loss, damage applied at the server's beats (4); zone 1's fixed pad with Chomp Frog (5, fixed pad only); carry and
  the Rolling Log with drop and grab (6); one base plot with spots and placing (7); income to the pad and
  collecting (8). No saving beyond the M0 proof.
- Client: the Huss button, timing ring, hit band and three pips to the style guide's sizes; GOOD and PERFECT pops;
  Power and cash counters; the fight overlay (health bar, hearts, band word, Run); Place and Grab prompts. Touch,
  keyboard and gamepad bindings for these actions.
- **Proof 1, the burst clock** (`sound-direction.md`, "Keeping sound and the three hit frames together"): one
  `t0` per burst, the burst voice F started in the same frame, beats fired from `t0` on Heartbeat (late frames fire
  every missed beat in order), the jab clip seeked to the elapsed time, the server applying the three punches on
  the same table. F is uploaded to the group by the main session (computer use), and its three loud parts are
  measured on the uploaded asset with the envelope probe and written to config as `F_BEAT_IN_FILE`.
- **Proof 2, the stud:** the `Stud` MaterialVariant (three maps made by script from `style/make_stud_refs.py`'s
  height map) on a test strip: a wall, a floor, a crate and one UI button, beside the manager's references 8, 13,
  14, 1 and 2, built both ways for the normal map.
- **Proof 3, one boss with moving groups:** Chomp Frog (`z1_t1`, squat stomper) built from its approved picture
  (`concepts/brick-brawl/creatures.png`, about 19 cubes tall) through the headless builder, FBX, the Studio
  importer, a setup script, onto the pad, with its groups `Body`, `Head` (upper face and jaw block, pivot at the
  back of the jaw), `FistL`, `FistR`, `Sig`, named and pivoted as the style guide's table. Built both ways the style
  guide names (shared atlas, one mesh per colour role); one is picked (B4). Its moves: idle, guard, hit reactions at
  Good, Perfect and big-huss sizes, its signature (hops in and chomps, then a fist bop), last heart and gloat,
  defeat, carry rock, half idle. Render beside its picture, same angle.
- **Proof 4, one studded button:** the Huss button (round, stud tile clipped to the circle) and one panel with the
  tiled overlay, at three `UIScale`s.
- Avatar: the voxel boxing gloves (Huss red, yellow cuff, about head size, put on at spawn, following each hand),
  and the jab x3 and big third punch clips, published under the group.
- Sound: F on every landed burst, one F voice per player, none on a Miss (soft swish on the bag; in a fight the
  boss's wind-up marks it); the two single-huss takes (02 A and 01 A) uploaded for the owner's plain punch later;
  one stand-in thud set. Nothing else waits for sound.
- World: one flat test strip built by `studio/BuildSlice.lua`, to `base-layout/`: **the manager's own plot** (the plot
  template at its real size, entrance, bag at its front right with its pad and sign, lock pad and board, crate, spots
  with cash pads), **the track start** (the 36-wide track with its start line) in front of it, 40 studs of lane, the
  zone 1 gate, one pad, the log. The hub's other seven plots, the walls and the yard scenery are M3. The builder
  **greyboxes this slice first and measures** the bag pad to the gate, the run to zone 1's fixed pad and the carry
  home, and the sight line from the bag pad over a 4-stud wall to the fixed pad and the windmill, at the default
  camera, and writes the numbers in `team/verification/` against `base-layout.md` section 5.
- The skin table exists from the first line of code: Chomp Frog, the log, the colours, F and its beat table are
  read from `Skins/brickbrawl`.
- Test hooks v1 and the smoke-loop script (see "Test hooks").

| Task family | Role | Model | Why |
|---|---|---|---|
| Ring schedule, burst validation, fight rules, carry and drop, placing, income | scripter | opus | The server decides every result here; client-judged timing is the first exploit target |
| Skin table, module seams, the remotes contract and the burst timing contract | tech-lead | opus | Architecture; both halves of every later feature quote it |
| Burst clock on the client (beats from `t0`, F, the clip seek) | scripter | opus | Same files as the server punch code; one owner keeps the clock in one place |
| Huss button, ring, pips, overlay, counters, prompts | gui-designer | sonnet | Exact values from the kit |
| Voxel builder, Chomp Frog's data from its picture, gloves | modeler-3d | sonnet | Exact pictures and a written group table |
| Chomp Frog's moves, the jab x3 and big third clips | animator-vfx | sonnet | Timings and poses are written out in the style guide |
| F upload list, envelope probe, single-huss cuts, the sync test with the scripter | audio-specialist | sonnet | Measurement against written targets |
| Test strip, stud material both ways | builder | sonnet | Exact recipe |
| First-session times and fight lengths against the tables | game-designer | sonnet | Measuring against tables; tuning waits for M2 |
| Board and checks | producer | sonnet | Upkeep |

**Exit checks.**
- Scripted (gate "Core loop"): a play-mode script plays punch, burst, reach 25 Power, fight, win, carry, log hit,
  grab, place, earn, collect with no errors, and asserts the server owned every result (Power, damage, win, drop,
  place, cash).
- Scripted: taps faster than one cycle allows (over the 20% tolerance), taps away from a bag or fight, a fight
  started while carrying, a tap during a burst (ignored, no penalty), and a place on a spot that is not the
  player's are all refused.
- Scripted: a Good burst is worth 4 punches and a Perfect 8, applied at 0, 0.213 and 0.401 s; a Miss launches no
  burst and the ring restarts after 0.61 s; the combo cycle is 1.81 s at Speed 1 and 1.11 s at Speed 10; fight tap
  counts match the brief's band table at r = 0.5, 1, 1.5, 2, 3 and 5.
- Scripted, **the sync test** (`sound-direction.md`, step 7): 20 bursts at 60, 30 and 15 fps (throttled), logging
  each beat's fire time against `BEAT` and how many times F started. Pass: F started once per burst; three beats in
  order, none dropped, each within one frame of its schedule; the avatar's contact frames and Chomp Frog's hit
  reactions hang off the same beats. Saved in `team/verification/`.
- Scripted: the envelope probe on the uploaded F: each loud part within 20 ms of its beat plus the file's own lead
  (about 10 ms for F). The numbers are reported; if a part is further off, B21 applies.
- Scripted: no fight move delays the ring: Misses and big husses back to back at Speed 10, the next ring starts on
  schedule and a reaction still running is cut by the next result.
- Scripted: the skin check, parts 1 and 2.
- Measured and written in `team/verification/`: seconds to first punch, first Perfect, 25 Power, first fight, first
  boss beaten, first boss placed, against the brief's first-session timings (the brief's numbers, which carry the
  layout's real run and carry times).
- Measured by the builder (**the layout's M1 exit check**): on the greybox slice, the walk from the bag pad to the
  gate, the run to zone 1's fixed pad and the carry home with and without Fast Carry, against `base-layout.md`
  section 5 (139 to 176 studs to the gate by plot; the slice's own plot is the one measured). A difference of more
  than 10% goes to the game-designer and the brief's timings, not quietly absorbed. Also the sight line over the
  4-stud wall from the bag pad.
- Style guide section 13, settled here: which way the normal map faces; `BasePart.Color` tints the `Stud` variant
  (else route B); tiles line up across neighbouring and rotated parts; stud depth at quality levels 1, 5 and 10;
  the 1-stud tile at distance down the 40-stud strip (the full lane is checked at M3); `TileSize` in Offset under a
  `UIScale` and under a 4 px `UICorner` and the round Huss button; Montserrat Black's weight name; boss atlas
  against per-role colour, one picked; Chomp Frog's groups animate without re-pivoting (squat stomper); upload size
  and moderation of the tile images; the jab rhythm against the ring schedule (scripted half; the feel is the
  manager's). From the kit's unverified list: `UIStroke` thickness at each scale.
- On-screen (main session, phone and desktop size): the Huss button, ring and pips beside the UI kit's
  `phone-hud-base.png`; the ring readable and the button clear of the jump button and top bar on the smallest
  phone; Chomp Frog beside its picture and beside an avatar for size; its guard, a hit, its bite on a Miss and its
  defeat at the fight camera; the gloves on an R15 and an R6 avatar; studs on the strip up close and at 40 studs.
- Quality passes: **Function only.** M1 is the proof slice. Its features are in the brief, so they get Friction,
  Feel and Look in M3 to M5 with everything else.

**The manager sees.** A flat studded strip playable in Studio, and for the first time their own plot with its bag,
the track with its start line, a frog and a log: punch, fight, carry, place. `team/manager-todo.md` gets one "look at" item: **the stud proof** beside references 8, 13, 14, 1 and 2
(style guide section 2: nothing else is studded until the manager says yes; until then the `Stud` variant in the
world is a plain stand-in under the same name, so the yes changes one instance). Nothing asks them to stop unless
they started the build with `until M1`.

### M2: All version 1 systems, and the first six bosses
**Goal.** Every rule in "Systems and numbers" works, is decided by the server, and survives leaving and rejoining.
Art is still stand-in boxes except Chomp Frog. Beside it, an art track that touches none of the systems' files
builds the other five pictured bosses so the manager can look at all six before the other 30 are made.

**Built, in three systems waves** (files don't overlap inside a wave; the remotes contract is written first and
read by the qa-exploit-reviewer before waves B and C are coded):
- Wave A, economy and saving: the data layer with a session lock (14) and the schema below; buying Punch Strength
  (30 levels) and Punch Speed (10 levels) and the six bag tiers as model ids (2); Auto Punch and Perfect Auto Punch
  on the bag pad (Good or Perfect bursts at the owner's Speed, never in fights, never offline; the hand-tap rule,
  B20); all six zones' pads, rolls, timers and per-player "beaten this roll" (5); the saved zones-beaten list
  written on fight wins (4, 14); all six hazards as server-clock paths with stand-in shapes (6); spots, pick up,
  duplicates, sell, swap, the delivery crate (7); income from time stamps, the 2-hour pad cap (8); boss upgrades to
  level 20 (9); offline earnings (11); rebirth as one save operation: the reset list, the kept list (passes,
  tickets, Shield Breaker charges, the zones-beaten list, settings, first-session flags), the buyer's own bought
  bosses at their levels placed back on spots lowest first and the rest to the crate, pad cash reset, cash set to
  the bought-cash number (12); the bought mark (source and buyer) and the bought-cash rule (earned cash spent
  first).
- Wave B, other players: plot assignment for 8; stealing for every boss including bought ones, the owner's punch
  (plain punch, 0.8 s, single huss), chase speed 20 studs/s, returns, the 60 s safe time after a steal (10); the bought-boss policy guard (a boss with a bought mark, spin or Starter Pack Ram, cannot be lifted when `IsPaidItemTradingAllowed` is false for the thief or the owner, or a failed check: the Steal prompt greyed "Can't be stolen"; TEAM CALL 38); the bought mark moving with a stolen boss unchanged; Quick
  Hands (1.0 s hold) and Iron Grip (stagger, then a drop on a second hit within 10 s); the lock shield, cooldown,
  push-out, the joining shield, Instant Shield's unbreakable shield, the per-base 5-minute break timer (10); the
  transfer as one operation with a boss uid.
- Wave C, Robux: the one receipt handler, purchase ids, pass checks on join and after purchase; all **10 passes**
  (Auto Punch, Perfect Auto Punch, 2x Power, 2x Cash, Fast Carry, Long Lock, Extra Spots, Quick Hands, Iron Grip,
  and the Starter Pack built as a pass) and **9 developer products** (four cash packs, three spin bundles, Instant
  Shield, Shield Breaker); Perfect Auto Punch offered in the game only to Auto Punch owners and working alone when
  bought on the web page; cash pack quotes with a key; the Lucky Spin from the one odds table with the zone picker
  read from zones beaten; Shield Breaker bought at the shield with its checks and its stored charge; the
  `PolicyService` checks (below); the Starter Pack mark and its once-a-session offer after the first upgrade. All
  against stand-in ids (0 means no call) until the manager's ids arrive.
- All waves: every screen as a plain working version (function, not the kit yet): boss panel, bag panel with the
  Perfect Auto Punch row, shop with 19 cards and the bought-cash well, Lucky Spin with its odds list, rebirth with
  the brief's text and the player's numbers and its second confirm, "While you were away", Starter Pack offer, steal
  alerts (with the BOUGHT tag variant) and the "shield broken" alert, the Break shield button with its greyed
  reasons, confirm dialog, toasts and prompts, settings. The first-session arrow and the **12 funnel events**
  (`Joined` to `Zone2BossPlaced`, with `FirstPerfectLanded`), logged on the server. All bindings in the brief's
  controls table. The avatar's other five clips (flinch, carry hold, steal lift stretched to the hold, knockdown,
  stun).
- **Art track, the first six bosses** (parallel, its own files): Snap Scorpion (tailed striker), Bit Shark (rearing
  swayer), Frost Byte (biped bruiser), Ember Drake (tailed striker; the dark-basalt rock-club tail, no flame) and
  Star Golem (biped bruiser), each from its approved picture, with its groups, renders of guard and signature impact,
  and the moves of the four body types the six cover (squat stomper from M1, tailed striker, rearing swayer, biped
  bruiser) plus their six signatures, the scorpion's tail sting then pincer punch first. Triangle counts of the six
  at the pictures' density.

| Task family | Role | Model | Why |
|---|---|---|---|
| Data layer, session lock, schema, migration, transfer, receipt records | data-engineer | opus | Lost or doubled saves and doubled bosses are the costliest bugs in the game |
| Systems 2 to 13 on the server | scripter | opus | Server authority, stealing, purchases, rebirth |
| Remotes contract review before waves B and C; review after | qa-exploit-reviewer | opus | Exploit review |
| Curve measurement and tuning inside what the brief leaves open | game-designer | opus | Economy numbers |
| Plain screens, prompts, the first-session arrow | gui-designer | sonnet | Function versions of written screens |
| Five bosses from their pictures | modeler-3d | sonnet | Exact pictures; goes up to opus if a model fails the match twice |
| Four body types' moves, six signatures, five avatar clips | animator-vfx | sonnet | Written poses and timings |
| Match review of the six against `creatures.png` | art-director | opus | Judgment on a manager-approved look (fable when available) |
| Board and checks | producer | sonnet | Upkeep |

**Exit checks.**
- Scripted (gate "Systems"): one passing check per system 1 to 14, listed by number in `team/verification/`.
- Scripted, saving: save, leave, rejoin gives the same profile; a second session cannot take a locked profile; a
  simulated shutdown saves; a schema version bump migrates a saved profile; offline earnings with the clock hook
  at 30 s (nothing shown), 10 minutes, and 3 hours (capped at 2 hours a pad); content is saved by id only.
- Scripted, stealing (a stand-in second player through a module seam, then two Studio clients): hold cancelled by
  moving or by the owner's punch; teleporting or over-speed drops the boss; the owner's punch returns it; a
  successful steal moves the boss with its level and its bought mark unchanged; the boss uid never exists in two
  profiles after any sequence, including a forced error between the two writes; a shielded base pushes out and
  cancels; a bought boss shows a working Steal prompt while both flags are true; a bought boss (spin or Starter Pack Ram) shows the greyed prompt and a forced steal request is refused when the policy hook sets `IsPaidItemTradingAllowed` false for the thief, for the owner, or fails; an earned boss stays stealable under the same hook.
- Scripted, Robux: the same purchase id granted once; a cash pack grants the quoted amount and refuses a stale
  key; the spin's results over 100,000 server rolls match the table within tolerance; the Spin screen's list is
  read from the same table; the zone picker shows only zones on the zones-beaten list and "Beat a boss first" when
  it is empty; with the restricted hook on, the Spin card, screen and spin products are gone and the rest of the
  shop is unchanged; no prompt opens during a fight, a carry, a steal alert or a "shield broken" alert; never two
  prompts; Perfect Auto Punch is offered only to Auto Punch owners and works for a web-page buyer without Auto
  Punch.
- Scripted, attacking set: Quick Hands halves the hold; Iron Grip needs two hits inside 10 s and does nothing
  against hazards, falls or the shield; Shield Breaker refuses a joining shield, an Instant Shield and a base broken
  in the last 5 minutes, checks the 15 studs, and stores a charge when the purchase arrives too late; the charge is
  used free on the next press and kept through rebirth.
- Scripted, rebirth: after a rebirth, exactly the brief's reset list is reset and exactly its kept list is kept;
  the buyer's bought bosses come back at their levels, placed lowest spot first, the rest in the crate, pad cash
  cleared; a bought boss the player stole from someone else is reset; a bought boss the buyer stole back is kept;
  cash equals the bought-cash number, which followed the brief's rule through a scripted run of buy, earn, spend
  below it, rebirth; zones beaten survive. The confirm screen shows the brief's text with the player's own numbers.
- Scripted, the bought mark: only the Lucky Spin and Starter Pack grants set it (source and buyer user id); no
  remote can write it or `boughtCash`.
- Scripted, first session: from a fresh profile a scripted player reaches `FirstBossUpgraded` and
  `Zone2BossPlaced`; each of the 12 funnel events fires once, in order; the arrow is gone after the first upgrade;
  the Starter Pack offer shows once, after the panel closes.
- Scripted, the six bosses: each has its body type's groups and pivots, named exactly; one set of offsets drives
  the smallest and the largest boss of a body type without re-pivoting; triangle counts reported against the tier
  budgets (the picture wins if they break them; B6).
- Measured by the game-designer and reported against the brief's tables: Power per second at Speed 1 and 10
  (2.98 and 4.86 at Strength 1), fight lengths and win rates per band, income at minutes 3, 10 and 30 of a scripted
  run, time to zone 2. Differences are reported, and tuned only inside what the brief leaves open.
- Scripted: the skin check, all three parts.
- On-screen: the odds list on the Spin screen before any Buy or Spin button is active; the rebirth confirm's
  wording; the steal alert with and without the BOUGHT tag; the greyed "Can't be stolen" prompt; each at phone
  size. The six bosses' renders beside `creatures.png`, same angle, same order.
- Quality passes: **Function**, for every system.

**The manager sees.** The whole game playable in boxes on the test strip grown to six plain zones: every rule
works, nothing is pretty. `team/manager-todo.md` asks for the pass and product ids if they are not in yet, and adds
the second "look at" item: **the first six bosses**, rendered beside their pictures (style guide section 5; the
other 30 are not made until the manager says yes). The build does not stop for it: M3 starts with the world and
UI, and the 30 follow the yes.

### M3: World and UI
**Goal.** It looks like the picked look: the stud world, all 36 voxel bosses fighting with their own bodies, six
hazards, six bags, and every screen built from the approved UI kit.

**Built.**
- World, by `studio/BuildWorld.lua` and one dressing table per zone: **the full hub, to `base-layout/`**: the walled
  yard (412 x 234 inside; back and side walls 16 tall, front wall 4 tall, the invisible blockers, scenery in the back
  corners and along the front wall), **8 identical plots in a U** (4 on the back wall, 2 on each side, one plot
  template turned to face the yard and never mirrored; one fence look, kerb white; the name board, bag frame, plinth,
  bag pad and bag sign, lock pad and lock board, delivery crate and spots-full sign, 17 spot positions as two
  columns, an aisle and a back row, with cash pads on the aisle side, ghost outlines for the locked rebirth spots,
  lock shield walls), the track and start line in the yard, the 36-stud lane with kerbs and arrows every 40 studs,
  **the lane as a walled corridor with a centre line in each zone** (style guide, "The lane"), six zone gates (zone
  1's is the hub's arch with its two-line sign; the others carry their own second line), six zones with their **48
  props (8 a zone, the landmark among them)**, each landmark at least 40 studs tall and visible from the gate before
  it, 24 boss pads with countdowns, stud water, the `Clouds` sky. Every measure the builder changes from the
  approved layout is reported with the measured run times. The layout's TEAM CALLs (`base-layout.md` section 8, 1 to
  15: hub size and walls, the U and the fill order 1, 8, 4, 5, 2, 7, 3, 6, one template never mirrored, the track and
  start line, the gate sign's second line, the invisible blockers, the spot arrangement, bosses facing the aisle, the
  crate in the front-left corner, the lock board and its buttons hidden during alerts, ghost spots, income on name
  tags, the fallback spawn and the spawn facing the bag, the world-sign text rule, the wall colour) are carried
  into `team/decisions.md` at M0 by reference.
- Hazards: the six (Rolling Log, Tumble Cactus, Swinging Anchor, Sliding Ice Block, Lava Burst Row, Orbit Meteor)
  with their striped tracks, built to the style guide's hazard rule, on the server paths from M2.
- Bag tiers: six bag models (Starter, Sand, Plank, Ice, Lava, Star), swapped every five Strength levels.
- Bosses: after the manager's yes on the six, **the other 30**, each reviewed by the art-director against the
  originality rule and the six pictures' design language before its data file is written; imported in batches; set
  up by script; a render of each real mesh for the UI (boss panel, shop, Spin screen, Starter Pack offer) replacing
  the kit's stand-in portraits and "MODEL RENDER" wells.
- Boss moves: the three body types the six do not cover (charger, flyer, tentacled floater) and the 30 remaining
  signature moves, all as tween tables on the moving groups; the 0.3 s watcher limit; fight moves only within 150
  studs; the half idle at about 15 updates a second at a random phase.
- Lighting: the base table and the six client-side zone shifts; the phone fallback.
- UI: all 13 screens and the HUD parts rebuilt from `ui-kit/` in code, with the stud tile, tokens from the skin
  table, one `UIScale`, safe areas, glyphs per input. The numbers on screens come from config, not from the kit
  (the kit's bag panel showed old Speed numbers; fixed in the kit's last rebuild, verify at M0).
- Icons: the **64 approved icons** of board 04 (`ui-kit/04-icons.png`), uploaded to the group and checked in place
  on HUD screenshots over the Ice Blocks ground and the lane. No new icon is made; one that fails the in-place check
  is remade with board 04 as its reference (allowance below).

| Task family | Role | Model | Why |
|---|---|---|---|
| World, plots, props, landmarks, hazards, bags, placing scripts | builder | sonnet | Exact recipes and sizes |
| The 30 bosses' data files and builder runs, renders | modeler-3d | sonnet | Written design language and approved six as reference |
| Originality and design-language review of the 30; Look review of zones, bosses, screens | art-director | opus | Judgment (fable when available) |
| Three body types' moves, 30 signatures, distance and update-rate settings | animator-vfx | sonnet | Written poses |
| Lighting, zone shifts, fallback | lighting-specialist | sonnet | Written table, tuned against references |
| Screens from the kit, icons in place | gui-designer | sonnet | Approved kit |
| Binding screens to M2 systems, zone shift triggers | scripter | sonnet | Wiring to an existing contract |
| First full measurement, budgets, B6 | performance-optimizer | opus | Budget decisions that every later art task obeys |
| Asset inventory against `team/assets.md` | any | haiku | File check |
| Board and checks | producer | sonnet | Upkeep |

**Exit checks.**
- Scripted: counts. The hub (4 walls at 16, 16, 16 and 4 tall, the gate opening, the track and start line); 8 plots in
  the U at the positions in `base-layout.md` section 2, each with 1 bag, 17 spot positions with cash pads on the
  aisle side (the two pass spots absent until the pass; ghost outlines for the rebirth spots), 1 lock pad, 1 lock
  board, 1 shield, 1 crate, 1 spots-full sign, 1 name board; every plot's spawn facing its bag; 6 gates; 24 pads at the planned distances; 6 hazards with tracks; 48 props placed by name from the
  skin folder, 6 of them landmarks at least 40 studs tall; 36 boss models each with its body type's groups, named
  exactly, pivots where they turn, cube size per tier, no stud material; 6 bag models; 1 glove model.
- Scripted: every built part outside the style guide's smooth list carries the `Stud` variant; no colour on any
  part or UI object that is not in the token table; no Terrain water or grass; no text under 14 px at phone scale;
  no touch target under 44 px; the Huss button never under 96 px.
- Scripted: every asset id in the skin table loads (`ContentProvider:PreloadAsync`), belongs to the group, and
  `team/assets.md` lists each with what it is.
- Scripted: hazard hit checks still pass on the real shapes; each hazard leaves a way through at every moment of
  its cycle (sampled) and shows its position 0.6 s ahead.
- Scripted: run times measured gate to gate and base to each fixed pad, against the brief's 5 s (zone 1) and 40 s
  (zone 6).
- Measured by the builder (**the layout's M3 exit check**): from all 8 bag pads, the walk to the gate, the run to
  zone 1's fixed pad and the carry home with and without Fast Carry, against the layout's table (8.7 to 11.0 s to the
  gate; run 11.4 to 13.7 s; carry home 15.2 to 18.3 s); the owner's catch radius against `base-layout.md` section 5
  for the corner neighbour (plots 2 and 3, 6 and 7); the sight line over the 4-stud front wall from every bag pad to
  the fixed pad's Power number and the windmill; world sign text sizes on a phone; an invisible blocker keeps a player
  out of every fence and over the front wall except through an entrance or the gate; the lane corridors leave a
  carrier no way round a hazard.
- Scripted: every boss plays guard, three hit sizes, its signature, last heart and gloat, defeat, carry rock and
  half idle with no error, and no fight or signature move on a placed or carried boss; nothing drawn over the Huss
  button; the next ring starts on schedule during every move.
- Scripted: the skin check, all three parts.
- Performance, first measurement (numbers into `team/verification/`): part count, triangle count and memory of the
  full map; frame time in the device emulator with 8 plots holding 17 bosses each (136 placed, half idle), 24 on
  pads with fight moves within 150 studs, and 8 carried, all at their heaviest tier and at the pictures' cube
  density. Budgets for M5 are set from this (B6).
- Style guide section 13, settled here: every lighting, atmosphere and post-effect number and the zone tints, tuned
  against references 8 and 12 to 14; whether `LightingStyle` and `PrioritizeLightingQuality` exist on this Studio;
  Space Baseplate at `ClockTime` 20 (kept only if a phone screenshot stays as readable as Brick Meadow, else
  daytime); the 1-stud tile down the full lane at phone size (a 2-stud ground tile if it shimmers); the UI tile at
  16 px and whether the 30% dark L is too busy under text; spot, cash pad, lock pad, crate and boss pad sizes and the
  plot layout for 17 spots; Magma Hydra read as cracks on three matte heads; hazard looks against "always leaves a
  way through"; board 04 icons in place on real screenshots; the 30 designs against the originality rule; each body
  type's groups animate without re-pivoting (charger, flyer, floater); triangle budgets with 136 placed. From the
  kit's unverified list: top bar and safe-area insets in the emulator, gamepad glyphs and selection order on every
  screen, the shop's instance count.
- On-screen (gate "World and UI", main session): every screen as a full screenshot beside its UI kit export
  (`phone-*.png`, `desktop-*.png`), at phone and desktop size; nothing default-grey; each zone from its gate with
  the next landmark in view; the HUD over the Ice Blocks ground and the lane; each of the 36 bosses on a pad, on a
  spot and carried, and its signature at the fight camera; the shield up, down, Instant (gold rim) and broken; each
  hazard mid-cycle.
- Quality passes: **Function** for the new work, and **Look** (art-director: each zone, each boss, each screen;
  open mismatches go on the board for M5).

**The manager sees.** The real game: studs, six zones, 36 creatures that fight back, the real screens. Silent
except for the huss and the stand-in thuds.

### M4: Feel and sound
**Goal.** Every action answers back with motion and sound, to the style guide's motion and effects rules and
`sound-direction.md`.

**Built.**
- Motion and effects (animator-vfx): the avatar's seven clips polished on R15 and R6; cube bursts (6 to 8 a Good,
  10 a Perfect, 12 a big huss), stud confetti, the impact star, number count-ups and fly-to-counter; panel and
  button motion; placing thump; the shield raising, dropping and breaking; the spin reveal; the rebirth celebration;
  camera shake only on a clean big huss and a boss beaten, inside 0.3 studs for 0.15 s.
- Sound (audio-specialist): the sound map from `vault/templates/sound-map.md` covering every row of
  `sound-direction.md`, "Every action and screen in the brief", including its silences; every family sourced
  (earshot, Creator Store, the manager's recording), measured, levelled, put on a listening page with three
  candidates per slot, uploaded to the group once picked, wired through the skin's `Sounds` table into the four mix
  groups. In particular: **six thud sets** (one per bag tier, 6 to 8 takes each, `PlaybackSpeed` stepped 1.04 to
  0.96 inside a tier); the three body-hit sizes; **the boss scheme of 19 file sets**: 6 zone voices (call, grunt,
  defeat), 7 body-type attacks (wind-up and impact), 6 zone element layers, with the tier pitch table, the second
  beat of two-beat moves, the heart-lost drop and the fight-lost tumble; carry footsteps on six surfaces; the six
  hazard sounds; the steal and shield **alert family, which shares no sound with the shop or the cash family**; the
  fatigue rule; Auto Punch and Perfect Auto Punch at 6 dB lower, and the soft thinned sting on Perfect Auto Punch's automatic bursts (`sound-direction.md`); other players'
  bursts capped at two; music starting at the player's first spawn (player in `ReplicatedFirst`), rotation and
  ducking; ambience beds and zone crossfades; the settings sliders saved. Slots the manager has not picked yet run
  on the audio-specialist's first candidate, marked `PROVISIONAL`.

| Task family | Role | Model | Why |
|---|---|---|---|
| Effects, clip polish, UI motion with the gui-designer | animator-vfx | sonnet | Written limits |
| Sound map, sourcing, measuring, listening pages, uploads list, wiring | audio-specialist | sonnet | Written direction; measurement |
| Hooks for effects and sounds, mix groups, ducking, caps | scripter | sonnet | Wiring to the contract |
| UI motion states | gui-designer | sonnet | Written motion table |
| Board and checks | producer | sonnet | Upkeep |

**Exit checks.**
- Scripted (gate "Feel and sound"): the feedback list in `quality-bar.md` as a table for this game (main action,
  success, failure, "can't do that yet", earning, purchase, level-up, rare boss, rebirth, UI open, close, press),
  each row naming what is seen and heard, each verified to fire.
- Scripted: every sound id loads and fires once per event and belongs to the group; one F per landed burst at
  Speed 1, 5 and 10, none on a Miss, never two for one ring, never above 1.2 bursts a second; the fatigue drop after
  12 bursts and its recovery after 4 s; Auto Punch at the lower level with no sting, Perfect Auto Punch at the lower level with the soft sting on bursts 1, 4, 7 and so on (every 6th after the fatigue drop) and never the hand sting's level; the
  right thud set and speed step for each Strength level 1 to 30; one attack per body type and one voice per zone at
  each tier's pitch over all 36 creatures; nothing on a placed boss's half idle; the steal ratchet heard by the
  thief only, alerts by the owner only (the same for a bought boss), no shop, coin or reward sound inside an alert;
  other players' bursts capped at two; shop and spin sounds reach the buyer only (two clients); every sound sits in
  its mix group at its volume; music ducks and returns; settings save.
- Scripted: **the sync test from M1, run again** with the real thuds, body-hit sounds and boss reactions on the
  beats, at 60, 30 and 15 fps.
- Scripted: particle counts within the style guide's phone limits (24 a hit, 60 a celebration); no effect uses a
  soft texture, a PointLight or a screen-wide flash.
- Scripted: avatar animations play on every client (a second client sees the jabs, the carry and the steal lift)
  and on the owner's own screen.
- Measured: every uploaded file's length, lead silence, peak and loudness against the mix table.
- On-screen: each effect once at phone size; pressed states on every button; panels open and close with motion.
- Quality passes: **Feel**.
- `UNVERIFIED` by design: how anything sounds. The listening pages and a numbered in-game sound checklist go to
  the manager.

**The manager sees.** The game moving and making noise. Listening pages wait in `team/manager-todo.md` under
"listen to"; answering them is a letter per slot.

### M5: Quality passes
**Goal.** Remove everything an agent can catch, so the manager's playtest is spent on fun, pacing and sound.

**Built.** Fixes only. Nothing new.

**Roles and what each does.**
- gui-designer (sonnet) and game-designer (opus): the first-time walk-through on the smallest phone in the device
  emulator, touch, then gamepad (Controller Emulator) and keyboard; taps and seconds to the first reward; every
  hesitation is a finding; the action x input table has no empty cell.
- art-director (opus; fable when available): the Look review of the whole game against `team/style-guide.md`, the
  UI kit and the six approved pictures, including the Never list.
- qa-exploit-reviewer (opus): stealing and client-judged timing first, then the bought mark and its buyer id, the
  paid-item trading check on steals, the bought-cash number, Shield Breaker receipts and charges (the brief's
  Caution 6 list), then every remote, the receipt handler, the save and transfer paths, the test hooks list (each
  gated to Studio, each harmless if saved into the place).
- performance-optimizer (opus): the M3 measurement repeated on the finished game against the budgets; phone memory;
  server heartbeat with 8 simulated players punching, carrying and stealing; network load of hazard and pad state
  and of burst and fight results sent to nearby clients.
- auditor (opus; fable when available): `/audit` against the vault playbooks.
- scripter: fixes (opus for anything the server decides, sonnet for UI). producer (sonnet): tracks findings to
  closed, gathers every `UNVERIFIED` line.

**Exit checks.**
- Gate "Quality": the Friction walk-through passes; the Look review has no open mismatch; `/audit`, the exploit
  review and the performance review have no must-fix left.
- Scripted: every check from M1 to M4 runs again and passes (one command, `studio/CheckAll.lua`).
- Scripted: the skin check, all three parts, final. A fail here is a must-fix.
- Scripted: a policy pass on the shop: odds on screen before purchase and totalling 100%; restricted players see
  no spin; no countdown, struck-out price or urgent wording anywhere in the UI strings; nothing in the shop or on a
  tag says a bought boss is safe from stealing; the rebirth confirm says what is kept and reset in the brief's words.
- Style guide section 13, settled here: triangle budgets with a full server, final; frame time of 136 placed bosses
  on the half idle and of fight moves within 150 studs, final; the phone cost of Bloom, DepthOfField and the zone
  tweens as far as the emulator shows (a real low-end phone is on the two-device list).
- On-screen: the walk-through is done on screen by the main session from the specialists' check lists.
- Quality passes: **Friction**, and **Look** closed.

**The manager sees.** No change they were not told about; a shorter list of known gaps.

### M6: Release kit and handoff
**Goal.** Hand the manager a game to playtest and everything needed to publish it themselves.

**Built.** The game page kit: the game icon and three thumbnails made from real screenshots of the built game,
improved in Higgsfield image to image and finished in FigCraft; the **group icon remake** (one glove landing on a boss face, composed for a circle, from real renders; the first icon is already uploaded); title options, description and genre from `game-page.md`; the 19
pass and product icons at dashboard size (from board 04). Each checked against the `game-page/` concepts and showing
only things that exist in the game. `team/handoff.md` from the template: how to play, a 15-minute playtest script
built around the brief's five playtest questions, a silent-observation sheet for a first-time player, what was
built against the brief, every team call, the manager's steps, known gaps, the two-device checklist, what it cost.

| Task family | Role | Model | Why |
|---|---|---|---|
| Screenshots, Higgsfield image to image, FigCraft finish, page text | live-ops | sonnet | Written concepts and rules |
| Review of the kit against the content tables and the style guide | art-director | opus | Judgment |
| Handoff file, two-device checklist, cost summary | producer | sonnet | Gathering |

**Exit checks.** Gate "Handoff": `team/handoff.md` complete; the kit made from real screenshots; every lock
released; `team/build-state.md` lists anything that exists only in the place; the manager is asked to save.
Quality passes: pass 5, **the manager's playtest**, is the handoff itself.

**The manager sees.** The game, the handoff file, the game page kit and group icon, and one checklist to run on two
devices after they publish privately.

## Asset list
Everything to be made, with its source and method. Uploading anything on this list **to the group** is covered if
the manager ticks that box in `approval.md`; anything not on it needs a yes. Only things in the brief's content
tables get art. Credits are Higgsfield credits.

Credit basis (`concepts/higgsfield-log.md`): this pitch was charged 2 credits for a 2k image (16:9 or 1:1, high), 1
for a 1k transparent image or a 1k sheet of nine icons, 1.75 for a 2k transparent sheet of 16 icons. Prices change;
each cost is estimated with the connector before it is spent and reported with the balance after.

### World (0 credits)
| Asset | Count | Source and method | Uploads | Milestone |
|---|---|---|---|---|
| `Stud` MaterialVariant: colour, normal and roughness maps | 3 images | Script, from the style guide's height map (`style/make_stud_refs.py`) | 3 images | M1 |
| UI stud overlay tile | 1 image | Same script | 1 image | M1 |
| A 2-stud ground tile, only if the 1-stud tile shimmers down the lane | 0 to 3 images | Same script | 0 to 3 | M3 |
| Base pieces: bag frame and plinth with bag pad and sign, spot with cash pad, lock pad, lock shield, delivery crate, plot border with the name board, **lock board, spots-full sign, ghost spot outline** | 9 kinds, x8 plots (the manager's own plot at M1) | Roblox parts, placed by `studio/BuildWorld.lua` to `base-layout/` | none | M1 (one plot), M3 |
| Hub pieces: back, side and front walls (16, 16 and 4 tall) with the invisible blockers; zone 1's arch with its two-line gate sign; the track with its start line; yard scenery (trees, bushes, flowers) | 1 hub | Roblox parts, built by script (the arch and sign reused for the five later gates, each with its own second line) | none | M1 (track and start line), M3 |
| Zone lane corridors: wall and centre-line dashes per zone | 6 zones | Roblox parts, built by script to the style guide's table | none | M3 |
| Bag tiers: Starter, Sand, Plank, Ice, Lava, Star | 6 | Roblox parts, built by script to the style guide's table | none | M3 |
| Lane, kerbs, lane arrows; 6 zone gates; 24 boss pads with countdown plates | | Roblox parts, built by script | none | M3 |
| Zone props: 48, 8 a zone, the landmark (bold) among them. 1 Brick Meadow: round block tree, bush pair, flower cluster, picket fence, hay block, striped market stall, **windmill**, pond. 2 Sand Blocks: **stepped pyramid**, cactus, sandstone arch, clay pot stack, palm, tent with striped awning, dune ridge, obelisk. 3 Pirate Plates: **brick ship**, dock with posts, palm, treasure chest, barrel stack, cannon, rope bridge, lighthouse. 4 Ice Blocks: ice crystal cluster, snow-capped pine, igloo, snow block wall, frozen pond, icicle arch, sled, **snow fort tower**. 5 Lava Bricks: **stepped volcano**, lava channel, basalt column cluster, forge with chimney, chain bridge, bone pile, cracked ground plates, ember brazier. 6 Space Baseplate: **rocket on a pad**, crater, satellite dish, moon rock cluster, star pylon, dome module, floating plate steps, antenna mast | 48 | Roblox parts, one build function per prop, scattered by the zone's dressing table | none | M3 |
| Hazards: Rolling Log, Tumble Cactus, Swinging Anchor, Sliding Ice Block, Lava Burst Row, Orbit Meteor, each with its striped track | 6 | Roblox parts, built by script, moved on the server clock | none | M3 |
| Water | 1 recipe | Stud-tiled parts, two planes | none | M3 |
| Sky | 1 | Roblox's `Clouds` object and default sky (a skybox asset would need the manager's yes) | none | M3 |
| World markers: lane arrows, countdown plates, the dropped-boss timer plate, name tags with tier chip, BOUGHT tag and Power number | 7 kinds (brief, Markers) | Parts and `SurfaceGui`/`BillboardGui` built to the UI rules | none | M2 to M3 |

Part counts, from `base-layout.md` section 7 (estimates, `UNVERIFIED` until the performance-optimizer measures on a
weak phone): about 210 parts a plot (fence built once and unioned per side, spots and cash pads 51, cash stacks as one
swapped MeshPart per pad, about 100 for 17 bosses), **about 1,700 for 8 plots, plus about 60 for the walls, track,
gate and scenery**. Four SurfaceGuis a plot (name board, bag sign, lock board, spots-full sign); no SurfaceGui per
spot; BillboardGuis only per occupied spot (distance-limited), per cash pad (owner only), the crate count and the
shield timer. Locked rebirth spots are one flat part each, and nothing exists for pass spots not yet bought. All 8
plots stay streamed in (B6 decides streaming at the M3 measurement).

### Bosses (0 credits required)
36 voxel bosses from layer data through one headless Blender builder (`tools/blender/build_boss.py` plus one data
file per creature id), FBX out with **one mesh per moving group**, the Studio 3D importer in (main session, computer
use), one setup script that names the groups, sets pivots, welds Neon cubes to their group and applies colour.

- **Size and cubes** (style guide section 5): about 20 cubes tall on a Common (cube about 0.2 studs, 4 studs high)
  up to about 34 on a Mythic (about 0.41 studs, 14 studs high). This is finer than the earlier plan's 0.5-stud cube,
  and **may break the tier triangle budgets (600 to 6,000)**: the six are counted at M2, and if they do not fit, the
  picture wins and the performance-optimizer measures a raised budget (B6).
- **The six with approved pictures** (Chomp Frog, Snap Scorpion, Bit Shark, Frost Byte, Ember Drake with its
  rock-club tail, Star Golem) are built to match `concepts/brick-brawl/creatures.png` and shown to the manager
  before the other 30 are made.
- **Moving groups** (style guide, "What the modeler delivers"): `Body`, `Head`, `FistL`, `FistR` for all; plus `Sig`
  (bipeds that need it, squat stompers, Sun Sphinx); `TailA`, `TailB` (tailed strikers); `Upper` (rearing swayers;
  Magma Hydra's `HeadMid`); `WingL`, `WingR` (flyers); `Legs` (floaters; Tidal Kraken adds `FistL2`, `FistR2`).

| Zone | Common | Uncommon | Rare | Epic | Legendary | Mythic |
|---|---|---|---|---|---|---|
| 1 Brick Meadow | `z1_t1` Chomp Frog | `z1_t2` Bop Bunny | `z1_t3` Bumble Brute | `z1_t4` Headbutt Ram | `z1_t5` Timber Bear | `z1_t6` Bloom Stag |
| 2 Sand Blocks | `z2_t1` Roll Beetle | `z2_t2` Snap Scorpion | `z2_t3` Prickle Gecko | `z2_t4` Thump Camel | `z2_t5` Dune Cobra | `z2_t6` Sun Sphinx |
| 3 Pirate Plates | `z3_t1` Pinch Crab | `z3_t2` Plunder Parrot | `z3_t3` Bit Shark | `z3_t4` Tangle Squid | `z3_t5` Cannon Turtle | `z3_t6` Tidal Kraken |
| 4 Ice Blocks | `z4_t1` Waddle Penguin | `z4_t2` Tusk Walrus | `z4_t3` Flurry Fox | `z4_t4` Frost Byte | `z4_t5` Glacier Mammoth | `z4_t6` Aurora Owl |
| 5 Lava Bricks | `z5_t1` Cinder Newt | `z5_t2` Ash Bat | `z5_t3` Coal Boar | `z5_t4` Molten Gorilla | `z5_t5` Ember Drake (rock-club tail, no flame) | `z5_t6` Magma Hydra |
| 6 Space Baseplate | `z6_t1` Moon Mite | `z6_t2` Orbit Jelly | `z6_t3` Comet Hound | `z6_t4` Nebula Ray | `z6_t5` Void Mantis | `z6_t6` Star Golem |

| Asset | Count | Source and method | Uploads | Credits | Milestone |
|---|---|---|---|---|---|
| Boss group meshes | 36 bosses x 4 to 7 groups: about 185 group meshes, plus a Neon mesh on groups that glow | Headless builder. One FBX per boss (36 imports) unless the importer keeps groups apart in a per-zone file (6); proven at M1 (B5) | about 185 to 260 meshes on the atlas route; several times more on the per-colour fallback (one mesh per colour role per group), which is why B4 is decided at M1 | 0 | M1 (1), M2 (5), M3 (30) |
| Boss atlas (if the atlas route wins at M1) | 1 image | Script | 1 image | 0 | M1 |
| Boss pictures for the boss panel, shop, Spin screen and Starter Pack offer | 36 | Headless Blender render of the real mesh on a clear ground. Never generated art | 36 images | 0 | M2 (6), M3 (30) |
| Guard and signature-impact renders per boss, for review | 72 | Same renders | none (review only) | 0 | M1 to M3 |
| Concept sheets for the 30 bosses with no picture, for the art-director's originality review | 6 sheets (one per zone) | Higgsfield image with `creatures.png` as the style reference; optional, the builder can also be reviewed from its own render | none | 12 (optional; 2 a sheet) | M3 |

### Boss and avatar animation (0 credits)
| Asset | Count | Source and method | Uploads | Milestone |
|---|---|---|---|---|
| Body-type move sets: idle, guard, hit reaction (Good, Perfect, big huss), attack template, gloat, defeat, half idle | 7 body types x 7 moves | Tween tables in `Shared/Moves/` (structure, fractions of H), played on the moving groups on each client. No `Animator`, no keyframe assets | none | M1 (squat), M2 (tailed, rearing, biped), M3 (charger, flyer, floater) |
| Signature moves, one per creature | 36 | Same, applied to each creature's signature part; about 0.45 s; two beats at most heard | none | M1 (1), M2 (5), M3 (30) |
| Carry rock | 1, shared | Same | none | M1 |
| Avatar boxing gloves | 1 model (mirrored left and right) | Headless voxel builder: Huss red `#E02A2A` with the yellow cuff, about head size; put on at spawn, following each hand on R15 and R6 | 1 to 2 meshes | M1 |
| Avatar clips: jab x3, big third punch, flinch, carry hold, steal lift, knockdown, stun | 7 | animator-vfx, on an R15 dummy (Blender, or Studio's animation editor), published **under the group** (an experience plays animations its owner owns; confirmed at the first upload), main session through computer use. `TEAM CALL` B14 on the method | 7 animations | M1 (2), M2 (5) |
| Effects: cube burst, stud confetti, impact star, trails, dust | 5 shapes | Parts and hard-edged square particle textures made by script | up to 3 images | M4 |

### UI art and icons
All screens are built in code from `ui-kit/`; the only UI images are the stud tile, the icons and the boss
pictures. **The icon set is made and approved:** the 64 icons on board 04 (`ui-kit/04-icons.png`, as listed in
`ui-kit/README.md`): stats 8, HUD and actions 20, status 11, zone badges 6, shop products 19 (Perfect Auto Punch is
the 19th, made in the kit's final pass). The manager accepted them as they are on 2026-11-25 ("icons, all
amazing"). No other icon is made.

| Asset | Count | Source and method | Uploads | Credits | Milestone |
|---|---|---|---|---|---|
| Icon set (board 04) | 64 | Made in the pitch (`ui-kit/src/icons/` and `concepts/brick-brawl/parts/`), cut by `ui-kit/src/cut_icons.sh` | 64 images | 0 | M3 |
| Remakes of icons that fail the in-place check on real screenshots | 0 to 4 | Higgsfield, one at a time at 1k transparent, board 04 as the reference | one each | up to 4 (1 each, charged in this pitch) | M3 |
| Font | 1 | Montserrat, built into Roblox | none | 0 | M1 |
| Robux glyph | 1 | Roblox's own | none | 0 | M3 |

### Sounds (0 credits; Higgsfield audio is optional and not planned)
From `sound-direction.md` as it stands (burst voice F; the 19-file-set boss scheme). No Creator Store id is named in
the pack; ids are found, measured and offered on listening pages during M4. Creator Store sounds are not uploads.
Counts are estimates until the sound map exists.

| Family | What | Source | Uploads (est.) | Milestone |
|---|---|---|---|---|
| The huss | F (`f_group1_no_breath.wav`, the burst voice), 02 A (single huss, levelled), 01 A (single huss, as cut) | The manager's recording, trimmed and levelled only | 3 | M1 |
| Punch layer | Six thud sets (one per bag tier), 6 to 8 takes each; three body-hit sizes, 3 takes each; brick thump; Perfect sting; bag Miss swish | earshot; ProSoundEffects fallback | 48 to 60 | M4 (one stand-in set at M1) |
| Bosses | 6 zone voices (call, grunt, defeat; 2 takes each) 36; 7 body-type attacks (wind-up, impact; 2 takes each) 28; 6 zone element layers (2 takes each) 12; heart-lost drop; fight-lost tumble. Start and defeat stings from the Creator Store | earshot; Creator Store stings | about 78 | M4 |
| UI | Open, close, click, tab, no, hover, slider release | earshot `ui` set; Roblox's own sets as fallback | 6 to 8 | M4 |
| Cash and upgrades | Cash tick, quiet tick, collect, offline collect with coin run, upgrade, buy, reward, sell, the six-step reveal figure, brick snap | earshot tonal figures in one voice | 8 to 12 | M4 |
| Carry and hazards | Carry footsteps on six surfaces (grass, sand, wood planks, ice, stone, metal plate), 6 to 12 takes each; hazard hit thud, drop, lift pop, deflate pop, rolling pad brick pop, crate knock and lid creak; the six hazards' sounds (rumble loop, bounce and rustle, creak and whoosh, scrape loop and knock, sizzle and burst, humming whoosh loop) | earshot | 55 to 90 | M4 |
| Steal and shield alerts | Hold ratchet and its stop, the alert (knock and two-note call), its three-note shield-broken form, its falling form, the recovered answer, dizzy wobble, Iron Grip clank, shield rise, hum, the two warning ticks, ready tick, rubbery bounce, brick-wall break. Their own family: nothing shared with shop or cash | Creator Store or earshot | 0 to 15 | M4 |
| Rebirth | The one long sound (2 to 3 s) | Creator Store; earshot candidate | 0 to 1 | M4 |
| Shop and spin | Reuse of UI and cash | none new | 0 | M4 |
| Ambience | Seven beds (base and six zones), two or three point sources each | earshot | 21 to 28 | M4 |
| Music | Two or three tracks | Creator Store licensed libraries | 0 | M4 |
| **Uploads, total** | | | **about 220 to 300** | |

Roblox's audio import limits (`vault/roblox-docs/audio-permissions-and-creator-store.md`): **100 imports per 30
days on an account that is not ID-verified, 2,000 on an ID-verified one**; each file under 20 MB and under 7
minutes. This plan's 220 to 300 is over the unverified limit and well under the verified one; the manager's account is ID-verified (2026-11-25), so the counts below stand as a note, not a step. `UNVERIFIED` until the
first upload: whether uploads to a group count against the uploading account's limit (most likely, since the
limit is the uploader's) and whether the group needs anything of its own; whether a group-owned game plays every
group-owned sound without a Permissions grant; how long moderation holds a file. Suggestion S3 would remove about
30 to 50 uploads.

### Game page and group art
| Asset | Count | Source and method | Credits | Milestone |
|---|---|---|---|---|
| First group icon | 1 | Made in the pitch from concept art and uploaded to the group by the main session on 2026-11-25 (`game-page/group-icon.png`, moderation pending) | 3.00, charged in this pitch | done |
| Group icon remake | 1 | Real render of the glove landing on a boss face, composed for a circle, improved in Higgsfield image to image, finished in FigCraft (`game-page.md`, Group) | about 2, plus one retry 2 | M6 |
| Game icon | 1 | Real screenshot of the built game, improved in Higgsfield image to image | about 2 | M6 |
| Thumbnails | 3 | Same | about 6 | M6 |
| One more round on the icon and thumbnails | 4 | Same | about 8 (a guess) | M6 |
| Pass and product icons at dashboard size | 19 | Board 04's shop icons, resized | 0 | M6 |

The manager uploads the game page art, the final group icon and the pass and product icons themselves (publishing,
group settings and the dashboard are theirs).

### Credit estimate
| Line | Credits | Basis |
|---|---|---|
| Game page art (icon and three thumbnails, one more round each) | 16 | 2 a 2k image, charged in this pitch; the second round is a guess |
| Group icon remake at the end, with one retry | 4 | 2 a 2k image, charged in this pitch |
| Icon remakes after the in-place check | 4 | 1 a 1k transparent icon, charged in this pitch (Perfect Auto Punch); an allowance, not a plan |
| **Planned total** | **24** | |
| Boss concept sheets for the 30, optional | 12 | 2 a sheet, charged in this pitch |
| **Total with the optional line** | **36** | Over the balance of 34.96 by about 1; the optional line is trimmed to five sheets (10) if taken |
| Left after the planned 24 | about 11 | 34.96 minus 24 |
| Left after the planned 24 and 5 optional sheets | about 1 | 34.96 minus 34 |
| A generated clean huss, only if the recording does not hold up in the game (allowed by the manager) | not estimated | Higgsfield or earshot; estimated with the connector before any spend and reported |
| 3D models, video | 0 | Not used |

Balance now: **34.96** (`concepts/higgsfield-log.md`, after the base layout renders; the pitch spent **77.25**: 45.00 on five look directions, 8.00 on game page concepts, 12.25 on the UI kit, 1.00 on the final icon, 3.00 on the first group icon, 8.00 on the three base layout renders). After the planned 24 the balance would be about 11 (10.96); the optional 12 would not fully fit (it would leave about -1, so five of the six sheets, 10 credits, is the most it can take, leaving about 1). Nothing is left for a generated clean huss after both.

The manager's ceiling of 40 credits ("done") stays as approved, but **the balance, 34.96, is the real limit**: the
ceiling is above what is left, so the ceiling never binds. The build reads the balance before the first generation
and reports each cost and the balance as it goes. If the balance would run out, a top-up goes under "Blocked on the
manager" and the optional line is dropped first (a generated clean huss, if needed, has its own cost estimated before
any spend and is paid for before the optional sheets). Nothing but the game page art, the group icon remake and icon
remakes depends on Higgsfield.

## Technical shape

### Repo layout (game repo, `projects/huss-for-bosses/`)
```
src/
  ReplicatedFirst/
    Music.client.lua      music from the first spawn, never restarted
  ReplicatedStorage/
    Shared/Config/        every tunable number in the brief, by system; ids only; BEAT, ring times, windows
    Shared/Ids.lua        zones, tiers, creature ids, body types, hazard ids, product keys
    Shared/Net.lua        the remotes, created in one place, with the payload contract
    Shared/Moves/         boss move tables per body type and per signature (structure, fractions of H)
    Shared/TestHooks.lua  hooks, read only in Studio
    Skins/brickbrawl/     Names, Tokens, Models, Icons, Sounds (+ the burst voice's beat table), Lighting,
                          Effects, Dressing
    Skins/stub/           the test fixture for the skin check
  ServerScriptService/
    Data/                 profile store, session lock, schema, migrations, transfer
    Systems/              Punch, Bag, AutoPunch, Fight, Zones, Carry, Hazards, Base, Income, Upgrades,
                          Steal, Shield, Offline, Rebirth, Shop, Spin, Policy, Funnel
    Main.server.lua
  StarterPlayer/StarterPlayerScripts/
    Ui/                   Kit (panel, button, chip, tag, counter, well, stud tile), one module per screen
    Controllers/          Input, Ring, BurstClock, Fight, BossMoves, Carry, Arrow, ZoneLighting, Audio,
                          Effects, Avatar (gloves, clips)
    Main.client.lua
studio/                   BuildSlice, BuildWorld, zone dressing, SetupBosses, SetupGloves, SetupStud,
                          checks (CheckAll and one per system), the place guard
tools/
  devsync.py              the sync server
  blender/                build_boss.py, bosses/<id>.json, build_gloves.py, render_boss.py
  audio/                  cut, level, measure and envelope-probe scripts
team/                     as written by the tech-lead at M0; pack/ is the copy of this folder
docs/controls.md          the action x input table
```

### How code reaches Studio (`TEAM CALL` B1)
**The project's own sync script, taken from deja-kill's DevSync**, not Rojo.
- Why: it is already on this PC and proven with the Studio MCP in the manager's other game; it also runs
  `studio/` build scripts, which this build leans on; Rojo, rokit and wally are not installed (`scripts/doctor.sh`,
  read earlier on 2026-11-25) and the approval's default is to install nothing new.
- deja-kill measured that the sync works through the Studio MCP even with `HttpService.HttpEnabled` off; the
  tech-lead proves it again at M0 before calling anything a blocker.
- File names follow Rojo's convention (`*.server.lua`, `*.client.lua`, `*.lua`), so moving to Rojo later costs one
  project file.
- After each wave the orchestrator syncs once and runs the smoke check before the next wave.

### Client and server boundaries
The brief's "the server decides" lines are the contract. In short:

| The server owns | The client does |
|---|---|
| Power, cash, levels, every price and payment | Shows them |
| The ring schedule per player, the value of each burst, rate limits, where the player must stand, the beats at which each punch counts | Draws the ring, judges the tap against the ring it drew, reports grade and tap time, runs the burst clock for picture and sound |
| A fight's ratio and band, boss health, damage at each beat, hearts, win or loss | Camera, health bar, hearts, the boss's moves as dressing of the results |
| Auto Punch and Perfect Auto Punch value and rate, and that the owner is on their pad with the pass | Runs the auto ring and its bursts on the owner's client so picture and sound share one clock (B23) |
| Every roll, pad timers, who has beaten which roll, the zones-beaten list | Countdown display |
| Hazard positions (a function of the server clock), hits, drops, grabs | Animates the hazard from the same clock |
| Plots, spots, place, pick up, swap, sell, crate, the rebirth auto-placing | Prompts |
| Income (from time stamps, no per-boss loop), collection (server-side pad touch) | Cash pops |
| Steal hold, carry speed checks, the owner's punch, Iron Grip, returns, transfers, the bought mark moving with a boss, the shield, Shield Breaker uses and charges | Hold bar, alert, arrow |
| Offline earnings (saved leave time, server clock) | The panel |
| Rebirth, as one save operation | The confirm screen |
| Passes, receipts, quotes, the spin roll, the odds table, both policy checks | Reads the same odds table to print the list; hides what the policy flags hide |
| Funnel events | Nothing |

Client-judged timing is the one place the client is believed, by the brief's design; the server bounds it (rate,
place, state) and the gain from cheating is capped at about 1.5x (8 against a typical 5.4 per burst). It is first
on the exploit review.

### The burst timing contract (server, animation and sound)
One table, three readers. Quoted in every brief that touches the punch, the fight, the avatar clips, the boss moves
or the punch sounds.

- **Constants** (`Shared/Config`): `BEAT = {0, 0.213, 0.401}` (brief, system 1); `BURST_LEN = 0.61`; `RING[1..10]`
  from 1.20 s to 0.50 s (brief, system 2); windows per band (system 4); `CYCLE = RING[level] + BURST_LEN`. In the
  skin: the burst voice's asset id and `F_BEAT_IN_FILE`, the three loud parts measured on the uploaded F at M1
  (about 10 ms lead to the first). If any loud part sits more than 20 ms from its beat plus that lead, B21 applies.
- **Own client, on a tap it grades Good or Perfect:** `t0 = os.clock()`; `Play()` the pooled F in the same frame
  (`PlaybackSpeed` 1.0, never changed; volume only); start the jab x3 clip, seeking `TimePosition` to the elapsed
  time if it starts late; a Heartbeat loop fires beat n when `os.clock() - t0 >= BEAT[n]`, firing every missed beat
  in order on a late frame; each beat carries the contact frame, thud, star, cube burst, Power number, pip, and the
  boss's hit reaction and grunt. Send the report (context, grade, tap time). A Miss: no burst; the swish on the bag,
  or nothing in a fight (the boss's wind-up marks it).
- **Server, on the report:** accept only if the player is in the right place and state and the tap is no sooner
  than `CYCLE x 0.8` after the last accepted one; apply punch n's value at accept time + `BEAT[n]` (bag Power, or
  fight damage). In a fight, check health at each beat: **the beat that empties the bar wins the fight; later beats
  deal nothing and send no hit** (B22). On a Miss in a fight: one heart, and the attack result. Results go to the
  owner (to confirm or roll back: a refused tap fades F over 30 ms) and to clients near the bag or pad, at most one
  boss reaction per 0.3 s per boss to watchers.
- **Watching clients:** on a burst result, start their own copy (F at the lowered other-player level, two voices at
  most, only the third thud) and run the same `BEAT` from the moment it arrived.
- **Boss moves never gate anything:** a Miss's attack (0.45 s) plays inside the 0.61 s where a burst would have
  been; a reaction still running when the next result arrives is cut; the next ring starts on schedule.
- **Auto Punch and Perfect Auto Punch:** the owner's client runs the ring and fires one burst per cycle at the
  owner's Speed (Good, or Perfect with the pass), F 6 dB lower, no sting for Auto Punch and the soft thinned sting for Perfect Auto Punch (rule in `sound-direction.md`); the server applies 4 or 8 per cycle only
  while the pass is owned and the owner stands on their own bag pad, and caps the rate the same way. A hand tap
  follows B20.

### `PolicyService` checks
- On join, on the server, `GetPolicyInfoForPlayerAsync` once per player, cached for the session; a failed or slow
  call counts as restricted (for spins) and as `IsPaidItemTradingAllowed = false` (for steals).
- `ArePaidRandomItemsRestricted` true: the server never quotes, prompts or grants the three spin products for that
  player and never accepts a spin; the client hides the Spin card, the Spin screen and the ticket buttons. Nothing
  else in the shop changes.
- `IsPaidItemTradingAllowed` false for the thief or the owner: a boss with a bought mark (spin or the Starter Pack's Ram: Roblox says the flag restricts trading of all paid items) cannot be lifted by that thief (or by anyone, when it is the owner's flag); the prompt shows greyed "Can't be stolen" with a padlock and no reason. An earned boss is not affected. If Roblox says stealing is not trading, the guard is removed (TEAM CALL 38, `UNVERIFIED` until Roblox answers; the paste-ready question is in `vault/roblox-docs/paid-random-items-policy.md`).
- Test hooks set both flags on and off and make the call fail.

### Remotes, by family
Created in `Shared/Net.lua`; every one validates type, range, rate, state and distance on the server
(`roblox-networking` skill). Names are a team call (B8); the families are:

| Family | Client to server | Server to client |
|---|---|---|
| Punch | burst report (context: bag, fight; grade; tap time); auto mode on or off | ring schedule (Speed level, cycle), burst result, refused tap; burst results to nearby clients |
| Fight | start, run | fight state, beat results (hit, heart lost, win, loss), to nearby clients rate-limited |
| Bag | buy Strength, buy Speed, Auto Punch toggle, PERFECT mode toggle | bag tier |
| Base | place, pick up, swap, sell, take from crate | base state for all 8 plots, rebirth auto-placing |
| Boss | upgrade | |
| Carry | grab | carry state, drop |
| Steal | hold start, hold cancel, owner's punch at a thief | steal alert (with the BOUGHT tag), thief strip, Iron Grip stagger, result, greyed-prompt flag per boss |
| Shield | raise, use a stored Shield Breaker charge | shield state (up, cooldown, ready, Instant, breakable or the reason), "shield broken" alert |
| Zones | | pad contents and timers, clock sync for hazards |
| Rebirth | request (after the second confirm) | result |
| Shop | open (returns quotes and keys), spin (zone) | grant results, pass state, tickets, charges, bought cash, policy flags |
| Offline | collect | summary on join |
| Profile | settings | profile snapshot and changes |

Purchases themselves go through `MarketplaceService` prompts (passes with `PromptGamePassPurchase`, products with
`PromptProductPurchase`, Shield Breaker from the button on another player's shield) and the one receipt handler,
not a remote.

### Data schema outline and save rules
Designed in full by the data-engineer at M2 (`roblox-data` skill;
`vault/patterns/session-lock-inside-the-record-one-updateasync.md`, candidate). Outline:

```
version
power, cash, boughtCash, strengthLevel, speedLevel, rebirths
bosses: [ { uid, creatureId, level, spot (1..17), padCash, padStamp,
            bought: nil | { source = "spin" | "pack", buyer = userId } } ]
crate:  [ { uid, creatureId, level, bought } ]
zonesBeaten: { 1..6 }          fight wins only; never from a steal or a purchase; kept by rebirth
spinTickets, breakerCharges, starterPackGiven
purchases: { handled purchase ids, bounded }
leftAt, shieldReadyAt
flags: first-session steps (12 funnel events, the arrow)
settings: { music, effects }
lock: { server, stamp }
```
- **The bought mark** (brief, systems 7, 10, 12): set only by the server when the Lucky Spin or the Starter Pack
  grants a boss, holding the source and the buyer's user id, and never changed afterwards. It moves with a stolen
  boss unchanged (so the BOUGHT tag still shows, the spin rule still applies, and only the buyer keeps it through
  rebirth). No remote can write it.
- **Bought cash:** `boughtCash` rises with every cash pack and the Starter Pack's $5,000, and is lowered to `cash`
  whenever `cash` falls below it (earned cash is spent first). At rebirth `cash = boughtCash`. No remote can write
  it.
- **Rebirth** reads both: bosses whose mark names this player as buyer are kept at their level, placed back on
  spots lowest first and the rest put in the crate, pad cash cleared; every other boss is removed. Tickets, charges,
  zones beaten, passes (from Roblox), settings and flags stay. One write.
- **The 60 s safe time after a steal** and **when a base was last broken** are per server, in memory, keyed by boss
  uid and base; not saved (brief, system 14).
- Content is saved by id only; no name is ever saved.
- One record per player, session lock inside the record, one `UpdateAsync` per write; autosave on a timer, on
  leave, and on shutdown (`BindToClose`); `Players.PlayerRemoving` returns a thief's carried boss before the save.
- A purchase grant and its purchase id are one write. A steal transfer happens in memory in one step, keyed by boss
  uid, then both profiles are written with the owner's first; a load drops a uid that a transfer note says has
  left. A boss may never exist twice.
- DataStore names carry the environment (Studio or live), so test data never reaches a published game. The stores
  belong to the group-owned game from the start (brief, system 14).
- Schema changes go through a version number and a migration, tested at M2.

### Test hooks
`Shared/TestHooks.lua`, read only when `RunService:IsStudio()`, every hook named in `team/test-hooks.md`, and a
live server warns once if one is set in the place
(`vault/patterns/test-hooks-gated-to-studio-and-listed.md`, own-dev). Planned hooks:
- Set Power, cash, bought cash, Strength, Speed, rebirths, zones beaten; grant a boss by id to a spot or the crate,
  with or without a bought mark and a buyer; wipe to a fresh profile.
- Force a pad's roll; speed up pad timers; set the server clock offset (offline earnings, shield, safe time, the
  5-minute break timer).
- Saving off; force a save error between the two writes of a transfer.
- A stand-in second player through module seams (owner or thief) for steal checks with one client
  (`vault/patterns/stand-ins-through-module-seams.md`, own-dev).
- A fake receipt for any product key; pass ownership on or off; both policy flags on or off, or the call failing.
- Force the input kind (touch, gamepad, keyboard); force the skin (`stub`); throttle the frame rate to 30 and 15 for
  the sync test.
- An auto-player that taps the ring at a chosen grade mix, for the smoke loop and the curve measurements.
Long check scripts are loaded over the sync, not pasted
(`vault/patterns/long-check-scripts-loaded-over-localhost.md`, own-dev).

### Performance budget (starting points, all `UNVERIFIED` until measured at M3)
- Worst case on screen: 8 plots x 17 spots = 136 placed bosses on the half idle, 24 on pads, 8 carried.
- The hub: about 210 parts a plot, about 1,700 for 8 plots, about 60 more for walls, track, gate and scenery
  (`base-layout.md` section 7); the hub is 412 studs across, so placed bosses on the far wall stand still beyond 150.
- Bosses at the pictures' cube density (about 20 to 34 cubes tall) may exceed the tier triangle budgets; the six
  are counted at M2 and the budget is set from the M3 measurement (B6).
- Placed bosses are scaled to 9 studs at most; the half idle runs on the client at about 15 updates a second, at a
  random phase, only for bosses on screen and within 150 studs; beyond that they stand still. Fight moves only on
  pads within 150 studs. Moves are tweens of group pivots, not Animation assets.
- The world is parts with one material variant and no per-stud geometry; whether instance streaming is on is B6,
  made on the M3 measurement.
- Hazards and pads replicate as a clock and a few numbers, never as per-frame positions; burst and fight results to
  watchers are rate-limited.
- Income is computed from time stamps; no loop runs per boss.

## The manager's steps

### Before the build starts (do these, then paste the line in `START-PROMPT.md`)
Already done (2026-11-25): the group **Huss for Bosses** is created (community id 432262304) and its first icon is
uploaded (moderation pending); the account is ID-verified, so the audio limit is 2,000 imports per 30 days (the
build plans about 220 to 300 sound uploads; the counts stand as a note).
1. **Answer what is left in `approval.md`** (the manager's answers so far are written under their questions there; "defaults" is an
   answer for the rest; the base layout you asked for before building is made and you approved it, so what is left is
   the last box, "installing nothing new", and your saying the pack is approved), then go through its boxes with the
   main session. `/build` will
   not start on a draft.
2. **Publish the place under the group.** In Roblox Studio: File, New, Baseplate. Then File, Publish to Roblox As,
   choose **the group** as the creator, name it "Huss for Bosses", leave it private. (`UNVERIFIED`: the dialog's
   wording for choosing a group.) Doing it under the group now means data stores, passes, products and uploads all
   belong to the group from the start, and nothing has to be moved later.
3. **Turn on saving in Studio.** Home, Game Settings, Security, switch on "Enable Studio Access to API Services".
   Save.
4. **Leave that place open in Studio, and close any other place** (deja-kill included) for the length of a build
   session. The team's tools act on whichever place is open; the place guard refuses any other.
5. **Check the tools.** Studio's MCP server is on (Assistant, the `...` menu, Manage MCP Servers) and computer use
   is on in the Claude app (Settings, Capabilities). Studio is signed in to the account that owns the group, because
   the team uploads to the group through it.
6. Optional: make an empty private GitHub repo for the game and put its URL on a second line under the build line.
   Without one, the team makes a local repo and a remote can be added later.
7. Optional, starts a slow clock early: the **Kids and Select** steps (`game-page.md`): a new game is open only to
   age-checked 16+ accounts until it passes the evaluation (creator verification, 2-step verification, a fee or two
   months of subscription, and 100 unique plays by highly engaged age-checked users within 60 days). The manager
   will pay or advertise as needed (2026-11-25). Starting the verification steps now shortens the wait after
   release; for a group-owned game the questions go to the group owner, the manager's account.

### During the build (the team keeps working; these wait in `team/manager-todo.md`)
1. **Create the 10 passes and 9 developer products under the group's game and paste their ids.** Creator
   Dashboard, switch to the group, Creations, Huss for Bosses, Monetization. Prices are the brief's starting figures
   (system 13); prices are yours.
   - Passes (10), for each: Create a Pass, name, description, create; then open it, Sales, switch on "Item for sale",
     set the price, save. Auto Punch R$249; Perfect Auto Punch R$399; 2x Power R$349; 2x Cash R$349; Fast Carry
     R$149; Long Lock R$199; Extra Spots R$249; Quick Hands R$199; Iron Grip R$299; Starter Pack R$99.
   - Developer Products (9), for each: Create a Developer Product, name, price, save. Small Cash Pack R$29; Medium
     Cash Pack R$79; Large Cash Pack R$199; Huge Cash Pack R$399; Lucky Boss Spin x1 R$49; Lucky Boss Spin x3 R$129;
     Lucky Boss Spin x10 R$399; Instant Shield R$19; Shield Breaker R$39.
   - Paste each id next to its name in `team/manager-todo.md`. Until then the game runs on stand-ins and no
     purchase can be tested. The 19 icons are on board 04 already and can be added at creation or later.
   - If you drop Perfect Auto Punch or any of the three attacking products at approval, skip them here.
2. **Set the server size.** Creator Dashboard, the game's place settings, Maximum Visitors: 8 (`UNVERIFIED`: the
   exact page; the team names it when it asks).
3. **Look at the stud proof** (after M1) and say yes or what is wrong. Nothing else is studded until then.
4. **Look at the first six bosses** (after M2), rendered beside their pictures. The other 30 are made after your
   yes. The build does other work meanwhile.
5. **Listen and pick.** Each sound family arrives as a listening page; answer with one letter per slot.
6. **Audio.** If an uploaded sound is silent in the game, open that sound's page in the Creator Dashboard,
   Permissions, and add the experience. The team lists which.
7. **Save the place** when the team asks (anything hand-done is listed in `team/build-state.md`).
8. **Higgsfield top-up**, only if the team reports the balance will not cover what is left.
9. Answer anything under "Questions". Nothing there stops the build; what was built on a default is marked
   `PROVISIONAL`.

### Only at the end
1. Playtest in Studio with `team/handoff.md` (15 minutes, the five playtest questions from the brief).
2. Listen through the in-game sound checklist.
3. Publish privately; add the game icon, thumbnails, title, description and genre from the kit; upload the pass and
   product icons; replace the first group icon with the remake; set the group's description and links.
4. Fill in the maturity and content questionnaire with the answers in `game-page.md`. **Paid random items: yes.
   Paid item trading: ask Roblox first** (below).
5. **Ask Roblox (or re-read the paid random items policy and the DevForum) whether a steal counts as a trade**,
   before any public release: it decides the questionnaire answer and whether the bought-boss guard (TEAM CALL 38) is kept or dropped (the paste-ready question is in the digest). The team re-reads `vault/roblox-docs/paid-random-items-policy.md` (re-check due by
   2027-02-11) and lists what changed.
6. Run the two-device checklist (below) with a second account or a friend.
7. The Kids and Select steps, if not started before.
8. Decide prices, when to make it public, and whether to advertise.
9. Run `/retro huss-for-bosses` so the results reach the vault.

## Team calls expected
The brief's **39 team calls** (`brief.md`, "Team calls (for the producer)", numbers 1 to 39; 31 to 39 came with the
manager's later answers: body types, fight moves, gloves, avatar clips, zones beaten, the one-tap burst, Perfect Auto
Punch, the bought-boss policy guard, the already-made Perfect Auto Punch icon and the group) are carried into `team/decisions.md` at M0 as
written. The build adds its own, each logged as `TEAM CALL` with the reason and what changing it later costs:

| # | Build-side team call | Decided at |
|---|---|---|
| B1 | Code reaches Studio by the project's sync script, not Rojo | this plan |
| B2 | UI in code; the world by build scripts; boss moves as tweens; nothing hand-built in the place | this plan |
| B3 | Own save module to the `roblox-data` skill, or a vendored library | M0, tech-lead |
| B4 | Boss colour: shared atlas or one mesh per colour role | M1, modeler-3d |
| B5 | Boss import: one FBX per boss or per zone (groups kept apart); boss pictures as rendered images or live viewports | M1, modeler-3d with the main session |
| B6 | Instance streaming on or off; the 150-stud move distance and the 15-a-second half idle tuned; part and triangle budgets, raised if the pictures' cube density needs it | M2 count, M3 measurement, M5 final, performance-optimizer |
| B7 | Stud route A (MaterialVariant) or B (face textures); normal map direction; a 2-stud ground tile if the 1-stud tile shimmers | M1, builder (the manager confirms the look) |
| B8 | Remote names and payloads; rate limits per remote; hit-check tolerances | M1 and M2, tech-lead |
| B9 | Autosave interval; how many purchase ids are kept; the transfer's write order | M2, data-engineer |
| B10 | Settled by the approved layout: plots are 50 x 92 in the hub's U with two columns, an aisle and a back row (`base-layout.md`); what stays with the builder is the greybox measurement of run, carry and sight lines, and any dimension changed because of it (reported, not silent) | M1 greybox, M3, builder |
| B11 | How group moves are driven: each group's pivot `CFrame` or `Motor6D.Transform` (style guide: the animator-vfx picks) | M1, animator-vfx |
| B12 | The shield plate's "ready" state: not shown, or grey "0:00" (style guide: one way everywhere) | M2, gui-designer |
| B13 | Fight camera framing; how the player is held in place | M1, scripter with the gui-designer |
| B14 | How avatar clips are authored (Blender or Studio) and published under the group; how the gloves attach on R15 and R6 | M1, animator-vfx |
| B15 | Sound: takes per family; which Creator Store ids for stings, alerts, rebirth and music; the shield drop heard nearby (settled: the manager's "9. yep") | M4, audio-specialist |
| B16 | Number shortening; toast wording; the wording of a stored Shield Breaker charge on the Break shield button | M2, gui-designer |
| B17 | Roblox's default loading screen (the brief has none); music starts at the player's first spawn | M4 |
| B18 | `PROVISIONAL` sound picks where the manager has not listened yet | M4 |
| B19 | Models per launch (above); at most two Opus agents in a wave | this plan |
| B20 | A hand tap while Auto Punch runs: one burst per ring; a hand tap replaces the auto tap for that ring only if its grade is better, and is ignored once the auto burst has started (now in the brief, system 2, and the sound direction) | M2, game-designer |
| B21 | If the envelope probe finds a loud part of the uploaded F more than 20 ms from its beat, `BEAT` is set from the probe for the server, the hit frames and the clips alike, because the manager asked for the punches to be "timed against this" | M1, audio-specialist with the game-designer |
| B22 | A boss emptied on punch 1 or 2 of a burst: the fight is won on that beat, later beats deal nothing, F plays to its end, the avatar's remaining jabs play without contact effects, defeat starts at once (now in the brief, system 4) | M1, game-designer with the animator-vfx |
| B23 | Auto Punch runs on the owner's client (ring, burst, sound) with the server applying value and rate | M2, tech-lead |
| B24 | The first six bosses are built in M2 beside the systems, so the manager's look comes before M3 | this plan |
| B25 | The huss files are uploaded to the group that owns the game, which the manager's account owns (settled: the manager's "under me") | M1 |
| B26 | The base layout's 15 TEAM CALLs (`base-layout/base-layout.md` section 8) are carried into `team/decisions.md` at M0 by reference; the builder's greybox at M1 and M3 may change a dimension and reports it | M0, tech-lead; M1 and M3, builder |

None of these adds, removes or changes a rule, a product or the look. A choice that would is a question in
`team/manager-todo.md`, not a team call.

## Risks
| Risk | Mitigation |
|---|---|
| **Stealing exploits**: duplication, teleport-steals, stealing through a shield | Every pick-up, drop, return and transfer is one server operation keyed by a boss uid; speed and path checks on the carrier; forced-error tests at M2; qa-exploit-reviewer reads the contract before the code and reviews after |
| **Client-judged timing**: a client can claim Perfects | Server owns the ring schedule and bounds rate, place and state; gain capped at about 1.5x; reviewed first at M5; windows down to 12 ms are config values for the playtest |
| **Burst sync on real phones**: picture and sound drifting apart at low frame rates | One `t0` per burst, F as one file, beats fired from the clock and never dropped; the sync test at 60, 30 and 15 fps at M1 and M4; the probe on the uploaded file; real phones on the two-device list |
| **Timing on real phones**: the Perfect window (45 ms) is near one frame at 30 frames a second, and touch delay varies | The tap is judged on the client against the ring it drew, so network delay does not matter; frame rate and touch delay do. On the two-device list |
| **The paid random spin** | Odds from one server table, printed from the same table, on screen before any button; restricted or failed policy check hides it; scripted policy pass at M5; the policy digest is re-read before release |
| **Bought bosses can be stolen, and a steal may be a trade** | Built as the manager asked; every bought boss (spin or Starter Pack Ram) blocked when either player's `IsPaidItemTradingAllowed` is false or the call fails, because Roblox says the flag covers all paid items (TEAM CALL 38, `UNVERIFIED`; the guard is removed if Roblox says stealing is not trading); nothing in the shop or on a tag says a bought boss is safe; the manager asks Roblox before release (end step 5); the strongest complaint risk in the game, watched through `/retro` |
| **Rebirth and Robux purchases** | Built exactly to the brief's kept and reset lists; the confirm screen shows the brief's text with the player's numbers; scripted at M2 |
| **The bought mark, its buyer id and the bought-cash number** as exploit targets (marking earned or stolen things as bought by you carries them through rebirth) | Set only inside the receipt handler's grant; no remote writes them; scripted at M2; on the exploit review at M5 |
| **Shield Breaker**: a paid, single-use purchase whose target can change before the receipt arrives | The server checks again on receipt; a late purchase becomes a saved charge, never a loss; one receipt, one grant; scripted at M2; real purchases on the two-device list |
| **Attacking products** (Shield Breaker, Quick Hands, Iron Grip), sold to a young audience | Built as the manager asked (brief, Caution 4). Never offered during a steal alert, a fight or a carry; plain wording; the alerts share no sound with the shop; Iron Grip and Shield Breaker are heard by their target |
| **Lost or doubled saves**: session locks, offline earnings from a wrong clock, shutdowns | Session lock in the record; leave time and server clock only; `BindToClose`; scripted at M2; cross-server behaviour on the two-device list |
| **The wrong owner**: the place or an asset published under the manager's account instead of the group | Before-step 2 (publish the place under the group); the M0 owner check stops saving and uploads if the place is not the group's; every upload checked for its owner in `team/assets.md` |
| **The hub on weak phones and in play**: about 1,700 parts for 8 plots, run and carry times and sight lines that are only on paper, a 4-stud front wall and invisible blockers players may not read as closed | Greybox and measure at M1 and M3 against `base-layout.md` section 5; the part-count measurement at M3; the manager's playtest questions (yard too empty, fences read as closed, corner-neighbour steal too easy) |
| **Boss detail against phones**: the pictures' cube density (20 to 34 cubes tall) may break the triangle budgets with 136 placed | The picture wins (brief); counted at M2, measured at M3 with the worst case, raised budget or fewer updates and a shorter move distance; real low-end phone on the two-device list |
| **The first six bosses not matching their pictures** | Built from the pictures side by side with renders; the art-director's match review before the manager sees them; a model that fails twice goes up one model or to the tech-lead; the other 30 wait for the manager's yes, so a "no" costs six, not 36 |
| **Boss moves reading as fighting**: rigid groups on a phone at the fight camera | One test boss per body type, smallest and largest tier; guard and impact renders before any code; the manager's playtest for feel |
| **The boss pipeline has one narrow point**: the Studio 3D importer and animation publishing are driven by computer use, which only the main session has | Proven on one boss and two clips at M1; batched; everything after import is scripted; a part-built stand-in with the right groups keeps every other task moving |
| **The stud look depends on unverified engine behaviour** (tinting, alignment, shimmer) | Proven at M1 with route B and a 2-stud ground tile as fallbacks, and shown to the manager before any zone is studded |
| **Audio import limit**: about 220 to 300 uploads planned; the account is ID-verified (manager, 2026-11-25), so 2,000 are allowed per 30 days (100 would apply otherwise) | No step needed; uploads in priority order (huss, punch, alerts, UI, cash first); Creator Store sounds need no import; S3 cuts footstep takes |
| **The huss upload**: rights (answered), a voice clip may be held in moderation, the group's game playing it | Uploaded at M1 to the group by the main session; a thud layer keeps the punch playable if the file is held; the Permissions step if it is silent; a generated clean huss is the manager-allowed fallback |
| **The wrong place**: a build script run in another game's open place | The place guard at M0; before-step 4 |
| **Usage limits and models**: Fable unavailable until 2026-11-27 22:00 PT; Opus-heavy waves hit limits | Opus is the top model in this plan; at most two Opus agents a wave; state in `team/build-state.md`; the same line resumes |
| **Higgsfield balance**: 34.96, planned 24, optional 12 more (does not fully fit; the manager's ceiling of 40 is above the balance) | Cost and balance reported with each generation; the optional line goes first; only page art, the group icon and remakes depend on it |
| **Originality**: 30 creatures with no picture; none may resemble a known character | The art-director reviews every design before its data file is written; the brief's and style guide's Never lists are checks at M3 and M5 |
| **A first autonomous build**: sizes are guesses; usage limits will interrupt it | State in `team/build-state.md`; the same line resumes; milestones are gates, not dates |
| **Hand-built work lost** | Nothing is hand-built by plan; anything that had to be is listed and the manager is asked to save |

## Unverified until published
Built and checked as far as Studio allows, then gathered into one checklist in `team/handoff.md`
(`vault/patterns/published-two-device-checklist.md`, own-dev: deja-kill's found 29 things Studio had passed).

**Two-device checklist, outline** (a phone and a PC, two accounts, the game published privately under the group):
1. Joining: both land on their own plot with the joining shield; a friend can join the same server.
2. The ring and the burst on the real phone: Speed 1 and 10, Perfects reachable, the three jabs, pips and husses on
   the same beats, the button clear of the jump button and the top bar; a red and a skull boss can be attempted.
3. Boss moves on the phone at the fight camera: guard, hits, the signature on a Miss (the scorpion's sting), defeat;
   the ring never held up.
4. Stealing across two real connections: hold, alert (with the BOUGHT tag on a bought boss), chase at 20 studs/s,
   punch back, a successful steal of an earned and of a bought boss (including a steal from the corner neighbour, plots 2 and 3, 6 and 7, whose doors are 41 studs apart: is the owner's catch fair), the 60 s safe time, the shield pushing a thief
   out; nothing doubled or lost after both rejoin.
5. Saving: leave and rejoin; rejoin within seconds; join a different server; a server closing with players in it.
6. Offline earnings after a real 10 minutes away and after more than 2 hours.
7. Every pass and product bought once with real Robux in the private game: granted once, kept after rejoin, the
   cash pack amount equals the button, the Starter Pack cannot be bought twice, Perfect Auto Punch offered only
   after Auto Punch and working when bought on the web page. Shield Breaker bought on one device drops the other
   device's shield, is refused on a joining shield and an Instant Shield, and a late purchase shows as a charge.
   Quick Hands and Iron Grip behave as the brief says against the other device.
8. Rebirth on a profile holding a spin boss, the Starter Pack ram, bought cash, tickets and a breaker charge: the
   confirm text shows the right numbers; the bought bosses come back on spots at their levels; everything listed as
   kept is there afterwards.
9. The Lucky Spin and the bought-boss steal guard on accounts Roblox restricts (paid random items, paid item trading),
   if any are available: hidden, and the greyed "Can't be stolen". Otherwise `UNVERIFIED` with the scripted checks
   as the only evidence.
10. Sound on the phone speaker: every uploaded sound plays (none silent for permissions), the huss on the beats, the
    mix.
11. Avatar clips and gloves seen from the other device and on the owner's own screen, on R15 and R6 avatars.
12. Performance on the real phone with 8 players and full bases, if 8 can be gathered; otherwise the largest group
    available, with the number written down.
13. Gamepad on a real controller: every action in the controls table.
14. The 12 funnel events arriving in the Creator Dashboard.
15. The stud tile and post effects at the phone's own graphics quality.

## Suggestions (optional)
Not in the brief or this plan's build. Each is the manager's to accept or drop.

| # | Suggestion | Why | Cost |
|---|---|---|---|
| S1 | Start with `/build huss-for-bosses until M1` and play the strip before the rest is built | The ring, the burst and the frog's moves are what the game stands on and only a person can judge them; playing the smallest version early is docs-backed (`vault/patterns/thin-playable-slice-then-watched-playtest.md`, docs; `feel-pass-on-the-main-action-first.md`, multi-source). The brief's suggestion table lists the same idea | One short playtest; the build waits for it |
| S2 | ID-verify the Roblox account before the build | Done: the manager's account is ID-verified ("yes, account is verified", 2026-11-25) | None |
| S3 | Fewer footstep takes (4 a surface instead of 6 to 12) | About 30 to 50 fewer uploads; changes `sound-direction.md` | None |
| S4 | A soft launch as its own stage after the handoff, before any advertising | `vault/patterns/soft-launch-then-grow-ads-never-rescue.md` (multi-source); also in the brief's suggestions | None; an order of release |

## Reconciled with the pack
Last read of the pack files: 2026-11-25, with `brief.md` and `sound-direction.md` as saved at 16:12,
`style-guide.md` at 15:58, `game-page/game-page.md` at 16:02, `ui-kit/README.md` at 16:12 and `ui-kit.figcraft` at
16:11 (49 exports, 5 boards, 22 screens at two sizes, 64 icons), `decisions.md` at 16:12. After that, the base layout (`base-layout/base-layout.md`, written 16:58 to 17:04 and
approved at 17:04, with the brief and style guide changes it listed in its section 11) was read and this plan updated
to it. If any of them changes before approval, this plan is read against it again.

The manager's changes of 2026-11-25 and where this plan carries them:

| Change (the manager's words) | In the pack | In this plan |
|---|---|---|
| "Items bought with robux should remain." | Brief system 12 (kept list, per-item table, bought-cash rule, bought mark with buyer, auto-placing), 13, 14 | M2 wave A and its rebirth checks; schema; risks; two-device item 8 |
| "lets change that no attacking products rule then." | Brief systems 10 and 13 (Quick Hands, Iron Grip, Shield Breaker) | M2 waves B and C and their checks; the passes and products step; risks; two-device item 7 |
| "components, make sure bosses look like that [...] should have small fighting animations too [...] if its like a scorpion it should use its tail to stin" | Brief system 4 and Content (body types, signature moves, approved pictures, gloves, avatar clips); style guide section 5 and 7 | The six built first (M1, M2) and shown before the 30; moving groups; move tables per milestone; the asset list's boss and animation sections; risks |
| "you can upload it under me yes. use computer use" | Brief "Look and sound"; sound direction "Sources" | M1 upload by the main session, to the group the manager's account owns; B25 |
| "for combo use reference E. make sure the punches against bag or boss are timed against this"; then "choose the one without the breath" | Brief system 1 (one tap, 0 / 0.213 / 0.401 s); sound direction Update (F) | The burst timing contract; the M1 sync test and probe; B21, B22 |
| "I guess I will make a group so we will need group icon" | Brief 13, 14, Content; game page, Group | Before-step 2 (the group and its first icon exist); M0 owner check; uploads to the group; the icon remake at M6 |
| "maybe we sell a perfect auto puncher too" | Brief system 2 and 13 (R$399, 19 items); kit final pass | M2 wave C; the passes step; B20, B23 |
| Answers 1 to 5 of the cold read's second list | Brief systems 7, 10, 12, 11, 2 | M2 throughout |
| "I want to first actually have a layout of what the base area will look like, with layout of everyones bases and such, as well as what pads will look like etc." and, with refs 15 to 17, "THIS IS THEE general layout im referring to youu know. but it should still have our own twist and theme to it obviously. but general layout."; then "perfect. base-layout looks good. all 4 pages in that document." | `base-layout/` (the hub, the plot, every pad, the steal route and timings); style guide section 4 and 6; brief system 5, 7, 10, 13 and content | M1 (own plot, track start, greybox measurement), M3 (the full hub, the walled lanes), the asset list's hub and base rows, B10 and B26, the exit checks, the part-count note |

Style guide section 13, item by item, and the milestone that settles it:

| Section 13 item | Settled at |
|---|---|
| The stud matches the manager's screenshots, world and UI | M1 stud proof, the manager's yes |
| Normal map direction; `BasePart.Color` tints the variant; tiles line up; stud depth at quality 1, 5 and 10 | M1 |
| The 1-stud tile at distance | M1 on the strip, M3 down the full lane |
| `TileSize` under `UIScale` and `UICorner`; Montserrat Black's weight name | M1 |
| The UI tile at 16 px and the 30% dark L under text | M1 first look, M3, then the manager's playtest |
| Boss atlas against per-role colour | M1 |
| Upload size and moderation of the tile images | M1 |
| Lighting, atmosphere, post-effect numbers and zone tints; `LightingStyle` and `PrioritizeLightingQuality` | M3 |
| Space Baseplate at `ClockTime` 20 | M3 |
| Triangle budgets with a full server at the pictures' cube density | M2 count, M3 measurement, M5 final |
| The first six match their pictures; Ember Drake's aura and Star Golem's stars as its aura | M2, the manager's yes |
| Each body type's groups and pivots; one set of offsets for a Common and a Mythic | M1 (squat), M2 (tailed, rearing, biped), M3 (charger, flyer, floater) |
| Rigid-group moves read as fighting on a phone | M2 and M3 checks, M4 Feel, the manager's playtest |
| No fight move hides or delays the ring | M1, again at M3 and M4 |
| Frame time of 136 placed half idles and fight moves within 150 studs | M3 first, M5 final |
| Avatar clips on R15 and R6, gloves on every hand, clips on a second client | M1 (jabs), M2 (the rest), M4 |
| The jab rhythm against the ring schedule | M1 sync test; the manager's playtest |
| Spot, pad, crate sizes and the plot layout for 17 | M1 greybox of the own plot, M3 for the hub (layout approved; this is the measurement) |
| The hub's run and carry times, sight lines over the front wall, world sign text sizes | M1 greybox, M3 |
| Part counts of the hub (about 210 a plot, about 1,700 in all) | M3 measurement, M5 final |
| Corner-neighbour steal too easy; yard too empty; fences read as closed | The manager's playtest |
| Zone corridor wall and centre-line colours | M3 Look review |
| Magma Hydra's reading | M3 design review |
| Hazard looks and "always a way through" | M2 (paths), M3 (shapes) |
| Board 04's icons in place on real screenshots | M3 |
| The other 30 against the originality rule | M3, before each data file |
| Phone cost of Bloom, DepthOfField and zone tweens | M5 in the emulator; a real phone on the two-device list |
| Motion, the ring's speed, three pips, boss and avatar moves, any sound | The manager's playtest |

The cold read's findings against the earlier version of this file, all corrected above: the funnel has 12 events,
not 13; six thud sets, not four weights; one fence look for every plot, not per-plot colours (B11 is now a different
call); the steal and shield alerts are their own family and reuse nothing from cash; music starts at the first
spawn, not when the client loads; six footstep surfaces, not seven; the unverified table is style guide section 13,
not 12; the UI tile's dark L is 30%, not 26%; the Higgsfield balance was 45.96 (now 42.96, after the 3.00 group icon) and the kit cost 12.25 plus 1; the UI
kit is made and approved; the old contradictions list is replaced by the one below; the "five questions" and the huss
cap question no longer exist.

## Contradictions still open
Re-checked on 2026-11-25 (late), after the consistency pass over `brief.md`, `style-guide.md`, `sound-direction.md`,
`game-page/game-page.md` and the approval sheet, and again after the base layout pass. The layout pass settled four
things that were open or mismatched and are not repeated: the shield-drop sound is heard nearby (B15; "9. yep"); the
bag tier table's Starter Bag band against its "every tier keeps a red band" rule (one rule now, following the kit);
screen 7's rebirth confirm (its own "REBIRTH NOW?" panel, as the kit draws it); and plots, crate, lock pad and
first-session timings that assumed bases beside the lane (the approved layout and the brief's matching changes replace
them; the build follows the layout). What the earlier list held is settled in the files and is not
repeated: the burst voice (F, in the brief and the sound direction), the sound direction's body, the hand tap while
Auto Punch runs (brief system 2, build plan B20), a boss emptied on punch 1 or 2 (brief system 4, B22), the style
guide's icon list and bag panel, the "new" Perfect Auto Punch icon, the jab note, who owns the huss upload (the
group, owned by the manager's account), and when the group is created (it exists). Until the one below is settled
the build follows the decision ladder: the manager's own words first, then the brief, then the other files.

1. **The beat offsets against the measured file.** Brief: punches at 0, 0.213 and 0.401 s. Sound direction: a second
   measurement of E puts the loud parts at 0.025, 0.255 and 0.44 s in the file (gaps 0.23 and 0.185 s), up to 17 ms
   from the brief's table; F starts about 10 ms in. Build follows the brief's `BEAT` until the probe on the uploaded
   F at M1; if a loud part is more than 20 ms off, B21 sets `BEAT` from the probe (the manager's "timed against
   this" wins over a reading of it). Settles: audio-specialist measures, game-designer updates the brief's table if
   it changes. Not a one-line fix until measured.

**Fixed in the kit's last rebuild, verify at M0** (the gui-designer rebuilt the kit; check the exports against these
before the screens are built from them):
- The `bag-panel` Speed numbers (phone and desktop) read the pre-burst figures ("The ring closes in 0.60 s"); the
  brief says 1.20 s at level 1 and 1.12 s at level 2. Screens read the numbers from config either way.
- Board 01's palette captions left things out of the style guide's job table (the orange confirm for a bought boss's
  sell or swap and for rebirth, and the "can't do that" toasts; Huss red's gloves and bag band). The style guide's
  table is the authority.

Checked and not contradictions:
- The brief's first-session line now says the Upgrade button is the only green button **on the boss panel**; the style
  guide's "a screen may have more than one green button" is about the bag panel. Both hold.
- The kit's `alert-steal-owner` screen shows no BOUGHT tag; board 03 draws the BOUGHT-tag variant, which is what the
  brief's screen 10 asks for. The build follows board 03 for the variant.
