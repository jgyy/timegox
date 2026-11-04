"""Sword-saint tomb (Graveyard of Sword Saints landmark): a weathered stele on a stepped plinth,
an old jian driven into the mound before it, offerings and a guttering spirit flame.
Run: blender --background --python art/props/tombstone.py  ->  assets/props/tombstone.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CRYSTAL, FOLIAGE, MAT_GLOW, METAL, STONE, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(61)
b = Builder("tombstone")
b.lathe(V(0, 0, 0), [(1.0, -0.05), (0.9, 0.15), (0.55, 0.38), (0.001, 0.45)], "5a5a4a", cls=STONE, seg=16, squash=(1.0, 0.8))
b.superquad(V(0, 0.15, -0.55), (0.6, 0.15, 0.3), "8a8890", e=0.25, cls=STONE)
b.superquad(V(0, 0.35, -0.55), (0.48, 0.08, 0.25), "9a98a0", e=0.25, cls=STONE)
b.superquad(V(0, 1.05, -0.55), (0.36, 0.65, 0.09), "a8a6b0", e=0.2, cls=STONE, col2="7a7880")
b.superquad(V(0, 1.75, -0.55), (0.44, 0.08, 0.13), "8a8890", e=0.3, cls=STONE)
for k in range(4):
    b.superquad(V(0, 1.45 - k * 0.22, -0.455), (0.07, 0.06, 0.01), "3a3840", e=0.3, cls=STONE)
# moss creeping over the stele
for k in range(6):
    b.ellipsoid(V(rnd.uniform(-0.3, 0.3), rnd.uniform(0.4, 1.0), -0.45), (0.12, 0.06, 0.03), "4a6a3a", cls=FOLIAGE, seg=8, rings=4)
# a sword driven into the mound
blade = [V(0.35, 0.05, 0.25), V(0.37, 0.9, 0.22)]
b.tube(blade, [(0.03, 0.007), (0.025, 0.006)], "a8b0b8", cls=METAL, seg=6, up=(1, 0, 0))
b.ellipsoid(V(0.37, 0.95, 0.22), (0.1, 0.02, 0.03), "b08a40", cls=METAL, seg=8, rings=4)
b.tube([V(0.37, 0.96, 0.22), V(0.38, 1.15, 0.21)], [0.018, 0.016], "3a2a20", cls=STONE, seg=6)
# incense bowl and spirit flame
b.lathe(V(-0.4, 0.3, -0.2), [(0.1, 0.0), (0.14, 0.06), (0.12, 0.1)], "6a5040", cls=STONE, seg=10)
for k in range(3):
    b.tube([V(-0.42 + k * 0.03, 0.38, -0.2), V(-0.42 + k * 0.03, 0.6, -0.2)], [0.006, 0.006], "c84030", cls=STONE, seg=4)
b.ellipsoid(V(0, 2.0, -0.55), (0.12, 0.2, 0.12), "7af0e0", cls=CRYSTAL, seg=8, rings=6, mat=MAT_GLOW)
print("[art] tombstone: %d triangles" % b.tri_count())
kit.finish_static(b, "props/tombstone.glb", target_tris=2000, samples=12, dist=0.6, strength=0.5)
