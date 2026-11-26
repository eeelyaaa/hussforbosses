"""Boxing gloves builder (M1-03). Headless:
  blender -b --factory-startup --python tools/blender/build_gloves.py -- tools/blender/bosses/gloves.json
Same builder as the bosses (build_boss.py): both routes into assets-src/models/ (gloves_atlas.fbx, gloves_perrole.fbx,
gloves.groups.json). Meshes GloveL and GloveR (real mirror, built for both sides); pivot = the wrist."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_boss as B, json
argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [os.path.join(B.HERE, "bosses", "gloves.json")]
B.clear_scene()
rep, _, _ = B.build_all(B.load(argv[0]), export="--no-export" not in argv)
print("REPORT " + json.dumps(rep))
print("TRIS atlas=%d perrole=%d size studs (Roblox X,Y,Z)=%s" % (rep["tris_atlas"], rep["tris_perrole"], rep["size_studs_roblox_xyz"]))
