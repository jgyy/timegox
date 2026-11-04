"""Tortoise: a great domed shell of hexagonal scutes over a scaly body (Eon Tortoise, Moss-Backed
Tortoise, Xuan Wu).  Head and neck on a two-bone chain, stubby legs and a short tail; moss and
crystals grow on the shell.
Run: blender --background --python art/monsters/tortoise.py  ->  assets/monsters/tortoise.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import claws, eyes, zero_pose  # noqa: E402
from kit import CRYSTAL, FOLIAGE, SCALE, STONE, V, Builder, Rig, env  # noqa: E402

kit.reset()
rnd = random.Random(9)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("shell", (0, 0.55, -0.3), (0, 0.6, 0.3), "root")
r.bone("neck", (0, 0.6, 0.55), (0, 0.72, 0.85), "shell")
r.bone("head", (0, 0.72, 0.85), (0, 0.74, 1.1), "neck")
r.bone("jaw", (0, 0.66, 0.9), (0, 0.64, 1.1), "head")
r.bone("tail", (0, 0.5, -0.7), (0, 0.4, -0.95), "shell")
for fz, nm in ((0.42, "f"), (-0.42, "h")):
    for s, sd in ((1, "L"), (-1, "R")):
        r.bone("%s_up.%s" % (nm, sd), (0.45 * s, 0.5, fz), (0.6 * s, 0.3, fz + 0.05), "shell")
        r.bone("%s_lo.%s" % (nm, sd), (0.6 * s, 0.3, fz + 0.05), (0.62 * s, 0.03, fz + 0.08), "%s_up.%s" % (nm, sd))

b = Builder("tortoise")
# shell dome, rim and scutes
prof = [(0.82, 0.42), (0.86, 0.5), (0.82, 0.68), (0.7, 0.88), (0.5, 1.02), (0.25, 1.1), (0.001, 1.12)]
b.lathe(V(0, 0, 0), prof, (0.75, 0.75, 0.75), cls=STONE, bone="shell", seg=24, squash=(0.85, 1.0), tint=1.0, col_top=(0.95, 0.95, 0.95))
b.lathe(V(0, 0, 0), [(0.85, 0.36), (0.9, 0.44), (0.86, 0.5)], (0.5, 0.5, 0.5), cls=STONE, bone="shell", seg=24, squash=(0.86, 1.0), tint=1.0)
for ring, (rad, y, n) in enumerate(((0.0, 1.11, 1), (0.42, 0.98, 6), (0.72, 0.72, 10))):
    for k in range(n):
        a = 2 * math.pi * (k + 0.5 * ring) / n
        c = V(math.sin(a) * rad * 0.85, y, math.cos(a) * rad)
        nrm = (c - V(0, 0.3, 0)).normalized()
        rx = math.atan2(nrm.z, nrm.y) if ring else 0.0
        rz = -math.atan2(nrm.x, nrm.y) if ring else 0.0
        sh = rnd.uniform(0.8, 1.0)
        b.superquad(c, (0.17, 0.05, 0.17), (sh, sh, sh), e=0.5, cls=STONE, bone="shell", rot=(rx, 0, rz), tint=1.0, seg=6, rings=4, col2=(sh * 0.6, sh * 0.6, sh * 0.6))
# moss tufts and crystals on top
for k in range(14):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.1, 0.6)
    y = 1.12 - rr * rr * 0.9
    root = V(math.sin(a) * rr * 0.85, y, math.cos(a) * rr)
    b.leaf(root, root + V(rnd.uniform(-0.1, 0.1), 0.18, rnd.uniform(-0.1, 0.1)), 0.06, "5a8a3a", cls=FOLIAGE, bone="shell", col_tip="9ac860")
for k in range(4):
    a = k * 1.7
    b.crystal(V(math.sin(a) * 0.3, 1.06, math.cos(a) * 0.3 - 0.1), 0.06, 0.3, "a0f0ff", cls=CRYSTAL, bone="shell", rot=(0.3 * math.cos(a), 0, -0.3 * math.sin(a)))
# underbelly
b.ellipsoid(V(0, 0.46, 0), (0.7, 0.14, 0.8), (0.95, 0.95, 0.95), cls=SCALE, bone="shell", tint=0.6, seg=16, rings=8)
# neck and head
b.tube([V(0, 0.55, 0.45), V(0, 0.63, 0.65), V(0, 0.71, 0.85)], [0.16, 0.13, 0.12], (0.8, 0.8, 0.8), cls=SCALE, bones=["shell", {"shell": 0.3, "neck": 0.7}, {"neck": 0.5, "head": 0.5}], tint=0.8, seg=12)
b.ellipsoid(V(0, 0.75, 0.98), (0.16, 0.13, 0.19), (0.85, 0.85, 0.85), cls=SCALE, bone="head", tint=0.8, seg=16, rings=10)
b.ellipsoid(V(0, 0.68, 0.98), (0.13, 0.05, 0.16), (0.9, 0.9, 0.9), cls=SCALE, bone="jaw", tint=0.8, seg=12, rings=6)
b.cone(V(0, 0.73, 1.16), 0.05, 0.08, "c8b080", cls=STONE, bone="head", rot=(math.pi / 2 + 0.6, 0, 0), seg=8)
eyes(b, V(0, 0.8, 1.06), 0.1, 0.03, iris="e0a020", bone="head", slit=False, glow=False, rot_y=0.9, h=0.8)
for s in (1, -1):
    b.tube([V(0.08 * s, 0.86, 1.02), V(0.14 * s, 0.86, 0.94)], [0.02, 0.01], (0.5, 0.5, 0.5), bone="head", tint=0.8, seg=6)
# legs
for nm in ("f", "h"):
    for sd in ("L", "R"):
        up = "%s_up.%s" % (nm, sd)
        lo = "%s_lo.%s" % (nm, sd)
        b.tube([r.head(up), r.tail(up), r.tail(lo) + V(0, 0.03, 0)], [0.15, 0.13, 0.13], (0.75, 0.75, 0.75), cls=SCALE, bones=[up, {up: 0.5, lo: 0.5}, lo], tint=0.8, seg=12)
        claws(b, r.tail(lo) + V(0, 0.02, 0.1), True, lo, n=4, spread=0.05, length=0.06)
b.cone(V(0, 0.45, -0.85), 0.07, 0.3, (0.7, 0.7, 0.7), cls=SCALE, bone="tail", tint=0.8, rot=(-math.pi / 2 - 0.4, 0, 0), seg=8)

T = 4.0


def idle(t):
    w = 2 * math.pi / T
    p = zero_pose(r)
    p["shell"] = ((math.sin(t * w) * 0.015, 0, math.sin(t * w * 0.5) * 0.01), (0, math.sin(t * w * 2) * 0.008, 0))
    p["neck"] = ((math.sin(t * w) * 0.08, math.sin(t * w * 0.5) * 0.25, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w + 1) * 0.06, math.sin(t * w * 0.5 + 0.4) * 0.15, 0), (0, 0, 0))
    p["jaw"] = ((0.05 + 0.05 * abs(math.sin(t * w)), 0, 0), (0, 0, 0))
    p["tail"] = ((0, math.sin(t * w * 2) * 0.2, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    snap = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["neck"] = ((0.4 * snap - 0.3 * e, 0, 0), (0, 0.05 * snap, 0.35 * snap))
    p["head"] = ((-0.2 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.8 * snap, 0, 0), (0, 0, 0))
    p["shell"] = ((0.1 * snap, 0, 0), (0, 0, 0.1 * snap))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["neck"] = ((0, 0, 0), (0, -0.05 * e, -0.25 * e))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["shell"] = ((-0.1 * e, 0, 0.08 * e), (0, 0, -0.1 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["shell"] = ((-0.25 * e, 0, 0), (0, 0.12 * e, 0))
    p["neck"] = ((-0.5 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.7 * e, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up.%s" % sd] = ((-0.7 * e, 0, 0), (0, 0, 0))
    return p


print("[art] tortoise: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/tortoise.glb", {"idle": (T, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=14, dist=0.3, strength=0.5, floor_y=0.0)
