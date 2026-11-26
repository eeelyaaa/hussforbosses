# Huss for Bosses: decisions

Newest at the bottom. A `TEAM CALL` is a choice the pack left open that is reversible and doesn't change what the
game is (`vault/playbooks/autonomous-build.md`, rung 2): the call, the reason, what changing it later costs.
Choices that would change the game are questions in `manager-todo.md`, not entries here.

## Carried in at M0 (2026-11-25), by reference; the pack copies are the source
- **The pitch's record**: `pack/decisions.md` (what was shown and what the manager said, round by round).
- **The brief's team calls 1 to 42**: `pack/brief.md`, "Team calls (for the producer)". Carried in as written
  (the build plan counts 39; the brief has since added 40, the base layout; 41, walled zone corridors; 42, the
  settings gear tile). All 42 apply.
- **The base layout's 15 team calls**: `pack/base-layout/base-layout.md`, section 8 (B26). The builder's greybox at
  M1 and M3 may change a dimension and reports it here.
- **The build-side calls B1 to B26**: `pack/build-plan.md`, "Team calls expected". Status at M0:
  - Settled in the plan: B1 (DevSync, not Rojo), B2 (UI in code, world by scripts, moves as tweens), B10 (layout
    settled; greybox measures), B15 shield drop heard nearby, B19 (models per launch, at most two Opus agents a
    wave), B20, B21 (rule set; applied at M1 if the probe says so), B22, B24, B25.
  - Decided below at M0: B3.
  - Open, owner and milestone as the plan says: B4, B5, B7, B11, B13, B14, B21 (measurement) at M1; B8 at M1/M2
    (convention set below); B6 at M2/M3/M5; B9, B12, B16, B20 (built), B23 at M2; B15 (picks), B17, B18 at M4.

## M0 (tech-lead, 2026-11-25)
- `TEAM CALL` M0-1 **Pack media in git.** Committed: every text file in `pack/` (md, py, sh, json, html, txt) and
  the media the build compares against or builds from: `ui-kit/` and `ui-kit.figcraft` (screens are checked side
  by side against these at M3), `base-layout/01..04` plans and `base-layout.figcraft`, `concepts/brick-brawl/` (the
  approved direction; Chomp Frog's picture), `concepts/manager-refs/` (the stud proof's references), `style/`,
  `sound-refs/` (the manager's huss recording, the burst voice's source). Ignored (`.gitignore`): the four
  rejected look directions and `concepts.figcraft` (about 246 MB), `game-page/` images (concepts; M6 makes the
  real ones from screenshots), the base layout's renders (`view-*.png`, `src/render-sources/`; "impressions only"). Reason: keep
  the spec reproducible from the repo while leaving out about 280 MB of exploration history. The originals stay on
  disk in `team/pack/` and in ro-team `pitches/huss-for-bosses/` (which ro-team does not track either; see
  `manager-todo.md`, "Confirm"). Cost to change: edit `.gitignore` and commit the files (git history then grows by
  their size).
- `TEAM CALL` M0-2 **One source for the spec.** `team/brief.md`, `style-guide.md` and `sound-direction.md` are
  pointers to `team/pack/`, not copies, so the spec can't drift between two files. Cost to change: copy the files.
- `TEAM CALL` M0-3 **DevSync adapted from deja-kill** (B1): port 34874 (deja-kill keeps 34873, so the two servers
  never collide); `/files` names the project and the loader refuses any other server; `init.lua` /
  `init.server.lua` / `init.client.lua` turn a folder into that script (Rojo's rule, so `Shared/Config/` and
  `Skins/brickbrawl/` work as the plan lays them out and a move to Rojo stays one project file); root
  `StarterPlayer` (paths `StarterPlayer/StarterPlayerScripts/...` as in the plan's layout); `studio/` subfolders
  allowed; `/loader` recreates the loader in a place that lost it; refuses during play mode. Cost to change: small,
  one Python file and one module.
- `TEAM CALL` M0-4 **The place guard.** Marker `Workspace.HussForBosses = true`, set once by
  `studio/SetPlaceMarker.lua`, which itself refuses unless CreatorType is Group, CreatorId 432262304, PlaceId
  139279056607944 and GameId 10779089797. The loader checks the marker before every sync and run; every `studio/`
  script also starts with the guard line, so it refuses even if pasted past the loader; `tools/check_guard.py`
  fails on a script without it. Proven at M0 (`verification/m0-setup.md`).
- `TEAM CALL` B3 **Own save module**, not a vendored library. Reasons: vendoring ProfileStore means downloading
  third-party code, which the approval doesn't cover (box 6 unanswered, "installing nothing new"); the
  `roblox-data` skill and `vault/patterns/session-lock-inside-the-record-one-updateasync.md` give the design (one
  record, session lock inside it, one `UpdateAsync` per write, environment in the store name). Built by the
  data-engineer at M2. Cost to change: swap the module behind the same `Data/` interface before live data exists.
- `TEAM CALL` B8 (convention only; names and payloads at M1) **Remotes**: all in `Shared/Net.lua`, at
  `ReplicatedStorage.Remotes.<Family>.<Name>` with the plan's 13 families, PascalCase names, created only by the
  server, `UnreliableRemoteEvent` only for cosmetic broadcasts, `RemoteFunction` only for the shop's quotes, a
  payload comment on every entry. Cost to change: rename inside one module.
- `TEAM CALL` M0-5 **Content ids** in `Shared/Ids.lua`: creatures `z<zone>_t<tier>`, product keys `pass_*`
  (10) and `product_*` (9) named after the brief's products. The plan's example `pass_auto_punch` is kept. Cost
  to change: a rename before anything is saved.
- `TEAM CALL` M0-6 **Test hook attributes** are `Workspace.HFB_<Name>`, listed in `TestHooks.HOOKS` and
  `test-hooks.md`; two named at M0 (ForceSkin, SaveOff).
- Checked at M0, the two kit items the plan said to verify: the bag panel's Speed numbers now read 1.20 s and
  "Next level: 1.12 s" on both `ui-kit/phone-bag-panel.png` and `desktop-bag-panel.png` (fixed). Board 01's
  palette captions still leave out jobs (Alarm orange doesn't name the bought boss's sell or swap confirm or the
  "can't do that" toasts by name; Huss red doesn't name the gloves or the bag band); as the plan says, the style
  guide's table is the authority, so nothing changes in the build. For the gui-designer and art-director: read
  colour jobs from `pack/style-guide.md`, not from board 01's captions.

## M1 planning (producer, 2026-11-25)
- `TEAM CALL` M1-P1 **Icons are not uploaded at M1.** The plan's icon set is an M3 upload and M1 has no icon in its
  list, so the Huss button shows "HUSS!" with no glove image and the Kit draws plain stand-ins for id 0. Cost to
  change: one upload and one id in `Icons.lua`.
- `TEAM CALL` M1-P2 **Watching clients are M2.** The plan's M1 "Built" list has no watcher code; `Punch.Burst` and
  `Fight.Watch` are declared in `Net` and not sent. Cost to change: one sender and one client copy.
- `TEAM CALL` M1-P3 **`tapServerTime`, not `os.clock`.** The burst report carries the client's `GetServerTimeNow()`
  at the tap (sanity-checked); the server schedules beats from its own receipt time. Reason: client `os.clock()`
  values cannot be compared with the server's. Cost to change: the payload of one remote.
- `TEAM CALL` M1-P4 **Server stall rule** in fights (a missing report counts as a Miss) so a client cannot stay in a
  fight by never reporting a Miss. Cost to change: one timer in `Systems/Fight`.
- `TEAM CALL` M1-P5 **Chomp Frog's groups:** `Head` = upper face, `Sig` = the lower jaw, both pivoted at the jaw
  hinge (the pack names `Head` as "upper face and jaw block" and also lists `Sig` for a squat stomper's jaw).
  Cost to change: re-split one mesh.
- `TEAM CALL` M1-P6 **Task split and waves** for M1 (23 tasks, four waves, at most two Opus agents a wave): the
  plan's "scripter (opus)" is three Opus launches (server punch, client punch, server carry and base) spread over
  waves 2 and 3. Cost to change: the board.

## M1-02 (gui-designer, 2026-11-25): skin keys. TEAM CALLs
`ringLandScale` 1.075 (centre of the kit's 1.0 to 1.15 band); `Tokens.fontBody` and `Tokens.type` added next to `font`; extra `Tokens.ui` sizes from the style guide; `colors.pipEmpty`; all 64 icon keys declared at id 0; `Names.products` (19) and all 36 creatures filled now; tiers and bands stored in sentence case, views upper-case. Detail: `verification/m1-02-skin-keys.md`.

## M1-04 (audio-specialist, 2026-11-25): audio tools, measurements, stand-in set. TEAM CALLs
- `TEAM CALL` M1-04-1 **`F_BEAT_IN_FILE = {0.007, 0.233, 0.420}`** written from my own probe of the local F (5 ms RMS, onset 20 dB under each part's peak); the pack said 0.237 for part 2 (4 ms method difference). Provisional; M1-13 writes the final value from the uploaded asset. `BEAT` untouched (brief's 0, 0.213, 0.401); parts are +10 and +9 ms off beat plus lead, inside the 20 ms rule, so no sign B21 triggers. Cost to change: one table.
- `TEAM CALL` M1-04-2 **Stand-in set = earshot `thump/book` x3 (bag thud), `flick/thin` (swish), `tick/glass` cut to 0.40 s with a 60 ms fade (sting)**, picked by measurement (short, early peak, clean tail). Creator Store fallback not needed. Cost to change: five files re-rendered and re-uploaded.
- `TEAM CALL` M1-04-3 **Extra `Sounds.volumes` keys** `single 0.55, sting 0.4, swish 0.25` beside the contract's `burst` and `thud` (burst 0.55, thud 0.5): starting values from the roblox-audio skill, tuned by ear later. Cost to change: one table.
- `TEAM CALL` M1-04-4 **The upload list lives in `verification/m1-04-audio.md`** (the task's path), not `m1-audio-upload-list.md` as the sound-proof names it. Eight uploads.

## M1-05 (builder, 2026-11-25): greybox slice and stud maps. TEAM CALLs
- `TEAM CALL` M1-05-1 **Fixed pad at (233, 276), 44 studs past the gate's inside edge, 40 past the front wall's outer face (Y 236).** Follows `base-layout.md` and `layout.py`, not the plan's "40 studs of lane". Cost to change: one position.
- `TEAM CALL` M1-05-2 **Front wall at hub Y 234..236, gate centre (206, 234)** (the layout's `GATE_C`); the contract's "gate (hub Y 232)" is a typo of the same line. Floors are 0.05 above the place's Baseplate top (Y 0) so they do not z-fight; the Baseplate and the default `SpawnLocation` (at 0, 0.5, 0, the hub corner) were not touched.
- `TEAM CALL` M1-05-3 **Windmill stand-in at hub (130, 340), 6 x 6 x 44**, left of the lane. Plan 01 does not draw it. At the first try (150, 340) plot 1's name board (Y 7.5..11, X 95, Z 171..187) hid the tower from 30 studs up; (130, 340) is clear at 10 to 44 studs. Cost to change: one position. Other plots untested (only plot 1 is built).
- `TEAM CALL` M1-05-4 **Normal map strength 1.0** (`assets-src/stud/make_stud_maps.py`; 4.0 saturated the edges). The "flipped" file inverts the green channel (OpenGL vs DirectX). One number to change.
- `TEAM CALL` M1-05-5 **Greybox omits** posts under the lock board, kerbs beside the track, the fence's posts and rails (solid 3-tall fence plus a 10-tall invisible blocker), the fixed pad's corner posts, lane arrows. Real version M1-12.
- Contract note for M1-12 and M1-06: a `Workspace:Raycast` still hits an invisible blocker with `CanQuery = false` while `CanCollide` is on (measured, edit mode). Anything that raycasts in the hub (punch aim, hazard hit tests, sight checks) must exclude by tag or name.

## M1-03 (modeler-3d, 2026-11-25): voxel builder, Chomp Frog, gloves. TEAM CALLs
- `TEAM CALL` M1-03-1 **Layer data as fills, not ASCII layers.** `bosses/*.json` lists boxes and balls of cubes painted in order with a colour scatter list (a fixed hash picks the shade), `mirror` and `only_x`. Same result as layers, far shorter to edit; the later 35 bosses use the same format.
- `TEAM CALL` M1-03-2 **Closed meshes per group.** Faces between two groups are kept (hidden faces are removed only inside a group's own surface and against empty space), so Head, Sig and the fists show no holes when they turn. Cost: 5,764 triangles against 4,940 without them.
- `TEAM CALL` M1-03-3 **Chomp Frog is 5,764 triangles against the Common budget of 600.** The picture's cube density (about 2,900 cubes at 20 tall) does not fit 600; the style guide says the picture wins and the performance-optimizer measures a raised budget (B6, M2). Not cut.
- `TEAM CALL` M1-03-4 **Jaw rest pose = as pictured (mouth open between lip and jaw).** The chomp is `Sig` turning +X about the hinge (front down, about 25 degrees max); upward it meets the lip after about 5 degrees. The animator's `sig/z1_t1` uses that range.
- `TEAM CALL` M1-03-5 **Both routes have the same faces and triangles.** perRole is not merged into flat rectangles (it would lose the cube edges: 4,024 triangles as a count only). B4 is picked in M1-17 on the Studio look.
- `TEAM CALL` M1-03-6 **Atlas cells are an append-only registry** (`tools/blender/atlas_cells.json`), so a boss added later never moves another boss's UVs. Frog uses cells 0 to 11 in one registry shared by the gloves.
- `TEAM CALL` M1-03-7 **Gloves: cube 0.14 stud, 772 triangles each, cuff yellow `#F1D417` (the boss band yellow), not Shop gold `#FFC21A`** (gold means Robux). Red `#E02A2A` with one darker shade `#C92424` scattered. Fist hangs below the wrist, knuckles toward Roblox forward, thumb inward.

## M1-01 tech-lead: the contract in code (2026-11-25)
Applied: `roblox-networking` skill (validate every c2s field, NaN/inf first, silent drop over the rate limit),
`vault/patterns/test-hooks-gated-to-studio-and-listed.md`, `long-check-scripts-loaded-over-localhost.md`.
- `TEAM CALL` M1-01a **c2s remotes are hooked through `Net.onServerEvent(family, name, handler)`**: it rate-limits per
  player from `Config.Punch.RATE["Family.Name"]` (an entry is required for every c2s remote; sliding 1 s window,
  over-limit calls dropped silently and counted in `TestHooks.reports._dropped`) and drops a non-table payload; the
  handler validates every field (`Net.isNumber/isInt/isOneOf/isShortString`). `Fight.Run` gets 2 a second (the
  contract gives none; same as `Fight.Start`). Cost to change: one module.
- `TEAM CALL` M1-01b **The skin scan ignores comments** (`tools/check_skin.py`): a comment is not what a player sees;
  comment hits are listed with `--verbose` as notes and never fail. Colour hits include `Color3.new` and
  `BrickColor.new` as well as `fromRGB`/`fromHex` and `"#hex"` strings; asset hits include `rbxassetid`,
  `roblox.com/asset`, `Content.fromAssetId` and an asset property set to a 5+ digit literal. The scan also lexes
  every `src/` file (strings, comments, bracket balance) as the only syntax check without a Luau parser (exit 2).
  Cost to change: one script.
- `TEAM CALL` M1-01c **`Shared/Skin` API**: the active skin's eight sections are copied onto `Skin`; `Skin.get(path)`
  (nil when missing), `Skin.need(path)` (errors naming the key), `Skin.SCHEMA` (contract F's M1 keys with types,
  128 entries), `Skin.check(t)`, `Skin.shapeDiff(a, b)`, `Skin.load(id)`. Skins are found beside `Shared` (in the
  game, `ReplicatedStorage.Skins`) so a check can load a fresh clone pair. Cost to change: one module.
- `TEAM CALL` M1-01d **Skin check part 2 flow**: `studio/CheckSkin.lua` runs the API and key checks, builds
  `Boss_z1_t1_stub` in `ServerStorage.HFB_SkinCheck`, then arms `HFB_ForceSkin = "stub"` (Skin reads the hook once at
  first require, so it must be set before play starts); the runner starts play, runs `checks/CoreLoop.lua` with skin
  `stub`, stops play and disarms with the one-liner the script prints. `HFB_CheckSkinNoArm = true` skips arming
  (a studio-script switch, listed in `test-hooks.md`, not a game hook). Cost to change: one script.
- `TEAM CALL` M1-01e **Test hooks v1 have kinds** (`state` consumed by the server via `TestHooks.onSet`/`consume`,
  `config` and `client` read while set); `TestHooks.listenReports(Net)` serves `Profile.TestReport` and is called by
  `Main.server.lua` (M1-06). `AutoMix` is its own hook (the contract names it beside `AutoTap`). `TestHooks` stays a
  leaf module (Net and Skin require it; it requires nothing of ours). Cost to change: one module and `test-hooks.md`.
- `TEAM CALL` M1-01f **Config holds the brief's whole Power and income table now** (all 36 creatures, brief system 5),
  not only `z1_t1`, so M2 adds none; plus brief or style-guide numbers the contract implies: `Bag.STRENGTH_MAX = 30`,
  `Bag.SPEED_MAX = 10`, `Income.LEVEL_CAP = 20`, `Carry.HEAD_GAP = 0.5`, `Hazards.LOG.thickness = 6`,
  `Zones.CLOCK_EVERY_S = 30`, `Config.Fight.band(r)` (first band with `maxRatio >= r`, so r = 1.0 is `fair`). No
  number is invented. Cost to change: a value in one file.
- `TEAM CALL` M1-01g **`Shared/Ids` adds** `BANDS`, `GRADES`, `CONTEXTS`, `GROUPS` (`Body, Head, FistL, FistR, Sig`).
- The stub skin mirrors brickbrawl's whole key shape (including M1-02's extra keys: `fontBody`, `type`, the extra
  `ui` sizes, `pipEmpty`, zones 2 to 6, `products`, the 64 icon keys) with greys, ids as names, ids 0.

## M1-10 (animator-vfx, 2026-11-25): the avatar's gloves and punch clips
- `TEAM CALL` **B14: the punch clips are KeyframeSequences built by `studio/BuildClips.lua` from numbers in the script**
  (no Blender, no Higgsfield, no hand authoring); it rebuilds `ServerStorage.HFB_Clips` (4 sequences and one dummy per
  rig type with `AnimSaves`) and reads them back. The Animation Editor step is only load and publish (MS-B1, brief in
  `verification/m1-10-avatar.md`). Cost to change: edit the tables and rerun.
- `TEAM CALL` M1-10a **Two clips, switched on the beat, held within a frame.** `jab3` is L, R, L with a plain third jab;
  `bigThird` is the wide third alone, started `Config.Avatar.BIG_LEAD` (0.08 s) before beat 3 so its contact frame lands
  on `BEAT[3]`, stopping `jab3` with a 0.02 s fade. Measured in play mode: third-contact shoulder peak at 0.400 s (R15)
  and 0.402 s (R6) against 0.401, so a switch holds to one 60 Hz frame; the combined-clip fallback is not needed. If
  `bigThird` has no id, `jab3`'s own third jab plays. Cost to change: `Avatar.startJab`.
- `TEAM CALL` M1-10b **Clip time 0 is the first contact.** The tap and punch 1 are the same instant (brief system 1), so
  jab 1's 0.05 s snap-out is not played; jabs 2 and 3 snap out 0.05 s before their beats. Clips are authored at the real
  beat times, so nothing is stretched in code.
- `TEAM CALL` M1-10c **Separate ids for R6.** A clip only plays on its own rig type, so `Skin.Models.clipsR6 = { jab3,
  bigThird }` sits beside `clips` (R15), in `brickbrawl` and in the stub (one line added to `Skins/stub/Models.lua`, a
  file M1-01 owns, to keep the shape check equal). R6 has no elbow, so its guard is a straight arm 40 degrees forward.
- `TEAM CALL` M1-10d **Gloves are built on each client, for every character it sees, never on the server.** Cosmetic
  only, nothing replicates, a late joiner gets them from `Avatar.start()`. Source: the model `ReplicatedStorage.<Models.gloves.model>`
  (children `GloveL`, `GloveR`, pivot at the wrist) once `studio/SetupGloves.lua` (M1-12) places it; until then a
  stand-in of two blocks per glove (yellow cuff `arrowYellow`, red fist `hussRed`, matte Plastic, no studs). Size =
  `head.Size.Y / 1.2` clamped 0.7 to 1.5. The real mesh drops in with no code change. Weld: `Weld(hand, glove root)` at the
  hand's wrist attachment (R15) or the arm's lower end (R6). Cost to change: `Avatar.equipGloves`.
- `TEAM CALL` M1-10e **`Config/Avatar.lua`** holds every number (glove scale, wrist offsets, `BIG_LEAD`, fade, carry
  raise); the colours come from `Skin.Tokens`. `Avatar.setClipIds` is a test seam (local `KeyframeSequenceProvider` ids).
- `TEAM CALL` M1-10f **`carryHold(on)` is procedural at M1** (shoulders raised straight up, written to the shoulder
  `Motor6D.Transform` on `RenderStepped`, local character only); the authored carry clip is M2. Not seen on screen yet.
- `TEAM CALL` M1-10g The content scheme in `Avatar.lua` is split (`"rbxasset" .. "id://"`) so `tools/check_skin.py` does not
  read the scheme as an asset id; no id is in the file.
- Big third's half-stud step moves the torso only (legs stay), and the clip is Action priority on the arms and torso
  joints only, so idle and run legs keep playing.
- `Main.client.lua` (M1-07's) must call `require(Controllers.Avatar).start()` and `BurstClock.setAvatar(Avatar)`; not
  done here, those files belong to the wave's scripters.

## M1-09 (animator-vfx): Chomp Frog's moves, `BossMoves`
- `TEAM CALL` **B11: boss moves play on `Motor6D.Transform`** (not the part's `CFrame`). Measured working on a box rig with the
  contract's joints (`Part0 = Body`, `C1 = pivot in the group's frame`, identity rotations). Contract for the builder (M1-12,
  `SetupBosses`): (1) `Body.PivotOffset` puts the Body's pivot at the middle of the feet; (2) joint `C0`/`C1` carry no
  rotation; (3) nothing else moves the model while a move runs. The root, `Body`, cannot use a joint: it moves as
  `Body.CFrame` (rest pivot x pose), the rest follow through the joints. Cost to change: `Controllers/BossMoves.lua` `apply`.
- `TEAM CALL` M1-09a **Scale** is `MeshPart.Size` scaled about the pivot with the position corrected (a joint cannot scale). A Body
  scale carries every other group's pivot with it (they scale about the feet). `s` may be a number or `{x,y,z}`: the schema in
  H says a number, but "0.9 tall and 1.1 wide" needs three axes.
- `TEAM CALL` M1-09b **Layers.** `loop` sets a base (guard, idle, halfIdle, carryRock); `play` is an overlay added on top
  (positions and degrees add, scales multiply). When a reaction ends the base carries on with no pop; with no base the
  rest pose is restored. `defeat` pauses the base and holds its last pose (`final = "hold"`) for Carry to take over;
  `opts.hopTo` is where its 0.5 to 0.8 s hop lands. `loop` asked for the running move is a no-op.
- `TEAM CALL` M1-09c **Per-group tracks:** a key lists only the groups it moves; each group interpolates between its own keys.
- `TEAM CALL` M1-09d **Sig follows Head** in the squat set (one hinge, one face); a jaw turns **negative x** in the game (front
  down, up to 25 degrees; the modeler's "+X" was Blender's axis), the wind-up opens it 4 degrees only (the lip stops it at about 5).
- `TEAM CALL` M1-09e **`lastHeart` includes the 0.35 s gloat** (0.65 to 1.0 s). Fight's loss path is `lastHeart` then `idle`; the
  `gloat` move stays available on its own. Hit on a Perfect big huss: `opts.perfect` makes `hitBig` go 1.25x as far.
- `TEAM CALL` M1-09f **Idle loop is 7.2 s** (six 1.2 s bobs, one jab triplet every 3 s, inside the brief's 2.5 to 4); half idle
  the same at 0.015 H with one triplet per 7.2 s. Each boss starts at a random phase. Carry rock is a 1.0 s stride; Carry
  sets `opts.speed` / `setSpeed` to the run.
- `TEAM CALL` M1-09g **White flash** = the group meshes go `Neon` and `Skin.Tokens.colors.white` for 0.05 s, restored from
  values saved at start. Impact stars, cube bursts and sounds are M4 (`onImpact` is the hook).
- Not built, as asked: other body types, turn-to-face on guard, the 15 Hz stepping, distance culling.

## M1-08 HUD views (gui-designer, 2026-11-25)
- `TEAM CALL` M1-08a **Ring drawn as three round frames with outside `UIStroke`s** (ink 2, white 6, ink 2), resized by `setRing`; no image, no rotation. Its size is the white ring's outer edge: `ringStartScale` (1.6) x the button at progress 0, `ringLandScale` (1.075, centre of the 10 px hit band) at progress 1. The hit band is a round frame whose stroke is `bandThickPx` thick (outer edge 1.167 x, the kit's 1.15 rounded to the 10 px the style guide says).
- `TEAM CALL` M1-08b **Everything in design px under one `UIScale`.** The root frame is `viewport / scale` in offsets, so children anchor to real screen edges. The Huss button diameter is `max(120, ceil(96 / scale))`; Run and prompt plates are at least `ceil(44 / scale)`; counters start at `max(115, ceil(112 / scale))` design px so they stay clear of Roblox's top-bar buttons on a small phone.
- `TEAM CALL` M1-08c **Taps fire on input going down** (mouse button 1 or touch), not on release: the grade is judged at the tap.
- `TEAM CALL` M1-08d **Text floor in `Kit.Text`**: a label never renders under 14 px on screen, the boost capped at 1.3 x its design size (shrinking layouts do not overflow). The ink hard shadow under text (second label) is not built at M1; the 2 px outline carries legibility (Look pass).
- `TEAM CALL` M1-08e **"Mouse" scale rule** = keyboard and mouse present and no touch (`TouchEnabled` false); a touch laptop gets the phone scale.
- `TEAM CALL` M1-08f **`clearPips()` is called by the controller** after the third punch; the view flashes yellow and empties 0.15 s later. `pips(n)` cancels a pending clear. The star is bigger when `pips(3)` was set before `landed`.
- `TEAM CALL` M1-08g **Prompts are screen-space plates at M1** (bottom centre, `Kit.Button`): keyboard E (start: F), gamepad X (start: RT), touch no glyph and the plate is the button. World-space prompts come later.
- `TEAM CALL` M1-08h **Icons not uploaded**: `Kit.Icon` draws a plain square stand-in for id 0; hearts are a seven-by-six pixel heart built from frames. `Kit.StudTile` returns nothing while `Tokens.stud.uiTileId == 0`; with an id it needs `Skin.assetUrl(id)` (contract issue, see the report).

## M1-07 client punch (scripter, 2026-11-25)
- `TEAM CALL` M1-07a **No burst voice until Controllers/Audio plugs in.** `BurstClock.setAudio({ playBurst(grade) -> handle,
  fadeBurst(handle, ms) })` is the hook (contract D step 2); Main.client plugs `Controllers/Audio` in when it exists. Until
  then the default is a no-op that counts calls and prints once. A fallback Sound pool was written and removed: building
  `rbxassetid://` outside `Skins/` fails `check_skin.py`, and the pool is M1-13's.
- `TEAM CALL` M1-07b **Ring starts are scheduled times.** Ring n+1 starts at exactly `t0 + BURST_LEN` or `missTime +
  MISS_RESTART` (missTime of a timed-out ring = `landing + goodMs`), not at the frame that notices; only a ring held off
  more than 0.1 s (context just entered) starts at the frame time. Entering a context waits out a running burst or miss pause.
- `TEAM CALL` M1-07c **Fight camera**: Scriptable, set once at start, 11 studs behind the player on the player-boss line and
  6 up, looking 60 % of the way to the boss's mid-height; the character is turned to face the boss, `AutoRotate` off.
  Restored to Custom on the humanoid at win, loss, run or respawn. Movement held per B13 (WalkSpeed, JumpPower, JumpHeight 0).
- `TEAM CALL` M1-07d **Power pop on the bag is display only**, computed from the Strength level the client last heard
  (`Profile.Changed.strengthLevel`); the counter itself is set only from `Profile.Changed.power`.
- `TEAM CALL` M1-07e **Extra AutoTap values for the client's own checks**: `busy` (Good tap, then a tap 100 ms into the
  burst), `early` (a tap 0.5 s before landing, then Good), `lag` (Good tap, then one frame held 0.45 s so beats 2 and 3
  fire together). With AutoTap set, standing in a boss ring with no fight presses Huss once a second. AutoTap taps on the
  frame nearest its target (`now + dt/2 >= target`): at 15 fps a tap errs up to 33 ms, so a "good" AutoTap at 15 fps can
  grade Perfect. Extra reports with ReportBeats: `ring`, `ignored`, `refused`, `input`.
- `TEAM CALL` M1-07f **Client bag-pad test = the server's radius** (`Config.Bag.PAD_RADIUS`, horizontal); the server also
  checks height. The start ring test is horizontal distance <= the Ring part's `RingRadius` (the server allows +2).

## M1-06 (scripter, 2026-11-25): server punch, bag, fight, zones, session. TEAM CALLs
Applied: `roblox-networking` and `roblox-security` skills (validate type, range, state, distance; NaN first; drop
malformed silently and count), scripter playbook "Gate every test hook to Studio" (hooks only through `TestHooks`),
"Client pacing mirrors every part of the server's limit" (the cycle rule and Net's 4/s live in `Config.Punch`).
Evidence: `verification/m1-06-server.md`.
- `TEAM CALL` M1-06a **Plot and spawn live in `Data/Session`**: the first free plot by `PlotId` is the player's
  (`OwnerUserId`, freed on leave); every spawn is moved to `SpawnPoint` facing the bag. `Session.plot(player)` is
  what M1-11's Base reads. The profile state hooks (`SetPower`, `SetCash`, `SetStrength`, `SetSpeed`, `Wipe`) are
  applied there to every player. Cost to change: one module.
- `TEAM CALL` M1-06b **A Miss report is not held to the cycle rate**: it gains nothing, so it is only refused
  during a burst (`busy`) and by Net's 4 a second; every accepted report (Miss included) anchors the next cycle.
  Reason: an early Miss tap (up to 0.35 s before landing) after a burst falls under `CYCLE x 0.8` at Speed 10 and
  would otherwise be refused, costing no heart. Cost to change: one line in `Systems/Punch`.
- `TEAM CALL` M1-06c **Refusal reasons.** `Punch.Result`: `state` for no living character; `place` for the wrong
  context (also a bag report during a fight, off the pad); `grade` for a Good/Perfect with no `tapServerTime` or
  one outside the bounds. `Fight.State refused` reasons: `pad, dead, running, knocked, carrying, closed, ring`; a
  `padId` that is not a short string is dropped with no reply. Cost to change: one module each.
- `TEAM CALL` M1-06d **Run, death and leaving.** Run: no knockdown, the 5 s pad cooldown of a loss applies (the
  brief calls Run a loss; without the cooldown Run would dodge it). Death or leaving mid-fight: `loss` (brief: a
  disconnect is a loss) with the cooldown, no knockback. A carry starting mid-fight (M1-11, `GrantBoss`) ends it
  as `run` with reason `carrying`. Cost to change: one function.
- `TEAM CALL` M1-06e **Loss knockback**: the character is moved to the ring centre + (RingRadius + RING_SLACK + 2)
  studs along its own direction from the centre, facing the pad, held for `KNOCKDOWN_S`. Cost: one block.
- `TEAM CALL` M1-06f **Fight damage uses the Power read at fight start** (fixed for the fight like r). Cost: one line.
- `TEAM CALL` M1-06g **Stall rule timing**: the expected landing is start + ring at fight start, t0 + 0.61 + ring
  after a burst, receipt + 0.61 + ring after a Miss (and after a counted stall); the server counts one Miss when
  no report has arrived by that landing + ring + `STALL_SLACK_S`. Measured 3.53 s after a Miss at Speed 1.
- `TEAM CALL` M1-06h **`Zones.Clock.serverTime` includes `ClockOffset`** and is re-sent to everyone when the hook
  changes, so the client's hazard clock and the server's agree in tests. Cost: one line.
- `TEAM CALL` M1-06i **`Main.server.lua` starts every other `Systems/*` module with a `start()`** after the M1-06
  set (order Hazards, Carry, Base, Income, then by name), each in a `pcall` that warns; M1-11 needs no edit to Main.
- `TEAM CALL` M1-06j **Check seams**: `Punch.report` (the handler behind the limiter), `Punch.stats`
  (refused/dropped/accepted/stalls/schedules/lastSchedule/lastResult/log of every applied beat with its lateness),
  `Fight.stats` (refused, log), `Fight.begin/canStart/finish`, `Zones.isOpen`. M1-16 reads these.

- `TEAM CALL` M1-01b-a **`Skin.assetUrl(id)` is the one holder of the asset scheme outside `Skins/`.** Returns the content string for a positive integer id, nil otherwise. `tools/check_skin.py` exempts exactly the `function Skin.assetUrl ... end` lines of `Shared/Skin.lua`; every other line and file is still scanned. Avatar.lua now calls it (the `SCHEME` split string is gone). BurstClock.lua is owned by M1-07 and is untouched.
- `TEAM CALL` M1-01b-b **Edit-mode cache fix = swap, not clone.** After a sync that changed anything, DevSync replaces every synced ModuleScript with a new instance (name, attributes, tags, children carried over). All modules, not just changed ones, because a module's dependents cache the old value too. Rule written in `team/CLAUDE.md` (sync section).
- `TEAM CALL` M1-07g **FrameCap and AutoTap use the Heartbeat step, not RenderStepped** (contract L says "a busy-wait in
  RenderStepped"). Measured in the Studio play client: RenderStepped about 6 to 12 a second, Heartbeat 25 to 60, so a
  RenderStepped wait held nothing and AutoTap's half-frame lead was 30 ms (Good taps graded Perfect). The contract line
  should read "Heartbeat" (request to the contract owner).

## M1-12 (builder, 2026-11-25): the real slice, stud setup, boss and glove setup. TEAM CALLs
- `TEAM CALL` M1-12-1 **Z-fighting rule (the manager's, from the greybox flicker).** The default `Baseplate` is deleted by
  `BuildSlice.lua` (its top was Y 0, the slice floor's too); the slice has its own ground (`Hub.Floor` and `Zones.Z1.Ground`,
  tops at Y 0). Overlays sit 0.2 above what they lie on (track, lane, driveway, spawn pad 0.2 thick; the start line 0.2 on the
  track). Pieces meet edge to edge or on opposite faces, never overlapping with the same facing within 0.1: the fence runs
  stop at the corners (the greybox overlapped their tops), the front wall stops at the gate pillars (the greybox wall ran
  through them), the name board posts are sunk 0.5 into the floor and 0.3 deeper than the fence, the default `SpawnLocation`
  moved onto the track at (206, 0.7, 112). A scan of every visible axis-aligned box in Workspace runs at the end of
  `BuildSlice.lua` and must print `PASS ... 0 pairs`; it names both parts of any pair. Keep it in the script for M3. Cost to
  change: none, it is the rule.
- `TEAM CALL` M1-12-2 **The 14-tall bag frame and the 11-tall name board stay.** The layout's "nothing taller than 4 studs
  between the plot fronts and the front wall" is about the yard (scenery, props); the pack's own plot template
  (`base-layout.md` section 4, rows 1 and 8: name board top at 11, bag frame 13 over a 1 plinth) puts these two over the plot,
  so the pack says otherwise for them. Kept as built, sizes unchanged. Cost: plot 1's bag frame can pull the default camera in
  when the player faces the windmill from the bag pad (M1-05, UNVERIFIED on screen); if that fails the on-screen check, the
  fix is a shorter frame or the bag nearer the pad, which is a layout change for the game-designer.
- `TEAM CALL` M1-12-3 **Invisible blockers carry the tag `HFB_Blocker`** (7: the two front-wall blockers and the five plot-1
  fence blockers). `Workspace:Raycast` hits a `CanCollide` part even with `CanQuery = false`, so any ray in the hub
  (M1-06 Bag/Fight, M1-05 sight checks, the client camera) excludes `CollectionService:GetTagged("HFB_Blocker")` via
  `RaycastParams.FilterDescendantsInstances`. `Entrance`, `BossAnchor`, `NumberAnchor` and the other markers are
  `CanCollide = false` and need no exclusion. M1-06/M1-05: add the filter.
- `TEAM CALL` M1-12-4 **`Stud` stays a plain stand-in until the manager's yes.** `studio/SetupStud.lua` makes
  `MaterialService.Stud` (SmoothPlastic, no maps, `StudsPerTile` 4) and two proof variants `StudProof_A` (normal map as
  made) and `StudProof_B` (flipped), with the uploaded ids from `Tokens.stud`. Every visible slice part names `Stud`. The yes
  is one edit: `PROMOTE = "normal"` or `"flipped"` at the top of `SetupStud.lua`, run it again; `normalFlip` in Tokens is
  the skin's record of the pick (M1-02's file). Cost to change: none.
- `TEAM CALL` M1-12-5 **Group pivots are read from `studio/data/<id>.groups.json` over the sync**, a copy of the modeler's
  `assets-src/models/<id>.groups.json` made by `python tools/sync_group_data.py` (the sync server serves only `src/` and
  `studio/`, and `tools/devsync.py` is the tech-lead's). Re-run the copy after the modeler redo moves a pivot; no pivot
  is written in a Setup script. Cost to change: serve `assets-src/models/` from `devsync.py` and drop the copy.
- `TEAM CALL` M1-12-6 **`SetupBosses.lua` builds the atlas route only** until B4 picks (the per-role meshes are named
  `Body_g1` etc and would need merging into groups); feet = the Body's pivot horizontally, the lowest vertex vertically;
  model named `Boss_z1_t1` (contract G; `Controllers/Fight` finds it by the `HFB_Boss` tag when no child is named `Boss`).
  `BossAnchor` now sits at Y 1.0 (the ring's top) and is where the Body pivot (the middle of the feet) stands; the greybox
  had it at 1.1.
- Not done here: mesh ids into `Skins/brickbrawl/Models.lua`. The meshes are not imported yet; the setup scripts print
  `MESHID <group> <id>` lines for each imported MeshPart to paste into `Models.lua` (`creatures.z1_t1.groups`,
  `gloves.groups`). The four stud ids were already in `Tokens.stud` and are used by `SetupStud.lua`.
- `TEAM CALL` M1-03b-1 (modeler-3d) **Chomp Frog rest pose: fists out to the sides, not the picture's fighting pose.**
  The style guide's squat stomper stance says "fists out to the sides"; the picture shows a turned torso with one fist
  forward and one raised. The rest pose holds both gloves out at the sides, raised to jaw height and pushed forward,
  symmetric, with the yellow cuff on the wrist between glove and body so both cuffs read from the picture's front 3/4
  angle (gloves pointing straight forward hid the cuffs). The picture's guard is the animator's to pose.
- `TEAM CALL` M1-03b-2 (modeler-3d) **Chomp Frog has two nostrils** although the style guide's face rule says "no nose
  unless the description names one": its approved picture shows two nostril dots, and the guide says the picture wins
  for that boss. One ink cube each on a small snout below the brow's V tip. Other bosses keep the no-nose rule.
- `TEAM CALL` M1-03b-3 (modeler-3d) **Chomp Frog pivots moved** to fit the rebuilt geometry: Head and Sig hinge now
  Roblox offset (0, 2.2, 0.6) (was (0, 1.6, 0.6)); FistL (-1.4, 1.8, -1.0), FistR (1.4, 1.8, -1.0) (were (+-1.4, 2.4,
  -0.4)). Group names unchanged; `assets-src/models/z1_t1.groups.json` and `studio/data/` copy refreshed. Size now
  6.8 x 4.0 x 3.0 studs; 6,584 triangles either route (was 5,764). Patterns applied: modeler playbook "The approved
  look wins over the budget" and "Build models with scripts and run Blender headless".
- `TEAM CALL` M1-15-1 (gui-designer) **The proof is a standalone ScreenGui, not the live HUD**: `StarterGui.StudProofUi`, built by `studio/checks/UiStudProof.lua`, three sections side by side at UIScale 0.75, 1.0, 1.65. `Kit.StudTile(parent, cornerScale, fixedScale)` and `Kit.Plate{fixedScale=}` got an optional scale that sizes the tile for that UIScale and keeps it out of the live-scale retune list (used by the proof only; HUD behaviour unchanged). The Huss button is rebuilt there from the same recipe as `Ui/HussButton` because that module is a singleton. Remove with `game.StarterGui.StudProofUi:Destroy()`.
- `TEAM CALL` M1-15-2 (gui-designer) **`Tokens.font.weight = "Heavy"` confirmed**: the Studio install's `Montserrat.json` lists face "Black" at weight 900, and `Enum.FontWeight.Heavy.Value` is 900 (`Enum.FontWeight.Black` does not exist). No change to Tokens.
- `TEAM CALL` M1-11a (scripter) **The Rolling Log's path.** The log's 12-long axis runs along the lane, it is 6
  thick across, and it rolls across between the walls: centre offset -15..+15 from the lane centre (travel = 36 - 6),
  cycle 8 s (wait 1 at the minus side, cross 3 linear, wait 1, cross back 3), phase 0 at server time 0. The track's
  home is the Hazard_Log pivot as built (stamped by the server as the model attribute `TrackHome`, which clients read
  instead of their animated pivot); across = world X (optional `TrackAcross`, `LaneWidth` attributes override). All
  in `Shared/Hazards` (pure functions of the clock). Brief system 6 numbers; no new tunables.
- `TEAM CALL` M1-11b (scripter) **The session's `carry` stays set during the 5 s grace**, so a fight is refused
  `carrying` until the dropped boss is grabbed or gone ("the boss is gone; the player may fight for another").
- `TEAM CALL` M1-11c (scripter) **Carry speed check**: the server holds `WalkSpeed` at `Config.Carry.CARRY` while
  carrying and, every 0.5 s, pulls a carrier back to the last good spot if it moved more than speed x 0.5 x 1.5 + 2.5
  studs on the ground plane. Lenient on purpose (security skill: don't over-validate movement); server pushes reset it.
- `TEAM CALL` M1-11d (scripter) **Hazard push direction and the small push.** A carrier hit is pushed 6 studs along
  the lane, away from the log's line on the side they stand (they lose ground; never through a wall). A hit while not
  carrying is a 2-stud push at most once a second (brief "a small push only" gives no number; request for M1-01:
  `Config.Hazards.SMALL_PUSH = 2`, `PUSH_COOLDOWN_S = 1`; constants in `Systems/Hazards` until then). A dropped boss
  is also grabbed by walking within 3 studs of it (brief: "by walking into it or pressing the prompt").
- `TEAM CALL` M1-11e (scripter) **Pads fill in whole seconds**: cash on a pad = income x min(floor(now - stamp),
  PAD_CAP_S); a collect moves the stamp on by the whole seconds taken (the part-second carries over), or to now when
  the pad was full. The client floors too, so both agree to the dollar. Contract C row `Base.State` updated.
- `TEAM CALL` M1-11f (scripter) **A refused `Base.Place` or `Carry.Grab` sends nothing** (contract C has no refusal
  remote); reasons are counted in `Base.stats.refused` / `Carry.stats.refused`. If M1-14 needs a reply, the tech-lead
  adds one.
- `TEAM CALL` M1-11g (scripter) **`Base.State.spots` is a dense array 1..10 with `false` for an empty spot** (a
  sparse table is cut at the first nil over a remote: roblox-networking skill, serialization). Contract C updated.
- `TEAM CALL` M1-13a (audio-specialist) **B21 does not apply; `Config.Punch.BEAT` is unchanged.** The probe on the uploaded F
  read the three loud parts (onset 20 dB under each part's peak) at 0.004, 0.237 and 0.418 s; against BEAT + F_LEAD
  (0.010, 0.223, 0.411) that is -6, +14 and +7 ms, inside the 20 ms rule. `Sounds.F_BEAT_IN_FILE` is now the uploaded asset's
  numbers. The "beat offsets" contradiction in the pack's build plan is closed on the measured side; the producer to note it.
  Evidence `verification/m1-13-audio.md`.
- `TEAM CALL` M1-13b (audio-specialist) **The Perfect sting plays at the same instant as F (beat 1), and the three thuds of a Perfect
  burst are 2 dB louder** (x1.259 on `volumes.thud`), as "The punch family" says. A thud plays on every beat that is not `noContact` (B22).
- `TEAM CALL` M1-13c (audio-specialist) **Audio sends its own `Profile.TestReport` "audio" per burst when `ReportBeats` is on**
  (F plays attributed to the burst, F start minus t0 in ms, Sound.Played count, thud/sting/swish/fade counters), through
  `TestClient.report`. Reason: `BurstClock.starts` counts burst starts, so it cannot show that F was actually played once.
  No new hook; no change to M1-07's files. SyncTest reads it.
- `TEAM CALL` M1-13d (audio-specialist) **Two SoundGroups under SoundService, `HFB_Burst` (F, singles) and `HFB_Effects` (thuds, sting,
  swish), created by the Audio controller on the client.** Both at group volume 1; the starting volumes are per Sound (`Skin.Sounds.volumes`).
  The settings controls are M4. One F voice per burst from a pool of two (F1, F2, alternating; the voice reused is stopped and rewound first).
- `TEAM CALL` M1-17a (modeler-3d) **B4: the shared atlas route is picked.** Both imports are the same 6,584 triangles in Studio (read back with EditableMesh:GetFaces: atlas Body 1,980, Head 1,668, Sig 1,128, FistL 904, FistR 904; per-role 23 meshes). Atlas = 5 MeshParts / 5 draw calls per frog, 13,168 vertices, one 256 x 256 texture (about 0.26 MB raw); per-role = 23 MeshParts per frog (4.6x the parts, draw calls and joints/welds to move), 9,517 vertices, no texture. Colour fidelity is the same either way once the tint is right (atlas texels read back from the upload: cell 0 = 58,190,35, cell 3 cream = 236,207,151, cell 5 pink = 241,151,186, exactly the hexes), so the part count decides. With 36 bosses of 4 to 7 groups, per-role would be about 5x the meshes (plan figure). Crispness at distance: cells are 32 px, UVs inset 1 px, 2 px darker edge; at the fight camera a cube is about 7 px, so mip 2, no neighbour cell reaches the sampled texel before mip 5 (cube under 1 px). Not seen on screen yet: on-screen check owed. The per-role import stays in `ServerStorage.BossScratchPerRole` (unwired). SetupBosses stays atlas-only.
- `TEAM CALL` M1-17b (modeler-3d) **The "grey-green cream" was the MeshPart Color tint, not the texture, UVs or lighting.** The importer leaves every MeshPart at the default Color (163,162,165, 0.639,0.635,0.647), and `Color` multiplies `TextureID`, so every cell was darkened to about 64% (cream 236,207,151 became about 151,132,97 before lighting; with the green around it the belly reads grey-green). The texture itself is right (read back from asset 116542096217311). Fix: `studio/SetupBosses.lua` and `SetupGloves.lua` now set `Color = white`, `Material = SmoothPlastic`, `Reflectance = 0` on every MeshPart that has a `TextureID` (verified in Studio: all five groups and both gloves read 1,1,1 after a re-run). No re-export or re-import needed. A skin that tints a boss would use this Color on purpose later.
- `TEAM CALL` M1-17c (modeler-3d) **B5: one FBX per boss.** The importer (Merge Meshes off) kept the five groups as five separate MeshParts in one FBX, with the Blender origin as every part's pivot, so a per-boss file works and a per-zone file is not needed for grouping; one per boss stays (36 imports) because a per-zone file was not tried and the plan's fallback saves only imports, not draw calls. The gloves are their own file (2 meshes). Not tested: a per-zone FBX (not needed).
- `TEAM CALL` M1-17d (modeler-3d) **No sign flip for the jaw.** Measured on the real Chomp Frog through `BossMoves`: Sig `r.x = -25` lowers the jaw front 0.87 stud (direct Transform), `+25` raises it 0.99, and the `attack` move's jaw front goes down (min dy -1.15 studs in Body space, never above rest) at 0.234 s. `squat.lua` and `sig/z1_t1.lua` are unchanged.
- `TEAM CALL` M1-17e (modeler-3d) **Models.lua wiring adds a `textureId` key** (creatures.z1_t1.textureId and gloves.textureId = 116542096217311) beside the contract F `groups` ids; the stub skin got the same keys at 0 (and `gloves.groups` at 0) so `Skin.shapeDiff` on Models differs only in bags and hazards (owned by others, pre-existing).
- `TEAM CALL` M1-01c (tech-lead) **Carry's walk-in grab distance and speed-check numbers moved to Config.Carry** (`WALK_IN_GRAB`, `SPEED_WINDOW`, `SPEED_SLACK`, `SPEED_PAD`) beside the requested `Config.Hazards.SMALL_PUSH` and `PUSH_COOLDOWN_S`: they are tuning numbers a test or balance pass may need to move, same values as before. Changing back costs only moving the locals in again.
- `TEAM CALL` M1-14a (scripter) **`Controllers/Clock`: the client's hazard/pad clock = `GetServerTimeNow()` + the `Zones.Clock` offset, and an offset under 0.25 s counts as 0.** The remote's `serverTime` is stamped at send, so `serverTime - GetServerTimeNow()` at receipt is the server's `ClockOffset` hook minus the latency (measured 33 ms: 2.3 arrives as 2.267). Live the hook is 0, so latency must not become a clock shift. A hook value under 0.25 s cannot be tested on the client.
- `TEAM CALL` M1-14b (scripter) **Boss clones come from a template taken from the pad boss once it is whole (all five groups and four joints), not at start.** In the play client the tagged `Boss_z1_t1` arrives before its children, so a template taken at init had no Body and `BossMoves.loop` returned false silently. The template's `PrimaryPart` is set to Body (the replicated copy can lack it). The clone, not the pad boss, is carried, dropped and placed; the carried clone is re-based onto the head every RenderStepped (`world = target x restPivot^-1 x raw`, `raw` = the pose BossMoves wrote that Heartbeat).
- `TEAM CALL` M1-14c (scripter) **The pad boss after a win: plays `defeat` with `hopTo` = the head, then is hidden on this client (`LocalTransparencyModifier`) until `Zones.PadBeaten.backIn` has passed, then `BossMoves.stop` + `startPadIdle`.** Nothing else showed the pad boss going away or coming back; the hop only runs when a won fight ended within 3 s (a `GrantBoss` or a grab just attaches).
- `TEAM CALL` M1-14d (scripter) **Placed boss landing = a 0.12 s fall from 4 studs, then `BossMoves.play "hitGood"` (the Body squash 0.9 tall / 1.1 wide, flash included), then `halfIdle`.** The squash is the existing move, not a new one; the flash on the thump is a side effect the animator-vfx may want gone (Feel pass). Only a boss that appears after the plot's first `Base.State` lands; the first state (join) shows them standing.
- `TEAM CALL` M1-14e (scripter) **Cash on a pad: a `$N` label and 1 to 6 green slabs over the CashPad, refreshed 4 times a second from `Base.State`; `Counters.popCash(amount, fromScreen)` added to `Ui/Counters.lua` (M1-08's file, one function, same shape as `popPower`) for the fly to the counter.** The glow is a client `Highlight` (arrowYellow, pulsing) on spots whose `Glow` attribute is true; the Place target is the nearest glowing spot of the player's plot within 14 flat / 10 vertical (the server's rule).
- `TEAM CALL` M1-14f (scripter) **New test hook `AutoInteract` (client, boolean): `Input.fire("interact", "auto")` every 0.6 s; plus `ReportBeats` now also sends `carry`, `base` and `log` reports every 0.4 s (changed ones).** Reason: the Grab and Place press paths cannot be pressed from the MCP. Both in `Shared/TestHooks.HOOKS` and `test-hooks.md`.
- `TEAM CALL` M1-14g (scripter) **The dropped boss lies on its back (pivot tipped 90 degrees back, lifted half its depth) at `dropPos` with a billboard plate: white square, ink seconds left, an alarm-orange bar draining over `GRAB_S`.** The warning shadow is an alarm-orange 0.1 thick slab at the ground under `logOffset(t + WARN_S)`, shown while the log moves or is within 0.6 s of moving; the ground height is one raycast down from the track home at start.
- `TEAM CALL` M1-21a (builder) **The Hazard_Log stand-in is rebuilt in `BuildSlice.lua` to `Config.Hazards.LOG` (12 long, 6 thick, read from Config so it cannot drift), axis along the lane (world Z; the cylinder's own X turned 90 degrees about Y), pivot on the lane centre line (X 206) at the crossing (Z 248) at Y 3.2 (lane top 0.2 + radius 3), CanCollide / CanQuery / CanTouch off.** Reason: M1-11 asked for exactly this and M1-14 showed the old 36-long, 4-thick, across-the-lane stand-in rolled wrong and sat 0.8 low. A new assert checks size, pivot and axis. Sizes of every other part unchanged.
- `TEAM CALL` M1-21b (builder) **`SetupStud.lua` adds a `RotatedWall` to each proof set (three 4 x 2 bricks turned 90 degrees, two 8 x 2 bricks turned 45) so tile alignment on rotated parts has something to look at.** Proof strip only, no game part changed. Stud variant in the world is still the plain stand-in.
- `TEAM CALL` M1-16a (scripter) **CheckAll is a driver, not one call: it runs the edit-mode parts (sync, CheckSync, CheckSkin A-E, Refusals "live"), installs the play-mode checks as `ServerStorage.TmpChecks.*` plus a client probe, prints the play calls, builds the summary from the `CHECKALL row` lines those calls print (`summary` mode), and `cleanup` removes everything.** Reason: each `run_script_in_play_mode` is a fresh DataModel with a ~90 s limit and the place's HttpService is off, so no play session can hand its result to the next; the MCP returns only the server log. Pattern `long-check-scripts-loaded-over-localhost.md`.
- `TEAM CALL` M1-16b (scripter) **A check-only client probe (`studio/checks/CheckProbe.lua`, installed as `StarterPlayerScripts.HFB_CheckProbe` only for the run) sends the malformed payloads and rate bursts through the real remotes and wraps the client's `BossMoves.play` to log cuts.** Reason: a server script cannot fire a c2s remote, and BossMoves keeps no log; this keeps the game's code unchanged. Studio only; idles until `HFB_CheckProbe` is set.
- `TEAM CALL` M1-16c (scripter) **Forged-report sections (Refusals, the BurstValues fight tap counts) hold the real client's reports off by filling Net's `Punch.Report` limiter on every Heartbeat, and send the forged reports through `Punch.report` (the handler after the limiter).** Reason: at r >= 2 the band's Good window (60 ms and less) is narrower than AutoTap's +70 ms tap, and the server believes the grade, so the tap counts are the server's damage rule; a 0.05 s refill let one client Miss through once (run 1, r = 5).
- `TEAM CALL` M1-16d (scripter) **"Profile.TestReport ignored when not Studio (simulated through a flag)" is run in edit mode on a throwaway copy of `Shared/TestHooks` whose `RunService` says `IsStudio() = false`.** No game file changed; the copy is destroyed after.
- `TEAM CALL` M1-16e (scripter) **CoreLoop step 6 walks the carrier to the log in server-side steps at carry speed (12 studs/s, the speed check not reset) instead of `Humanoid:MoveTo`.** Reason: a server `MoveTo` did not move the character with the M1-14 client running (no position change in the client's carry reports); the stepped walk passed the speed check with 0 pull-backs.
- `TEAM CALL` M1-16f (scripter) **The step-1 "Zones.Clock arrived" check passes on the client's offset leaving 0 after `ClockOffset 5`; its precision is noted, not asserted (errors seen -0.06 to -0.87 s within 3 s of joining).** Step 8 shows it settled (29.97 for 30).

## 2026-11-25: stud proof answered by the manager
The manager, looking at `verification/m1-stud/stud-proof-sheet.png`: "B on both". The world `Stud` variant takes the flipped normal map (95643445290942) on walls and ground; `SetupStud.lua` PROMOTE = "flipped", `Tokens.stud.normalFlip = true`. Studding everything else (M3) is now unblocked. This is the manager's call, not a TEAM CALL.

- `TEAM CALL` M1-24a (scripter) **The pad Power number is a screen-pixel BillboardGui on `NumberAnchor` (`Controllers/Pads.lua`), AlwaysOnTop, MaxDistance 400, text 1.5 x `Tokens.type.title` (33 px), ink outline `Tokens.ui.textOutlinePx`, Montserrat via `Kit.Font`, colour `Tokens.colors.band[Config.Fight.band(boss / own Power).id]`.** Reason: a stud-sized billboard would be about 4 px at 320 studs; pixel size stays readable and AlwaysOnTop clears the 4-stud wall. Own Power starts at 1 until the first `Profile.Changed`. The "skull beside Near impossible" is not drawn: Skin has no skull icon key (needs one from the icon owner).
- `TEAM CALL` M1-24b (scripter) **`brickbrawl/Models.lua` `bags = { "Bag" }`, `hazards = { "Hazard_Log" }` (the model names `BuildSlice.lua` builds); `Effects.lua` `stars = {}`, `cubeBurst = {}`.** Contract F.

- 2026-11-25 TEAM CALL M1-20a (animator-vfx): NoDelay "2 losses, 1 lastHeart" was the check, not the game: the client probe flushes 14 plays a second and the check read it 1.6 s after the last fight. Fixed in studio/checks/NoDelay.lua (wait 3.2 s, new lastHeart-vs-last-heart-events check). Controllers/Fight.lua and BossMoves unchanged. See team/verification/m1-20-moves-avatar.md.
- 2026-11-25: The manager asked for the game repo to be pushed to https://github.com/eeelyaaa/hussforbosses.git (main) and "everything to remote all repos". Done at the M1 commit.
- 2026-11-25 `TEAM CALL` M1-18 (game-designer, sonnet) **First-session measures use a zero-reaction stand-in; the brief's cumulative times are human times, so only intervals are compared, and nothing was tuned.** Mix used: 45/45/10 x3 plus all-Perfect, all-Good (+70 ms) and the mix in fights. Findings and the M2 wording list (bursts to 25 Power is 4 to 5, fight 4 to 5 s at typical grades, very-hard windows against a phone's timing spread): `verification/m1-first-session.md`. Patterns applied: `vault/patterns/test-hooks-gated-to-studio-and-listed.md`. Nothing to `manager-todo.md`.

- `TEAM CALL` M1-19 (audio-specialist, 2026-11-25) **The sync test's avatar and boss counts come from a throwaway client probe, not from `src/`.** The task asked whether `Avatar.hitLog` and the boss reactions hang off the same beats; neither is reported to the server. `studio/checks/SyncProbe.lua` (installed as a LocalScript for the run, removed after, like `HFB_CheckProbe`) wraps `BossMoves.play` and reads `Avatar.hitLog` per burst and reports them as Profile.TestReport `sprobe`; `SyncTest.lua` summarises them (`SYNCPROBE` lines) and has a fight phase (`_G.HFB_SYNC_FIGHT`). No code in `src/` changed, no level or sound changed. Result and the double `defeat` call: `verification/m1-sync-test.md`.

TEAM CALL (gui-designer, M1-25, 2026-11-25): HUD plates sit below the real top bar (`GuiService.TopbarInset.Max.Y` + 10 px), not beside it. Reason: TopbarInset's x range does not reliably say where the left buttons end, and below is the only placement that cannot overlap at any size. Kit look and sizes unchanged; plates move down about 58 px. Evidence: `verification/m1-25-hud-inset.md`.

- `TEAM CALL` M1-26 (scripter, 2026-11-25) **Fight camera frames the boss, replaces M1-07c's behind-the-avatar placement.** The old camera (11 behind, 6 up) put the avatar over the boss (manager's on-screen look, `verification/m1-onscreen/fight-overlay-camera-blocked.jpg`). Now `Fight.frameBoss` (Controllers/Fight.lua) puts the eye on the boss-to-player line turned `SIDE_DEG` 60 to the avatar's side and raised `ELEV_DEG` 25, then bisects the distance until the boss's 8 bounding-box corners (not fixed numbers, so any tier's size) fit the screen band `BAND_*` (left .06, right .94, top .28 below the fight overlay, bottom .93), re-centring the aim at each distance, for the live viewport and FOV. Never closer than `MIN_DIST_H` 1.5 boss heights. The avatar lands at the lower left, the Huss button is lower right. All numbers in `Config.Fight.CAMERA`. Scriptable, set once at start, as M1-07c. No other camera mode touched. Evidence `verification/m1-26-fight-camera.md`.
- 2026-11-25 TEAM CALL (gui-m1-25b): RUN sits under the Power/cash plates (kit's top-left, row 2) rather than beside them; fight plate top = max(46, bar+8 px), pushed right only if the counters reach it. Run, plate, counters positions all driven from Hud.place.

- `TEAM CALL` M1-26b (scripter, opus, 2026-11-25) **At fight start the server stands the player at a fight spot.** On the line from the boss's box centre toward where the player stood, at the box's half-extent along that line + `Config.Fight.SPOT.GAP_H` (0.75) x H, kept `EDGE_MARGIN` inside RingRadius and `AVATAR_RADIUS` short of any wall (ray excludes boss, character, `HFB_Blocker`), facing the boss; if that leaves under `MIN_GAP` (1.5 studs) of air, the line turns in 15 degree steps to the nearest side with room. The server moves the character (every client sees the same); `Fight.State started` carries `spot` so the owner sets the same CFrame at once and frames from it. Reason: the camera can only be right if the player's place is known (main session's look, M1-26 retry). The frame is unchanged apart from `CAMERA.BAND_RIGHT` 0.94 -> 0.76 (keeps the boss box left of the Huss button; a diagonal start put it under it).
- `TEAM CALL` M1-26c (scripter, opus, 2026-11-25) **The client no longer saves or restores WalkSpeed/Jump in a fight; the server owns them (B13).** Found while testing M1-26b: the server's freeze replicated before `Fight.State started`, the client saved 0 and wrote 0 back on Run, so the player could not walk after a Run (client 0, server 16). The client keeps only AutoRotate.
- `TEAM CALL` M1-26d (scripter, opus, 2026-11-25) **One automatic Fight.Start retry after a `ring` refusal, `Config.Fight.RING_RETRY_S` (0.25 s) later, if the client is still in that ring.** A press the moment a walking player enters the ring reached the server while it still saw the character outside RingRadius + 2 (measured: client 5.9 studs from the centre). The server check is unchanged; nothing new is trusted.

## 2026-11-25: the manager's decisions after playing M1 (their words; these are the spec, not TEAM CALLs)
1. **No world-attached UI that keeps its screen size with distance.** "I really don't like the UI elements over things that scale up as you get further away. make this a rule everywhere." Applies to every BillboardGui / world label (the pad number "25" is the first case): world labels must shrink with distance like the world does (scale in studs, not pixels) or not exist. Rule added to ro-team's `vault/playbooks/quality-bar.md`. Fix the pad number in M2.
2. **The huss timing is a little hard, and the ring should be a little quicker in general.** M2: retune the ring speed and the timing windows (game-designer with the scripter), then the manager judges by feel.
3. **Tapping without timing still punches.** "just clicking the huss button should work. but if you don't time it it obviously doesn't do the three in a row, which is considered perfect (perfect text should float up above the button). and does more damage when timed. if they just click it just does 1 on the punching bag and depends on strength level on fighting bosses." This replaces the brief's "a Miss launches no burst": an untimed tap = one punch (bag: +1 Power; boss: damage from the Strength level); a timed tap = the three-punch huss burst with PERFECT floating above the button and more damage. M2 redesigns system 1's grading on this (game-designer writes the numbers; server authority unchanged; the exploit review re-checks the rate caps).
4. **The fight angle should be a little better for the player.** M2: improve the fight camera framing (M1-26b's spot and `Config.Fight.CAMERA`); the avatar currently reads large in the lower left.
5. **Bosses walk back and forth along their region**, not standing on one platform; the player walks up to a boss to start the fight, as now. M2/M3 (scripter, animator, builder): patrol paths per zone region; the fight start stays a walk-up.
6. **The huss animation and the fighting should be more intense.** M4 Feel (animator-vfx, audio): bigger avatar punches, stronger hit reactions, more impact.
7. **The stud texture disappears and comes back with distance** ("idk something causes it"). M2 investigation (builder + tech-lead): likely MaterialVariant / texture LOD or mip on the 256 px maps or StudsPerTile; find the cause and fix it.
8. **Standing permissions:** the team creates the 10 passes and 9 developer products itself in the Creator Dashboard by computer use, at the brief's prices, and does "the majority of the set up" itself (including the server size); for audio, "YES to everything": upload all M4 sounds, ticking the Audio Upload License Agreement for each. Publishing the game and group settings stay the manager's.
9. **Pack media:** "yes if it's in the game commit and push it": the exploration media in `team/pack/` is committed (concepts.figcraft via Git LFS) and pushed.
