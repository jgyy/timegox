"""Mantis: the Jade Mantis Matriarch, the Gale Mantis Empress, the Sky Mantis, the Plague Locust and
the Locust Marquis.

After mantis anatomy (Mantodea): a triangular head, broad across the top where the two huge
compound eyes bulge out at its corners, each with the dark pseudopupil that seems to follow you,
three ocelli between the bases of the long thread-like antennae, narrowing to the mouthparts; a
prothorax much longer than the rest of the thorax, carried raised like a neck and widening where
the forelegs join it; the raptorial forelegs held folded in the praying pose - a coxa almost as
long as the femur hanging from the front of the prothorax, a thick flattened femur with rows of
spines along its inner edge and a spined tibia folded back against it like a jack-knife, ending in
a hook.  Behind them a short thorax on two pairs of long, thin walking legs planted wide, and a
long abdomen of overlapping segments covered by the leathery forewings (tegmina), veined, with a
pale stigma, folded flat over it like a leaf; the hind wing's fan is folded under them and opens in
the threat display (cast).  Plain-shaded cuticle (no scale grid), recoloured by the game; eyes and
spines keep their colours.
Run: blender --background --python art/monsters/mantis.py  ->  assets/monsters/mantis.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import arthropod as X  # noqa: E402
from creature import Walker, add, euler_yxz, flip_die, leg_chain, smooth, zero_pose  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, MAT_PLAIN, V, Builder, Rig  # noqa: E402
from sculpt import TAU, catmull, loft, morph_sphere  # noqa: E402

kit.reset()
creature.realtime()
BY = 0.66
UP = V(0, 1, 0)
NECK0 = V(0, BY + 0.05, 0.1)          # where the prothorax leaves the thorax
NECK1 = V(0, BY + 0.5, 0.4)           # where the head sits on it
HC = NECK1 + V(0, 0.07, 0.07)         # head centre

# ---------------------------------------------------------------- rig
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("thorax", (0, BY, -0.12), (0, BY + 0.03, 0.12), "root")
r.bone("abdomen", (0, BY + 0.02, -0.12), (0, BY + 0.1, -0.95), "thorax")
r.bone("neck", NECK0, NECK1, "thorax")
r.bone("head", NECK1, HC + V(0, 0.02, 0.12), "neck")
LEGS = []
for s, sd in ((1, "L"), (-1, "R")):
    # the middle legs reach forward and out, the hind legs back and out
    for k, (z, kz, fz) in enumerate(((0.06, 0.18, 0.4), (-0.08, -0.26, -0.64))):
        nm = "leg%d.%s" % (k, sd)
        root = V(0.05 * s, BY - 0.02, z)
        knee = V(0.36 * s, BY + 0.16, kz)
        foot = V(0.56 * s, 0.015, fz)
        leg_chain(r, nm, root, knee, foot, "thorax")
        LEGS.append((nm + "_a", nm + "_b", k * math.pi + (0 if s > 0 else math.pi), root, knee, foot, s, k))
    # raptorial foreleg: the coxa down and forward from the front of the prothorax, the femur up in
    # front of the chest, the tibia folded back down against it
    c0 = V(0.045 * s, BY + 0.4, 0.33)
    c1 = V(0.075 * s, BY + 0.16, 0.48)
    f1 = V(0.09 * s, BY + 0.5, 0.6)
    t1 = V(0.085 * s, BY + 0.24, 0.6)
    r.bone("rap.%s_a" % sd, c0, c1, "neck")
    r.bone("rap.%s_b" % sd, c1, f1, "rap.%s_a" % sd)
    r.bone("rap.%s_c" % sd, f1, t1, "rap.%s_b" % sd)
    r.bone("wing.%s" % sd, (0.02 * s, BY + 0.11, 0.04), (0.06 * s, BY + 0.15, -0.85), "thorax")
b = Builder("mantis")

# ---------------------------------------------------------------- abdomen and thorax
abd = []
for k in range(9):
    t = k / 8
    abd.append(V(0, BY + 0.03 + 0.06 * math.sin(t * math.pi * 0.8) - 0.02 * t, -0.1 - t * 0.85))
for k in range(8):
    t = (k + 0.5) / 8
    wk = 0.105 * (0.75 + 0.45 * math.sin(math.pi * min(1.0, t * 1.15))) * (1.0 - 0.35 * t)
    X.segment(b, abd[k] + (abd[k] - abd[k + 1]) * 0.15, abd[k + 1], wk, wk * 0.62, bone="abdomen", up=UP, neck=0.12, neck_len=0.2, swell=0.03, taper=0.05,
              rim=0.1, keels=((0.0, 0.05),), flat=0.3, col=0.8, back=0.04, belly=0.35, joint=0.35, n=18, rings=6)
for s in (1, -1):
    X.finger(b, [abd[-1], abd[-1] + V(0.025 * s, 0.02, -0.05), abd[-1] + V(0.045 * s, 0.03, -0.1)], 0.012, 0.012, "abdomen", col0=0.8, col1=0.5, tip_from=0.5,
             tint_tip=1.0, n=8)
X.segment(b, V(0, BY - 0.0, -0.16), V(0, BY + 0.03, 0.14), 0.085, 0.075, bone="thorax", up=UP, neck=0.15, swell=0.08, taper=0.0, rim=0.06,
          keels=((0.0, 0.08),), col=0.78, back=0.05, belly=0.3, joint=0.35, n=18, rings=8)

# ---------------------------------------------------------------- prothorax: the long "neck"
nd = (NECK1 - NECK0).normalized()
nup = (V(0, 0.4, -1.0) - nd * V(0, 0.4, -1.0).dot(nd)).normalized()       # its back faces up and back
X.segment(b, NECK0 - nd * 0.04, NECK1 + nd * 0.03, 0.034, 0.03, w1=0.05, h1=0.034, bone=lambda p: {"neck": 1.0} if (p - NECK0).dot(nd) > 0.08 else
          {"neck": 0.6, "thorax": 0.4}, up=nup, neck=0.2, swell=0.0, taper=0.0, rim=0.1, keels=((0.0, 0.25),), flat=0.2, col=0.8, back=0.06,
          belly=0.3, joint=0.3, n=16, rings=16)
# the supracoxal dilation: the pronotum widens into a little shield where the forelegs join
X.segment(b, NECK0.lerp(NECK1, 0.62), NECK1 - nd * 0.02, 0.075, 0.018, bone="neck", up=nup, neck=0.5, neck_len=0.4, swell=0.15, swell_at=0.45, taper=0.55,
          rim=0.0, keels=((0.0, 0.5),), col=0.84, back=0.06, belly=0.2, joint=0.2, n=18, rings=10)

# ---------------------------------------------------------------- head
HF = V(0, -0.25, 1.0).normalized()      # the face looks forward and a little down


def head_shape(d):
    # a triangle in front view: wide across the top, narrowing to the mouth, flat from front to back
    x, y, z = d.x, d.y, d.z
    w = 0.1 * (1.0 - 0.55 * smooth(0.1, -1.0, y))
    p = V(x * w, y * 0.085, z * 0.05)
    p.y += 0.02 * smooth(0.0, 1.0, y) * (1.0 - abs(x))
    return p


rot_h = X.rot_to(HF, UP)
morph_sphere(b, HC, head_shape, lambda lp, d: X.grey(0.8 + 0.06 * d.y - 0.12 * smooth(-0.4, -1.0, d.y)), cls=X.CHITIN, bone="head", seg=24, rings=16,
             tint_fn=lambda lp, d: 1.0, rot=rot_h)
EYE_R = 0.058
for s in (1, -1):
    ec = HC + rot_h @ V(0.085 * s, 0.045, -0.005)
    look = (rot_h @ V(0.75 * s, 0.25, 0.65)).normalized()
    # the compound eye: a big glossy ovoid in the accent colour, a dark pseudopupil looking out of it
    b.cur_pal = 1.0
    b.ellipsoid(ec, (EYE_R, EYE_R * 1.18, EYE_R * 0.95), (0.72, 0.72, 0.72), cls=CRYSTAL, bone="head", rot=euler_yxz(X.rot_to(look, UP)), seg=16, rings=12,
                tint=1.0, mat=MAT_PLAIN)
    b.cur_pal = 0.0
    b.ellipsoid(ec + look * (EYE_R * 0.9), (EYE_R * 0.22, EYE_R * 0.26, EYE_R * 0.12), "0c0a0c", cls=CRYSTAL, bone="head",
                rot=euler_yxz(X.rot_to(look, UP)), seg=10, rings=6, mat=MAT_PLAIN)
    b.ellipsoid(ec + look * (EYE_R * 0.8) + UP * (EYE_R * 0.45), (EYE_R * 0.18, EYE_R * 0.14, EYE_R * 0.08), "ffffff", cls=CRYSTAL, bone="head",
                rot=euler_yxz(X.rot_to(look, UP)), seg=6, rings=4, mat=MAT_GLOW)
    # long thread-like antennae
    a0 = HC + rot_h @ V(0.022 * s, 0.07, 0.03)
    pts = catmull([a0, a0 + V(0.03 * s, 0.14, 0.06), a0 + V(0.12 * s, 0.3, 0.02), a0 + V(0.24 * s, 0.38, -0.12), a0 + V(0.34 * s, 0.38, -0.28)], 4)
    b.tube(pts, [0.006 * (1.0 - 0.7 * i / (len(pts) - 1)) for i in range(len(pts))], (0.62, 0.62, 0.62), cls=X.CHITIN, bone="head", seg=5, tint=1.0)
    # mandibles and palps under the clypeus
    m0 = HC + rot_h @ V(0.018 * s, -0.075, 0.02)
    X.finger(b, [m0, m0 + rot_h @ V(-0.004 * s, -0.025, 0.012), m0 + rot_h @ V(-0.018 * s, -0.035, 0.006)], 0.01, 0.009, "head", col0=0.7, col1=0.15,
             tip_from=0.3, tint_tip=0.0, n=8)
    p0 = HC + rot_h @ V(0.04 * s, -0.06, 0.0)
    X.limb(b, [p0, p0 + rot_h @ V(0.01 * s, -0.04, 0.02), p0 + rot_h @ V(0.012 * s, -0.08, 0.0)], [0.008, 0.007], ["head", "head"], up=HF, neck=0.2,
           taper=0.1, col=0.78, joint=0.3, n=8, rings=4)
b.cur_pal = 1.0
for k in range(3):
    b.ball(HC + rot_h @ V((k - 1) * 0.018, 0.06 - abs(k - 1) * 0.01, 0.045), 0.007, "f0f0f0", cls=CRYSTAL, bone="head", seg=6, rings=4, mat=MAT_GLOW, tint=1.0)
b.cur_pal = 0.0
X.segment(b, HC + rot_h @ V(0, -0.035, 0.045), HC + rot_h @ V(0, -0.075, 0.045), 0.03, 0.012, bone="head", up=HF, neck=0.0, swell=0.1, taper=0.2,
          rim=0.0, col=0.88, joint=0.1, n=10, rings=4)

# ---------------------------------------------------------------- walking legs
for a_, b_, ph, root, knee, foot, s, k in LEGS:
    out = V(foot.x, 0.0, foot.z).normalized()
    fd = (foot - knee).normalized()
    ta = knee.lerp(foot, 0.84)
    X.limb(b, [root, knee, ta], [0.024, 0.017], [a_, b_], out=out, neck=0.25, swell=0.06, taper=0.15, rim=0.1, keels=((math.pi * 0.5, 0.06),),
           col=0.8, back=0.05, belly=0.3, joint=0.4, n=12, rings=10)
    # the tarsus: a few short segments down to a hooked claw
    X.finger(b, [ta - fd * 0.01, ta.lerp(foot, 0.5) + out * 0.012, foot], 0.013, 0.013, b_, up=out, col0=0.78, col1=0.3, tip_from=0.6, tint_tip=0.5, n=8)
    X.spine(b, knee + fd * 0.01 - UP * 0.01, -UP + fd * 0.6, 0.03, 0.005, b_, col0=0.75, col1=0.3)

# ---------------------------------------------------------------- raptorial forelegs
SPINE_COL = ("f2ecd8", "3a2c1c")
for s, sd in ((1, "L"), (-1, "R")):
    ra, rb, rc = "rap.%s_a" % sd, "rap.%s_b" % sd, "rap.%s_c" % sd
    c0, c1, f1, t1 = r.head(ra), r.tail(ra), r.tail(rb), r.tail(rc)
    plane = (c1 - c0).cross(f1 - c1).normalized()       # the leg folds in this plane
    if plane.x * s < 0:
        plane = -plane
    # coxa: long, angular, almost as long as the femur
    X.segment(b, c0 - (c1 - c0).normalized() * 0.03, c1, 0.032, 0.04, bone=ra, up=-plane.cross(c1 - c0).normalized(), neck=0.2, swell=0.05, taper=0.1,
              rim=0.1, keels=((0.0, 0.15),), col=0.8, back=0.05, belly=0.25, joint=0.4, n=14, rings=10)
    # femur: a thick blade, its inner edge (towards the tibia) grooved and lined with spines
    fdir = (f1 - c1).normalized()
    inner = (t1 - f1) - fdir * (t1 - f1).dot(fdir)
    inner = (inner - plane * inner.dot(plane)).normalized() if inner.length > 1e-4 else plane.cross(fdir).normalized()
    X.segment(b, c1 - fdir * 0.035, f1, 0.03, 0.058, bone=rb, up=-inner, neck=0.3, swell=0.12, swell_at=0.35, taper=0.4, rim=0.05,
              keels=((0.0, 0.12),), flat=0.15, col=0.82, back=0.06, belly=0.25, joint=0.4, n=16, rings=14)
    for q in range(9):
        t = 0.22 + 0.075 * q
        ln = (0.07 if q % 2 == 0 else 0.042) * (1.0 + 0.3 * (q == 8))
        base = c1.lerp(f1, t) + inner * (0.058 * (1.0 - 0.4 * t) * 0.7)
        X.spine(b, base, (inner * 1.0 - fdir * 0.15).normalized(), ln, 0.009, rb, col0=SPINE_COL[0], col1=SPINE_COL[1], tint=0.0, cls=0.9)
    # tibia: folded back against the femur, spined along its inner edge, ending in a hook
    tdir = (t1 - f1).normalized()
    tin = -inner
    X.segment(b, f1 - tdir * 0.025, t1, 0.022, 0.03, bone=rc, up=-tin, neck=0.25, swell=0.04, taper=0.3, rim=0.0, keels=((0.0, 0.1),), col=0.84,
              back=0.05, belly=0.2, joint=0.4, n=12, rings=10)
    for q in range(6):
        t = 0.2 + 0.12 * q
        X.spine(b, f1.lerp(t1, t) + tin * 0.02, (tin - tdir * 0.2).normalized(), 0.04, 0.007, rc, col0=SPINE_COL[0], col1=SPINE_COL[1], tint=0.0, cls=0.9)
    X.finger(b, [t1 - tdir * 0.02, t1 + tdir * 0.03 + tin * 0.01, t1 + tdir * 0.04 + tin * 0.05], 0.012, 0.012, rc, col0=0.8, col1=0.1, tip_from=0.3,
             tint_tip=0.0, n=8)


# ---------------------------------------------------------------- wings
def wing_plate(root, tip, width, bone, side, col_fn, thick=0.007, camber=0.03, n_len=14, n_w=10, tint=1.0, arch=0.0):
    """A thin, cambered, leaf-shaped wing plate from `root` to `tip`, `width` across at its widest,
    spreading to `side`; coloured by col_fn(u along, v across) -> grey."""
    root, tip = V(root), V(tip)
    d = (tip - root).normalized()
    sv = V(side)
    sv = (sv - d * sv.dot(d)).normalized()
    nrm = d.cross(sv).normalized()
    if nrm.y < 0:
        nrm = -nrm
    L = (tip - root).length
    rings = []
    params = []
    for j in range(n_len + 1):
        u = j / n_len
        w = width * (0.22 + 0.78 * math.sin(math.pi * min(1.0, 0.1 + u * 0.95)) ** 0.7) * (1.0 - 0.35 * smooth(0.75, 1.0, u)) + 0.002
        c = root + d * (L * u) + sv * (w * 0.92) + nrm * (arch * math.sin(math.pi * min(1.0, u * 1.1)))
        ring = []
        for i in range(n_w):
            a = TAU * i / n_w
            x = math.sin(a)                                 # across: -1 at the inner edge, +1 at the outer
            y = math.cos(a)
            p = c + sv * (x * w) + nrm * (y * thick - camber * x * x * w * 2.0 + camber * w)
            ring.append(p)
        rings.append(ring)
        params.append(u)

    def colf(p, j, i):
        u = params[j]
        x = math.sin(TAU * i / n_w)
        return X.grey(col_fn(u, x))

    return loft(b, rings, X.grey(0.8), cls=X.CHITIN, bone=bone, col_fn=colf, tint=tint, cap0=True, cap1=True, cap_push=0.2)


def tegmen_col(u, x):
    v = 0.8 + 0.04 * x
    # veins: a strong radial vein near the front edge, branches running back, a crossed network
    v *= 1.0 - 0.22 * smooth(0.12, 0.0, abs(x + 0.35))
    for k in range(5):
        xv = -0.1 + k * 0.22
        v *= 1.0 - 0.12 * smooth(0.06, 0.0, abs(x - xv - 0.2 * u))
    v *= 1.0 - 0.07 * smooth(0.85, 1.0, abs(math.sin(u * 22.0)))
    # the stigma: a pale spot a third of the way along
    v += 0.16 * math.exp(-(((u - 0.32) / 0.05) ** 2 + ((x + 0.35) / 0.18) ** 2))
    return min(1.0, v)


def hind_col(u, x):
    v = 0.7 + 0.2 * smooth(-0.6, 0.8, x)
    v *= 1.0 - 0.15 * smooth(0.85, 1.0, abs(math.sin((x + 1.0) * 9.0)))
    return v


for s, sd in ((1, "L"), (-1, "R")):
    wb = "wing.%s" % sd
    root = r.head(wb) - V(0.025 * s, 0, 0)
    tip = V(0.0, BY + 0.1, -1.02)
    # the hind wing's fan folded under the tegmen (it shows when the wings open)
    b.cur_pal = 0.5
    wing_plate(root + V(0, -0.012, 0), tip + V(0.02 * s, -0.015, 0.06), 0.11, wb, V(s, -0.25, 0), hind_col, thick=0.004, camber=0.02, arch=0.075)
    b.cur_pal = 0.0
    # the tegmina lie over the abdomen like a folded leaf, meeting along the back
    wing_plate(root, tip, 0.125, wb, V(s, -0.4, 0), tegmen_col, thick=0.006, camber=0.04, arch=0.085)

# ---------------------------------------------------------------- motion
T_IDLE = 2.6
T_WALK = 1.1
WALK = Walker(r, [(a_, b_) for a_, b_, *_ in LEGS], [0.0, 0.5, 0.5, 0.0], duty=0.6)


def sway(p, t, T, amp=1.0):
    w = 2 * math.pi / T
    add(p, "neck", (math.sin(t * w * 2) * 0.05 * amp, math.sin(t * w) * 0.1 * amp, 0))
    add(p, "head", (0, math.sin(t * w + 0.8) * 0.35 * amp, math.sin(t * w) * 0.15 * amp))
    add(p, "abdomen", (math.sin(t * w - 0.8) * 0.05, 0, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "rap.%s_b" % sd, (math.sin(t * w + s_) * 0.05, 0, 0))
        add(p, "wing.%s" % sd, (0, 0, 0.02 * math.sin(t * w * 4) * s_))


def idle(t):
    p = zero_pose(r)
    sway(p, t, T_IDLE)
    # a slow side-to-side rock, the classic mantis sway, over planted feet
    add(p, "thorax", (0, 0, 0), (0.02 * math.sin(2 * math.pi * t / T_IDLE), 0, 0))
    return WALK.step(p)


def walk(t):
    p = zero_pose(r)
    sway(p, t, T_WALK, 0.5)
    ph = (t / T_WALK) % 1.0
    add(p, "thorax", (0, 0, 0), (0.015 * math.sin(2 * math.pi * ph), 0.01 * abs(math.sin(2 * math.pi * ph)), 0))
    return WALK.step(p, ph, 0.26, 0.08)


def attack(t):
    """Raptorial strike: the forelegs cock back, snap out and fold the prey in."""
    k = t / 0.55
    cock = smooth(0.0, 0.3, k) * (1.0 - smooth(0.32, 0.4, k))
    snap = smooth(0.32, 0.42, k) * (1.0 - smooth(0.6, 1.0, k))
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0, 0.3 * snap))
    add(p, "neck", (-0.15 * cock + 0.35 * snap, 0, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "rap.%s_a" % sd, (-0.6 * cock + 0.4 * snap, 0, 0))
        add(p, "rap.%s_b" % sd, (-0.9 * cock + 1.3 * snap, 0, 0))
        add(p, "rap.%s_c" % sd, (1.2 * cock - 0.6 * snap, 0, 0))
        add(p, "wing.%s" % sd, (0, 0.6 * cock * s_, 0.5 * cock * s_))
    return WALK.step(p, offsets=[(0.0, 0.0, 0.3 * snap)] * 4)


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    add(p, "neck", (-0.4 * e, 0.2 * e, 0))
    add(p, "thorax", (-0.1 * e, 0, 0.1 * e), (0, 0, -0.06 * e))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "wing.%s" % sd, (0, 0.4 * e * s_, 0.5 * e * s_))
    return WALK.step(p, offsets=[(0.0, 0.0, -0.08 * e)] * 4)


def die(t):
    p = zero_pose(r)
    k = min(1.0, t / 1.2)
    p = WALK.step(p)
    curl = []
    for a_, b_, *_ in LEGS:
        sg = 1 if ".L_" in a_ else -1
        curl.append((a_, (0.0, 0.0, -1.0 * sg)))
        curl.append((b_, (0.0, 0.0, -1.4 * sg)))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "rap.%s_b" % sd, (0.8 * smooth(0.3, 0.9, k), 0, 0))
    add(p, "neck", (0.5 * smooth(0.2, 0.8, k), 0, 0))
    flip_die(p, t, 1.2, BY, side=1, curl_legs=curl, rest=0.1)
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    # threat display: rear up with the wings fanned and the forelegs spread
    add(p, "neck", (-0.35 * e, 0, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "rap.%s_a" % sd, (-0.8 * e, 0, -0.6 * e * s_))
        add(p, "wing.%s" % sd, (-0.6 * e, 0.9 * e * s_, 0.9 * e * s_))
    return WALK.step(p)


print("[art] mantis: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/mantis.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=16, dist=0.3, strength=0.5, floor_y=0.0)
