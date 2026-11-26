# M2: first session, the arrow and the 12 funnel events
Task M2-21 scripter (sonnet). Quality pass: **Function**. Depends on M2-09 (flags), M2-10, M2-11, M2-18 (Starter Pack shown).

## The brief
`pack/brief.md` "The first session": the arrow (bag, first boss, home, first spot, first upgrade; gone after `FirstBossUpgraded`),
no tutorial screens; 12 funnel events in order, once per player (saved flags): `Joined, FirstBagPunch, FirstPerfectLanded,
ReachedFirstBossPower, FirstFightStarted, FirstBossBeaten, FirstBossPlaced, FirstCashCollected, FirstBossUpgraded,
StarterPackShown, FirstStrengthBought, Zone2BossPlaced`; the Starter Pack offer shows once after the first upgrade, after the panel closes.

## Acceptance criteria
From a fresh profile a scripted player reaches `FirstBossUpgraded` and `Zone2BossPlaced`; each event fires once, in order; the arrow
is gone after the first upgrade; the offer shows once. The measured real times go to the game-designer (floor values from `m2-carryover.md`).

## Not asked for (do not build)
Tutorial screens or text, extra funnel events, analytics services, a daily reward, a quest list.
