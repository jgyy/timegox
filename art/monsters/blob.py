"""Blob: the slimes and oozes (Marsh Slime, Ember Ooze, Ink Slime ...).  A glossy, wobbling drop of
jelly with a darker core and a few swallowed trinkets floating inside, drips around its base, a
tiny crown of bubbles, and a big-eyed, open-mouthed face.  It squashes and stretches on a
two-bone rig (body plus a top bulb that lags behind it).  Tinted by the game per enemy.
Run: blender --background --python art/monsters/blob.py  ->  assets/monsters/blob.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CRYSTAL, METAL, SKIN, STONE, V, Builder, Rig, env  # noqa: E402

kit.reset()
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, 0.0, 0), (0, 0.55, 0), "root")
r.bone("top", (0, 0.55, 0), (0, 1.0, 0), "body")
b = Builder("blob")


def bw(p):
    k = max(0.0, min(1.0, (p.y - 0.35) / 0.4))
    return {"body": 1.0 - k, "top": k}


b.lathe(V(0, 0, 0), [(0.62, 0.02), (0.68, 0.12), (0.62, 0.35), (0.5, 0.58), (0.32, 0.8), (0.12, 0.93), (0.001, 0.96)], (0.85, 0.85, 0.85), cls=CRYSTAL, seg=28, tint=1.0, col_top=(1.0, 1.0, 1.0), bone_fn=bw, folds=(5, 0.03, 0.0))
# drips and puddle lobes around the base
for k in range(9):
    a = 2 * math.pi * k / 9 + 0.2
    b.ellipsoid(V(math.cos(a) * 0.66, 0.05, math.sin(a) * 0.66), (0.14, 0.06, 0.12), (0.9, 0.9, 0.9), cls=CRYSTAL, bone="body", tint=1.0, seg=10, rings=6, rot=(0, -a, 0))
for k in range(4):
    a = 2 * math.pi * k / 4 + 0.7
    b.ellipsoid(V(math.cos(a) * 0.58, 0.32 - k * 0.04, math.sin(a) * 0.58), (0.05, 0.12, 0.05), (0.95, 0.95, 0.95), cls=CRYSTAL, bone="body", tint=1.0, seg=8, rings=6)
# a darker core and swallowed trinkets (a coin, a bone, a pebble)
b.ellipsoid(V(0, 0.38, -0.05), (0.3, 0.26, 0.28), (0.55, 0.55, 0.55), cls=CRYSTAL, bone=bw(V(0, 0.38, 0)), tint=1.0, seg=14, rings=8)
b.lathe(V(0.15, 0.25, -0.1), [(0.07, -0.01), (0.07, 0.01)], "e8c050", cls=METAL, bone="body", seg=12, rot=(1.2, 0, 0.3))
b.tube([V(-0.2, 0.3, -0.05), V(-0.05, 0.36, -0.12)], [0.025, 0.02], "ece4d0", cls=STONE, bone="body", seg=6)
b.ball(V(0.05, 0.5, -0.15), 0.05, "6a6a70", cls=STONE, bone=bw(V(0, 0.5, 0)), seg=8, rings=5)
# bubbles
for k in range(5):
    a = k * 2.2
    b.ball(V(math.cos(a) * 0.12, 0.92 + 0.04 * (k % 2), math.sin(a) * 0.1), 0.04 + 0.015 * (k % 3), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="top", tint=1.0, seg=8, rings=5)
# face
for s in (1, -1):
    b.eye(V(0.17 * s, 0.6, 0.47), 0.085, "1a2030", side=s, bone=bw(V(0, 0.6, 0)), rot_y=0.25, h=1.25)
b.ellipsoid(V(0, 0.42, 0.56), (0.1, 0.07, 0.04), "401828", cls=SKIN, bone="body", seg=12, rings=6)
b.ellipsoid(V(0, 0.4, 0.58), (0.05, 0.03, 0.02), "e05068", cls=SKIN, bone="body", seg=10, rings=5)

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
