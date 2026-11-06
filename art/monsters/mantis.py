"""Mantis: the Jade Mantis Matriarch, the Gale Mantis Empress and their brood.  A slender insect
standing tall on four legs: segmented abdomen, a long neck-like prothorax, a triangular head with
huge compound eyes and feathery antennae, two folded raptorial forelegs lined with spines, and
two pairs of veined wings that flare open when it strikes.
Tinted by the game per enemy; eyes and spines keep their colours.
Run: blender --background --python art/monsters/mantis.py  ->  assets/monsters/mantis.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import leg_chain, scuttle, zero_pose  # noqa: E402
from kit import CLOTH, MAT_GLOW, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402

kit.reset()
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

# abdomen: tapered and segmented
for k in range(6):
    t = k / 5
    z = -0.12 - t * 0.72
    rr = 0.13 * (1.0 - t * 0.45)
    b.ellipsoid(V(0, BY + 0.03 + t * 0.1, z), (rr, rr * 0.85, 0.09), (0.8 + 0.04 * (k % 2), 0.8 + 0.04 * (k % 2), 0.8 + 0.04 * (k % 2)), cls=SCALE, bone="abdomen", tint=1.0, seg=14, rings=8)
b.ellipsoid(V(0, BY + 0.03, 0.02), (0.1, 0.09, 0.16), (0.75, 0.75, 0.75), cls=SCALE, bone="thorax", tint=1.0, seg=14, rings=8)
b.tube([V(0, BY + 0.06, 0.12), V(0, BY + 0.35, 0.22), V(0, BY + 0.6, 0.31)], [0.06, 0.05, 0.045], (0.8, 0.8, 0.8), cls=SCALE, bones=["thorax", "neck", "neck"], tint=1.0, seg=10)
# head: a wide triangle with bulging compound eyes, mandibles and feathery antennae
hc = V(0, BY + 0.68, 0.38)
b.ellipsoid(hc, (0.12, 0.08, 0.07), (0.85, 0.85, 0.85), cls=SCALE, bone="head", tint=1.0, seg=14, rings=8)
b.ellipsoid(hc + V(0, -0.08, 0.04), (0.05, 0.06, 0.04), (0.9, 0.9, 0.9), cls=SCALE, bone="head", tint=1.0, seg=10, rings=6)
for s in (1, -1):
    b.ellipsoid(hc + V(0.11 * s, 0.03, 0.0), (0.06, 0.07, 0.06), "a0f0a0", cls=SKIN, bone="head", seg=12, rings=8)
    b.ellipsoid(hc + V(0.13 * s, 0.04, 0.04), (0.02, 0.025, 0.015), "103010", cls=SKIN, bone="head", seg=8, rings=5)
    b.ball(hc + V(0.12 * s, 0.07, 0.04), 0.012, "ffffff", cls=SKIN, bone="head", seg=6, rings=4, mat=MAT_GLOW)
    b.tube([hc + V(0.03 * s, 0.07, 0.03), hc + V(0.1 * s, 0.25, 0.12), hc + V(0.18 * s, 0.38, 0.05)], [0.006, 0.005, 0.002], (0.6, 0.6, 0.6), cls=SCALE, bone="head", tint=1.0, seg=4)
    b.cone(hc + V(0.025 * s, -0.13, 0.05), 0.015, 0.05, "f0e8d0", cls=STONE, bone="head", seg=5, rot=(math.pi, 0, 0))
# walking legs
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(2):
        nm = "leg%d.%s" % (k, sd)
        a0, a1 = r.bones[nm + "_a"][0], r.bones[nm + "_a"][1]
        f1 = r.bones[nm + "_b"][1]
        b.tube([a0, a1], [0.03, 0.025], (0.75, 0.75, 0.75), cls=SCALE, bones=[nm + "_a", {nm + "_a": 0.5, nm + "_b": 0.5}], tint=1.0, seg=7)
        b.tube([a1, f1], [0.022, 0.008], (0.85, 0.85, 0.85), cls=SCALE, bones=[{nm + "_a": 0.5, nm + "_b": 0.5}, nm + "_b"], tint=1.0, seg=7)
    # raptorial foreleg with a row of spines on the femur and tibia
    ra, rb, rc = r.bones["rap.%s_a" % sd], r.bones["rap.%s_b" % sd], r.bones["rap.%s_c" % sd]
    b.tube([ra[0], ra[1]], [0.04, 0.04], (0.8, 0.8, 0.8), cls=SCALE, bone="rap.%s_a" % sd, tint=1.0, seg=8)
    b.tube([rb[0], V(rb[0]).lerp(V(rb[1]), 0.5), rb[1]], [(0.045, 0.06), (0.05, 0.07), (0.03, 0.04)], (0.85, 0.85, 0.85), cls=SCALE, bone="rap.%s_b" % sd, tint=1.0, seg=8)
    b.tube([rc[0], rc[1]], [(0.025, 0.035), (0.006, 0.008)], (0.85, 0.85, 0.85), cls=SCALE, bone="rap.%s_c" % sd, tint=1.0, seg=7)
    for q in range(5):
        p0 = V(rb[0]).lerp(V(rb[1]), 0.15 + q * 0.17)
        b.cone(p0 + V(0, 0, 0.04), 0.01, 0.06, "f8f0d8", cls=STONE, bone="rap.%s_b" % sd, seg=5, rot=(1.4, 0, 0))
    # wings: an outer leathery tegmen over a veined, translucent-looking hind wing
    wg = r.bones["wing.%s" % sd]
    root = V(wg[0])
    rows = []
    for j in range(5):
        tt = j / 4
        rows.append([root + V(0.02 * s, 0.03 * tt, -0.85 * tt), root + V((0.14 + 0.06 * math.sin(tt * math.pi)) * s, 0.06 * tt, -0.82 * tt), root + V((0.24 + 0.1 * math.sin(tt * math.pi)) * s, 0.02, -0.78 * tt)])
    b.sheet(rows, (0.7, 0.7, 0.7), cls=CLOTH, bone="wing.%s" % sd, tint=1.0, cols=[(0.65 + 0.06 * j, 0.65 + 0.06 * j, 0.65 + 0.06 * j) for j in range(5)])
    for v in range(3):
        b.tube([root + V(0.04 * s, 0.035, 0), root + V((0.08 + v * 0.07) * s, 0.06, -0.78)], [0.004, 0.003], (0.45, 0.45, 0.45), cls=SCALE, bone="wing.%s" % sd, tint=1.0, seg=4)

T_IDLE = 2.6


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    scuttle(p, legs, t, w, 0.04, 0.03)
    p["neck"] = ((math.sin(t * w) * 0.05, math.sin(t * w * 0.5) * 0.1, 0), (0, 0, 0))
    p["head"] = ((0, math.sin(t * w * 0.7) * 0.35, math.sin(t * w * 0.5) * 0.2), (0, 0, 0))
    p["abdomen"] = ((math.sin(t * w) * 0.05, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["rap.%s_b" % sd] = ((math.sin(t * w + s) * 0.06, 0, 0), (0, 0, 0))
        p["wing.%s" % sd] = ((0, 0, 0.03 * math.sin(t * w * 4) * s), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    strike = math.sin(min(1.0, k * 1.8) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0, 0.35 * strike))
    p["neck"] = ((0.35 * strike, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["rap.%s_a" % sd] = ((-0.6 * e + 0.4 * strike, 0, 0), (0, 0, 0))
        p["rap.%s_b" % sd] = ((-0.9 * e + 1.3 * strike, 0, 0), (0, 0, 0))
        p["rap.%s_c" % sd] = ((1.2 * e - 0.6 * strike, 0, 0), (0, 0, 0))
        p["wing.%s" % sd] = ((0, 0.6 * e * s, 0.5 * e * s), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["neck"] = ((-0.4 * e, 0.2 * e, 0), (0, 0, 0))
    p["thorax"] = ((-0.1 * e, 0, 0.1 * e), (0, 0, -0.06 * e))
    scuttle(p, legs, t, 35.0, 0.15 * e, 0.1 * e)
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    # threat display: rear up with wings fanned and forelegs spread
    p["neck"] = ((-0.35 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["rap.%s_a" % sd] = ((-0.8 * e, 0, -0.6 * e * s), (0, 0, 0))
        p["wing.%s" % sd] = ((-0.6 * e, 0.9 * e * s, 0.9 * e * s), (0, 0, 0))
    return p


print("[art] mantis: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/mantis.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
