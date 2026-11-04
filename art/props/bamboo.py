"""Bamboo grove clump (Whispering Bamboo Forest landmark): seven jointed culms of different ages,
each with node rings and sprays of slender leaves at the top.
Run: blender --background --python art/props/bamboo.py  ->  assets/props/bamboo.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import FOLIAGE, WOOD, V, Builder  # noqa: E402

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
print("[art] bamboo: %d triangles" % b.tri_count())
kit.finish_static(b, "props/bamboo.glb", samples=10, dist=0.6, strength=0.45)
