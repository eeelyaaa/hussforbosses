# M2-29: stub-skin CoreLoop rerun and skin check parts 1 and 2 (scripter, 2026-11-25)

Task: re-run after any change under `Skins/` (`team/requirements/m2-carryover.md`, "Re-run the stub-skin CoreLoop calls").
No code changed. Studio lock `scripter-stubskin`, released after the run. Play mode stopped (get_studio_mode: stop).
Model: Haiku 5.5 (lookup-and-run task).

## Result
- Skin check part 1 (repo scan, `python tools/check_skin.py`): 0 hits, 0 files that do not lex (51 files).
- Skin check part 1 guard (`python tools/check_guard.py`): 30 studio scripts, 0 without the guard.
- Skin check part 2 (Studio, `CheckSkin` run in `prepare`, then `arm` with `HFB_ForceSkin = stub`): **FAIL**, 12 passed, 1 failed.
- CoreLoop under the stub skin: a 22/0, b 36/0.

## FAIL lines (verbatim, from the prepare run and repeated in the arm run)
```
CheckSkin: FAIL B  brickbrawl and stub have the same key shape (1 differences)
CheckSkin:   shape: brickbrawl has Tokens.stud.worldColorBakedMapId, stub does not
CheckSkin: FAIL, 12 passed, 1 failed
```
Not a rule break in play. It is a new key, `Tokens.stud.worldColorBakedMapId`, in `Skins/brickbrawl` that the stub
skin lacks. M1-16 and M1-26b recorded B as PASS, so this came from a change under `Skins/` after M1-26b. Owner: whoever
added the key (the art / skin owner). Not fixed here, per the task. The fix is either to add the key to `Skins/stub`
or to remove it from the brickbrawl skin.

## Checked (CheckAll flow: prepare, arm, CoreLoop stub a and b, disarm, cleanup)
- CheckSync (prepare, edit): 8 PASS, 0 FAIL (from the prepare run's console; DevSync 66 files, 5 updated, 64 modules swapped).
- CheckSkin Studio parts A-E (prepare): 11 PASS, 1 FAIL (B above). A1 stub has every M1 key, A2 brickbrawl has every M1 key: PASS.
- CheckSkin part 2 (armed, `HFB_ForceSkin = stub`): the server printed `[HFB] server up: env=Studio skin=stub`; both CoreLoop runs
  reported `server skin is stub`.
- CoreLoop/a stub: TOTAL pass=22 fail=0.
- CoreLoop/b stub: TOTAL pass=36 fail=0 (full fight at r 1.0 fair 110/45 ms, win on burst 3, carry at speed 12, drop by LogForce hit,
  regrab, place on spot 1, a second place refused `taken`, ClockOffset +30 pad read `$30`, cash 0 -> 30).
- Refusals live (prepare, edit): 6 PASS, 0 FAIL.
- Cleanup read back: 0 `HFB_` attributes on Workspace, `HFB_ForceSkin` nil, no TmpChecks, no CheckProbe, marker true.

## Not run (out of scope of this task)
- The seven non-stub play calls of the full CheckAll gate (CoreLoop brickbrawl a/b, Refusals a/b, BurstValues a/b, NoDelay a).
  The task asks for the stub-skin CoreLoop calls and skin parts 1 and 2 only. Run the full gate for a release check.

## Not checked / needs the manager
- Nothing on screen was looked at (computer use is the main session's; no look was asked for here).

## Re-run: stub creature keys (scripter-stubcreatures, 2026-11-25)
Task: add `creatures.z2_t2` to `z6_t6` to `Skins/stub/Models.lua` (same nested keys as brickbrawl, placeholder values: model `Boss_zN_tN_stub`, bodyType 2, heightStuds 4, groups with 0s, textureId 0). Brickbrawl not edited. Studio lock `scripter-stubcreatures`, released after the run. Model: Haiku 5.5.

Result: CheckSkin **PASS, 13 passed, 0 failed** (latest run: sync 0 updated, B 0 differences, A1/A2 PASS, C1-C3, D1-D3, E1-E3 PASS). Part 2 armed only, not played.

Note: the first FAIL block on the console came from an earlier sync, before the stub edit was synced. It is not the result of this re-run. Earlier FAIL B (1 difference, `Tokens.stud.worldColorBakedMapId`) is no longer reported.

Not checked: stub `clips` gained `flinch`, `carryHold`, `stealLift`, `knockdown`, `stun` (both clips and clipsR6) in the file on disk. Another agent made that change; the sync shows it matches brickbrawl. Not edited here.
