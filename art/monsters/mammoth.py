"""Mammoth (new in Part V): a shaggy giant of the Aurora Steppe with curling tusks, a swinging
four-bone trunk, flapping ears and a coat of hanging fur locks (Frost Yak, Mammoth Ancestor).
Run: blender --background --python art/monsters/mammoth.py  ->  assets/monsters/mammoth.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import catmull, chain_weights, eyes, leg_nodes, quad_rig, shade_fn, skin_graph, weights_for, zero_pose  # noqa: E402
from kit import HAIR, SKIN, STONE, V, Builder, env  # noqa: E402

kit.reset()
rnd = random.Random(21)
BY = 1.25
TR = [V(0, 1.45, 1.25), V(0, 1.15, 1.42), V(0, 0.8, 1.48), V(0, 0.5, 1.45), V(0, 0.3, 1.55)]
extra = [("ear.L", (0.28, 1.75, 0.95), (0.5, 1.45, 0.9), "head"), ("ear.R", (-0.28, 1.75, 0.95), (-0.5, 1.45, 0.9), "head")]
for i in range(4):
    extra.append(("trunk%d" % i, TR[i], TR[i + 1], "head" if i == 0 else "trunk%d" % (i - 1)))
r = quad_rig(BY, 0.55, -0.55, 0.32, (0, 1.6, 0.85), (0, 1.62, 1.25), [(0, 1.35, -0.85), (0, 1.15, -1.05), (0, 0.9, -1.12)], extra=extra)
b = Builder("mammoth")
b.auto = weights_for(r, ["pelvis", "chest", "neck", "head"] + [n for n in r.bones if n[1:3] in ("_u", "_l", "_p") or n.startswith("f_") or n.startswith("h_")])


def spine_y(p):
    return BY + 0.2 + 0.1 * max(0.0, p.z)


shade = shade_fn(spine_y, back=0.55, side=0.7, belly=0.85)
spine = [((0, 1.3, -0.8), 0.3), ((0, 1.32, -0.45), (0.48, 0.5)), ((0, 1.38, 0.0), (0.5, 0.55)), ((0, 1.5, 0.45), (0.52, 0.6)), ((0, 1.62, 0.85), (0.36, 0.38)), ((0, 1.6, 1.12), (0.3, 0.3)), ((0, 1.45, 1.28), (0.17, 0.16))]
chains = [(spine, None)]
for nm, att in (("f", 3), ("h", 1)):
    for sd in ("L", "R"):
        chains.append((leg_nodes(r, nm, sd, (0.24, 0.17, 0.15, 0.17)), att))
nodes, edges = skin_graph(chains)
b.skin(nodes, edges, shade, subdiv=2, tint_fn=lambda p: 1.0)
# domed head top
b.ellipsoid(V(0, 1.88, 0.9), (0.28, 0.22, 0.26), (0.6, 0.6, 0.6), bone="head", tint=1.0, seg=14, rings=8)
# trunk
pts, idx = catmull(TR, per=4)
b.tube(pts, [0.15 - 0.1 * (f / 4) for f in idx], (0.65, 0.65, 0.65), cls=SKIN, bones=[chain_weights("trunk", f, 4) for f in idx], tint=1.0, seg=12, cols=[(0.6 + 0.08 * (k % 2), 0.6 + 0.08 * (k % 2), 0.6 + 0.08 * (k % 2)) for k in range(len(pts))])
# tusks: long curling ivory
for s in (1, -1):
    tusk = [V(0.16 * s, 1.35, 1.25), V(0.22 * s, 1.05, 1.5), V(0.28 * s, 0.85, 1.85), V(0.24 * s, 0.95, 2.15), V(0.15 * s, 1.2, 2.25)]
    tp, _ = catmull(tusk, per=3)
    b.tube(tp, [0.07 - 0.06 * (k / (len(tp) - 1)) for k in range(len(tp))], "f6eed8", cls=STONE, bone="head", seg=10)
eyes(b, V(0, 1.68, 1.22), 0.2, 0.03, iris="402010", bone="head", slit=False, glow=False, rot_y=1.0, h=0.8)
for s, sd in ((1, "L"), (-1, "R")):
    e = "ear.%s" % sd
    b.ellipsoid(V(0.4 * s, 1.6, 0.92), (0.06, 0.22, 0.18), (0.55, 0.55, 0.55), bone=e, tint=1.0, seg=12, rings=8, rot=(0, 0, 0.3 * s))
# shaggy coat: hanging fur locks over the back, flanks and legs
for k in range(110):
    z = rnd.uniform(-0.75, 0.85)
    a = rnd.uniform(-2.3, 2.3)
    rad = 0.5 + 0.05 * math.cos(z * 2)
    root = V(math.sin(a) * rad * 0.95, 1.38 + math.cos(a) * rad * 0.9 + 0.1 * max(0.0, z), z)
    length = rnd.uniform(0.35, 0.65) * (1.0 if abs(a) > 0.6 else 0.6)
    tip = root + V(math.sin(a) * 0.1, -length, rnd.uniform(-0.08, 0.04))
    sh = rnd.uniform(0.45, 0.75)
    b.leaf(root, tip, 0.09, (sh, sh, sh), side=(math.cos(a), 0, -math.sin(a) * 0.3), cls=HAIR, tint=1.0, col_tip=(sh * 0.8, sh * 0.8, sh * 0.8), curl=0.12)
for nm in ("f", "h"):
    for sd, s in (("L", 1), ("R", -1)):
        up = "%s_up.%s" % (nm, sd)
        for k in range(6):
            a = k / 6 * 2 * math.pi
            root = r.head(up).lerp(r.tail(up), 0.6) + V(math.sin(a) * 0.2, 0, math.cos(a) * 0.2)
            b.leaf(root, root + V(math.sin(a) * 0.05, -0.35, math.cos(a) * 0.05), 0.08, (0.5, 0.5, 0.5), cls=HAIR, bone=up, tint=1.0)
        b.ellipsoid(r.tail("%s_paw.%s" % (nm, sd)) + V(0, 0.04, -0.05), (0.19, 0.08, 0.2), "4a4038", cls=STONE, bone="%s_paw.%s" % (nm, sd), seg=12, rings=6)
for k in range(5):
    b.leaf(r.tail("tail1"), r.tail("tail1") + V((k - 2) * 0.04, -0.25, -0.05), 0.04, (0.45, 0.45, 0.45), cls=HAIR, bone="tail1", tint=1.0)

T = 4.0


def idle(t):
    w = 2 * math.pi / T
    p = zero_pose(r)
    p["pelvis"] = ((0, 0, 0), (0, math.sin(t * w * 2) * 0.015, 0))
    p["neck"] = ((math.sin(t * w) * 0.04, math.sin(t * w * 0.5) * 0.12, 0), (0, 0, 0))
    for i in range(4):
        p["trunk%d" % i] = ((math.sin(t * w - i * 0.8) * 0.12 - 0.05, math.sin(t * w * 0.5 - i * 0.6) * 0.12, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["ear.%s" % sd] = ((0, s * math.sin(t * w * 2) * 0.25, 0), (0, 0, 0))
    p["tail0"] = ((0, math.sin(t * w * 2) * 0.3, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.7
    e = env(k)
    up = math.sin(min(1.0, k / 0.5) * math.pi / 2)
    down = max(0.0, min(1.0, (k - 0.5) / 0.2))
    p = idle(0.0)
    p["pelvis"] = ((-0.35 * up + 0.4 * down, 0, 0), (0, 0, 0.2 * down * e))
    p["neck"] = ((-0.3 * up + 0.5 * down, 0, 0), (0, 0, 0))
    for i in range(4):
        p["trunk%d" % i] = ((-0.4 * up + 0.3 * down, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up.%s" % sd] = ((-0.9 * up + 0.9 * down, 0, 0), (0, 0, 0))
        p["f_lo.%s" % sd] = ((0.9 * up * (1 - down), 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["pelvis"] = ((-0.1 * e, 0, 0.06 * e), (0, 0, -0.12 * e))
    p["neck"] = ((-0.35 * e, 0.2 * e, 0), (0, 0, 0))
    for i in range(4):
        p["trunk%d" % i] = ((-0.35 * e, 0, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["neck"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    for i in range(4):
        p["trunk%d" % i] = ((-0.65 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["ear.%s" % sd] = ((0, s * 0.6 * e, 0), (0, 0, 0))
    return p


print("[art] mammoth: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/mammoth.glb", {"idle": (T, idle), "attack": (0.7, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.35, strength=0.5, floor_y=0.0)
