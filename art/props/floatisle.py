"""Floating island of the Sea of Clouds: an inverted cone of layered rock hovering above the ground, roots and vines dangling, moss on top, a windswept pine and a small waterfall spilling off the edge into mist.
Run: blender --background --python art/props/floatisle.py  ->  assets/props/floatisle.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, METAL, STONE, WOOD, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(87)
b = Builder("floatisle")
Y = 1.7
b.lathe(V(0, Y, 0), [(0.001, -1.3), (0.35, -0.95), (0.7, -0.45), (0.95, -0.1), (1.0, 0.0)], "7a6a5a", cls=STONE, seg=12, folds=(7, 0.12, 0.3), col_top="8a7a6a")
b.ellipsoid(V(0, Y + 0.02, 0), (1.02, 0.14, 1.0), "6a9a50", cls=FOLIAGE, seg=16, rings=6)
for k in range(9):
    a = 2 * math.pi * k / 9 + rnd.random() * 0.3
    r0 = 0.6 + rnd.random() * 0.3
    root = V(math.cos(a) * r0, Y - 0.3, math.sin(a) * r0)
    b.tube([root, root + V(math.cos(a) * 0.05, -0.4, math.sin(a) * 0.05), root + V(0, -0.8 - rnd.random() * 0.4, 0)], [0.035, 0.025, 0.004], "5a4a3a", cls=WOOD, seg=5)
# windswept pine
b.tube([V(0.2, Y, 0.1), V(0.35, Y + 0.6, 0.1), V(0.1, Y + 1.2, 0.0), V(-0.2, Y + 1.5, 0.0)], [0.08, 0.07, 0.05, 0.02], "5a4232", cls=WOOD, seg=7)
for p in (V(-0.25, Y + 1.55, 0.0), V(0.45, Y + 1.0, 0.15), V(0.0, Y + 1.25, -0.3)):
    b.ellipsoid(p, (0.45, 0.13, 0.36), "3a7048", cls=FOLIAGE, seg=12, rings=6)
    b.ellipsoid(p + V(0, 0.08, 0), (0.32, 0.1, 0.26), "5a9058", cls=FOLIAGE, seg=10, rings=5)
# a thin waterfall off the edge
b.ribbon([V(0.98, Y, 0.0), V(1.05, Y - 0.6, 0.0), V(1.08, Y - 1.4, 0.0)], [0.08, 0.1, 0.14], (0, 0, 1), "e8f4ff", col_end="ffffff", mat=MAT_GLOW)
print("[art] floatisle: %d triangles" % b.tri_count())
kit.finish_static(b, "props/floatisle.glb", target_tris=2400, samples=12, dist=0.6, strength=0.45)
