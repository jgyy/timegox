"""Blob: the slimes, oozes and formless spawn (Mire Toads, Magma Slimes, Bog Colossi, Taisui ...).

Designed silhouette first, after the slime of Dragon Quest (one feature that names it even when
it is small: Toriyama's teardrop): a drop of gel that sags outwards under its own weight into a
puddle rim, its top drawn up into a curled drip-tip.  The game has no transparent material, so
the gel is an opaque, glossy drop that *reads* as clear by its values: lit and pale on top, a
murky core band low in the middle where the light does not reach, the thin edge and the puddle
lighter again where light passes through, crisp white glints where it is wet, bubbles welling
up under the skin, and swallowed things - Chinese cash coins with square holes, a skull - only
half sunk, tinted by the gel they sit in.  Big simple eyes and a wide D-shaped grin painted on
the surface (not a hole).  Tinted by the game per enemy.
Run: blender --background --python art/monsters/blob.py  ->  assets/monsters/blob.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay  # noqa: E402
from creature import add, zero_pose  # noqa: E402
from elemental import decal  # noqa: E402
from kit import CLOTH, MAT_GLOW, MAT_PLAIN, METAL, SKIN, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, smooth  # noqa: E402

kit.reset()
creature.realtime()
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, 0.0, 0), (0, 0.55, 0), "root")
r.bone("head", (0, 0.5, 0.3), (0, 0.7, 0.45), "body")
r.bone("top", (0, 0.55, 0), (0, 1.0, 0), "body")
b = Builder("blob")


def bw(p):
    k = max(0.0, min(1.0, (p.y - 0.42) / 0.4))
    return {"body": 1.0 - k, "top": k}


# ---------------------------------------------------------------- the drop of gel
cl = Clay(0.024, "blob_body")
cl.ellipsoid(V(0, 0.38, 0), (0.62, 0.38, 0.6), bones=lambda p, t: bw(p), tag="body")
cl.ellipsoid(V(0.0, 0.64, -0.02), (0.42, 0.3, 0.4), bones=lambda p, t: bw(p), tag="body")
# the drip-tip drawn up from the top and curling back: the one shape that names it
cl.chain([V(0.0, 0.84, -0.03), V(0.01, 0.98, -0.05), V(-0.02, 1.08, -0.12), V(-0.06, 1.1, -0.2)], [0.16, 0.1, 0.06, 0.035],
         bones=lambda p, t: {"top": 1.0}, tag="tip")
cl.ellipsoid(V(0, 0.07, 0), (0.8, 0.08, 0.78), bones={"body": 1.0}, tag="puddle")
# a few runnels hugging the flanks down into the puddle (on the surface, so they leave no dark gaps)
for k in range(6):
    a = 2 * math.pi * k / 6 + 0.6
    ca, sa = math.cos(a), math.sin(a)
    cl.chain([V(ca * 0.5, 0.5, sa * 0.48), V(ca * 0.6, 0.3, sa * 0.58), V(ca * 0.7, 0.12, sa * 0.68)], [0.05, 0.06, 0.07], bones=lambda p, t: bw(p), tag="drip")
    cl.ball(V(ca * 0.86, 0.06, sa * 0.84), 0.06, bones={"body": 1.0}, tag="puddle")


def slime_col(p, info):
    # lit and pale on top, a murky core band low in the middle, lighter again at the thin edge
    # and in the puddle, where light passes through the gel
    rr = math.hypot(p.x, p.z)
    top = smooth(0.45, 1.0, p.y)
    core = math.exp(-((p.y - 0.3) / 0.14) ** 2) * smooth(0.72, 0.35, rr)
    edge = smooth(0.5, 0.75, rr) * smooth(0.3, 0.1, p.y)
    v = 0.86 + 0.14 * top - 0.16 * core + 0.1 * edge
    if info.tag == "puddle":
        v = 0.9
    elif info.tag == "drip":
        v = max(v, 0.84)
    elif info.tag == "tip":
        v = 0.96
    g = fbm3((p.x * 4.0, p.y * 4.0, p.z * 4.0), 2, 3)
    v *= 0.96 + 0.08 * g
    return (v, v, v)


def slime_wobble(p, info):
    w = fbm3((p.x * 3.0, p.y * 3.0, p.z * 3.0), 2, 6) - 0.5
    return info.n * (0.022 * w)


cl.build(b, slime_col, cls=SKIN, tint_fn=lambda p, info: 1.0, post=slime_wobble)
hit = A.surface(b)


def on_gel(x, y, z_dir=1.0):
    h = hit(V(x, y, 2.0 * z_dir), V(0, 0, -z_dir), 4.0)
    return (h[0], h[1]) if h is not None else (V(x, y, 0.5 * z_dir), V(0, 0, z_dir))


def on_gel_dir(o, d):
    h = hit(o, d, 4.0)
    return (h[0], h[1]) if h is not None else (o, -V(d))


# ---------------------------------------------------------------- wet glints: crisp white highlights on the lit top
for (x, y, z, rx, rz, rot) in ((-0.22, 0.8, 0.3, 0.15, 0.06, (0.6, 0.5, 0.3)), (0.2, 0.78, 0.33, 0.06, 0.025, (0.7, -0.4, -0.3)),
                               (-0.05, 1.0, 0.02, 0.05, 0.02, (0.2, 0.0, 0.4))):
    p, n = on_gel_dir(V(x, y + 0.6, z) + V(x, 0, z) * 0.5, (V(0, -1, 0) - V(x, 0, z) * 0.6).normalized())
    b.ellipsoid(p + n * 0.006, (rx, 0.012, rz), "ffffff", cls=CLOTH, bone=bw(p), rot=(math.atan2(n.z, n.y), math.atan2(x, z) * 0.0 + rot[1], -math.atan2(n.x, n.y)),
                seg=12, rings=5, mat=MAT_GLOW, tint=0.15)
# ---------------------------------------------------------------- bubbles welling up under the skin
b.cur_pal = 0.0
for k in range(8):
    a = k * 2.4 + 0.3
    y = 0.22 + 0.06 * (k % 7)
    d = V(math.cos(a), (y - 0.38) * 1.2, math.sin(a)).normalized()
    p, n = on_gel_dir(V(0, 0.38, 0) + d * 1.5, -d)
    rad = 0.03 + 0.014 * (k % 3)
    b.ball(p - n * rad * 0.45, rad, (1.0, 1.0, 1.0), cls=SKIN, bone=bw(p), tint=0.88, seg=10, rings=6)
    b.ball(p - n * rad * 0.35 + n * rad * 0.7 + V(-0.3, 0.5, 0.2).normalized() * rad * 0.35, rad * 0.28, "ffffff", cls=CLOTH, bone=bw(p),
           seg=6, rings=4, mat=MAT_GLOW, tint=0.0)
# ---------------------------------------------------------------- swallowed things, half sunk in the gel
p, n = on_gel(-0.33, 0.27)
A.skull(b, p - n * 0.035, 1.25, "body", col="c4bca8", fwd=(n + V(-0.2, 0.3, 0.1)).normalized())
for k, (x, y, ang) in enumerate(((0.3, 0.22, 0.9), (0.4, 0.3, 0.35), (0.22, 0.15, 1.4))):
    p, n = on_gel(x, y)
    c = p - n * 0.025
    rot = (math.atan2(n.y, n.z) + ang * 0.3, math.atan2(n.x, n.z), ang)
    b.lathe(c, [(0.07, -0.009), (0.07, 0.009)], "d8b050", cls=METAL, bone="body", seg=18, rot=(math.pi / 2 + rot[0], rot[1], rot[2]))
    # the square hole of a cash coin
    b.box(c + n * 0.01, (0.028, 0.028, 0.022), "2a1a10", bone="body", rot=(math.pi / 2 + rot[0], rot[1], rot[2]), cls=METAL)

# ---------------------------------------------------------------- face: big simple eyes and a wide D-shaped grin
for s in (1, -1):
    p, n = on_gel(0.17 * s, 0.6)
    rot = (math.atan2(-n.y, n.z) * 0.5, math.atan2(n.x, n.z), 0)
    b.ellipsoid(p + n * 0.006, (0.065, 0.092, 0.03), "141018", cls=SKIN, bone="head", rot=rot, seg=16, rings=10, mat=MAT_PLAIN)
    b.ellipsoid(p + n * 0.03 + V(-0.02 * s, 0.035, 0), (0.022, 0.026, 0.01), "ffffff", cls=CLOTH, bone="head", rot=rot, seg=10, rings=6, mat=MAT_GLOW)
    b.ellipsoid(p + n * 0.03 + V(0.018 * s, -0.035, 0), (0.01, 0.01, 0.006), "ffffff", cls=CLOTH, bone="head", seg=8, rings=5, mat=MAT_GLOW)
mouth = []
for i in range(17):
    a = math.pi * i / 16
    mouth.append((math.cos(a) * 0.13, -math.sin(a) * 0.1 + 0.01 * math.sin(a * 2.0)))
mouth.append((-0.13, 0.008))
mouth.append((0.0, 0.016))
mouth.append((0.13, 0.008))
mouth = list(reversed(mouth))
mp, mn = on_gel(0.0, 0.43)
decal(b, hit, mp, mn, mouth, "3a1020", "head", lift=0.004, cols=("2a0c18", "4a1424"))
# the tongue in the lower half of the grin
tongue = [(math.cos(a) * 0.075, -0.09 + 0.045 * math.sin(a)) for a in [math.pi * i / 12 for i in range(13)]]
decal(b, hit, mp, mn, tongue, "e05a78", "head", lift=0.007, cols=("c84a68", "f07890"))


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
# the gel carries its own values (lit top, murky core, bright rim): no coat split
kit.finish_rigged(b, r, "monsters/blob.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  coat=False, samples=10, dist=0.14, strength=0.18, floor_y=0.0)
