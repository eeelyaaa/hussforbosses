# M1: what only the main session can do (computer use, uploads, imports, publishing under the group)

Subagents can't use computer use. Each item holds the `computer` lock (then `studio` if it needs both, in that
order, released in reverse), is recorded in `team/verification/m1-onscreen.md` with the screenshot path, and stays
`UNVERIFIED` until looked at. Studio is never launched: take a screenshot and click the open window.

## Uploads and imports (approved by the approval's "asset list to the group"; all owned by group 432262304)
| Id | When | What | Source | Result goes to |
|---|---|---|---|---|
| MS-A1 | after wave 1 | Upload F (`f_group1_no_breath.wav`), 02 A, 01 A, and the stand-in sound set | `assets-src/audio/` per `m1-audio-upload-list.md` | `team/assets.md`; ids to M1-13 |
| MS-A2 | after wave 1 | Upload the stud's three world maps and the UI tile (and the flipped normal map as a fourth image for the proof) | `assets-src/stud/` | `team/assets.md`; ids to M1-12 |
| MS-A3 | after wave 1 | Studio 3D importer: Chomp Frog both routes and the gloves into a scratch folder in the place | `assets-src/models/` per the modeler's import brief | mesh ids to `team/assets.md`; M1-17 reads |
| MS-B1 | after wave 2 | Publish the two avatar clips under the group (Animation Editor, "Publish to Roblox", group as owner) | `studio/BuildClips.lua`'s sequences per the animator's brief | animation ids to `team/assets.md`; M1-12 wires |
Check after each upload: it loads (`PreloadAsync` or the importer's result), the group is the owner, moderation
state; if audio is silent in game, `manager-todo.md` item 7 names the sound.
The audio import limit note (100 per 30 days unverified, 2,000 verified) is in the plan; M1 uploads about 10 to 15.

## On-screen checks (phone size and desktop size; the smallest phone in the device emulator)
After the real slice, the HUD and the moves exist (wave 3 lands), the main session looks and writes what it saw:
1. The Huss button, ring and pips beside `ui-kit/phone-hud-base.png` (and `phone-hud-fight.png` for the fight overlay):
   size, red, studs/stand-in, ring start size, hit band; at 874 x 402 and a desktop size.
2. The ring readable; the button clear of the jump button and the top bar and the thumbstick on the smallest phone.
3. GOOD and PERFECT pops, three pips filling on the three beats (a screen recording is not available: three
   captures at the beats, or the log plus one capture).
4. Chomp Frog beside `concepts/brick-brawl/creatures.png` (same angle, read both images) and beside an avatar for size.
5. At the fight camera: guard, a Good hit, a Perfect hit, a big huss, the bite on a Miss, the defeat and the hop.
6. The gloves on an R15 and an R6 avatar.
7. Studs on the proof strip up close and at 40 studs, both normal directions, beside references 8, 13, 14 (world)
   and 1, 2 (UI); the Huss button and one panel at three `UIScale`s. Captures go to `team/verification/m1-stud/` and
   the proof sheet is stacked with ffmpeg (no new tool installed).
8. The strip from the bag pad: the sight line over the 4-stud wall to the fixed pad's number and the windmill stand-in.
9. A whole play-through on screen once: punch, fight, carry past the log, place, collect.
10. The upload moderation states (F, the three images) once, later in the milestone.

## Manager-todo items M1 adds (`team/manager-todo.md`)
- Under "Look at": **the stud proof** (already item 4; the producer fills it with the sheet's path and the exact
  question: do the world stud and the UI stud read like references 8, 13, 14, 1 and 2; say yes, or what is wrong;
  nothing else is studded until then) and **play the M1 strip** (optional, no gate): punch, fight the frog, carry
  it past the log, place it; say what feels off about the ring and the burst (the manager's playtest of pass 5 is
  for the feel of the ring speed, the three pips and the sound; nothing else is asked).
- Under "Confirm": none new. If the clips could not be published under the group, a "Set up" line says so.
- Nothing blocks the build on the manager at M1.
