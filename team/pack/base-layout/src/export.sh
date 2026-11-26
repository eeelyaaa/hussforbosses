#!/usr/bin/env bash
# Rebuilds base-layout.figcraft from the scripts and exports the four boards as PNG into base-layout/.
set -e
cd "$(dirname "$0")"
CLI="/c/Program Files/ArtCraft/FigCraft/figcraft-cli.exe"
export TMPDIR="${TMPDIR:-$(cygpath -m "$TEMP")}"
python build_plans.py "$TMPDIR/base-layout.json"
"$CLI" run "$TMPDIR/base-layout.json" --out ../base-layout.figcraft > "$TMPDIR/base-layout.log" 2>&1 || true
grep -v '"ok":true' "$TMPDIR/base-layout.log" | head -c 1500
mkdir -p "$TMPDIR/bl-out"; rm -f "$TMPDIR/bl-out/"*.png
for p in "1 Base area" "2 Plot" "3 Pads" "4 Steal route"; do "$CLI" export ../base-layout.figcraft --page "$p" --scale 1.5 -o "$TMPDIR/bl-out"; done
cp "$TMPDIR/bl-out/01 Base area plan.png" ../01-base-area-plan.png
cp "$TMPDIR/bl-out/02 Plot plan.png" ../02-plot-plan.png
cp "$TMPDIR/bl-out/03 Pads.png" ../03-pads.png
cp "$TMPDIR/bl-out/04 Steal route.png" ../04-steal-route.png
ls -la ../*.png
