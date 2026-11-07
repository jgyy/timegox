"""Glowcap cluster (Glowcap Vale landmark): three giant mushrooms with frilled gills, spotted caps
that glow from inside, shelf fungi on the stems and moss at their feet.
Run: blender --background --python art/props/glowcap.py  ->  assets/props/glowcap.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402

from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, SKIN, V, Builder, darken, lighten  # noqa: E402

kit.reset()
rnd = random.Random(17)
b = Builder("glowcap")
CAPS = ["b060e0", "d070c0", "7060e0"]
for k, (ox, oz, hgt, cr) in enumerate(((0.0, 0.0, 3.0, 1.35), (0.95, 0.45, 1.9, 0.85), (-0.75, 0.55, 1.3, 0.62))):
    base = V(ox, 0, oz)
    lean = V(rnd.uniform(-0.15, 0.15), 0, rnd.uniform(-0.15, 0.15))
    stem = [base, base + V(0, hgt * 0.35, 0) + lean * 0.3, base + V(0, hgt * 0.7, 0) + lean * 0.7, base + V(0, hgt, 0) + lean]
    b.tube(stem, [0.32 * cr, 0.22 * cr, 0.19 * cr, 0.18 * cr], "ece4d4", cls=SKIN, seg=9, cap0=False)
    top = stem[-1]
    cap = CAPS[k]
    b.lathe(top + V(0, -0.08, 0), [(0.15, 0.0), (cr, 0.1), (cr * 1.02, 0.26), (cr * 0.82, 0.5), (cr * 0.45, 0.72), (0.001, 0.8)], cap, cls=CLOTH, seg=16, col_top=lighten(cap, 0.25), cap_bottom=False)
    # gills
    for i in range(12):
        a = 2 * math.pi * i / 12
        b.leaf(top + V(math.sin(a) * 0.15, -0.05, math.cos(a) * 0.15), top + V(math.sin(a) * cr * 0.95, 0.05, math.cos(a) * cr * 0.95), 0.03 * cr, "f0e0d8", cls=FOLIAGE, side=(math.cos(a), 0, -math.sin(a)), curl=0.0, n=3)
    # glowing spots
    for i in range(8):
        a = rnd.uniform(0, 2 * math.pi)
        rr = rnd.uniform(0.15, 0.85) * cr
        y = 0.8 * (1.0 - (rr / (cr * 1.02)) ** 2) - 0.05
        c = top + V(math.sin(a) * rr, y, math.cos(a) * rr)
        n = (c - (top + V(0, -0.4 * cr, 0))).normalized()
        b.ellipsoid(c, (0.07 * cr, 0.015, 0.07 * cr), "80ffe0", cls=CRYSTAL, rot=(math.atan2(n.z, n.y), 0, -math.atan2(n.x, n.y)), seg=6, rings=3, mat=MAT_GLOW)
    # shelf fungi on the stem
    for i in range(3):
        a = rnd.uniform(0, 2 * math.pi)
        y = hgt * (0.2 + 0.2 * i)
        c = base + lean * (y / hgt) + V(math.sin(a) * 0.2 * cr, y, math.cos(a) * 0.2 * cr)
        b.ellipsoid(c + V(math.sin(a) * 0.08, 0, math.cos(a) * 0.08), (0.15 * cr, 0.03, 0.15 * cr), darken(cap, 0.2), cls=CLOTH, seg=12, rings=5)
# moss mound and little sprouts with glowing tips
b.lathe(V(0, 0, 0), [(1.4, -0.05), (1.1, 0.08), (0.5, 0.14), (0.001, 0.15)], "3a4a6a", cls=FOLIAGE, seg=20, cap_bottom=False)
for i in range(8):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.4, 1.3)
    p = V(math.cos(a) * rr, 0.08, math.sin(a) * rr)
    tip = p + V(0, rnd.uniform(0.12, 0.3), 0)
    b.tube([p, tip], [0.015, 0.01], "c8e0e0", cls=FOLIAGE, seg=5)
    b.ball(tip, 0.035, "60ffd0", cls=CRYSTAL, seg=8, rings=5, mat=MAT_GLOW)
# detail: fine radial gills under the great cap, a ring on the stem, spores drifting up in glowing
# motes and a cluster of tiny caps at the foot
for k in range(36):
    a = k / 36 * 2 * math.pi
    b.leaf(V(math.cos(a) * 0.2, 1.62, math.sin(a) * 0.2), V(math.cos(a) * 0.9, 1.72, math.sin(a) * 0.9), 0.02, "f0c8a0", cls=FOLIAGE, side=(math.sin(a), 0, -math.cos(a)), n=3, curl=0.0)
ring = [V(math.cos(t) * 0.24, 1.3, math.sin(t) * 0.24) for t in [i / 16 * 2 * math.pi for i in range(17)]]
b.tube(ring, [0.02] * 17, "f8e0c0", cls=SKIN, seg=4, cap0=False, cap1=False)
for k in range(10):
    b.ball(V(rnd.uniform(-0.8, 0.8), rnd.uniform(1.9, 3.0), rnd.uniform(-0.8, 0.8)), 0.025, "ffb060", cls=CRYSTAL, seg=5, rings=3, mat=MAT_GLOW)
for k in range(6):
    a = rnd.uniform(0, 2 * math.pi)
    c = V(math.cos(a) * 0.55, 0.0, math.sin(a) * 0.55)
    b.tube([c, c + V(0, 0.12, 0)], [0.02, 0.018], "f0e0c8", cls=SKIN, seg=6)
    b.ellipsoid(c + V(0, 0.14, 0), (0.06, 0.03, 0.06), "ff9a50", cls=CRYSTAL, seg=8, rings=5, mat=MAT_GLOW)
print("[art] glowcap: %d triangles" % b.tri_count())
kit.finish_static(b, "props/glowcap.glb", samples=14, dist=0.5, strength=0.5, target_tris=3200)
