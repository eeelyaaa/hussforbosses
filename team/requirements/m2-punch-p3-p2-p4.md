# M2: the punch redesign (P3), the ring and windows (P2), the fight angle (P4)
Tasks M2-03 (game-designer, opus), M2-06 (scripter, opus), M2-07 (scripter, sonnet), M2-08 (gui-designer, sonnet).
Quality pass: **Function** (Friction, Feel, Look come at M3 to M5). Contract: `m2-contract.md` section B.

## The brief (the manager's words, 2026-11-25, after playing M1; they replace the brief's "a Miss launches no burst")
- P3: "just clicking the huss button should work. but if you don't time it it obviously doesn't do the three in a row, which is considered perfect (perfect text should float up above the button). and does more damage when timed. if they just click it just does 1 on the punching bag and depends on strength level on fighting bosses."
- P2: the huss timing is "a little hard", and "the ring should be a little quicker in general."
- P4: "the fight angle should be a little better for the player"; the avatar reads large in the lower left.
Built as written: an untimed tap is one punch; a timed tap is the three-punch burst; PERFECT floats above the button.

## Goal and player outcome
Pressing the Huss button always does something. Timing it is how you get the burst and the big damage.

## Work
- M2-03: writes `m2-punch-numbers.md`: new `RING[1..10]` (a little quicker than 1.20 to 0.50; Speed's 1.63x spread kept), windows
  per band (a little wider), the single-punch value on the bag and in fights, the untimed rule (one per ring, contract B2),
  the heart rule's consequence, and a measured table: Power a second at Speed 1 and 10 for all-untimed, typical and
  all-Perfect play (untimed must stay below the Good burst), first-session timings re-derived. Anything that changes the game
  (no heart for an untimed tap) is answered in `manager-todo.md` Q1 with its default.
- M2-06 (server): `Punch.Report` with `untimed`, the single punch on the bag and in a fight, `Config` values from M2-03, the
  rate rules, the stall rule kept; removes the duplicate `defeat` second caller on the server side if it is there.
  Check `studio/checks/Punch2.lua`: untimed on the bag +1 at Strength 1 and `x1.35` at Strength 2; untimed in a fight = Power;
  a second untimed in the same ring refused `untimedBusy`; no heart lost; a no-tap ring costs one heart; Good 4, Perfect 8;
  forged `untimed` with `auto` refused; rate cap holds at 20 reports a second.
- M2-07 (client): the Ring grades Perfect, Good, untimed (a tap outside Good, only when the tap is not earlier than the
  ignore window), the single huss on an untimed tap, no pips, no F; `Config.Fight.CAMERA` for the better angle (avatar
  centre-left and smaller, boss right, both in frame at 874 x 402 and 640 x 300); the duplicate `defeat` caller on the client
  removed; real Input path checked for key (F, left mouse), gamepad (right trigger) and touch through the real handlers
  (not only `Input.fire`).
- M2-08 (UI): PERFECT floats up above the Huss button and fades (the kit's flash yellow, plain version); a plain pop for an
  untimed single punch (no text); FightOverlay shows the band as before.

## Acceptance criteria
1. Untimed, Good, Perfect and Miss each give the value in the table above on the bag and in a fight, read on the server.
2. Mashing the button for 10 s at Speed 1 gives less Power than 10 s of Good bursts (measured, in the check).
3. PERFECT appears above the Huss button on every Perfect (on-screen, phone size), no text on an untimed tap.
4. The fight camera frames avatar and boss together at 874 x 402 and 640 x 300 (on-screen, the art-director's look).
5. The Refusals check from M1 still passes; the exploit reviewer re-checks the rate caps (M2-27).

## Roles in order
M2-03 and M2-01 together first; then M2-06 with M2-07 and M2-08 in the same batch (contract B quoted in all three);
check by the main session: PERFECT float and the camera on screen.

## Risks
Untimed spam beating timing (contract B2 caps it); the burst timing contract (hits at 0, 0.213, 0.401 s) must not move.

## Suggestions from the vault
None taken.

## Not asked for (do not build)
A combo counter or streak; a new grade; a mash penalty; auto-timing aids; changes to burst timing or F; new sounds (the
single huss 02 A and 01 A are already uploaded); the huss "more intense" work (that is P6, M4).
