# M2-32 boss review line (animator-vfx, 2026-11-26)

Studio lock `animator-reviewline` held and released. Studio MCP, edit mode then play mode (play stopped, no hook armed, `RLResult`/`RLTest` leftovers removed). No computer use (subagent): on-screen items are UNVERIFIED until the main session looks. Nothing committed.

## Built
`studio/BuildReviewLine.lua` (re-runnable, place guard first, rebuilds from the current `Boss_*` models) puts `Workspace.ReviewLine` in the place: a plain floor (top y 100, z -400, x 122.8..289.2, so far from the strip z 0..956, plots and StudProof; one slab, no coplanar pairs), CLONES of the six bosses (tags removed, so no gameplay code sees them) in zone order left to right facing the viewer (+Z), an R15 and an R6 dummy at the right end, a name plate and a "now playing" plate per boss/dummy (BillboardGui through `Ui/WorldLabel`, studs only, `python tools/check_labels.py` 0 problems), a **GoPad** on the hub track beside the spawn, a **ReturnPad** and spawn spot at the line. Slots are sized per boss (largest bbox side + 0.7 H + 6) so moves clear neighbours.
Runtime, all Studio-only, source in `studio/review/`: LocalScript `StarterPlayerScripts.HFB_ReviewLine` + ModuleScript `HFB_ReviewLineDriver` (the loop), Script `ServerScriptService.HFB_ReviewLineGuard` (in a non-Studio server it deletes the line and the scripts; in Studio it does the two teleport pads). `studio/RemoveReviewLine.lua` takes everything out of the place (run before publishing). These instances exist only in the place (not in `src/`).
Loop per boss (through `BossMoves`): guard 3 s, idle, halfIdle (full length), hitGood, hitPerfect, hitBig, attack, gloat, lastHeart, defeat (holds its last pose through the break), carryRock 3 s, 1 s break after each, forever. Dummies: jab3, bigThird, flinch, carryHold (2 s, two turns), stealLift, knockdown, stun, 1 s break, gloves on (`Avatar.equipGloves`, client-side). Bosses all start together.

## Measured (play mode, driver run on a clone of the line, 60 s bosses / 40 s dummies)
- 11 moves each on all six bosses, in order, every one resolved. Gap between end of a move and the start of the next: min 1.000 s, max 1.018 s on every boss and both dummies. Move lengths match the brief (hitGood 0.15, hitPerfect 0.20, hitBig 0.30, attack 0.45, gloat 0.35, lastHeart 1.0, defeat 0.8; +0.02 frame lag).
- Dummies: all seven clips played on R15 and R6 (lengths 0.62, 0.33, 0.25, 2.0 looped, 2.0, 2.0, 1.5); gloves attached on both. A first run found the first lap's clips cut to 0.02 s while the tracks loaded; fixed (the driver waits for Length).
- Build checks: 6 bosses found, feet on the floor within 0.001, go pad overlaps nothing.
- Not seen: the client LocalScript itself (the console showed no client output through the MCP); it runs the same driver.

## Manager: get there and watch
1. Run Play (F5) in the place. You spawn at the hub; walk onto the yellow "Boss review line" pad beside the spawn (east side, on the track). You land 45 studs in front of the middle of the line, facing it.
2. Zone 1 is on the left, R15 and R6 avatars at the far right. Name plate on top, yellow "now playing" plate below each (the move name; "- break -" during the 1 s gap). Walk along the line; the yellow "Back to the game" pad returns you.
3. Give feedback with the boss name and the move name. The line plays in Play (and Run); in edit mode it is static.

## On-screen checks for the main session (UNVERIFIED)
1. Press Play, step on the GoPad: arrives at the line facing it. Both plates readable from 20 to 40 studs and shrink with distance.
2. Six bosses textured, in order, none clipping a neighbour's moves (drake, golem widest), feet on the floor, no flicker where parts meet.
3. Each boss cycles and the plate text matches what is playing; the 1 s rest pose between moves; defeat holds through its break.
4. Dummies play all seven clips, gloves visible; knockdown lies on the floor.
5. Stop Play: no leftovers; Output has no errors.

## Notes
- Re-import of the four bosses: run SetupBosses.lua, then BuildReviewLine.lua again (the clones are rebuilt from Boss_*).
- The teleport is a plain server pivot; M2-11's carrier over-speed pullback only applies to a carrier, so do not step on the pad while carrying.

## Fix pass after the on-screen look (animator-vfx, 2026-11-26, lock `animator-reviewline`)
1. **Plates stuck on "starting..." (root cause found).** The launcher LocalScript kept the place-guard first line. On a real client it runs before `Workspace.HussForBosses` has replicated, so the guard errored and the launcher died; the driver itself was fine (a probe that required and started it on the client changed the plates). `BuildReviewLine.lua` now strips the guard line from the three runtime copies (they gate on `IsStudio()`); the build script and `studio/review/*.lua` sources keep it (`check_guard` clean). Proof, real client in play mode (`studio/checks/ReviewLineProbe.client.lua`, client reads every plate and fires it to the server): at 5 s all six bosses `guard`, R15 `bigThird`, R6 `- break -`; at 15 s all six `halfIdle`, R15 `knockdown`, R6 `- break -`. Probe, RemoteEvent and attributes removed afterwards; play stopped.
2. **Plates above the figures.** Name plate and "now playing" plate now sit directly above each figure: plate bottom 1.1 to 4.5 studs above the highest point of its boss (bbox top + 0.25 H + 1; the golem's halo included), nothing in front of any boss. Dummies the same.
3. **Facing.** Every boss and both dummies have LookVector +Z (read on the server in play mode), the landing spot is at +Z of the line, so all face the viewer.
