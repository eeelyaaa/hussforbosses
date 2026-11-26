# M1-04 audio: tools, measurements, stand-in set, upload list (audio-specialist, 2026-11-25)

Status: files measured on disk; nothing uploaded (no Studio, no locks). How anything sounds is `UNVERIFIED` until the manager listens.
All three picked files are copied unmodified from `team/pack/sound-refs/candidates/` to `assets-src/audio/`
(sizes and names match the pack). Tools: `tools/audio/` (`measure.py`, `probe.py`, `cut.py`, `level.py`, `README.md`);
earshot `measure` agrees with them (F -11.7 LUFS, peak -2.8 / -1.1 / -4.0 dBFS).

## Measurements (local files; mono = plain channel mean; lead = first 5 ms RMS window within 30 dB of the file's loudest)
| File | Slot | Format | Length | Peak (at) | RMS | LUFS | Lead | Last 10 ms peak |
|---|---|---|---|---|---|---|---|---|
| `f_group1_no_breath.wav` | 03 F | 44.1 kHz stereo 16-bit, 104 858 B | 0.594 s | -2.87 dBFS (0.253 s) | -15.7 dBFS | -11.7 | 0 ms to -30 dB (loud part 1 onset 7 ms) | -37.9 dBFS |
| `a_huss4_full_levelled.wav` | 02 A | same, 42 204 B | 0.239 s | -1.12 dBFS (0.086 s) | -13.5 dBFS | n/a (< 0.4 s) | 16 ms | -30.7 dBFS |
| `a_huss1.wav` | 01 A | same, 42 380 B | 0.240 s | -4.05 dBFS (0.096 s) | -15.7 dBFS | n/a (< 0.4 s) | 12 ms | -37.2 dBFS |

- 01 A vs 02 A: 2.2 dB lower RMS, so x1.29 would match exactly; the contract's x1.25 (1.9 dB) is within 0.3 dB. Left at 1.25; the manager's ear tunes it.
- Tails end at -31 to -38 dBFS (a short hard stop, not at full level). They are the pack's own cuts; not changed ("trimmed and levelled only").

### The three loud parts of F (`probe.py`: 5 ms RMS, 1 ms hop; onset = last time the level was N dB under that part's peak)
| Part | Peak at | Onset -10 dB | **Onset -20 dB** (pack's method) | Onset -30 dB |
|---|---|---|---|---|
| 1 | 0.030 s | 0.021 | **0.007** | 0.000 |
| 2 | 0.249 s | 0.234 | **0.233** | 0.226 |
| 3 | 0.429 s | 0.423 | **0.420** | 0.405 |
Gaps between onsets (-20 dB): 0.226 s and 0.187 s. Between peaks: 0.219 s and 0.180 s.

### The beat-offset question (brief `BEAT = {0, 0.213, 0.401}` against the file)
- Pack's earlier measure of F (E minus 18 ms): 0.007, 0.237, 0.42. Mine at the same -20 dB rule: 0.007, **0.233**, 0.420. Part 2 differs by 4 ms (window alignment); I wrote the measured 0.233.
- Against the brief plus the file's own lead (0.010): part 1 -3 ms, part 2 **+10 ms**, part 3 **+9 ms** (onset -20 dB). Every part is inside the 20 ms rule at M1-13.
- The result depends on the threshold more than on the file: at -10 dB the onsets are 0.021, 0.234, 0.423, i.e. 0.213 and 0.402 after part 1, which is the brief's schedule to 1 ms; at -30 dB they are 0.226 and 0.405 after part 1 (+13 and +4 ms). The spread between methods (13 ms) is below the 20 ms rule and below one 60 fps frame plus a bit (16.7 ms).
- Reading: no sign that B21 will trigger on the local file. B21 decides at M1-13 on the **uploaded** asset, which may gain or lose start padding after re-encoding. Not changed anywhere: `Config.Punch.BEAT` stays as the brief says.

## Stand-in thud set (earshot 2026-11-25, learned designs only; no Higgsfield; spec `tools/audio/standin_spec.json`)
Rendered `thump/soft`, `thump/book`, `hit/drop` (3 takes each) plus swish and sting candidates; picked by measurement (length at most 0.25 s, peak early, tail clean). All answers read `clean`.
| File | Design | Length | Peak (at) | Lead | Note |
|---|---|---|---|---|---|
| `standin_thud_bag1_1.wav` | thump/book, take 1 | 0.151 s | -1.16 dBFS (16 ms) | 0 ms | 48 kHz stereo, 28 948 B |
| `standin_thud_bag1_2.wav` | take 2 | 0.151 s | -1.08 dBFS (16 ms) | 0 ms | 28 956 B |
| `standin_thud_bag1_3.wav` | take 3 | 0.141 s | -1.04 dBFS (16 ms) | 0 ms | 27 156 B |
| `standin_swish.wav` | flick/thin | 0.214 s | -1.64 dBFS (73 ms) | 17 ms | 41 220 B |
| `standin_sting.wav` | tick/glass cut to 0.40 s, 60 ms fade out | 0.400 s | -1.62 dBFS (2 ms) | 0 ms | 76 878 B, -14.7 LUFS |
Not picked and not uploaded: thump/soft (0.09 s, thinner), hit/drop (0.23 s, 17 ms lead, peak up to 77 ms late), flick `swish/flick`. A brick thump for punch 3 is not in this set (not asked for at M1).
Everything is peak-normalised near -1 dBFS by earshot; in-game balance is by `Volume` (below).

## UPLOAD LIST (main session, computer use; Creator Hub > Audio, owner = group Huss for Bosses 432262304; then grant the experience; record in `team/assets.md`)
Paths are relative to `projects/huss-for-bosses/`. Roblox group = the asset owner. Mix group = the runtime group the Audio controller (M1-13) puts it in.
| # | File | Asset name | Description | Mix group | Skin key | Size |
|---|---|---|---|---|---|---|
| 1 | `assets-src/audio/f_group1_no_breath.wav` | HFB Burst Voice F | Huss x3 burst voice, 0.594 s, one file per landed burst | Burst | `Sounds.burstVoice` | 104 858 B |
| 2 | `assets-src/audio/a_huss4_full_levelled.wav` | HFB Single Huss 02A | Single huss, levelled, alternates with 01A | Burst | `Sounds.singleHuss[1]` | 42 204 B |
| 3 | `assets-src/audio/a_huss1.wav` | HFB Single Huss 01A | Single huss, as cut; plays at x1.25 volume | Burst | `Sounds.singleHuss[2]` | 42 380 B |
| 4 | `assets-src/audio/standin/standin_thud_bag1_1.wav` | HFB Standin Thud Bag1 1 | Stand-in bag thud, take 1 (earshot) | Effects | `Sounds.thud.bag1[1]` | 28 948 B |
| 5 | `.../standin_thud_bag1_2.wav` | HFB Standin Thud Bag1 2 | Stand-in bag thud, take 2 | Effects | `Sounds.thud.bag1[2]` | 28 956 B |
| 6 | `.../standin_thud_bag1_3.wav` | HFB Standin Thud Bag1 3 | Stand-in bag thud, take 3 | Effects | `Sounds.thud.bag1[3]` | 27 156 B |
| 7 | `assets-src/audio/standin/standin_swish.wav` | HFB Standin Swish | Stand-in air swish for a bag Miss | Effects | `Sounds.swish` | 41 220 B |
| 8 | `assets-src/audio/standin/standin_sting.wav` | HFB Standin Perfect Sting | Stand-in Perfect sting, 0.40 s | Effects | `Sounds.sting` | 76 878 B |
Eight uploads, 0.75 MB total, all under the limits (20 MB, 7 min). Upload order 1 to 3 first (they unblock M1-13's probe). After upload write the ids in `team/assets.md` and into `Skins/brickbrawl/Sounds.lua` (ids only; do not touch `F_BEAT_IN_FILE`; M1-13 owns it), note moderation state for 1 (F), and grant the experience (`manager-todo.md` 7 if the group-owned place needs it). The sting, swish and thuds are earshot-made (ours; no licence issue); F, 02 A and 01 A come from the manager's own recording.
Note: the plan's file name for this list is `m1-audio-upload-list.md`; the task asked for it here, so this file is that list.

## `Skins/brickbrawl/Sounds.lua` keys (all ids 0)
`burstVoice`, `F_BEAT_IN_FILE = {0.007, 0.233, 0.420}` (provisional, local file), `F_LEAD = 0.010`, `singleHuss = {0, 0}`, `singleHuss01Gain = 1.25`, `thud = { bag1 = {0, 0, 0} }`, `swish`, `sting`, `volumes = { burst = 0.55, thud = 0.5, single = 0.55, sting = 0.4, swish = 0.25 }`.

## Fairness
Own-player cues only (2D); no new cue lets one player hear another's timing at M1. The 3D copy for other players is M4/not asked for.

## UNVERIFIED (manager or later tasks)
How F, the singles and the stand-ins sound and whether the stand-in thud suits the bag; the x1.25 match of 01 A; ids load (`PreloadAsync`, M1-13); the offsets on the uploaded asset (M1-13 probe, B21).
