"""Fox: the nine-tailed fox spirit of the Maple Gorge (Part VI) and the Hounds of the Ten Courts.
A slender skin-modifier body on long legs, a narrow muzzle, tall ears, cheek ruffs and a white
bib, and nine bushy tails fanned behind it, each tipped in white with a wisp of fox-fire.  Every
tail is its own three-bone chain, so the fan ripples like flames.  Tinted by the game per enemy;
the white tips, bib and fox-fire keep their own colours.
Run: blender --background --python art/monsters/fox.py  ->  assets/monsters/fox.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import claws, eyes, fangs, glow_ball, leg_nodes, quad_rig, shade_fn, skin_graph, weights_for, zero_pose  # noqa: E402
from kit import CLOTH, HAIR, SKIN, V, Builder, Rig, env  # noqa: E402

kit.reset()
BY = 0.78
N_TAILS = 9
extra = [("ear.L", (0.09, 1.2, 0.84), (0.13, 1.44, 0.8), "head"), ("ear.R", (-0.09, 1.2, 0.84), (-0.13, 1.44, 0.8), "head")]
# nine tail chains fanned behind the hips
tails = []
for k in range(N_TAILS):
    # a three-dimensional fan: outer tails sweep wide and low, inner ones rise high; heights,
    # lengths and curl vary per tail so the tips do not line up
    u = k / (N_TAILS - 1) - 0.5
    a = u * 3.0
    ln = 1.0 - 0.18 * abs(math.sin(k * 2.3))
    lift = 0.55 - 0.45 * abs(u) * 2 + 0.08 * math.sin(k * 1.7)
    base = V(0, 0.86, -0.5)
    d1 = V(math.sin(a) * 0.25, 0.1 + lift * 0.3, -0.36) * ln
    d2 = V(math.sin(a) * 0.55, lift, -0.18 + 0.12 * math.cos(k * 1.3)) * ln
    d3 = V(math.sin(a) * 0.3 + 0.06 * math.cos(k), 0.1 - 0.15 * abs(u), 0.18) * ln
    p1 = base + d1
    p2 = p1 + d2
    p3 = p2 + d3
    tails.append([base, p1, p2, p3])
    extra.append(("ft%d_0" % k, base, p1, "pelvis"))
    extra.append(("ft%d_1" % k, p1, p2, "ft%d_0" % k))
    extra.append(("ft%d_2" % k, p2, p3, "ft%d_1" % k))
r = quad_rig(BY, 0.38, -0.42, 0.15, (0, 1.06, 0.62), (0, 1.1, 0.98), [(0, 0.86, -0.5), (0, 0.9, -0.6)], extra=extra)
b = Builder("fox")
b.auto = weights_for(r, [n for n in r.bones if not n.startswith("ear") and not n.startswith("ft") and n not in ("jaw", "root", "tail0")])


def spine_y(p):
    return BY + 0.05 + 0.22 * max(0.0, p.z - 0.4)


shade = shade_fn(spine_y, back=0.62, side=0.8, belly=1.08)
spine = [((0, 0.84, -0.5), 0.12), ((0, 0.82, -0.3), (0.2, 0.21)), ((0, 0.82, -0.05), (0.2, 0.2)), ((0, 0.88, 0.25), (0.24, 0.26)), ((0, 0.96, 0.46), (0.2, 0.21)), ((0, 1.06, 0.64), (0.13, 0.14)), ((0, 1.1, 0.8), (0.13, 0.12)), ((0, 1.05, 0.98), (0.07, 0.065)), ((0, 1.02, 1.1), (0.04, 0.035))]
chains = [(spine, None)]
for nm, att in (("f", 3), ("h", 1)):
    for sd in ("L", "R"):
        rad = (0.085, 0.045, 0.028, 0.035) if nm == "f" else (0.11, 0.05, 0.028, 0.035)
        chains.append((leg_nodes(r, nm, sd, rad), att))
nodes, edges = skin_graph(chains)
b.skin(nodes, edges, shade, cls=CLOTH, subdiv=2, tint_fn=lambda p: 1.0)

# white bib on the chest and throat, white cheeks
b.ellipsoid(V(0, 0.98, 0.52), (0.13, 0.17, 0.1), "f4f0ea", cls=HAIR, bone="chest", seg=14, rings=8)
for i in range(8):
    a = (i / 7 - 0.5) * 2.2
    root = V(math.sin(a) * 0.1, 0.92 - abs(a) * 0.02, 0.55)
    b.leaf(root, root + V(math.sin(a) * 0.05, -0.16, 0.06), 0.05, "f4f0ea", side=(math.cos(a), 0, -math.sin(a)), cls=HAIR, col_tip="ffffff")
# narrow muzzle, black nose, jaw
b.tube([V(0, 1.08, 0.88), V(0, 1.05, 1.02), V(0, 1.02, 1.14)], [(0.07, 0.06), (0.05, 0.045), (0.025, 0.022)], (0.95, 0.95, 0.95), bone="head", tint=1.0, seg=12)
b.ellipsoid(V(0, 1.03, 1.15), (0.022, 0.018, 0.018), "141014", cls=SKIN, bone="head", seg=10, rings=6)
b.ellipsoid(V(0, 0.99, 1.0), (0.045, 0.022, 0.1), "f4f0ea", cls=HAIR, bone="jaw", seg=10, rings=6)
fangs(b, [V(0.025, 1.0, 1.08), V(-0.025, 1.0, 1.08)], 0.04, "head")
eyes(b, V(0, 1.14, 0.92), 0.06, 0.03, iris="ffb020", slit=True, glow=True, rot_y=0.6, h=0.8)
# cheek ruffs
for s in (1, -1):
    for k in range(4):
        root = V(0.09 * s, 1.07 - k * 0.025, 0.86 - k * 0.02)
        b.leaf(root, root + V(0.12 * s, -0.04 - k * 0.02, -0.06), 0.045, (0.85, 0.85, 0.85), side=(0, 1, 0), cls=HAIR, tint=1.0, col_tip="ffffff")
    # tall ears with dark backs and pale insides
    b.cone(V(0.11 * s, 1.3, 0.8), 0.07, 0.26, (0.6, 0.6, 0.6), bone="ear." + ("L" if s > 0 else "R"), tint=1.0, seg=8, rot=(-0.1, 0, -0.18 * s))
    b.cone(V(0.11 * s, 1.29, 0.815), 0.045, 0.19, "f8e0d8", cls=SKIN, bone="ear." + ("L" if s > 0 else "R"), seg=8, rot=(-0.1, 0, -0.18 * s))
    b.cone(V(0.11 * s, 1.41, 0.795), 0.03, 0.06, "1a1418", cls=HAIR, bone="ear." + ("L" if s > 0 else "R"), seg=6, rot=(-0.1, 0, -0.18 * s))
# dark socks on the legs
for nm in ("f", "h"):
    for sd in ("L", "R"):
        lo = r.bones["%s_lo.%s" % (nm, sd)]
        pw = r.bones["%s_paw.%s" % (nm, sd)]
        b.tube([V(lo[0]).lerp(V(lo[1]), 0.4), V(lo[1]), V(pw[1])], [0.033, 0.032, 0.036], "2a2024", cls=HAIR, bones=["%s_lo.%s" % (nm, sd), "%s_lo.%s" % (nm, sd), "%s_paw.%s" % (nm, sd)], seg=8)
        claws(b, V(pw[1]) + V(0, 0.0, 0.02), True, "%s_paw.%s" % (nm, sd), length=0.04)
# nine bushy tails: a fat tube per tail with fur locks along it, a white tip and a wisp of fox-fire
for k, pts in enumerate(tails):
    bones = ["ft%d_0" % k, "ft%d_1" % k, "ft%d_1" % k, "ft%d_2" % k, "ft%d_2" % k]
    path = [pts[0], pts[1], pts[1].lerp(pts[2], 0.5), pts[2], pts[3]]
    # body colour fading into a white tip along the tube (the tip is not tinted)
    b.tube(path, [0.06, 0.13, 0.16, 0.13, 0.05], (0.8, 0.8, 0.8), bones=bones, tint=1.0, seg=12, cls=HAIR,
           cols=[(0.75, 0.75, 0.75), (0.8, 0.8, 0.8), (0.85, 0.85, 0.85), (0.96, 0.95, 0.93), (1.0, 0.99, 0.97)], tints=[1.0, 1.0, 1.0, 0.25, 0.0])
    for j in range(5):
        t = 0.2 + j * 0.16
        q = pts[1].lerp(pts[2], t) if t < 1 else pts[2]
        side = (pts[2] - pts[1]).cross(V(0, 1, 0)).normalized()
        b.leaf(q, q + (pts[2] - pts[1]).normalized() * 0.22 + side * 0.1, 0.09, (0.75, 0.75, 0.75), side=side, cls=HAIR, bone="ft%d_1" % k, tint=1.0, col_tip=(0.95, 0.95, 0.95))
    glow_ball(b, pts[3] + (pts[3] - pts[2]).normalized() * 0.08, 0.045, "ffb860", "ft%d_2" % k)

T_IDLE = 3.0


def fan(p, t, speed, amp, spread=0.0):
    for k in range(N_TAILS):
        ph = t * speed + k * 0.55
        for j in range(3):
            p["ft%d_%d" % (k, j)] = ((math.sin(ph - j * 0.8) * amp * (0.6 + j * 0.3) - spread * 0.2, math.cos(ph - j * 0.6) * amp * 0.6, (k / (N_TAILS - 1) - 0.5) * spread), (0, 0, 0))


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    br = math.sin(t * w * 2)
    p["pelvis"] = ((0, 0, 0), (0, br * 0.008, 0))
    p["chest"] = ((br * 0.02, 0, 0), (0, 0, 0))
    p["neck"] = ((math.sin(t * w) * 0.05, math.sin(t * w) * 0.18, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w * 2) * 0.05, 0, math.sin(t * w) * 0.12), (0, 0, 0))
    p["jaw"] = ((0.04 + abs(math.sin(t * w)) * 0.06, 0, 0), (0, 0, 0))
    p["ear.L"] = ((0, 0, -0.25 * max(0.0, math.sin(t * w * 3)) ** 8), (0, 0, 0))
    p["ear.R"] = ((0, 0, 0.25 * max(0.0, math.sin(t * w * 3 + 1.3)) ** 8), (0, 0, 0))
    fan(p, t, w * 2, 0.16)
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.08 * lunge, 0.5 * lunge))
    p["chest"] = ((0.2 * e - 0.35 * lunge, 0, 0), (0, 0, 0))
    p["neck"] = ((0.3 * lunge, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.7 * lunge, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up." + sd] = ((-0.9 * lunge, 0, 0), (0, 0, 0))
        p["f_lo." + sd] = ((0.6 * lunge, 0, 0), (0, 0, 0))
        p["h_up." + sd] = ((0.45 * lunge, 0, 0), (0, 0, 0))
    fan(p, t, 14.0, 0.25, spread=0.4 * e)
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0, -0.2 * e))
    p["chest"] = ((-0.25 * e, 0, 0.12 * e), (0, 0, 0))
    p["neck"] = ((-0.4 * e, 0.25 * e, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["ear." + sd] = ((0.7 * e, 0, 0), (0, 0, 0))
    fan(p, t, 20.0, 0.1, spread=-0.5 * e)
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    # the tails flare into a full fan of fox-fire
    p["neck"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.5 * e, 0, 0), (0, 0, 0))
    fan(p, t, 10.0, 0.12, spread=1.0 * e)
    return p


print("[art] fox: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/fox.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
