# M2-21: first-session arrow and the 12 funnel events (scripter, 2026-11-26)

Status: **PASS 28/0** (play mode, 2026-11-26, phase all). On-screen checks below still owed.

## Built
- `src/ServerScriptService/Systems/Funnel.lua`: saved once-guard (`profile.flags[name]`, one `Session.mutate`, sent in `Profile.Changed`, kept through rebirth by `Config.Rebirth.KEPT`); marks `Joined` on `Session.onJoin` and, in Studio, after the Wipe hook. API unchanged (`mark`, `has`, `start`).
- Who marks the rest (already wired by their owners, verified by grep): FirstBagPunch and FirstPerfectLanded `Punch`; ReachedFirstBossPower and FirstStrengthBought `Bag`; FirstFightStarted and FirstBossBeaten `Fight`; FirstBossPlaced and Zone2BossPlaced `Base`; FirstCashCollected `Income`; FirstBossUpgraded `Upgrades`; StarterPackShown `StarterPack.offerSeen` (on the client's `Shop.OfferSeen`).
- `src/StarterPlayer/StarterPlayerScripts/Controllers/Arrow.lua` (AUTO_START) + `Config/Funnel.lua` (ARROW numbers in studs/seconds) + an "arrow" report in `TestClient.setProbes`.
- `studio/checks/FirstSession.lua` (replaces M1's timing script; phases a, b, all).
- Repo scans: `check_streaming.py`, `check_labels.py`, `check_guard.py`, `check_skin.py` clean.

## On-screen checks owed (main session)
1. Fresh profile: yellow arrow bounces over the own bag pad at spawn; moves to Chomp Frog's pad at 25 Power; points at the own spot 1 while carrying; cash pad after placing; the boss after collecting; gone after the first upgrade.
2. The Starter Pack screen appears once, only after the boss panel is closed.
3. The arrow reads at phone size and shrinks with distance (Look pass: art-director).

## Run
The `studio` lock stayed with M2-20 (screens C) with M2-11b queued ahead for the whole session, so nothing ran in Studio. To run: sync `src/`, `CheckAll` mode `install`, add `studio/checks/FirstSession.lua` as `TmpChecks.FirstSession` (wrapped `return function(...) ... end`), then one play call `require(game.ServerStorage.TmpChecks.FirstSession)({ phase = "all" })` (split a / b if it times out). UNVERIFIED: gate row S21.

**Result (lock acquired later, `scripter-funnel`, released):** `FirstSession` phase `all`: pass=28 fail=0 (one fix to the check itself: wait for the live profile before the Wipe). Real client taps, fight and arrow reports; teleports for walking; prompt stub on; Starter Pack pass forced off with PassOwned. Order: Joined, FirstBagPunch, FirstPerfectLanded, ReachedFirstBossPower, FirstFightStarted, FirstBossBeaten, FirstBossPlaced, FirstCashCollected, FirstBossUpgraded, StarterPackShown, FirstStrengthBought, Zone2BossPlaced, each once; arrow steps bag, boss, home, cash, upgrade, then destroyed; offer sent once; flags saved, kept through Leave/Rejoin and rebirth. Scripted times (s, income clock jumped): 0,2,2,3,3,8,9,10,10,12,13,14 (a floor, not a human). TmpChecks and probe removed, HFB_ attributes cleared.
