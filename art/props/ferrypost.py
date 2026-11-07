"""Ferry post (Starfall Ferry landmark): a weathered mooring post of twisted timber driven into a
heap of river stones, a rope coiled round it, a little boat-roofed lantern holding a fallen star
on its arm, and the reeds that grow up round any post left standing in water long enough.
Run: blender --background --python art/props/ferrypost.py  ->  assets/props/ferrypost.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, WOOD, V, Builder  # noqa: E402
from sculpt import bezier  # noqa: E402

kit.reset()
rnd = random.Random(53)
b = Builder("ferrypost")
# river stones heaped round the foot
for k in range(9):
    a = k / 9 * 2 * math.pi + rnd.uniform(-0.2, 0.2)
    rr = rnd.uniform(0.25, 0.45)
    A.hewn_stone(b, V(math.cos(a) * rr, 0.05, math.sin(a) * rr), (rnd.uniform(0.18, 0.3), rnd.uniform(0.1, 0.18), rnd.uniform(0.16, 0.26)), None, seed=k + 3, shade=0.62, e=0.7, tint=0.0, moss=0.6, seg=12, rings=8)
# the post: twisted, split timber leaning slightly downstream
post = [V(0, -0.2, 0), V(0.03, 0.8, 0.0), V(0.06, 1.7, 0.02), V(0.05, 2.4, 0.03)]
A.bark_limb(b, post, [0.16, 0.14, 0.13, 0.12], "6a5a48", None, seed=4, ridges=7, twist=0.6, tint=0.0, n=12)
b.cone(V(0.05, 2.47, 0.03), 0.13, 0.12, "4a3a2c", cls=WOOD, seg=10)
# rope coiled round the post and trailing into the water
coil = [V(math.cos(t) * 0.16, 0.6 + t * 0.012, math.sin(t) * 0.16) for t in [i * 0.5 for i in range(30)]]
b.tube(coil, [0.022] * len(coil), "c8b088", cls=CLOTH, seg=6)
trail = bezier(coil[-1], coil[-1] + V(0.3, 0.0, 0.2), V(0.7, 0.05, 0.4), V(1.0, -0.05, 0.6), 8)
b.tube(trail, [0.02] * len(trail), "b8a078", cls=CLOTH, seg=6)
# the arm and the lantern with a fallen star inside
arm = [V(0.05, 2.1, 0.03), V(0.5, 2.15, 0.05), V(0.7, 2.08, 0.06)]
b.tube(arm, [0.05, 0.045, 0.04], "5a4a38", cls=WOOD, seg=8)
lc = V(0.7, 1.8, 0.06)
b.tube([arm[-1], lc + V(0, 0.18, 0)], [0.008, 0.008], "3a3028", cls=CLOTH, seg=4)
b.lathe(lc, [(0.13, 0.12), (0.2, 0.16), (0.04, 0.26)], "3a3a40", cls=WOOD, seg=8)
for k in range(4):
    a = k / 4 * 2 * math.pi + math.pi / 4
    b.tube([lc + V(math.cos(a) * 0.1, -0.12, math.sin(a) * 0.1), lc + V(math.cos(a) * 0.1, 0.12, math.sin(a) * 0.1)], [0.012, 0.012], "4a3a2c", cls=WOOD, seg=5)
b.ball(lc, 0.07, "fff4c0", cls=CRYSTAL, seg=10, rings=8, mat=MAT_GLOW)
for k in range(5):
    a = k / 5 * 2 * math.pi
    b.leaf(lc, lc + V(math.cos(a) * 0.1, math.sin(a) * 0.1, 0.0), 0.025, "fff8d8", cls=CRYSTAL, n=3, mat=MAT_GLOW)
b.lathe(lc + V(0, -0.14, 0), [(0.11, 0.0), (0.12, 0.02)], "3a3a40", cls=WOOD, seg=8)
# reeds round the foot
for k in range(18):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.35, 0.7)
    root = V(math.cos(a) * rr, 0.0, math.sin(a) * rr)
    b.leaf(root, root + V(rnd.uniform(-0.15, 0.15), rnd.uniform(0.6, 1.1), rnd.uniform(-0.15, 0.15)), 0.03, "6a8a50", cls=FOLIAGE, col_tip="c0c890", curl=0.1)
print("[art] ferrypost: %d triangles" % b.tri_count())
kit.finish_static(b, "props/ferrypost.glb", samples=12, dist=0.5, strength=0.5, target_tris=2600)
