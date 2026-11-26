# M1: Chomp Frog's moves, the avatar's gloves and the jab clips

Build to `m1-contract.md` sections G, H, J and D (the beats). Quality pass: **Function only** (the feel of the
moves is the manager's and M4's; M1 proves they hang off the beats, cost nothing and never delay the ring).

## The brief
Style guide section 5, "Fight animation", and section 7, "Avatar animation". Boss moves are tweens of the moving
groups in code (no `Animator`, no keyframe assets). Chomp Frog's set: idle, guard, hit reactions at Good, Perfect
and big-huss sizes, its signature (hops in and chomps, then a fist bop), last heart and gloat, defeat, carry rock,
half idle. Rigid groups only; snappy: two to four key poses, 0.04 to 0.08 s between poses, Quad Out or Back Out;
sizes in fractions of H; body scale within 0.85 to 1.15; anticipation, strike, impact, recover; the impact frame is
where the star, the flinch and the heart break land. Lengths: hit Good 0.15 s, Perfect 0.2 s, big 0.3 s; attack
0.45 s; last heart 1.0 s; defeat 0.8 s. Avatar: voxel gloves at spawn on R15 and R6; the jab x3 (left, right, left,
rhythm about 0.21 s then 0.19 s, contact frame on the beat, shoulders turn 10 degrees, legs planted) and the big
third punch (wider wind-up, torso twist 25 degrees, half-stud step, longer hold). Clips published under the group.

## Tasks
- **M1-09 animator-vfx (sonnet), wave 2:** `Shared/Moves/` (schema of contract H), `squat.lua` (guard pose; idle
  with the three-jab triplet at 0.21/0.19 s; the three hit sizes; the attack template; lastHeart; gloat; defeat;
  halfIdle; carryRock), `sig/z1_t1.lua` (hop a step in at 0.05 H high, land on the impact frame with `Sig` (the jaw)
  chomping about the hinge, then the right fist bops out 0.25 H and pops to 1.2; the heart breaks on the chomp),
  `Controllers/BossMoves.lua` (the API in H; plays on `Motor6D.Transform`, **B11 logged**; each loop at a random
  phase; steps at 15 Hz for pad idle beyond the near range is M3, not built). It works against the contract's
  group names with a test rig made from boxes if the real model has not been imported yet.
- **M1-10 animator-vfx (sonnet), wave 2:** `Controllers/Avatar.lua` (`equipGloves` on R15 and R6 using the
  `Gloves` model: weld to each hand, hide nothing of the avatar; `startJab`, `cancel`, `carryHold`), the jab x3 and
  big third punch clips: **B14 logged** (the route: `studio/BuildClips.lua` builds `KeyframeSequence`s on an R15
  dummy from numbers in the script, so the clips can be rebuilt; Blender only if the script route cannot do it);
  `tools/blender/clips/` only if used. The animator returns the publish brief for the main session: the dummy, the
  sequence names, `Hit` markers at 0, 0.213 and 0.401 s on the contact poses.
- **MS-B (main session, computer use + studio):** publishes the two clips under the group; ids to `team/assets.md`.
- **M1-20 animator-vfx (sonnet), wave 4, `studio` lock:** checks: Chomp Frog's moves animate without re-pivoting;
  no-delay check with M1-16's `NoDelay.lua` (Misses and big husses back to back at Speed 10: next ring on
  schedule, a running reaction cut by the next result); the avatar's contact frames and Chomp Frog's hit reactions
  fire from the same `BurstClock` beats (log); gloves attached on an R15 and an R6 avatar and follow every hand;
  clips replicated to a second client **UNVERIFIED** if only one client can be run (stated). Renders of guard and
  signature-impact poses by `tools/blender/render_boss.py` for the art-director later. Hands the main session the
  on-screen list below.

## Acceptance criteria
1. `BossMoves.play(model, name)` exists for every move in H on Chomp Frog; a new `play` cuts the old one and starts
   from its first frame; `stop` restores the rest pose exactly (all `Transform`s identity, scale 1).
2. Lengths match the table within one frame; the attack's impact is at about 0.21 s and held 0.06 s; Body scale
   stays inside 0.85 to 1.15; the head is never scaled.
3. A Good burst's beats produce `hitGood`, `hitGood`, `hitBig`; a Perfect burst `hitPerfect`, `hitPerfect`, `hitBig`
   (perfect flag); a Miss in a fight produces `attack`; the last heart `lastHeart`; a win `defeat`; none of it waits
   on or changes the ring.
4. The gloves are on a spawned R15 and R6 avatar and move with the hands (script read-back of the weld).
5. The two clips load (the ids exist and `AnimationTrack.Length` > 0), contact poses on beats 1 to 3 within one
   frame at 60 fps, and `startJab` seeks when started late. [M1-20 + M1-13's sync test]
6. Cost: a move allocates nothing per frame beyond its tweens; idle on one pad is one loop. (Frame cost of 136
   placed bosses is M3.)

## On-screen (main session; phone size and desktop size, fight camera)
Chomp Frog's guard; a Good hit; a Perfect hit; a big huss; the bite on a Miss (the sting is the chomp then the
fist bop); the last heart's gloat; the defeat and the hop onto the head; the gloves on an R15 and an R6 avatar;
Chomp Frog beside an avatar for size.

## Risks
Motor6D rest pose drifting with `C0`/`C1`; clip contact frames drifting at 15 fps; a clip switch on a beat costing a
frame; publishing under the group failing (then the animator's fallback: the code-driven pose tweens on the
avatar's Motor6Ds, logged as a TEAM CALL with the reason, and the manager's todo note that clips are not published).

## Suggestions from the vault (optional)
None added.

## Not asked for (do not build)
Any other body type or signature (M2/M3); the other five clips (flinch, carry hold pose beyond what `carryHold`
needs from the avatar, steal lift, knockdown, stun: M2); a flinch on the avatar at M1 beyond a no-op call; cube
bursts, impact stars, camera shake, stud confetti (M4); the half idle's 15 Hz stepping and distance culling (M3);
boss sounds (M4); an `Animator` or keyframe assets for bosses.
