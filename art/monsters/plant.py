"""Plant: walking flora (the Ancient Bamboo Spirit, Leaf Sprites, the Ten-Thousand-Year Peach Tree,
the Empress of the Red Lilies ...).  A gnarled trunk-body of twisting fibrous bark standing on gripping
roots with root hairs, a bark face with burl brows, glowing knot-hole eyes, a split mouth of
splinter teeth and a hanging moss beard, two thorned woody vine arms sprouting veined leaves and
ending in leaf talons, a crown of serrated veined leaves and a great flower with stamens.  Tinted by the game per enemy; eyes and the
flower's heart keep their colours.
Run: blender --background --python art/monsters/plant.py  ->  assets/monsters/plant.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import chain_rig, wave_chain, zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, MAT_PLAIN, SKIN, WOOD, V, Builder, Rig, env  # noqa: E402
from sculpt import catmull, strand  # noqa: E402

kit.reset()
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("trunk", (0, 0.3, 0), (0, 1.2, 0), "root")
r.bone("crown", (0, 1.2, 0), (0, 1.9, 0), "trunk")
arms = {}
for s, sd in ((1, "L"), (-1, "R")):
    arms[sd] = chain_rig(r, "arm%s" % sd, [V(0.28 * s, 1.15, 0.0), V(0.55 * s, 1.0, 0.12), V(0.75 * s, 0.75, 0.22), V(0.85 * s, 0.48, 0.3)], "trunk")
roots = []
for k in range(5):
    a = 2 * math.pi * k / 5 + 0.3
    roots.append(chain_rig(r, "rt%d_" % k, [V(math.cos(a) * 0.2, 0.35, math.sin(a) * 0.2), V(math.cos(a) * 0.5, 0.12, math.sin(a) * 0.5), V(math.cos(a) * 0.8, 0.02, math.sin(a) * 0.8)], "root"))
fronds = []
for k in range(9):
    a = 2 * math.pi * k / 9
    base = V(math.cos(a) * 0.15, 1.75, math.sin(a) * 0.15)
    fronds.append((chain_rig(r, "fr%d_" % k, [base, base + V(math.cos(a) * 0.35, 0.25, math.sin(a) * 0.35), base + V(math.cos(a) * 0.7, 0.05, math.sin(a) * 0.7)], "crown"), a))
b = Builder("plant")


def trunk_w(p):
    return {"trunk": 1.0} if p.y < 1.3 else ({"trunk": 0.5, "crown": 0.5} if p.y < 1.6 else {"crown": 1.0})


# gnarled trunk: a woody loft ploughed into twisting fibrous ridges, flaring into buttress roots
tpts = [V(0, 0.2, 0), V(0.02, 0.45, 0.0), V(-0.01, 0.75, 0.02), V(0.02, 1.05, 0.0), V(0, 1.3, -0.02), V(-0.02, 1.6, 0.0), V(0, 1.88, 0)]
A.bark_limb(b, tpts, [0.38, 0.3, 0.27, 0.29, 0.26, 0.2, 0.12], (0.7, 0.7, 0.7), trunk_w, seed=3, ridges=11, twist=1.4)
# bark face: a heavy brow of burls, knot-hole eyes deep in their hollows that glow, a split mouth
# with splinter teeth, and a beard of hanging moss
for s in (1, -1):
    b.ellipsoid(V(0.11 * s, 1.34, 0.25), (0.1, 0.05, 0.06), (0.55, 0.55, 0.55), cls=WOOD, bone="trunk", tint=1.0, seg=12, rings=6, rot=(0, 0, -0.3 * s))
    b.ellipsoid(V(0.1 * s, 1.24, 0.25), (0.06, 0.05, 0.035), "100c08", cls=SKIN, bone="trunk", seg=10, rings=6)
    b.ellipsoid(V(0.1 * s, 1.24, 0.275), (0.028, 0.024, 0.01), "c0ff80", cls=SKIN, bone="trunk", seg=8, rings=5, mat=MAT_GLOW)
    b.ellipsoid(V(0.17 * s, 1.15, 0.22), (0.05, 0.06, 0.04), (0.6, 0.6, 0.6), cls=WOOD, bone="trunk", tint=1.0, seg=10, rings=6)
b.ellipsoid(V(0, 1.06, 0.26), (0.1, 0.045, 0.04), "100c08", cls=SKIN, bone="trunk", seg=12, rings=6)
for k in range(7):
    x = (k - 3) * 0.026
    b.cone(V(x, 1.09, 0.28), 0.01, 0.035, "d8c8a0", cls=WOOD, bone="trunk", seg=4, rot=(math.pi, 0, 0))
    b.cone(V(x, 1.025, 0.28), 0.009, 0.03, "d8c8a0", cls=WOOD, bone="trunk", seg=4)
for k in range(9):
    x = (k - 4) * 0.045
    strand(b, [V(x, 1.0, 0.27), V(x * 1.1, 0.88, 0.3), V(x * 1.25, 0.72, 0.29)], 0.022, 0.003, "5a7a3a", col_tip="9ab860", cls=FOLIAGE, bone="trunk", flat=0.4, seg=5, per=3, mat=MAT_PLAIN)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# vine arms: woody, thorned, sprouting veined leaves, ending in leafy talons
for sd, names in arms.items():
    s = 1 if sd == "L" else -1
    pts = [r.head(n) for n in names] + [r.tail(names[-1])]
    fine = catmull(pts, 3)
    bones = [names[min(len(names) - 1, int(i / (len(fine) - 1) * len(names)))] for i in range(len(fine))]
    A.bark_limb(b, fine, [0.09 - 0.055 * i / (len(fine) - 1) for i in range(len(fine))], (0.65, 0.65, 0.65), lambda p, fine=fine, bones=bones: bones[min(range(len(fine)), key=lambda i: (fine[i] - p).length)], seed=5 + s, ridges=6, twist=3.0)
    A.thorns(b, fine, lambda p, fine=fine, bones=bones: bones[min(range(len(fine)), key=lambda i: (fine[i] - p).length)], size=0.035, seed=s + 4)
    for j in range(len(pts) - 1):
        q = V(pts[j]).lerp(V(pts[j + 1]), 0.5)
        A.veined_leaf(b, q, q + V(0.18 * s, 0.12, 0.06), 0.07, (0.78, 0.78, 0.78), names[j], col_tip=(1.0, 1.0, 1.0), serrate=0.2)
    tip = V(pts[-1])
    for f in range(4):
        a = -0.6 + f * 0.4
        A.veined_leaf(b, tip, tip + V(math.sin(a) * 0.13 * s, -0.24, math.cos(a) * 0.13), 0.05, (0.85, 0.85, 0.85), names[-1], col_tip=(1.0, 1.0, 1.0), curl=0.3)
# spreading roots gripping the ground, with fine root hairs at their tips
for names in roots:
    pts = [r.head(n) for n in names] + [r.tail(names[-1])]
    fine = catmull(pts, 3)
    A.bark_limb(b, fine, [0.13 - 0.11 * i / (len(fine) - 1) for i in range(len(fine))], (0.55, 0.55, 0.55), lambda p, names=names: names[0] if (p - V(0, 0.3, 0)).length < 0.45 else names[1], seed=7, ridges=5, twist=2.0)
    end = fine[-1]
    for k in range(4):
        a = k * 1.6
        b.tube([end, end + V(math.cos(a) * 0.08, -0.02, math.sin(a) * 0.08)], [0.008, 0.001], (0.5, 0.5, 0.5), cls=WOOD, bone=names[-1], tint=1.0, seg=4)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# leafy crown: arching fronds of big serrated veined leaves layered round the top
for names, a in fronds:
    pts = [r.head(n) for n in names] + [r.tail(names[-1])]
    side = V(-math.sin(a), 0, math.cos(a))
    b.tube(pts, [0.025, 0.018, 0.006], (0.6, 0.6, 0.6), cls=WOOD, bones=[names[0], names[0], names[1]], tint=1.0, seg=6)
    for j in range(3):
        q = V(pts[1]).lerp(V(pts[2]), j / 3)
        out = V(math.cos(a), 0, math.sin(a))
        A.veined_leaf(b, q, q + out * 0.28 + side * 0.1 * (j - 1) + V(0, -0.06 * j, 0), 0.1, (0.72, 0.72, 0.72), names[1], side=side, col_tip=(1.0, 1.0, 1.0), serrate=0.25, curl=0.2)
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# the great flower on top (heart untinted): two whorls of cupped petals, stamens with glowing anthers
for k in range(8):
    a = 2 * math.pi * k / 8
    b.leaf(V(0, 1.98, 0), V(math.cos(a) * 0.3, 2.1, math.sin(a) * 0.3), 0.12, (0.95, 0.95, 0.95), side=(-math.sin(a), 0, math.cos(a)), cls=CLOTH, bone="crown", tint=1.0, col_tip=(1.0, 1.0, 1.0), curl=-0.2)
for k in range(6):
    a = 2 * math.pi * k / 6 + 0.3
    b.leaf(V(0, 2.0, 0), V(math.cos(a) * 0.18, 2.2, math.sin(a) * 0.18), 0.08, (1.0, 1.0, 1.0), side=(-math.sin(a), 0, math.cos(a)), cls=CLOTH, bone="crown", tint=1.0, curl=-0.25)
for k in range(10):
    a = 2 * math.pi * k / 10
    top = V(math.cos(a) * 0.06, 2.16, math.sin(a) * 0.06)
    b.tube([V(0, 2.03, 0), top], [0.004, 0.003], "f0e0a0", cls=FOLIAGE, bone="crown", seg=4)
    b.ball(top, 0.012, "ffe060", cls=CRYSTAL, bone="crown", seg=6, rings=4, mat=MAT_GLOW)
b.ball(V(0, 2.04, 0), 0.07, "ffe060", cls=CLOTH, bone="crown", seg=10, rings=6, mat=MAT_GLOW)

T_IDLE = 3.2


def sway(p, t, speed, amp):
    for names, _ in fronds:
        wave_chain(p, names, t, speed, amp, axis=0, lag=0.6)
    for sd, names in arms.items():
        wave_chain(p, names, t + (0 if sd == "L" else 1.0), speed * 0.8, amp * 0.8, axis=2, lag=0.7)


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    sway(p, t, w, 0.08)
    p["trunk"] = ((math.sin(t * w) * 0.03, math.sin(t * w * 0.5) * 0.08, math.sin(t * w) * 0.04), (0, 0, 0))
    p["crown"] = ((math.sin(t * w - 0.6) * 0.06, 0, math.sin(t * w - 0.6) * 0.05), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    lash = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["trunk"] = ((0.25 * lash, 0, 0), (0, 0, 0))
    for sd, names in arms.items():
        s = 1 if sd == "L" else -1
        p[names[0]] = ((-1.0 * e + 0.6 * lash, 0, 0.3 * s * e), (0, 0, 0))
        p[names[1]] = ((-0.6 * lash, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["trunk"] = ((-0.25 * e, 0, 0.12 * e), (0, 0, 0))
    sway(p, t, 25.0, 0.15 * e)
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["crown"] = ((-0.2 * e, t * 3.0, 0), (0, 0.1 * e, 0), (1.0 + 0.2 * e, 1.0 + 0.2 * e, 1.0 + 0.2 * e))
    for sd, names in arms.items():
        s = 1 if sd == "L" else -1
        p[names[0]] = ((-1.3 * e, 0, 0.6 * s * e), (0, 0, 0))
    return p


print("[art] plant: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/plant.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.3, strength=0.5, floor_y=0.0)
