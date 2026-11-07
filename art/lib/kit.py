"""Shared Blender (bpy) toolkit for the game's hero assets.

Every asset script in ``art/`` builds its model from code with this kit and exports a ``.glb``
into ``assets/``.  Nothing is modelled by hand.

Conventions
-----------
* All coordinates passed to the kit are in **Godot space**: +X right, +Y up, +Z forward (the way
  the model faces), one unit = one metre.  The kit converts them to Blender space (Z up, -Y
  forward), and the glTF exporter converts back, so what you write is what Godot sees.
* Colours are sRGB hex strings or tuples.  The alpha channel of the exported vertex colour holds
  the surface class used by the game's toon shader (cloth, stone, metal, wood, skin, crystal,
  foliage, scales, hair), exactly like ``MB.tag`` in ``scripts/mb.gd``.  Thin double-sided
  geometry has the class nudged by -0.025 so the ink outline pass skips it.
* UV channel 0 carries a *tint* weight in U: 0 keeps the authored colour, 1 multiplies it with the
  colour the game passes in (so one monster mesh can be a jade lion or a frost wolf).  V carries the
  *palette slot* of tinted parts: 0 the primary colour, 0.5 the secondary, 1 the accent.  The game
  derives a harmonious secondary and a contrasting accent from the one enemy colour (assets.gd),
  so a mane, a belly, horns or fins come out in their own colours instead of one flat tone.  Set
  ``Builder.cur_pal`` before building a part (or call ``palette``/``palette_where`` afterwards).
* Material slots: ``toon`` (outlined), ``plain`` (no outline) and ``glow`` (additive, unshaded).
* Rotations for animation are Godot Euler angles (order YXZ) in the parent's frame, the same
  numbers you would put on a ``Node3D.rotation``.

Run any asset script with ``blender --background --python art/<group>/<asset>.py`` or, with the
``bpy`` wheel installed, ``python art/<group>/<asset>.py``.  ``python art/build_all.py`` rebuilds
everything.
"""

import math
import os
import random

import bpy  # noqa: I001  (bpy must load before bmesh when used as a module)
import bmesh
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

# ---------------------------------------------------------------- surface classes (see mb.gd)
CLOTH = 1.0
STONE = 0.9
METAL = 0.8
WOOD = 0.7
SKIN = 0.6
CRYSTAL = 0.5
FOLIAGE = 0.4
SCALE = 0.3
HAIR = 0.2
THIN = -0.025

MAT_TOON = 0
MAT_PLAIN = 1
MAT_GLOW = 2
MAT_NAMES = ("toon", "plain", "glow")

FPS = 30
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))

# Godot -> Blender basis change (x, y, z) -> (x, -z, y)
C = Matrix(((1.0, 0.0, 0.0), (0.0, 0.0, -1.0), (0.0, 1.0, 0.0)))
CI = C.transposed()


def g2b(p):
    return Vector((p[0], -p[2], p[1]))


def b2g(p):
    return Vector((p[0], p[2], -p[1]))


def V(x, y=None, z=None):
    if y is None:
        return Vector(x)
    return Vector((x, y, z))


# ---------------------------------------------------------------- colour helpers
def _s2l(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rgb(c):
    """sRGB hex string / tuple -> sRGB float tuple (r, g, b)."""
    if isinstance(c, str):
        h = c.lstrip("#")
        return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return tuple(c[:3])


def mix(a, b, t):
    a = rgb(a)
    b = rgb(b)
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def lighten(c, t):
    return mix(c, (1.0, 1.0, 1.0), t)


def darken(c, t):
    c = rgb(c)
    return tuple(x * (1.0 - t) for x in c)


def lin(c, cls):
    """Final vertex colour: linear RGB and the class in alpha."""
    c = rgb(c)
    return (_s2l(c[0]), _s2l(c[1]), _s2l(c[2]), cls)


def grey(v):
    return (v, v, v)


def to_hsv(c):
    import colorsys
    return colorsys.rgb_to_hsv(*rgb(c))


def hsv(h, s, v):
    """sRGB tuple from hue (wraps), saturation and value (clamped)."""
    import colorsys
    return colorsys.hsv_to_rgb(h % 1.0, max(0.0, min(1.0, s)), max(0.0, min(1.0, v)))


def harmonise(o):
    """A fuller palette for a costume.  Unless ``o["monotone"]`` is set, every part the script did
    not colour gets a harmonious one, and parts that are only a darker or lighter copy of the robe
    are turned round the colour wheel: the inner robe becomes a pastel of an analogous hue, the
    trousers a deep analogous tone, the sash and the middle collar band a complement of the robe,
    the trim a light warm tint.  Returns a new options dict."""
    o = dict(o)
    if o.get("monotone") or o.get("tint_cloth"):
        # recolourable enemies keep neutral cloth: the game paints them from its own palette
        return o
    rh, rs, rv = to_hsv(o.get("robe", "3a8ae8"))
    grey_robe = rs < 0.12

    def close(c):
        h, s, v = to_hsv(c)
        dh = min(abs(h - rh), 1.0 - abs(h - rh))
        return s < 0.1 or grey_robe or dh < 0.06

    comp = (rh + 0.5) % 1.0 if not grey_robe else 0.08
    if "inner" not in o or (to_hsv(o["inner"])[1] < 0.08 and to_hsv(o["inner"])[2] > 0.85):
        base = rgb(o.get("inner", "f8f4ec"))
        o["inner"] = mix(base, hsv(rh - 0.08, 0.45, 1.0), 0.3)
    if "pants" not in o or close(o["pants"]):
        pv = to_hsv(o["pants"])[2] if "pants" in o else rv * 0.45
        o["pants"] = hsv(rh - 0.12, max(rs * 0.7, 0.3), max(0.18, min(0.5, pv * 1.1)))
    if "sash" not in o or close(o["sash"]):
        sv = to_hsv(o["sash"])[2] if "sash" in o else 0.5
        o["sash"] = hsv(comp, 0.55, max(0.3, min(0.85, sv * 1.2 + 0.1)))
    if "collar2" not in o or close(o["collar2"]):
        o["collar2"] = hsv(comp + 0.06, 0.45, 0.75)
    if "trim" not in o:
        o["trim"] = hsv(rh + 0.06, 0.18, 0.97)
    if "boots" not in o:
        o["boots"] = hsv(rh - 0.12, 0.35, 0.2)
    return o


# ---------------------------------------------------------------- Euler / pose maths
def euler_g(rot):
    """Godot Basis.from_euler(rot) (order YXZ) as a 3x3 matrix in Godot space."""
    x, y, z = rot
    return Matrix.Rotation(y, 3, "Y") @ Matrix.Rotation(x, 3, "X") @ Matrix.Rotation(z, 3, "Z")


def euler_b(rot):
    """The same rotation expressed in Blender axes."""
    return C @ euler_g(rot) @ CI


def look_frame(d):
    """An orthonormal frame (n, b) perpendicular to direction d (all Godot space)."""
    d = Vector(d).normalized()
    up = Vector((0, 1, 0)) if abs(d.y) < 0.9 else Vector((1, 0, 0))
    n = d.cross(up).normalized()
    b = d.cross(n).normalized()
    return n, b


def seg_dist(p, a, b):
    ab = b - a
    t = 0.0 if ab.length_squared < 1e-12 else max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (a + ab * t - p).length


# ---------------------------------------------------------------- scene
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    random.seed(7)
    # bake_action keys a pose every 1/FPS s on consecutive frames, so the scene must run at FPS:
    # Blender's factory scene runs at 24 fps, which stretched every exported clip by a quarter (a
    # 0.55 s attack lasted 0.69 s, the walk slowed down)
    bpy.context.scene.render.fps = FPS
    bpy.context.scene.render.fps_base = 1.0


def out_path(rel):
    p = os.path.join(ROOT, "assets", rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


# ---------------------------------------------------------------- mesh builder
class Builder:
    """Accumulates geometry with colour, tint, material and bone weights in one bmesh."""

    def __init__(self, name="mesh"):
        self.name = name
        self.bm = bmesh.new()
        self.cl = self.bm.verts.layers.float_color.new("Col")
        self.tl = self.bm.verts.layers.float.new("tint")
        self.pl = self.bm.verts.layers.float.new("pal")
        self.cur_pal = 0.0  # palette slot given to everything added until it is changed
        self.dl = self.bm.verts.layers.deform.verify()
        self.groups = []
        self.gidx = {}
        self.auto = None  # optional callable(pos) -> {bone: weight} used when no bone is given

    # ---- low level
    def gi(self, bone):
        if bone not in self.gidx:
            self.gidx[bone] = len(self.groups)
            self.groups.append(bone)
        return self.gidx[bone]

    def _weights(self, bone, p):
        if bone is None:
            return self.auto(p) if self.auto is not None else {}
        if isinstance(bone, str):
            return {bone: 1.0}
        if callable(bone):
            return bone(p)
        return dict(bone)

    def add(self, verts, faces, col, cls=CLOTH, bone=None, tint=0.0, mat=MAT_TOON, smooth=True, cols=None, tints=None, bones=None, closed=True):
        """Add raw geometry.  verts: Godot-space points; faces: index tuples (CCW seen from outside).
        `cols`/`tints`/`bones` give per-vertex overrides."""
        bm = self.bm
        out = []
        for i, p in enumerate(verts):
            v = bm.verts.new(g2b(p))
            c = cols[i] if cols is not None else col
            if len(c) == 4:
                v[self.cl] = c
            else:
                v[self.cl] = lin(c, cls)
            v[self.tl] = tints[i] if tints is not None else tint
            v[self.pl] = self.cur_pal
            w = self._weights(bones[i] if bones is not None else bone, Vector(p))
            tot = sum(w.values())
            for bn, wt in w.items():
                if wt > 1e-4 and tot > 0:
                    v[self.dl][self.gi(bn)] = wt / tot
            out.append(v)
        made = []
        for f in faces:
            try:
                face = bm.faces.new([out[j] for j in f])
            except ValueError:
                continue
            face.material_index = mat
            face.smooth = smooth
            made.append(face)
        if closed and made:
            self._orient(made)
        return out

    def _orient(self, faces):
        """Flip a closed part whose faces point inwards (signed volume test)."""
        vol = 0.0
        for f in faces:
            vs = [v.co for v in f.verts]
            for k in range(1, len(vs) - 1):
                vol += vs[0].dot(vs[k].cross(vs[k + 1]))
        if vol < 0.0:
            bmesh.ops.reverse_faces(self.bm, faces=faces)

    # ---- primitives
    def ellipsoid(self, c, r, col, cls=CLOTH, bone=None, rot=(0, 0, 0), seg=16, rings=10, tint=0.0, mat=MAT_TOON, col2=None, smooth=True, squash_top=1.0):
        """Ellipsoid centred at c with radii r (Godot axes before rotation).  col2 shades the
        underside (a simple two-tone gradient from top to bottom)."""
        c = V(c)
        R = euler_g(rot)
        verts = []
        cols = []
        for j in range(rings + 1):
            th = math.pi * j / rings
            y = math.cos(th)
            s = math.sin(th)
            for i in range(seg):
                ph = 2 * math.pi * i / seg
                p = Vector((math.cos(ph) * s * r[0], y * r[1] * (squash_top if y > 0 else 1.0), math.sin(ph) * s * r[2]))
                verts.append(c + R @ p)
                if col2 is not None:
                    cols.append(lin(mix(col2, col, (y + 1) * 0.5), cls))
        faces = []
        for j in range(rings):
            for i in range(seg):
                a = j * seg + i
                b = j * seg + (i + 1) % seg
                faces.append((a, b, b + seg, a + seg))
        return self.add(verts, faces, col, cls, bone, tint, mat, smooth, cols=cols if col2 is not None else None)

    def ball(self, c, r, col, **kw):
        return self.ellipsoid(c, (r, r, r), col, **kw)

    def superquad(self, c, r, col, e=0.35, cls=STONE, bone=None, rot=(0, 0, 0), seg=16, rings=10, tint=0.0, mat=MAT_TOON, smooth=True, col2=None):
        """Superellipsoid: e=1 is an ellipsoid, small e a rounded box (armour plates, bricks,
        pillows, carved stone)."""
        c = V(c)
        R = euler_g(rot)

        def sp(w, m):
            s = math.copysign(abs(w) ** m, w)
            return s

        verts = []
        cols = []
        for j in range(rings + 1):
            th = -math.pi / 2 + math.pi * j / rings
            for i in range(seg):
                ph = -math.pi + 2 * math.pi * i / seg
                x = sp(math.cos(th), e) * sp(math.cos(ph), e)
                z = sp(math.cos(th), e) * sp(math.sin(ph), e)
                y = sp(math.sin(th), e)
                verts.append(c + R @ Vector((x * r[0], y * r[1], z * r[2])))
                if col2 is not None:
                    cols.append(lin(mix(col2, col, j / rings), cls))
        faces = []
        for j in range(rings):
            for i in range(seg):
                a = j * seg + i
                b = j * seg + (i + 1) % seg
                faces.append((a, a + seg, b + seg, b))
        return self.add(verts, faces, col, cls, bone, tint, mat, smooth, cols=cols if col2 is not None else None)

    def tube(self, pts, radii, col, cls=CLOTH, bone=None, bones=None, seg=10, cap0=True, cap1=True, tint=0.0, mat=MAT_TOON, cols=None, flat=1.0, twist=0.0, up=None, smooth=True, tints=None):
        """Swept tube along a polyline with per-point radius (scalar or (rx, ry)).  `bones` gives
        per-point bone weights so limbs bend smoothly across joints.  `cols` per point colours.
        Caps are rounded."""
        pts = [V(p) for p in pts]
        n = len(pts)
        tans = []
        for i in range(n):
            a = pts[max(0, i - 1)]
            b = pts[min(n - 1, i + 1)]
            tans.append((b - a).normalized())
        if up is not None:
            nrm = tans[0].cross(V(up)).normalized()
            if nrm.length < 0.5:
                nrm, _ = look_frame(tans[0])
        else:
            nrm, _ = look_frame(tans[0])
        frames = []
        for i in range(n):
            if i > 0:
                q = tans[i - 1].rotation_difference(tans[i])
                nrm = (q @ nrm).normalized()
            bi = tans[i].cross(nrm).normalized()
            frames.append((nrm.copy(), bi))
        verts = []
        vcols = []
        vbones = []
        vtints = []
        ring_of = []
        for i in range(n):
            r = radii[i]
            rx, ry = (r, r * flat) if not isinstance(r, (tuple, list)) else r
            nn, bb = frames[i]
            tw = twist * i / max(1, n - 1)
            for k in range(seg):
                a = 2 * math.pi * k / seg + tw
                verts.append(pts[i] + nn * (math.cos(a) * rx) + bb * (math.sin(a) * ry))
                vcols.append(lin(cols[i], cls) if cols is not None else lin(col, cls))
                vbones.append(bones[i] if bones is not None else bone)
                vtints.append(tints[i] if tints is not None else tint)
            ring_of.append(i)
        faces = []
        for i in range(n - 1):
            for k in range(seg):
                a = i * seg + k
                b = i * seg + (k + 1) % seg
                faces.append((a, b, b + seg, a + seg))

        def cap(i, sign):
            r = radii[i]
            rx, ry = (r, r * flat) if not isinstance(r, (tuple, list)) else r
            nn, bb = frames[i]
            base = len(verts)
            # two shrinking rings and a pole make a soft dome
            for step, (sc, push) in enumerate(((0.75, 0.55), (0.4, 0.85))):
                for k in range(seg):
                    a = 2 * math.pi * k / seg
                    verts.append(pts[i] + tans[i] * (sign * push * min(rx, ry) * 0.9) + nn * (math.cos(a) * rx * sc) + bb * (math.sin(a) * ry * sc))
                    vcols.append(vcols[i * seg])
                    vbones.append(vbones[i * seg])
                    vtints.append(vtints[i * seg])
            pole = len(verts)
            verts.append(pts[i] + tans[i] * (sign * min(rx, ry) * 0.95))
            vcols.append(vcols[i * seg])
            vbones.append(vbones[i * seg])
            vtints.append(vtints[i * seg])
            rings = [i * seg, base, base + seg]
            for j in range(2):
                for k in range(seg):
                    a = rings[j] + k
                    b = rings[j] + (k + 1) % seg
                    a2 = rings[j + 1] + k
                    b2 = rings[j + 1] + (k + 1) % seg
                    faces.append((a, b, b2, a2) if sign > 0 else (a, a2, b2, b))
            for k in range(seg):
                a = base + seg + k
                b = base + seg + (k + 1) % seg
                faces.append((a, b, pole) if sign > 0 else (a, pole, b))

        if cap0:
            cap(0, -1)
        if cap1:
            cap(n - 1, 1)
        return self.add(verts, faces, col, cls, None, tint, mat, smooth, cols=vcols, bones=vbones, tints=vtints, closed=cap0 and cap1)

    def limb(self, a, b, r0, r1, col, bone=None, bones=None, seg=10, cls=CLOTH, n=4, bulge=0.0, **kw):
        """Tapered limb between two points with an optional muscle bulge in the middle."""
        a = V(a)
        b = V(b)
        pts = [a.lerp(b, i / (n - 1)) for i in range(n)]
        radii = []
        for i in range(n):
            t = i / (n - 1)
            radii.append(r0 + (r1 - r0) * t + bulge * math.sin(math.pi * t))
        if bones is not None and len(bones) == 2 and not isinstance(bones[0], (list, tuple, dict)):
            # blend from the first bone to the second along the limb
            b0, b1 = bones
            bones = [{b0: 1.0 - t, b1: t} if b0 != b1 else b0 for t in [i / (n - 1) for i in range(n)]]
        return self.tube(pts, radii, col, cls=cls, bone=bone, bones=bones, seg=seg, **kw)

    def lathe(self, c, prof, col, cls=CLOTH, bone=None, seg=16, rot=(0, 0, 0), squash=(1.0, 1.0), col_top=None, tint=0.0, mat=MAT_TOON, cap_bottom=True, cap_top=True, smooth=True, bone_fn=None, open_angle=0.0, cols=None, folds=None):
        """Surface of revolution around local +Y.  prof = [(radius, y), ...] bottom to top.
        `open_angle` leaves a slit at the front (robes open at the legs).  `folds` = (count,
        depth, phase) ripples the radius into vertical pleats that deepen towards the bottom, so
        cloth hangs in folds instead of as a smooth cone."""
        c = V(c)
        R = euler_g(rot)
        verts = []
        vcols = []
        n = len(prof)
        full = open_angle <= 0.0
        cnt = seg if full else seg + 1
        for j, (r, y) in enumerate(prof):
            t = j / max(1, n - 1)
            cc = cols[j] if cols is not None else (mix(col, col_top, t) if col_top is not None else rgb(col))
            for i in range(cnt):
                if full:
                    a = 2 * math.pi * i / seg
                else:
                    a = open_angle * 0.5 + (2 * math.pi - open_angle) * i / seg
                rr = r
                if folds is not None:
                    rr = r * (1.0 + folds[1] * math.sin(folds[0] * a + folds[2]) * (1.0 - t) ** 0.7)
                p = Vector((math.sin(a) * rr * squash[0], y, math.cos(a) * rr * squash[1]))
                verts.append(c + R @ p)
                fc = cc
                if folds is not None:
                    # fold valleys a little darker, ridges a little lighter
                    k = math.sin(folds[0] * a + folds[2]) * (1.0 - t) ** 0.7
                    fc = lighten(cc, 0.06 * k) if k > 0 else darken(cc, -0.12 * k)
                vcols.append(lin(fc, cls))
        faces = []
        for j in range(n - 1):
            for i in range(cnt if full else cnt - 1):
                a = j * cnt + i
                b = j * cnt + (i + 1) % cnt
                faces.append((a, a + cnt, b + cnt, b))
        if full:
            if cap_bottom and prof[0][0] > 1e-4:
                verts.append(c + R @ Vector((0, prof[0][1], 0)))
                vcols.append(vcols[0])
                p = len(verts) - 1
                for i in range(cnt):
                    faces.append((i, (i + 1) % cnt, p))
            if cap_top and prof[-1][0] > 1e-4:
                verts.append(c + R @ Vector((0, prof[-1][1], 0)))
                vcols.append(vcols[-2])
                p = len(verts) - 1
                o = (n - 1) * cnt
                for i in range(cnt):
                    faces.append((o + (i + 1) % cnt, o + i, p))
        bones = None
        if bone_fn is not None:
            bones = [bone_fn(Vector(v)) for v in verts]
        if not full:
            # open shells are seen from both sides: add a slightly inset back face
            front = self.add(verts, faces, col, cls, bone, tint, mat, smooth, cols=vcols, bones=bones, closed=False)
            inner = [c + (Vector(v) - c) * 0.985 for v in verts]
            back = [tuple(reversed(f)) for f in faces]
            self.add(inner, back, col, cls, bone, tint, mat, smooth, cols=[(x[0] * 0.7, x[1] * 0.7, x[2] * 0.7, x[3]) for x in vcols], bones=bones, closed=False)
            return front
        return self.add(verts, faces, col, cls, bone, tint, mat, smooth, cols=vcols, bones=bones, closed=True)

    def cyl(self, c, r, h, col, seg=12, **kw):
        return self.lathe(c, [(r, -h / 2), (r, h / 2)], col, seg=seg, **kw)

    def cone(self, c, r, h, col, seg=12, **kw):
        return self.lathe(c, [(r, -h / 2), (0.0001, h / 2)], col, seg=seg, cap_top=False, **kw)

    def box(self, c, s, col, rot=(0, 0, 0), **kw):
        return self.superquad(c, (s[0] / 2, s[1] / 2, s[2] / 2), col, e=0.12, rot=rot, seg=12, rings=6, **kw)

    def sheet(self, rows, col, cls=CLOTH, bone=None, bones=None, tint=0.0, mat=MAT_TOON, cols=None, thickness=0.006):
        """A double-sided grid surface from rows of points (all rows the same length).  Used for
        capes, sleeves, wings, petals and leaves.  The class is nudged for the outline pass."""
        nr = len(rows)
        nc = len(rows[0])
        pts = [V(p) for row in rows for p in row]
        # per-vertex normal estimate for the back-face offset
        nrm = []
        for j in range(nr):
            for i in range(nc):
                a = V(rows[j][min(nc - 1, i + 1)]) - V(rows[j][max(0, i - 1)])
                b = V(rows[min(nr - 1, j + 1)][i]) - V(rows[max(0, j - 1)][i])
                nn = a.cross(b)
                nrm.append(nn.normalized() if nn.length > 1e-9 else Vector((0, 0, 1)))
        faces = []
        for j in range(nr - 1):
            for i in range(nc - 1):
                a = j * nc + i
                faces.append((a, a + 1, a + nc + 1, a + nc))
        vcols = None
        if cols is not None:
            vcols = [lin(cols[j][i] if isinstance(cols[j], (list, tuple)) and isinstance(cols[j][0], (list, tuple, str)) else cols[j], cls + THIN) for j in range(nr) for i in range(nc)]
        vb = None
        if bones is not None:
            vb = [bones[j] for j in range(nr) for i in range(nc)]
        front = [p + nrm[k] * thickness * 0.5 for k, p in enumerate(pts)]
        back = [p - nrm[k] * thickness * 0.5 for k, p in enumerate(pts)]
        c2 = lin(col, cls + THIN)
        out = self.add(front, faces, c2, cls, bone, tint, mat, True, cols=vcols, bones=vb, closed=False)
        dark = [(x[0] * 0.75, x[1] * 0.75, x[2] * 0.75, x[3]) for x in vcols] if vcols is not None else None
        out = out + self.add(back, [tuple(reversed(f)) for f in faces], (c2[0] * 0.75, c2[1] * 0.75, c2[2] * 0.75, c2[3]), cls, bone, tint, mat, True, cols=dark, bones=vb, closed=False)
        return out

    def leaf(self, root, tip, width, col, side=None, cls=FOLIAGE, bone=None, tint=0.0, col_tip=None, curl=0.15, n=5, mat=MAT_TOON):
        """A curved pointed blade (leaf, feather, hair lock, flame tongue, petal)."""
        root = V(root)
        tip = V(tip)
        d = tip - root
        if side is None:
            side, _ = look_frame(d)
        side = V(side).normalized()
        nrm = d.cross(side).normalized()
        rows = []
        cols = []
        for j in range(n):
            t = j / (n - 1)
            w = width * math.sin(math.pi * min(1.0, t * 1.15 + 0.05)) * (1.0 - 0.6 * t)
            cen = root + d * t + nrm * (math.sin(math.pi * t) * curl * d.length)
            rows.append([cen - side * w, cen + nrm * (w * 0.25), cen + side * w])
            cols.append(mix(col, col_tip, t) if col_tip is not None else rgb(col))
        self.sheet(rows, col, cls, bone, None, tint, mat, cols=cols)

    def ribbon(self, pts, widths, side, col, cls=CLOTH, bone=None, bones=None, col_end=None, tint=0.0, mat=MAT_TOON):
        pts = [V(p) for p in pts]
        side = V(side).normalized()
        rows = []
        cols = []
        for i, p in enumerate(pts):
            rows.append([p - side * widths[i], p + side * widths[i]])
            t = i / max(1, len(pts) - 1)
            cols.append(mix(col, col_end, t) if col_end is not None else rgb(col))
        return self.sheet(rows, col, cls, bone, bones, tint, mat, cols=cols)

    def disc(self, c, r, col, cls=CLOTH, bone=None, seg=20, rot=(0, 0, 0), tint=0.0, mat=MAT_TOON, col_rim=None, thick=0.01):
        c = V(c)
        R = euler_g(rot)
        rows = [[c + R @ Vector((0, 0, 0))] * (seg + 1), [c + R @ Vector((math.sin(2 * math.pi * i / seg) * r, 0, math.cos(2 * math.pi * i / seg) * r)) for i in range(seg + 1)]]
        cols = [rgb(col), rgb(col_rim) if col_rim is not None else rgb(col)]
        self.sheet(rows, col, cls, bone, None, tint, mat, cols=cols, thickness=thick)

    def crystal(self, c, r, h, col, cls=CRYSTAL, bone=None, rot=(0, 0, 0), sides=6, tint=0.0, mat=MAT_TOON):
        """Faceted gem: a prism with pointed ends, flat shaded."""
        return self.lathe(c, [(0.0001, -h * 0.25), (r, 0.0), (r * 0.9, h * 0.55), (0.0001, h * 0.8)], col, cls=cls, bone=bone, seg=sides, rot=rot, tint=tint, mat=mat, smooth=False, cap_bottom=False, cap_top=False)

    def skin(self, nodes, edges, col_fn, cls=CLOTH, bone=None, subdiv=2, tint_fn=None, mat=MAT_TOON):
        """Organic body from a skeleton graph using Blender's Skin + Subdivision modifiers.
        nodes = [(pos, radius or (rx, ry)), ...] in Godot space; edges = [(i, j), ...].
        col_fn(pos) -> sRGB colour; weights come from `bone` (or the builder's auto weights)."""
        me = bpy.data.meshes.new("skin_tmp")
        me.from_pydata([g2b(p) for p, _ in nodes], edges, [])
        ob = bpy.data.objects.new("skin_tmp", me)
        bpy.context.scene.collection.objects.link(ob)
        sk = ob.modifiers.new("skin", "SKIN")
        sk.use_smooth_shade = True
        sk.branch_smoothing = 0.6
        for i, (_, r) in enumerate(nodes):
            rx, ry = (r, r) if not isinstance(r, (tuple, list)) else r
            me.skin_vertices[0].data[i].radius = (rx, ry)
        me.skin_vertices[0].data[0].use_root = True
        sub = ob.modifiers.new("sub", "SUBSURF")
        sub.levels = subdiv
        sub.render_levels = subdiv
        dg = bpy.context.evaluated_depsgraph_get()
        ev = ob.evaluated_get(dg)
        m2 = ev.to_mesh()
        verts = [b2g(v.co) for v in m2.vertices]
        faces = [tuple(p.vertices) for p in m2.polygons]
        cols = [lin(col_fn(p), cls) for p in verts]
        tints = [tint_fn(p) for p in verts] if tint_fn is not None else None
        out = self.add(verts, faces, col_fn(verts[0]), cls, bone, 0.0, mat, True, cols=cols, tints=tints, closed=False)
        ev.to_mesh_clear()
        bpy.data.objects.remove(ob)
        bpy.data.meshes.remove(me)
        return out

    def eye(self, c, r, iris, side=1, look=(0.0, 0.0), bone=None, slit=False, glow=False, rot_y=0.0, h=1.25, mat=MAT_PLAIN, accent=False):
        """Anime eye pressed onto a surface facing +Z: white, a dark limbal ring, an iris that is
        darker under the lid and lighter at the bottom, pupil, two highlights and a lower glint.
        `accent` paints the iris in greys on the palette's accent slot (monsters: the enemy's
        element colour looks out of it)."""
        c = V(c)
        ry = rot_y * side
        R = euler_g((0, ry, 0))
        self.ellipsoid(c, (r, r * h, r * 0.45), "f8f8ff", cls=SKIN, bone=bone, rot=(0, ry, 0), seg=16, rings=10, mat=mat, col2="d8dcf0")
        ic = c + R @ Vector((look[0] * r, look[1] * r, r * 0.3))
        old_pal = self.cur_pal
        tint = 0.0
        if accent:
            iris = "e8e8e8"
            tint = 1.0
            self.cur_pal = 1.0
        self.ellipsoid(ic - R @ Vector((0, 0, r * 0.02)), (r * 0.76, r * h * 0.82, r * 0.27), darken(iris, 0.6), cls=CRYSTAL, bone=bone, rot=(0, ry, 0), seg=16, rings=8, mat=mat, tint=tint)
        self.ellipsoid(ic, (r * 0.7, r * 0.95 * h * 0.8, r * 0.28), lighten(iris, 0.18), cls=CRYSTAL, bone=bone, rot=(0, ry, 0), seg=16, rings=10, mat=MAT_GLOW if glow else mat, col2=darken(iris, 0.45), tint=tint)
        self.ellipsoid(ic + R @ Vector((0, -r * 0.35, r * 0.05)), (r * 0.42, r * 0.22, r * 0.2), lighten(iris, 0.45), cls=CRYSTAL, bone=bone, rot=(0, ry, 0), seg=10, rings=6, mat=mat, tint=tint)
        self.cur_pal = old_pal
        pc = ic + R @ Vector((0, 0, r * 0.12))
        if slit:
            self.ellipsoid(pc, (r * 0.14, r * 0.7, r * 0.2), "100810", cls=SKIN, bone=bone, rot=(0, ry, 0), seg=10, rings=6, mat=mat)
        else:
            self.ellipsoid(pc, (r * 0.36, r * 0.5, r * 0.2), "180c20", cls=SKIN, bone=bone, rot=(0, ry, 0), seg=10, rings=6, mat=mat)
        hl = pc + R @ Vector((r * 0.25 * side, r * 0.3, r * 0.1))
        self.ellipsoid(hl, (r * 0.18, r * 0.2, r * 0.1), "ffffff", cls=CRYSTAL, bone=bone, rot=(0, ry, 0), seg=8, rings=5, mat=MAT_GLOW)
        hl2 = pc + R @ Vector((-r * 0.2 * side, -r * 0.3, r * 0.1))
        self.ellipsoid(hl2, (r * 0.09, r * 0.09, r * 0.05), "ffffff", cls=CRYSTAL, bone=bone, rot=(0, ry, 0), seg=6, rings=4, mat=MAT_GLOW)

    def palette(self, verts, slot):
        """Put already-built vertices in a palette slot (0 primary, 0.5 secondary, 1 accent)."""
        for v in verts:
            v[self.pl] = slot

    def palette_where(self, pred, slot):
        """Palette slot for every vertex where pred(godot_pos, linear_rgba) holds."""
        for v in self.bm.verts:
            if pred(b2g(v.co), v[self.cl]):
                v[self.pl] = slot

    def coat_slots(self, rise=(0.05, 0.2), fall=(0.07, 0.24), under_grey=0.94, mark_grey=0.9):
        """Countershading and markings for the game's palette (see assets.gd).

        Coats are painted in grey values: a pale belly, bib, throat and cheeks, dark stripes,
        saddles, masks and tail tips, all on the one *dominant* slot, so in game they came out as
        one hue in light and dark.  Here every tinted dominant vertex noticeably paler than the
        coat's median grey blends into the *underside* slot (0..0.2) and every one noticeably
        darker into the *markings* slot (0.6..0.8), weighted by how far it is from the median
        (`rise`/`fall` are the ramps), with its grey lifted towards a neutral so the palette's own
        colour shows (the AO baked afterwards still darkens the creases).  The median is taken by
        surface area, so finely modelled small parts (legs, joints, teeth) cannot outvote the
        broad coat, and the ramps widen so that neither role claims much more than 40% of it: the
        dominant colour stays dominant.  Run before bake_ao."""
        coat = []
        for v in self.bm.verts:
            if v[self.tl] > 0.05 and v[self.pl] < 0.02:
                c = v[self.cl]
                area = sum(f.calc_area() / len(f.verts) for f in v.link_faces)
                coat.append((v, (0.3 * c[0] + 0.55 * c[1] + 0.15 * c[2]) ** (1.0 / 2.2), area))
        if len(coat) < 8:
            return 0, 0
        by_l = sorted(coat, key=lambda e: e[1])
        total = sum(e[2] for e in coat) or 1.0

        def quantile(q):
            acc = 0.0
            for _, L, ar in by_l:
                acc += ar
                if acc >= q * total:
                    return L
            return by_l[-1][1]

        med = quantile(0.5)
        hi = quantile(0.6) - med
        lo = med - quantile(0.4)
        rise = (max(rise[0], hi), max(rise[1], hi + 0.12))
        fall = (max(fall[0], lo), max(fall[1], lo + 0.14))

        def ramp(a, b, x):
            t = min(1.0, max(0.0, (x - a) / (b - a)))
            return t * t * (3.0 - 2.0 * t)

        ug = (under_grey ** 2.2,) * 3
        mg = (mark_grey ** 2.2,) * 3
        n_u = n_m = 0
        for v, L, _ in coat:
            wu = ramp(med + rise[0], med + rise[1], L)
            wm = ramp(med - fall[0], med - fall[1], L)
            c = v[self.cl]
            if wu > 0.02:
                v[self.pl] = 0.2 * wu
                v[self.cl] = (c[0] + (ug[0] - c[0]) * wu, c[1] + (ug[1] - c[1]) * wu, c[2] + (ug[2] - c[2]) * wu, c[3])
                v[self.tl] = v[self.tl] + (1.0 - v[self.tl]) * wu
                n_u += 1
            elif wm > 0.02:
                v[self.pl] = 0.6 + 0.2 * wm
                v[self.cl] = (c[0] + (mg[0] - c[0]) * wm, c[1] + (mg[1] - c[1]) * wm, c[2] + (mg[2] - c[2]) * wm, c[3])
                v[self.tl] = v[self.tl] + (1.0 - v[self.tl]) * wm
                n_m += 1
        return n_u, n_m

    def recolor(self, verts, fn, cls=CLOTH):
        """Repaint vertices with fn(godot_pos, old_srgb_guess) -> sRGB colour (embroidery, stripes,
        markings).  Keeps the surface class."""
        for v in verts:
            p = b2g(v.co)
            col = fn(p)
            if col is not None:
                c = lin(col, cls)
                # keep the vertex's own class alpha (thin sheets carry an offset the outline needs)
                v[self.cl] = (c[0], c[1], c[2], v[self.cl][3])

    def scale_where(self, pred, pivot, k):
        """Scale every vertex for which pred(vertex weights {bone: w}) is true about `pivot`."""
        inv = {i: n for n, i in self.gidx.items()}
        pv = g2b(V(pivot))
        for v in self.bm.verts:
            w = {inv[g]: x for g, x in v[self.dl].items()}
            if pred(w):
                v.co = pv + (v.co - pv) * k

    # ---- finishing
    def bake_ao(self, samples=20, dist=0.35, strength=0.55, floor_y=None, floor_k=0.25):
        """Ambient occlusion baked into the vertex colours with BVH ray casts (rest pose), plus an
        optional darkening towards the ground."""
        bm = self.bm
        bm.normal_update()
        tree = BVHTree.FromBMesh(bm)
        dirs = []
        for k in range(samples):
            u = (k + 0.5) / samples
            ph = k * 2.399963
            r = math.sqrt(u)
            dirs.append(Vector((math.cos(ph) * r, math.sin(ph) * r, math.sqrt(max(0.0, 1.0 - u)))))
        for v in bm.verts:
            n = v.normal
            if n.length < 0.5:
                continue
            t = n.orthogonal().normalized()
            b = n.cross(t)
            o = v.co + n * 0.003
            occ = 0.0
            for d in dirs:
                w = t * d.x + b * d.y + n * d.z
                hit = tree.ray_cast(o, w, dist)
                if hit[0] is not None:
                    occ += 1.0 - (hit[3] / dist) * 0.6
            f = 1.0 - strength * (occ / samples)
            if floor_y is not None:
                gy = b2g(v.co).y
                f *= 1.0 - floor_k * max(0.0, 1.0 - (gy - floor_y) / 0.5)
            c = v[self.cl]
            v[self.cl] = (c[0] * f, c[1] * f, c[2] * f, c[3])

    def to_object(self, name=None, parent=None):
        name = name or self.name
        me = bpy.data.meshes.new(name)
        self.bm.normal_update()
        self.bm.to_mesh(me)
        ob = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(ob)
        # vertex groups in the order the deform layer refers to them
        for g in self.groups:
            ob.vertex_groups.new(name=g)
        # colour attribute must be the active one for the exporter
        ca = me.color_attributes.get("Col")
        if ca is not None:
            me.color_attributes.active_color = ca
            me.color_attributes.render_color_index = me.color_attributes.find("Col")
        # tint weight -> UV channel 0 (U)
        uv = me.uv_layers.new(name="tint")
        ta = me.attributes.get("tint")
        pa = me.attributes.get("pal")
        if ta is not None:
            vals = [d.value for d in ta.data]
            pals = [d.value for d in pa.data] if pa is not None else [0.0] * len(vals)
            for poly in me.polygons:
                for li in poly.loop_indices:
                    vi = me.loops[li].vertex_index
                    uv.data[li].uv = (vals[vi], pals[vi])
            me.attributes.remove(ta)
        if pa is not None:
            me.attributes.remove(pa)
        for nm in MAT_NAMES:
            m = bpy.data.materials.get(nm) or bpy.data.materials.new(nm)
            me.materials.append(m)
        if parent is not None:
            ob.parent = parent
            mod = ob.modifiers.new("rig", "ARMATURE")
            mod.object = parent
        self.bm.free()
        return ob

    def tri_count(self):
        return sum(len(f.verts) - 2 for f in self.bm.faces)


# ---------------------------------------------------------------- automatic skin weights
def auto_weights(rig, names=None, sharp=4.0, k=2):
    """Weights from the distance to each bone segment (nearest k bones, inverse-power falloff).
    Good for organic skin-modifier bodies."""
    segs = [(nm, V(h), V(t)) for nm, (h, t, _) in rig.bones.items() if (names is None or nm in names)]

    def fn(p):
        ds = sorted(((seg_dist(p, a, b), nm) for nm, a, b in segs))[:k]
        w = {}
        for d, nm in ds:
            w[nm] = 1.0 / (d ** sharp + 1e-6)
        return w

    return fn


# ---------------------------------------------------------------- rig
class Rig:
    """Armature description in Godot space; bones are created in insertion order."""

    def __init__(self, name="rig"):
        self.name = name
        self.bones = {}
        self.obj = None
        self.rest = {}

    def bone(self, name, head, tail, parent=None):
        self.bones[name] = (V(head), V(tail), parent)
        return name

    def head(self, name):
        return self.bones[name][0]

    def tail(self, name):
        return self.bones[name][1]

    def build(self):
        arm = bpy.data.armatures.new(self.name)
        ob = bpy.data.objects.new(self.name, arm)
        bpy.context.scene.collection.objects.link(ob)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.mode_set(mode="EDIT")
        for nm, (h, t, par) in self.bones.items():
            eb = arm.edit_bones.new(nm)
            eb.head = g2b(h)
            eb.tail = g2b(t)
            eb.roll = 0.0
            if par is not None:
                eb.parent = arm.edit_bones[par]
                eb.use_connect = False
        bpy.ops.object.mode_set(mode="OBJECT")
        self.obj = ob
        for b in arm.bones:
            self.rest[b.name] = b.matrix_local.to_3x3()
        return ob


# ---------------------------------------------------------------- animation
def bake_action(rig, name, seconds, fn, fps=FPS):
    """Sample fn(t) -> {bone: (rot, loc)} every frame and store it as an action.  Rotations are
    Godot Euler angles in the parent's frame; locations are Godot-space offsets.  Every bone is
    keyed on every frame so clips never inherit a pose from the previous one."""
    ob = rig.obj
    ad = ob.animation_data_create()
    act = bpy.data.actions.new(name)
    ad.action = act
    frames = max(1, int(round(seconds * fps)))
    prev = {}
    for f in range(frames + 1):
        t = f / fps
        pose = fn(t)
        for pb in ob.pose.bones:
            val = pose.get(pb.name, ((0, 0, 0), (0, 0, 0)))
            rot, loc = val[0], val[1]
            scl = val[2] if len(val) > 2 else (1.0, 1.0, 1.0)
            M = rig.rest[pb.name]
            q = (M.inverted() @ euler_b(rot) @ M).to_quaternion()
            if pb.name in prev and prev[pb.name].dot(q) < 0.0:
                q = -q
            prev[pb.name] = q
            pb.rotation_mode = "QUATERNION"
            pb.rotation_quaternion = q
            pb.location = M.inverted() @ g2b(loc)
            pb.keyframe_insert("rotation_quaternion", frame=f + 1)
            pb.scale = scl
            pb.keyframe_insert("location", frame=f + 1)
            pb.keyframe_insert("scale", frame=f + 1)
    tr = ad.nla_tracks.new()
    tr.name = name
    tr.strips.new(name, 1, act)
    ad.action = None
    for pb in ob.pose.bones:
        pb.rotation_quaternion = Quaternion()
        pb.location = (0, 0, 0)
        pb.scale = (1, 1, 1)


def ease(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


def env(k):
    """0..1..0 envelope over an action."""
    return math.sin(math.pi * max(0.0, min(1.0, k)))


# ---------------------------------------------------------------- export
def export(path, objs, animations=True):
    for o in bpy.context.scene.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    kw = dict(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=False,
        export_texcoords=True,
        export_normals=True,
        export_vertex_color="ACTIVE",
        export_materials="EXPORT",
        export_skins=True,
        export_animations=animations,
    )
    if animations:
        kw["export_animation_mode"] = "ACTIONS"
        # clips are keyed from frame 1: start them at 0 s so a loop's last frame meets its first
        kw["export_anim_slide_to_zero"] = True
    bpy.ops.export_scene.gltf(**kw)
    print("[art] wrote", os.path.relpath(path, ROOT))


export.slides_to_zero = True  # creature.realtime() checks this and leaves the export alone


def decimate(ob, target_tris):
    """Reduce a mesh to roughly `target_tris` triangles with Blender's Decimate (collapse)
    modifier; colours and the tint UV are interpolated across collapsed edges."""
    me = ob.data
    me.calc_loop_triangles()
    tris = len(me.loop_triangles)
    if tris <= target_tris:
        return tris
    mod = ob.modifiers.new("decimate", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.ratio = target_tris / tris
    mod.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    me.calc_loop_triangles()
    print("[art] decimated %s: %d -> %d triangles" % (ob.name, tris, len(me.loop_triangles)))
    return len(me.loop_triangles)


def finish_static(b, rel, ao=True, target_tris=0, **ao_kw):
    """Bake AO and export a static prop (no rig), optionally decimated to a triangle budget
    (landmarks are instanced hundreds of times per map)."""
    if ao:
        b.bake_ao(**ao_kw)
    ob = b.to_object()
    if target_tris > 0:
        decimate(ob, target_tris)
    export(out_path(rel), [ob], animations=False)
    return ob


def scale_asset(b, rig, f):
    """Uniformly scale a built mesh and its (not yet created) rig about the origin."""
    for v in b.bm.verts:
        v.co *= f
    for nm in list(rig.bones):
        h, t, p = rig.bones[nm]
        rig.bones[nm] = (h * f, t * f, p)


def finish_rigged(b, rig, rel, clips, ao=True, coat=None, **ao_kw):
    """Bake AO, bind the mesh to the rig, bake every clip and export.  Monsters first get their
    painted coats split into the palette's underside and markings slots (`Builder.coat_slots`);
    `coat` is False to skip that, or a dict of its keyword arguments."""
    if coat is None:
        coat = rel.startswith("monsters/")
    if coat:
        n_u, n_m = b.coat_slots(**(coat if isinstance(coat, dict) else {}))
        print("[art] coat %s: %d underside, %d markings vertices" % (rel, n_u, n_m))
    if ao:
        b.bake_ao(**ao_kw)
    arm = rig.build()
    ob = b.to_object(parent=arm)
    for nm, (secs, fn) in clips.items():
        bake_action(rig, nm, secs, fn)
    export(out_path(rel), [arm, ob])
    return ob
