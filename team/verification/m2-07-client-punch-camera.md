# M2-07: client punch (P3), fight camera (P4), one defeat, input path (scripter, 2026-11-25)
Probe: `studio/checks/ClientPunch.client.lua` (installed as StarterPlayerScripts.HFB_ClientPunchProbe, removed after). Studio MCP, `studio` lock held and released. Server (M2-06) was NOT yet updated: Config still had M1 bag windows 110/45 (RING_GRACE_S read as 0.15 fallback; RING[1] read 1.05 so Config had M2 RING). The server side of untimed was not tested here.

## Changed (game repo)
Ring.lua (untimed grade, grace, spent ring, next ring at landing+0.61, `Ring.setSinglePunch`, view `landed("untimed")` + optional `setSpent`), Main.client.lua (single huss, one jab, bag Power pop), Fight.lua (boss hit on untimed; one defeat), Config/FightCamera.lua, TestClient.lua (AutoTap `untimed`, `mash`), studio/checks/ClientPunch.client.lua.

## Results (play mode, real client)
- Grace tap (r0+0.04): ignored, no report. Untimed (keyboard, r0+0.30): grade untimed, phase spent, 1 report, single huss +1, 0 burst beats. Second tap in spent ring: ignored. Next ring opened at landing+0.610 (cause untimed). PASS
- Perfect via button source: burst; next ring gap 0.610. Untimed via gamepad source: untimed. Good via touch source (+70 ms): good. No tap: miss. PASS
- Routing (`Input.route`, the handler's own function): F, ButtonR2, MouseButton1 -> punch; E -> interact; Backspace -> run. PASS
- Win: BossMoves.play calls hitPerfect, hitPerfect, defeat = 1 defeat (was 2). PASS
- Camera, Chomp Frog (box 7.3x3.8x3.1, stood 4.49): 874x402 box u .41-.62 v .29-.84, avatar u .29-.40 v .43-.81 (h .39), overlap 0%; 640x300 box u .44-.64 v .32-.82, avatar u .34-.43 v .44-.79; 1280x720 box .40-.66 / .31-.85, avatar .27-.39; head never covered; real camera 0 corners off screen. Camera 10.7 studs. PASS (numbers)
- Fight untimed: grade untimed, ring waits; player walks after Run (WalkSpeed 16).
- Note: place had `HFB_ForceSkin = stub` set by someone else; run with brickbrawl for sound, restored to stub after.

## Limits
- Real key/mouse/touch events can not be injected (VirtualInputManager needs RobloxScript capability): sources go through `Input.fire`, routing through `Input.route`. UNVERIFIED: a real F key, left click, right trigger, and a finger on the button.
- Old checks using AutoTap `early` now hit the untimed rule (a tap 0.5 s before landing is untimed at Speed 1); M2-28 should drop or redo that mode.

## On-screen checks owed (main session)
1. Phone 874x402 and desktop: at Power 25 step into Chomp Frog's ring, press Huss. Expect avatar whole, about 40% of screen height, centre-left; frog right of it about half the screen height, head clear; Huss button (lower right) clear; overlay on top clear. Judge the angle (higher, 65 degrees).
2. A big boss: avatar smaller still, boss in the same place.
3. Click Huss untimed on the bag: one punch, single huss, small pop, ring dims only if M2-08 adds setSpent; next ring on rhythm.
4. Real F, left click, touch, gamepad right trigger each punch.

## Follow-up 2026-11-26: Speed 10 Good "skipped ring" (M2-26 FAIL): not a client bug, no code changed
Measured (real client, AutoTap good, Speed 10, bag, 36 s, `ring` reports): every ring after a Good opens exactly 0.610 s after the burst (cause burst, gap 0.61), tap at landing + 63 ms (dMs 62 to 65, a few 78 to 79 on a slow frame), ring numbers n continuous 2 to 34, no Miss, no ignored tap. Ring-to-ring spacing 1.08 to 1.09 s, never 1.53 s. The two ring numbers missing from the reports (12, 15) sit between neighbours exactly two cycles (2.19 s) apart: the ring happened, its TestReport was not delivered.
Cause of 3.665: the stand-in Good taps 70 ms after landing, so the tap-to-tap cycle is 0.61 + 0.41 + 0.07 = 1.09 s, 4 / 1.09 = 3.67 Power/s. 3.92 = 4 / 1.02 assumes the tap AT landing (that is the Perfect cadence). A Good tap late in the window costs its lateness each ring by design (burst length counts from the tap, contract D). Server rules and P2/P3 numbers untouched. Fix belongs in `Curves.lua`'s expectation for Good (3.67 at Speed 10; Speed 1 Good: 4/1.73 = 2.31 on +70 ms), or tap Good at landing + 0.0 with a window-edge offset of the designer's choosing; the client is correct.
Lock `studio` released; background lock loops stopped.

## Follow-up 2026-11-26: FightCamera a and b, patrol-aware (gate S24)
Result: **set a 16 PASS / 0 FAIL, set b 16 / 0** (Studio MCP, direct driver identical to GateRun's `fightCamera`; lock released, probe removed, 0 HFB_ attributes left by me).
Causes found, three:
1. The probe used the tagged boss (the static template, always at the ring centre), not the patrolling clone `pad.Boss`; its spots and its framing were measured against a boss that was not the one on screen. Now it waits for `pad.Boss` (what `Fight.bossOf` returns).
2. Spots were offsets from the ring centre. Now each is an offset from the boss's live centre taken at the moment of use (press-on-entry walks at the live centre, re-aiming); a refused press is repeated up to 3 times (what a player would do), a `note` line says so.
3. **Real client bug (mine, M1):** `Fight.inStartRing()` measured from the static ring centre, while the server tests `Fight.Start` against the boss's live patrol position. Standing at a patrolling boss 14 studs from the ring gave no Huss "start" mode and no prompt. It now measures from the pad boss's live position (the ring centre when it has none).
4. **Real camera finding:** with the boss near the lane's end the server's fight spot leaves the avatar 3.5 studs from the boss (a raycast hit behind it), and the usual 65 degree side angle put the avatar over 20 to 25% of the boss box at 874x402. `Fight.frameBoss` now turns the camera further round (8 degrees at a time, up to 90) while the avatar covers more than 4% of the boss's screen box (`AVOID_OVERLAP`, `SIDE_STEP`, `SIDE_MAX` in `Config/FightCamera.lua`). Normal spots are untouched (set a unchanged at 0% overlap); the close ones now read 0% overlap, avatar u .35-.43.
Measured numbers (874x402): box u .43-.63 v .31-.85, avatar u .28-.40 v .45-.84 (about 0.4 of the height), overlap 0%, head clear, Huss button and overlay clear, 0 corners off screen; same at 1280x720 and the real 1235x481 viewport.
On screen still owed: a boss at the lane end (close fight spot) at 874x402, to judge the extra side turn by eye (O1).
