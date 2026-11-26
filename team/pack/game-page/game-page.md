# Huss for Bosses: game page concepts

Status: DRAFT, part of the pitch pack. Written 2026-11-25 by live-ops, with `style-guide.md` as the art authority.

**These are concepts made from mockups.** The four images here were generated from a description before any of the
game exists. The shipped icon and thumbnails are made at the end of the build from real screenshots of the real game
(improved in Higgsfield, finished in FigCraft), and show only things that exist in it. Nothing here is uploaded or
published by the team: the Creator Dashboard steps are the manager's.

Sources: `vault/roblox-docs/game-page-icon-description-genre-maturity-audience.md` (checked 2026-11-24),
`vault/roblox-docs/discovery-thumbnails-referrals-ads.md` (checked 2026-11-11),
`vault/roblox-docs/paid-random-items-policy.md` (checked 2026-11-11),
`vault/patterns/honest-clear-icon-thumbnail-and-title.md` (docs), `vault/playbooks/live-ops.md`. All three digests must
be re-read before the real page is prepared: the Kids and Select page and the questionnaire change often.

## Title

The game is **Huss for Bosses**. **Decided (manager, 2026-11-25): title line 1, `Huss for Bosses`, no subtitle.** Lines 2 and 3 stay below as the record.

| # | Title line as it would appear | Note |
|---|---|---|
| 1 | `Huss for Bosses` | The name alone. Recommended for launch: short, and the icon carries the meaning. |
| 2 | `Huss for Bosses: Punch & Steal` | Adds the two verbs a stranger searches for. |
| 3 | `Huss for Bosses - Punch, Carry, Steal` | The whole loop in three words. Longest; may be cut off on small tiles. |

- **No bracket tags are offered.** The docs digests say nothing in favour of them, and the one vault note on title tags
  (`live-ops.md`, "A sustainable, announced update cadence") allows an update tag only when the update is real, on weak
  evidence. A tag such as `[UPDATE]` can be added after a real update, never at launch.
- Nothing in the title promises Robux or a reward (docs: such metadata is not prioritized for recommendations).
- `UNVERIFIED`: the title length limit is not in the digest. Check the field in the Creator Dashboard (the chosen title is short).

## Description

Limits (docs digest): about 1,000 characters, aim under 950; the first 160 or so show in search and on mobile. No
hashtags, no list of controls. The text below is 942 characters and its first line is 158.

```
Huss for Bosses: a punch-and-steal boss collecting game. Time your huss huss huss punches to power up, beat voxel bosses, carry them home and guard your base!

PUNCH: Tap as the ring closes to launch a three-punch combo on your bag. Every hit builds Power.
FIGHT: Run down the lane through 6 zones and out-punch 36 bosses. Stronger bosses are harder to beat and earn more.
CARRY: Lift your boss and dodge each zone's hazard on the way home.
EARN: Place bosses at your base to earn cash, even while you are away. Upgrade them, then buy Punch Strength and Punch Speed.
STEAL: Sneak into other bases and carry off their bosses. Punch thieves to get yours back, and raise your lock shield before you leave.
REBIRTH: Start over stronger, with more room for bosses.

Plays on phone, tablet, PC and gamepad.
Sells optional passes and items, including a Lucky Boss Spin with random results. All outcomes and odds are shown in the game before you buy.
```

- Every line is a feature in `brief.md` (systems 1 to 13). Nothing else is claimed: no quests, codes, trading, pets,
  events or leaderboards, because version 1 has none.
- **Paid random item line.** The docs read do not require a disclosure in the description: the requirement is the odds
  shown in the game before purchase, the restricted-player check, and a truthful "paid random items" answer in the
  maturity questionnaire. The last line is there for honesty and can be cut if the manager wants the space.
- **Shop and punch rechecked 2026-11-25.** The shop is now 19 items (brief system 13), including attacking products
  (Shield Breaker, Quick Hands, Iron Grip) and Perfect Auto Punch, and rebirth keeps what was bought with Robux. The
  description lists no product except the spin and says nothing about what rebirth keeps, so it stays true. The
  PUNCH line was reworded: the punch is now one timed tap that launches a three-punch burst (brief system 1), where
  the old line said combos were landed. Re-check against the final shop table before the page is built.
- "Even while you are away" is the offline earnings rule (capped at 2 hours a pad). If the cap changes, the line stays
  true.

## Genre

Pick once, carefully: the docs say genre can be changed only once every three months, and Roblox can change one that
does not fit.

- **Decided (manager, 2026-11-25): Simulation, with the Tycoon or Incremental Simulator subgenre** (train a stat, collect things that earn,
  rebirth). `UNVERIFIED`: the digest lists only the Shooter and Action subgenres; read the genre page for the exact
  Simulation subgenre names before choosing.
- Not chosen: Action, subgenre Battlegrounds & Fighting (named in the digest). It fits the punching less well than it
  sounds: fights are a timing minigame against bosses, and players never fight each other for eliminations.

## Maturity and content questionnaire: suggested answers

The manager answers the questionnaire in Publish settings > Content rating. These are the answers the brief supports;
anything the build changes must be re-checked. A game with no answers is restricted for everybody.

- [ ] **Violence: yes, mild / unrealistic, repeated.** Cartoon punching of cube creatures and of a thief; a beaten boss
  shrinks and is carried, a punched thief is stunned for 1.5 seconds. Nobody dies, no bodies, no realistic harm.
- [ ] **Blood: none.**
- [ ] **Fear: none.** No dark zone (style guide), no jump scares.
- [ ] **Crude humor: none. Strong language: none. Romance: none. Alcohol: none. Sensitive issues: none.**
- [ ] **Unplayable gambling content: none.** No casino imagery; the spin is a paid random item, answered below.
- [ ] **Paid random items: YES.** The Lucky Boss Spin is bought with Robux and gives a random boss. The build shows every
  outcome and its odds before purchase and hides it from restricted players (brief, system 13).
- [ ] **Paid item trading: the manager answers this, and the answer is not settled by the docs; check with Roblox
  before release.** Facts to answer truthfully: (1) the game has no trading, gifting or marketplace screen. (2) Bought
  bosses (Lucky Boss Spin, Starter Pack) can be stolen from a base like any boss (brief system 10, manager's
  "replicate the genre" call); the boss keeps its BOUGHT tag and moves to the thief. (3) Any boss bought with Robux (a Lucky Spin boss or the Starter Pack's Headbutt Ram) cannot change hands in a steal
  when `IsPaidItemTradingAllowed` is false for either player; a failed check counts as false (`TEAM CALL` 38,
  `UNVERIFIED`). A Roblox reply on the DevForum says the flag restricts trading of all paid items, so the Ram is
  covered like a spin boss. (4) The docs say players for whom the flag is false must not trade the results of paid
  random items; they do not say whether theft is a trade (`paid-random-items-policy.md`, checked 2026-11-11, and the docs page
  re-read 2026-11-25). So whether this game "has paid item trading" is not decided by anything read: if a steal
  counts as a trade, answer yes; if not, no. Ask Roblox (or re-read the policy and the DevForum announcement) before
  release, and answer the questionnaire by what they say. Do not guess, because a mismatched answer can get the label
  replaced.
- [ ] **Social hangout: no. Free-form user creation: no. Media sharing: no. Content feeds or auto-playing media: no.
  Content captured from other games: no. Generative AI interaction: no.**
- Expected label from these answers: Minimal or Mild. Roblox assigns it; do not promise it anywhere.

**Who can play at launch (docs, 2026-11-24).** The brief's audience is about 8 to 16. A new game is available only to
age-checked 16+ accounts until it passes the Kids and Select evaluation (creator verification, 2-step verification, a
fee or two months of subscription, and 100 unique plays by highly engaged age-checked users within 60 days). The launch
plan has to allow for this; the manager will pay or advertise as needed (2026-11-25: "i'll have to advertise to unlock to 16+. or whatever else. if i need to pay 1000 robux i will"), and the steps go on the board as `BLOCKED: manager` at build time.

## Search keywords

Roblox has no keyword field that ranks (docs: tags and hashtags are not used). These are the words to keep in the
title, the first 160 characters and the genre, in plain sentences: **punch, punching, boxing, bosses, boss, steal, base,
collect, tycoon, simulator, rebirth, power, voxel**. No other game's name is used as a keyword.

## Icon concept

**File:** `icon-concept.png` (2048 x 2048, to be made at 512 x 512 for real).

- **Shows:** the player's blocky avatar landing a red boxing glove on Chomp Frog (zone 1 Common, the first boss every
  player meets), a flat yellow impact star between them, grey stud road, blue sky.
- **Why:** one action and two faces, the main verb of the game; readable at 150 px, where the docs say icons are
  shown (`honest-clear-icon-thumbnail-and-title.md`; icon section of the game page digest).
- **Lettering (decided, manager 2026-11-25: "lets do work huss yes"):** the shipped icon carries the word HUSS, set in FigCraft with the kit's font (Montserrat Black caps, white with an ink outline, as the Huss label) and never generated. The concept image has no lettering; it is a mockup. Keep the word clear of the glove and the frog's face, and check it at 150 px (the docs have no rule on icon text).
- **Checks:** content table only: pass. Corrected stud look: pass (square inset studs on the road and grass, matte, real
  avatar shape, plain-cube boss). Brand or character resemblance: pass, with one note: the frog's long jaw makes it read
  a little like a crocodile; the real mesh follows the style guide's frog. Small size: pass at 150 px (green shape, red
  glove, yellow star all still read). **Honesty note for the real icon:** the concept draws the frog about twice the
  avatar's height; a Common is 4 studs, shorter than the avatar. The shipped icon uses the real scale or a bigger boss.

## Thumbnail concepts

Three different promises, as the docs suggest for the 2 to 5 active Home thumbnails (each a different idea, not a
colour variant). Real ones are 1920 x 1080, under 3 MB, with nothing important along the bottom edge.

### 1. The punch: "train, then go get them"
**File:** `thumb-1.png`

- **Shows:** the avatar hitting the red punching bag on its blue frame; behind, the lane running into the zones with
  Chomp Frog, Bit Shark and Frost Byte waiting on it; the Brick Meadow windmill, the Sand Blocks pyramid, the Ice Blocks
  peaks and the Lava Bricks volcano on the horizon.
- **Why:** the first thing a player does and what it is for, in one picture (pattern: "the main action, a character,
  bright readable shapes").
- **Caption, if wanted (FigCraft, top half only):** "HUSS HUSS HUSS!"
- **Checks:** content table only: pass (bag, lane, three named bosses, four named zones' landmarks). Stud look: pass
  (square inset studs on every surface; real avatar; cube bosses). Resemblance: pass. Notes for the real one: the
  bag stands on the lane here and belongs on the base plot; bosses stand on boss pads, not loose on the road; the
  zones run one after another down the lane, not side by side; Pirate Plates is missing.

### 2. The base: "collect them and get paid"
**File:** `thumb-2.png`

- **Shows:** a fenced base plot with Chomp Frog, Snap Scorpion, Bit Shark, Frost Byte and Star Golem on boss spots,
  small to huge, green cash cubes piling on the pad in front of each, the bag at the front by the entrance (as in the approved base layout), the
  avatar cheering in front. Real thumbnails are made from screenshots of the built hub, so its look follows `base-layout/`.
- **Why:** the collection and the income are the long goal; the size ladder from frog to golem shows there is far to
  go without a word.
- **Caption, if wanted (FigCraft):** "36 BOSSES". Name tags and tier chips over the bosses come from the real game's UI.
- **Checks:** content table only: pass. Stud look: pass (studs on grass, road, pads, fence, bag; the block trees are
  nearly plain cubes and need the tile in the real world). Resemblance: pass (Star Golem follows our own mockup).
  Notes: the bag is a plain box here, the style guide's is a stepped octagon; a new player will not own a Star Golem
  (zone 6 Mythic), so the real thumbnail should show a base a player can plausibly reach, or keep the golem as the
  visible long goal on purpose: the manager's call.

### 3. The steal: "take theirs, guard yours"
**File:** `thumb-3.png`

- **Shows:** a thief running off with Bit Shark held over their head, the owner right behind with a red glove
  swinging, the empty spot left on the owner's base beside Chomp Frog and Snap Scorpion, and a neighbour's base inside
  a cyan lock shield.
- **Why:** the moment that sets this genre apart and the one players retell; it also shows the shield, so the promise
  includes the defence.
- **Caption, if wanted (FigCraft, top half):** "STEAL BOSSES!"
- **Checks:** content table only: pass (carrying, stealing, getting it back, lock shield, base, three named bosses).
  Stud look: pass. Resemblance: pass. Notes: the frog in the background lost its fists and angry face (it must match
  Chomp Frog); the shark is carried lying flat, the style guide carries bosses upright; the shield reads as a glass
  box, the guide asks for stud panels with a solid rim.

## Suggestions from the vault (optional, the manager picks)

| Suggestion | Source | Evidence |
|---|---|---|
| Make 4 or 5 real thumbnails and set 3 or 4 active for Home so Roblox tests them per user group | `discovery-thumbnails-referrals-ads.md` | docs |
| Compare icon candidates at 150, 100 and 64 px beside typical competitors before choosing | `honest-clear-icon-thumbnail-and-title.md` | docs |
| A short gameplay video on the page (no voice, no lyrics; 3 uploads a month) | game page digest; one creator's small samples | docs for the rules, unverified for the effect |

## Group

**The group exists.** Name **Huss for Bosses** (decided), community id **432262304**, https://www.roblox.com/communities/432262304/Huss-for-Bosses, created by the manager and owned by their account (2026-11-25). Creating it is no longer a step for anyone. Source for sizes: `vault/roblox-docs/badge-product-group-images.md` (checked 2026-11-16, not re-read for this pass; re-check before uploading anything else).

**First group icon: uploaded (2026-11-25), moderation pending.** The main session uploaded `game-page/group-icon.png` (512 x 512 PNG) through the manager's Chrome at their request (Configure Community, Emblem). Roblox answered "Successfully updated community icon" and then showed the pending-review placeholder, so whether moderation accepts it is `UNVERIFIED` until it appears. It replaced the placeholder emblem the manager had set.
- Files: `game-page/group-icon.png` (the one uploaded), `game-page/group-icon.figcraft` (FigCraft source, with a hidden circle safe-area guide), `game-page/group-icon-150.png` and `group-icon-64.png` (circular-mask previews only, not for upload), `game-page/group-icon-source-2.png` (Higgsfield original, 1024 px; `group-icon-source.png` is the rejected first try).
- Shows: the Chomp Frog's voxel head with a red glove (short wrist, blue sleeve) landing on its face, a flat yellow impact star, flying green cubes, blue sky, a strip of square-stud ground at the bottom. No text, no avatar body. Made from concept art for 3 Higgsfield credits.

**Group icon remake (end of the build; the first icon stays until then).** Made from real renders of the built game, improved in Higgsfield and finished in FigCraft, then uploaded by the manager or by the team on their word.
- **Shows:** a single close shot of the red boxing glove landing on a voxel boss face (Chomp Frog, or Star Golem if the manager picks it for the base thumbnail), a flat yellow impact star between them, grey stud road below and blue sky, all in the game's Roblox square-stud look. The game icon's idea recomposed for a circle, with the important parts inside a circle in the middle 80%.
- **Lettering:** none generated. A wordmark, if wanted, is set in FigCraft with a real font.
- **Content rule:** only things in the brief's content table (glove, a boss, impact star, stud ground).
- **Size and format:** 512 x 512 PNG was accepted on 2026-11-25. Check the image at 64 to 150 px.

**Cover photo (optional).** Roblox's configure page, seen 2026-11-25, takes a cover photo of **720 x 228 or 1440 x 456**. None is uploaded and none is made unless the manager wants one.

**Group description (draft):**
```
Home of Huss for Bosses: punch the bag, beat the bosses, carry them home, and steal from your friends. Updates and news are posted here.
```
No promise of Robux, rewards or release dates.

**Manager's steps** (they do these; the team does none of them)
- Done: the group is created (2026-11-25), and its first icon is uploaded.
- `BLOCKED: manager` Publish the place under the group: in Roblox Studio, File, Publish to Roblox As, choose the group as the creator, name it "Huss for Bosses", leave it private (`UNVERIFIED`: the dialog's wording). Do it before any real player joins: data stores belong to the group-owned game, so nothing has to be moved later (brief system 14). Passes and developer products are created under the group's game (brief system 13).
- `BLOCKED: manager` Set the group's social links (up to three) and profile; add the game to the group's page.
- Kids and Select questions go to the group owner for a group-owned game (docs digest): the manager's account. The manager will pay or advertise as needed.
- The real group icon is made at the end of the build and replaces the first one.

## Questions for the manager

1. **Star Golem on the base thumbnail:** keep it as the visible long goal, or show a base a new player can reach. Default: the team makes both from real screenshots at M6 and the manager picks then.

Answered 2026-11-25 and no longer questions: title line `Huss for Bosses`; genre Simulation; icon text HUSS; group name `Huss for Bosses` and the group created; Kids and Select (the manager will pay or advertise as needed); group banner (a cover photo is optional, none planned).

## For the build (queued, not done now)

- `BLOCKED: manager`: publish the place under the group (see Group), upload icon and thumbnails, set title, description and genre (Simulation), answer the questionnaire, start the Kids and Select steps, activate Home thumbnails.
- `UNVERIFIED` until the real page exists: how the icon and thumbnails look on the Roblox page and Home tiles; title length limit; Simulation subgenre names; moderation of each image, the group icon included.
