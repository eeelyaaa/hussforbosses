#!/usr/bin/env bash
# Rebuilds ui-kit.figcraft from the scripts and re-exports every PNG.
set -e
cd "$(dirname "$0")"
TMP="${TMPDIR:-$(cygpath -m "$TEMP")}"
python build_kit.py "$TMP/huss-kit.json"
"/c/Program Files/ArtCraft/FigCraft/figcraft-cli.exe" run "$TMP/huss-kit.json" --out ../../ui-kit.figcraft > "$TMP/huss-kit.log" 2>&1 || true
grep -v '"ok":true' "$TMP/huss-kit.log" | head -c 1200
rm -f ../*.png
bash export.sh > /dev/null
ls ../*.png | wc -l
