# M2-09: data layer verification (data-engineer, opus, 2026-11-25)

Studio MCP, lock `studio` as `dataeng-save` (released). Edit mode: `DevSync()` sync, then
`DevSync.run("checks/Saving.lua")` installs `ServerStorage.TmpChecksData.{Saving, SkinCheck3}`; each phase is one
`run_script_in_play_mode` (start_play). All records were in the Studio check store `HFB_Studio_PlayersCheck`
(stand-ins in the memory store); the test player's normal Studio record was only left and re-joined. Place left
clean: `TmpChecksData` removed, 0 `HFB_` attributes (ForceSkin disarmed), marker true, mode stop. Nothing committed.
Repo scans after: `check_guard.py` 47 scripts, 0 without the guard; `check_skin.py` 0 hits.

## Results (final runs)
| Gate row | Phase | Result | What it shows |
|---|---|---|---|
| S15 | Saving a | 50 PASS, 0 FAIL | load takes the lock (per-server GUID, S1); save, leave (lock released), rejoin = the same profile; second session refused `locked`, record untouched; protected fields (boughtCash, zonesBeaten, purchases, nextUid, transferNote, starterPackGiven, version, bought marks) refused by mutate and set, BoughtMark token allowed; fn error, NaN, inf, out-of-range level, a name instead of an id refused with nothing applied; `boughtCash <= cash` after set/spend/mutate (M1); `setZonesBeatenForTest`; saved record holds ids only (scan against brickbrawl Names); autosave writes and renews the lock; shutdown path (called directly and through the `Shutdown` hook) saves in 0.33 s and releases; ForceSave, Leave, Rejoin hooks |
| S15 | Saving b | 20 PASS, 0 FAIL | foreign live lock: temp profile, not saving, record untouched, receipt `retry`; lease end: real profile swapped in by the background retry (S2); load error: temp, record untouched, background retry loads it; failed save: false, still saving, record unchanged, next save writes; receipts: granted once with the id in the same write, same id `already`, failed write `retry` with the live profile unchanged then granted once, an erroring grant `retry`, a receipt while leaving `retry`, purchases kept after rejoin (M3) |
| S15 | Saving c | 9 PASS, 0 FAIL | v1 -> stand-in v2 (new field `testField`, `leftAt` renamed `leftAtV2`) on load, written back in the load's write; back on v1 code the v2 record gives a temp profile and is never written (M10); a record with a missing step gives a temp profile, nothing written |
| S14 | Saving d | 20 PASS, 0 FAIL | transfer by uid real player <-> stand-in: owner then thief written, uid in exactly one record and one profile, owner's `transferNote`; `SaveFailBetween` errors between the writes, one-shot, uid in exactly one record after both reload; owner write fails: the uid stays out of the thief's saves (M6) until the owner's write succeeds; stolen back: the old note is removed and the boss kept after reload; thief leaves while pending and the owner's write fails: boss back in the owner's profile, one record |
| S23 (part 3) | SkinCheck3 save / load | 5 + 7 PASS, 0 FAIL | a record saved under brickbrawl (6 bosses, one per zone, a crate boss, numbers, flags) loads unchanged in a session running the stub (`[HFB] server up: ... skin=stub`), every saved id resolves in the stub's Names, and a save under the stub writes the same record |

## Fixed during the runs
- `spendCash` / `set("cash")` lowering `boughtCash` was refused as a protected change (first run of a: 2 FAIL); the
  bought-cash rule now may lower `boughtCash` to `cash` without a claim.
- Check fixes only: b's fault count took the raw read's turn; receipt ids made unique per run (the check store keeps
  the last run's ids, so the second run saw `already`, which is the right behaviour); Saving waits for `Remotes`
  before its fallback start.

## Seen, not ours (reported, not fixed)
- First play run: `ReplicatedStorage.Skins.brickbrawl.Names:141: Malformed string` (a literal newline inside
  `confirm.sellText` / `boughtLine`, a file another task was writing at 23:15). Main.server did not start; the
  Saving check started Net + Session itself and printed a FAIL line. The file was fixed by its owner before the
  final runs.

## Not checked / needs the manager
- `Profile.Settings` handler (c2s): not fired from a client in these runs (needs M2-13's settings screen or a
  client probe). `UNVERIFIED`.
- Real `BindToClose` on a Studio stop, two live servers racing for one lock, and a real server crash: published-build
  items for the two-device checklist (M2-02 test plan 5 and 6).
- The `notSaving` notice reaching the client (the play-mode call returns the server log only).

## Follow-up 2026-11-26: the transfer crash window closed, plot fill order (M2-15 request)
Lock `studio` as `dataeng-save` (released); place clean after (no `TmpChecksData`, 0 `HFB_` attributes, mode stop).
- **Design** (`Data/Transfer.lua`, `Session.lua` load; TEAM CALL M2-09-9): the owner keeps its write order (owner
  first, then thief; M6 unchanged). The owner's "left" note now carries the boss and the id of the server that made
  the move: `{ uid, to, server, entry }`. The thief's record gets an arrival note `{ uid, from }` in the same write as
  the boss. On every load, before its UpdateAsync, the owner reads the thief's record for each note that still has an
  entry. If the boss or its arrival note is there, the entry is dropped. If it is not there and no live session of the
  moving server holds that record, the boss comes back to the owner's crate. Otherwise (the moving server is still live
  and may still write it) the note waits for a later load. Arrival and departure notes are trimmed to 20 each.
- **Saving d: 28 PASS, 0 FAIL** (was 20; 8 new). d6: a crash after the owner's write leaves no record holding the
  boss and the owner's note carrying it; after both reload: exactly one record and one profile (the owner's). d7: the
  same, thief loads first: still one. d8: crash after both writes: one (the thief's). d9: the owner rejoins in the
  moving server while the thief's write is pending: not restored (no copy); after the thief's write and the owner's
  next load: one. Crash = `Session._test.crash` (no writes, no releases, then a new server id). **Saving a: 50 PASS, 0
  FAIL** re-run after the change.
- `Session` `assignPlot` now uses `Systems/Plots.pick` (fill order 1, 8, 4, 5, 2, 7, 3, 6), with the lowest free id as
  a fallback if Plots fails to load. Only Plot1 exists in the place, so the order itself was not exercised here (M2-15's
  check covers `pick`).
- Seen, not ours: `ServerScriptService.Systems.Receipts:69: Expected identifier when parsing expression, got '?'`
  (M2-18's file; Receipts failed to start in these runs).
- For M2-15's Steal c item 3: its label "the known window" is still true for raw bosses lists (0/0); the boss is now
  held in the owner's note and restored on the owner's load.

## Follow-up 2026-11-26: "Session shutdown: 1 players, 0 saved, 1 failed" on a Studio Play stop
Lock `studio` as `dataeng-save` (released); place clean after (no `TmpChecksData`, 0 `HFB_` attributes, mode stop).
- **Cause (in `Data/Session.lua`, a counting bug, not a lost save):** a Studio stop runs `PlayerRemoving` and
  `BindToClose` together. `PlayerRemoving`'s leave was already saving, so BindToClose's leave for the same player
  waited for it and returned `"already"`, and the shutdown counted anything other than `"saved"` as failed. The
  0.4-0.6 s in the log is that one save. The Receipts parse error was not involved.
- **Fix:** the second leave now returns the first leave's final status (`S.finalStatus`), and the shutdown log line
  lists each player's status (`... (28683760=saved)`).
- **Checks:** `studio/checks/PlayStop.lua` covers the real path: edit mode arms a random Power, a play session sets it
  and returns without saving, the MCP stops play, and edit mode reads `HFB_Studio_Players/player_28683760` (UseCache
  false): **power 167683.25 = the armed value, lock null: PASS**. A same-time leave + shutdown in play counted
  `players=1 saved=1 failed=0`: PASS (now Saving a10). **Saving a: 51 PASS, 0 FAIL.**
- Studio-script switch `HFB_PlayStopValue` (read only by `studio/checks/PlayStop.lua`, cleared by its read step):
  M2-01 should add it to `test-hooks.md` "Studio-script switches".

## Follow-up 2026-11-26: M2-27 MF1 (a stale transfer note could restore a boss the thief already sold)
Lock `studio` as `dataeng-save` (released); place clean after (no TmpChecks or TmpChecksData, 0 `HFB_` attributes,
marker true, mode stop). Scans: `check_guard.py` and `check_skin.py` clean.
- **Fix (TEAM CALL M2-09-10).** (1) When the thief's write that carries the uid succeeds, the owner's live note loses
  its `entry` at once (`Transfer.landedSnapshot` / `onLanded`), and the owner is written. So in every steal where the
  owner is still online, the boss can no longer be restored. (2) Arrival notes `{ uid, from, at }` are kept by age, not
  by count (`Config.Data.ARRIVAL_KEEP_S` = 60 days, safety cap `ARRIVAL_MAX` 500). Resolved "left" notes still keep the
  newest 20, and a left note that still carries its boss is never trimmed. (3) A left note that still carries its boss
  and is older than `ARRIVAL_KEEP_S` resolves to "drop", never to a blind restore.
- **Saving d: 34 PASS, 0 FAIL** (6 new). d10: the thief's write clears the owner's live note and record; the thief
  sells it and takes 21 more; the victim reloads: not restored, uid in 0 records. d11: the owner leaves before the
  thief's write (its record note still carries the boss); the thief writes, sells it and takes 21 more from another
  stand-in; the owner reloads: not restored (the arrival note is kept by age) and the note is resolved. The crash cases
  d6 to d9 still give exactly one record. **Saving a: 51 PASS, 0 FAIL. Steal c (M2-15's check; it stubs
  `Shop.setPromptFn` and forces passes off with `PassOwned` itself): 8 PASS, 0 FAIL.**
