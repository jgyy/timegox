"""Storm: the Heavenly Tribulation itself, the Lightning Magistrate's thunderheads and the First
Lightning.  A towering anvil-shaped storm cloud built from billowing puffs, darker underneath,
with two blazing eyes in the murk, a frowning brow of cloud, crackling bolts forking down from its
belly and a halo ring of runes turning around it.  Arms of cloud reach out to strike.
Tinted by the game per enemy; the lightning and eyes keep their own glow.
Run: blender --background --python art/monsters/storm.py  ->  assets/monsters/storm.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CLOTH, MAT_GLOW, SKIN, V, Builder, Rig, env  # noqa: E402

kit.reset()
rnd = random.Random(7)
Y = 2.0
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, Y - 0.6, 0), (0, Y + 0.8, 0), "root")
r.bone("halo", (0, Y + 0.2, 0), (0, Y + 0.5, 0), "body")
r.bone("bolts", (0, Y - 0.6, 0), (0, 0.1, 0), "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm." + sd, (0.7 * s, Y + 0.1, 0.1), (1.3 * s, Y - 0.3, 0.6), "body")
b = Builder("storm")

# billowing cloud mass: an anvil top, a heavy middle and a darker, ragged base
for k in range(26):
    a = rnd.random() * 2 * math.pi
    layer = k % 3
    rr = (0.75, 0.55, 0.95)[layer] * (0.7 + 0.5 * rnd.random())
    y = Y + (-0.35, 0.25, 0.75)[layer] + rnd.uniform(-0.15, 0.15)
    rad = (0.45, 0.35, 0.55)[layer]
    shade = (0.55, 0.8, 1.0)[layer]
    b.ellipsoid(V(math.cos(a) * rr, y, math.sin(a) * rr * 0.75), (rad, rad * 0.8, rad), (shade, shade, shade), cls=CLOTH, bone="body", tint=1.0, seg=12, rings=8, col2=(shade * 0.7, shade * 0.7, shade * 0.7))
# face: a frowning brow of cloud and two glowing eyes
b.tube([V(-0.4, Y + 0.35, 0.72), V(-0.1, Y + 0.25, 0.82), V(0.1, Y + 0.25, 0.82), V(0.4, Y + 0.35, 0.72)], [0.12, 0.14, 0.14, 0.12], (0.6, 0.6, 0.6), cls=CLOTH, bone="body", tint=1.0, seg=10)
for s in (1, -1):
    b.ellipsoid(V(0.2 * s, Y + 0.12, 0.84), (0.11, 0.06, 0.04), "fffce0", cls=SKIN, bone="body", seg=12, rings=6, mat=MAT_GLOW)
    b.ellipsoid(V(0.2 * s, Y + 0.12, 0.82), (0.2, 0.12, 0.05), "a0c0ff", cls=SKIN, bone="body", seg=12, rings=6, mat=MAT_GLOW)
# cloud arms
for s, sd in ((1, "L"), (-1, "R")):
    ar = r.bones["arm." + sd]
    for k in range(4):
        t = k / 3
        c = V(ar[0]).lerp(V(ar[1]), t)
        b.ellipsoid(c, (0.3 - 0.05 * k, 0.25 - 0.04 * k, 0.28 - 0.05 * k), (0.75, 0.75, 0.75), cls=CLOTH, bone="arm." + sd, tint=1.0, seg=10, rings=7)
# forked lightning under the cloud
for k in range(5):
    x0 = rnd.uniform(-0.6, 0.6)
    z0 = rnd.uniform(-0.3, 0.4)
    pts = [V(x0, Y - 0.6, z0)]
    for j in range(5):
        pts.append(pts[-1] + V(rnd.uniform(-0.25, 0.25), -0.32, rnd.uniform(-0.15, 0.15)))
    b.tube(pts, [0.035] * len(pts), "f4f8ff", cls=CLOTH, bone="bolts", seg=5, mat=MAT_GLOW)
    b.tube(pts, [0.08] * len(pts), "6080ff", cls=CLOTH, bone="bolts", seg=5, mat=MAT_GLOW)
    fork = pts[2]
    b.tube([fork, fork + V(0.3, -0.25, 0.05), fork + V(0.45, -0.55, 0.0)], [0.025, 0.02, 0.005], "e8f0ff", cls=CLOTH, bone="bolts", seg=4, mat=MAT_GLOW)
# halo of runes
for k in range(24):
    a = 2 * math.pi * k / 24
    c = V(math.cos(a) * 1.5, Y + 0.3, math.sin(a) * 1.5)
    b.superquad(c, (0.07, 0.07, 0.015) if k % 3 else (0.05, 0.11, 0.015), "ffe890", e=0.3, cls=CLOTH, bone="halo", rot=(0, -a + math.pi / 2, 0), mat=MAT_GLOW)

T_IDLE = 3.0


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    p["body"] = ((0, math.sin(t * w * 0.5) * 0.08, 0), (0, math.sin(t * w) * 0.1, 0), (1.0 + 0.03 * math.sin(t * w * 2), 1.0 + 0.03 * math.sin(t * w * 2 + 1.0), 1.0))
    p["halo"] = ((0.15, t * w * 0.5, 0), (0, 0, 0))
    p["bolts"] = ((0, 0, 0), (0, 0, 0), (1.0, 0.6 + 0.4 * abs(math.sin(t * w * 4.7)), 1.0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((math.sin(t * w + s) * 0.15, 0, math.sin(t * w * 0.7) * 0.15 * s), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    p = idle(0.0)
    p["body"] = ((0.25 * e, 0, 0), (0, 0, 0.3 * math.sin(min(1.0, k * 1.6) * math.pi)), (1.0 + 0.15 * e, 1.0 + 0.15 * e, 1.0 + 0.15 * e))
    p["bolts"] = ((0, 0, 0), (0, 0, 0), (1.0 + 0.3 * e, 1.0 + 0.6 * e, 1.0 + 0.3 * e))
    for sd in ("L", "R"):
        p["arm." + sd] = ((-1.0 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["body"] = ((-0.2 * e, 0, 0.2 * e), (0, 0, -0.15 * e), (1.0 - 0.15 * e, 1.0 - 0.15 * e, 1.0 - 0.15 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["halo"] = ((0.15, t * 14.0, 0), (0, 0.4 * e, 0), (1.0 + 0.4 * e, 1.0, 1.0 + 0.4 * e))
    p["bolts"] = ((0, t * 5.0, 0), (0, 0, 0), (1.0 + 0.5 * e, 1.3, 1.0 + 0.5 * e))
    return p


print("[art] storm: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/storm.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=10, dist=0.35, strength=0.45)
