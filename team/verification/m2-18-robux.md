# M2-18: wave C server: receipts, passes, shop, spin, Starter Pack (scripter, opus, 2026-11-26)

Brief system 13; requirement `requirements/m2-wave-c-robux.md`; contract `requirements/m2-contract.md` C "Shop",
"Receipt rules", H; M2-02 items M3, M4, S3, S4, S11. Quality pass: Function. Game repo, nothing committed.

## Files (M2-18's own, contract section A)
- `src/ServerScriptService/Systems/Passes.lua`: owns all 10 passes. A cache that never yields, filled on join (all 10 asked of Roblox
  in parallel), confirmed after a purchase hint (`UserOwnsGamePassAsync`, 3 tries about 10 s apart), the `PassOwned` hook;
  on a change: `Base.refresh`, `Carry.refreshSpeed`, `Bag.sendState`, listeners. `Bag.owns` (and so Base, Carry, Income,
  Shield, Steal) now reads it.
- `Systems/Shop.lua`: `Shop.Open` (Quotes + State), `Shop.Buy`, quotes with keys (300 s), held amounts, `Shop.prompt` (the
  one opener, also used by `Shield.BuyBreaker`), the guard (`busyReason`: prompt / fight / carry / alert), Finished
  events, the 120 s timeout (S3), `Shop.State`, `Shop.Grant`, quotes dropped on `Rebirth.onRebirth` (S4),
  `Shop.setPromptFn` (checks).
- `Systems/Receipts.lua`: the one `ProcessReceipt` (cash packs, spin bundles, Instant Shield, Shield Breaker), all through
  `Session.recordPurchase`; the `FakeReceipt` hook.
- `Systems/Spin.lua`: `Shop.Spin`, the roll, `SetTickets`, `SpinSeed`, save after each spin (S11).
- `Systems/StarterPack.lua`: the contents grant (purchase or web buyer on join) and the once-a-session offer + `OfferSeen`.
- `Shared/SpinTable.lua` (the one odds table), `Config/Shop.lua`, `Config/Spin.lua`.
- Checks: `studio/checks/Robux.lua` (phases a, b, c), `studio/checks/Spin.lua` (a).

## What ran (Studio MCP, `studio` lock as `scripter-robux`, released)
Edit mode: `DevSync()` sync; CheckAll `install`; `Robux`, `Spin` (later `Shield`) added to `TmpChecks` from the sync
server. One `run_script_in_play_mode` (start_play) per row. Prompts never reach Roblox: `Shop.setPromptFn` records them;
grants come from `FakeReceipt` / `PassOwned`. No real purchase.

| Gate row | Check / phase | Result | What it shows |
|---|---|---|---|
| S13, S17 | Spin a | 20 PASS, 0 FAIL (the first run's 1 FAIL was Receipts not parsing, a type annotation; fixed) | table 40/28/17/10/4/1 = 100 in `ReplicatedStorage.Shared`; 100,000 rolls within 0.7 points three ways (seed 20261126 worst 0.120; SpinSeed 777 worst 0.213; unseeded worst 0.084; 0.03 s); the roll goes through the shared table; no zone beaten: zone 1 'zone'; zones 1,3: zone 2 'zone', zone 3 a z3 boss to the crate with `{spin, buyer}` and ticket 3 to 2 in one mutate, saved at once; restricted 'restricted'; malformed zones 'bad'; all six tiers give their boss; no tickets 'tickets' |
| S13, S17, S20 | Robux a | 48 PASS, 0 FAIL (run 1: 2 FAIL, both check artifacts: an older Grant read back, a crate holding the Starter Ram; fixed) | same purchase id twice = granted once, 'already'; quotes at the minimums, keys valid 300 s; the formula (15 min of income, 2x Cash doubles it); Buy prompts; never two ('busy' + notice); receipt grants the amount held at the prompt (2,500) not the new formula (7,777); a client-opened receipt grants the formula; wrong / missing / expired key 'stale' with new quotes; cancel frees and drops the held amount; S3 timeout; guard: a real carry, a fight and an alert (module seams) 'busy'; Breaker refused in Shop.Buy; 'owned'; 'needAuto'; PAP opens with Auto Punch; PAP alone (web buyer) = auto and Perfect usable; each pass read through Passes; Fast Carry 16, 2x Cash, Extra Spots 16/17 on and off; 10 Roblox answers cached on join; a hint with the hook off is never ownership; a hint with no hook entry asked Roblox (owned); Instant Shield 'shieldUp' while joining, receipt makes it 'instant'; restricted: State flag, three spin products 'restricted', quotes, packs and passes unchanged, a spin receipt becomes kept tickets; malformed Buy 'bad'; 19 ids, every product id maps back |
| S17 (attacking set), S20 | Robux b | 22 PASS, 0 FAIL | Breaker at 10 studs prompts through `Shop.prompt`; receipt breaks the held target after the write; 'recent'; after 5 min a held target broken before the receipt becomes 1 charge (Grant `charge`, `breakerCharged` n=1); a client-opened Breaker receipt adds a charge; the charge is used free; 'joining', 'instant', 'range'; a real "shield broken" alert on the buyer makes Buy 'busy' (cleared after 10 s); charges and tickets in `Config.Rebirth.KEPT` |
| S17, S13 | Robux c | 18 PASS, 0 FAIL (run 1: 5 FAIL, a real bug, below) | no offer before an upgrade, OfferSeen refused; the first upgrade during an alert: no offer until the guard clears, then one Shop.Offer; no second; OfferSeen once (StarterPackShown); Starter Pack owned: $5,000 bought cash, Ram z1_t4 in the crate with `{pack, buyer}`, recorded first, Grant with the uid; not granted twice; Buy 'owned'; web buyer gets it on join (Leave + Rejoin); TEAM CALL M2-18-3: Roblox's real answer alone grants nothing in Studio; a rebirth drops the quotes |
| S20 | BoughtScan (M2-14, edit mode) | 2 PASS, 0 FAIL (129 scripts) | no c2s payload carries bought / boughtCash; no script outside Data/ and BoughtMark builds a mark or assigns boughtCash |
| regression | Shield a (M2-15) | 35 PASS, **1 FAIL** | `FAIL Shield/a 12 BuyBreaker with no Shop module: 'busy', nothing held`: expected; that row tested the seam before Systems/Shop existed. With Shop present it opens a real Studio test prompt. M2-15's check must stub `Shop.setPromptFn` (owner: M2-15; not edited here) |

Bug found and fixed in run 1 of phase c: the Starter Pack contents were recorded under one fixed id, and `Session.wipe`
keeps handled purchase ids, so after a Wipe the grant answered "already" and gave nothing. Now each attempt records
`starter_pack:<the Ram's uid>` and `starterPackGiven` (checked in the write and live) is the once-guard.

Repo scans: `python tools/check_guard.py` 72 scripts, 0 without the guard; `python tools/check_skin.py` 0 hits.
Cleanup: CheckAll `cleanup` (TmpChecks removed), 0 `HFB_` attributes, marker true, mode stop. Lock released.

## M2-02 items landed
- M3: grants only into a live, saving profile (`Session.isSaving` before any planning, then `recordPurchase`); "retry" -> NotProcessedYet;
  effects outside the profile only after the write; amount held at prompt time, formula without a prompt; Breaker target
  re-checked (`canBreakTarget`), else a charge (also if it changes during the write, TEAM CALL M2-18-6).
- M4: `PromptGamePassPurchaseFinished(true)` is only a hint (`Passes.hint`); ownership after `UserOwnsGamePassAsync`;
  Starter Pack contents on a confirmed purchase and on join for a web buyer; never into a temp profile.
- S3: prompt freed on Finished, leave, 120 s. S4: quotes dropped on rebirth. S11: save after each spin.

## Only a published game (or a real Studio purchase) can prove: UNVERIFIED
1. A real `ProcessReceipt` delivery for each of the 9 products, the same receipt redelivered after a rejoin (granted once).
2. Leaving before the grant, rejoining: the receipt arrives again and is granted once.
3. `PromptGamePassPurchaseFinished` then `UserOwnsGamePassAsync` true within 10 s for a real pass bought in game; a pass
   bought on the web page while away is owned on the next join (Starter Pack contents on that join).
4. `PromptProductPurchaseFinished` arriving for every closed dialog (cancel and buy) so the prompt frees without the 120 s timeout.
5. A real restricted account (`ArePaidRandomItemsRestricted` true) seeing no spin products.
6. The Studio account owns every pass, so in Studio the real join answer is true for all 10: only the hooks test "not owned".

## 2026-11-26 M2-27 should-fixes SF2, SF3, SF4 (scripter, opus; `studio` lock as scripter-robux, released)
- SF2 (`Shop.peekHeld` / `clearHeld`; `Receipts`): the held cash-pack amount is peeked for the plan and cleared only
  once the grant is written ("granted" or "already"); a failed write ("retry") keeps it for the redelivered receipt.
- SF3 (`Passes`): a failed join check is "unknown" (read as not owned), asked again in the background
  (`Config.Shop.PASS_RETRY_TRIES` 3, gap 10 s doubling) and on demand when the shop opens (`Passes.retryFailed`);
  seams `Passes.setAskFn`, `Passes.refetch` for checks.
- SF4 (`Systems/Bag.lua`, M2-10's file, taken over with the orchestrator's go-ahead): buying a level is one
  `Session.mutate` doing `ops.spendCash` (the bought-cash rule) and the level together; no refund path left.

| Check / phase | Result | New rows |
|---|---|---|
| Robux a | 57 PASS, 0 FAIL (first rerun: row 52 counted the funnel's flag write as a second mutate; the row now counts mutates that change level or cash) | 47-48 SF2: a failed write is NotProcessedYet with the held 2,500 kept; redelivery grants 2,500 not the 7,777 formula, hold cleared. 49-51 SF3: join failure = unknown and not owned; owned after 2 background tries; with the tries spent, the shop opening asks again. 52-55 SF4: one mutate (level +1, cost 150), boughtCash 850 = cash 850, a refused mutate changes nothing ('state'), 'cash' when short |
| Robux b | 22 PASS, 0 FAIL | (rerun) |
| Robux c | 18 PASS, 0 FAIL (first rerun: row 5 FAIL because the real client from M2-19/M2-20 now answers Shop.Offer with OfferSeen itself; the row now accepts exactly one acceptance from either side) | (rerun) |
| Spin a | 21 PASS, 0 FAIL | (rerun) |
| Bag a, b (M2-10) | 23 PASS / 25 PASS, 0 FAIL | run with `Shop.setPromptFn` stubbed and every pass `PassOwned=off` before the check (the check then sets its own) |

check_guard: 79 scripts, 0 without the guard; check_skin: 0 hits. Cleanup: TmpChecks removed, 0 `HFB_` attributes, marker true, mode stop.
