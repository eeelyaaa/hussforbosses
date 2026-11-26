"""Render a boss from its data (Workbench, atlas texture so the cube edges read) and a side-by-side with its picture.
  blender -b --factory-startup --python tools/blender/render_boss.py -- tools/blender/bosses/z1_t1.json OUTDIR [--pose]
Writes OUTDIR/<id>_render.png (guard view, the picture's angle), OUTDIR/<id>_vs_picture.png (picture crop | render),
and with --pose OUTDIR/<id>_pivots.png (Sig opened 25 deg about its hinge, FistL raised 40 deg about its shoulder,
FistR turned 30 deg, to prove the pivots). Never exports FBX."""
import bpy, sys, os, json, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_boss as B
from mathutils import Matrix, Vector

CROPS = {"z1_t1": (0, 950, 330, 1195)}  # x0,y0,x1,y1 in creatures.png top-left pixels: the frog and its ground line
PICTURE = os.path.join(B.REPO, "team", "pack", "concepts", "brick-brawl", "creatures.png")

def setup_render(w, h):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = w, h
    sc.view_settings.view_transform = "Standard"
    w_ = bpy.data.worlds.new("w"); w_.use_nodes = True
    bg = w_.node_tree.nodes["Background"]; bg.inputs["Color"].default_value = (0.55, 0.72, 1.0, 1); bg.inputs["Strength"].default_value = 0.9
    sc.world = w_
    sun = bpy.data.lights.new("sun", "SUN"); sun.energy = 3.2; sun.angle = math.radians(12)
    so = bpy.data.objects.new("sun", sun); bpy.context.scene.collection.objects.link(so)
    so.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
    # ground slab
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    g = bpy.context.active_object
    gm = B.material_flat("ground", "#3DAA3C"); g.data.materials.append(gm)
    g.data.polygons[0].use_smooth = False

def camera(az_deg, elev_deg, dist, target, lens=70):
    cam = bpy.data.cameras.new("cam"); cam.lens = lens
    co = bpy.data.objects.new("cam", cam); bpy.context.scene.collection.objects.link(co)
    az, el = math.radians(az_deg), math.radians(elev_deg)
    # azimuth 0 = in front of the boss (Blender -y); positive turns toward the boss's right (Blender -x)
    pos = Vector((-math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el))) * dist + Vector(target)
    co.location = pos
    d = Vector(target) - pos
    co.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = co
    return co

def rotate_about(ob, pivot, axis, deg):
    p = Vector(pivot)
    ob.matrix_world = Matrix.Translation(p) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-p) @ ob.matrix_world

def render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)

def compose(picture_crop, render_png, out):
    import numpy as np
    a = bpy.data.images.load(picture_crop); b = bpy.data.images.load(render_png)
    A = np.array(a.pixels[:]).reshape(a.size[1], a.size[0], 4); Bm = np.array(b.pixels[:]).reshape(b.size[1], b.size[0], 4)
    H = max(A.shape[0], Bm.shape[0])
    def pad(X):
        o = np.ones((H, X.shape[1], 4), dtype=np.float32) * np.array([1, 1, 1, 1], dtype=np.float32)
        o[:X.shape[0]] = X; return o
    C = np.concatenate([pad(A), np.ones((H, 12, 4), dtype=np.float32), pad(Bm)], axis=1)
    im = bpy.data.images.new("cmp", C.shape[1], C.shape[0]); im.pixels = C.ravel()
    im.filepath_raw = out; im.file_format = "PNG"; im.save()

def crop_picture(box, scale, out):
    import numpy as np
    im = bpy.data.images.load(PICTURE)
    w, h = im.size
    a = np.array(im.pixels[:]).reshape(h, w, 4)
    x0, y0, x1, y1 = box
    sub = a[h - y1:h - y0, x0:x1]
    sub = np.kron(sub, np.ones((scale, scale, 1), dtype=np.float32))
    o = bpy.data.images.new("crop", sub.shape[1], sub.shape[0]); o.pixels = sub.ravel()
    o.filepath_raw = out; o.file_format = "PNG"; o.save()
    return sub.shape[1], sub.shape[0]

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:]
    data = B.load(argv[0]); outdir = argv[1]; os.makedirs(outdir, exist_ok=True)
    B.clear_scene()
    rep, atlas_objs, role_objs = B.build_all(data, export=False)
    for o in role_objs: bpy.data.objects.remove(o)
    setup_render(1100, 980)
    cid = data["id"]
    bb, cu = rep["bbox_cubes"], data["cube"]
    if cid in CROPS:
        tgt, dist = (0, 0, 1.8), 14.5
    else:  # anything else: frame its bounding box
        tgt = ((bb[0] + bb[3]) / 2 * cu, (bb[1] + bb[4]) / 2 * cu, (bb[2] + bb[5]) / 2 * cu)
        dist = max(bb[3] - bb[0], bb[4] - bb[1], bb[5] - bb[2]) * cu * 2.2
    if cid not in CROPS:
        bpy.data.objects["Plane"].location.z = bb[2] * cu - 0.05
    camera(24, 10, dist, tgt)
    render(os.path.join(outdir, cid + "_render.png"))
    if cid in CROPS:
        box = CROPS[cid]
        crop_picture(box, 4, os.path.join(outdir, cid + "_picture_crop.png"))
        compose(os.path.join(outdir, cid + "_picture_crop.png"), os.path.join(outdir, cid + "_render.png"),
                os.path.join(outdir, cid + "_vs_picture.png"))
    if "--pose" in argv:
        piv = {g: [c * data["cube"] for c in v["pivot"]] for g, v in data["groups"].items()}
        for o in atlas_objs:
            if o.name == "Sig": rotate_about(o, piv["Sig"], "X", 25)       # opens the jaw (front goes down)
            if o.name == "Head": rotate_about(o, piv["Head"], "X", 0)
            if o.name == "FistL": rotate_about(o, piv["FistL"], "X", -40)
            if o.name == "FistR": rotate_about(o, piv["FistR"], "Z", 30)
        render(os.path.join(outdir, cid + "_pivots.png"))
