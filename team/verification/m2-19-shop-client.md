# M2-19: wave C client: shop and spin controllers (scripter, sonnet, 2026-11-26)
Pass: Function. Files: `Controllers/Shop.lua`, `Controllers/Spin.lua` (both AUTO_START), probe `studio/checks/ShopClient.client.lua`. Nothing committed.

## Built
- Shop: open/close/toggle (B, D-pad up via `Input.on("shop")` when it exists else read here; gamepad B closes; the Shop tile only if `Names.ui.tiles.shop` exists), `Shop.Open` on open, quotes kept with keys and refreshed before expiry, `Shop.buy(key)` (local checks only spare a round trip; the server prompts and decides), the client half of the prompt guard `Shop.canAsk()` (fight, carry, steal/broken alert via `Ui/StealAlert.isOn`, prompt open/pending), Starter Pack offer (waits for `Ui/StarterOffer.show()` to return true and the boss panel to close, then `OfferSeen` once), `Profile.Changed` tickets/charges/zonesBeaten.
- Spin: zone picker from zonesBeaten (default furthest), `Spin.spin()` -> `Shop.Spin {zone}`, one in flight, `SpinResult` to `onResult`, policy-restricted hides/refuses, `Spin.odds()` = `SpinTable.ODDS`; if `Ui/Spin.oddsVisible()` exists the spin is refused until true.
- Screen contract for M2-20 (duck-typed, all optional): `Ui/Shop` open/close/isOpen (its X and tile call `Shop.close()/toggle()`); `Ui/StarterOffer` show(Shop)->drawn:boolean, hide; `Ui/Spin` open/close/isOpen/oddsVisible. Screens subscribe with `Shop.onChange/onGrant/onOpenChanged`, `Spin.onChange/onResult`, read `Shop.quoteFor/owns/restricted/spinTickets/breakerCharges`.

## Ran (Studio MCP, `studio` lock scripter-shopclient, released; live M2-18 server)
Probe 40 PASS, 0 FAIL (one real client, lines via Profile.TestReport): real `Shop.Open` sent once; closed in a fight; quote kept / expired not offered / stale buy sends nothing; one buy pending, second refused; Grant clears; unknown, Breaker ('atShield'), owned, restricted spin refused locally; guard: fight, carry, broken alert, server promptOpen; profile fields; offer waits for its screen and no OfferSeen when not drawn; spin: no zone, no ticket, bad zone, one in flight, result, odds table identity, restricted; malformed payloads ignored. Buys/spins ran with `_noSend(true)`: no Shop.Buy/Spin reached the server, no prompt, no purchase. Probe removed, no hooks armed, play stopped. Scans: check_streaming 0, check_guard 0, check_skin 0.
Not run against live replies: Shop.State/Quotes/Grant/SpinResult payloads came through the seams (shapes from Net.lua), only Shop.Open round-tripped.

## Owed
- ON-SCREEN (main session, after M2-20): B / D-pad up / Shop tile open the shop on phone, desktop, gamepad; shop closes when a fight starts; odds list visible before Spin active; Starter Pack offer appears after the boss panel closes, once; no Robux dialog during fight/carry/alert (needs a real prompt: Studio account).
- UNVERIFIED: real Shop.Buy prompt path end to end (stubbed by design).
## Notes
- Refusal reasons from Shop.Grant (cancelled/stale/busy/owned/...) have no text in `Names.ui.reasons`; M2-20 / Toasts owner must add them. Also `Names.ui.tiles.shop` is missing.

## SF1 (M2-27-1, 2026-11-26): restricted until Shop.State says otherwise
`Controllers/Shop.lua` and `Spin.lua` now start with `randomItemsRestricted = true` (and `_reset` returns to it): before the first `Shop.State`, or if it never arrives, the Spin card/wording/screen are hidden (`Spin.available()` false, `Spin.open()` and spin products refused 'restricted'). Shop.State then sets the real flag. Screens must read `Spin.available()` / `Shop.restricted()` and re-read on `onChange`.
Probe rerun under the lock (scripter-shopclient): 42 PASS, 0 FAIL, new rows z1 (before State: restricted, no spin UI, spin product refused) and z2 (State unrestricted opens it). Probe g-rows now open the Spin screen first (M2-20's `oddsVisible` correctly refuses a spin before odds are drawn: seen live as 'odds'). Probe removed, play stopped, lock released.
