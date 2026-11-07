"""Storm: thunderheads with a temper (Thunder Spirit, Storm Wyrm's herald, the Lord of the
Nine Skies).  Cauliflower cloud lobes - each a noise-lumped sphere - pile into a heavy middle, a
dark ragged base trailing streaks of rain and a flat anvil spreading wide on top; a frowning brow
with burning eyes and a scowl, cloud arms crackling with static round the fists, recursive forked
lightning below, and a halo of glowing rune tablets carved with strokes.  Tinted per enemy.
Run: blender --background --python art/monsters/storm.py  ->  assets/monsters/storm.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, smooth  # noqa: E402
from clay import Clay  # noqa: E402
from creature import add  # noqa: E402

kit.reset()
creature.realtime()
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

# the thunderhead is sculpted as one billowing mass: cauliflower lobes piled into a heavy middle,
# a flat-topped anvil spreading wide above and a flat, dark, ragged base; every lobe is pushed
# out into smaller bulges, and the cloud darkens from its sunlit crown down to the base
BASE_Y = Y - 0.62


def cells(p, scale, seed=0):
    """Worley noise: distances (in cell units) to the nearest two jittered points of a 3D grid."""
    x, y, z = p[0] * scale, p[1] * scale, p[2] * scale
    ix, iy, iz = math.floor(x), math.floor(y), math.floor(z)
    f1 = f2 = 9.0
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                cx, cy, cz = ix + dx, iy + dy, iz + dz
                h = ((cx * 73856093) ^ (cy * 19349663) ^ (cz * 83492791) ^ (seed * 2654435761)) & 0xFFFFFFFF
                d = (cx + (h & 1023) / 1023.0 - x) ** 2 + (cy + ((h >> 10) & 1023) / 1023.0 - y) ** 2 + (cz + ((h >> 20) & 1023) / 1023.0 - z) ** 2
                if d < f1:
                    f1, f2 = d, f1
                elif d < f2:
                    f2 = d
    return math.sqrt(f1), math.sqrt(f2)


def billow(p, info):
    nn = info.n
    bump = fbm3((p.x * 2.6, p.y * 2.6, p.z * 2.6), 3, 3) - 0.5
    # cauliflower: every cell of the surface swells into its own round bulge, smaller bulges
    # crowding over the big ones
    f1, _ = cells(p, 2.4, 5)
    g1, _ = cells(p, 5.5, 8)
    off = nn * (0.2 * (0.55 - f1) ** 2 * 4.0 * 0.5 + 0.06 * (0.6 - g1) + 0.05 * bump)
    # the underside is cut flat, and ragged
    if p.y < BASE_Y + 0.08:
        off = off + V(0, (BASE_Y + 0.08 - p.y) * 0.75 * (1.0 - 0.3 * bump), 0)
    return off


def cloud_col(p, info):
    g = fbm3((p.x * 2.6, p.y * 2.6, p.z * 2.6), 3, 3)
    h = smooth(BASE_Y, Y + 1.2, p.y)
    f1, f2 = cells(p, 2.4, 5)
    # the creases between bulges are shadowed, the bulges' crowns catch the light
    v = 0.5 + 0.44 * h + 0.1 * (g - 0.5) - 0.12 * smooth(0.12, 0.0, f2 - f1)
    if info.tag == "brow":
        v = 0.5
    return (min(1.0, v),) * 3


cloud = Clay(0.055, "storm_cloud")
for k in range(26):
    a = rnd.random() * 2 * math.pi
    layer = k % 3
    rr = (0.75, 0.55, 0.95)[layer] * (0.7 + 0.5 * rnd.random())
    y = Y + (-0.35, 0.25, 0.75)[layer] + rnd.uniform(-0.15, 0.15)
    rad = (0.45, 0.38, 0.55)[layer]
    cloud.ball(V(math.cos(a) * rr, y, math.sin(a) * rr * 0.75), rad, bones={"body": 1.0}, tag="cloud")
for k in range(10):
    a = k / 10 * 2 * math.pi
    cloud.ellipsoid(V(math.cos(a) * 1.15, Y + 1.02, math.sin(a) * 0.85), (0.4, 0.22, 0.4), bones={"body": 1.0}, tag="cloud")
cloud.ellipsoid(V(0, Y + 1.08, 0), (1.0, 0.25, 0.75), bones={"body": 1.0}, tag="cloud")
# a scowling brow of darker cloud over the eyes
cloud.chain([V(-0.42, Y + 0.36, 0.66), V(-0.12, Y + 0.24, 0.8), V(0.12, Y + 0.24, 0.8), V(0.42, Y + 0.36, 0.66)], [0.12, 0.14, 0.14, 0.12], bones={"body": 1.0}, tag="brow")
cloud.build(b, cloud_col, cls=CLOTH, tint_fn=lambda p, info: 1.0, post=billow)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# rain falling from the base in streaks
for k in range(40):
    x = rnd.uniform(-0.8, 0.8)
    z = rnd.uniform(-0.5, 0.5)
    y0 = Y - 0.55 - rnd.uniform(0.0, 0.2)
    b.tube([V(x, y0, z), V(x - 0.04, y0 - 0.35, z)], [0.006, 0.002], (0.85, 0.9, 1.0), cls=CRYSTAL, bone="bolts", seg=3, tint=0.5, mat=MAT_PLAIN)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# face: a frowning brow of cloud and two glowing eyes
for s in (1, -1):
    b.ellipsoid(V(0.2 * s, Y + 0.12, 0.84), (0.11, 0.06, 0.04), "fffce0", cls=SKIN, bone="body", seg=12, rings=6, mat=MAT_GLOW)
    b.ellipsoid(V(0.2 * s, Y + 0.12, 0.82), (0.2, 0.12, 0.05), "a0c0ff", cls=SKIN, bone="body", seg=12, rings=6, mat=MAT_GLOW)
b.ellipsoid(V(0, Y - 0.12, 0.84), (0.16, 0.05, 0.04), "1a1830", cls=SKIN, bone="body", seg=12, rings=6)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# cloud arms
for s, sd in ((1, "L"), (-1, "R")):
    ar = r.bones["arm." + sd]
    arm = Clay(0.035, "storm_arm_" + sd)
    for k in range(5):
        t = k / 4
        c = V(ar[0]).lerp(V(ar[1]), t) + V(0, 0.05 * math.sin(k * 2.0), 0)
        arm.ball(c, 0.3 - 0.04 * k, bones={"arm." + sd: 1.0}, tag="arm")
    arm.ball(V(ar[1]) + V(0.04 * s, -0.04, 0.05), 0.2, bones={"arm." + sd: 1.0}, tag="arm")
    arm.build(b, lambda p, info: (0.8,) * 3, cls=CLOTH, tint_fn=lambda p, info: 1.0, post=lambda p, info: info.n * (0.08 * (fbm3((p.x * 3.5, p.y * 3.5, p.z * 3.5), 2, 9) - 0.5)))
    # a crackle of static round each fist
    fist = V(ar[1])
    for k in range(4):
        a = k * 1.6
        b.tube([fist, fist + V(math.cos(a) * 0.15, math.sin(a) * 0.15, 0.1), fist + V(math.cos(a + 0.5) * 0.28, math.sin(a + 0.5) * 0.25, 0.05)], [0.012, 0.008, 0.002], "e8f0ff", cls=CLOTH, bone="arm." + sd, seg=4, mat=MAT_GLOW)


def bolt(p0, d, n, width, depth=0):
    """Forked lightning: a jagged channel that splits into thinner branches."""
    pts = [p0]
    for j in range(n):
        pts.append(pts[-1] + d * 0.3 + V(rnd.uniform(-0.18, 0.18), rnd.uniform(-0.06, 0.06), rnd.uniform(-0.12, 0.12)))
    b.tube(pts, [width] * len(pts), "f4f8ff", cls=CLOTH, bone="bolts", seg=5, mat=MAT_GLOW)
    b.tube(pts, [width * 2.3] * len(pts), "6080ff", cls=CLOTH, bone="bolts", seg=5, mat=MAT_GLOW)
    if depth < 2:
        for j in range(1, len(pts) - 1, 2):
            nd = (d + V(rnd.uniform(-0.8, 0.8), 0.0, rnd.uniform(-0.4, 0.4))).normalized()
            bolt(pts[j], nd, max(2, n - 2), width * 0.6, depth + 1)


for k in range(4):
    bolt(V(rnd.uniform(-0.6, 0.6), Y - 0.6, rnd.uniform(-0.3, 0.4)), V(0, -1, 0), 5, 0.032)
# halo of runes: each a carved glyph of strokes on a glowing tablet
for k in range(24):
    a = 2 * math.pi * k / 24
    c = V(math.cos(a) * 1.5, Y + 0.3, math.sin(a) * 1.5)
    rot = (0, -a + math.pi / 2, 0)
    b.cur_pal = 1.0  # the rune tablets glow in the accent colour round the storm's head
    b.superquad(c, (0.07, 0.07, 0.015) if k % 3 else (0.05, 0.11, 0.015), "f4f4f4", e=0.3, cls=CLOTH, bone="halo", rot=rot, mat=MAT_GLOW, tint=1.0)
    b.cur_pal = 0.0
    tang = V(-math.sin(a), 0, math.cos(a))
    for st in range(2):
        q = c + V(math.cos(a), 0, math.sin(a)) * 0.02 + tang * (0.025 * (st - 0.5))
        b.tube([q + V(0, 0.04, 0), q - V(0, 0.04, 0)], [0.006, 0.006], "c08020", cls=CLOTH, bone="halo", seg=3, mat=MAT_PLAIN)

T_IDLE = 3.0


def halo_rot(spin, tilt=0.15):
    """The halo leans in the body's frame and spins about its own leaning axis."""
    cx, sx, cy, sy = math.cos(tilt), math.sin(tilt), math.cos(spin), math.sin(spin)
    rx = ((1, 0, 0), (0, cx, -sx), (0, sx, cx))
    ry = ((cy, 0, sy), (0, 1, 0), (-sy, 0, cy))
    return creature.euler_yxz([[sum(rx[i][k] * ry[k][j] for k in range(3)) for j in range(3)] for i in range(3)])


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    p["body"] = ((0, math.sin(t * w + 0.5) * 0.08, 0), (0, math.sin(t * w) * 0.1, 0), (1.0 + 0.03 * math.sin(t * w * 2), 1.0 + 0.03 * math.sin(t * w * 2 + 1.0), 1.0))
    # the 24 runes repeat every 45 degrees: a quarter turn per loop keeps the loop seamless
    p["halo"] = (halo_rot(0.5 * math.pi * t / T_IDLE), (0, 0, 0))
    p["bolts"] = ((0, 0, 0), (0, 0, 0), (1.0, 0.6 + 0.4 * abs(math.sin(t * w * 5)), 1.0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((math.sin(t * w + s) * 0.15, 0, math.sin(t * w + 0.7) * 0.15 * s), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.55
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


T_WALK = 2.0


def walk(t):
    """Rolls forward like weather: the mass leans and churns, the rain slants."""
    w = 2 * math.pi / T_WALK
    p = idle(t * T_IDLE / T_WALK)
    add(p, "body", (0.15, 0.05 * math.sin(t * w), 0.06 * math.sin(t * w)), (0, 0.05 * math.sin(t * w * 2), 0))
    add(p, "bolts", (-0.25, 0, 0))
    return p


def die(t):
    """Breaks up: the cloud swells, thins and sinks away, the lightning gone."""
    k = min(1.0, t / 1.2)
    swell = math.sin(math.pi * smooth(0.0, 0.3, k))
    f = smooth(0.2, 0.86, k)
    p = idle(0.0)
    s_ = (1.0 + 0.15 * swell) * (1.0 - 0.85 * f) + 0.02
    p["body"] = ((0, 0, 0), (0, -1.6 * f, 0), (s_ * (1.0 + 0.3 * f), s_ * (1.0 - 0.4 * f), s_ * (1.0 + 0.3 * f)))
    p["bolts"] = ((0, 0, 0), (0, 0, 0), (max(0.01, 1.0 - 1.5 * k), max(0.01, 1.0 - 1.5 * k), max(0.01, 1.0 - 1.5 * k)))
    # the halo's spin runs down and stops as the cloud dies
    u = min(1.0, k / 0.85)
    p["halo"] = ((0.15, 6.12 * (u - 0.5 * u * u), 0), (0, -0.2 * f, 0), (1.0 - 0.9 * f, 1.0, 1.0 - 0.9 * f))
    return p

print("[art] storm: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/storm.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=10, dist=0.35, strength=0.45)
