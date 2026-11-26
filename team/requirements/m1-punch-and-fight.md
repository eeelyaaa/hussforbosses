# M1: punch, bag, Power and Chomp Frog's fight (server M1-06, client M1-07, controls)

Build to `m1-contract.md` sections C, D, E, H (events to moves), I (`Input`), K, L. Quality pass: **Function only**
(M1 is the proof slice; Friction, Feel and Look run at M3 to M5 with everything else).

## The brief (the manager's words, and the pack's rules they became)
"Stand at your bag and tap once as the timing ring lands: the avatar throws three jabs to my huss huss huss"
(brief, "The idea"). One graded tap, a burst of three punches at 0, 0.213 and 0.401 s, 1 + 1 + 2 punches, x2 on a
Perfect; ring 1.20 s at Speed 1 to 0.50 s at Speed 10; Miss = no burst, ring restarts after 0.61 s; windows 45/110
ms on the bag (brief systems 1 to 4). Bag adds Power; fights: health 10 x boss Power, 3 hearts, band by r, damage
at the three beats, a Miss costs a heart and the boss answers; Run ends it; a loss costs 2 s down and a 5 s
cooldown on that pad. The server decides every result; the client is believed only for grade and tap time, bounded.

## Goal and player outcome
A player on their bag pad taps once as the ring lands and gets three punches; Power rises; at 25 Power they step
into Chomp Frog's ring, press Huss, fight it with the same ring, and win or lose by the brief's rules.

## Tasks
- **M1-06 scripter (opus), server.** `Systems/Punch` (schedule, validation, the Heartbeat beat queue, rate limit,
  stall rule), `Systems/Bag` (own-pad test, Strength value from `Config.Bag`, Power), `Systems/Fight` (r and band at
  start, health, hearts, win and loss, B22, knockdown, cooldowns, pad return after 10 s), `Systems/Zones` (the
  fixed pad's creature and Power, `Zones.Pads`, `Zones.PadBeaten`, `Zones.Clock`), `Data/Session` (K),
  `Main.server.lua` wiring and plot assignment (first player gets plot 1; the character is moved to
  `Plot1.SpawnPoint` facing the bag), the test hooks it consumes (`SetPower`, `SetCash`, `SetStrength`, `SetSpeed`,
  `Wipe`, `PadFastBack`, `ClockOffset`, `Profile.TestReport` receiver). Every c2s remote validates type, range,
  rate, state, distance (roblox-networking skill); a bad payload is dropped and counted, never an error.
- **M1-07 scripter (opus), client.** `Controllers/Input` (all three inputs, `docs/controls.md`), `Ring` (section D),
  `BurstClock` (section D, the API and log), `Fight` (starts a fight from the Huss button in a ring, the fight
  camera frames the boss and stays put, the player is held in place (**B13, TEAM CALL**: set `WalkSpeed` and
  `JumpPower` 0 on the client plus the server freezing the character's movement for the fight, released on end),
  wires fight events to `BossMoves` and the overlay), `TestClient` (`AutoTap`, `ForceInput`, `FrameCap`,
  `ReportBeats`). Reads `Ui/*` through the section I interfaces: if M1-08 has not landed, writes against the
  interface and the orchestrator syncs both before the check.
- **M1-16 scripter (opus), checks** (wave 4): see `m1-core-loop-gate.md`.

## Acceptance criteria (each is an exit check; owner in brackets)
1. A Good burst applies 4 punches' value and a Perfect 8, at 0, 0.213 and 0.401 s after accept, each applied time
   within 20 ms (server clock) of its schedule. A Miss launches no burst and the next ring starts 0.61 s later.
   The cycle is 1.81 s at Speed 1 and 1.11 s at Speed 10. [M1-16 BurstValues]
2. Fight tap counts match the brief's band table at r = 0.5, 1, 1.5, 2, 3, 5: all-Good taps = ceil(2.5 r) = 2, 3,
   4, 5, 8, 13; all-Perfect taps = ceil(1.25 r) = 1, 2, 2, 3, 4, 7; the band and windows at start match the table.
   [M1-16 BurstValues]
3. Refused, with no state change: taps faster than `CYCLE x 0.8`; a bag report off the own pad; a fight report
   with no fight; a fight started while carrying; a fight started outside the ring; a tap during a burst (ignored,
   no penalty, no refusal count); a `Base.Place` on a spot that is not the player's. [M1-16 Refusals]
4. B22: a boss emptied on punch 1 or 2: `won` on that beat, later beats deal nothing and send nothing, F still
   plays to its end (client check), defeat starts at once. [M1-16 BurstValues + M1-13 SyncTest for the F half]
5. The stall rule: a client that stops reporting in a fight loses a heart per missed ring. [M1-16 Refusals]
6. No fight move delays the ring: Misses and big husses back to back at Speed 10; the next ring starts on schedule
   and a running reaction is cut by the next result. [M1-20 NoDelay with M1-16's script]
7. Controls: Huss works on keyboard (left mouse, F), gamepad (right trigger), touch (button); Interact and Run
   per `docs/controls.md`; the glyph in the prompt matches `Input.kind()`. [M1-07 scripted with `ForceInput`; the
   real devices are the manager's]
8. Seconds to first punch, first Perfect, 25 Power, first fight, first boss beaten, measured. [M1-18]

## Roles and order
M1-01 (contract code) -> M1-06 and M1-07 and M1-08 in parallel -> sync + smoke check by the orchestrator ->
M1-16. Studio lock: only the checks and the on-screen look need it; M1-06 and M1-07 verify through the MCP in
play mode, one at a time.

## Risks
Client-judged timing is the first exploit target (bounded: rate, place, state; gain capped about 1.5x). Late
frames on a phone: the beat loop must catch up, not drop. A long fight camera that fights the character's
movement. Rate limit too tight at Speed 10 (cycle 1.11 s = 0.9 a second; the limit is 4 a second).

## Suggestions from the vault (optional; none is built unless the manager accepts)
None added by the producer for this feature.

## Not asked for (do not build)
Buying Strength or Speed (M2; config levels only); Auto Punch and Perfect Auto Punch (M2); the watching clients'
copy of a burst and `Punch.Burst`/`Fight.Watch` senders (M2); more than one pad or boss; rolling pads; any boss
besides Chomp Frog; Power shortening (B16); saving; the thief punch; the HUD zone strip; GOOD/PERFECT sounds beyond
the stand-in set; cube bursts, camera shake and stud confetti (M4); a Power-over-boss number colour beyond what
the HUD overlay needs (the number's colour is the world billboard in M1-12/M1-14); any fatigue rule for the voice.
