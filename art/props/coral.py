"""Coral tree (Sunken Dragon Palace landmark): branching staghorn coral grown from a rock, its tips
glowing softly, with fan coral and a pearl clam at its foot.
Run: blender --background --python art/props/coral.py  ->  assets/props/coral.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, SKIN, STONE, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(59)
b = Builder("coral")
b.superquad(V(0, 0.15, 0), (0.7, 0.3, 0.6), "6a7a8a", e=0.8, cls=STONE, seg=12, rings=7)


def branch(p, d, length, r, depth):
    end = p + d * length
    b.tube([p, p.lerp(end, 0.5) + V(0, length * 0.05, 0), end], [r, r * 0.85, r * 0.7], "ff8a7a", cls=SKIN, seg=6, cols=["e06a5a", "ff8a7a", "ffb0a0"])
    if depth == 0:
        b.ball(end, r * 1.1, "ffe0d0", cls=CRYSTAL, seg=6, rings=4, mat=MAT_GLOW)
        return
    for k in range(2):
        a = rnd.uniform(-0.9, 0.9)
        nd = (d + V(math.cos(a + k * 3.1) * 0.6, 0.5, math.sin(a + k * 3.1) * 0.6)).normalized()
        branch(end, nd, length * 0.72, r * 0.7, depth - 1)


for k in range(4):
    a = k / 4 * 2 * math.pi
    branch(V(math.cos(a) * 0.2, 0.3, math.sin(a) * 0.2), V(math.cos(a) * 0.35, 1.0, math.sin(a) * 0.35).normalized(), 0.85, 0.08, 2)
# sea fan
rows = [[V(0.6 + 0.05 * i, 0.25 + j * 0.25, 0.3 + 0.25 * (i - 2) * (0.4 + j * 0.2)) for i in range(5)] for j in range(5)]
b.sheet(rows, "c060e0", cls=0.4, cols=["a040c0", "b050d0", "c060e0", "d080f0", "e0a0ff"], thickness=0.02)
b.ellipsoid(V(-0.55, 0.15, 0.35), (0.22, 0.08, 0.18), "e8d8c8", cls=STONE, seg=10, rings=5)
b.ball(V(-0.55, 0.22, 0.35), 0.06, "f8f4ff", cls=CRYSTAL, seg=8, rings=5, mat=MAT_GLOW)
print("[art] coral: %d triangles" % b.tri_count())
kit.finish_static(b, "props/coral.glb", samples=10, dist=0.5, strength=0.45)
