"""Mantis: the Jade Mantis Matriarch, the Gale Mantis Empress and their brood.  A slender insect
standing tall on four legs: an abdomen of overlapping flared tergites with cerci, a long ridged
prothorax with a leafy pronotum, an inverted-triangle head with huge faceted compound eyes, three
glowing ocelli, mandibles and long antennae, two raptorial forelegs - a spined, grooved femur and
a spined tibia ending in a hook - and a leathery veined tegmen over the fan of the hind wing.
Tinted by the game per enemy; eyes and spines keep their colours.
Run: blender --background --python art/monsters/mantis.py  ->  assets/monsters/mantis.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import Walker, add, flip_die, leg_chain, smooth, zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, SCALE, SKIN, STONE, V, Builder, Rig  # noqa: E402
from sculpt import morph_sphere, strand  # noqa: E402

kit.reset()
creature.realtime()
BY = 0.75
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("thorax", (0, BY, -0.1), (0, BY + 0.05, 0.15), "root")
r.bone("abdomen", (0, BY + 0.02, -0.1), (0, BY + 0.12, -0.9), "thorax")
r.bone("neck", (0, BY + 0.05, 0.15), (0, BY + 0.62, 0.32), "thorax")
r.bone("head", (0, BY + 0.62, 0.32), (0, BY + 0.72, 0.5), "neck")
legs = []
for s, sd in ((1, "L"), (-1, "R")):
    for k, z in enumerate((0.05, -0.18)):
        nm = "leg%d.%s" % (k, sd)
        leg_chain(r, nm, V(0.06 * s, BY, z), V(0.42 * s, BY + 0.25, z + (0.15 if k == 0 else -0.2)), V(0.62 * s, 0.02, z + (0.3 if k == 0 else -0.45)), "thorax")
        legs.append((nm + "_a", nm + "_b", k * math.pi + (0 if s > 0 else math.pi)))
    # raptorial foreleg: coxa down from the prothorax, femur forward, tibia folded back
    r.bone("rap.%s_a" % sd, (0.06 * s, BY + 0.4, 0.26), (0.12 * s, BY + 0.28, 0.5), "neck")
    r.bone("rap.%s_b" % sd, (0.12 * s, BY + 0.28, 0.5), (0.14 * s, BY + 0.72, 0.62), "rap.%s_a" % sd)
    r.bone("rap.%s_c" % sd, (0.14 * s, BY + 0.72, 0.62), (0.13 * s, BY + 0.38, 0.6), "rap.%s_b" % sd)
    r.bone("wing.%s" % sd, (0.05 * s, BY + 0.12, 0.0), (0.12 * s, BY + 0.2, -0.75), "thorax")
b = Builder("mantis")

b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# abdomen: overlapping tergites tapering to the tip, each flaring at its rear edge
abd = [V(0, BY + 0.03, -0.1)]
for k in range(1, 8):
    t = k / 7
    abd.append(V(0, BY + 0.03 + t * 0.12 + 0.03 * math.sin(t * math.pi), -0.1 - t * 0.8))
for k in range(7):
    wk = 0.13 * (1 - 0.45 * k / 7) * (1.0 + 0.3 * math.sin(math.pi * (k + 0.5) / 7))
    A.sclerite(b, abd[k] + (abd[k] - abd[k + 1]) * 0.12, abd[k + 1], wk, wk * 0.62, "abdomen", col=0.84, keels=1, ridge=0.18, belly=0.2, blunt=0.4, flare=0.12, seg=18, rings=8)
for s in (1, -1):
    b.tube([abd[-1], abd[-1] + V(0.03 * s, 0.03, -0.08)], [0.012, 0.002], (0.6, 0.6, 0.6), cls=SCALE, bone="abdomen", tint=1.0, seg=5)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# mesothorax and the long prothorax (the "neck") with a ridged pronotum shield
A.sclerite(b, V(0, BY + 0.02, -0.14), V(0, BY + 0.05, 0.16), 0.105, 0.09, "thorax", col=0.8, keels=1, ridge=0.15, seg=18, rings=10, blunt=0.5)
pro = [V(0, BY + 0.06, 0.12), V(0, BY + 0.22, 0.17), V(0, BY + 0.4, 0.24), V(0, BY + 0.6, 0.31)]
A.sclerite(b, pro[0], pro[1] + (pro[1] - pro[0]) * 0.1, 0.06, 0.05, "thorax", col=0.82, keels=1, ridge=0.3, seg=14, rings=8, blunt=0.5)
A.sclerite(b, pro[1], pro[3] + (pro[3] - pro[2]) * 0.15, 0.058, 0.05, "neck", col=0.86, keels=1, ridge=0.35, seg=16, rings=12, blunt=0.55, up=(0, 0.3, -1))
for s in (1, -1):
    b.ribbon([pro[1] + V(0.04 * s, 0, 0), pro[2] + V(0.06 * s, 0, 0.01), pro[3] + V(0.04 * s, 0, 0)], [0.025, 0.035, 0.02], (0, 0, 1), (0.7, 0.7, 0.7), bone="neck", tint=1.0, col_end=(0.9, 0.9, 0.9))
# head: an inverted triangle with huge compound eyes at the upper corners, three ocelli,
# a clypeus and mandibles below, and long antennae
hc = V(0, BY + 0.68, 0.38)


def head_shape(d):
    p = V(d.x * 0.14, d.y * 0.1, d.z * 0.065)
    p.x *= 1.0 - 0.62 * smooth(0.0, -1.0, d.y)
    return p


morph_sphere(b, hc, head_shape, lambda p, d: (0.82 + 0.1 * d.y,) * 3, cls=SCALE, bone="head", seg=18, rings=12, tint_fn=lambda p, d: 1.0)
b.ellipsoid(hc + V(0, -0.075, 0.035), (0.04, 0.035, 0.03), (0.9, 0.9, 0.9), cls=SCALE, bone="head", tint=1.0, seg=10, rings=6)
for s in (1, -1):
    A.compound_eye(b, hc + V(0.115 * s, 0.035, 0.005), 0.058, "a0f0a0", "head")
    b.cone(hc + V(0.022 * s, -0.115, 0.045), 0.014, 0.05, "f0e8d0", cls=STONE, bone="head", seg=5, rot=(math.pi, 0, 0.3 * s))
    strand(b, [hc + V(0.03 * s, 0.07, 0.03), hc + V(0.08 * s, 0.2, 0.1), hc + V(0.16 * s, 0.34, 0.08), hc + V(0.24 * s, 0.4, -0.02)], 0.006, 0.0015, (0.6, 0.6, 0.6), cls=SCALE, bone="head", seg=4, per=3, tint=1.0)
for k in range(3):
    b.ball(hc + V((k - 1) * 0.02, 0.07 - abs(k - 1) * 0.008, 0.05), 0.008, "e0ffa0", cls=CRYSTAL, bone="head", seg=6, rings=4, mat=MAT_GLOW)
# walking legs: femur, tibia, a jointed tarsus
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(2):
        nm = "leg%d.%s" % (k, sd)
        a0, a1 = V(r.bones[nm + "_a"][0]), V(r.bones[nm + "_a"][1])
        f1 = V(r.bones[nm + "_b"][1])
        A.sclerite(b, a0, a1, 0.03, 0.028, nm + "_a", col=0.78, keels=2, phase=math.pi / 2, seg=12, rings=8, blunt=0.5)
        A.sclerite(b, a1 - (f1 - a1) * 0.04, a1.lerp(f1, 0.8), 0.021, 0.02, nm + "_b", col=0.84, seg=10, rings=8, blunt=0.5)
        A.sclerite(b, a1.lerp(f1, 0.78), f1 + V(0, 0, 0.04 * (1 if k == 0 else -1)), 0.012, 0.012, nm + "_b", col=0.74, seg=8, rings=6, taper=0.4)
    b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
    # raptorial foreleg: a coxa, a thick spined femur with a groove the tibia folds into, the
    # spined tibia ending in a hook
    ra, rb, rc = r.bones["rap.%s_a" % sd], r.bones["rap.%s_b" % sd], r.bones["rap.%s_c" % sd]
    A.sclerite(b, V(ra[0]), V(ra[1]), 0.042, 0.045, "rap.%s_a" % sd, col=0.82, keels=1, ridge=0.2, seg=14, rings=8, blunt=0.5)
    A.sclerite(b, V(rb[0]) - (V(rb[1]) - V(rb[0])) * 0.04, V(rb[1]), 0.045, 0.072, "rap.%s_b" % sd, col=0.88, keels=2, ridge=0.18, seg=18, rings=12, blunt=0.55, taper=0.35, up=(1, 0, 0))
    b.ellipsoid(V(rb[0]).lerp(V(rb[1]), 0.45) + V(0.03 * s, 0, 0.0), (0.012, 0.05, 0.03), "f0f0d0", cls=SKIN, bone="rap.%s_b" % sd, seg=8, rings=5)
    for q in range(7):
        p0 = V(rb[0]).lerp(V(rb[1]), 0.1 + q * 0.12)
        ln = 0.05 if q % 2 else 0.035
        b.cone(p0 + V(0, 0, 0.04), 0.009, ln, "f8f0d8", cls=STONE, bone="rap.%s_b" % sd, seg=5, rot=(1.4, 0, 0))
    A.sclerite(b, V(rc[0]), V(rc[0]).lerp(V(rc[1]), 0.9), 0.024, 0.034, "rap.%s_c" % sd, col=0.88, keels=2, ridge=0.15, seg=14, rings=10, blunt=0.55, taper=0.4, up=(1, 0, 0))
    A.horn(b, [V(rc[0]).lerp(V(rc[1]), 0.85), V(rc[1]), V(rc[1]) + V(0, -0.03, 0.04)], 0.013, (0.8, 0.8, 0.8), "3a3020", "rap.%s_c" % sd, r1=0.002, cls=STONE, seg=8, tint=0.7)
    for q in range(5):
        p0 = V(rc[0]).lerp(V(rc[1]), 0.15 + q * 0.17)
        b.cone(p0 + V(0, 0, 0.025), 0.007, 0.03, "f8f0d8", cls=STONE, bone="rap.%s_c" % sd, seg=5, rot=(1.6, 0, 0))
    b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
    # wings: the leathery tegmen with a network of veins, over the fan of the hind wing
    wg = r.bones["wing.%s" % sd]
    root = V(wg[0])
    hind = []
    for j in range(6):
        tt = j / 5
        hind.append([root + V(0.01 * s, 0.02 * tt, -0.8 * tt), root + V((0.2 + 0.12 * math.sin(tt * math.pi)) * s, 0.0, -0.76 * tt), root + V((0.32 + 0.16 * math.sin(tt * math.pi)) * s, -0.03, -0.7 * tt)])
    b.sheet(hind, (0.9, 0.9, 0.9), cls=CLOTH, bone="wing.%s" % sd, tint=0.5, cols=[(0.92, 0.92, 0.88)] * 6, thickness=0.004)
    rows = []
    for j in range(6):
        tt = j / 5
        rows.append([root + V(0.02 * s, 0.03 * tt + 0.01, -0.86 * tt), root + V((0.13 + 0.06 * math.sin(tt * math.pi)) * s, 0.06 * tt + 0.01, -0.84 * tt), root + V((0.22 + 0.09 * math.sin(tt * math.pi)) * s, 0.025, -0.8 * tt)])
    b.sheet(rows, (0.7, 0.7, 0.7), cls=CLOTH, bone="wing.%s" % sd, tint=1.0, cols=[(0.65 + 0.06 * j,) * 3 for j in range(6)])
    for v in range(4):
        b.tube([root + V(0.04 * s, 0.045, 0), root + V((0.06 + v * 0.05) * s, 0.07, -0.4), root + V((0.07 + v * 0.055) * s, 0.06, -0.8)], [0.004, 0.003, 0.002], (0.45, 0.45, 0.45), cls=SCALE, bone="wing.%s" % sd, tint=1.0, seg=4)
    for c in range(5):
        z = -0.12 - c * 0.14
        b.tube([root + V(0.05 * s, 0.05 + 0.04 * c / 5, z), root + V(0.2 * s, 0.06, z - 0.02)], [0.002, 0.002], (0.5, 0.5, 0.5), cls=SCALE, bone="wing.%s" % sd, tint=1.0, seg=3)

T_IDLE = 2.6
T_WALK = 1.1
WALK = Walker(r, [(a_, b_) for a_, b_, _ in legs], [0.0, 0.5, 0.5, 0.0], duty=0.6)


def sway(p, t, T, amp=1.0):
    w = 2 * math.pi / T
    add(p, "neck", (math.sin(t * w * 2) * 0.05 * amp, math.sin(t * w) * 0.1 * amp, 0))
    add(p, "head", (0, math.sin(t * w + 0.8) * 0.35 * amp, math.sin(t * w) * 0.15 * amp))
    add(p, "abdomen", (math.sin(t * w - 0.8) * 0.05, 0, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "rap.%s_b" % sd, (math.sin(t * w + s_) * 0.05, 0, 0))
        add(p, "wing.%s" % sd, (0, 0, 0.02 * math.sin(t * w * 4) * s_))


def idle(t):
    p = zero_pose(r)
    sway(p, t, T_IDLE)
    # a slow side-to-side rock, the classic mantis sway, over planted feet
    add(p, "thorax", (0, 0, 0), (0.02 * math.sin(2 * math.pi * t / T_IDLE), 0, 0))
    return WALK.step(p)


def walk(t):
    p = zero_pose(r)
    sway(p, t, T_WALK, 0.5)
    ph = (t / T_WALK) % 1.0
    add(p, "thorax", (0, 0, 0), (0.015 * math.sin(2 * math.pi * ph), 0.01 * abs(math.sin(2 * math.pi * ph)), 0))
    return WALK.step(p, ph, 0.26, 0.08)


def attack(t):
    """Raptorial strike: the forelegs cock back, snap out and fold the prey in."""
    k = t / 0.55
    cock = smooth(0.0, 0.3, k) * (1.0 - smooth(0.32, 0.4, k))
    snap = smooth(0.32, 0.42, k) * (1.0 - smooth(0.6, 1.0, k))
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0, 0.3 * snap))
    add(p, "neck", (-0.15 * cock + 0.35 * snap, 0, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "rap.%s_a" % sd, (-0.6 * cock + 0.4 * snap, 0, 0))
        add(p, "rap.%s_b" % sd, (-0.9 * cock + 1.3 * snap, 0, 0))
        add(p, "rap.%s_c" % sd, (1.2 * cock - 0.6 * snap, 0, 0))
        add(p, "wing.%s" % sd, (0, 0.6 * cock * s_, 0.5 * cock * s_))
    return WALK.step(p, offsets=[(0.0, 0.0, 0.3 * snap)] * 4)


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    add(p, "neck", (-0.4 * e, 0.2 * e, 0))
    add(p, "thorax", (-0.1 * e, 0, 0.1 * e), (0, 0, -0.06 * e))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "wing.%s" % sd, (0, 0.4 * e * s_, 0.5 * e * s_))
    return WALK.step(p, offsets=[(0.0, 0.0, -0.08 * e)] * 4)


def die(t):
    p = zero_pose(r)
    k = min(1.0, t / 1.2)
    p = WALK.step(p)
    curl = []
    for a_, b_, _ in legs:
        sg = 1 if ".L_" in a_ else -1
        curl.append((a_, (0.0, 0.0, -1.0 * sg)))
        curl.append((b_, (0.0, 0.0, -1.4 * sg)))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "rap.%s_b" % sd, (0.8 * smooth(0.3, 0.9, k), 0, 0))
        add(p, "neck", (0.3 * smooth(0.2, 0.8, k), 0, 0))
    flip_die(p, t, 1.2, BY, side=1, curl_legs=curl, rest=0.1)
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    # threat display: rear up with wings fanned and forelegs spread
    add(p, "neck", (-0.35 * e, 0, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "rap.%s_a" % sd, (-0.8 * e, 0, -0.6 * e * s_))
        add(p, "wing.%s" % sd, (-0.6 * e, 0.9 * e * s_, 0.9 * e * s_))
    return WALK.step(p)


print("[art] mantis: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/mantis.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=16, dist=0.3, strength=0.5, floor_y=0.0)
