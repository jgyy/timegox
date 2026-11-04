"""Ice spire (Aurora Steppe landmark): a cluster of blue-white ice crystals erupting from a snow
drift, with frozen-in aurora light and icicles.
Run: blender --background --python art/props/icespire.py  ->  assets/props/icespire.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, STONE, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(23)
b = Builder("icespire")
# snow drift
b.lathe(V(0, 0, 0), [(1.3, -0.05), (1.15, 0.15), (0.8, 0.32), (0.3, 0.42), (0.001, 0.44)], "f2f6ff", cls=STONE, seg=20, cap_bottom=False, squash=(1.0, 0.85))
# the great spire and its brothers
b.crystal(V(0, 0.1, 0), 0.42, 4.4, "bfe4ff", rot=(0.04, 0.3, 0.05), sides=6)
b.crystal(V(0.02, 0.4, 0.02), 0.2, 3.6, "e8f6ff", rot=(0.04, 0.3, 0.05), sides=6, mat=kit.MAT_TOON)
for k in range(8):
    a = k / 8 * 2 * math.pi + rnd.uniform(-0.2, 0.2)
    rr = rnd.uniform(0.35, 0.7)
    tilt = (math.sin(a) * rnd.uniform(0.3, 0.6), 0, -math.cos(a) * rnd.uniform(0.3, 0.6))
    col = ["a8d8ff", "c8ecff", "90c8f8"][k % 3]
    b.crystal(V(math.cos(a) * rr, 0.15, math.sin(a) * rr), rnd.uniform(0.12, 0.24), rnd.uniform(1.0, 2.4), col, rot=tilt, sides=5)
# frozen aurora ribbons inside the ice
for k in range(3):
    pts = [V(math.sin(k * 2.1 + i * 0.5) * 0.14, 0.5 + i * 0.55, math.cos(k * 2.1 + i * 0.5) * 0.14) for i in range(6)]
    b.tube(pts, [0.03, 0.035, 0.035, 0.03, 0.02, 0.01], ["60ffc0", "a080ff", "60e0ff"][k], cls=CRYSTAL, seg=5, mat=MAT_GLOW)
# icicles hanging from the drift's edge
for k in range(10):
    a = rnd.uniform(0, 2 * math.pi)
    b.cone(V(math.cos(a) * 1.0, 0.18, math.sin(a) * 0.85), 0.04, 0.2, "d8f0ff", cls=CRYSTAL, rot=(math.pi, 0, 0), seg=5)
print("[art] icespire: %d triangles" % b.tri_count())
kit.finish_static(b, "props/icespire.glb", target_tris=1800, samples=12, dist=0.5, strength=0.45)
