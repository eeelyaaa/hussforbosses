# M1-10 verification: the avatar (animator-vfx, 2026-11-25)

Scope: gloves at spawn on R15 and R6, the jab3 and bigThird clips built by script, the `Avatar` controller (contract J),
B14. Studio MCP only (lock `studio`, released). Nothing uploaded, published or committed. No screen was looked at
(subagent: no computer use), so every visual item is `UNVERIFIED` below.

## Files
- `src/StarterPlayer/StarterPlayerScripts/Controllers/Avatar.lua` (new)
- `src/ReplicatedStorage/Shared/Config/Avatar.lua` (new; auto-loaded as `Config.Avatar`)
- `src/ReplicatedStorage/Skins/brickbrawl/Models.lua`: added `clips` and `clipsR6` only (ids 0)
- `src/ReplicatedStorage/Skins/stub/Models.lua`: added `clipsR6` (shape match; M1-01's file, one line)
- `studio/BuildClips.lua` (builds and reads back the sequences), `studio/checks/AvatarCheck.lua` (play-mode check)
- decisions: `team/decisions.md`, "M1-10"; B14 logged there.

## Avatar interface (contract J) as built
`Avatar.start()`, `equipGloves(character?)`, `startJab(grade, t0, character?)`, `cancel(character?)`,
`carryHold(on, character?)`, `flinch()` (no-op), `preload`, `hitLog`, `setClipIds` (test seam). A clip with id 0 is a
no-op that warns once. `BurstClock.setAvatar(Avatar)` fits (`startJab(grade, t0)`, `cancel()`).

## Results (all from scripts; reports below are the scripts' own output)
Sync: `DevSync()` then `run("BuildClips.lua")`: PASS lines below. Then `studio/checks/AvatarCheck.lua` pasted into
`run_script_in_play_mode`. `check_guard.py`: 0 without the guard. `check_skin.py`: 0 hits.

**BuildClips read-back (forward kinematics on the rig, keyframe times):**
- R15 and R6: Jab3 Hit 1, 2, 3 at 0, 0.213, 0.401 (equal to `Config.Punch.BEAT`); BigThird Hit at 0.08 (`BIG_LEAD`), so
  started at 0.321 it lands on 0.401. Lengths: Jab3 0.621 s, BigThird 0.330 s (burst 0.61 s; the 0.011 s tail is the
  return to neutral and is cut by the next burst's `cancel`).
- Hand reach relative to the root (studs, forward is -z): R15 guard z -0.98, jab contact -1.94, big wind-up +0.53,
  big contact -2.64; R6 guard -0.96, jab -1.74, wind-up +1.66, big contact -2.45. All 3 reach checks per rig PASS.

**Gloves, play mode, test rigs (R15, R6, two scaled R15: tall 1.25 / narrow 0.8 / head 1.2, and short 0.9 / head 0.8):**
- Weld `Hand > Cuff` PASS on all 8 gloves; the glove follows a 6-stud move of the body (pivot to hand distance unchanged
  0.13 R15, 0.35 R6, 0.16 and 0.12 scaled); massless, no collision; every avatar part kept, nothing hidden.
- Glove size against head height 1.04 on all four rigs (R15 1.23 studs, R6 1.04, scaled 1.50 and 0.99).

**Clips through `Avatar.startJab` (clips registered locally with `KeyframeSequenceProvider`), sampled each Heartbeat:**

| Rig | L shoulder at 80 deg or more | R shoulder | Hit markers (s after t0) |
|---|---|---|---|
| R15 | 0.017..0.067 (peak 88), 0.400..0.534 (peak 92) | 0.216..0.284 (peak 88) | 0.017, 0.216, 0.400 |
| R6 | 0.017..0.068 (peak 88), 0.402..0.550 (peak 92) | 0.218..0.267 (peak 88) | 0.017, 0.217, 0.418 |

Contacts reach the beats within one 60 Hz frame (the first marker reads 0.017 because the first sample is the next
frame; R6's marker 3 reads 0.418, one frame late, while its shoulder peak is at 0.402). The switch to `bigThird` on beat
3 held. A start 0.2 s late seeks (track at 0.229 and 0.233 after a 0.03 s wait). After `cancel`, 0 tracks playing.
Test rigs destroyed in the script; the edit place holds no test rigs, only `ServerStorage.HFB_Clips` (below).

## Not verified (UNVERIFIED)
- How the clips and the gloves look: pose, weight, snap, glove fit on the hand. Nobody has looked.
- Second client sees the gloves and clips: gloves are built locally on every client by `Avatar.start()` (not started
  yet; `Main.client.lua` owns the call); clip replication from the owner's Animator is the engine's, unseen.
- The published clips (ids 0), `ContentProvider:PreloadAsync` on them, and clip names in the editor.
- Gloves on a real Roblox avatar with accessories on the hands, R6 avatars in a live server, `carryHold` visuals.
- The real glove mesh (`gloves_atlas.fbx` imported by MS-A3 and placed by `SetupGloves.lua`): the stand-in's size and
  wrist placement stand in for it; check the mesh's pivot at the wrist on first import.

## On-screen checks (main session, `computer`, Studio open)
1. Sync, run `studio/BuildClips.lua`. In play mode with a character: run `Avatar.equipGloves` (or start `Avatar.start()`)
   and look at the gloves on the R15 avatar (red fist, yellow cuff, about head size, sitting on the hand, following it as
   the avatar walks and jumps). Repeat on R6 (StarterPlayer > CharacterRigType = R6, or the R6 dummy).
2. Look at one body-shape change (Avatar Editor scale in play, or a scaled dummy): glove still about head size.
3. After MS-B1: punch once on the bag and watch jab, jab, big third (wide wind-up, step in) on R15 and R6; the contact
   should land with the ring-landing tap and the three burst sounds. Judge the feel: snap, the held contact, the return.
4. Second client (Server and Clients, 2 players): the other player's gloves and punches are seen.

## Publish brief for MS-B1 (Animation Editor, main session, `computer` and `studio`; publishing is under the group)
Four clips to publish, **owned by the group Huss for Bosses (432262304)**, from `ServerStorage.HFB_Clips`
(`studio/BuildClips.lua` recreates it):
1. Move `HFB_ClipRig_R15` to Workspace, select it, open the Animation Editor (Plugins > Animation Editor, "Create"/"Load"
   if asked), **File/menu > Load** and pick `Jab3_R15` from the rig's `AnimSaves`. Check the clip name at the top (not
   "Automatic Save"). Do not move keys: the contact keys are at exact times 0, 0.213, 0.401 and the editor snaps to its
   frame rate when keys are moved. Publish to Roblox, name **`HFB Jab3 R15`**, group Huss for Bosses; copy the id.
2. Same for `BigThird_R15`, name **`HFB BigThird R15`**.
3. Move `HFB_ClipRig_R6` to Workspace and do `Jab3_R6` (**`HFB Jab3 R6`**) and `BigThird_R6` (**`HFB BigThird R6`**).
4. Put the ids in `src/ReplicatedStorage/Skins/brickbrawl/Models.lua`: `clips.jab3`, `clips.bigThird` (R15) and
   `clipsR6.jab3`, `clipsR6.bigThird` (R6). Ids are 0 until then. Record all four in `team/assets.md`.
5. Verify each: `ContentProvider:PreloadAsync` on `rbxassetid://<id>` and `AnimationTrack.Length` near 0.621 (Jab3) and 0.330
   (BigThird). Then in play mode watch `Avatar.hitLog` after a punch (markers `Hit` 1, 2 and 3 at about 0, 0.213, 0.401
   from the tap, 3 from `bigThird`); if an editor save moved them by more than a frame, republish or fall back to the
   combined clip.
6. Put the two rigs back in ServerStorage (or delete them; the script rebuilds them). A published edit keeps its id when
   published over the same asset.
If the editor's Load from `AnimSaves` is unavailable for the rig type (new constraint-based R15 dummy), the alternative is
to open the KeyframeSequence's own right-click publish, then the same naming; say which route worked in `team/lessons.md`.

## Hand-off notes
- M1-07 (Main.client): call `require(Controllers.Avatar).start()` and `BurstClock.setAvatar(Avatar)`.
- M1-12 (`SetupGloves.lua`): place `ReplicatedStorage.Gloves` with children `GloveL` and `GloveR` (MeshParts or models,
  pivot at the wrist, fist down -Y); `Avatar` clones them and scales them to the head.
- Cheap on phones: 2 parts per glove (4 per avatar) as stand-in, no particles, no per-frame work except `carryHold`.
