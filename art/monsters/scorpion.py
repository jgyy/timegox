"""Scorpion (new in Part V): the Glass Scorpion King, the Dune and Cracked-Earth Scorpions.

After scorpion anatomy (prosoma, mesosoma, metasoma; Stahnke's nomenclature): a low, flat body.  The
prosoma is a squarish carapace with the median eyes on a tubercle in the middle and a cluster of
lateral eyes at each front corner, small pincer chelicerae before it; the mesosoma is seven broad
tergites shingled one over the next, each with a median keel, the last narrowing into the tail.
The metasoma is five segments of box section with keels (carinae) along their edges, each longer
than the one before, carried in an arch over the back, and the telson: a bulbous vesicle that holds
the venom glands (glowing through in the accent colour) and the hooked aculeus, black at the tip.
The pedipalps end in the chelae: a long squarish femur and patella, then a swollen, granular hand
(the manus) with a fixed finger inside and a movable finger outside that close sideways, lined
with denticles.  Four pairs of legs splay out on femur, patella, tibia and tarsus with paired
claws; the combs of the pectines sit underneath.  Plain-shaded cuticle (no scale grid).
Run: blender --background --python art/monsters/scorpion.py  ->  assets/monsters/scorpion.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import arthropod as X  # noqa: E402
from creature import Walker, add, flip_die, smooth, zero_pose  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, V, Builder, Rig  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
UP = V(0, 1, 0)
BY = 0.3                     # the underside of the body
# the metasoma: five segments, each longer than the last, arching up and over the back
TAIL = [V(0, BY + 0.07, -0.64)]
for ln, deg in ((0.24, 32.0), (0.26, 68.0), (0.28, 104.0), (0.3, 138.0), (0.34, 170.0)):
    a = math.radians(deg)
    TAIL.append(TAIL[-1] + V(0, math.sin(a), -math.cos(a)) * ln)

# ---------------------------------------------------------------- rig
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, BY + 0.05, -0.45), (0, BY + 0.05, 0.35), "root")
r.bone("head", (0, BY + 0.17, 0.2), (0, BY + 0.17, 0.42), "body")
for i in range(5):
    r.bone("tail%d" % i, TAIL[i], TAIL[i + 1], "body" if i == 0 else "tail%d" % (i - 1))
LEGS = []
for s, sd in ((1, "L"), (-1, "R")):
    sh = V(0.13 * s, BY + 0.06, 0.38)
    el = V(0.34 * s, BY + 0.14, 0.47)
    wr = V(0.38 * s, BY + 0.12, 0.64)
    tip = wr + V(-0.1 * s, -0.02, 0.52)
    r.bone("arm.%s" % sd, sh, el, "body")
    r.bone("fore.%s" % sd, el, wr, "arm.%s" % sd)
    r.bone("claw.%s" % sd, wr, tip, "fore.%s" % sd)
    hinge = wr + V(0.04 * s, 0.0, 0.3)
    r.bone("pinch.%s" % sd, hinge, hinge + V(-0.06 * s, 0.0, 0.22), "fore.%s" % sd)
    for k, (z, deg, ln) in enumerate(((0.22, 58.0, 0.92), (0.1, 82.0, 0.98), (-0.03, 108.0, 1.02), (-0.16, 132.0, 1.08))):
        a = math.radians(deg)
        out = V(math.sin(a) * s, 0.0, math.cos(a))
        hip = V(0.16 * s, BY + 0.02, z)
        fe = hip + out * (0.04 + 0.17 * ln) + UP * (0.12 * ln)          # femur up to the knee
        pa = fe + out * (0.07 * ln) - UP * (0.01 * ln)                  # patella over it
        ti = pa + out * (0.12 * ln) - UP * (0.16 * ln)                  # tibia down
        ft = V(ti.x + out.x * 0.13 * ln, 0.012, ti.z + out.z * 0.13 * ln)   # tarsi to the ground, raked out
        r.bone("leg%d.%s" % (k, sd), hip, fe, "body")
        r.bone("shin%d.%s" % (k, sd), fe, ft, "leg%d.%s" % (k, sd))
        LEGS.append((k, sd, s, out, ln, [hip, fe, pa, ti, ft]))

b = Builder("scorpion")

# ---------------------------------------------------------------- prosoma: the carapace shield
CAR = [(0.0, 0.24), (0.1, 0.235), (0.16, 0.2), (0.22, 0.05), (0.24, -0.1), (0.2, -0.16), (0.0, -0.17)]
CR = X.outline_radius(CAR[:-1] + [(-x, z) for x, z in reversed(CAR[1:])])
CC = V(0, BY + 0.08, 0.22)


def car_off(th, ph, p):
    if ph < 0.0:
        return 0.0
    x, z = p.x, p.z
    off = 0.016 * math.exp(-((x / 0.05) ** 2 + ((z - 0.0) / 0.06) ** 2))         # the eye tubercle
    off -= 0.008 * math.exp(-((x / 0.012) ** 2)) * smooth(-0.05, -0.15, z)        # median furrow behind it
    for s in (1, -1):
        off -= 0.006 * math.exp(-(((x - 0.13 * s) / 0.02) ** 2)) * smooth(0.1, -0.1, z)
    return off


def car_col(th, ph, p):
    if ph < 0.0:
        return X.grey(0.9)
    x, z = p.x, p.z
    v = 0.8 + 0.05 * smooth(0.0, 0.8, ph)
    v *= 1.0 - 0.25 * math.exp(-((x / 0.014) ** 2)) * smooth(-0.05, -0.15, z)
    for s in (1, -1):
        v *= 1.0 - 0.2 * math.exp(-(((x - 0.13 * s) / 0.018) ** 2)) * smooth(0.1, -0.1, z)
    v *= 0.94 + 0.12 * fbm3((p.x * 26.0, p.y * 26.0, p.z * 26.0), 2, 5)      # granules
    v *= 1.0 - 0.2 * smooth(0.2, 0.0, ph)                                     # the rim
    return X.grey(min(1.0, v))


X.shield(b, CC, CR, 0.075, 0.06, "body", car_col, dome=2.6, offset=car_off, seg=64, rings=24)
for s in (1, -1):
    X.bead_eye(b, CC + V(0.025 * s, 0.085, 0.0), 0.02, "head", fwd=V(0.6 * s, 0.6, 0.4).normalized(), col="120c10")
    for k in range(3):
        X.bead_eye(b, CC + V((0.15 + 0.025 * k) * s, 0.035, 0.17 - 0.02 * k), 0.011, "head", fwd=V(0.8 * s, 0.3, 0.5).normalized(), col="120c10",
                   glint=False)

# ---------------------------------------------------------------- mesosoma: seven shingled tergites
for k in range(7):
    z0 = 0.06 - k * 0.1
    w = 0.25 + 0.02 * math.sin(math.pi * (k + 0.5) / 6.0) - (0.045 * (k - 4.5) if k > 4 else 0.0)
    X.segment(b, V(0, BY + 0.085 + 0.004 * k, z0 + 0.03), V(0, BY + 0.08 + 0.004 * k, z0 - 0.115), w, 0.07, bone="body", up=UP, neck=0.08, neck_len=0.25,
              swell=0.04, taper=0.04 if k < 6 else 0.35, rim=0.1, keels=((0.0, 0.18), (0.6, 0.04), (-0.6, 0.04)), flat=0.5, flat_top=0.25, col=0.8,
              back=0.06, belly=0.3, joint=0.4, n=26, rings=8)
# the sternites underneath and the pectines, two combs behind the last legs
X.segment(b, V(0, BY + 0.03, 0.1), V(0, BY + 0.03, -0.62), 0.2, 0.04, bone="body", up=UP, neck=0.0, swell=0.05, taper=0.3, rim=0.0, col=0.9, belly=0.0,
          joint=0.1, n=18, rings=8)
b.cur_pal = 0.5
for s in (1, -1):
    for k in range(8):
        base = V(0.03 * s, BY + 0.005, -0.12 - k * 0.02)
        X.spine(b, base, V(0.9 * s, -0.15, -0.2), 0.08 - k * 0.004, 0.008, "body", col0=0.9, col1=0.75)
b.cur_pal = 0.0

# ---------------------------------------------------------------- metasoma and telson
for i in range(5):
    a, c = TAIL[i], TAIL[i + 1]
    d = (c - a).normalized()
    side = V(1, 0, 0)
    up_t = side.cross(d).normalized()          # the segment's back: away from the arch's inside
    w = 0.088 - 0.006 * i
    X.segment(b, a - d * 0.03, c, w, w * 0.92, bone="tail%d" % i, up=up_t, neck=0.25, neck_len=0.16, swell=0.06 + 0.03 * i, swell_at=0.6, taper=-0.05,
              rim=0.08, square=0.45, keels=((0.75, 0.07), (-0.75, 0.07), (math.pi * 0.5, 0.05), (-math.pi * 0.5, 0.05), (math.pi, 0.04)),
              col=0.8 - 0.04 * (i == 4), back=0.06, belly=0.2, joint=0.5, n=20, rings=10)
end = TAIL[5]
dE = (TAIL[5] - TAIL[4]).normalized()
upE = V(1, 0, 0).cross(dE).normalized()
ves = end + dE * 0.1 - upE * 0.02
# the vesicle: a smooth bulb, the venom glowing through its lower half
X.segment(b, end - dE * 0.03, ves + dE * 0.11, 0.085, 0.08, bone="tail4", up=upE, neck=0.35, neck_len=0.2, swell=0.25, swell_at=0.45, taper=0.55, rim=0.0,
          col=0.82, back=0.08, belly=0.1, joint=0.3, n=20, rings=12, cap1=0.5)
b.cur_pal = 1.0
b.ellipsoid(ves - upE * 0.045 + dE * 0.01, (0.06, 0.04, 0.075), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="tail4", tint=1.0, mat=MAT_GLOW, seg=14, rings=8,
            rot=creature.euler_yxz(X.rot_to(dE, upE)))
b.cur_pal = 0.0
# the aculeus curves towards the tail's back, so with the tail over the body it hooks down and forward
st0 = ves + dE * 0.1
X.finger(b, [st0, st0 + dE * 0.07 + upE * 0.03, st0 + dE * 0.08 + upE * 0.12, st0 + dE * 0.01 + upE * 0.19], 0.03, 0.032, "tail4", up=dE,
         col0=0.55, col1=0.04, tip_from=0.25, tint_tip=0.0, n=12, power=1.4)

# ---------------------------------------------------------------- chelicerae
b.cur_pal = 0.5
for s in (1, -1):
    c0 = V(0.04 * s, BY + 0.08, 0.44)
    X.segment(b, c0, c0 + V(0.0, -0.01, 0.08), 0.032, 0.026, bone="head", up=UP, neck=0.1, swell=0.15, taper=0.2, rim=0.0, col=0.78, joint=0.2, n=12, rings=6)
    X.finger(b, [c0 + V(0, -0.005, 0.07), c0 + V(-0.01 * s, -0.012, 0.11), c0 + V(-0.025 * s, -0.02, 0.13)], 0.012, 0.012, "head", up=UP, col0=0.5, col1=0.08,
             tip_from=0.2, tint_tip=0.0, n=8)
b.cur_pal = 0.0

# ---------------------------------------------------------------- pedipalps and chelae
for s, sd in ((1, "L"), (-1, "R")):
    a_, f_, c_, p_ = "arm." + sd, "fore." + sd, "claw." + sd, "pinch." + sd
    sh, el, wr = r.head(a_), r.tail(a_), r.tail(f_)
    out = V(s, 0.0, 0.4).normalized()
    X.segment(b, sh - (el - sh).normalized() * 0.05, el, 0.04, 0.036, bone=a_, up=UP, neck=0.2, swell=0.05, taper=0.0, rim=0.1, square=0.4,
              keels=((0.78, 0.06), (-0.78, 0.06)), col=0.8, back=0.06, belly=0.25, joint=0.45, n=16, rings=8)
    X.segment(b, el - (wr - el).normalized() * 0.03, wr, 0.046, 0.04, bone=f_, up=UP, neck=0.28, swell=0.12, taper=-0.05, rim=0.1, square=0.3,
              keels=((0.78, 0.06), (-0.78, 0.06)), col=0.8, back=0.06, belly=0.25, joint=0.45, n=16, rings=8)
    # the manus: a swollen, granular hand, flattened top to bottom
    hd = (r.tail(c_) - wr).normalized()
    m0 = wr - hd * 0.03
    m1 = wr + hd * 0.31
    X.segment(b, m0, m1, 0.1, 0.07, bone=c_, up=UP, neck=0.5, neck_len=0.3, swell=0.22, swell_at=0.55, taper=0.2, rim=0.0, keels=((0.0, 0.05),),
              col=0.8, back=0.07, belly=0.25, joint=0.35, n=24, rings=14, cap1=0.5)
    side_in = V(-s, 0.0, 0.0)
    for q in range(5):
        pq = wr.lerp(m1, 0.2 + 0.15 * q) + UP * 0.07 + side_in * (0.024 * (q % 2) - 0.012)
        b.ellipsoid(pq, (0.009, 0.007, 0.011), X.grey(0.58), cls=X.CHITIN, bone=c_, tint=1.0, seg=8, rings=5)
    # the fixed finger runs on from the inner edge, the movable finger is hinged on the outer edge;
    # they close sideways and are toothed along the bite
    fx0 = m1 + side_in * 0.045 - hd * 0.05
    ftip = m1 + hd * 0.22 + side_in * 0.0
    X.finger(b, [fx0, fx0 + hd * 0.1 - side_in * 0.005, fx0 + hd * 0.19 - side_in * 0.012, ftip], 0.03, 0.026, c_, up=UP, col0=0.78, col1=0.06, tip_from=0.45,
             tint_tip=0.0, n=12, teeth=6, teeth_side=-side_in, teeth_len=0.012)
    hg = r.head(p_)
    X.finger(b, [hg - hd * 0.04, hg + hd * 0.09 + side_in * 0.006, hg + hd * 0.17 + side_in * 0.02, ftip - side_in * 0.012 + hd * 0.006], 0.028, 0.025, p_,
             up=UP, col0=0.78, col1=0.06, tip_from=0.45, tint_tip=0.0, n=12, teeth=6, teeth_side=side_in, teeth_len=0.012)

# ---------------------------------------------------------------- legs
for k, sd, s, out, ln, J in LEGS:
    hip, fe, pa, ti, ft = J
    lg, sn = "leg%d.%s" % (k, sd), "shin%d.%s" % (k, sd)
    X.limb(b, [hip, fe, pa, ti], [0.04, 0.036, 0.031], [lg, sn, sn], out=out, neck=0.3, swell=0.06, taper=0.12, rim=0.1,
           keels=((math.pi * 0.5, 0.06), (-math.pi * 0.5, 0.06)), col=0.8, back=0.06, belly=0.3, joint=0.45, n=12, rings=8)
    dd = (ft - ti).normalized()
    X.finger(b, [ti - dd * 0.012, ti.lerp(ft, 0.55) + out * 0.01, ft], 0.023, 0.023, sn, up=out, col0=0.78, col1=0.12, tip_from=0.55, tint_tip=0.3, n=10,
             power=1.6)
    X.spine(b, pa + out * 0.01 - UP * 0.02, out * 0.6 - UP * 0.8, 0.035, 0.006, sn, col0=0.5, col1=0.2)

# ---------------------------------------------------------------- motion
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
        add(p, "pinch.%s" % sd, (0, s_ * 0.3 * (1 - snap) * amp, 0))
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
        add(p, "pinch.%s" % sd, (0, s_ * 0.5 * (cock + stab), 0))
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
        add(p, "tail%d" % i, (0.32 * smooth(0.3, 0.9, k), 0.05 * i * smooth(0.3, 0.9, k), 0))
    flip_die(p, t, 1.2, BY + 0.06, side=1, curl_legs=curl, rest=0.12)
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    add(p, "body", (-0.25 * e, 0, 0), (0, 0.08 * e, 0))
    tail_pose(p, t, 0.6, 1.5)
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm.%s" % sd, (-0.8 * e, -s_ * 0.3 * e, 0))
        add(p, "fore.%s" % sd, (-0.5 * e, 0, 0))
        add(p, "pinch.%s" % sd, (0, s_ * 0.6 * e, 0))
    return WALK.step(p)


print("[art] scorpion: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/scorpion.glb", {"idle": (T * 2, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=12, dist=0.25, strength=0.5, floor_y=0.0)
