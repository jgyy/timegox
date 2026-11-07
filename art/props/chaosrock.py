"""Chaos rock (Primordial Chaos landmark): a fragment of the unformed world adrift above the
ground, its underside dripping roots of light, Nuwa's five-coloured stones set into its crown and
a ring of pebbles caught in orbit.
Run: blender --background --python art/props/chaosrock.py  ->  assets/props/chaosrock.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402

from kit import CRYSTAL, FOLIAGE, MAT_GLOW, STONE, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(29)
b = Builder("chaosrock")
Y = 1.7
# inverted mountain: a lathe with a jagged profile, then a grassy crown
prof = [(0.001, Y - 1.5), (0.35, Y - 1.2), (0.55, Y - 0.85), (0.85, Y - 0.45), (1.05, Y - 0.1), (1.1, Y + 0.05)]
b.lathe(V(0, 0, 0), prof, "3a2c4a", cls=STONE, seg=9, smooth=False, col_top="5a4a6a", cap_bottom=False)
b.superquad(V(0, Y + 0.12, 0), (1.12, 0.14, 1.05), "6a5a8a", e=0.6, cls=STONE, seg=16, rings=6)
# crystalline glass "grass" on top
for k in range(18):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.2, 0.95)
    p = V(math.cos(a) * rr, Y + 0.24, math.sin(a) * rr)
    b.leaf(p, p + V(rnd.uniform(-0.05, 0.05), rnd.uniform(0.15, 0.35), rnd.uniform(-0.05, 0.05)), 0.03, "8a7ab8", cls=FOLIAGE, col_tip="d0c0ff")
# five-coloured stones of Nuwa
five = ["ff5050", "ffd040", "50a0ff", "f0f0ff", "403050"]
for i, c in enumerate(five):
    a = i / 5 * 2 * math.pi
    b.crystal(V(math.cos(a) * 0.5, Y + 0.2, math.sin(a) * 0.45), 0.11, 0.6, c, rot=(0.25 * math.cos(a), 0, 0.25 * math.sin(a)), sides=5)
    b.ball(V(math.cos(a) * 0.5, Y + 0.5, math.sin(a) * 0.45), 0.08, c, cls=CRYSTAL, seg=8, rings=5, mat=MAT_GLOW)
# roots of light dripping from the underside
for k in range(7):
    a = k / 7 * 2 * math.pi
    top = V(math.cos(a) * 0.5, Y - 0.6, math.sin(a) * 0.5)
    pts = [top, top + V(math.cos(a) * 0.15, -0.4, math.sin(a) * 0.15), top + V(math.cos(a) * 0.1, -0.8, math.sin(a) * 0.1), top + V(0, -1.05, 0)]
    b.tube(pts, [0.03, 0.025, 0.015, 0.004], "ff80d0", cls=CRYSTAL, seg=5, mat=MAT_GLOW)
# pebbles in orbit
for k in range(8):
    a = k / 8 * 2 * math.pi
    b.superquad(V(math.cos(a) * 1.55, Y + 0.3 * math.sin(k * 1.7), math.sin(a) * 1.55), (0.12, 0.09, 0.1), "5a4a6a", e=0.7, cls=STONE, rot=(k, k * 0.7, 0), seg=8, rings=5)
# detail: hewn chunks torn loose and hanging in the air round it, chaos-light leaking from the
# cracks
for k in range(7):
    a = k / 7 * 2 * math.pi
    A.hewn_stone(b, V(math.cos(a) * 1.2, 1.2 + math.sin(a * 2) * 0.5, math.sin(a) * 1.0), (0.22, 0.18, 0.2), None, seed=k + 101, shade=0.4, e=0.4, tint=0.0, rot=(a, a * 0.5, 0), seg=10, rings=6)
for k in range(5):
    a = k / 5 * 2 * math.pi + 0.3
    A.glow_seam(b, [V(math.cos(a) * 0.2, 0.3, math.sin(a) * 0.2), V(math.cos(a) * 0.45, 0.9, math.sin(a) * 0.4), V(math.cos(a + 0.3) * 0.3, 1.5, math.sin(a + 0.3) * 0.3)], 0.014, "ff60e0", None, tint=0.0)
print("[art] chaosrock: %d triangles" % b.tri_count())
kit.finish_static(b, "props/chaosrock.glb", target_tris=3000, samples=12, dist=0.5, strength=0.5)
