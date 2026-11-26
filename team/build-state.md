# Build state: huss-for-bosses

The orchestrator rewrites this file before and after every wave. A new session reads it first and trusts files and
`git status` over anything written here about work "in flight".

Updated: 2026-11-25
Milestone: M2 (All version 1 systems, and the first six bosses) — CLOSED 2026-11-26 (gate 27/27 scripted; on-screen O2-O4 PASS, O1/O5-O8 + crate on the manager playtest list)
Stop at: M2 (`/build huss-for-bosses until M2`)

## Next action
M2 is closed and committed; the build stopped here as asked (`until M2`). Next: the manager reviews (review line, six-boss sheet, M2 playtest list, Q1-Q4 in manager-todo), then starts M3 with `/build huss-for-bosses` (or `until M3`). The M3 producer reads `requirements/m2-carryover.md` first. Studio and computer locks are free; no agent is running.

## M1 record (closed, commit a70ff0f)
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
- none
Done and checked this milestone: M2-30 on-screen (team/verification/m2-30-onscreen.md: O2 O3 O4 PASS + review line, HUD, streaming, patrol, shutdown save; O1 O5 O6 O7 O8 + crate UNVERIFIED -> manager playtest list); M2-07d S24 FightCamera 16/0 + 16/0 (gate 27/27); place saved 03:42; biped defeat flop margin (lie+0.02) + Frost Byte wind-up lift; MovesM2Real biped 3x PASS; M2-28 GATE RUN: 26/27 PASS (11,431 PASS lines), 1 FAIL S24 FightCamera a (stale probe vs patrol) -> M2-07d; MovesM2Real z6 flop flake -> animator; how to run: m2-gate.md; M2-07c no client bug: Good at Speed 10 is 3.67 by the late-tap cadence (check expectation wrong; Curves row fix sent to the gate run); M2-27b S25 PASS (code half), S20 PASS, no must-fix open; M5 notes R1 (>500 arrivals in 60 days pushes out unresolved evidence) and R2 (boss dropped after 60 days if the thief's save never landed); SF2/SF3/SF4 fixed (Robux a 57/0, b 22/0, c 18/0, Spin 21/0, Bag 48/0); M2-26 curves (1 FAIL: Good at Speed 10 -6.5%, client ring skip -> M2-07c; income 4-7x brief at min 30 -> Q4 PROVISIONAL no change; zone 3 at 14:45-15:57 vs 11:00; no tunings); MF1 fixed (Saving d 34/0, a 51/0, Steal c 8/0; TEAM CALL M2-09-10); MF2 fixed (Base a 39/0, b 14/0, c 4/0, Steal a 54/0); SF1 shop client defaults to restricted (ShopClient 42/0); M2-15c server stagger slow (Steal 88/0, Shield 40/0); NEXT: after SF2-4 land, the reviewer (M2-27 agent) re-reads MF1, MF2 and the should-fixes for S25; M2-16b client stagger slow removed, slowSpeed look only (StealClient 21/0); M2-27 exploit review: all ten M2-02 items landed; S20 PASS; S25 FAIL until MF1 (duplicate via trimmed notes, M2-09) and MF2 (pending sale via crate, M2-11b) are fixed and re-read by the reviewer (resume it after). Should-fix still open: SF2 held cash-pack amount consumed before the write (M2-18), SF3 failed pass check on join = not owned all session (M2-18), SF4 level buy is two mutates, refund loses bought-cash status (M2-10) -> do before the gate close; M2-11b Carry.setSlow + pending-sale block (Hazards 66/0, Base 55/0, Upgrades 18/0, Steal a 54/0); M2-20 shop/spin/starter screens (ScreensC 5742/0; on-screen via ScreensCShow/ScreensCVp); M2-21 funnel + arrow (FirstSession 28/0, S21 PASS); M2-15b Shield check stubbed (Shield 40/0, Steal 86/0, Policy 18/0, Base 37/0, Rebirth 21/0); M2-19 shop client (probe 40/0; Input.on still missing, key fallback); M2-09c shutdown save was a counting bug, fixed; PlayStop check PASS (real Play stop saves); Saving a 51/0; HFB_PlayStopValue to add to test-hooks.md (M2-28); M2-18 robux server (Robux 88/0, Spin 20/0; published-only checks listed in m2-18); ORCHESTRATOR LOOK 01:44 (real Play): review line PASS (plates change halfIdle/stun -> break/stealLift, nothing covers a boss, all face the viewer); zone 6 Star Golem on the ring PASS; HUD tiles PASS; place saved 01:44. Crate TAKE moved to M2-30. Found: shutdown save "0 saved, 1 failed" -> M2-09c; M2-34 streaming fix (probe 0 failed); M2-09b transfer gap closed (Saving d 28/0) + Plots.pick; M2-16 steal client (StealClient 20/0; two-client looks owed); M2-15 steal/shield/policy/plots (Steal 86/0, Shield 36/0, Policy 18/0, Base 36/0, Rebirth 21/0); IN FLIGHT: SF1 screens read Spin.available (screens sonnet), M2-28 gate wiring + run (sonnet). ORCHESTRATOR LOOK 01:27: HUD tiles fixed (no white panels) PASS; review line plates above figures, nothing covers PASS; plates stuck "starting..." + all bosses "has no Body" on client FAIL -> streaming (StreamingEnabled true, Default model streaming) -> M2-34; M2-17c no duplicate toast source (ScreensB 2164/0); M2-12b all six zones draw pad bosses (BossVisuals no longer requires Sig; cactus/lava probes pass); M2-13b Rebirth/BossPanel guards, white panels (tiles resize, cap 64), Offline resend ignore, toasts under StealAlert (ScreensA 1944/0; Play look owed); M2-25b/M2-22b S22 on fixed meshes: all five PASS after the tailed hitBig claw drop -0.2 H -> -0.1 H; M2-32 review line fixed (client probe: plates change; plates above figures; all face +Z; UNVERIFIED by look; R6 dummy read "- break -" twice, watch it); M2-17b Prompts nil fix (ScreensB 2159/0, Play look owed); M2-14 offline/rebirth/bought mark (Offline 29/0, Rebirth 36/0, BoughtScan 2/0); M2-24 fix pass accepted by look + re-imported; M2-32 review line built (Workspace.ReviewLine, z -400 y 100; timings 1.000-1.018 s; UNVERIFIED on screen, client start not confirmed; rebuild with studio/BuildReviewLine.lua after SetupBosses; RemoveReviewLine.lua before any publish); M2-11 hazards/carry/base/income/upgrades (Hazards 63/0, Base 54/0, Upgrades 18/0, BuildHazards 11/0; place holds 19 BuildHazards pieces: save); M2-25 six bosses on pads (SetupBosses PASS, MovesM2Real S22 PASS; re-run SetupBosses after the fix-pass re-import, deleting old BossScratch models first); M2-09 data layer (Saving 99/0, SkinCheck3 12/0); M2-06b fight spot follows patrol (Punch2 77/0; Refusals/BurstValues/CoreLoop/NoDelay need near-boss teleport, M2-28); M2-10b six-zone strip (Zones 42/0 on real pads, ZFIGHT 0); M2-17 screens B (2159/0); M2-10 bag/zones/patrol (Bag 54/0, Zones 42/0; auto Power/s within 0.2% of paper; patrol 14 studs, 4 st/s, 16 s); M2-22 boss moves on box rigs (MovesM2 PASS; on-screen needs real meshes); boss atlas uploaded (decal 97710172015828); M2-01b S5/S7/N3 applied (smoke: Refusals 19/0, 63/63 remotes; CheckSync not seen); M2-08b setSpent (PerfectFloat 74/0; on-screen: dimmed button looks spent); M2-06 punch server (Punch2 64/0, Refusals 51/0, BurstValues 57/0, CoreLoop 58/0, NoDelay 9/0; S6 fixed); M2-13 screens A (ScreensA 1929/0, on-screen owed: set Workspace ScreensAShow/ScreensAVp and run the check); M2-02 contract review: B and C may start, 10 must-fix applied to the contract, code items routed per task in audits/m2-02-contract-review.md (S6 sent to M2-06); M2-ART redo (opus) accepted by look; M2-07 client punch + camera (avatar 0.39 of screen); M2-08 PERFECT float (66/0); M2-23 avatar clips (10, unpublished; publish brief in verification/m2-23); stub creature keys (CheckSkin 13/0); HFB_ForceSkin cleared by the orchestrator; M2-01 contract + skeletons (smoke PASS; real shop ids in Config/ShopIds.lua), M2 plan (producer), M2-00 (dashboard: 19 items, server 8), M2-03 numbers (paper), M2-04 stud fix (baked map uploaded: image 134322499090979, preload failed right after upload; re-check, then run SetupStud), M2-05 world labels (on-screen owed), M2-29 stub skin (CoreLoop 22/0 + 36/0; part B fixed by adding the stub key, re-run owed).
- (M1 note) devsync may still be running on 127.0.0.1:34874 (restart: `python tools/devsync.py` from the game repo root).

## Next main-session Play look (one session, computer + studio)
- Review line (landing pad beside hub spawn): plates change, readable, nothing covers a boss; R6 dummy not stuck on "- break -".
- HUD at spawn: no white panels; no client errors in output (Prompts:140, Rebirth:235, Base:767 all fixed in code).
- Zone 6 pad bosses: ~0.4 studs above the ring per M2-12 (SetupBosses says feet within 0.05) — the client probe tolerance was widened to 0.6, so judge by eye; route to M2-12/M2-25 if real.
- Crate TAKE by hand with E, X and tap (scripted prompt never showed).
- Fight camera, PERFECT float, world labels at phone size; bosses patrolling.
- One refused shield action shows one toast (no duplicate) in a real session.
- Save the place after.

## Notes to carry into later briefs
- Every check that can reach Shop.prompt stubs Shop.setPromptFn and restores it; all 10 passes now read Roblox (true for the Studio account): force every pass with PassOwned (M2-18).
- QUEUED for the next opus slot: M2-11b (resume the M2-11 scripter): a slow-down hook in Carry for the Iron Grip stagger; Base refuses selling a stolen boss whose save is pending.
- M2-28: Base and Rebirth checks switch the steal lock off for the rest of their play session — restore Steal.isLocked after.
- M2-01 note: Shield.State also carries ownerUserId (Net comment).
- Two-client checks owed by the main session (M2-15): steal with banner/arrow/BOUGHT + owner punch snaps back; greyed prompt with PolicyTrading off; push-out on shield raise; Break shield + "shield broken" alert; Iron Grip stagger.
- Next main-session Studio turn (after the boss fix pass): delete old BossScratch z3/z4/z5/z6 (+ z2 if changed), re-upload boss-atlas.png, import the changed FBX, rewire Models.lua, run SetupBosses, BuildReviewLine, then LOOK at the review line (client start unconfirmed) and the bosses on pads, then save the place.
- M2-28: CoreLoop a 20/2 because it does not force PassOwned off (real 2x Power): fix in the gate wiring. Refusals/BurstValues/CoreLoop/NoDelay need the near-boss teleport (patrol).
- M2-15 (next opus slot): Base.setLockCheck(Steal.isLocked), Base.setAlertCheck; Carry.begin(thief, cid, {origin="stolen", uid, level, bought, stolenFrom}); Carry.onChanged(player,"none",c,why) to return; settleOp the owner's pad on a steal; send Steal.Alert, Steal.Result, Shield.Broken, Shield.State{breakable,reason}, Carry.State.stolenFrom for the M2-17 screens; transfer seam on Session.standIn.
- M2-18: Bag's pass cache asks Roblox about 3 passes only; build Systems/Passes for all 10; after a pass purchase call Base.refresh and Carry.refreshSpeed; grants are pure Session.ops, answer NotProcessedYet on "retry".
- M2-26: the M2-11 income run is high ($11.75/s at 3 min vs brief $5) because the script reaches zones on a timetable without Power gating: re-measure with real progression.
- Every check reading pass-dependent values sets `PassOwned` =off per pass: the Studio account (group owner) owns Auto Punch, Perfect Auto Punch, 2x Power for real (M2-10).
- M2-11/M2-12: Bag.State and Zones.Pads resent 1 s after spawn; bag tier = plot attribute BagTier; draw patrol with Patrol.position(Patrol.anchor(pad, Config.Zones.LANE), entry.patrol, serverTime), frozen at Fight.State.bossPos for the fighter; pad entry {zone, rollEndsAt, beaten}.
- M2-12: client auto ring (B23): Punch.Report {grade good|perfect, auto=true, tapServerTime} once per ring; stop when autoOn and perfectOn are false.
- M2-10, M2-14: Bag.State and Offline.Summary are sent once on join and can be missed; resend on request or on client ready (M2-13).
- M2-12: must call BossPanel.open(info) and BagPanel.open() (M2-13).
- M2-28: M1 HudViews expects full separators >= 10,000, now stale (B16 short numbers); AutoTap `early` lands as untimed at low Speed, drop or redo (M2-07).
- M2-10: auto good/perfect is refused `pass` until M2-10 wires Auto Punch (M2-06-2); rebirth/pass multipliers via Bag.value.
- M2-16: Fight.Watch not built; Punch.Burst to players within 150 studs (M2-06).

## Waiting for a Studio turn (on-screen checks the main session owes)
- The 11 UNVERIFIED looks in `verification/m1-exit-checks.md` (carry/log/place on screen, phone emulator, R6 gloves, stud quality levels and rotated tiles, sync by eye and ear). Folded into the M3-M5 passes and the manager's optional M1 playtest.

## Exists only in the place (hand-built; needs a save)
- the `HussForBosses` marker on Workspace, `ServerStorage.DevSync` loader, and the synced scripts (rebuild steps in `team/CLAUDE.md`); manager asked to save the place

## Blocked on the manager (also in `team/manager-todo.md`)
- RESOLVED 2026-11-26: the manager said "Go ahead with Studio"; import, publish and the stud look are done. Waiting on it: boss import (boss atlas already uploaded: decal 97710172015828, image id to read via InsertService), avatar clip publish, on-screen looks, then M2-25 and M2-32. Do not re-ask in the same turn.
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
| M1 | done | `verification/m1-exit-checks.md`: 30 PASS, 0 FAIL, 11 UNVERIFIED (looks/listens); Core loop gate PASS (`m1-26-fight-camera.md` M1-26b CheckAll) | a70ff0f |
| M2 | done | `verification/m2-gate.md` 27/27 scripted PASS; `verification/m2-30-onscreen.md` (O2-O4 PASS; O1, O5-O8, crate UNVERIFIED -> playtest) | (this commit) |
