"""Immortal peach tree (Garden of Immortal Peaches landmark): a gnarled forked trunk under clouds of
pink blossom, with ripe peaches hanging below.
Run: blender --background --python art/props/peach.py  ->  assets/props/peach.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import FOLIAGE, SKIN, WOOD, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(47)
b = Builder("peach")
trunk = [V(0, -0.1, 0), V(0.12, 0.7, 0.05), V(0.05, 1.3, -0.05), V(0.15, 1.6, 0.0)]
b.tube(trunk, [0.22, 0.17, 0.14, 0.12], "6a4434", cls=WOOD, seg=10, cap0=False)
ends = []
for k in range(4):
    a = k / 4 * 2 * math.pi + 0.5
    p0 = V(0.12, 1.5, 0.0)
    p1 = p0 + V(math.cos(a) * 0.5, 0.45, math.sin(a) * 0.5)
    p2 = p1 + V(math.cos(a + 0.4) * 0.45, 0.35, math.sin(a + 0.4) * 0.45)
    b.tube([p0, p1, p2], [0.1, 0.07, 0.03], "6a4434", cls=WOOD, seg=7)
    ends.append(p2)
for k, e in enumerate(ends + [V(0.1, 2.5, 0.0)]):
    for j in range(3):
        c = e + V(rnd.uniform(-0.25, 0.25), rnd.uniform(-0.05, 0.25), rnd.uniform(-0.25, 0.25))
        r = rnd.uniform(0.42, 0.6)
        pink = ["ffb0c8", "ffc8d8", "ff9ab8", "ffe0ea"][(k + j) % 4]
        b.ellipsoid(c, (r, r * 0.8, r), pink, cls=FOLIAGE, seg=12, rings=8, col2="e07898")
    for j in range(2):
        b.ball(e + V(rnd.uniform(-0.3, 0.3), -0.35, rnd.uniform(-0.3, 0.3)), 0.08, "ff9070", cls=SKIN, seg=8, rings=6)
print("[art] peach: %d triangles" % b.tri_count())
kit.finish_static(b, "props/peach.glb", samples=12, dist=0.6, strength=0.5, target_tris=2400)
