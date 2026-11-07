"""Blood Moon obelisk (Blood Moon Palace landmark): a tapering black-stone obelisk on a stepped plinth, carved with glowing crimson runes, ringed with iron spikes and chains, a blood-red crystal burning at its tip.
Run: blender --background --python art/props/obelisk.py  ->  assets/props/obelisk.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from sculpt import bezier  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, METAL, STONE, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(81)
b = Builder("obelisk")
for k in range(3):
    b.superquad(V(0, 0.1 + k * 0.18, 0), (0.75 - k * 0.12, 0.1, 0.75 - k * 0.12), "2a1418", e=0.25, cls=STONE)
b.lathe(V(0, 0.55, 0), [(0.42, 0.0), (0.36, 0.6), (0.3, 1.5), (0.22, 2.5), (0.12, 3.0), (0.001, 3.35)], "20101a", cls=STONE, seg=4, rot=(0, math.pi / 4, 0), col_top="3a1a24")
for k in range(7):
    y = 0.85 + k * 0.33
    w = 0.42 - k * 0.04
    for s in range(4):
        a = math.pi / 2 * s
        c = V(math.sin(a) * w * 0.72, y, math.cos(a) * w * 0.72)
        b.superquad(c, (0.07, 0.07, 0.01), "ff3040", e=0.3, cls=CRYSTAL, rot=(0, a, 0), mat=MAT_GLOW)
for k in range(8):
    a = 2 * math.pi * k / 8
    b.cone(V(math.cos(a) * 0.62, 0.62, math.sin(a) * 0.62), 0.05, 0.4, "3a3438", cls=METAL, seg=5)
for k in range(10):
    a = 2 * math.pi * k / 10
    c = V(math.cos(a) * 0.5, 1.2 - abs(math.sin(a * 2)) * 0.15, math.sin(a) * 0.5)
    b.lathe(c, [(0.03, -0.025), (0.045, 0.0), (0.03, 0.025)], "4a4450", cls=METAL, seg=6, rot=(0, -a, (k % 2) * 1.57), cap_bottom=False, cap_top=False)
b.crystal(V(0, 3.4, 0), 0.12, 0.5, "ff2030", cls=CRYSTAL, sides=6)
b.ball(V(0, 3.55, 0), 0.22, "ff4050", cls=CRYSTAL, mat=MAT_GLOW, seg=10, rings=6)
# detail: chains slung between the iron spikes, a skull offered at the foot, rust streaks under the
# glowing runes
for k in range(8):
    a0 = 2 * math.pi * k / 8
    a1 = 2 * math.pi * (k + 1) / 8
    p0 = V(math.cos(a0) * 0.62, 0.78, math.sin(a0) * 0.62)
    p1 = V(math.cos(a1) * 0.62, 0.78, math.sin(a1) * 0.62)
    sag = bezier(p0, p0 + V(0, -0.12, 0), p1 + V(0, -0.12, 0), p1, 6)
    b.tube(sag, [0.012] * len(sag), "4a4450", cls=METAL, seg=4)
b.ellipsoid(V(0.8, 0.1, 0.3), (0.07, 0.08, 0.09), "d8d0bc", cls=STONE, seg=10, rings=6)
b.ellipsoid(V(0.83, 0.1, 0.37), (0.022, 0.02, 0.01), "1a1010", cls=STONE, seg=6, rings=4)
b.ellipsoid(V(0.77, 0.1, 0.38), (0.022, 0.02, 0.01), "1a1010", cls=STONE, seg=6, rings=4)
for k in range(7):
    y = 0.75 + k * 0.33
    w = 0.42 - k * 0.04
    for s4 in range(4):
        a = math.pi / 2 * s4
        c = V(math.sin(a) * w * 0.73, y - 0.12, math.cos(a) * w * 0.73)
        b.tube([c, c - V(0, 0.16, 0)], [0.012, 0.004], "5a2028", cls=STONE, seg=4)
print("[art] obelisk: %d triangles" % b.tri_count())
kit.finish_static(b, "props/obelisk.glb", target_tris=4000, samples=12, dist=0.6, strength=0.5)
