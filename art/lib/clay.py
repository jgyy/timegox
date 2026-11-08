"""Clay: organic bodies sculpted from metaball elements (Blender's implicit surfaces).

A creature is not a stack of tubes.  Its torso, the muscle masses of its shoulders and haunches,
its neck, its limbs and the base of its tail are one continuous skin over overlapping forms.  The
``Clay`` class collects soft elements - balls, ellipsoids, capsules and tapered chains - exactly the
way a sculptor builds a maquette out of clay lumps, lets Blender's metaball polygoniser melt them
into one smooth manifold mesh, and then gives every vertex of that mesh

* **bone weights** blended from the elements that formed the surface there (each element carries
  its own bone weights, or a function of position for chains), so joints bend smoothly where two
  forms overlap and rigidly inside a form;
* a **region** (the tag of the element that dominates the vertex: "body", "leg", "head", "tail"
  ...) and a parameter along chains, which colour functions use to paint natural markings that
  follow the form - stripes that ring a leg but wrap a flank, rings round a tail;
* colour, tint weight and palette slot from caller functions.

Element sizes are given as *visible* radii.  A lone element shows ``VIS`` of its influence radius;
overlapping elements add up and swell a little, so chains are built with half-overlapping
segments, which keeps a taper smooth.  Negative elements carve hollows (eye sockets, nostrils,
the groove of a spine).  Separate ``Clay`` objects never melt into one another (Blender only blends
elements of the same family), which is how a lower jaw stays a separate part from the skull.

Everything is in Godot space, like the rest of the kit.
"""

import math

import bpy
from mathutils import Matrix

from kit import CLOTH, MAT_TOON, V, b2g, euler_g, g2b, lin

VIS = 0.575          # visible radius / influence radius for a lone element (stiffness 2, threshold 0.6)
VIS2 = 0.685         # the same where two elements overlap fully (the middle of a chain)
_C = Matrix(((1.0, 0.0, 0.0), (0.0, 0.0, -1.0), (0.0, 1.0, 0.0)))   # Godot -> Blender basis


class Elem:
    __slots__ = ("kind", "c", "a", "b", "R", "M", "Mi", "size", "bones", "tag", "neg", "t0", "t1", "stiff", "lo", "hi")


class Info:
    """What formed a vertex: the dominant element's tag and chain parameter, and the share of
    every tag (``tags``) for blending markings across regions."""
    __slots__ = ("tag", "t", "tags", "elem", "n")

    def __init__(self, tag, t, tags, elem, n):
        self.tag = tag
        self.t = t
        self.tags = tags
        self.elem = elem
        self.n = n

    def share(self, tag):
        return self.tags.get(tag, 0.0)


def _as_matrix(rot):
    if rot is None:
        return Matrix.Identity(3)
    if isinstance(rot, Matrix):
        return rot.to_3x3()
    return euler_g(rot)


def frame_from(d, up=(0.0, 1.0, 0.0)):
    """A rotation whose local +X runs along d (Godot space), +Y as close to `up` as possible."""
    d = V(d).normalized()
    u = V(up)
    side = d.cross(u)
    if side.length < 1e-5:
        side = d.cross(V(1, 0, 0)) if abs(d.x) < 0.9 else d.cross(V(0, 0, 1))
    side.normalize()            # local z
    y = side.cross(d).normalized()
    return Matrix((d, y, side)).transposed()


def limb_weights(names, zone=0.18):
    """Bone weights along a chain of bones for Clay.chain (its parameter t runs 0..len(names)):
    rigid inside each bone, blended linearly over a short zone either side of every joint."""
    n = len(names)

    def fn(p, t):
        f = max(0.0, min(n - 1e-6, t))
        i = int(f)
        u = f - i
        if u > 1.0 - zone and i < n - 1:
            k = 0.5 * (u - (1.0 - zone)) / zone
            return {names[i]: 1.0 - k, names[i + 1]: k}
        if u < zone and i > 0:
            k = 0.5 + 0.5 * u / zone
            return {names[i - 1]: 1.0 - k, names[i]: k}
        return {names[i]: 1.0}

    return fn


class Clay:
    """A family of soft elements that melt into one mesh.  ``res`` is the polygoniser's voxel
    size in metres (smaller is finer and heavier: about 3 / res^2 triangles per square metre)."""

    def __init__(self, res=0.02, name="clay", stiff=2.0, threshold=0.6):
        self.res = res
        self.name = name
        self.stiff = stiff
        self.threshold = threshold
        self.elems = []

    # ---------------------------------------------------------------- elements
    def _new(self, kind, bones, tag, neg, stiff):
        e = Elem()
        e.kind = kind
        e.bones = bones
        e.tag = tag
        e.neg = neg
        e.t0 = 0.0
        e.t1 = 0.0
        e.stiff = stiff or self.stiff
        self.elems.append(e)
        return e

    def ball(self, c, r, bones=None, tag="body", neg=False, stiff=None, t=0.0):
        """A ball of visible radius r."""
        e = self._new("BALL", bones, tag, neg, stiff)
        e.c = V(c)
        e.R = r / VIS
        e.M = Matrix.Identity(3)
        e.Mi = e.M
        e.size = (1.0, 1.0, 1.0)
        e.t0 = e.t1 = t
        self._bounds(e)
        return e

    def ellipsoid(self, c, radii, rot=None, bones=None, tag="body", neg=False, stiff=None, t=0.0):
        """An ellipsoid with visible radii (rx, ry, rz) along its local axes; `rot` is a Godot
        Euler tuple or a 3x3 matrix whose columns are the local axes."""
        e = self._new("ELLIPSOID", bones, tag, neg, stiff)
        e.c = V(c)
        m = max(radii)
        e.R = m / VIS
        e.size = (radii[0] / m, radii[1] / m, radii[2] / m)
        e.M = _as_matrix(rot)
        e.Mi = e.M.transposed()
        e.t0 = e.t1 = t
        self._bounds(e)
        return e

    def capsule(self, a, b, r, bones=None, tag="body", neg=False, stiff=None, t0=0.0, t1=0.0, vis=VIS):
        """A capsule (a sausage) of visible radius r from a to b."""
        e = self._new("CAPSULE", bones, tag, neg, stiff)
        e.a = V(a)
        e.b = V(b)
        e.c = (e.a + e.b) * 0.5
        e.R = r / vis
        d = e.b - e.a
        if d.length < 1e-6:
            d = V(1e-6, 0, 0)
        e.M = frame_from(d)
        e.Mi = e.M.transposed()
        e.size = (1.0, 1.0, 1.0)
        e.t0 = t0
        e.t1 = t1
        self._bounds(e)
        return e

    def chain(self, pts, radii, bones=None, tag="body", per=None, stiff=None, t0=0.0, t1=1.0):
        """A smooth tapered tube through `pts` with a visible radius per point: resampled into
        short half-overlapping capsules so the surface neither beads nor steps.  `bones` may be a
        callable (point, t) -> {bone: w}, a dict, or a list with one entry per point."""
        pts = [V(p) for p in pts]
        # cumulative length and a fine resampling every ~0.6 of the local radius
        segs = []
        L = 0.0
        for i in range(len(pts) - 1):
            segs.append((L, pts[i], pts[i + 1], radii[i], radii[i + 1], i))
            L += (pts[i + 1] - pts[i]).length
        if L < 1e-6:
            return []
        samples = []
        s = 0.0
        while True:
            # point and radius at arc length s
            for (l0, a, b2, r0, r1, i) in segs:
                ln = (b2 - a).length
                if s <= l0 + ln + 1e-9 or i == len(segs) - 1:
                    u = 0.0 if ln < 1e-9 else min(1.0, max(0.0, (s - l0) / ln))
                    samples.append((a.lerp(b2, u), r0 + (r1 - r0) * u, i + u))
                    break
            if s >= L - 1e-9:
                break
            step = max(0.006, (per or 0.55) * samples[-1][1])
            s = min(L, s + step)
        out = []
        n = len(samples)
        for k in range(n - 1):
            pa, ra, fa = samples[k]
            pb, rb, fb = samples[min(n - 1, k + 1)]
            # each capsule spans one step; neighbours overlap at the shared ends.  The middle of
            # a chain sees about two elements at a time: size for that.
            rr = (ra + rb) * 0.5
            ta = t0 + (t1 - t0) * (fa / max(1e-9, len(pts) - 1))
            tb = t0 + (t1 - t0) * (fb / max(1e-9, len(pts) - 1))
            bw = bones
            if isinstance(bones, (list, tuple)):
                i = min(len(bones) - 1, int(round((fa + fb) * 0.5)))
                bw = bones[i]
            out.append(self.capsule(pa, pb, rr, bw, tag, False, stiff, ta, tb, vis=VIS2 if 0 < k < n - 2 else (VIS + VIS2) * 0.5))
        return out

    def _bounds(self, e):
        if e.kind == "CAPSULE":
            lo = V(min(e.a.x, e.b.x), min(e.a.y, e.b.y), min(e.a.z, e.b.z)) - V(e.R, e.R, e.R)
            hi = V(max(e.a.x, e.b.x), max(e.a.y, e.b.y), max(e.a.z, e.b.z)) + V(e.R, e.R, e.R)
        else:
            ext = e.R * max(e.size)
            lo = e.c - V(ext, ext, ext)
            hi = e.c + V(ext, ext, ext)
        e.lo = lo
        e.hi = hi

    # ---------------------------------------------------------------- field (for weights)
    @staticmethod
    def _dist(e, p):
        """Distance of p from the element's core in the element's normalised space."""
        if e.kind == "CAPSULE":
            ab = e.b - e.a
            l2 = ab.length_squared
            t = 0.0 if l2 < 1e-12 else max(0.0, min(1.0, (p - e.a).dot(ab) / l2))
            return (e.a + ab * t - p).length, t
        q = e.Mi @ (p - e.c)
        if e.kind == "ELLIPSOID":
            q = V(q.x / e.size[0], q.y / e.size[1], q.z / e.size[2])
        return q.length, 0.0

    def field(self, e, p):
        d, t = self._dist(e, p)
        x = d / e.R
        if x >= 1.0:
            return 0.0, t
        k = 1.0 - x * x
        return k * k * k, t

    # ---------------------------------------------------------------- polygonise
    def _mesh(self):
        mb = bpy.data.metaballs.new(self.name)
        mb.resolution = self.res
        mb.render_resolution = self.res
        mb.threshold = self.threshold
        ob = bpy.data.objects.new(self.name, mb)
        bpy.context.scene.collection.objects.link(ob)
        for e in self.elems:
            m = mb.elements.new(type=e.kind)
            m.radius = e.R
            m.stiffness = e.stiff
            m.use_negative = e.neg
            Mb = _C @ e.M @ _C.transposed()
            m.co = g2b(e.c)
            m.rotation = Mb.to_quaternion()
            if e.kind == "CAPSULE":
                m.size_x = (e.b - e.a).length * 0.5
            elif e.kind == "ELLIPSOID":
                # Godot local y -> Blender local z, Godot local z -> Blender local -y
                m.size_x, m.size_y, m.size_z = e.size[0], e.size[2], e.size[1]
        dg = bpy.context.evaluated_depsgraph_get()
        ev = ob.evaluated_get(dg)
        me = ev.to_mesh()
        verts = [b2g(v.co) for v in me.vertices]
        faces = [tuple(p.vertices) for p in me.polygons]
        ev.to_mesh_clear()
        bpy.data.objects.remove(ob)
        bpy.data.metaballs.remove(mb)
        return verts, faces

    def _grid(self, cell=0.2):
        grid = {}
        for idx, e in enumerate(self.elems):
            if e.neg:
                continue
            for ix in range(int(math.floor(e.lo.x / cell)), int(math.floor(e.hi.x / cell)) + 1):
                for iy in range(int(math.floor(e.lo.y / cell)), int(math.floor(e.hi.y / cell)) + 1):
                    for iz in range(int(math.floor(e.lo.z / cell)), int(math.floor(e.hi.z / cell)) + 1):
                        grid.setdefault((ix, iy, iz), []).append(idx)
        return grid, cell

    def build(self, b, col_fn, cls=CLOTH, tint_fn=None, pal_fn=None, mat=MAT_TOON, sharp=2.0, smooth=1, post=None):
        """Polygonise, then add the mesh to Builder b.  col_fn(p, info) -> sRGB, tint_fn(p, info)
        -> tint weight, pal_fn(p, info) -> palette slot.  `post(p, info)` may return an offset
        Vector to displace the vertex (sculpted fur tufts, wrinkles).  Returns [(bm_vert, info)]."""
        verts, faces = self._mesh()
        if not verts:
            return []
        # light Laplacian smoothing evens out the polygoniser's stair-steps
        if smooth:
            nb = [[] for _ in verts]
            for f in faces:
                m = len(f)
                for k in range(m):
                    a, c = f[k], f[(k + 1) % m]
                    nb[a].append(c)
                    nb[c].append(a)
            for _ in range(smooth):
                new = []
                for i, p in enumerate(verts):
                    if not nb[i]:
                        new.append(p)
                        continue
                    avg = V(0, 0, 0)
                    for j in nb[i]:
                        avg += verts[j]
                    avg /= len(nb[i])
                    new.append(p.lerp(avg, 0.5))
                verts = new
        # vertex normals (area weighted) for the colour functions and displacement
        nrm = [V(0, 0, 0) for _ in verts]
        for f in faces:
            a = verts[f[0]]
            for k in range(1, len(f) - 1):
                n = (verts[f[k]] - a).cross(verts[f[k + 1]] - a)
                for j in (f[0], f[k], f[k + 1]):
                    nrm[j] += n
        nrm = [n.normalized() if n.length > 1e-12 else V(0, 1, 0) for n in nrm]
        grid, cell = self._grid()
        infos = []
        bones = []
        for i, p in enumerate(verts):
            key = (int(math.floor(p.x / cell)), int(math.floor(p.y / cell)), int(math.floor(p.z / cell)))
            best = None
            bestf = -1.0
            tags = {}
            wsum = {}
            for idx in grid.get(key, ()):
                e = self.elems[idx]
                f, t = self.field(e, p)
                if f <= 0.0:
                    continue
                if f > bestf:
                    bestf = f
                    best = (e, t)
                tags[e.tag] = tags.get(e.tag, 0.0) + f
                w = f ** sharp
                bw = e.bones
                if callable(bw):
                    bw = bw(p, e.t0 + (e.t1 - e.t0) * t)
                if bw is None:
                    continue
                if isinstance(bw, str):
                    bw = {bw: 1.0}
                for nm, x in bw.items():
                    wsum[nm] = wsum.get(nm, 0.0) + w * x
            if best is None:
                # outside every element's reach (should not happen): nearest element by distance
                e = min((x for x in self.elems if not x.neg), key=lambda x: self._dist(x, p)[0] / x.R)
                best = (e, self._dist(e, p)[1])
                tags = {e.tag: 1.0}
                bw = e.bones(p, e.t0) if callable(e.bones) else e.bones
                wsum = {bw: 1.0} if isinstance(bw, str) else dict(bw or {})
            tot = sum(tags.values()) or 1.0
            tags = {k: v / tot for k, v in tags.items()}
            e, t = best
            infos.append(Info(e.tag, e.t0 + (e.t1 - e.t0) * t, tags, e, nrm[i]))
            # glTF skins carry four influences: keep the strongest four
            top = sorted(wsum.items(), key=lambda kv: -kv[1])[:4]
            tw = sum(v for _, v in top)
            bones.append({k: v / tw for k, v in top if v / tw > 0.01} if tw > 0 else None)
        if post is not None:
            for i, p in enumerate(verts):
                off = post(p, infos[i])
                if off is not None:
                    verts[i] = p + off
        cols = [lin(col_fn(verts[i], infos[i]), cls) for i in range(len(verts))]
        tints = [tint_fn(verts[i], infos[i]) for i in range(len(verts))] if tint_fn is not None else None
        old_pal = b.cur_pal
        out = b.add(verts, faces, (0.8, 0.8, 0.8), cls, None, 0.0, mat, True, cols=cols, tints=tints, bones=bones, closed=False)
        if pal_fn is not None:
            for v, i in zip(out, range(len(verts))):
                v[b.pl] = pal_fn(verts[i], infos[i])
        b.cur_pal = old_pal
        return list(zip(out, infos))
