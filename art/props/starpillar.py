"""Star pillar (Palace of the Weaver Star landmark): a slender column of night-blue jade on a
lotus base, its shaft wound with a ribbon of woven starlight, carrying a capital of cloud scrolls
and an armillary ring with a star at its heart.
Run: blender --background --python art/props/starpillar.py  ->  assets/props/starpillar.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, METAL, STONE, V, Builder  # noqa: E402

kit.reset()
b = Builder("starpillar")
# a stepped plinth of hewn jade
A.hewn_stone(b, V(0, 0.08, 0), (1.0, 0.2, 1.0), None, seed=71, shade=0.55, e=0.25, tint=0.0, seg=16, rings=10)
A.hewn_stone(b, V(0, 0.24, 0), (0.75, 0.16, 0.75), None, seed=72, shade=0.6, e=0.25, tint=0.0, seg=16, rings=10)
# lotus base: two rings of petals
for row in range(2):
    for k in range(12):
        a = (k + 0.5 * row) / 12 * 2 * math.pi
        root = V(math.cos(a) * 0.18, 0.34 + 0.05 * row, math.sin(a) * 0.18)
        b.leaf(root, root + V(math.cos(a) * 0.18, 0.14 + 0.06 * row, math.sin(a) * 0.18), 0.08, "8090e0", cls=STONE, col_tip="d0d8ff", curl=-0.25)
# the shaft: fluted jade
shaft = b.lathe(V(0, 0, 0), [(0.16, 0.38), (0.15, 1.2), (0.14, 2.2), (0.13, 3.0)], "3a4080", cls=STONE, seg=20, folds=(10, 0.05, 0.0), col_top="5a60a8")
# a ribbon of starlight spiralling up it
spiral = [V(math.cos(t) * 0.165, 0.5 + t * 0.11, math.sin(t) * 0.165) for t in [i * 0.35 for i in range(68)]]
b.tube(spiral, [0.018] * len(spiral), "c8d8ff", cls=CRYSTAL, seg=5, mat=MAT_GLOW)
for k in range(0, len(spiral), 7):
    b.ball(spiral[k], 0.03, "ffffff", cls=CRYSTAL, seg=6, rings=4, mat=MAT_GLOW)
# capital of cloud scrolls
for k in range(6):
    a = k / 6 * 2 * math.pi
    c = V(math.cos(a) * 0.17, 3.08, math.sin(a) * 0.17)
    scroll = [c + V(math.cos(a) * 0.08 * math.cos(t), 0.06 * math.sin(t), math.sin(a) * 0.08 * math.cos(t)) for t in [i * 0.6 for i in range(9)]]
    b.tube(scroll, [0.03] * 9, "d8c070", cls=METAL, seg=6)
b.lathe(V(0, 3.0, 0), [(0.2, 0.0), (0.26, 0.08), (0.18, 0.16)], "d8c070", cls=METAL, seg=16)
# the armillary ring and its star
top = V(0, 3.55, 0)
for axes in ((0, 1, 2), (0, 2, 1), (1, 2, 0)):
    ring = []
    for i in range(25):
        t = i / 24 * 2 * math.pi
        comp = [0.0, 0.0, 0.0]
        comp[axes[0]] = math.cos(t) * 0.32
        comp[axes[1]] = math.sin(t) * 0.32
        ring.append(top + V(*comp))
    b.tube(ring, [0.016] * 25, "e8d080", cls=METAL, seg=5, cap0=False, cap1=False)
b.tube([V(0, 3.16, 0), top], [0.03, 0.02], "d8c070", cls=METAL, seg=8)
b.ball(top, 0.11, "f0f4ff", cls=CRYSTAL, seg=12, rings=8, mat=MAT_GLOW)
for k in range(8):
    a = k / 8 * 2 * math.pi
    b.leaf(top, top + V(math.cos(a) * 0.22, math.sin(a) * 0.22, 0.0), 0.04, "fff8e0", cls=CRYSTAL, n=3, mat=MAT_GLOW)
print("[art] starpillar: %d triangles" % b.tri_count())
kit.finish_static(b, "props/starpillar.glb", samples=12, dist=0.6, strength=0.5, target_tris=3000)
