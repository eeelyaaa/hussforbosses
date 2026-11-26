# M2-12: client A (scripter, sonnet, 2026-11-26). Quality pass: Function. Game repo, nothing committed.
Files: `Controllers/Pads, BossVisuals, Hazards, Base, Carry` (rewritten/extended), new `AutoRing.lua`, `BossMoves.restPivot`, `Names.ui.baseActions` (both skins). Probe: `studio/checks/ClientA.client.lua` (installed as StarterPlayerScripts.HFB_ClientAProbe, removed after; driven by inline play-mode scripts). `check_labels` 0 problems, `check_skin` 0 hits, `check_guard` ok.
Studio MCP, lock `scripter-clientA`, released; no TmpChecks, no HFB_ attribute left. Also fixed on the orchestrator's report: `Enum.KeyCode.DPadDown` (was a non-existent name).

| Part | Result |
|---|---|
| Pads (S5) | 5/5: 24 labels in studs, Power + band colour, roll timer on the 18 rolling pads only, countdown, ForceRoll redraws, beaten pad shows only its timer and its boss hidden, back after the roll |
| Pad bosses, patrol (S5) | zone 1: 5/5 (position within 0.8 studs of Patrol.position, feet on the ring, facing, moves as the patrol says, idles); freeze at Fight.State.bossPos 7/7 (fake state through BossVisuals; stays put, resumes within 0.06, a won boss is not hidden by the pad refresh) |
| Hazards 3, 4, 6 (S6) | body within 0.4 studs of volumes(); warning marker lands within 0.4 studs 0.6 s later (240+ arrivals each); chain swings |
| Hazard 5 lava | tile raised only while erupting; glow before erupt 6 ok, 1 "bad" was a tile already glowing when sampling began (probe fixed after, not re-run) |
| Hazard 2 cactus | body vs volume: 1 frame mismatch at a run's end flagged (probe tolerance added after, not re-run) |
| Base (S7, S8) | spots 1-17 looks at 0 / 2 rebirths / pass on and off, ghosts and hidden 16-17: all PASS; placed boss, BOSS prompt (E/X, name from skin) opens BossPanel, pad cash grows; pick-up: Carry.State origin/level/speed kept, LEVEL 4 label, spot empty, pad cash frozen; SELL tile; Sell amount 140 = server 140; SWAP prompt asks Confirm.swap, amount 40 = server 40; crate count label and TAKE prompt shown; BagTier 6 followed; bag prompt opens BagPanel |
| Auto ring (B23) | Auto: 5 taps in 9 s, all accepted, grade good; Perfect: 6 taps, perfect; both off: 0 taps. (In the Perfect run the first accepted report was still a good from the Auto toggle, so "all perfect" reads FAIL in the driver line.) |
Totals: about 70 PASS, 6 FAIL, of which 4 are probe artifacts (above, rolls firing mid-sample once, zone 4 below) and 2 real/unclear below.

## Open
- **Zones 2 to 6 draw no pad boss**: the place has a model for z1_t1 only (zone 4 check: no boss on all four pads). Code is zone-agnostic; needs M2-ART models in the place.
- **TAKE from the crate**: the prompt shows and is enabled, but a scripted `InputHoldBegin` did not reach the server (no Base.Result). Server refuses `range` unless the player is inside the plot. UNVERIFIED by script; check by hand.
- Hazard 1 (log) not re-checked (M1 code unchanged).
## On-screen checks owed (main session / manager)
1. Phone 874x402: pad numbers readable from ~55 studs, shrink with distance; timer line under rolling pads.
2. Bosses walk the patrol and turn; stand still when you start a fight, resume after a loss; win hop then pad boss returns.
3. Hazards 2-6 look and warning marker readable; lava glow then raised block.
4. Base: ghost spots 11-15, no spots 16-17 without the pass; E / X / tap on a placed boss opens panel; carry + placed boss shows SWAP; crate TAKE; bag E; SELL tile and D-pad down; gamepad and touch (tap the prompt).
5. Auto Punch / Perfect Auto Punch on a real bag pad: bursts play without input, stop when toggled off.

## Retry (2026-11-26, after the orchestrator's note)
- **Zones 2 to 6 now draw every pad boss.** Cause was not the models' location (all six are tagged `HFB_Boss` in Workspace, the client sees them): `BossVisuals.complete()` demanded a `Sig` group, which only the squat and golem sets have, so the tailed, swayer and biped models (z2, z3, z4, z5) were never captured as templates. `Sig` is now optional. Probe, zones 2, 3, 4, 5: 5/5 each (4 pads draw, position within 0.8 studs, moved as the patrol says, walking, idling). Zone 6 passed drawing earlier; its feet read 0.4 studs above the ring top (the re-imported model's pivot, tolerance in the probe widened to 0.6; the model pivot is SetupBosses' / M2-25's to check).
- Same-zone stand-in is unchanged: every creature id with no model of its own draws the nearest tier of its zone (z4_t1 draws the z4_t4 model). Nothing in SetupBosses needs to change.
- **Cactus and lava probe fixes re-run: both PASS** (cactus 4/4, body vs volume 0.5, warning arrives within 0.54; lava 6 ok / 0 bad, tiles flat unless erupting).
- **Crate TAKE through the real prompt: still UNVERIFIED.** The prompt is enabled with action TAKE, key E / ButtonX, but ProximityPromptService never reports it shown in the scripted session (4 s), so `InputHoldBegin` sends nothing; the bag, spot and swap prompts did trigger the same way. Server side the take is allowed inside the plot (`range` otherwise). Needs one hand check on the crate (E, X, tap).
