"""Crab: the armoured crustaceans of the coasts and the Blood Pool (Coral Crab, Crab General,
Blood-Pool Crab ...).  A trapezoid carapace sculpted with the H-shaped groove between its
gastric, cardiac and branchial regions, tubercles and serrated anterolateral and frontal teeth;
a broad, low body on eight sprawling walking legs, each a flattened merus, carpus and bristled
propodus ending in a dark pointed dactyl; asymmetric chelipeds - a great crusher on the left and
a slimmer cutter on the right - each an inflated keeled palm with toothed fixed and hinged
fingers with dark tips; eye stalks rising from their orbits; and frothing mouthparts.
Tinted by the game per enemy; eyes, tips and the claw's inner edge keep their colours.
Run: blender --background --python art/monsters/crab.py  ->  assets/monsters/crab.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import Gait, Walker, add, flip_die, foot_path, leg_chain, smooth, zero_pose  # noqa: E402
from kit import CRYSTAL, HAIR, MAT_PLAIN, SCALE, SKIN, STONE, V, Builder, Rig  # noqa: E402
from sculpt import blob3, fbm3, morph_sphere  # noqa: E402

kit.reset()
creature.realtime()
BY = 0.5
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, BY, -0.1), (0, BY, 0.3), "root")
legs = []
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(4):
        z = 0.18 - k * 0.17
        root = V(0.38 * s, BY - 0.02, z)
        knee = V(0.68 * s, BY + 0.16, z - 0.05 * k)
        foot = V(0.92 * s, 0.02, z - 0.12 * k)
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
    p = V(d.x * 0.7, d.y * (0.27 if d.y > 0 else 0.12), d.z * 0.5)
    p.x *= 1.0 + 0.14 * d.z
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
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# anterolateral teeth along the front edges, frontal teeth between the eyes
for s in (1, -1):
    for k in range(6):
        a = 0.25 + k * 0.17
        base = CC + V(math.sin(a) * 0.72 * s * (1.0 + 0.14 * math.cos(a)), 0.04, math.cos(a) * 0.47)
        out = V(math.sin(a) * s, 0.1, math.cos(a) * 0.6).normalized()
        ln = 0.06 + (0.08 if k == 5 else 0.0)
        b.cone(base + out * ln * 0.5, 0.025, ln, (0.6, 0.6, 0.6), cls=STONE, bone="body", seg=6, tint=1.0, rot=(math.atan2(out.z, out.y) - 0.0, 0, -math.atan2(out.x, out.y)))
for k in range(4):
    x = (k - 1.5) * 0.045
    b.cone(CC + V(x, 0.06, 0.48), 0.018, 0.05, (0.6, 0.6, 0.6), cls=STONE, bone="body", seg=6, tint=1.0, rot=(math.pi / 2, 0, 0))
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# legs: a flattened merus, a short carpus, the propodus fringed with bristles and a pointed dark
# dactyl, each its own armoured plate
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(4):
        nm = "leg%d.%s" % (k, sd)
        a0, a1 = V(r.bones[nm + "_a"][0]), V(r.bones[nm + "_a"][1])
        f1 = V(r.bones[nm + "_b"][1])
        ba, bb = nm + "_a", nm + "_b"
        mid = a1.lerp(f1, 0.55) + V(0.03 * s, 0.02, 0)
        A.sclerite(b, a0 - (a1 - a0) * 0.08, a1, 0.078, 0.05, ba, col=0.8, keels=2, phase=math.pi / 2, ridge=0.15, seg=14, rings=8, blunt=0.45)
        A.sclerite(b, a1 - (mid - a1) * 0.05, a1.lerp(mid, 0.4), 0.058, 0.045, bb, col=0.84, seg=12, rings=6)
        A.sclerite(b, a1.lerp(mid, 0.38), mid, 0.055, 0.04, bb, col=0.86, keels=2, phase=math.pi / 2, seg=12, rings=8, blunt=0.5)
        A.horn(b, [mid, mid.lerp(f1, 0.5) + V(0.01 * s, 0.01, 0), f1], 0.03, (0.75, 0.75, 0.75), "2a1a18", bb, r1=0.003, cls=STONE, seg=8, flat=0.7, up=(1, 0, 0), tint=0.6)
        for h in range(5):
            q = a1.lerp(mid, 0.25 + h * 0.15)
            b.tube([q, q + V(0.02 * s, 0.04, -0.012)], [0.004, 0.001], (0.45, 0.45, 0.45), cls=HAIR, bone=bb, tint=1.0, seg=3)
    # chelipeds: merus and carpus, then the chela - an inflated, keeled palm with the fixed finger
    # and the hinged dactyl, both toothed along the cutting edge with dark tips.  The left is the
    # great crusher, the right a slimmer cutter, as in a real crab
    big = 1.0 if s > 0 else 0.72
    ua = r.bones["arm." + sd]
    u0, u1 = V(ua[0]), V(ua[1])
    A.sclerite(b, u0 - (u1 - u0) * 0.05, u0.lerp(u1, 0.55), 0.075 * big, 0.06 * big, "arm." + sd, col=0.82, keels=3, ridge=0.18, seg=16, rings=8, blunt=0.5)
    A.sclerite(b, u0.lerp(u1, 0.5), u1 + (u1 - u0) * 0.05, 0.085 * big, 0.07 * big, "arm." + sd, col=0.86, keels=3, ridge=0.18, seg=16, rings=8, blunt=0.5)
    cb = r.bones["claw." + sd]
    c0, c1 = V(cb[0]), V(cb[1])
    fwd = (c1 - c0).normalized()
    hf = A.HeadFrame(c0.lerp(c1, 0.35), fwd)
    A.sclerite(b, c0 - fwd * 0.04, c0 + fwd * (0.3 * big + 0.05), 0.14 * big, 0.15 * big, "claw." + sd, col=0.9, keels=4, phase=math.pi / 4, ridge=0.08, seg=24, rings=14, blunt=0.42, joint=0.2,
               up=tuple(hf.u))
    tip0 = c0 + fwd * (0.3 * big + 0.02)
    fixed = [tip0 + hf.u * (-0.06 * big), tip0 + fwd * 0.12 * big - hf.u * 0.07 * big, tip0 + fwd * 0.24 * big - hf.u * 0.05 * big, tip0 + fwd * 0.3 * big - hf.u * 0.01]
    # the fingers in the accent colour fading to dark tips, like a fiddler crab's claw
    b.cur_pal = 1.0
    A.horn(b, fixed, 0.06 * big, (0.92, 0.92, 0.92), (0.15, 0.12, 0.12), "claw." + sd, r1=0.006, cls=SCALE, seg=10, flat=0.6, up=tuple(hf.r), tint=1.0)
    pc = r.bones["pincer." + sd]
    p0, p1 = V(pc[0]), V(pc[1])
    pf = (p1 - p0).normalized()
    mov = [p0, p0 + pf * 0.12 * big + hf.u * 0.035 * big, p0 + pf * 0.24 * big + hf.u * 0.01, p0 + pf * 0.3 * big - hf.u * 0.04 * big]
    A.horn(b, mov, 0.055 * big, (0.92, 0.92, 0.92), (0.15, 0.12, 0.12), "pincer." + sd, r1=0.006, cls=SCALE, seg=10, flat=0.6, up=tuple(hf.r), tint=1.0)
    b.cur_pal = 0.0
    for q in range(5):
        t = 0.2 + q * 0.15
        b.cone(p0 + pf * (0.3 * big * t) - hf.u * 0.03 * big, 0.011 * big, 0.03 * big, "f0e8d8", cls=STONE, bone="pincer." + sd, seg=5, rot=(math.pi, 0, 0))
        b.cone(tip0 + fwd * (0.3 * big * t) - hf.u * 0.035 * big, 0.011 * big, 0.03 * big, "f0e8d8", cls=STONE, bone="claw." + sd, seg=5)
for s, sd in ((1, "L"), (-1, "R")):
    b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
    # eye stalks rising out of the orbits
    st = r.bones["stalk." + sd]
    s0, s1 = V(st[0]), V(st[1])
    b.ellipsoid(s0 + V(0, -0.02, 0), (0.045, 0.03, 0.04), (0.55, 0.55, 0.55), cls=SCALE, bone="body", tint=1.0, seg=10, rings=6)
    b.tube([s0, s0.lerp(s1, 0.5) + V(0.01 * s, 0, 0.01), s1], [0.025, 0.022, 0.02], (0.7, 0.7, 0.7), cls=SCALE, bone="stalk." + sd, tint=1.0, seg=8)
    b.ball(s1 + V(0, 0.03, 0), 0.045, "101018", cls=SKIN, bone="stalk." + sd, seg=12, rings=8)
    b.ball(s1 + V(0.015 * s, 0.05, 0.03), 0.014, "ffffff", cls=SKIN, bone="stalk." + sd, seg=6, rings=4, mat=kit.MAT_GLOW)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# mouthparts: layered maxillipeds frothing with bubbles
for k in range(3):
    b.ellipsoid(V((k - 1) * 0.05, BY - 0.02, 0.43), (0.03, 0.05, 0.02), (0.6, 0.6, 0.6), cls=SCALE, bone="body", tint=1.0, seg=8, rings=5)
for k in range(6):
    b.ball(V(math.sin(k * 2.1) * 0.06, BY - 0.07 + 0.02 * math.cos(k), 0.46), 0.012 + 0.006 * (k % 2), "f0f8ff", cls=CRYSTAL, bone="body", seg=6, rings=4, mat=MAT_PLAIN)

T_IDLE = 2.0
T_WALK = 0.9
WALK = Walker(r, [(a_, b_) for a_, b_, _ in legs], [0.5 * ((i % 4 + (0 if i < 4 else 1)) % 2) for i in range(8)], duty=0.55)


def claws(p, t, T_, amp=1.0):
    w = 2 * math.pi / T_
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm." + sd, (-0.1 + math.sin(t * w + s_) * 0.1 * amp, 0, 0))
        add(p, "pincer." + sd, (-0.15 - 0.15 * max(0.0, math.sin(t * w * 2 + s_)) * amp, 0, 0))
        add(p, "stalk." + sd, (math.sin(t * w * 2 + s_) * 0.2, math.sin(t * w + s_) * 0.3, 0))


def idle(t):
    p = zero_pose(r)
    w = 2 * math.pi / T_IDLE
    add(p, "body", (0, math.sin(t * w) * 0.05, 0), (math.sin(t * w) * 0.03, abs(math.sin(t * w)) * 0.015, 0))
    claws(p, t, T_IDLE)
    return WALK.step(p)


def walk(t):
    """Crabs scuttle sideways: the feet step out to the side in alternate groups."""
    p = zero_pose(r)
    ph = (t / T_WALK) % 1.0
    add(p, "body", (0, 0, 0.04 * math.sin(2 * math.pi * ph)), (0.015 * math.sin(2 * math.pi * ph), 0.012 * abs(math.sin(2 * math.pi * ph * 2)), 0))
    claws(p, t, T_WALK, 0.5)
    D = []
    for i in range(8):
        on, s_ = Gait(WALK.phases[i], WALK.duty).at(ph)
        dz, dy = foot_path(on, s_, 0.16, 0.08)
        D.append((dz * 0.8, dy, dz * 0.35))
    return WALK.step(p, offsets=D)


def attack(t):
    k = t / 0.55
    raise_ = smooth(0.0, 0.3, k) * (1.0 - smooth(0.32, 0.42, k))
    snap = smooth(0.32, 0.42, k) * (1.0 - smooth(0.6, 1.0, k))
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0, 0.3 * snap))
    for sd in ("L", "R"):
        add(p, "arm." + sd, (-0.7 * raise_ + 0.5 * snap, 0, 0))
        add(p, "pincer." + sd, (-0.5 * raise_ + 0.5 * snap, 0, 0))
    return WALK.step(p, offsets=[(0.0, 0.0, 0.3 * snap)] * 8)


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    add(p, "body", (-0.2 * e, 0, 0.15 * e), (0, 0, -0.1 * e))
    for sd in ("L", "R"):
        add(p, "stalk." + sd, (0.6 * e, 0, 0))
    return WALK.step(p, offsets=[(0.0, 0.0, -0.1 * e)] * 8)


def die(t):
    k = min(1.0, t / 1.2)
    p = zero_pose(r)
    p = WALK.step(p)
    curl = []
    for a_, b_, _ in legs:
        sg = 1 if ".L_" in a_ else -1
        curl.append((a_, (0.0, 0.0, -0.9 * sg)))
        curl.append((b_, (0.0, 0.0, -1.3 * sg)))
    for sd in ("L", "R"):
        add(p, "arm." + sd, (0.4 * smooth(0.3, 0.9, k), 0, 0))
        add(p, "stalk." + sd, (0.9 * smooth(0.2, 0.6, k), 0, 0))
    flip_die(p, t, 1.2, BY, side=1, curl_legs=curl, rest=0.14)
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    add(p, "body", (-0.25 * e, 0, 0), (0, 0.1 * e, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm." + sd, (-1.0 * e, 0, -0.4 * e * s_))
        add(p, "pincer." + sd, (-0.6 * e, 0, 0))
    return WALK.step(p)


kit.scale_asset(b, r, 1.15)
print("[art] crab: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/crab.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=16, dist=0.3, strength=0.5, floor_y=0.0)
