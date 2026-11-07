"""Mammoth (new in Part V): a shaggy giant of the Aurora Steppe (Frost Yak, Mammoth Ancestor).
Built on art/lib/anatomy.py: high domed shoulders sloping to low haunches, a hanging belly,
pillar legs on round toenailed feet, a domed skull with a ringed four-bone trunk ending in two
fingers, curling banded tusks in their sockets, small fur-covered ears, and a two-layer coat - a
dense undercoat of clumps and long guard hairs hanging in a skirt.
Run: blender --background --python art/monsters/mammoth.py  ->  assets/monsters/mammoth.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import catmull, chain_weights, eyes, quad_rig, weights_for, zero_pose  # noqa: E402
from kit import CLOTH, HAIR, MAT_PLAIN, SKIN, STONE, V, Builder, env  # noqa: E402
from sculpt import loft, morph_sphere, prof_egg, section, smooth, strand  # noqa: E402

kit.reset()
rnd = random.Random(21)
BY = 1.25
TR = [V(0, 1.45, 1.25), V(0, 1.15, 1.42), V(0, 0.8, 1.48), V(0, 0.5, 1.45), V(0, 0.3, 1.55)]
extra = [("ear.L", (0.28, 1.75, 0.95), (0.5, 1.45, 0.9), "head"), ("ear.R", (-0.28, 1.75, 0.95), (-0.5, 1.45, 0.9), "head")]
for i in range(4):
    extra.append(("trunk%d" % i, TR[i], TR[i + 1], "head" if i == 0 else "trunk%d" % (i - 1)))
r = quad_rig(BY, 0.55, -0.55, 0.32, (0, 1.6, 0.85), (0, 1.62, 1.25), [(0, 1.35, -0.85), (0, 1.15, -1.05), (0, 0.9, -1.12)], extra=extra)
b = Builder("mammoth")
body_bones = ["pelvis", "chest", "neck", "head"] + [n for n in r.bones if n.endswith("_up.L") or n.endswith("_up.R")]
weights = weights_for(r, body_bones, sharp=3.0, k=3)
# a heavy body: high domed shoulders sloping to low haunches, a belly that hangs rather than tucks
sp = A.QuadSpec(hip_w=0.46, chest_w=0.5, chest_d=0.62, waist_d=0.55, waist_w=0.47, back_h=0.32, withers=0.2, neck_r=0.34, belly=0.08, shade=(0.5, 0.78), seed=12)
torso, spine_y = A.quad_body(b, r, sp, weights)
legs = {}
for nm in ("f", "h"):
    for sd in ("L", "R"):
        legs[nm + sd] = A.quad_leg(b, r, nm, sd, sp, spine_y, thick=1.0, paw=False, hoof=False)
        # a round elephant foot with toenails
        pw = "%s_paw.%s" % (nm, sd)
        foot = r.tail(pw) + V(0, 0.06, -0.06)
        b.lathe(V(foot.x, 0.0, foot.z), [(0.2, 0.0), (0.21, 0.05), (0.19, 0.14), (0.17, 0.2)], (0.55, 0.55, 0.55), cls=SKIN, bone=pw, seg=18, tint=1.0, folds=(9, 0.04, 0.0))
        for k in range(4):
            a = (k - 1.5) * 0.45
            b.ellipsoid(V(foot.x + math.sin(a) * 0.19, 0.05, foot.z + math.cos(a) * 0.19), (0.05, 0.045, 0.03), "e8dcc0", cls=STONE, bone=pw, seg=8, rings=5, rot=(0, a, 0))
# head: a high domed skull with a deep forehead dent, the trunk springing from it
HC = V(0, 1.72, 1.02)
morph_sphere(b, HC, lambda d: V(d.x * 0.32, d.y * 0.36, d.z * 0.32) * (1.0 + 0.12 * smooth(0.3, 1.0, d.y) - 0.06 * smooth(0.6, 1.0, d.z) * smooth(-0.2, 0.4, d.y)),
             lambda p, d: (0.55 + 0.1 * d.y,) * 3, cls=CLOTH, bone="head", seg=24, rings=16, tint_fn=lambda p, d: 1.0)
# trunk: a ringed loft tapering to a two-fingered tip
pts, idx = catmull(TR, per=5)
rings = []
for k, (p0, f) in enumerate(zip(pts, idx)):
    d = (pts[min(len(pts) - 1, k + 1)] - pts[max(0, k - 1)]).normalized()
    rr = 0.17 - 0.11 * (f / 4)
    rings.append(section(p0, d, prof_egg(rr, rr * 0.95, rr * 1.05), 14, up=V(0, 0, 1)))
loft(b, rings, (0.62, 0.62, 0.62), cls=SKIN, col_fn=lambda p, j, i: (0.58 + 0.1 * (j % 2),) * 3, bones=[chain_weights("trunk", f, 4) for f in idx], tint=1.0, cap0=False, cap1=True)
tip = pts[-1]
for s in (1, -1):
    b.cone(tip + V(0.025 * s, -0.04, 0.03), 0.025, 0.06, (0.55, 0.55, 0.55), cls=SKIN, bone="trunk3", seg=8, tint=1.0, rot=(math.pi, 0, 0))
# tusks: long curling ivory with growth bands, set in sockets
for s in (1, -1):
    tusk = [V(0.16 * s, 1.35, 1.25), V(0.22 * s, 1.05, 1.5), V(0.28 * s, 0.85, 1.85), V(0.24 * s, 0.95, 2.15), V(0.15 * s, 1.2, 2.25)]
    tp, _ = catmull(tusk, per=4)
    b.tube(tp, [0.075 - 0.065 * (k / (len(tp) - 1)) for k in range(len(tp))], "f6eed8", cls=STONE, bone="head", seg=12, cols=[("f6eed8" if k % 3 else "e0d4b8") for k in range(len(tp))])
    b.ellipsoid(V(0.16 * s, 1.37, 1.24), (0.11, 0.1, 0.1), (0.55, 0.55, 0.55), cls=SKIN, bone="head", seg=12, rings=8, tint=1.0)
eyes(b, V(0, 1.7, 1.26), 0.21, 0.03, iris="402010", bone="head", slit=False, glow=False, rot_y=1.0, h=0.8)
# small fur-covered ears (cold-adapted), with a fringe
for s, sd in ((1, "L"), (-1, "R")):
    e = "ear.%s" % sd
    b.ellipsoid(V(0.36 * s, 1.62, 0.92), (0.06, 0.18, 0.14), (0.5, 0.5, 0.5), bone=e, tint=1.0, seg=12, rings=8, rot=(0, 0, 0.3 * s))
# shaggy coat: a dense undercoat of short clumps over the body, then long guard hairs hanging
# from the back, flanks and shoulders in a skirt nearly to the knees
A.fur(b, torso, 340, 0.12, 0.05, seed=13, bone_fn=weights, min_dist=0.07, col_root=(0.42, 0.42, 0.42), col_tip=(0.7, 0.7, 0.7),
      groom=lambda p, n: (V(0, -1, -0.15) - n * V(0, -1, -0.15).dot(n)).normalized())
for k in range(150):
    z = rnd.uniform(-0.75, 0.85)
    a = rnd.uniform(-2.4, 2.4)
    rad = 0.52 + 0.06 * math.cos(z * 2)
    root = V(math.sin(a) * rad * 0.95, spine_y(z) + 0.12 + math.cos(a) * rad * 0.35 - 0.1, z)
    length = rnd.uniform(0.4, 0.75) * (1.0 if abs(a) > 0.6 else 0.6)
    tip = root + V(math.sin(a) * 0.12, -length, rnd.uniform(-0.08, 0.04))
    sh = rnd.uniform(0.45, 0.72)
    strand(b, [root, root.lerp(tip, 0.4) + V(math.sin(a) * 0.08, 0, 0), tip], 0.045, 0.006, (sh, sh, sh), col_tip=(sh * 0.8,) * 3, cls=HAIR, bone=weights(root), flat=0.45, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
# a mop of hair on the crown
for k in range(16):
    a = k / 16 * 2 * math.pi
    root = HC + V(math.sin(a) * 0.14, 0.34, math.cos(a) * 0.12)
    strand(b, [root, root + V(math.sin(a) * 0.08, 0.06, math.cos(a) * 0.06), root + V(math.sin(a) * 0.16, -0.08, math.cos(a) * 0.1 - 0.06)], 0.04, 0.004, (0.45, 0.45, 0.45), col_tip=(0.7, 0.7, 0.7), cls=HAIR, bone="head", flat=0.4, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
for nm in ("f", "h"):
    for sd, s in (("L", 1), ("R", -1)):
        up = "%s_up.%s" % (nm, sd)
        for k in range(8):
            a = k / 8 * 2 * math.pi
            root = r.head(up).lerp(r.tail(up), 0.6) + V(math.sin(a) * 0.2, 0, math.cos(a) * 0.2)
            strand(b, [root, root + V(math.sin(a) * 0.05, -0.2, math.cos(a) * 0.05), root + V(math.sin(a) * 0.07, -0.38, math.cos(a) * 0.07)], 0.04, 0.004, (0.5, 0.5, 0.5), col_tip=(0.62, 0.62, 0.62), cls=HAIR, bone=up, flat=0.4, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
for k in range(7):
    strand(b, [r.tail("tail1"), r.tail("tail1") + V((k - 3) * 0.02, -0.12, -0.03), r.tail("tail1") + V((k - 3) * 0.04, -0.28, -0.05)], 0.02, 0.003, (0.42, 0.42, 0.42), cls=HAIR, bone="tail1", flat=0.4, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)

T = 4.0


def idle(t):
    w = 2 * math.pi / T
    p = zero_pose(r)
    p["pelvis"] = ((0, 0, 0), (0, math.sin(t * w * 2) * 0.015, 0))
    p["neck"] = ((math.sin(t * w) * 0.04, math.sin(t * w * 0.5) * 0.12, 0), (0, 0, 0))
    for i in range(4):
        p["trunk%d" % i] = ((math.sin(t * w - i * 0.8) * 0.12 - 0.05, math.sin(t * w * 0.5 - i * 0.6) * 0.12, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["ear.%s" % sd] = ((0, s * math.sin(t * w * 2) * 0.25, 0), (0, 0, 0))
    p["tail0"] = ((0, math.sin(t * w * 2) * 0.3, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.7
    e = env(k)
    up = math.sin(min(1.0, k / 0.5) * math.pi / 2)
    down = max(0.0, min(1.0, (k - 0.5) / 0.2))
    p = idle(0.0)
    p["pelvis"] = ((-0.35 * up + 0.4 * down, 0, 0), (0, 0, 0.2 * down * e))
    p["neck"] = ((-0.3 * up + 0.5 * down, 0, 0), (0, 0, 0))
    for i in range(4):
        p["trunk%d" % i] = ((-0.4 * up + 0.3 * down, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up.%s" % sd] = ((-0.9 * up + 0.9 * down, 0, 0), (0, 0, 0))
        p["f_lo.%s" % sd] = ((0.9 * up * (1 - down), 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["pelvis"] = ((-0.1 * e, 0, 0.06 * e), (0, 0, -0.12 * e))
    p["neck"] = ((-0.35 * e, 0.2 * e, 0), (0, 0, 0))
    for i in range(4):
        p["trunk%d" % i] = ((-0.35 * e, 0, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["neck"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    for i in range(4):
        p["trunk%d" % i] = ((-0.65 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["ear.%s" % sd] = ((0, s * 0.6 * e, 0), (0, 0, 0))
    return p


print("[art] mammoth: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/mammoth.glb", {"idle": (T, idle), "attack": (0.7, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.35, strength=0.5, floor_y=0.0)
