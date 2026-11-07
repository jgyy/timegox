"""Lightning crag (Thunder Valley landmark): a split basalt column scarred by strikes, with
crackling quartz veins and a lightning rod of fused glass at its peak.
Run: blender --background --python art/props/crag.py  ->  assets/props/crag.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402

from kit import CRYSTAL, FOLIAGE, MAT_GLOW, STONE, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(67)
b = Builder("crag")
# hexagonal basalt columns of different heights
for k in range(7):
    a = k / 7 * 2 * math.pi
    rr = 0.0 if k == 0 else 0.42
    h = 3.2 if k == 0 else rnd.uniform(1.0, 2.4)
    c = V(math.cos(a) * rr, 0, math.sin(a) * rr)
    sh = rnd.uniform(0.28, 0.38)
    b.lathe(c, [(0.3, -0.05), (0.28, h * 0.5), (0.26, h), (0.001, h + 0.08)], (sh, sh, sh + 0.05), cls=STONE, seg=6, smooth=False, rot=(rnd.uniform(-0.06, 0.06), a, rnd.uniform(-0.06, 0.06)))
# glowing quartz veins
for k in range(4):
    a = k * 1.6
    pts = [V(math.cos(a) * 0.3, 0.3 + i * 0.6, math.sin(a) * 0.3) + V(rnd.uniform(-0.05, 0.05), 0, rnd.uniform(-0.05, 0.05)) for i in range(5)]
    b.tube(pts, [0.02] * 5, "e0e8ff", cls=CRYSTAL, seg=4, mat=MAT_GLOW)
# fused-glass lightning rod
b.crystal(V(0, 3.2, 0), 0.08, 0.9, "c8d8ff", rot=(0.1, 0, 0.05), sides=5)
b.ball(V(0, 3.95, 0.05), 0.08, "f6f0a0", cls=CRYSTAL, seg=8, rings=5, mat=MAT_GLOW)
# detail: weathered column tops, a skirt of scree and fallen column drums at the foot, lichen on the
# north faces
for k in range(6):
    a = k / 6 * 2 * math.pi + 0.25
    rr = rnd.uniform(0.6, 0.95)
    A.hewn_stone(b, V(math.cos(a) * rr, 0.08, math.sin(a) * rr), (rnd.uniform(0.15, 0.3), rnd.uniform(0.1, 0.18), rnd.uniform(0.15, 0.28)), None, seed=k + 21, shade=0.32, e=0.6, tint=0.0, seg=10, rings=6)
for k in range(2):
    a = 1.2 + k * 2.4
    b.lathe(V(math.cos(a) * 0.9, 0.15, math.sin(a) * 0.9), [(0.26, -0.15), (0.26, 0.15)], (0.3, 0.3, 0.35), cls=STONE, seg=6, smooth=False, rot=(math.pi / 2, a, 0))
for k in range(10):
    a = rnd.uniform(-0.8, 0.8)
    y = rnd.uniform(0.4, 2.0)
    b.ellipsoid(V(math.sin(a) * 0.33, y, -0.3 - 0.05 * math.cos(a)), (0.08, 0.05, 0.02), "7a9a6a", cls=FOLIAGE, seg=8, rings=4)
print("[art] crag: %d triangles" % b.tri_count())
kit.finish_static(b, "props/crag.glb", samples=12, dist=0.6, strength=0.5)
