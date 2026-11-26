# Huss for Bosses: board

Owned by the producer. One line per task: id, task, owner, model, status, evidence link. Detail goes in
`requirements/` and `verification/`. Finished milestones are in `board-archive.md`.
Statuses: `TODO`, `IN PROGRESS`, `CHECK` (built, evidence owed), `DONE` (evidence in `verification/`),
`UNVERIFIED` (not looked at), `PROVISIONAL` (built on a default; question in `manager-todo.md`), `BLOCKED: manager`.
Quality passes per player-facing feature: Function, Friction, Feel, Look, Manager playtest.

## M1: closed (2026-11-25)
M1 closed: the Core loop gate passes, 30 PASS, 0 FAIL, 11 UNVERIFIED looks (`verification/m1-exit-checks.md`). Rows and final
statuses are in `board-archive.md`. Quality passes done: Function only (by plan). Follow-ups for later milestones:
`requirements/m2-carryover.md`. Nothing is `BLOCKED: manager` or `PROVISIONAL`; the manager's optional steps are in
`manager-todo.md`.

## M2: closed (2026-11-26)
M2 closed: the gate passes 27/27 scripted rows (`verification/m2-gate.md`). On screen, O2, O3, O4 and the review line PASS; O1, O5, O6, O7, O8 and the crate TAKE are `UNVERIFIED` and listed in `manager-todo.md` as the M2 playtest. Rows and final statuses are in `board-archive.md`. Quality pass done: Function only (by plan). Follow-ups: `requirements/m2-carryover.md`. PROVISIONAL: Q1 to Q4 in `manager-todo.md`. The next milestone (M3, the world) is planned when the manager has reviewed M2.
