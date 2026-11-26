# Huss for Bosses: test hooks

Read only in Studio through `src/ReplicatedStorage/Shared/TestHooks.lua` (`TestHooks.get(name)` is nil on a live
server, which warns once if any is set). Each hook is a Workspace attribute `HFB_<Name>`. **This list and
`TestHooks.HOOKS` must match**; a task that adds a hook adds it to both. Tests set hooks from the play-mode script
and clear them afterwards. (`vault/patterns/test-hooks-gated-to-studio-and-listed.md`)

## In the code
| Hook | Attribute | Type | What it does | Added |
|---|---|---|---|---|
| ForceSkin | `HFB_ForceSkin` | string | Loads `Skins/<id>` instead of `Config.SkinId` (the skin check uses `stub`) | M0, read by `Shared/Skin` |
| SaveOff | `HFB_SaveOff` | boolean | No DataStore reads or writes; fresh unsaved profiles | M0, named; honoured by the save module (M2) |

## Planned (build plan, "Test hooks"); added by the task that builds each
- Set Power, cash, bought cash, Strength, Speed, rebirths, zones beaten; grant a boss by id to a spot or the crate,
  with or without a bought mark and buyer; wipe to a fresh profile.
- Force a pad's roll; speed up pad timers; server clock offset (offline earnings, shield, safe time, break timer).
- Force a save error between the two writes of a transfer.
- A stand-in second player (owner or thief) through module seams.
- A fake receipt for any product key; pass ownership on or off; both policy flags on or off, or the call failing.
- Force the input kind (touch, gamepad, keyboard); throttle the frame rate to 30 and 15 for the sync test.
- An auto-player tapping the ring at a chosen grade mix.
