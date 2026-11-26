# M2-23: the avatar's five other clips (animator-vfx, 2026-11-25)

Studio lock `animator-avatarclips` held and released. Nothing published or uploaded. Nothing committed. No screen looked at (subagent): visual items are `UNVERIFIED`.

## Built (`studio/BuildClips2.lua`, re-runnable; run `BuildClips.lua` first if the folder is empty, as that one deletes HFB_Clips)
10 KeyframeSequences in `ServerStorage.HFB_Clips.KeyframeSequences` (`<Clip>_R15`, `<Clip>_R6`), copies in `HFB_ClipRig_R15/_R6.AnimSaves` (now 7 each with Jab3 and BigThird). All Priority Action.
| Clip | Length | Loop | Markers (s) | Look |
|---|---|---|---|---|
| Flinch | 0.25 | no | Impact 0.05 | snap back 0.05 s (lean 18, head 22, 0.35 stud step back, arms up), held to 0.09, back to stance. No fall |
| CarryHold | 1.0 | yes | none | both arms straight up (Config CARRY_SHOULDER_DEG 175), rocks 3 deg each way in the 1.0 s carry-rock stride; trunk and head pose weight 0 so the run keeps legs and hips (R15 rocks the upper torso, R6 through the arms) |
| StealLift | 2.0 | no | Grip 0.55, Step1..4 at 0.60/0.95/1.30/1.65, LiftDone 2.0 | reach down and forward 0.4, grip, 4 rises (0.12 s each, then hold) ending arms up; code stretches: speed = 2.0 / hold (Quick Hands = 2) |
| Knockdown | 2.0 | no | Dust 0.20, GetUp 1.60 | falls back in 0.2 s (Cubic In), lies still to 1.6, sits up 1.8, stance 2.0 |
| Stun | 1.5 | no | Dizzy 0.00 | arms down, drooped head, torso wobbles 10 deg and twists 10, head tips 14 |
Marker names avoid `Hit` (the jab sync marker). Dust cubes, the three stun cubes and the ratchet sound are code/audio on those markers.

## Results
- BuildClips2 read-back, all PASS (R15 and R6): lengths and markers as above; Flinch head moves back 1.24 (R15) / 0.98 (R6) studs; CarryHold and StealLift end with the hand above the head (R6 arms are short: glove end reaches the head's top); grip 2.05 / 1.44 studs forward; Knockdown lying: torso centre 0.50 above the floor, no sinking (drop 1.69 R15, 0.50 R6); Stun head swing 0.47 / 0.33 studs.
- Play mode (server, R15 and R6 rigs, `KeyframeSequenceProvider` ids): every track loads, Length matches, loop flag right, markers fire on time (StealLift at speed 2: Grip 0.28, Step1..4 0.32/0.48/0.67/0.83, LiftDone 1.02; Stun Dizzy 0.02; Knockdown Dust 0.22, GetUp 1.62; Flinch Impact 0.05). First run in the first seconds of a session lagged (known); a re-run after 4 s warm-up was exact.
- `Avatar.playClip(name, opts?, character?)` and `Avatar.stopClip` added to `Controllers/Avatar.lua` (id 0 = no-op, warns once; `opts.hold` stretches stealLift; `Avatar.flinch()` now plays flinch). Not wired to gameplay (M2-16 calls it). Procedural `carryHold(on)` is unchanged and still what Carry calls.
- `CheckSkin` PASS 13/13 after stub keys were added. It leaves `HFB_ForceSkin = stub` ARMED on the workspace: clear it (`workspace:SetAttribute("HFB_ForceSkin", nil)`).

## Publish brief (main session, computer use + `studio`; like M1 MS-B1)
1. Sync, `run("BuildClips2.lua")` (check Report2 attribute all PASS). Publish under the group Huss for Bosses.
2. For each rig (`ServerStorage.HFB_Clips.HFB_ClipRig_R15`, then `_R6`): select it, Animation Editor, load clip from AnimSaves (`Flinch_R15` ...), check the name, Save to Roblox (Explorer > right-click the KeyframeSequence > Save to Roblox, owner = group). 10 uploads; names `HFB_<Clip>_<rig>`.
3. Paste ids into `Skins/brickbrawl/Models.lua`: `clips.{flinch,carryHold,stealLift,knockdown,stun}` (R15) and `clipsR6.*` (R6), replacing 0. Add to `team/assets.md`. `ContentProvider:PreloadAsync` each.
4. Do not re-publish the jabs.

## On-screen checks (main session, `computer` then `studio`; UNVERIFIED)
Rigs: HFB_ClipRig_R15 / _R6 or `CreateHumanoidModelFromDescription` in play mode, camera 8 studs side-on then front; before ids exist load with `Avatar.setClipIds` + `KeyframeSequenceProvider:RegisterKeyframeSequence`.
1. Flinch: a quick back snap with a step, no fall, ends upright.
2. CarryHold: arms straight up, gentle sway; legs keep walking while moving (run animation not frozen).
3. StealLift at speed 1 and 2: reach, grip, four visible ratchet rises, arms up exactly at the end.
4. Knockdown: falls on the back, lies flat ON the floor (not floating or sunk) on R15, R6 and a scaled body (drop is fixed in studs: a tall or small body may float/sink; report), gets up in the last 0.4 s.
5. Stun: standing wobble, arms down, no fall; reads as dizzy.
