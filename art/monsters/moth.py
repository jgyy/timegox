"""Moth (new in Part V): a great lantern moth with four patterned wings bearing glowing eye
spots, a fuzzy body, feathered antennae and dangling legs (Glow Moth, Lantern Moth Queen).
Run: blender --background --python art/monsters/moth.py  ->  assets/monsters/moth.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, V, Builder, Rig, env  # noqa: E402

kit.reset()
C = V(0, 1.5, 0)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", C + V(0, 0, -0.1), C + V(0, 0.02, 0.2), "root")
r.bone("abdomen", C + V(0, 0, -0.1), C + V(0, -0.15, -0.55), "body")
r.bone("head", C + V(0, 0.02, 0.2), C + V(0, 0.05, 0.36), "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("fw.%s" % sd, C + V(0.08 * s, 0.06, 0.08), C + V(0.9 * s, 0.25, 0.25), "body")
    r.bone("hw.%s" % sd, C + V(0.08 * s, 0.02, -0.05), C + V(0.7 * s, -0.1, -0.35), "body")
    r.bone("ant.%s" % sd, C + V(0.04 * s, 0.1, 0.33), C + V(0.22 * s, 0.4, 0.6), "head")

b = Builder("moth")
# fuzzy thorax, segmented abdomen, head
b.ellipsoid(C + V(0, 0.02, 0.05), (0.13, 0.13, 0.18), (0.9, 0.9, 0.9), cls=HAIR, bone="body", tint=0.6, seg=16, rings=10)
for k in range(5):
    t = k / 4
    b.ellipsoid(C + V(0, -0.03 - t * 0.12, -0.15 - t * 0.38), (0.12 - t * 0.05, 0.11 - t * 0.04, 0.08), (0.75 + 0.1 * (k % 2), 0.75 + 0.1 * (k % 2), 0.75 + 0.1 * (k % 2)), cls=HAIR, bone="abdomen", tint=0.6, seg=14, rings=8)
b.ellipsoid(C + V(0, 0.04, 0.27), (0.09, 0.085, 0.08), (0.85, 0.85, 0.85), cls=HAIR, bone="head", tint=0.6, seg=14, rings=8)
# fluffy ruff around the neck
for k in range(14):
    a = k / 14 * 2 * math.pi
    root = C + V(math.cos(a) * 0.1, 0.03 + math.sin(a) * 0.1, 0.17)
    b.leaf(root, root + V(math.cos(a) * 0.1, math.sin(a) * 0.1, 0.05), 0.04, (1.0, 1.0, 1.0), cls=HAIR, bone="body", tint=0.4)
# big compound eyes
for s in (1, -1):
    b.ellipsoid(C + V(0.07 * s, 0.06, 0.31), (0.05, 0.055, 0.05), "201830", cls=CRYSTAL, bone="head", seg=12, rings=8)
    b.ellipsoid(C + V(0.08 * s, 0.08, 0.34), (0.015, 0.015, 0.01), "ffffff", cls=CRYSTAL, bone="head", seg=6, rings=4, mat=MAT_GLOW)
# feathered antennae
for s, sd in ((1, "L"), (-1, "R")):
    a = "ant.%s" % sd
    h, tl = r.head(a), r.tail(a)
    b.tube([h, h.lerp(tl, 0.5) + V(0, 0.04, 0), tl], [0.008, 0.007, 0.004], (0.6, 0.6, 0.6), bone=a, tint=0.6, seg=5)
    for k in range(8):
        t = 0.2 + k / 10
        p = h.lerp(tl, t)
        b.leaf(p, p + V(0.06 * s, 0.02, -0.05), 0.012, (0.8, 0.8, 0.8), cls=HAIR, bone=a, tint=0.6, n=3)
        b.leaf(p, p + V(-0.02 * s, 0.07, 0.0), 0.012, (0.8, 0.8, 0.8), cls=HAIR, bone=a, tint=0.6, n=3)


def wing(bone, root, span, chord, sweep, s, shade_in, shade_out, spot):
    rows = []
    cols = []
    n = 7
    for j in range(n):
        u = j / (n - 1)
        row = []
        for i in range(6):
            v = i / 5
            x = s * span * u
            w = chord * math.sin(math.pi * (0.15 + 0.85 * v)) * (1.0 - 0.35 * u) + 0.02
            z = sweep * u - w * (v - 0.4) * 1.6
            row.append(root + V(x, 0.05 * u * u, z))
        rows.append(row)
        sh = shade_in + (shade_out - shade_in) * u
        cols.append((sh, sh, sh))
    b.sheet(rows, cols[0], cls=CLOTH, bone=bone, tint=1.0, cols=cols, thickness=0.008)
    # vein lines and glowing eye spot
    for k in range(3):
        b.ribbon([root, root + V(s * span * 0.9, 0.04, sweep * 0.9 - (k - 1) * chord * 0.5)], [0.006, 0.003], (0, 1, 0), (0.35, 0.35, 0.35), cls=CLOTH, bone=bone, tint=1.0)
    sp = root + V(s * span * spot[0], 0.03 * spot[0] + 0.012, sweep * spot[0] + spot[1])
    b.disc(sp, chord * 0.22, (1.0, 0.9, 0.5), cls=CRYSTAL, bone=bone, seg=16, mat=MAT_GLOW, col_rim=(0.6, 0.3, 0.1), thick=0.02)
    b.disc(sp + V(0, 0.006, 0), chord * 0.09, "201020", cls=CRYSTAL, bone=bone, seg=12, thick=0.024)


for s, sd in ((1, "L"), (-1, "R")):
    wing("fw.%s" % sd, C + V(0.06 * s, 0.07, 0.08), 0.95, 0.5, 0.2, s, 0.55, 0.95, (0.6, -0.05))
    wing("hw.%s" % sd, C + V(0.06 * s, 0.03, -0.06), 0.72, 0.42, -0.35, s, 0.5, 0.85, (0.55, 0.0))
    for k in range(3):
        root = C + V(0.07 * s, -0.08, 0.1 - k * 0.1)
        b.tube([root, root + V(0.12 * s, -0.15, 0.04), root + V(0.15 * s, -0.32, 0.0)], [0.012, 0.01, 0.005], (0.5, 0.5, 0.5), bone="body", tint=0.6, seg=5)

FLAP = 0.8


def idle(t, amp=1.0):
    w = 2 * math.pi / FLAP
    f = math.sin(t * w)
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, -f * 0.07 + math.sin(t * w / 4) * 0.1, 0))
    p["body"] = ((0.05 * f, math.sin(t * w / 4) * 0.1, 0), (0, 0, 0))
    p["abdomen"] = ((-0.06 * f, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["fw.%s" % sd] = ((0, 0, -s * (0.25 + f * 0.75) * amp), (0, 0, 0))
        p["hw.%s" % sd] = ((0, 0, -s * (0.2 + math.sin(t * w - 0.5) * 0.6) * amp), (0, 0, 0))
        p["ant.%s" % sd] = ((math.sin(t * w / 2) * 0.1, 0, 0), (0, 0, 0))
    return p


def attack(t):
    e = env(t / 0.6)
    p = idle(t * 1.5, 1.2)
    p["root"] = ((0, 0, 0), (0, -0.2 * e, 0.45 * e))
    p["body"] = ((0.35 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(t, 0.5)
    p["root"] = ((0, 0, 0), (0, 0.15 * e, -0.25 * e))
    p["body"] = ((-0.4 * e, 0, 0.3 * e), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(t, 0.4)
    p["body"] = ((-0.35 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["fw.%s" % sd] = ((0, 0, s * 0.6 * e), (0, 0, 0))
        p["hw.%s" % sd] = ((0, 0, s * 0.4 * e), (0, 0, 0))
    return p


# the moth reads small next to the other foes: scale it up (clips are rotations, so they still fit)
kit.scale_asset(b, r, 1.45)
print("[art] moth: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/moth.glb", {"idle": (FLAP * 4, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=10, dist=0.2, strength=0.4)
