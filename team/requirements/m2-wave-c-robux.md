# M2 wave C: Robux (system 13)
Tasks: M2-18 scripter (opus), M2-19 scripter (sonnet), M2-20 gui-designer (sonnet). After wave B's policy module (M2-15).
The ids come from the main session's P8 work (`Config.Shop.IDS`); until then 0 means no call and the checks fake receipts.
Quality pass: **Function**.

## The brief
`pack/brief.md` system 13 and the build plan's "Wave C" as written: the one receipt handler, purchase ids, pass checks on join
and after purchase; the 10 passes and 9 developer products at the brief's prices; Perfect Auto Punch offered in the game only to
Auto Punch owners and working alone when bought on the web page; cash packs quoted with a key (valid 5 minutes); the Lucky Spin from
one odds table (40/28/17/10/4/1) with the zone picker read from zones beaten; Shield Breaker bought at the shield with its checks and
stored charge; `PolicyService` (random-items restricted hides the Spin card, screen and the three spin products); the Starter Pack
mark and its once-a-session offer after the first upgrade.

## Work
- M2-18 server: `Receipts`, `Passes`, `Shop`, `Spin`, `StarterPack`, quotes, `Shop.Buy` prompt guard (no prompt during a fight, carry,
  steal alert or shield-broken alert; never two), grants through `BoughtMark`. Checks `Robux`, `Spin` (100,000 rolls within
  tolerance; the screen's list read from `Shared/SpinTable`).
- M2-19 client: Shop and Spin controllers, prompt-safe state, policy flags hiding the Spin UI.
- M2-20 screens (plain): shop with 19 cards and the bought-cash well, Lucky Spin with its odds list **before any Buy or Spin button
  is active**, Starter Pack offer, the bag panel's Perfect Auto Punch row, the rebirth bought-boss line.

## Acceptance criteria
The gate's Robux, attacking-set, bought-mark and spin rows; on screen: the odds list before any button is active, at phone size.

## Not asked for (do not build)
Any price, discount, countdown, "% off", limited offer or urgent wording; a second shop; gifting; subscriptions; ads;
products or passes beyond the 19; publishing, creating the passes and products (that is the main session's P8); real sounds (M4).
