# Start prompt for Huss for Bosses

Before you paste, do these, in this order. The full wording is in `build-plan.md` ("The manager's steps", "Before
the build starts"); this is the checklist.

Already done (2026-11-25): the Roblox group **Huss for Bosses** is created (community id 432262304) and its first icon
is uploaded (moderation pending); your account is ID-verified.

- [ ] 1. Look at what is left under "Still open" at the end of `approval.md` (three items, each with a default), or say
      "defaults". The base layout you asked for before building is made and you approved it (`base-layout/`); the
      last box without an answer is "installing nothing new". Then go through its boxes with the chat that ran the
      pitch and say the pack is approved. `/build` stops if `approval.md` does not say `Status: APPROVED`.
- [ ] 2. Create the place under the group: in Roblox Studio, File, New, Baseplate; then File, Publish to Roblox As,
      choose the group as the creator, name "Huss for Bosses", private.
- [ ] 3. In Studio: Home, Game Settings, Security, switch on "Enable Studio Access to API Services". Save.
- [ ] 4. Leave that place open in Studio and close every other place (deja-kill included).
- [ ] 5. Studio's MCP server is on, computer use is on in the Claude app (Settings, Capabilities), and Studio is
      signed in to the account that owns the group.
- [ ] 6. Optional: an empty private GitHub repo for the game. Put its URL on a second line under the build line.
- [ ] 7. Optional: start the Kids and Select steps early (`game-page/game-page.md`); the evaluation takes weeks after
      release. You said you will pay or advertise as needed.

Then start a new chat at the ro-team root (`C:\Users\elya\Desktop\ro-team`), on your top available model (Opus
until Fable resets on 2026-11-27 at 22:00 PT; Fable after that), and paste the line below. That chat orchestrates:
it picks a model for every agent it launches (`build-plan.md`, "Models"), so the specialists do not all run on the
chat's own model.

```
/build huss-for-bosses
```

To stop at a milestone instead of running to the end, add it. To play the core feel first (bag, ring, the one-tap
"huss huss huss" burst in sync with the avatar's jabs, Chomp Frog fighting back, carry, place). `until M1` also shows
you, for the first time in Studio, your own plot built to the base layout, with its bag, the track and its start
line, and the stud:

```
/build huss-for-bosses until M1
```

After a usage limit or a closed chat, the same line in a new chat picks up where the build stopped.

The team reads the base layout (`base-layout/base-layout.md` and its four plans) as the spec for the hub and every
plot: M1 builds your own plot and the track start, M3 the whole hub with its eight plots and the walled zone lanes.

While it runs, everything that waits for you is in `projects/huss-for-bosses/team/manager-todo.md`. The first things
it will ask for: the ids of the 10 passes and 9 developer products, created under the group's game at the brief's
prices (steps in `build-plan.md`, "During the build"); your look at the stud proof after M1; and your look at the
first six bosses beside their pictures after M2. The build does not stop for any of them.
