"""Sculpting helpers on top of the kit's Builder: lofted bodies with non-circular cross-sections,
deformed spheres (heads, skulls, muzzles), smooth noise, curves and surface scattering.

The kit's primitives are round: ellipsoids, tubes and lathes.  Living things are not.  A ribcage is
deep and narrow, a hanging sleeve is a teardrop, a dog's muzzle is a wedge with a stop in front of
the eyes, a cheek is a soft plane that turns into a jaw.  The helpers here build those shapes:

* ``loft``: a skin through a list of rings.  Each ring is produced by ``section`` from a centre, a
  direction and a *profile* function angle -> radius, so cross-sections can be eggs, teardrops,
  D-shapes or anything else, and change smoothly along the body.
* ``morph_sphere``: a UV sphere whose radius per direction comes from a shape function, with the
  vertex colour and bone weights computed per vertex.  Faces and skulls are built this way.
* ``noise3`` / ``fbm3``: deterministic value noise in pure Python, for uneven fur, bark, rock and
  skin blotches baked into vertex colours.
* ``curve`` / ``frames``: Catmull-Rom curves with parallel-transport frames, for strands of hair,
  tails, whiskers and tentacles.
* ``scatter``: points spread evenly over a part of a built mesh (with normals), used to plant fur
  clumps, scales, feathers and spikes on bodies.

Everything is in Godot space, like the rest of the kit.
"""

import math
import random

from mathutils import Vector

from kit import CLOTH, b2g, lin, look_frame, mix, rgb

TAU = 2.0 * math.pi


# ---------------------------------------------------------------- scalar helpers
def clamp(x, a=0.0, b=1.0):
    return a if x < a else (b if x > b else x)


def smooth(a, b, x):
    """GLSL smoothstep."""
    if a == b:
        return 0.0 if x < a else 1.0
    t = clamp((x - a) / (b - a))
    return t * t * (3.0 - 2.0 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def bump(x, c, w):
    """A smooth 0..1..0 bump of half-width w centred on c (cosine window)."""
    d = abs(x - c) / w
    return 0.5 + 0.5 * math.cos(math.pi * d) if d < 1.0 else 0.0


def gauss(d2, s):
    return math.exp(-d2 / (2.0 * s * s))


def blob3(p, c, r):
    """Gaussian falloff of point p around centre c with radii r=(rx, ry, rz) (all Vectors)."""
    dx = (p.x - c[0]) / r[0]
    dy = (p.y - c[1]) / r[1]
    dz = (p.z - c[2]) / r[2]
    return math.exp(-(dx * dx + dy * dy + dz * dz))


# ---------------------------------------------------------------- noise
def _h(ix, iy, iz, seed):
    n = ix * 374761393 + iy * 668265263 + iz * 2147483647 + seed * 144665
    n = (n ^ (n >> 13)) * 1274126177
    n = n ^ (n >> 16)
    return (n & 0xFFFF) / 65535.0


def noise3(p, seed=0):
    """Smooth value noise in [0, 1] at point p (any 3-sequence)."""
    x, y, z = p[0], p[1], p[2]
    ix, iy, iz = math.floor(x), math.floor(y), math.floor(z)
    fx, fy, fz = x - ix, y - iy, z - iz
    ux = fx * fx * (3 - 2 * fx)
    uy = fy * fy * (3 - 2 * fy)
    uz = fz * fz * (3 - 2 * fz)

    def c(dx, dy, dz):
        return _h(ix + dx, iy + dy, iz + dz, seed)

    x00 = lerp(c(0, 0, 0), c(1, 0, 0), ux)
    x10 = lerp(c(0, 1, 0), c(1, 1, 0), ux)
    x01 = lerp(c(0, 0, 1), c(1, 0, 1), ux)
    x11 = lerp(c(0, 1, 1), c(1, 1, 1), ux)
    return lerp(lerp(x00, x10, uy), lerp(x01, x11, uy), uz)


def fbm3(p, octaves=3, seed=0, lac=2.03, gain=0.5):
    s = 0.0
    a = 0.5
    tot = 0.0
    q = Vector((p[0], p[1], p[2]))
    for k in range(octaves):
        s += noise3(q, seed + k * 17) * a
        tot += a
        q = q * lac
        a *= gain
    return s / tot


# ---------------------------------------------------------------- profiles (angle -> radius)
# Angle 0 points along the section's "up" axis (b), angles increase towards its "side" axis (n).
def prof_ellipse(rw, rh):
    """Ellipse: rw across, rh up/down."""

    def f(a):
        c, s = math.cos(a), math.sin(a)
        return 1.0 / math.sqrt((c / rh) ** 2 + (s / rw) ** 2)

    return f


def prof_egg(rw, rtop, rbot, flat=0.0):
    """Egg: different heights above and below the centre, optional flattened sides."""

    def f(a):
        c, s = math.cos(a), math.sin(a)
        rh = rtop if c >= 0 else rbot
        r = 1.0 / math.sqrt((c / rh) ** 2 + (s / rw) ** 2)
        if flat > 0.0:
            r *= 1.0 - flat * (abs(s) ** 6)
        return r

    return f


def prof_tear(rw, rtop, rbot, sharp=2.0):
    """Teardrop pointing down (a hanging sleeve, a belly, a dewlap)."""

    def f(a):
        c, s = math.cos(a), math.sin(a)
        if c >= 0:
            return 1.0 / math.sqrt((c / rtop) ** 2 + (s / rw) ** 2)
        k = (-c) ** sharp
        w = rw * (1.0 - 0.85 * k)
        return 1.0 / math.sqrt((c / rbot) ** 2 + (s / max(w, 1e-4)) ** 2)

    return f


def prof_d(rw, rh, flat_side=0.6):
    """D-shape: round on the top, flatter underneath (a carapace, a skull base)."""

    def f(a):
        c, s = math.cos(a), math.sin(a)
        rr = 1.0 / math.sqrt((c / rh) ** 2 + (s / rw) ** 2)
        if c < 0:
            rr *= 1.0 - flat_side * (-c) ** 3 * 0.5
        return rr

    return f


def prof_mod(base, fn):
    """Multiply a profile by fn(angle) (ridges, keels, muscle bulges)."""
    return lambda a: base(a) * fn(a)


# ---------------------------------------------------------------- sections and lofts
def section(c, d, prof, n=16, up=None, twist=0.0, offset=None):
    """A ring of n points around centre c, perpendicular to direction d.  `up` orients the ring
    (angle 0 points along up projected off d).  `offset(angle)` adds a vector to each point."""
    c = Vector(c)
    d = Vector(d).normalized()
    if up is None:
        up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((0, 0, 1))
    up = Vector(up)
    b = (up - d * up.dot(d))
    if b.length < 1e-6:
        side, b = look_frame(d)
    b.normalize()
    side = b.cross(d).normalized()
    pts = []
    for i in range(n):
        a = TAU * i / n + twist
        r = prof(a)
        p = c + b * (math.cos(a) * r) + side * (math.sin(a) * r)
        if offset is not None:
            p = p + Vector(offset(a))
        pts.append(p)
    return pts


def path_dirs(cs):
    """Central-difference directions along a list of centres."""
    cs = [Vector(c) for c in cs]
    out = []
    for i in range(len(cs)):
        a = cs[max(0, i - 1)]
        b = cs[min(len(cs) - 1, i + 1)]
        out.append((b - a).normalized())
    return out


def _outward(rings, faces_side):
    """+1 if quads (a, c, c+n, a+n) of these rings face away from each ring's centre."""
    n = len(rings[0])
    tot = 0.0
    for j in range(len(rings) - 1):
        cen = sum((Vector(p) for p in rings[j]), Vector()) / n
        for i in range(0, n, max(1, n // 8)):
            a = Vector(rings[j][i])
            c = Vector(rings[j][(i + 1) % n])
            d = Vector(rings[j + 1][i])
            nrm = (c - a).cross(d - a)
            tot += nrm.dot((a + c + d) / 3.0 - cen)
    return 1 if tot >= 0 else -1


def loft(b, rings, col, cls=CLOTH, bone=None, bones=None, cols=None, col_fn=None, tint=0.0, tint_fn=None, mat=0, cap0=True, cap1=True, cap_push=0.6, smooth_shade=True, bone_fn=None, closed=True, inside=False):
    """Skin a list of rings (each a list of the same number of points).  `bones`/`cols` give one
    value per ring; `col_fn(p, j, i)` and `bone_fn(p)` per vertex.  Caps are domed fans pushed
    out along the end directions by `cap_push` x the ring's mean radius.  Faces are wound to
    point away from the axis (towards it with `inside`, for linings), whatever the ring order."""
    flip = (_outward(rings, 1) < 0) != inside
    nr = len(rings)
    n = len(rings[0])
    verts = []
    vcols = []
    vbones = []
    vtints = []
    for j, ring in enumerate(rings):
        for i, p in enumerate(ring):
            verts.append(Vector(p))
            if col_fn is not None:
                vcols.append(lin(col_fn(Vector(p), j, i), cls))
            elif cols is not None:
                vcols.append(lin(cols[j], cls))
            else:
                vcols.append(lin(col, cls))
            if bone_fn is not None:
                vbones.append(bone_fn(Vector(p)))
            elif bones is not None:
                vbones.append(bones[j])
            else:
                vbones.append(bone)
            vtints.append(tint_fn(Vector(p)) if tint_fn is not None else tint)
    faces = []
    for j in range(nr - 1):
        for i in range(n):
            a = j * n + i
            c = j * n + (i + 1) % n
            faces.append((a, c, c + n, a + n))

    def cap(j, sign):
        ring = [Vector(p) for p in rings[j]]
        cen = sum(ring, Vector()) / n
        rad = sum((p - cen).length for p in ring) / n
        other = rings[j - sign] if 0 <= j - sign < nr else rings[j]
        oc = sum((Vector(p) for p in other), Vector()) / n
        d = (cen - oc)
        d = d.normalized() if d.length > 1e-6 else Vector((0, 1, 0))
        base = len(verts)
        for step, (sc, push) in enumerate(((0.72, 0.5), (0.36, 0.86))):
            for i in range(n):
                q = cen + (ring[i] - cen) * sc + d * (push * rad * cap_push)
                verts.append(q)
                vcols.append(vcols[j * n + i])
                vbones.append(vbones[j * n + i])
                vtints.append(vtints[j * n + i])
        pole = len(verts)
        verts.append(cen + d * (rad * cap_push))
        vcols.append(vcols[j * n])
        vbones.append(vbones[j * n])
        vtints.append(vtints[j * n])
        rws = [j * n, base, base + n]
        for k in range(2):
            for i in range(n):
                a = rws[k] + i
                c = rws[k] + (i + 1) % n
                a2 = rws[k + 1] + i
                c2 = rws[k + 1] + (i + 1) % n
                faces.append((a, c, c2, a2) if sign > 0 else (a, a2, c2, c))
        for i in range(n):
            a = base + n + i
            c = base + n + (i + 1) % n
            faces.append((a, c, pole) if sign > 0 else (a, pole, c))

    if cap0:
        cap(0, -1)
    if cap1:
        cap(nr - 1, 1)
    if flip:
        faces = [tuple(reversed(f)) for f in faces]
    return b.add(verts, faces, col, cls, None, tint, mat, smooth_shade, cols=vcols, bones=vbones, tints=vtints, closed=closed and cap0 and cap1 and not inside)


def loft_path(b, centres, profs, col, n=16, up=None, ups=None, offsets=None, **kw):
    """Loft along a path of centres with one profile per centre (or one for all)."""
    dirs = path_dirs(centres)
    rings = []
    for k, c in enumerate(centres):
        pr = profs[k] if isinstance(profs, (list, tuple)) else profs
        u = ups[k] if ups is not None else up
        off = offsets[k] if offsets is not None else None
        rings.append(section(c, dirs[k], pr, n, up=u, offset=off))
    return loft(b, rings, col, **kw)


# ---------------------------------------------------------------- deformed spheres
def morph_sphere(b, c, shape, col_fn, cls=CLOTH, bone=None, bone_fn=None, seg=32, rings=24, tint_fn=None, mat=0, rot=None):
    """UV sphere around c.  shape(dir) -> local point (Vector) for each unit direction, so the
    caller can push the surface anywhere (jaws, brows, cheeks, snouts).  col_fn(local_p, dir)."""
    c = Vector(c)
    verts = []
    cols = []
    bones = []
    tints = []
    for j in range(rings + 1):
        th = math.pi * j / rings
        y = math.cos(th)
        s = math.sin(th)
        for i in range(seg):
            ph = TAU * i / seg
            d = Vector((math.sin(ph) * s, y, math.cos(ph) * s))
            lp = shape(d)
            if rot is not None:
                lp = rot @ lp
            p = c + lp
            verts.append(p)
            cols.append(lin(col_fn(lp, d), cls))
            bones.append(bone_fn(p) if bone_fn is not None else bone)
            tints.append(tint_fn(lp, d) if tint_fn is not None else 0.0)
    faces = []
    for j in range(rings):
        for i in range(seg):
            a = j * seg + i
            bb = j * seg + (i + 1) % seg
            faces.append((a, a + seg, bb + seg, bb))
    return b.add(verts, faces, col_fn(Vector((0, 1, 0)), Vector((0, 1, 0))), cls, None, 0.0, mat, True, cols=cols, bones=bones, tints=tints)


def ellipsoid_shape(r):
    return lambda d: Vector((d.x * r[0], d.y * r[1], d.z * r[2]))


# ---------------------------------------------------------------- curves
def catmull(pts, per=6):
    """Catmull-Rom resample of a polyline: returns points (the end point included)."""
    pts = [Vector(p) for p in pts]
    n = len(pts)
    if n < 3:
        return [pts[0].lerp(pts[-1], k / max(1, per)) for k in range(per + 1)] if n == 2 else pts
    out = []
    for i in range(n - 1):
        p0 = pts[max(0, i - 1)]
        p1 = pts[i]
        p2 = pts[i + 1]
        p3 = pts[min(n - 1, i + 2)]
        for k in range(per):
            t = k / per
            t2 = t * t
            t3 = t2 * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(pts[-1])
    return out


def bezier(p0, p1, p2, p3, n=8):
    p0, p1, p2, p3 = (Vector(p) for p in (p0, p1, p2, p3))
    out = []
    for k in range(n + 1):
        t = k / n
        u = 1 - t
        out.append(p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t))
    return out


def arc_len(pts):
    return sum((Vector(pts[i + 1]) - Vector(pts[i])).length for i in range(len(pts) - 1))


def taper(n, r0, r1, power=1.0, tip=0.0):
    """Radii falling from r0 to r1 over n points (power shapes the fall), last one `tip`."""
    out = []
    for i in range(n):
        t = i / max(1, n - 1)
        out.append(r0 + (r1 - r0) * (t ** power))
    if tip is not None and n > 1:
        out[-1] = max(tip, 1e-4)
    return out


def strand(b, pts, r0, r1, col, col_tip=None, cls=CLOTH, bone=None, bones=None, flat=1.0, seg=6, per=4, up=None, power=1.0, mat=0, tint=0.0, cap0=False):
    """A smooth tapered strand through control points: hair locks, whiskers, tendrils."""
    cp = catmull(pts, per)
    n = len(cp)
    radii = taper(n, r0, r1, power, tip=r1 * 0.2 if r1 > 0 else 0.0005)
    cols = None
    if col_tip is not None:
        cols = [mix(col, col_tip, (i / max(1, n - 1)) ** 1.3) for i in range(n)]
    bl = None
    if bones is not None:
        # bones given per control point: spread over the resampled points
        bl = []
        m = len(pts)
        for i in range(n):
            f = i / max(1, n - 1) * (m - 1)
            k = int(min(m - 1, math.floor(f)))
            bl.append(bones[k])
    return b.tube(cp, [(r, r * flat) for r in radii], col, cls=cls, bone=bone, bones=bl, seg=seg, cap0=cap0, cap1=True, cols=cols, up=up, mat=mat, tint=tint)


# ---------------------------------------------------------------- scattering over a mesh part
def scatter(b, verts, count, seed=3, pred=None, min_dist=0.0):
    """Pick up to `count` surface points (position, normal) from a list of bmesh verts returned by
    a Builder call, evenly spread (dart throwing with min_dist).  pred(pos, nrm) filters."""
    b.bm.normal_update()
    rnd = random.Random(seed)
    cand = []
    for v in verts:
        p = b2g(v.co)
        nb = v.normal
        nrm = Vector((nb.x, nb.z, -nb.y))
        if nrm.length < 0.5:
            continue
        if pred is not None and not pred(p, nrm):
            continue
        cand.append((p, nrm.normalized()))
    rnd.shuffle(cand)
    out = []
    md2 = min_dist * min_dist
    for p, nrm in cand:
        if len(out) >= count:
            break
        if md2 > 0 and any((p - q).length_squared < md2 for q, _ in out):
            continue
        out.append((p, nrm))
    return out


# ---------------------------------------------------------------- colour fields
def mottled(base, dark, light, scale=8.0, seed=1, amount=1.0):
    """Colour function: noise-mottled between dark and light around base."""
    base = rgb(base)

    def fn(p, *_):
        k = fbm3((p[0] * scale, p[1] * scale, p[2] * scale), 3, seed)
        if k < 0.5:
            return mix(base, dark, (0.5 - k) * 2.0 * amount)
        return mix(base, light, (k - 0.5) * 2.0 * amount)

    return fn


def gradient_y(lo_col, hi_col, y0, y1):
    def fn(p, *_):
        return mix(lo_col, hi_col, smooth(y0, y1, p[1]))

    return fn


def countershade(spine_y, back, belly, sharp=8.0):
    """Animal colouring: darker along the back, lighter underneath."""

    def fn(p, *_):
        k = 0.5 + 0.5 * math.tanh((p[1] - spine_y(p)) * sharp)
        return mix(belly, back, k)

    return fn
