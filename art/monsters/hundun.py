"""Hundun, the Faceless Chaos (new in Part V, final boss): a vast cinnabar sack with six legs and
four wings and no face, only a slow whirl of light where a face should be.  Glowing seams pulse
across its hide (after the Classic of Mountains and Seas).
Run: blender --background --python art/monsters/hundun.py  ->  assets/monsters/hundun.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, SKIN, V, Builder, Rig, env  # noqa: E402

kit.reset()
rnd = random.Random(13)
C = V(0, 1.55, 0)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", C + V(0, -0.4, 0), C + V(0, 0.5, 0), "root")
r.bone("swirl", C + V(0, 0.1, 0.62), C + V(0, 0.1, 0.9), "body")
for s, sd in ((1, "L"), (-1, "R")):
    for k, (z, y) in enumerate(((0.45, 0.4), (-0.05, 0.5))):
        root = C + V(0.45 * s, y, z)
        r.bone("wing%d.%s" % (k, sd), root, root + V(0.9 * s, 0.5 - k * 0.3, -0.3 - k * 0.2), "body")
    for k in range(3):
        z = 0.35 - k * 0.35
        hip = C + V(0.42 * s, -0.45, z)
        knee = hip + V(0.28 * s, -0.3, 0.05)
        foot = knee + V(0.08 * s, -0.75, 0.05)
        r.bone("leg%d.%s" % (k, sd), hip, knee, "body")
        r.bone("shin%d.%s" % (k, sd), knee, foot, "leg%d.%s" % (k, sd))

b = Builder("hundun")
# the sack: a big lumpy ellipsoid with folds
b.ellipsoid(C, (0.68, 0.72, 0.75), (0.85, 0.85, 0.85), cls=CLOTH, bone="body", tint=1.0, seg=28, rings=18, col2=(0.5, 0.5, 0.5))
for k in range(9):
    a = rnd.uniform(0, 2 * math.pi)
    y = rnd.uniform(-0.4, 0.5)
    rr = math.sqrt(max(0.05, 1.0 - (y / 0.72) ** 2)) * 0.66
    c = C + V(math.sin(a) * rr, y, math.cos(a) * rr)
    sz = rnd.uniform(0.18, 0.3)
    b.ellipsoid(c, (sz, sz * 0.8, sz), (0.8, 0.8, 0.8), cls=CLOTH, bone="body", tint=1.0, seg=12, rings=8)
# glowing seams wandering over the hide
for k in range(7):
    a0 = rnd.uniform(0, 2 * math.pi)
    pts = []
    for i in range(9):
        a = a0 + i * 0.22
        y = -0.5 + i * 0.13 + 0.1 * math.sin(i + k)
        rr = math.sqrt(max(0.02, 1.0 - (y / 0.73) ** 2)) * 0.7
        pts.append(C + V(math.sin(a) * rr, y, math.cos(a) * rr))
    b.tube(pts, [0.018] * 9, (1.0, 0.95, 0.6), cls=CRYSTAL, bone="body", mat=MAT_GLOW, seg=5)
# the missing face: a whirl of light on a dark hollow
b.disc(C + V(0, 0.1, 0.735), 0.3, "120818", cls=SKIN, bone="body", seg=24, rot=(math.pi / 2, 0, 0), thick=0.02)
for k in range(5):
    pts = []
    for i in range(14):
        a = k * 2 * math.pi / 5 + i * 0.32
        rr = 0.03 + i * 0.019
        pts.append(C + V(math.cos(a) * rr, 0.1 + math.sin(a) * rr, 0.75 + 0.002 * i))
    b.tube(pts, [0.012 - i * 0.0006 for i in range(14)], (1.0, 1.0, 0.8), cls=CRYSTAL, bone="swirl", mat=MAT_GLOW, seg=5)
# wings: layered feathers fanning from four roots
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(2):
        wb = "wing%d.%s" % (k, sd)
        h, tl = r.head(wb), r.tail(wb)
        for f in range(9):
            u = f / 8
            base = h.lerp(tl, u * 0.7)
            tip = base + (tl - h) * 0.45 + V(0, -0.25 - u * 0.4, -0.35 - u * 0.2)
            sh = 0.55 + 0.4 * u
            b.leaf(base, tip, 0.1, (sh, sh, sh), side=(0, 1, 0), cls=HAIR, bone=wb, tint=1.0, col_tip=(1.0, 0.9, 0.7), curl=0.1)
    for k in range(3):
        lg, sn = "leg%d.%s" % (k, sd), "shin%d.%s" % (k, sd)
        b.tube([r.head(lg), r.tail(lg)], [0.09, 0.07], (0.7, 0.7, 0.7), bone=lg, tint=1.0, seg=10)
        b.tube([r.head(sn), r.head(sn).lerp(r.tail(sn), 0.7), r.tail(sn)], [0.07, 0.05, 0.035], (0.6, 0.6, 0.6), bones=[{lg: 0.4, sn: 0.6}, sn, sn], tint=1.0, seg=10)
        b.ellipsoid(r.tail(sn) + V(0, 0.02, 0.05), (0.08, 0.04, 0.12), "302018", cls=SKIN, bone=sn, seg=10, rings=5)

T = 3.0


def idle(t):
    w = 2 * math.pi / T
    f = math.sin(t * w * 2)
    pulse = 1.0 + 0.03 * math.sin(t * w)
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, math.sin(t * w) * 0.12, 0))
    p["body"] = ((math.sin(t * w) * 0.05, math.sin(t * w * 0.5) * 0.12, 0), (0, 0, 0), (pulse, 2.0 - pulse, pulse))
    p["swirl"] = ((0, 0, t * w), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        for k in range(2):
            p["wing%d.%s" % (k, sd)] = ((0, 0, -s * f * (0.4 - k * 0.1)), (0, 0, 0))
        for k in range(3):
            ph = t * w + k * 1.2 + (0 if s > 0 else math.pi)
            p["leg%d.%s" % (k, sd)] = ((math.sin(ph) * 0.25, 0, s * 0.1), (0, 0, 0))
            p["shin%d.%s" % (k, sd)] = ((0.2 + math.sin(ph + 1) * 0.2, 0, 0), (0, 0, 0))
    return p


def attack(t):
    e = env(t / 0.7)
    p = idle(t)
    p["root"] = ((0, 0, 0), (0, -0.25 * e, 0.6 * e))
    p["body"] = ((0.4 * e, 0, 0), (0, 0, 0), (1.0 + 0.1 * e, 1.0 - 0.1 * e, 1.0 + 0.15 * e))
    for sd, s in (("L", 1), ("R", -1)):
        for k in range(3):
            p["leg%d.%s" % (k, sd)] = ((-0.9 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(t)
    p["root"] = ((0, 0, 0), (0, 0.15 * e, -0.3 * e))
    p["body"] = ((-0.3 * e, 0.2 * e, 0), (0, 0, 0), (1.0 - 0.1 * e, 1.0 + 0.12 * e, 1.0 - 0.1 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(t)
    p["body"] = ((-0.2 * e, 0, 0), (0, 0.2 * e, 0), (1.0 + 0.2 * e, 1.0 + 0.2 * e, 1.0 + 0.2 * e))
    p["swirl"] = ((0, 0, t * 20.0), (0, 0, 0), (1.0 + e, 1.0 + e, 1.0))
    for sd, s in (("L", 1), ("R", -1)):
        for k in range(2):
            p["wing%d.%s" % (k, sd)] = ((0, 0, s * (0.7 - k * 0.2) * e), (0, 0, 0))
    return p


print("[art] hundun: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/hundun.glb", {"idle": (T, idle), "attack": (0.7, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.35, strength=0.5)
