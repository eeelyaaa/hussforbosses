# M2-14: offline earnings, rebirth, the bought mark and bought cash (scripter, opus, 2026-11-26)

Brief systems 11, 12 and 13's mark; contract `requirements/m2-contract.md` C (Offline, Rebirth), D (rebirth table,
protected fields) with `[M2-02 M1, M2, M5, M9]` and S4 (as a seam). Quality pass: Function. Game repo, nothing committed.

## Files (all new or M2-14's own)
- `src/ServerScriptService/Systems/BoughtMark.lua`: the only writer of a mark. `grant(player, creatureId, source, opts)`
  (claimed mutate, crate only, `opts.extra(q)` in the same mutate), `op(q, userId, creatureId, source, opts)` (pure, for
  receipt grants), `isBuyer`, `keptCount`, `grantFromHook` (Studio).
- `src/ServerScriptService/Systems/Offline.lua`: summary on join / Rejoin / LeaveAt, Collect from the pads, `cancel`.
- `src/ServerScriptService/Systems/Rebirth.lua`: `Rebirth.Request` handler, `refusal`, `op` (pure reset), `onRebirth(fn)`,
  `required`, `keptCount`, hook `SetRebirths`.
- `src/ReplicatedStorage/Shared/Config/Offline.lua` (MIN_AWAY_S 60, SEND_AT_S), `Config/Rebirth.lua` (REQUIRED, MAX,
  BAG_MULT_STEP, INCOME_STEP, POWER_MULT, INCOME_MULT, COOLDOWN_S 5, RESET, KEPT). Bag and Income already read
  `POWER_MULT` / `INCOME_MULT`; the rebirth screen reads `REQUIRED` and the steps.
- `studio/checks/Offline.lua`, `Rebirth.lua` (play mode), `BoughtScan.lua` (edit mode).

## What ran (Studio MCP, `studio` lock as `scripter-rebirth`, released)
Edit mode: `DevSync()` sync; CheckAll `install`, then `Offline` and `Rebirth` added to `TmpChecks` from the sync server.
Each row is one `run_script_in_play_mode` (start_play). Rebirth b ran twice: the first run had 2 FAIL from the check
itself (the second rebirth in the phase hit the 5 s cooldown, the right refusal); the check now waits it out.
Rebirth c's first run stopped at a static scan (a running server cannot read `Source`); that scan moved to `BoughtScan`.

| Gate row | Check / phase | Result | What it shows |
|---|---|---|---|
| S11 | Offline a | 20 PASS, 0 FAIL | no bosses: nothing; LeaveAt 30 s: nothing; 10 min: 600 x each pad's income (600 + 3,600), nothing paid by the summary; Collect pays exactly 4,200 earned, off the pads (pads before - after = paid), second Collect refused; [M9] a pad walked over first pays only what is left, a boss moved off its spot pays 0; 3 h: pad capped at 7,200 s (14,400 not 21,600), $100 already on a pad counts (7,100), it stays on the pad; 2 rebirths x2; cancel pays 0; Power untouched |
| S11 | Offline b | 9 PASS, 0 FAIL | the real path: Leave saves `leftAt`; ClockOffset +900; Rejoin: summary 900 s from the SAVED leave time, 1,802 (2/s; grant-to-leave seconds included); held for resend; Collect once; cash survives a second leave and rejoin; an immediate rejoin shows nothing |
| S12, S19 | Rebirth a | 21 PASS, 0 FAIL | RESET + KEPT name every schema key and `lock` once; the table; refusals with nothing changed: confirmed missing / "true" / 1, Power 9,999,999, carrying, a thief's lock on one boss [M5], 10 rebirths `max`; the rebirth: Power 0, Strength 1, Speed 1, shield 0, cash 50,000 with 5,000 bought -> 5,000; every kept key unchanged (zones {1,2}, 3 tickets, 2 charges, starterPackGiven, purchases, transferNote, nextUid, leftAt, flags, settings, version), rebirths +1; spin boss (spot 4) -> 1, pack boss (crate) -> 2, a bought boss stolen by a stand-in and stolen back -> 3, levels 7/3/9, marks unchanged, pads 0 from now; earned bosses and the stand-in's bought boss the player stole removed; income x1.5, bag x2, 11 spots; the store's record already holds it; a second request in 5 s `cooldown` |
| S19 | Rebirth b | 7 PASS, 0 FAIL | 15 own bought bosses, rebirth 2 with Extra Spots: 14 on 1..12, 16, 17 in order, the 15th in the crate, levels kept; bought-cash rule: buy 1,000, earn 500, spend 400 (earned first: 1,100/1,000), spend 300 (800/800), earn 200, rebirth -> 800; no bought cash -> 0 |
| S20 | Rebirth c | 8 PASS, 0 FAIL | grant: crate, `{ source = "pack", buyer = me }`; extra(q) in the same mutate; bad source, bad creature, an erroring extra: nothing applied; plain mutate cannot add, change or clear a mark or write boughtCash, `Session.set` refuses it; GrantBoss `bought=spin,buyer=-77,to=3` places with that mark; `to=head` with bought refused. The mark moving unchanged through `Session.transfer` is in Rebirth a |
| S20 | BoughtScan (edit) | 2 PASS, 0 FAIL | no c2s remote in Net names bought; no script outside `Data/` and `Systems/BoughtMark` (114 scanned) claims BoughtMark, builds a mark or assigns `.boughtCash` on the server |

Place left clean: CheckAll `cleanup` (TmpChecks and probe removed), 0 `HFB_` attributes, marker true, mode stop. Repo
scans after: `check_guard.py` 60 scripts, 0 without the guard; `check_skin.py` 0 hits.

## On-screen checks for the main session (UNVERIFIED until looked at)
1. Join with bosses placed and `HFB_LeaveAt = 600`: the "While you were away" panel opens within 2 s with "Away for
   10 min" and the total; COLLECT closes it and the cash plate rises by that amount; the pads show less cash.
2. Phone size: `HFB_SetPower = 12000000`, open REBIRTH, confirm twice: the panel closes, Power 0, own bought bosses
   (grant with `HFB_GrantBoss = "z1_t4,to=crate,bought=pack"` first) appear on spots 1.. at once.

## Not checked / for others
- A real Starter Pack or Spin grant through `BoughtMark` (M2-18 calls it); a real steal changing hands (M2-15).
- In a fight: the refusal path is in code (`Fight.get`) but no fight was started in the check.
- The rebirth celebration (Feel pass) and the rebirth star by the name (not built; brief "Reward").
