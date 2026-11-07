"""Animal anatomy for the monster scripts: sculpted quadruped bodies, legs, paws and hooves, heads,
fur locks, animal eyes, ears, horns, claws and teeth, feathers, scales and exoskeletons.

Reference points (animal anatomy for artists, stylised-creature workflows):

* Build the silhouette first, as forms: the ribcage is deep and narrow, keel-shaped, reaching
  down to the elbows; behind it the belly *tucks up* to a slim waist before the haunches; the
  back rises at the withers (the tops of the shoulder blades) and at the croup.  The bodies are
  sculpted from overlapping masses in clay (art/lib/clay.py) so they read as one skin.
* Digitigrade animals walk on their toes.  In the hind leg the *stifle* (knee) points forward and
  the *hock* (heel) backwards and high; in the front leg the elbow sits behind, at the bottom of
  the chest, and the wrist low.  Shoulders, triceps, thighs and gaskins carry the muscle; the
  cannons are slender.  Paws: four toes in an arc before the pad, hooked claws on the toes.
* Canine heads: a domed skull, a "stop" in front of the eyes, a long wedge muzzle with a nose pad
  and a separate lower jaw.  Feline heads: round skull, short muzzle, whisker pads, a small chin.
* Stylised fur is a few larger sculpted clumps that belong to the silhouette (ruffs, cheeks,
  manes, elbows, tail tips) - ``lock`` and shingled displacement of the clay - never a pelt of
  tiny cards.
* Markings are authored in the grey values (countershading, stripes that follow the form, darker
  points, pale muzzles) so the game's tint recolours an animal that still reads as itself.

The quadruped helpers (``clay_torso``, ``clay_foreleg``, ``clay_hindleg``, ``clay_tail``) read a
``creature.quad_skel`` layout and weight to a ``creature.quad_rig2`` rig.  Everything is
greyscale with tint weight 1 unless a colour is passed, so the game can recolour it.
"""

import math
import random

from mathutils import Matrix

from kit import b2g, g2b
from kit import CRYSTAL, FOLIAGE, HAIR, MAT_GLOW, MAT_PLAIN, METAL, SCALE, SKIN, STONE, WOOD, V, darken, lighten, mix, rgb
from sculpt import blob3, catmull, fbm3, loft, morph_sphere, section, smooth

GREY = (0.82, 0.82, 0.82)


def grey(v):
    return (v, v, v)


# ---------------------------------------------------------------- heads
class HeadFrame:
    """A local frame for a head: origin at the skull centre, +f forward along the muzzle."""

    def __init__(self, centre, fwd, up=V(0, 1, 0)):
        self.c = V(centre)
        self.f = V(fwd).normalized()
        self.r = self.f.cross(V(up)).normalized() * -1.0     # +X side (the animal's left)
        self.u = self.r.cross(self.f).normalized() * -1.0
        if self.u.y < 0:
            self.u = -self.u
        self.M = Matrix((self.r, self.u, self.f)).transposed()

    def at(self, x, y, z):
        return self.c + self.M @ V(x, y, z)


# ---------------------------------------------------------------- feathers, scales, exoskeletons
def feather(b, root, tip, width, col, col_tip=None, side=None, bone=None, tint=0.0, barbs=True, curl=0.12, mat=0):
    """A contour or flight feather: a vane with a notched edge and a pale rachis."""
    root = V(root)
    tip = V(tip)
    d = tip - root
    if side is None:
        side = d.cross(V(0, 1, 0)).normalized()
        if side.length < 0.5:
            side = V(1, 0, 0)
    side = V(side).normalized()
    nrm = d.cross(side).normalized()
    rows = []
    cols = []
    n = 7
    for j in range(n):
        t = j / (n - 1)
        w = width * math.sin(math.pi * min(1.0, t * 1.05 + 0.04)) ** 0.6 * (1.0 - 0.3 * t)
        notch = 0.18 if (barbs and j in (2, 4)) else 0.0
        cen = root + d * t + nrm * (math.sin(math.pi * t) * curl * d.length)
        rows.append([cen - side * w * (1.0 - notch), cen + nrm * w * 0.08, cen + side * w * 0.6])
        cols.append(mix(col, col_tip, t) if col_tip is not None else rgb(col))
    b.sheet(rows, col, cls=HAIR, bone=bone, cols=cols, tint=tint, mat=mat)
    b.tube([root, root + d * 0.5 + nrm * curl * d.length * 0.9, tip], [width * 0.07, width * 0.05, 0.001], lighten(col, 0.4), cls=HAIR, bone=bone, seg=4, tint=tint, mat=mat)


def plate_segments(b, path, radii, col, bone_fn, n=14, col2=None, tint=1.0, ridge=0.0, cls=STONE):
    """An insect / crustacean exoskeleton: overlapping rings that each flare at the back edge, so
    the abdomen or tail reads as segments rather than a smooth tube."""
    path = [V(p) for p in path]
    for i in range(len(path) - 1):
        a, c = path[i], path[i + 1]
        d = (c - a).normalized()
        r0 = radii[i]
        r1 = radii[i + 1]
        rings = []
        for k, t in enumerate((0.0, 0.35, 0.8, 1.05)):
            q = a.lerp(c, min(1.0, t)) + d * max(0.0, t - 1.0) * (c - a).length
            a0 = r0 if isinstance(r0, tuple) else (r0, r0)
            a1 = r1 if isinstance(r1, tuple) else (r1, r1)
            tt = min(1.0, t)
            flare = 1.0 + 0.12 * smooth(0.5, 1.05, t)
            rw = (a0[0] + (a1[0] - a0[0]) * tt) * flare
            rh = (a0[1] + (a1[1] - a0[1]) * tt) * flare

            def prof(ang, rw=rw, rh=rh):
                base = 1.0 / math.sqrt((math.cos(ang) / rh) ** 2 + (math.sin(ang) / rw) ** 2)
                return base * (1.0 + ridge * max(0.0, math.cos(ang)) ** 8)

            rings.append(section(q, d, prof, n, up=V(0, 1, 0)))
        cc = [mix(col2 or col, col, 0.4), col, col, darken(col, 0.25)]
        loft(b, rings, col, cls=cls, cols=cc, bone_fn=bone_fn, tint=tint, cap0=True, cap1=True, cap_push=0.3)


def compound_eye(b, c, r, col, bone, facets=True, accent=False):
    """A bulging insect eye with a sheen and a grid of facet glints; with `accent` the eye takes
    the enemy's accent colour (a focal point)."""
    tint = 0.0
    old = b.cur_pal
    if accent:
        col = "e0e0e0"
        tint = 1.0
        b.cur_pal = 1.0
    b.ellipsoid(c, (r, r * 1.1, r), darken(col, 0.3), cls=CRYSTAL, bone=bone, seg=14, rings=10, mat=MAT_PLAIN, col2=darken(col, 0.6), tint=tint)
    b.cur_pal = old
    b.ellipsoid(c + V(0, r * 0.3, r * 0.4), (r * 0.5, r * 0.35, r * 0.4), lighten(col, 0.4), cls=CRYSTAL, bone=bone, seg=8, rings=5, mat=MAT_GLOW)
    if facets:
        for i in range(6):
            a = i / 6 * 2 * math.pi
            b.ball(c + V(math.cos(a) * r * 0.75, math.sin(a) * r * 0.75, r * 0.55), r * 0.12, lighten(col, 0.2), cls=CRYSTAL, bone=bone, seg=5, rings=3, mat=MAT_PLAIN)


def bristles(b, pts, length, col, bone_fn, seed=2, width=0.004):
    """Short stiff hairs on a leg or body (spiders, mammoths' feet, insects)."""
    rnd = random.Random(seed)
    for p in pts:
        p = V(p)
        d = V(rnd.uniform(-1, 1), rnd.uniform(-0.2, 1), rnd.uniform(-1, 1)).normalized()
        b.tube([p, p + d * length], [width, width * 0.2], col, cls=HAIR, bone=bone_fn(p), seg=4)


# ---------------------------------------------------------------- bones (skeletal parts for undead)
def skull(b, c, k, bone, col="e8e0cc", eye_glow=None, jaw_bone=None, fwd=V(0, 0, 1)):
    """A skull: cranium, cheekbones, deep eye sockets (with an optional glow), nasal cavity and a
    toothed jaw.  `k` is the scale (1.0 is about a human skull)."""
    hf = HeadFrame(c, fwd)
    bone_col = rgb(col)

    def shape(d):
        p = V(d.x * 0.075, d.y * 0.085, d.z * 0.095) * k
        q = p.copy()
        off = 0.0
        for s in (1, -1):
            off -= 0.02 * k * blob3(q, (0.03 * s * k, 0.0, 0.085 * k), (0.022 * k, 0.02 * k, 0.03 * k))   # sockets
            off += 0.008 * k * blob3(q, (0.055 * s * k, -0.03 * k, 0.06 * k), (0.02 * k, 0.015 * k, 0.03 * k))  # cheekbones
        off -= 0.012 * k * blob3(q, (0.0, -0.035 * k, 0.09 * k), (0.012 * k, 0.015 * k, 0.03 * k))       # nasal cavity
        # the face narrows to the upper jaw
        if d.y < -0.2:
            p.x *= 1.0 - 0.3 * smooth(-0.2, -1.0, d.y)
        return p + p.normalized() * off

    morph_sphere(b, hf.c, shape, lambda p, d: mix(bone_col, darken(bone_col, 0.35), smooth(0.4, -0.8, d.y) * 0.4 + max(0.0, -d.z) * 0.2), cls=STONE, bone=bone, seg=22, rings=16, rot=hf.M)
    for s in (1, -1):
        b.ellipsoid(hf.at(0.03 * s * k, 0.0, 0.07 * k), (0.018 * k, 0.017 * k, 0.012 * k), "120a10", cls=SKIN, bone=bone, seg=10, rings=6, mat=MAT_PLAIN)
        if eye_glow == "accent":
            # the eye-lights burn in the enemy's accent colour
            old = b.cur_pal
            b.cur_pal = 1.0
            b.ellipsoid(hf.at(0.03 * s * k, 0.0, 0.078 * k), (0.008 * k, 0.007 * k, 0.004 * k), "f0f0f0", cls=CRYSTAL, bone=bone, seg=8, rings=5, mat=MAT_GLOW, tint=1.0)
            b.cur_pal = old
        elif eye_glow is not None:
            b.ellipsoid(hf.at(0.03 * s * k, 0.0, 0.078 * k), (0.008 * k, 0.007 * k, 0.004 * k), eye_glow, cls=CRYSTAL, bone=bone, seg=8, rings=5, mat=MAT_GLOW)
    b.ellipsoid(hf.at(0, -0.036 * k, 0.085 * k), (0.008 * k, 0.012 * k, 0.006 * k), "120a10", cls=SKIN, bone=bone, seg=8, rings=4, mat=MAT_PLAIN)
    jb = jaw_bone or bone
    jaw = [hf.at(0.05 * s * k, -0.055 * k, 0.0) for s in (1, -1)]
    b.tube([jaw[0], hf.at(0.035 * k, -0.085 * k, 0.05 * k), hf.at(0, -0.09 * k, 0.075 * k), hf.at(-0.035 * k, -0.085 * k, 0.05 * k), jaw[1]], [0.01 * k, 0.012 * k, 0.014 * k, 0.012 * k, 0.01 * k], bone_col, cls=STONE, bone=jb, seg=8)
    for i in range(8):
        u = (i / 7 - 0.5) * 2
        for row, (yy, bb) in enumerate(((-0.06, bone), (-0.075, jb))):
            p = hf.at(u * 0.03 * k, yy * k, (0.082 - abs(u) * 0.018) * k)
            b.ellipsoid(p, (0.0045 * k, 0.007 * k, 0.004 * k), lighten(bone_col, 0.1), cls=STONE, bone=bb, seg=6, rings=4)


def bony_hand(b, wrist, fwd, k, bone, col="e8e0cc", spread=1.0, curl=0.5, side=1):
    """A skeletal hand reaching forward: carpal knot, metacarpals, three jointed phalanges per
    finger with knuckle balls, and a thumb."""
    wrist = V(wrist)
    f = V(fwd).normalized()
    sv = f.cross(V(0, 1, 0)).normalized() * side
    dn = sv.cross(f).normalized()
    if dn.y > 0:
        dn = -dn
    col = rgb(col)
    b.ellipsoid(wrist + f * 0.02 * k, (0.03 * k, 0.015 * k, 0.025 * k), col, cls=STONE, bone=bone, seg=8, rings=5)
    for i in range(4):
        u = (i / 3 - 0.5) * 2
        base = wrist + f * 0.03 * k + sv * u * 0.02 * k
        knuck = base + f * 0.05 * k + sv * u * 0.012 * k * spread
        b.tube([base, knuck], [0.005 * k, 0.006 * k], col, cls=STONE, bone=bone, seg=5)
        b.ball(knuck, 0.008 * k, col, cls=STONE, bone=bone, seg=6, rings=4)
        p = knuck
        d = f + sv * u * 0.15 * spread
        for j, ln in enumerate((0.035, 0.025, 0.02)):
            d = (d + dn * curl * 0.5).normalized()
            q = p + d * ln * k
            b.tube([p, q], [0.0055 * k, 0.0045 * k], col, cls=STONE, bone=bone, seg=5)
            b.ball(q, 0.0055 * k, col, cls=STONE, bone=bone, seg=6, rings=4)
            p = q
        b.cone(p + d * 0.008 * k, 0.004 * k, 0.016 * k, darken(col, 0.3), cls=STONE, bone=bone, seg=5, rot=(math.atan2(-d.y, math.hypot(d.x, d.z)) + math.pi / 2, math.atan2(d.x, d.z), 0))
    tb = wrist + f * 0.02 * k - sv * 0.03 * k
    tq = [tb, tb + (f * 0.4 - sv * 0.6 + dn * 0.3).normalized() * 0.04 * k, tb + (f * 0.9 - sv * 0.5 + dn * 0.5).normalized() * 0.07 * k]
    b.tube(tq, [0.006 * k, 0.005 * k, 0.003 * k], col, cls=STONE, bone=bone, seg=5)


def chain(b, start, step, n, bone, col="5a5a68", r=0.03):
    """Interlocking oval links, each turned a quarter from the last."""
    start = V(start)
    step = V(step)
    d = step.normalized()
    for k in range(n):
        c = start + step * k
        pts = []
        side = d.cross(V(0, 1, 0))
        side = side.normalized() if side.length > 1e-4 else V(1, 0, 0)
        if k % 2:
            side = side.cross(d).normalized()
        for i in range(13):
            a = i / 12 * 2 * math.pi
            pts.append(c + d * math.cos(a) * r * 1.3 + side * math.sin(a) * r * 0.8)
        b.tube(pts, [r * 0.28] * 13, col, cls=METAL, bone=bone, seg=6, cap0=False, cap1=False)


# ---------------------------------------------------------------- stone and crystal bodies
def hewn_stone(b, c, size, bone, seed=1, shade=0.8, e=0.32, rot=(0, 0, 0), tint=0.55, moss=0.0, crack_glow=None, seg=20, rings=14):
    """A chiselled block: a rounded box (superellipsoid) whose faces are chipped and dented by
    noise, with dark crack veins in the colour, lighter worn edges and optional moss on top.
    `crack_glow` paints the deepest cracks in a glow colour instead (lava, runes)."""
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    R = Matrix.Rotation(rot[1], 3, "Y") @ Matrix.Rotation(rot[0], 3, "X") @ Matrix.Rotation(rot[2], 3, "Z")

    def sp(w, m):
        return math.copysign(abs(w) ** m, w)

    # chisel planes: flat cuts across corners and edges, different for every block
    rnd = random.Random(seed * 31 + 7)
    planes = []
    for _ in range(9):
        nv = V(rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))
        if nv.length < 0.2:
            continue
        nv.normalize()
        ext = abs(nv.x) * hx + abs(nv.y) * hy + abs(nv.z) * hz
        planes.append((nv, ext * rnd.uniform(0.62, 0.8)))

    def shape(d):
        th = math.asin(max(-1.0, min(1.0, d.y)))
        ph = math.atan2(d.z, d.x)
        x = sp(math.cos(th), e) * sp(math.cos(ph), e)
        z = sp(math.cos(th), e) * sp(math.sin(ph), e)
        y = sp(math.sin(th), e)
        p = V(x * hx, y * hy, z * hz)
        for nv, off in planes:
            dist = p.dot(nv)
            if dist > off:
                p = p * (off / dist)
        q = (p.x * 7 + seed, p.y * 7, p.z * 7)
        n = fbm3(q, 3, seed)
        chip = smooth(0.6, 0.7, fbm3((p.x * 3 + seed, p.y * 3, p.z * 3), 2, seed + 3))
        k = 1.0 + 0.06 * (n - 0.5) - 0.1 * chip
        return R @ (p * k)

    def col(p, d):
        q = (p.x * 9 + seed, p.y * 9, p.z * 9)
        v = shade * (0.85 + 0.3 * fbm3(q, 3, seed + 7))
        crack = 1.0 - smooth(0.0, 0.025, abs(fbm3((p.x * 4 + seed, p.y * 4, p.z * 4), 3, seed + 11) - 0.5))
        c = (v * (1 - 0.55 * crack),) * 3
        if crack_glow is not None and crack > 0.6:
            return mix(c, crack_glow, (crack - 0.6) * 2.5)
        if moss > 0.0 and d.y > 0.5:
            return mix(c, (0.35, 0.55, 0.28), moss * smooth(0.5, 0.9, d.y) * smooth(0.4, 0.6, fbm3(q, 2, seed + 2)))
        return c

    return morph_sphere(b, c, shape, col, cls=STONE, bone=bone, seg=seg, rings=rings, tint_fn=lambda p, d: tint)


def glow_seam(b, pts, r, col, bone, tint=1.0):
    """A thin glowing seam (lava crack, rune channel) along a polyline, jittered so it zigzags."""
    pts = [V(p) for p in pts]
    out = []
    for i in range(len(pts) - 1):
        a, c = pts[i], pts[i + 1]
        for k in range(3):
            t = k / 3
            q = a.lerp(c, t)
            if 0 < i + k:
                q = q + V(math.sin(i * 7.1 + k * 3.3) * r * 1.5, math.cos(i * 5.3 + k) * r * 1.5, 0)
            out.append(q)
    out.append(pts[-1])
    b.tube(out, [r] * len(out), col, cls=CRYSTAL, bone=bone, seg=5, mat=MAT_GLOW, tint=tint)


# ---------------------------------------------------------------- plants
def bark_limb(b, pts, radii, col, bone_fn, seed=1, ridges=9, twist=1.2, tint=1.0, n=16):
    """A woody limb: a loft whose surface is ploughed into fibrous ridges that twist around it,
    with dark fissures between them and lighter, worn ridge tops."""
    pts = [V(p) for p in pts]
    m = len(pts)
    rings = []
    along = 0.0
    alongs = []
    for i in range(m):
        if i:
            along += (pts[i] - pts[i - 1]).length
        alongs.append(along)
        d = (pts[min(m - 1, i + 1)] - pts[max(0, i - 1)]).normalized()
        rr = radii[i]
        tw = twist * along

        def prof(a, rr=rr, tw=tw, i=i):
            ridge = 0.5 + 0.5 * math.sin(a * ridges + tw)
            k = fbm3((math.cos(a) * 2 + seed, i * 0.7, math.sin(a) * 2), 2, seed)
            return rr * (1.0 + 0.09 * ridge + 0.06 * (k - 0.5))

        rings.append(section(pts[i], d, prof, n, up=V(0, 0, 1)))

    def colf(p, j, i):
        a = 2 * math.pi * i / n
        ridge = 0.5 + 0.5 * math.sin(a * ridges + twist * alongs[j])
        v = (0.45 + 0.35 * ridge) * (0.9 + 0.2 * fbm3((p.x * 8, p.y * 8, p.z * 8), 2, seed + 4))
        return mix(col, darken(col, 0.6), 1.0 - v)

    return loft(b, rings, col, cls=WOOD, col_fn=colf, bone_fn=bone_fn, tint=tint, cap0=True, cap1=True, cap_push=0.4)


def veined_leaf(b, root, tip, width, col, bone, side=None, tint=1.0, serrate=0.0, curl=0.15, col_tip=None, vein_col=None):
    """A broad leaf with a pale midrib and paired side veins, optionally serrated."""
    root = V(root)
    tip = V(tip)
    d = tip - root
    if side is None:
        side = d.cross(V(0, 1, 0))
        side = side.normalized() if side.length > 1e-4 else V(1, 0, 0)
    side = V(side).normalized()
    nrm = d.cross(side).normalized()
    rows = []
    cols = []
    n = 8
    for j in range(n):
        t = j / (n - 1)
        w = width * math.sin(math.pi * min(1.0, t * 1.08 + 0.03)) * (1.0 - 0.35 * t)
        if serrate > 0.0 and 0 < j < n - 1:
            w *= 1.0 + serrate * (1 if j % 2 else -1)
        cen = root + d * t + nrm * (math.sin(math.pi * t) * curl * d.length)
        rows.append([cen - side * w + nrm * w * 0.15, cen, cen + side * w + nrm * w * 0.15])
        cols.append(mix(col, col_tip, t) if col_tip is not None else rgb(col))
    b.sheet(rows, col, cls=FOLIAGE, bone=bone, cols=cols, tint=tint)
    vc = vein_col or lighten(col, 0.35)
    b.tube([root, root + d * 0.5 + nrm * curl * d.length * 0.9, tip], [width * 0.06, width * 0.04, 0.001], vc, cls=FOLIAGE, bone=bone, seg=4, tint=tint, mat=MAT_PLAIN)
    for k in range(1, 4):
        t = k / 4
        c = root + d * t + nrm * (math.sin(math.pi * t) * curl * d.length + 0.003)
        w = width * math.sin(math.pi * t) * (1.0 - 0.35 * t) * 0.75
        for sgn in (-1, 1):
            b.tube([c, c + side * w * sgn + d * 0.12], [width * 0.025, 0.0008], vc, cls=FOLIAGE, bone=bone, seg=3, tint=tint, mat=MAT_PLAIN)


def thorns(b, pts, bone_fn, size=0.04, col="d8c8a0", every=1, seed=3):
    rnd = random.Random(seed)
    pts = [V(p) for p in pts]
    for i in range(1, len(pts) - 1, every):
        d = (pts[i + 1] - pts[i - 1]).normalized()
        side = d.cross(V(rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1))).normalized()
        base = pts[i] + side * size * 0.6
        tip = base + side * size + d * size * 0.6
        b.tube([base, tip], [size * 0.25, 0.001], col, cls=STONE, bone=bone_fn(pts[i]), seg=5)


# ================================================================ sculpted creatures
# The helpers below build animals as sculpted forms (art/lib/clay.py) with a few broad fur locks,
# animal (not anime) eyes set under lids, cupped ears, keratin horns, claws and teeth that taper
# and darken toward the base, and markings authored in the grey values so a recolour still reads
# as the animal: countershading, stripes that follow the form, rosettes, darker points.

def frame_m(fwd, up=(0.0, 1.0, 0.0)):
    """Columns (side, up, fwd): side is the creature's left when fwd is +Z."""
    f = V(fwd).normalized()
    s = f.cross(V(up))
    if s.length < 1e-6:
        s = f.cross(V(1, 0, 0))
    s = -s.normalized()
    u = f.cross(s).normalized()
    if u.dot(V(up)) < 0:
        u = -u
    return Matrix((s, u, f)).transposed()


def sclerite(b, a, c, w, h, bone, col=0.85, keels=0, phase=0.0, taper=0.0, tint=1.0, up=(0.0, 1.0, 0.0), seg=18, rings=10, blunt=0.6,
             cls=SCALE, belly=0.0, mat=0, joint=0.35, ridge=0.12, flare=0.0):
    """One plate of an exoskeleton between joints a and c (arthropod body segments, leg segments,
    a crab's carapace or a mantis's thorax): a barrel `w` wide and `h` deep with blunt ends
    (`blunt` near 0 makes it slab-like), optional keels (carinae) running along it (`keels`
    ridges round it, rotated by `phase`; 0 is the back), paler on the back and dark where it
    meets the next plate.  `belly` flattens the underside, `taper` narrows it towards c, `flare`
    widens its rear rim.  A deformed sphere turned onto the a -> c axis with `up` as its back."""
    a, c = V(a), V(c)
    L = (c - a).length
    M = frame_m(c - a, up)

    def cross(d):
        u = d.y
        s = math.sqrt(max(0.0, 1.0 - u * u))
        if s < 1e-6:
            return u, 0.0, 1.0, 0.0
        return u, d.x / s, d.z / s, s

    def keel(cx, cy):
        if not keels:
            return 0.0
        return max(0.0, math.cos((math.atan2(cx, cy) - phase) * keels)) ** 10

    def shape(d):
        u, cx, cy, s = cross(d)
        rad = (s ** blunt) * (1.0 + ridge * keel(cx, cy)) * (1.0 - taper * (0.5 + 0.5 * u)) * (1.0 + flare * smooth(-0.3, -0.9, u))
        yy = cy * h * rad
        if belly and cy < 0.0:
            yy *= 1.0 - belly
        return V(cx * w * rad, yy, math.copysign(abs(u) ** 0.75, u) * L * 0.5)

    def colf(lp, d):
        u, cx, cy, s = cross(d)
        v = col * (0.78 + 0.22 * smooth(-0.6, 0.8, cy)) + 0.08 * keel(cx, cy)
        v *= 1.0 - joint * smooth(0.72, 0.97, abs(u))
        return (v, v, v)

    return morph_sphere(b, (a + c) * 0.5, shape, colf, cls=cls, bone=bone, seg=seg, rings=rings, tint_fn=lambda lp, d: tint, rot=M, mat=mat)


def euler_of(M):
    from creature import euler_yxz
    return euler_yxz(M)


def lock(b, root, groom, nrm, length, width, col, col_tip=None, bone=None, lift=0.2, rise=0.12, thick=0.4, tint=1.0,
         cls=HAIR, mat=0, steps=6, seg=8, bury=0.35, bend=0.0, twist=0.0, droop=0.0, cols=None):
    """A sculpted clump of fur: a curved, tapered, flattened lock growing from `root` (buried a
    little) along the `groom` direction, its flat side facing `nrm` (the skin normal), arching
    away from the skin by `lift` and ending `rise` x length off it, pointed at the tip.  Broad clumps like this belong to the
    silhouette (ruffs, cheeks, manes, elbows, tail tips) instead of a pelt of tiny cards."""
    root = V(root)
    d = V(groom).normalized()
    n = V(nrm)
    n = n - d * n.dot(d)
    if n.length < 1e-6:
        n = d.orthogonal()
    n.normalize()
    sv = d.cross(n).normalized()
    start = root - n * (width * bury) - d * (width * bury)
    pts = []
    for j in range(steps + 1):
        t = j / steps
        off = n * (length * (lift * math.sin(math.pi * t) * 0.5 + rise * t)) + sv * (length * bend * t * t) + V(0, -1, 0) * (length * droop * t * t)
        pts.append(start + d * (length * t) + off)
    rings = []
    rcols = []
    for j, c in enumerate(pts):
        t = j / steps
        tan = (pts[min(steps, j + 1)] - pts[max(0, j - 1)]).normalized()
        w = width * (1.0 - t) ** 0.8 * (0.8 + 0.8 * t * (1.0 - t)) + 0.0006
        h = max(0.0005, w * thick)
        up = n - tan * n.dot(tan)
        if twist:
            up = Matrix.Rotation(twist * t, 3, tan) @ up
        rings.append(section(c, tan, prof_ellipse_fn(w, h), seg, up=up))
        if cols is not None:
            rcols.append(cols[min(len(cols) - 1, j)])
        else:
            rcols.append(mix(col, col_tip, t ** 1.2) if col_tip is not None else rgb(col))
    return loft(b, rings, col, cls=cls, cols=rcols, bone=bone, tint=tint, mat=mat, cap0=True, cap1=True, cap_push=0.25)


def prof_ellipse_fn(rw, rh):
    def f(a):
        c, s = math.cos(a), math.sin(a)
        return 1.0 / math.sqrt((c / rh) ** 2 + (s / rw) ** 2)
    return f


def tuft(b, root, groom, nrm, length, width, n, col, col_tip=None, bone=None, spread=0.5, seed=1, **kw):
    """A fan of `n` locks from one root region (cheek ruffs, elbow tufts, tail tips)."""
    rnd = random.Random(seed)
    root = V(root)
    nv = V(nrm).normalized()
    g = V(groom).normalized()
    sv = g.cross(nv).normalized()
    out = []
    for k in range(n):
        u = (k / max(1, n - 1) - 0.5) * 2.0 if n > 1 else 0.0
        dd = (g + sv * (u * spread) + V(rnd.uniform(-0.1, 0.1), rnd.uniform(-0.1, 0.1), rnd.uniform(-0.1, 0.1))).normalized()
        r0 = root + sv * (u * width * 0.9)
        ln = length * (1.0 - 0.25 * abs(u)) * rnd.uniform(0.85, 1.1)
        out += lock(b, r0, dd, nv, ln, width * rnd.uniform(0.85, 1.1), col, col_tip, bone=bone, **kw)
    return out


def animal_eye(b, c, fwd, r, iris, bone, pupil="round", up=(0.0, 1.0, 0.0), almond=0.72, lid="1a1210", slant=0.0, side=1,
               glow=False, mat=MAT_PLAIN, lid_w=0.13, tear=None, ring=None, accent=True):
    """An animal eye set under its lids: a dark-rimmed eyeball almost filled by the iris (lighter
    at the bottom, shadowed under the upper lid), a round, slit or bar pupil, one small catchlight
    and an almond rim of dark lid skin - no anime sclera or brows.  `tear` = (length, direction)
    draws a feline tear line from the inner corner.  With `accent` (the default) the iris is
    painted in greys on the palette's accent slot, so each enemy looks out with its element's
    colour (the eyes are a creature's first focal point); `iris` then only matters untinted."""
    c = V(c)
    M = frame_m(fwd, up) @ Matrix.Rotation(slant * side, 3, "Z")
    rot = euler_of(M)
    old_pal = b.cur_pal
    tint = 0.0
    if accent:
        iris = "e8e8e8"
        tint = 1.0
        b.cur_pal = 1.0
    b.ellipsoid(c, (r, r * almond, r * 0.6), darken(iris, 0.75), cls=CRYSTAL, bone=bone, rot=rot, seg=16, rings=10, mat=mat, tint=tint)
    ic = c + M @ V(0, 0, r * 0.28)
    b.ellipsoid(ic, (r * 0.88, r * almond * 0.9, r * 0.36), darken(iris, 0.3), cls=CRYSTAL, bone=bone, rot=rot, seg=16, rings=10,
                mat=MAT_GLOW if glow else mat, col2=lighten(iris, 0.3), tint=tint)
    b.cur_pal = old_pal
    pc = c + M @ V(0, 0, r * 0.46)
    if pupil == "slit":
        pr = (r * 0.11, r * almond * 0.82, r * 0.2)
    elif pupil == "bar":
        pr = (r * 0.5, r * 0.13, r * 0.2)
    else:
        pr = (r * 0.38, min(r * 0.38, r * almond * 0.7), r * 0.2)
    b.ellipsoid(pc, pr, "0a0608", cls=SKIN, bone=bone, rot=rot, seg=12, rings=6, mat=mat)
    b.ellipsoid(c + M @ V(-r * 0.28 * side, r * almond * 0.38, r * 0.56), (r * 0.13, r * 0.11, r * 0.06), "ffffff", cls=CRYSTAL, bone=bone, rot=rot, seg=8, rings=5, mat=MAT_GLOW)
    # the lid rim: heavier along the top
    pts = []
    radii = []
    for i in range(17):
        a = i / 16 * 2 * math.pi
        x = math.cos(a)
        y = math.sin(a)
        pts.append(c + M @ V(x * r * 1.04, y * r * almond * 1.08, r * 0.3 * (1.0 - 0.35 * x * x)))
        radii.append(r * lid_w * (1.25 if y > 0 else 0.8))
    b.tube(pts, radii, lid, cls=SKIN, bone=bone, seg=6, cap0=False, cap1=False, mat=MAT_PLAIN)
    if ring is not None:
        b.tube([c + M @ V(math.cos(a) * r * 1.25, math.sin(a) * r * almond * 1.3, r * 0.15) for a in [i / 16 * 2 * math.pi for i in range(17)]],
               [r * 0.12] * 17, ring, cls=SKIN, bone=bone, seg=5, cap0=False, cap1=False, mat=MAT_PLAIN)
    if tear is not None:
        ln, dv = tear
        p0 = c + M @ V(r * 0.95 * side * -1.0, -r * almond * 0.3, r * 0.25)
        b.tube([p0, p0 + V(dv) * (ln * 0.5), p0 + V(dv) * ln], [r * 0.1, r * 0.08, r * 0.03], lid, cls=SKIN, bone=bone, seg=5, mat=MAT_PLAIN)
    return M


def ear(b, base, fwd, h, w, d, col_back, col_in, bone, up=(0.0, 1.0, 0.0), point=0.7, cup=0.55, tint=1.0, tint_in=0.35, tip_col=None,
        tip=0.25, rim_col=None, seg=14, rings=12, lean=0.0, side=1, spot=None):
    """A cupped ear standing on `base`: a lens-shaped shell narrowing to a rounded or pointed tip
    (`point`), its opening facing `fwd` and hollowed by `cup`, dark on the back (optionally with a
    pale spot), pale inside, darker at the tip."""
    M = frame_m(fwd, up) @ Matrix.Rotation(lean * side, 3, "Z")

    def shape(dd):
        v = (dd.y + 1.0) * 0.5
        px = dd.x * w * 0.5 * (1.0 - point * v ** 1.6)
        py = v * h
        pz = dd.z * d * 0.5 * (1.0 - 0.5 * v)
        if dd.z > 0.0:
            pz -= cup * d * (1.0 - dd.x * dd.x) * math.sin(math.pi * min(1.0, v * 1.1)) * dd.z
        return M @ V(px, py, pz)

    def col(p, dd):
        v = (dd.y + 1.0) * 0.5
        inner = smooth(0.15, 0.55, dd.z) * (1.0 - smooth(0.65, 0.95, abs(dd.x))) * smooth(0.05, 0.25, v)
        cc = mix(col_back, col_in, inner)
        if rim_col is not None and dd.z > -0.2:
            cc = mix(cc, rim_col, smooth(0.75, 0.95, abs(dd.x)) * (1.0 - inner))
        if spot is not None and dd.z < -0.3:
            cc = mix(cc, spot, smooth(0.45, 0.3, math.hypot(dd.x * 1.1, v - 0.45)))
        if tip_col is not None:
            cc = mix(cc, tip_col, smooth(1.0 - tip - 0.05, 1.0 - tip + 0.05, v))
        return cc

    def tf(p, dd):
        inner = smooth(0.15, 0.55, dd.z) * (1.0 - smooth(0.65, 0.95, abs(dd.x)))
        return tint * (1.0 - inner) + tint_in * inner

    return morph_sphere(b, V(base), shape, col, cls=HAIR, bone=bone, seg=seg, rings=rings, tint_fn=tf)


def horn(b, pts, r0, col0, col1, bone, r1=0.002, rings=0, ring_k=0.25, cls=STONE, seg=10, per=4, mat=0, tint=0.0, flat=1.0, up=None, power=1.0, ridge=0.0):
    """A keratin horn, tusk or antler tine through control points: tapering from r0, its colour
    running from the base (col0) to the tip (col1), with optional growth rings."""
    cp = catmull(pts, per)
    n = len(cp)
    radii = []
    cols = []
    for i in range(n):
        t = i / (n - 1)
        rr = r0 + (r1 - r0) * t ** power
        cc = mix(col0, col1, t ** 0.8)
        if rings:
            k = 0.5 + 0.5 * math.cos(t * rings * 2 * math.pi)
            rr *= 1.0 + ridge * k * (1.0 - t)
            cc = darken(cc, ring_k * k * (1.0 - t * 0.7))
        radii.append((rr, rr * flat))
        cols.append(cc)
    return b.tube(cp, radii, col0, cls=cls, bone=bone, seg=seg, cols=cols, up=up, mat=mat, tint=tint)


def claw(b, base, fwd, length, width, bone, col0="3a302a", col1="efe6d4", down=(0.0, -1.0, 0.0), hook=0.7, mat=MAT_PLAIN, cls=STONE, seg=6):
    """A hooked claw, flattened side to side, dark at the root and pale at the tip."""
    f = V(fwd).normalized()
    dn = V(down)
    dn = (dn - f * dn.dot(f))
    dn = dn.normalized() if dn.length > 1e-6 else V(0, -1, 0)
    base = V(base)
    pts = [base - f * width * 0.4, base + f * length * 0.45 - dn * length * 0.05, base + f * length * 0.85 + dn * length * 0.25 * hook,
           base + f * length * 1.0 + dn * length * 0.7 * hook]
    radii = [(width * 0.5, width), (width * 0.42, width * 0.8), (width * 0.24, width * 0.45), (0.0008, 0.0008)]
    cols = [col0, mix(col0, col1, 0.5), col1, col1]
    return b.tube(pts, radii, col0, cls=cls, bone=bone, seg=seg, cols=cols, up=tuple(dn), mat=mat, cap0=True, cap1=True)


def fang(b, root, down, length, width, bone, back=(0.0, 0.0, -1.0), curve=0.25, col0="e0d0a8", col1="fbf6e8", mat=MAT_PLAIN, seg=6):
    """A curved canine tooth: ivory, a touch yellow at the gum, curving back toward its tip."""
    dv = V(down).normalized()
    bk = V(back)
    bk = (bk - dv * bk.dot(dv))
    bk = bk.normalized() if bk.length > 1e-6 else V(0, 0, -1)
    r0 = V(root)
    pts = [r0 - dv * width * 0.5, r0 + dv * length * 0.5 + bk * length * curve * 0.2, r0 + dv * length + bk * length * curve]
    return b.tube(pts, [width, width * 0.7, 0.0008], col0, cls=STONE, bone=bone, seg=seg, cols=[col0, mix(col0, col1, 0.6), col1], mat=mat)


def nose_pad(b, c, fwd, w, h, col, bone, kind="cat", up=(0.0, 1.0, 0.0), nostril="0c0608", mat=0):
    """Nose leather: a cat's inverted triangle with comma nostrils or a dog's rounded pad with a
    central groove."""
    M = frame_m(fwd, up)

    def shape(dd):
        x, y, z = dd.x, dd.y, dd.z
        if kind == "cat":
            px = x * w * 0.5 * (1.0 - 0.55 * smooth(0.2, -1.0, y))
            py = y * h * 0.5
        else:
            px = x * w * 0.5
            py = y * h * 0.5 * (1.0 - 0.15 * abs(x))
        pz = z * w * 0.3
        if z > 0 and kind != "cat":
            pz -= 0.06 * w * math.exp(-(x * 8.0) ** 2) * (1.0 - y)
        return M @ V(px, py, pz)

    morph_sphere(b, V(c), shape, lambda p, dd: mix(col, lighten(col, 0.25), smooth(0.3, 0.9, dd.y)), cls=SKIN, bone=bone, seg=14, rings=10, mat=mat)
    for s in (1, -1):
        q = V(c) + M @ V(s * w * 0.22, -h * 0.08, w * 0.27)
        b.ellipsoid(q, (w * 0.1, h * 0.12, w * 0.05), nostril, cls=SKIN, bone=bone, rot=euler_of(M @ Matrix.Rotation(0.5 * s, 3, "Z")), seg=8, rings=5, mat=MAT_PLAIN)


def hoof(b, c, fwd, r, h, col, bone, cloven=True, col_top=None, mat=0):
    """A hoof: a truncated cone of horn, glossy and dark, split in two digits when cloven."""
    f = V(fwd).normalized()
    side = f.cross(V(0, 1, 0)).normalized()
    parts = ((-1, 0.5), (1, 0.5)) if cloven else ((0, 1.0),)
    for s, wk in parts:
        cc = V(c) + side * (s * r * 0.5)
        rr = r * wk * (1.12 if cloven else 1.0)

        def shape(dd, rr=rr, s=s):
            y = (dd.y + 1.0) * 0.5
            k = 1.0 - 0.28 * y
            px = dd.x * rr * k
            pz = dd.z * rr * 1.15 * k + rr * 0.25 * y * (1.0 if dd.z > 0 else 0.3)
            if cloven and dd.x * s < 0:
                px *= 0.55
            return V(px, y * h, pz)

        morph_sphere(b, cc, shape, lambda p, dd: mix(col, col_top or lighten(col, 0.12), (dd.y + 1.0) * 0.5), cls=STONE, bone=bone, seg=14, rings=8, mat=mat)


# ---------------------------------------------------------------- clay quadrupeds
# Sculpting a four-legged body on a creature.QuadSkel: the torso as overlapping masses (haunch,
# loin, belly, a deep keel of ribs, the brisket and the withers), a neck, and legs with their
# muscle bellies - shoulder blade and triceps, the forearm thick at the elbow; the thigh and the
# gaskin - tapering to slender cannons and ending in paws, hooves or flat feet.  Sizes are given
# relative to the height of the back H so one set of numbers fits a fox or a mammoth.

def _lw(names, zone=0.18):
    from clay import limb_weights
    return limb_weights(names, zone)


def clay_torso(c, sk, w=0.25, d=0.275, haunch=(0.22, 0.2, 0.21), tuck=0.0, belly=0.0, withers=0.1, neck=(0.19, 0.175, 0.15),
               throat=0.14, ribs_z=0.75, chest_y=0.775, loin_y=0.885, neck_pts=None):
    """Torso and neck masses.  w, d: half width and half depth of the ribcage; haunch: radii of the
    hindquarters; tuck lifts the belly (a greyhound's waist), belly lowers it (a heavy animal's
    paunch); all as fractions of H except where noted."""
    H = sk.H
    hz = sk["hip.L"].z
    fz = sk["sh.L"].z
    L = fz - hz
    c.ellipsoid(V(0, 0.85 * H, hz), (haunch[0] * H, haunch[1] * H, haunch[2] * H), bones={"pelvis": 1.0}, tag="body")
    c.ellipsoid(V(0, (loin_y - tuck * 0.3) * H, hz + 0.22 * L), (w * 0.8 * H, (0.16 - tuck * 0.2) * H, 0.24 * L), bones={"loin": 0.7, "pelvis": 0.3}, tag="body")
    c.ellipsoid(V(0, (0.8 + tuck - belly * 0.5) * H, hz + 0.47 * L), (w * 0.85 * H, (d * 0.77 - tuck + belly) * H, 0.24 * L), bones={"body": 0.7, "loin": 0.3}, tag="body")
    c.ellipsoid(V(0, chest_y * H, hz + ribs_z * L), (w * H, d * H, 0.28 * L), bones={"chest": 0.7, "body": 0.3}, tag="body")
    c.ellipsoid(V(0, 0.69 * H, fz - 0.025 * H), (w * 0.8 * H, d * 0.77 * H, 0.16 * L), bones={"chest": 1.0}, tag="body")
    c.ellipsoid(V(0, 0.99 * H, fz - 0.125 * H), (w * 0.7 * H, withers * H, 0.2 * L), bones={"chest": 1.0}, tag="body")
    pts = neck_pts or [V(0, H, fz), sk["neck1"].lerp(sk["neck0"], 0.3), sk["head"] + (sk["neck1"] - sk["head"]) * 0.15]
    c.chain(pts, [neck[0] * H, neck[1] * H, neck[2] * H],
            bones=lambda p, t: {"chest": 1.0 - t, "neck0": t} if t < 1.0 else {"neck0": 2.0 - t, "neck1": t - 1.0}, tag="neck", t0=0.0, t1=2.0)
    if throat:
        c.ellipsoid(pts[0].lerp(pts[1], 0.7) + V(0, -0.075 * H, 0), (throat * 0.8 * H, throat * H, throat * H), bones={"neck0": 0.6, "chest": 0.4}, tag="neck")


def clay_foreleg(c, sk, sd, g=1.0, foot="paw", paw=1.0, toes=4, scap=1.0):
    """A foreleg: the shoulder blade over the ribs, the triceps behind the upper arm, a forearm
    thick at the elbow tapering to the wrist, the metacarpus, and the foot."""
    H = sk.H
    s = 1 if sd == "L" else -1
    sc, sh, el, wr, fb, ft = (sk[k + "." + sd] for k in ("sc", "sh", "el", "wr", "fb", "ft"))
    sb = "shoulder." + sd
    up, lo, mt, tb = "f_up." + sd, "f_lo." + sd, "f_meta." + sd, "f_toe." + sd
    c.ellipsoid(sc.lerp(sh, 0.45) + V(0.044 * H * s, 0, 0), (0.0625 * H * g * scap, 0.19 * H * scap, 0.11 * H * g * scap), rot=(0.35, 0, 0), bones={sb: 0.8, "chest": 0.2}, tag="leg")
    c.ellipsoid(sh.lerp(el, 0.5) + V(0.0, 0.0, -0.05 * H), (0.1 * H * g, 0.16 * H, 0.12 * H * g), rot=(-0.3, 0, 0), bones={up: 0.75, sb: 0.25}, tag="leg")
    if foot == "hoof":
        radii = [0.09 * H * g, 0.08 * H * g, 0.042 * H * g, 0.045 * H * g]
    elif foot == "pillar":
        radii = [0.11 * H * g, 0.1 * H * g, 0.095 * H * g, 0.1 * H * g]
    else:
        radii = [0.094 * H * g, 0.09 * H * g, 0.06 * H * g, 0.0625 * H * g]
    c.chain([sh, el, wr, fb], radii, bones=_lw([up, lo, mt]), tag="fleg", t0=0.0, t1=3.0)
    c.ellipsoid(el.lerp(wr, 0.25) + V(0.015 * H * s, 0.0, 0.025 * H), (0.075 * H * g, 0.125 * H, 0.075 * H * g), rot=(0.15, 0, 0), bones={lo: 1.0}, tag="fleg", t=1.3)
    _foot(c, fb, ft, mt, tb, H, foot, paw, toes, s)


def clay_hindleg(c, sk, sd, g=1.0, foot="paw", paw=1.0, toes=4):
    """A hind leg: the big thigh (biceps femoris and quadriceps), the gaskin behind the shin,
    the long metatarsus from the hock, and the foot."""
    H = sk.H
    s = 1 if sd == "L" else -1
    hip, kn, hk, hb, ht = (sk[k + "." + sd] for k in ("hip", "kn", "hk", "hb", "ht"))
    up, lo, mt, tb = "h_up." + sd, "h_lo." + sd, "h_meta." + sd, "h_toe." + sd
    c.ellipsoid(hip.lerp(kn, 0.4) + V(0.025 * H * s, 0.0, -0.0375 * H), (0.106 * H * g, 0.2 * H, 0.175 * H * g), rot=(-0.3, 0, 0), bones={up: 0.75, "pelvis": 0.25}, tag="leg")
    if foot == "hoof":
        radii = [0.1 * H * g, 0.08 * H * g, 0.042 * H * g, 0.045 * H * g]
    elif foot == "pillar":
        radii = [0.12 * H * g, 0.105 * H * g, 0.095 * H * g, 0.1 * H * g]
    else:
        radii = [0.1 * H * g, 0.0875 * H * g, 0.0525 * H * g, 0.056 * H * g]
    c.chain([hip, kn, hk, hb], radii, bones=_lw([up, lo, mt]), tag="hleg", t0=0.0, t1=3.0)
    c.ellipsoid(kn.lerp(hk, 0.3) + V(0, 0.0125 * H, -0.044 * H), (0.0625 * H * g, 0.1125 * H, 0.069 * H * g), rot=(-0.5, 0, 0), bones={lo: 1.0}, tag="hleg", t=1.3)
    _foot(c, hb, ht, mt, tb, H, foot, paw * 0.92, toes, s)


def _foot(c, fb, ft, mt, tb, H, foot, paw, toes, s):
    if foot == "paw":
        c.ellipsoid(fb.lerp(ft, 0.35) + V(0, 0.015 * H, 0), (0.081 * H * paw, 0.05 * H * paw, 0.0875 * H * paw), bones={tb: 0.6, mt: 0.4}, tag="paw")
        for k in range(toes):
            u = (k / max(1, toes - 1) - 0.5) * 2
            c.ball(fb.lerp(ft, 0.75) + V(u * 0.0475 * H * paw, 0.005 * H, -abs(u) * 0.0225 * H * paw), 0.0325 * H * paw, bones={tb: 1.0}, tag="paw")
    elif foot == "hoof":
        # fetlock and pastern; the hoof itself is horn (see hoof())
        c.ball(fb + V(0, 0.01 * H, 0), 0.05 * H * paw, bones={mt: 0.5, tb: 0.5}, tag="fetlock")
        c.chain([fb, fb.lerp(ft, 0.6)], [0.042 * H * paw, 0.04 * H * paw], bones={tb: 1.0}, tag="fetlock")
    elif foot == "pillar":
        c.ellipsoid(fb + V(0, 0.03 * H, 0.02 * H), (0.12 * H * paw, 0.07 * H * paw, 0.12 * H * paw), bones={tb: 0.5, mt: 0.5}, tag="paw")
    elif foot == "plant":
        c.ellipsoid(fb.lerp(ft, 0.3) + V(0, 0.02 * H, -0.04 * H), (0.06 * H * paw, 0.04 * H * paw, 0.14 * H * paw), bones={mt: 0.6, tb: 0.4}, tag="paw")
        for k in range(toes):
            u = (k / max(1, toes - 1) - 0.5) * 2
            c.ball(fb.lerp(ft, 0.8) + V(u * 0.04 * H * paw, 0.008 * H, -abs(u) * 0.02 * H), 0.025 * H * paw, bones={tb: 1.0}, tag="paw")


def clay_tail(c, sk, radii, tag="tail"):
    tail = sk.tail
    names = ["tail%d" % i for i in range(len(tail) - 1)]
    return c.chain(tail, radii, bones=_lw(names), tag=tag, t0=0.0, t1=len(tail) - 1.0)


def toe_claws(b, sk, sd, length, width, hind=False, toes=4, col0="3a302a", col1="efe6d4", spread=0.0475, paw=1.0):
    H = sk.H
    fb = sk[("hb." if hind else "fb.") + sd]
    ft = sk[("ht." if hind else "ft.") + sd]
    bone = ("h_toe." if hind else "f_toe.") + sd
    for k in range(toes):
        u = (k / max(1, toes - 1) - 0.5) * 2
        base = fb.lerp(ft, 0.95) + V(u * spread * H * paw, 0.02 * H, -abs(u) * 0.02 * H * paw)
        claw(b, base, V(0, -0.25, 1.0), length, width, bone, col0=col0, col1=col1, hook=0.9)


def head_clay(c, hf, K, parts, bone="head"):
    """Add head masses given in the head frame (x side, y up, z along the muzzle) scaled by K:
    parts = [(kind, (x, y, z), radii or r, tag, mirror, neg)]."""
    for kind, pos, rad, tag, mirror, neg in parts:
        for s in ((1, -1) if mirror else (1,)):
            x, y, z = pos
            p = hf.at(x * K * s, y * K, z * K)
            if kind == "ball":
                c.ball(p, rad * K, bones={bone: 1.0}, tag=tag, neg=neg)
            else:
                c.ellipsoid(p, (rad[0] * K, rad[1] * K, rad[2] * K), rot=hf.M, bones={bone: 1.0}, tag=tag, neg=neg)


def surface(b):
    """Ray-cast against everything built so far in Builder b: returns hit(origin, direction) ->
    (point, normal) in Godot space or None.  Used to plant locks, horns and plates exactly on a
    sculpted (clay) surface."""
    from mathutils.bvhtree import BVHTree
    b.bm.normal_update()
    tree = BVHTree.FromBMesh(b.bm)

    def hit(origin, direction, dist=10.0):
        loc, nrm, _, _ = tree.ray_cast(g2b(V(origin)), g2b(V(direction)).normalized(), dist)
        if loc is None:
            return None
        return b2g(loc), b2g(nrm).normalized()

    return hit


class Spline:
    """A smooth curve through control points with rotation-minimising frames, for serpentine
    bodies: ``at(u)`` (u = 0..1 along the arc) returns (point, tangent, up, side)."""

    def __init__(self, pts, per=8, up=(0.0, 1.0, 0.0)):
        cp = catmull(pts, per)
        self.pts = cp
        n = len(cp)
        self.tan = [(cp[min(n - 1, i + 1)] - cp[max(0, i - 1)]).normalized() for i in range(n)]
        self.len = [0.0]
        for i in range(1, n):
            self.len.append(self.len[-1] + (cp[i] - cp[i - 1]).length)
        self.L = self.len[-1]
        ups = []
        u = V(up)
        u = (u - self.tan[0] * u.dot(self.tan[0])).normalized()
        for i in range(n):
            if i:
                q = self.tan[i - 1].rotation_difference(self.tan[i])
                u = (q @ u)
                # lean back towards world up so the belly stays underneath
                wu = V(up) - self.tan[i] * V(up).dot(self.tan[i])
                if wu.length > 1e-4:
                    u = u.lerp(wu.normalized(), 0.35)
                u = (u - self.tan[i] * u.dot(self.tan[i])).normalized()
            ups.append(u)
        self.up = ups
        self.side = [self.tan[i].cross(self.up[i]).normalized() for i in range(n)]

    def _idx(self, u):
        s = max(0.0, min(1.0, u)) * self.L
        lo, hi = 0, len(self.len) - 1
        while hi - lo > 1:
            m = (lo + hi) // 2
            if self.len[m] <= s:
                lo = m
            else:
                hi = m
        seg = self.len[hi] - self.len[lo]
        f = 0.0 if seg < 1e-9 else (s - self.len[lo]) / seg
        return lo, hi, f

    def at(self, u):
        lo, hi, f = self._idx(u)
        p = self.pts[lo].lerp(self.pts[hi], f)
        t = self.tan[lo].lerp(self.tan[hi], f).normalized()
        up = self.up[lo].lerp(self.up[hi], f)
        up = (up - t * up.dot(t)).normalized()
        return p, t, up, t.cross(up).normalized()

    def local(self, p, u):
        """(angle round the body from the top, distance from the axis) of a point near u."""
        c, t, up, side = self.at(u)
        d = p - c
        d = d - t * d.dot(t)
        return math.atan2(d.dot(side), d.dot(up)), d.length


def blade(b, root, tip, width, col, col_tip=None, side=None, bone=None, curl=0.08, thick=0.14, tint=1.0, cls=HAIR, mat=0, steps=6, seg=8,
          point=0.5, cols=None, twist=0.0):
    """A solid flight or tail feather: a flattened, gently curved blade, narrow at the quill,
    broad through the vane and rounded or pointed at the tip (`point`), shading from the root
    colour to the tip colour.  Solid (not a card) so it keeps a clean ink outline."""
    root = V(root)
    tip = V(tip)
    d = tip - root
    L = d.length
    dn = d.normalized()
    if side is None:
        side = dn.cross(V(0, 1, 0))
        if side.length < 1e-4:
            side = V(1, 0, 0)
    side = V(side)
    side = (side - dn * side.dot(dn)).normalized()
    nrm = dn.cross(side).normalized()
    rings = []
    rcols = []
    for j in range(steps + 1):
        t = j / steps
        c = root + d * t + nrm * (math.sin(math.pi * t) * curl * L)
        tan = (d + nrm * (math.cos(math.pi * t) * math.pi * curl * L)).normalized()
        w = width * (0.25 + 0.75 * math.sin(math.pi * min(1.0, 0.12 + t * 0.95)) ** 0.6) * (1.0 - point * smooth(0.6, 1.0, t))
        w = max(w, 0.0008)
        h = max(0.0006, min(w * thick, width * thick))
        up = nrm - tan * nrm.dot(tan)
        if twist:
            up = Matrix.Rotation(twist * t, 3, tan) @ up
        rings.append(section(c, tan, prof_ellipse_fn(w, h), seg, up=up))
        if cols is not None:
            rcols.append(cols[min(len(cols) - 1, j)])
        else:
            rcols.append(mix(col, col_tip, t ** 1.3) if col_tip is not None else rgb(col))
    return loft(b, rings, col, cls=cls, cols=rcols, bone=bone, tint=tint, mat=mat, cap0=True, cap1=True, cap_push=0.3)
