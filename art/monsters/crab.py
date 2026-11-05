"""Crab: the armoured crustaceans of the coasts and the Blood Pool (Coral Crab, Crab General,
Blood-Pool Crab ...).  A ridged, spiked carapace on eight jointed walking legs, two heavy claws
with a hinged pincer, eye stalks that swivel, and frothing mouthparts.
Tinted by the game per enemy; eyes, tips and the claw's inner edge keep their colours.
Run: blender --background --python art/monsters/crab.py  ->  assets/monsters/crab.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import leg_chain, scuttle, zero_pose  # noqa: E402
from kit import SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402

kit.reset()
BY = 0.62
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, BY, -0.1), (0, BY, 0.3), "root")
legs = []
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(4):
        z = 0.18 - k * 0.17
        root = V(0.38 * s, BY - 0.02, z)
        knee = V(0.66 * s, BY + 0.2, z - 0.05 * k)
        foot = V(0.84 * s, 0.02, z - 0.12 * k)
        nm = "leg%d.%s" % (k, sd)
        leg_chain(r, nm, root, knee, foot, "body")
        legs.append((nm + "_a", nm + "_b", k * 1.6 + (0 if s > 0 else math.pi)))
    # claw arm: upper, forearm, then the movable finger
    r.bone("arm." + sd, (0.3 * s, BY + 0.02, 0.32), (0.55 * s, BY + 0.2, 0.62), "body")
    r.bone("claw." + sd, (0.55 * s, BY + 0.2, 0.62), (0.62 * s, BY + 0.24, 1.0), "arm." + sd)
    r.bone("pincer." + sd, (0.62 * s, BY + 0.3, 0.78), (0.64 * s, BY + 0.32, 1.06), "claw." + sd)
    r.bone("stalk." + sd, (0.1 * s, BY + 0.2, 0.36), (0.12 * s, BY + 0.42, 0.42), "body")
b = Builder("crab")

# carapace: a broad superquadric dome with a raised rim, ridges and spikes
b.superquad(V(0, BY + 0.04, 0.02), (0.6, 0.26, 0.47), (0.8, 0.8, 0.8), e=0.55, cls=SCALE, bone="body", tint=1.0, seg=24, rings=14, col2=(1.0, 1.0, 1.0))
b.superquad(V(0, BY - 0.1, 0.02), (0.52, 0.12, 0.42), (1.0, 1.0, 1.0), e=0.6, cls=SCALE, bone="body", tint=1.0, seg=20, rings=8)
for k in range(5):
    x = (k - 2) * 0.17
    b.tube([V(x, BY + 0.2, -0.25), V(x * 1.05, BY + 0.27, 0.0), V(x * 1.1, BY + 0.2, 0.3)], [0.02, 0.03, 0.02], (0.6, 0.6, 0.6), cls=SCALE, bone="body", tint=1.0, seg=6)
for k in range(7):
    a = -1.2 + k * 0.4
    b.cone(V(math.sin(a) * 0.5, BY + 0.1, math.cos(a) * 0.4), 0.035, 0.12, "ece0d0", cls=STONE, bone="body", seg=6, rot=(math.cos(a) * 1.2, 0, -math.sin(a) * 1.2))
# legs
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(4):
        nm = "leg%d.%s" % (k, sd)
        a0, a1 = r.bones[nm + "_a"][0], r.bones[nm + "_a"][1]
        f1 = r.bones[nm + "_b"][1]
        b.tube([a0, V(a0).lerp(V(a1), 0.5) + V(0, 0.04, 0), a1], [0.055, 0.05, 0.04], (0.75, 0.75, 0.75), cls=SCALE, bones=[nm + "_a", nm + "_a", {nm + "_a": 0.5, nm + "_b": 0.5}], tint=1.0, seg=8)
        b.tube([a1, V(a1).lerp(V(f1), 0.6), f1], [0.04, 0.03, 0.008], (0.85, 0.85, 0.85), cls=SCALE, bones=[{nm + "_a": 0.5, nm + "_b": 0.5}, nm + "_b", nm + "_b"], tint=1.0, seg=8)
    # claw arm and the big claw
    ua = r.bones["arm." + sd]
    b.tube([ua[0], ua[1]], [0.07, 0.08], (0.75, 0.75, 0.75), cls=SCALE, bone="arm." + sd, tint=1.0, seg=10)
    cb = r.bones["claw." + sd]
    b.ellipsoid(V(cb[0]).lerp(V(cb[1]), 0.35), (0.14, 0.13, 0.22), (0.85, 0.85, 0.85), cls=SCALE, bone="claw." + sd, tint=1.0, seg=16, rings=10, rot=(0.1, 0.1 * s, 0))
    b.tube([V(cb[0]).lerp(V(cb[1]), 0.5) + V(0, -0.04, 0), V(cb[1]) + V(0, -0.06, 0.0)], [(0.07, 0.04), (0.012, 0.01)], (0.8, 0.8, 0.8), cls=SCALE, bone="claw." + sd, tint=1.0, seg=8)
    pc = r.bones["pincer." + sd]
    b.tube([pc[0], V(pc[0]).lerp(V(pc[1]), 0.5) + V(0, 0.03, 0), pc[1]], [(0.06, 0.035), (0.05, 0.03), (0.01, 0.008)], (0.9, 0.9, 0.9), cls=SCALE, bone="pincer." + sd, tint=1.0, seg=8)
    for q in range(3):
        b.cone(V(pc[0]).lerp(V(pc[1]), 0.3 + q * 0.2) + V(0, -0.03, 0), 0.012, 0.04, "f0e8d8", cls=STONE, bone="pincer." + sd, seg=5, rot=(math.pi, 0, 0))
    # eye stalks
    st = r.bones["stalk." + sd]
    b.tube([st[0], st[1]], [0.025, 0.02], (0.7, 0.7, 0.7), cls=SCALE, bone="stalk." + sd, tint=1.0, seg=6)
    b.ball(V(st[1]) + V(0, 0.03, 0), 0.045, "101018", cls=SKIN, bone="stalk." + sd, seg=10, rings=6)
    b.ball(V(st[1]) + V(0.015 * s, 0.05, 0.03), 0.014, "ffffff", cls=SKIN, bone="stalk." + sd, seg=6, rings=4, mat=kit.MAT_GLOW)
# mouthparts
for k in range(3):
    b.ellipsoid(V((k - 1) * 0.05, BY - 0.02, 0.4), (0.03, 0.05, 0.02), (0.6, 0.6, 0.6), cls=SCALE, bone="body", tint=1.0, seg=8, rings=5)

T_IDLE = 2.0


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    scuttle(p, legs, t, w, 0.06, 0.04)
    p["body"] = ((0, math.sin(t * w * 0.5) * 0.06, 0), (math.sin(t * w * 0.5) * 0.04, abs(math.sin(t * w)) * 0.02, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((-0.1 + math.sin(t * w + s) * 0.1, 0, 0), (0, 0, 0))
        p["pincer." + sd] = ((-0.15 - 0.15 * max(0.0, math.sin(t * w * 2 + s)), 0, 0), (0, 0, 0))
        p["stalk." + sd] = ((math.sin(t * w * 1.3 + s) * 0.2, math.sin(t * w * 0.7 + s) * 0.3, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    snap = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0, 0.35 * snap))
    for sd in ("L", "R"):
        p["arm." + sd] = ((-0.7 * e + 0.5 * snap, 0, 0), (0, 0, 0))
        p["pincer." + sd] = ((-0.5 * e + 0.5 * snap, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["body"] = ((-0.2 * e, 0, 0.15 * e), (0, 0, -0.1 * e))
    for sd in ("L", "R"):
        p["stalk." + sd] = ((0.6 * e, 0, 0), (0, 0, 0))
    scuttle(p, legs, t, 30.0, 0.15 * e, 0.1 * e)
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["body"] = ((-0.25 * e, 0, 0), (0, 0.1 * e, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((-1.0 * e, 0, -0.4 * e * s), (0, 0, 0))
        p["pincer." + sd] = ((-0.6 * e, 0, 0), (0, 0, 0))
    return p


kit.scale_asset(b, r, 1.15)
print("[art] crab: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/crab.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
