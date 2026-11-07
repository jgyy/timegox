"""Wraith: hooded ghosts of the graveyards, the Willow Widow, the Hungry Ghosts and the Thousand
Unforgotten.  A deep cowl over a yellowed skull with burning sockets, a two-layered robe whose hem is torn
into ragged points by noise and whose strips stream behind it on bone chains, ribs glimpsed
through a tear, jointed skeletal hands and forearm bones reaching out of shredded sleeves, a rope
belt with a talisman, a shackle and a broken chain of interlocking links, and ghost-fire wisps.  Tinted by the game per enemy; eyes, bone and iron keep
their own colours.
Run: blender --background --python art/monsters/wraith.py  ->  assets/monsters/wraith.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import chain_rig, glow_ball, wave_chain, zero_pose  # noqa: E402
from kit import CLOTH, MAT_GLOW, METAL, SKIN, STONE, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, smooth  # noqa: E402

kit.reset()
Y = 1.2
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, Y - 0.3, 0), (0, Y + 0.4, 0), "root")
r.bone("head", (0, Y + 0.45, 0.02), (0, Y + 0.75, 0.08), "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm." + sd, (0.22 * s, Y + 0.35, 0.02), (0.45 * s, Y + 0.05, 0.25), "body")
    r.bone("fore." + sd, (0.45 * s, Y + 0.05, 0.25), (0.55 * s, Y + 0.05, 0.62), "arm." + sd)
strips = []
for k in range(9):
    a = math.pi * 0.15 + (k / 8) * math.pi * 1.7
    top = V(math.sin(a) * 0.3, Y - 0.25, math.cos(a) * 0.25)
    pts = [top + V(math.sin(a) * 0.05 * j, -0.22 * j, math.cos(a) * 0.05 * j - 0.1 * j * j * 0.3) for j in range(5)]
    strips.append((chain_rig(r, "s%d_" % k, pts, "body"), pts, a))
b = Builder("wraith")


def body_w(p):
    return {"body": 1.0} if p.y < Y + 0.42 else {"body": 0.5, "head": 0.5}


# robe: two layers of torn cloth.  The outer shell falls from the shoulders and flares, its hem
# cut into ragged points by noise; the inner layer shows darker through the gaps.
n = 40
for layer, (rk, col, top, low) in enumerate(((1.0, 0.7, Y + 0.46, Y - 0.62), (0.9, 0.42, Y + 0.3, Y - 0.5))):
    rows = []
    cols = []
    ys = [top - (top - low) * (j / 9) for j in range(10)]
    for j, y in enumerate(ys):
        t = j / 9
        row = []
        for i in range(n + 1):
            a = 2 * math.pi * i / n
            rr = (0.17 + 0.18 * t ** 0.8 + 0.03 * math.sin(a * 9 + t * 4) * t) * rk
            yy = y
            if j == 9:
                # ragged hem: long torn points and short tears
                rag = fbm3((math.cos(a) * 3, math.sin(a) * 3, layer * 5.0), 3, 4)
                yy = y - 0.28 * smooth(0.45, 0.8, rag) + 0.08 * math.sin(a * 13)
            row.append(V(math.sin(a) * rr, yy, math.cos(a) * rr * 0.92))
        rows.append(row)
        cols.append((col * (1.0 - 0.25 * t),) * 3)
    b.sheet(rows, (col,) * 3, bones=[body_w(V(0, y, 0)) for y in ys], cols=cols, tint=1.0, thickness=0.02)
# a rope belt with a hanging talisman knot
belt = [V(math.sin(2 * math.pi * i / 24) * 0.24, Y + 0.05 + 0.02 * math.sin(i), math.cos(2 * math.pi * i / 24) * 0.23) for i in range(25)]
b.tube(belt, [0.014] * 25, "4a3a2a", cls=CLOTH, bone="body", seg=6, cap0=False, cap1=False)
kc = V(0.1, Y + 0.03, 0.21)
b.ellipsoid(kc, (0.025, 0.02, 0.015), "4a3a2a", cls=CLOTH, bone="body", seg=8, rings=5)
b.ribbon([kc, kc + V(0.01, -0.12, 0.02), kc + V(0.02, -0.26, 0.02)], [0.025, 0.026, 0.024], (1, 0, 0), "d8c060", bone="body", col_end="c8a850")
# ribs glimpsed through a tear in the chest
for k in range(4):
    y = Y + 0.28 - k * 0.055
    rib = [V(math.sin(a) * 0.13, y - 0.03 * abs(math.sin(a)), math.cos(a) * 0.1 + 0.08) for a in [(-0.9 + 1.8 * i / 6) for i in range(7)]]
    b.tube(rib, [0.008] * 7, "d8d0bc", cls=STONE, bone="body", seg=5)
b.tube([V(0, Y + 0.34, 0.16), V(0, Y + 0.1, 0.17)], [0.012, 0.01], "d8d0bc", cls=STONE, bone="body", seg=6)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# cowl: a deep hood of heavy cloth with a peak, the shadowed opening, a skull inside
hood_rows = []
for j in range(10):
    t = j / 9
    y = Y + 0.86 - t * 0.48
    rr = 0.13 + 0.12 * math.sin(math.pi * min(1.0, t * 1.2)) + 0.04 * t
    row = []
    for i in range(19):
        a = math.pi * 0.38 + (i / 18) * math.pi * 1.24
        fold = 0.012 * math.sin(i * 1.7 + j * 0.8) * t
        row.append(V(math.sin(a) * (rr + fold), y, math.cos(a) * (rr + fold) - 0.02 - 0.03 * t))
    hood_rows.append(row)
b.sheet(hood_rows, (0.6, 0.6, 0.6), bones=["head"] * 7 + [{"head": 0.5, "body": 0.5}] * 3, cols=[(0.62 - 0.2 * j / 9,) * 3 for j in range(10)], tint=1.0, thickness=0.022)
b.tube([V(0, Y + 0.86, -0.08), V(0, Y + 0.95, -0.2), V(0, Y + 0.86, -0.36), V(0, Y + 0.7, -0.42)], [0.06, 0.05, 0.025, 0.005], (0.55, 0.55, 0.55), cls=CLOTH, bone="head", tint=1.0, seg=10)
b.ellipsoid(V(0, Y + 0.6, 0.06), (0.16, 0.2, 0.1), "050308", cls=SKIN, bone="head", seg=14, rings=8)
A.skull(b, V(0, Y + 0.6, 0.06), 1.15, "head", col="b8b4a8", eye_glow="a0f0ff")
for s in (1, -1):
    b.ellipsoid(V(0.035 * s, Y + 0.6, 0.15), (0.05, 0.035, 0.015), "306080", cls=SKIN, bone="head", seg=10, rings=5, mat=MAT_GLOW)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# sleeves hanging in tatters from the reaching arms, bony hands and forearm bones
for s, sd in ((1, "L"), (-1, "R")):
    ar = r.bones["arm." + sd]
    fo = r.bones["fore." + sd]
    a0, a1, a2 = V(ar[0]), V(ar[1]), V(fo[1])
    b.tube([a0, a1, a1.lerp(a2, 0.6)], [(0.08, 0.08), (0.1, 0.12), (0.15, 0.2)], (0.65, 0.65, 0.65), cls=CLOTH, bones=["arm." + sd, {"arm." + sd: 0.5, "fore." + sd: 0.5}, "fore." + sd], tint=1.0, seg=14, cap1=False)
    d = (a2 - a1).normalized()
    for k in range(5):
        u = (k / 4 - 0.5) * 2
        root = a1.lerp(a2, 0.6) + V(u * 0.12, -0.12 - 0.05 * abs(u), 0)
        b.ribbon([root, root + V(0, -0.12, -0.04), root + V(0.01 * u, -0.22 - 0.05 * (k % 2), -0.08)], [0.04, 0.03, 0.004], (1, 0, 0), (0.55, 0.55, 0.55), bone="fore." + sd, tint=1.0, col_end=(0.85, 0.85, 0.85))
    for off in (-0.012, 0.012):
        b.tube([a1.lerp(a2, 0.5) + V(off, 0, 0), a2 + V(off, 0, 0)], [0.012, 0.01], "d8d0bc", cls=STONE, bone="fore." + sd, seg=6)
    A.bony_hand(b, a2 + d * 0.01, d + V(0, -0.2, 0), 1.25, "fore." + sd, col="e0d8c4", spread=1.2, curl=0.6, side=s)
# the broken chain on the left wrist and a shackle
cw = V(r.bones["fore.L"][1])
b.lathe(cw + V(0, 0, -0.04), [(0.05, -0.025), (0.055, 0.0), (0.05, 0.025)], "4a4a58", cls=METAL, bone="fore.L", seg=12, rot=(math.pi / 2, 0, 0), cap_bottom=False, cap_top=False)
A.chain(b, cw + V(0.02, -0.07, -0.04), V(0.0, -0.075, -0.015), 6, "fore.L", col="5a5a68", r=0.028)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# tattered strips streaming from the hem, each torn into two tongues at the end
for names, pts, a in strips:
    side = V(math.cos(a), 0, -math.sin(a))
    bones = [names[0]] + [names[min(j, len(names) - 1)] for j in range(len(pts) - 1)]
    b.ribbon(pts, [0.09, 0.08, 0.06, 0.04, 0.005], side, (0.65, 0.65, 0.65), cls=CLOTH, bones=bones, tint=1.0, col_end=(0.9, 0.9, 0.9))
    end = pts[-2]
    for k in (-1, 1):
        b.ribbon([end, end + side * 0.03 * k + V(0, -0.12, -0.04), end + side * 0.05 * k + V(0, -0.22, -0.06)], [0.02, 0.015, 0.002], side, (0.8, 0.8, 0.8), cls=CLOTH, bone=names[-1], tint=1.0)
# ghost-fire wisps drifting round the hem
for k in range(5):
    a = k / 5 * 2 * math.pi
    glow_ball(b, V(math.sin(a) * 0.36, Y - 0.45 + 0.08 * math.sin(k * 2.0), math.cos(a) * 0.33), 0.028, "80d8ff", "body")

T_IDLE = 3.0


def drift(p, t, speed, amp):
    for k, (names, _, _) in enumerate(strips):
        wave_chain(p, names, t + k * 0.3, speed, amp, axis=0, lag=0.8, grow=0.35)


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    drift(p, t, w * 2, 0.15)
    p["body"] = ((math.sin(t * w) * 0.05, math.sin(t * w * 0.5) * 0.1, 0), (0, 0.1 * math.sin(t * w), 0))
    p["head"] = ((math.sin(t * w * 2) * 0.06, math.sin(t * w) * 0.2, math.sin(t * w * 0.5) * 0.1), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((math.sin(t * w + s) * 0.15, 0, 0), (0, 0, 0))
        p["fore." + sd] = ((math.sin(t * w * 1.3 + s) * 0.15, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    drift(p, t, 14.0, 0.3)
    p["root"] = ((0, 0, 0), (0, 0.1 * lunge, 0.6 * lunge))
    p["body"] = ((0.3 * lunge, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["arm." + sd] = ((-0.9 * e, 0, 0), (0, 0, 0))
        p["fore." + sd] = ((-0.4 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    drift(p, t, 22.0, 0.25 * e)
    p["body"] = ((-0.35 * e, 0, 0.15 * e), (0, 0, -0.2 * e))
    p["head"] = ((-0.4 * e, 0.3 * e, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    drift(p, t, 10.0, 0.35)
    p["body"] = ((-0.2 * e, 0, 0), (0, 0.25 * e, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((-1.4 * e, 0, -0.5 * e * s), (0, 0, 0))
    return p


print("[art] wraith: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/wraith.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.45)
