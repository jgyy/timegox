"""Heaven's Forge furnace (Forge landmark): a squat brick-and-iron furnace with a glowing mouth, a riveted chimney belching sparks, bellows, an anvil and a rack of glowing ingots.
Run: blender --background --python art/props/furnace.py  ->  assets/props/furnace.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402

from kit import CLOTH, CRYSTAL, MAT_GLOW, METAL, STONE, V, WOOD, Builder  # noqa: E402

kit.reset()
rnd = random.Random(84)
b = Builder("furnace")
b.lathe(V(0, 0, 0), [(0.75, 0.0), (0.78, 0.6), (0.66, 1.2), (0.42, 1.6), (0.3, 1.7)], "7a4a3a", cls=STONE, seg=12, folds=(12, 0.03, 0.0))
for k in range(4):
    b.lathe(V(0, 0.25 + k * 0.38, 0), [(0.8 - k * 0.07, -0.03), (0.81 - k * 0.07, 0.0), (0.8 - k * 0.07, 0.03)], "3a3430", cls=METAL, seg=14, cap_bottom=False, cap_top=False)
    for r in range(12):
        a = 2 * math.pi * r / 12
        b.ball(V(math.cos(a) * (0.81 - k * 0.07), 0.25 + k * 0.38, math.sin(a) * (0.81 - k * 0.07)), 0.025, "6a6058", cls=METAL, seg=6, rings=4)
b.superquad(V(0, 0.45, 0.68), (0.3, 0.26, 0.1), "ffa030", e=0.4, cls=CRYSTAL, mat=MAT_GLOW)
b.superquad(V(0, 0.45, 0.72), (0.38, 0.33, 0.04), "2a2420", e=0.4, cls=METAL)
b.lathe(V(0, 1.65, 0), [(0.26, 0.0), (0.22, 1.6), (0.3, 1.75), (0.3, 1.9)], "4a3a30", cls=METAL, seg=10)
b.ball(V(0, 2.05, 0), 0.22, "ff8020", cls=CRYSTAL, mat=MAT_GLOW, seg=10, rings=6)
# bellows and anvil
b.superquad(V(-0.95, 0.35, 0.2), (0.25, 0.12, 0.35), "6a4430", e=0.5, cls=WOOD, rot=(0, 0.4, 0.2))
b.tube([V(-0.8, 0.35, 0.45), V(-0.6, 0.4, 0.62)], [0.04, 0.03], "3a3430", cls=METAL, seg=6)
b.superquad(V(0.95, 0.3, 0.4), (0.15, 0.3, 0.12), "5a4a3a", e=0.4, cls=WOOD)
b.superquad(V(0.95, 0.65, 0.4), (0.3, 0.07, 0.13), "4a4a54", e=0.3, cls=METAL)
for k in range(3):
    b.superquad(V(-0.4 + k * 0.25, 0.08, 0.95), (0.1, 0.05, 0.06), "ffc860", e=0.4, cls=CRYSTAL, mat=MAT_GLOW)
# detail: the furnace's brick courses hewn and soot-stained, a heap of coal glowing at the stoke
# hole, bellows on its stand, and sparks rising from the flue
for k in range(10):
    a = k / 10 * 2 * math.pi
    A.hewn_stone(b, V(math.cos(a) * 0.72, 0.1, math.sin(a) * 0.72), (0.28, 0.2, 0.18), None, seed=k + 81, shade=0.4, e=0.35, tint=0.0, rot=(0, -a, 0), seg=8, rings=6)
for k in range(9):
    b.ellipsoid(V(0.55 + rnd.uniform(-0.15, 0.15), 0.05 + rnd.uniform(0, 0.08), 0.5 + rnd.uniform(-0.15, 0.15)), (0.06, 0.05, 0.06), "2a2020" if k % 3 else "ff7020", cls=STONE, seg=6, rings=4, mat=MAT_GLOW if k % 3 == 0 else 0)
b.superquad(V(-0.8, 0.35, 0.3), (0.2, 0.08, 0.14), "6a4a30", e=0.5, cls=CLOTH, rot=(0, 0.5, 0.2))
b.tube([V(-0.65, 0.35, 0.38), V(-0.45, 0.32, 0.45)], [0.03, 0.02], "5a5a60", cls=METAL, seg=6)
for k in range(8):
    b.ball(V(rnd.uniform(-0.15, 0.15), 2.8 + k * 0.18, rnd.uniform(-0.15, 0.15)), 0.025, "ffb040", cls=CRYSTAL, seg=5, rings=3, mat=MAT_GLOW)
print("[art] furnace: %d triangles" % b.tri_count())
kit.finish_static(b, "props/furnace.glb", target_tris=3800, samples=12, dist=0.6, strength=0.5)
