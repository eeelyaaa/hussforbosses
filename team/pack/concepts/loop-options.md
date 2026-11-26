# Huss for Bosses: loop options (pitch step 2)

Written 2026-11-25 by the game-designer. Status: OPTIONS for the manager to pick from. Nothing here is decided, built or measured. Every number is arithmetic on paper.

## What is fixed (the manager's words, not reshaped)

Source: `brief.md`, "The idea, in the manager's words". All three options below keep every line of this.

- A "Steal a [Thing]"-style linear runner and base-collector tycoon.
- You build Power by punching ("Huss Huss") a punching bag at your base.
- You run down a lane of zones. Your Power decides how far you get and which bosses you can defeat. Further zones hold higher boss tiers, and those earn more.
- A beaten boss is brought back to base and placed on a spot, where it earns and can be upgraded.
- Other players can run into your base and carry a boss off. You can chase and punch the thief to get it back. A timed lock shield protects the base.
- The bosses are the creatures: 6 themed zones, 6 creatures each (about 36), in rarity tiers. Plus rebirth.
- Version 1 has a full Robux shop: passes, cash packs, a lucky boss spin, a starter pack.
- Mobile-first.

Concept in one sentence (same for all options): **punch a bag to get strong, run down the lane to beat a boss, and bring it home to earn for you.**

## What is open (what the options differ on)

| | Open point | The choices |
|---|---|---|
| a | How a boss fight plays | Automatic exchange decided by Power / tap duel with health bars / timed hits |
| b | How the boss gets home | Appears at base / carried along the lane, at risk from hazards / carried, at risk from other players |
| c | What stops you going further | Power gates at zone entrances / no gates, the bosses are simply too strong / a gatekeeper fight |
| d | How bag training plays | Hold to auto-punch / tap with a combo / timed taps; and how bag upgrades work |
| e | How bosses appear in a zone (found while writing this) | Six fixed pedestals per zone, always there / pads that roll a random creature by rarity odds on a timer |
| f | What losing a fight costs (found while writing this) | Nothing, you are knocked back / a short stun / you lose some Power |

The brief says "when you bring them back to base", which leans toward carrying (options B and C). Option A is offered because it is the cheapest, and it still has the player place the boss on the spot by hand.

## The same in every option

So the options can be compared on the open points only.

- **Base:** one plot per player beside the lane's start, with the punching bag, a row of boss spots (draft: 10), a lock button, and a cash pad in front of each boss.
- **Earning:** a placed boss drops cash onto its pad every second; walking over the pad collects it.
- **Upgrading:** stand at a placed boss, press Upgrade, pay cash, its income goes up one level.
- **Stealing at bases:** a visitor walks into an unlocked base, holds a prompt on a boss for about 2 seconds, lifts it overhead and runs for their own base, slowed while carrying. The owner gets an alert and an arrow to the thief. One punch from the owner makes the thief drop it and the boss snaps back to its spot. If the thief reaches their own base, it is theirs.
- **Lock shield:** a button at the base raises a shield for a set time (draft: 60 seconds), then it is on cooldown (draft: 60 seconds). Nobody can enter while it is up.
- **Assumption, needs the manager's yes:** a base exists only while its owner is in the server. Nothing can be stolen from a player who is offline.
- **Rebirth:** reach the requirement, reset Power, cash and bag, gain a permanent multiplier. Draft numbers further down.
- **What a second player adds in every option:** somebody to steal from and to guard against, and a row of other players' bosses you can see and want.

---

## Option A: "Power Check"

**One line:** train, walk through the gate your Power opens, and the fight is a five-second show whose winner Power already decided.

| Open point | Choice |
|---|---|
| a Fight | Walk into the boss's ring and the fight runs by itself: you punch automatically, its health bar drains at your Power per hit. Enough Power: you win in 3 to 6 seconds. Not enough: the ring shows the number you need in red and you are bounced out. |
| b Getting home | The beaten boss shrinks into a crate that appears at your base. You open the crate and place the boss on a spot yourself. |
| c What stops you | A gate at each zone entrance with its Power number on it. Below the number you cannot pass. |
| d Bag | Hold the screen (or stand at the bag) to auto-punch. Bag upgrades bought with cash multiply Power per punch. |
| e Spawns | Six fixed pedestals per zone, one per creature, always there. Each respawns for you a few seconds after you beat it. |
| f Losing | Nothing. You are bounced back and shown the number. |

**What the player does**

| Timescale | What happens |
|---|---|
| Every few seconds | Holds to punch the bag and watches Power tick up; collects cash from pads. |
| Every few minutes | Power passes a boss's number, runs down, wins the automatic fight, runs back, opens the crate, places the boss, buys an upgrade or a bag tier. |
| 20-minute session | Minute 1: first boss placed. Minute 5: zone 2 gate open, 4 to 5 bosses earning. Minute 10: bag tier 3, replacing weak bosses. Minute 20: zone 3 or 4, spots full, choosing which bosses to keep. |
| Tomorrow | The next gate's number, the creatures still missing from the collection, the rebirth bar. |

**How stealing fits:** only at bases, as fixed. Because bosses arrive in a crate, stealing is the only time anybody ever carries a boss, so it stands out, but it is also the only tense thing in the game.

**Risks**
- The lane is a walk there and a walk back with nothing at stake. The run "down the lane" is the manager's centrepiece and here it is a commute.
- With fights automatic and training on hold, the hands do almost nothing. It may read as an idle game with a corridor attached. Only a playtest can say.
- A new creature differs from the last one only by its number (the "bigger numbers, nothing new to do" tell in `vault/playbooks/quality-bar.md`).

**Build cost: small.** No carry-on-the-lane system, no fight input, no hazards. Stealing, the shield, saving and the shop cost the same in every option.

---

## Option B: "Carry It Home"

**One line:** out-punch the boss in a tap duel, then haul it over your head back up the lane past the zone's hazards before you can call it yours.

| Open point | Choice |
|---|---|
| a Fight | Tap duel with two health bars. Each tap is a punch worth your Power. The boss winds up a slam every few seconds, shown by a red circle on the floor; step out of it or lose a chunk of your bar. Power decides whether the fight is winnable: at the boss's listed Power it takes about 8 to 12 seconds, at double it takes 4. Well below it, your punches barely move the bar. |
| b Getting home | You lift the beaten boss overhead and carry it back along the lane, slower than normal. Each zone has its own moving hazard (swinging bags, rolling barrels, falling ice). A hit knocks the boss out of your hands; you have a few seconds to grab it again or it goes back to its pad. Other players cannot take it on the lane: stealing stays at bases, as the manager described. |
| c What stops you | No gates. You can run into any zone and look. Each boss wears its Power number over its head, green if you can take it and red if not, and a boss far above you knocks you back with one slam. |
| d Bag | Tap to punch. A short combo meter fills while you keep tapping and adds up to +50% Power per punch. Holding still works at the base rate, so nobody has to mash. Bag upgrades bought with cash multiply Power per punch. |
| e Spawns | Boss pads in each zone roll a creature by rarity odds every 20 to 30 seconds, so a Legendary showing up is an event people run for. Each player has their own fight with it (their own health bar on the boss), so nobody is blocked. |
| f Losing | You are knocked down for 2 seconds and thrown clear. No Power or cash is lost. |

**What the player does**

| Timescale | What happens |
|---|---|
| Every few seconds | Taps the bag and keeps the combo up; in a fight, taps and sidesteps the slam; while carrying, dodges hazards. |
| Every few minutes | One trip: train to the next green number, run down, duel, carry home, place, collect, upgrade. The further the boss, the longer and riskier the carry. |
| 20-minute session | Minute 1: first Common beaten and carried the short way home. Minute 5: first zone 2 trip, the first dropped boss, 4 to 5 bosses earning. Minute 10: a rare spawn seen on a pad with a red number; back to the bag for it. Minute 20: zone 3 or 4 trips of 40 to 60 seconds each way, first steal attempt on the base, lock timing learned. |
| Tomorrow | The rare creature seen but not yet beatable, a deeper zone visited but not yet survivable, the rebirth bar, getting even with whoever stole from you. |

**How stealing fits:** the carry on the lane teaches the carry used for stealing, so the player already knows the rules (slowed, one hit drops it) before anybody robs them. The longest trips keep players away from base longest, which is exactly when the lock timer matters.

**Risks**
- Trip length grows with every zone. A zone 6 carry could turn into a long walk. It needs a cap, for example a shortcut back that opens per zone; that is a tuning job, and its numbers need a playtest.
- Dropping a boss to a hazard on a laggy phone can feel unfair. Hazards have to be slow, readable and generous.
- The tap duel needs a real Feel pass (hit reactions, sound, the slam telegraph) or it is just a bar going down.
- Open zones mean a new player can wander into zone 6 at minute 2. That is good for showing what is ahead, but they must not be able to get stuck or farmed there.

**Build cost: medium.** Adds the duel (boss wind-up, health bars, dodge), the carry state on the lane, one hazard type per zone (6), and rolled spawns. The carry state is shared with stealing, which every option builds anyway.

---

## Option C: "Timed Hits, Open Lane"

**One line:** land your punches on the beat to hit above your weight, and carry the boss home through a lane where anybody can knock it out of your hands.

| Open point | Choice |
|---|---|
| a Fight | Timed hits. A ring closes on the boss; tap inside the window for a Good or a Perfect. Perfects multiply the punch, so a skilled player can beat a boss up to about 1.5 times their Power. Misses let the boss hit back. |
| b Getting home | Carried overhead, slowed, and stealable the whole way: any player can punch the carrier, the boss drops, and whoever grabs it first carries on. Zone hazards as in option B. |
| c What stops you | A gatekeeper at each zone entrance: a one-time timed-hit fight against the zone's guard. Beat it once and the zone stays open until rebirth. |
| d Bag | The same closing ring on the bag. Perfect punches give double Power, so training is the practice ground for fights. Holding gives the base rate. |
| e Spawns | Rolled pads as in option B, but the boss is shared: one player fights it at a time, and whoever wins it carries it. |
| f Losing | A 3-second stun, and anything you were carrying is dropped. |

**What the player does**

| Timescale | What happens |
|---|---|
| Every few seconds | Times taps on the bag ring; in a fight, times hits; while carrying, watches for other players and jukes. |
| Every few minutes | One trip, as in option B, with an ambush possible anywhere on the way home. Or the reverse: waiting on the lane for somebody else's carry. |
| 20-minute session | Minute 1: first boss, short carry. Minute 5: first time robbed on the lane. Minute 10: first gatekeeper beaten. Minute 20: zone 3, travelling with or against other players, a few bosses won and a few lost. |
| Tomorrow | Rivalries, the gatekeeper you could not beat, rare spawns, the rebirth bar. |

**How stealing fits:** stealing is everywhere, at bases and on the lane. This is the most "steal" of the three and the most clip-friendly, and it goes one step beyond what the manager described (base stealing with a lock): the lock shield does nothing on the lane.

**Risks**
- A new or young player can train for five minutes, win a boss and lose it to a stronger player ten steps from home, several times in a row. The vault's one record of a stealing game's feedback is complaints about being targeted (`vault/patterns/interact-with-other-players-progress.md`, counter-examples).
- Timing windows on phones depend on frame rate and network delay. The window has to be judged on the client and checked on the server, which is the hardest networking in any of the three options.
- Shared bosses mean queues and kill-stealing at rare spawns.
- With a full shop, anything sold that helps in a lane fight is paid power over other players. That makes the fairness-line question (at the end) much sharper here.

**Build cost: large.** Timed-hit input with server checks, lane PvP with drop-and-grab rules, shared boss ownership, six gatekeeper fights, plus everything in option B.

---

## Side by side

| | A: Power Check | B: Carry It Home | C: Timed Hits, Open Lane |
|---|---|---|---|
| Fight | Automatic, 3 to 6 s | Tap duel with a dodge, 4 to 12 s | Timed hits, skill beats up to 1.5x |
| Boss gets home | Crate at base | Carried past hazards | Carried, players can take it |
| What stops you | Gates with numbers | Boss numbers, open zones | Gatekeeper fights |
| Bag | Hold | Tap with combo, hold works | Timed ring, hold works |
| Spawns | Fixed pedestals | Rolled pads, own fight | Rolled pads, shared boss |
| Losing a fight | Nothing | 2 s knockdown | 3 s stun, drop what you carry |
| Stealing | Bases only | Bases only | Bases and lane |
| Main risk | Nothing for the hands to do | Long carries late on | New players robbed constantly |
| Build cost | Small | Medium | Large |

The open points are independent. The manager can also mix: for example B's carry with A's gates, or B with C's timed bag.

## Recommendation

1. **Option B, "Carry It Home".** It is the closest reading of "bring them back to base", and it gives the lane a job in both directions.
2. It keeps stealing exactly where the manager put it (bases, with the lock), while the hazard carry teaches the carry rules before a thief does.
3. It is one step of build above A, and C's lane PvP can be added later if playtests ask for more danger; taking it out after launch would be much harder.

What only a playtest can settle: whether tapping the bag is enjoyable for more than a minute, whether the duel feels like a fight, and how long a carry can be before it turns into a chore.

---

## DRAFT: zone themes (proposal only; the art-director is drafting themes in parallel and theirs wins on look)

Three alternative sets. The order is lane order, nearest to furthest.

| # | Set 1: "Wild world" | Set 2: "Fight tour" | Set 3: "Monster lands" |
|---|---|---|---|
| 1 | Sunny Meadow | Backyard Gym | Slime Swamp |
| 2 | Scorched Desert | Street Market | Candy Kingdom |
| 3 | Deep Jungle | Jungle Dojo | Bone Canyon |
| 4 | Frozen Peaks | Ice Arena | Robot Scrapyard |
| 5 | Volcano | Lava Colosseum | Haunted Castle |
| 6 | Sky Realm | Champions' Sky Ring | Dragon Summit |

- Set 1 is the easiest to read from a distance down a lane (green, sand, dark green, white, red, gold) and the easiest to fill with creatures.
- Set 2 ties the world to the punching theme of the name; creatures become fighters (a boxing kangaroo, a sumo walrus).
- Set 3 gives the most varied creature silhouettes, at the cost of six unrelated looks.

## DRAFT: rarity tiers

Six tiers, one creature of each tier in every zone (6 x 6 = 36). The zone sets the scale; the tier sets how rare, how strong and how well paid within the zone.

| Tier | Plain names (read instantly) | Themed alternative | Power needed (x zone base) | Income (x zone base) | Spawn chance on a rolled pad (options B, C) |
|---|---|---|---|---|---|
| 1 | Common | Rookie | x1 | x1 | 45% |
| 2 | Uncommon | Contender | x1.5 | x2 | 27% |
| 3 | Rare | Brawler | x2.5 | x4 | 15% |
| 4 | Epic | Champ | x4 | x8 | 8% |
| 5 | Legendary | Titan | x6 | x20 | 4% |
| 6 | Mythic | Undisputed | x9 | x60 | 1% |

Spawn chances total 100%. These pads are earned by play only. The lucky boss spin in the shop is a different thing and falls under Roblox's paid random items policy (see Cautions).

## DRAFT: first-pass number curve

Paper only. Assumes about 2.5 punches a second, 1 Power per punch before multipliers, 10 base spots. None of this has been run in Studio; time targets are guesses to be measured in play mode once something is built.

**Zones**

| Zone | Power to enter (gate in A; the Common's Power in B and C) | Boss Power range (Common to Mythic) | Zone base income per second | Income range per boss per second | Target time to first reach it |
|---|---|---|---|---|---|
| 1 | 0 (zone base 25) | 25 to 225 | 1 | 1 to 60 | 20 to 40 seconds |
| 2 | 250 | 250 to 2,250 | 8 | 8 to 480 | 3 to 4 minutes |
| 3 | 2,500 | 2,500 to 22,500 | 60 | 60 to 3,600 | 10 to 12 minutes |
| 4 | 25,000 | 25,000 to 225,000 | 450 | 450 to 27,000 | 25 to 35 minutes |
| 5 | 250,000 | 250,000 to 2.25M | 3,500 | 3,500 to 210,000 | about 1 hour |
| 6 | 2,500,000 | 2.5M to 22.5M | 28,000 | 28,000 to 1.68M | about 2 hours |

Power steps x10 per zone; income steps about x8 per zone, so cash gets a little tighter the deeper you go and upgrades stay worth buying.

**Bag upgrades (bought with cash, reset on rebirth)**

| Bag tier | Power per punch | Cost | Power per second at 2.5 punches |
|---|---|---|---|
| 1 Starter bag | x1 | free | 2.5 |
| 2 | x4 | 150 | 10 |
| 3 | x20 | 3,000 | 50 |
| 4 | x120 | 40,000 | 300 |
| 5 | x800 | 500,000 | 2,000 |
| 6 | x6,000 | 6,000,000 | 15,000 |

**Boss upgrades**

- Income at level L = base income x (1 + 0.25 x (L - 1)).
- Cost to go from level L to L+1 = 30 x base income x 1.3^(L - 1).
- Level cap 20 (draft). The first upgrade pays itself back in 2 minutes; level 10 in about 21 minutes; the last levels in hours.
- Time to the first upgrade: the first Common earns 1 a second and its first upgrade costs 30, so about 30 seconds after placing it, around 1:15 to 1:45 into a first session.

**Rebirth**

| Rebirth | Requirement (draft) | Reward (draft) |
|---|---|---|
| 1 | 5M Power and 50M cash | +50% Power per punch, +25% boss income, +1 base spot |
| 2 | 15M Power and 250M cash | the same again, stacking |
| 3+ | Power x3 and cash x5 each time | the same again, stacking |

- Resets Power, cash and bag tier. Draft assumption: placed bosses and their levels are kept, since they are the collection. This is a question for the manager (below).
- Target for the first rebirth: 4 to 5 hours of play. Unmeasured.

**Known gaps in the draft**
- No prices or contents for the shop yet. That is the monetization sheet, written after an option is picked, since cash packs have to be sized against this curve.
- Every source has to be checked for unlimited repetition once the option is fixed (for example: fixed pedestals in option A let a player re-beat the same boss forever; what happens to duplicates and to bosses beyond 10 spots, sell for cash or store, is not designed yet).
- Steal, lock and carry-speed numbers are placeholders.

---

## Cautions (said once)

- **The lucky boss spin is a paid random item.** Roblox policy: every outcome and its odds shown before purchase, odds totalling 100%, hidden or replaced with a non-random route for restricted players. Source: `vault/patterns/paid-random-items-show-odds-before-purchase.md` (docs, checked 2026-11-11; digest `vault/roblox-docs/paid-random-items-policy.md`). The spin's outcome table gets written on the monetization sheet.
- **Stealing takes progress from players.** The vault's guidance is protection, limits or recovery for anything that can be lost, and the one recorded stealing game drew complaints about being targeted: `vault/patterns/interact-with-other-players-progress.md` (multi-source). The manager's lock shield and punch-back are that protection. Option C adds loss with no protection on the lane.
- **Stealing logic is the highest exploit risk in the game** (duplication, teleport-steals). Server authority for every pick-up, drop and placement, and a qa-exploit-reviewer pass before release. Same pattern file.

## Suggestions from the vault (optional, the manager picks)

None of these is in the options above. Each is separate from the brief.

| Suggestion | What it adds | Pattern file | Evidence | Cost |
|---|---|---|---|---|
| Prototype the bag punch and one fight in a grey room first, before the lane or bases exist | Finds out whether "Huss Huss" is fun for its own sake before 36 creatures are built around it | `vault/patterns/feel-pass-on-the-main-action-first.md`, `vault/patterns/thin-playable-slice-then-watched-playtest.md` | multi-source; docs | Small; one extra manager playtest early |
| Safe pockets along the carry home (a rest pad between zones where hazards can't reach) | A push-on-or-rest choice on long carries; applies to options B and C | `vault/patterns/tension-and-release-inside-one-trip.md` | unverified (one creator's analysis) | Small, builder only |
| Tune the first boss's first minute of income to cover the first boss upgrade and bag tier 2 | The first visit to an upgrade has something affordable | `vault/patterns/first-run-pays-for-the-first-upgrades.md` | unverified (one clip) | None; a tuning rule (the draft curve is already close) |
| Make zone 6 and a Mythic visible from spawn, with their numbers | A goal in sight from the first minute | `vault/patterns/end-the-first-session-wanting-more.md` | docs | Small, builder and gui-designer |
| Name one moment worth filming: a thief punched one step from their own base, the boss flying back | A clip that explains the game in ten seconds | `vault/patterns/design-a-moment-worth-filming.md` | docs | Small; animator-vfx time on one effect |

## Assumptions

- Bases and their bosses exist only while the owner is in the server; no offline stealing.
- Bosses earn only while the owner is online (offline earnings are not designed; adding them is a feature the manager would have to ask for).
- 10 base spots at the start, more through rebirth.
- "6 creatures each across rarity tiers" is read as one creature per tier per zone.

## Questions only the manager can answer

1. **Which loop option:** A, B, C, or a mix of the open points?
2. **Fairness line.** This is a tycoon with raids, which the playbook treats as a mixed case. May the shop sell things that work against other players (a longer lock, faster stealing, a stronger punch against thieves), or only things that speed up the buyer's own progress (Power, cash, luck)?
3. **On the lane, can another player take a boss you are carrying home,** or is stealing only at bases? (B says bases only; C says both.)
4. **Rebirth: are placed bosses kept or wiped?** The draft keeps them.
5. **Offline:** is "nothing can be stolen while you are offline" right, and should bosses earn while you are away?
