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
from creature import zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, morph_sphere, smooth  # noqa: E402

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

# billowing cloud mass built from cauliflower lobes (each a noise-lumped sphere): a flat-topped
# anvil spreading wide, a heavy middle and a dark ragged base trailing curtains of rain
def lobe(c, rad, shade, bone="body"):
    def shape(d):
        k = 1.0 + 0.18 * (fbm3((d.x * 3 + c.x, d.y * 3 + c.y, d.z * 3 + c.z), 2, 3) - 0.5)
        return V(d.x * rad, d.y * rad * 0.8, d.z * rad) * k

    morph_sphere(b, c, shape, lambda p, d: (shade * (0.75 + 0.25 * smooth(-0.7, 0.7, d.y)),) * 3, cls=CLOTH, bone=bone, seg=16, rings=10, tint_fn=lambda p, d: 1.0)


for k in range(26):
    a = rnd.random() * 2 * math.pi
    layer = k % 3
    rr = (0.75, 0.55, 0.95)[layer] * (0.7 + 0.5 * rnd.random())
    y = Y + (-0.35, 0.25, 0.75)[layer] + rnd.uniform(-0.15, 0.15)
    rad = (0.45, 0.35, 0.55)[layer]
    shade = (0.55, 0.8, 1.0)[layer]
    lobe(V(math.cos(a) * rr, y, math.sin(a) * rr * 0.75), rad, shade)
for k in range(8):
    a = k / 8 * 2 * math.pi
    lobe(V(math.cos(a) * 1.15, Y + 1.0, math.sin(a) * 0.85), 0.32, 1.0)
# rain falling from the base in streaks
for k in range(40):
    x = rnd.uniform(-0.8, 0.8)
    z = rnd.uniform(-0.5, 0.5)
    y0 = Y - 0.55 - rnd.uniform(0.0, 0.2)
    b.tube([V(x, y0, z), V(x - 0.04, y0 - 0.35, z)], [0.006, 0.002], (0.85, 0.9, 1.0), cls=CRYSTAL, bone="bolts", seg=3, tint=0.5, mat=MAT_PLAIN)
# face: a frowning brow of cloud and two glowing eyes
b.tube([V(-0.4, Y + 0.35, 0.72), V(-0.1, Y + 0.25, 0.82), V(0.1, Y + 0.25, 0.82), V(0.4, Y + 0.35, 0.72)], [0.12, 0.14, 0.14, 0.12], (0.6, 0.6, 0.6), cls=CLOTH, bone="body", tint=1.0, seg=10)
for s in (1, -1):
    b.ellipsoid(V(0.2 * s, Y + 0.12, 0.84), (0.11, 0.06, 0.04), "fffce0", cls=SKIN, bone="body", seg=12, rings=6, mat=MAT_GLOW)
    b.ellipsoid(V(0.2 * s, Y + 0.12, 0.82), (0.2, 0.12, 0.05), "a0c0ff", cls=SKIN, bone="body", seg=12, rings=6, mat=MAT_GLOW)
b.ellipsoid(V(0, Y - 0.12, 0.84), (0.16, 0.05, 0.04), "1a1830", cls=SKIN, bone="body", seg=12, rings=6)
# cloud arms
for s, sd in ((1, "L"), (-1, "R")):
    ar = r.bones["arm." + sd]
    for k in range(4):
        t = k / 3
        c = V(ar[0]).lerp(V(ar[1]), t)
        lobe(c, 0.3 - 0.05 * k, 0.75, "arm." + sd)
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
    b.superquad(c, (0.07, 0.07, 0.015) if k % 3 else (0.05, 0.11, 0.015), "ffe890", e=0.3, cls=CLOTH, bone="halo", rot=rot, mat=MAT_GLOW)
    tang = V(-math.sin(a), 0, math.cos(a))
    for st in range(2):
        q = c + V(math.cos(a), 0, math.sin(a)) * 0.02 + tang * (0.025 * (st - 0.5))
        b.tube([q + V(0, 0.04, 0), q - V(0, 0.04, 0)], [0.006, 0.006], "c08020", cls=CLOTH, bone="halo", seg=3, mat=MAT_PLAIN)

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
