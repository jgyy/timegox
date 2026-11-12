"""Tome: the Jade Ledger and the Court's living record-books, after the Register of Life and Death
(shengsi bu) that the judges of the underworld keep, every soul in it with the years allotted.

Designed silhouette first: a thick ledger floating upright and open towards whoever faces it, its
two halves in a wide V like a pair of jaws (so from the front and in three-quarter view it reads
as a book, never as a flat board), a fan of loose leaves riffling up out of the middle.  It is a
Chinese ledger: covers of carved jade with a raised border and a cloud-scroll medallion, the
binding sewn with thread through four holes along the spine (xianzhuang), a paper title slip on
the cover, and the pages written in vertical columns, a few names struck through in vermilion.
One focal point: an eye that opens in the gutter, in the seam of the book itself.  The names it
holds lift off the pages as glowing characters, red silk bookmarks trail beneath it, and the
judge's vermilion brush hovers at its side.  The jade takes the enemy's colour; the paper, the
ink and the silk keep their own.
Run: blender --background --python art/monsters/tome.py  ->  assets/monsters/tome.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import add, chain_rig, smooth, wave_chain, zero_pose  # noqa: E402
from kit import CLOTH, MAT_GLOW, MAT_PLAIN, METAL, STONE, WOOD, V, Builder, Rig, env  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(19)
Y = 1.95                 # the middle of the book
HINGE = V(0.0, Y, -0.16)  # the spine, vertical
W, H = 0.68, 0.98        # a page: width (spine to fore-edge) and height
T, P = 0.055, 0.1        # a cover's thickness and a block of pages
BETA = 0.68              # each half turns this far forward of flat: the V of the open book

r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("spine", HINGE - V(0, H * 0.5, 0), HINGE + V(0, H * 0.5, 0), "root")
r.bone("head", HINGE + V(0, 0, 0.03), HINGE + V(0, 0, 0.2), "spine")
SIDES = {}
for s, sd in ((1, "L"), (-1, "R")):
    u = V(math.cos(BETA) * s, 0.0, math.sin(BETA))
    n = V(-math.sin(BETA) * s, 0.0, math.cos(BETA))
    SIDES[sd] = (s, u, n)
    r.bone("cover." + sd, HINGE, HINGE + u * W, "spine")
LEAF_A = (0.62, 0.38, -0.38, -0.62)     # the loose leaves turning, two over each half (0 is straight out at the reader)
for k in range(4):
    a = LEAF_A[k]
    d = V(math.sin(a), 0.0, math.cos(a))
    r.bone("page%d" % k, HINGE + V(0, 0.0, 0.02), HINGE + d * W * 0.9, "spine")
marks = chain_rig(r, "mark", [HINGE + V(0, -H * 0.48, 0.02), HINGE + V(0.03, -H * 0.48 - 0.3, 0.06), HINGE + V(0.0, -H * 0.48 - 0.62, 0.1)], "spine")
r.bone("brush", V(-0.78, Y + 0.05, 0.22), V(-0.66, Y + 0.6, 0.12), "root")
b = Builder("tome")


def at(sd, u_, v_, w_):
    """A point of one half of the book: u_ from the spine towards the fore-edge, v_ up, w_ out of
    the page towards the reader."""
    s, u, n = SIDES[sd]
    return HINGE + u * u_ + V(0, v_, 0) + n * w_


def turn(sd):
    """The Euler turn that lays a box along one half of the book."""
    s, u, n = SIDES[sd]
    return (0.0, -math.atan2(u.z, u.x), 0.0)


# ---------------------------------------------------------------- the two halves: jade boards and blocks of pages
for sd in ("L", "R"):
    s, u, n = SIDES[sd]
    bone = "cover." + sd
    rot = turn(sd)
    # the jade board, its edges bevelled, a raised border and a cloud-scroll medallion carved on its outer face
    b.superquad(at(sd, W * 0.5 + 0.02, 0, -T * 0.5 - 0.004), (W * 0.5 + 0.035, H * 0.5 + 0.035, T * 0.5), (0.86, 0.86, 0.86), e=0.18, cls=STONE,
                bone=bone, tint=1.0, rot=rot, seg=20, rings=10)
    border = []
    for i in range(41):
        t = i / 40 * 4
        side = int(t) % 4
        f = t - int(t)
        cs = [(0.06, -H * 0.44), (W - 0.02, -H * 0.44), (W - 0.02, H * 0.44), (0.06, H * 0.44), (0.06, -H * 0.44)]
        uu = cs[side][0] + (cs[side + 1][0] - cs[side][0]) * f
        vv = cs[side][1] + (cs[side + 1][1] - cs[side][1]) * f
        border.append(at(sd, uu, vv, -T - 0.006))
    b.tube(border, [0.014] * 41, (0.95, 0.95, 0.95), cls=STONE, bone=bone, tint=1.0, seg=6, cap0=False, cap1=False)
    scroll = []
    for i in range(34):
        a = i / 33 * 4 * math.pi
        rr = 0.025 + 0.1 * i / 33
        scroll.append(at(sd, W * 0.55 + math.cos(a) * rr, math.sin(a) * rr * 1.2, -T - 0.008))
    b.tube(scroll, [0.009] * 34, "d8b050", cls=METAL, bone=bone, seg=5)
    # gilt corner guards
    for vv in (-1, 1):
        b.superquad(at(sd, W + 0.015, vv * (H * 0.5 + 0.01), -T * 0.5), (0.05, 0.05, T * 0.62), "d8b050", e=0.3, cls=METAL, bone=bone, rot=rot, seg=10, rings=6)
    # the block of pages lying on the board, its fore-edge ruled
    b.superquad(at(sd, W * 0.5, 0, P * 0.5), (W * 0.5, H * 0.5, P * 0.5), "f4ecd8", e=0.12, cls=CLOTH, bone=bone, rot=rot, seg=16, rings=8)
    for k in range(6):
        w_ = 0.01 + k * P / 6
        b.tube([at(sd, W + 0.002, -H * 0.49, w_), at(sd, W + 0.002, H * 0.49, w_)], [0.0022, 0.0022], "c8a060" if k % 2 else "b8a888", cls=CLOTH,
               bone=bone, seg=3, mat=MAT_PLAIN)
    # the page: written in vertical columns, read right to left; a few names struck through in vermilion
    for col in range(8):
        uu = W * 0.9 - col * W * 0.105
        vv = H * 0.42
        while vv > -H * 0.42:
            h = rnd.uniform(0.018, 0.034)
            w = rnd.uniform(0.016, 0.026)
            q = [[at(sd, uu - w * 0.5, vv - h, P + 0.002), at(sd, uu + w * 0.5, vv - h, P + 0.002)],
                 [at(sd, uu - w * 0.5, vv, P + 0.002), at(sd, uu + w * 0.5, vv, P + 0.002)]]
            b.sheet(q, "4a3a30", cls=CLOTH, bone=bone, thickness=0.0015)
            vv -= h + rnd.uniform(0.012, 0.022)
        if col in (1, 4):
            y0 = rnd.uniform(-0.1, 0.25)
            b.tube([at(sd, uu - 0.045, y0 + 0.07, P + 0.006), at(sd, uu + 0.04, y0 - 0.12, P + 0.006)], [0.007, 0.004], "d8301e", cls=CLOTH, bone=bone,
                   seg=4, mat=MAT_PLAIN)

# ---------------------------------------------------------------- the spine, sewn through four holes with silk thread
b.cur_pal = 0.0
b.lathe(HINGE - V(0, 0, 0.02), [(0.055, -H * 0.5 - 0.03), (0.06, -H * 0.47), (0.06, H * 0.47), (0.055, H * 0.5 + 0.03)], (0.8, 0.8, 0.8), cls=STONE,
        bone="spine", tint=1.0, seg=14)
for k in range(4):
    yy = -H * 0.36 + k * H * 0.24
    ring = [HINGE + V(math.sin(a) * 0.066, yy, math.cos(a) * 0.066 - 0.02) for a in [i / 12 * 2 * math.pi for i in range(13)]]
    b.tube(ring, [0.009] * 13, "c8a040", cls=CLOTH, bone="spine", seg=5, cap0=False, cap1=False)
    for sd in ("L", "R"):
        b.ball(at(sd, 0.04, yy, -T - 0.004), 0.011, "c8a040", cls=CLOTH, bone="cover." + sd, seg=6, rings=4)
# the title slip on the left cover: pale paper, a single column of characters
s_, u_, n_ = SIDES["L"]
slip = [[at("L", 0.11, -0.26, -T - 0.012), at("L", 0.2, -0.26, -T - 0.012)], [at("L", 0.11, 0.38, -T - 0.012), at("L", 0.2, 0.38, -T - 0.012)]]
b.sheet(slip, "efe4c8", cls=CLOTH, bone="cover.L", thickness=0.002)
for k in range(6):
    yy = 0.32 - k * 0.1
    q = [[at("L", 0.135, yy - 0.06, -T - 0.016), at("L", 0.175, yy - 0.06, -T - 0.016)], [at("L", 0.135, yy, -T - 0.016), at("L", 0.175, yy, -T - 0.016)]]
    b.sheet(q, "1e1a1a", cls=CLOTH, bone="cover.L", thickness=0.0015)

# ---------------------------------------------------------------- loose leaves riffling up out of the middle
for k in range(4):
    a = LEAF_A[k]
    d = V(math.sin(a), 0.0, math.cos(a))
    side = V(math.cos(a), 0.0, -math.sin(a)) * (1 if a > 0 else -1)
    rows = []
    for j in range(6):
        t = j / 5
        # a leaf mid-turn: it arches away from its half and its free corner curls
        cen = HINGE + V(0, 0.0, 0.05) + d * (W * 0.9 * t) + side * (0.07 * math.sin(math.pi * t)) + V(0, 0.05 * t * t, 0)
        rows.append([cen - V(0, H * 0.45 - 0.03 * t, 0), cen + V(0, H * 0.45 + 0.04 * t * t, 0)])
    b.sheet(rows, "fbf4e2", cls=CLOTH, bone="page%d" % k, cols=["f8f0dc", "fbf4e2", "fbf4e2", "f6eed8", "f0e6cc", "e6d8b8"], thickness=0.003)
    # a few columns of script on the leaf
    for c_ in range(3):
        for j in range(5):
            t = 0.35 + 0.17 * c_
            cen = HINGE + V(0, 0.0, 0.05) + d * (W * 0.9 * t) + side * (0.07 * math.sin(math.pi * t) + 0.004)
            vv = 0.32 - j * 0.15
            q = [[cen + V(0, vv - 0.04, 0) - d * 0.012, cen + V(0, vv - 0.04, 0) + d * 0.012], [cen + V(0, vv, 0) - d * 0.012, cen + V(0, vv, 0) + d * 0.012]]
            b.sheet(q, "5a4a3c", cls=CLOTH, bone="page%d" % k, thickness=0.0012)

# ---------------------------------------------------------------- the eye that opens in the gutter
ec = HINGE + V(0, 0.04, 0.15)
for s in (1, -1):
    rows = []
    for j in range(7):
        t = j / 6
        yy = (t - 0.5) * 0.42
        bulge = 0.078 * math.sqrt(max(0.0, 1.0 - (2 * t - 1) ** 2))
        rows.append([ec + V(s * (bulge + 0.006), yy, 0.016), ec + V(s * (bulge + 0.07), yy, -0.05)])
    b.sheet(rows, "f6eedc", cls=CLOTH, bone="head", cols=["e8dcc0"] * 7, thickness=0.004)
# (the eye's frame is turned a quarter so the almond stands upright: its "bar" pupil is then a vertical slit)
A.animal_eye(b, ec, (0, 0, 1), 0.1, "40ffb0", "head", pupil="bar", up=(1, 0, 0), almond=0.6, lid="2a1e14", glow=True)

# ---------------------------------------------------------------- the names lifting off the pages as glowing characters
b.cur_pal = 1.0
for c_ in range(3):
    x0 = (c_ - 1) * 0.3
    for k in range(5):
        cen = V(x0 + 0.03 * math.sin(k * 1.7 + c_), Y + 0.56 + k * 0.16, 0.1 + 0.04 * math.cos(k + c_))
        sz = 0.085 * (1.0 - 0.08 * k)
        strokes = [((-1, 0.6), (1, 0.6)), ((0, 1), (0, -1)), ((-0.8, -0.2), (0.8, -0.4))] if (k + c_) % 2 else [((-1, 1), (-1, -1)), ((1, 1), (1, -1)), ((-1, 0), (1, 0))]
        for (a0, a1) in strokes:
            p0 = cen + V(a0[0] * sz * 0.5, a0[1] * sz * 0.5, 0)
            p1 = cen + V(a1[0] * sz * 0.5, a1[1] * sz * 0.5, 0)
            b.tube([p0, p1], [0.011, 0.011], (1.0, 1.0, 1.0), cls=CLOTH, bone="spine", seg=5, mat=MAT_GLOW, tint=1.0)
b.cur_pal = 0.0

# ---------------------------------------------------------------- red silk bookmarks trailing beneath, with tassels
pts = [r.head(nm) for nm in marks] + [r.tail(marks[-1])]
for dx in (-0.05, 0.05):
    b.ribbon([p_ + V(dx, 0, 0) for p_ in pts], [0.03, 0.03, 0.026, 0.02], (1, 0, 0), "c02a2a", bones=[marks[0], marks[0], marks[1], marks[1]], col_end="e8503a")
    end = pts[-1] + V(dx, 0, 0)
    for j in range(5):
        a = j / 5 * 2 * math.pi
        b.tube([end, end + V(math.cos(a) * 0.015, -0.1, math.sin(a) * 0.015)], [0.006, 0.003], "d83a2a", cls=CLOTH, bone=marks[-1], seg=4)
    b.ball(end, 0.018, "d8b050", cls=METAL, bone=marks[-1], seg=8, rings=5)

# ---------------------------------------------------------------- the judge's vermilion brush, hovering at its side
bb0, bb1 = r.bones["brush"][0], r.bones["brush"][1]
d = (bb1 - bb0).normalized()
b.tube([bb0 + d * 0.06, bb1 + d * 0.12], [0.017, 0.017], "7a5a30", cls=WOOD, bone="brush", seg=8)
for k in range(5):
    b.tube([bb0 + d * (0.1 + k * 0.12), bb0 + d * (0.11 + k * 0.12)], [0.019, 0.019], "4a3418", cls=WOOD, bone="brush", seg=8, cap0=False, cap1=False)
b.tube([bb0 + d * 0.07, bb0 - d * 0.05, bb0 - d * 0.16], [0.03, 0.026, 0.002], "f0e8d8", cls=CLOTH, bone="brush", seg=10)
b.tube([bb0 - d * 0.02, bb0 - d * 0.1, bb0 - d * 0.165], [0.027, 0.02, 0.002], "d02a1a", cls=CLOTH, bone="brush", seg=10)
b.ball(bb1 + d * 0.14, 0.02, "d8b050", cls=METAL, bone="brush", seg=8, rings=5)

T_IDLE = 2.8


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    p["spine"] = ((math.sin(t * w) * 0.06, math.sin(t * w + 0.8) * 0.18, 0), (0, math.sin(t * w) * 0.08, 0))
    for sd, s in (("L", 1), ("R", -1)):
        # the halves breathe open and shut a little
        p["cover." + sd] = ((0, s * (0.06 + 0.05 * math.sin(t * w * 2)), 0), (0, 0, 0))
    for k in range(4):
        p["page%d" % k] = ((0, 0.28 * math.sin(t * w * 2 + k * 0.9), 0), (0, 0, 0))
    wave_chain(p, marks, t, w * 2, 0.15, axis=0)
    p["brush"] = ((0.1 * math.sin(t * w), 0, 0.12 * math.sin(t * w + 0.6)), (0, 0.06 * math.sin(t * w + 1.2), 0))
    return p


def attack(t):
    """The halves snap shut on the victim like jaws as the book lunges, then spring open."""
    k = t / 0.55
    e = env(k)
    bite = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.1 * bite, 0.5 * bite))
    for sd, s in (("L", 1), ("R", -1)):
        p["cover." + sd] = ((0, s * (0.25 * e - 0.95 * bite), 0), (0, 0, 0))
    for kk in range(4):
        p["page%d" % kk] = ((0, math.sin(t * 30 + kk) * 0.5 * e, 0), (0, 0, 0))
    p["brush"] = ((-1.0 * bite, 0, 0.3 * bite), (0, 0, 0.3 * bite))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["spine"] = ((-0.35 * e, 0, 0.25 * e), (0, 0, -0.15 * e))
    for kk in range(4):
        p["page%d" % kk] = ((0, math.sin(t * 26 + kk) * 0.7 * e, 0), (0, 0, 0))
    return p


def cast(t):
    """The book flies wide open, the leaves fan out and the names stream up."""
    e = env(t / 0.6)
    p = idle(0.0)
    p["spine"] = ((-0.25 * e, 0, 0), (0, 0.25 * e, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["cover." + sd] = ((0, s * 0.45 * e, 0), (0, 0, 0))
    for kk in range(4):
        p["page%d" % kk] = ((0, (kk - 1.5) * 0.45 * e, 0), (0, 0, 0))
    p["brush"] = ((-0.6 * e, 0, 0), (0.1 * e, 0.2 * e, 0))
    return p


T_WALK = 1.0


def walk(t):
    """Flies on its two halves like wings, leaves riffling, leaning into the flight."""
    w = 2 * math.pi / T_WALK
    p = idle(t * T_IDLE / T_WALK)
    add(p, "spine", (0.2, 0, 0), (0, 0.06 * math.sin(t * w * 2), 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "cover." + sd, (0, s_ * (0.1 + 0.3 * math.sin(t * w * 2)), 0))
    return p


def die(t):
    """Snaps shut and drops to the ground, landing flat on its cover."""
    k = min(1.0, t / 1.2)
    shut = smooth(0.0, 0.25, k)
    f = smooth(0.2, 0.75, k) ** 1.5
    p = idle(0.0)
    for sd, s_ in (("L", 1), ("R", -1)):
        p["cover." + sd] = ((0, s_ * (-1.05 * shut), 0), (0, 0, 0))
    for kk in range(4):
        p["page%d" % kk] = ((0, 0, 0), (0, 0, 0))
    add(p, "spine", (-1.45 * f, 0.3 * f, 0.0), (0, -1.36 * f + 0.05 * math.sin(math.pi * smooth(0.72, 0.9, k)), 0.2 * f))
    p["brush"] = ((1.2 * f, 0, 0.6 * f), (0.1 * f, -1.7 * f, 0.05 * f))
    return p


print("[art] tome: %d triangles" % b.tri_count())
# a book has a binding, not a coat: its jade keeps its own carving (no coat split)
kit.finish_rigged(b, r, "monsters/tome.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  coat=False, samples=12, dist=0.25, strength=0.4)
