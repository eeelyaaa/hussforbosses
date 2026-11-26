# Huss for Bosses: waiting on the manager

The one place things wait for you. The build keeps going around every item. Short lines, exact steps.
Groups: do first, set up, look at or listen to, questions, confirm, done. Updated at the M2 close (2026-11-26).

## Do first (unblocks the most)
1. **Save the place** (File, Save to Roblox, or Ctrl+S) before closing Studio. It holds the sync loader, the place marker, the imported meshes, the six bosses and the review line. The main session saved it at 03:42 on 2026-11-26; save again after any change you make.

## Set up
2. Nothing open. The 19 passes and products, server size 8, Studio computer use and the audio licence yes are done (see Done).

## Look at or listen to
3. **(a) The boss review line: READY.** Press Play, step on the yellow "Boss review line" pad beside the hub spawn; you land 45 studs in front of the line. Each boss loops its 11 moves with a 1 s break and a "now playing" plate names the move, so you can say e.g. "Bit Shark, signature: too slow". The avatar clips are on an R15 and an R6 dummy at the end. The "Back to the game" pad returns you. Studio only; `studio/RemoveReviewLine.lua` removes it before any publish.
4. **(b) The six bosses' sheet:** `team/verification/m2-six-bosses/m2_sheet_vs_picture.png` (our renders under the picture). Say yes, or what to fix per boss. The other 30 bosses wait for your yes. Our own review (`audits/m2-24-six-bosses-review.md`): the Star Golem reads stockier than the picture; your call (keep, or slim it).
5. **(c) M2 playtest list** (on-screen items the team could not look at; hooks are set as Workspace attributes, list in `team/test-hooks.md`; `UNVERIFIED` until you say):
   - **O1 fight camera and PERFECT float at phone size.** Test tab, Device, pick a phone (874 x 402, then 640 x 300). Play, set `HFB_SetPower` on Workspace to 25 or more, walk to the frog's ring (it patrols; stand in the ring), press Huss. Look: the avatar is not covering the boss, the camera frames the boss, "PERFECT" floats above the Huss button on a Perfect, an untimed tap dims the button.
   - **O5 each boss in a fight.** Set `HFB_SetPower` to 100000, `HFB_SetZonesBeaten` to `1,2,3,4,5` and fight one boss per zone (zones 2 to 6: Snap Scorpion, Bit Shark, Frost Byte, Ember Drake, Star Golem). Look: wind-up, hits, defeat read at the camera and nothing clips the ground.
   - **O6 labels and stud at phone size.** On a phone-size view, walk away from a pad: the pad number shrinks with distance (no constant-size label). Look at the stud ground at about 5, 40 and 100 studs: no flicker.
   - **O7 two clients.** Test tab, Clients and Servers, 2 players, Start. Player 1: set `HFB_GrantBoss` to `chomp_frog` (carrying). Check: player 2 sees gloves and punches; player 2 steals the boss from your plot (the steal alert and BOUGHT tag on player 1 are only for bought bosses); owner punch drops the thief; the shield pushes a player out; the greyed "Can't be stolen" prompt; Break shield (set `HFB_SetCharges` to 1); Iron Grip stagger (`HFB_PassOwned` `pass_iron_grip=on`); then respawn (reset character) while carrying and see the boss returns.
   - **O8 real input.** Press the Huss button by key (F), by touch (device emulator tap) and by gamepad (button R2). Each should punch.
   - **Crate TAKE.** Set `HFB_GrantBoss` to `chomp_frog,to=crate`; stand at the crate, press E (keyboard), X (gamepad) or tap the prompt: the boss goes to your head.
6. **Published-only checks** (real Robux purchases, web buyer, badges, two real phones) are in `team/verification/m2-18-robux.md`, "published game". Do them once the game is published; nothing to do now.
7. **Listen and pick.** Each sound family arrives as a listening page at M4; answer with one letter per slot. If an uploaded sound is silent in a published test, add the experience to that sound's permissions (ids in `verification/m1-13-audio.md`).
8. **Higgsfield top-up**, only if the team reports the balance will not cover what is left.

## Questions
(the build uses each default and marks what rests on it `PROVISIONAL`)
Q1. **Does a tap that is not timed cost a heart in a fight?** Default (PROVISIONAL): **no heart on green bosses (Easy, Fair), one heart from yellow up (Hard and above)**. Say "never" or "always" to change it. One setting either way.
Q2. **Brief wording from the M1 measurements:** "about five bursts" to 25 Power and "about 4 to 5 seconds" for the first fight. Default: leave your wording and the numbers as they are.
Q3. **P5, how far a boss walks:** default a short walk (14 studs each way); the real region length comes with the M3 world. Say if you want them to roam a whole zone room.
Q4. **Cash comes in about 4 to 7 times the brief's income line from minute 10 on** (`verification/m2-26-curves.md`): minute 3 $3 to $6 a second (brief $5), minute 10 $91 to $188 ($80), minute 30 $3,000 to $5,500 ($800). Zone 3 comes at 15 to 16 minutes, not 11. Default (PROVISIONAL): **change nothing in the game**; the brief's income line becomes the measured ranges and we check again against real sessions. The other choices (a lower zone income table, or dearer upgrades from zone 2) change your tables, so they are your call.

## Confirm
9. **A stray folder:** `C:/team/verification/m1-chomp-frog/` (4 duplicate renders from a wrong path in M1-03). A safety check blocked the delete; remove it in File Explorer or approve the delete in chat. Harmless.

## Your notes for later milestones (2026-11-25, your words; not questions)
- M3, the zones: "hopefully the map will have walls and stuff (the part with the different world types and monsters) ... with voxel style too some parts especially." Reference: a long lane walled on both sides by high walls with voxel trees along the top, each zone a different ground colour in sequence, big mountains behind the walls. Carried in `requirements/m2-carryover.md`.
- M3/M4, the log: "I know log will be functional but it should look better."
- Workflow: you start the next milestone in a new chat after M2, and give feedback at certain parts of the game.

## Done
- 2026-11-25, M0: the open place is the group's (432262304) and saving works.
- 2026-11-25, M1: stud proof answered "B on both" (applied); gloves and frog imported and the 4 clips published; audio licence yes for the 8 M1 files; you said yes to everything for future audio (upload at M4).
- 2026-11-25 (M2-00): all 10 passes and 9 developer products created and on sale, ids in `assets.md`; Maximum Visitor Count 8. Icons not added yet.
- 2026-11-25: the pack's media is committed to the game repo (concepts.figcraft via Git LFS).
- 2026-11-26: Studio computer use approved; five bosses imported; 10 avatar clips published; the review line built.
