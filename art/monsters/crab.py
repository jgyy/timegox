"""Crab: the armoured crustaceans of the coasts and the Blood Pool (Coral Crab, Crab General,
Blood-Pool Crab ...).  A trapezoid carapace sculpted with the H-shaped groove between its
gastric, cardiac and branchial regions, tubercles and serrated anterolateral and frontal teeth;
eight walking legs of overlapping armoured segments with hairy propodi and dark dactyls; chelae with
an inflated palm, toothed fixed and movable fingers with dark tips; eye stalks rising from their
orbits; and frothing mouthparts.
Tinted by the game per enemy; eyes, tips and the claw's inner edge keep their colours.
Run: blender --background --python art/monsters/crab.py  ->  assets/monsters/crab.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import leg_chain, scuttle, zero_pose  # noqa: E402
from kit import CRYSTAL, HAIR, MAT_PLAIN, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402
from sculpt import blob3, fbm3, morph_sphere, smooth, strand  # noqa: E402

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
CC = V(0, BY + 0.02, 0.02)


def cara_shape(d):
    # wider at the front than the back (a swimming crab's trapezoid), domed, flat underneath
    p = V(d.x * 0.6, d.y * (0.24 if d.y > 0 else 0.12), d.z * 0.46)
    p.x *= 1.0 + 0.12 * d.z
    q = p.copy()
    off = 0.0
    # the H-shaped groove separating the gastric, cardiac and branchial regions
    off -= 0.018 * blob3(q, (0.0, 0.2, -0.02), (0.2, 0.06, 0.02))
    for s2 in (1, -1):
        off -= 0.016 * blob3(q, (0.12 * s2, 0.2, 0.05), (0.02, 0.06, 0.16))
        off += 0.02 * blob3(q, (0.3 * s2, 0.16, -0.04), (0.14, 0.06, 0.16))     # branchial swellings
    off += 0.02 * blob3(q, (0.0, 0.22, 0.18), (0.12, 0.05, 0.1))                 # gastric region
    return p + p.normalized() * off


def cara_col(p, d):
    v = 0.72 + 0.22 * smooth(-0.1, 0.8, d.y)
    tub = smooth(0.82, 0.88, fbm3((p.x * 14, p.y * 14, p.z * 14), 1, 4))
    v *= 1.0 + 0.18 * tub
    v *= 1.0 - 0.25 * smooth(0.95, 1.0, abs(math.sin(p.x * 6.0) * math.sin(p.z * 5.0))) * smooth(0.2, 0.7, d.y)
    if d.y < -0.1:
        v = 0.95 - 0.25 * smooth(0.9, 1.0, abs(math.sin(p.z * 14.0)))           # sternal plates
    return (v, v, v)


morph_sphere(b, CC, cara_shape, cara_col, cls=SCALE, bone="body", seg=40, rings=22, tint_fn=lambda p, d: 1.0)
# anterolateral teeth along the front edges, frontal teeth between the eyes
for s in (1, -1):
    for k in range(6):
        a = 0.25 + k * 0.17
        base = CC + V(math.sin(a) * 0.62 * s * (1.0 + 0.12 * math.cos(a)), 0.04, math.cos(a) * 0.45)
        out = V(math.sin(a) * s, 0.1, math.cos(a) * 0.6).normalized()
        ln = 0.06 + (0.08 if k == 5 else 0.0)
        b.cone(base + out * ln * 0.5, 0.025, ln, (0.6, 0.6, 0.6), cls=STONE, bone="body", seg=6, tint=1.0, rot=(math.atan2(out.z, out.y) - 0.0, 0, -math.atan2(out.x, out.y)))
for k in range(4):
    x = (k - 1.5) * 0.045
    b.cone(CC + V(x, 0.06, 0.48), 0.018, 0.05, (0.6, 0.6, 0.6), cls=STONE, bone="body", seg=6, tint=1.0, rot=(math.pi / 2, 0, 0))
# legs: merus, carpus, propodus and dactyl as overlapping armoured segments, hairs on the
# propodus, a dark pointed dactyl
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(4):
        nm = "leg%d.%s" % (k, sd)
        a0, a1 = V(r.bones[nm + "_a"][0]), V(r.bones[nm + "_a"][1])
        f1 = V(r.bones[nm + "_b"][1])
        ba, bb = nm + "_a", nm + "_b"
        mid = a1.lerp(f1, 0.55) + V(0.03 * s, 0.02, 0)
        A.plate_segments(b, [a0, a0.lerp(a1, 0.5) + V(0, 0.04, 0), a1], [(0.055, 0.04), (0.052, 0.04), (0.042, 0.034)], (0.75, 0.75, 0.75), lambda p, ba=ba, bb=bb, a1=a1: ba if (p - a1).length > 0.05 else {ba: 0.5, bb: 0.5}, n=10, col2=(0.95, 0.95, 0.95), ridge=0.15)
        A.plate_segments(b, [a1, mid, f1 + (mid - f1) * 0.3], [(0.04, 0.032), (0.032, 0.026), (0.022, 0.018)], (0.82, 0.82, 0.82), lambda p, bb=bb: bb, n=10, col2=(0.95, 0.95, 0.95))
        tip = f1 + (mid - f1) * 0.3
        b.tube([tip, f1], [0.018, 0.003], "3a2a28", cls=STONE, bone=bb, seg=6)
        for h in range(4):
            q = a1.lerp(mid, 0.3 + h * 0.2)
            b.tube([q, q + V(0.02 * s, 0.035, -0.01)], [0.004, 0.001], (0.45, 0.45, 0.45), cls=HAIR, bone=bb, tint=1.0, seg=3)
    # cheliped: merus and carpus, then the chela - an inflated palm, the fixed finger and the
    # movable finger (pincer), both toothed along the cutting edge, tips dark
    ua = r.bones["arm." + sd]
    A.plate_segments(b, [V(ua[0]), V(ua[0]).lerp(V(ua[1]), 0.5) + V(0, 0.03, 0), V(ua[1])], [(0.07, 0.06), (0.08, 0.065), (0.075, 0.065)], (0.75, 0.75, 0.75), lambda p, sd=sd: "arm." + sd, n=12, col2=(0.95, 0.95, 0.95), ridge=0.25)
    cb = r.bones["claw." + sd]
    c0, c1 = V(cb[0]), V(cb[1])
    palm_c = c0.lerp(c1, 0.35)
    fwd = (c1 - c0).normalized()
    hf = A.HeadFrame(palm_c, fwd)
    morph_sphere(b, palm_c, lambda d: V(d.x * 0.13, d.y * 0.14, d.z * 0.22) * (1.0 + 0.08 * max(0.0, d.y)), lambda p, d: (0.82 + 0.15 * d.y - 0.1 * smooth(0.85, 0.9, fbm3((p.x * 18, p.y * 18, p.z * 18), 1, 2)),) * 3,
                 cls=SCALE, bone="claw." + sd, seg=20, rings=14, tint_fn=lambda p, d: 1.0, rot=hf.M)
    fixed = [hf.at(0, -0.05, 0.16), hf.at(0, -0.06, 0.28), hf.at(0, -0.04, 0.38), hf.at(0, -0.01, 0.42)]
    strand(b, fixed, 0.06, 0.008, (0.82, 0.82, 0.82), col_tip=(0.3, 0.3, 0.3), cls=SCALE, bone="claw." + sd, flat=0.6, seg=10, per=3, up=tuple(hf.r), tint=1.0)
    pc = r.bones["pincer." + sd]
    p0, p1 = V(pc[0]), V(pc[1])
    mov = [p0, p0.lerp(p1, 0.45) + V(0, 0.035, 0), p0.lerp(p1, 0.85) + V(0, 0.01, 0), p1 + V(0, -0.03, 0)]
    strand(b, mov, 0.055, 0.008, (0.9, 0.9, 0.9), col_tip=(0.3, 0.3, 0.3), cls=SCALE, bone="pincer." + sd, flat=0.6, seg=10, per=3, up=tuple(hf.r), tint=1.0)
    for q in range(5):
        t = 0.25 + q * 0.14
        b.cone(p0.lerp(p1, t) + V(0, -0.02, 0), 0.01, 0.03, "f0e8d8", cls=STONE, bone="pincer." + sd, seg=5, rot=(math.pi, 0, 0))
        b.cone(hf.at(0, -0.03, 0.18 + q * 0.045), 0.01, 0.028, "f0e8d8", cls=STONE, bone="claw." + sd, seg=5)
    # eye stalks rising out of the orbits
    st = r.bones["stalk." + sd]
    s0, s1 = V(st[0]), V(st[1])
    b.ellipsoid(s0 + V(0, -0.02, 0), (0.045, 0.03, 0.04), (0.55, 0.55, 0.55), cls=SCALE, bone="body", tint=1.0, seg=10, rings=6)
    b.tube([s0, s0.lerp(s1, 0.5) + V(0.01 * s, 0, 0.01), s1], [0.025, 0.022, 0.02], (0.7, 0.7, 0.7), cls=SCALE, bone="stalk." + sd, tint=1.0, seg=8)
    b.ball(s1 + V(0, 0.03, 0), 0.045, "101018", cls=SKIN, bone="stalk." + sd, seg=12, rings=8)
    b.ball(s1 + V(0.015 * s, 0.05, 0.03), 0.014, "ffffff", cls=SKIN, bone="stalk." + sd, seg=6, rings=4, mat=kit.MAT_GLOW)
# mouthparts: layered maxillipeds frothing with bubbles
for k in range(3):
    b.ellipsoid(V((k - 1) * 0.05, BY - 0.02, 0.43), (0.03, 0.05, 0.02), (0.6, 0.6, 0.6), cls=SCALE, bone="body", tint=1.0, seg=8, rings=5)
for k in range(6):
    b.ball(V(math.sin(k * 2.1) * 0.06, BY - 0.07 + 0.02 * math.cos(k), 0.46), 0.012 + 0.006 * (k % 2), "f0f8ff", cls=CRYSTAL, bone="body", seg=6, rings=4, mat=MAT_PLAIN)

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
