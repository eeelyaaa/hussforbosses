# M2-16: wave B client: steal, shield, watchers, respawn (scripter, sonnet, 2026-11-26)
Pass: Function. Files: `Controllers/Steal.lua`, `Shield.lua`, `Watchers.lua` (new, AUTO_START), `Main.client.lua` (thief routing + "start" look), `-- stream-ok` markers on three Plots lookups (Shield, Steal, StealAlert:361; `check_streaming.py` 0). Probe: `studio/checks/StealClient.client.lua`. Nothing committed.

## Built
- Steal: nearest placed boss of another plot within 6 studs (shield not up, not carrying, no fight) -> Prompts.showSteal; hold E / X / the plate sends HoldStart, bar fills (server holdEndsAt), stealLift clip stretched to the hold; release or moving off sends HoldCancel; locked flag greys it; stagger slows the thief x0.5 for 0.5 s; owner: Steal.Alert tracks the thief, Huss within 8 studs sends OwnerPunch (single huss + one jab, 0.8 s gap).
- Shield: Q / Y / tap on the HUD plate raise (inside own base only); Break prompt within 15 studs of another plot's edge while its shield shows; LockBoard show/hide at the board; cyan pad and entrance gate.
- Watchers: Punch.Burst (jab on their character, spatial voice at 0.4x, two voices max, boss reaction in fights one per 0.3 s per boss), Fight.Watch if sent, Steal.Punch clips, respawn while carrying (arms follow state, clips stop).

## Ran (Studio MCP, `studio` lock as scripter-stealclient, released; play mode client probe, one real client, lines via Profile.TestReport)
Probe 20 PASS, 0 FAIL: prompt up and enabled, greyed when flagged, no hold from a greyed press, hold sends and shows the bar, server refusal clears it, bar follows holdEndsAt (0.42 at about 1 s of 2), 'carried' ends it, stagger halves and restores WalkSpeed, thief in reach, first punch sent and the one inside 0.8 s swallowed, no thief = tap goes on, raise only inside the own base, HUD plate tap exists, own Burst ignored, Steal.Punch clip, voices built (4), respawn seen, carry none, hold and stagger clear. First run 2 fails were in the probe (a server refusal cleared the c1 hold; a stats table compared by reference), fixed. Probe removed, no hooks left. Repo scans: check_streaming 0, check_guard 0, check_skin 0, check_labels 0 problems. Noted, not mine: `Systems/Receipts` parse error at line 69 in play (M2-18).

## Owed, UNVERIFIED (main session, two clients, Test > Clients 2)
1. B holds E on A's placed boss: bar fills 2 s (1 s Quick Hands), lift clip; A sees the alert, B the thief strip; A runs up and taps Huss: single huss, jab, B drops the boss and stuns (stun clip) 1.5 s; A's punch seen on B's screen (jab, huss, stun).
2. Iron Grip on B: first hit staggers (slow 0.5 s), second within 10 s drops.
3. `PolicyTrading` = `<B>:off`: greyed plate, E does nothing.
4. A bursts on a boss pad while B watches within 150 studs: A's jabs, quiet voice, boss reacts (not every beat), at most two watcher voices.
5. A raises the shield (Q, plate tap on a phone, the pad): cyan pad and gate seen by B; B within 15 studs gets Break prompt, greyed reasons; B pushed out.
6. Respawn while carrying (reset on a boss run and on a stolen boss): no stuck arms or ghost boss, Carry state none.
7. Huss button "start" look beside a thief on a phone; every action by gamepad.

## Update 2026-11-26: server-side stagger slow
Steal.lua no longer touches WalkSpeed. `Carry.State.slowSpeed` (sent while the server's slow runs) only sets the stagger look (a flinch clip on the rising edge). Probe rerun under the studio lock: 21 PASS, 0 FAIL (d1/d2 now: slowSpeed marks the look and WalkSpeed stays 16; clears when gone). Probe removed, lock released. check_streaming 0.
