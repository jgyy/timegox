"""Origin monolith (Origin of the Dao landmark): a tall pale standing stone floating a hand above its cracked base, inscribed with the first characters ever written, glowing faintly, ringed by orbiting pebbles.
Run: blender --background --python art/props/monolith.py  ->  assets/props/monolith.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, METAL, STONE, WOOD, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(86)
b = Builder("monolith")
b.superquad(V(0, 0.15, 0), (0.75, 0.15, 0.6), "b8acc8", e=0.4, cls=STONE)
for k in range(5):
    a = rnd.random() * 2 * math.pi
    b.superquad(V(math.cos(a) * 0.55, 0.32, math.sin(a) * 0.45), (0.12, 0.06, 0.1), "a89cb8", e=0.5, cls=STONE, rot=(rnd.random(), a, rnd.random()))
b.superquad(V(0, 2.05, 0), (0.5, 1.6, 0.28), "f4eefc", e=0.3, cls=STONE, col2="d8d0e8", rot=(0.0, 0.0, 0.04))
for k in range(6):
    y = 1.0 + k * 0.38
    b.superquad(V(0.0, y, 0.285), (0.09, 0.09, 0.01), "c0a0ff", e=0.3, cls=CRYSTAL, mat=MAT_GLOW, rot=(0, 0, k * 0.4))
    b.superquad(V(0.0, y + 0.12, -0.285), (0.06, 0.12, 0.01), "ffd8a0", e=0.3, cls=CRYSTAL, mat=MAT_GLOW)
for k in range(8):
    a = 2 * math.pi * k / 8
    b.superquad(V(math.cos(a) * 0.9, 1.8 + math.sin(a * 2) * 0.4, math.sin(a) * 0.9), (0.08, 0.07, 0.07), "c8bcd8", e=0.5, cls=STONE, rot=(a, a, 0))
b.lathe(V(0, 0.4, 0), [(0.62, -0.01), (0.66, 0.0), (0.62, 0.01)], "e0d0ff", cls=CRYSTAL, seg=24, mat=MAT_GLOW, cap_bottom=False, cap_top=False)
print("[art] monolith: %d triangles" % b.tri_count())
kit.finish_static(b, "props/monolith.glb", target_tris=2000, samples=12, dist=0.6, strength=0.45)
