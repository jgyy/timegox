"""Hundun, the Faceless Chaos (final boss of Part V; the Faceless Spawn and the Beast of the Tangled
Warp wear the same shape).

After the Classic of Mountains and Seas (Xi Shan Jing, the god Dijiang of Mount Tian, whom the
commentaries make Hundun; Strassberg, "A Chinese Bestiary"): "its form is like a yellow sack, red as
cinnabar fire; it has six feet and four wings; it is a muddled thing without face or eyes, and it
knows singing and dancing."  So: a plump sack of a body, full at the bottom and gathered at the top
into a knot tied with a cord, tongues of cinnabar fire escaping from its folds; no face at all -
the front is smooth, blank hide; seams of fire glowing through it.  Four feathered wings, a big pair and a small pair, each an arm with the long
primaries fanned from the wrist, the secondaries and two rows of coverts over them, held up as if
dancing; six short, stout legs with plump thighs, scaled bird's shanks and three clawed toes forward
and one back, standing on tiptoe.  The hide takes the enemy's colour (not tamed: the god is as
bright as fire), the wings the secondary, the fire the accent.
Run: blender --background --python art/monsters/hundun.py  ->  assets/monsters/hundun.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
import arthropod as X  # noqa: E402
import serpentine as S  # noqa: E402
from creature import zero_pose  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from sculpt import fbm3, morph_sphere, smooth  # noqa: E402
from kit import CRYSTAL, HAIR, MAT_GLOW, V, Builder, Rig, env  # noqa: E402
from creature import Walker, add  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(13)
C = V(0, 1.12, 0)
RX, RY, RZ = 0.7, 0.62, 0.66
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", C + V(0, -0.4, 0), C + V(0, 0.5, 0), "root")
# where a face should be (the game's "head"): the whirl turns under the hide there
r.bone("head", C + V(0, 0.08, 0.45), C + V(0, 0.08, 0.72), "body")
r.bone("swirl", C + V(0, 0.08, 0.6), C + V(0, 0.08, 0.9), "head")
WING_ROOT = {}
for s, sd in ((1, "L"), (-1, "R")):
    for k, (z, y, span, rise, back) in enumerate(((0.16, 0.34, 0.95, 0.62, 0.22), (-0.26, 0.2, 0.7, 0.36, 0.42))):
        root = C + V(0.42 * s, y, z)
        tip = root + V(span * s, rise, -back)
        r.bone("wing%d.%s" % (k, sd), root, tip, "body")
        WING_ROOT[(k, sd)] = (root, tip, s)
LEGS = []
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(3):
        z = 0.34 - k * 0.34
        hip = C + V(0.36 * s, -0.4, z * 0.92)
        knee = hip + V(0.17 * s, -0.25, 0.08 - 0.04 * k)
        foot = V(knee.x + 0.05 * s, 0.06, knee.z - 0.05)
        r.bone("leg%d.%s" % (k, sd), hip, knee, "body")
        r.bone("shin%d.%s" % (k, sd), knee, foot, "leg%d.%s" % (k, sd))
        LEGS.append((k, sd, s, hip, knee, foot))

b = Builder("hundun")


# ---------------------------------------------------------------- the sack
def sack(d):
    th = math.atan2(d.x, d.z)
    y = d.y
    k = 1.0 + 0.06 * smooth(0.1, -0.7, y)                       # full at the bottom, like a sack of grain
    k *= 1.0 - 0.58 * smooth(0.5, 0.97, y)                      # gathered at the top
    # the folds drawn together into the knot
    fold = 0.5 + 0.5 * math.cos(th * 7.0 + 0.6 * math.sin(th * 3.0))
    k *= 1.0 - 0.09 * smooth(0.25, 0.85, y) * fold
    k *= 1.0 + 0.05 * (fbm3((d.x * 2.0, d.y * 2.0, d.z * 2.0), 2, 9) - 0.5)
    p = V(d.x * RX * k, y * RY, d.z * RZ * k)
    if y < -0.6:
        p.y = -RY * (0.6 + 0.4 * (1.0 - math.cos(math.pi * 0.5 * (-y - 0.6) / 0.4)) * 0.75)    # sits a little flat
    if y > 0.85:
        p.y += 0.08 * smooth(0.85, 1.0, y)                        # the knot
    return p


def hide(lp, d):
    th = math.atan2(d.x, d.z)
    y = d.y
    v = 0.66 + 0.22 * smooth(0.3, -0.8, y) * smooth(-0.6, 0.5, d.z)      # paler low on the front
    v -= 0.12 * smooth(0.2, 0.8, y)                                       # darker up into the folds
    fold = 0.5 + 0.5 * math.cos(th * 7.0 + 0.6 * math.sin(th * 3.0))
    v *= 1.0 - 0.22 * smooth(0.25, 0.85, y) * (1.0 - fold)
    v *= 0.94 + 0.12 * fbm3((d.x * 6.0, d.y * 6.0, d.z * 6.0), 2, 2)
    return X.grey(v)


morph_sphere(b, C, sack, hide, cls=X.CHITIN, bone="body", seg=48, rings=32, tint_fn=lambda p, d: 1.0)
# the cord that ties the sack, and the knot
b.cur_pal = 0.5
top = C + V(0, RY * 0.97, 0)
ring = [top + V(math.cos(a) * 0.18, -0.03 + 0.012 * math.sin(a * 3), math.sin(a) * 0.18) for a in [i / 16 * 2 * math.pi for i in range(17)]]
b.tube(ring, [0.035] * 17, X.grey(0.75), cls=X.CHITIN, bone="body", seg=8, cap0=False, cap1=False, tint=1.0)
b.cur_pal = 0.0

# the two ends of the cord hang down the back of the sack
b.cur_pal = 0.5
for s2 in (1, -1):
    c0 = top + V(0.12 * s2, -0.04, -0.12)
    b.tube(A.catmull([c0, c0 + V(0.06 * s2, -0.08, -0.08), c0 + V(0.07 * s2, -0.22, -0.13), c0 + V(0.04 * s2, -0.34, -0.12)], 4),
           [0.03 - 0.0015 * i for i in range(13)], X.grey(0.75), cls=X.CHITIN, bone="body", seg=8, tint=1.0)
b.cur_pal = 0.0
# ---------------------------------------------------------------- cinnabar fire: tongues escaping from the folds, seams in the hide
b.cur_pal = 1.0
for k in range(8):
    a = k / 8 * 2 * math.pi + 0.3
    out = V(math.sin(a), 0.0, math.cos(a))
    ln = 0.34 + 0.1 * math.sin(k * 2.3)
    d = V(out.x * 0.5, 0.86, out.z * 0.5).normalized()
    base = C + sack(d) * 0.98
    side = out.cross(V(0, 1, 0))
    flick = 1.0 if k % 2 else -1.0
    # a tongue of fire licking up and out, flickering to one side and back
    pts = [base, base + V(0, ln * 0.3, 0) + out * ln * 0.22, base + V(0, ln * 0.58, 0) + out * ln * 0.3 + side * ln * 0.14 * flick,
           base + V(0, ln * 0.82, 0) + out * ln * 0.22 - side * ln * 0.06 * flick, base + V(0, ln, 0) + out * ln * 0.3 + side * ln * 0.08 * flick]
    S.flame(b, pts, 0.07, side, (1.0, 1.0, 1.0), (1.0, 1.0, 0.92), bone="body", thick=0.3, cls=CRYSTAL, mat=MAT_GLOW, widest=0.22)
for k in range(7):
    a0 = rnd.uniform(0, 2 * math.pi)
    pts = []
    for i in range(9):
        a = a0 + i * 0.2
        y = -0.55 + i * 0.12 + 0.08 * math.sin(i + k)
        d = V(math.sin(a) * math.sqrt(max(0.0, 1.0 - y * y)), y, math.cos(a) * math.sqrt(max(0.0, 1.0 - y * y)))
        pts.append(C + sack(d.normalized()) * 1.004)
    b.tube(pts, [0.006, 0.012, 0.016, 0.016, 0.016, 0.014, 0.012, 0.009, 0.004], (1.0, 1.0, 1.0), cls=CRYSTAL, bone="body", mat=MAT_GLOW, seg=5, tint=1.0)
# and no face at all: the front of the sack is smooth, blank hide
b.cur_pal = 0.0

# ---------------------------------------------------------------- four feathered wings (the secondary colour)
b.cur_pal = 0.5
for (k, sd), (root, tip, s) in WING_ROOT.items():
    wb = "wing%d.%s" % (k, sd)
    span = (tip - root)
    sdir = span.normalized()
    elbow = root + span * 0.45 + V(0, 0.06, 0.04)
    wrist = root + span * 0.8
    # the arm: a feathered leading edge from the shoulder through the wrist
    b.tube(A.catmull([root, elbow, wrist, tip], 4), [0.075, 0.07, 0.06, 0.05, 0.045, 0.04, 0.035, 0.03, 0.026, 0.022, 0.018, 0.014, 0.01],
           X.grey(0.82), cls=HAIR, bone=wb, seg=8, tint=1.0)
    down = V(0, -1, 0)
    back = V(0, 0, -1)
    nrm = sdir.cross(back).normalized()
    if nrm.y < 0:
        nrm = -nrm
    # primaries fanned from the wrist, secondaries along the forearm, coverts over their roots
    sc = 1.0 if k == 0 else 0.75
    for row, (n, ln, shd, t0, t1) in enumerate(((10, 0.62, 0.66, 0.55, 1.0), (10, 0.46, 0.74, 0.1, 0.62), (11, 0.28, 0.84, 0.08, 0.96), (9, 0.16, 0.9, 0.1, 0.9))):
        for f in range(n):
            u = f / (n - 1)
            t = t0 + (t1 - t0) * u
            base = root.lerp(tip, t) + nrm * (0.012 * row)
            if row == 0:
                # the primaries fan out round the wrist, the outermost longest
                ang = -0.25 + 1.25 * u
                dv = (sdir * math.sin(ang) + (down * 0.55 + back * 0.85) * math.cos(ang)).normalized()
                ln2 = ln * sc * (0.75 + 0.35 * u)
            else:
                dv = (down * 0.5 + back * 0.85 + sdir * 0.15 * u).normalized()
                ln2 = ln * sc * (0.85 + 0.2 * u)
            A.blade(b, base, base + dv * ln2, (0.19 - 0.03 * row) * sc, X.grey(shd), col_tip=X.grey(min(1.0, shd + 0.2)), side=sdir, bone=wb, curl=0.05,
                    thick=0.1, tint=1.0, steps=4, seg=6, point=0.25 if row == 0 else 0.1)
b.cur_pal = 0.0

# ---------------------------------------------------------------- six legs: plump thighs, scaled shanks, clawed toes
for k, sd, s, hip, knee, foot in LEGS:
    lg, sn = "leg%d.%s" % (k, sd), "shin%d.%s" % (k, sd)
    c = Clay(0.02, "hundun_leg%d%s" % (k, sd))
    c.chain([hip + V(-0.08 * s, 0.1, 0.0), hip, knee], [0.14, 0.13, 0.08], bones=limb_weights([lg, lg]), tag="thigh", t0=0.0, t1=2.0)
    c.ellipsoid(hip.lerp(knee, 0.4), (0.12, 0.13, 0.115), rot=A.frame_m(knee - hip), bones={lg: 1.0}, tag="thigh")
    c.build(b, lambda p, info: X.grey(0.72), cls=X.CHITIN, tint_fn=lambda p, info: 1.0)
    # the shank: a bird's scaled tarsus, plates down its front
    sh_dir = (foot - knee).normalized()
    out = V(s, 0.0, 0.0)
    X.segment(b, knee - sh_dir * 0.04, foot + V(0, 0.04, 0), 0.058, 0.058, bone=sn, up=V(0, 0, 1), neck=0.05, swell=0.0, taper=0.25, rim=0.0, col=0.66,
              joint=0.2, n=12, rings=10, belly=0.0, back=0.0)
    for q in range(5):
        pq = knee.lerp(foot + V(0, 0.04, 0), 0.12 + q * 0.17) + V(0, 0, 0.05 - 0.005 * q)
        b.ellipsoid(pq, (0.048 - 0.004 * q, 0.026, 0.018), X.grey(0.58), cls=X.CHITIN, bone=sn, tint=1.0, seg=10, rings=6)
    # three toes forward and one back, each ending in a hooked claw; it stands on tiptoe
    f0 = foot + V(0, 0.03, 0)
    for t_ in range(4):
        a = (t_ - 1) * 0.5 if t_ < 3 else math.pi
        dv = V(math.sin(a) * 0.8 + 0.15 * s, 0.0, math.cos(a)).normalized()
        ln = 0.13 if t_ < 3 else 0.07
        tip = f0 + dv * ln - V(0, 0.03, 0)
        X.segment(b, f0, tip, 0.024, 0.02, bone=sn, up=V(0, 1, 0), neck=0.1, swell=0.15, taper=0.3, rim=0.0, col=0.62, joint=0.2, n=10, rings=6)
        A.claw(b, tip - dv * 0.01, dv - V(0, 0.3, 0), 0.06, 0.016, sn, hook=0.8, col0="3a2018", col1="f0e4d0")

T = 3.0


def idle(t):
    w = 2 * math.pi / T
    f = math.sin(t * w * 2)
    pulse = 1.0 + 0.03 * math.sin(t * w)
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, math.sin(t * w) * 0.06, 0))
    p["body"] = ((math.sin(t * w) * 0.05, math.sin(t * w + 0.8) * 0.12, 0), (0, 0, 0), (pulse, 2.0 - pulse, pulse))
    p["swirl"] = ((0, 0, t * w), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        for k in range(2):
            p["wing%d.%s" % (k, sd)] = ((0, 0, -s * f * (0.4 - k * 0.1)), (0, 0, 0))
        for k in range(3):
            ph = t * w + k * 1.2 + (0 if s > 0 else math.pi)
            p["leg%d.%s" % (k, sd)] = ((math.sin(ph) * 0.12, 0, s * 0.05), (0, 0, 0))
            p["shin%d.%s" % (k, sd)] = ((0.06 + math.sin(ph + 1) * 0.08, 0, 0), (0, 0, 0))
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
    add(p, "root", (0, 0, 0), (0, -0.48 * f + 0.04 * math.sin(math.pi * smooth(0.7, 0.9, k)), 0))
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
