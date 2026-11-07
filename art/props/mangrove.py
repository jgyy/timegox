"""Mangrove (Crimson Marsh landmark): a tree standing on an arching cage of stilt roots above the
bog water, with a drooping canopy and hanging moss.
Run: blender --background --python art/props/mangrove.py  ->  assets/props/mangrove.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from sculpt import catmull, strand  # noqa: E402
from kit import FOLIAGE, STONE, V, WOOD, Builder  # noqa: E402

kit.reset()
rnd = random.Random(53)
b = Builder("mangrove")
hub = V(0, 1.0, 0)
for k in range(7):
    a = k / 7 * 2 * math.pi
    foot = V(math.cos(a) * 0.9, -0.1, math.sin(a) * 0.9)
    mid = V(math.cos(a) * 0.65, 0.75, math.sin(a) * 0.65)
    b.tube([foot, mid, hub], [0.05, 0.06, 0.09], "4a3428", cls=WOOD, seg=6)
b.tube([hub, V(0.1, 1.9, 0.05), V(-0.05, 2.7, 0.0)], [0.16, 0.13, 0.09], "4a3428", cls=WOOD, seg=8)
for k in range(5):
    a = k / 5 * 2 * math.pi + 0.3
    c = V(math.cos(a) * 0.65, 2.75 + rnd.uniform(-0.1, 0.2), math.sin(a) * 0.65)
    b.ellipsoid(c, (0.7, 0.42, 0.7), "3a5a2a", cls=FOLIAGE, seg=10, rings=7, col2="2a3a1a")
    for j in range(2):
        root = c + V(rnd.uniform(-0.4, 0.4), -0.35, rnd.uniform(-0.4, 0.4))
        b.ribbon([root, root + V(0, -0.35, 0), root + V(0.03, -0.75, 0)], [0.04, 0.03, 0.005], (1, 0, 0), "6a7a4a", cls=FOLIAGE)
b.ellipsoid(V(0, 3.15, 0), (0.75, 0.45, 0.75), "4a6a32", cls=FOLIAGE, seg=10, rings=7)
# detail: arching prop roots ploughed with bark ridges, hanging moss from the branches, and
# barnacled roots at the waterline
for k in range(7):
    a = k / 7 * 2 * math.pi + 0.2
    root = catmull([V(math.cos(a) * 0.1, 0.9, math.sin(a) * 0.1), V(math.cos(a) * 0.5, 0.7, math.sin(a) * 0.5), V(math.cos(a) * 0.85, 0.25, math.sin(a) * 0.85), V(math.cos(a) * 0.95, -0.1, math.sin(a) * 0.95)], 2)
    A.bark_limb(b, root, [0.07 - 0.04 * i / (len(root) - 1) for i in range(len(root))], "4a3a2a", None, seed=k, ridges=5, twist=2.0, tint=0.0, n=8)
    b.ball(root[-2], 0.03, "c8c0b0", cls=STONE, seg=6, rings=4)
for k in range(12):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.4, 1.0)
    top = V(math.cos(a) * rr, rnd.uniform(1.6, 2.2), math.sin(a) * rr)
    strand(b, [top, top + V(0.02, -0.25, 0.0), top + V(-0.02, -0.5, 0.03)], 0.025, 0.004, "6a7a50", cls=FOLIAGE, seg=4, per=3, flat=0.4)
print("[art] mangrove: %d triangles" % b.tri_count())
kit.finish_static(b, "props/mangrove.glb", samples=12, dist=0.6, strength=0.5)
