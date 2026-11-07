"""Magpie pine (Heights of the Magpie Bridge landmark): a storm-bent cliff pine, its trunk ploughed
into twisting ridges, leaning out over the drop, with a great domed magpie nest of woven sticks in
its crook and three magpies - black with a blue sheen and white shoulders - perched on its arms.
Run: blender --background --python art/props/magpienest.py  ->  assets/props/magpienest.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from kit import FOLIAGE, HAIR, METAL, WOOD, V, Builder  # noqa: E402
from sculpt import catmull, strand  # noqa: E402

kit.reset()
rnd = random.Random(61)
b = Builder("magpienest")
trunk = catmull([V(0, -0.2, 0), V(0.15, 0.9, 0.05), V(0.5, 1.9, 0.1), V(1.0, 2.6, 0.05), V(1.6, 3.0, 0.0)], 3)
A.bark_limb(b, trunk, [0.26 - 0.2 * i / (len(trunk) - 1) for i in range(len(trunk))], "5a4430", None, seed=9, ridges=9, twist=1.5, tint=0.0, n=12)
# roots gripping the rock
for k in range(4):
    a = k / 4 * 2 * math.pi + 0.4
    strand(b, [V(0, 0.15, 0), V(math.cos(a) * 0.35, 0.05, math.sin(a) * 0.35), V(math.cos(a) * 0.6, -0.08, math.sin(a) * 0.6)], 0.09, 0.02, "4a3624", cls=WOOD, seg=6, per=3)
# side arms with flat, cloud-like tiers of needles
tiers = []
for k, t in enumerate((0.45, 0.65, 0.85, 1.0)):
    i = int(t * (len(trunk) - 1))
    base = trunk[i]
    a = (k % 2) * math.pi + 0.6
    tip = base + V(math.cos(a) * 0.7, 0.15, math.sin(a) * 0.7)
    strand(b, [base, base.lerp(tip, 0.5) + V(0, 0.08, 0), tip], 0.06, 0.015, "5a4430", cls=WOOD, seg=6, per=3)
    tiers.append(tip)
tiers.append(trunk[-1])
for k, c in enumerate(tiers):
    for j in range(16):
        a = j / 16 * 2 * math.pi
        rr = rnd.uniform(0.25, 0.55)
        root = c + V(math.cos(a) * rr * 0.4, 0.02, math.sin(a) * rr * 0.4)
        b.leaf(root, root + V(math.cos(a) * rr, rnd.uniform(-0.02, 0.06), math.sin(a) * rr), 0.09, "2e5a30", cls=FOLIAGE, col_tip="5a8a48", curl=0.05)
# the nest: a dome of woven sticks in the crook of the trunk
nc = trunk[len(trunk) // 2] + V(0.0, 0.25, 0.0)
for k in range(46):
    a = k * 2.4
    h = (k % 9) / 9
    rr = 0.32 * math.sin(math.pi * (0.15 + 0.7 * h))
    p0 = nc + V(math.cos(a) * rr, h * 0.45 - 0.1, math.sin(a) * rr)
    p1 = nc + V(math.cos(a + 1.3) * rr, h * 0.45 - 0.05, math.sin(a + 1.3) * rr)
    b.tube([p0, p1], [0.014, 0.012], "7a6040" if k % 3 else "5a4430", cls=WOOD, seg=4)
b.ellipsoid(nc + V(0, 0.08, 0), (0.28, 0.22, 0.28), "6a5034", cls=WOOD, seg=12, rings=8)
b.ellipsoid(nc + V(0.22, 0.08, 0.0), (0.04, 0.06, 0.06), "1a1410", cls=WOOD, seg=8, rings=5)


def magpie(p, yaw):
    """A perched magpie: black body with a white belly and shoulder patch, a long tail."""
    d = V(math.sin(yaw), 0, math.cos(yaw))
    side = V(math.cos(yaw), 0, -math.sin(yaw))
    b.ellipsoid(p, (0.06, 0.07, 0.1), "14141c", cls=HAIR, seg=10, rings=6, rot=(0, yaw, 0))
    b.ellipsoid(p + V(0, -0.025, 0) + d * 0.02, (0.045, 0.04, 0.06), "f0f0f4", cls=HAIR, seg=8, rings=5, rot=(0, yaw, 0))
    for s in (1, -1):
        b.ellipsoid(p + side * 0.05 * s + V(0, 0.02, 0), (0.015, 0.03, 0.05), "f0f0f4", cls=HAIR, seg=8, rings=4, rot=(0, yaw, 0))
    hd = p + d * 0.09 + V(0, 0.06, 0)
    b.ball(hd, 0.04, "14141c", cls=HAIR, seg=8, rings=6)
    b.cone(hd + d * 0.05, 0.012, 0.04, "202020", cls=METAL, seg=5, rot=(math.pi / 2, yaw, 0))
    strand(b, [p - d * 0.08, p - d * 0.2 + V(0, -0.04, 0), p - d * 0.32 + V(0, -0.1, 0)], 0.025, 0.012, "1a2a5a", cls=HAIR, seg=5, per=3, flat=0.3, up=(0, 1, 0))


magpie(tiers[0] + V(0, 0.08, 0), 1.2)
magpie(tiers[2] + V(0, 0.08, 0), -0.7)
magpie(nc + V(0.0, 0.42, 0.0), 2.5)
print("[art] magpienest: %d triangles" % b.tri_count())
kit.finish_static(b, "props/magpienest.glb", samples=12, dist=0.6, strength=0.5, target_tris=3000)
