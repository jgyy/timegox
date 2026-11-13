"""Plant: an old tree that has learned to walk (the Ancient Bamboo Spirit, the Ten-Thousand-Year
Peach Tree, the Old Mulberry, the Empress of the Red Lilies, Leaf Sprites, Poison Vines ...).

Designed silhouette first, after the tree spirits of Chinese tales and the pines of Chinese
painting and penjing: a trunk-body twisting up in an S and leaning forward, on two root-legs that
split into gripping roots; long branch-arms hanging to the knees and ending in twig claws; and a
crown of four flat, cloud-shaped pads of foliage held out on gnarled branches, the highest of them
the highest point of the figure.  The bark is furrowed into long plates by deep, dark fissures
(``elemental.bark``) so it reads as bark from far off; the foliage is in masses, light on top and
dark beneath (``elemental.leaf_pad``), with a few blossoms in the accent colour.  One focal point:
a face in the bark - two knot-hole eyes glowing under a heavy brow, a split for a mouth.
The foliage takes the enemy's colour, the bark a dark shade of it, the eyes and blossoms its accent.
Run: blender --background --python art/monsters/plant.py  ->  assets/monsters/plant.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import Walker, add, smooth, zero_pose  # noqa: E402
from elemental import bark, leaf_clump  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, MAT_PLAIN, SKIN, WOOD, V, Builder, Rig, env  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(11)

BARK = (0.74, 0.6, 0.47)       # a brown, half tinted towards the dark shade of the enemy's colour
BARK_PAL, BARK_TINT = 0.8, 0.5

HIP = {s: V(0.16 * s, 0.66, 0.0) for s in (1, -1)}
KN = {s: V(0.27 * s, 0.38, 0.07) for s in (1, -1)}
AN = {s: V(0.31 * s, 0.09, 0.0) for s in (1, -1)}
SH = {s: V(0.2 * s, 1.47, 0.05) for s in (1, -1)}
EL = {s: V(0.52 * s, 1.2, 0.13) for s in (1, -1)}
WR = {s: V(0.63 * s, 0.86, 0.23) for s in (1, -1)}
# the crown: branches from the top of the trunk out to flat pads of foliage (centre, size, tilt)
PADS = [
    (V(0.08, 2.4, -0.1), (0.36, 0.29, 0.33), 0),
    (V(-0.64, 2.14, -0.02), (0.32, 0.25, 0.3), 1),
    (V(0.68, 2.08, 0.06), (0.32, 0.24, 0.3), 2),
    (V(-0.26, 2.0, -0.52), (0.29, 0.23, 0.27), 3),
    (V(0.34, 2.14, 0.4), (0.25, 0.2, 0.23), 4),
    (V(-0.34, 2.36, 0.18), (0.27, 0.22, 0.25), 5),
]
FORK = V(0.0, 1.78, 0.0)

r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("hips", (0, 0.6, 0), (0, 0.9, 0.0), "root")
r.bone("trunk", (0, 0.9, 0.0), (0, 1.6, 0.06), "hips")
r.bone("head", (0, 1.3, 0.16), (0, 1.44, 0.24), "trunk")
r.bone("crown", (0, 1.6, 0.06), (0, 2.0, 0.0), "trunk")
for k, (pc, _, _) in enumerate(PADS):
    r.bone("pad%d" % k, FORK + (pc - FORK) * 0.35, pc, "crown")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm." + sd, SH[s], EL[s], "trunk")
    r.bone("fore." + sd, EL[s], WR[s], "arm." + sd)
    r.bone("hand." + sd, WR[s], WR[s] + V(0.04 * s, -0.22, 0.08), "fore." + sd)
    r.bone("thigh." + sd, HIP[s], KN[s], "hips")
    r.bone("shin." + sd, KN[s], AN[s], "thigh." + sd)
    # the gripping roots hang from the ankle on a bone of their own, so they stay on the ground
    r.bone("foot." + sd, AN[s], AN[s] + V(0, -0.05, 0.2), "shin." + sd)

b = Builder("plant")


def trunk_w(p):
    y = p.y
    if y < 0.84:
        return {"hips": 1.0}
    if y < 1.0:
        k = (y - 0.84) / 0.16
        return {"hips": 1.0 - k, "trunk": k}
    if y < 1.58:
        return {"trunk": 1.0}
    if y < 1.72:
        k = (y - 1.58) / 0.14
        return {"trunk": 1.0 - k, "crown": k}
    return {"crown": 1.0}


def chain_w(names, pts):
    """Weights along a chain of bones for a limb built through the joint points `pts`."""
    def fn(p):
        best = None
        for i in range(len(names)):
            a, c = V(pts[i]), V(pts[i + 1])
            ab = c - a
            t = max(0.0, min(1.0, (p - a).dot(ab) / max(1e-9, ab.length_squared)))
            d = (a + ab * t - p).length
            if best is None or d < best[0]:
                best = (d, i, t)
        _, i, t = best
        if t < 0.15 and i > 0:
            k = 0.5 + 0.5 * t / 0.15
            return {names[i - 1]: 1.0 - k, names[i]: k}
        if t > 0.85 and i < len(names) - 1:
            k = 0.5 * (t - 0.85) / 0.15
            return {names[i]: 1.0 - k, names[i + 1]: k}
        return {names[i]: 1.0}
    return fn


def wood(pts, radii, bone_fn, seed, plates=7, **kw):
    return bark(b, pts, radii, bone_fn, seed=seed, plates=plates, col=BARK, tint=BARK_TINT, pal=BARK_PAL, **kw)


# ---------------------------------------------------------------- the trunk: an S of furrowed bark flaring at its foot
TRUNK = [V(0.0, 0.5, -0.02), V(0.02, 0.8, 0.0), V(-0.03, 1.12, 0.06), V(0.0, 1.42, 0.08), V(0.04, 1.66, 0.03), V(0.01, 1.86, -0.03)]


def gauss(x):
    return math.exp(-x * x)


# the face is carved into the bark itself: a heavy brow ridge, its inner ends drawn down (an old,
# cross face), deep sockets, a knot of a nose, cheekbones and a crooked split of a mouth
EYE_Y, MOUTH_Y = 1.345, 1.17


def face_marks(p, out):
    front = smooth(0.25, 0.75, out.z)
    ax = abs(p.x)
    brow = gauss((p.y - (1.415 + 0.3 * ax)) / 0.04) * gauss(p.x / 0.17)
    socket = gauss(math.hypot(ax - 0.088, (p.y - EYE_Y) * 1.15) / 0.042)
    nose = gauss(p.x / 0.03) * smooth(1.22, 1.27, p.y) * (1.0 - smooth(1.36, 1.41, p.y))
    cheek = gauss(math.hypot(ax - 0.14, p.y - 1.26) / 0.04)
    my = MOUTH_Y + 0.12 * p.x
    mouth = gauss((p.y - my) / 0.016) * gauss(p.x / 0.095)
    lip = gauss((p.y - my + 0.035) / 0.02) * gauss(p.x / 0.09)
    region = gauss(math.hypot(p.x / 0.24, (p.y - 1.3) / 0.25)) * front
    return front, brow, socket, nose, cheek, mouth, lip, region


def carve(p, out):
    front, brow, socket, nose, cheek, mouth, lip, region = face_marks(p, out)
    off = 0.06 * brow + 0.026 * nose + 0.016 * cheek + 0.014 * lip - 0.055 * socket - 0.034 * mouth
    return out * (off * front), min(1.0, region * 1.6)


def face_shade(p, col):
    front, brow, socket, nose, cheek, mouth, lip, region = face_marks(p, V(p.x, 0.0, max(0.0, p.z - 0.05)).normalized() if p.z > 0.05 else V(0, 0, -1))
    k = 1.0 - 0.8 * socket * front - 0.85 * mouth * front + 0.1 * brow * front
    return (col[0] * k, col[1] * k, col[2] * k)


wood(TRUNK, [0.36, 0.27, 0.25, 0.235, 0.18, 0.11], trunk_w, 3, plates=11, depth=0.22, twist=0.35, n=44, per=9, carve=carve, shade=face_shade)
# burls and knots: the old wounds of the tree
for (x, y, z, rad) in ((-0.2, 0.95, 0.12, 0.07), (0.21, 1.58, -0.08, 0.06), (-0.12, 0.75, -0.22, 0.08)):
    old = b.cur_pal
    b.cur_pal = BARK_PAL
    b.ellipsoid(V(x, y, z), (rad, rad * 0.85, rad * 0.7), (BARK[0] * 0.95, BARK[1] * 0.95, BARK[2] * 0.95), cls=WOOD, bone=trunk_w(V(x, y, z)),
                tint=BARK_TINT, rot=(0, math.atan2(x, z), 0), seg=10, rings=7)
    b.ellipsoid(V(x, y, z) + V(x, 0, z).normalized() * rad * 0.62, (rad * 0.45, rad * 0.4, rad * 0.2), "1c120c", cls=WOOD, bone=trunk_w(V(x, y, z)),
                rot=(0, math.atan2(x, z), 0), seg=8, rings=5)
    b.cur_pal = old

# ---------------------------------------------------------------- root-legs, and the roots they grip the ground with
for s, sd in ((1, "L"), (-1, "R")):
    th, sn = "thigh." + sd, "shin." + sd
    leg = [HIP[s] + V(-0.05 * s, 0.08, 0.0), HIP[s], KN[s], AN[s]]
    wood(leg, [0.16, 0.15, 0.12, 0.1], chain_w([th, th, sn], leg), 20 + s, plates=6, depth=0.2, twist=0.6, n=18)
    for k, (dx, dz, ln) in enumerate(((0.55 * s, 0.85, 0.32), (0.05 * s, 1.0, 0.36), (-0.45 * s, 0.85, 0.28), (0.25 * s, -1.0, 0.24))):
        dv = V(dx, 0.0, dz).normalized()
        a = AN[s] + V(0, 0.02, 0)
        toe = [a, a + dv * ln * 0.4 + V(0, 0.01, 0), a + dv * ln * 0.78 - V(0, 0.04, 0), a + dv * ln - V(0, 0.09, 0)]
        wood(toe, [0.075, 0.06, 0.04, 0.012], lambda p, sd=sd: {"foot." + sd: 1.0}, 30 + k + 5 * s, plates=4, depth=0.18, twist=0.4, n=12, per=2, cap0=False)

# ---------------------------------------------------------------- branch-arms with twig claws
for s, sd in ((1, "L"), (-1, "R")):
    arm, fore, hand = "arm." + sd, "fore." + sd, "hand." + sd
    pts = [SH[s] - V(0.12 * s, -0.03, 0.0), SH[s], EL[s], WR[s]]
    wood(pts, [0.1, 0.095, 0.072, 0.055], chain_w([arm, arm, fore], pts), 40 + s, plates=6, depth=0.2, twist=1.0, n=16)
    # a broken-off twig at the elbow
    wood([EL[s], EL[s] + V(0.1 * s, 0.1, -0.06), EL[s] + V(0.16 * s, 0.2, -0.06)], [0.03, 0.022, 0.008], lambda p, fore=fore: {fore: 1.0},
         44 + s, plates=3, n=8, per=2, cap0=False)
    # four long twig fingers, knobbly at the knuckles, curling in like claws
    for f, (ax, az) in enumerate(((0.55, 0.55), (0.2, 0.95), (-0.15, 1.0), (-0.55, 0.6))):
        dv = V(ax * s, -1.6, az).normalized()
        side = V(ax * s, 0.0, az).normalized()
        w0 = WR[s] + V(0.0, -0.02, 0.0)
        tw = [w0, w0 + dv * 0.1, w0 + dv * 0.2 + side * 0.03, w0 + dv * 0.27 + side * 0.07 + V(0, 0.02, 0)]
        wood(tw, [0.03, 0.024, 0.016, 0.004], lambda p, hand=hand: {hand: 1.0}, 50 + f + 4 * s, plates=3, n=8, per=2, cap0=False, depth=0.12)

# ---------------------------------------------------------------- the crown: gnarled branches holding flat pads of foliage
for k, (pc, size, tilt) in enumerate(PADS):
    pad = "pad%d" % k
    # a gnarled branch: out and up with a kink, so the crown is held up by visible limbs
    out = V(pc.x - FORK.x, 0.0, pc.z - FORK.z)
    out = out.normalized() if out.length > 1e-4 else V(0, 0, 1)
    mid = FORK.lerp(pc, 0.45) + V(0.0, -0.05 + 0.03 * (k % 3), 0.0) + out.cross(V(0, 1, 0)) * (0.06 if k % 2 else -0.06)
    br = [FORK + (pc - FORK) * 0.05 - V(0, 0.06, 0), mid, pc - V(0, size[1] * 0.45, 0) - out * size[0] * 0.3]
    wood(br, [0.08, 0.055, 0.032], chain_w(["crown", pad], [br[0], br[1], br[2]]), 60 + k, plates=5, n=12, depth=0.16, per=3, cap0=False)
    leaf_clump(b, pc, size, pad, seed=70 + k, lobes=18, flat=0.2, leaves=14, leaf=0.11, col_top=1.0, col_under=0.5, res=0.032)

# blossoms on top of the pads (the accent colour): five petals round a heart
hit = A.surface(b)
old = b.cur_pal
for k, (pc, size, tilt) in enumerate(PADS):
    for j in range(4):
        a = rnd.uniform(0, 2 * math.pi)
        rr = rnd.uniform(0.15, 0.62)
        o = pc + V(math.cos(a) * size[0] * rr, 0.8, math.sin(a) * size[2] * rr)
        h = hit(o, V(0, -1, 0), 1.0)
        if h is None:
            continue
        p, n = h
        if n.y < 0.3:
            continue
        b.cur_pal = 1.0
        up = n.normalized()
        side = up.cross(V(0, 0, 1)).normalized() if abs(up.z) < 0.9 else V(1, 0, 0)
        fwd = side.cross(up).normalized()
        for q in range(5):
            ang = q / 5 * 2 * math.pi + j
            dv = side * math.cos(ang) + fwd * math.sin(ang)
            b.ellipsoid(p + up * 0.015 + dv * 0.036, (0.034, 0.011, 0.025), (0.96, 0.96, 0.96), cls=CLOTH, bone="pad%d" % k, tint=1.0,
                        rot=(0, math.atan2(dv.x, dv.z), 0), seg=8, rings=4)
        b.cur_pal = old
        b.ball(p + up * 0.022, 0.016, "ffe070", cls=CRYSTAL, bone="pad%d" % k, seg=6, rings=4)

# ---------------------------------------------------------------- the face in the bark: eyes glowing deep in their sockets
for sx in (1, -1):
    h = hit(V(0.088 * sx, EYE_Y, 1.0), V(0, 0, -1), 2.0)
    p, n = (h[0], h[1]) if h is not None else (V(0.088 * sx, EYE_Y, 0.28), V(0, 0, 1))
    b.ellipsoid(p - n * 0.012, (0.036, 0.03, 0.02), "0e0906", cls=SKIN, bone="head", rot=(0, 0.3 * sx, -0.2 * sx), seg=12, rings=7, mat=MAT_PLAIN)
    b.cur_pal = 1.0
    b.ellipsoid(p + n * 0.006, (0.027, 0.02, 0.01), (1.0, 1.0, 1.0), cls=CLOTH, bone="head", tint=1.0, rot=(0, 0.3 * sx, -0.2 * sx), mat=MAT_GLOW, seg=10, rings=6)
    b.cur_pal = old

T_IDLE = 3.2


def sway(p, t, w, amp):
    """The pads and twigs move in the air a beat behind the trunk."""
    for k in range(len(PADS)):
        add(p, "pad%d" % k, (amp * 0.7 * math.sin(t * w - 0.6 - k), 0.0, amp * math.sin(t * w - 0.9 - 1.3 * k)))
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "hand." + sd, (amp * 1.5 * math.sin(t * w - 1.2), 0.0, s * amp * math.sin(t * w - 0.4)))


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    add(p, "hips", (0.0, 0.03 * math.sin(t * w), 0.0))
    add(p, "trunk", (0.06 + math.sin(t * w) * 0.025, math.sin(t * w + 1.2) * 0.06, math.sin(t * w) * 0.03))
    add(p, "crown", (math.sin(t * w - 0.6) * 0.04, 0, math.sin(t * w - 0.6) * 0.04))
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "arm." + sd, (math.sin(t * w + s) * 0.05, 0.0, s * 0.04 * math.sin(t * w)))
        add(p, "fore." + sd, (-0.1 + 0.04 * math.sin(t * w + 0.5), 0.0, 0.0))
        add(p, "thigh." + sd, (-0.06, 0, 0))
        add(p, "shin." + sd, (0.08, 0, 0))
    sway(p, t, w, 0.05)
    return p


def attack(t):
    """The branch-arms rear back and lash down and forward together."""
    k = t / 0.55
    e = env(k)
    up = math.sin(min(1.0, k / 0.42) * math.pi / 2)
    lash = smooth(0.4, 0.62, k) * (1.0 - smooth(0.8, 1.0, k))
    p = idle(0.0)
    add(p, "trunk", (-0.2 * up + 0.45 * lash, 0, 0))
    add(p, "root", (0, 0, 0), (0, 0, 0.25 * lash))
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "arm." + sd, (-1.9 * up * (1.0 - lash) - 0.5 * lash, 0, 0.3 * s * up))
        add(p, "fore." + sd, (-0.5 * up + 0.2 * lash, 0, 0))
        add(p, "hand." + sd, (0.5 * lash - 0.4 * up, 0, 0))
    sway(p, t, 14.0, 0.12 * e)
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    add(p, "trunk", (-0.25 * e, 0, 0.1 * e))
    add(p, "root", (0, 0, 0), (0, 0, -0.12 * e))
    sway(p, t, 25.0, 0.15 * e)
    return p


def cast(t):
    """The arms rise and the crown lifts and spreads its pads, drawing on the qi of the earth."""
    e = env(t / 0.6)
    p = idle(0.0)
    add(p, "crown", (-0.15 * e, 0, 0), (0, 0.06 * e, 0))
    for k in range(len(PADS)):
        add(p, "pad%d" % k, (0, 0, 0), (0, 0.05 * e, 0), (1.0 + 0.15 * e, 1.0 + 0.15 * e, 1.0 + 0.15 * e))
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "arm." + sd, (-1.2 * e, 0, 0.5 * s * e))
        add(p, "hand." + sd, (-0.4 * e, 0, 0))
    return p


T_WALK = 1.7
WALK = Walker(r, [("thigh.L", "shin.L"), ("thigh.R", "shin.R")], [0.0, 0.5], duty=0.62, sagittal=True)


def walk(t):
    """A heavy, rocking stride on the root-legs; the trunk rolls over each planted foot, the arms
    swing slowly and the pads of the crown sway after it."""
    ph = (t / T_WALK) % 1.0
    w = 2 * math.pi
    p = zero_pose(r)
    add(p, "hips", (0.04, 0.07 * math.sin(w * ph), 0.06 * math.sin(w * ph)), (0.04 * math.sin(w * ph), -0.035 * abs(math.cos(w * ph)), 0))
    add(p, "trunk", (0.1, -0.1 * math.sin(w * ph), -0.04 * math.sin(w * ph)))
    add(p, "crown", (0.04 * math.sin(w * ph * 2 - 0.8), 0, -0.05 * math.sin(w * ph - 0.6)))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm." + sd, (0.25 * s_ * math.sin(w * ph), 0, 0.04 * s_))
        add(p, "fore." + sd, (-0.12 - 0.1 * max(0.0, s_ * math.sin(w * ph)), 0, 0))
    sway(p, t, w / T_WALK, 0.06)
    p = WALK.step(p, ph, 0.42, 0.12)
    # each foot of roots turns back by what its leg has turned, so it stays flat on the ground
    for sd in ("L", "R"):
        tilt = p["root"][0][0] + p["hips"][0][0] + p["thigh." + sd][0][0] + p["shin." + sd][0][0]
        p["foot." + sd] = ((-tilt, 0.0, 0.0), (0, 0, 0))
    return p


def die(t):
    """The roots give way and the tree topples like a felled trunk; the arms and the crown droop."""
    k = min(1.0, t / 1.2)
    f = smooth(0.15, 0.75, k) ** 1.6
    p = zero_pose(r)
    # (not quite flat: the crown comes to rest on the ground and holds the trunk off it)
    a = 1.2 * f
    q = V(-0.3, 0, 0)
    R = creature.euler_g((0.2 * f, 0.0, a))
    off = q - R @ q
    add(p, "root", (0.2 * f, 0.0, a), (off.x, off.y + 0.05 * math.sin(math.pi * smooth(0.75, 0.9, k)), off.z))
    add(p, "crown", (0.25 * f, 0, 0.2 * f))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm." + sd, (0.3 * f, 0, -0.5 * s_ * f))
        add(p, "fore." + sd, (0.3 * f, 0, 0))
        add(p, "thigh." + sd, (-0.3 * f, 0, 0))
    for k2 in range(len(PADS)):
        add(p, "pad%d" % k2, (0.2 * f, 0, 0))
    return p


print("[art] plant: %d triangles" % b.tri_count())
# the bark and the foliage carry their own values (light pads above, dark beneath): no coat split
kit.finish_rigged(b, r, "monsters/plant.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  coat=False, samples=12, dist=0.22, strength=0.38, floor_y=0.0)
