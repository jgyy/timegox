"""Mushroom folk (new in Part V): a walking glowcap with a spotted cap that glows in the dark,
pale gills, a round face, little arms and stubby feet (Spore Puff, Mother of Spores).
Run: blender --background --python art/monsters/mushroom.py  ->  assets/monsters/mushroom.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import eyes, zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, env  # noqa: E402

kit.reset()
rnd = random.Random(3)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, 0.15, 0), (0, 0.85, 0), "root")
r.bone("cap", (0, 0.85, 0), (0, 1.35, 0), "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm.%s" % sd, (0.26 * s, 0.6, 0.02), (0.48 * s, 0.38, 0.08), "body")
    r.bone("foot.%s" % sd, (0.14 * s, 0.18, 0), (0.15 * s, 0.02, 0.1), "root")

b = Builder("mushroom")
# stem body
b.lathe(V(0, 0, 0), [(0.2, 0.1), (0.3, 0.25), (0.31, 0.45), (0.27, 0.7), (0.22, 0.9)], "f4ecd8", cls=SKIN, seg=20, bone_fn=lambda p: {"body": 1.0} if p.y > 0.3 else {"body": 0.6, "root": 0.4}, col_top="fff8ea")
# cap: dome, rim and glowing spots (tinted)
cap_prof = [(0.12, 0.82), (0.55, 0.88), (0.72, 0.95), (0.7, 1.08), (0.58, 1.22), (0.38, 1.33), (0.001, 1.38)]
b.lathe(V(0, 0, 0), cap_prof, (0.7, 0.7, 0.7), cls=CLOTH, bone="cap", seg=28, tint=1.0, col_top=(1.0, 1.0, 1.0), cap_bottom=False)
# gills under the cap
for k in range(28):
    a = 2 * math.pi * k / 28
    b.leaf(V(math.sin(a) * 0.15, 0.86, math.cos(a) * 0.15), V(math.sin(a) * 0.68, 0.94, math.cos(a) * 0.68), 0.025, "e8d8c0", cls=FOLIAGE, bone="cap", side=(math.cos(a), 0, -math.sin(a)), curl=0.0, n=3)
for k in range(16):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.15, 0.62)
    prof_y = 1.38 - (rr / 0.72) ** 2 * 0.42
    c = V(math.sin(a) * rr, prof_y + 0.01, math.cos(a) * rr)
    nrm = (c - V(0, 0.6, 0)).normalized()
    rx = math.atan2(nrm.z, nrm.y)
    rz = -math.atan2(nrm.x, nrm.y)
    sz = rnd.uniform(0.04, 0.08)
    b.ellipsoid(c, (sz, 0.012, sz), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="cap", rot=(rx, 0, rz), tint=0.35, mat=MAT_GLOW, seg=10, rings=4)
# face
eyes(b, V(0, 0.62, 0.27), 0.09, 0.04, iris="402818", bone="body", slit=False, glow=False, rot_y=0.35, h=1.3)
mouth = [V((i / 4 - 0.5) * 0.08, 0.5 + ((i / 4 - 0.5) ** 2) * 0.12, 0.3) for i in range(5)]
b.tube(mouth, [0.006] * 5, "6a3020", cls=SKIN, bone="body", seg=6, mat=MAT_PLAIN)
for s in (1, -1):
    b.ellipsoid(V(0.15 * s, 0.53, 0.27), (0.04, 0.02, 0.01), "ffb0a0", cls=SKIN, bone="body", seg=8, rings=4, rot=(0, 0.5 * s, 0), mat=MAT_PLAIN)
# arms and feet
for s, sd in ((1, "L"), (-1, "R")):
    a = "arm.%s" % sd
    b.tube([r.head(a), r.tail(a)], [0.06, 0.05], "f0e6d0", cls=SKIN, bone=a, seg=10)
    b.ball(r.tail(a), 0.065, "f0e6d0", cls=SKIN, bone=a, seg=10, rings=6)
    f = "foot.%s" % sd
    b.ellipsoid(V(0.15 * s, 0.07, 0.06), (0.11, 0.08, 0.14), "e0d4b8", cls=SKIN, bone=f, seg=12, rings=8)
# spore motes floating around the cap
for k in range(8):
    a = k * 0.8
    b.ball(V(math.sin(a) * 0.8, 1.2 + 0.15 * math.sin(k * 2.0), math.cos(a) * 0.8), 0.03, (1.0, 1.0, 1.0), cls=CRYSTAL, bone="cap", tint=0.5, mat=MAT_GLOW, seg=8, rings=5)

T = 2.0


def idle(t):
    w = 2 * math.pi / T
    bounce = abs(math.sin(t * w))
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, bounce * 0.06, 0))
    p["body"] = ((0, math.sin(t * w * 0.5) * 0.1, math.sin(t * w) * 0.06), (0, 0, 0), (1.0 + 0.04 * (1 - bounce), 1.0 - 0.05 * (1 - bounce), 1.0 + 0.04 * (1 - bounce)))
    p["cap"] = ((math.sin(t * w + 1) * 0.06, 0, math.sin(t * w + 0.5) * 0.08), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((math.sin(t * w + s) * 0.3, 0, s * 0.2 * math.sin(t * w)), (0, 0, 0))
        p["foot.%s" % sd] = ((math.sin(t * w + (0 if s > 0 else math.pi)) * 0.25, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    butt = math.sin(min(1.0, k * 1.5) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.25 * e, 0.35 * butt))
    p["body"] = ((0.5 * butt - 0.2 * e, 0, 0), (0, 0, 0))
    p["cap"] = ((0.3 * butt, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["arm.%s" % sd] = ((-1.2 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["body"] = ((-0.3 * e, 0, 0), (0, 0, 0), (1.0 + 0.15 * e, 1.0 - 0.2 * e, 1.0 + 0.15 * e))
    p["cap"] = ((-0.2 * e, 0, 0.15 * e), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["cap"] = ((0, 0, 0), (0, 0.08 * e, 0), (1.0 + 0.25 * e, 1.0 + 0.1 * e, 1.0 + 0.25 * e))
    p["body"] = ((-0.15 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((-0.5 * e, 0, s * 1.6 * e), (0, 0, 0))
    return p


print("[art] mushroom: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/mushroom.glb", {"idle": (T, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.5, floor_y=0.0)
