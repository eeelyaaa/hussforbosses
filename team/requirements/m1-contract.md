# M1 contract: the calls, payloads, keys and names every M1 task builds against

Written by the producer, 2026-11-25, before any M1 task starts. **Every M1 brief quotes the section it builds to.**
Source of the numbers: `team/pack/brief.md` (systems 1 to 8), `build-plan.md` ("The burst timing contract",
"Remotes, by family", "Client and server boundaries"), `style-guide.md`, `sound-direction.md`, `base-layout.md`.
Where this file adds a name or a number the pack leaves open, it is marked **(TEAM CALL)** and the task that
builds it logs it in `team/decisions.md`. If a task finds this file wrong, it changes the file and says so in its
report; it never builds a private variant.

Autonomous mode: no task asks the manager anything. Ids come from `Shared/Ids`; every tunable number lives in
`Shared/Config/<System>.lua`; nothing outside `Skins/` holds a display name, a hex colour or an asset id.

## A. Who owns what (files; no two tasks in one wave share a file)
| Task | Owns |
|---|---|
| M1-01 tech-lead | `Shared/Net.lua`, `Shared/Config/*.lua` (all M1 children), `Shared/Skin.lua`, `Shared/Ids.lua`, `Shared/TestHooks.lua`, `Skins/brickbrawl/init.lua`, `Skins/stub/*`, `tools/check_skin.py`, `studio/CheckSkin.lua`, `team/test-hooks.md`, `docs/controls.md` (add rows if needed) |
| M1-02 gui-designer | `Skins/brickbrawl/Tokens.lua`, `Names.lua`, `Icons.lua` |
| M1-03 modeler-3d | `tools/blender/*`, `Skins/brickbrawl/Models.lua`, `assets-src/models/*` |
| M1-04 audio-specialist | `tools/audio/*`, `assets-src/audio/*`, `Skins/brickbrawl/Sounds.lua` (ids 0 until uploaded) |
| M1-05 builder | `assets-src/stud/*`, `studio/BuildSlice.lua` (greybox version), `team/verification/m1-greybox.md` |
| M1-06 scripter (server punch) | `ServerScriptService/Main.server.lua`, `Systems/Punch.lua`, `Systems/Bag.lua`, `Systems/Fight.lua`, `Systems/Zones.lua`, `Data/Session.lua` (in-memory profile only, see section K) |
| M1-07 scripter (client punch) | `StarterPlayerScripts/Main.client.lua`, `Controllers/Input.lua`, `Controllers/Ring.lua`, `Controllers/BurstClock.lua`, `Controllers/Fight.lua`, `Controllers/TestClient.lua` |
| M1-08 gui-designer | `StarterPlayerScripts/Ui/*` (Kit, Hud, HussButton, FightOverlay, Counters, Prompts) |
| M1-09 animator-vfx (boss) | `Shared/Moves/*`, `Controllers/BossMoves.lua` |
| M1-10 animator-vfx (avatar) | `Controllers/Avatar.lua`, `StarterCharacterScripts/` (if used), `studio/BuildClips.lua`, `tools/blender/clips/*` |
| M1-11 scripter (server carry/base) | `Systems/Carry.lua`, `Systems/Hazards.lua`, `Systems/Base.lua`, `Systems/Income.lua`, `Shared/Hazards.lua` |
| M1-12 builder | `studio/BuildSlice.lua` (real version), `studio/SetupStud.lua`, `studio/SetupBosses.lua`, `studio/SetupGloves.lua`; wires ids from `team/assets.md` into `Skins/brickbrawl/Models.lua` and `Effects.lua` (stud map ids) |
| M1-13 audio-specialist (wiring) | `Controllers/Audio.lua`, `Skins/brickbrawl/Sounds.lua`, `studio/checks/Probe.lua`, `studio/checks/SyncTest.lua` |
| M1-14 scripter (client carry/base) | `Controllers/Carry.lua`, `Controllers/Hazards.lua`, `Controllers/Base.lua` |
| M1-15 gui-designer (stud button) | `studio/checks/StudButton.lua`, `team/verification/m1-ui-stud.md` (Kit edits only if the proof demands, reported) |
| M1-16 scripter (checks) | `studio/checks/CoreLoop.lua`, `Refusals.lua`, `BurstValues.lua`, `NoDelay.lua`, `CheckAll.lua` |
A task that needs a change in a file it does not own writes the request in its report; the owner makes it in a
later wave.

## B. World instance names (builder creates them, systems find them; nothing is searched by position)
Hub frame as in `base-layout.md` section 2 (X across, Y toward the gate, 1 unit = 1 stud); **world X = hub X,
world Z = hub Y, world Y up**. The slice builds only plot 1, the track, the front wall and the zone 1 strip.
```
Workspace.Plots.Plot1               Model; attributes PlotId=1, OwnerUserId (server sets on join, 0 when free)
  .BagPad                           Part, CollectionService tag HFB_BagPad
  .Bag                              Model (the tier 1 bag; model name from Skin.Models.bags[1])
  .Spot_1 .. Spot_10                Part, tag HFB_Spot, attribute SpotIndex (1..10)
  .CashPad_1 .. CashPad_10          Part, tag HFB_CashPad, attribute SpotIndex
  .Entrance                         Part (invisible marker, 12 wide), tag HFB_PlotEntrance
  .SpawnPoint                       Part, tag HFB_PlotSpawn (a 4 x 4 pad; the server moves the character here)
  .LockPad .LockBoard .Crate .SpotsFullSign .NameBoard   built, inert at M1 (tags HFB_LockPad etc.)
Workspace.Hub.Track / StartLine / FrontWall / Gate
Workspace.Zones.Z1.Hazard_Log       Model, tag HFB_Hazard, attribute HazardId=1
Workspace.Zones.Z1.Pads.Fixed       Model, tag HFB_BossPad, attributes PadId="z1_fixed", ZoneId=1, Kind="fixed"
  .Ring                             Part (flat, 12 x 12), attribute RingRadius=6: the server's "in the ring" test
  .BossAnchor                       Part: where the boss's Body pivot stands
  .NumberAnchor                     Part: where the Power number billboard hangs
  .Boss                             Model "Boss_z1_t1" (section G), placed by studio/SetupBosses.lua
Workspace.Sight                     Folder of the measurement markers the builder used (BagPadEye, WindmillStandIn)
```
The slice's lane runs from the gate (hub Y 232) to at least 20 studs past the fixed pad (to Y 300). **(TEAM CALL,
builder)** the plan says "40 studs of lane" and the layout puts the fixed pad 44 in; the builder follows the layout.

## C. Remotes (all in `Shared/Net.lua`; created by `Net.serverInit`; every c2s validated on the server)
`Net.get(family, name)`. Server time everywhere means `Workspace:GetServerTimeNow()`; client durations use `os.clock()`.
Payload tables use the key names shown. `reliable` events unless marked.

| Remote | Dir | Payload | Server checks / notes |
|---|---|---|---|
| `Punch.Schedule` | s2c, to owner | `{ speedLevel: number, ringClose: number, burstLen: number, cycle: number }` | Sent on join, on entering a bag pad or fight, on a Speed change. The client draws every ring from it |
| `Punch.Report` | c2s | `{ seq: number, context: "bag"\|"fight", grade: "perfect"\|"good"\|"miss", tapServerTime: number? }` | See section D. `tapServerTime` is the client's `GetServerTimeNow()` at the tap, absent on a Miss with no tap. It is sanity-checked (not in the future by more than 0.25 s, not older than 1.0 s); the server's own receipt time is what schedules beats |
| `Punch.Result` | s2c, to owner | `{ seq: number, accepted: boolean, reason: string?, context: string, grade: string, gains: {number}? , t0: number? }` | `gains` = value of each of the three punches (Power on the bag, damage in a fight), `t0` = server time the burst was accepted. `accepted=false` -> the client fades F over 30 ms and cancels the burst. `reason` is one of `rate`, `place`, `state`, `grade`, `busy` |
| `Punch.Burst` | s2c, unreliable, nearby players except the owner | `{ userId: number, context: string, grade: string, t0: number }` | **Reserved at M1: declared in Net, not sent, no watcher code.** Watching clients are M2 |
| `Profile.Changed` | s2c, to owner | `{ power: number?, cash: number?, strengthLevel: number?, speedLevel: number? }` | Partial. After each applied beat on the bag the server sends the new `power` |
| `Profile.TestReport` | c2s | `{ name: string, json: string }` | **Studio only**: the server ignores it unless `RunService:IsStudio()`; max 1 KB; stored in `TestHooks.reports[name]` and `warn`ed (the client-report pattern) |
| `Fight.Start` | c2s | `{ padId: string }` | Player inside `Ring` of that pad (radius + 2), not carrying, not knocked down, not on the 5 s cooldown for that pad, no fight running |
| `Fight.Run` | c2s | `{}` | Ends a running fight as a loss with no knockdown (`run`) |
| `Fight.State` | s2c, to owner | `{ fightId: number, state: "started"\|"win"\|"loss"\|"run"\|"refused", reason: string?, padId: string, creatureId: string, bossPower: number, playerPower: number, ratio: number, band: "easy"\|"fair"\|"hard"\|"veryHard"\|"brutal"\|"impossible", goodMs: number, perfectMs: number, health: number, maxHealth: number, hearts: number, spot: Vector3? }` | Sent at start, win, loss, run. `spot` (started only, M1-26b): where the server stood the player for the fight |
| `Fight.Beat` | s2c, to owner | `{ fightId: number, burstSeq: number, n: number, size: "good"\|"perfect", big: boolean, damage: number, health: number, won: boolean }` | One per applied punch, at its beat. `won=true` on the punch that empties the bar (B22); later punches of that burst send nothing |
| `Fight.Heart` | s2c, to owner | `{ fightId: number, hearts: number, last: boolean }` | On a Miss: one heart lost; `last=true` when it was the last (the loss follows) |
| `Fight.Watch` | s2c, unreliable, nearby | `{ padId: string, kind: string, size: string? }` | **Reserved at M1**, not sent |
| `Zones.Pads` | s2c, to every player | `{ { padId: string, creatureId: string, power: number, kind: "fixed" } }` | Sent on join and on change. The client colours the Power number from its own Power |
| `Zones.PadBeaten` | s2c, to owner | `{ padId: string, backIn: number }` | After a win: the fixed pad is back for that player in 10 s |
| `Zones.Clock` | s2c, to every player | `{ serverTime: number }` | On join and every 30 s; the hazard clock reads `GetServerTimeNow()` and is only re-anchored here |
| `Carry.State` | s2c, to owner | `{ state: "none"\|"carrying"\|"dropped"\|"placed", uid: string?, creatureId: string?, dropPos: Vector3?, graceEnds: number? }` | `graceEnds` = server time the dropped boss is gone (5 s) |
| `Carry.Grab` | c2s | `{ uid: string }` | Only the player who dropped it, within 12 studs of it, inside the grace time |
| `Base.State` | s2c, to every player | `{ plotId: number, ownerUserId: number, spots: { [number]: { uid: string, creatureId: string, level: number, income: number, stamp: number, capSeconds: number } \| false } }` | `spots` is a dense array 1..`SPOTS_AT_START`, `false` = empty (M1-11, TEAM CALL M1-11g: a sparse table is cut at the first nil on a remote). `stamp` = server time (`Zones.now()`) of the last collect; the pad fills once a second, so the cash on the pad is `income x min(floor(now - stamp), capSeconds)` (M1-11, TEAM CALL M1-11e) |
| `Base.Place` | c2s | `{ spotIndex: number }` | Player carrying, the plot is theirs, the spot is theirs and empty, within 14 studs of the spot |
| `Base.Collected` | s2c, to owner | `{ spotIndex: number, amount: number }` | The server collects when the owner's character touches the cash pad (server-side distance check each Heartbeat step, 4 studs) |

The families `Bag`, `Boss`, `Steal`, `Shield`, `Rebirth`, `Shop`, `Offline` stay empty at M1 (Strength and Speed
are read from config levels; buying them is M2). **(TEAM CALL, tech-lead)** a `Punch.Report` for a context the
player is not in (bag while not on the own bag pad, fight while not in a fight) is refused with `place`.

Rate limits (`Config.Punch`): `Punch.Report` at most 4 a second per player (a legitimate cycle is at most
0.9 a second); `Fight.Start` 2 a second; `Carry.Grab` 4 a second; `Base.Place` 4 a second; `Profile.TestReport`
10 a second. A call over the limit is dropped silently and counted in `TestHooks.reports._dropped`.

## D. The burst timing contract, as the server and client each implement it
Quoted from the plan; the numbers are in `Config.Punch` (`BEAT = {0, 0.213, 0.401}`, `BURST_LEN = 0.61`,
`RING = {1.20, 1.12, 1.04, 0.96, 0.88, 0.80, 0.72, 0.64, 0.57, 0.50}`, `CYCLE(level) = RING[level] + BURST_LEN`,
`RATE_TOLERANCE = 0.8`, `GRADE_VALUE = {perfect = 2, good = 1, miss = 0}`, `BIG_MULT = 2`, `MISS_RESTART = 0.61`).
Windows: bag `perfectMs = 45, goodMs = 110`; fight windows by band from `Config.Fight.BANDS`.

**Client ring (Controllers/Ring):** a ring starts when the player stands on the own bag pad (or a fight is
`started`) and the previous burst has ended. Ring n starts at local time `r0`, lands at `r0 + ringClose`. A tap at
time `t` (local `os.clock()`) is graded by `d = |t - landing|`: `d <= perfectMs` Perfect, `d <= goodMs` Good, else
Miss; a tap earlier than `landing - 0.35` s is ignored (button feedback only, no report); no tap by
`landing + goodMs` is a Miss reported with no `tapServerTime`. A tap during a burst is ignored. After a Good or
Perfect the next ring starts at `t0 + BURST_LEN`; after a Miss at `missTime + MISS_RESTART`.

**Client burst (Controllers/BurstClock), on a Good or Perfect, in this order, in the same frame:**
1. `t0 = os.clock()`; 2. `Audio.playBurst(grade)` (the pooled F `Play()`, `PlaybackSpeed` never touched);
3. `Avatar.startJab(grade, t0)` (clip started, `TimePosition` seeked to the elapsed time if it starts late);
4. fire beat 1 at once (`BEAT[1] = 0`); 5. send `Punch.Report`; 6. a Heartbeat loop fires beat n when
`os.clock() - t0 >= BEAT[n]`, firing every missed beat in order on a late frame, never dropping one, never
moving a later one back. Beats are never gated on the server's reply.
Subscribers use `BurstClock.onBeat(fn)`; the event is
`{ burstId: number, n: number (1..3), big: boolean (n == 3), grade: "good"|"perfect", context: "bag"|"fight", t0: number, scheduled: number (BEAT[n]), firedAt: number (os.clock() - t0), lateFrames: number, noContact: boolean }`.
Other calls: `BurstClock.cancel(burstId, reason)` (server refusal: fade F 30 ms, stop later beats; Run or
knockdown mid-burst: fade 40 ms), `BurstClock.cutContact(burstId, fromBeat)` (B22: set `noContact` on beats >=
fromBeat that have not fired; F is not cut), `BurstClock.log` (array of every fired beat, for the sync test),
`BurstClock.starts` (count of F starts per burst, for the sync test). Subscribers at M1: Ui (pips, GOOD/PERFECT pop,
Power number), Avatar (contact frame), BossMoves (hit reaction: n = 1, 2 -> `hitGood` or `hitPerfect`, n = 3 ->
`hitBig`, `opts.perfect` on a Perfect), Audio (stand-in thud per beat; the boss's grunt is M4).

**Server (Systems/Punch):** accept a `Punch.Report` only if the player is in the context's place and state (own
bag pad for `bag`; in a running fight for `fight`) and the receipt time is at least `CYCLE x RATE_TOLERANCE` after
the last accepted report (`RATE_TOLERANCE` is 0.8 = the plan's "20% tolerance") and no burst of the player's is
still running. On accept: `t0 = receipt time`; punch n applies at `t0 + BEAT[n]`, processed by one Heartbeat
queue (not `task.delay`). Bag: Power += `strengthValue x GRADE_VALUE[grade] x (n == 3 ? BIG_MULT : 1)`, then
`Profile.Changed` with the new `power`. Fight: damage = `playerPower x GRADE_VALUE[grade] x (n == 3 ? BIG_MULT : 1)` (the plan's "one Good
punch does damage equal to your Power"); at each beat check health first: the beat that empties the bar wins
(`Fight.Beat.won = true`, then `Fight.State win`); later beats of that burst deal nothing and send nothing.
A `miss` in a fight: one heart lost, `Fight.Heart`; with 0 hearts `Fight.State loss`, 2 s knockdown (the player
cannot start a fight for 2 s, and that pad is closed to them for 5 s). A `miss` on the bag: nothing is applied,
the ring simply restarts. **(TEAM CALL, scripter)** stall rule: in a fight, if no report arrives within
`RING[level] + 0.5` s of the time a ring should have landed, the server counts one Miss itself, so a client that
never reports a Miss cannot stay in a fight for free.
At M1, a win adds nothing saved (no saving beyond the M0 proof); the fixed pad is back for the player in 10 s.

## E. Config keys (`Shared/Config/<Child>.lua`, read as `Config.<Child>`; numbers from the brief, none invented)
- `Punch`: `BEAT, BURST_LEN, RING, CYCLE (function), RATE_TOLERANCE, GRADE_VALUE, BIG_MULT, MISS_RESTART, BAG_WINDOWS = {perfectMs = 45, goodMs = 110}, MAX_REPORTS_PER_SEC = 4, EARLY_TAP_S = 0.35, TAP_TIME_FUTURE_S = 0.25, TAP_TIME_PAST_S = 1.0`.
- `Bag`: `STRENGTH_VALUE(level) = 1.35^(level-1)`, `DEFAULT_STRENGTH = 1`, `DEFAULT_SPEED = 1`, `PAD_RADIUS = 5` (the server's own-bag-pad test), `START_POWER = 0`.
- `Fight`: `HEARTS = 3`, `HEALTH_PER_POWER = 10`, `BANDS` (the brief's table: `maxRatio, goodMs, perfectMs`, in order easy 0.5 / 55 / 130 ..., near impossible over 3.0 / 12 / 35), `KNOCKDOWN_S = 2`, `PAD_COOLDOWN_S = 5`, `FIXED_BACK_S = 10`, `RING_SLACK = 2`, `STALL_SLACK_S = 0.5`.
- `Zones`: `PADS = { z1_fixed = { creatureId = "z1_t1", zone = 1, kind = "fixed" } }`, `POWER = { z1_t1 = 25 }` (brief system 5 table; only the zone 1 Common is needed at M1, the full table is M2), `INCOME = { z1_t1 = 1 }`.
- `Carry`: `WALK = 16, CARRY = 12, FAST_CARRY = 16, DROP_PUSH = 6, GRAB_S = 5, GRAB_RANGE = 12, MAX_HEIGHT = 6, LEAN_DEG = 8, ROCK_DEG = 4`.
- `Hazards`: `LOG = { length = 12, cross_s = 3, wait_s = 1, ... }` (system 6), `HAZARD_TOLERANCE = 1.0` (studs of slack in the player's favour), `WARN_S = 0.6`.
- `Base`: `SPOTS_AT_START = 10, PLACE_RANGE = 14, COLLECT_RANGE = 4, PAD_CAP_S = 7200`.
- `Income`: `LEVEL_MULT(level) = 1 + 0.25 x (level - 1)`, `DEFAULT_LEVEL = 1`.
- `Skin` keys do not live here.

## F. Skin keys (read as `Skin.Names...`, `Skin.Tokens...`; added by the owner in section A; missing key = nil, never a silent default)
- `Names`: `game`, `zones[1]`, `creatures.z1_t1` ("Chomp Frog"), `hazards[1]` ("Rolling Log"), `bags[1]`, `bands = { easy, fair, hard, veryHard, brutal, impossible }`, `grades = { good = "GOOD", perfect = "PERFECT" }`, `hudWords = { huss, run, place, grab, power, cash }`, `tiers[1..6]`.
- `Tokens.colors`: every hex in `style-guide.md` section 3 (UI, rarity, difficulty, world shared, zone 1), by job names: `panelGrey, plateBlue, hussRed, cashGreen, shopGold, shieldCyan, alarmOrange, flashYellow, white, ink, disabledGrey, disabledText, laneGrey, kerbWhite, arrowYellow, padStone, dirt, bagRed, tier = {1..6}, band = {easy, fair, hard, veryHard, brutal, impossible}, zone1 = {ground, ground2, structure, foliage, dark, accent}`. `Tokens.font = Enum.Font`-independent: `{ family = "Montserrat", weight = "Heavy" }` (the weight name is verified in M1-15).
- `Tokens.ui`: `outlinePx = 3, radiusPx = 4, lipPx = 5, shadowPx = 5, shadowAlpha = 0.35, panelPad = 10, gap = 8, header = 44, buttonH = 48, touchMin = 44, designW = 874, designH = 402, mouseScale = 0.75, studTilePx = 16, studTileMin = 12, studTileMax = 32, hussButtonPx = 120, hussButtonMinPx = 96, ringStartScale = 1.6, ringThickPx = 6, bandInner = 1.0, bandOuter = 1.15, bandThickPx = 10, ringLandScale (TEAM CALL, gui-designer: the scale at which the white ring's outer edge meets the hit band's centre, 1.075 unless the kit says otherwise), pipPx = 18, pipGap = 4`.
- `Tokens.stud`: `uiTileId` (0 until uploaded), `worldColorMapId`, `worldNormalMapId`, `worldRoughMapId` (0 until uploaded), `studsPerTile = 4`, `variantName = "Stud"`, `normalFlip = false` (decided by M1-12, section 13).
- `Models`: `creatures.z1_t1 = { model = "Boss_z1_t1", bodyType = 2, heightStuds = 4, groups = {...ids per group, filled by M1-12...} }`, `bags[1]`, `hazards[1] = "Hazard_Log"`, `gloves = { model = "Gloves", ... }`, `clips = { jab3 = <animation id>, bigThird = <animation id> }`.
- `Sounds`: `burstVoice = <F id>`, `F_BEAT_IN_FILE = {a, b, c}` (seconds, measured on the uploaded asset; before the probe the local-file values 0.007, 0.237, 0.42), `F_LEAD = 0.010`, `singleHuss = { <02 A id>, <01 A id> }`, `singleHuss01Gain = 1.25`, `thud = { bag1 = { ids... } }` (stand-in set), `swish`, `sting` (stand-in), all id 0 until uploaded/wired; `volumes = { burst = ..., thud = ... }`.
- `Effects`: `stars`, `cubeBurst` (declared, empty at M1), `stud map ids` as in `Tokens.stud` only if the builder prefers (one place: `Tokens.stud`).
- `Lighting`, `Dressing`: stay skeletons at M1 (M3).
- **The stub skin** (`Skins/stub`): same keys, grey `Color3`-free literals are allowed there; models are 5-group grey boxes with the right names; ids shown as names; no sounds. It is a fixture of about 50 lines. `Skin.Models` in the stub holds `model = "Boss_z1_t1_stub"`, built by `studio/CheckSkin.lua` at run time (not placed in the real place).

## G. The Chomp Frog model and the moving groups (modeler outputs; builder places; animator moves)
Creature `z1_t1`, body type 2 **squat stomper** (`Ids.BODY_TYPES`: 1 biped bruiser, 2 squat stomper, 3 tailed
striker, 4 charger, 5 rearing swayer, 6 flyer, 7 tentacled floater; the style guide's order). About 19 cubes tall
(cube about 0.2 stud, 4 studs high, `H = 4`). Model `Boss_z1_t1`, `PrimaryPart = Body`, attributes `CreatureId =
"z1_t1"`, `BodyType = 2`, `H = 4`, tag `HFB_Boss`.

| Group (MeshPart name) | Pivot (where it turns) | Notes |
|---|---|---|
| `Body` | middle of the feet, on the ground | the whole model's pivot; carries the belly, legs, back; the root |
| `Head` | the back of the jaw hinge | the upper face: eyes, brow, top of the head |
| `Sig` | the same hinge point as `Head` | the lower jaw block with the pink mouth inside: the chomp is `Sig` turning about the hinge (**TEAM CALL, modeler + animator**: the pack says "`Head` is the upper face and jaw block" and also lists `Sig` for a squat stomper's jaw; resolved as upper face = `Head`, jaw = `Sig`, both pivoted at the hinge) |
| `FistL`, `FistR` | the shoulder (the fist hangs from it); the yellow wrist band is part of the fist | big green block fists |
Neon cubes (none needed on Chomp Frog; eyes are matte) would be separate parts welded to their group, named
`<Group>_Neon<n>`. Colour route (B4): `atlas` (one shared 256 x 256 `boss-atlas`, cells 32 px, one mesh per
group) or `perRole` (one mesh per colour role per group, tinted by `MeshPart.Color`); the modeler builds both,
the builder imports both into a scratch folder, the modeler picks after the Studio check (M1-17) and writes the
pick and why to `team/decisions.md` as B4; B5 (one FBX per boss) is read off the same import. Joints: the setup
script (`studio/SetupBosses.lua`) puts a `Motor6D` per non-root group under `Body` (`Part0 = Body`, `Part1 =
group`, `C0`/`C1` set so `Transform = identity` is the rest pose and the joint turns about the group's pivot);
the animator drives `Motor6D.Transform` (**B11, TEAM CALL, animator-vfx** logs it; the alternative is the part's
own `CFrame`, which the animator only picks if Transform fails). Every group `Anchored = false`, `Massless`,
`CanCollide = false`, the model anchored by its `Body` while on a pad (`Body.Anchored = true`, the rest welded by
the Motor6Ds). Gloves: model `Gloves`, two meshes `GloveL`, `GloveR` (one mesh mirrored), pivot at the wrist.

## H. The move tables (`Shared/Moves/`; structure, not skin; fractions of the boss's height H)
```
Shared/Moves/squat.lua          the body-type set for body type 2: guard pose, idle, hit sizes, attack template,
                                lastHeart, gloat, defeat, halfIdle, carryRock
Shared/Moves/sig/z1_t1.lua      Chomp Frog's signature: "hops in and chomps, then a fist bop" (plan; style guide)
Shared/Moves/init.lua           Moves.get(bodyType) / Moves.sig(creatureId); the schema check
```
A move is `{ length: number, loop: boolean?, keys: { { t: number, ease: "Quad"|"Back"|"Sine", pose: { [groupName]: { p: {x,y,z}?, r: {x,y,z}?, s: number? } } } }, flashAt: number?, impactAt: number? }`
where `p` is an offset in fractions of H from the group's rest position, `r` is degrees about the group's own
pivot, `s` a uniform scale (the head is never scaled, Body stays within 0.85 to 1.15, a fist or Sig may pop to
1.2 on its impact frame). Move names (the keys the controller plays): `idle`, `guard`, `hitGood` (0.15 s),
`hitPerfect` (0.2 s), `hitBig` (0.3 s), `attack` (0.45 s, the signature, impact at about 0.21 s, held 0.06 s),
`lastHeart` (1.0 s), `gloat` (0.35 s, inside lastHeart), `defeat` (0.8 s), `halfIdle`, `carryRock`.
`BossMoves` API (`Controllers/BossMoves`): `play(model, name, opts?)` (`opts.perfect`, `opts.onImpact`,
`opts.onDone`), `loop(model, name)`, `stop(model)`, `isPlaying(model)`, `startPadIdle(model)`. A new `play` cuts a
running reaction and starts from its first frame. Nothing in BossMoves yields, waits on the ring or touches the
ring's state; it only reads events. White flash: `Highlight`-free; the animator picks (briefly neon-white
`Color` flash of the group meshes, restored on the next frame after 0.05 s).
Fight events -> moves (wired in `Controllers/Fight`, owner M1-07, from M1-09's API): fight started -> `guard`
(loop); a beat -> `hitGood` / `hitPerfect` / `hitBig`; `Fight.Heart` -> `attack` (`lastHeart` when `last`);
`Fight.State win` -> `defeat`; `loss` -> `lastHeart` already played, then `gloat`, then `idle`; fight ended ->
`idle`. On a pad with nobody fighting: `idle`.

## I. View interfaces (the gui-designer's Ui modules are views; the controllers drive them)
All take plain values; none reads the network or the clock.
- `Ui/HussButton`: `setMode("bag"|"fight"|"start"|"hidden")` ("start" = the button shows "HUSS!" in a boss ring and
  is how a fight begins), `setRing(progress: number?)` (0 = ring just started at 1.6x, 1 = landed; nil hides it),
  `landed(grade)` (the band and button flash `flashYellow` 0.08 s, star, "GOOD"/"PERFECT" pop), `missed()` (ring
  grey, button shakes), `pressed(bool)`, `pips(n)` (0..3 filled, with the pop; `clearPips()` after 0.15 s flash),
  `onTap(fn)`.
- `Ui/Counters`: `setPower(n)`, `setCash(n)`, `popPower(amount, big)` (the number flies to the counter, the counter
  bumps; the third bigger). Number shortening (B16) is M2: M1 prints full numbers with thousands separators.
- `Ui/FightOverlay`: `show(info)` (info = the `Fight.State` payload plus `bossName`, `tierWord`), `setHealth(h, max)`,
  `setHearts(n)`, `setBand(band)`, `hide()`, `onRun(fn)`.
- `Ui/Prompts`: `show(kind: "place"|"grab"|"start", glyphKind: "keyboard"|"gamepad"|"touch")`, `hide(kind)`,
  `onPress(kind, fn)`; the prompt shows the input glyph in use (the Input controller supplies the kind).
- `Ui/Kit`: `Panel`, `Button`, `Counter`, `StudTile` (the tiled `ImageLabel`, `ScaleType = Tile`, `TileSize` in
  Offset from `Tokens.ui.studTilePx` x current scale, clamped 12 to 32), `Scale` (the one `UIScale` rule,
  `min(w/874, h/402)` x 0.75 on mouse-and-keyboard), `Font`. A plain stand-in fill is used while
  `Tokens.stud.uiTileId == 0`.
- `Controllers/Input` supplies: `Input.kind()` ("keyboard"|"gamepad"|"touch", the `HFB_ForceInput` hook overrides),
  `Input.onPunch(fn)` (Huss button, left mouse or F, right trigger), `Input.onInteract(fn)` (E, X, prompt button),
  `Input.onRun(fn)` (Backspace, B, Run button). Bindings follow `docs/controls.md`.

## J. Avatar (Controllers/Avatar, M1-10)
`Avatar.equipGloves(character)` on spawn (R15 and R6; the gloves follow each hand), `Avatar.startJab(grade,
t0)` (plays the `jab3` clip, or `bigThird` is the clip's own third punch: **one clip with three contacts for Good
and Perfect alike; the third contact is the wider big-huss punch**, **TEAM CALL, animator-vfx**: the brief lists
"jab x3" and "big third punch" as two clips; M1 authors `jab3` (L, R, L jabs) and `bigThird` (the wide third) and
plays `jab3` for punches 1 and 2 and `bigThird` for punch 3, switched on the beats, so contact frames sit on the
beats; if switching clips on a beat cannot hold within one frame at 15 fps, the animator authors one combined
clip and logs why), `Avatar.cancel()`, `Avatar.flinch()` (**not asked at M1**), `Avatar.carryHold(on)` (M1-14 calls
it). Clip ids come from `Skin.Models.clips`. A clip with id 0 (before publishing) is a no-op that logs once.
Clips play on the player's own client; the server-made `Animator` is not required for M1.

## K. Session state at M1
`Data/Session.lua` holds the in-memory profile per player: `{ power, cash, strengthLevel = 1, speedLevel = 1,
carry = nil | {uid, creatureId}, spots = { [1..10] = { uid, creatureId, level = 1, stamp } } }`. `SaveOff` is
effectively always on at M1 (nothing is written). The M2 data-engineer replaces the module behind the same
functions (`get(player)`, `set`, `changed` signal). Every system reads and writes the session only through it.

## L. Test hooks v1 (add to `Shared/TestHooks.lua` and `team/test-hooks.md`; Workspace attributes `HFB_<Name>`)
State hooks are **consumed**: the server applies the value and clears the attribute.
`SetPower` (number), `SetCash` (number), `SetStrength` (number), `SetSpeed` (number, 1..10), `Wipe` (true), `GrantBoss`
(creature id: puts that boss on the player's head as if beaten), `PadFastBack` (seconds, replaces `FIXED_BACK_S`),
`LogForce` ("hit" = the log is on the player's path now; "clear" = it never reaches the carrier; both until
cleared), `ClockOffset` (seconds added to the server's hazard and pad clock). Client hooks (read by the client, not
consumed): `AutoTap` ("perfect" | "good" | "miss" | "mix" using `AutoMix = "45,45,10"`; the real client path taps
at the landing time, offset 0 for Perfect, 70 ms for Good, none for Miss; also "busy" = a Good tap then a tap 100 ms into the burst, ignored; "early" = a tap 0.5 s before landing, ignored, then a Good tap; "lag" = a Good tap then one frame held 0.45 s so beats 2 and 3 fire together; with AutoTap set, standing in a boss ring with no fight presses Huss once a second, M1-07e), `ForceInput` ("touch"|"gamepad"|"keyboard"),
`FrameCap` (60, 30 or 15: a busy-wait in Heartbeat to hold each frame to at least 1/cap s; RenderStepped ran only 6 to 12 times a second in the Studio play client, TEAM CALL M1-07g), `ReportBeats` (true: the client
sends `Profile.TestReport` named `beats` with `BurstClock.log` per burst). Existing: `ForceSkin`, `SaveOff`.
Tests clear what they set.

## M. Seconds to look at while building (what each owner must be able to say at the end)
First punch is the ring landing about 1.2 s after the player stands on the pad; the first Perfect needs the AutoTap
hook to be honest about the grade mix; the brief's first-session table is the yardstick for M1-18.
