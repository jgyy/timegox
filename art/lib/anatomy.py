"""Animal anatomy for the monster scripts: quadruped bodies, legs and paws, canine and feline
heads, groomed fur, overlapping scales, feathers and insect exoskeletons.

Reference points (animal anatomy for artists):

* The ribcage is deep and narrow, keel-shaped, reaching down to the elbows; behind it the belly
  *tucks up* to a slim waist before the haunches.  Seen from the side the body is not a tube.
* The back rises at the withers (the tops of the shoulder blades) and at the croup.
* Digitigrade animals walk on their toes.  In the hind leg the *stifle* (knee) points forward and
  the *hock* (heel) backwards and high; in the front leg the elbow sits behind, at the bottom of
  the chest, and the wrist low.  Thighs and shoulders carry the muscle; cannon bones are slender.
* Paws: four toes in an arc in front of a heart-shaped pad, claws on the toes.
* Canine heads: a domed skull, a "stop" in front of the eyes, a long wedge muzzle with a nose pad
  and a separate lower jaw.  Feline heads: round skull, short muzzle, whisker pads, a small chin.

The quadruped helpers read a ``creature.quad_rig`` rig (pelvis, chest, neck, head, jaw, tail and
three-bone legs ``f_up/f_lo/f_paw`` and ``h_up/h_lo/h_paw``) so the existing clips keep working.
Everything is greyscale with tint weight 1 unless a colour is passed, so the game can recolour it.
"""

import math
import random

from mathutils import Matrix

from kit import b2g, g2b
from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, METAL, SCALE, SKIN, STONE, V, darken, lighten, mix, rgb
from sculpt import blob3, catmull, clamp, fbm3, loft, morph_sphere, prof_egg, scatter, section, smooth, strand

GREY = (0.82, 0.82, 0.82)


def grey(v):
    return (v, v, v)


# ---------------------------------------------------------------- quadruped body
class QuadSpec:
    """Body proportions.  Lengths in metres; the rig gives the overall layout."""

    def __init__(self, **kw):
        self.hip_w = kw.get("hip_w", 0.2)        # half width at the haunches
        self.chest_w = kw.get("chest_w", 0.19)   # half width of the ribcage
        self.chest_d = kw.get("chest_d", 0.34)   # depth below the spine at the chest (keel)
        self.waist_d = kw.get("waist_d", 0.2)    # depth at the tucked waist
        self.waist_w = kw.get("waist_w", 0.15)
        self.back_h = kw.get("back_h", 0.12)     # spine to top of the back
        self.withers = kw.get("withers", 0.05)   # rise of the withers
        self.neck_r = kw.get("neck_r", 0.15)
        self.head_r = kw.get("head_r", 0.12)
        self.belly = kw.get("belly", 0.0)        # >0 for heavy animals: belly hangs instead of tucking
        self.shade = kw.get("shade", (0.55, 1.05))  # back and belly grey levels
        self.stripes = kw.get("stripes", 0.0)
        self.seed = kw.get("seed", 3)


def _rig_pts(r):
    pel = r.head("pelvis")
    chest = r.tail("chest")
    neck_top = r.tail("neck")
    head = r.tail("head")
    return pel, chest, neck_top, head


def body_colour(spine_y, sp, spots=0.0):
    """Countershaded grey: dark back, pale belly, a little noise and optional stripes."""
    back, belly = sp.shade

    def fn(p, *_):
        dy = p.y - spine_y(p.z)
        k = 0.5 + 0.5 * math.tanh(dy * 6.0 + 0.6)
        v = belly + (back - belly) * k
        v *= 0.93 + 0.14 * fbm3((p.x * 6, p.y * 6, p.z * 6), 3, sp.seed)
        if sp.stripes > 0.0:
            s = math.sin(p.z * sp.stripes + 1.5 * math.sin(p.y * 7.0))
            v *= 1.0 - 0.22 * smooth(0.3, 0.8, s) * k
        if spots > 0.0:
            v *= 1.0 - 0.2 * smooth(0.62, 0.7, fbm3((p.x * 14, p.y * 14, p.z * 14), 2, sp.seed + 5)) * spots
        return grey(v)

    return fn


def quad_body(b, r, sp, weights):
    """Torso and neck as one loft from the rump to behind the head.  Returns (verts, spine_y)."""
    pel, chest, neck_top, head = _rig_pts(r)
    hz = pel.z
    fz = chest.z
    by = pel.y
    length = fz - hz
    # spine line: croup, dip behind the withers, withers, then up the neck
    keys = [
        (hz - 0.2 * length, by - 0.03),
        (hz, by + 0.02),
        (hz + 0.35 * length, by - 0.01),
        (hz + 0.7 * length, by + 0.02),
        (fz, by + 0.06 + sp.withers),
    ]

    def spine_y(z):
        if z <= keys[0][0]:
            return keys[0][1]
        for i in range(len(keys) - 1):
            a, c = keys[i], keys[i + 1]
            if a[0] <= z <= c[0]:
                t = (z - a[0]) / (c[0] - a[0])
                t = t * t * (3 - 2 * t)
                return a[1] + (c[1] - a[1]) * t
        # neck: interpolate towards the neck top
        t = clamp((z - fz) / max(1e-4, neck_top.z - fz))
        return keys[-1][1] + (neck_top.y - keys[-1][1]) * t

    rings = []
    zs = [hz - 0.24 * length, hz - 0.14 * length, hz - 0.04 * length, hz + 0.1 * length, hz + 0.28 * length, hz + 0.46 * length,
          hz + 0.62 * length, hz + 0.78 * length, hz + 0.92 * length, fz + 0.04 * length]
    n = 24
    for k, z in enumerate(zs):
        t = (z - hz) / length
        y = spine_y(z)
        # half width, height above the spine and depth below it along the body
        if t < 0.0:
            w = sp.hip_w * (0.6 + 0.4 * smooth(-0.25, 0.0, t))
            up = sp.back_h * (0.7 + 0.3 * smooth(-0.25, 0.0, t))
            dn = (sp.waist_d + 0.05) * (0.55 + 0.45 * smooth(-0.25, 0.0, t))
        elif t < 0.45:
            u = t / 0.45
            w = sp.hip_w + (sp.waist_w - sp.hip_w) * smooth(0.0, 1.0, u)
            up = sp.back_h
            dn = (sp.waist_d + 0.06) + (sp.waist_d - (sp.waist_d + 0.06)) * smooth(0.0, 1.0, u)
        else:
            u = (t - 0.45) / 0.55
            w = sp.waist_w + (sp.chest_w - sp.waist_w) * smooth(0.0, 0.7, u)
            up = sp.back_h + sp.withers * smooth(0.6, 1.0, u)
            dn = sp.waist_d + (sp.chest_d - sp.waist_d) * smooth(0.0, 0.75, u)
        dn += sp.belly * math.sin(math.pi * clamp(t + 0.1))
        prof = prof_egg(w, up, dn, flat=0.15)
        rings.append(section(V(0, y, z), V(0, 0, 1), prof, n, up=V(0, 1, 0)))
    # neck: from the withers up to just behind the head, narrowing, deeper than wide
    nb = V(0, spine_y(fz) - sp.chest_d * 0.35, fz + 0.04 * length)
    nt = neck_top + (head - neck_top) * 0.25
    for k in range(1, 6):
        t = k / 5
        c = nb.lerp(nt, t) + V(0, 0.04 * math.sin(math.pi * t), 0)
        d = (nt - nb).normalized()
        rw = sp.neck_r * (1.15 - 0.35 * t)
        rh = sp.neck_r * (1.5 - 0.6 * t)
        prof = prof_egg(rw, rh * 0.8, rh * 1.1)
        rings.append(section(c, d, prof, n, up=V(0, 1, 0)))
    cf = body_colour(spine_y, sp)
    verts = loft(b, rings, GREY, cls=CLOTH, col_fn=lambda p, j, i: cf(p), bone_fn=weights, tint=1.0, cap0=True, cap1=True, cap_push=0.5)
    return verts, spine_y


def quad_leg(b, r, nm, sd, sp, spine_y, thick=1.0, col=None, paw=True, hoof=False, toes=4, claw_col="ece6d6"):
    """A muscled leg on bones nm_up/nm_lo/nm_paw.  Front legs carry the shoulder and forearm mass,
    hind legs the thigh and gaskin; both taper to slender cannons and end in a paw (or hoof)."""
    up = "%s_up.%s" % (nm, sd)
    lo = "%s_lo.%s" % (nm, sd)
    pw = "%s_paw.%s" % (nm, sd)
    top, knee = r.head(up), r.tail(up)
    ank = r.tail(lo)
    tip = r.tail(pw)
    s = 1 if sd == "L" else -1
    hind = nm == "h"
    col = col or GREY
    # start inside the body so the leg grows out of it
    root = V(top.x * 0.7, spine_y(top.z) - 0.02, top.z + (0.04 if hind else -0.02))
    mid_up = top.lerp(knee, 0.5) + V(0, 0, (0.06 if hind else -0.02))
    ctrl = [root, top, mid_up, knee, knee.lerp(ank, 0.5), ank, ank.lerp(tip, 0.4)]
    pts = catmull(ctrl, 4)
    radii = []
    big = (sp.hip_w * 0.75 if hind else sp.chest_w * 0.62) * thick
    m = len(pts)
    for i in range(m):
        t = i / (m - 1)
        # muscle mass high up, slim cannon, knobbly joints
        rr = big * (1.0 - smooth(0.12, 0.55, t) * 0.72)
        rr += 0.012 * thick * math.exp(-((t - 0.5) / 0.05) ** 2)       # knee / elbow
        rr += 0.01 * thick * math.exp(-((t - 0.83) / 0.04) ** 2)       # hock / wrist
        rr = max(rr, 0.028 * thick)
        # flatter side to side over the thigh, rounder below
        radii.append((rr * (0.78 if t < 0.45 else 0.95), rr * (1.15 if t < 0.45 else 1.0)))
    bones = []
    for i in range(m):
        t = i / (m - 1)
        if t < 0.08:
            bones.append({("pelvis" if hind else "chest"): 0.6, up: 0.4})
        elif t < 0.46:
            bones.append({up: 1.0})
        elif t < 0.54:
            bones.append({up: 0.5, lo: 0.5})
        elif t < 0.8:
            bones.append({lo: 1.0})
        elif t < 0.9:
            bones.append({lo: 0.5, pw: 0.5})
        else:
            bones.append({pw: 1.0})
    cols = [mix(col, darken(col, 0.3), smooth(0.4, 1.0, i / (m - 1))) for i in range(m)]
    verts = b.tube(pts, radii, col, cls=CLOTH, bones=bones, seg=12, cap0=True, cap1=False, cols=cols, tint=1.0, up=(1, 0, 0))
    if hoof:
        hc = pts[-1]
        b.lathe(V(hc.x, 0.0, hc.z + 0.02), [(0.055 * thick, 0.0), (0.06 * thick, 0.02), (0.05 * thick, 0.07), (0.038 * thick, 0.1)], "3a3028", cls=STONE, bone=pw, seg=14)
        b.lathe(V(hc.x, 0.09, hc.z + 0.02), [(0.045 * thick, 0.0), (0.055 * thick, 0.03), (0.04 * thick, 0.08)], darken(col, 0.4), cls=HAIR, bone=pw, seg=14, folds=(11, 0.15, 0.0), tint=1.0)
    elif paw:
        make_paw(b, pts[-1], tip, pw, s, thick, col, toes, claw_col)
    return verts


def make_paw(b, base, tip, bone, s, k, col, toes=4, claw_col="ece6d6"):
    """A paw: a rounded pad mass, toes in an arc, claws, and dark pads underneath."""
    c = V(base.x, 0.04 * k, max(base.z, tip.z - 0.04 * k))
    b.ellipsoid(c, (0.055 * k, 0.04 * k, 0.07 * k), col, cls=CLOTH, bone=bone, seg=14, rings=8, tint=1.0, col2=darken(col, 0.3))
    b.ellipsoid(c + V(0, -0.03 * k, -0.01 * k), (0.035 * k, 0.012 * k, 0.035 * k), "302428", cls=SKIN, bone=bone, seg=10, rings=5)
    for i in range(toes):
        u = (i / max(1, toes - 1) - 0.5) * 2.0
        tc = c + V(u * 0.038 * k, -0.008 * k, 0.055 * k - abs(u) * 0.016 * k)
        b.ellipsoid(tc, (0.02 * k, 0.024 * k, 0.026 * k), col, cls=CLOTH, bone=bone, seg=10, rings=6, tint=1.0)
        b.ellipsoid(tc + V(0, -0.02 * k, 0.0), (0.012 * k, 0.006 * k, 0.012 * k), "302428", cls=SKIN, bone=bone, seg=8, rings=4)
        claw = [tc + V(0, 0.004 * k, 0.018 * k), tc + V(0, -0.002 * k, 0.04 * k), tc + V(0, -0.02 * k, 0.05 * k)]
        b.tube(claw, [0.007 * k, 0.005 * k, 0.001], claw_col, cls=STONE, bone=bone, seg=6)
    return c


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


def canine_head(b, hf, k, bone="head", jaw="jaw", eye_col="ffd040", ear_bones=("ear.L", "ear.R"), long=1.0, ruff=True, ear_len=1.0):
    """Wolf / fox / lion-dog head: skull with a stop, wedge muzzle, black nose, lips, separate jaw,
    fangs, slanted eyes under a brow, tall ears with a pale inside, cheek ruffs."""
    def skull(d):
        p = V(d.x * 0.1, d.y * 0.09, d.z * 0.11) * k
        q = p.copy()
        off = 0.0
        for s in (1, -1):
            off += 0.012 * k * blob3(q, (0.075 * s * k, -0.02 * k, 0.02 * k), (0.03 * k, 0.04 * k, 0.04 * k))  # cheek muscle
            off -= 0.008 * k * blob3(q, (0.045 * s * k, 0.025 * k, 0.085 * k), (0.02 * k, 0.015 * k, 0.02 * k))  # eye socket
        off += 0.01 * k * blob3(q, (0, 0.06 * k, 0.04 * k), (0.03 * k, 0.03 * k, 0.06 * k))  # sagittal crest
        return p + p.normalized() * off

    rot = hf.M
    morph_sphere(b, hf.c, skull, lambda p, d: grey(0.7 + 0.25 * d.y * 0.5 - 0.15 * max(0.0, -d.y)), cls=CLOTH, bone=bone, seg=24, rings=16, tint_fn=lambda p, d: 1.0, rot=rot)
    # muzzle: from the stop forward, a rounded wedge narrowing to the nose
    L = 0.17 * k * long
    rings = []
    for i in range(6):
        t = i / 5
        c = hf.at(0, -0.02 * k - 0.025 * k * t, 0.06 * k + L * t)
        w = (0.06 - 0.03 * t) * k
        hgt_t = (0.045 - 0.018 * t) * k
        hgt_b = (0.035 - 0.015 * t) * k
        rings.append(section(c, hf.f, prof_egg(w, hgt_t, hgt_b, flat=0.3), 16, up=hf.u))
    loft(b, rings, GREY, cls=CLOTH, cols=[grey(0.75), grey(0.8), grey(0.85), grey(0.9), grey(0.92), grey(0.95)], bone=bone, tint=1.0, cap0=False, cap1=True, cap_push=0.5)
    nose = hf.at(0, -0.026 * k, 0.065 * k + L)
    b.ellipsoid(nose, (0.022 * k, 0.016 * k, 0.014 * k), "1a1418", cls=SKIN, bone=bone, seg=12, rings=8)
    for s in (1, -1):
        b.ellipsoid(nose + hf.M @ V(0.009 * s * k, -0.004 * k, 0.01 * k), (0.004 * k, 0.003 * k, 0.003 * k), "000000", cls=SKIN, bone=bone, seg=6, rings=4, mat=MAT_PLAIN)
    # lips: a dark line along the side of the muzzle
    for s in (1, -1):
        lip = [hf.at(0.04 * s * k, -0.055 * k, 0.07 * k), hf.at(0.032 * s * k, -0.058 * k, 0.07 * k + L * 0.5), hf.at(0.015 * s * k, -0.055 * k, 0.06 * k + L)]
        b.tube(lip, [0.004 * k, 0.004 * k, 0.003 * k], "2a2028", cls=SKIN, bone=bone, seg=5, mat=MAT_PLAIN)
    # lower jaw on its own bone, with a tongue and fangs
    jr = []
    for i in range(5):
        t = i / 4
        c = hf.at(0, -0.065 * k - 0.006 * k * t, 0.03 * k + L * 0.92 * t)
        jr.append(section(c, hf.f, prof_egg((0.045 - 0.02 * t) * k, 0.012 * k, (0.024 - 0.01 * t) * k), 12, up=hf.u))
    loft(b, jr, grey(0.95), cls=CLOTH, bone=jaw, tint=1.0, cap0=True, cap1=True, cap_push=0.4)
    b.ellipsoid(hf.at(0, -0.058 * k, 0.05 * k + L * 0.5), (0.022 * k, 0.005 * k, L * 0.4), "c04a58", cls=SKIN, bone=jaw, seg=10, rings=4)
    for s in (1, -1):
        b.cone(hf.at(0.022 * s * k, -0.07 * k, 0.05 * k + L * 0.85), 0.007 * k, 0.03 * k, "f6f0e0", cls=STONE, bone=bone, seg=6, rot=(math.pi, 0, 0))
        b.cone(hf.at(0.02 * s * k, -0.062 * k, 0.04 * k + L * 0.75), 0.006 * k, 0.022 * k, "f6f0e0", cls=STONE, bone=jaw, seg=6)
    # eyes under a heavy brow, angled along the skull
    for s in (1, -1):
        b.eye(hf.at(0.048 * s * k, 0.018 * k, 0.088 * k), 0.022 * k, eye_col, side=s, bone=bone, slit=False, glow=True, rot_y=0.55, h=0.75, mat=MAT_PLAIN)
        brow = [hf.at(0.02 * s * k, 0.04 * k, 0.1 * k), hf.at(0.05 * s * k, 0.045 * k, 0.095 * k), hf.at(0.075 * s * k, 0.036 * k, 0.075 * k)]
        b.tube(brow, [0.012 * k, 0.014 * k, 0.008 * k], grey(0.55), cls=CLOTH, bone=bone, seg=7, tint=1.0)
    # ears: tall, pointed, hollow at the front
    for s, eb in ((1, ear_bones[0]), (-1, ear_bones[1])):
        base = hf.at(0.06 * s * k, 0.07 * k, 0.0)
        tip = hf.at(0.085 * s * k, (0.07 + 0.14 * ear_len) * k, -0.01 * k)
        rows = []
        cols = []
        for j in range(6):
            t = j / 5
            c = base.lerp(tip, t)
            w = 0.04 * k * (1.0 - t) ** 0.8 + 0.002
            side = hf.r
            back = -hf.f * (0.02 * k * (1.0 - t))
            rows.append([c - side * w + back, c + hf.f * 0.008 * k, c + side * w + back])
            cols.append(mix(grey(0.55), grey(0.35), t))
        b.sheet(rows, GREY, bone=eb, cols=cols, thickness=0.012 * k, tint=1.0)
        inner = [base.lerp(tip, t) + hf.f * 0.008 * k for t in (0.05, 0.4, 0.75)]
        b.tube(inner, [0.022 * k, 0.014 * k, 0.003 * k], "e8b0a8", cls=SKIN, bone=eb, seg=6, flat=0.4, up=tuple(hf.f))
    if ruff:
        for s in (1, -1):
            for j in range(4):
                root = hf.at(0.08 * s * k, -0.02 * k - j * 0.018 * k, 0.03 * k - j * 0.02 * k)
                strand(b, [root, root + hf.M @ V(0.05 * s * k, -0.02 * k, -0.03 * k), root + hf.M @ V(0.07 * s * k, -0.05 * k, -0.07 * k)], 0.022 * k, 0.002, grey(0.75), col_tip=grey(0.95), cls=HAIR, bone=bone, flat=0.4, seg=5, per=3, tint=1.0)


def feline_head(b, hf, k, bone="head", jaw="jaw", eye_col="ffd040", ear_bones=("ear.L", "ear.R")):
    """Lion-dog / tiger head: round skull, short broad muzzle with whisker pads, a broad nose."""
    def skull(d):
        p = V(d.x * 0.12, d.y * 0.105, d.z * 0.11) * k
        q = p.copy()
        off = 0.0
        for s in (1, -1):
            off += 0.016 * k * blob3(q, (0.08 * s * k, -0.04 * k, 0.04 * k), (0.035 * k, 0.04 * k, 0.04 * k))
            off -= 0.01 * k * blob3(q, (0.05 * s * k, 0.025 * k, 0.09 * k), (0.022 * k, 0.018 * k, 0.02 * k))
        return p + p.normalized() * off

    morph_sphere(b, hf.c, skull, lambda p, d: grey(0.72 + 0.2 * d.y * 0.5), cls=CLOTH, bone=bone, seg=24, rings=16, tint_fn=lambda p, d: 1.0, rot=hf.M)
    for s in (1, -1):
        b.ellipsoid(hf.at(0.03 * s * k, -0.045 * k, 0.11 * k), (0.035 * k, 0.03 * k, 0.03 * k), grey(0.95), cls=CLOTH, bone=bone, seg=12, rings=8, tint=1.0)
        for j in range(3):
            root = hf.at(0.045 * s * k, -0.04 * k - j * 0.008 * k, 0.12 * k)
            strand(b, [root, root + hf.M @ V(0.06 * s * k, 0.004 * k - j * 0.01 * k, 0.0), root + hf.M @ V(0.14 * s * k, -0.01 * k - j * 0.02 * k, -0.03 * k)], 0.0016, 0.0005, "f8f4ec", cls=HAIR, bone=bone, seg=4, per=3)
        b.eye(hf.at(0.05 * s * k, 0.02 * k, 0.09 * k), 0.025 * k, eye_col, side=s, bone=bone, slit=True, glow=True, rot_y=0.4, h=0.8, mat=MAT_PLAIN)
        ear = [hf.at(0.07 * s * k, 0.08 * k, -0.01 * k), hf.at(0.09 * s * k, 0.13 * k, -0.02 * k), hf.at(0.095 * s * k, 0.155 * k, -0.025 * k)]
        b.tube(ear, [(0.035 * k, 0.012 * k), (0.022 * k, 0.01 * k), (0.002, 0.002)], grey(0.5), cls=CLOTH, bone=ear_bones[0 if s > 0 else 1], seg=8, up=tuple(hf.f), tint=1.0)
    b.ellipsoid(hf.at(0, -0.015 * k, 0.13 * k), (0.03 * k, 0.02 * k, 0.018 * k), "2a1a20", cls=SKIN, bone=bone, seg=12, rings=6)
    b.ellipsoid(hf.at(0, -0.08 * k, 0.09 * k), (0.04 * k, 0.025 * k, 0.04 * k), grey(0.95), cls=CLOTH, bone=jaw, seg=12, rings=6, tint=1.0)
    for s in (1, -1):
        b.cone(hf.at(0.022 * s * k, -0.07 * k, 0.115 * k), 0.008 * k, 0.035 * k, "f6f0e0", cls=STONE, bone=bone, seg=6, rot=(math.pi, 0, 0))


# ---------------------------------------------------------------- fur, scales, feathers
def groom_back(p, n):
    """Default fur direction: backwards along the body and down the flanks."""
    g = V(0, -0.35, -1.0)
    g = g - n * g.dot(n)
    return g.normalized() if g.length > 1e-6 else V(0, -1, 0)


def fur(b, verts, count, length, width, col_root=grey(0.62), col_tip=grey(0.92), groom=groom_back, seed=7, pred=None, bone_fn=None, tint=1.0, lift=0.35, min_dist=0.0, len_fn=None, mat=MAT_PLAIN):
    """Plant `count` fur clumps on a built surface: each a short flattened lock leaning along the
    groom direction, darker at the root, lifting slightly off the skin so the silhouette breaks."""
    pts = scatter(b, verts, count, seed=seed, pred=pred, min_dist=min_dist)
    for k, (p, n) in enumerate(pts):
        g = groom(p, n)
        ln = length * (0.75 + 0.5 * fbm3((p.x * 9, p.y * 9, p.z * 9), 2, seed))
        if len_fn is not None:
            ln *= len_fn(p)
        root = p - n * 0.006
        mid = p + g * ln * 0.5 + n * ln * lift * 0.6
        tip = p + g * ln + n * ln * lift * 0.4
        bone = bone_fn(p) if bone_fn is not None else None
        strand(b, [root, mid, tip], width, width * 0.15, col_root, col_tip=col_tip, cls=HAIR, bone=bone, flat=0.4, seg=5, per=2, up=tuple(n), tint=tint, mat=mat)
    return len(pts)


def scale_rows(b, path, radius_fn, rows, per_row, col, bone_fn, size=0.05, tint=1.0, col2=None, belly_gap=0.0, up=V(0, 1, 0)):
    """Overlapping scales along a body path: each a rounded plate leaning back over the next.
    `belly_gap` (radians) leaves the underside bare for belly plates."""
    path = [V(p) for p in path]
    n = len(path)
    for j in range(rows):
        t = j / max(1, rows - 1)
        f = t * (n - 1)
        i = min(n - 2, int(f))
        u = f - i
        c = path[i].lerp(path[i + 1], u)
        d = (path[i + 1] - path[i]).normalized()
        side = d.cross(up).normalized()
        upv = side.cross(d).normalized()
        rad = radius_fn(t)
        for k in range(per_row):
            a = (k + 0.5 * (j % 2)) / per_row * 2 * math.pi
            if belly_gap > 0.0 and abs(((a + math.pi) % (2 * math.pi)) - math.pi) > math.pi - belly_gap * 0.5:
                continue
            nrm = upv * math.cos(a) + side * math.sin(a)
            pc = c + nrm * rad * 1.0
            sz = size * (0.6 + 0.4 * rad / max(1e-4, radius_fn(0.3)))
            # plate frame: x along the ring, y along the normal, z back along the body
            R = Matrix((nrm.cross(d).normalized(), nrm, -d)).transposed()
            verts = b.superquad(pc - d * sz * 0.3, (sz * 0.7, sz * 0.18, sz * 0.8), col, e=0.55, cls=SCALE, bone=bone_fn(pc), seg=8, rings=5, tint=tint, col2=col2)
            # orient the plate: rotate its verts from the default frame into R, tilted outwards
            tilt = Matrix.Rotation(-0.35, 3, "X")
            for v in verts:
                lp = b2g(v.co) - (pc - d * sz * 0.3)
                v.co = g2b((pc - d * sz * 0.3) + R @ (tilt @ lp))


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


def compound_eye(b, c, r, col, bone, facets=True):
    """A bulging insect eye with a sheen and a grid of facet glints."""
    b.ellipsoid(c, (r, r * 1.1, r), darken(col, 0.3), cls=CRYSTAL, bone=bone, seg=14, rings=10, mat=MAT_PLAIN, col2=darken(col, 0.6))
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
        if eye_glow is not None:
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
