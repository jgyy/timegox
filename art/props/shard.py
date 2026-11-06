"""Void shard (Void Rift landmark): a cluster of violet crystal blades bursting from a dark rock, one great shard tilted and hovering, star-motes caught inside, a crack of light in the ground.
Run: blender --background --python art/props/shard.py  ->  assets/props/shard.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, METAL, STONE, WOOD, V, Builder  # noqa: E402

kit.reset()
rnd = random.Random(88)
b = Builder("shard")
b.superquad(V(0, 0.18, 0), (0.7, 0.22, 0.6), "201830", e=0.6, cls=STONE)
for k in range(7):
    a = 2 * math.pi * k / 7 + rnd.random() * 0.4
    tilt = 0.25 + rnd.random() * 0.35
    b.crystal(V(math.cos(a) * 0.35, 0.3, math.sin(a) * 0.3), 0.1 + rnd.random() * 0.08, 0.8 + rnd.random() * 1.2, "8a5ae8" if k % 2 else "b48aff", cls=CRYSTAL, rot=(math.sin(a) * tilt, 0, -math.cos(a) * tilt), sides=5)
b.crystal(V(0.1, 1.6, 0.0), 0.32, 2.4, "a070ff", cls=CRYSTAL, rot=(0.15, 0.4, 0.2), sides=6)
for k in range(9):
    b.ball(V(rnd.uniform(-0.12, 0.25), rnd.uniform(1.3, 2.4), rnd.uniform(-0.12, 0.12)), 0.03, "ffffff", cls=CRYSTAL, mat=MAT_GLOW, seg=6, rings=4)
b.superquad(V(0, 0.42, 0.0), (0.5, 0.01, 0.04), "d0b0ff", e=0.3, cls=CRYSTAL, mat=MAT_GLOW, rot=(0, 0.7, 0))
print("[art] shard: %d triangles" % b.tri_count())
kit.finish_static(b, "props/shard.glb", target_tris=2000, samples=12, dist=0.6, strength=0.45)
