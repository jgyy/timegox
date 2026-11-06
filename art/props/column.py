"""Celestial column (Celestial Gate landmark): a white marble column with a spiral cloud relief, a gilded lotus capital, a jade phoenix finial and a ring of light.
Run: blender --background --python art/props/column.py  ->  assets/props/column.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, METAL, STONE, WOOD, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(83)
b = Builder("column")
b.superquad(V(0, 0.15, 0), (0.6, 0.15, 0.6), "f2eefc", e=0.3, cls=STONE)
b.lathe(V(0, 0.3, 0), [(0.45, 0.0), (0.38, 0.12), (0.32, 0.2)], "f8f4ff", cls=STONE, seg=16)
b.lathe(V(0, 0.5, 0), [(0.3, 0.0), (0.27, 1.5), (0.25, 2.6)], "f8f4ff", cls=STONE, seg=16, folds=(16, 0.05, 0.0))
for i in range(40):
    t = i / 39
    a = t * math.pi * 4
    b.ellipsoid(V(math.cos(a) * 0.29, 0.6 + t * 2.4, math.sin(a) * 0.29), (0.08, 0.05, 0.06), "e8e4f4", cls=STONE, seg=8, rings=5, rot=(0, -a, 0))
for k in range(10):
    a = 2 * math.pi * k / 10
    b.leaf(V(math.cos(a) * 0.2, 3.1, math.sin(a) * 0.2), V(math.cos(a) * 0.48, 3.35, math.sin(a) * 0.48), 0.14, "e8c860", side=(-math.sin(a), 0, math.cos(a)), cls=METAL)
b.lathe(V(0, 3.05, 0), [(0.32, 0.0), (0.36, 0.08), (0.2, 0.2)], "e8c860", cls=METAL, seg=16)
# a small jade phoenix on top
b.ellipsoid(V(0, 3.55, 0), (0.1, 0.12, 0.16), "6ae0b8", cls=CRYSTAL, seg=10, rings=6)
b.ellipsoid(V(0, 3.72, 0.12), (0.06, 0.06, 0.07), "6ae0b8", cls=CRYSTAL, seg=8, rings=5)
for s in (1, -1):
    b.leaf(V(0.08 * s, 3.58, 0), V(0.38 * s, 3.8, -0.1), 0.12, "8af0d0", cls=CRYSTAL)
b.tube([V(0, 3.5, -0.12), V(0, 3.45, -0.4), V(0, 3.6, -0.6)], [0.05, 0.04, 0.01], "8af0d0", cls=CRYSTAL, seg=6)
b.lathe(V(0, 2.95, 0), [(0.55, -0.01), (0.6, 0.0), (0.55, 0.01)], "fff0b0", cls=CRYSTAL, seg=24, mat=MAT_GLOW, cap_bottom=False, cap_top=False)
print("[art] column: %d triangles" % b.tri_count())
kit.finish_static(b, "props/column.glb", target_tris=2600, samples=12, dist=0.6, strength=0.45)
