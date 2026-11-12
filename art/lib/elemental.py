"""Spirits, plants and constructs: helpers for the monster scripts of that group (golem, plant,
mushroom, blob, storm, tome, wisp, wraith).

* ``hewn``: a block of hewn or fractured stone.  Real stone breaks along planes, so a construct of
  stone reads as stone when it is built of a few big *convex* chunks whose faces are flat planes
  meeting in narrow chamfered edges, not of round boulders.  The chunk is the exact intersection
  of a (tapered) box with a few random cutting planes, bevelled, and shaded with *hardened*
  normals: every vertex of a big face takes that face's normal, so in the game's two-tone cel
  ramp each face is one clean plane of light or shadow and only the narrow bevels turn (the
  "harden normals" set-up of stylised hard-surface and rock modelling).  The vertex greys follow
  the planes - tops lighter, undersides darker, the worn edges lighter still - so the value
  design survives the game's tint.
  ``rock=n`` makes it a fractured boulder instead (``rock_planes``: broken planes round an
  ellipsoid); ``crack`` lays a glowing zig-zag fracture over a block, ``surface_point`` finds where
  a ray leaves one.
* ``bark``: a tree limb whose bark is split into long plates by deep, dark fissures, with hooks to
  carve a face into it (``carve``) and repaint it (``shade``).
* ``leaf_clump``: a mass of foliage, scalloped by smaller lobes, light above and dark beneath, with
  shingled leaves breaking its outline.
* ``decal``: a flat shape (a mouth, a mark) laid onto a surface by ray-casting.
* ``frame_y``: a rotation whose local +Y runs along a direction (aligning a chunk with a bone).

Everything is in Godot space, like the rest of the kit.
"""

import itertools
import math
import random

import bmesh
from mathutils import Matrix, Vector

from kit import MAT_TOON, STONE, THIN, V, euler_g, g2b, mix

# the game's toon ramp is lit from above and in front: a plane is shaded by how much it faces up
_UP = Vector((0.0, 1.0, 0.0))


def frame_y(d, fwd=(0.0, 0.0, 1.0)):
    """A 3x3 rotation (Godot space) whose local +Y runs along `d`, its local +Z as close to `fwd`
    as the direction allows."""
    y = V(d).normalized()
    f = V(fwd)
    x = y.cross(f)
    if x.length < 1e-5:
        x = y.cross(V(1.0, 0.0, 0.0))
    x.normalize()
    z = x.cross(y).normalized()
    return Matrix((x, y, z)).transposed()


def _as_rot(rot):
    if rot is None:
        return Matrix.Identity(3)
    if isinstance(rot, Matrix):
        return rot.to_3x3()
    return euler_g(rot)


def rock_planes(half, seed, n=14, rough=(0.86, 1.0), taper=1.0, extra=()):
    """Half-spaces of a fractured boulder: `n` planes spread evenly round an ellipsoid of half sizes
    `half` (a Fibonacci sphere, jittered), each set back from the ellipsoid by a random share
    `rough` of its reach, so the stone is all broken planes with no box left in it.  `taper`
    shrinks the top (+Y) half."""
    hx, hy, hz = half
    rnd = random.Random(seed * 7907 + 29)
    planes = []
    for i in range(n):
        y = 1.0 - 2.0 * (i + 0.5) / n
        r = math.sqrt(max(0.0, 1.0 - y * y))
        a = i * 2.399963 + rnd.uniform(-0.5, 0.5)
        d = Vector((math.cos(a) * r, y, math.sin(a) * r))
        d = (d + Vector((rnd.uniform(-0.25, 0.25), rnd.uniform(-0.25, 0.25), rnd.uniform(-0.25, 0.25)))).normalized()
        sx = hx * (taper if d.y > 0 else 1.0)
        sz = hz * (taper if d.y > 0 else 1.0)
        # the normal of the ellipsoid's tangent plane at its point in direction d, and the reach there
        p = Vector((d.x * sx, d.y * hy, d.z * sz))
        nv = Vector((p.x / (sx * sx), p.y / (hy * hy), p.z / (sz * sz))).normalized()
        reach = math.sqrt((nv.x * sx) ** 2 + (nv.y * hy) ** 2 + (nv.z * sz) ** 2)
        planes.append((nv, reach * rnd.uniform(rough[0], rough[1])))
    # keep the boulder closed whatever the draw: a loose box round it
    for ax, h in ((Vector((1, 0, 0)), hx), (Vector((0, 1, 0)), hy), (Vector((0, 0, 1)), hz)):
        planes.append((ax.copy(), h * 1.02))
        planes.append((-ax, h * 1.02))
    for nv, dd in extra:
        planes.append((V(nv).normalized(), dd))
    return planes


def chunk_planes(half, seed, taper=(1.0, 1.0), cuts=5, depth=(0.08, 0.28), base=(1.0, 1.0), extra=()):
    """Half-spaces n.p <= d (local space) of a hewn block: a box of half sizes `half` whose top is
    scaled by `taper` (x, z) and bottom by `base`, shaved by `cuts` random planes that take
    `depth` (a fraction of the reach in that direction) off its corners and edges.  `extra` adds
    planes of your own as (normal, d)."""
    hx, hy, hz = half
    tx, tz = taper
    bx, bz = base
    planes = [(_UP.copy(), hy), (Vector((0.0, -1.0, 0.0)), hy)]
    # the sides lean in to the tapered top (or out to a wider base)
    for sx in (1.0, -1.0):
        n = Vector((2.0 * hy * sx, hx * (bx - tx), 0.0)).normalized()
        planes.append((n, n.dot(Vector((sx * hx * bx, -hy, 0.0)))))
    for sz in (1.0, -1.0):
        n = Vector((0.0, hz * (bz - tz), 2.0 * hy * sz)).normalized()
        planes.append((n, n.dot(Vector((0.0, -hy, sz * hz * bz)))))
    corners = [Vector((sx * hx * (tx if sy > 0 else bx), sy * hy, sz * hz * (tz if sy > 0 else bz)))
               for sx in (1, -1) for sy in (1, -1) for sz in (1, -1)]
    rnd = random.Random(seed * 7919 + 13)
    for _ in range(cuts):
        # mostly corners and edges: a random octant, nudged
        n = Vector((rnd.choice((-1, 1)) / hx, rnd.uniform(-0.6, 1.0) / hy, rnd.choice((-1, 1)) / hz))
        n = (n.normalized() + Vector((rnd.uniform(-0.35, 0.35), rnd.uniform(-0.35, 0.35), rnd.uniform(-0.35, 0.35)))).normalized()
        reach = max(n.dot(c) for c in corners)
        planes.append((n, reach * (1.0 - rnd.uniform(depth[0], depth[1]))))
    for n, d in extra:
        planes.append((V(n).normalized(), d))
    return planes


def _polytope(planes):
    """Vertices of the convex polytope {p: n.p <= d for every plane}."""
    pts = []
    for a, b, c in itertools.combinations(planes, 3):
        M = Matrix((a[0], b[0], c[0]))
        if abs(M.determinant()) < 1e-7:
            continue
        x = M.inverted() @ Vector((a[1], b[1], c[1]))
        if all(n.dot(x) <= d + 1e-6 for n, d in planes):
            if not any((x - q).length < 1e-5 for q in pts):
                pts.append(x)
    return pts


def hewn(b, c, half, seed, bone, rot=None, taper=(1.0, 1.0), base=(1.0, 1.0), cuts=5, depth=(0.08, 0.28), bevel=0.02,
         shade=0.78, var=0.06, tint=1.0, cls=STONE, mat=MAT_TOON, edge=0.1, extra=(), col_fn=None, dark_below=None, pal=None,
         face_var=0.07, jitter=0.0, rock=0):
    """A block of hewn stone centred on `c` (see the module notes).  `bone` is a bone name, a dict
    of weights or a callable(position) -> weights.  The grey of a vertex is `shade` (varied by
    `var` per block and `face_var` per plane, so neighbouring facets read apart) lifted on planes
    facing up and lowered on planes facing down, the bevelled edges `edge` lighter; `dark_below` =
    (y0, y1, k) darkens everything below y1 by up to k at y0 (the value grouping of a figure: lit
    above, heavy and dark at the feet).  `jitter` turns the block a little off the rotation it was
    given (no two blocks of a wall sit square).  `col_fn(p, n, grey)` may repaint any vertex (moss,
    lichen, scorch).  With `rock` > 0 the block is a fractured boulder of that many planes instead
    (``rock_planes``; `taper` then shrinks its top).  Returns (verts, planes in world space)."""
    R = _as_rot(rot)
    if jitter > 0.0:
        jr = random.Random(seed * 17 + 3)
        R = R @ euler_g((jr.uniform(-jitter, jitter), jr.uniform(-jitter, jitter), jr.uniform(-jitter, jitter)))
    c = V(c)
    if rock:
        planes = rock_planes(half, seed, rock, (1.0 - depth[1] * 0.45, 1.0 - depth[0] * 0.3), taper[0], extra)
    else:
        planes = chunk_planes(half, seed, taper, cuts, depth, base, extra)
    pts = _polytope(planes)
    bm = bmesh.new()
    vs = [bm.verts.new(p) for p in pts]
    bmesh.ops.convex_hull(bm, input=vs)
    bmesh.ops.dissolve_limit(bm, angle_limit=0.002, verts=bm.verts[:], edges=bm.edges[:])
    bm.normal_update()
    made = set()
    if bevel > 0.0:
        res = bmesh.ops.bevel(bm, geom=bm.edges[:] + bm.verts[:], offset=bevel, segments=2, profile=0.5, affect="EDGES", clamp_overlap=True)
        made = set(res["faces"])
    bm.normal_update()
    bm.verts.index_update()
    # hardened normals: a vertex of a big face takes that face's normal; the bevels blend
    rnd = random.Random(seed * 31 + 5)
    fval = {f: 1.0 + rnd.uniform(-face_var, face_var) for f in bm.faces if f not in made}
    nrm = []
    on_edge = []
    fk = []
    for v in bm.verts:
        big = [f for f in v.link_faces if f not in made]
        if big:
            n = Vector((0.0, 0.0, 0.0))
            k = 0.0
            for f in big:
                n += f.normal * f.calc_area()
                k += fval[f]
            nrm.append(n.normalized() if n.length > 1e-9 else v.normal.copy())
            on_edge.append(False)
            fk.append(k / len(big))
        else:
            nrm.append(v.normal.copy())
            on_edge.append(True)
            fk.append(1.0)
    g0 = shade * (1.0 + rnd.uniform(-var, var))
    verts = []
    cols = []
    for i, v in enumerate(bm.verts):
        p = c + R @ v.co
        n = (R @ nrm[i]).normalized()
        up = n.dot(_UP)
        g = g0 * fk[i] * (1.0 + 0.16 * max(0.0, up) - 0.3 * max(0.0, -up))
        if on_edge[i]:
            g += edge
        if dark_below is not None:
            y0, y1, k = dark_below
            t = max(0.0, min(1.0, (y1 - p.y) / max(1e-6, y1 - y0)))
            g *= 1.0 - k * t * t * (3.0 - 2.0 * t)
        g = max(0.05, min(1.0, g))
        col = (g, g, g)
        if col_fn is not None:
            cc = col_fn(p, n, g)
            if cc is not None:
                col = cc
        verts.append(p)
        cols.append(col)
    faces = [tuple(v.index for v in f.verts) for f in bm.faces]
    wn = [(R @ n).normalized() for n in nrm]
    bm.free()
    old = b.cur_pal
    if pal is not None:
        b.cur_pal = pal
    bones = None
    if callable(bone):
        bones = [bone(p) for p in verts]
    out = b.add(verts, faces, (0.8, 0.8, 0.8), cls, None if callable(bone) else bone, tint, mat, True, cols=cols, bones=bones)
    b.cur_pal = old
    for v, n in zip(out, wn):
        b.nover.append((v, g2b(n)))
    world = [((R @ n).normalized(), d + (R @ n).normalized().dot(c)) for n, d in planes]
    return out, world


def _smooth(a, b_, x):
    if a == b_:
        return 0.0 if x < a else 1.0
    t = max(0.0, min(1.0, (x - a) / (b_ - a)))
    return t * t * (3.0 - 2.0 * t)


def bark(b, pts, radii, bone_fn, seed=1, plates=9, depth=0.2, twist=0.8, n=28, per=3, col=(0.62, 0.62, 0.62), fissure=0.3,
         tint=1.0, pal=None, cap0=True, cap1=True, cls=None, wobble=0.06, carve=None, shade=None):
    """A limb of a tree: a loft whose bark is split into long plates by narrow, deep fissures that
    twist round it and fork and merge along its length (the furrowed bark of an old oak or pine),
    the plates' faces lit and worn paler, the fissures nearly black (`fissure` x the plate grey), so
    the bark reads from far off.  `radii` per control point; `bone_fn(p)` -> weights.  `carve(p,
    out)` -> (offset Vector, smoothing 0..1) sculpts the surface (a face in the bark: the plates
    are smoothed away where it says, so the face reads as carved, not stuck on); `shade(p, col)`
    may repaint a vertex.  Returns the verts."""
    from kit import WOOD
    from sculpt import catmull, fbm3, loft, section
    cls = WOOD if cls is None else cls
    pts = [V(p) for p in pts]
    cp = catmull(pts, per) if len(pts) > 2 else [pts[0].lerp(pts[-1], k / (per * 2)) for k in range(per * 2 + 1)]
    m = len(cp)
    # radius along the resampled path
    rr = []
    for k in range(m):
        f = k / (m - 1) * (len(radii) - 1)
        i = min(len(radii) - 2, int(f))
        rr.append(radii[i] + (radii[i + 1] - radii[i]) * (f - i))
    along = [0.0]
    for k in range(1, m):
        along.append(along[-1] + (cp[k] - cp[k - 1]).length)
    plate = {}
    rings = []
    for j in range(m):
        d = (cp[min(m - 1, j + 1)] - cp[max(0, j - 1)]).normalized()

        def prof(a, j=j):
            u = a * plates / (2.0 * math.pi) + twist * along[j] * 3.0 + 1.1 * fbm3((math.cos(a) * 1.3 + seed, along[j] * 2.2, math.sin(a) * 1.3), 2, seed)
            f = u - math.floor(u)
            pl = _smooth(0.0, 0.2, f) * _smooth(1.0, 0.78, f)
            plate[(j, round(a, 6))] = pl
            k = fbm3((math.cos(a) * 3.0, along[j] * 5.0 + seed, math.sin(a) * 3.0), 2, seed + 5)
            return rr[j] * (1.0 - depth + depth * pl + wobble * (k - 0.5))

        ring = section(cp[j], d, prof, n, up=V(0, 0, 1))
        if carve is not None:
            # where the surface is carved, the plates give way to smooth wood (the face)
            flat = section(cp[j], d, lambda a, j=j: rr[j] * (1.0 - depth * 0.35), n, up=V(0, 0, 1))
            for i in range(n):
                out = (flat[i] - cp[j]).normalized()
                off, sm = carve(flat[i], out)
                if sm > 0.0:
                    a = 2.0 * math.pi * i / n
                    key = (j, round(a, 6))
                    plate[key] = plate.get(key, 1.0) * (1.0 - sm) + sm
                ring[i] = ring[i].lerp(flat[i], sm) + off
        rings.append(ring)

    def colf(p, j, i):
        a = 2.0 * math.pi * i / n
        pl = plate.get((j, round(a, 6)), 1.0)
        g = fbm3((p.x * 7.0, p.y * 7.0, p.z * 7.0), 2, seed + 9)
        v = (0.78 + 0.22 * pl + 0.16 * (g - 0.5)) * (fissure + (1.0 - fissure) * _smooth(0.0, 0.55, pl))
        out = (col[0] * v, col[1] * v, col[2] * v)
        if shade is not None:
            out = shade(p, out)
        return out

    old = b.cur_pal
    if pal is not None:
        b.cur_pal = pal
    out = loft(b, rings, col, cls=cls, col_fn=colf, bone_fn=bone_fn, tint=tint, cap0=cap0, cap1=cap1, cap_push=0.35)
    b.cur_pal = old
    return out


def leaf_clump(b, c, size, bone, seed=1, res=0.026, col_top=0.95, col_under=0.4, tint=1.0, pal=0.0, lobes=16, bumps=0.035,
               leaves=12, leaf=0.1, flat=0.0):
    """A clump of foliage the way stylised trees are built: a soft mass whose outline is scalloped
    by many smaller round lobes (a cauliflower of leaf clusters, never one smooth ball), light on
    top and dark underneath (the value grouping that makes a canopy read as masses), with a few
    solid leaves lying along its surface like shingles, their tips standing out at the edge.
    `size` = (rx, ry, rz); `flat` flattens the underside."""
    from anatomy import blade
    from clay import Clay
    from kit import FOLIAGE
    from sculpt import fbm3, scatter
    rnd = random.Random(seed * 13 + 1)
    c = V(c)
    rx, ry, rz = size
    cl = Clay(res, "clump%d" % seed)
    cl.ellipsoid(c, (rx * 0.74, ry * 0.74, rz * 0.74), bones={bone: 1.0}, tag="leaf")
    m = min(rx, ry, rz)
    for k in range(lobes):
        # lobes spread over the upper four fifths of the mass (Fibonacci sphere)
        y = 1.0 - 1.8 * (k + 0.5) / lobes
        rr = math.sqrt(max(0.0, 1.0 - y * y))
        a = k * 2.399963 + rnd.uniform(-0.3, 0.3)
        q = V(math.cos(a) * rr * rx * 0.72, y * ry * 0.7, math.sin(a) * rr * rz * 0.72)
        cl.ball(c + q, m * rnd.uniform(0.3, 0.42), bones={bone: 1.0}, tag="leaf")

    def post(p, info):
        n = info.n
        g = fbm3((p.x * 9.0, p.y * 9.0, p.z * 9.0), 2, seed)
        off = n * (bumps * (g - 0.45))
        if flat > 0.0 and n.y < -0.2:
            off = off + V(0.0, (c.y - ry * 0.5 - p.y) * flat * (-n.y), 0.0)
        return off

    def colf(p, info):
        n = info.n
        g = fbm3((p.x * 10.0, p.y * 10.0, p.z * 10.0), 2, seed + 3)
        t = _smooth(-0.55, 0.8, n.y)
        v = (col_under + (col_top - col_under) * t) * (0.9 + 0.2 * g)
        return (v, v, v)

    old = b.cur_pal
    b.cur_pal = pal
    built = cl.build(b, colf, cls=FOLIAGE, tint_fn=lambda p, info: tint, post=post)
    if leaves:
        verts = [v for v, _ in built]
        for p, n in scatter(b, verts, leaves, seed=seed + 5, pred=lambda p, n: n.y > -0.2, min_dist=leaf * 0.9):
            # a shingle: lying along the surface, pointing down and out, its tip lifting off
            down = V(0.0, -1.0, 0.0) - n * (-n.y)
            if down.length < 1e-3:
                down = n.orthogonal()
            t = (down.normalized() + n.cross(V(0, 1, 0)) * rnd.uniform(-0.6, 0.6)).normalized()
            ln = leaf * rnd.uniform(0.85, 1.2)
            g = (col_under + (col_top - col_under) * _smooth(-0.55, 0.8, n.y)) * rnd.uniform(0.95, 1.08)
            root = p - t * ln * 0.35 + n * 0.004
            tip = p + t * ln * 0.8 + n * ln * 0.35
            blade(b, root, tip, ln * 0.45, (g, g, g), (min(1.0, g * 1.06),) * 3, side=n.cross(t).normalized(), bone=bone, curl=-0.12,
                  thick=0.16, tint=tint, cls=FOLIAGE, steps=4, seg=6, point=0.7)
    b.cur_pal = old
    return built


def crack(b, planes, centre, dirs, bone, width=0.014, seed=1, lift=0.004, jag=0.35, glow_mat=None):
    """A glowing crack on a hewn block: a zig-zag of straight, sharply turning segments through
    the surface points the directions `dirs` reach from `centre`, widest in the middle and
    tapering to nothing at both ends (a fracture, not a wobbly line).  Drawn on the palette's
    accent slot so it burns in the element's colour."""
    from kit import CLOTH, MAT_GLOW
    rnd = random.Random(seed * 101 + 7)
    pts = []
    n = len(dirs)
    for i in range(n - 1):
        a, e = V(dirs[i]).normalized(), V(dirs[i + 1]).normalized()
        steps = 3
        for k in range(steps):
            t = k / steps
            d = a.lerp(e, t).normalized()
            if 0 < i + k:
                side = d.cross(e - a)
                if side.length > 1e-6:
                    d = (d + side.normalized() * rnd.uniform(-jag, jag) * (e - a).length / steps).normalized()
            pts.append(surface_point(planes, centre, d) + d * lift)
    pts.append(surface_point(planes, centre, dirs[-1]) + V(dirs[-1]).normalized() * lift)
    m = len(pts)
    radii = [max(0.0015, width * math.sin(math.pi * (0.08 + 0.84 * i / (m - 1))) ** 0.7) for i in range(m)]
    old = b.cur_pal
    b.cur_pal = 1.0
    b.tube(pts, radii, (1.0, 1.0, 1.0), cls=CLOTH, bone=bone, seg=5, mat=MAT_GLOW if glow_mat is None else glow_mat, tint=1.0)
    b.cur_pal = old


def decal(b, hit, centre, fwd, outline, col, bone, lift=0.003, cls=None, mat=None, tint=0.0, cols=None, rings=3):
    """A flat shape painted onto a surface: `outline` is a closed list of (u, v) points in the
    plane facing `fwd` round `centre` (u to the creature's left, v up); every point is dropped onto
    the surface by ray-casting (`hit` from anatomy.surface) and lifted by `lift`.  Filled with
    `rings` rings from the rim in to the middle, so it bends with the surface.  `cols` = (rim, middle)
    shades it from the rim inwards.  Thin, so the ink outline skips it."""
    from kit import MAT_PLAIN, SKIN, lin
    cls = SKIN if cls is None else cls
    mat = MAT_PLAIN if mat is None else mat
    f = V(fwd).normalized()
    side = V(0.0, 1.0, 0.0).cross(f)
    side = side.normalized() if side.length > 1e-4 else V(1.0, 0.0, 0.0)
    up = f.cross(side).normalized()
    c = V(centre)
    cu = sum(u for u, _ in outline) / len(outline)
    cv = sum(v for _, v in outline) / len(outline)
    verts = []
    vcols = []
    n = len(outline)
    for j in range(rings + 1):
        k = 1.0 - j / rings
        for i in range(n if j < rings else 1):
            u, v = outline[i] if j < rings else (cu, cv)
            u = cu + (u - cu) * k
            v = cv + (v - cv) * k
            o = c + side * u + up * v + f * 1.0
            h = hit(o, -f, 3.0)
            p = h[0] + h[1] * lift if h is not None else c + side * u + up * v
            verts.append(p)
            cc = col if cols is None else mix(cols[0], cols[1], j / rings)
            vcols.append(lin(cc, cls + THIN))
    faces = []
    for j in range(rings - 1):
        for i in range(n):
            a = j * n + i
            bb = j * n + (i + 1) % n
            faces.append((a, bb, bb + n, a + n))
    centre_i = rings * n
    for i in range(n):
        a = (rings - 1) * n + i
        bb = (rings - 1) * n + (i + 1) % n
        faces.append((a, bb, centre_i))
    # (an outline counter-clockwise in (u, v) faces out of the surface, towards `fwd`)
    return b.add(verts, faces, col, cls, bone, tint, mat, True, cols=vcols, closed=False)


def surface_point(planes, origin, direction):
    """Where a ray from `origin` (inside a hewn block) along `direction` leaves it."""
    o = V(origin)
    d = V(direction).normalized()
    best = 1e9
    for n, dd in planes:
        k = n.dot(d)
        if k > 1e-6:
            best = min(best, (dd - n.dot(o)) / k)
    return o + d * best
