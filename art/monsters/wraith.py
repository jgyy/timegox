"""Wraith: hooded ghosts of the graveyards, the Willow Widow, the Hungry Ghosts and the Thousand
Unforgotten.  A floating cowl with nothing inside but two burning eyes, a long tattered robe whose
torn strips stream behind it on bone chains, skeletal hands reaching out of wide sleeves, and a
broken chain hanging from one wrist.  Tinted by the game per enemy; eyes, bone and iron keep
their own colours.
Run: blender --background --python art/monsters/wraith.py  ->  assets/monsters/wraith.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import chain_rig, wave_chain, zero_pose  # noqa: E402
from kit import CLOTH, MAT_GLOW, METAL, SKIN, STONE, V, Builder, Rig, env  # noqa: E402

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

# robe: a long cowled shell, darker inside, tinted
b.lathe(V(0, 0, 0), [(0.3, Y - 0.3), (0.32, Y - 0.05), (0.3, Y + 0.2), (0.26, Y + 0.38), (0.18, Y + 0.48)], (0.7, 0.7, 0.7), cls=CLOTH, bone="body", seg=24, tint=1.0, folds=(12, 0.08, 0.0))
# hood with a shadowed opening and burning eyes
b.ellipsoid(V(0, Y + 0.62, -0.02), (0.22, 0.25, 0.24), (0.6, 0.6, 0.6), cls=CLOTH, bone="head", tint=1.0, seg=18, rings=12, squash_top=1.15)
b.tube([V(0, Y + 0.86, -0.06), V(0, Y + 0.95, -0.22), V(0, Y + 0.85, -0.38)], [0.08, 0.05, 0.01], (0.55, 0.55, 0.55), cls=CLOTH, bone="head", tint=1.0, seg=10)
b.ellipsoid(V(0, Y + 0.58, 0.14), (0.15, 0.17, 0.08), "050308", cls=SKIN, bone="head", seg=14, rings=8)
for s in (1, -1):
    b.ellipsoid(V(0.055 * s, Y + 0.62, 0.2), (0.03, 0.018, 0.01), "a0f0ff", cls=SKIN, bone="head", seg=10, rings=5, mat=MAT_GLOW)
    b.ellipsoid(V(0.055 * s, Y + 0.62, 0.19), (0.07, 0.05, 0.02), "306080", cls=SKIN, bone="head", seg=10, rings=5, mat=MAT_GLOW)
# sleeves and skeletal hands
for s, sd in ((1, "L"), (-1, "R")):
    ar = r.bones["arm." + sd]
    fo = r.bones["fore." + sd]
    b.tube([ar[0], ar[1], fo[1]], [(0.08, 0.08), (0.1, 0.12), (0.15, 0.18)], (0.65, 0.65, 0.65), cls=CLOTH, bones=["arm." + sd, {"arm." + sd: 0.5, "fore." + sd: 0.5}, "fore." + sd], tint=1.0, seg=12, cap1=False)
    hc = V(fo[1]) + V(0.02 * s, -0.04, 0.06)
    b.ellipsoid(hc, (0.035, 0.025, 0.045), "e8e0d0", cls=STONE, bone="fore." + sd, seg=8, rings=5)
    for f in range(4):
        x = (f - 1.5) * 0.018
        b.tube([hc + V(x, 0, 0.03), hc + V(x * 1.4, -0.04, 0.1), hc + V(x * 1.6, -0.1, 0.12)], [0.008, 0.006, 0.003], "e8e0d0", cls=STONE, bone="fore." + sd, seg=4)
# the broken chain on the left wrist
cw = V(r.bones["fore.L"][1])
for k in range(5):
    c = cw + V(0.02, -0.06 - k * 0.07, -0.02 * k)
    b.lathe(c, [(0.025, -0.02), (0.035, 0.0), (0.025, 0.02)], "5a5a68", cls=METAL, bone="fore.L", seg=8, rot=(0, 0, (k % 2) * 1.57 + 0.3), cap_bottom=False, cap_top=False)
# tattered strips streaming from the hem
for names, pts, a in strips:
    side = V(math.cos(a), 0, -math.sin(a))
    bones = [names[0]] + [names[min(j, len(names) - 1)] for j in range(len(pts) - 1)]
    b.ribbon(pts, [0.09, 0.08, 0.06, 0.04, 0.005], side, (0.65, 0.65, 0.65), cls=CLOTH, bones=bones, tint=1.0, col_end=(0.9, 0.9, 0.9))

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
