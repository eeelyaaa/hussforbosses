# M1-20: moves and avatar on the finished build (animator-vfx, 2026-11-25)

Studio lock `animator-m1-20` held and released. Play-mode runs through `run_script_in_play_mode`; place cleaned after (0 `HFB_` attributes, no `TmpChecks`, no probe, no test rigs, `StudProofUi` still disabled). Nothing committed.

## 1. NoDelay: 2 losses, 1 lastHeart (cause)
- Game code is correct. Server order is `Fight.Heart {last=true}` then `Fight.State loss` (`Systems/Fight.lua` miss()), and `Controllers/Fight.lua` onHeart plays `lastHeart` and sets `lastHeartPlaying`, so the loss path does not also play `gloat`. No guard or cut drops it. (A loss by `died` or `left` has no Heart event and plays `gloat` instead: by design.)
- Cause: the check. The client probe flushes at most 14 plays a second and `NoDelay.lua` waited 1.6 s after the last fight; the loss that came near the end had its `lastHeart` still in the probe buffer when the check read its reports.
- Fix in `studio/checks/NoDelay.lua`: wait 3.2 s, and a new check "every last-heart loss played one lastHeart move" (server `heart` events with hearts 0 vs probe `lastHeart` plays). Re-run: `fights won 8, lost 1`, `server last-heart events 1 for 1 losses`, `lastHeart plays 1`: PASS; ring gaps all 0.610 s (+/- 0.035) for 15 bursts and 8 misses; 86 plays, 33 cuts, all cuts start the new move at once; no `[HFB]` warnings. All 11 lines PASS.
- Side note (not a fault): `defeat` shows 16 plays for 8 wins; it is played twice per win (Fight controller and a second caller). Harmless as `play` restarts the same move; the cut is invisible. Not changed.
- No change to `Controllers/Fight.lua` or `BossMoves`.

## 2. Real clips and real gloves (script `studio/checks/AvatarReal.lua`, rigs from `CreateHumanoidModelFromDescription`)
Ids from `Models.lua`: R15 jab3 107079293119205, bigThird 85557599926728; R6 jab3 131510122151794, bigThird 112874224987934. Loaded and played through `Avatar.startJab` on both rigs (no errors, `Avatar.preload` fine).
| | R15 | R6 |
|---|---|---|
| Hit markers (s after t0; keys 0 / 0.213 / 0.401) | jab 0.016, jab 0.233, bigThird 0.400 | jab 0.016, jab 0.233, bigThird 0.417 |
| Right shoulder >= 80 deg peak window | 0.217 to 0.283 | 0.216 to 0.283 |
| Late start (0.2 s late) track position | 0.233 (expect 0.23) PASS | 0.238 PASS |
| After cancel, tracks playing | 0 | 0 |
Markers land within one frame (sampled at Heartbeat, about 16 ms) of the beats; the second jab marker is one frame after the pose peak (0.217), the others on it.
Gloves (`ReplicatedStorage.Gloves`, real meshes): welded to LeftHand/RightHand (R15) and Left/Right Arm (R6), follow a 6 stud move, massless, no collide, avatar keeps all its parts. Size over head: 1.05 on all four rigs (R15 1.24 vs head 1.18; R6 1.05 vs 1.00; tall/wide R15 1.52 vs 1.44; small R15 0.99 vs 0.95). Wrist placement and look: on-screen list.

## 3. Moves on the real frog (`studio/checks/FrogMoves.lua`, a clone of `Fixed.Boss_z1_t1` at y 300; the M1-17 script plus a rapid-cut block)
After a 4 s warm-up, all PASS: every group turns about its pivot (drift 0.00000); no Motor6D C0/C1 change and sizes restored after all seven moves; `attack` jaw goes down (-1.40 at 0.266 s, never above rest), right fist 1.06 forward, 0.484 s; `lastHeart` jaw -1.37, 1.02 s; `defeat` 0.815 s; `hitBig` 0.317 s with head 2.1 back (knock-back).
Rapid cuts (hitGood, hitPerfect, hitBig, attack, hitGood, lastHeart, hitBig, hitGood, 40 to 140 ms apart): each play was the overlay at once, the last one finished back to `guard`, then after `stop` every Transform is identity, the model pivot drift is 0.0000, C0/C1 unchanged, sizes restored, nothing running.
Notes: (a) a first run in the first seconds of a play session showed the first `attack` stretched to 1.14 s and tiny (session-start frame lag); repeated after a 4 s warm-up it was right. Checks should warm up. (b) The M1-17 limit "left fist < 0.3 forward" in the attack no longer holds in world space (0.97, the whole body lunges, both fists ride it); the check now compares left <= right. Right fist leads by only about 0.09 stud over the lunge: judge the bop on screen. (c) `Transform` read in the same frame shows 0 (applies a frame later), as in M1-17.
No move delays the ring: NoDelay above, the real frog is the fight boss, Speed 10, bursts and misses back to back.

## On-screen list (main session, `computer` then `studio`; UNVERIFIED until looked at)
Camera: from `run_code` set BOTH `workspace.CurrentCamera.CFrame` and `.Focus` (CFrame only lets Studio turn the view back). Edit-mode view of the pad, or play mode with the camera type Scriptable.
1. Frog moves at fight distance. Clone `Fixed.Boss_z1_t1` to (0, 300, 0) (or use the pad's own), `local BM = require(game.StarterPlayer.StarterPlayerScripts.Controllers.BossMoves)` in a play-mode client command bar; camera `CFrame.lookAt(Vector3.new(14, 303, -12), Vector3.new(0, 301.5, 0))` with Focus = the same CFrame as `CFrame.new(0, 301.5, 0)`. Play `attack`, `lastHeart`, `hitBig`, `defeat`, `hitPerfect` one by one: jaw chomps down, no hole where Head and Sig meet, belly cream, flop does not sink into the pad. Front view: eye (0, 302.5, -14) looking at (0, 301.5, 0).
2. In a real fight (Test > Play, walk into the ring of the first pad): miss twice and lose: the boss chomps on the heart loss, the gloat follows, then idle. Hit 4 Good bursts: `hitGood` each tap, `hitBig` on the third, `defeat` on the win. Look for any pause between the beat and the next ring.
3. Gloves, R15: play with the avatar, camera behind at 8 studs (`Focus` on the character head); gloves sit on the hands (fist down, cuff at the wrist), about head size, follow a walk and a jump. Repeat with StarterPlayer.CharacterRigType = R6 (restore Default after). One scaled body (Avatar Editor scales or a rig from `AvatarReal.lua` with HeightScale 1.25 and HeadScale 1.2): still about head size.
4. Punch on the bag: jab, jab, big third on R15 then R6: the contact lands with the ring-landing tap and the three burst sounds; snap, held contact, return. Judge the feel.
5. Second client (Server and Clients, 2 players): the other player's gloves and punches are seen.

Files: `studio/checks/NoDelay.lua` (edited), `studio/checks/AvatarReal.lua` (new), `studio/checks/FrogMoves.lua` (new).
