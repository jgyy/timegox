"""Hundun, the Faceless Chaos (new in Part V, final boss): a vast cinnabar sack with six legs and
four wings and no face, only a slow whirl of light where a face should be.  Glowing seams pulse
across its hide (after the Classic of Mountains and Seas).
The hide is one lumpy, sagging sack with deep folds, veins and mottling; the four wings carry
flight feathers and two rows of coverts; the six legs have knobbly knees, plated shins and
three-clawed feet; folds of hide are drawn into the hollow where a face should be.
Run: blender --background --python art/monsters/hundun.py  ->  assets/monsters/hundun.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import zero_pose  # noqa: E402
from sculpt import fbm3, morph_sphere, smooth, strand  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402
from creature import Walker, add  # noqa: E402

kit.reset()
creature.realtime()
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
# the sack: one lumpy, sagging hide with deep folds and creases, mottled and veined
def sack(d):
    p = V(d.x * 0.7, d.y * 0.72, d.z * 0.76)
    p = p * (1.0 + 0.16 * (fbm3((d.x * 2.2, d.y * 2.2, d.z * 2.2), 3, 9) - 0.5))
    p.y -= 0.06 * smooth(0.0, -0.9, d.y)                                    # sags at the bottom
    fold = abs(math.sin(math.atan2(d.x, d.z) * 4.0 + d.y * 2.5))
    return p * (1.0 - 0.035 * smooth(0.12, 0.0, fold))


def hide(p, d):
    v = 0.62 + 0.25 * smooth(-0.8, 0.6, d.y)
    vein = smooth(0.03, 0.0, abs(fbm3((d.x * 5, d.y * 5, d.z * 5), 2, 13) - 0.5))
    v *= 1.0 - 0.25 * vein
    v *= 0.92 + 0.16 * fbm3((d.x * 12, d.y * 12, d.z * 12), 1, 2)
    return (v, v, v)


body_v = morph_sphere(b, C, sack, hide, cls=CLOTH, bone="body", seg=40, rings=26, tint_fn=lambda p, d: 1.0)
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# glowing seams wandering over the hide
for k in range(7):
    a0 = rnd.uniform(0, 2 * math.pi)
    pts = []
    for i in range(9):
        a = a0 + i * 0.22
        y = -0.5 + i * 0.13 + 0.1 * math.sin(i + k)
        rr = math.sqrt(max(0.02, 1.0 - (y / 0.73) ** 2)) * 0.7
        pts.append(C + V(math.sin(a) * rr, y, math.cos(a) * rr))
    b.tube(pts, [0.018] * 9, (1.0, 1.0, 1.0), cls=CRYSTAL, bone="body", mat=MAT_GLOW, seg=5, tint=1.0)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# the missing face: a whirl of light on a dark hollow
b.disc(C + V(0, 0.1, 0.735), 0.3, "120818", cls=SKIN, bone="body", seg=24, rot=(math.pi / 2, 0, 0), thick=0.02)
for k in range(5):
    pts = []
    for i in range(14):
        a = k * 2 * math.pi / 5 + i * 0.32
        rr = 0.03 + i * 0.019
        pts.append(C + V(math.cos(a) * rr, 0.1 + math.sin(a) * rr, 0.75 + 0.002 * i))
    b.tube(pts, [0.012 - i * 0.0006 for i in range(14)], (1.0, 1.0, 0.8), cls=CRYSTAL, bone="swirl", mat=MAT_GLOW, seg=5)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# wings: four feathered wings, each a covered arm with long flight feathers and two rows of
# coverts over them
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(2):
        wb = "wing%d.%s" % (k, sd)
        h, tl = r.head(wb), r.tail(wb)
        b.tube([h, h.lerp(tl, 0.5) + V(0, 0.04, 0), tl], [0.06, 0.045, 0.02], (0.75, 0.75, 0.75), bone=wb, tint=1.0, seg=8)
        span = (tl - h).normalized()
        # solid feathers whose vanes lie in the plane of the wing (spanwise), overlapping like
        # shingles: long dark flight feathers, then two rows of paler coverts over their roots
        for row, (n, ln, shd) in enumerate(((15, 0.75, 0.62), (13, 0.45, 0.78), (10, 0.25, 0.9))):
            for f in range(n):
                u = f / (n - 1)
                base = h.lerp(tl, 0.1 + u * 0.85) + V(0, 0.015 * row, 0.012 * row)
                tip = base + span * 0.2 * u + V(0, -ln * (0.5 + 0.5 * u), -ln * 0.6)
                A.blade(b, base, tip, 0.1 - 0.015 * row, (shd, shd, shd), col_tip=(min(1.0, shd + 0.25),) * 3, side=span, bone=wb, curl=0.06, thick=0.1, tint=1.0, steps=5, seg=6, point=0.15)
    b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
    # six legs: thick thighs, knobbly knees, scaled shins and three-clawed feet
    for k in range(3):
        lg, sn = "leg%d.%s" % (k, sd), "shin%d.%s" % (k, sd)
        b.tube([r.head(lg), r.head(lg).lerp(r.tail(lg), 0.5) + V(0, 0.02, 0), r.tail(lg)], [0.1, 0.095, 0.07], (0.7, 0.7, 0.7), bone=lg, tint=1.0, seg=12)
        b.ball(r.tail(lg), 0.075, (0.6, 0.6, 0.6), bone=sn, tint=1.0, seg=10, rings=6)
        A.plate_segments(b, [r.head(sn), r.head(sn).lerp(r.tail(sn), 0.5), r.tail(sn)], [0.065, 0.055, 0.04], (0.6, 0.6, 0.6), lambda p, sn=sn: sn, n=10, cls=SCALE)
        foot = r.tail(sn)
        b.ellipsoid(foot + V(0, 0.02, 0.03), (0.07, 0.035, 0.09), "302018", cls=SKIN, bone=sn, seg=10, rings=5)
        for c in range(3):
            a = (c - 1) * 0.5
            d = V(math.sin(a), 0, math.cos(a))
            strand(b, [foot + d * 0.05, foot + d * 0.1 + V(0, 0.01, 0), foot + d * 0.13 - V(0, 0.02, 0)], 0.016, 0.002, "e8dcc0", cls=STONE, bone=sn, seg=5, per=3)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# the hollow where a face should be is ringed by folds of hide drawn into it
for k in range(4):
    rr = 0.32 + k * 0.06
    ring = [C + V(math.cos(a) * rr, 0.1 + math.sin(a) * rr, 0.71 - 0.03 * k) for a in [i / 24 * 2 * math.pi for i in range(25)]]
    b.tube(ring, [0.03 - 0.005 * k] * 25, (0.55 + 0.08 * k,) * 3, cls=CLOTH, bone="body", tint=1.0, seg=6, cap0=False, cap1=False)

T = 3.0


def idle(t):
    w = 2 * math.pi / T
    f = math.sin(t * w * 2)
    pulse = 1.0 + 0.03 * math.sin(t * w)
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, math.sin(t * w) * 0.12, 0))
    p["body"] = ((math.sin(t * w) * 0.05, math.sin(t * w + 0.8) * 0.12, 0), (0, 0, 0), (pulse, 2.0 - pulse, pulse))
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
    e = env(t / 0.55)
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


T_WALK = 1.4
PAIRS = [("leg%d.%s" % (k, sd), "shin%d.%s" % (k, sd)) for sd in ("L", "R") for k in range(3)]
WALK = Walker(r, PAIRS, [0.5 * ((k + (0 if sd == "L" else 1)) % 2) for sd in ("L", "R") for k in range(3)], duty=0.55)


def walk(t):
    """Six legs in alternating tripods carry the sack; the wings beat, the hide sways."""
    ph = (t / T_WALK) % 1.0
    w = 2 * math.pi
    p = zero_pose(r)
    add(p, "body", (0.04 * math.sin(w * ph * 2), 0.08 * math.sin(w * ph), 0.05 * math.sin(w * ph)), (0, 0.03 * abs(math.sin(w * ph * 2)), 0))
    add(p, "swirl", (0, 0, 2 * math.pi * t / T_WALK))
    for sd, s_ in (("L", 1), ("R", -1)):
        for k in range(2):
            add(p, "wing%d.%s" % (k, sd), (0, 0, -s_ * 0.35 * math.sin(w * ph * 2 - k * 0.6)))
    return WALK.step(p, ph, 0.3, 0.12)


def die(t):
    """The sack sags and slumps to the ground, its legs splaying, its wings falling open."""
    k = min(1.0, t / 1.2)
    f = smooth(0.15, 0.75, k)
    p = zero_pose(r)
    sq = 1.0 - 0.25 * f
    add(p, "root", (0, 0, 0), (0, -0.95 * f + 0.04 * math.sin(math.pi * smooth(0.7, 0.9, k)), 0))
    add(p, "body", (0.15 * f, 0, 0.1 * f), (0, 0, 0), (1.0 + 0.15 * f, sq, 1.0 + 0.15 * f))
    for sd, s_ in (("L", 1), ("R", -1)):
        for k2 in range(3):
            add(p, "leg%d.%s" % (k2, sd), (0.0, 0.0, 1.0 * s_ * f))
            add(p, "shin%d.%s" % (k2, sd), (0.0, 0.0, -0.4 * s_ * f))
        for k2 in range(2):
            add(p, "wing%d.%s" % (k2, sd), (0.0, 0.0, -s_ * 0.6 * f))
    return p

print("[art] hundun: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/hundun.glb", {"idle": (T, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=12, dist=0.35, strength=0.5)
