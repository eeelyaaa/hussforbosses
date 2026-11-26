# M1-09 verification: Chomp Frog's moves and `BossMoves` (animator-vfx, 2026-11-25)

Files: `src/ReplicatedStorage/Shared/Moves/{init,squat}.lua`, `Moves/sig/z1_t1.lua`,
`src/StarterPlayer/StarterPlayerScripts/Controllers/BossMoves.lua`. Check script (play mode, server): `team/verification/m1-09-rig-test.lua`.
Studio lock held (`animator-m1-09`), synced with DevSync, two play-mode runs, rig destroyed after each. Rig: boxes with the
contract's groups and pivots (hinge (0,1.6,0.6), shoulders (+-1.4,2.4,-0.4)), Body pivot at the feet. The real model was not used
(being reworked): **the move directions on the real mesh are UNVERIFIED** (below).
`tools/check_skin.py`: 0 hits (the earlier 2 were other tasks' files, since fixed by their owners). Moves schema check (`Moves.check`): 0 problems.

## Measured (play mode, steady round; Heartbeat frame is 1/60 s so a done fires 0 to 1 frame late)
| Move | Brief | Measured os.clock | Frames |
|---|---|---|---|
| hitGood | 0.15 | 0.167 | 10 |
| hitPerfect | 0.20 | 0.200 | 12 |
| hitBig | 0.30 | 0.316 | 19 |
| attack | 0.45 | 0.467 (run 1: 0.465), impact at 0.216 s (brief ~0.21) | 28 |
| lastHeart | 1.00 | 1.001 (run 1: 1.016), impact 0.266 | 60 |
| gloat | 0.35 | 0.366 | 22 |
| defeat | 0.80 | 0.801 | 48 |
All within one frame. The attack (0.467 s) ends inside a Miss's 0.61 s burst (checked: 0.450 s). The very first reaction of a play
session lost frames (0.29 to 0.39 s for 0.15 to 0.2 s moves): Studio warm-up, not repeated in round 2.

## Passed (first run, all PASS unless noted)
- Body scale ranges: hitGood 0.90..1.10, hitPerfect 0.85..1.15, hitBig 0.90..1.10, attack and lastHeart 0.88..1.10; Head never
  scaled (min = max = 1); Sig max 1.200 (after the fix: the jaw's impact key uses Quad, Back overshot to 1.219), fists max 1.19.
- Rest restored after every non-hold move: all Motor6D `Transform` identity, all sizes equal rest, Body.CFrame equal rest, flash
  material restored; `isPlaying` false. `stop` after the defeat and after loops restores the exact rest.
- Defeat holds its last pose; with `hopTo` (0,6,-10) the pivot ended at (0,6,-10).
- Cut: hitBig cut by hitGood 0.1 s later: new move's frame 1 drawn in the same call, the cut move never reports done, hitGood lasts 0.151 s, rest restored.
- Loops: guard loops; a hit over it returns to guard (`current` = guard, nil); idle moves the boss; eight idle starts gave different phases; carryRock tilts 7.2 degrees at that sample (8 lean with the rock).
- White flash seen on every hit reaction and restored (`Neon` while flashing).
- Beat wiring (criterion 3) is Fight's (M1-07); BossMoves has no ring state: it never yields and reads nothing but its own calls.

## UNVERIFIED (owed)
- Move directions on the real Chomp Frog mesh (jaw down on -x, lean back on +x, fist forward -z, fists left/right, the flop onto
  the back and where the body lies on the pad): needs the imported model (M1-12). The rig proves the maths, not the mesh.
- Criterion 2's "lengths on the real model" and that no joint re-pivots (Transform only): proved on the rig.
- Feel: timing, how the bite reads, the flop's look. Manager's playtest.

## On-screen checks for the main session (phone and desktop size, fight camera; after M1-12 puts the real model on the pad)
Hold `computer` and `studio`; in play mode, call from the command bar or a test hook: `BossMoves.loop(model,"guard")`, then
`play(model,"hitGood")`, `"hitPerfect"`, `"hitBig"` (with `{perfect=true}`), `"attack"`, `"lastHeart"`, `"defeat"` (with `{hopTo=head position}`).
1. Guard: low, wide, fists out to the sides, small hop. 2. Good, Perfect, big: head snaps back, squash, white flash; Perfect and big
visibly bigger; big knocks back a step and staggers. 3. Attack (a Miss): wind-up squash, hop a step in, jaw chomps DOWN (not up through
the lip) at 0.21 s, then the right fist bops out. 4. lastHeart: longer wind-up, then fists pumped twice. 5. Defeat: wobbles, flops onto
its back, flashes, hops to the head; check the flop does not sink into the pad. 6. Idle on a pad: bob and a three-jab triplet every ~3 s, a row
out of step. 7. Frog beside an avatar for size. If the jaw turns the wrong way on the real mesh, flip the sign of `Sig` `r` x in `squat.lua`
(`_strike`) and `sig/z1_t1.lua`.

## Note, 2026-11-25 (M1-17, modeler-3d): the pivots changed after this was written
The redo (M1-03b) moved the jaw hinge to **(0, 2.2, 0.6)** (was 0, 1.6, 0.6) and the fists to **(+-1.4, 1.8, -1.0)** (was +-1.4, 2.4, -0.4); the numbers above are the old box rig's. The moves were then run on the real mesh: see `m1-17-chomp-frog-studio.md`. The jaw goes down with the existing sign; no change made.
