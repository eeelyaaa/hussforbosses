# Huss for Bosses: decisions

Newest at the bottom. A `TEAM CALL` is a choice the pack left open that is reversible and doesn't change what the
game is (`vault/playbooks/autonomous-build.md`, rung 2): the call, the reason, what changing it later costs.
Choices that would change the game are questions in `manager-todo.md`, not entries here.

## Carried in at M0 (2026-11-25), by reference; the pack copies are the source
- **The pitch's record**: `pack/decisions.md` (what was shown and what the manager said, round by round).
- **The brief's team calls 1 to 42**: `pack/brief.md`, "Team calls (for the producer)". Carried in as written
  (the build plan counts 39; the brief has since added 40, the base layout; 41, walled zone corridors; 42, the
  settings gear tile). All 42 apply.
- **The base layout's 15 team calls**: `pack/base-layout/base-layout.md`, section 8 (B26). The builder's greybox at
  M1 and M3 may change a dimension and reports it here.
- **The build-side calls B1 to B26**: `pack/build-plan.md`, "Team calls expected". Status at M0:
  - Settled in the plan: B1 (DevSync, not Rojo), B2 (UI in code, world by scripts, moves as tweens), B10 (layout
    settled; greybox measures), B15 shield drop heard nearby, B19 (models per launch, at most two Opus agents a
    wave), B20, B21 (rule set; applied at M1 if the probe says so), B22, B24, B25.
  - Decided below at M0: B3.
  - Open, owner and milestone as the plan says: B4, B5, B7, B11, B13, B14, B21 (measurement) at M1; B8 at M1/M2
    (convention set below); B6 at M2/M3/M5; B9, B12, B16, B20 (built), B23 at M2; B15 (picks), B17, B18 at M4.

## M0 (tech-lead, 2026-11-25)
- `TEAM CALL` M0-1 **Pack media in git.** Committed: every text file in `pack/` (md, py, sh, json, html, txt) and
  the media the build compares against or builds from: `ui-kit/` and `ui-kit.figcraft` (screens are checked side
  by side against these at M3), `base-layout/01..04` plans and `base-layout.figcraft`, `concepts/brick-brawl/` (the
  approved direction; Chomp Frog's picture), `concepts/manager-refs/` (the stud proof's references), `style/`,
  `sound-refs/` (the manager's huss recording, the burst voice's source). Ignored (`.gitignore`): the four
  rejected look directions and `concepts.figcraft` (about 246 MB), `game-page/` images (concepts; M6 makes the
  real ones from screenshots), the base layout's renders (`view-*.png`, `src/render-sources/`; "impressions only"). Reason: keep
  the spec reproducible from the repo while leaving out about 280 MB of exploration history. The originals stay on
  disk in `team/pack/` and in ro-team `pitches/huss-for-bosses/` (which ro-team does not track either; see
  `manager-todo.md`, "Confirm"). Cost to change: edit `.gitignore` and commit the files (git history then grows by
  their size).
- `TEAM CALL` M0-2 **One source for the spec.** `team/brief.md`, `style-guide.md` and `sound-direction.md` are
  pointers to `team/pack/`, not copies, so the spec can't drift between two files. Cost to change: copy the files.
- `TEAM CALL` M0-3 **DevSync adapted from deja-kill** (B1): port 34874 (deja-kill keeps 34873, so the two servers
  never collide); `/files` names the project and the loader refuses any other server; `init.lua` /
  `init.server.lua` / `init.client.lua` turn a folder into that script (Rojo's rule, so `Shared/Config/` and
  `Skins/brickbrawl/` work as the plan lays them out and a move to Rojo stays one project file); root
  `StarterPlayer` (paths `StarterPlayer/StarterPlayerScripts/...` as in the plan's layout); `studio/` subfolders
  allowed; `/loader` recreates the loader in a place that lost it; refuses during play mode. Cost to change: small,
  one Python file and one module.
- `TEAM CALL` M0-4 **The place guard.** Marker `Workspace.HussForBosses = true`, set once by
  `studio/SetPlaceMarker.lua`, which itself refuses unless CreatorType is Group, CreatorId 432262304, PlaceId
  139279056607944 and GameId 10779089797. The loader checks the marker before every sync and run; every `studio/`
  script also starts with the guard line, so it refuses even if pasted past the loader; `tools/check_guard.py`
  fails on a script without it. Proven at M0 (`verification/m0-setup.md`).
- `TEAM CALL` B3 **Own save module**, not a vendored library. Reasons: vendoring ProfileStore means downloading
  third-party code, which the approval doesn't cover (box 6 unanswered, "installing nothing new"); the
  `roblox-data` skill and `vault/patterns/session-lock-inside-the-record-one-updateasync.md` give the design (one
  record, session lock inside it, one `UpdateAsync` per write, environment in the store name). Built by the
  data-engineer at M2. Cost to change: swap the module behind the same `Data/` interface before live data exists.
- `TEAM CALL` B8 (convention only; names and payloads at M1) **Remotes**: all in `Shared/Net.lua`, at
  `ReplicatedStorage.Remotes.<Family>.<Name>` with the plan's 13 families, PascalCase names, created only by the
  server, `UnreliableRemoteEvent` only for cosmetic broadcasts, `RemoteFunction` only for the shop's quotes, a
  payload comment on every entry. Cost to change: rename inside one module.
- `TEAM CALL` M0-5 **Content ids** in `Shared/Ids.lua`: creatures `z<zone>_t<tier>`, product keys `pass_*`
  (10) and `product_*` (9) named after the brief's products. The plan's example `pass_auto_punch` is kept. Cost
  to change: a rename before anything is saved.
- `TEAM CALL` M0-6 **Test hook attributes** are `Workspace.HFB_<Name>`, listed in `TestHooks.HOOKS` and
  `test-hooks.md`; two named at M0 (ForceSkin, SaveOff).
- Checked at M0, the two kit items the plan said to verify: the bag panel's Speed numbers now read 1.20 s and
  "Next level: 1.12 s" on both `ui-kit/phone-bag-panel.png` and `desktop-bag-panel.png` (fixed). Board 01's
  palette captions still leave out jobs (Alarm orange doesn't name the bought boss's sell or swap confirm or the
  "can't do that" toasts by name; Huss red doesn't name the gloves or the bag band); as the plan says, the style
  guide's table is the authority, so nothing changes in the build. For the gui-designer and art-director: read
  colour jobs from `pack/style-guide.md`, not from board 01's captions.
