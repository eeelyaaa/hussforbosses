"""M2 renders of the six pictured bosses (Workbench-free EEVEE, atlas texture). Headless:
  blender -b --factory-startup --python tools/blender/render_six.py -- OUTDIR [sheet|each|all] [id ...]
sheet: all six in one scene in creatures.png's order, same angle, true relative size -> m2_sheet.png and m2_sheet_vs_picture.png
each : per boss guard pose (rest), signature impact pose (static, rotated about the pivots in the data), and a beside-picture crop.
Never exports FBX. Atlas build writes boss-atlas.png only (the shared registry)."""
import bpy, sys, os, json, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_boss as B
import render_boss as R
from mathutils import Matrix, Vector

ORDER = ["z1_t1", "z2_t2", "z3_t3", "z4_t4", "z5_t5", "z6_t6"]
# crops of creatures.png in original pixels (x0, y0, x1, y1, top-left origin)
PIC = {"z1_t1": (0, 950, 330, 1195), "z2_t2": (300, 800, 665, 1195), "z3_t3": (625, 780, 985, 1195),
       "z4_t4": (962, 660, 1462, 1195), "z5_t5": (1348, 470, 2011, 1195), "z6_t6": (1984, 130, 2800, 1195)}
PARENT = {"Head": "Upper", "FistL": "Upper", "FistR": "Upper", "TailB": "TailA"}  # only for the swayer's Upper; others are flat
# signature impact poses: (group, axis, degrees), applied in order, children follow their parent
IMPACT = {
    "z1_t1": [("Sig", "X", 25), ("FistR", "X", -40)],
    "z2_t2": [("TailA", "X", 55), ("TailB", "X", 40), ("FistL", "X", -35)],           # tail sting over the head
    "z3_t3": [("Upper", "X", 30), ("Head", "X", 12), ("FistR", "X", -30)],             # lunge from the base, jaws first
    "z4_t4": [("FistR", "X", -55), ("Head", "X", 12), ("FistL", "X", 10)],             # heavy right straight
    "z5_t5": [("TailA", "Z", 85), ("TailB", "Z", 45), ("FistL", "X", -30)],            # tail club swings round to the front
    "z6_t6": [("FistR", "X", -125), ("FistL", "X", -45), ("Sig", "Y", 20)],            # right fist overhead, halo tilts
}

def build(cid, offset=(0, 0, 0)):
    data = B.load(os.path.join(B.HERE, "bosses", cid + ".json"))
    rep, objs, roles = B.build_all(data, export=False)
    for o in roles: bpy.data.objects.remove(o)
    names = {}
    for o in objs:
        o.name = cid + ":" + o.name; o.location = offset; names[o.name.split(":")[1]] = o
    return data, rep, names

def pivot_world(data, g, ob):
    p = Vector([c * data["cube"] for c in data["groups"][g]["pivot"]])
    return ob.matrix_world @ p

def rot(ob, P, axis, deg):
    return Matrix.Translation(P) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-P)

def pose(data, names, spec):
    kids = {"Upper": ["Head", "FistL", "FistR"], "TailA": ["TailB"]}
    for g, axis, deg in spec:
        if g not in names: continue
        P = pivot_world(data, g, names[g])
        M = rot(names[g], P, axis, deg)
        for n in [g] + kids.get(g, []):
            if n in names: names[n].matrix_world = M @ names[n].matrix_world

def crop_pic(box, scale):
    import numpy as np
    im = bpy.data.images.load(R.PICTURE)
    w, h = im.size
    a = np.array(im.pixels[:]).reshape(h, w, 4)
    x0, y0, x1, y1 = box
    return a[h - y1:h - y0, x0:x1][::scale, ::scale] if scale > 1 else a[h - y1:h - y0, x0:x1]

def load_png(path):
    import numpy as np
    im = bpy.data.images.load(path)
    return np.array(im.pixels[:]).reshape(im.size[1], im.size[0], 4)

def save_arr(C, out):
    im = bpy.data.images.new("o_" + os.path.basename(out), C.shape[1], C.shape[0])
    im.pixels = C.ravel(); im.filepath_raw = out; im.file_format = "PNG"; im.save()

def stack_v(a, b, gap=10):
    import numpy as np
    W = max(a.shape[1], b.shape[1])
    def padw(X):
        o = np.ones((X.shape[0], W, 4), dtype=np.float32); o[:, :X.shape[1]] = X; return o
    return np.concatenate([padw(a), np.ones((gap, W, 4), dtype=np.float32), padw(b)], axis=0)

def side_by_side(a, b, gap=12):
    import numpy as np
    H = max(a.shape[0], b.shape[0])
    def padh(X):
        o = np.ones((H, X.shape[1], 4), dtype=np.float32); o[H - X.shape[0]:] = X; return o
    return np.concatenate([padh(a), np.ones((H, gap, 4), dtype=np.float32), padh(b)], axis=1)

def ortho_camera(az, el, target, scale):
    cam = bpy.data.cameras.new("oc"); cam.type = "ORTHO"; cam.ortho_scale = scale
    co = bpy.data.objects.new("oc", cam); bpy.context.scene.collection.objects.link(co)
    a, e = math.radians(az), math.radians(el)
    pos = Vector((-math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))) * 120 + Vector(target)
    co.location = pos
    co.rotation_euler = (Vector(target) - pos).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = co

def do_sheet(outdir):
    B.clear_scene()
    R.setup_render(2800, 900)
    x = 0.0; xs = {}
    widths = {"z1_t1": 8, "z2_t2": 9, "z3_t3": 12, "z4_t4": 12, "z5_t5": 20, "z6_t6": 22}
    for cid in ORDER:
        w = widths[cid]
        x += w / 2
        build(cid, (x, 0, 0)); xs[cid] = x
        x += w / 2 + 1.0
    bpy.data.objects["Plane"].location = (x / 2, 0, -0.05); bpy.data.objects["Plane"].scale = (30, 30, 1)
    sc = bpy.context.scene
    ortho_camera(24, 8, (x / 2, 0, 7.2), x * 0.98 * math.cos(math.radians(24)) + 2)
    R.render(os.path.join(outdir, "m2_sheet.png"))
    pic = crop_pic((0, 110, 2800, 1195), 1)
    mine = load_png(os.path.join(outdir, "m2_sheet.png"))
    # scale the render to the picture crop's width by simple repeat/stride is overkill: put both at their own size, stacked
    save_arr(stack_v(pic, mine), os.path.join(outdir, "m2_sheet_vs_picture.png"))

def do_each(outdir, ids, guard_only=False):
    for cid in ids:
        B.clear_scene()
        R.setup_render(900, 900)
        data, rep, names = build(cid)
        bb, cu = rep["bbox_cubes"], data["cube"]
        tgt = ((bb[0] + bb[3]) / 2 * cu, (bb[1] + bb[4]) / 2 * cu, (bb[2] + bb[5]) / 2 * cu)
        dist = max(bb[3] - bb[0], bb[4] - bb[1], bb[5] - bb[2]) * cu * 2.3
        bpy.data.objects["Plane"].location.z = -0.02
        R.camera(24, 10, dist, tgt)
        R.render(os.path.join(outdir, cid + "_guard.png"))
        if guard_only:
            R.camera(110, 8, dist, tgt); R.render(os.path.join(outdir, cid + "_side.png"))
            R.camera(24, 10, dist, tgt)
        pose(data, names, IMPACT[cid])
        R.render(os.path.join(outdir, cid + "_impact.png"))
        pic = crop_pic(PIC[cid], 1)
        # picture crop scaled to the render height by stride/repeat
        import numpy as np
        f = 900.0 / pic.shape[0]
        if f > 1:
            k = int(round(f)); pic = np.kron(pic, np.ones((k, k, 1), dtype=np.float32))
        else:
            k = int(math.ceil(1 / f)); pic = pic[::k, ::k]
        g = load_png(os.path.join(outdir, cid + "_guard.png"))
        save_arr(side_by_side(pic, g), os.path.join(outdir, cid + "_vs_picture.png"))

def do_turn(outdir, ids, az):
    for cid in ids:
        B.clear_scene()
        R.setup_render(900, 900)
        data, rep, names = build(cid)
        bb, cu = rep["bbox_cubes"], data["cube"]
        tgt = ((bb[0] + bb[3]) / 2 * cu, (bb[1] + bb[4]) / 2 * cu, (bb[2] + bb[5]) / 2 * cu)
        dist = max(bb[3] - bb[0], bb[4] - bb[1], bb[5] - bb[2]) * cu * 2.3
        bpy.data.objects["Plane"].location.z = -0.02
        R.camera(az, 10, dist, tgt)
        R.render(os.path.join(outdir, "%s_az%d.png" % (cid, az)))

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:]
    outdir = argv[0]; os.makedirs(outdir, exist_ok=True)
    mode = argv[1] if len(argv) > 1 else "all"
    ids = argv[2:] or ORDER
    if mode in ("sheet", "all"): do_sheet(outdir)
    if mode in ("each", "all"): do_each(outdir, ids)
    if mode == "quick": do_each(outdir, ids, guard_only=True)  # iteration: guard + side view + beside-picture
    if mode == "turn": do_turn(outdir, ids, 40)  # M2-24: the picture's own angle (about 40 degrees) -> <id>_az40.png
