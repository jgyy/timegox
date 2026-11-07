"""Mountain pine (Azure Cloud Sect landmark): a twisted trunk with exposed roots carrying five
star-shaped tiers of needles that darken towards the core, the classic sect-painting pine.
Run: blender --background --python art/props/pine.py  ->  assets/props/pine.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from sculpt import catmull  # noqa: E402
from kit import FOLIAGE, V, WOOD, Builder  # noqa: E402

kit.reset()
rnd = random.Random(41)
b = Builder("pine")
trunk = [V(0, -0.1, 0), V(0.08, 0.8, 0.02), V(-0.05, 1.7, 0.06), V(0.06, 2.6, -0.02), V(0.0, 3.6, 0.0)]
b.tube(trunk, [0.24, 0.18, 0.14, 0.1, 0.05], "6a4a30", cls=WOOD, seg=10, cap0=False, cols=["5a3a24", "6a4a30", "7a5838", "7a5838", "6a4a30"])
for k in range(5):
    a = k / 5 * 2 * math.pi + 0.3
    b.tube([V(0, 0.15, 0), V(math.cos(a) * 0.35, 0.05, math.sin(a) * 0.35), V(math.cos(a) * 0.55, -0.08, math.sin(a) * 0.55)], [0.09, 0.06, 0.02], "5a3a24", cls=WOOD, seg=6)
for tier in range(5):
    y = 1.1 + tier * 0.62
    rad = 1.35 - tier * 0.22
    spikes = 9 - tier
    prof = []
    # a jagged star-shaped skirt: lathe rings whose radius alternates around the trunk
    n = spikes * 2
    rows = []
    for j, (rr, dy) in enumerate(((0.08, 0.55), (rad * 0.55, 0.3), (rad, 0.0), (rad * 0.85, -0.12))):
        row = []
        for i in range(n + 1):
            a = 2 * math.pi * i / n + tier * 0.4
            jag = 1.0 if i % 2 == 0 else 0.72
            r2 = rr * (jag if j >= 2 else 1.0) * rnd.uniform(0.95, 1.05)
            row.append(V(math.cos(a) * r2, y + dy, math.sin(a) * r2))
        rows.append(row)
    shade = 0.75 + tier * 0.06
    b.sheet(rows, (0.18 * shade, 0.42 * shade, 0.3 * shade), cls=FOLIAGE, cols=[(0.12, 0.3, 0.22), (0.2, 0.45, 0.3), (0.28 * shade + 0.05, 0.55 * shade, 0.36 * shade), (0.22, 0.42, 0.3)], thickness=0.05)
# detail: the trunk ploughed into twisting bark ridges over the old one, a few cones, a broken
# dead branch and fallen needles round the roots
A.bark_limb(b, catmull(trunk[:4], 2), [0.25, 0.23, 0.21, 0.19, 0.17, 0.15, 0.13], "6a4a30", None, seed=41, ridges=9, twist=1.8, tint=0.0, n=12)
for k in range(8):
    a = rnd.uniform(0, 2 * math.pi)
    b.ellipsoid(V(math.cos(a) * 0.6, rnd.uniform(1.4, 3.0), math.sin(a) * 0.6), (0.04, 0.06, 0.04), "7a5030", cls=WOOD, seg=8, rings=6)
dead = [V(0.0, 1.2, 0.05), V(-0.35, 1.35, 0.1), V(-0.6, 1.3, 0.15)]
b.tube(dead, [0.05, 0.03, 0.01], "8a7a6a", cls=WOOD, seg=6)
for k in range(20):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.3, 1.1)
    p0 = V(math.cos(a) * rr, 0.01, math.sin(a) * rr)
    b.leaf(p0, p0 + V(math.cos(a + 0.5) * 0.08, 0.004, math.sin(a + 0.5) * 0.08), 0.008, "8a6a40", cls=FOLIAGE, n=3, curl=0.0)
print("[art] pine: %d triangles" % b.tri_count())
kit.finish_static(b, "props/pine.glb", samples=12, dist=0.6, strength=0.5)
