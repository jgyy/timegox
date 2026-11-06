"""Jade pillar of the ruined Heavenly Court: a fluted jade column on a lotus base, a dragon coiling up it, a cracked gilded capital and a hanging silk banner.
Run: blender --background --python art/props/jadepillar.py  ->  assets/props/jadepillar.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, METAL, STONE, WOOD, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(82)
b = Builder("jadepillar")
b.lathe(V(0, 0, 0), [(0.62, 0.0), (0.62, 0.16), (0.5, 0.24), (0.42, 0.32)], "d8d0c0", cls=STONE, seg=12)
for k in range(10):
    a = 2 * math.pi * k / 10
    b.leaf(V(math.cos(a) * 0.3, 0.3, math.sin(a) * 0.3), V(math.cos(a) * 0.5, 0.5, math.sin(a) * 0.5), 0.13, "e8e0cc", side=(-math.sin(a), 0, math.cos(a)), cls=STONE)
b.lathe(V(0, 0, 0), [(0.3, 0.3), (0.28, 1.5), (0.26, 2.7), (0.3, 2.85)], "3ab08a", cls=CRYSTAL, seg=16, folds=(12, 0.06, 0.0), col_top="6ae0b8")
# a dragon spiralling up the column
pts = []
for i in range(25):
    t = i / 24
    a = t * math.pi * 3.2
    pts.append(V(math.cos(a) * 0.36, 0.45 + t * 2.3, math.sin(a) * 0.36))
b.tube(pts, [0.03 + 0.06 * math.sin(math.pi * min(1.0, t * 1.1)) for t in [i / 24 for i in range(25)]], "e8c060", cls=METAL, seg=8)
head = pts[-1]
b.ellipsoid(head + V(0, 0.05, 0), (0.1, 0.08, 0.13), "e8c060", cls=METAL, seg=10, rings=6)
for s in (1, -1):
    b.tube([head + V(0.04 * s, 0.1, -0.02), head + V(0.08 * s, 0.22, -0.1)], [0.02, 0.005], "f0d880", cls=METAL, seg=5)
    b.ball(head + V(0.06 * s, 0.08, 0.08), 0.02, "ff3030", cls=CRYSTAL, mat=MAT_GLOW, seg=6, rings=4)
# capital, cracked at one corner, and a banner
b.superquad(V(0, 2.95, 0), (0.48, 0.12, 0.48), "e8c060", e=0.3, cls=METAL)
b.superquad(V(0.05, 3.15, 0.0), (0.4, 0.1, 0.36), "d8d0c0", e=0.3, cls=STONE, rot=(0, 0, 0.08))
b.ribbon([V(0.32, 2.85, 0.0), V(0.36, 2.2, 0.05), V(0.33, 1.5, 0.08)], [0.14, 0.13, 0.11], (0, 0, 1), "c8302a", col_end="e05040")
print("[art] jadepillar: %d triangles" % b.tri_count())
kit.finish_static(b, "props/jadepillar.glb", target_tris=2600, samples=12, dist=0.6, strength=0.5)
