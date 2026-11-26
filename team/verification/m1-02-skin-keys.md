# M1-02 skin tokens, names, icon keys (gui-designer, 2026-11-25)

Files: `src/ReplicatedStorage/Skins/brickbrawl/Tokens.lua`, `Names.lua`, `Icons.lua`. Pass: Function (data only).

## Repo scan (shell grep, every contract section F key this task owns)
- Tokens.colors: all 13 UI names, 6 world-shared, `tier[1..6]`, `band{easy,fair,hard,veryHard,brutal,impossible}`, `zone1..zone6{ground,ground2,structure,foliage,dark,accent}`: present.
- Tokens.font, Tokens.ui (every key named in F incl. `ringLandScale`), Tokens.stud (7 keys): present.
- Names: `game`, `zones[1..6]`, `creatures` (36), `hazards[1..6]`, `bags[1..6]`, `bands` (6), `grades{good,perfect}`, `hudWords{huss,run,place,grab,power,cash}`, `tiers[1..6]`: present. Extra: `products` (19, keyed by Ids.PASSES / Ids.PRODUCTS).
- Icons: 64 keys of board 04, all 0 (count checked: 64).
- Values come from style-guide.md sections 3 and 6 and brief.md (creatures table, hazards, bags, shop); none invented except the TEAM CALLs below.

## Not run
- `python tools/check_skin.py`: not written yet (tools/ has only devsync.py, check_guard.py, devsync); re-run when the tech-lead's M1-01 lands. It will see hex literals in Tokens.lua only, which the skin allows.
- No Luau parser on this machine (no luau/lua/stylua; Studio not used). Files were not syntax-checked; the first sync shows any error.

## TEAM CALLs
1. `ringLandScale = 1.075`, the centre of the kit's band (1.0 to 1.15).
2. `Tokens.fontBody` ({Montserrat, Bold}) and `Tokens.type` (22/20/18/16/14/14) added beside `font`: the type table needs a body face and sizes, and F lists only `font`.
3. Extra `Tokens.ui` sizes taken straight from the style guide (well/Huss outline, lip factor, pip pop scales, counter and chip heights, text outline 2/3, dim alpha...) so M1-08 hard-codes nothing.
4. `colors.pipEmpty` (`#3A4250`, empty pip and lost heart), zone 5 `accentCore`, zone 6 `accentCyan` (the guide's second accents).
5. Names are in the brief's case; tiers and bands are upper-cased by the view (chip, band word); grades and hudWords are stored in caps as drawn.
6. Icons: all 64 keys declared at 0 now (the contract/plan lists only 5 for M1); no uploads at M1, the Huss button has no glove.
