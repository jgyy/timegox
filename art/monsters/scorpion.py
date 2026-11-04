"""Scorpion (new in Part V): plated body, eight jointed legs, two great pincers that snap, and a
five-segment tail arching overhead to a glowing stinger (Glass Scorpion King, Dune Stalker).
Run: blender --background --python art/monsters/scorpion.py  ->  assets/monsters/scorpion.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import eyes, zero_pose  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, SCALE, V, Builder, Rig, env  # noqa: E402

kit.reset()
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, 0.42, -0.4), (0, 0.45, 0.35), "root")
TAIL = [V(0, 0.45, -0.55), V(0, 0.6, -0.85), V(0, 0.9, -1.05), V(0, 1.25, -1.05), V(0, 1.5, -0.85), V(0, 1.55, -0.55)]
for i in range(5):
    r.bone("tail%d" % i, TAIL[i], TAIL[i + 1], "body" if i == 0 else "tail%d" % (i - 1))
for s, sd in ((1, "L"), (-1, "R")):
    sh = V(0.22 * s, 0.45, 0.35)
    el = V(0.45 * s, 0.5, 0.55)
    wr = V(0.38 * s, 0.5, 0.85)
    r.bone("arm.%s" % sd, sh, el, "body")
    r.bone("fore.%s" % sd, el, wr, "arm.%s" % sd)
    r.bone("claw.%s" % sd, wr, wr + V(0.0, 0.0, 0.3), "fore.%s" % sd)
    r.bone("pinch.%s" % sd, wr + V(-0.06 * s, 0, 0.02), wr + V(-0.08 * s, 0, 0.28), "fore.%s" % sd)
    for k in range(4):
        z = 0.2 - k * 0.2
        hip = V(0.22 * s, 0.42, z)
        knee = V(0.55 * s, 0.55, z + 0.05 - k * 0.03)
        foot = V(0.75 * s, 0.02, z + 0.08 - k * 0.1)
        r.bone("leg%d.%s" % (k, sd), hip, knee, "body")
        r.bone("shin%d.%s" % (k, sd), knee, foot, "leg%d.%s" % (k, sd))

b = Builder("scorpion")
# cephalothorax and abdominal plates
b.superquad(V(0, 0.45, 0.2), (0.28, 0.12, 0.25), (0.9, 0.9, 0.9), e=0.5, cls=SCALE, bone="body", tint=1.0, col2=(0.55, 0.55, 0.55))
for k in range(5):
    z = -0.05 - k * 0.12
    w = 0.3 - k * 0.025
    b.superquad(V(0, 0.44 + 0.01 * k, z), (w, 0.1, 0.08), (0.8 + 0.04 * (k % 2), 0.8 + 0.04 * (k % 2), 0.8 + 0.04 * (k % 2)), e=0.5, cls=SCALE, bone="body", tint=1.0, col2=(0.5, 0.5, 0.5))
eyes(b, V(0, 0.56, 0.38), 0.06, 0.025, iris="ff4030", bone="body", slit=False, glow=True, rot_y=0.4, h=0.9)
for s in (1, -1):
    b.ball(V(0.15 * s, 0.53, 0.4), 0.018, "ff6040", cls=CRYSTAL, bone="body", mat=MAT_GLOW, seg=8, rings=5)
# mandibles
for s in (1, -1):
    b.cone(V(0.05 * s, 0.4, 0.47), 0.03, 0.12, (0.5, 0.5, 0.5), cls=SCALE, bone="body", tint=1.0, rot=(math.pi / 2, 0, 0), seg=6)
# tail segments with a glowing venom bulb and stinger
for i in range(5):
    a = TAIL[i]
    c = TAIL[i].lerp(TAIL[i + 1], 0.5)
    d = TAIL[i + 1] - a
    rx = math.atan2(-d.y, d.z) if d.length > 0 else 0.0
    w = 0.13 - i * 0.012
    b.superquad(c, (w, w * 0.85, d.length * 0.62), (0.85, 0.85, 0.85), e=0.55, cls=SCALE, bone="tail%d" % i, rot=(rx, 0, 0), tint=1.0, col2=(0.6, 0.6, 0.6))
bulb = TAIL[5] + V(0, -0.02, 0.08)
b.ellipsoid(bulb, (0.1, 0.09, 0.13), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="tail4", tint=1.0, mat=MAT_GLOW, seg=12, rings=8)
b.cone(bulb + V(0, -0.1, 0.13), 0.035, 0.22, "201010", cls=SCALE, bone="tail4", rot=(math.pi * 0.75, 0, 0), seg=8)
# pincers
for s, sd in ((1, "L"), (-1, "R")):
    a, fo, c = "arm.%s" % sd, "fore.%s" % sd, "claw.%s" % sd
    b.tube([r.head(a), r.tail(a)], [0.06, 0.055], (0.8, 0.8, 0.8), cls=SCALE, bone=a, tint=1.0, seg=10)
    b.tube([r.head(fo), r.tail(fo)], [0.06, 0.07], (0.85, 0.85, 0.85), cls=SCALE, bone=fo, tint=1.0, seg=10)
    wr = r.tail(fo)
    b.ellipsoid(wr + V(0.03 * s, 0, 0.12), (0.11, 0.08, 0.16), (0.95, 0.95, 0.95), cls=SCALE, bone=c, tint=1.0, seg=14, rings=8)
    b.cone(wr + V(0.04 * s, 0, 0.33), 0.05, 0.2, (0.6, 0.6, 0.6), cls=SCALE, bone=c, tint=1.0, rot=(math.pi / 2, 0, 0.1 * s), seg=8)
    b.cone(wr + V(-0.06 * s, 0, 0.17), 0.035, 0.24, (0.6, 0.6, 0.6), cls=SCALE, bone="pinch.%s" % sd, tint=1.0, rot=(math.pi / 2, 0, -0.15 * s), seg=8)
    for k in range(4):
        lg, sn = "leg%d.%s" % (k, sd), "shin%d.%s" % (k, sd)
        b.tube([r.head(lg), r.tail(lg)], [0.035, 0.03], (0.75, 0.75, 0.75), cls=SCALE, bone=lg, tint=1.0, seg=8)
        b.tube([r.head(sn), r.head(sn).lerp(r.tail(sn), 0.6), r.tail(sn)], [0.03, 0.022, 0.006], (0.6, 0.6, 0.6), cls=SCALE, bones=[{lg: 0.4, sn: 0.6}, sn, sn], tint=1.0, seg=8)

T = 2.0


def idle(t, k_tail=1.0):
    w = 2 * math.pi / T
    p = zero_pose(r)
    p["body"] = ((0, math.sin(t * w * 0.5) * 0.06, 0), (0, math.sin(t * w) * 0.01, 0))
    for i in range(5):
        p["tail%d" % i] = ((math.sin(t * w - i * 0.6) * 0.05 * k_tail, math.sin(t * w * 0.5 - i * 0.4) * 0.07 * k_tail, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        snap = max(0.0, math.sin(t * w * 2 + (0 if s > 0 else 1.5))) ** 6
        p["pinch.%s" % sd] = ((0, -s * 0.35 * (1 - snap), 0), (0, 0, 0))
        p["arm.%s" % sd] = ((math.sin(t * w + s) * 0.06, s * 0.1 * math.sin(t * w * 0.5), 0), (0, 0, 0))
        for k in range(4):
            ph = t * w * 2 + k * 1.3 + (0 if s > 0 else math.pi)
            p["leg%d.%s" % (k, sd)] = ((0, math.sin(ph) * 0.06, s * max(0.0, math.sin(ph)) * 0.08), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    strike = math.sin(min(1.0, max(0.0, (k - 0.2) / 0.5)) * math.pi)
    p = idle(0.0, 0.3)
    for i in range(5):
        p["tail%d" % i] = ((0.25 * strike - 0.1 * e, 0, 0), (0, 0, 0))
    p["body"] = ((0.15 * strike, 0, 0), (0, 0, 0.25 * strike))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((0, s * 0.3 * e, 0), (0, 0, 0))
        p["pinch.%s" % sd] = ((0, -s * 0.5 * e, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0, 0.5)
    p["body"] = ((-0.2 * e, 0.15 * e, 0), (0, 0.04 * e, -0.15 * e))
    for i in range(5):
        p["tail%d" % i] = ((-0.12 * e, 0.1 * e, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(t, 1.5)
    p["body"] = ((-0.25 * e, 0, 0), (0, 0.08 * e, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((-0.8 * e, -s * 0.3 * e, 0), (0, 0, 0))
        p["fore.%s" % sd] = ((-0.5 * e, 0, 0), (0, 0, 0))
        p["pinch.%s" % sd] = ((0, -s * 0.6 * e, 0), (0, 0, 0))
    return p


print("[art] scorpion: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/scorpion.glb", {"idle": (T * 2, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.5, floor_y=0.0)
