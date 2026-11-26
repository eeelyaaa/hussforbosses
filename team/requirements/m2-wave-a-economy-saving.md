# M2 wave A: saving and the economy (systems 2 to 9, 11, 12, 14)
Tasks: M2-09 data-engineer (opus), M2-10, M2-11, M2-14 scripter (opus), M2-12 scripter (sonnet), M2-13 gui-designer (sonnet).
Quality pass: **Function** for every system. Contract: `m2-contract.md` sections A, C, D, E.

## The brief
The manager's brief, `pack/brief.md` systems 2 to 9, 11, 12 and 14 as written (every number there is the spec; the
build plan's "M2, Wave A" is the task list). The manager's M1 decisions P2, P3 stand over system 1's old Miss rule. Quoted
by every brief of this wave: "the server decides" lines of each system; content by id only; no remote writes a price,
a level, an amount, the bought mark or bought cash.

## Goal and player outcome
Every rule works on the server and survives leaving and rejoining; rebirth is one safe operation.

## Task split (files do not overlap; see contract A)
- **M2-09 data layer:** the store, session lock inside the record, schema v1, migrations (test v2), autosave, leave, `BindToClose`,
  transfer by uid, receipt records, temp profile on a load error, `Session` API unchanged for M1 callers, test hooks
  `SaveOff/ForceSave/Leave/Shutdown/SaveFailBetween/LeaveAt`. Checks: save, leave, rejoin gives the same profile; a second
  session cannot take a locked profile; a simulated shutdown saves; a version bump migrates; content saved by id only
  (scan of a saved record); skin check part 3 (a save made under brickbrawl loads under stub).
- **M2-10 bag, Auto Punch, zones, patrol (systems 2, 5, 4's saved list):** `Bag.BuyStrength/Speed` with the brief's cost
  tables (30 and 10 levels) and the six bag tiers as model ids; Auto Punch and Perfect Auto Punch rules (client runs the ring,
  server applies value and rate, B20, B23; never in fights, never offline); all six zones' four pads each (1 fixed Common, 3
  rolling every 45 s, per-player "beaten this roll", deeper zones roll high tiers more often), `Zones.Pads` with patrol; the
  zones-beaten list written on fight wins (never on steals or purchases); `Shared/Patrol` and fight-start against the boss's
  patrol position. Checks `Bag`, `Zones`.
- **M2-11 carry, hazards, base, income, upgrades (systems 6, 7, 8, 9):** all six hazards as server-clock paths with stand-in
  shapes and "always leaves a way through"; Fast Carry speed; spots (10 + rebirths + pass), place, pick up, duplicates, sell,
  swap, the crate; income from time stamps with the 2-hour pad cap (no per-boss loop), the 2x Cash multiplier; boss
  upgrades to level 20 with the brief's curve. Checks `Hazards`, `Base`, `Upgrades`.
- **M2-12 clients for A:** Pads (6 zones, patrol, roll countdown from the server, number colours), Base (17 spots, crate,
  prompts), Carry, Hazards (all six), BossVisuals (half idle for placed bosses). Watching other players' bursts is M2-16.
- **M2-13 plain screens A (function, not the kit yet):** boss panel (upgrade), bag panel (Strength, Speed, Auto Punch toggles, the
  Perfect Auto Punch row only to Auto Punch owners: row built by M2-20), "While you were away", rebirth (the brief's
  text with the player's own numbers, a second confirm), settings (music and effects volume, a gear tile), toasts,
  number shortening (B16), the shield plate "ready" way (B12). Views only; calls go through the contract's remotes.
- **M2-14 offline, rebirth, bought mark and cash (systems 11, 12, 13's mark):** `Systems/BoughtMark.lua` is the only writer;
  offline earnings from the saved leave time and the clock hook (nothing under 60 s, capped at 2 hours a pad); rebirth as one
  save operation: reset list, kept list, the buyer's own bought bosses placed lowest spot first and the rest to the crate,
  pad cash cleared, cash = bought cash, a bought boss the player stole is reset, one the buyer stole back is kept,
  zones beaten kept. Checks `Offline`, `Rebirth`.

## Acceptance criteria
The gate rows in `m2-gate.md` for systems 2 to 9, 11, 12, 14, the saving set, the rebirth set, the bought-mark set.

## Roles in order
M2-01 contract first; M2-09 and M2-10 first batch (two opus); M2-11 next; M2-14 after M2-09 and M2-11; clients and screens beside.

## Risks
Doubled or lost saves (the data-engineer and the reviewer); the module cache rule after every sync; a sync pulls everyone's files.

## Suggestions from the vault (optional)
`vault/patterns/session-lock-inside-the-record-one-updateasync.md` (candidate, already the build plan's choice).

## Not asked for (do not build)
Leaderboards, quests, codes, an index, trading, a second currency, boss fusion, any pass or product beyond the brief's 19, real world
art, the kit's look on screens (M3), sound beyond what M1 wired (M4).
