"""Spider: the eight-legged hunters (Cave Spider, Root Crawler) and, recoloured brass, the Brass
Spider Engine of Heaven's Forge.  A bulbous striped abdomen with a spinneret, a cephalothorax with
a cluster of eight glowing eyes, curved fangs, hairy pedipalps and eight long, kinked legs that
walk in an alternating gait.  Tinted by the game per enemy; eyes and fangs keep their colours.
Run: blender --background --python art/monsters/spider.py  ->  assets/monsters/spider.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import leg_chain, scuttle, zero_pose  # noqa: E402
from kit import HAIR, MAT_GLOW, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402

kit.reset()
BY = 0.7
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("thorax", (0, BY, -0.05), (0, BY, 0.35), "root")
r.bone("abdomen", (0, BY + 0.05, -0.1), (0, BY + 0.2, -0.85), "thorax")
r.bone("fangs", (0, BY - 0.05, 0.35), (0, BY - 0.2, 0.5), "thorax")
legs = []
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(4):
        z = 0.22 - k * 0.15
        spread = (0.45, 0.15, -0.15, -0.45)[k]
        root = V(0.17 * s, BY, z)
        knee = V((0.62 + 0.05 * k) * s, BY + 0.5, z + spread * 0.6)
        foot = V((1.0 + 0.04 * k) * s, 0.02, z + spread * 1.4)
        nm = "leg%d.%s" % (k, sd)
        leg_chain(r, nm, root, knee, foot, "thorax")
        legs.append((nm + "_a", nm + "_b", (k % 2) * math.pi + (0 if s > 0 else math.pi)))
    r.bone("palp." + sd, (0.08 * s, BY - 0.02, 0.36), (0.16 * s, BY - 0.05, 0.62), "thorax")
b = Builder("spider")

# abdomen: big, striped and hairy, with a spinneret
b.ellipsoid(V(0, BY + 0.2, -0.55), (0.36, 0.32, 0.46), (0.75, 0.75, 0.75), cls=SCALE, bone="abdomen", tint=1.0, seg=22, rings=14, col2=(0.95, 0.95, 0.95))
for k in range(4):
    z = -0.3 - k * 0.14
    rr = 0.33 * math.sqrt(max(0.05, 1.0 - ((z + 0.55) / 0.46) ** 2))
    b.tube([V(-rr, BY + 0.28, z), V(0, BY + 0.2 + 0.32 * (rr / 0.33) + 0.02, z), V(rr, BY + 0.28, z)], [0.03, 0.035, 0.03], (0.45, 0.45, 0.45), cls=SCALE, bone="abdomen", tint=1.0, seg=6)
b.cone(V(0, BY + 0.06, -1.0), 0.06, 0.12, (0.5, 0.5, 0.5), cls=SCALE, bone="abdomen", tint=1.0, seg=8, rot=(-1.9, 0, 0))
for k in range(16):
    a = k * 2.4
    root = V(math.cos(a) * 0.25, BY + 0.22 + math.sin(a) * 0.22, -0.55 + math.sin(k * 1.3) * 0.25)
    b.tube([root, root + (root - V(0, BY + 0.2, -0.55)).normalized() * 0.08], [0.008, 0.002], (0.4, 0.4, 0.4), cls=HAIR, bone="abdomen", tint=1.0, seg=4)
# cephalothorax and eye cluster
b.ellipsoid(V(0, BY + 0.04, 0.16), (0.22, 0.16, 0.26), (0.7, 0.7, 0.7), cls=SCALE, bone="thorax", tint=1.0, seg=18, rings=10, col2=(0.9, 0.9, 0.9))
for k, (x, y, rr) in enumerate(((0.05, 0.14, 0.035), (-0.05, 0.14, 0.035), (0.11, 0.12, 0.025), (-0.11, 0.12, 0.025), (0.04, 0.19, 0.02), (-0.04, 0.19, 0.02), (0.13, 0.17, 0.016), (-0.13, 0.17, 0.016))):
    c = V(x, BY + y, 0.38 - abs(x) * 0.4)
    b.ball(c, rr, "200810", cls=SKIN, bone="thorax", seg=10, rings=6)
    b.ball(c + V(0, 0, rr * 0.4), rr * 0.6, "ff3040", cls=SKIN, bone="thorax", seg=8, rings=5, mat=MAT_GLOW)
for s in (1, -1):
    b.tube([V(0.05 * s, BY - 0.04, 0.38), V(0.06 * s, BY - 0.14, 0.45), V(0.03 * s, BY - 0.24, 0.42)], [0.035, 0.025, 0.004], "201418", cls=STONE, bone="fangs", seg=8)
# legs: thick femur, kinked tibia, hairy
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(4):
        nm = "leg%d.%s" % (k, sd)
        a0, a1 = r.bones[nm + "_a"][0], r.bones[nm + "_a"][1]
        f1 = r.bones[nm + "_b"][1]
        b.tube([a0, V(a0).lerp(V(a1), 0.5) + V(0, 0.05, 0), a1], [0.045, 0.045, 0.035], (0.7, 0.7, 0.7), cls=SCALE, bones=[nm + "_a", nm + "_a", {nm + "_a": 0.5, nm + "_b": 0.5}], tint=1.0, seg=8)
        b.tube([a1, V(a1).lerp(V(f1), 0.55) + V(0.04 * s, 0.03, 0), f1], [0.035, 0.025, 0.006], (0.8, 0.8, 0.8), cls=SCALE, bones=[{nm + "_a": 0.5, nm + "_b": 0.5}, nm + "_b", nm + "_b"], tint=1.0, seg=8)
        for h in range(3):
            q = V(a1).lerp(V(f1), 0.2 + h * 0.2)
            b.tube([q, q + V(0.05 * s, 0.03, 0)], [0.006, 0.001], (0.4, 0.4, 0.4), cls=HAIR, bone=nm + "_b", tint=1.0, seg=3)
    pa = r.bones["palp." + sd]
    b.tube([pa[0], pa[1]], [0.03, 0.025], (0.65, 0.65, 0.65), cls=SCALE, bone="palp." + sd, tint=1.0, seg=7)

T_IDLE = 2.2


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    scuttle(p, legs, t, w, 0.05, 0.03)
    p["thorax"] = ((math.sin(t * w) * 0.03, 0, 0), (0, abs(math.sin(t * w)) * 0.015, 0))
    p["abdomen"] = ((math.sin(t * w * 0.5) * 0.08, math.sin(t * w * 0.7) * 0.06, 0), (0, 0, 0))
    p["fangs"] = ((0.1 * max(0.0, math.sin(t * w * 2)), 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["palp." + sd] = ((math.sin(t * w * 2 + s) * 0.2, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.1 * lunge, 0.4 * lunge))
    p["thorax"] = ((0.25 * e - 0.4 * lunge, 0, 0), (0, 0, 0))
    p["fangs"] = ((0.8 * lunge, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["leg0.%s_a" % sd] = ((-0.9 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["thorax"] = ((-0.3 * e, 0, 0.1 * e), (0, 0, -0.08 * e))
    scuttle(p, legs, t, 40.0, 0.2 * e, 0.1 * e)
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    # rear up, abdomen raised to spray web
    p["thorax"] = ((-0.35 * e, 0, 0), (0, 0.12 * e, 0))
    p["abdomen"] = ((-0.6 * e, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["leg0.%s_a" % sd] = ((-1.0 * e, 0, 0), (0, 0, 0))
        p["leg1.%s_a" % sd] = ((-0.6 * e, 0, 0), (0, 0, 0))
    return p


print("[art] spider: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/spider.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
