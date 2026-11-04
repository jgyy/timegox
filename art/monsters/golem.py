"""Golem: a hulking construct of carved stone blocks bound by a glowing core and rune seams
(Lava Titan, Glass Colossus, Bronze Sentinel, Crucible Golem ...).  Rigid plates on a humanoid
rig with oversized fists; the glow takes the enemy's colour.
Run: blender --background --python art/monsters/golem.py  ->  assets/monsters/golem.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, STONE, V, Builder, Rig, env  # noqa: E402

kit.reset()
rnd = random.Random(5)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("hips", (0, 0.95, 0), (0, 1.25, 0), "root")
r.bone("chest", (0, 1.25, 0), (0, 1.85, 0.05), "hips")
r.bone("head", (0, 1.85, 0.1), (0, 2.15, 0.15), "chest")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm.%s" % sd, (0.55 * s, 1.75, 0), (0.72 * s, 1.25, 0.05), "chest")
    r.bone("fore.%s" % sd, (0.72 * s, 1.25, 0.05), (0.78 * s, 0.75, 0.15), "arm.%s" % sd)
    r.bone("thigh.%s" % sd, (0.25 * s, 0.95, 0), (0.28 * s, 0.5, 0.02), "hips")
    r.bone("shin.%s" % sd, (0.28 * s, 0.5, 0.02), (0.28 * s, 0.06, 0.0), "thigh.%s" % sd)


def rock(c, size, bone, shade=0.8, e=0.3, rot=None):
    jitter = rot or (rnd.uniform(-0.12, 0.12), rnd.uniform(-0.3, 0.3), rnd.uniform(-0.12, 0.12))
    sh = shade * rnd.uniform(0.85, 1.1)
    b.superquad(c, (size[0] / 2, size[1] / 2, size[2] / 2), (sh, sh, sh), e=e, cls=STONE, bone=bone, rot=jitter, tint=0.55, seg=14, rings=8, col2=(sh * 0.7, sh * 0.7, sh * 0.7))


b = Builder("golem")
# torso: a stack of slabs with a glowing heart
rock(V(0, 1.55, 0), (0.95, 0.62, 0.62), "chest", 0.82, rot=(0, 0, 0))
rock(V(0, 1.12, 0.02), (0.62, 0.36, 0.48), "hips", 0.75)
rock(V(0, 1.83, -0.02), (1.15, 0.22, 0.55), "chest", 0.7, rot=(0.05, 0, 0))
for k in range(5):
    a = k / 4 - 0.5
    rock(V(a * 0.7, 1.32 + abs(a) * 0.1, 0.27), (0.18, 0.22, 0.12), "chest", 0.9)
b.crystal(V(0, 1.55, 0.29), 0.11, 0.24, (1.0, 1.0, 1.0), cls=CRYSTAL, bone="chest", tint=1.0, mat=MAT_GLOW, rot=(math.pi / 2, 0, 0))
b.ball(V(0, 1.55, 0.3), 0.2, (0.6, 0.6, 0.6), cls=CRYSTAL, bone="chest", tint=1.0, mat=MAT_GLOW, seg=12, rings=8)
# rune seams
for k in range(6):
    y = 1.3 + k * 0.1
    b.tube([V(-0.46, y, 0.31), V(-0.3, y + 0.03, 0.315)], [0.012, 0.012], (1, 1, 1), cls=CRYSTAL, bone="chest", tint=1.0, mat=MAT_GLOW, seg=5)
    b.tube([V(0.3, y + 0.03, 0.315), V(0.46, y, 0.31)], [0.012, 0.012], (1, 1, 1), cls=CRYSTAL, bone="chest", tint=1.0, mat=MAT_GLOW, seg=5)
# head: a small craggy block with a visor of light
rock(V(0, 2.0, 0.12), (0.36, 0.3, 0.34), "head", 0.85)
b.superquad(V(0, 2.02, 0.29), (0.13, 0.03, 0.02), (1, 1, 1), e=0.2, cls=CRYSTAL, bone="head", tint=1.0, mat=MAT_GLOW)
for s in (1, -1):
    b.crystal(V(0.12 * s, 2.18, 0.08), 0.05, 0.22, (0.9, 0.9, 0.9), bone="head", tint=1.0, rot=(0, 0, -0.4 * s))
# shoulders with crystal growths, arms of stacked stones, huge fists
for s, sd in ((1, "L"), (-1, "R")):
    rock(V(0.6 * s, 1.82, 0), (0.42, 0.36, 0.44), {"chest": 0.5, "arm.%s" % sd: 0.5}, 0.78)
    for k in range(3):
        b.crystal(V((0.55 + k * 0.08) * s, 2.0 + k * 0.04, -0.1 + k * 0.08), 0.05, 0.25 - k * 0.04, (0.95, 0.95, 0.95), bone="chest", tint=1.0, rot=(0.3, 0, -0.5 * s - k * 0.2 * s))
    rock(V(0.66 * s, 1.5, 0.02), (0.3, 0.42, 0.3), "arm.%s" % sd, 0.72)
    rock(V(0.74 * s, 1.08, 0.08), (0.28, 0.4, 0.28), "fore.%s" % sd, 0.75)
    rock(V(0.79 * s, 0.72, 0.16), (0.44, 0.38, 0.42), "fore.%s" % sd, 0.86, e=0.45)
    for k in range(3):
        rock(V((0.79 + (k - 1) * 0.12) * s, 0.55, 0.3), (0.11, 0.14, 0.12), "fore.%s" % sd, 0.9)
    b.ball(V(0.72 * s, 1.27, 0.05), 0.08, (0.8, 0.8, 0.8), cls=CRYSTAL, bone="arm.%s" % sd, tint=1.0, mat=MAT_GLOW, seg=10, rings=6)
    rock(V(0.27 * s, 0.72, 0.02), (0.3, 0.42, 0.32), "thigh.%s" % sd, 0.7)
    rock(V(0.28 * s, 0.3, 0.02), (0.28, 0.4, 0.3), "shin.%s" % sd, 0.75)
    rock(V(0.28 * s, 0.07, 0.08), (0.36, 0.16, 0.48), "shin.%s" % sd, 0.65, e=0.4)

T = 3.0


def idle(t):
    w = 2 * math.pi / T
    br = math.sin(t * w)
    p = zero_pose(r)
    p["hips"] = ((0, math.sin(t * w / 2 * 1) * 0.04, 0), (0, br * 0.02, 0))
    p["chest"] = ((br * 0.03, math.sin(t * w) * 0.05, 0), (0, 0, 0))
    p["head"] = ((0, math.sin(t * w) * 0.15, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((math.sin(t * w + s) * 0.06, 0, 0.05 * s * br), (0, 0, 0))
        p["fore.%s" % sd] = ((-0.2, 0, 0), (0, 0, 0))
        p["shin.%s" % sd] = ((0.05, 0, 0), (0, 0, 0))
        p["thigh.%s" % sd] = ((-0.05, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.7
    e = env(k)
    up = math.sin(min(1.0, k / 0.45) * math.pi / 2)
    slam = max(0.0, min(1.0, (k - 0.45) / 0.2))
    p = idle(0.0)
    p["chest"] = ((-0.3 * up + 0.7 * slam, 0, 0), (0, 0, 0))
    p["root"] = ((0, 0, 0), (0, 0, 0.3 * slam * e))
    for sd in ("L", "R"):
        p["arm.%s" % sd] = ((-2.6 * up + 2.2 * slam, 0, 0), (0, 0, 0))
        p["fore.%s" % sd] = ((-0.6 * up, 0, 0), (0, 0, 0))
    p["thigh.L"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["shin.L"] = ((0.4 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["chest"] = ((-0.25 * e, 0.15 * e, 0.1 * e), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["root"] = ((0, 0, 0), (0, 0, -0.15 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["chest"] = ((-0.25 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((-0.4 * e, 0, s * 1.2 * e), (0, 0, 0))
        p["fore.%s" % sd] = ((-0.8 * e, 0, 0), (0, 0, 0))
    return p


print("[art] golem: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/golem.glb", {"idle": (T, idle), "attack": (0.7, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=14, dist=0.3, strength=0.55, floor_y=0.0)
