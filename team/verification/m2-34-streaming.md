# M2-34 streaming (tech-lead, 2026-11-26)

**Cause (confirmed from the code and the logs):** `workspace.StreamingEnabled = true` and every boss model, the review line and the rest were Default/Nonatomic, so on the client a model could arrive without its groups. `BossMoves.initState` looked once, found no Body, warned and never retried (the idle start from Controllers/Fight at init; the review-line driver). The review-line launcher did `root:WaitForChild("Dummies")` with no timeout under a Folder root that had streamed in empty, so the driver never started and the plates stayed on "starting...".

**Changes:** `studio/SetupBosses.lua` (Boss_* Persistent + check), `studio/BuildReviewLine.lua` (root is one Persistent Model, clones Default inside it, + check), `studio/review/Launcher.lua` (longer waits incl. Bosses), `studio/SetStreamingModes.lua` (new: plots, hazards and rolling pads Atomic; run after the Build scripts), `Controllers/BossMoves.lua` (a play/loop on a model whose groups are not all there is kept and replayed when they arrive, up to 10 s, then with what is there; never yields), `Controllers/Fight.lua` (idle a pad's boss when it arrives), `-- stream-ok` markers in Base/BossVisuals/Ring, `tools/check_streaming.py` (new scan), `studio/checks/StreamingProbe*.lua` (new check), `vault/roblox-docs/instance-streaming.md`.

**Run in place:** SetupBosses (0 failed, six PASS "Persistent"), BuildReviewLine (root Persistent Model, 6 bosses), SetStreamingModes (1 plot, hazards, 18 rolling pads Atomic). The place needs saving by the manager (not saved by me).

**Probe (real client, play mode, `checks/StreamingProbe.lua`, result 0 failed):**
- join: 6/6 Fixed bosses whole and BossMoves playing; ReviewLine on the client; 6/6 review-line bosses whole
- wait path: an incomplete boss clone is not started, and plays 0.1 s after its parts arrive
- at the review line: t5 all plates left "starting..." (8/8), t5 to t15 all changed (8/8); BossMoves ran on 6/6 bosses within 4 s
- zone 6 and back at spawn: 6/6 whole and playing each time. No "has no Body" warning in the play log.
Probe, RemoteEvent and listener removed (`StreamingProbeRemove.lua`), play stopped, lock released.

**Not covered / UNVERIFIED:** a real phone memory cost of Persistent bosses (six small models); a second player; the Atomic plots with more than one plot (only Plot1 exists in the place now).
**Routed:** `tools/check_streaming.py` still flags `Controllers/Shield.lua:59`, `Controllers/Steal.lua:78`, `Ui/StealAlert.lua:361` (Plots lookups called on every use and nil-tolerant, so fine; add a `-- stream-ok` marker when M2-16 is done). Run `SetStreamingModes.lua` after any Build script rebuilds plots/pads/hazards (orchestrator).
