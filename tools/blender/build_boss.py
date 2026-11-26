"""Voxel boss builder (M1-03). Headless:
  blender -b --factory-startup --python tools/blender/build_boss.py -- tools/blender/bosses/z1_t1.json [--no-export]

Reads the layer data (fills of cubes), removes hidden faces, builds one mesh per moving group and exports two FBX
routes into assets-src/models/:
  <id>_atlas.fbx    one mesh per group, UVs into the shared boss-atlas (256x256, 32 px cells), one material
  <id>_perrole.fbx  one mesh per colour role per group, named <Group>_<role>, coloured later by MeshPart.Color
It also writes <id>.groups.json (pivots in Blender cube units, Blender studs and Roblox studs, triangle counts)
and boss-atlas.png (+ atlas_cells.json, an append-only hex -> cell registry shared by every boss).
1 Blender unit = 1 stud. Model origin = middle of the feet. Blender (x,y,z) lands at Roblox (-x, z, y); the front
of the boss is Blender -y (Roblox -Z). Geometry stays in model space (object origins at the model origin); the
group pivots are numbers in the sidecar, never read back from the FBX.
Also used as a library by build_gloves.py and render_boss.py."""
import bpy, bmesh, json, os, sys, math

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(REPO, "assets-src", "models")
CELL = 32
ATLAS = 256

# ---- data -> voxels --------------------------------------------------------------------------------------------
def _hash(x, y, z):
    return ((x * 73856093) ^ (y * 19349663) ^ (z * 83492791)) & 0x7FFFFFFF

def _pick(cols, x, y, z):
    return cols[_hash(x, y, z) % len(cols)]

def _cells(f):
    if "box" in f:
        x0, y0, z0, x1, y1, z1 = f["box"]
        for x in range(x0, x1):
            for y in range(y0, y1):
                for z in range(z0, z1):
                    yield x, y, z
    elif "cyl" in f:
        # cyl = [axis, c1, c2, r, lo, hi]: cubes with index lo..hi-1 along axis ("x"|"y"|"z") whose centre lies
        # within r of the line through (c1, c2) on the other two axes (in their x,y,z order)
        ax, c1, c2, r, lo, hi = f["cyl"]
        a = "xyz".index(ax)
        R = int(math.ceil(r)) + 1
        for t in range(lo, hi):
            for u in range(int(c1) - R, int(c1) + R + 1):
                for v in range(int(c2) - R, int(c2) + R + 1):
                    if (u + .5 - c1) ** 2 + (v + .5 - c2) ** 2 <= r * r:
                        p = [u, v]; p.insert(a, t)
                        yield tuple(p)
    elif "seg" in f:
        # seg = [x0,y0,z0, x1,y1,z1, r]: cubes whose centre lies within r of the segment (a capsule cut flat at the ends)
        x0, y0, z0, x1, y1, z1, r = f["seg"]
        d = (x1 - x0, y1 - y0, z1 - z0); L2 = sum(c * c for c in d) or 1e-9
        R = int(math.ceil(r)) + 1
        for x in range(int(min(x0, x1)) - R, int(max(x0, x1)) + R + 1):
            for y in range(int(min(y0, y1)) - R, int(max(y0, y1)) + R + 1):
                for z in range(int(min(z0, z1)) - R, int(max(z0, z1)) + R + 1):
                    w = (x + .5 - x0, y + .5 - y0, z + .5 - z0)
                    t = sum(a * b for a, b in zip(w, d)) / L2
                    if 0 <= t <= 1 and sum((a - t * b) ** 2 for a, b in zip(w, d)) <= r * r:
                        yield x, y, z
    else:
        cx, cy, cz, r = f["ball"]
        R = int(math.ceil(r)) + 1
        for x in range(int(cx) - R, int(cx) + R + 1):
            for y in range(int(cy) - R, int(cy) + R + 1):
                for z in range(int(cz) - R, int(cz) + R + 1):
                    if (x + .5 - cx) ** 2 + (y + .5 - cy) ** 2 + (z + .5 - cz) ** 2 <= r * r:
                        yield x, y, z

def voxelize(data):
    """Fills painted in order. `mirror` repeats the fill at x -> -x-1 (group `mirror_group` if given, colour hash
    taken from the source cube). `only_x` = [lo, hi) limits a fill to those x cube indices (before mirroring)."""
    vox = {}
    under = {}  # first cube of another group that a fill overwrote (restored if the overwriting group is yawed away)
    def put(k, v):
        old = vox.get(k)
        if old is not None and old[0] != v[0] and k not in under:
            under[k] = old
        vox[k] = v
    for f in data["fills"]:
        cols = f["c"]
        ox = f.get("only_x")
        paint = f.get("paint")  # M2 redo: recolour existing cubes only (lava cracks, star specks), adds none
        for x, y, z in _cells(f):
            if ox and not (ox[0] <= x < ox[1]):
                continue
            if paint and (x, y, z) not in vox:
                continue
            col = _pick(cols, x, y, z)
            put((x, y, z), (vox[(x, y, z)][0] if paint else f["g"], col))
            if f.get("mirror"):
                if paint and (-x - 1, y, z) not in vox:
                    continue
                g2 = vox[(-x - 1, y, z)][0] if paint else f.get("mirror_group", f["g"])
                put((-x - 1, y, z), (g2, col))
    # M2-24: a group may carry a rest "yaw" (degrees about z through its pivot; + turns the front (-y) toward +x).
    # The group's cubes are resampled on the grid (nearest source cube), so the pivot numbers never change.
    for g, spec in data.get("groups", {}).items():
        yaw = spec.get("yaw")
        if not yaw:
            continue
        px, py = spec["pivot"][0], spec["pivot"][1]
        src = {k: v for k, v in vox.items() if v[0] == g}
        for k in src:
            if k in under: vox[k] = under[k]
            else: del vox[k]
        a = math.radians(yaw); ca, sa = math.cos(a), math.sin(a)
        xs = [k[0] for k in src]; ys = [k[1] for k in src]; zs = sorted(set(k[2] for k in src))
        R = int(math.ceil(max(abs(min(xs) - px), abs(max(xs) + 1 - px), abs(min(ys) - py), abs(max(ys) + 1 - py)) * 1.5)) + 2
        for x in range(int(px) - R, int(px) + R + 1):
            for y in range(int(py) - R, int(py) + R + 1):
                dx, dy = x + .5 - px, y + .5 - py
                sx, sy = px + ca * dx + sa * dy, py - sa * dx + ca * dy   # inverse rotation
                ix, iy = int(math.floor(sx)), int(math.floor(sy))
                for z in zs:
                    v = src.get((ix, iy, z))
                    if v is not None:
                        vox[(x, y, z)] = v
    return vox

# six directions: normal, and the 4 corner offsets (CCW seen from outside)
DIRS = [
    ((1, 0, 0),  [(1,0,0),(1,1,0),(1,1,1),(1,0,1)]),
    ((-1, 0, 0), [(0,0,0),(0,0,1),(0,1,1),(0,1,0)]),
    ((0, 1, 0),  [(0,1,0),(0,1,1),(1,1,1),(1,1,0)]),
    ((0, -1, 0), [(0,0,0),(1,0,0),(1,0,1),(0,0,1)]),
    ((0, 0, 1),  [(0,0,1),(1,0,1),(1,1,1),(0,1,1)]),
    ((0, 0, -1), [(0,0,0),(0,1,0),(1,1,0),(1,0,0)]),
]

def faces(vox, keep_seams=True):
    """-> list of (group, role, dirindex, (x,y,z))"""
    out = []
    for (x, y, z), (g, role) in vox.items():
        for di, (n, _) in enumerate(DIRS):
            nb = vox.get((x + n[0], y + n[1], z + n[2]))
            if nb is None:
                out.append((g, role, di, (x, y, z)))
            elif keep_seams and nb[0] != g:
                out.append((g, role, di, (x, y, z)))
    return out

def merged_count(fs):
    """Quads after greedy rectangle merge of same group/role/plane faces (a count only, for the per-role note)."""
    from collections import defaultdict
    planes = defaultdict(set)
    for g, role, di, (x, y, z) in fs:
        ax = 0 if DIRS[di][0][0] else (1 if DIRS[di][0][1] else 2)
        pos = (x, y, z)
        u, v = [a for a in range(3) if a != ax]
        planes[(g, role, di, pos[ax])].add((pos[u], pos[v]))
    q = 0
    for cells in planes.values():
        left = set(cells)
        while left:
            u0, v0 = min(left)
            w = 1
            while (u0 + w, v0) in left: w += 1
            h = 1
            while all((u0 + i, v0 + h) in left for i in range(w)): h += 1
            for i in range(w):
                for j in range(h): left.discard((u0 + i, v0 + j))
            q += 1
    return q

# ---- atlas -----------------------------------------------------------------------------------------------------
def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))

def srgb_to_lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def cell_registry(hexes):
    path = os.path.join(HERE, "atlas_cells.json")
    reg = json.load(open(path)) if os.path.exists(path) else {}
    for h in hexes:
        h = h.upper()
        if h not in reg:
            reg[h] = len(reg)
    assert len(reg) <= (ATLAS // CELL) ** 2, "atlas full"
    json.dump(reg, open(path, "w"), indent=1, sort_keys=True)
    return reg

def write_atlas(reg):
    import numpy as np
    n = ATLAS // CELL
    img = np.zeros((ATLAS, ATLAS, 4), dtype=np.float32)
    img[..., :3] = 0.5; img[..., 3] = 1
    for h, c in reg.items():
        col, row = c % n, c // n  # row counted from the top
        rgb = np.array(hex_rgb(h), dtype=np.float32)  # sRGB values; image is saved as sRGB
        y0 = ATLAS - (row + 1) * CELL
        x0 = col * CELL
        blk = np.empty((CELL, CELL, 4), dtype=np.float32)
        blk[..., :3] = rgb; blk[..., 3] = 1
        edge = np.clip(rgb * 0.88, 0, 1)
        blk[:2, :, :3] = edge; blk[-2:, :, :3] = edge; blk[:, :2, :3] = edge; blk[:, -2:, :3] = edge
        img[y0:y0 + CELL, x0:x0 + CELL] = blk
    im = bpy.data.images.new("boss-atlas", ATLAS, ATLAS, alpha=False)
    im.colorspace_settings.name = "sRGB"
    # pixels are written raw into an sRGB-tagged image: store the sRGB numbers directly
    im.pixels = img.ravel()
    im.filepath_raw = os.path.join(OUT, "boss-atlas.png")
    im.file_format = "PNG"
    im.save()
    return im

# ---- meshes ----------------------------------------------------------------------------------------------------
def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def build_mesh(name, fs, cube, reg=None):
    """fs: list of (group, role, dirindex, cube). reg: hex registry + palette for UVs (atlas) or None."""
    verts, vmap, polys, uvs = [], {}, [], []
    def vid(p):
        if p not in vmap:
            vmap[p] = len(verts); verts.append(p)
        return vmap[p]
    n = ATLAS // CELL
    for g, role, di, (x, y, z), cellidx in fs:
        quad = [vid((x + dx, y + dy, z + dz)) for dx, dy, dz in DIRS[di][1]]
        polys.append(quad)
        if cellidx is not None:
            col, row = cellidx % n, cellidx // n
            u0, u1 = (col * CELL + 1) / ATLAS, (col * CELL + CELL - 1) / ATLAS
            v1 = 1 - (row * CELL + 1) / ATLAS
            v0 = 1 - (row * CELL + CELL - 1) / ATLAS
            uvs.append([(u0, v0), (u1, v0), (u1, v1), (u0, v1)])
    me = bpy.data.meshes.new(name)
    me.from_pydata([(a * cube, b * cube, c * cube) for a, b, c in verts], [], polys)
    if uvs:
        layer = me.uv_layers.new(name="UVMap")
        for pi, poly in enumerate(me.polygons):
            for li, loop in enumerate(poly.loop_indices):
                layer.data[loop].uv = uvs[pi][li]
    me.polygons.foreach_set("use_smooth", [False] * len(me.polygons))
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob

def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)

def material_flat(name, hexc):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    r, g, b = [srgb_to_lin(c) for c in hex_rgb(hexc)]
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (r, g, b, 1)
    bsdf.inputs["Roughness"].default_value = 1.0
    m.diffuse_color = (r, g, b, 1)
    return m

def material_atlas(im):
    m = bpy.data.materials.new("boss-atlas")
    m.use_nodes = True
    t = m.node_tree.nodes.new("ShaderNodeTexImage")
    t.image = im; t.interpolation = "Closest"
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 1.0
    m.node_tree.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
    return m

def export_fbx(path, objs):
    for o in bpy.data.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(
        filepath=path, use_selection=True, object_types={"MESH"}, apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z", axis_up="Y", use_mesh_modifiers=True, mesh_smooth_type="FACE",
        bake_anim=False, add_leaf_bones=False, path_mode="COPY", embed_textures=False)

def build_all(data, export=True, out=OUT, build_name=None):
    """Builds both routes in the current (cleared) scene. Returns a report dict and the object lists."""
    os.makedirs(out, exist_ok=True)
    cube = data["cube"]
    vox = voxelize(data)
    fs = faces(vox)
    fs_noseam = faces(vox, keep_seams=False)
    pal = data["palette"]
    reg = cell_registry([pal[k] for k in pal])
    im = write_atlas(reg)
    groups = list(data["groups"].keys())
    rep = {"id": data["id"], "cube": cube, "cubes": len(vox),
           "bbox_cubes": [min(k[i] for k in vox) for i in range(3)] + [max(k[i] for k in vox) + 1 for i in range(3)]}
    # atlas route
    atlas_objs = []
    am = material_atlas(im)
    for g in groups:
        gf = [(g_, r, di, c, reg[pal[r].upper()]) for g_, r, di, c in fs if g_ == g]
        if not gf: continue
        ob = build_mesh(g, gf, cube); ob.data.materials.append(am); ob["route"] = "atlas"
        atlas_objs.append(ob)
    # per-role route
    role_objs = []
    for g in groups:
        for r in pal:
            gf = [(g_, r_, di, c, None) for g_, r_, di, c in fs if g_ == g and r_ == r]
            if not gf: continue
            ob = build_mesh("%s_%s" % (g, r), gf, cube)
            ob.data.materials.append(material_flat("role_" + r, pal[r])); ob["route"] = "perrole"; ob["group"] = g; ob["role"] = r
            role_objs.append(ob)
    rep["tris_atlas"] = sum(tris(o) for o in atlas_objs)
    rep["meshes_atlas"] = [(o.name, tris(o)) for o in atlas_objs]
    rep["tris_perrole"] = sum(tris(o) for o in role_objs)
    rep["meshes_perrole"] = [(o.name, tris(o)) for o in role_objs]
    rep["tris_atlas_no_seam_faces"] = len(fs_noseam) * 2
    rep["tris_perrole_greedy_merged_count_only"] = merged_count(fs) * 2
    rep["size_studs_blender_xyz"] = [round((rep["bbox_cubes"][i + 3] - rep["bbox_cubes"][i]) * cube, 3) for i in range(3)]
    rep["size_studs_roblox_xyz"] = [rep["size_studs_blender_xyz"][0], rep["size_studs_blender_xyz"][2], rep["size_studs_blender_xyz"][1]]
    gp = {}
    for g, v in data["groups"].items():
        px, py, pz = [c * cube for c in v["pivot"]]
        gp[g] = {"pivot_cubes_blender": v["pivot"], "pivot_studs_blender": [round(px, 4), round(py, 4), round(pz, 4)],
                 "pivot_studs_roblox_offset_from_model_pivot": [round(-px, 4), round(pz, 4), round(py, 4)]}
    rep["groups"] = gp
    if export:
        base = os.path.join(out, data["id"])
        export_fbx(base + "_atlas.fbx", atlas_objs)
        export_fbx(base + "_perrole.fbx", role_objs)
        json.dump(rep, open(base + ".groups.json", "w"), indent=1)
    return rep, atlas_objs, role_objs

def load(path):
    return json.load(open(path))

if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    clear_scene()
    data = load(argv[0])
    rep, _, _ = build_all(data, export="--no-export" not in argv)
    print("REPORT " + json.dumps(rep))
    print("TRIS atlas=%d perrole=%d (greedy-merged count %d, no-seam-faces %d)  size studs (Roblox X,Y,Z)=%s"
          % (rep["tris_atlas"], rep["tris_perrole"], rep["tris_perrole_greedy_merged_count_only"],
             rep["tris_atlas_no_seam_faces"], rep["size_studs_roblox_xyz"]))
