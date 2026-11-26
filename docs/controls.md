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
