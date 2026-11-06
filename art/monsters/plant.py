"""Plant: walking flora (the Ancient Bamboo Spirit, Leaf Sprites, the Ten-Thousand-Year Peach Tree,
the Empress of the Red Lilies ...).  A gnarled trunk-body standing on spreading roots, a bark face
with glowing knot-hole eyes, two long vine arms ending in leaf claws, a leafy crown of layered
fronds and a great flower blooming from the top.  Tinted by the game per enemy; eyes and the
flower's heart keep their colours.
Run: blender --background --python art/monsters/plant.py  ->  assets/monsters/plant.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import chain_rig, wave_chain, zero_pose  # noqa: E402
from kit import CLOTH, FOLIAGE, MAT_GLOW, SKIN, WOOD, V, Builder, Rig, env  # noqa: E402

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

# gnarled trunk: a lathe with knotted folds, bark-dark at the base
b.lathe(V(0, 0, 0), [(0.36, 0.25), (0.3, 0.45), (0.27, 0.75), (0.29, 1.05), (0.26, 1.3), (0.2, 1.6), (0.12, 1.85)], (0.65, 0.65, 0.65), cls=WOOD, seg=22, tint=1.0, folds=(7, 0.12, 0.6),
       bone_fn=lambda p: {"trunk": 1.0} if p.y < 1.3 else {"trunk": 0.5, "crown": 0.5}, cols=[(0.5, 0.5, 0.5), (0.6, 0.6, 0.6), (0.7, 0.7, 0.7), (0.72, 0.72, 0.72), (0.75, 0.75, 0.75), (0.8, 0.8, 0.8), (0.85, 0.85, 0.85)])
# bark face: brow ridge, knot-hole eyes that glow, a mossy beard
b.tube([V(-0.18, 1.32, 0.24), V(0, 1.36, 0.29), V(0.18, 1.32, 0.24)], [0.05, 0.06, 0.05], (0.5, 0.5, 0.5), cls=WOOD, bone="trunk", tint=1.0, seg=8)
for s in (1, -1):
    b.ellipsoid(V(0.1 * s, 1.24, 0.26), (0.055, 0.045, 0.03), "100c08", cls=SKIN, bone="trunk", seg=10, rings=6)
    b.ellipsoid(V(0.1 * s, 1.24, 0.28), (0.028, 0.024, 0.01), "c0ff80", cls=SKIN, bone="trunk", seg=8, rings=5, mat=MAT_GLOW)
b.ellipsoid(V(0, 1.06, 0.27), (0.09, 0.04, 0.03), "100c08", cls=SKIN, bone="trunk", seg=10, rings=5)
for k in range(6):
    x = (k - 2.5) * 0.06
    b.leaf(V(x, 1.0, 0.27), V(x * 1.3, 0.75, 0.33), 0.04, (0.55, 0.55, 0.55), side=(1, 0, 0), cls=FOLIAGE, bone="trunk", tint=1.0, col_tip=(0.8, 0.8, 0.8))
# vine arms with leaf claws
for sd, names in arms.items():
    s = 1 if sd == "L" else -1
    pts = [r.head(n) for n in names] + [r.tail(names[-1])]
    b.tube(pts, [0.09, 0.07, 0.055, 0.035], (0.65, 0.65, 0.65), cls=WOOD, bones=[names[0], names[0], names[1], names[2]], tint=1.0, seg=10)
    for j in range(len(pts) - 1):
        q = V(pts[j]).lerp(V(pts[j + 1]), 0.5)
        b.leaf(q, q + V(0.15 * s, 0.1, 0.05), 0.07, (0.8, 0.8, 0.8), cls=FOLIAGE, bone=names[j], tint=1.0, col_tip=(1.0, 1.0, 1.0))
    tip = V(pts[-1])
    for f in range(4):
        a = -0.6 + f * 0.4
        b.leaf(tip, tip + V(math.sin(a) * 0.12 * s, -0.22, math.cos(a) * 0.12), 0.06, (0.85, 0.85, 0.85), cls=FOLIAGE, bone=names[-1], tint=1.0, col_tip=(1.0, 1.0, 1.0))
# spreading roots
for names in roots:
    pts = [r.head(n) for n in names] + [r.tail(names[-1])]
    b.tube(pts, [0.12, 0.07, 0.02], (0.5, 0.5, 0.5), cls=WOOD, bones=[names[0], names[1], names[1]], tint=1.0, seg=8)
# leafy crown: layered arching fronds
for names, a in fronds:
    pts = [r.head(n) for n in names] + [r.tail(names[-1])]
    side = V(-math.sin(a), 0, math.cos(a))
    b.ribbon(pts, [0.06, 0.18, 0.04], side, (0.75, 0.75, 0.75), cls=FOLIAGE, bones=[names[0], names[0], names[1]], tint=1.0, col_end=(1.0, 1.0, 1.0))
# the great flower on top (heart untinted)
for k in range(8):
    a = 2 * math.pi * k / 8
    b.leaf(V(0, 1.98, 0), V(math.cos(a) * 0.3, 2.1, math.sin(a) * 0.3), 0.12, (0.95, 0.95, 0.95), side=(-math.sin(a), 0, math.cos(a)), cls=CLOTH, bone="crown", tint=1.0, col_tip=(1.0, 1.0, 1.0))
for k in range(6):
    a = 2 * math.pi * k / 6 + 0.3
    b.leaf(V(0, 2.0, 0), V(math.cos(a) * 0.18, 2.2, math.sin(a) * 0.18), 0.08, (1.0, 1.0, 1.0), side=(-math.sin(a), 0, math.cos(a)), cls=CLOTH, bone="crown", tint=1.0)
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
