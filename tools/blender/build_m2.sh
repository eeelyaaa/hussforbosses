#!/bin/sh
# Rebuild the five M2 bosses (FBX, atlas, groups.json) and render the sheet and per-boss pictures.
BL="${BLENDER:-D:/Games/steamapps/common/Blender/blender.exe}"
R="$(cd "$(dirname "$0")/../.." && pwd -W 2>/dev/null || pwd)"
python "$R/tools/blender/make_m2_bosses.py"
for id in z2_t2 z3_t3 z4_t4 z5_t5 z6_t6; do "$BL" -b --factory-startup --python "$R/tools/blender/build_boss.py" -- "$R/tools/blender/bosses/$id.json" 2>&1 | grep -E "^TRIS|Error|Traceback"; done
"$BL" -b --factory-startup --python "$R/tools/blender/render_six.py" -- "$R/team/verification/m2-six-bosses" all 2>&1 | grep -E "Error|Traceback|line "
