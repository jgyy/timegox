"""Phoenix / great bird (Ash Phoenix, Thunder Roc, Garden Crane, Jade Emperor of Ruin ...).
A hovering bird with two-bone wings of layered feathers, a crest, a hooked beak, tucked talons and
long trailing tail plumes on a three-bone chain.
Run: blender --background --python art/monsters/phoenix.py  ->  assets/monsters/phoenix.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import catmull, chain_weights, claws, eyes, zero_pose  # noqa: E402
from kit import CLOTH, HAIR, METAL, V, Builder, Rig, env  # noqa: E402

kit.reset()
BODY = V(0, 1.45, 0)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", BODY + V(0, 0, -0.25), BODY + V(0, 0.05, 0.2), "root")
r.bone("neck", BODY + V(0, 0.05, 0.2), BODY + V(0, 0.35, 0.36), "body")
r.bone("head", BODY + V(0, 0.35, 0.36), BODY + V(0, 0.42, 0.62), "neck")
for s, sd in ((1, "L"), (-1, "R")):
    sh = BODY + V(0.14 * s, 0.12, 0.08)
    el = sh + V(0.55 * s, 0.08, -0.08)
    tp = el + V(0.75 * s, -0.02, -0.18)
    r.bone("wing.%s" % sd, sh, el, "body")
    r.bone("wing2.%s" % sd, el, tp, "wing.%s" % sd)
    r.bone("leg.%s" % sd, BODY + V(0.08 * s, -0.15, 0.0), BODY + V(0.09 * s, -0.42, 0.06), "body")
TAIL = [BODY + V(0, -0.02, -0.28), BODY + V(0, -0.12, -0.7), BODY + V(0, -0.32, -1.15), BODY + V(0, -0.6, -1.55)]
for i in range(3):
    r.bone("tail%d" % i, TAIL[i], TAIL[i + 1], "body" if i == 0 else "tail%d" % (i - 1))

b = Builder("phoenix")
# body and breast
b.ellipsoid(BODY, (0.22, 0.24, 0.36), (0.8, 0.8, 0.8), cls=CLOTH, bone="body", tint=1.0, seg=18, rings=12, col2=(1.0, 1.0, 1.0))
b.ellipsoid(BODY + V(0, 0.02, 0.18), (0.17, 0.2, 0.18), (1.0, 1.0, 1.0), cls=CLOTH, bone={"body": 0.6, "neck": 0.4}, tint=0.75, seg=14, rings=8)
# neck and head
b.tube([BODY + V(0, 0.05, 0.2), BODY + V(0, 0.22, 0.3), BODY + V(0, 0.36, 0.38)], [0.12, 0.09, 0.085], (0.85, 0.85, 0.85), bones=[{"body": 0.5, "neck": 0.5}, "neck", {"neck": 0.4, "head": 0.6}], tint=1.0, seg=12)
H = BODY + V(0, 0.4, 0.42)
b.ellipsoid(H, (0.1, 0.1, 0.13), (0.9, 0.9, 0.9), bone="head", tint=1.0, seg=14, rings=10)
b.cone(H + V(0, -0.01, 0.17), 0.045, 0.16, "f0c040", cls=METAL, bone="head", seg=10, rot=(math.pi / 2 + 0.2, 0, 0))
b.cone(H + V(0, -0.035, 0.14), 0.03, 0.1, "d8a030", cls=METAL, bone="head", seg=8, rot=(math.pi / 2 + 0.5, 0, 0))
eyes(b, H + V(0, 0.03, 0.07), 0.065, 0.026, iris="ff6020", bone="head", slit=False, glow=True, rot_y=0.9, h=0.9)
# crest plumes sweeping back
for k in range(5):
    a = (k - 2) * 0.18
    root = H + V(math.sin(a) * 0.05, 0.08, -0.02)
    b.leaf(root, root + V(math.sin(a) * 0.15, 0.25 - abs(k - 2) * 0.04, -0.3), 0.045, (0.7, 0.7, 0.7), side=(1, 0, 0), cls=HAIR, bone="head", tint=1.0, col_tip=(1.0, 1.0, 1.0))
    b.ball(root + V(math.sin(a) * 0.15, 0.25 - abs(k - 2) * 0.04, -0.3), 0.022, "fff0a0", cls=0.5, bone="head", seg=8, rings=5, mat=kit.MAT_GLOW)
# wings: three rows of feathers along the two wing bones
for s, sd in ((1, "L"), (-1, "R")):
    w1 = "wing.%s" % sd
    w2 = "wing2.%s" % sd
    sh, el, tp = r.head(w1), r.tail(w1), r.tail(w2)
    b.tube([sh, el, tp], [0.07, 0.045, 0.015], (0.8, 0.8, 0.8), bones=[{"body": 0.3, w1: 0.7}, {w1: 0.5, w2: 0.5}, w2], tint=1.0, seg=8)
    for row, (ln, shd) in enumerate(((0.55, 0.55), (0.42, 0.75), (0.28, 0.95))):
        n = 12
        for k in range(n):
            u = k / (n - 1)
            base = sh.lerp(el, u * 2) if u < 0.5 else el.lerp(tp, (u - 0.5) * 2)
            bone = w1 if u < 0.42 else (w2 if u > 0.58 else {w1: 0.5, w2: 0.5})
            length = ln * (0.7 + 0.6 * u) * (1.0 - 0.25 * row)
            tipp = base + V(0.12 * s * u, -0.04 - row * 0.02, -length)
            b.leaf(base + V(0, 0.01 * row, -0.02 * row), tipp, 0.06 + 0.02 * u, (shd * 0.75, shd * 0.75, shd * 0.75), side=(1, 0, 0), cls=HAIR, bone=bone, tint=1.0, col_tip=(1.0, 1.0, 1.0) if row == 0 else (shd, shd, shd), curl=0.06)
    # talons
    lg = "leg.%s" % sd
    b.tube([r.head(lg), r.tail(lg)], [0.04, 0.02], "c89030", cls=METAL, bone=lg, seg=8)
    claws(b, r.tail(lg) + V(0, -0.02, 0.03), True, lg, n=3, spread=0.03, length=0.08, col="403020")
# tail plumes: long ribbons with glowing eye spots at their tips
pts, idx = catmull(TAIL, per=4)
for k in range(7):
    a = (k - 3) * 0.16
    pp = [p + V(math.sin(a) * (0.05 + 0.4 * f / 3), 0.02 * abs(k - 3), 0) for p, f in zip(pts, idx)]
    ws = [0.03 + 0.05 * (f / 3) for f in idx]
    b.ribbon(pp, ws, (1, 0, 0) if abs(a) < 0.2 else (math.cos(a), 0, -math.sin(a) * 0.3), (0.8, 0.8, 0.8), cls=HAIR, bones=[chain_weights("tail", f, 3) for f in idx], tint=1.0, col_end=(1.0, 1.0, 1.0))
    b.ellipsoid(pp[-1] + V(0, 0.01, 0.05), (0.05, 0.015, 0.06), "fff4b0", cls=0.5, bone="tail2", seg=10, rings=5, mat=kit.MAT_GLOW)

FLAP = 1.0


def idle(t, strength=1.0):
    w = 2 * math.pi / FLAP
    f = math.sin(t * w)
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, -f * 0.08, 0))
    p["body"] = ((0.05 * f, 0, 0), (0, 0, 0))
    p["neck"] = ((-0.05 * f, math.sin(t * w / 3) * 0.15, 0), (0, 0, 0))
    p["head"] = ((0.05 * f, math.sin(t * w / 3) * 0.1, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["wing.%s" % sd] = ((0.1 * f, 0, -s * f * 0.6 * strength), (0, 0, 0))
        p["wing2.%s" % sd] = ((0, -s * 0.1, -s * math.sin(t * w - 0.9) * 0.45 * strength), (0, 0, 0))
        p["leg.%s" % sd] = ((0.6, 0, 0), (0, 0, 0))
    for i in range(3):
        p["tail%d" % i] = ((math.sin(t * w - i * 0.8) * 0.08, math.sin(t * w / 2 - i) * 0.06, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    dive = math.sin(min(1.0, k * 1.4) * math.pi)
    p = idle(t * 2, 1.2)
    p["root"] = ((0, 0, 0), (0, -0.3 * dive, 0.5 * dive))
    p["body"] = ((0.4 * dive, 0, 0), (0, 0, 0))
    p["neck"] = ((0.3 * dive - 0.3 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["wing.%s" % sd] = ((-0.3 * e, 0.5 * s * e, -s * 0.9 * e), (0, 0, 0))
        p["leg.%s" % sd] = ((-0.9 * dive, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(t, 0.4)
    p["root"] = ((0, 0, 0), (0, 0.1 * e, -0.3 * e))
    p["body"] = ((-0.35 * e, 0, 0.15 * e), (0, 0, 0))
    p["neck"] = ((-0.4 * e, 0.3 * e, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(t, 0.3)
    p["root"] = ((0, 0, 0), (0, 0.2 * e, 0))
    p["body"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["neck"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["wing.%s" % sd] = ((0.2 * e, 0, s * 0.9 * e), (0, 0, 0))
        p["wing2.%s" % sd] = ((0, 0, s * 0.5 * e), (0, 0, 0))
    return p


print("[art] phoenix: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/phoenix.glb", {"idle": (FLAP * 3, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.4)
