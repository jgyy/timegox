"""Clockwork gear of the River of Ten Thousand Years (Time landmark): interlocking bronze cogwheels standing on a sandstone pedestal, an hourglass at the centre trickling golden sand.
Run: blender --background --python art/props/gear.py  ->  assets/props/gear.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402

from kit import CRYSTAL, MAT_GLOW, METAL, STONE, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(85)
b = Builder("gear")
b.superquad(V(0, 0.2, 0), (0.7, 0.2, 0.5), "c8a060", e=0.3, cls=STONE)


def cog(c, r, teeth, rot_y, col):
    b.lathe(c, [(r * 0.85, -0.05), (r * 0.85, 0.05)], col, cls=METAL, seg=24, rot=(math.pi / 2, rot_y, 0))
    for k in range(teeth):
        a = 2 * math.pi * k / teeth
        p = c + V(math.cos(a) * r * math.cos(rot_y), math.sin(a) * r, -math.cos(a) * r * math.sin(rot_y))
        b.superquad(p, (0.06, 0.06, 0.05), col, e=0.3, cls=METAL, rot=(0, rot_y, a))
    for k in range(5):
        a = 2 * math.pi * k / 5
        b.tube([c, c + V(math.cos(a) * r * 0.8 * math.cos(rot_y), math.sin(a) * r * 0.8, -math.cos(a) * r * 0.8 * math.sin(rot_y))], [0.035, 0.03], col, cls=METAL, seg=5)
    b.ball(c, r * 0.18, "6a4a20", cls=METAL, seg=10, rings=6)


cog(V(-0.3, 1.5, 0), 0.75, 16, 0.0, "b08a40")
cog(V(0.62, 0.95, 0.05), 0.42, 10, 0.0, "c89a50")
cog(V(0.45, 2.15, -0.05), 0.3, 8, 0.0, "a07a30")
for k in range(2):
    b.tube([V(-0.3 + k * 0.92, 0.4, -0.08), V(-0.3 + k * 0.92, 1.5 - k * 0.55, -0.08)], [0.05, 0.05], "6a4a20", cls=METAL, seg=6)
# hourglass
b.lathe(V(-0.3, 1.5, 0.15), [(0.14, -0.28), (0.13, -0.15), (0.03, 0.0), (0.13, 0.15), (0.14, 0.28)], "e0f0ff", cls=CRYSTAL, seg=12)
b.lathe(V(-0.3, 1.5, 0.15), [(0.1, -0.25), (0.06, -0.1), (0.01, -0.02)], "ffd060", cls=CRYSTAL, seg=10, mat=MAT_GLOW)
# detail: rivets round the hub and the rim, a drive chain hanging off the teeth, and rust bleeding
# from every joint
for k in range(12):
    a = k / 12 * 2 * math.pi
    for rr in (0.25, 0.85):
        b.ball(V(math.cos(a) * rr, 1.1 + math.sin(a) * rr, 0.13), 0.025, "d8b060", cls=METAL, seg=6, rings=4)
A.chain(b, V(0.95, 1.0, 0.0), V(0.02, -0.075, 0.01), 6, None, col="6a5a48", r=0.03)
for k in range(8):
    a = k / 8 * 2 * math.pi
    c = V(math.cos(a) * 0.55, 1.1 + math.sin(a) * 0.55, 0.12)
    b.tube([c, c + V(0, -0.15, 0.002)], [0.015, 0.004], "8a4a20", cls=METAL, seg=4)
print("[art] gear: %d triangles" % b.tri_count())
kit.finish_static(b, "props/gear.glb", target_tris=3800, samples=12, dist=0.6, strength=0.5)
