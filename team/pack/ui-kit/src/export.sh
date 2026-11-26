#!/usr/bin/env bash
# Exports every board and screen of ui-kit.figcraft into ui-kit/. Boards and phone screens at 2x, desktop at 1x.
set -e
cd "$(dirname "$0")/.."
CLI="/c/Program Files/ArtCraft/FigCraft/figcraft-cli.exe"
export TMPDIR="${TMPDIR:-$(cygpath -m "$TEMP")}"
"$CLI" export ../ui-kit.figcraft --page "1 Foundations" --scale 2 -o .
"$CLI" export ../ui-kit.figcraft --page "2 Components" --scale 2 -o .
"$CLI" export ../ui-kit.figcraft --page "3 Icons" --scale 2 -o .
"$CLI" export ../ui-kit.figcraft --page "4 Screens phone 874x402" --scale 2 -o .
"$CLI" export ../ui-kit.figcraft --page "5 Screens desktop 1920x1080" --scale 1 -o .
