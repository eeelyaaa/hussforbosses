# M2-02: exploit review of the M2 contract, before waves B and C (qa-exploit-reviewer, opus, 2026-11-25)

**Verdict: waves B and C may start**, building to the contract as edited here. All ten must-fix findings were contract
gaps, and the edits are now in `requirements/m2-contract.md`, each marked `[M2-02 Mn]`. Their code changes are routed
by task below. None is in M2-06's files. S25 (contract half) passes; the code half is M2-27.

**How this was established:** a paper review, read from the contract (A to J), `Shared/Net.lua`, `Ids.lua`, `TestHooks.lua`,
`Config/*`, `Systems/Funnel.lua`, the M1 `Data/Session.lua` API (names only), the wave A/B/C requirements,
`m2-punch-numbers.md` section 2, brief systems 10 to 14 and the build plan's "Technical shape". Nothing was run (no
Studio lock taken, as briefed). Each finding gives the path to an exploit, or a concrete path to data loss.

## Must-fix (applied to the contract)

| # | Where | Finding: the path | Fix (now in the contract) | Code: task |
|---|---|---|---|---|
| M1 | D `cash`, `boughtCash`; `Data/Session.lua:75` `Session.set`; `Systems/Income.lua:69` | M1 code writes `cash` with `Session.set`, which skips the bought-cash rule. Spend through `set` and `boughtCash` stays above `cash`. Rebirth sets `cash = boughtCash`, so cash appears out of nothing. `Session.mutate(fn)` also lets any system write `boughtCash`, a `bought` mark or `zonesBeaten`. | `set("cash")` routes the difference through `addCash`/`spendCash`. After every mutate, `boughtCash = min(boughtCash, cash)`. Protected fields: `mutate` refuses a change to any of them unless it comes from the owning API. `set` refuses them. Rebirth: `cash = min(cash, boughtCash)`. | M2-09 (Session), M2-11 (Income/Base use `addCash`/`spendCash`), M2-14 |
| M2 | D (new "Rebirth, every key"); C `Rebirth.Request` | The contract had no complete reset/kept list. A "reset all but the kept list" build would reset `nextUid`, so new uids would collide with kept bought bosses (the transfer is keyed by uid). It would reset `starterPackGiven`, so on join the pass is still owned and the flag false: $5,000 and a bought Ram again after every rebirth. Resetting `purchases` would let a redelivered receipt grant twice. | A table that names every schema key once, as reset or kept. `Config.Rebirth.RESET`/`KEPT` hold it, and a check asserts that it covers the schema. | M2-14 |
| M3 | C "Receipt rules"; D Receipts | (a) A receipt granted into a temp, loading or leaving profile is never saved, so the Robux is taken and nothing is kept. (b) "Undo the grant in memory" after a failed write also undoes changes made during the write's yield. Effects outside the profile (a shield raised or broken, toasts) cannot be undone. (c) A client can open `PromptProductPurchase` itself. The contract assumed a server-held prompt, so a cash-pack amount, a Breaker target or a held quote could be nil, or wrong if the quote expired while the dialog was open. A stale Breaker target could break a later owner's shield on the same plot. | `NotProcessedYet` for temp, loading or leaving profiles. A grant is a pure op: applied inside `UpdateAsync`, then to the live profile only after success, with outside effects after that. A receipt never needs a server prompt. The amount is held at prompt time; with no prompt held, the formula at receipt time. The Breaker target is held as `{plotId, ownerUserId, at}` and re-checked, else a charge. | M2-09 (`recordPurchase`), M2-18 (`Receipts`, `Shop`), M2-15 (Breaker pending) |
| M4 | C "Receipt rules" (passes) | `PromptGamePassPurchaseFinished(true)` was the only signal named for a pass purchase. The Starter Pack (cash, bought cash and a bought boss) hangs on it. Treat that flag as a hint (DevForum reports it can be spoofed; not confirmed here), and the defence costs one call. Web-page buyers of the Starter Pack were never granted the contents. | Owned only after `UserOwnsGamePassAsync` is true (retried). The Starter Pack grant is one mutate plus a save, runs whenever the pass is owned and `starterPackGiven` is false (after a purchase and on join), and never goes into a temp profile. | M2-18 |
| M5 | C rows `Base.PickUp`, `Swap`, `Boss.Upgrade`; new C2 | While a thief held or carried a boss, only `PickUp` refused "a hold". `Swap` could sell the held boss and the hold would still complete (cash plus boss = duplication). `PickUp` during the carry-off put the uid on two heads. Nothing required the success to re-check that the uid was still there. | One lock per uid (`held`, then `carriedOff`). PickUp, Swap, Upgrade, Place on that spot and Rebirth are refused `locked`. The hold is timed by the server. Success re-checks the uid, the spot, the lock and the thief's plot in the same step. | M2-15 (`Steal.isLocked`), M2-11 (checks in Base and Boss), M2-14 (rebirth) |
| M6 | D Transfer | Owner written first, thief second. But the thief's 60 s autosave could write the uid before the owner's write had succeeded. If the owner's server then died, the old owner record still holds the uid: two records. A boss stolen back was dropped on load by the owner's own old `transferNote`. | The thief's saves leave the uid out (`pendingFrom`) until the owner's write succeeds. Placing a uid removes that profile's note for it. | M2-09 (`transfer`, save filter), M2-15 (caller) |
| M7 | C2 "Movement" | "Over-speed drops" had no definition. Characters are client-owned, so a client can set its own speed or teleport home with the boss, and the brief says "no teleports". | Server samples every Heartbeat, with a limit per step and per 1 s window. A stolen carry that breaks either returns the boss. Success also needs a minimum travel time from the spot to the thief's plot. | M2-15 (stolen carry, chase), M2-11 (fight, crate and spot carries) |
| M8 | C `Carry.State`; D "Not saved" | "Carried bosses are not saved" covered only fight bosses. A boss taken from the crate (perhaps bought) or picked up from a spot that hits a hazard and runs out its grace, or is carried when the player leaves, would be deleted: a paid boss lost. A stolen carry that entered `dropped` could be grabbed by the thief while it also snapped back: two copies. | Each carry keeps an `origin`. Only `fight` can vanish. Crate and spot bosses stay in the profile until the one mutate that places, swaps or sells them. A stolen carry never enters `dropped`, and Grab is refused for it. | M2-11 (Carry, Base), M2-15 |
| M9 | C `Offline.*` | "Collect" could pay `total` as new cash while the same seconds also sit on the pads (padStamp-based fill): double pay on every rejoin. | Collect takes the money from the pads (settle each pad, then move at most `perBoss[uid]`). It never creates money. A boss no longer on its spot pays 0. | M2-14 |
| M10 | D `version` | A record from newer code (during a Roblox update, old and new servers run together) loaded by old code loses its new fields on the next save. | A higher `version` than the code knows gets a temp profile and is never written. | M2-09 |

## Should-fix (not applied; route through M2-01 or the task)

| # | Where | Finding | Fix | Task |
|---|---|---|---|---|
| S1 | D `lock = { server = JobId }` | `game.JobId` is `""` in Studio, so two Studio sessions share one "server" and the S15 check "a second session cannot take a locked profile" can pass for the wrong reason. | Make `lock.server` a GUID made once per server (`HttpService:GenerateGUID(false)`). | M2-09 |
| S2 | D lease 300 s, load retries 15 s | A player who rejoins after a server crash gets a temp profile for up to 5 minutes, and whatever they earn there is lost. | Keep retrying in the background (every 15 s, until the lease ends), then swap the real profile in, saying up front that progress in a temp profile is not kept. Or shorten the lease to 180 s (3 missed autosaves). | M2-09 |
| S3 | C `Shop.Buy` `promptOpen` | If the Finished event never comes, `promptOpen` stays set and the player can never buy again that session. | Clear it on Finished, on leave, and after 120 s. | M2-18 |
| S4 | C `Shop.Quotes` | A quote taken before a rebirth (12 h of the old income) can still be bought after it, within 5 minutes. | Invalidate quotes on rebirth. | M2-18, M2-14 |
| S5 | C "Every c2s handler" | Not stated: no yield between the checks and the mutate. A yielding call (for example `UserOwnsGamePassAsync` in `AutoToggle`) opens a check-then-act race. | Add "no yield between the checks and the mutate; pass ownership read from the cached answer". | M2-01, all handler tasks |
| S6 | B2/B5 and `m2-punch-numbers.md` 2.2 (fight) | An untimed report moves the fight's `nextLanding` on by `MISS_RESTART + RING`, and that adds up. Untimed every 0.79 s pushes the expected landing ahead of real time, so the stall (Miss) rule never fires. At Easy and Fair the player can never lose a heart. | Accept a fight untimed only inside the server's current ring, and set `nextLanding = currentRingLanding + MISS_RESTART + RING`, never the previous `nextLanding` plus. | M2-06 (now in its files: send as a note, don't edit) |
| S7 | Contract B5 | It doesn't carry TEAM CALL M2-06-1 (untimed after untimed needs 0.66 s plus the context's Good window), which `Config/Punch.lua:16-20` already states. | Bring B5 up to date. | M2-01 |
| S8 | `Systems/Plots` | Server size is 8 (M2-00), but if it ever isn't, a ninth player has no plot and every handler meets a nil plot. | Plots: no free plot means that player's base remotes refuse `state`; log it. | M2-15 |
| S9 | G `Steal2` seam | `seam.addPlayer(userId)` makes profiles. If it ever runs outside Studio, or with a real user id, it loads or locks a DataStore record. | The seam asserts `RunService:IsStudio()`, uses user ids <= 0, and its profiles never touch the store. | M2-15, M2-09 |
| S10 | H `Policy.get` | If a field is missing from the policy answer, it should count as restrictive. | `tradingAllowed = info.IsPaidItemTradingAllowed == true`; `randomItemsRestricted = info.ArePaidRandomItemsRestricted ~= false`. | M2-15 |
| S11 | C `Shop.Spin` | A spin isn't saved until the next autosave or leave. | `Session.save` after each spin (the ticket and the boss together). | M2-18 |

## Notes (no change needed now)
- N1. The forged-grade ceiling (about 1.5x flawless play, TEAM CALL M2-03-4; lower with M2-06-1) is the accepted
  exposure. The rate rules as written allow normal play (I checked the legal gaps in `m2-punch-numbers.md` 2). M2-27
  re-measures it.
- N2. Owner-side distance checks (`OwnerPunch` 8 studs, chase 20) work on positions the owner's client controls. M7's
  sampling also covers the chase. An owner who teleports can only recover their own boss.
- N3. `Profile.TestReport` exists in live with no listener (`TestHooks.lua:145-148`), so events queue on it unread.
  Connect a no-op live, or don't create it live (M2-01).
- N4. Spin: `Shared/SpinTable` is read by both sides and the roll is the server's `Random`. Assert at load that the
  weights add up to 100. `SpinSeed` is Studio-only through `TestHooks.get`.
- N5. Income multipliers (2x Cash, rebirth) apply to the whole elapsed stamp when the pad settles, offline time
  included. That is design, not an exploit.
- N6. M2-13-5: the rebirth text counts stolen bought bosses as kept. Display only; M2-14 should send the kept count.
- N7. Saved stamps (`padStamp`, `leftAt`, `shieldReadyAt`) are compared across servers: clamp negative elapsed time
  to 0.

## Found sound
- `Net.onServerEvent` rate-limits before anything else, asserts that a rate exists for every c2s remote, and drops
  any payload that isn't a table. `Net.isNumber` rejects NaN and infinity first. `isShortString` checks byte length
  and UTF-8.
- No c2s payload carries a price, an amount, a level, a bought mark, bought cash, a zone beaten or a user id. The one
  exception, `OwnerPunch.thiefUserId`, is checked against the carrier. Every id is looked up in server state.
- Product and pass ids come from `Config/ShopIds` by key (`Ids.SHOP_KEYS`), never from the client. `Shield.BuyBreaker`
  is the only Breaker path, there is one `ProcessReceipt`, the purchase id is recorded in the same write, and
  restricted spin receipts become kept tickets (M2-01-8).
- The policy defaults to restrictive until it answers and on failure, both flags; the guard is checked for thief and
  owner. Spin tickets are refused while restricted.
- Test hooks: `get`, `consume` and `onSet` return nil outside Studio; `TestReport` is listened to in Studio only; a
  live server warns about hooks saved into the place; `FakeReceipt` and `PassOwned` go through the hooks.
- `Config.Env` (from `RunService:IsStudio()`) goes into every store name, and keys are `player_<UserId>` (RTBF works).
- The session lock is inside the record, with one `UpdateAsync` per write, `BindToClose` within 25 s, and the
  thief's boss returned before the final save.
- Shop prompt guard: never two prompts, none during a fight, a carry or an alert; Instant Shield is refused while a
  shield is up and turned into an unbreakable shield if it lands late.

## Not reviewed
M1 code beyond what the contract touches; `Shared/Moves`, `Hazards.lua` paths; client controllers; the UI. Rate
numbers per remote weren't load-tested. Nothing was run in Studio.

## Published-build test plan (for the two-device checklist)
1. Buy a cash pack, wait 6 minutes on the dialog, confirm: the granted amount equals the amount shown.
2. Buy the Starter Pack on the game page (web), then join: contents granted once; rejoin after a rebirth: not again.
3. Buy a product, then leave during the purchase dialog: granted on the next join, once.
4. Two accounts: steal a bought boss while one account's `IsPaidItemTradingAllowed` is false: greyed and refused.
5. Two accounts: thief leaves the server during a carry: the boss is back on the owner's spot after both rejoin.
6. Server shutdown during a steal carry (close the server from the dashboard): the boss is with its owner, in one place.
7. Real `ProcessReceipt` redelivery: buy, crash the server before the grant (not scriptable; watch for duplicates in logs).
