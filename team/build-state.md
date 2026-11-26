# Build state: huss-for-bosses

The orchestrator rewrites this file before and after every wave. A new session reads it first and trusts files and
`git status` over anything written here about work "in flight".

Updated: 2026-11-25
Milestone: M1 (Core feel and the four proofs) — CLOSED, closed by the producer (M1-23); commit pending (orchestrator)
Stop at: M1 (`/build huss-for-bosses until M1`)

## Next action
M1 is closed and committed; the build stopped here as asked (`until M1`). Next: the manager starts M2 in a new chat with `/build huss-for-bosses` (or `until M2`). The M2 producer reads `requirements/m2-carryover.md` first.

## Done this milestone
- M1 plan: board + 10 requirement files incl. `m1-contract.md`, producer (sonnet). TEAM CALLs M1-P1..P6.
- M1-01 contract in code, tech-lead (opus): `verification/m1-01-contract.md`
- M1-02 skin keys, gui-designer (sonnet): `verification/m1-02-skin-keys.md`
- M1-04 audio tools and measurements, audio-specialist (sonnet): `verification/m1-04-audio.md`
- M1-05 stud maps and greybox, builder (sonnet): `verification/m1-greybox.md` (all within 2% of the layout). The manager saw z-fighting on the greybox (floors 0.05 above the Baseplate): fix in M1-12.
- M1-03 voxel builder, gloves, Chomp Frog in Blender, modeler-3d (sonnet): `verification/m1-chomp-frog.md`. Picture match FAILED by the orchestrator's look (head reads as a flat box with a cap; picture has a domed head, angry V brow, jutting jaw, splayed legs). Redo queued on opus.
- After wave 1: sync 31 files; CheckPlace PASS, CheckSync PASS, check_skin 0 hits, check_guard 0 missing; CheckSkin 11/13 (the 2 FAILs are keys owed by M1-10/M1-12). Stub hook disarmed.
- MS-A1 audio uploads (manager's yes in chat for the license agreement on these 8 files): F 127740860120528, 02A 133382295573645, 01A 87792871818595 listed under the group; ids written to `Sounds.lua` and `assets.md`. The 5 stand-ins appeared after ~2 min of listing lag; all 8 ids in `Sounds.lua` and `assets.md`.
- M1-06 server punch/fight/zones/session, scripter (opus): `verification/m1-06-server.md` (60 PASS)
- M1-08 HUD views, gui-designer (sonnet): `verification/m1-08-hud.md` (270 PASS at 4 sizes; on-screen looks owed)
- M1-07 client input/ring/burst clock/fight controller, scripter (opus): `verification/m1-07-client.md` (beats 0/0.215/0.401-0.417 against the real server; on-screen looks owed)
- M1-01b Skin.assetUrl + loader swaps modules after a sync, tech-lead (sonnet): `verification/m1-01b-fixes.md`
- M1-03b Chomp Frog redo, modeler-3d (opus): `verification/m1-chomp-frog.md`, 6,584 tris; ACCEPTED for M1 by the orchestrator's look (V brow, nostrils, jaw wedge, splayed feet, cuffs match). Notes for the M2 six-boss pass: outer brow ends read like ear bumps; eyes set wide. Pivots moved (hinge 0,2.2,0.6; fists +-1.4,1.8,-1.0); `m1-09-moves.md` and the rig test still show the old numbers.
- M1-11 server carry/log/base/income, scripter (opus): `verification/m1-11-server.md` (54 PASS); contract C updated (Base.State spots dense array)
- M1-12 real slice, z-fighting check 0 pairs, Baseplate deleted, stud proof strip A/B, Setup scripts, builder (sonnet): `verification/m1-12-slice.md`
- M1-13 Audio controller, all 8 ids load, uploaded-F probe -6/+14/+7 ms (B21 not triggered), sync test PASS at 60/30/15, audio (sonnet): `verification/m1-13-audio.md`
- M1-15 UI stud proof at 0.75/1.0/1.65 (StarterGui.StudProofUi), gui (sonnet): `verification/m1-ui-stud.md`
- MS-B1 4 clips published under the group via Explorer "Save to Roblox" (manager allowed computer access to Studio for this): jab3 R15 107079293119205, bigThird R15 85557599926728, jab3 R6 131510122151794, bigThird R6 112874224987934; read back with markers; wired in Models.lua
- MS-A3 imported under the group: z1_t1_atlas (5 meshes), gloves_atlas (2), z1_t1_perrole (23); atlas texture 116542096217311; SetupBosses + SetupGloves PASS on real meshes. Cream reads grey-green in Studio: M1-17 investigating.
- M1-17 frog in Studio, modeler (sonnet): `verification/m1-17-chomp-frog-studio.md`. B4 = shared atlas (5 parts vs 23, same 6,584 tris); B5 one FBX per boss; grey-green was the importer's grey Color tinting the texture, fixed in SetupBosses/SetupGloves (Color white); jaw opens down, no sign flip; mesh + texture ids wired in Models.lua. Orchestrator looked: cream reads cream (`verification/m1-onscreen.md`).
- M1-14 client carry/log/base, scripter (sonnet): `verification/m1-14-client.md` (log 0.000 studs from server; carry, drop, grab, place, pad cash follow the server)
- M1-01c tech-lead follow-ups (FrameCap doc, AutoTap docs, Config.Hazards/Carry constants): appended to `verification/m1-01b-fixes.md`
- UI proof GUI hidden (Enabled=false) at the manager's note that it covered the viewport; re-enable only for the capture.
- M1-16 gate scripts, scripter (opus): `verification/m1-16-gate.md`. CORE LOOP GATE PASSES: CoreLoop 22+36 PASS (also under the stub skin), Refusals 6+19+32, BurstValues 31+26, NoDelay 8, 0 FAIL; CheckSkin A2/B fail on 4 missing keys (routed to M1-24). Findings: no client draws Zones.Pads (M1-24); NoDelay 2 losses, 1 lastHeart (M1-20).
- M1-21 stud checks + Hazard_Log rebuilt to Config size, builder (sonnet): `verification/m1-stud.md`
- Stud proof sheet taken by the main session and sent to the manager: `verification/m1-stud/stud-proof-sheet.png`; A/B question in manager-todo (wall: B raised like ref 8; ground: A matches the style-guide L).
- M1-20 moves/avatar on real assets, animator (sonnet): `verification/m1-20-moves-avatar.md` (lastHeart finding was the check's buffer read, fixed in NoDelay; clips markers within a frame on R15/R6; gloves 1.05x head)
- M1-24 pad number client + skin keys, scripter (sonnet): `verification/m1-24-pads-and-keys.md` (CheckSkin 13/13 PASS). Easy/Fair share #6BE04A per style guide line 189 (correct). Open for M3: skull icon for Near impossible has no skin key.
- STUD PROOF ANSWERED by the manager: "B on both". Promoted: MaterialService.Stud uses the flipped normal 95643445290942 (SetupStud PASS).
- The manager's notes for M3/M4 (walled voxel zone lanes, a better-looking log) and the push request are in manager-todo / decisions.
- M1-18 first session, game-designer (sonnet): `verification/m1-first-session.md` (fight tap counts match the brief in every cell; walks/carry within 2%; cumulative times are a no-reaction floor; M2 tuning notes: 'about six bursts' is 4-5, typical r=1 fight 3.5-5.0 s, Good windows at r>=2 need a human playtest)
- MS-A2 stud images (Decal uploads, Image ids used): color 106741057264448, normal 106077758301166, normal flipped 95643445290942, rough 106124900748892, UI tile 70915382854444; in `Tokens.stud` and `assets.md`.
- M1-09 Chomp Frog moves on a box rig, animator (sonnet): `verification/m1-09-moves.md` (lengths within a frame; jaw direction on the real mesh UNVERIFIED).
- M1-10 gloves stand-in, 4 clips built by script, Avatar controller, animator (sonnet): `verification/m1-10-avatar.md` (publish brief inside; clip ids 0 until MS-B1).

## In flight (spawned, not yet checked)
- none. devsync may still be running on 127.0.0.1:34874 (restart: `python tools/devsync.py` from the game repo root).

## Waiting for a Studio turn (on-screen checks the main session owes)
- The 11 UNVERIFIED looks in `verification/m1-exit-checks.md` (carry/log/place on screen, phone emulator, R6 gloves, stud quality levels and rotated tiles, sync by eye and ear). Folded into the M3-M5 passes and the manager's optional M1 playtest.

## Exists only in the place (hand-built; needs a save)
- the `HussForBosses` marker on Workspace, `ServerStorage.DevSync` loader, and the synced scripts (rebuild steps in `team/CLAUDE.md`); manager asked to save the place

## Blocked on the manager (also in `team/manager-todo.md`)
- Stray folder `C:/team/verification/m1-chomp-frog/` (4 duplicate renders written by a wrong path in M1-03); deleting it was blocked by a safety check, so the manager removes it by hand.
- Each future audio upload needs the Audio Upload License Agreement ticked: the manager's yes covered M1's 8 files only.

## Team calls since the last handoff
Count: 0 so far in the build (pack's brief and B-series carried in by reference)

## Spend
Higgsfield credits used in the build: 0. Balance at approval: 34.96.

## Milestones
| # | Status | Checked how | Commit |
|---|---|---|---|
| M0 | done | exit checks in `team/verification/m0-setup.md` | 96bbb68 |
| M1 | done | `verification/m1-exit-checks.md`: 30 PASS, 0 FAIL, 11 UNVERIFIED (looks/listens); Core loop gate PASS (`m1-26-fight-camera.md` M1-26b CheckAll) | (this commit) |
