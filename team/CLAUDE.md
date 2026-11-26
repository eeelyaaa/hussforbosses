# Huss for Bosses: team context

**Mode: autonomous** (`vault/playbooks/autonomous-build.md`, started with `/build huss-for-bosses`).
Don't ask the manager mid-build: decide with the playbook's ladder, log `TEAM CALL`s in `decisions.md`, and put
what only the manager can do or decide in `manager-todo.md`. Build state: `build-state.md` (the orchestrator's).

## What the approval covers (`pack/approval.md`, APPROVED 2026-11-25)
The manager answered boxes 1 to 5 yes, in their words:
1. The pack as it is (brief, style guide, UI kit, base layout, sound direction, game page, build plan) is the spec.
2. Build mode autonomous; stops only at the handoff unless the build line says `until M<n>`. Two looks that gate
   later work without stopping the build: the stud proof (after M1), the first six bosses (after M2).
3. Uploading the build plan's asset list to Roblox **owned by the group** without asking again (by the main
   session's computer use or the Studio MCP).
4. Higgsfield spending up to 40 credits on the asset list (the balance, about 35, is the real limit); estimate each
   cost first, report the balance after.
5. Local commits in this repo at each milestone, by the orchestrator. Never pushed.
6. Box 6 (installing nothing new) was not answered: **the build installs nothing**. Anything it turns out to need
   is asked for separately first.

Never covered: publishing, Robux and prices, game, group and account settings, signing in, pushing, and anything
the brief doesn't contain.

## The game
A Roblox simulator about punching. Stand at your bag and tap once as the timing ring lands: the avatar throws three
jabs to the manager's own "huss huss huss" recording. Power grows; fight zone bosses (voxel creatures, 6 zones x 6
tiers), carry the beaten boss home past each zone's hazard, place it on your base where it earns cash; upgrade,
steal from and defend other bases (lock shield), rebirth. Full shop (10 passes, 9 developer products). Look: "Brick
Brawl", a stud world with voxel bosses. Audience, numbers and every rule: `pack/brief.md`.
Fairness line: paid advantages are allowed, including attacking products (brief, "Who it is for").

## Owner and place
- Owner: the Roblox group **Huss for Bosses**, community id **432262304** (owned by the manager's account).
- The place: PlaceId **139279056607944**, GameId **10779089797**, `game.CreatorType = Group`. Checked at M0
  (`verification/m0-setup.md`). Every upload goes to this group.
- **The place guard.** The open place carries `Workspace.HussForBosses = true` (set at M0 by
  `studio/SetPlaceMarker.lua` after checking owner and ids). The loader and every `studio/` script refuse to run
  without it. The manager often has another game's place open (deja-kill); nothing of this game may run there. If
  the guard refuses, check which place is open; never set the marker by hand in another place.

## Where to read
| File | What |
|---|---|
| `pack/` | The approved pack, **the source**. `brief.md` (the spec; "The idea, in the manager's words" outranks all), `style-guide.md`, `sound-direction.md`, `build-plan.md`, `ui-kit/` + `ui-kit.figcraft`, `base-layout/`, `concepts/brick-brawl/`, `game-page/`, `approval.md` |
| `brief.md`, `style-guide.md`, `sound-direction.md` | Pointers to the pack copies (one source, no drift) |
| `board.md` | Tasks for the milestone (the producer's) |
| `decisions.md` | Every TEAM CALL, the brief's calls and the B-series by reference |
| `manager-todo.md` | Everything waiting on the manager |
| `test-hooks.md` | Every test hook; the list in `Shared/TestHooks.lua` must match |
| `assets.md` | Every uploaded asset and its id |
| `requirements/`, `verification/`, `audits/` | Per feature: the spec, the evidence, the audits |
| `../docs/controls.md` | Action x input table |

## How code reaches Studio: DevSync (TEAM CALL B1; not Rojo)
`src/` is the source of truth. Rojo is not installed and isn't needed.
1. Start the sync server from the game repo root and keep it running (background):
   `python tools/devsync.py`  -> serves `src/` and `studio/` on **http://127.0.0.1:34874** (deja-kill's is 34873).
   Check: `curl -s http://127.0.0.1:34874/health` -> `{"project": "huss-for-bosses"}`. Stop: kill the process.
2. In Studio, edit mode, holding the `studio` lock (Studio MCP `run_code`, or the command bar):
   - sync `src/`: `require(game.ServerStorage.DevSync:Clone())()`
   - run a `studio/` script: `require(game.ServerStorage.DevSync:Clone()).run("CheckPlace.lua")` (subfolders: `"checks/X.lua"`)
3. If the place lost the loader (not saved), recreate it (pulls `src/ServerStorage/DevSync.lua` from the server):
   ```lua
   local s = game:GetService("HttpService"):GetAsync("http://127.0.0.1:34874/loader", true)
   local m = Instance.new("ModuleScript"); m.Name = "DevSync"; m.Source = s; m:SetAttribute("DevSync", true); m.Parent = game.ServerStorage
   ```
   If the marker is lost too: `require(game.ServerStorage.DevSync:Clone()).run("SetPlaceMarker.lua")`.
- `HttpService.HttpEnabled` is off in this place and the sync works anyway from the MCP (measured at M0).
- The loader refuses during play mode, refuses a server that isn't this project, and refuses without the marker.
- Mapping: `src/<Root>/...` -> `ReplicatedFirst`, `ReplicatedStorage`, `ServerScriptService`, `ServerStorage`,
  `StarterPlayer` (`StarterPlayerScripts/`, `StarterCharacterScripts/`), `StarterGui`. Rojo file names:
  `*.server.lua` Script, `*.client.lua` LocalScript, `*.lua` ModuleScript, `init*.lua` turns its folder into that
  script, directories are Folders. Synced instances carry a `DevSync` attribute; deleting a file removes its instance.
- **Module cache rule (M1-01b):** in edit mode `require` caches per ModuleScript instance and setting `Source` does not
  clear it. So whenever a sync changes anything, the loader swaps EVERY synced ModuleScript for a fresh instance (same
  name, attributes, tags, children; one swap each, no clones), because a changed module also stales every module that
  required it. After a sync a plain `require` is fresh. Never edit `Source` in place to refresh code, and never
  `:Clone()` a tree to dodge the cache (that made 24 duplicates once); sync again instead. References to old module
  instances held across a sync are dead: fetch them again by path. Checks that need two versions side by side (the
  skin check) still clone, into a throwaway folder they destroy.
- A sync pulls everyone's files: a broken file you don't own shows up in your test. Report it, don't fix it. After
  each wave the orchestrator syncs once and runs the smoke check.

## Repo layout (build plan, "Technical shape")
```
src/ReplicatedFirst/                 Music.client.lua (M4)
src/ReplicatedStorage/Shared/        Config/ (init.lua + one module per system), Ids.lua, Net.lua, Skin.lua,
                                     TestHooks.lua, Moves/ (boss move tables per body type, fractions of H)
src/ReplicatedStorage/Skins/         brickbrawl/ (init + Names, Tokens, Models, Icons, Sounds, Lighting, Effects,
                                     Dressing), stub/ (the skin-check fixture, M1)
src/ServerScriptService/             Main.server.lua, Data/, Systems/ (one module per system, start())
src/ServerStorage/DevSync.lua        the loader
src/StarterPlayer/StarterPlayerScripts/  Main.client.lua, Controllers/, Ui/ (Kit + one module per screen)
studio/                              build and check scripts, run through the sync; each starts with the guard
tools/                               devsync.py, check_guard.py, blender/, audio/
docs/controls.md                     the action x input table
```

## Rules for this game
- **The skin is separate from the rules** (build plan, "Architecture requirement"). Rules, numbers and saves use
  ids only (`Shared/Ids`: zones, tiers, `z<zone>_t<tier>`, hazards, bags, body types, product keys). Everything a
  player sees or hears for an id comes from `Skins/<skinId>/` through `Shared/Skin`. **Nothing outside `Skins/`
  contains a display name, a hex or RGB colour literal, or an asset id.** Structure (layout, heights per tier,
  moving-group names and pivots, body types, move timing) stays outside the skin. Checked at M1, M3, M5
  (`studio/CheckSkin.lua` + a repo scan, built at M1).
- **Models**: bosses and gloves come from the voxel builder in headless Blender (`tools/blender/`), FBX with one
  mesh per moving group (`Body`, `Head`, `FistL`, `FistR`, `Sig`, as the style guide's table), imported through
  Studio, set up by a `studio/` script. Boss moves are tweens of group pivots in code, not Animation assets; the
  avatar's seven clips are Animation assets published under the group. No Higgsfield 3D.
  Blender: `D:/Games/steamapps/common/Blender/blender.exe -b` (5.3.0, measured at M0).
- **Nothing hand-built in the place.** UI is built in code from the UI kit's values (`src/.../Ui/`); the world,
  lighting and imported models are placed by `studio/` scripts that can run again on an empty place. Anything that
  had to be done by hand goes in `build-state.md`, "exists only in the place".
- **`studio/` scripts** start with exactly this line (checked by `python tools/check_guard.py`):
  `if workspace:GetAttribute("HussForBosses") ~= true then error("PLACE-GUARD: not the Huss for Bosses place; refusing to run", 0) end`
  They run in edit mode, print `PASS`/`FAIL` lines, and never `return` (the loader appends one). Long check
  scripts are loaded over the sync, not pasted.
- **Server authority.** The server owns every result (build plan, "Client and server boundaries"). The one client
  value believed is the burst report's grade and tap time, bounded by the server (rate, place, state).
- **Remotes** live only in `Shared/Net.lua`: `ReplicatedStorage.Remotes.<Family>.<Name>`, created by the server
  (`Net.serverInit`), fetched with `Net.get(family, name)`, a payload comment on every entry, every c2s input
  validated (type, range, rate, state, distance). Names and payloads: B8, the tech-lead's contract at M1.
- **Config**: every tunable number in `Shared/Config/<System>.lua`, read as `Config.<System>`. Tests override at
  runtime, never by editing the file. `Config.Env` is `Studio` or `Live`; every DataStore name includes it.
- **Test hooks**: Workspace attributes `HFB_<Name>`, read only through `Shared/TestHooks.get` (nil outside Studio),
  listed in `TestHooks.HOOKS` and `test-hooks.md`. Tests clear what they set.
- **Saving** (B3): our own save module to the `roblox-data` skill (one record per player, session lock inside the
  record, one `UpdateAsync` per write), built by the data-engineer at M2. Studio API access is on (M0).
- **Ids from the manager** (passes, products): stand-in 0 means no call; the ids go in `Config.Shop` when pasted.
- Every action works on keyboard and mouse, gamepad and touch (`docs/controls.md`). Mobile first.
- Studio: never launch it; use the open window. Hold the lock (`scripts/lock.sh`) for the MCP and computer use;
  only the main session has computer use.

## Known issues and open items
- The client entry script's print has not been seen in play mode yet (M0, `verification/m0-setup.md`).
- The marker, the loader and the synced scripts exist only in the open place until the manager saves it
  (`manager-todo.md`).
- Open contradictions in the pack (beat offsets measured at M1; two kit items to verify): `pack/build-plan.md`,
  "Contradictions still open".
