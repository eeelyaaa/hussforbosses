# M2-15: wave B server: plots, stealing, the shield, the policy guard (scripter, opus, 2026-11-26)

Brief system 10 (and 7's plot assignment); contract `requirements/m2-contract.md` C "Steal" / "Shield", C2, G, H with
`[M2-02 M3, M5, M6, M7, M8]` and S8, S9, S10. Quality pass: Function. Game repo, nothing committed.

## Files (all M2-15's own, contract section A)
- `src/ServerScriptService/Systems/Plots.lua`: fill order `Plots.pick` (1, 8, 4, 5, 2, 7, 3, 6), `of`, `ownerOf`, `byId`,
  `byUserId`, `players`, `root`; the stand-in seam `Plots.seam.addPlayer / removePlayer / moveTo / walkTo / plotPoint`
  (Studio only, user ids <= 0, on `Session.standIn`); the `Steal2` hook.
- `src/ServerScriptService/Systems/Steal.lua`: HoldStart / HoldCancel / OwnerPunch, the uid lock (`Steal.isLocked`, wired
  into `Base.setLockCheck`), `Steal.alertOn` (wired into `Base.setAlertCheck`), lift, carry-off, returns, success with
  `Session.transfer`, safe time, chase, stun, Iron Grip stagger, `Steal.Flag`, `Steal.Punch`.
- `src/ServerScriptService/Systems/Shield.lua`: joining / up / instant / cooldown / ready per plot, lock pad, push-out,
  Raise / UseCharge / BuyBreaker, Broken, State, saved `shieldReadyAt`, `Rebirth.onRebirth` reset, `SetCharges` hook,
  the M2-18 seams.
- `src/ServerScriptService/Systems/Policy.lua`: `get`, `isAnswered`, `onReady`, `onChange`, `fromInfo` (S10), hooks.
- `Config/Steal.lua`, `Config/Shield.lua` (incl. `BROKEN_ALERT_S` 10), `Config/Policy.lua`.
- Checks: `studio/checks/Steal.lua` (phases a, b, c), `Shield.lua` (a), `Policy.lua` (a), play mode.

## What ran (Studio MCP, `studio` lock as `scripter-steal`, released)
Edit mode: `DevSync()` sync, `HFB_CheckAllMode = install` + CheckAll, then Steal / Shield / Policy (and Base, Rebirth for
regression) added to `TmpChecks` from the sync server. Each row is one `run_script_in_play_mode` (start_play). A stand-in
second player through the seam; two check plots cloned from Plot1 as PlotId 2 and 8 in play mode only.

| Gate row | Check / phase | Result | What it shows |
|---|---|---|---|
| S16, S8, S9 | Steal a | 54 PASS, 0 FAIL | fill order 1,8,4,5,2,7,3,6; no free plot = nil; stand-in gets plot 8 not the lower 2; the seam refuses a real-looking id; refusals (malformed x4, own plot, crate boss, unknown uid, shield 'shield', 9 studs 'range') change nothing; policy guard: bought boss 'locked' with both flags off, owner's only, thief's call 'fail'; Flag sent locked=true then false; earned boss stealable with flags off; hold 2.05 s by the server's timer (Quick Hands 1.03 s); lock + owner Rebirth 'state'; second HoldStart 'state'; lift: origin stolen, stolenFrom 8, level 4, Alert; Grab refused; teleport home, a hazard, a respawn return it; moving 8 studs cancels; HoldCancel only own; home at 16.4 studs/s inside the 1 s window returned by the minimum travel time (Carry flags 0/0); a real steal of a bought boss: success to both, in the thief's crate at level 2 with `{spin, buyer -51}`, owner's transferNote, owner's pad paid (135), written owner then thief, records 0/1, still on the head as a crate carry, placed with the mark; safe 59.1 s; steal-back 'safe', allowed after ShieldClock +61 |
| S16, S18 | Steal b | 24 PASS, 0 FAIL | stand-in thief, real owner: Pick Up and Upgrade 'locked', Rebirth 'state'; the owner's punch cancels a hold ('punched'), 0.8 s gap; lift: owner WalkSpeed 20, alertOn; punch 'range' at 19 studs; a hit: 'dropped', boss back, stun (WalkSpeed 0, no hold) 1.5 s, chase ends (16), Steal.Punch drop; Iron Grip: stagger, second hit within 10 s drops, a hit 10.3 s after the stagger staggers again, a hazard still returns at once; the owner's shield rising returns a boss still inside ('shield'), thief pushed out, hold 'shield' |
| S16 | Steal c | 8 PASS, 0 FAIL | stand-in steals and walks home (round to the entrance) with `SaveFailBetween`: success, the thief's write errored; uid in exactly one profile; records owner 0 / thief 0 (the known window, below); after the thief's next write 0 / 1; hook one-shot; crate carry, not pending |
| S10, S18 | Shield a | 36 PASS, 0 FAIL | joining 60 s unbreakable; a visitor inside pushed to 5 studs outside the entrance; SetCharges 3; 'joining'; cooldown to +120 and saved; 'state' when down; ready; lock pad: up 60 s breakable; 'range' at 20; own plot / bad id 'state'; BuyBreaker with no Shop 'busy', nothing held; break at 10 studs: cooldown, charge 3->2, brokenUntil +300, Broken, alert on; raised again: 'recent', no charge used; alert over after 10 s; breakable after 300 s; M2-18 seam: stale owner false, live target breaks; 'charge'; Instant in the cooldown (60 s, 'instant'); Instant over a running shield restarts at 60; isUp; Long Lock 90 s; a hold cancelled 'shield' with push-out; rejoin keeps the saved readyAt (cooldown to +500, not +60); resetCooldown; real owner's Raise inside the base, 'state' when not ready |
| S16 (policy) | Policy a | 18 PASS, 0 FAIL | the Studio account's real answer (trading true, restricted false) from Roblox on join, cached, no further calls; fromInfo: missing / odd fields restrictive (S10); stand-in restrictive default; onReady once; hooks on / off / fail / per-player; onChange on a hook change; back to the real answer |
| regression | Base a; Rebirth a | 36 / 0; 21 / 0 | M2-11's lock seam rows and M2-14's thief-lock rows still pass with Steal wired in |

Failures fixed during the runs (all in my check, none in the systems): phase b set the owner 9 studs away (punch range
8); phase c waited on the wrong stand-in id; the first success walk went straight through Plot1's side fence (anchored
steps ignore collisions) and was correctly refused by the minimum travel time, so the check now walks round to the
entrance; the real player's root is anchored during a seam walk so its client cannot pull it back. Phase b + c in one call
timed out the MCP (100 s): split.
Cleanup: TmpChecks removed, 0 `HFB_` attributes, no check plots, marker true, mode stop. Repo scans: `check_guard.py` 65
scripts 0 without the guard; `check_skin.py` 0 hits; `check_labels.py` 0 problems.

## M2-02 items landed
M3 (Breaker target held as `{plotId, ownerUserId, at}`, re-checked by `canBreakTarget`, else a charge), M5 (one lock per
uid, server-timed hold, success re-checks in the same step), M6 (caller of `Session.transfer`; the pending case ends the
carry with the boss in the thief's crate), M7 (stolen carry: Carry's step and window, plus the minimum travel time; the
chase sampled), M8 (a stolen carry never drops; Grab refused), S8 (no plot: HoldStart refused 'state'; `Plots.pick` nil),
S9 (seam Studio only, ids <= 0, memory store), S10 (`Policy.fromInfo`). M3 as the Breaker target here only; M2-18 grants.

## The known data window (not closed: `Data/Transfer.lua` is M2-09's)
Measured in Steal c: after the owner's write succeeds and before the thief's write, the uid is in no record. A server
crash in that moment loses the boss (never duplicates it). Closing it needs Data: e.g. the owner's `transferNote` keeps
the entry and the owner's next load, or a reconcile on the thief's load, puts the boss back when the thief's record lacks
it. Routed to M2-09 / M2-27.

## Requests to other owners (not edited)
- M2-09 `Data/Session.lua` `assignPlot`: pick with `Plots.pick(list)` (fill order) instead of the lowest PlotId. Same
  result while the place has only Plot1; it matters once M3 builds the hub.
- M2-11 `Systems/Carry.lua`: a slow seam (`Carry.setSlow(player, factor, untilT)` applied to WalkSpeed while the movement
  check keeps the unslowed speed) for the Iron Grip stagger; until then the stagger is server state + `Steal.Result
  stagger` + `Steal.Punch` and the client (M2-16) slows its own character 0.5 s x `Config.Steal.STAGGER_SLOW`.
- M2-11 `Systems/Base.lua`: refuse Sell / Swap of a uid still pending from a steal (`Transfer.isPending`): if the owner's
  write keeps failing and the thief leaves, the boss goes back to the owner after the thief already sold it.
- M2-28 / M2-11 / M2-14 checks: `Base.lua` and `Rebirth.lua` checks end with `Base.setLockCheck(function() return false
  end)`, which switches the steal lock off for the rest of that play session; restore `Steal.isLocked` instead.
- M2-01 `Net.lua` comment: `Shield.State` also carries `ownerUserId`.

## On-screen and two-client checks owed (main session) UNVERIFIED
1. Two Studio clients (Test > Clients 2): B holds the Steal prompt on A's placed boss; A sees the banner, the arrow and
   the BOUGHT tag for a spin boss (GrantBoss `bought=spin,buyer=<A>,to=<spot>`); B's thief strip; A punches B (plain
   punch, single huss) and the boss snaps back; A runs at 20 while chasing.
2. `PolicyTrading` = `<B>:off`: B's prompt on A's bought boss greyed "Can't be stolen"; A's earned boss still works.
3. A raises the shield (pad and HUD) with B inside: B is pushed out at the entrance; B's hold bar cancels.
4. B with a charge (`SetCharges` 1) within 15 studs of A's up shield: Break shield button, A's "shield broken" alert.
5. Iron Grip on B (`PassOwned pass_iron_grip=on`): the stagger shows (once M2-16 slows the client).
Published-build items (two accounts): the M2-02 test plan 4, 5, 6.

## Re-run after M2-18 (2026-11-26, lock `scripter-steal`, released)
`Shield a` row 12 assumed no `Systems/Shop`; with M2-18 in, `Shop.prompt` would open a real Studio purchase dialog. The
check now stubs `Shop.setPromptFn` at its start (records the call) and restores it (`setPromptFn(nil)`) at the end, and
tests the Breaker purchase through it: 12a BuyBreaker prompts the Shield Breaker product (stub), 12b a second BuyBreaker
while the prompt is open 'busy', 12c a cancelled dialog drops the held target, 12d a receipt (`Receipts.process`, unique
purchase id per run) whose target is no longer breakable is granted as one stored charge, 12e a receipt with the target
still breakable breaks the shield and stores nothing. `Policy a` now forces every pass off with `PassOwned` too (Steal and
Shield already did). `studio/checks/Base.lua` and `Rebirth.lua` (at the orchestrator's request, M2-28 note) now put
`Steal.isLocked` back instead of `return false` after their lock rows.

| Check | Result |
|---|---|
| Shield a | 40 PASS, 0 FAIL |
| Steal a / b / c | 54 / 0, 24 / 0, 8 / 0 |
| Policy a | 18 / 0 |
| Base a / Rebirth a (regression, seam restored) | 37 / 0, 21 / 0 |
Place clean after (no TmpChecks, 0 `HFB_` attributes, Plot1 only, mode stop). `check_guard.py` clean.

## Re-run after M2-11b's slow seam (2026-11-26, lock `scripter-steal`, released)
`Systems/Steal.lua`: the Iron Grip stagger now calls `Carry.setSlow(thief, Config.Steal.STAGGER_SLOW (0.5),
Config.Steal.STAGGER_S (0.5))`, so the slow is held by the server (TEAM CALL M2-15-6 superseded: the client need not slow
itself). New rows in Steal b: 16b the thief's WalkSpeed is 6 of 12 right after the stagger; 16c back to 12 after 0.5 s,
still carrying.

| Check | Result |
|---|---|
| Steal a / b / c | 54 / 0, 26 / 0, 8 / 0 |
| Shield a (Shop prompt stubbed, passes forced off) | 40 / 0 |
Place clean after (no TmpChecks, 0 `HFB_` attributes, Plot1 only, mode stop).
