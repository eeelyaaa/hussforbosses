# M1-26: the fight camera frames the boss (scripter, 2026-11-25)

Fix for: the avatar covered Chomp Frog (`m1-onscreen/fight-overlay-camera-blocked.jpg`). TEAM CALL M1-26 in `decisions.md`.
Quality pass: Function (projection checks in play mode). **Look is UNVERIFIED until the main session looks (below).**

## What changed (game repo `projects/huss-for-bosses/`)
- `src/StarterPlayer/StarterPlayerScripts/Controllers/Fight.lua`: removed CAMERA_BACK/UP/LOOK; `hold()` calls the new
  `Fight.frameBoss(boss, playerPos, cam)` (pure: reads `boss:GetBoundingBox()`, `H`, FOV, viewport; bisects the distance).
- `src/ReplicatedStorage/Shared/Config/Fight.lua`: `Fight.CAMERA` (SIDE_DEG 60, ELEV_DEG 25, BAND_LEFT/RIGHT/TOP/BOTTOM
  .06/.94/.28/.93, MIN_DIST_H 1.5, FIT_ITERATIONS 22, PAN_ITERATIONS 6).
- `studio/checks/FightCameraProbe.client.lua`: the check (a client probe; install as `StarterPlayerScripts.HFB_FightCamProbe`
  from the sync URL `/studio/checks/FightCameraProbe.client.lua`, removed after). Not wired into CheckAll.

## How it was run (Studio MCP, `studio` lock as `scripter-m1-26`, released)
Edit mode: sync, install the probe. Then `run_script_in_play_mode` (start_play): server sets `HFB_SetPower = 25`, moves the
player to 4.5 studs in front of `Zones.Z1.Pads.Fixed.Boss_z1_t1` (in the ring); the probe presses Huss when `inStartRing`,
waits 0.8 s, and reports through `Profile.TestReport` (`m126_<n>`, the server prints them as `[HFB] TestReport`).
Chomp Frog: H 4, bbox 7.3 x 3.8 x 3.1 (animated, so it moves a few %). Real Studio viewport 1235 x 479, FOV 70.

## Result (all PASS)
Boss box = 8 bounding-box corners projected; head = the boss's `Head` part; avatar = body parts. Real camera, then the same
`frameBoss` evaluated for each viewport with that viewport's aspect:

| viewport | boss box (u0 v0 u1 v1) | head | avatar covers head / boss | on screen |
|---|---|---|---|---|
| real 1235x479 (cam:WorldToViewportPoint: 0 corners outside) | .38 .29 .63 .96 | .40 .31 .54 .61 | 0% / 0% | yes |
| 1280x720 | .32 .28 .68 .93 | .35 .30 .55 .59 | 0% / 0% | yes |
| 874x402 (phone) | .35 .28 .65 .93 | .37 .30 .54 .59 | 0% / 0% | yes |
| 812x375 | .35 .28 .65 .93 | .37 .30 .54 .59 | 0% / 0% | yes |
| 1920x1080 | .32 .28 .68 .93 | .35 .30 .55 .59 | 0% / 0% | yes |

Avatar rect at 1235x479: u .14-.34, v .37-1.04 (lower left, feet cut by the screen bottom). FightOverlay rect
(real `AbsolutePosition`, union of its visible children) u .01-.64, v .09-.24 and HussButton u .78-.93, v .41-.81: neither
touches the boss box or head (0%). Camera ends 8.2 studs from the boss centre, 7.4 from the avatar.

Limits: the HUD rects come from the real Studio viewport and are reused as fractions for the other sizes (the kit scales,
but the phone's real rects were not measured); the box is the rest/guard pose and moves a few % in the animation.
Sweep (not kept in the file) showed side 40 puts the avatar over 2 to 30% of the boss; side 55 to 70 clears it.

## Gate (`team/verification/m1-16-gate.md` flow, edit-mode prepare, play calls, cleanup)
CheckSync 8/0, CheckSkin 11/0 (A2 now passes), Refusals live 6/0, CoreLoop a 22/0, CoreLoop b 36/0 (full fight, win, carry,
place, cash), NoDelay a 9/0 on the second run. NoDelay failed once with `lastHeart plays 0, last-heart events 1` (M1-20) and
passed on a re-run with no change: a timing flake at the end of the window, not the camera. NOT re-run: Refusals a/b,
BurstValues a/b, CoreLoop under the stub skin (they do not use the fight camera). Cleanup read back: 0 `HFB_` attributes,
no TmpChecks, no probe, `StudProofUi.Enabled` false, marker true.
Repo checks: `check_skin.py` 0 hits; `check_guard.py` 1 script without the guard, `studio/checks/FrogMoves.lua` (not mine).

## Re-look for the main session (UNVERIFIED until looked at)
In play mode (desktop and the phone emulator 874x402), step into Chomp Frog's ring at Power 25 and press Huss:
- The whole frog (head to feet, both fists) is visible and is the subject; the avatar sits at the lower left, small.
- The frog's face is not behind the avatar, the overlay (top) and the Huss button (lower right) do not cover it.
- Win, Run and Backspace return the normal camera (unchanged code path).
- Judge: does 60 degrees to the side read as a fight (the frog is seen three-quarter)? If too oblique, lower `SIDE_DEG`
  (55 is the lowest that cleared the head in the sweep).

---

# M1-26b: the server stands the player at a fight spot (scripter, Opus, 2026-11-25; retry under the stuck rule)

Why the first fix failed the main session's look (`m1-onscreen/fight-camera-retry-avatar-too-close.jpg`): the probe
placed the player at 4.5 studs, but a real player presses Huss wherever they are in the ring; walking in put the avatar
against the frog and the 60 degree camera still saw the avatar across most of it. Fixed at the cause (TEAM CALL M1-26b).
Quality pass: Function (projection checks in play mode). **Look is UNVERIFIED until the main session looks (below).**

## What changed (game repo `projects/huss-for-bosses/`)
- `src/ServerScriptService/Systems/Fight.lua`: `Fight.fightSpot(pad, fromPos, rootHeight, ignore)` and `standAtSpot`.
  At `Fight.begin`, after the freeze, the server pivots the character to the spot: on the line from the boss's box
  centre toward where the player stood, at the box's half-extent along that line + `GAP_H` x H (bigger tiers stand
  further), clamped to `RingRadius - EDGE_MARGIN` from the ring centre and short of any wall (one horizontal ray per
  tried line; excludes the boss, the character and `HFB_Blocker`, decision M1-12-3), facing the boss, root at the
  rig's height above the ring top. If that leaves under `MIN_GAP` of air on that side, the line turns in 15 degree steps
  (either way, up to 90) to the nearest side with room. Validated before moving (finite, on the pad, moved no further
  than the ring's diameter + slack + 10); otherwise no move and an `[HFB]` warning. `FightT.spot`; `Fight.State started`
  carries `spot: Vector3?` (Net.lua comment and `m1-contract.md` updated).
- `src/StarterPlayer/StarterPlayerScripts/Controllers/Fight.lua`: `hold(boss, spot)` sets the same CFrame locally at
  once (the client owns the character's physics and the server's move can arrive after the remote), zeroes velocity,
  then `frameBoss`. **Bug found and fixed:** `hold()` saved WalkSpeed/Jump after the server's freeze had already
  replicated (0) and `release()` wrote 0 back, so after Run the player could not walk (measured: client WalkSpeed 0,
  server 16). The client no longer touches WalkSpeed/Jump (the server owns them, B13); it keeps only AutoRotate.
  One automatic retry: a press while walking in reached the server before the character did and was refused `ring`
  (client 5.9 studs from the ring centre, server > 8); the client asks once more after `RING_RETRY_S` if still in the
  ring.
- `src/ReplicatedStorage/Shared/Config/Fight.lua`: `Fight.SPOT` (GAP_H 0.75, MIN_GAP 1.5, EDGE_MARGIN 0.5,
  AVATAR_RADIUS 1.5), `RING_RETRY_S` 0.25, `CAMERA.BAND_RIGHT` 0.94 -> 0.76 (a diagonal start put the box under the
  Huss button, measured u .78 to .93).
- `studio/checks/FightCameraProbe.client.lua`: rewritten to start fights the way a player does (below).

## How it was run (Studio MCP, `studio` lock as `scripter-m1-26b`, released after each batch)
Edit mode: `DevSync` sync, install the probe as `StarterPlayerScripts.HFB_FightCamProbe` from the sync URL, set the
check-only switch `Workspace.HFB_M126Spots` = `a` or `b`. Then one `run_script_in_play_mode` (start_play) per set: the
server sets `HFB_SetPower = 25` and waits for the probe's `m126_done` report. For each start spot the probe pivots the
character 10 studs out on that side, WALKS in with `Humanoid:MoveTo` and presses Huss (`Fight.requestStart`, what the
button calls) on arrival, or, for `press-on-entry`, the moment it enters the ring still walking at 16. 0.8 s after the
start it projects the boss box (8 corners), the boss's `Head`, the avatar's body parts and the HUD (FightOverlay union,
HussButton, real `AbsolutePosition`) for the real camera and for `Fight.frameBoss` at 1280x720 and 874x402; then Run
and wait out the 5 s pad cooldown. Pass per size: box fully on screen, avatar over the head < 0.5%, avatar over the box
< 15%, no HUD rect touching the box; plus WorldToViewportPoint on the real camera (0 corners outside).
Offsets are from the ring centre (233, 276); the boss box centre is (233, 275.5), box 6.8 x 4.0 x 3.0, H 4.

## Result: 32/32 PASS on the final code (set a 16/0, set b 16/0)
Stood = root distance from the boss box centre after the server's move. Avatar % = of the boss box; head always 0%;
HUD (overlay, Huss) over the box 0% in every row.

| start spot (pressed at, from boss) | stood | cam to boss | 1280x720 box u0 v0 u1 v1 / avatar % | 874x402 box / avatar % | real 1235x479 box / avatar % |
|---|---|---|---|---|---|
| zneg-near-face, walked to the face (3.4) | 4.50 | 8.2 | .22 .28 .60 .93 / 7 | .25 .28 .57 .93 / 8 | .27 .29 .55 .96 / 7 |
| zneg-press-on-entry, walking (5.4) | 4.50 | 8.2 | .22 .28 .60 .93 / 7 | .25 .28 .57 .93 / 8 | .27 .29 .55 .96 / 7 |
| zneg-ring-edge (5.4) | 4.50 | 8.2 | .22 .28 .60 .93 / 7 | .25 .28 .57 .93 / 8 | .27 .28 .55 .95 / 7 |
| xpos-side (5.8) | 5.52 | 8.2 | .18 .28 .64 .93 / 8 | .23 .28 .59 .93 / 9 | .25 .29 .56 .96 / 9 |
| xneg-side-near (5.0) | 5.53 | 7.9 | .16 .28 .67 .93 / 7 | .21 .28 .61 .93 / 7 | .23 .29 .57 .95 / 7 |
| zpos-ring-edge, behind (6.5) | 4.51 | 8.2 | .22 .28 .60 .93 / 7 | .25 .28 .57 .93 / 7 | .27 .29 .55 .96 / 7 |
| diag-xpos-zneg (5.4) | 5.15 | 6.1 | .09 .33 .77 .89 / 3 | .13 .29 .76 .90 / 3 | .16 .30 .70 .89 / 2 |
| zpos-near, behind (3.2) | 4.51 | 8.2 | .22 .28 .60 .93 / 6 | .25 .28 .57 .93 / 7 | .27 .29 .55 .97 / 7 |

Every start ends facing the boss (dot 1.00); WalkSpeed 16 / JumpPower 50 after each Run. Runs that failed on the way
(kept for the record): before the WalkSpeed fix, every fight after the first could not start (the player could not
walk); before the retry, `press-on-entry` was refused `ring`; with BAND_RIGHT 0.94, `diag` put the box under the Huss
button (3% at 1280x720, 1% at 874x402); one `ring-edge` run walked to 6.1 from the ring centre (MoveTo overshoot, no
prompt, no press), so the edge spots moved to 5.0.

Limits: the HUD rects are measured on the real Studio viewport and reused as fractions at the other two sizes (the
kit scales; the phone's real rects were not measured). The avatar rect is often partly off the left edge (u < 0): it
sits at the lower left, cut by the frame. The diagonal start puts the camera at the `MIN_DIST_H` floor (6.1 studs) and
the avatar large in the lower left (rect u -.65 to .15, v .37 to 1.6): it passes, but it is the frame to judge on screen.
Fight spots near walls were not exercised: the zone 1 pad has none within reach (the ray code ran, never hit).

## Gate (`CheckAll` flow: prepare, play calls, cleanup)
CheckSync 8/0 (7 + total), CheckSkin 13/0, Refusals live 6/0, CoreLoop a 22/0, CoreLoop b 36/0 (its fight starts from
`onPart(ring, 1, 1)`; full fight, win, carry, place, cash), Refusals a 19/0, Refusals b 32/0, BurstValues a 31/0,
BurstValues b 26/0, NoDelay a 9/0. No `[HFB]` warning in any run (the spot was never refused). NOT re-run: the two
CoreLoop calls under the stub skin (arm/disarm; nothing skin-related changed). Cleanup read back: 0 `HFB_` attributes,
no TmpChecks, no CheckProbe, no FightCamProbe, `StudProofUi.Enabled` false, marker true.
Repo checks: `check_skin.py` 0 hits, `check_guard.py` 30 scripts, 0 without the guard.

## Re-look for the main session (UNVERIFIED until looked at)
In play mode (desktop and the phone emulator 874x402), Power 25, Chomp Frog's pad:
1. Walk straight in from the track side and press Huss the moment the prompt shows: the avatar snaps to about 1.5
   studs of air in front of the frog, facing it; the whole frog is visible, avatar small at the lower left.
2. Walk to touching the frog's face and press: same picture (the server moves you back to the spot).
3. From the frog's side (+X) and from behind (+Z): the frog whole, its head clear of the avatar.
4. From a diagonal corner (about (+3.6, -3.6) from the ring centre): the closest camera of the set; judge whether the
   avatar looks too big in the lower left.
5. After Run: you can walk and jump at once (this was broken).
6. The snap itself: does the jump to the spot read as fine, or does it want a short slide (not built: new feel work).
