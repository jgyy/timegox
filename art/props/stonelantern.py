"""Stone lantern of the Yellow Springs (Part VI landmark): a tall weathered toro on a carved base,
its firebox glowing through paper windows, a moss-capped roof with upturned corners, offerings of
spider lilies at its foot and red prayer ribbons tied around the post.
Run: blender --background --python art/props/stonelantern.py  ->  assets/props/stonelantern.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CLOTH, FOLIAGE, MAT_GLOW, STONE, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(73)
b = Builder("stonelantern")
grey = "8a8478"
# carved base: a hexagonal plinth and a lotus-petal collar
b.lathe(V(0, 0, 0), [(0.62, -0.05), (0.62, 0.12), (0.5, 0.2), (0.32, 0.28)], grey, cls=STONE, seg=6)
for k in range(8):
    a = 2 * math.pi * k / 8
    b.leaf(V(math.cos(a) * 0.2, 0.28, math.sin(a) * 0.2), V(math.cos(a) * 0.42, 0.42, math.sin(a) * 0.42), 0.12, "9a9488", side=(-math.sin(a), 0, math.cos(a)), cls=STONE)
# post with prayer ribbons
b.lathe(V(0, 0, 0), [(0.15, 0.28), (0.13, 0.8), (0.14, 1.25), (0.2, 1.32)], grey, cls=STONE, seg=10, folds=(8, 0.03, 0.0))
for k in range(3):
    y = 0.65 + k * 0.18
    b.lathe(V(0, y, 0), [(0.145, -0.02), (0.15, 0.0), (0.145, 0.02)], "c02a20", cls=CLOTH, seg=12, cap_bottom=False, cap_top=False)
    a = rnd.random() * math.pi * 2
    b.ribbon([V(math.cos(a) * 0.15, y, math.sin(a) * 0.15), V(math.cos(a) * 0.22, y - 0.18, math.sin(a) * 0.22), V(math.cos(a) * 0.25, y - 0.38, math.sin(a) * 0.25)], [0.04, 0.035, 0.02], (math.sin(a), 0, -math.cos(a)), "c02a20", col_end="ff6050")
# platform and firebox with glowing paper windows on four sides
b.superquad(V(0, 1.38, 0), (0.42, 0.06, 0.42), grey, e=0.3, cls=STONE)
b.superquad(V(0, 1.68, 0), (0.3, 0.26, 0.3), "6a6458", e=0.25, cls=STONE)
for k in range(4):
    a = math.pi / 2 * k
    c = V(math.sin(a) * 0.305, 1.68, math.cos(a) * 0.305)
    b.superquad(c, (0.16 if k % 2 == 0 else 0.012, 0.16, 0.012 if k % 2 == 0 else 0.16), "ffcc70", e=0.3, cls=CLOTH, mat=MAT_GLOW)
b.ball(V(0, 1.68, 0), 0.12, "ffb050", cls=CLOTH, mat=MAT_GLOW, seg=10, rings=6)
# roof: four sweeping planes with upturned corners, mossy on top, and a jewel finial
for k in range(4):
    a = math.pi / 2 * k + math.pi / 4
    rows = []
    for j in range(4):
        t = j / 3
        r = 0.2 + t * 0.55
        lift = 0.06 * t * t * 3
        y = 2.12 - t * 0.3 + lift
        rows.append([V(math.cos(a - 0.78) * r, y, math.sin(a - 0.78) * r), V(math.cos(a) * r * 1.12, y + lift * 0.8, math.sin(a) * r * 1.12), V(math.cos(a + 0.78) * r, y, math.sin(a + 0.78) * r)])
    b.sheet(rows, "5a5a54", cls=STONE, thickness=0.05)
b.lathe(V(0, 2.1, 0), [(0.2, 0.0), (0.1, 0.12), (0.06, 0.2), (0.001, 0.32)], "5a5a54", cls=STONE, seg=8)
b.ellipsoid(V(0, 2.02, 0), (0.42, 0.06, 0.42), "4a6a3a", cls=FOLIAGE, seg=12, rings=5)
# spider lilies offered at the foot
for k in range(5):
    a = rnd.random() * math.pi * 2
    p = V(math.cos(a) * 0.55, 0.0, math.sin(a) * 0.55)
    top = p + V(0, 0.32 + rnd.random() * 0.1, 0)
    b.tube([p, top], [0.008, 0.007], "4a8040", cls=FOLIAGE, seg=4)
    for q in range(6):
        pa = 2 * math.pi * q / 6
        b.leaf(top, top + V(math.cos(pa) * 0.1, 0.05, math.sin(pa) * 0.1), 0.02, "e02018", side=(-math.sin(pa), 0, math.cos(pa)), cls=CLOTH, col_tip="ff5040")
print("[art] stonelantern: %d triangles" % b.tri_count())
kit.finish_static(b, "props/stonelantern.glb", target_tris=2400, samples=12, dist=0.5, strength=0.5)
