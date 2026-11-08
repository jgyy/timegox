"""Tortoise (Eon Tortoise, Moss-Backed Tortoise, Xuan Wu): a high domed carapace of scutes - five
vertebrals, four costals a side and a serrated ring of marginals, each raised to a pale areola,
ringed with growth lines and split by deep seams - over a pale, plated plastron.  The neck, head,
legs and tail are sculpted in one piece of clay: loose folds round the neck, a heavy head with a
horny hooked beak and lidded eyes, thick elephantine legs armoured with big raised scales on
round pads with blunt nails, a short tapering tail.  Moss and crystals grow on the shell.  The
shell takes the enemy's colour, the skin its secondary colour.
Run: blender --background --python art/monsters/tortoise.py  ->  assets/monsters/tortoise.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import zero_pose  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from sculpt import morph_sphere, smooth  # noqa: E402
from kit import CRYSTAL, FOLIAGE, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402
from creature import Walker, add  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(9)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("shell", (0, 0.55, -0.3), (0, 0.6, 0.3), "root")
r.bone("neck", (0, 0.6, 0.55), (0, 0.72, 0.85), "shell")
r.bone("head", (0, 0.72, 0.85), (0, 0.74, 1.1), "neck")
r.bone("jaw", (0, 0.66, 0.9), (0, 0.64, 1.1), "head")
r.bone("tail", (0, 0.5, -0.7), (0, 0.4, -0.95), "shell")
for fz, nm in ((0.42, "f"), (-0.42, "h")):
    for s, sd in ((1, "L"), (-1, "R")):
        r.bone("%s_up.%s" % (nm, sd), (0.45 * s, 0.5, fz), (0.6 * s, 0.3, fz + 0.05), "shell")
        r.bone("%s_lo.%s" % (nm, sd), (0.6 * s, 0.3, fz + 0.05), (0.62 * s, 0.03, fz + 0.08), "%s_up.%s" % (nm, sd))

def cells(p, scale, seed=0):
    """Worley noise: distances (in cell units) to the nearest two jittered points of a 3D grid,
    for scale and scute patterns."""
    x, y, z = p[0] * scale, p[1] * scale, p[2] * scale
    ix, iy, iz = math.floor(x), math.floor(y), math.floor(z)
    f1 = f2 = 9.0
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                cx, cy, cz = ix + dx, iy + dy, iz + dz
                h = ((cx * 73856093) ^ (cy * 19349663) ^ (cz * 83492791) ^ (seed * 2654435761)) & 0xFFFFFFFF
                jx = (h & 1023) / 1023.0
                jy = ((h >> 10) & 1023) / 1023.0
                jz = ((h >> 20) & 1023) / 1023.0
                d = (cx + jx - x) ** 2 + (cy + jy - y) ** 2 + (cz + jz - z) ** 2
                if d < f1:
                    f1, f2 = d, f1
                elif d < f2:
                    f2 = d
    return math.sqrt(f1), math.sqrt(f2)


b = Builder("tortoise")
# carapace: a high dome whose scutes are a Voronoi pattern over its surface - five vertebral
# scutes down the spine, four costals either side and a ring of marginals - each raised towards
# a pale areola, ringed with growth lines and split from its neighbours by deep seams
SC = V(0, 0.42, 0)
CENTRES = []
for k in range(5):
    CENTRES.append(V(0, 1.0, 0.62 - k * 0.31).normalized())
for s2 in (1, -1):
    for k in range(4):
        CENTRES.append(V(0.62 * s2, 0.72, 0.5 - k * 0.33).normalized())
for k in range(22):
    a = k / 22 * 2 * math.pi
    CENTRES.append(V(math.sin(a), 0.12, math.cos(a)).normalized())


def scute(d):
    best = 9.0
    second = 9.0
    for c in CENTRES:
        dd = (d - c).length
        if dd < best:
            best, second = dd, best
        elif dd < second:
            second = dd
    return best, second - best


def shell_shape(d):
    if d.y < 0.0:
        # the flat underside (plastron) sits inside the rim
        return V(d.x * 0.74, d.y * 0.12, d.z * 0.86)
    p = V(d.x * 0.84, d.y * 0.84, d.z * 0.96)
    best, gap = scute(d)
    seam = smooth(0.09, 0.0, gap)
    # each scute rises to a low pyramid at its areola; deep grooves between scutes
    p = p * (1.0 + 0.05 * smooth(0.45, 0.0, best) - 0.035 * seam)
    # the rim flares out and is serrated at the back
    if d.y < 0.18:
        flare = smooth(0.18, 0.02, d.y)
        teeth = 0.03 * max(0.0, -d.z) * abs(math.sin(math.atan2(d.x, d.z) * 11.0))
        p = p + V(d.x, 0, d.z) * (0.07 * flare + teeth * flare)
    return p


def shell_col(p, d):
    if d.y < 0.0:
        # plastron: pale, split into paired plates
        grid = smooth(0.02, 0.0, abs(math.sin(p.z * 6.0))) + smooth(0.015, 0.0, abs(p.x))
        return ((0.97 - 0.3 * min(1.0, grid)),) * 3
    best, gap = scute(d)
    seam = smooth(0.07, 0.0, gap)
    rings = 0.5 + 0.5 * math.cos(best * 34.0)
    areola = smooth(0.14, 0.04, best)
    v = 0.7 + 0.22 * areola + 0.1 * rings * smooth(0.06, 0.16, best) + 0.08 * smooth(0.2, 0.45, best)
    v *= 1.0 - 0.75 * seam
    return (v, v, v)


# horn, not wet scales: the carapace takes the matte horn surface class
morph_sphere(b, SC, shell_shape, shell_col, cls=STONE, bone="shell", seg=96, rings=48, tint_fn=lambda p, d: 1.0)
# moss in the seams and on the crown, crystals pushing up through it
rnd = random.Random(9)
for k in range(18):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.05, 0.62)
    d = V(math.sin(a) * rr, 1.0, math.cos(a) * rr).normalized()
    root = SC + shell_shape(d) - d * 0.01
    b.leaf(root, root + d * 0.13 + V(rnd.uniform(-0.06, 0.06), 0.03, rnd.uniform(-0.06, 0.06)), 0.045, "5a8a3a", cls=FOLIAGE, bone="shell", col_tip="9ac860")
for k in range(5):
    a = k * 1.7
    d = V(math.sin(a) * 0.35, 1.0, math.cos(a) * 0.35 - 0.1).normalized()
    b.crystal(SC + shell_shape(d) - d * 0.03, 0.05 + 0.01 * (k % 2), 0.24 + 0.06 * (k % 3), "a0f0ff", cls=CRYSTAL, bone="shell", rot=(0.4 * d.z, 0, -0.4 * d.x))

# skin: the neck, head, legs and tail sculpted in one family of clay, in the skin palette slot
SKIN_GREY = 0.86


def skin_col(p, info):
    tag = info.tag
    if tag == "beak":
        return (0.86, 0.84, 0.78)
    f1, f2 = cells(p, 14.0 if tag in ("leg", "foot") else 22.0, 3)
    edge = smooth(0.0, 0.2, f2 - f1)
    v = SKIN_GREY * (0.7 + 0.32 * edge)
    if tag == "neck":
        v = SKIN_GREY * (0.86 + 0.1 * (0.5 + 0.5 * math.sin(info.t * 40.0)))
    if tag == "head" and info.n.y > 0.3:
        v *= 0.9 + 0.1 * edge
    return (v, v, v)


def skin_post(p, info):
    tag = info.tag
    nn = info.n
    if tag == "neck":
        # loose folds of skin round the neck
        return nn * (0.012 * math.sin(info.t * 40.0) - 0.004)
    if tag in ("leg", "foot", "tail") or (tag == "head" and nn.y > 0.2):
        f1, f2 = cells(p, 14.0 if tag in ("leg", "foot") else 22.0, 3)
        # big, raised scales: domed in the middle of each cell, grooved at the edges
        return nn * (0.02 * smooth(0.0, 0.35, f2 - f1) - 0.007)
    return None


sk = Clay(0.02, "tortoise_skin")
neck = [V(0, 0.52, 0.48), V(0, 0.6, 0.66), V(0, 0.7, 0.84)]
sk.chain(neck, [0.16, 0.13, 0.11], bones=lambda p, t: {"shell": max(0.0, 0.7 - t * 1.4), "neck": min(1.0, 0.3 + t * 1.4)} if t < 0.5 else ({"neck": 1.0} if t < 0.85 else {"neck": 1.0 - (t - 0.85) / 0.3, "head": (t - 0.85) / 0.3}), tag="neck")
HC = V(0, 0.77, 0.99)
sk.ellipsoid(HC + V(0, 0.0, -0.03), (0.16, 0.13, 0.19), bones={"head": 1.0}, tag="head")
sk.ellipsoid(HC + V(0, 0.035, 0.08), (0.12, 0.095, 0.12), bones={"head": 1.0}, tag="head")
sk.ellipsoid(HC + V(0, -0.08, 0.05), (0.12, 0.05, 0.14), bones={"jaw": 1.0}, tag="jaw")
for s in (1, -1):
    sk.ellipsoid(HC + V(0.11 * s, 0.0, 0.02), (0.06, 0.07, 0.08), bones={"head": 1.0}, tag="head")
# legs: thick, elephant-like columns of big scales, the forelegs bowed outwards, ending in round
# pads; the upper legs disappear under the rim of the shell
for nm in ("f", "h"):
    for sd, s2 in (("L", 1), ("R", -1)):
        up = "%s_up.%s" % (nm, sd)
        lo = "%s_lo.%s" % (nm, sd)
        h0, k0, f0 = r.head(up), r.tail(up), r.tail(lo)
        sk.chain([h0 + V(-0.1 * s2, -0.08, 0.0), k0 + V(0.03 * s2, 0.0, 0.0), f0 + V(0, 0.05, 0)], [0.12, 0.15, 0.15], bones=limb_weights([up, lo]), tag="leg", t0=0.0, t1=2.0)
        sk.ellipsoid(f0 + V(0, 0.04, 0.03), (0.17, 0.06, 0.18), bones={lo: 1.0}, tag="foot")
# a short, tapering tail
sk.chain([V(0, 0.48, -0.76), V(0, 0.43, -0.86), V(0, 0.37, -0.97)], [0.07, 0.05, 0.02], bones={"tail": 1.0}, tag="tail")
b.cur_pal = 0.5  # palette slot (kit.py): the skin is naturally another colour than the shell
sk.build(b, skin_col, cls=SCALE, tint_fn=lambda p, info: 0.0 if info.tag == "beak" else 0.55, post=skin_post)
b.cur_pal = 0.0
# a horny, hooked beak over a hinged lower bill, heavy-lidded eyes, nostrils
upper = [HC + V(0, 0.05, 0.16), HC + V(0, 0.025, 0.22), HC + V(0, -0.025, 0.25), HC + V(0, -0.08, 0.23)]
A.horn(b, upper, 0.07, "d8c8a0", "8a7858", "head", r1=0.01, cls=STONE, seg=12, flat=0.75, up=(1, 0, 0), tint=0.0)
lower = [HC + V(0, -0.09, 0.12), HC + V(0, -0.1, 0.18), HC + V(0, -0.09, 0.225)]
A.horn(b, lower, 0.055, "d8c8a0", "8a7858", "jaw", r1=0.01, cls=STONE, seg=10, flat=0.7, up=(1, 0, 0), tint=0.0)
for s in (1, -1):
    A.animal_eye(b, HC + V(0.1 * s, 0.04, 0.1), V(0.8 * s, 0.1, 0.6), 0.032, "c09020", "head", pupil="round", almond=0.62, lid="3a3028", lid_w=0.2, side=s)
    b.ball(HC + V(0.026 * s, 0.035, 0.225), 0.009, "201810", cls=SKIN, bone="head", seg=6, rings=4)
# claws: four blunt, horny nails on every foot
for nm in ("f", "h"):
    for sd, s2 in (("L", 1), ("R", -1)):
        lo = "%s_lo.%s" % (nm, sd)
        f0 = r.tail(lo)
        for k in range(4):
            u = (k / 3 - 0.5) * 2
            A.claw(b, f0 + V(u * 0.08, 0.035, 0.17 - abs(u) * 0.04), V(u * 0.3, -0.25, 1.0), 0.06, 0.02, lo, hook=0.4, col0="4a4038", col1="d8ccb0")


T = 4.0


def idle(t):
    w = 2 * math.pi / T
    p = zero_pose(r)
    p["shell"] = ((math.sin(t * w) * 0.015, 0, math.sin(t * w + 0.9) * 0.01), (0, math.sin(t * w * 2) * 0.008, 0))
    p["neck"] = ((math.sin(t * w) * 0.08, math.sin(t * w + 0.5) * 0.25, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w + 1) * 0.06, math.sin(t * w + 0.9) * 0.15, 0), (0, 0, 0))
    p["jaw"] = ((0.05 + 0.05 * abs(math.sin(t * w)), 0, 0), (0, 0, 0))
    p["tail"] = ((0, math.sin(t * w * 2) * 0.2, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    snap = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["neck"] = ((0.4 * snap - 0.3 * e, 0, 0), (0, 0.05 * snap, 0.35 * snap))
    p["head"] = ((-0.2 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.8 * snap, 0, 0), (0, 0, 0))
    p["shell"] = ((0.1 * snap, 0, 0), (0, 0, 0.1 * snap))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["neck"] = ((0, 0, 0), (0, -0.05 * e, -0.25 * e))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["shell"] = ((-0.1 * e, 0, 0.08 * e), (0, 0, -0.1 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["shell"] = ((-0.25 * e, 0, 0), (0, 0.12 * e, 0))
    p["neck"] = ((-0.5 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.7 * e, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up.%s" % sd] = ((-0.7 * e, 0, 0), (0, 0, 0))
    return p


T_WALK = 2.0
LEGS4 = [("f_up.L", "f_lo.L"), ("h_up.L", "h_lo.L"), ("f_up.R", "f_lo.R"), ("h_up.R", "h_lo.R")]
WALK = Walker(r, LEGS4, [0.25, 0.0, 0.75, 0.5], duty=0.75)


def walk(t):
    """A slow four-beat walk: the shell rocks over each planted foot, the neck nods."""
    ph = (t / T_WALK) % 1.0
    w = 2 * math.pi
    p = zero_pose(r)
    add(p, "shell", (0.02 * math.sin(w * ph * 2), 0.04 * math.sin(w * ph), 0.03 * math.sin(w * ph - 0.6)), (0.015 * math.sin(w * ph), 0.012 * abs(math.sin(w * ph * 2)), 0))
    add(p, "neck", (0.06 * math.sin(w * ph * 2), -0.08 * math.sin(w * ph), 0), (0, 0, 0.03 * math.sin(w * ph * 2)))
    add(p, "head", (-0.04 * math.sin(w * ph * 2), 0.05 * math.sin(w * ph), 0))
    add(p, "tail", (0, 0.2 * math.sin(w * ph), 0))
    return WALK.step(p, ph, 0.2, 0.08)


def die(t):
    """Head and legs draw into the shell; the shell drops onto its plastron and tips."""
    k = min(1.0, t / 1.2)
    w = smooth(0.0, 0.5, k)
    f = smooth(0.3, 0.8, k)
    p = zero_pose(r)
    add(p, "neck", (0.3 * w, 0, 0), (0, -0.1 * w, -0.32 * w))
    add(p, "head", (0.4 * w, 0, 0.3 * f))
    add(p, "jaw", (0.2 * f, 0, 0))
    add(p, "shell", (0.08 * f, 0, 0.12 * f), (0, -0.3 * f + 0.03 * math.sin(math.pi * smooth(0.7, 0.88, k)), 0))
    for nm, s_ in (("L", 1), ("R", -1)):
        for fr in ("f", "h"):
            add(p, "%s_up.%s" % (fr, nm), (0.0, 0.0, 0.9 * s_ * w))
            add(p, "%s_lo.%s" % (fr, nm), (0.0, 0.0, -1.3 * s_ * w))
    add(p, "tail", (0.4 * w, 0, 0))
    return p

print("[art] tortoise: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/tortoise.glb", {"idle": (T, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=14, dist=0.3, strength=0.5, floor_y=0.0)
