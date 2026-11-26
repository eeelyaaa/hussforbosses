"""Frog beside an R15-sized block avatar (5 studs tall incl. head, 2 wide), side and 3/4 views, for scale.
  blender -b --factory-startup --python tools/blender/render_size.py -- tools/blender/bosses/z1_t1.json OUTDIR"""
import bpy, sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_boss as B
import render_boss as R
argv = sys.argv[sys.argv.index("--") + 1:]
data = B.load(argv[0]); outdir = argv[1]; os.makedirs(outdir, exist_ok=True)
B.clear_scene()
rep, atlas_objs, role_objs = B.build_all(data, export=False)
for o in role_objs: bpy.data.objects.remove(o)
R.setup_render(1100, 700)
def box(name, size, centre, hexc):
    bpy.ops.mesh.primitive_cube_add(size=1, location=centre)
    o = bpy.context.active_object; o.name = name; o.scale = size
    o.data.materials.append(B.material_flat(name, hexc)); return o
# avatar at 4 studs in front of the frog (frog front = Blender -y), R15 proportions: legs 2, torso 2, head 1 -> about 5.2 tall
x, y = 0.0, -5.0
box("legs", (1.6, 1.0, 2.0), (x, y, 1.0), "#2B4DA0")
box("torso", (2.0, 1.0, 2.0), (x, y, 3.0), "#E02A2A")
box("head", (1.2, 1.2, 1.2), (x, y, 4.6), "#F5CD30")
box("armL", (1.0, 1.0, 2.0), (x - 1.5, y, 3.0), "#F5CD30"); box("armR", (1.0, 1.0, 2.0), (x + 1.5, y, 3.0), "#F5CD30")
R.camera(70, 8, 17, (0, -2.0, 2.2), lens=50)
R.render(os.path.join(outdir, "z1_t1_size_side.png"))
R.camera(25, 12, 17, (0, -2.0, 2.2), lens=50)
R.render(os.path.join(outdir, "z1_t1_size_front.png"))
