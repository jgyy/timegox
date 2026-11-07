"""Tortoise: a great domed shell of hexagonal scutes over a scaly body (Eon Tortoise, Moss-Backed
Tortoise, Xuan Wu).  Head and neck on a two-bone chain, stubby legs and a short tail; moss and
crystals grow on the shell.
Run: blender --background --python art/monsters/tortoise.py  ->  assets/monsters/tortoise.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import claws, eyes, zero_pose  # noqa: E402
from sculpt import morph_sphere, smooth, strand  # noqa: E402
from kit import CRYSTAL, FOLIAGE, SCALE, STONE, V, Builder, Rig, env  # noqa: E402

kit.reset()
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

b = Builder("tortoise")
# carapace: one dome whose scutes are a Voronoi pattern over its surface - five vertebral scutes
# down the spine, four costals either side and a ring of marginals - each slightly domed, with
# grooved seams between them and concentric growth rings
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
    p = V(d.x * 0.84, d.y * 0.7, d.z * 0.96)
    best, gap = scute(d)
    seam = smooth(0.07, 0.0, gap)
    p = p * (1.0 + 0.07 * (1.0 - best * 1.6) - 0.045 * seam)
    # the rim flares out and is serrated at the back
    if d.y < 0.18:
        flare = smooth(0.18, 0.02, d.y)
        teeth = 0.03 * max(0.0, -d.z) * abs(math.sin(math.atan2(d.x, d.z) * 11.0))
        p = p + V(d.x, 0, d.z) * (0.06 * flare + teeth * flare)
    return p


def shell_col(p, d):
    if d.y < 0.0:
        grid = smooth(0.02, 0.0, abs(math.sin(p.z * 9.0))) + smooth(0.015, 0.0, abs(p.x))
        return ((0.95 - 0.35 * min(1.0, grid)),) * 3
    best, gap = scute(d)
    seam = smooth(0.06, 0.0, gap)
    rings = 0.5 + 0.5 * math.sin(best * 70.0)
    v = 0.78 + 0.16 * (1.0 - best * 2.0) - 0.08 * rings * smooth(0.05, 0.2, best)
    v *= 1.0 - 0.55 * seam
    return (v, v, v)


morph_sphere(b, SC, shell_shape, shell_col, cls=SCALE, bone="shell", seg=48, rings=28, tint_fn=lambda p, d: 1.0)
# moss in the seams and on the crown, crystals pushing up through it
for k in range(22):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.05, 0.62)
    d = V(math.sin(a) * rr, 1.0, math.cos(a) * rr).normalized()
    root = SC + shell_shape(d) - d * 0.01
    b.leaf(root, root + d * 0.15 + V(rnd.uniform(-0.06, 0.06), 0.03, rnd.uniform(-0.06, 0.06)), 0.05, "5a8a3a", cls=FOLIAGE, bone="shell", col_tip="9ac860")
for k in range(5):
    a = k * 1.7
    d = V(math.sin(a) * 0.35, 1.0, math.cos(a) * 0.35 - 0.1).normalized()
    b.crystal(SC + shell_shape(d) - d * 0.03, 0.05 + 0.01 * (k % 2), 0.26 + 0.06 * (k % 3), "a0f0ff", cls=CRYSTAL, bone="shell", rot=(0.4 * d.z, 0, -0.4 * d.x))
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# neck: soft skin in folds pulled out from under the shell; the head with a horny hooked beak,
# plated crown, heavy-lidded eyes
neck = [V(0, 0.52, 0.5), V(0, 0.6, 0.66), V(0, 0.7, 0.84)]
b.tube(neck, [0.17, 0.135, 0.12], (0.8, 0.8, 0.8), cls=SCALE, bones=["shell", {"shell": 0.3, "neck": 0.7}, {"neck": 0.5, "head": 0.5}], tint=0.8, seg=14)
for k in range(5):
    q = neck[0].lerp(neck[2], 0.1 + k * 0.18)
    rr = 0.17 - 0.05 * (k / 4)
    ring = [q + V(math.sin(a) * rr * 1.04, math.cos(a) * rr * 0.98, 0.0) for a in [i / 12 * 2 * math.pi for i in range(13)]]
    b.tube(ring, [0.012] * 13, (0.68, 0.68, 0.68), cls=SCALE, bone="neck" if k > 1 else "shell", tint=0.8, seg=5, cap0=False, cap1=False)
HC = V(0, 0.75, 0.98)
morph_sphere(b, HC, lambda d: V(d.x * 0.15, d.y * 0.12, d.z * 0.19) * (1.0 + 0.06 * smooth(0.2, 1.0, d.z) * smooth(-0.6, 0.2, d.y)),
             lambda p, d: (0.82 + 0.1 * d.y - 0.15 * smooth(0.97, 1.0, abs(math.sin(p.x * 30) * math.sin(p.z * 30))),) * 3,
             cls=SCALE, bone="head", seg=20, rings=14, tint_fn=lambda p, d: 0.8)
b.ellipsoid(V(0, 0.68, 0.98), (0.13, 0.05, 0.16), (0.9, 0.9, 0.9), cls=SCALE, bone="jaw", tint=0.8, seg=12, rings=6)
beak = [HC + V(0, 0.02, 0.15), HC + V(0, -0.0, 0.2), HC + V(0, -0.04, 0.22), HC + V(0, -0.07, 0.205)]
strand(b, beak, 0.05, 0.006, "c8b080", col_tip="8a7050", cls=STONE, bone="head", flat=0.7, seg=10, per=3, up=(1, 0, 0))
b.tube([V(0, 0.665, 1.06), V(0, 0.67, 1.13)], [(0.06, 0.02), (0.035, 0.012)], "b8a070", cls=STONE, bone="jaw", seg=8, up=(0, 1, 0))
eyes(b, V(0, 0.8, 1.06), 0.1, 0.03, iris="e0a020", bone="head", slit=False, glow=False, rot_y=0.9, h=0.8)
for s in (1, -1):
    b.tube([V(0.07 * s, 0.835, 1.06), V(0.11 * s, 0.84, 1.03), V(0.135 * s, 0.825, 0.98)], [0.012, 0.016, 0.01], (0.6, 0.6, 0.6), bone="head", tint=0.8, seg=6)
    for k in range(3):
        b.superquad(HC + V(0.04 * s + 0.0, 0.11 - k * 0.02, 0.05 - k * 0.06), (0.04, 0.012, 0.035), (0.7, 0.7, 0.7), e=0.5, cls=SCALE, bone="head", tint=0.8, seg=8, rings=5)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# legs: elephantine columns armoured with big scales, blunt claws
for nm in ("f", "h"):
    for sd in ("L", "R"):
        up = "%s_up.%s" % (nm, sd)
        lo = "%s_lo.%s" % (nm, sd)
        s2 = 1 if sd == "L" else -1
        col_pts = [r.head(up), r.tail(up), r.tail(lo) + V(0, 0.03, 0)]
        b.tube(col_pts, [0.15, 0.13, 0.14], (0.75, 0.75, 0.75), cls=SCALE, bones=[up, {up: 0.5, lo: 0.5}, lo], tint=0.8, seg=14)
        for k in range(7):
            t = 0.15 + k * 0.11
            q = col_pts[1].lerp(col_pts[2], t) if t > 0.0 else col_pts[1]
            a = (k % 3 - 1) * 0.7 + (0.0 if nm == "f" else math.pi)
            out = V(math.sin(a) * s2 * 0.4 + 0.6 * s2, 0, math.cos(a)).normalized()
            b.superquad(q + out * 0.13, (0.05, 0.04, 0.012), (0.62, 0.62, 0.62), e=0.5, cls=SCALE, bone=lo, tint=0.8, rot=(0, math.atan2(out.x, out.z), 0), seg=8, rings=5)
        b.ellipsoid(r.tail(lo) + V(0, 0.0, 0.0), (0.16, 0.06, 0.17), (0.6, 0.6, 0.6), cls=SCALE, bone=lo, tint=0.8, seg=14, rings=6)
        claws(b, r.tail(lo) + V(0, 0.02, 0.12), True, lo, n=4, spread=0.05, length=0.06)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# tail: a short cone ringed with scales
tb = [V(0, 0.48, -0.78), V(0, 0.44, -0.86), V(0, 0.38, -0.96)]
b.tube(tb, [0.07, 0.05, 0.01], (0.7, 0.7, 0.7), cls=SCALE, bone="tail", tint=0.8, seg=8)
for k in range(3):
    q = tb[0].lerp(tb[2], 0.15 + k * 0.3)
    b.tube([q + V(0, 0, 0.008), q - V(0, 0, 0.008)], [0.065 - k * 0.018] * 2, (0.55, 0.55, 0.55), cls=SCALE, bone="tail", tint=0.8, seg=8, cap0=False, cap1=False)

T = 4.0


def idle(t):
    w = 2 * math.pi / T
    p = zero_pose(r)
    p["shell"] = ((math.sin(t * w) * 0.015, 0, math.sin(t * w * 0.5) * 0.01), (0, math.sin(t * w * 2) * 0.008, 0))
    p["neck"] = ((math.sin(t * w) * 0.08, math.sin(t * w * 0.5) * 0.25, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w + 1) * 0.06, math.sin(t * w * 0.5 + 0.4) * 0.15, 0), (0, 0, 0))
    p["jaw"] = ((0.05 + 0.05 * abs(math.sin(t * w)), 0, 0), (0, 0, 0))
    p["tail"] = ((0, math.sin(t * w * 2) * 0.2, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
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


print("[art] tortoise: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/tortoise.glb", {"idle": (T, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=14, dist=0.3, strength=0.5, floor_y=0.0)
