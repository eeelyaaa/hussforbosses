# M2 contract: remotes, data, hooks and file ownership for waves A, B and C

**Status: COMPLETE (M2-01, tech-lead, 2026-11-25)**, from the producer's skeleton. The same is in code:
`Shared/Net.lua` (every remote below, created by `Net.serverInit`, each M2 entry naming its `owner` task and its
`rate`), `Shared/Ids.lua`, `Shared/Config/*` (empty skeletons; `ShopIds` holds the 19 real ids from M2-00),
`Shared/TestHooks.lua` and `team/test-hooks.md` (the list matches), `Systems/Funnel.lua` (API skeleton),
`Main.client.lua` (auto-start seam). Remote names are TEAM CALL B8 (logged as M2-01-1). Task M2-02
(qa-exploit-reviewer, opus) reviews this before waves B and C are coded; its changes come back to M2-01.
**Reviewed by M2-02 (2026-11-25, `audits/m2-02-contract-review.md`):** ten must-fix edits applied in place, each marked
`[M2-02 Mn]`; should-fix items and the code changes per task are in the audit.
Extends `m1-contract.md` (read it first; every M1 section stands except where B below changes it). Sources:
`team/pack/brief.md` systems 1 to 14, `build-plan.md` ("M2", "Remotes, by family", "Data schema outline and save
rules", "Test hooks", "`PolicyService` checks", "The burst timing contract"), `m2-carryover.md` (the manager's P1 to
P9), `m2-punch-numbers.md` (M2-03). Autonomous mode: nobody asks the manager; the ladder is in
`vault/playbooks/autonomous-build.md`. Every M2 brief quotes the section it builds to and ends with "Not asked for".

## A. Who owns what (no two tasks that run together share a file)
A task that needs a change in a file it does not own writes the request in its report; the owner changes it in a
later batch. Config children were created empty by M2-01 and now belong to the task named. New modules in
`Controllers/` or `Ui/` start themselves (`AUTO_START = true` and `start(ctx)`, the seam in `Main.client.lua`), so
nobody but the owner below edits `Main.client.lua`. New `Systems/*` start themselves (Main.server's name-order loop).

| Task | Owns |
|---|---|
| M2-00 main session | `Config/ShopIds.lua` (the 19 real ids, pasted by M2-01 from `assets.md` on 2026-11-25; read as `Config.Shop.IDS`), `team/assets.md` rows for them |
| M2-01 tech-lead | `requirements/m2-contract.md`, `Shared/Net.lua`, `Shared/Ids.lua`, `Shared/TestHooks.lua`, `team/test-hooks.md`, `docs/controls.md`, `Config/init.lua`, `Main.server.lua` |
| M2-02 qa-exploit-reviewer | `audits/m2-02-contract-review.md` |
| M2-03 game-designer | `requirements/m2-punch-numbers.md` (done) |
| M2-04 builder | `assets-src/stud/*`, `studio/SetupStud.lua`, `studio/checks/StudDistance.lua`, the `Tokens.stud` block of both skins' `Tokens.lua` |
| M2-05 gui-designer | `Ui/WorldLabel.lua`, `tools/check_labels.py`, and only the BillboardGui lines of `Controllers/Pads.lua`, `Base.lua`, `Carry.lua`, `Ui/Prompts.lua` (batch 1; done before any later task touches those files) |
| M2-06 scripter | `Systems/Punch.lua`, `Systems/Fight.lua`, `Config/Punch.lua`, `Config/Fight.lua` (its `CAMERA` block is dead once `Config/FightCamera` sets one; leave it), `studio/checks/Punch2.lua` |
| M2-07 scripter | `Controllers/Ring.lua`, `BurstClock.lua`, `Input.lua`, `Fight.lua` (client), `TestClient.lua` (AutoTap `untimed`, `mash`), `Main.client.lua` (the Huss routing and `Profile.Changed` block), `Config/FightCamera.lua`, `studio/checks/FightAngle.lua`. Adds the Input actions `shop`, `rebirth`, `settings`, `shield`, `sell`, `run`, `menu` (`Input.on(action, fn)`) that later screens subscribe to |
| M2-08 gui-designer | `Ui/HussButton.lua`, `Ui/FightOverlay.lua` |
| M2-09 data-engineer | `Data/*` (`Session` = the facade, plus `Store`, `Schema`, `Migrations`, `Transfer`, `Purchases`), `Config/Data.lua`, `studio/checks/Saving.lua`, `studio/checks/SkinCheck3.lua`; the server handler of `Profile.Settings` |
| M2-10 scripter | `Systems/Bag.lua`, `AutoPunch.lua`, `Zones.lua`, `Config/Bag.lua`, `AutoPunch.lua`, `Zones.lua`, `Shared/Patrol.lua`, checks `Bag.lua`, `Zones.lua` |
| M2-11 scripter | `Systems/Hazards.lua`, `Carry.lua`, `Base.lua`, `Income.lua`, `Upgrades.lua`, `Shared/Hazards.lua`, `Config/Hazards.lua`, `Carry.lua`, `Base.lua`, `Income.lua`, `Upgrades.lua`, checks `Hazards.lua`, `Base.lua`, `Upgrades.lua` |
| M2-12 scripter | `Controllers/Pads.lua`, `Base.lua`, `Carry.lua`, `Hazards.lua`, `BossVisuals.lua` (after M2-05) |
| M2-13 gui-designer | `Ui/BossPanel.lua`, `BagPanel.lua`, `Offline.lua`, `Rebirth.lua`, `Settings.lua`, `Toasts.lua`, `Hud.lua`, `Counters.lua` |
| M2-14 scripter | `Systems/Offline.lua`, `Rebirth.lua`, `BoughtMark.lua`, `Config/Offline.lua`, `Rebirth.lua`, checks `Offline.lua`, `Rebirth.lua` |
| M2-15 scripter | `Systems/Plots.lua`, `Steal.lua`, `Shield.lua`, `Policy.lua`, `Config/Steal.lua`, `Shield.lua`, `Policy.lua`, checks `Steal.lua`, `Shield.lua`, `Policy.lua` |
| M2-16 scripter | `Controllers/Steal.lua`, `Shield.lua`, `Watchers.lua`; `Main.client.lua` thief mode of the Huss routing (after M2-07); calls `Avatar.playClip` (no edit of `Avatar.lua`) |
| M2-17 gui-designer | `Ui/StealAlert.lua`, `LockBoard.lua`, `Confirm.lua`, `Prompts.lua` (kinds only, after M2-05) |
| M2-18 scripter | `Systems/Shop.lua`, `Receipts.lua` (the one `ProcessReceipt`), `Passes.lua`, `Spin.lua`, `StarterPack.lua`, `Config/Shop.lua` (never `IDS`), `Spin.lua`, `Shared/SpinTable.lua`, checks `Robux.lua`, `Spin.lua` |
| M2-19 scripter | `Controllers/Shop.lua`, `Spin.lua` |
| M2-20 gui-designer | `Ui/Shop.lua`, `Spin.lua`, `StarterOffer.lua`, the Perfect Auto Punch row of `Ui/BagPanel.lua` (after M2-13) |
| M2-21 scripter | `Systems/Funnel.lua` (skeleton by M2-01), `Controllers/Arrow.lua`, `Config/Funnel.lua`, `TestClient.lua` (AutoPlayer, after M2-07), check `FirstSession.lua` (replaces M1's) |
| M2-22 animator-vfx | `Shared/Moves/*` (tailed, swayer, biped sets and the `sig/*`), `studio/checks/MovesM2.lua` |
| M2-23 animator-vfx | `Controllers/Avatar.lua` (clips; exposes `Avatar.playClip(name)` for flinch, carryHold, stealLift, knockdown, stun), `studio/BuildClips.lua`, `tools/blender/clips/*` |
| M2-ART, M2-25 modeler-3d | `tools/blender/bosses/*`, `make_m2_bosses.py`, `render_*.py`, `assets-src/models/z*_t*`, `studio/data/z*_t*.groups.lua`; M2-25 adds `studio/checks/BodyTypeFit.lua` |
| M2-24, M2-26, M2-27 | their `verification/` or `audits/` file only; M2-26 also `requirements/m2-curves.md` |
| M2-28 scripter | `studio/checks/CheckAll.lua`, `studio/checks/Gate.lua`, `studio/checks/CheckLib.lua` |

**Batch check (M2-01, against `build-state.md`).** Batch 1 (M2-01, M2-03, M2-04, M2-05, M2-29, M2-ART): no shared
file. Batch 2 (M2-02, M2-06, M2-07, M2-08, M2-13, M2-23): the skeleton had M2-06 and M2-07 both in
`Config/Fight.lua`; fixed by `Config/FightCamera.lua` (TEAM CALL M2-01-4). `Main.client.lua` and `TestClient.lua`
were unowned; now M2-07 in batch 2, then M2-16 / M2-21 later. `Avatar.lua` was shared by M2-16 and M2-23; now M2-23
only. `Config.Shop.IDS` was shared by M2-00 and M2-18; now `Config/ShopIds.lua` (TEAM CALL M2-01-5). `Data/Receipts`
and `Systems/Receipts` were two modules with one name: the data one is now `Data/Purchases`. The producer keeps
later batches to this table.

## B. What changes in the M1 contract (the manager's P3, P2, P4; manager's words win; numbers: `m2-punch-numbers.md`)
1. **`Punch.Report.grade`** is `"perfect" | "good" | "untimed" | "miss"` (`Ids.REPORT_GRADES`; `Ids.GRADES` stays the
   burst grades until M2-06 switches the check). `untimed` = a tap anywhere in the ring from `RING_GRACE_S` (0.15 s)
   after it opens up to the Good window's early edge (`EARLY_TAP_S` no longer gates grading). `miss` = the ring
   passed with no tap (in a fight a heart and the boss's attack; on the bag nothing). `auto: boolean?` (C, Bag).
2. **Untimed tap = one punch** (P3: "if they just click it just does 1 on the punching bag and depends on strength
   level on fighting bosses"). Bag: Power += `STRENGTH_VALUE(level) x GRADE_VALUE.untimed (1) x rebirth mult x pass
   mult`, no `BIG_MULT`. Fight: damage = the player's Power x 1. No F, no pips; the single huss (02 A / 01 A),
   `gains = { value }`, applied at accept time. **One report per ring** (TEAM CALLs M2-P1, M2-03-3): an untimed tap
   spends the ring (drawn dimmed; later taps in it, timed ones too, are ignored by the client); the next ring opens at
   the scheduled landing + `MISS_RESTART` (0.61 s).
3. **Hearts (PROVISIONAL, manager-todo Q1, TEAM CALL M2-03-6 over M2-P2):** an untimed tap costs no heart in bands
   Easy and Fair, one heart from Hard up (`Config.Fight.UNTIMED_HEART_FROM = "hard"`). A ring with no tap is a Miss.
4. **Timed = burst** unchanged (0, 0.213, 0.401; Good 1+1+2, Perfect 2+2+4); PERFECT floats above the Huss button
   (M2-08); a Good keeps its small pop.
5. **Server rate rules (replace the skeleton's B4; TEAM CALL M2-03-4):** at most one accepted report per ring
   (`untimedBusy` for a second untimed in a ring); an **untimed** report needs `UNTIMED_MIN_GAP_S` (0.66 s) since the
   last accepted report of any grade; a **timed** report needs `CYCLE x RATE_TOLERANCE` (0.75) since the last
   accepted timed report and 0.66 s since any; **an untimed report right after an accepted untimed one needs
   `UNTIMED_MIN_GAP_S` + the context's Good window** (bag 0.66 + 0.13 = 0.79 s; a fight its band's Good; TEAM CALL
   M2-06-1, M2-02 S7), else `untimedBusy`; an untimed report never starts `BURST_LEN` and is refused `busy` while a
   burst runs. `RATE["Punch.Report"]` stays 4/s. Cheat ceiling about 1.5x flawless play (M2-27 re-checks).
6. **P2 values:** `RING` = 1.05 0.98 0.91 0.84 0.77 0.70 0.63 0.56 0.48 0.41; bag windows 130 / 55 ms; bands 150/65,
   130/55, 100/40, 80/30, 65/24, 55/20 (Good / Perfect). Structure unchanged.
7. **P4:** `Config/FightCamera.lua` `CAMERA` (same keys as M1's `Fight.CAMERA`): avatar smaller and nearer
   centre-left, boss in the right two thirds, both fully in frame at 874 x 402 and 640 x 300 (M2-07 measures, the
   art-director looks).
8. `Punch.Result.reason` gains `untimedBusy` and `pass` (auto without the pass or the toggle); `Fight.Beat.size`
   gains `single`; `Fight.State` (started) gains `bossPos` (where the patrol froze the boss, E).

## C. Remotes (all in `Shared/Net.lua`; the code is the exact payload, this table is the rule)
**Every c2s handler, in this order:** `Net.onServerEvent` (rate per `Net.rateFor`, table payload) then each field's
type with `Net.isNumber/isInt/isOneOf/isShortString` (NaN and infinity first; strings <= 40 bytes and valid UTF-8;
booleans `typeof == "boolean"`; a table field only where listed; unknown keys ignored), then state, place, distance,
the per-action cooldown, then one mutate. **No yield between the first state check and the mutate** (M2-02 S5): a
handler that needs a yielding answer (pass ownership, policy) reads the cached one (`Passes.owns`, `Policy.get`,
filled on join and after a purchase), never calls `UserOwnsGamePassAsync` or another `...Async` inside the handler. Over the rate: dropped silently and counted in `TestHooks.reports._dropped`.
A refusal answers with the family's `Result` (or `Punch.Result`, `Steal.Result`, `Shop.Grant`) and a reason from the
list in `Net.lua`; refusals never carry server text. **No c2s remote carries a price, an amount, a level, a cost, a
bought mark, bought cash, a zone beaten or a user id, except `Steal.OwnerPunch.thiefUserId` (checked against the
carrier of the caller's boss).** Ids that are carried (`padId`, `uid`, `plotId`, `spotIndex`, `key`, `zone`) are
looked up in server state; one that is not the caller's to act on is refused. Rates are calls per second per player.
Sending helpers: `Net.fire`, `Net.fireAll`, `Net.fireNear(pos, radius, except)`. Unreliable payloads < 900 bytes.
`Profile.TestReport` is `studioOnly`: `Net.serverInit` does not create it on a live server (M2-02 N3).

| Remote | Dir | Server validation (beyond the shape) | Rate | Owner |
|---|---|---|---|---|
| `Punch.Report` | c2s | B1 to B5; `auto` as in Bag below | 4 | M2-06 (auto: M2-10) |
| `Punch.Result` / `Punch.Burst` | s2c owner / unrel. 150 studs, not owner | Burst also for untimed (grade `untimed`) | | M2-06 |
| `Fight.Start` | c2s | M1 rule, but "in the ring" is against `Zones.bossPosition(padId, Zones.now())` (E) with `RingRadius + RING_SLACK + PATROL.slack (1.5)` | 2 | M2-06 |
| `Fight.Run`, `State`, `Beat`, `Heart` | as M1 | `State.bossPos`, `Beat.size = 'single'` | 2 (Run) | M2-06 |
| `Fight.Watch` | unrel. 150 studs, not the fighter | at most one per 0.3 s per boss | | M2-06 sends, M2-16 plays |
| `Bag.BuyStrength` / `BuySpeed` | c2s `{}` | own plot, within `Config.Bag.PAD_RANGE` (14) of own bag pad, level < 30 / 10, cash >= `Config.Bag` cost; funnel `FirstStrengthBought` | 5 | M2-10 |
| `Bag.AutoToggle` / `PerfectToggle` | c2s `{ on }` | pass owned (`pass_auto_punch`; Perfect: `pass_perfect_auto_punch`, works alone for a web-page buyer); per session, off on join | 2 | M2-10 |
| `Bag.State`, `Bag.Result` | s2c owner | costs are the server's (nil at the cap) | | M2-10 |
| `Punch.Report` with `auto` | c2s | grade only `good` (`perfect` needs Perfect Auto Punch owned and on), the toggle on, owner on own bag pad, never in a fight, one auto burst per ring; a hand tap replaces it only if better and before the auto burst started (B20) | 4 | M2-10 |
| `Zones.Pads` / `PadBeaten` / `Clock` | s2c | per player (rolls, `beaten`); `patrol = { phase, halfLen, speed, pauseS }` (E) | | M2-10 |
| `Base.Place` | c2s `{ spotIndex }` | M1, plus spot unlocked (`spotsCap`); funnel `FirstBossPlaced`, `Zone2BossPlaced` (zone 2 creature) | 4 | M2-11 |
| `Base.PickUp` | c2s `{ spotIndex }` | own plot, boss there, within `PLACE_RANGE`, not carrying, no hold or carry-off on it (`[M2-02 M5]` `Steal.isLocked(uid)`, refused `locked`); pad cash stays | 4 | M2-11 |
| `Base.Swap` | c2s `{ spotIndex }` | carrying, spot occupied, own plot, in range, the placed boss not held or carried off (`[M2-02 M5]`, refused `locked`); placed boss sold at server value, carried one placed; one mutate | 4 | M2-11 |
| `Base.Sell` | c2s `{}` | carrying, inside own plot; value = 20 x income/s at its level (server) | 2 | M2-11 |
| `Base.TakeCrate` | c2s `{ uid }` | uid in the caller's crate, not carrying, inside own plot; the boss goes on the head (`Carry.State`); spots full: refused `full` + `Profile.Notice spotsFull` / `spotsFullOffer` | 4 | M2-11 |
| `Base.State` (all), `Base.Crate` (owner), `Base.Collected`, `Base.Result` | s2c | `State` per plot on change; funnel `FirstCashCollected` on the first `Collected` > 0 | | M2-11 |
| `Boss.Upgrade` | c2s `{ uid }` | uid on one of the caller's spots, within `PLACE_RANGE`, level < 20, cash >= server cost, not held or carried off (`[M2-02 M5]`, refused `locked`); funnel `FirstBossUpgraded` | 5 | M2-11 |
| `Boss.Result` | s2c owner | | | M2-11 |
| `Carry.State` / `Carry.Grab` | as M1 | `State` gains `level`, `bought`, `stolenFrom`, `speed` (12 / 16 Fast Carry; over-speed drops, B Steal). `[M2-02 M8]` the server keeps each carry's `origin` (`fight`, `crate`, `spot`, `stolen`); only a `fight` carry can vanish at `graceEnds`; Grab is refused for a `stolen` carry (it never enters `dropped`, see C2) | 4 (Grab) | M2-11 |
| `Steal.HoldStart` | c2s `{ plotId, uid }` | another player's plot, owner in the server, shield not up, boss placed there, not safe-timed (60 s), caller within `HOLD_RANGE` (6), not carrying, no fight, not policy-locked (H); hold `HOLD_S` 2.0 / 1.0 Quick Hands; moving away > `HOLD_RANGE` + 1 or an owner punch cancels | 2 | M2-15 |
| `Steal.HoldCancel` | c2s `{}` | only the caller's own hold | 4 | M2-15 |
| `Steal.OwnerPunch` | c2s `{ thiefUserId }` | the caller owns the boss that user carries (`stolenFrom` = caller's plot), within 8 studs, >= 0.8 s since the caller's last; Iron Grip: first hit staggers 0.5 s, a second within 10 s drops | 3 | M2-15 |
| `Steal.Alert` (owner), `Result` (both), `Flag` (each non-owner), `Punch` (unrel. 150 studs) | s2c | `Flag` per viewer per bought boss; `Result.reason` list in `Net.lua` | | M2-15 |
| `Shield.Raise` | c2s `{}` | inside own plot, state `ready` (the lock pad raises server-side by touch, no remote) | 2 | M2-15 |
| `Shield.UseCharge` | c2s `{ plotId }` | not own plot, within `BREAK_RANGE` (15) of that shield, breakable (not `joining`, not `instant`, not broken in the last 300 s), `breakerCharges >= 1`; one mutate then the break | 1 | M2-15 |
| `Shield.BuyBreaker` | c2s `{ plotId }` | same checks without the charge, plus the Shop prompt guard; server opens the product prompt and keeps `{ plotId, at }` for the receipt | 1 | M2-15 (prompt via M2-18's `Shop.prompt`) |
| `Shield.State` (all), `Broken` (owner), `Result` (caller) | s2c | `brokenUntil` drives the "Broken recently, 3:20" grey | | M2-15 |
| `Rebirth.Request` | c2s `{ confirmed = true }` | `confirmed == true` exactly; Power >= the table; rebirths < 10; not carrying, no fight, none of the player's bosses held or carried by a thief; one per `COOLDOWN_S` (5); one save op | 1 | M2-14 |
| `Rebirth.Result` | s2c owner | | | M2-14 |
| `Shop.Open` | c2s `{}` | replies `Shop.Quotes` and `Shop.State` (RemoteEvent, not a RemoteFunction: TEAM CALL M2-01-2) | 2 | M2-18 |
| `Shop.Buy` | c2s `{ key, quoteKey? }` | key in `Ids.SHOP_KEYS`; pass not owned; spin products refused if restricted; `pass_perfect_auto_punch` only with Auto Punch owned; `product_shield_breaker` refused here (`Shield.BuyBreaker`); `product_instant_shield` refused while a shield is up (`shieldUp`); a cash pack needs the live `quoteKey` (else `stale` + new Quotes); **no prompt during a fight, a carry, a steal alert or a shield-broken alert, never two open** (`promptOpen` per player until `PromptProductPurchaseFinished` / `PromptGamePassPurchaseFinished`); the server prompts | 1 | M2-18 |
| `Shop.Spin` | c2s `{ zone }` | `Net.isInt(zone, 1, 6)` and on the saved `zonesBeaten`; `spinTickets >= 1`; not restricted; ticket -1 and the boss to the crate with `bought = { source = "spin", buyer }` in one mutate (through `BoughtMark`) | 1 | M2-18 |
| `Shop.OfferSeen` | c2s `{ key }` | key `pass_starter_pack`, an offer was sent this session, once; funnel `StarterPackShown` | 1 | M2-18 |
| `Shop.Quotes`, `State`, `Grant`, `SpinResult`, `Offer` | s2c owner | no client value is read back; `State.policy` is what the client hides by | | M2-18 |
| `Offline.Summary` / `Offline.Collect` / `Offline.Result` | s2c / c2s `{}` / s2c | summary only if away >= 60 s and earned > 0; collect once. `[M2-02 M9]` the offline amount IS the pads' stamp fill, not new money: Collect, in one mutate, settles each listed pad (`padCash = min(padCash + income x (now - padStamp), cap)`, `padStamp = now`) and moves `min(perBoss[uid], padCash)` from that pad to cash with `addCash`; a boss no longer on its spot (sold, picked up, stolen, rebirth) pays 0. The summary never pays on top of the pads | 1 | M2-14 |
| `Profile.Settings` | c2s `{ music, effects }` | each `Net.isNumber(x, 0, 1)`, rounded to 0.05; one mutate | 2 | M2-09 |
| `Profile.Changed` | s2c owner | all fields once on join, then changed ones; names = schema keys (D) | | M2-09 (+ each system via `Session`) |
| `Profile.Notice` | s2c owner | `kind` from `Ids.NOTICES` | | any system |

Purchases are not remotes: `MarketplaceService.ProcessReceipt` (one handler, `Systems/Receipts`) and
`PromptGamePassPurchaseFinished`, server only. A pass is checked with `UserOwnsGamePassAsync` on join (pcall; a
failure = not owned, retried on the next purchase event), after a purchase, and through the `PassOwned` hook.
**The 19 real ids are in (`Config/ShopIds.lua`, M2-00).** A key whose id is 0 still means no Roblox call
(`Shop.Buy` answers `Grant { ok = false, reason = "unknown" }`). Scripted checks never complete a real purchase:
they grant through `FakeReceipt` and `PassOwned` (Studio prompts are test purchases, but a check must not depend
on a dialog nobody clicks).

**`[M2-02 M3]` Receipt rules (M2-18 with M2-09's `recordPurchase`).**
- `ProcessReceipt` returns `NotProcessedYet` (and grants nothing) when the player is not in this server, the profile is
  still loading, it is a temp profile (`saving = false`: nothing it grants could be saved), or the leave or shutdown path
  for that player has begun. Roblox redelivers on the next join.
- A grant is a pure operation on a profile table. `recordPurchase` applies it to the record inside the one
  `UpdateAsync` (with the purchase id), and only after that write succeeds applies the same operation to the live
  profile. No "undo in memory": the live profile is never changed before the write. Anything outside the profile
  (raising an Instant Shield, breaking a shield, `Shop.Grant`, toasts, `Base.State`) happens only after the write.
- A receipt never depends on a prompt the server opened: a client can call `PromptProductPurchase` itself, from any
  state. The amount is decided by: a cash pack prompted through `Shop.Buy` grants the amount held with that prompt
  (fixed when the server prompted, so the shown offer is the granted offer even if the quote expired while the dialog
  was open); a cash pack with no held prompt grants the formula amount at receipt time; spins grant tickets
  (restricted: tickets kept, M2-01-8); Instant Shield as brief 10; Shield Breaker uses the held
  `{ plotId, ownerUserId, at }` only if that plot still has that owner and is breakable now, else one stored charge.
- `[M2-02 M4]` Passes: `PromptGamePassPurchaseFinished(true)` is a hint, never the proof. The pass counts as owned only
  after `UserOwnsGamePassAsync` returns true (retry up to 3 times over about 10 s; the `PassOwned` hook in Studio). The
  Starter Pack's contents ($5,000 with `addCash(.., true)`, the Ram to the crate through `BoughtMark`,
  `starterPackGiven = true`) are granted once, in one mutate followed by `Session.save`, whenever the pass is owned and
  `starterPackGiven` is false: after a confirmed purchase, and on join for a web-page buyer. Never into a temp profile.

## C2. `[M2-02 M5, M7]` Steal and carry state rules (M2-15, M2-11)
- **One lock per uid.** From an accepted `Steal.HoldStart` until the boss is back on its spot or the transfer is done,
  the server holds `held` then `carriedOff` for that uid (`Steal.isLocked(uid)`). While locked, the owner's `Base.PickUp`,
  `Base.Swap` (as the placed boss), `Boss.Upgrade`, `Base.Place` onto that spot and `Rebirth.Request` are refused
  `locked`; a second `HoldStart` on it is refused `state`. The boss stays in the owner's `bosses` at its spot until
  success (it is the owner's, D "Not saved"); `Base.State` may draw the spot as empty, but the spot is not free.
- **The hold is timed by the server.** Completion = the server's own timer (receipt time + `HOLD_S`), sampled each
  Heartbeat for range (`HOLD_RANGE + 1`), the shield, an owner punch and the owner leaving. The client sends no "done".
- **A stolen carry never enters `dropped`.** A hit (or the second Iron Grip hit), a hazard, a fall, a reset, the shield,
  an over-speed or teleport, or either player leaving returns the boss to its spot at once; `Carry.Grab` is refused.
- **Success re-checks in the same step:** the uid is still in the owner's profile at that spot and locked to this
  thief, the thief is inside their own plot, and the minimum travel time has passed (below); then `Session.transfer`.
- **Movement is checked on the server** (characters are client-owned: a client can set its own speed or teleport).
  For every carry (fight, crate, spot, stolen) and the owner's chase, sample the HumanoidRootPart each Heartbeat:
  a single step longer than `speed x dt x 2 + 4` studs is a teleport, and the distance over any 1 s window may not
  exceed `speed x 1.25 + 2` studs (vertical falls excluded, they are a fall). A stolen carry that breaks either rule
  returns the boss (`Steal.Result` reason `speed`); a fight carry drops it as M1. And a steal can succeed no sooner
  than `0.8 x (straight-line distance from the spot to the thief's plot entrance) / speed` seconds after the lift.
  Tolerances are `Config.Steal` / `Config.Carry` numbers; M2-27 tries a teleport home and a speed hack in Studio.

## D. Data (M2-09 builds; `roblox-data` skill; one record per player)
**Schema v1** (the runtime profile is this record minus `lock`; field names are used as written by every task):

| Key | Type, default | Rule |
|---|---|---|
| `version` | int, 1 | migrations `Migrations[n]` (n -> n+1) run in order on load; a test bumps to v2 (one new field, one renamed key). `[M2-02 M10]` a record whose `version` is higher than this code knows is never loaded into a session and never written: the player gets the temp profile (`notSaving`) so an old server during an update cannot drop the new fields |
| `power`, `cash` | number >= 0, 0 | finite; `cash` changes only through `Session.addCash / spendCash` (below). `[M2-02 M1]` the M1 `Session.set(player, "cash", v)` keeps working by routing the difference through `addCash` / `spendCash` |
| `boughtCash` | number >= 0, 0 | + every cash pack and the Starter Pack's 5,000; `spendCash` lowers it to `cash` when `cash` falls below; never written by a remote. `[M2-02 M1]` invariant checked by `Session.mutate` after every change: `boughtCash = min(boughtCash, cash)` |
| `strengthLevel` 1..30, `speedLevel` 1..10, `rebirths` 0..10 | int, 1 / 1 / 0 | |
| `bosses` | array of `{ uid, creatureId, level, spot, padCash, padStamp, bought? }` | `spot` 1..17 unique; `padStamp` server time the pad's cash was last settled; `bought = { source = "spin"\|"pack", buyer = userId }` or absent |
| `crate` | array of `{ uid, creatureId, level, bought? }` | no size limit (brief 7) |
| `zonesBeaten` | array of zone ints, `{}` | added only on a fight win (`Session.addZoneBeaten`), kept by rebirth |
| `spinTickets`, `breakerCharges` | int >= 0, 0 | kept by rebirth |
| `starterPackGiven` | boolean, false | |
| `purchases` | array of purchase id strings, last `PURCHASES_KEPT` (200) | B9 |
| `transferNote` | array of `{ uid, to }`, last 20 | a load drops a uid noted as left |
| `nextUid` | int, 1 | uid = `("%d-%d"):format(userId, nextUid)`, then +1 (TEAM CALL M2-01-6): unique for ever, even after the boss moves |
| `leftAt`, `shieldReadyAt` | server time or 0 | |
| `flags` | map `name -> true` | the 12 funnel names and `arrowDone` |
| `settings` | `{ music = 1, effects = 1 }` | 0..1 in steps of 0.05 (default full: the mix itself is M4's, TEAM CALL M2-01-7) |
| `lock` | `{ server = JobId, stamp = os.time() }` | inside the record; not in the runtime profile |

Not saved: carried bosses (a beaten boss is not owned until placed; a stolen one stays the owner's until the steal
succeeds), the plot, shields' up time, the 60 s safe time, the 5-minute break timer, rolls, toggles.
`[M2-02 M8]` "Carried" means carried from a fight only. A boss taken from the crate stays in `crate`, and a boss
picked up from a spot stays in `bosses` (spot cleared only when it is placed elsewhere, swapped or sold), until the
one mutate that places, swaps or sells it. If that carry ends any other way (hazard, grace expiry, leave, shutdown,
rebirth) the boss is still where the profile has it: a crate boss stays in the crate, a picked-up boss goes back to
its spot (or the crate if the spot was taken). An owned boss, bought or earned, never vanishes.

**`[M2-02 M1]` Protected fields.** `boughtCash`, any boss's `bought`, `zonesBeaten`, `purchases`, `nextUid`,
`transferNote`, `starterPackGiven`, `lock` and `version` are written only by the API that owns them (`addCash(.., true)`
and `spendCash`, `BoughtMark`, `addZoneBeaten`, `recordPurchase`, `newUid`, `transfer`, the Starter Pack grant, the
store). `Session.mutate` snapshots them before `fn` and returns false with nothing applied if `fn` changed one; the
owning APIs pass an internal flag. `Session.set` refuses these keys.

**`[M2-02 M2]` Rebirth, every key** (M2-14; `Config.Rebirth.RESET` / `KEPT` hold these lists and a check asserts that
together they name every schema key exactly once):
| Reset | Kept |
|---|---|
| `power` 0; `cash = min(cash, boughtCash)`; `strengthLevel` 1, `speedLevel` 1; `bosses` and `crate`: every boss whose `bought.buyer ~= userId` removed, the rest re-placed lowest spot first at their level with `padCash` 0 and `padStamp` now, overflow to the crate; `shieldReadyAt` 0 | `version`, `rebirths` (+1), `boughtCash`, `zonesBeaten`, `spinTickets`, `breakerCharges`, `starterPackGiven`, `purchases`, `transferNote`, `nextUid` (never reset: uids must stay unique), `leftAt`, `flags`, `settings`, `lock` |

**API (`Data/Session`, the M1 facade; M1 calls `get`, `set`, `onChanged`, `onJoin`, `plot`, `wipe` keep working).**
Callers written before M2-09 lands may use only these names:
- `Session.get(player) -> Profile?` never yields; read-only by convention.
- `Session.mutate(player, fn: (Profile) -> ()) -> boolean` sync, validates the result (finite numbers, ints in range),
  marks dirty, sends `Profile.Changed` for public fields that changed; false (and nothing applied) if `fn` errors.
- `Session.addCash(player, n, bought: boolean?)`, `Session.spendCash(player, n) -> boolean` (the bought-cash rule).
- `Session.addZoneBeaten(player, zone)`, `Session.newUid(player) -> string`.
- `Session.save(player, reason) -> (boolean, string?)` yields: one `UpdateAsync` that checks and renews the lock.
- `Session.transfer(uid, fromPlayer, toPlayer, place: (Profile) -> ()) -> boolean` (the steal, below).
- `Session.recordPurchase(player, purchaseId, grant: (Profile) -> ()) -> "granted"|"already"|"retry"`.
- `Session.isSaving(player) -> boolean`; `Session.onLeaving(fn(player))` runs before the final save (thief returns).
- Autosave every `AUTOSAVE_S` (60, B9); lock lease `LOCK_LEASE_S` (300) of stamp age; a foreign live lock refuses
  the load (retry 3 times over 15 s, then a temp profile, `Profile.Notice notSaving`); a load error never writes over
  a record. `BindToClose` saves all within 25 s. Store name includes `Config.Env`; key `player_<UserId>`.
- **Transfer (steal):** in memory in one step keyed by uid (removed from the owner, `transferNote { uid, to }` added
  to the owner, placed for the thief); then the owner's record is written first, the thief's second; hook
  `SaveFailBetween` errors between them and the uid must still be in exactly one profile after both reload.
  `[M2-02 M6]` Until the owner's write (the one with the `transferNote`) has succeeded, the thief's profile marks the
  uid `pendingFrom = ownerUserId` and every thief save (autosave, leave, shutdown) writes the record without that uid;
  the owner's write is retried by the owner's autosave and final save. Once it succeeds the mark is cleared and the
  thief's next write includes the boss. So a crash can at worst leave the boss with its owner, never in two records.
  A uid placed into a profile by any path removes that profile's own `transferNote` entry for the uid, so a boss
  stolen back is not dropped by its old note on the next load.
- **Receipts:** `recordPurchase` grants and records the id in one write; a handled id returns `PurchaseGranted`
  without granting; a failed write returns `NotProcessedYet` and the live profile was never changed (`[M2-02 M3]`: the
  grant is applied to the live profile only after the write succeeds; temp, loading or leaving profiles return
  `"retry"` at once, see C "Receipt rules").
- **The bought mark and `boughtCash`** are written only through `Systems/BoughtMark.lua` (M2-14; called by Spin and
  StarterPack) and `addCash(.., true)`. No remote reads them back. Content is saved by id only, never a name.

## E. Shared clocks and patrol (P5; TEAM CALL M2-P4)
`Shared/Patrol.lua` (M2-10), pure, the same on both sides:
`Patrol.position(anchor: CFrame, patrol: { phase, halfLen, speed, pauseS }, serverTime) -> (Vector3, Vector3)`
(position, facing). Ping-pong along `anchor.RightVector` through `anchor.Position`: leg = 2 x halfLen / speed,
period T = 2 x (leg + pauseS), `t = (serverTime + phase) % T`; `[0, leg)` from -halfLen to +halfLen, then a pause at
+halfLen facing `anchor.LookVector`, then back, then a pause at -halfLen. Facing = the travel direction.
`phase` = `(h % 1000) / 1000 x T`, `h` = djb2 of the pad id (`h = 5381; h = (h x 33 + byte) % 16777216`), computed by
the server and sent in `Zones.Pads`. Stand-ins (`Config.Zones.PATROL`): `halfLen` 14, `speed` 4, `pauseS` 1.0,
`slack` 1.5. The real region paths are M3 (builder). Server: `Systems/Zones.bossPosition(padId, serverTime) ->
Vector3?` and `Zones.now()` (server time + `ClockOffset`); `Systems/Fight` uses `bossPosition` when present, else the
pad anchor (so M2-06 can land before M2-10). A fight freezes the boss for the fighter at `Fight.State.bossPos`;
other players still see it patrol (TEAM CALL M2-10).

## F. Funnel events (server; names fixed by the brief, in order; `Ids.FUNNEL`)
API: `Systems/Funnel.mark(player, name)` (skeleton now: in memory, logs, `TestHooks.reports.funnel`; M2-21 adds the
saved `flags`). Each once per player, logged `[HFB][funnel] <name> <userId> t=<seconds since this join>`. Who marks:
| Event | When | Marked by |
|---|---|---|
| `Joined` | the first load of a profile without the flag | M2-21 (Funnel on `Session.onJoin`) |
| `FirstBagPunch` | first accepted bag punch, timed or untimed (P3), not auto | M2-06 |
| `FirstPerfectLanded` | first accepted hand `perfect`, bag or fight | M2-06 |
| `ReachedFirstBossPower` | Power >= the zone 1 fixed pad's boss Power | M2-10 |
| `FirstFightStarted` / `FirstBossBeaten` | first `Fight.State` started / win | M2-06 |
| `FirstBossPlaced` / `Zone2BossPlaced` | first accepted place / of a zone 2 creature (`Ids.parseCreature`) | M2-11 |
| `FirstCashCollected` | first `Base.Collected` > 0 | M2-11 |
| `FirstBossUpgraded` | first accepted `Boss.Upgrade` | M2-11 |
| `StarterPackShown` | the accepted `Shop.OfferSeen` | M2-18 |
| `FirstStrengthBought` | first accepted `Bag.BuyStrength` | M2-10 |

## G. Test hooks added at M2 (in `TestHooks.HOOKS` and `team/test-hooks.md`; the honouring task is listed there)
State: `SetBoughtCash, SetRebirths, SetZonesBeaten ("1,2,3"), SetTickets, SetCharges, ForceRoll ("<padId>=<creatureId>"),
LeaveAt (seconds), ForceSave, Leave, Rejoin, Shutdown, FakeReceipt ("<shopKey>[,purchaseId]"), Steal2 ("<seam
command>")`; `GrantBoss` extended (`"<creatureId>,to=crate|head|<spot>,level=n,bought=spin|pack,buyer=<userId>,uid=..."`).
Config: `PadsFast, SaveFailBetween, PassOwned ("<key>=on|off,..."), PolicyRandom, PolicyTrading ("on|off|fail" or
"<userId>:off,..."), SpinSeed, ShieldClock`. Client: `AutoPlayer ("perfect|good|mix|untimed")`; `AutoTap` gains
`untimed` and `mash`. The stand-in second player: `Systems/Plots` exposes `seam.addPlayer(userId)` and the same entry
points the remotes call (`vault/patterns/stand-ins-through-module-seams.md`). Existing hooks stay.

## H. Policy (M2-15 builds `Systems/Policy`, M2-18 reads it)
`Policy.get(player) -> { randomItemsRestricted: boolean, tradingAllowed: boolean }`, never yields: one
`PolicyService:GetPolicyInfoForPlayerAsync` per player on join in a pcall with `Config.Policy.TIMEOUT_S`; until it
answers, and if it fails or times out, `{ randomItemsRestricted = true, tradingAllowed = false }`; cached for the
session; the hooks override. `Policy.onReady(player, fn)` for the first answer (Shop.State and Steal.Flag re-send).
A boss with a bought mark cannot be lifted when the thief's or the owner's `tradingAllowed` is false; earned bosses
are unaffected; `Steal.Flag` carries the greyed prompt; a forced `HoldStart` is refused `locked`. Restricted: the
server never quotes, prompts, grants (a late receipt becomes tickets kept, not spun, TEAM CALL M2-01-8) or accepts a
spin. TEAM CALL 38 stays `UNVERIFIED` until Roblox answers.

## I. Names for ids in `Shared/Ids.lua`
Zones 1..6, tiers 1..6, `z<zone>_t<tier>` (36, `Ids.parseCreature`), body types, hazards, bags as M1;
`REPORT_GRADES`, `BOUGHT_SOURCES`, `PAD_KINDS`, `FUNNEL`, `NOTICES`, `SHOP_KEYS`, `CASH_PACKS`, `SPIN_PRODUCTS`,
`isPass`, `isProduct`. **The shop keys stay M1's snake_case** (`pass_auto_punch`, `pass_perfect_auto_punch`,
`pass_2x_power`, `pass_2x_cash`, `pass_fast_carry`, `pass_long_lock`, `pass_extra_spots`, `pass_quick_hands`,
`pass_iron_grip`, `pass_starter_pack`, `product_cash_small|medium|large|huge`, `product_spin_1|3|10`,
`product_instant_shield`, `product_shield_breaker`), not the skeleton's camelCase (TEAM CALL M2-01-3: the skin's
Names and the skin scan already key on them). Roblox ids: `Config/ShopIds.lua`, read as `Config.Shop.IDS`: the 19
real ids from `team/assets.md` (M2-00).

## J. Evidence and checks
Every owner writes its check file in `studio/checks/` (the place guard first, `PASS`/`FAIL` lines, hooks cleared)
and its result to `team/verification/m2-<id>-<name>.md`. The gate wiring is `requirements/m2-gate.md`. Check headers
keep the M1 warm-ups (4 s warm-up before timing a move; AutoTap starts a fight itself; the clock offset settles after
about 3 s; SetPower during a bag burst gets the later beats). The M2 stand-in tap offsets are in
`m2-punch-numbers.md` section 1 (the M1 +70 ms Good is no longer a Good in every band).
