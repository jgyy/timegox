"""Bamboo grove clump (Whispering Bamboo Forest landmark): seven jointed culms of different ages,
each with node rings and sprays of slender leaves at the top.
Run: blender --background --python art/props/bamboo.py  ->  assets/props/bamboo.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402

from kit import FOLIAGE, V, WOOD, Builder  # noqa: E402

kit.reset()
rnd = random.Random(43)
b = Builder("bamboo")
for k in range(7):
    a = k * 2.4
    rr = 0.1 + (k % 3) * 0.18
    base = V(math.cos(a) * rr, -0.05, math.sin(a) * rr)
    h = rnd.uniform(3.2, 5.0)
    lean = V(math.cos(a) * 0.25, 0, math.sin(a) * 0.25) * rnd.uniform(0.5, 1.2)
    pts = [base + lean * (t * t) + V(0, h * t, 0) for t in (0.0, 0.33, 0.66, 1.0)]
    green = ["6aa84a", "7ab858", "8ac060", "5a9a40"][k % 4]
    r0 = rnd.uniform(0.055, 0.08)
    b.tube(pts, [r0, r0 * 0.95, r0 * 0.85, r0 * 0.6], green, cls=WOOD, seg=8, cap0=False)
    # node rings every half metre
    for j in range(1, int(h / 0.5)):
        t = j * 0.5 / h
        c = base + lean * (t * t) + V(0, h * t, 0)
        b.cyl(c, r0 * 1.12 * (1 - 0.35 * t), 0.035, "c8d890" if k % 2 else "a8c070", cls=WOOD, seg=8)
    # leaf sprays near the top
    top = pts[-1]
    for i in range(7):
        a2 = i / 7 * 2 * math.pi + k
        root = top + V(0, -rnd.uniform(0.0, 0.9), 0)
        tip = root + V(math.cos(a2) * 0.55, rnd.uniform(-0.3, 0.05), math.sin(a2) * 0.55)
        b.leaf(root, tip, 0.06, "5aa848", cls=FOLIAGE, col_tip="a8e070", curl=0.1, n=4)
# detail: veined leaf sprays at the nodes, papery sheaths, new shoots pushing up at the foot and
# fallen leaves on the ground
for k in range(8):
    y = rnd.uniform(1.0, 3.2)
    a = rnd.uniform(0, 2 * math.pi)
    root = V(rnd.uniform(-0.25, 0.25), y, rnd.uniform(-0.25, 0.25))
    for j in range(2):
        aa = a + (j - 0.5) * 0.6
        A.veined_leaf(b, root, root + V(math.cos(aa) * 0.3, -0.06, math.sin(aa) * 0.3), 0.04, "5aa040", None, tint=0.0, col_tip="8ac860", curl=0.1)
for k in range(5):
    a = k / 5 * 2 * math.pi + 0.4
    c = V(math.cos(a) * 0.45, 0.0, math.sin(a) * 0.45)
    b.cone(c + V(0, 0.15, 0), 0.06, 0.3, "8a7a40", cls=WOOD, seg=8)
    b.leaf(c + V(0, 0.1, 0), c + V(0.03, 0.32, 0.02), 0.04, "a89a60", cls=FOLIAGE, n=3)
for k in range(14):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.2, 0.8)
    p0 = V(math.cos(a) * rr, 0.01, math.sin(a) * rr)
    b.leaf(p0, p0 + V(math.cos(a + 1) * 0.12, 0.005, math.sin(a + 1) * 0.12), 0.02, "c8b070", cls=FOLIAGE, n=3, curl=0.02)
print("[art] bamboo: %d triangles" % b.tri_count())
kit.finish_static(b, "props/bamboo.glb", samples=10, dist=0.6, strength=0.45, target_tris=4000)
