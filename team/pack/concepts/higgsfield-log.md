# Higgsfield log: Huss for Bosses concepts

2026-11-25, art-director, pitch step 2 (first mockups). Model for every image: `gpt_image_2_6`, paid with credits
(`use_unlim: false`; the unlimited allowance was not available). Cost was estimated with `estimate_image_cost` before
each configuration was used. Balance before starting: **112.21**. Balance at the end: **85.21**. Spent: **27.00**.

The balance was read after each batch, not after each job, so "balance after" is the batch's closing balance.
The connector allows 4 jobs at once; the batches below are how the 16 submissions were grouped.

| # | Direction | What | Settings | Reference | Estimate | Charged | Result | Balance after |
|---|---|---|---|---|---|---|---|---|
| 1 | gym-zoo | key art | 16:9, 2k, high | none | 2 | 2 | `gym-zoo/key-art.png` | |
| 2 | neon-knockout | key art | 16:9, 2k, high | none | 2 | 2 | `neon-knockout/key-art.png` | |
| 3 | clay-kaiju | key art | 16:9, 2k, high | none | 2 | 2 | `clay-kaiju/key-art.png` | 106.21 |
| 4 | gym-zoo | map | 21:9, 2k, high | its key art | 2 | 0 | **Refused** by the safety filter (status `nsfw`, a false positive: the prompt was a children's map). Not charged. | |
| 5 | neon-knockout | icon sheet (9 icons) | 1:1, 1k, medium, transparent | its key art | 1 | 1 | `neon-knockout/icons-sheet.png` | |
| 6 | clay-kaiju | scene | 16:9, 2k, high | its key art | 2 | 2 | `clay-kaiju/scene.png` | |
| 7 | clay-kaiju | creature line-up | 16:9, 2k, high, transparent | its key art | 2 | 2 | `clay-kaiju/creatures-raw.png` | |
| 8 | gym-zoo | scene | 16:9, 2k, high | its key art | 2 | 2 | `gym-zoo/scene.png` | |
| 9 | gym-zoo | creature line-up | 16:9, 2k, high, transparent | its key art | 2 | 2 | `gym-zoo/creatures-raw.png` | |
| 10 | gym-zoo | icon sheet (9 icons) | 1:1, 1k, medium, transparent | its key art | 1 | 1 | `gym-zoo/icons-sheet.png` | |
| 11 | neon-knockout | scene | 16:9, 2k, high | its key art | 2 | 2 | `neon-knockout/scene.png` | |
| 12 | gym-zoo | map, the one retry (reworded: "training bag", "volcanic workshop") | 21:9, 2k, high | its key art | 2 | 2 | `gym-zoo/map-raw.png` | |
| 13 | neon-knockout | map | 21:9, 2k, high | its key art | 2 | 2 | `neon-knockout/map-raw.png` | |
| 14 | neon-knockout | creature line-up | 16:9, 2k, high, transparent | its key art | 2 | 2 | `neon-knockout/creatures-raw.png` | |
| 15 | clay-kaiju | map | 21:9, 2k, high | its key art | 2 | 2 | `clay-kaiju/map-raw.png` | |
| 16 | clay-kaiju | icon sheet (9 icons) | 1:1, 1k, medium, transparent | its key art | 1 | 1 | `clay-kaiju/icons-sheet.png` | 85.21 |

Totals: 15 images kept, 1 refused and not charged, 0 quality retries. 27 credits: 9 per direction
(key art 2, scene 2, map 2, creatures 2, icons 1).

Notes
- Eight submissions in the first follow-up batch came back `submission_failed` with "max 4 concurrent jobs". They never
  became jobs and cost nothing; they were sent again in groups of four.
- Each direction's key art was the style reference for its other four images. It held the look in all twelve.
- Prompts asked for no text. No image has a watermark, and nothing was removed from any image.
- The icon sheets and creature sheets have real transparency. `parts/` in each folder holds the pieces cut from them
  with ffmpeg (crop only): nine icons, and the creatures that could be cut with a plain rectangle.

---

## Round 2: directions 4 and 5

2026-11-25, art-director, pitch step 2 (second mockups, after the manager asked for a stud and voxel direction and one
more). Same model and payment as round 1 (`gpt_image_2_6`, `use_unlim: false`). Each configuration was estimated with
`estimate_image_cost` before use (16:9 2k high: 2; 21:9 2k high with a reference: 2; 16:9 2k high transparent with a
reference: 2; 1:1 1k medium transparent with a reference: 1). Balance before: **85.21**. Balance at the end: **67.21**.
Spent: **18.00**.

The balance was read once, after the last job. Jobs ran at most four at a time.

| # | Direction | What | Settings | Reference | Estimate | Charged | Result | Balance after |
|---|---|---|---|---|---|---|---|---|
| 17 | brick-brawl | key art | 16:9, 2k, high | none | 2 | 2 | `brick-brawl/key-art.png` | |
| 18 | snack-attack | key art | 16:9, 2k, high | none | 2 | 2 | `snack-attack/key-art.png` | |
| 19 | brick-brawl | scene | 16:9, 2k, high | its key art | 2 | 2 | `brick-brawl/scene.png` | |
| 20 | brick-brawl | map | 21:9, 2k, high | its key art | 2 | 2 | `brick-brawl/map-raw.png` | |
| 21 | brick-brawl | creature line-up | 16:9, 2k, high, transparent | its key art | 2 | 2 | `brick-brawl/creatures-raw.png` | |
| 22 | brick-brawl | icon sheet (9 icons) | 1:1, 1k, medium, transparent | its key art | 1 | 1 | `brick-brawl/icons-sheet.png` | |
| 23 | snack-attack | scene | 16:9, 2k, high | its key art | 2 | 2 | `snack-attack/scene.png` | |
| 24 | snack-attack | map | 21:9, 2k, high | its key art | 2 | 2 | `snack-attack/map-raw.png` | |
| 25 | snack-attack | icon sheet (9 icons) | 1:1, 1k, medium, transparent | its key art | 1 | 1 | `snack-attack/icons-sheet.png` | |
| 26 | snack-attack | creature line-up | 16:9, 2k, high, transparent | its key art | 2 | 2 | `snack-attack/creatures-raw.png` | 67.21 |

Totals: 10 images kept, 0 refused, 0 retries. 18 credits: 9 per direction, the same as round 1.

Notes
- Prompts asked for no text, original characters, and "training bag" (the wording that passed the filter in round 1).
  No image has a watermark, and nothing was removed from any image.
- `brick-brawl/creatures-raw.png` is not the file exactly as generated: it came with a soft coloured glow behind each
  boss in the transparency. The glow was cut with ffmpeg by raising the alpha threshold
  (`lut=a='clip((val-205)*5.1,0,255)'`); the colours and the creatures are untouched. The original is job
  `c6c99b2a-4654-4412-b3f9-10d852b7719b` in the Higgsfield history.
- `parts/` holds the nine icons and the zone-1 boss of each direction, cut with ffmpeg (crop only). Snack Attack also
  has the burger cut; the rest of its line-up, and the rest of Brick Brawl's, stand too close to cut with a rectangle.
- Two things in the results to redraw before any is used as a real design: the Brick Brawl avatar is a toy minifigure
  (a known brand's look), and its red dragon has a flame-tipped tail close to a famous character. Both are noted in
  `directions.md`.

---

## Step 3: game page concepts (live-ops)

2026-11-25, live-ops, pitch step 3 (`game-page/`). Model `gpt_image_2_6`, paid with credits (`use_unlim: false`).
Both configurations were estimated with `estimate_image_cost` before use (16:9 2k high, no reference: 2; 1:1 2k high,
no reference: 2). Balance before: **67.21**. Balance after the four jobs: **59.21**. Spent: **8.00**. The gui-designer
was using Higgsfield at the same time; only this role's generations are listed, and the balance moved by exactly these
four between the two reads.

| # | What | Settings | Reference | Estimate | Charged | Result | Job | Balance after |
|---|---|---|---|---|---|---|---|---|
| 27 | game icon concept: avatar's red glove against Chomp Frog | 1:1, 2k, high | none | 2 | 2 | `game-page/icon-concept.png` | `106c5f05-4ac0-4b26-80b6-0d4215887fe2` | |
| 28 | thumbnail 1, the punch: avatar at the bag, the lane and three bosses behind | 16:9, 2k, high | none | 2 | 2 | `game-page/thumb-1.png` | `5b6ac250-65a6-4a33-93a9-1a8f899175df` | |
| 29 | thumbnail 2, the base: five bosses on pads with cash | 16:9, 2k, high | none | 2 | 2 | `game-page/thumb-2.png` | `58f966d2-75af-4d2b-a25d-1a5a49970591` | |
| 30 | thumbnail 3, the steal: a thief carrying Bit Shark, the owner chasing, a shielded base | 16:9, 2k, high | none | 2 | 2 | `game-page/thumb-3.png` | `8b04a6c3-5946-4240-9d02-a3a968ca7d83` | 59.21 |

Totals: 4 images kept, 0 refused, 0 retries (one was allowed; none of the four broke a rule). Files are saved exactly
as generated: no crop, no edit, no watermark present or removed. Prompts asked for no text, square inset studs, a
blocky avatar and original cube creatures. The session was cut off by a usage limit after the jobs were submitted;
on resuming, the same four jobs were collected from the history, so nothing was paid for twice.

---

## Round 3: UI kit (gui-designer)

2026-11-25, gui-designer, pitch step 3 (the UI kit in `ui-kit/`). Model `gpt_image_2_6`, paid with credits
(`use_unlim: false`). Each configuration was estimated with `estimate_image_cost` first (1:1 2k medium transparent
with a reference: 1.75; 16:9 2k high: 2). Balance when this role started: **67.21**; it read **59.21** before the first
job below, because the live-ops role was generating game page concepts at the same time (its jobs are not in this
table). Only this role's jobs are listed. Files are in `ui-kit/src/`.

| # | What | Settings | Reference | Estimate | Charged | Result | Balance after |
|---|---|---|---|---|---|---|---|
| 27 | icon sheet A, 16 icons (strength, speed, settings, steal, alarm, hazard, timer, heart, skull, padlock, crate, star, offline, bag, sell, pick up) | 1:1, 2k, medium, transparent | `brick-brawl/icons-sheet.png` | 1.75 | 1.75 | `ui-kit/src/icons-a-sheet.png` | |
| 28 | icon sheet C, 16 icons (six zone badges, swap, place, music, sound, ticket, run, shield, shield down, trophy, check) | 1:1, 2k, medium, transparent | same | 1.75 | 1.75 | `ui-kit/src/icons-c-sheet.png` | |
| 29 | scene: at base (bag, pads, gate, lane) | 16:9, 2k, high | none | 2 | 2 | `ui-kit/src/scene-base.png` | |
| 30 | scene: fight (Chomp Frog on a pad by the lane) | 16:9, 2k, high | none | 2 | 2 | `ui-kit/src/scene-fight.png` | |
| 31 | scene: carry (frog on the head, Rolling Log ahead) | 16:9, 2k, high | none | 2 | 2 | `ui-kit/src/scene-carry.png` | 49.71 |

Notes
- No refusals, no retries. Prompts asked for no text; no image has a watermark and nothing was removed from one.
- The icon sheets came with a soft glow in the transparency and without the white rim the style guide asks for.
  `ui-kit/src/cut_icons.sh` (ffmpeg only) hardens the alpha, adds the rim by growing the alpha outward in white, and
  crops each cell. No pixel inside an icon is redrawn. The untouched sheets are kept beside the cut icons.
- Known misses in the scenes (they are backdrops for HUD mocks, not designs): the Rolling Log came out round (the
  style guide wants stepped boxes), the carry scene's fences are brown, and the frog's face differs between scenes.

Second batch, same day, after the brief gained the attacking products and the style guide listed the product icons
(estimates: 1:1 2k medium transparent with a reference 1.75; 1:1 1k medium transparent with a reference 1).

| # | What | Settings | Reference | Estimate | Charged | Result | Balance after |
|---|---|---|---|---|---|---|---|
| 32 | icon sheet B, 16 product icons (Auto Punch, 2x Power, 2x Cash, Fast Carry, Long Lock, Extra Spots, Quick Hands, Iron Grip, Starter Pack, four cash packs, Instant Shield, Shield Breaker, Lucky Spin x1) | 1:1, 2k, medium, transparent | `brick-brawl/icons-sheet.png` | 1.75 | 1.75 | `ui-kit/src/icons-b-sheet.png` | |
| 33 | icon sheet D, 9 icons (Lucky Spin x3 and x10, first-session arrow, pointer arrow, grab, lost heart, shield broken, toggle; a house that is not used) | 1:1, 1k, medium, transparent | same | 1 | 1 | `ui-kit/src/icons-d-sheet.png` | 46.96 |

- The ninth icon on sheet D (a small house, meant for "home") is not in the brief's content tables and is not cut or used.
- The spin wheels came out round, not square-built as the style guide asks; flagged in `ui-kit/README.md`.

Round 3 total for the gui-designer: 7 images, **12.25 credits** (9.50 + 2.75), 0 refusals, 0 retries. Balance after
the last job: **46.96** (the live-ops role's spending is in that figure too).

---

## Final pass: Perfect Auto Punch icon (gui-designer)

2026-11-25, gui-designer, UI kit final pass. Model `gpt_image_2_6`, `use_unlim: false`. Estimated first with
`estimate_image_cost` (1:1, 1k, medium, transparent, two references: 1 credit; budget was 2). Balance before: **46.96**.

| # | What | Settings | Reference | Estimate | Charged | Result | Job | Balance after |
|---|---|---|---|---|---|---|---|---|
| 34 | one icon: Perfect Auto Punch (red glove with a gold star on a spring, flash-yellow impact star behind) | 1:1, 1k, medium, transparent | `brick-brawl/icons-sheet.png` and `ui-kit/src/icons-b-sheet.png` (the Auto Punch icon is on it) | 1 | 1 | `ui-kit/src/icons-e-sheet.png`, cut to `ui-kit/src/icons/perfect-auto-punch.png` with `cut_icons.sh` (`GRID=1`) | `7d007a83-c597-4352-9454-45bf7be77ba4` | 45.96 |

No retry, no refusal, no watermark; nothing removed. The cut script hardened the alpha and added the white rim as for the other icons.

---

## Group icon (art-director)

2026-11-25, art-director, at the manager's request ("i created the group. can you please give me an icon for it"). Model `gpt_image_2_6`, `use_unlim: false`, reference `game-page/icon-concept.png` (job `106c5f05-4ac0-4b26-80b6-0d4215887fe2`). Balance before: **45.96**. Both configurations were estimated first (1:1 2k high with a reference: 2; 1:1 1k medium with a reference: 0.75 quoted).

| # | What | Settings | Estimate | Charged | Result | Job | Balance after |
|---|---|---|---|---|---|---|---|
| 35 | group icon, glove hits Chomp Frog | 1:1, 2k, high | 2 | 2 | `game-page/group-icon-source.png`: **rejected**, the model drew a white circle outline into the image, and the frog's arm and the glove's arm ran past the circle | `76d42ff5-9e3b-4444-aad2-b38e91202e0a` | 43.96 |
| 36 | the one retry: prompt said no ring and a compact subject in the middle 70% | 1:1, 1k, medium | 0.75 | 1 (balance moved by 1.00) | `game-page/group-icon-source-2.png`: **used** | `bbab8f9b-4370-4c5b-be94-c8bc8376f422` | 42.96 |

Spent: **3.00** (over the 2 budget by 1: the first image broke a rule, so the one allowed retry was used). Balance after: **42.96**. No watermark present; nothing removed.

---

## Base area layout renders (art-director)

2026-11-25, art-director, base-layout step (the manager: "I want to first actually have a layout of what the base area will look like"). Model `gpt_image_2_6`, `use_unlim: false`, 16:9, 2k, high. Reference for every image: `ui-kit/src/scene-base.png` (uploaded as media `8f536d85-f9f4-44a2-97e8-ca3a6cfb2dfd`). Estimated first with `estimate_image_cost` (16:9 2k high, one reference: 2 credits). Balance before: **42.96**. Budget 6, ceiling 9.

| # | What | Estimate | Charged | Result | Job | Balance after |
|---|---|---|---|---|---|---|
| 37 | base area from above (hub, 8 plots in a U, track, gate) | 2 | 2 | `base-layout/src/render-sources/view-area-try1-rejected.png`: **rejected**, it drew farm animals (pig, chick, dog, sheep) that are not in the content table, square shallow plots and lock pads outside the fences | `6c8c330c-06a4-4ee6-8e99-03dde065e8a1` | 40.96 (balance read after #39) |
| 38 | one plot from the player's camera | 2 | 2 | `base-layout/view-plot.png`: used | `31c05be0-fb15-40b2-9c6f-2e30bef0f66c` | 38.96 |
| 39 | locked plot beside an open one, seen from the yard | 2 | 2 | `base-layout/view-shield.png`: used | `a28991a8-350a-4ab0-b9d5-40834001b521` | 36.96 (read) |
| 40 | the one retry of #37: deep plots, only the four approved creatures, bag right of the entrance | 2 | 2 | `base-layout/view-area.png`: used | `44815d55-d75c-4f76-a889-dbf5559c92eb` | 34.96 (read) |

Spent: **8.00** (budget 6, ceiling 9: the first area view broke the "nothing not in the content tables" rule, so the one retry was used). Balance after: **34.96**. No lettering asked for or present; no watermark; nothing removed.
