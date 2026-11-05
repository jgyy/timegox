"""Beast: the wolf / lion / qilin / ape shape (Bamboo Wolf, Frost Wolf, Jade Guardian Lion, Azure
Qilin ...).  One smooth skin-modifier body with a mane of fur locks, a hinged jaw, a swishing tail
and three-bone legs.  Tinted by the game per enemy.
Run: blender --background --python art/monsters/beast.py  ->  assets/monsters/beast.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import claws, eyes, fangs, leg_nodes, quad_rig, shade_fn, skin_graph, tail_wave, weights_for, zero_pose  # noqa: E402
from kit import CLOTH, HAIR, SKIN, STONE, V, Builder, env  # noqa: E402

kit.reset()
BY = 0.86
r = quad_rig(BY, 0.42, -0.44, 0.19, (0, 1.12, 0.66), (0, 1.16, 1.02), [(0, 0.96, -0.62), (0, 1.02, -0.86), (0, 1.0, -1.08), (0, 0.92, -1.28), (0, 0.84, -1.44)],
             extra=[("ear.L", (0.12, 1.3, 0.74), (0.17, 1.46, 0.7), "head"), ("ear.R", (-0.12, 1.3, 0.74), (-0.17, 1.46, 0.7), "head")])
b = Builder("beast")
b.auto = weights_for(r, [n for n in r.bones if not n.startswith("ear") and n != "jaw" and n != "root"])


def spine_y(p):
    z = p.z
    return BY + 0.06 + 0.25 * max(0.0, z - 0.4)


shade = shade_fn(spine_y, back=0.5, side=0.72, belly=1.0, stripes=9.0)
spine = [((0, 0.9, -0.62), 0.16), ((0, 0.88, -0.36), (0.27, 0.29)), ((0, 0.88, -0.05), (0.29, 0.29)), ((0, 0.94, 0.3), (0.33, 0.36)), ((0, 1.02, 0.5), (0.27, 0.29)), ((0, 1.13, 0.7), (0.19, 0.2)), ((0, 1.15, 0.86), (0.17, 0.16)), ((0, 1.08, 1.04), (0.1, 0.09)), ((0, 1.06, 1.14), (0.07, 0.065))]
chains = [(spine, None)]
for nm, att in (("f", 3), ("h", 1)):
    for sd in ("L", "R"):
        rad = (0.13, 0.07, 0.045, 0.052) if nm == "f" else (0.17, 0.085, 0.045, 0.052)
        chains.append((leg_nodes(r, nm, sd, rad), att))
nodes, edges = skin_graph(chains)
b.skin(nodes, edges, shade, cls=CLOTH, subdiv=2, tint_fn=lambda p: 1.0)

# muzzle, nose and lower jaw
b.ellipsoid(V(0, 1.04, 1.06), (0.085, 0.06, 0.12), (1.0, 1.0, 1.0), bone="head", tint=1.0, seg=14, rings=8)
b.ellipsoid(V(0, 1.1, 1.18), (0.04, 0.03, 0.03), "1a1018", cls=SKIN, bone="head", seg=10, rings=6)
b.ellipsoid(V(0, 0.98, 0.98), (0.075, 0.035, 0.13), (0.95, 0.95, 0.95), bone="jaw", tint=1.0, seg=12, rings=6)
b.ellipsoid(V(0, 1.005, 0.98), (0.06, 0.012, 0.11), "a03040", cls=SKIN, bone="jaw", seg=10, rings=4)
fangs(b, [V(0.045, 1.02, 1.08), V(-0.045, 1.02, 1.08)], 0.07, "head")
fangs(b, [V(0.04, 0.99, 1.04), V(-0.04, 0.99, 1.04)], 0.05, "jaw", down=False)
eyes(b, V(0, 1.2, 0.97), 0.075, 0.034, iris="ffd040", slit=True, glow=True, rot_y=0.55, h=0.9)
# brow ridge
for s in (1, -1):
    b.tube([V(0.03 * s, 1.24, 1.0), V(0.1 * s, 1.25, 0.95), V(0.13 * s, 1.22, 0.88)], [0.02, 0.022, 0.012], (0.6, 0.6, 0.6), bone="head", tint=1.0, seg=7)
# ears
for s, sd in ((1, "L"), (-1, "R")):
    b.cone(V(0.14 * s, 1.37, 0.72), 0.07, 0.2, (0.55, 0.55, 0.55), bone="ear." + sd, tint=1.0, seg=8, rot=(-0.15, 0, -0.3 * s))
    b.cone(V(0.14 * s, 1.36, 0.735), 0.04, 0.13, "ffb0b0", cls=SKIN, bone="ear." + sd, seg=8, rot=(-0.15, 0, -0.3 * s))
# mane: overlapping fur locks around the neck and down the spine
for i in range(14):
    a = (i / 13 - 0.5) * 3.4
    root = V(math.sin(a) * 0.2, 1.18 + math.cos(a) * 0.08, 0.66 - abs(a) * 0.03)
    tip = root + V(math.sin(a) * 0.18, -0.08 + math.cos(a) * 0.1, -0.22)
    b.leaf(root, tip * 1.0 + (tip - root) * 0.4, 0.1, (0.62, 0.62, 0.62), side=(math.cos(a), 0, 0), cls=HAIR, tint=1.0, col_tip=(0.9, 0.9, 0.9), curl=0.2)
for i in range(10):
    z = 0.55 - i * 0.12
    y = spine_y(V(0, 0, z)) + 0.2 - i * 0.012
    b.leaf(V(0, y, z), V(0, y + 0.13, z - 0.2), 0.07, (0.45, 0.45, 0.45), side=(1, 0, 0), cls=HAIR, tint=1.0, col_tip=(0.6, 0.6, 0.6))
# shaggy coat: overlapping fur locks down the flanks and over the shoulders and haunches, darker
# at the roots and lighter at the tips, so the body reads as fur rather than a smooth skin
for side in (1, -1):
    for i in range(9):
        z = 0.42 - i * 0.11
        for row in range(2):
            y = spine_y(V(0, 0, z)) - 0.02 - row * 0.13
            rx = 0.26 + row * 0.03 - (0.05 if z < -0.3 else 0.0)
            root = V(side * rx, y, z)
            tip = root + V(side * 0.08, -0.15, -0.12)
            b.leaf(root, tip, 0.075, (0.5, 0.5, 0.5), side=(0, 0, 1), cls=HAIR, tint=1.0, col_tip=(0.78, 0.78, 0.78), curl=0.25)
# chest ruff and cheek tufts
for i in range(9):
    a = (i / 8 - 0.5) * 2.6
    root = V(math.sin(a) * 0.17, 0.98, 0.58 + math.cos(a) * 0.05)
    b.leaf(root, root + V(math.sin(a) * 0.06, -0.2, 0.06), 0.07, (0.85, 0.85, 0.85), side=(math.cos(a), 0, -math.sin(a)), cls=HAIR, tint=1.0, col_tip=(1.0, 1.0, 1.0))
for s2 in (1, -1):
    for k in range(3):
        root = V(0.1 * s2, 1.12 - k * 0.03, 0.9 - k * 0.03)
        b.leaf(root, root + V(0.13 * s2, -0.05, -0.08), 0.045, (0.7, 0.7, 0.7), side=(0, 1, 0), cls=HAIR, bone="head", tint=1.0, col_tip=(0.95, 0.95, 0.95))
# tail: tapered with a tuft
tp = [r.head("tail0"), r.head("tail1"), r.head("tail2"), r.head("tail3"), r.tail("tail3")]
b.tube(tp, [0.07, 0.065, 0.055, 0.045, 0.03], (0.7, 0.7, 0.7), bones=["tail0", "tail1", "tail2", "tail3", "tail3"], tint=1.0, seg=10)
for k in range(6):
    a = k / 6 * 2 * math.pi
    base = r.tail("tail3")
    b.leaf(base, base + V(math.cos(a) * 0.08, -0.05 + math.sin(a) * 0.08, -0.2), 0.05, (0.45, 0.45, 0.45), cls=HAIR, bone="tail3", tint=1.0)
# claws on every paw
for nm in ("f", "h"):
    for sd in ("L", "R"):
        pw = r.tail("%s_paw.%s" % (nm, sd))
        claws(b, pw + V(0, 0.0, 0.03), True, "%s_paw.%s" % (nm, sd))

T_IDLE = 3.0


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    br = math.sin(t * w * 2)
    p["pelvis"] = ((0, 0, 0), (0, br * 0.01, 0))
    p["chest"] = ((br * 0.02, 0, 0), (0, 0, 0))
    p["neck"] = ((math.sin(t * w) * 0.05, math.sin(t * w) * 0.15, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w * 2) * 0.04, math.sin(t * w) * 0.1, 0), (0, 0, 0))
    p["jaw"] = ((0.06 + abs(math.sin(t * w)) * 0.1, 0, 0), (0, 0, 0))
    p["ear.L"] = ((0, 0, -0.2 * max(0.0, math.sin(t * w * 3)) ** 8), (0, 0, 0))
    p["ear.R"] = ((0, 0, 0.2 * max(0.0, math.sin(t * w * 3 + 1.0)) ** 8), (0, 0, 0))
    tail_wave(p, 4, t, w * 2, 0.18, curl=-0.1)
    for sd in ("L", "R"):
        p["f_up." + sd] = ((br * 0.02, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.05 * lunge, 0.45 * lunge))
    p["chest"] = ((0.25 * e - 0.4 * lunge, 0, 0), (0, 0, 0))
    p["neck"] = ((0.3 * lunge, 0, 0), (0, 0, 0))
    p["head"] = ((-0.2 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.75 * lunge, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up." + sd] = ((-0.9 * lunge, 0, 0), (0, 0, 0))
        p["f_lo." + sd] = ((0.6 * lunge, 0, 0), (0, 0, 0))
        p["h_up." + sd] = ((0.4 * lunge, 0, 0), (0, 0, 0))
    tail_wave(p, 4, t, 12.0, 0.25)
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0, -0.18 * e))
    p["chest"] = ((-0.25 * e, 0, 0.1 * e), (0, 0, 0))
    p["neck"] = ((-0.4 * e, 0.2 * e, 0), (0, 0, 0))
    p["jaw"] = ((0.35 * e, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["ear." + sd] = ((0.6 * e, 0, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    # rear up and roar
    p["pelvis"] = ((-0.3 * e, 0, 0), (0, 0.05 * e, 0))
    p["neck"] = ((-0.55 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.9 * e, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up." + sd] = ((-0.6 * e, 0, 0), (0, 0, 0))
        p["f_lo." + sd] = ((0.9 * e, 0, 0), (0, 0, 0))
        p["h_up." + sd] = ((0.3 * e, 0, 0), (0, 0, 0))
    tail_wave(p, 4, t, 9.0, 0.3, curl=0.3)
    return p


print("[art] beast: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/beast.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
