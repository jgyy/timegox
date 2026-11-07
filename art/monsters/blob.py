"""Blob: the slimes, oozes and formless spawn.  One sculpted drop of gel that sags outwards under
its own weight into a puddle rim, with a softer bulb on top and runnels dripping down its sides
into droplets; the gel is paler and clearer at the top and edges and murkier round the middle
where its core sits, its surface wobbles and wet highlights glint on it.  Swallowed things are
half sunk in it - a skull, coins, a pebble, a sword hilt jutting from the top - with bubbles
welling up through the surface; big glossy eyes and a gaping mouth.  Tinted by the game per enemy.
Run: blender --background --python art/monsters/blob.py  ->  assets/monsters/blob.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, METAL, SKIN, STONE, WOOD, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, smooth  # noqa: E402
from clay import Clay  # noqa: E402
from creature import add  # noqa: E402

kit.reset()
creature.realtime()
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, 0.0, 0), (0, 0.55, 0), "root")
r.bone("top", (0, 0.55, 0), (0, 1.0, 0), "body")
b = Builder("blob")


def bw(p):
    k = max(0.0, min(1.0, (p.y - 0.35) / 0.4))
    return {"body": 1.0 - k, "top": k}


# body: one sculpted drop of slime sagging outwards under its own weight into a puddle rim, a
# softer bulb on top, and runnels of slime dripping down its sides into droplets; the gel is
# paler and clearer at the top and towards its edges, deeper and murkier round its middle where
# the core sits, and its surface wobbles
cl = Clay(0.026, "blob_body")
cl.ellipsoid(V(0, 0.42, 0), (0.62, 0.42, 0.6), bones=lambda p, t: bw(p), tag="body")
cl.ellipsoid(V(0.02, 0.7, -0.02), (0.42, 0.3, 0.4), bones=lambda p, t: bw(p), tag="body")
cl.ellipsoid(V(0, 0.1, 0), (0.8, 0.1, 0.78), bones={"body": 1.0}, tag="puddle")
for k in range(8):
    a = 2 * math.pi * k / 8 + 0.35
    ca, sa = math.cos(a), math.sin(a)
    top = V(ca * 0.5, 0.62 - 0.05 * (k % 3), sa * 0.48)
    bot = V(ca * 0.68, 0.16, sa * 0.66)
    cl.chain([top, top.lerp(bot, 0.5) + V(ca * 0.05, 0, sa * 0.05), bot], [0.07, 0.06, 0.075], bones=lambda p, t: bw(p), tag="drip")
    if k % 2:
        cl.ball(V(ca * 0.86, 0.09, sa * 0.84), 0.07, bones={"body": 1.0}, tag="puddle")


def slime_col(p, info):
    h = smooth(0.1, 0.95, p.y)
    rr = math.hypot(p.x, p.z)
    murk = smooth(0.3, 0.0, abs(p.y - 0.4)) * smooth(0.75, 0.4, rr)
    v = 0.78 + 0.2 * h - 0.18 * murk
    if info.tag in ("drip", "puddle"):
        v = 0.9
    return (v, v, v)


def slime_wobble(p, info):
    w = fbm3((p.x * 3.0, p.y * 3.0, p.z * 3.0), 2, 6) - 0.5
    return info.n * (0.025 * w)


cl.build(b, slime_col, cls=SKIN, tint_fn=lambda p, info: 1.0, post=slime_wobble)
# wet highlights across the top
b.ellipsoid(V(-0.18, 0.95, 0.2), (0.12, 0.035, 0.07), "ffffff", cls=CRYSTAL, bone="top", seg=10, rings=5, rot=(0.6, 0.4, 0.3), mat=MAT_GLOW, tint=0.2)
b.ellipsoid(V(0.2, 0.86, 0.3), (0.05, 0.02, 0.03), "ffffff", cls=CRYSTAL, bone="top", seg=8, rings=4, rot=(0.7, -0.4, -0.3), mat=MAT_GLOW, tint=0.2)
# swallowed things half sunk in the gel: a skull, coins, a pebble and a sword hilt jutting from the
# top, all darkened by the slime, and bubbles welling up through the surface
b.cur_pal = 0.0
A.skull(b, V(-0.33, 0.3, 0.42), 0.9, "body", col="c8c0b0", fwd=V(-0.5, 0.2, 1.0))
for k, (x, y, z, rx) in enumerate(((0.52, 0.28, 0.25, 1.2), (0.58, 0.36, 0.1, 0.5), (0.45, 0.18, 0.42, 1.6))):
    b.lathe(V(x, y, z), [(0.06, -0.008), (0.06, 0.008)], "d8b048", cls=METAL, bone="body", seg=14, rot=(rx, 0, 0.3 * k + 0.8))
b.ball(V(-0.5, 0.22, -0.3), 0.07, "5a5a60", cls=STONE, bone="body", seg=10, rings=6)
b.tube([V(0.15, 0.82, -0.25), V(0.24, 1.08, -0.36)], [0.022, 0.02], "4a3020", cls=WOOD, bone="top", seg=6)
b.ellipsoid(V(0.17, 0.86, -0.27), (0.09, 0.018, 0.025), "c8a048", cls=METAL, bone="top", seg=8, rings=4, rot=(0, 0.6, 0.5))
b.ball(V(0.25, 1.1, -0.37), 0.03, "c8a048", cls=METAL, bone="top", seg=8, rings=5)
b.cur_pal = 0.5
for k in range(12):
    a = k * 2.4
    rr = 0.3 + 0.25 * ((k * 7) % 5) / 5
    y = 0.3 + 0.05 * (k % 9)
    q = V(math.cos(a) * rr, y, math.sin(a) * rr)
    q = q + V(q.x, 0, q.z).normalized() * (0.6 * math.sqrt(max(0.0, 1.0 - ((y - 0.42) / 0.42) ** 2)) - rr)
    b.ball(q, 0.025 + 0.012 * (k % 3), (1.0, 1.0, 1.0), cls=SKIN, bone=bw(q), tint=0.6, seg=8, rings=5)
b.cur_pal = 0.0
# face: big glossy eyes and a gaping mouth with a tongue
for s in (1, -1):
    b.eye(V(0.17 * s, 0.62, 0.5), 0.085, "1a2030", side=s, bone=bw(V(0, 0.6, 0)), rot_y=0.25, h=1.25, accent=True)
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
    k = t / 0.55
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


T_WALK = 0.9


def walk(t):
    """Hops: squashes down, stretches up into the air, lands and splats."""
    k = (t / T_WALK) % 1.0
    p = zero_pose(r)
    air = math.sin(math.pi * smooth(0.25, 0.75, k))
    squash = math.exp(-((k - 0.12) / 0.1) ** 2) + math.exp(-((k - 0.9) / 0.08) ** 2)
    stretch = math.sin(math.pi * smooth(0.22, 0.5, k)) * (1.0 - smooth(0.5, 0.7, k))
    sy = 1.0 - 0.22 * squash + 0.18 * stretch
    sx = 1.0 + 0.16 * squash - 0.1 * stretch
    add(p, "root", (0.12 * stretch - 0.08 * squash, 0, 0), (0, 0.32 * air, 0))
    p["body"] = ((0, 0, 0), (0, 0, 0), (sx, sy, sx))
    p["top"] = ((-0.15 * stretch + 0.1 * squash, 0, 0), (0, 0, 0), (1.0 - 0.05 * stretch, 1.0 + 0.08 * stretch, 1.0 - 0.05 * stretch))
    return p


def die(t):
    """Quivers, then melts into a flat puddle."""
    k = min(1.0, t / 1.2)
    f = smooth(0.15, 0.85, k)
    q = math.sin(k * 30.0) * 0.08 * (1.0 - f)
    p = zero_pose(r)
    p["body"] = ((0, 0, 0), (0, 0, 0), (1.0 + 0.7 * f + q, 1.0 - 0.8 * f - q, 1.0 + 0.7 * f + q))
    p["top"] = ((0.2 * f, 0, 0.1 * f), (0, -0.15 * f, 0), (1.0 + 0.3 * f, 1.0 - 0.6 * f, 1.0 + 0.3 * f))
    return p

print("[art] blob: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/blob.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.35, floor_y=0.0)
