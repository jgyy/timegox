"""Centipede (new in the Turned Face release): the Hundred-Legged Rumour, the thing that runs ahead of a man
along every road and is in the next town before he is, and the others of Part XLIV that go on many legs.

After centipede anatomy (Scolopendra subspinipes mutilans, the red-headed centipede of China, which the
apothecaries dry on a slip of bamboo, and which the Wuxia stories put in every poisoner's jar):

* **Silhouette.**  Long and low: a flat ribbon of twenty-one trunk segments as long as a man is tall,
  never higher than a hand off the ground except when it rears, the whole length moving in a slow
  wave.  What leaves the outline: the legs, a pair to a segment, standing out on both sides like the
  teeth of a comb; the long antennae in front; and at the back the last pair, the ultimate legs, much
  longer and heavier than the rest and laid straight back, spined, so that the tail end looks like a
  second head (it is meant to).
* **Head.**  A flat, rounded shield with a cluster of simple eyes at each front corner; under it the
  forcipules, the first pair of legs grown into curved, black-tipped fangs that meet across the mouth.
* **Value.**  Each tergite (the plate on the back) is dark, a little paler towards its front, with a
  black band along its back edge where it overlaps the next; the head and the first tergite paler and
  warmer (the red head); the sternites underneath pale; the legs on the secondary colour, paler towards
  their claws, which are dark.  The plates take the enemy's colour (taken down by `Assets.natural`),
  the legs the second colour, the eyes the accent; the fang tips keep their black.

Clips: idle (the body breathes in a slow wave, the antennae feel the air), walk (the body waves and the
legs go in a metachronal ripple, each pair a beat behind the one in front), attack (rears up its front
third and strikes down, the fangs closing), hurt (writhes), die (rolls onto its back on the ground and
the legs curl), cast (rears high, fangs spread, every leg rippling).
Run: blender --background --python art/monsters/centipede.py  ->  assets/monsters/centipede.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import arthropod as X  # noqa: E402
from creature import Walker, add, flip_die, smooth, zero_pose  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, MAT_PLAIN, V, Builder, Rig  # noqa: E402
from sculpt import catmull  # noqa: E402

kit.reset()
creature.realtime()
BY = 0.13                     # the height of the middle of the trunk
N = 21                        # trunk segments, each with a pair of legs
SEG = 0.1                     # the length of one segment
Z0 = 1.05                     # the back of the head
UP = V(0, 1, 0)


def zc(i):
    """The front of trunk segment i (0 behind the head)."""
    return Z0 - i * SEG


def width(i):
    """Half the width of segment i: broadest in the middle of the body, narrowing a little at both ends."""
    t = i / (N - 1)
    return 0.095 * (0.82 + 0.25 * math.sin(math.pi * min(1.0, t * 1.05 + 0.05))) * (1.0 - 0.18 * smooth(0.8, 1.0, t))


# ---------------------------------------------------------------- rig
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
TRUNK = []
prev = "root"
for i in range(N):
    nm = "t%d" % i
    r.bone(nm, (0, BY, zc(i)), (0, BY, zc(i + 1)), prev)
    TRUNK.append(nm)
    prev = nm
HC = V(0, BY + 0.005, Z0 + 0.09)
r.bone("head", (0, BY, Z0), (0, BY + 0.01, Z0 + 0.19), "t0")
for s, sd in ((1, "L"), (-1, "R")):
    a0 = HC + V(0.045 * s, 0.02, 0.08)
    a1 = a0 + V(0.12 * s, 0.1, 0.22)
    a2 = a1 + V(0.14 * s, 0.02, 0.24)
    r.bone("ant0.%s" % sd, a0, a1, "head")
    r.bone("ant1.%s" % sd, a1, a2, "ant0.%s" % sd)
    f0 = HC + V(0.05 * s, -0.04, 0.02)
    f1 = f0 + V(0.06 * s, -0.01, 0.07)
    r.bone("fang.%s" % sd, f0, f1, "head")
LEGS = []
PHASES = []
LEG_INFO = []
for i in range(N - 1):
    zm = zc(i) - SEG * 0.55
    w = width(i)
    for s, sd in ((1, "L"), (-1, "R")):
        nm = "leg%d.%s" % (i, sd)
        root = V(w * 0.9 * s, BY - 0.025, zm)
        knee = V((w + 0.075) * s, BY + 0.035, zm + 0.02)
        foot = V((w + 0.15) * s, 0.008, zm - 0.025 - 0.012 * (i / N))
        creature.leg_chain(r, nm, root, knee, foot, TRUNK[i])
        LEGS.append((nm + "_a", nm + "_b"))
        # a wave of steps from the head backwards: each pair a beat behind the one before, the sides opposed
        PHASES.append((i * 0.14 + (0.0 if s > 0 else 0.5)) % 1.0)
        LEG_INFO.append((nm, root, knee, foot, s, i))
# the ultimate legs: long, heavy, laid straight back from the last segment
TAIL_LEGS = []
for s, sd in ((1, "L"), (-1, "R")):
    nm = "ult.%s" % sd
    z = zc(N - 1) - SEG * 0.5
    p0 = V(0.05 * s, BY - 0.01, z)
    p1 = p0 + V(0.05 * s, 0.0, -0.17)
    p2 = p1 + V(0.03 * s, -0.02, -0.17)
    p3 = p2 + V(0.01 * s, -0.04, -0.12)
    r.bone(nm + "_a", p0, p1, TRUNK[-1])
    r.bone(nm + "_b", p1, p2, nm + "_a")
    r.bone(nm + "_c", p2, p3, nm + "_b")
    TAIL_LEGS.append((nm, p0, p1, p2, p3, s))
b = Builder("centipede")

# ---------------------------------------------------------------- the trunk: tergites over sternites


def plate_col(i):
    def fn(t, ang):
        cy = math.cos(ang)
        v = 0.72 + 0.08 * (1.0 - t)                   # a little paler towards the front of each plate
        if i == 0:
            v = 0.82                                    # the first tergite is the head's colour
        v *= 1.0 - 0.45 * smooth(0.82, 0.97, t)         # the black band along the back edge
        v *= 1.0 + 0.12 * smooth(0.2, 0.9, cy)
        # the paired grooves either side of the midline of the back
        v *= 1.0 - 0.18 * (smooth(0.06, 0.0, abs(abs(math.sin(ang)) - 0.35)) * smooth(0.0, 0.5, cy))
        # pale underneath (the sternites)
        v = v + (0.9 - v) * smooth(-0.3, -0.8, cy)
        return X.grey(min(1.0, v))
    return fn


for i in range(N):
    a = V(0, BY, zc(i) + SEG * 0.08)
    c = V(0, BY, zc(i + 1))
    w = width(i)
    X.segment(b, a, c, w, w * 0.38, bone=TRUNK[i], up=UP, n=18, rings=6, neck=0.12, neck_len=0.15, swell=0.04, taper=0.0, rim=0.05,
              keels=((math.pi * 0.5, 0.12), (-math.pi * 0.5, 0.12)), flat=0.45, flat_top=0.35, col_fn=plate_col(i))

# ---------------------------------------------------------------- the head shield, the eyes, the antennae, the fangs
X.segment(b, V(0, BY, Z0 - 0.01), V(0, BY + 0.006, Z0 + 0.17), 0.085, 0.034, bone="head", up=UP, n=20, rings=8, neck=0.0, swell=0.06, swell_at=0.4,
          taper=0.35, rim=0.0, flat=0.5, flat_top=0.3, col_fn=lambda t, ang: X.grey(min(1.0, (0.86 - 0.08 * t) * (1.0 + 0.1 * math.cos(ang)))))
for s, sd in ((1, "L"), (-1, "R")):
    # a cluster of four simple eyes at each front corner of the shield
    for k, (dx, dz) in enumerate(((0.0, 0.0), (0.016, -0.012), (-0.004, -0.02), (0.014, 0.01))):
        X.bead_eye(b, HC + V((0.058 + dx) * s, 0.025, 0.04 + dz), 0.009 if k else 0.012, "head", fwd=V(0.6 * s, 0.6, 0.5), accent=True, glint=k == 0)
    a0, a1, a2 = r.head("ant0.%s" % sd), r.tail("ant0.%s" % sd), r.tail("ant1.%s" % sd)
    # the antennae: seventeen beaded joints, tapering
    pts = catmull([a0, a0.lerp(a1, 0.5) + V(0, 0.015, 0), a1, a1.lerp(a2, 0.5) + V(0.01 * s, 0.01, 0), a2], 4)
    n = len(pts)
    bones = [{"ant0.%s" % sd: 1.0} if q < n // 2 else {"ant1.%s" % sd: 1.0} for q in range(n)]
    b.tube(pts, [0.011 * (1.0 - 0.75 * q / (n - 1)) * (1.0 + 0.18 * (q % 2)) for q in range(n)], "c8b890", cls=X.CHITIN, bones=bones, seg=6, tint=1.0)
    # the forcipules: a thick basal joint and a curved fang, black-tipped, meeting across the mouth
    f0, f1 = r.head("fang.%s" % sd), r.tail("fang.%s" % sd)
    X.segment(b, f0 - V(0.01 * s, 0, 0.01), f1, 0.026, 0.02, bone="fang.%s" % sd, up=UP, n=12, rings=6, neck=0.2, swell=0.15, taper=0.2, col=0.8)
    X.finger(b, [f1 - V(0, 0, 0.01), f1 + V(-0.02 * s, -0.004, 0.035), f1 + V(-0.055 * s, -0.008, 0.045)], 0.018, 0.015, "fang.%s" % sd, col0=0.82,
             col1="120a08", tip_from=0.45, tint_tip=0.0, n=10)
# the venom gland's glow at the root of the fangs (the accent)
b.cur_pal = 1.0
b.ellipsoid(HC + V(0, -0.025, 0.06), (0.03, 0.012, 0.02), "f8f8f8", cls=CRYSTAL, bone="head", seg=10, rings=6, mat=MAT_GLOW, tint=1.0)
b.cur_pal = 0.0

# ---------------------------------------------------------------- legs, on the secondary colour, dark-clawed
b.cur_pal = 0.5
for nm, root, knee, foot, s, i in LEG_INFO:
    out = V(s, 0, 0)
    fd = (foot - knee).normalized()
    ta = knee.lerp(foot, 0.78)
    X.limb(b, [root, knee, ta], [0.013, 0.0095], [nm + "_a", nm + "_b"], out=out, neck=0.2, swell=0.05, taper=0.2, rim=0.08, col=0.82, back=0.04,
           belly=0.2, joint=0.35, n=8, rings=5)
    X.finger(b, [ta - fd * 0.008, ta.lerp(foot, 0.6) + V(0, 0.004, 0), foot], 0.0075, 0.0075, nm + "_b", up=out, col0=0.85, col1="1a120c", tip_from=0.55,
             tint_tip=0.0, n=6, per=3)
for nm, p0, p1, p2, p3, s in TAIL_LEGS:
    out = V(s, 0, 0)
    X.limb(b, [p0, p1, p2, p3 - (p3 - p2) * 0.3], [0.026, 0.021, 0.016], [nm + "_a", nm + "_b", nm + "_c"], out=out, neck=0.2, swell=0.1, taper=0.15,
           rim=0.08, col=0.78, back=0.05, belly=0.2, joint=0.35, n=10, rings=7)
    X.finger(b, [p3 - (p3 - p2) * 0.35, p3 + V(0.006 * s, 0.0, -0.02), p3 + V(0.01 * s, 0.004, -0.05)], 0.013, 0.012, nm + "_c", up=out, col0=0.8,
             col1="1a120c", tip_from=0.4, tint_tip=0.0, n=8)
    # spines along the inside of the femur, as the Scolopendra has them
    X.spine_row(b, p0, p1, V(-s, 0.4, 0), 4, 0.026, 0.006, nm + "_a", col0=0.8, col1="2a1e14", tint=0.5)
b.cur_pal = 0.0

# ---------------------------------------------------------------- motion
WALK = Walker(r, LEGS, PHASES, duty=0.62)
T_IDLE = 2.2
T_WALK = 1.0


def wave(p, t, T, amp, lag=0.42, lift=0.0):
    """A travelling wave of yaw down the trunk, from the head back."""
    w = 2 * math.pi / T
    for i, nm in enumerate(TRUNK):
        add(p, nm, (lift * (1.0 if i < 3 else 0.0), amp * math.sin(w * t - i * lag) * (1.0 if i else 0.5), 0))


def feelers(p, t, T, amp=1.0):
    w = 2 * math.pi / T
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "ant0.%s" % sd, (0.15 * amp * math.sin(w * t * 2 + s), 0.2 * amp * math.sin(w * t + s * 0.7), 0))
        add(p, "ant1.%s" % sd, (0.25 * amp * math.sin(w * t * 2 + 1.0 + s), 0.15 * amp * math.sin(w * t * 1.5), 0))


def tail_legs(p, t, T, amp=1.0):
    w = 2 * math.pi / T
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "ult.%s_a" % sd, (0.05 * amp * math.sin(w * t + s), 0.08 * amp * s * math.sin(w * t * 0.5), 0))


def idle(t):
    p = zero_pose(r)
    wave(p, t, T_IDLE, 0.025)
    feelers(p, t, T_IDLE)
    tail_legs(p, t, T_IDLE)
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "fang.%s" % sd, (0, 0.08 * s * math.sin(2 * math.pi * t / T_IDLE * 2), 0))
    return WALK.step(p)


def walk(t):
    ph = (t / T_WALK) % 1.0
    p = zero_pose(r)
    wave(p, ph * T_WALK, T_WALK, 0.045)
    feelers(p, t, T_WALK, 1.3)
    tail_legs(p, t, T_WALK, 0.6)
    return WALK.step(p, ph, 0.07, 0.035)


def rear(p, k, high=1.0):
    """Lift the front third off the ground: the first segments pitch up, the next ones level it out."""
    add(p, "t0", (-0.3 * k * high, 0, 0))
    add(p, "t1", (-0.25 * k * high, 0, 0))
    add(p, "t2", (-0.18 * k * high, 0, 0))
    add(p, "t3", (0.2 * k * high, 0, 0))
    add(p, "t4", (0.28 * k * high, 0, 0))
    add(p, "t5", (0.18 * k * high, 0, 0))
    add(p, "head", (0.35 * k * high, 0, 0))


def attack(t):
    k = t / 0.55
    up = smooth(0.0, 0.32, k) * (1.0 - smooth(0.36, 0.5, k))
    strike = smooth(0.36, 0.5, k) * (1.0 - smooth(0.7, 1.0, k))
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0, 0.12 * strike))
    rear(p, up)
    add(p, "t0", (0.25 * strike, 0, 0))
    add(p, "head", (0.25 * strike, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        # the fangs open wide as it rises and slam shut on the strike
        add(p, "fang.%s" % sd, (0, 0.7 * s * up - 0.4 * s * strike, 0))
        add(p, "ant0.%s" % sd, (0.6 * up, 0.3 * s * up, 0))
    feelers(p, t, 0.55, 0.4)
    return WALK.step(p)


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    # a writhe: the body throws itself into an S
    for i, nm in enumerate(TRUNK):
        add(p, nm, (0, 0.14 * e * math.sin(i * 0.5 + 1.0), 0.08 * e * math.sin(i * 0.4)))
    add(p, "head", (-0.3 * e, 0.3 * e, 0))
    return WALK.step(p)


def die(t):
    p = zero_pose(r)
    p = WALK.step(p)
    k = min(1.0, t / 1.2)
    curl = []
    for nm, root, knee, foot, s, i in LEG_INFO:
        curl.append((nm + "_a", (0.0, 0.0, -0.9 * s)))
        curl.append((nm + "_b", (0.0, 0.0, -1.2 * s)))
    # the body curls a little as it rolls over
    for i, nm in enumerate(TRUNK):
        add(p, nm, (0, 0.05 * smooth(0.3, 1.0, k) * math.sin(i * 0.3), 0))
    flip_die(p, t, 1.2, BY, side=1, curl_legs=curl, rest=0.035)
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    rear(p, e, 1.5)
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "fang.%s" % sd, (0, 0.9 * s * e, 0))
        add(p, "ant0.%s" % sd, (0.5 * e, 0.6 * s * e, 0))
    wave(p, t, 0.3, 0.03 * e)
    ph = (t / 0.3) % 1.0
    return WALK.step(p, ph, 0.03 * e, 0.03 * e)


print("[art] centipede: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/centipede.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt),
                                                   "die": (1.2, die), "cast": (0.6, cast)}, samples=12, dist=0.2, strength=0.45, floor_y=0.0)
