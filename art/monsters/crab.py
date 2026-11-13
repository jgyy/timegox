"""Crab: the armoured crustaceans of the coasts and the Blood Pool (Coral Guard, Armored Crab General,
Blood-Pool Crab, Ferry-Post Crab, Jade Tea Beetle ...).

After the anatomy of a true crab (Brachyura): a carapace wider than long, its outline a rounded fan
- a notched front between the orbits, five teeth down each anterolateral margin ending in a lateral
spine, margins converging behind - domed and sculpted into its regions (the gastric region in front,
the cardiac between the two grooves of the "H", the swollen branchial regions over the gills), pale
underneath; the eyes on short stalks that stand up out of their orbits in the front margin; the
mouth closed by the flat doors of the third maxillipeds; the abdomen folded under as an apron.
The first pair of legs are the chelipeds: a three-sided merus, a knobbly carpus with a spine, and
the chela - a swollen, smooth palm (the propodus) whose lower corner runs on into the fixed finger,
with the dactyl hinged above it, both fingers toothed along the bite and dark at the tips - held
folded in front of the mouth, the left a heavy crusher and the right a slimmer cutter.  Four pairs
of walking legs, each a row of flat plates (the merus the longest, a short carpus, the propodus
fringed with setae and the pointed dactyl), arch out from under the carapace and stand on their
tips, the front pairs raked forward and the back pairs back.  Shells are plain-shaded plates (no
scale grid), recoloured by the game; eyes, teeth and finger tips keep their colours.
Run: blender --background --python art/monsters/crab.py  ->  assets/monsters/crab.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import arthropod as X  # noqa: E402
from mathutils import Matrix  # noqa: E402
from creature import Gait, Walker, add, euler_yxz, flip_die, foot_path, smooth, zero_pose  # noqa: E402
from kit import CRYSTAL, MAT_PLAIN, V, Builder, Rig  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
BY = 0.37            # height of the carapace's rim
SCALE = 1.15         # the whole crab is scaled up by this at the end
TOP = 0.19           # the dome over the rim
UNDER = 0.13         # the sternum under it
UP = V(0, 1, 0)

# ---------------------------------------------------------------- the carapace outline (top view)
# the left half from the middle of the front round to the middle of the back (x, z), mirrored
HALF = [(0.0, 0.43), (0.05, 0.445), (0.1, 0.43), (0.15, 0.4), (0.2, 0.42), (0.25, 0.4), (0.4, 0.31), (0.52, 0.2), (0.6, 0.08),
        (0.58, -0.04), (0.46, -0.16), (0.33, -0.29), (0.19, -0.37), (0.0, -0.39)]
OUTLINE = HALF[:-1] + [(-x, z) for x, z in reversed(HALF[1:])]
BASE_R = X.outline_radius(OUTLINE)
TH_ORB = math.atan2(0.25, 0.4)       # the outer corner of the orbit
TH_LAT = math.atan2(0.62, 0.06)      # the lateral spine
N_TEETH = 5


def teeth(th):
    """Anterolateral teeth along the outline: each a forward-raked triangle, the last the long
    lateral spine (blue-crab-like)."""
    a = abs(th)
    if a < TH_ORB or a > TH_LAT + 0.08:
        return 0.0
    f = (a - TH_ORB) / (TH_LAT - TH_ORB) * N_TEETH
    k = min(N_TEETH - 1, int(f))
    u = f - k
    big = 0.055 if k == N_TEETH - 1 else 0.03
    return big * smooth(0.0, 0.18, u) * max(0.0, 1.0 - u) ** 1.2


def radius(th):
    return BASE_R(th) + teeth(th)


def cara_offset(th, ph, p):
    """The regions of the carapace: grooves of the "H" and the swellings between them."""
    if ph < 0.05:
        return 0.0
    x, z = p.x, p.z
    off = 0.0
    # cervical groove: a shallow U across the front third, its arms running out to the sides
    zc = 0.1 + 0.25 * (x / 0.42) ** 2
    off -= 0.009 * math.exp(-((z - zc) / 0.018) ** 2) * smooth(0.48, 0.3, abs(x))
    # branchiocardiac grooves either side of the cardiac region, closing in behind it
    for s in (1, -1):
        xg = (0.13 - 0.08 * smooth(-0.05, -0.3, z)) * s
        d = math.hypot((x - xg) / 0.018, max(0.0, abs(z + 0.12) - 0.14) / 0.04)
        off -= 0.007 * math.exp(-d * d)
    # gastric region swelling in front, the branchial regions over the gills, the cardiac hump
    off += 0.016 * math.exp(-((x / 0.15) ** 2 + ((z - 0.22) / 0.1) ** 2))
    for s in (1, -1):
        off += 0.018 * math.exp(-(((x - 0.33 * s) / 0.15) ** 2 + ((z + 0.06) / 0.18) ** 2))
    off += 0.012 * math.exp(-((x / 0.09) ** 2 + ((z + 0.12) / 0.09) ** 2))
    # the shell arches higher over the front half than over the back
    off += 0.03 * smooth(-0.42, 0.12, z) * smooth(0.05, 0.7, ph)
    return off


def rim(th):
    """The lateral margin is a sharp, toothed edge in front and rounds off behind."""
    return 0.3 * smooth(2.1, 1.5, abs(th)) * smooth(0.25, 0.5, abs(th))


def cara_col(th, ph, p):
    if ph < 0.0:
        # the sides of the shell curve under to the pale sternum
        return X.grey(0.76 + 0.2 * smooth(-0.75, -1.25, ph))
    x, z = p.x, p.z
    v = 0.74 + 0.04 * smooth(0.1, 0.9, ph)
    # grooves dark, the crests of the regions a touch paler
    zc = 0.1 + 0.25 * (x / 0.42) ** 2
    g = math.exp(-((z - zc) / 0.016) ** 2) * smooth(0.48, 0.3, abs(x))
    for s in (1, -1):
        xg = (0.13 - 0.08 * smooth(-0.05, -0.3, z)) * s
        d = math.hypot((x - xg) / 0.016, max(0.0, abs(z + 0.12) - 0.14) / 0.04)
        g = max(g, math.exp(-d * d))
    v *= 1.0 - 0.22 * g
    # a pale crest on each swelling, a darker band along the toothed margin
    v *= 1.0 + 0.06 * math.exp(-(((abs(x) - 0.33) / 0.12) ** 2 + ((z + 0.06) / 0.14) ** 2))
    v *= 1.0 - 0.1 * smooth(0.5, 0.15, ph) * smooth(0.3, 0.8, abs(th) / math.pi * 2.0) * smooth(1.6, 1.2, abs(th))
    # mottling and the dark granules of the front half
    v *= 0.96 + 0.08 * fbm3((p.x * 9.0, p.y * 9.0, p.z * 9.0), 2, 4)
    if fbm3((p.x * 30.0, p.y * 30.0, p.z * 30.0), 1, 7) > 0.76 and z > -0.05:
        v *= 0.86
    # dark teeth tips
    v *= 1.0 - 0.35 * smooth(0.012, 0.03, teeth(th)) * smooth(0.3, 0.05, ph)
    return X.grey(min(1.0, v))


# ---------------------------------------------------------------- rig
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, BY, -0.1), (0, BY, 0.3), "root")
# the front of the carapace between the eyes, where the stalks stand (the game's "head")
r.bone("head", (0, BY + 0.1, 0.3), (0, BY + 0.1, 0.46), "body")
LEGS = []                    # (bone a, bone b, joints, outward direction, size)
for s, sd in ((1, "L"), (-1, "R")):
    for k, (z, ang, size) in enumerate(((0.17, 0.5, 1.0), (0.04, 0.17, 1.0), (-0.1, -0.2, 0.96), (-0.22, -0.55, 0.86))):
        out = V(math.cos(ang) * s, 0.0, math.sin(ang))
        hip = V(0.36 * s, BY - 0.07, z)
        kq = 0.88 + 0.12 * size
        cx = hip + out * 0.08 - UP * 0.01                       # coxa (with basis-ischium)
        me = cx + out * (0.27 * kq) + UP * 0.08                   # merus: out and a little up
        ca = me + out * (0.08 * kq) - UP * 0.03                   # carpus: over the knee
        pr = ca + out * (0.12 * kq) - UP * 0.19                   # propodus: out and down
        da = V(pr.x + out.x * 0.11 * kq, 0.015, pr.z + out.z * 0.11 * kq)   # dactyl: raked out to the tip
        nm = "leg%d.%s" % (k, sd)
        r.bone(nm + "_a", hip, me, "body")
        r.bone(nm + "_b", me, da, nm + "_a")
        LEGS.append((nm + "_a", nm + "_b", [hip, cx, me, ca, pr, da], out, size, s))
    # cheliped: the merus forward and out, the carpus turning in, the chela pointing forward and
    # inwards so the two claws guard the mouth
    big = 1.16 if s > 0 else 0.88
    sh = V(0.28 * s, BY - 0.08, 0.27)
    el = V(0.47 * s, BY - 0.07, 0.47)
    wr = V(0.42 * s, BY - 0.04, 0.63)
    pe = wr + V(-0.17 * s, 0.0, 0.19) * big                     # the far end of the palm
    r.bone("arm." + sd, sh, el, "body")
    r.bone("claw." + sd, el, pe, "arm." + sd)
    hinge = pe + V(0.0, 0.055, 0.0) * big
    r.bone("pincer." + sd, hinge, hinge + V(-0.15 * s, -0.02, 0.17) * big, "claw." + sd)
    # the eye stalks stand up out of the orbits
    r.bone("stalk." + sd, (0.165 * s, BY + 0.06, 0.37), (0.215 * s, BY + 0.16, 0.44), "head")

b = Builder("crab")
CC = V(0, BY, 0)
X.shield(b, CC, radius, TOP, UNDER, "body", cara_col, dome=2.5, rim_lift=rim, offset=cara_offset, seg=144, rings=40)

# the apron: the abdomen folded under the sternum (it shows when the crab dies on its back)
b.cur_pal = 0.0
X.segment(b, V(0, BY - UNDER + 0.012, -0.3), V(0, BY - UNDER + 0.006, 0.05), 0.17, 0.02, bone="body", up=(0, -1, 0), neck=0.0, swell=0.1, taper=0.6, rim=0.0,
          col=0.9, belly=0.0, back=0.05, joint=0.15, n=16, rings=8)

# ---------------------------------------------------------------- eyes in their orbits
for s, sd in ((1, "L"), (-1, "R")):
    h0, t0 = r.head("stalk." + sd), r.tail("stalk." + sd)
    d = (t0 - h0).normalized()
    X.stalk_eye(b, h0 - d * 0.03, t0, 0.04, "stalk." + sd, out=V(0.8 * s, 0.0, 0.6), col=0.8)
    # the orbit: a dark notch in the front margin the stalk stands in
    b.ellipsoid(h0 + V(0, -0.01, 0.0), (0.05, 0.03, 0.04), (0.35, 0.35, 0.35), cls=X.CHITIN, bone="body", tint=1.0, seg=10, rings=6)

# ---------------------------------------------------------------- mouthparts
b.cur_pal = 0.5
for s in (1, -1):
    # the third maxillipeds: two flat doors over the mouth, ridged down the middle
    X.segment(b, V(0.042 * s, BY - 0.12, 0.33), V(0.04 * s, BY - 0.03, 0.375), 0.04, 0.012, bone="body", up=(0, 0, 1), neck=0.05, swell=0.05, taper=0.1, rim=0.0,
              keels=((math.pi * 0.5, 0.0),), col=0.86, back=0.08, joint=0.15, n=12, rings=6)
b.cur_pal = 0.0
for k in range(5):
    a = k * 2.3
    b.ball(V(math.sin(a) * 0.05, BY - 0.1 + 0.025 * math.cos(a * 1.7), 0.39 + 0.01 * (k % 2)), 0.011 + 0.005 * (k % 2), "eef6ff", cls=CRYSTAL, bone="body",
           seg=8, rings=5, mat=MAT_PLAIN)

# ---------------------------------------------------------------- walking legs
for a_, b_, J, out, size, s in LEGS:
    hip, cx, me, ca, pr, da = J
    sz = 0.9 + 0.1 * size
    fwd = V(-out.z, 0.0, out.x) * s       # the leg's front face (towards the head)
    fwd = fwd if fwd.z >= 0.0 or abs(fwd.z) < 0.2 else fwd
    # coxa and merus on the upper bone; carpus, propodus and dactyl on the lower one
    X.segment(b, hip - out * 0.03, cx, 0.045 * sz, 0.04 * sz, bone=a_, up=X.dorsal(cx - hip, out), neck=0.0, swell=0.1, taper=0.0, rim=0.1, col=0.84,
              belly=0.25, joint=0.25, n=12, rings=5)
    X.segment(b, cx - (me - cx).normalized() * 0.02, me, 0.064 * sz, 0.036 * sz, bone=a_, up=X.dorsal(me - cx, out), neck=0.25, swell=0.06, swell_at=0.55,
              taper=0.1, rim=0.08, keels=((math.pi * 0.5, 0.12), (-math.pi * 0.5, 0.12)), col=0.78, back=0.06, belly=0.3, joint=0.45, n=16, rings=10)
    X.segment(b, me - (ca - me).normalized() * 0.018, ca, 0.048 * sz, 0.034 * sz, bone=b_, up=X.dorsal(ca - me, out), neck=0.3, swell=0.1, taper=0.05,
              rim=0.08, col=0.78, back=0.06, belly=0.25, joint=0.45, n=14, rings=7)
    X.segment(b, ca - (pr - ca).normalized() * 0.016, pr, 0.044 * sz, 0.03 * sz, bone=b_, up=X.dorsal(pr - ca, out), neck=0.28, swell=0.05, taper=0.2,
              rim=0.06, keels=((math.pi * 0.5, 0.1), (-math.pi * 0.5, 0.1)), col=0.78, back=0.06, belly=0.25, joint=0.45, n=14, rings=9)
    # the dactyl: a pointed, slightly curved claw, darkening to its tip
    dd = (da - pr).normalized()
    X.finger(b, [pr - dd * 0.012, pr.lerp(da, 0.45) + out * 0.012, da], 0.022 * sz, 0.02 * sz, b_, up=out, col0=0.78, col1=0.12, tip_from=0.35,
             tint_tip=0.0, n=10)
    # setae: a fringe of short dark bristles along the back edge of the propodus and the merus
    X.spine_row(b, ca, pr, -fwd, 4, 0.03, 0.004, b_, t0=0.2, t1=0.85, rake=0.9, col0=0.5, col1=0.3)
    X.spine_row(b, cx, me, fwd + UP * 0.6, 3, 0.028, 0.006, a_, t0=0.35, t1=0.85, rake=0.7, col0=0.7, col1=0.25)

# ---------------------------------------------------------------- chelipeds
for s, sd in ((1, "L"), (-1, "R")):
    big = 1.16 if s > 0 else 0.88
    sh, el = r.head("arm." + sd), r.tail("arm." + sd)
    pe = r.tail("claw." + sd)
    wr = el + V(-0.05 * s, 0.03, 0.16)
    out = V(1.0 * s, 0.0, 0.6).normalized()
    # merus: a three-sided bar with a toothed upper edge
    X.segment(b, sh - (el - sh).normalized() * 0.05, el, 0.07 * big, 0.06 * big, bone="arm." + sd, up=UP, neck=0.15, swell=0.08, taper=0.05, rim=0.08,
              keels=((0.0, 0.18), (math.pi * 0.65, 0.12), (-math.pi * 0.65, 0.12)), col=0.8, belly=0.3, joint=0.4, n=18, rings=10)
    X.spine_row(b, sh.lerp(el, 0.3), el, UP, 3, 0.035 * big, 0.008, "arm." + sd, t0=0.0, t1=1.0, rake=0.5, col0=0.7, col1=0.2)
    # carpus: a knobbly wrist with a spine on its inner corner
    X.segment(b, el - (wr - el).normalized() * 0.03, wr, 0.075 * big, 0.065 * big, bone="claw." + sd, up=UP, neck=0.25, swell=0.2, taper=0.0, rim=0.06,
              col=0.82, belly=0.25, joint=0.42, n=16, rings=8)
    X.spine(b, el.lerp(wr, 0.6) + V(-0.05 * s, 0.04, 0.0) * big, V(-0.6 * s, 0.5, 0.5), 0.06 * big, 0.012 * big, "claw." + sd, col0=0.75, col1=0.2)
    # the palm: a swollen, smooth propodus, deep and laterally flat, with a keel along its top
    pd = (pe - wr).normalized()
    palm_up = (UP - pd * UP.dot(pd)).normalized()
    side = pd.cross(palm_up).normalized()
    X.segment(b, wr - pd * 0.03, pe + pd * 0.01, 0.054 * big, 0.08 * big, bone="claw." + sd, up=palm_up, neck=0.4, neck_len=0.22, swell=0.12,
              swell_at=0.55, taper=0.0, rim=0.0, keels=((0.0, 0.1), (math.pi, 0.06)), square=0.25, col=0.8, back=0.05, belly=0.2, joint=0.35, n=24,
              rings=14, cap1=0.6)
    for q in range(6):
        tq = 0.25 + q * 0.12
        for row, (ku, ks) in enumerate(((1.04, 0.012 * (q % 2)), (0.62, 0.62))):
            if row == 1 and q % 2:
                continue
            pq = wr.lerp(pe, tq) + palm_up * (0.08 * big * ku) + side * (0.054 * big * ks * s if row else ks * s)
            b.ellipsoid(pq, (0.011 * big, 0.008 * big, 0.013 * big), X.grey(0.6), cls=X.CHITIN, bone="claw." + sd, tint=1.0, seg=8, rings=5)
    # the fixed finger runs on from the palm's lower corner and curves up; the dactyl is hinged above
    # it and curves down to meet it, both toothed along the bite and dark at the tips (a gape between)
    f0 = pe - palm_up * (0.045 * big) - pd * 0.03
    tip = pe + pd * (0.21 * big) - palm_up * (0.005 * big)
    X.finger(b, [f0, f0 + pd * (0.09 * big) - palm_up * 0.008 * big, f0 + pd * (0.17 * big) + palm_up * 0.006 * big, tip], 0.026 * big, 0.036 * big, "claw." + sd,
             up=palm_up, col0=0.82, col1=0.08, tip_from=0.4, tint_tip=0.0, n=14, teeth=5, teeth_side=palm_up, teeth_len=0.016 * big)
    hg = r.head("pincer." + sd)
    dtip = tip + palm_up * (0.03 * big) + pd * 0.004
    X.finger(b, [hg - pd * 0.03, hg + pd * (0.08 * big) + palm_up * 0.022 * big, hg + pd * (0.16 * big) + palm_up * 0.012 * big, dtip], 0.024 * big,
             0.033 * big, "pincer." + sd, up=palm_up, col0=0.82, col1=0.08, tip_from=0.4, tint_tip=0.0, n=14, teeth=5, teeth_side=-palm_up,
             teeth_len=0.015 * big)


# ---------------------------------------------------------------- motion
def about(axis, ang):
    """Godot Euler angles of a turn of `ang` about `axis` (for hinges that are not on X)."""
    return euler_yxz(Matrix.Rotation(ang, 3, V(axis).normalized()))


HINGE = {}
for s, sd in ((1, "L"), (-1, "R")):
    pd = (r.tail("claw." + sd) - r.head("claw." + sd)).normalized()
    HINGE[sd] = pd.cross(UP).normalized()          # opening the dactyl lifts it


def pinch(p, sd, k):
    """Open (k > 0) or close the dactyl about its own hinge."""
    e = about(HINGE[sd], -0.5 * k * (1 if sd == "L" else 1))
    add(p, "pincer." + sd, e)


T_IDLE = 2.0
T_WALK = 0.9
WALK = Walker(r, [(a_, b_) for a_, b_, *_ in LEGS], [0.5 * ((i % 4 + (0 if i < 4 else 1)) % 2) for i in range(8)], duty=0.55)


def claws(p, t, T_, amp=1.0):
    w = 2 * math.pi / T_
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm." + sd, (-0.06 + math.sin(t * w + s_) * 0.08 * amp, 0, 0))
        pinch(p, sd, 0.15 + 0.35 * max(0.0, math.sin(t * w * 2 + s_)) ** 3 * amp)
        add(p, "stalk." + sd, (math.sin(t * w * 2 + s_) * 0.12, math.sin(t * w + s_) * 0.25, 0))


def idle(t):
    p = zero_pose(r)
    w = 2 * math.pi / T_IDLE
    add(p, "body", (0, math.sin(t * w) * 0.04, 0), (math.sin(t * w) * 0.02, abs(math.sin(t * w)) * 0.012, 0))
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
    """Both claws rear up open and slam down, snapping shut."""
    k = t / 0.55
    raise_ = smooth(0.0, 0.3, k) * (1.0 - smooth(0.32, 0.42, k))
    snap = smooth(0.32, 0.42, k) * (1.0 - smooth(0.6, 1.0, k))
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0, 0.3 * snap))
    add(p, "body", (-0.12 * raise_ + 0.08 * snap, 0, 0))
    for sd in ("L", "R"):
        add(p, "arm." + sd, (-0.75 * raise_ + 0.45 * snap, 0, 0))
        add(p, "claw." + sd, (-0.3 * raise_ + 0.25 * snap, 0, 0))
        pinch(p, sd, 1.2 * raise_ - 0.2 * snap)
    return WALK.step(p, offsets=[(0.0, 0.0, 0.3 * snap)] * 8)


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    add(p, "body", (-0.2 * e, 0, 0.15 * e), (0, 0, -0.1 * e))
    for sd in ("L", "R"):
        add(p, "stalk." + sd, (0.6 * e, 0, 0))
        add(p, "arm." + sd, (0.25 * e, 0, 0))
        pinch(p, sd, 0.6 * e)
    return WALK.step(p, offsets=[(0.0, 0.0, -0.1 * e)] * 8)


def die(t):
    k = min(1.0, t / 1.2)
    p = zero_pose(r)
    p = WALK.step(p)
    curl = []
    for a_, b_, *_ in LEGS:
        sg = 1 if ".L_" in a_ else -1
        curl.append((a_, (0.0, 0.0, -0.9 * sg)))
        curl.append((b_, (0.0, 0.0, -1.3 * sg)))
    for sd in ("L", "R"):
        add(p, "arm." + sd, (0.4 * smooth(0.3, 0.9, k), 0, 0))
        add(p, "stalk." + sd, (0.9 * smooth(0.2, 0.6, k), 0, 0))
        pinch(p, sd, 0.8 * smooth(0.3, 0.9, k))
    flip_die(p, t, 1.2, BY * SCALE, side=1, curl_legs=curl, rest=(TOP + 0.03) * SCALE)
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    add(p, "body", (-0.25 * e, 0, 0), (0, 0.1 * e, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm." + sd, (-1.0 * e, 0, -0.4 * e * s_))
        pinch(p, sd, 1.0 * e)
    return WALK.step(p)


kit.scale_asset(b, r, SCALE)
print("[art] crab: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/crab.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=16, dist=0.3, strength=0.5, floor_y=0.0)
