"""Fallen star (Desert of Fallen Stars landmark): a slag-crusted meteorite half sunk in a sand
crater, split by glowing seams and bristling with star-glass crystals.
Run: blender --background --python art/props/meteor.py  ->  assets/props/meteor.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, STONE, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(31)
b = Builder("meteor")
# crater rim of heaped sand
b.lathe(V(0, 0, 0), [(1.55, -0.05), (1.35, 0.18), (1.05, 0.24), (0.85, 0.1)], "d8b478", cls=STONE, seg=24, cap_bottom=False, cap_top=False)
# the stone: lumpy superquadric chunks fused together
for k in range(7):
    a = rnd.uniform(0, 2 * math.pi)
    rr = 0.0 if k == 0 else rnd.uniform(0.2, 0.45)
    size = (0.8, 0.62, 0.72) if k == 0 else tuple(rnd.uniform(0.25, 0.42) for _ in range(3))
    sh = rnd.uniform(0.22, 0.32)
    b.superquad(V(math.cos(a) * rr, 0.45 + rnd.uniform(-0.1, 0.25), math.sin(a) * rr), size, (sh, sh * 0.9, sh * 1.05), e=0.75, cls=STONE, rot=(rnd.uniform(-0.4, 0.4), rnd.uniform(0, 3), rnd.uniform(-0.4, 0.4)), seg=16, rings=10, col2=(sh * 0.6, sh * 0.5, sh * 0.5))
# glowing seams running over the crust
for k in range(6):
    a0 = rnd.uniform(0, 2 * math.pi)
    pts = []
    for i in range(6):
        a = a0 + i * 0.28
        y = 0.15 + i * 0.16
        rad = 0.82 * math.sqrt(max(0.05, 1.0 - ((y - 0.45) / 0.7) ** 2))
        pts.append(V(math.cos(a) * rad, y, math.sin(a) * rad * 0.9))
    b.tube(pts, [0.02] * 6, "ffc060", cls=CRYSTAL, seg=5, mat=MAT_GLOW)
# star-glass crystals
for k in range(9):
    a = k / 9 * 2 * math.pi + rnd.uniform(-0.2, 0.2)
    base = V(math.cos(a) * 0.65, 0.55 + rnd.uniform(-0.2, 0.3), math.sin(a) * 0.58)
    tilt = (math.sin(a) * 0.8, 0, -math.cos(a) * 0.8)
    h = rnd.uniform(0.45, 1.0)
    b.crystal(base, rnd.uniform(0.08, 0.15), h, "fff2c8" if k % 3 else "ffd890", rot=tilt, sides=5)
# a halo of heat shimmer at the core
b.ball(V(0, 0.95, 0), 0.22, "fff0b0", cls=CRYSTAL, seg=12, rings=8, mat=MAT_GLOW)
print("[art] meteor: %d triangles" % b.tri_count())
kit.finish_static(b, "props/meteor.glb", target_tris=1800, samples=14, dist=0.5, strength=0.55)
