"""Blob: the slimes, oozes and formless spawn.  A slumped drop of slime that sags outwards
under its own weight with a wobbling surface and a wet highlight, puddle lobes and hanging strands
with droplets round its base, a murky core full of swallowed things (coins, a skull, a pebble, a
sword hilt) and rising bubbles, glossy eyes and a gaping mouth.  Tinted by the game per enemy.
Run: blender --background --python art/monsters/blob.py  ->  assets/monsters/blob.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, METAL, SKIN, STONE, WOOD, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, morph_sphere, smooth, strand  # noqa: E402

kit.reset()
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, 0.0, 0), (0, 0.55, 0), "root")
r.bone("top", (0, 0.55, 0), (0, 1.0, 0), "body")
b = Builder("blob")


def bw(p):
    k = max(0.0, min(1.0, (p.y - 0.35) / 0.4))
    return {"body": 1.0 - k, "top": k}


# body: a slumped drop of slime, sagging outwards at the bottom under its own weight, its surface
# wobbling with noise, clearer at the top and murkier below
def blob_shape(d):
    p = V(d.x * 0.64, d.y * 0.48, d.z * 0.62)
    sag = smooth(0.4, -0.9, d.y)
    p.x *= 1.0 + 0.16 * sag
    p.z *= 1.0 + 0.16 * sag
    p = p * (1.0 + 0.06 * (fbm3((d.x * 2.5, d.y * 2.5, d.z * 2.5), 2, 6) - 0.5))
    if d.y < -0.6:
        p.y = -0.46 + (p.y + 0.46) * 0.3
    return p


morph_sphere(b, V(0, 0.47, 0), blob_shape, lambda p, d: (0.75 + 0.25 * smooth(-0.6, 0.8, d.y),) * 3, cls=CRYSTAL, seg=32, rings=20, bone_fn=bw, tint_fn=lambda p, d: 1.0)
# a wet highlight across the top
b.ellipsoid(V(-0.18, 0.86, 0.22), (0.12, 0.04, 0.08), "ffffff", cls=CRYSTAL, bone="top", seg=10, rings=5, rot=(0.6, 0.4, 0.3), mat=MAT_GLOW, tint=0.2)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# drips and puddle lobes around the base, with a few hanging strands and droplets
for k in range(11):
    a = 2 * math.pi * k / 11 + 0.2
    b.ellipsoid(V(math.cos(a) * 0.7, 0.04, math.sin(a) * 0.7), (0.15, 0.05, 0.12), (0.9, 0.9, 0.9), cls=CRYSTAL, bone="body", tint=1.0, seg=10, rings=6, rot=(0, -a, 0))
for k in range(5):
    a = 2 * math.pi * k / 5 + 0.7
    top = V(math.cos(a) * 0.62, 0.42 - k * 0.04, math.sin(a) * 0.62)
    strand(b, [top, top + V(math.cos(a) * 0.04, -0.12, math.sin(a) * 0.04), top + V(math.cos(a) * 0.05, -0.25, math.sin(a) * 0.05)], 0.05, 0.02, (0.95, 0.95, 0.95), cls=CRYSTAL, bone="body", seg=8, per=3, tint=1.0)
    b.ball(top + V(math.cos(a) * 0.05, -0.3, math.sin(a) * 0.05), 0.035, (0.95, 0.95, 0.95), cls=CRYSTAL, bone="body", tint=1.0, seg=8, rings=6)
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# a darker core and swallowed trinkets (coins, a skull, a pebble, a sword hilt)
b.ellipsoid(V(0, 0.38, -0.05), (0.3, 0.26, 0.28), (0.55, 0.55, 0.55), cls=CRYSTAL, bone=bw(V(0, 0.38, 0)), tint=1.0, seg=14, rings=8)
for k, (x, y, z, rx) in enumerate(((0.15, 0.25, -0.1, 1.2), (0.22, 0.3, 0.05, 0.4), (0.1, 0.2, 0.15, 2.0))):
    b.lathe(V(x, y, z), [(0.06, -0.008), (0.06, 0.008)], "e8c050", cls=METAL, bone="body", seg=14, rot=(rx, 0, 0.3 * k))
A.skull(b, V(-0.18, 0.36, -0.06), 0.9, "body", col="e8e0cc", fwd=V(0.4, 0.2, 1.0))
b.ball(V(0.05, 0.5, -0.15), 0.05, "6a6a70", cls=STONE, bone=bw(V(0, 0.5, 0)), seg=8, rings=5)
b.tube([V(0.25, 0.55, -0.2), V(0.35, 0.72, -0.25)], [0.02, 0.018], "4a3020", cls=WOOD, bone=bw(V(0, 0.6, 0)), seg=6)
b.ellipsoid(V(0.25, 0.55, -0.2), (0.07, 0.015, 0.02), "d8b050", cls=METAL, bone="body", seg=8, rings=4, rot=(0, 0, 0.6))
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# bubbles rising inside
for k in range(9):
    a = k * 2.2
    b.ball(V(math.cos(a) * (0.08 + 0.03 * k), 0.5 + 0.05 * k, math.sin(a) * 0.12), 0.025 + 0.012 * (k % 3), (1.0, 1.0, 1.0), cls=CRYSTAL, bone=bw(V(0, 0.5 + 0.05 * k, 0)), tint=1.0, seg=8, rings=5)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# face: big glossy eyes and a gaping mouth with a tongue
for s in (1, -1):
    b.eye(V(0.17 * s, 0.62, 0.5), 0.085, "1a2030", side=s, bone=bw(V(0, 0.6, 0)), rot_y=0.25, h=1.25)
b.ellipsoid(V(0, 0.42, 0.58), (0.11, 0.075, 0.04), "401828", cls=SKIN, bone="body", seg=12, rings=6)
b.ellipsoid(V(0, 0.4, 0.6), (0.055, 0.03, 0.02), "e05068", cls=SKIN, bone="body", seg=10, rings=5)

T_IDLE = 1.6


def wob(p, t, speed, amp):
    s = math.sin(t * speed)
    p["body"] = ((0, 0, 0), (0, 0, 0), (1.0 + amp * s, 1.0 - amp * s, 1.0 + amp * s))
    p["top"] = ((math.sin(t * speed - 0.8) * amp * 0.6, 0, math.cos(t * speed - 0.8) * amp * 0.5), (0, 0, 0), (1.0 - amp * 0.5 * s, 1.0 + amp * 0.5 * s, 1.0 - amp * 0.5 * s))


def idle(t):
    p = zero_pose(r)
    wob(p, t, 2 * math.pi / T_IDLE, 0.06)
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    hop = math.sin(min(1.0, k * 1.5) * math.pi)
    p = zero_pose(r)
    wob(p, t, 14.0, 0.12 * e)
    p["root"] = ((0.2 * hop, 0, 0), (0, 0.5 * hop, 0.55 * hop))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = zero_pose(r)
    p["body"] = ((0, 0, 0), (0, 0, 0), (1.0 + 0.25 * e, 1.0 - 0.3 * e, 1.0 + 0.25 * e))
    p["top"] = ((-0.4 * e, 0, 0.3 * e), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = zero_pose(r)
    wob(p, t, 20.0, 0.08)
    p["body"] = ((0, t * 6.0, 0), (0, 0, 0), (1.0 - 0.15 * e, 1.0 + 0.35 * e, 1.0 - 0.15 * e))
    return p


print("[art] blob: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/blob.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.35, floor_y=0.0)
