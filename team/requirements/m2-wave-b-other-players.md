# M2 wave B: other players, stealing, shields, the policy guard (system 10, 7's plot assignment)
Tasks: M2-15 scripter (opus), M2-16 scripter (sonnet), M2-17 gui-designer (sonnet). Starts after M2-01, M2-02 (contract
review) and wave A's data layer (M2-09) and base (M2-11). Quality pass: **Function**.

## The brief
`pack/brief.md` system 10 and the build plan's "Wave B", as written: plots for 8; stealing for every boss including bought
ones (hold 2 s, the owner's punch at 0.8 s with the single huss, chase speed 20 studs/s, returns, 60 s safe time after a
steal); the bought-boss policy guard (TEAM CALL 38: greyed "Can't be stolen"); Quick Hands (1.0 s hold); Iron Grip (stagger,
then a drop on a second hit within 10 s, nothing against hazards, falls or the shield); the lock shield (60 s up, 60 s
cooldown, push-out, joining shield, Instant Shield unbreakable, the 5-minute per-base break timer); the transfer as one
operation by boss uid.

## Work
- **M2-15 server:** plot assignment for 8 (fill order 1, 8, 4, 5, 2, 7, 3, 6), `Systems/Steal`, `Shield`, `Policy` (module read by
  wave C), the stand-in second player seam, the transfer through `Data` (M2-09), the policy hooks. Checks: the brief's
  stealing set and attacking set (see `m2-gate.md` rows).
- **M2-16 client:** Steal hold bar and prompt (hold E / X / prompt), thief strip, owner alert arrow, Iron Grip stagger, shield
  state display, **watching clients** (other players' bursts via `Punch.Burst` and their boss reactions, at most one boss reaction
  per 0.3 s per boss, F at the lowered level, two voices at most), a respawn while carrying (M1 carryover). Two real Studio
  clients for the second-client gloves and punches check (main session on screen).
- **M2-17 plain screens:** steal alert (with the BOUGHT tag variant), "shield broken" alert, the lock board buttons, the Break shield
  button with its greyed reasons, the confirm dialog, the greyed "Can't be stolen" prompt with a padlock, Prompts kinds.

## Acceptance criteria
The gate's stealing and attacking rows pass; the steal alert with and without BOUGHT, the greyed prompt and the Break shield
button are looked at on screen at phone size.

## Risks
A boss existing in two profiles (forced error between the two writes); a client that sends `Steal.OwnerPunch` for a boss it
doesn't own; the policy guard hiding a legal steal; teleport and over-speed carrying.

## Not asked for (do not build)
Stealing on the lane; stealing from offline players; more than one carried boss; a bounty, revenge or steal history; any
attacking product beyond the brief's three; the kit look (M3); steal sounds beyond the wired stand-ins (M4).
