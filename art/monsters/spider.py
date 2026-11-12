"""Spider: the eight-legged hunters (Rift Spider, Root Crawler, the Spider in the Village Well, the
Thread Matron, Madam Qianxian) and, recoloured brass, the Brass Spider Engine of Heaven's Forge.

After spider anatomy (a hunting spider, the wolf-spider and tarantula build): two body parts on a
narrow pedicel - a cephalothorax whose carapace is a low oval shield, raised over the head, with a
central fovea and grooves radiating from it towards the legs, and a bigger egg-shaped abdomen with
a dark cardiac mark and chevrons (the folium) down its back over paler flanks, spinnerets at its
tip.  Eight eyes in three rows: four small ones across the front, the two big posterior medians
above them looking forward, and two more on top looking out; all glow in the accent colour.  Big
bulbous chelicerae hang in front of the mouth with their dark fangs folded under, and the
pedipalps reach forward like short legs.  Each leg has its seven segments - coxa, trochanter, a
long femur that climbs steeply to the knee, the short patella over it, the tibia and the
metatarsus that fall away to the ground and a short tarsus with two claws - each a stiff tube with
pale bands at the joints and rows of stiff setae; the knees stand well above the body.
Clips: idle (breathes over planted feet, a foreleg taps), walk (alternating tetrapods), attack
(rears, then strikes with the fangs), hurt, die (rolls onto its back and curls its legs), cast
(rears and lifts the abdomen to spin).
Run: blender --background --python art/monsters/spider.py  ->  assets/monsters/spider.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import arthropod as X  # noqa: E402
from creature import Walker, add, flip_die, smooth, zero_pose  # noqa: E402
from kit import CLOTH, V, Builder, Rig  # noqa: E402
from sculpt import fbm3, morph_sphere  # noqa: E402

kit.reset()
creature.realtime()
BY = 0.5                     # the cephalothorax
UP = V(0, 1, 0)
TC = V(0, BY, 0.08)          # carapace centre
AC = V(0, BY + 0.14, -0.55)  # abdomen centre
AR = (0.31, 0.27, 0.4)       # abdomen radii


def ang_dir(out, deg):
    a = math.radians(deg)
    return out * math.cos(a) + UP * math.sin(a)


# ---------------------------------------------------------------- rig
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("thorax", (0, BY, -0.12), (0, BY, 0.3), "root")
r.bone("abdomen", (0, BY + 0.04, -0.16), AC + V(0, 0.0, -0.3), "thorax")
r.bone("head", (0, BY + 0.08, 0.14), (0, BY + 0.08, 0.3), "thorax")
r.bone("fangs", (0, BY - 0.0, 0.25), (0, BY - 0.16, 0.33), "head")
LEGS = []
# leg I points forward, II out, III out and back, IV back; IV and I are the longest
SPEC = ((38.0, 1.0, 0.2), (68.0, 0.92, 0.12), (108.0, 0.84, 0.04), (142.0, 0.98, -0.04))
for s, sd in ((1, "L"), (-1, "R")):
    for k, (deg, ln, z) in enumerate(SPEC):
        a = math.radians(deg)
        out = V(math.sin(a) * s, 0.0, math.cos(a))
        hip = V(0.12 * s, BY - 0.03, z) + out * 0.04
        c1 = hip + out * 0.05 - UP * 0.01                  # coxa
        t1 = c1 + out * 0.03                               # trochanter
        f1 = t1 + ang_dir(out, 56.0) * (0.42 * ln)         # femur: up to the knee
        p1 = f1 + ang_dir(out, -8.0) * (0.11 * ln)         # patella: over the knee
        ti = p1 + ang_dir(out, -52.0) * (0.37 * ln)        # tibia
        m1 = ti + ang_dir(out, -70.0) * (0.31 * ln)        # metatarsus
        ft = V(m1.x + out.x * 0.1 * ln, 0.012, m1.z + out.z * 0.1 * ln)   # tarsus to the ground
        nm = "leg%d.%s" % (k, sd)
        r.bone(nm + "_a", hip, f1, "thorax")
        r.bone(nm + "_b", f1, ft, nm + "_a")
        LEGS.append((nm + "_a", nm + "_b", [hip, c1, t1, f1, p1, ti, m1, ft], out, ln, s, k))
    r.bone("palp." + sd, (0.07 * s, BY - 0.04, 0.27), (0.14 * s, BY - 0.12, 0.5), "thorax")

b = Builder("spider")


# ---------------------------------------------------------------- abdomen
def abd_shape(d):
    p = V(d.x * AR[0], d.y * AR[1], d.z * AR[2])
    # egg-shaped: fuller behind the middle, narrowing to the spinnerets, flatter underneath
    p.x *= 1.0 + 0.08 * smooth(0.6, -0.4, d.z) - 0.18 * smooth(-0.55, -1.0, d.z)
    p.y *= (1.0 + 0.06 * smooth(0.6, -0.4, d.z) - 0.2 * smooth(-0.55, -1.0, d.z)) * (0.86 if d.y < 0 else 1.0)
    # a soft pile of hair: very fine, so the silhouette stays smooth
    p *= 1.0 + 0.012 * (fbm3((d.x * 9.0, d.y * 9.0, d.z * 9.0), 2, 11) - 0.5)
    return p


def abd_col(lp, d):
    x, y, z = d.x, d.y, d.z
    v = 0.76 + 0.2 * smooth(-0.05, -0.65, y)               # pale flanks and belly
    if y > -0.15:
        u = (z + 1.0) * 0.5                                  # 0 at the spinnerets, 1 at the pedicel
        ax = abs(x)
        # the cardiac mark: a dark lance down the front half of the back
        lance = smooth(0.13, 0.07, ax - 0.06 * smooth(0.95, 0.55, u)) * smooth(0.48, 0.62, u) * smooth(0.98, 0.9, u)
        # chevrons (the folium) down the back half, pale-edged
        ch = (u * 6.0 + ax * 3.2) % 1.0
        chev = smooth(0.32, 0.18, abs(ch - 0.5)) * smooth(0.38, 0.3, ax) * smooth(0.6, 0.48, u) * smooth(0.05, 0.15, u)
        edge = smooth(0.12, 0.04, abs(ch - 0.22)) * smooth(0.38, 0.3, ax) * smooth(0.6, 0.48, u) * smooth(0.05, 0.15, u)
        side = smooth(0.55, 0.68, ax) * smooth(0.3, 0.12, y) * smooth(-0.1, 0.05, y)    # a pale stripe down each flank
        band = smooth(0.7, 0.8, ax) * smooth(0.05, -0.05, y) * smooth(-0.3, -0.12, y)   # and a dark one under it
        v = v * (1.0 - 0.45 * max(lance, chev)) + 0.26 * edge * (1.0 - lance) + 0.2 * side
        v *= 1.0 - 0.3 * band
    v *= 0.93 + 0.14 * fbm3((d.x * 14.0, d.y * 14.0, d.z * 5.0), 2, 8)   # hair streaks
    return X.grey(min(1.0, v))


morph_sphere(b, AC, abd_shape, abd_col, cls=CLOTH, bone="abdomen", seg=44, rings=30, tint_fn=lambda lp, d: 1.0)
# setae: stiff hairs raked back over the abdomen, so it has a bristly outline, not a glossy ball
GOLD = math.pi * (3.0 - math.sqrt(5.0))
for k in range(150):
    yy = 1.0 - 2.0 * (k + 0.5) / 150
    rr = math.sqrt(max(0.0, 1.0 - yy * yy))
    d = V(math.cos(GOLD * k) * rr, yy, math.sin(GOLD * k) * rr)
    if d.y < -0.45 or d.z > 0.85:
        continue
    root = AC + abd_shape(d) * 0.985
    nrm = V(d.x / AR[0], d.y / AR[1], d.z / AR[2]).normalized()
    rake = (nrm - V(0, 0, 1) * 1.3 + V(0, -0.2, 0)).normalized()
    X.spine(b, root, rake, 0.05 + 0.025 * ((k * 7) % 5) / 4.0, 0.006, "abdomen", col0=0.62, col1=0.85, seg=5, cls=CLOTH)
# spinnerets at the tip and the pedicel, the narrow waist
for s2, ln in ((1, 0.07), (-1, 0.07), (0, 0.08)):
    base = AC + V(0.03 * s2, -0.1, -AR[2] * 0.92)
    X.segment(b, base, base + V(0.02 * s2, -0.04, -ln), 0.022, 0.022, bone="abdomen", up=UP, neck=0.1, taper=0.5, rim=0.0, col=0.6, joint=0.2, n=10, rings=5)
X.segment(b, V(0, BY + 0.01, -0.1), V(0, BY + 0.06, -0.2), 0.055, 0.05, bone=lambda p: {"thorax": 0.5, "abdomen": 0.5}, up=UP, neck=0.0, swell=-0.15,
          taper=0.0, rim=0.0, col=0.6, joint=0.0, n=12, rings=5)

# ---------------------------------------------------------------- cephalothorax
OUT_C = [(0.0, 0.25), (0.08, 0.235), (0.14, 0.18), (0.19, 0.08), (0.2, -0.02), (0.17, -0.12), (0.1, -0.19), (0.0, -0.21)]
OUTLINE = OUT_C[:-1] + [(-x, z) for x, z in reversed(OUT_C[1:])]
CR = X.outline_radius(OUTLINE)


def ceph_offset(th, ph, p):
    if ph < 0.0:
        return 0.0
    x, z = p.x, p.z
    # the head region rises in front; the fovea dips behind the middle; grooves radiate from it
    off = 0.045 * math.exp(-((x / 0.11) ** 2 + ((z - 0.14) / 0.1) ** 2))
    off -= 0.012 * math.exp(-((x / 0.012) ** 2 + ((z + 0.05) / 0.03) ** 2))
    a = math.atan2(x, z + 0.05)
    rad = math.hypot(x, z + 0.05)
    off -= 0.005 * smooth(0.9, 1.0, abs(math.cos(a * 4.0 + 0.4))) * smooth(0.04, 0.09, rad) * smooth(0.6, 0.2, ph)
    return off


def ceph_col(th, ph, p):
    if ph < 0.0:
        return X.grey(0.82 + 0.12 * smooth(-0.4, -1.2, ph))       # the sternum is pale
    x, z = p.x, p.z
    a = math.atan2(x, z + 0.05)
    rad = math.hypot(x, z + 0.05)
    v = 0.74
    v *= 1.0 - 0.3 * smooth(0.9, 1.0, abs(math.cos(a * 4.0 + 0.4))) * smooth(0.04, 0.09, rad) * smooth(0.6, 0.2, ph)
    v *= 1.0 - 0.4 * math.exp(-((x / 0.014) ** 2 + ((z + 0.05) / 0.035) ** 2))
    # a pale median band and pale margins, dark between (a wolf spider's carapace), the face dark
    v += 0.16 * smooth(0.05, 0.02, abs(x)) * smooth(-0.2, -0.05, z) * smooth(0.25, 0.45, ph) * smooth(0.12, 0.0, z)
    v += 0.12 * smooth(0.3, 0.1, ph) * smooth(0.7, 1.1, abs(th))
    v *= 0.94 + 0.12 * fbm3((p.x * 22.0, p.y * 22.0, p.z * 22.0), 2, 3)
    return X.grey(min(1.0, v))


X.shield(b, TC, CR, 0.09, 0.08, "thorax", ceph_col, dome=2.2, offset=ceph_offset, seg=72, rings=28)

# ---------------------------------------------------------------- eyes, chelicerae, pedipalps
EYES = []
for s in (1, -1):
    EYES.append((V(0.022 * s, BY + 0.115, 0.3), 0.014, V(0.2 * s, 0.1, 1.0)))        # anterior medians
    EYES.append((V(0.055 * s, BY + 0.105, 0.29), 0.012, V(0.6 * s, 0.0, 1.0)))       # anterior laterals
    EYES.append((V(0.04 * s, BY + 0.155, 0.255), 0.034, V(0.15 * s, 0.25, 1.0)))     # the big posterior medians
    EYES.append((V(0.075 * s, BY + 0.15, 0.17), 0.024, V(0.8 * s, 0.6, -0.1)))       # posterior laterals, looking out
for c, rr, f in EYES:
    X.bead_eye(b, c, rr, "head", fwd=f.normalized(), col="140e16")
for s in (1, -1):
    # the chelicerae: bulbous, hairy in front, dark fangs folded under them
    top = V(0.045 * s, BY + 0.06, 0.25)
    low = V(0.05 * s, BY - 0.12, 0.33)
    X.segment(b, top, low, 0.05, 0.056, bone="fangs", up=V(0, 0.3, 1.0), neck=0.15, swell=0.28, swell_at=0.4, taper=0.35, rim=0.0, col=0.7, back=0.14,
              joint=0.2, n=16, rings=10)
    X.finger(b, [low + V(0.0, 0.02, 0.0), low + V(-0.012 * s, -0.03, 0.015), low + V(-0.03 * s, -0.055, -0.0), low + V(-0.045 * s, -0.06, -0.03)], 0.014,
             0.016, "fangs", up=(0, 0, 1), col0=0.25, col1=0.06, tint=1.0, tint_tip=0.0, tip_from=0.2, n=10)
    X.spine_row(b, top + V(0.0, -0.02, 0.05), low + V(0.0, 0.02, 0.04), V(0.2 * s, 0.0, 1.0), 4, 0.04, 0.005, "fangs", t0=0.1, t1=0.8, rake=-0.4,
                col0=0.5, col1=0.3)
for s, sd in ((1, "L"), (-1, "R")):
    pa = "palp." + sd
    p0, p1 = r.head(pa), r.tail(pa)
    out = V(0.45 * s, 0.0, 1.0).normalized()
    j = [p0, p0 + V(0.035 * s, 0.07, 0.07), p0 + V(0.06 * s, 0.07, 0.13), p0 + V(0.08 * s, -0.02, 0.2), p1]
    X.limb(b, j, [0.028, 0.026, 0.024, 0.022], [pa] * 4, out=out, neck=0.25, swell=0.06, taper=0.1, rim=0.08, col=0.72, joint=0.4, n=12, rings=6)


# ---------------------------------------------------------------- legs
def banded(col, band=0.18):
    """Leg colour: the segment's own grey, a pale band at its far joint, dark membrane at its near
    one, paler underneath."""

    def f(t, ang):
        cy = math.cos(ang)
        v = col * (1.0 + 0.05 * smooth(0.2, 0.9, cy))
        v += band * smooth(0.8, 0.92, t)
        v = v + (0.94 - v) * 0.25 * smooth(-0.3, -0.9, cy)
        v *= 1.0 - 0.45 * (1.0 - smooth(0.0, 0.12, t))
        return X.grey(min(1.0, v))

    return f


for a_, b_, J, out, ln, s, k in LEGS:
    hip, c1, t1, f1, p1, ti, m1, ft = J
    th = 0.9 + 0.1 * ln + (0.08 if k == 0 else 0.0)
    widths = [0.04 * th, 0.035 * th, 0.042 * th, 0.038 * th, 0.033 * th, 0.025 * th]
    styles = [dict(col_fn=banded(0.6, 0.1), neck=0.0, swell=0.1),
              dict(col_fn=banded(0.62, 0.12)),
              dict(col_fn=banded(0.66), swell=0.1, swell_at=0.35, taper=0.18, keels=((0.0, 0.08),)),
              dict(col_fn=banded(0.6, 0.22), swell=0.16, taper=0.0),
              dict(col_fn=banded(0.66), taper=0.18),
              dict(col_fn=banded(0.68, 0.12), taper=0.25)]
    X.limb(b, [hip, c1, t1, f1, p1, ti, m1], widths, [a_, a_, a_, b_, b_, b_], out=out, styles=styles, neck=0.3, swell=0.05, taper=0.12, rim=0.08,
           col=0.66, joint=0.45, n=12, rings=8)
    # the tarsus: short and thin, ending in a pair of dark claws
    dd = (ft - m1).normalized()
    X.finger(b, [m1 - dd * 0.012, m1.lerp(ft, 0.5) + out * 0.005, ft], 0.02 * th, 0.02 * th, b_, up=out, col0=0.62, col1=0.2, tip_from=0.6, tint_tip=0.4,
             n=10, power=2.5)
    # stiff setae: rows along the femur, tibia and metatarsus
    side = out.cross(UP).normalized()
    for (sa, sb, bn, cnt, l) in ((t1, f1, a_, 5, 0.07), (p1, ti, b_, 5, 0.065), (ti, m1, b_, 4, 0.055)):
        dseg = (sb - sa).normalized()
        dors = X.dorsal(dseg, out)
        for sv in (dors + side * 0.7, dors - side * 0.7):
            X.spine_row(b, sa, sb, sv, cnt, l * th, 0.0055, bn, t0=0.15, t1=0.88, rake=1.1, alt=0.3, col0=0.5, col1=0.78)

# ---------------------------------------------------------------- motion
T_IDLE = 2.4
T_WALK = 1.0
# alternating tetrapods: L0 R1 L2 R3 swing together, then R0 L1 R2 L3
WALK = Walker(r, [(a_, b_) for a_, b_, *_ in LEGS], [0.0 if ((i // 4 == 0) == (i % 4 % 2 == 0)) else 0.5 for i in range(8)], duty=0.55)


def body(p, t, T, amp=1.0):
    w = 2 * math.pi / T
    add(p, "thorax", (math.sin(t * w) * 0.03 * amp, math.sin(t * w + 1.0) * 0.04 * amp, 0), (0, 0.01 * math.sin(t * w * 2) * amp, 0))
    add(p, "abdomen", (math.sin(t * w - 0.6) * 0.07 * amp, math.sin(t * w + 0.6) * 0.05 * amp, 0))
    add(p, "fangs", (0.1 * max(0.0, math.sin(t * w * 2)) ** 3, 0, 0))
    for sd, sg in (("L", 1), ("R", -1)):
        add(p, "palp." + sd, (math.sin(t * w * 2 + sg) * 0.2, 0, 0))


def idle(t):
    p = zero_pose(r)
    body(p, t, T_IDLE)
    # the feet stay planted while the body breathes and sways over them; one foreleg taps
    tap = max(0.0, math.sin(2 * math.pi * t / T_IDLE)) ** 4
    offs = [(0.0, 0.06 * tap if i == 0 else 0.0, 0.03 * tap if i == 0 else 0.0) for i in range(8)]
    return WALK.step(p, offsets=offs)


def walk(t):
    p = zero_pose(r)
    body(p, t, T_WALK, 0.6)
    ph = (t / T_WALK) % 1.0
    add(p, "thorax", (0, 0, 0), (0, 0.015 * abs(math.sin(2 * math.pi * ph * 2)), 0))
    return WALK.step(p, ph, 0.26, 0.09)


def attack(t):
    k = t / 0.55
    rear = smooth(0.0, 0.3, k) * (1.0 - smooth(0.32, 0.42, k))
    strike = smooth(0.3, 0.42, k) * (1.0 - smooth(0.62, 1.0, k))
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.06 * rear, 0.35 * strike))
    add(p, "thorax", (-0.3 * rear + 0.2 * strike, 0, 0))
    add(p, "abdomen", (0.25 * rear, 0, 0))
    add(p, "fangs", (0.9 * smooth(0.28, 0.4, k) * (1.0 - smooth(0.5, 0.7, k)), 0, 0))
    offs = []
    for i in range(8):
        front = i % 4 == 0
        offs.append((0.0, (0.35 * rear + 0.1 * strike) if front else 0.0, (0.15 * rear + 0.35 * strike) if front else 0.35 * strike))
    return WALK.step(p, offsets=offs)


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.04 * e, -0.15 * e))
    add(p, "thorax", (-0.3 * e, 0, 0.1 * e))
    add(p, "abdomen", (0.3 * e, 0.2 * e, 0))
    offs = [(0.0, 0.05 * e * (1 if i % 2 else 0), -0.15 * e) for i in range(8)]
    return WALK.step(p, offsets=offs)


def die(t):
    """Staggers, rolls onto its back and curls its legs up over its belly."""
    p = zero_pose(r)
    k = min(1.0, t / 1.2)
    p = WALK.step(p, offsets=[(0.0, 0.1 * smooth(0.0, 0.3, k) * (i % 2), 0.0) for i in range(8)])
    curl = []
    for a_, b_, *_ in LEGS:
        sg = 1 if a_.endswith(".L_a") else -1
        curl.append((a_, (0.0, 0.0, -1.1 * sg)))
        curl.append((b_, (0.0, 0.0, -1.6 * sg)))
    flip_die(p, t, 1.2, BY, side=1, curl_legs=curl, rest=0.2)
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    # rears up and raises the abdomen to spray web
    add(p, "thorax", (-0.35 * e, 0, 0), (0, 0.12 * e, 0))
    add(p, "abdomen", (-0.6 * e, 0, 0))
    offs = [(0.0, 0.35 * e if i % 4 == 0 else 0.0, 0.1 * e if i % 4 == 0 else 0.0) for i in range(8)]
    return WALK.step(p, offsets=offs)


print("[art] spider: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/spider.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=16, dist=0.3, strength=0.5, floor_y=0.0)
