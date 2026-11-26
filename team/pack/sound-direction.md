# Huss for Bosses: sound direction

> **Update, 2026-11-25 (after this file's last pass).** The manager, on the 25 ms of breath before the first huss in E: "okay then choose the one without the breath. if you need to generate a sound similar to this then please do that sounds clean."
> The burst voice is now **F** (`sound-refs/candidates/03 Combo at the game's speeds/f_group1_no_breath.wav`): E with the first 18 ms trimmed and a 4 ms fade in, nothing else changed. The manager heard it and said "combo f sounds good" (2026-11-25), so F is settled. The body of this file now says F wherever it means the burst voice; E is named only in the picking history and the measurements. The first huss now starts about 10 ms into the file, so it meets the 10 ms lead target for tap-timed sounds (resolved); the gaps between husses are unchanged (213 and 188 ms). Measured, not heard: 0.594 s, peak -2.8 dBFS.
> A generated clean huss is allowed by the manager if the recording does not hold up in the game (optional; Higgsfield or earshot, with a listening page). It is not needed for the build to start.


Status: DRAFT for the manager's approval (part of the game pack). Written 2026-11-25 by the audio-specialist;
reconciled the same day with the finished `brief.md`; final pass the same day after the manager's huss picks, the
one-tap burst (brief, system 1, TEAM CALL 36) and the 7 body types. The brief wins on rules and numbers; the
manager's words win over both. Read from: `brief.md` (all of it), `style-guide.md` sections 5 and 7, `decisions.md`,
`concepts/directions.md` (Brick Brawl).

**The team cannot hear.** Nothing here says how a sound sounds. Files were measured (length, level, where the
sound starts and peaks); how any of it sounds is `UNVERIFIED` until the manager has listened.
Listening page: `sound-refs/candidates/index.html` (the picks are marked PICKED on it; the other candidates stay).

## The mood, in three words
Punchy, toy-like, cheerful. One voice (the manager's "huss") over a world of studded bricks.

## The signature: the manager's huss
The manager's words (2026-11-25): "it says huss 3 times so we will probably want to extract just one huss and use it
for our punches. it would be nice tho if generally the punches were in threes like the sound effect. huss huss
huss."

**The manager's picks (listening page, 2026-11-25):** "for single huss as cut use A; for single leveled use a; for
combo use reference E. make sure the punches against bag or boss are timed against this". So the punch voice is
settled:

| Use | File | Picked as |
|---|---|---|
| **Every landed burst** (bag, boss fight, Auto Punch, Perfect Auto Punch): the "huss huss huss" | slot 03 F, `f_group1_no_breath.wav`: the first group of three as recorded (E) with its first 18 ms of breath trimmed, 0.594 s | "for combo use reference E", then "choose the one without the breath" (F), then "combo f sounds good" |
| **Every single huss** (the owner's plain punch at a thief, anywhere one punch is thrown alone) | slot 02 A, `a_huss4_full_levelled.wav`: huss 4, +2.4 dB, peak -1.0 dBFS | "for single leveled use a" |
| **Second take of the single huss**, alternated with the one above | slot 01 A, `a_huss1.wav`: huss 1 as cut | "for single huss as cut use A" |

The two single takes alternate strictly (02 A, 01 A, 02 A, ...). Huss 1 is not levelled (RMS -15.7 against -13.5
dBFS for 02 A), so it plays at a start volume about 2 dB higher (x1.25) to sound as loud; the probe checks the match
and the manager's ear tunes it. Nothing else from the recording is used. Slot 01 B to F, 02 B and C, and slot 03 A to
D, and E (the untrimmed original of F), stay on the listening page for the record and are not built.

### What the recording contains (measured, not heard)
File: `sound-refs/huss-huss-huss-manager.mp3`, untouched (a byte-identical copy is on the listening page).
1.933 s, stereo, 44.1 kHz, mp3 128 kbps, peak -2.9 dBFS, -13.2 LUFS, noise floor -73 dBFS.

- It holds **six** husses: two groups of three, with 0.36 s of silence between the groups (0.69 to 1.05 s). A
  quick silence check sees only two bursts because the husses inside a group run together: the level between them
  dips to between -41 and -51 dB for about 10 ms but never reaches silence.
- Each huss is a loud low part of about 80 ms followed by a quieter hiss of about 100 ms (energy above 3 kHz).
- Inside a group the loud parts start 213 ms and then 188 ms apart (first measurement). A second check of the
  picked file (E, 5 ms RMS windows, onset taken 20 dB under the peak) puts the loud parts at 0.025, 0.255 and 0.44 s
  into the file (gaps 0.23 and 0.185 s). The two methods differ by up to 17 ms because an onset depends on the
  threshold. The brief's schedule (0, 0.213, 0.401 s) stands; the three real offsets are pinned from the envelope
  probe on the uploaded asset (see "Keeping sound and the three hit frames together").
- The second group measures as a near copy of the first (same gaps to within 1 ms, same pitch on each huss, waveform
  match 0.91 at an offset of 0.968 s), so there are most likely **three distinct husses**, heard twice.
- Pitch measured on the loud part: about 445, 450 and 464 Hz; the third sits about 4 % above the first.
- The first huss of each group has about 25 ms of breath before the loud part, so E (as recorded) starts with about
  25 ms that is nearly silent: its lead to -30 dB is 23 ms. The manager asked for the version without the breath; F
  (E trimmed by 18 ms) has a lead of about 10 ms, which meets the 10 ms target for sounds timed to a tap. Resolved.

Evidence: `sound-refs/measurements/spectrogram.png`, `waveform.png`, `envelope-10ms.txt`.

### Candidates cut from it (measurements)
Cut at the measured dips. Processing: trim, a 3 ms fade in, an 8 ms fade out (12 ms on the tight cut), and for
the "levelled" ones a plain gain of +2.4 dB to a peak of -1 dBFS. No pitch change, no filtering, no compression.
All are 16-bit stereo .wav in `sound-refs/candidates/`. Clips under 0.4 s are too short for a LUFS reading, so
RMS is given. **PICKED** marks what the manager chose; those three are the only files built from the recording.

| Slot / letter | File | Cut from (s) | Length | Peak (dBFS) | Peak at | RMS (dBFS) | Lead to -30 dB | Status and note |
|---|---|---|---|---|---|---|---|---|
| 01 A | `a_huss1.wav` | 0.080 to 0.320 | 0.240 s | -4.0 | 96 ms | -15.7 | 23 ms | **PICKED** as the single huss "as cut" (second take). First of group 1, starts from silence with a breath |
| 01 B | `b_huss2.wav` | 0.320 to 0.496 | 0.176 s | -2.8 | 31 ms | -15.9 | 13 ms | Not used. Middle of group 1 |
| 01 C | `c_huss3.wav` | 0.496 to 0.692 | 0.196 s | -3.2 | 60 ms | -15.8 | 22 ms | Not used. Last of group 1 |
| 01 D | `d_huss4.wav` | 1.045 to 1.284 | 0.239 s | -3.4 | 86 ms | -15.9 | 30 ms | Not used as cut (its levelled version is 02 A) |
| 01 E | `e_huss5.wav` | 1.284 to 1.465 | 0.181 s | -3.4 | 48 ms | -16.7 | 17 ms | Not used |
| 01 F | `f_huss6.wav` | 1.465 to 1.662 | 0.197 s | -3.4 | 52 ms | -16.2 | 23 ms | Not used |
| 02 A | `a_huss4_full_levelled.wav` | 1.045 to 1.284 | 0.239 s | -1.0 | 86 ms | -13.5 | 30 ms | **PICKED** as the single huss, levelled (main take) |
| 02 B | `b_huss4_tight_levelled.wav` | 1.072 to 1.262 | 0.190 s | -1.0 | 59 ms | -12.5 | 3 ms | Not used |
| 02 C | `c_huss6_full_levelled.wav` | 1.465 to 1.662 | 0.197 s | -1.0 | 52 ms | -13.8 | 23 ms | Not used |
| 03 A | `a_one_huss_x3_speed1.wav` | huss 4 at 0, 0.60, 1.20 s | 1.50 s | -3.4 | | | | Not used: the old "one huss per punch" edit, superseded by the pick |
| 03 B | `b_one_huss_x3_speed10.wav` | huss 4 at 0, 0.33, 0.66 s | 0.96 s | -3.4 | | | | Not used (same) |
| 03 C | `c_three_husses_speed1.wav` | husses 1, 2, 3 at 0, 0.60, 1.20 s | 1.50 s | -2.8 | | | | Not used (the old alternative) |
| 03 D | `d_three_husses_speed10.wav` | husses 1, 2, 3 at 0, 0.33, 0.66 s | 0.96 s | -2.8 | | | | Not used (the old alternative) |
| 03 E | `e_group1_as_recorded.wav` | 0.080 to 0.692 | 0.612 s | -2.8 | 271 ms | -11.7 LUFS | 23 ms | Not used as it is: the combo with its breath. F, below, is E trimmed. Loud parts at about 0.025, 0.255, 0.44 s in the file |
| 03 F | `f_group1_no_breath.wav` | E from 0.018 s, 4 ms fade in | 0.594 s | -2.8 | about 253 ms | (E's, -11.7 LUFS; not re-measured) | about 10 ms | **PICKED** as the combo voice (manager: "choose the one without the breath"; "combo f sounds good"): every landed burst plays it. Loud parts at about 0.007, 0.237, 0.42 s in the file (E's minus 18 ms) |

F is as loud as E: 2.3 dB over the one-shot target (-11.7 LUFS against no louder than -14 LUFS in "Mix"). Beyond
the trim it is not changed; its start volume in game is lowered to compensate (see "Mix").

## The punch family (bag, boss fights, punching a thief)
One voice, one rule: **a huss is a punch that landed; a "huss huss huss" is a burst that landed.** The same F on the
bag and on a boss; the single huss only where one punch is thrown alone.

### The model (brief, system 1)
One graded tap as the ring closes. Perfect or Good launches one burst: three punches landing 0, 0.213 and 0.401 s
after the tap, 0.61 s long, the third counting double. A Miss launches no burst. The ring closes in 1.20 s at Speed
1 down to 0.50 s at Speed 10, so a cycle is 1.81 s down to 1.11 s: **33 to 54 bursts a minute** (99 to 162 husses a
minute). The burst never changes with Speed.

### What plays, moment by moment
Own player, 2D unless said. "Landing" times are the brief's; each is a hit frame (the avatar's contact frame, the
cube burst and star, the Power number, the pip, the boss's reaction). Thuds are 3D at what was hit.

| When (after the tap) | Bag | Boss fight |
|---|---|---|
| **The tap**, Good | F starts, as recorded, at the tap. No separate tap click: the Huss button is a gameplay button and the burst is its sound | Same |
| **The tap**, Perfect | F starts, plus the Perfect sting (one short bright tick, 0.40) at the same instant | Same |
| **The tap**, Miss | A soft air swish (quieter than a huss). No F | **No swish**: the boss's wind-up cue starts instead (it marks the Miss; see "Boss fight sounds") |
| **0 s: punch 1 lands** | Bag thud, tier set, take 1 | Body-hit thud, size small (Good) or medium (Perfect); the boss's grunt, small or medium |
| **0.213 s: punch 2 lands** | Bag thud, tier set, take 2 (never the same take twice in a row) | Body-hit thud, same size as punch 1. No grunt (a grunt on every punch would chatter) |
| **0.401 s: punch 3 lands (the big huss)** | The tier thud, third take, at x0.90 speed and +3 dB, plus one shared low brick thump under it | Body-hit thud, size large, plus the brick thump; the boss's big grunt |
| **0.612 s: F ends** | Nothing. The ring starts closing | Same |

- **Perfect** adds the sting and makes all three thuds 2 dB louder (twice as hard). The voice, F, does not change:
  it is never louder or different for a Perfect.
- **Good** is the normal burst: F and the three thuds.
- The sting, the swish and the boss sounds are the only things the grade changes. Fight bands (Easy to Near
  impossible) change the ring's windows, not the sounds.
- Taps during a burst are ignored (brief), so they make no sound.
- If the server refuses a tap (too fast, not at a bag), the client fades F out over 30 ms. This should never happen
  to a normal player.
- If the fight ends before the burst does (the boss dies on punch 1 or 2), F is **not** cut: it plays to its end
  while the defeat starts, and only the punches that landed get a thud (brief, system 4, and build plan B22: the fight
  is won on that beat, the later beats deal nothing and get no thud). If the player is knocked down or presses Run
  mid-burst, F fades over 40 ms.

### Hearing Speed and Strength grow
- **Speed** is heard as the pause between bursts shortening, one level at a time: 1.20 s of ring down to 0.50 s.
  The burst is the same 0.61 s at every level, so the voice always sounds like the recording. Nothing else changes
  with Speed. Buying a Speed level plays the upgrade sound once (cash family).
- **Strength** is heard in the thuds, never in the voice. The six bag tiers are six thud sets, one per bag:

  | Bag tier | Strength levels | Thud set |
  |---|---|---|
  | 1 Starter Bag | 1 to 5 | Light padded thud |
  | 2 Sand Bag | 6 to 10 | Heavier thud with a gritty tail |
  | 3 Plank Bag | 11 to 15 | Wooden knock |
  | 4 Ice Bag | 16 to 20 | Hard crack with a short ring |
  | 5 Lava Bag | 21 to 25 | Deep thud with a hiss |
  | 6 Star Bag | 26 to 30 | Deep thud with a bright shimmer |

  Inside a tier the five levels step all three thuds' `PlaybackSpeed` down from 1.04 to 0.96 (level 1 of the tier
  highest, level 5 lowest), so each Strength level bought sounds a little heavier, and the next bag is a clear
  change. Six sets of 6 to 8 takes cover all 30 levels; the "third punch heavier" is done with speed, level and the
  one shared brick thump, not with extra files. Buying a Strength level plays the upgrade sound; a new bag tier adds
  a brick snap as the bag swaps.
- **In fights** the thuds are the body-hit set (small, medium, large; one set for all bosses). Strength is not heard
  there because fight damage comes from Power.
- **Variation:** the thuds get a random `PlaybackSpeed` of plus or minus 2 % around their step and up to 1 dB of
  level; 6 to 8 takes each, never the same take twice in a row. **F gets no speed change and at most 1 dB of level
  change**: any speed change stretches its three beats and would pull sound and hit frames apart. Single husses (no
  hit frames to sync) keep plus or minus 2 %.

### Voice limits, re-derived for bursts (33 to 54 a minute)
- A burst is 0.612 s and the cycle is never shorter than 1.11 s, so at most 55 % of the time has F playing and two
  of the player's own Es can never overlap. **One F voice per player.** A second request while one is sounding (a
  bug or a cheating client) fades the old one over 15 ms. The server already rejects a tap sooner than the cycle
  allows (20 % tolerance, so 0.89 s at Speed 10); the sound adds its own guard of **at most 1.2 bursts a second per
  player**.
- Thuds are 0.25 s at most, so no more than two of a burst's thuds overlap. A fight burst's peak is F, a thud, a
  grunt and the sting at the same instant (four to five voices), under the cap of eight gameplay voices.
- **Single huss** (a thief punched, 0.8 s apart): at most 2 a second.
- **Fatigue rule (long bag sessions).** Standing at the bag for minutes means the same 0.61 s sound 33 to 54 times
  a minute. After **12 landed bursts in a row** (about 22 s at Speed 1, 13 s at Speed 10) F drops 3 dB, and the
  thuds stay. It comes back after 4 s with no landed burst (a missed cycle lasts about 1.8 s, so 4 s is a real
  rest), or on entering a fight. The 12 and the 3 dB are a start for the manager's playtest question about whether
  minutes at the bag are pleasant.
- **Auto Punch (brief, system 2):** every auto tap is Good and launches one burst per cycle at the owner's Speed. F
  plays as in a hand burst but **6 dB lower** because the player is not pressing; thuds as normal; no Perfect sting
  (every auto tap is Good, so there is no Perfect to mark).
  The toggle itself is a UI click. **One burst per ring, so one F per ring, never two** (brief, system 2; build plan B20): a hand tap
  replaces the auto tap for that ring only if its grade is better than the auto grade, and is ignored once the auto
  burst has started, as any tap during a burst is.
- **Perfect Auto Punch (new pass):** every auto tap is Perfect. F 6 dB lower, as Auto Punch; the three thuds are the
  Perfect level (2 dB louder than Auto Punch's), which is what a player hears the pass add. **Automatic bursts get a
  soft Perfect sting (manager, 2026-11-25: "maybe lets add a perfect sting")**, built to stay pleasant over minutes at
  the bag, because a full sting every 1.1 to 1.8 s would be the most repeated sound in the game and would cheapen
  the hand-tapped Perfect. The rules a scripter builds (the numbers are a default for the manager's ear in the
  playtest):
  - **Level:** the same sting file as the hand sting, played at **8 dB under the hand sting** (volume 0.16 where the
    hand sting is 0.40) and with PlaybackSpeed 0.89 (about two semitones down, duller). It sits under the auto F's level, so it never leads the burst. The hand-tapped Perfect sting stays the brightest, loudest
    sting in the game.
  - **Thinning:** it plays on the 1st automatic Perfect burst of a run at the bag and then **every 3rd** (bursts 1,
    4, 7 and so on), at the same instant as F starts. After the existing fatigue drop (12 landed bursts in a row)
    it plays **every 6th** instead. The counter resets with the fatigue reset (4 s with no landed burst, or entering a
    fight) and when the toggle is switched off.
  - **Whose:** the owner's own automatic bursts only, 2D; other players never hear it (their Perfect stings stay
    unplayed). A Perfect the player taps by hand, with or without the pass, always plays the full hand sting and does
    not advance the auto counter.
  Turning the PERFECT mode on is one UI click on the toggle; buying the pass is the buy figure (cash family). Same
  limits as Auto Punch: only on the owner's bag pad, never in fights, never offline.
- **Other players' bursts (their F and their thuds are 3D):** F is 8 dB under the player's own and short roll-off;
  automatic bursts of other players another 6 dB under. Of their three thuds only the heavy third is played, at the
  same lowered level (the first two are left out, so a row of bags is not three thuds a burst a base). At most
  **two other players' Es sound at once** (the nearest two, chosen when a burst starts). Eight bases sit side by
  side; at Speed 10 eight players would start eight bursts every 1.1 s, and the cap keeps that to two. Their Perfect
  stings and their Miss swishes are not played.

### One file or three cuts? One file.
Reference F is played **as one file**, started once at the tap, not as three cuts started at the three landing
times.
- **One file keeps the rhythm exact.** Once started, the audio engine plays the three husses at the recorded
  spacing whatever the frame rate, the animation or the network do. Three cuts started from the frame loop each
  start on a frame boundary and a `Play` call: at 60 fps up to 17 ms late, at 30 fps 33 ms, at 15 fps 67 ms, and
  differently late for each. That jitter lands on the one thing the manager asked to be kept ("timed against
  this"): the spacing of the husses. The cuts also leave their seams in the -41 to -51 dB dips, which are not
  silence.
- **When things slip, the picture slips, not the sound.** The three hit frames are the part that can fall behind (a
  slow frame, an animation that loaded late). They catch up on the next frame; the voice does not move.
- **What one file costs:** no per-huss variation (so none is wanted, above), and it cannot stop after one huss, so a
  win on punch 1 or 2 lets the file finish (above). The three husses as separate files (slot 01 A to C) stay on the
  page only as a fallback if a later skin wants them.

### Keeping sound and the three hit frames together (what the scripter must do)
1. **One clock per burst.** On the accepted local tap, record `t0 = os.clock()` and call `Play()` on F in the same
   frame. The Sound objects are created once per player (a pool of two), preloaded, never created per tap, and
   `PlaybackSpeed` stays 1.0.
2. **The hit frames follow `t0`, not the animation and not the server's reply.** A Heartbeat loop fires beat n when
   `os.clock() - t0 >= BEAT[n]` with `BEAT = {0, 0.213, 0.401}` (the brief). If a frame is late it fires every
   missed beat, in order, in that frame; it never drops a beat and never moves a later beat back. Everything that
   belongs to a landing hangs off the beat: the avatar's contact frame, thud, star, cube burst, Power number, pip,
   the boss's reaction and its grunt.
3. **The animation adapts to the clock, not the other way.** The jab clip starts at `t0`; if the track starts late
   (load, first play), seek its `TimePosition` to the elapsed time. A `Hit` marker in the clip is for the animator's
   check; it does not drive the beat.
4. **The server uses the same schedule.** It applies the three punches' Power or damage at 0, 0.213 and 0.401 s
   after the tap it accepted (brief, system 4). Other players' clients start their copy of the burst (F, the hit
   frames) when the result arrives and run the same offsets from that moment, so their picture and sound also share
   one clock.
5. **Pin the real offsets.** The three loud parts in the uploaded asset (about 0.007, 0.237 and 0.42 s into the
   file in the local copy) are measured on the uploaded asset with the envelope probe and written in the config as
   `F_BEAT_IN_FILE`. Audio uploads are re-encoded and can gain or lose start padding. The check is that each
   loud part sits within 20 ms of its beat plus the file's own lead; the build reports the numbers.
6. **No `PlaybackSpeed` change on F, ever**, including by the fatigue rule or Auto Punch (they change `Volume` only).
7. **Test (play mode, holding `studio`):** log, for 20 bursts at 60, 30 and 15 fps (throttled), the time each beat
   fired against its schedule and how many times F started. Pass: F started once per burst; the three beats fired in
   order, none dropped, each within one frame of `BEAT[n]`. Save it in `team/verification/`. Whether the sound feels
   locked to the picture on a phone is the manager's to say (`UNVERIFIED`).

Sources for the rest: thuds, swish, brick thump: earshot learned designs (bag or sandbag hit, wooden knock, ice
crack, cloth swish, block drop), several takes each, rendered as one set; its invented punches are avoided (its own
README rates them poorly), with ProSoundEffects on the Creator Store as the fallback. The Perfect sting: an earshot
tonal figure on the same instrument as the cash sounds.

## Boss fight sounds
The brief has 7 body types with shared moves and one signature move per creature (36). The sound scheme keeps the
two things apart and uses a third cheap layer, so there is one clear scheme and no recording per creature.

**One scheme (this replaces "six boss voice types" as a stand-alone idea):**
1. **Voice: six, one per zone.** What a boss says (its call, its grunt, its defeat). Zone 1 to 6 each have one voice
   set of three sounds, 2 takes each (36 files). A tier changes only its pitch (below).
2. **Attack: seven, one per body type.** What its body does: a wind-up cue and an impact (14 sounds, 2 takes each,
   28 files). Used by every signature move of that body type.
3. **Element layer: six, one per zone.** A short layer (at most 0.15 s, 2 takes each, 12 files) added on the impact
   of a signature move: leaves or petals, dry grit, wood and rope creak, ice crack, sizzle and ember, a small
   electronic zap.

**Tier pitch** (lower for higher tiers, as before; start values, tuned by the manager's ear):

| Tier | Common | Uncommon | Rare | Epic | Legendary | Mythic |
|---|---|---|---|---|---|---|
| Voice `PlaybackSpeed` | 1.15 | 1.08 | 1.00 | 0.93 | 0.86 | 0.80 |
| Attack `PlaybackSpeed` (half the step) | 1.07 | 1.04 | 1.00 | 0.97 | 0.93 | 0.90 |

Wind-up cues are cut to 0.12 s at speed 1 so that they still end within 0.15 s at the lowest attack speed (0.90);
a lower pitch never pushes the wind-up past the animation's 0.15 s.

**The 36 signature moves get variety cheaply.** Each creature is one (zone, tier): its voice is the zone's at the
tier's pitch, its attack is its body type's at the tier's attack pitch, its element layer is the zone's. So 36
creatures sound different from 19 sets of files (6 voices, 7 attacks, 6 layers) plus a table of pitches, with no
file per creature. Two creatures in the same body type and tier in different zones differ by voice and layer;
in the same zone differ by tier pitch and body type.

### The attack: one sound per body type
Wind-up cue starts at the wind-up (0 s of the move); impact lands at about 0.21 s (the animation's impact frame,
held 0.06 s). Impact sounds are at most 0.2 s so they clear before the recover. Sources: earshot learned designs
(cloth swish, whoosh, block drop, wooden knock, rubbery bounce, wing flap), several takes, one set per body type;
Creator Store as the fallback. Nothing frightening: toy-like.

| Body type (creatures) | Wind-up cue (0 to 0.12 s) | Impact (at 0.21 s) |
|---|---|---|
| Biped bruiser (9) | Cloth and air drawn back, short | Heavy fist thump |
| Squat stomper (7) | A squash creak, short, ending in a small hop | Hop landing with a short strike click |
| Tailed striker (6) | A cocked tail, a quick rising swish | A whip crack |
| Charger (3) | A paw scuff and a step back | A wooden head knock |
| Rearing swayer (4) | A soft rising sweep as it rears | A lunge whoosh ending in a clack |
| Flyer (4) | A quick wing flutter upward | A dive swoop ending in a flap-slap |
| Tentacled floater (3) | A rubbery stretch | A rubbery lash slap |

- **A move with more than one beat** (the scorpion's sting then pincer, Bunny's one-two, Drake's club then fist,
  Hydra's two heads, Squid's double lash, Frog's chomp then bop) plays its impact again on the second beat
  (0.12 s after the first, at the animation's beat) at x1.10 speed and 4 dB lower, with no element layer. A third
  or fourth beat (the Kraken's four arms) is silent: two impacts is the most any move makes. The heart breaks on
  the first impact, so the heart-lost sound goes with the first beat.
- **A Miss** (a heart lost, hearts left): wind-up cue at the tap, impact and element layer at 0.21 s, and on that
  impact frame the **heart-lost** two-note drop (2D, own player only; the body type's impact is short and ends
  before the drop's second note). The avatar's flinch is silent: the impact covers it.
- **The last heart:** the same move bigger (brief: wind-up 0.2 s, striking part at 1.2). Wind-up cue at x0.92
  speed, impact at its frame at +2 dB and x0.92 speed with the element layer. **No heart-lost drop** (the third
  heart goes straight to fight lost); the fall-and-tumble of the fight-lost sound starts 0.05 s after the impact
  with the avatar's knock-down; the boss's **gloat** (its zone call at x1.08 speed, short) plays at the start of
  the gloat pose (about 0.65 s into the 1.0 s).
- **Fight start:** the boss's call (its zone voice, tier pitch) as it turns to face the player, and the short start
  sting.

### Hit reactions by size
| Size | When (brief) | Sounds |
|---|---|---|
| Small | Punches 1 and 2 of a Good burst (0.15 s) | Body-hit thud, small, at each punch. The zone grunt at speed x1.00 of its tier pitch, on punch 1 only |
| Medium | Punches 1 and 2 of a Perfect burst (0.2 s) | Body-hit thud, medium (louder), at each punch. The grunt at x0.94 and +2 dB, on punch 1 only |
| Large | Punch 3, the big huss (0.3 s; larger again on a Perfect) | Body-hit thud, large, plus the brick thump. The grunt at x0.88 and +3 dB. On a Perfect the thud and grunt go up 2 dB |

The three body-hit sizes are three shared files (3 takes each, 9 files) for every boss. A grunt lasts at most 0.2 s
so the one at 0 s and the one at 0.401 s never overlap. A reaction replaced by the next result is a visual cut: the
sound is never cut, as every one of these is short. Other players watching hear the reactions the clients get from
the server (at most one reaction per 0.3 s per boss, as the animation), 3D at the boss.

### Defeat (0.8 s) and the half idle
| Time | Sound |
|---|---|
| 0 s | The boss's defeat voice (its zone's, tier pitch) as the wobble starts |
| 0.45 s | Body-hit thud, large, as it flops with its cube burst |
| 0.50 s | The defeat sting (as it flashes white), 2D for the fighter |
| about 0.80 s | The pop as it shrinks and lands on the player's head (the lift pop) |

If the boss died on punch 1 or 2, F is still sounding for part of this and keeps its priority.
- **Silent on purpose:** the idle on a boss pad (its jab triplets and bob), the guard bounce, the carry rock and the
  half idle of a boss placed on a spot. **A placed boss's half idle is silent**: up to 136 placed bosses within
  hearing, a jab triplet every 6 to 8 s each, would be noise with no information; a placed boss makes sound only
  when something happens to it (placing, upgrade, pick-up, steal).

## The other families
One source and one character per family. Every new slot gets three candidates on a listening page during the build.

| Family | Character | Source |
|---|---|---|
| **UI** | Small plastic clicks, like pressing a stud. One sound per press, the sound of what the press did. Hover is the quietest sound in the game and never on touch | earshot `ui` set with one theme, rendered as a set. Fallback: Roblox's own UI sets on the Creator Store |
| **Cash and upgrades** | One bright tonal instrument for everything that pays | earshot tonal figures (coin, success, level up) in one voice; brick snap and thump from earshot learned designs |
| **Bosses** | Toy creatures: short, blocky, never frightening. The scheme above: 6 zone voices, 7 body-type attacks, 6 zone element layers, 3 shared body-hit sizes; about 85 short files for all 36, no recording per creature | earshot learned animal and prop designs where one fits; stings from the Creator Store licensed libraries. Higgsfield only if nothing fits, optional |
| **Carry and hazards** | Heavier steps under a carried boss; each hazard sounds like what it visibly is | earshot learned footsteps and props, 6 to 12 takes |
| **Steal and shield (alerts)** | Its own family, short and urgent, built from a brick-knock and a two-note call. It shares no sound with the shop or the cash family (see "Alerts are not offers") | Creator Store (ProSoundEffects, Roblox) or earshot; three candidates each |
| **Rebirth** | The one long sound in the game (2 to 3 s): everything winds down, then one clean rise | Creator Store stinger; an earshot tonal rise as a candidate |
| **Shop and spin** | Reuses UI and cash. No files of its own: the spin tick is the UI click at a higher speed, the reveal is a cash figure in six steps | Reuse |
| **Ambience** | One 2D looped bed per zone and one for the base area, crossfaded over 1.5 s at each zone gate, plus two or three 3D point sources per zone | earshot ambience beds (seamless loops, 20 to 60 s) and learned props |
| **Music** | Light, bouncy, toy percussion | Creator Store licensed libraries (APMOfficial, Roblox). Higgsfield optional, for listening only until its licence is settled |

## Every action and screen in the brief
Each row is a sound or a stated silence. 2D sounds are heard only by the player whose screen shows the event.

### Bag and upgrades (systems 1, 2, 3)
| Event | Sound |
|---|---|
| Landed burst, Perfect, Good, Miss, big huss | Punch family, above |
| **First Perfect ever (`FirstPerfectLanded`)** | The normal Perfect sting, F and thuds: no extra sound. The moment is the screen's ("PERFECT" in flash yellow, the bigger burst); it is a measurement step, not an event with its own sound. It is not silent: it is the Perfect sting |
| Power numbers flying to the counter, the pips filling | Silent: the huss and thuds already answer each punch |
| Buy a Punch Strength or Punch Speed level | Upgrade figure (cash family), once, on the server's yes |
| The bag changes to the next tier | Brick snap, 3D at the bag |
| Bag panel opens, closes; Auto Punch or PERFECT toggle | UI open, close, click |
| **Buy Perfect Auto Punch** (bag sign, shop, or the web page) | The buy figure (cash family) on the server's yes. No extra sound |
| A boss's number turns from red to green as Power grows | One quiet tick (cash family), at most once per 5 s |
| **The bag sign's "level affordable" green dot appears** | The same quiet tick (cash family), 2D, once when it appears, at most once per 10 s, never during a fight. The boss-panel upgrade arrow appearing: silent (a state) |
| "Not enough cash" | UI "no" |

### Fights (system 4)
The boss's own sounds (call, grunt, attack, defeat) are in "Boss fight sounds" above.
| Event | Sound |
|---|---|
| Fight starts | The boss's call (its zone's voice at its tier's pitch) and a short start sting; music ducks to half |
| Landed burst | F, the three body-hit thuds, the boss's grunt on punches 1 and 3: the table in the punch family |
| Miss: the boss hits back | The body type's wind-up and impact, with the zone's element layer; no swish |
| **Heart lost** (hearts left) | One low two-note drop, 2D, on the impact frame. The last heart lost goes straight to fight lost, no separate sound. No looping low-health alarm |
| **Fight lost** (hearts gone, or the Run button) | A short falling toy tumble as the player is knocked back (after the bigger last-heart strike, then the boss's gloat); music returns. Not a harsh fail sound: losing costs time only |
| Fight won | The defeat sequence above: voice, large thud, defeat sting, then the pop as it lands on the player's head |
| Difficulty band and number colour | Silent (shown, not heard) |
| Boss-beaten banner (`hud-boss-beaten`) | Silent: the defeat sting and the pop answer it |

### Pads and zones (system 5)
| Event | Sound |
|---|---|
| A rolling pad rolls a new creature | A soft brick pop, 3D at the pad, the same for every tier |
| Pad countdown | Silent (a state) |
| Walking through a zone gate | Silent; the ambience bed crossfades |

### Carry and the six hazards (system 6)
| Event | Sound |
|---|---|
| Carrying | Carry footsteps on the zone's surface (grass, sand, wood planks, ice, stone, metal plate), heavier than normal steps, 3D |
| **Jumping while carrying** | Take-off silent (Roblox's own jump sound is left as it is); the **landing plays one carry step**, +3 dB, so the weight of the boss is heard. Not the hazard's business |
| **Spot rims glowing while carrying** | Silent: a state, and the Place prompt is the next step. Near-spot sound is the placing thump when it happens |
| Hazard hit while carrying | One thud and a drop sound, the same in every zone; the boss's short yelp (the zone's grunt) |
| Hazard push while not carrying | The thud only, quieter |
| **Grab** a dropped boss within 5 s | The lift pop (same as fight won's pop) |
| The 5 s run out, or the boss is lost by falling or resetting | A small deflating pop, 2D |
| Crossing into your own base with a boss | Silent; placing is the payoff |
| **The hazard warning plate** (the hazard's name on alarm orange, HUD) | **Silent on purpose.** The hazard's own 3D sound is the warning, 0.6 s ahead; a second beep on top would double it, and the alarm rule (no sirens, no beeps) stands. The carry indicator is silent too |

The brief says every hazard shows where it will be at least 0.6 s ahead by "a shadow, a glow or a sound". Each
hazard's sounds are 3D on the hazard, so it is heard coming from behind the camera.

| Zone | Hazard | Its sound | The 0.6 s warning |
|---|---|---|---|
| 1 Brick Meadow | Rolling Log | A low wooden rumble loop while it rolls (3 s per crossing), silent during its 1 s wait each side | The rumble starting up from the side |
| 2 Sand Blocks | Tumble Cactus | One soft bounce thud per bounce with a dry rustle, coming down the lane; one cactus every 6 s | The bounces getting nearer |
| 3 Pirate Plates | Swinging Anchor | A chain creak at the top of each swing and a heavy whoosh through the middle; one swing every 3 s | The creak before the swing comes down |
| 4 Ice Blocks | Sliding Ice Block | An ice scrape loop while it slides, a knock when it stops each side | The knock, then the scrape starting |
| 5 Lava Bricks | Lava Burst Row | A rising sizzle during each tile's 0.8 s glow, then a burst for its 0.6 s eruption; the sweep steps tile to tile | The sizzle is the warning |
| 6 Space Baseplate | Orbit Meteor | A low humming whoosh loop that swells as it passes; one lap every 4 s | The swell as it approaches |

At most one voice per hazard, and only hazards within earshot play (a carry home from zone 4 passes four of them
in turn, never together).

### Base, earning, bosses at home (systems 7, 8, 9, 11)
| Event | Sound |
|---|---|
| Placing a boss on a spot | A brick thump as it lands, the boss's call, and the first cash tick. The first placement ever is the brief's "first moment of joy": the thump plus the reward figure |
| Cash popping onto pads once a second | Near the base: one quiet tick a second at most, however many bosses are earning. Away from the base: silent (a constant state) |
| Collecting a pad by walking over it | Collect figure; several pads walked in a row step up in pitch, one sound per pad |
| **A pad reaching its 2-hour cap** | **Silent on purpose.** It fills continuously and takes 2 hours to fill, so a player who is at their base collects long before; one who is away hears nothing anyway, and the "While you were away" panel and its collect figure say it. A cap tick per pad (up to 17) would be the most repeated cue at a base |
| Boss panel opens, closes | UI open, close |
| Upgrade a boss | Upgrade figure, one step higher than collect, plus the boss's short call |
| Pick Up | Lift pop |
| **Sell** (after the shared confirm) | A cash-register style figure from the cash family, distinct from collect |
| **Swap** (after the confirm) | The sell figure followed by the placing thump, one after the other, never stacked |
| Confirm dialog opens; cancel | UI open; UI close |
| "Spots full" toast | UI "no" |
| **Delivery crate:** a boss arrives in it (spin, Starter Pack) | A crate knock, 3D at the crate, plus 2D for the owner if they are away from it |
| Taking a boss out of the crate | Crate lid creak and the lift pop |
| **Bought-boss gold tag** | Silent on purpose: it is a marker, not an event |
| **Offline earnings:** "While you were away" opens | UI open |
| **Offline earnings collected** | The collect figure in its largest form with a short coin run. A reward is never silent |

### Stealing and getting it back (system 10)
| Event | Who hears it | Sound |
|---|---|---|
| **The Steal prompt on a boss that "Can't be stolen"** (greyed with a padlock, the bought-boss policy guard) | The thief only, 2D | Silent until pressed; pressing or holding it plays UI "no" once. No sound tells why, as the screen does not |
| **Grab:** the thief starts the 2.0 s Steal hold | The thief only, 2D | A rising brick-ratchet over the hold. The brief tells the owner only once the hold completes, so the hold must not be heard in the world |
| Hold cancelled (moved away, punched, shield rose) | The thief only | The ratchet stops with a small drop |
| **Quick Hands** | The thief only | No sound of its own. The same ratchet plays at double speed to fit the 1.0 s hold |
| Hold completes: the boss is lifted | Thief 2D: lift pop. **Owner 2D: the steal alert**, wherever they are, as the banner appears | The steal alert: a brick-knock and a two-note call, played once and once more after 5 s if the boss is still being carried. Never a loop |
| **The alert for a bought boss** (the banner shows the BOUGHT tag) | Owner 2D | **The same alert, no difference.** The tag is on the banner, not in the sound: a different sound for paid bosses would single them out and sound like a shop, and the BOUGHT tag only means "from the shop", not "protected" |
| The thief carrying | Everyone near, 3D | Carry footsteps |
| **The owner's faster chase** (20 studs/s) | | Silent on purpose: Roblox's default footsteps already follow run speed. No extra cue |
| The owner punches the thief (0.8 s apart, no ring) | Everyone near, 3D | The single huss (slot 02 A, alternating with slot 01 A) and a body-hit thud, medium |
| A hit: the thief drops the boss and is stunned 1.5 s | Thief 2D and 3D at the spot | The drop sound; for the thief a short dizzy wobble |
| **Iron Grip stagger** (first hit, no drop) | Both the owner and the thief | A dull metal clank in place of the drop, so the owner hears that the hit landed and did not free the boss |
| Boss recovered (snaps back to its spot) | Owner 2D | The placing thump and a short rising two-note answer to the alert |
| Steal succeeded: the thief crossed into their base | Thief 2D: reward figure. Owner 2D: the alert's two notes falling, once | |
| Boss returned because the thief hit a hazard, fell, reset or left | Owner 2D | The recovered sound |

### Lock shield and shop attacks (systems 10, 13)
| Event | Who hears it | Sound |
|---|---|---|
| Shield raised (lock pad, HUD button, or on joining) | 3D at the base; 2D for the owner | A brick-wall rise |
| Shield up | | A very quiet hum at the base as a point source; silent beyond a few studs |
| 10 s before it drops | Owner only, 2D | Two soft ticks, once |
| Shield drops at its normal time | 3D at the base (default); owner 2D | The rise reversed. **Answered by the manager (2026-11-25, "9. yep"): heard nearby.** It helps a thief time a steal; that is accepted |
| Cooldown over, shield can be raised again | Owner only, 2D | One soft tick |
| A visitor bumps a raised shield or is pushed out | The visitor, 3D at the shield | A rubbery bounce |
| Instant Shield bought | As shield raised | The same rise, on the server's yes. No purchase fanfare on top |
| **"Break shield" pressed while greyed** | The visitor only | UI "no" |
| **Shield Breaker used** | Everyone near, 3D at the base | A brick-wall break: a crack and falling bricks |
| **Shield broken** (the owner's banner "[name] broke your shield!") | Owner 2D, wherever they are | The alert family's knock and call in its second form (three notes), played once |
| A Shield Breaker bought too late, stored as a charge | | Silent; the toast says it |

**Alerts are not offers (brief, Cautions 3 and 4; Never list).** The steal alert and the shield-broken alert
tell the owner what happened and nothing else. They never use the coin, buy, reward or shop-open sounds, never
rise like a jingle, never loop, and are never followed by an offer sound: the brief forbids any prompt during a
steal or "shield broken" alert, and the sound follows the same rule. They are short and plain, not alarming:
no sirens, no countdown beeps. Instant Shield and Shield Breaker have no advertising sound anywhere; their
buttons click like any other button. No paid item is silent to its target: Shield Breaker and Iron Grip are both
heard by the player they are used against.

### Rebirth, shop, spin, offers (systems 12, 13)
| Event | Sound |
|---|---|
| Rebirth screen opens; first press | UI open; UI click |
| Rebirth confirmed (second press) | The rebirth sound, 2 to 3 s; music ducks to silence under it and comes back after |
| **Kept bought bosses placed automatically after a rebirth** | After the rebirth sound ends: one placing thump per boss, 0.12 s apart, lowest spot first, the first six audible and any beyond them silent; no call and no cash tick on each. If any went to the delivery crate, one crate knock after the last thump. It is not a new "first moment of joy": no reward figure |
| Shop opens, closes, tab | UI open, close, click |
| A pass, cash pack or Starter Pack purchase completes | Buy figure (cash family) on the server's yes; a cash pack adds the coin run |
| Starter Pack offer opens by itself | UI open only. An offer gets no fanfare |
| Spin: ticket spent, wheel turning, slowing | Spin ticks slowing with the wheel; music ducks to a quarter |
| Spin result | The boss reveal by tier (one figure from the cash family in six steps, Common lowest, Mythic highest), then the crate knock as it is delivered |
| Buying spin tickets | Buy figure |
| **Tapping anything greyed or locked by progress** (a locked zone in the spin picker "Beat a boss first", a disabled button, the shield button in cooldown, a greyed Steal prompt, Break shield) | One UI "no", 2D, on the press only, at most once per 0.5 s. Hover on a greyed control: silent |
| Settings: music slider, effects slider | Music slider: silent (the music itself answers). Effects slider: one UI click on release |
| **The group** (the Roblox group that owns the game; the group icon) | No in-game event and no sound: the brief has no group perk or join reward. The group matters only to who owns the uploaded sounds (see "Sources, cost and licence") |

### Silent on purpose
- The timing ring moving, the pips, the difficulty band, pad countdowns, the shield timer away from its last
  10 s, the zone strip, the rebirth bar: states, not events.
- Power and cash counting up in the HUD; cash accruing when the player is away from their base.
- The tutorial arrow, the bought-boss gold tag, rebirth stars by names, players joining and leaving, a base
  appearing or disappearing.
- Hover on touch devices, scrolling lists.
- Other players' UI, purchases, upgrades, collections and spins.
- The owner's chase speed and Quick Hands (no sound of their own, above).
- Walking with no boss: Roblox's default footsteps, unchanged.
- A third sound inside two seconds for the same event: sequences play one sound at a time.
- Anything that pays the player is never silent (deja-kill lesson: the manager overruled silence on rewards twice).
- **Added in this pass:**
  - Bosses' idle on a pad, guard bounce, carry rock, and **a placed boss's half idle** (up to 136 of them).
  - A cash pad reaching its 2-hour cap (it never happens at the base; the away panel covers it).
  - Spot rims glowing while carrying; take-off when jumping while carrying (the landing has a step).
  - The hazard warning plate and the carry indicator (the hazard's own sound is the warning).
  - The boss-beaten banner, the affordable-upgrade arrow, the Miss swish in a fight, a different alert for a bought boss, the group, `FirstPerfectLanded` (it has the normal Perfect sting,
    nothing extra).
  - Other players' Perfect stings and Miss swishes; two of every three of their thuds.

## Zones: ambience
| Zone | Bed (2D loop) | Point sources (3D) |
|---|---|---|
| Base area | Soft outdoor air | The bags being punched, the shield hum, the crate |
| 1 Brick Meadow | Light wind, birds | A rustling bush, a brook or fountain if the map has one |
| 2 Sand Blocks | Dry wind | Flapping cloth, a creaking sign |
| 3 Pirate Plates | Shore and water | Creaking wood, a flag, gulls |
| 4 Ice Blocks | Cold wind | Ice creaks, dripping |
| 5 Lava Bricks | Low rumble, bubbling | A lava bubble, a steam vent |
| 6 Space Baseplate | Low hum, very sparse | A beeping console, a machine pulse |

Point sources are placed only on things the builder actually puts in the map.

## Music: where it plays and where it does not
- **Starts** when the player first spawns at their base (the brief has no loading screen). The player lives in
  `ReplicatedFirst` so it starts with the first frame and never restarts on respawn or when a window opens.
- **Plays** at the base and along the lane as a rotation of two or three full tracks with a 2 s crossfade, not
  starting on the same track every join.
- **Ducks** to half during a boss fight and under any sting; to a quarter during the spin's slow-down and reveal;
  to silence under the rebirth sound. No separate boss track in version 1.
- **Never** a looped track that has an ending, and never louder than a UI click.
- Music and effects volume in Settings, both saved (brief, screen 13).

## Skin and structure (the brief's re-skin rule)
The brief keeps names, models, colours, icons and sounds in one skin table so a second skin can swap them without
touching a rule. For sound, **the skin is the files**: one asset id per sound slot in the skin's `Sounds` table
(the burst voice F, the two single-huss takes, the six thud sets and the three body-hit sizes, the six boss voices,
the seven body-type attacks, the six element layers, the six hazard sounds, the zone beds and point sources, the
music rotation, the UI and cash sets, the alerts). **The structure is everything else and never changes with a
skin:** the list of slots, what triggers each, who hears it, 2D or 3D, mix groups, volumes, caps, ducking, the
burst timing (the file must keep three beats at the brief's offsets, or the skin carries its own beat table), the
tier pitches and the silence list. The manager's huss is the signature of the default skin, Brick Brawl; a second
skin may bring its own burst voice in the same slot, or keep the huss if the manager wants it to be the game's
sound in every skin.

## Fairness (stealing is player against player)
| Cue | Who hears it | What it tells one player about another |
|---|---|---|
| Steal hold ratchet | The thief only | Nothing; the owner learns of a steal when the hold completes, as the brief says |
| Steal alert (bought boss or not), shield-broken alert | The owner only | What the banner already says |
| Thief's carry footsteps, the owner's punches | Everyone near, 3D | Where they are; nothing the screen does not show |
| Other players' bursts (F, the third thud) | Everyone near, at most two voices | That someone is punching a bag or a boss nearby, which their avatar already shows |
| Shield rise, drop, break | 3D at the base (drop: heard nearby, answered by the manager) | That a base is open or closed, which its shield already shows |
| Iron Grip clank, Shield Breaker break | Both sides | That a paid item was used on them |
| Greyed Steal prompt "no" | The thief only | Nothing the padlock does not show |

## Mix
Groups: `UI`, `Gameplay` (punch, bosses, carry, hazards, steal and shield, rewards), `Ambience`, `Music`.

Priority, highest first; when two would play together the lower one ducks or waits:
1. The player's own burst (F) and the ring result (Perfect sting, Miss swish).
2. Steal alert, shield-broken alert, shield warning.
3. Hazards near a carrying player.
4. Boss voices, attacks, defeat and reward stings (a boss voice sounding while F plays sits 3 dB lower).
5. Cash and UI.
6. Other players' punches.
7. Ambience.
8. Music.

Files before upload:
| Kind | Target |
|---|---|
| One-shots (single huss, thuds, UI, cash, alerts, boss sounds) | Peak -1 dBFS, no louder than -14 LUFS, a family within 2.5 dB of its quietest member |
| **F, the burst** | E trimmed by 18 ms and nothing else: peak -2.8 dBFS, -11.7 LUFS (2.3 dB over the one-shot target; handled by its start volume) |
| Stings and the rebirth sound | Peak -1 dBFS, about -14 LUFS |
| Hazard loops and ambience beds | -22 LUFS |
| Music | -16 LUFS |
| Lead silence on anything timed to a tap | Under 10 ms for new sounds; F has about 10 ms, which meets it (E had 23 ms; the sync section schedules against F) |

Starting volumes in game (`Volume`; deja-kill's levels as a start, tuned by the manager's ear): own **F 0.42**
(0.55 less the 2.3 dB F is hotter than the target), own single huss 0.55 (the as-cut take x1.25 of that), thud
0.45, Perfect sting 0.40, reward 0.50, other sting 0.60, alerts 0.60, boss grunt 0.40, boss attack 0.45, UI click
0.30, hover 0.12, other players' punches 0.20, hazard 0.30 at its nearest, ambience bed 0.10, point source 0.15,
music 0.12. Auto Punch's and Perfect Auto Punch's F is 6 dB lower (0.21); the fatigue rule takes another 3 dB.
At most three UI sounds and eight gameplay voices at once. Phone speakers carry little below about 200 Hz, so no
cue relies on bass alone: every thud has a click in it that a phone can play.

## How it will be verified (agents cannot hear)
| What | How | Who |
|---|---|---|
| Every file: length, lead silence, peak time, cut tail, loudness | `earshot measure` and the envelope script; numbers in the sound map | audio-specialist |
| The uploaded F: where its three loud parts sit | Envelope probe in Studio on the uploaded asset; the offsets pinned in config | audio-specialist, holding `studio` |
| A Creator Store id: exists, free, verified creator, where the sound sits in the file | Store listing check, then the envelope probe in Studio | audio-specialist, holding `studio` |
| Every id loads | `ContentProvider:PreloadAsync` in Studio | audio-specialist |
| One F per landed burst, none on a Miss, never two for one ring, never above 1.2 bursts a second, no overlap; Auto Punch and Perfect Auto Punch at the lower level; the fatigue rule at 12 bursts and its recovery after 4 s | A play-mode script counting plays per event at Speed 1, 5 and 10 | audio-specialist with the scripter |
| The three beats and F stay together | The sync test in "Keeping sound and the three hit frames together", at 60, 30 and 15 fps | audio-specialist with the scripter |
| The right thud set for each of the six bag tiers and the speed step for each Strength level; the heavy third thud | Play-mode script stepping Strength 1 to 30 | audio-specialist |
| One attack per body type and one voice per zone, the pitches by tier, the second beat of a two-beat move, nothing on a placed boss | Play-mode script over all 36 creatures: sound names and speeds per creature | audio-specialist |
| Each hazard's sound follows its server-clock position and stops when out of earshot | Play-mode script per hazard | audio-specialist |
| Hold ratchet heard by the thief only; alerts by the owner only (same for a bought boss); others' punches capped at two; shop sounds only for the buyer; no offer or shop sound within an alert | Two-client play test, counts per client | audio-specialist |
| Groups, volumes, ducking, settings controls saved | Play-mode script reading the groups | audio-specialist |
| **How it sounds:** the burst against the hits on a phone, the pace of bursts at Speed 1 and 10, whether minutes at the bag are pleasant, the fatigue drop, every family's candidates, the boss voices and attacks, that an alert does not sound like an offer, the mix on a phone speaker | Listening pages (three candidates per slot), then a numbered in-game checklist answered row by row | **the manager only** |

Until the manager has listened, every row about how something sounds is `UNVERIFIED`.

## Sources, cost and licence
- **The manager's recording:** the signature. **Rights: answered** (below). Three files are built from it: F, 02 A
  and 01 A, uploaded as .wav (lossless; the mp3 would add encoder delay at the start).
- **earshot** (installed, `.venv-audio/`): UI, thuds, boss voices and attacks, footsteps, props, cash figures,
  ambience beds. Rendered sounds belong to the game. Untested by ear in any of our games: this game is its first
  test.
- **Creator Store** licensed libraries (Roblox, ProSoundEffects, APMOfficial): music, stings, alerts, shield. No
  ids are named here and none is guessed; they are found, measured and offered during the build.
- **Higgsfield:** optional, never required. Nothing was spent on this file. Generated music and Epidemic Sound
  downloads are for listening only until the manager confirms their licence for Roblox.
- **Uploads during the build:** the three huss files, plus the earshot picks. The upload happens in the build,
  through computer use, to **the group that owns the game**, so every asset shares the owner and the game can play
  it (manager, 2026-11-25). The group is owned by the manager's account, which is their "under me"; there is no
  open question about who owns the huss files. Roblox's audio upload limits (under 20 MB, under 7 minutes, .wav accepted) and its
  moderation apply, and whether the group-owned game plays the assets is checked on upload: all `UNVERIFIED` until
  done. Each asset also needs the experience granted on its Permissions page; they go in the approval's upload list.
  Nothing is uploaded during the pitch.

## Answered by the manager (2026-11-25)
1. **Which huss.** "for single huss as cut use A; for single leveled use a; for combo use reference E. make sure the
   punches against bag or boss are timed against this." Built as the table at the top: F (E without its breath, answer 3) for every burst, 02 A for
   a single huss with 01 A as its second take. This removes the one-huss-per-punch default, the three-pitch-step
   idea and the one-versus-three-husses alternative.
2. **Is the recording yours to upload?** "you can upload it under me yes. use computer use", and "I guess I will
   make a group". So the upload goes through computer use to the group that owns the game (see above). The file's
   name mentions Voicemod; the manager has answered that it is theirs to upload and nothing more is asked.

3. **Burst voice.** "okay then choose the one without the breath. if you need to generate a sound similar to this then
   please do that sounds clean." Then, after hearing F: "combo f sounds good". F is the burst voice (settled). A
   generated clean huss stays allowed only if the recording does not hold up in the game.
4. **Who owns the huss files.** "you can upload it under me yes" and "I guess I will make a group": the group that owns
   the game, which the manager's account owns (the group exists, community id 432262304). Settled.
5. **The three sound defaults** (the manager's list item 9: "yep"): a Miss on the bag plays no huss, only a soft swish
   (in a fight the boss's wind-up marks it); players nearby hear a shield drop; music is ducked to half in boss fights.
   All three as written in this file.

6. **Perfect sting on Perfect Auto Punch's automatic bursts.** Asked with the default "no sting"; the manager
   answered: "maybe lets add a perfect sting". Added as a soft, thinned variant (8 dB under the hand sting, pitched
   down, every 3rd burst, every 6th after the fatigue drop; see the Perfect Auto Punch paragraph). The numbers are a
   default for the manager's ear.

## Open
Nothing the manager must answer.

The numbers the manager's ear tunes in the playtest (not questions now): F's start volume against a single huss, the
fatigue drop (12 bursts, 3 dB), the tier pitches, whether the burst feels locked to the hits on a phone, and the
automatic Perfect sting's level (8 dB under the hand sting), pitch (0.89) and thinning (every 3rd, every 6th after the
fatigue drop): too present, too rare or gone unnoticed.
