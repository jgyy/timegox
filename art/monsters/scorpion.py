"""Scorpion (new in Part V): the Glass Scorpion King and the Dune Stalker.  Every sclerite is its
own sculpted barrel turned onto its joint axis, keeled and paler on the back, dark where it meets
the next: a broad flat carapace with a median eye tubercle and lateral eyes, seven roof-tiled
tergites with a median keel, little chelicerae, a metasoma of five keeled segments growing
longer towards a bulbous telson whose venom gland glows through, and a hooked aculeus; pedipalps
ending in big swollen chelae with a fixed and a hinged finger lined with denticles; eight legs of
femur, tibia and tarsus with spurs and paired claws; pectines underneath.
Run: blender --background --python art/monsters/scorpion.py  ->  assets/monsters/scorpion.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import Walker, add, eyes, flip_die, smooth, zero_pose  # noqa: E402
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
# prosoma: a broad, flat carapace shield with a median eye tubercle and lateral eyes at the front
A.sclerite(b, V(0, 0.45, -0.02), V(0, 0.47, 0.46), 0.29, 0.11, "body", col=0.9, keels=1, ridge=0.25, belly=0.45, blunt=0.3, seg=24, rings=12)
b.ellipsoid(V(0, 0.575, 0.28), (0.045, 0.028, 0.045), (0.6, 0.6, 0.6), cls=SCALE, bone="body", tint=1.0, seg=10, rings=6)
eyes(b, V(0, 0.595, 0.29), 0.035, 0.018, iris="ff4030", bone="body", slit=False, glow=True, rot_y=0.4, h=0.9)
for s in (1, -1):
    for k in range(3):
        b.ball(V((0.18 + 0.025 * k) * s, 0.51, 0.42 - 0.02 * k), 0.013, "ff6040", cls=CRYSTAL, bone="body", mat=MAT_GLOW, seg=6, rings=4)
# mesosoma: seven broad tergites, each with a median keel, overlapping the next like roof tiles
for k in range(7):
    z0 = 0.0 - k * 0.075
    wk = 0.3 - 0.004 * k - (0.03 * (k - 4) if k > 4 else 0.0)
    A.sclerite(b, V(0, 0.455 + 0.004 * k, z0 + 0.03), V(0, 0.45 + 0.004 * k, z0 - 0.1), wk, 0.12, "body", col=0.86, keels=1, ridge=0.2, belly=0.3, blunt=0.35, seg=22, rings=8)
# chelicerae: two little pincer jaws in front of the carapace
b.cur_pal = 0.5
for s in (1, -1):
    A.sclerite(b, V(0.045 * s, 0.43, 0.43), V(0.04 * s, 0.42, 0.53), 0.035, 0.03, "body", col=0.75, seg=10, rings=6)
    A.claw(b, V(0.035 * s, 0.415, 0.53), V(-0.3 * s, -0.3, 1.0), 0.05, 0.012, "body", hook=0.5, col0="402020", col1="100808")
b.cur_pal = 0.0
# metasoma: five keeled tail segments, each longer than the last, with dark joints; then the
# bulbous telson, its venom gland glowing through, and the hooked aculeus
for i in range(5):
    a, c2 = TAIL[i], TAIL[i + 1]
    w = 0.11 - i * 0.006
    A.sclerite(b, a - (c2 - a) * 0.06, c2 + (c2 - a) * 0.04, w, w * 0.92, "tail%d" % i, col=0.88, keels=4, phase=math.pi / 4, ridge=0.16, seg=18, rings=10, joint=0.45,
            up=(c2 - a).normalized().cross(V(1, 0, 0)))
bulb = TAIL[5] + V(0, -0.02, 0.09)
b.cur_pal = 1.0  # the venom gland glows through in the accent colour: a warning
b.ellipsoid(bulb, (0.1, 0.09, 0.13), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="tail4", tint=1.0, mat=MAT_GLOW, seg=14, rings=10)
b.cur_pal = 0.0
A.sclerite(b, bulb - V(0, -0.03, 0.12), bulb + V(0, -0.02, 0.12), 0.105, 0.075, "tail4", col=0.82, keels=0, belly=0.6, blunt=0.5, seg=18, rings=10, joint=0.2)
A.horn(b, [bulb + V(0, -0.04, 0.1), bulb + V(0, -0.1, 0.19), bulb + V(0, -0.2, 0.2), bulb + V(0, -0.27, 0.13)], 0.034, "5a2020", "0a0606", "tail4", r1=0.002, cls=STONE, seg=10)
# pedipalps: femur and patella, then the chela - a big swollen hand with a fixed finger and a
# hinged one, both lined with pale denticles
for s, sd in ((1, "L"), (-1, "R")):
    a, fo, cl, pn = "arm." + sd, "fore." + sd, "claw." + sd, "pinch." + sd
    A.sclerite(b, r.head(a), r.tail(a), 0.055, 0.05, a, col=0.85, keels=4, phase=math.pi / 4, seg=14, rings=8)
    A.sclerite(b, r.head(fo), r.tail(fo), 0.065, 0.058, fo, col=0.88, keels=4, phase=math.pi / 4, seg=14, rings=8)
    wr = r.tail(fo)
    A.sclerite(b, wr - V(0.0, 0, 0.03), wr + V(0.025 * s, 0, 0.27), 0.12, 0.09, cl, col=0.9, keels=2, phase=0.0, ridge=0.1, blunt=0.45, seg=22, rings=12, joint=0.25)
    fixed = [wr + V(0.05 * s, 0.0, 0.24), wr + V(0.055 * s, 0.0, 0.37), wr + V(0.035 * s, -0.005, 0.49), wr + V(0.0, -0.01, 0.55)]
    A.horn(b, fixed, 0.04, (0.8, 0.8, 0.8), (0.2, 0.2, 0.2), cl, r1=0.004, cls=SCALE, seg=10, flat=0.65, up=(0, 1, 0), tint=1.0)
    pin0 = r.head(pn)
    mov = [pin0 + V(0.0, 0.0, 0.2), pin0 + V(-0.01 * s, 0.0, 0.33), pin0 + V(0.005 * s, -0.005, 0.45), pin0 + V(0.035 * s, -0.01, 0.51)]
    A.horn(b, mov, 0.036, (0.8, 0.8, 0.8), (0.2, 0.2, 0.2), pn, r1=0.004, cls=SCALE, seg=10, flat=0.65, up=(0, 1, 0), tint=1.0)
    for q in range(5):
        b.cone(wr + V(0.02 * s, 0, 0.3 + q * 0.04), 0.007, 0.022, "f0e8d8", cls=STONE, bone=cl, seg=5, rot=(0, 0, -math.pi / 2 * s))
    # eight legs: femur, tibia and tarsus, a spur at each joint and a pair of hooked claws
    for k in range(4):
        lg, sn = "leg%d.%s" % (k, sd), "shin%d.%s" % (k, sd)
        hip, kn, ft = r.head(lg), r.tail(lg), r.tail(sn)
        mid = kn.lerp(ft, 0.55)
        A.sclerite(b, hip, kn, 0.036, 0.034, lg, col=0.82, keels=2, phase=math.pi / 2, seg=12, rings=8)
        A.sclerite(b, kn, mid, 0.03, 0.028, sn, col=0.84, seg=12, rings=8)
        A.sclerite(b, mid, ft + V(0, 0.02, 0), 0.022, 0.02, sn, col=0.8, seg=10, rings=6, taper=0.3)
        b.cone(kn + V(0.015 * s, -0.01, 0), 0.007, 0.035, "201010", cls=STONE, bone=lg, seg=5, rot=(0, 0, -1.2 * s))
        A.claw(b, ft + V(0, 0.02, 0), V(0.4 * s, -0.6, 0.6), 0.04, 0.01, sn, hook=0.6, col0="402020", col1="100808")
# pectines: two little combs underneath
b.cur_pal = 0.5
for s in (1, -1):
    for k in range(7):
        b.tube([V(0.03 * s, 0.37, -0.06 - k * 0.022), V(0.12 * s, 0.35, -0.09 - k * 0.024)], [0.008, 0.003], (0.9, 0.9, 0.9), cls=SCALE, bone="body", tint=0.6, seg=4)
b.cur_pal = 0.0


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
