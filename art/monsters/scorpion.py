"""Scorpion (new in Part V): the Glass Scorpion King and the Dune Stalker.  A flat prosoma with a
median eye tubercle and lateral eyes, seven keeled tergites over the mesosoma, chelicerae and
comb-like pectines underneath, a metasoma of five keeled tail segments arching overhead to the
bulbous telson and its curved aculeus, pedipalps ending in swollen chelae with toothed fingers,
and eight segmented legs with spurs.
Run: blender --background --python art/monsters/scorpion.py  ->  assets/monsters/scorpion.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import Walker, add, eyes, flip_die, smooth, zero_pose  # noqa: E402
from sculpt import morph_sphere, strand  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, SCALE, STONE, V, Builder, Rig  # noqa: E402

kit.reset()
creature.realtime()
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
# prosoma: a flat carapace with a median eye tubercle and lateral eyes at the front corners
PC = V(0, 0.45, 0.2)
morph_sphere(b, PC, lambda d: V(d.x * 0.28, d.y * (0.12 if d.y > 0 else 0.07), d.z * 0.26) * (1.0 + 0.05 * smooth(0.6, 1.0, d.y) * smooth(-0.2, 0.4, d.z)),
             lambda p, d: (0.85 + 0.1 * d.y - 0.2 * smooth(0.97, 1.0, abs(math.cos(math.atan2(p.x, p.z) * 3.0))) * smooth(0.3, 0.8, d.y),) * 3,
             cls=SCALE, bone="body", seg=24, rings=12, tint_fn=lambda p, d: 1.0)
b.ellipsoid(V(0, 0.565, 0.28), (0.04, 0.025, 0.04), (0.6, 0.6, 0.6), cls=SCALE, bone="body", tint=1.0, seg=10, rings=6)
eyes(b, V(0, 0.585, 0.29), 0.035, 0.018, iris="ff4030", bone="body", slit=False, glow=True, rot_y=0.4, h=0.9)
for s in (1, -1):
    for k in range(3):
        b.ball(V((0.17 + 0.025 * k) * s, 0.5, 0.42 - 0.02 * k), 0.012, "ff6040", cls=CRYSTAL, bone="body", mat=MAT_GLOW, seg=6, rings=4)
# mesosoma: seven tergites with a central keel, each overlapping the next
meso = [V(0, 0.44, 0.0)] + [V(0, 0.445 + 0.006 * k, -0.06 - k * 0.075) for k in range(1, 8)]
A.plate_segments(b, meso, [(0.27 - 0.008 * k, 0.1) for k in range(8)], (0.8, 0.8, 0.8), lambda p: "body", n=16, col2=(0.6, 0.6, 0.6), ridge=0.25, cls=SCALE)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# chelicerae and pectines underneath
for s in (1, -1):
    b.ellipsoid(V(0.04 * s, 0.42, 0.46), (0.035, 0.03, 0.05), (0.55, 0.55, 0.55), cls=SCALE, bone="body", tint=1.0, seg=10, rings=6)
    b.cone(V(0.035 * s, 0.4, 0.52), 0.015, 0.05, "201010", cls=STONE, bone="body", rot=(math.pi / 2 + 0.3, 0, 0), seg=6)
    for k in range(8):
        b.tube([V(0.03 * s, 0.35, -0.05 - k * 0.02), V(0.12 * s, 0.33, -0.08 - k * 0.022)], [0.008, 0.003], (0.9, 0.9, 0.9), cls=SCALE, bone="body", tint=0.6, seg=4)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# metasoma: five keeled tail segments, the joints dark, then the bulbous telson with its aculeus
for i in range(5):
    a = TAIL[i]
    c2 = TAIL[i + 1]
    w = 0.12 - i * 0.01
    A.plate_segments(b, [a, a.lerp(c2, 0.5), c2], [(w, w * 0.9), (w * 1.05, w * 0.95), (w * 0.95, w * 0.85)], (0.85, 0.85, 0.85), lambda p, i=i: "tail%d" % i, n=12, col2=(0.6, 0.6, 0.6), ridge=0.3, cls=SCALE)
    b.ellipsoid(a, (w * 0.8, w * 0.8, w * 0.5), (0.4, 0.4, 0.4), cls=SCALE, bone="tail%d" % i, tint=1.0, seg=10, rings=6)
bulb = TAIL[5] + V(0, -0.02, 0.08)
b.ellipsoid(bulb, (0.1, 0.09, 0.13), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="tail4", tint=1.0, mat=MAT_GLOW, seg=14, rings=10)
b.ellipsoid(bulb + V(0, 0.02, 0), (0.105, 0.06, 0.12), (0.7, 0.7, 0.7), cls=SCALE, bone="tail4", tint=1.0, seg=14, rings=8)
sting = [bulb + V(0, -0.05, 0.1), bulb + V(0, -0.12, 0.18), bulb + V(0, -0.22, 0.16), bulb + V(0, -0.27, 0.08)]
strand(b, sting, 0.035, 0.002, "3a2020", col_tip="100808", cls=STONE, bone="tail4", seg=8, per=3)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# pedipalps: femur and patella, then the chela - a swollen hand with fixed and movable fingers
# lined with denticles - and the walking legs, segmented with spurs
for s, sd in ((1, "L"), (-1, "R")):
    a, fo, c = "arm.%s" % sd, "fore.%s" % sd, "claw.%s" % sd
    A.plate_segments(b, [r.head(a), r.head(a).lerp(r.tail(a), 0.5), r.tail(a)], [(0.055, 0.05), (0.06, 0.05), (0.055, 0.05)], (0.8, 0.8, 0.8), lambda p, a=a: a, n=10, ridge=0.2, cls=SCALE)
    A.plate_segments(b, [r.head(fo), r.head(fo).lerp(r.tail(fo), 0.5), r.tail(fo)], [(0.06, 0.055), (0.07, 0.06), (0.065, 0.06)], (0.85, 0.85, 0.85), lambda p, fo=fo: fo, n=10, ridge=0.2, cls=SCALE)
    wr = r.tail(fo)
    hf = A.HeadFrame(wr + V(0.03 * s, 0, 0.12), V(0.05 * s, 0, 1))
    morph_sphere(b, hf.c, lambda d: V(d.x * 0.11, d.y * 0.08, d.z * 0.16) * (1.0 + 0.1 * max(0.0, d.x * s)), lambda p, d: (0.92 + 0.06 * d.y,) * 3, cls=SCALE, bone=c, seg=18, rings=12, tint_fn=lambda p, d: 1.0, rot=hf.M)
    fixed = [wr + V(0.04 * s, 0, 0.24), wr + V(0.045 * s, 0, 0.36), wr + V(0.03 * s, 0, 0.46)]
    strand(b, fixed, 0.04, 0.006, (0.75, 0.75, 0.75), col_tip=(0.3, 0.3, 0.3), cls=SCALE, bone=c, flat=0.7, seg=8, per=3, tint=1.0, up=(0, 1, 0))
    pin = [r.head("pinch.%s" % sd), r.head("pinch.%s" % sd).lerp(r.tail("pinch.%s" % sd), 0.5) + V(-0.02 * s, 0, 0), r.tail("pinch.%s" % sd)]
    strand(b, pin, 0.035, 0.006, (0.75, 0.75, 0.75), col_tip=(0.3, 0.3, 0.3), cls=SCALE, bone="pinch.%s" % sd, flat=0.7, seg=8, per=3, tint=1.0, up=(0, 1, 0))
    for q in range(4):
        b.cone(wr + V(0.0, 0, 0.26 + q * 0.05), 0.008, 0.025, "f0e8d8", cls=STONE, bone=c, seg=5, rot=(0, 0, math.pi / 2 * s))
    for k in range(4):
        lg, sn = "leg%d.%s" % (k, sd), "shin%d.%s" % (k, sd)
        A.plate_segments(b, [r.head(lg), r.head(lg).lerp(r.tail(lg), 0.5) + V(0, 0.02, 0), r.tail(lg)], [0.035, 0.034, 0.03], (0.75, 0.75, 0.75), lambda p, lg=lg: lg, n=8, cls=SCALE)
        b.tube([r.head(sn), r.head(sn).lerp(r.tail(sn), 0.6), r.tail(sn)], [0.03, 0.022, 0.006], (0.6, 0.6, 0.6), cls=SCALE, bones=[{lg: 0.4, sn: 0.6}, sn, sn], tint=1.0, seg=8)
        q = r.head(sn).lerp(r.tail(sn), 0.6)
        b.cone(q + V(0.015 * s, 0, 0), 0.006, 0.03, "201010", cls=STONE, bone=sn, seg=5, rot=(0, 0, -1.2 * s))

T = 2.0
T_WALK = 1.0
PAIRS = [("leg%d.%s" % (k, sd), "shin%d.%s" % (k, sd)) for sd in ("L", "R") for k in range(4)]
WALK = Walker(r, PAIRS, [0.5 * ((k + (0 if sd == "L" else 1)) % 2) for sd in ("L", "R") for k in range(4)], duty=0.58)


def tail_pose(p, t, T_, amp, cock=0.0):
    w = 2 * math.pi / T_
    for i in range(5):
        add(p, "tail%d" % i, (math.sin(t * w - i * 0.6) * 0.05 * amp - cock * 0.12, math.sin(t * w + 1.0 - i * 0.4) * 0.07 * amp, 0))


def claws_pose(p, t, T_, amp=1.0):
    w = 2 * math.pi / T_
    for sd, s_ in (("L", 1), ("R", -1)):
        snap = max(0.0, math.sin(t * w * 2 + (0 if s_ > 0 else 1.5))) ** 6
        add(p, "pinch.%s" % sd, (0, -s_ * 0.35 * (1 - snap) * amp, 0))
        add(p, "arm.%s" % sd, (math.sin(t * w + s_) * 0.06 * amp, s_ * 0.1 * math.sin(t * w + 0.7) * amp, 0))


def idle(t):
    p = zero_pose(r)
    add(p, "body", (0, math.sin(t * 2 * math.pi / (T * 2)) * 0.05, 0), (0, math.sin(t * 2 * math.pi / T) * 0.008, 0))
    tail_pose(p, t, T * 2, 1.0)
    claws_pose(p, t, T * 2)
    return WALK.step(p)


def walk(t):
    p = zero_pose(r)
    ph = (t / T_WALK) % 1.0
    add(p, "body", (0, 0.04 * math.sin(2 * math.pi * ph), 0), (0, 0.01 * abs(math.sin(2 * math.pi * ph * 2)), 0))
    tail_pose(p, t, T_WALK, 0.6)
    claws_pose(p, t, T_WALK, 0.5)
    return WALK.step(p, ph, 0.2, 0.07)


def attack(t):
    """The tail cocks back over the body and stabs forward; the claws pin."""
    k = t / 0.55
    cock = smooth(0.0, 0.3, k) * (1.0 - smooth(0.32, 0.42, k))
    stab = smooth(0.3, 0.42, k) * (1.0 - smooth(0.6, 1.0, k))
    p = zero_pose(r)
    for i in range(5):
        add(p, "tail%d" % i, (-0.12 * cock + 0.28 * stab, 0, 0))
    add(p, "body", (0.12 * stab, 0, 0), (0, 0, 0.2 * stab))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm.%s" % sd, (0, s_ * 0.3 * (cock + stab), 0))
        add(p, "pinch.%s" % sd, (0, -s_ * 0.5 * (cock + stab), 0))
    return WALK.step(p, offsets=[(0.0, 0.0, 0.2 * stab)] * 8)


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    add(p, "body", (-0.2 * e, 0.15 * e, 0), (0, 0.04 * e, -0.15 * e))
    for i in range(5):
        add(p, "tail%d" % i, (-0.12 * e, 0.1 * e, 0))
    return WALK.step(p, offsets=[(0.0, 0.0, -0.15 * e)] * 8)


def die(t):
    k = min(1.0, t / 1.2)
    p = zero_pose(r)
    p = WALK.step(p)
    curl = []
    for a_, b_ in PAIRS:
        sg = 1 if a_.endswith(".L") else -1
        curl.append((a_, (0.0, 0.0, -1.0 * sg)))
        curl.append((b_, (0.0, 0.0, -1.3 * sg)))
    # the tail goes limp and uncurls
    for i in range(5):
        add(p, "tail%d" % i, (0.25 * smooth(0.3, 0.9, k), 0.05 * i * smooth(0.3, 0.9, k), 0))
    flip_die(p, t, 1.2, 0.45, side=1, curl_legs=curl, rest=0.1)
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    add(p, "body", (-0.25 * e, 0, 0), (0, 0.08 * e, 0))
    tail_pose(p, t, 0.6, 1.5)
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm.%s" % sd, (-0.8 * e, -s_ * 0.3 * e, 0))
        add(p, "fore.%s" % sd, (-0.5 * e, 0, 0))
        add(p, "pinch.%s" % sd, (0, -s_ * 0.6 * e, 0))
    return WALK.step(p)


print("[art] scorpion: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/scorpion.glb", {"idle": (T * 2, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=12, dist=0.25, strength=0.5, floor_y=0.0)
