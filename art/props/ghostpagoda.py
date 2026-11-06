"""Ghost pagoda of the Ten Courts (Part VI landmark): a five-tiered black pagoda on a stone terrace,
each eave hung with blue ghost-fire lanterns and wind bells, its finial a stack of bronze rings
around a pearl of cold light.
Run: blender --background --python art/props/ghostpagoda.py  ->  assets/props/ghostpagoda.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CLOTH, MAT_GLOW, METAL, STONE, WOOD, V, Builder  # noqa: E402

kit.reset()
b = Builder("ghostpagoda")
# stone terrace with steps
b.superquad(V(0, 0.12, 0), (1.05, 0.14, 1.05), "4a4a58", e=0.25, cls=STONE)
b.superquad(V(0, 0.3, 0), (0.88, 0.08, 0.88), "5a5a68", e=0.25, cls=STONE)
for k in range(3):
    b.superquad(V(0, 0.05 + k * 0.08, 1.1 + 0.12 * (2 - k)), (0.35, 0.04, 0.08), "4a4a58", e=0.25, cls=STONE)
y = 0.38
w = 0.7
for tier in range(5):
    hgt = 0.62 - tier * 0.06
    # walls with red pillars and a dark door
    b.superquad(V(0, y + hgt * 0.5, 0), (w, hgt * 0.5, w), "1e1e2a", e=0.2, cls=WOOD)
    for c in range(4):
        a = math.pi / 2 * c + math.pi / 4
        b.tube([V(math.cos(a) * w * 1.3, y, math.sin(a) * w * 1.3), V(math.cos(a) * w * 1.3, y + hgt, math.sin(a) * w * 1.3)], [0.05, 0.05], "8a2020", cls=WOOD, seg=6)
    b.superquad(V(0, y + hgt * 0.45, w + 0.005), (w * 0.3, hgt * 0.35, 0.01), "0a0a10", e=0.3, cls=WOOD)
    # eave: four upswept planes
    ey = y + hgt
    ew = w * 1.7
    for k in range(4):
        a = math.pi / 2 * k + math.pi / 4
        rows = []
        for j in range(4):
            t = j / 3
            r = w * 0.5 + t * (ew - w * 0.5)
            lift = 0.12 * t ** 3
            yy = ey + 0.22 - t * 0.28 + lift
            rows.append([V(math.cos(a - 0.78) * r, yy, math.sin(a - 0.78) * r), V(math.cos(a) * r * 1.15, yy + lift, math.sin(a) * r * 1.15), V(math.cos(a + 0.78) * r, yy, math.sin(a + 0.78) * r)])
        b.sheet(rows, "141420", cls=STONE, thickness=0.04)
        # ghost lantern and wind bell at each corner
        corner = V(math.cos(a) * ew * 1.15, ey + 0.06, math.sin(a) * ew * 1.15)
        b.tube([corner, corner + V(0, -0.18, 0)], [0.006, 0.006], "6a6a78", cls=METAL, seg=4)
        b.ellipsoid(corner + V(0, -0.27, 0), (0.07, 0.1, 0.07), "a0e0ff", cls=CLOTH, seg=10, rings=6, mat=MAT_GLOW)
        b.lathe(corner + V(0.05, -0.12, 0.05), [(0.001, 0.0), (0.035, -0.02), (0.04, -0.07)], "b09040", cls=METAL, seg=8, cap_bottom=False)
    y = ey + 0.12
    w *= 0.82
# finial: bronze rings around a pearl of cold light
b.tube([V(0, y, 0), V(0, y + 0.9, 0)], [0.04, 0.025], "b09040", cls=METAL, seg=8)
for k in range(5):
    b.lathe(V(0, y + 0.15 + k * 0.13, 0), [(0.1 - k * 0.012, -0.02), (0.12 - k * 0.012, 0.0), (0.1 - k * 0.012, 0.02)], "c8a050", cls=METAL, seg=12)
b.ball(V(0, y + 0.98, 0), 0.09, "c0f0ff", cls=CLOTH, seg=10, rings=6, mat=MAT_GLOW)
print("[art] ghostpagoda: %d triangles" % b.tri_count())
kit.finish_static(b, "props/ghostpagoda.glb", target_tris=3000, samples=12, dist=0.6, strength=0.5)
