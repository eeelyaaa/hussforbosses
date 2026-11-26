# M1: proof 1, the burst clock: sound, picture and the server on one schedule

Build to `m1-contract.md` sections D, F (`Sounds`), L (`ReportBeats`, `FrameCap`) and to `sound-direction.md`
("The signature", "What plays, moment by moment", "Keeping sound and the three hit frames together"). Quality pass:
**Function only**; the manager listens later (listening pages are M4).

## The brief
The manager's picks (sound-direction, 2026-11-25): every landed burst plays **F** (`f_group1_no_breath.wav`, "combo f
sounds good"), played as **one file** started once at the tap; single husses are **02 A** (`a_huss4_full_levelled.wav`,
"for single leveled use a") alternating with **01 A** (`a_huss1.wav`, "for single huss as cut use A"); "make sure the
punches against bag or boss are timed against this". F on every landed burst, one F voice per player, none on a
Miss (a soft swish on the bag; in a fight the boss's wind-up marks it), `PlaybackSpeed` never changed. The three
beats fire from `t0` on Heartbeat; the server applies the same table.

## Tasks
- **M1-04 audio-specialist (sonnet), wave 1:** `tools/audio/` (a cut/level/measure script using ffmpeg and the
  earshot measure command; the envelope-probe script that finds the three loud parts of a file), copies the three
  source files from `team/pack/sound-refs/candidates/` into `assets-src/audio/` unmodified (the files are "trimmed
  and levelled only", already done in the pack), measures them (length, lead silence, peak, three loud parts of F
  in the local copy), renders **one stand-in thud set** (one bag tier, 3 takes, a stand-in sting and swish) with
  earshot into `assets-src/audio/standin/` (earshot's learned designs, not its invented punches; Creator Store
  ProSoundEffects fallback if earshot is bad), writes `Skins/brickbrawl/Sounds.lua` with slots and id 0 and the
  local-file `F_BEAT_IN_FILE` as a provisional value, and writes the **upload list** for the main session
  (`team/verification/m1-audio-upload-list.md`: file, size, length, slot, suggested asset name). Uploads: 03 F, 02 A,
  01 A, plus the stand-in set (counted in the plan's 220 to 300).
- **MS-A (main session, computer use):** uploads to the group (`team/assets.md`); notes moderation state.
- **M1-13 audio-specialist (sonnet), wave 3, `studio` lock:** `Controllers/Audio.lua` (pool of two F `Sound`s per
  player created once, preloaded with `ContentProvider:PreloadAsync`, `playBurst(grade)` plays F in the same
  frame the BurstClock calls it, F volume by `Skin.Sounds.volumes`, a stand-in thud per beat from `BurstClock`, the
  sting on a Perfect (stand-in), the bag Miss swish, none on a fight Miss, fade F 30 ms on a refusal and 40 ms on
  Run, `singleHuss` strict alternation with the x1.25 gain on 01 A, exported for the M2 thief punch), the envelope
  probe on the uploaded F (`studio/checks/Probe.lua`: each loud part within 20 ms of its beat plus the file's own lead
  of about 10 ms; numbers reported; **if a part is more than 20 ms off, B21 applies**: `BEAT` is set from the
  probe for the server, hit frames and clips alike, and the contradiction in the pack is closed in
  `decisions.md` and reported to the producer), writes the final `F_BEAT_IN_FILE`, and `studio/checks/SyncTest.lua`.
- **M1-19 audio-specialist (sonnet), wave 4, `studio` lock:** runs the sync test and saves
  `team/verification/m1-sync-test.md`.

## The sync test (`studio/checks/SyncTest.lua`, step 7 of the sound direction)
A play-mode script, `AutoTap = "good"` and `ReportBeats = true`, runs 20 bursts at `FrameCap` 60, 30 and 15, reads
`BurstClock.log` and `BurstClock.starts` from the `beats` test reports, and logs for each burst the time each beat
fired against `BEAT[n]` and how many times F started. **Pass:** F started exactly once per burst; the three beats
fired in order, none dropped; each fired within one frame of its schedule (`firedAt - BEAT[n] <= 1/FrameCap + 0.004`
s) and never early; the avatar contact and the boss reaction subscribers fired from the same beat events (their
counts equal the beat counts). Whether the sound feels locked to the picture on a phone is the manager's, listed
`UNVERIFIED`.

## Acceptance criteria
1. The three files are on the group and load (`PreloadAsync` succeeds), with their ids in `team/assets.md`; F's
   moderation state is noted.
2. One F `Play()` per landed burst, none on a Miss, never two for one ring, never above 1.2 bursts a second;
   counted at Speed 1, 5 and 10 by a play-mode script. [M1-13, M1-16 counters]
3. The probe's three numbers are in `team/verification/m1-envelope-probe.md`, with the pass/fail against 20 ms.
4. The sync test passes at 60, 30 and 15 fps. [M1-19]
5. Server and client use one table: `Config.Punch.BEAT` (changed only through B21).

## Roles and order
M1-04 (wave 1) -> uploads (main session) -> M1-13 (wave 3, after `BurstClock` and `Avatar` exist) -> M1-19 (wave 4).

## Risks
Uploads re-encoded with different start padding (the probe's job); the group's moderation holding F; a group-owned
game needing a Permissions grant for a sound (`manager-todo.md` 7); `PlaybackSpeed` touched by a later fatigue
rule (never; the rule is M4 and uses `Volume`).

## Suggestions from the vault (optional)
None added.

## Not asked for (do not build)
Any sound beyond: F, 02 A, 01 A, one stand-in thud set with sting and swish; the six bag-tier thud sets; boss
voices, attacks, hit sounds; UI sounds; cash sounds; hazard sounds; footsteps; ambience; music; the fatigue rule;
the watching-client copy of F; the listening page; Higgsfield audio; volume settings; mix groups beyond one burst
group and one effects group.
