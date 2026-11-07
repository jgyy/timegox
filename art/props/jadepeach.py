"""Peach of Kunlun (Jasper Pool landmark): an ancient peach tree whose roots grip a boulder of
green jade, its trunk ploughed into twisting fibres and forked into crooked limbs, clouds of
blossom on every branch and the peaches of immortality - blushing, downy, with their leaves -
hanging below.
Run: blender --background --python art/props/jadepeach.py  ->  assets/props/jadepeach.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from kit import FOLIAGE, SKIN, V, Builder  # noqa: E402
from sculpt import catmull, strand  # noqa: E402

kit.reset()
rnd = random.Random(83)
b = Builder("jadepeach")
A.hewn_stone(b, V(0, 0.2, 0), (1.1, 0.55, 0.9), None, seed=83, shade=0.7, e=0.55, tint=0.0, moss=0.5, seg=20, rings=12)
for v in b.bm.verts:
    c = v[b.cl]
    v[b.cl] = (c[0] * 0.55, c[1] * 1.0, c[2] * 0.75, c[3])
# roots spilling over the jade
for k in range(6):
    a = k / 6 * 2 * math.pi + 0.3
    strand(b, [V(0, 0.45, 0), V(math.cos(a) * 0.35, 0.42, math.sin(a) * 0.3), V(math.cos(a) * 0.55, 0.15, math.sin(a) * 0.45), V(math.cos(a) * 0.62, -0.05, math.sin(a) * 0.5)], 0.08, 0.02, "5a3a28", cls=SKIN, seg=6, per=3)
trunk = catmull([V(0, 0.4, 0), V(0.1, 1.0, 0.05), V(-0.05, 1.5, 0.0), V(0.1, 1.9, -0.05)], 3)
A.bark_limb(b, trunk, [0.22 - 0.08 * i / (len(trunk) - 1) for i in range(len(trunk))], "6a4434", None, seed=5, ridges=8, twist=2.2, tint=0.0, n=12)
ends = []
for k in range(5):
    a = k / 5 * 2 * math.pi + 0.5
    p0 = trunk[-1] + V(0, -0.05, 0)
    p1 = p0 + V(math.cos(a) * 0.45, 0.4, math.sin(a) * 0.45)
    p2 = p1 + V(math.cos(a + 0.5) * 0.4, 0.3, math.sin(a + 0.5) * 0.4)
    strand(b, [p0, p1, p2], 0.1, 0.025, "6a4434", cls=SKIN, seg=6, per=3)
    ends.append(p2)
for k, e in enumerate(ends + [trunk[-1] + V(0, 0.7, 0)]):
    for j in range(3):
        c = e + V(rnd.uniform(-0.25, 0.25), rnd.uniform(-0.05, 0.25), rnd.uniform(-0.25, 0.25))
        r = rnd.uniform(0.38, 0.55)
        pink = ["ffb0c8", "ffc8d8", "ff9ab8", "ffe0ea"][(k + j) % 4]
        b.ellipsoid(c, (r, r * 0.8, r), pink, cls=FOLIAGE, seg=12, rings=8, col2="e07898")
    for j in range(2):
        q = e + V(rnd.uniform(-0.3, 0.3), -0.36, rnd.uniform(-0.3, 0.3))
        b.ball(q, 0.09, "ffb090", cls=SKIN, seg=10, rings=8, col2="ff7060")
        b.ellipsoid(q + V(0.02, 0.0, 0.07), (0.01, 0.07, 0.01), "ff6a5a", cls=SKIN, seg=6, rings=4)
        b.leaf(q + V(0, 0.08, 0), q + V(0.1, 0.14, 0.03), 0.035, "4a8a3a", cls=FOLIAGE, col_tip="7ab05a")
print("[art] jadepeach: %d triangles" % b.tri_count())
kit.finish_static(b, "props/jadepeach.glb", samples=12, dist=0.6, strength=0.5, target_tris=3000)
