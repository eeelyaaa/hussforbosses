# Controls

From `team/pack/brief.md`, "Controls" (the source; brief team call 26). Every action works on all three inputs.
The Huss button is one button whose job follows where the player stands: on the bag pad it punches the bag, in a
boss ring it starts the fight and then punches, next to a thief carrying your boss it punches the thief.

| Action | Keyboard and mouse | Gamepad | Touch |
|---|---|---|---|
| Move | W A S D | Left stick | Thumbstick |
| Look | Right mouse drag | Right stick | Drag |
| Jump | Space | A | Jump button |
| Punch (Huss): bag, fight, thief | Left mouse button or F | Right trigger | Huss button |
| Interact: place, pick up from crate, grab a dropped boss, open boss panel, open bag panel | E | X | The prompt button on the object |
| Steal (hold 2 s) | Hold E | Hold X | Hold the prompt button |
| Raise the lock shield | Step on the lock pad, or Q inside your base | Step on the pad, or Y inside your base | Step on the pad, or the shield button |
| Run from a fight | Backspace, or click Run | B | Run button |
| Sell the carried boss (inside your base) | Click Sell | D-pad down | Sell button |
| Open or close the shop | B, or click Shop | D-pad up | Shop button |
| Open rebirth | N, or click Rebirth | D-pad right | Rebirth button |
| Open settings | M, or click the gear | D-pad left | Gear tile |
| Move in a menu and choose | Mouse | D-pad or left stick, A to choose | Tap |
| Close a menu | Click X, or the key that opened it | B | Tap X |

Prompts show the glyph for the input in use. The ring must be readable and the Huss button reachable with the right
thumb on the smallest phone; it stays clear of Roblox's jump button and top bar.

Built in `src/StarterPlayer/StarterPlayerScripts/Controllers/Input` (M1 for punch, interact and run; the rest with
their systems). A binding is done when it works on keyboard and mouse, gamepad and touch.

## What each action sends (M2-01, `team/requirements/m2-contract.md` section C)
The client only asks; the server decides (`Shared/Net.lua` has every payload). Bindings are added to
`Controllers/Input` by its owner (M2-07 in batch 2: `shop`, `rebirth`, `settings`, `shield`, `sell`, `run`,
`menu` actions next to `punch` and `interact`); screens and controllers subscribe to the action, they never read
keys themselves.

| Action | Remote |
|---|---|
| Punch on the bag or in a fight | `Punch.Report` (grade `perfect` / `good` / `untimed` / `miss`) |
| Punch in a boss ring with no fight | `Fight.Start` |
| Punch a thief carrying your boss | `Steal.OwnerPunch` |
| Run from a fight | `Fight.Run` |
| Place / pick up / swap / sell / take from the crate | `Base.Place` / `Base.PickUp` / `Base.Swap` / `Base.Sell` / `Base.TakeCrate` |
| Grab a dropped boss | `Carry.Grab` |
| Upgrade a boss (boss panel) | `Boss.Upgrade` |
| Buy Strength / Speed, Auto Punch toggles (bag panel) | `Bag.BuyStrength` / `Bag.BuySpeed` / `Bag.AutoToggle` / `Bag.PerfectToggle` |
| Steal (hold) / let go | `Steal.HoldStart` / `Steal.HoldCancel` (release or moving away) |
| Raise the shield (Q / Y / button; the pad needs no remote) | `Shield.Raise` |
| Break shield (another player's shield) | `Shield.UseCharge` with a charge, else `Shield.BuyBreaker` |
| Open the shop / buy / spin | `Shop.Open` / `Shop.Buy` / `Shop.Spin` |
| Rebirth (second confirm) | `Rebirth.Request { confirmed = true }` |
| Collect "While you were away" | `Offline.Collect` |
| Settings sliders | `Profile.Settings` |
