"""Golem: a walking mountain of hewn stone (Lava Titan, Glass Colossus, Bronze Sentinel, Crucible
Golem, the Sentinel of the Stone Forest ...).

Designed silhouette first: a top-heavy wedge of a body whose highest points are the karst spires
standing up from its back and shoulders (the limestone pillars of the Stone Forest of Yunnan, or a
landscape painter's peaks), a small wedge of a head sunk low and forward between huge shoulder
stones, gorilla arms whose forearms and fists are the heaviest blocks of all and hang to the
knees, and short bowed legs on flat foot slabs, so it looks as heavy as it is.  It is built of a
few big blocks of fractured stone (``elemental.hewn``: flat planes, narrow chamfers, lighter worn
edges, never round boulders), lit above and dark at the feet.  One focal point: the heart of the
construct glows through a forked fissure in its chest, and the same light shows in the slit of
its eyes under a heavy brow; the joints are dark.  A cluster of crystals grows out of one
shoulder in the second colour.  The stone and the light take the enemy's colours.
Run: blender --background --python art/monsters/golem.py  ->  assets/monsters/golem.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
from creature import Walker, add, smooth, zero_pose  # noqa: E402
from elemental import crack, frame_y, hewn  # noqa: E402
from kit import CLOTH, MAT_GLOW, V, Builder, Rig, env  # noqa: E402

kit.reset()
creature.realtime()

SH = {1: V(0.64, 1.8, -0.02), -1: V(-0.64, 1.8, -0.02)}     # shoulder joints
EL = {s: V(0.82 * s, 1.27, 0.04) for s in (1, -1)}           # elbows
WR = {s: V(0.88 * s, 0.74, 0.2) for s in (1, -1)}            # wrists
HIP = {s: V(0.26 * s, 0.9, 0.0) for s in (1, -1)}
KN = {s: V(0.3 * s, 0.5, 0.07) for s in (1, -1)}
AN = {s: V(0.31 * s, 0.13, 0.0) for s in (1, -1)}

r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("hips", (0, 0.9, 0), (0, 1.14, 0.02), "root")
r.bone("chest", (0, 1.14, 0.02), (0, 1.8, 0.14), "hips")
r.bone("head", (0, 1.74, 0.3), (0, 1.94, 0.44), "chest")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm.%s" % sd, SH[s], EL[s], "chest")
    r.bone("fore.%s" % sd, EL[s], WR[s], "arm.%s" % sd)
    r.bone("thigh.%s" % sd, HIP[s], KN[s], "hips")
    r.bone("shin.%s" % sd, KN[s], AN[s], "thigh.%s" % sd)
    # the foot slab hangs from the ankle on a bone of its own, so it can stay flat on the ground
    r.bone("foot.%s" % sd, AN[s], AN[s] + V(0, -0.06, 0.2), "shin.%s" % sd)

b = Builder("golem")
DARK = (0.05, 1.0, 0.22)      # the legs and feet sink into darker stone: lit above, heavy below
S = [100]


def nxt():
    S[0] += 7
    return S[0]


def stone(c, half, bone, shade=0.78, **kw):
    kw.setdefault("dark_below", DARK)
    kw.setdefault("cuts", 8)
    kw.setdefault("depth", (0.1, 0.36))
    kw.setdefault("jitter", 0.06)
    return hewn(b, c, half, nxt(), bone, shade=shade, **kw)


def glow(c, radii, bone, rot=(0, 0, 0), k=1.0, seg=14, rings=9):
    """A glowing part in the accent colour (the element's fire, frost, lightning ...)."""
    old = b.cur_pal
    b.cur_pal = 1.0
    b.ellipsoid(c, radii, (k, k, k), cls=CLOTH, bone=bone, tint=1.0, mat=MAT_GLOW, rot=rot, seg=seg, rings=rings)
    b.cur_pal = old


def seam(planes, centre, dirs, bone, width=0.013):
    """A glowing crack running over a block through the given directions from its centre."""
    crack(b, planes, centre, dirs, bone, width=width, seed=nxt())


# ---------------------------------------------------------------- the heart, seen through the chest
glow(V(0, 1.44, 0.12), (0.13, 0.22, 0.09), "chest")
glow(V(0, 1.44, 0.17), (0.06, 0.15, 0.04), "chest", k=0.9)
# dark stone behind the fissure so the light reads as coming from deep inside
stone(V(0, 1.47, 0.0), (0.2, 0.3, 0.1), "chest", shade=0.28, cuts=2, bevel=0.0, dark_below=None, jitter=0.0)

# ---------------------------------------------------------------- torso: pelvis, belly, chest, back
stone(V(0, 0.98, 0.0), (0.31, 0.16, 0.23), "hips", rock=11, depth=(0.05, 0.25))
# the belly block, notched at the top where the fissure forks down into it
stone(V(0, 1.2, 0.08), (0.27, 0.13, 0.2), "chest", shade=0.72, taper=(1.15, 1.1),
      extra=[((0.6, 0.8, 0.5), 0.17), ((-0.6, 0.8, 0.5), 0.17)])
# two great breast stones split by a forked fissure that the heart shines through
for s in (1, -1):
    pec, pp = stone(V(0.22 * s, 1.56, 0.16), (0.2, 0.25, 0.17), "chest", shade=0.84, rot=(0.1, 0.22 * s, -0.06 * s),
                    taper=(1.15, 1.0), base=(0.75, 0.9), extra=[((-s, 0.2, 0.0), 0.15), ((-s, -0.9, 0.3), 0.17)], jitter=0.03, cuts=10)
    seam(pp, V(0.22 * s, 1.56, 0.16), [(-0.95 * s, -0.25, 0.5), (-0.45 * s, 0.0, 0.9), (0.15 * s, 0.35, 1.0)], "chest")
back, bp = stone(V(0, 1.6, -0.13), (0.46, 0.34, 0.22), "chest", shade=0.8, rock=12, taper=(1.05, 1.0), depth=(0.05, 0.25))
seam(bp, V(0, 1.6, -0.13), [(0.7, 0.4, -0.6), (0.15, -0.05, -1.0), (-0.4, -0.5, -0.8)], "chest")
# the hunched mass between the shoulders, which the head sinks into
stone(V(0, 1.87, -0.04), (0.3, 0.12, 0.22), "chest", shade=0.86, taper=(0.8, 0.85))

# ---------------------------------------------------------------- the karst spires on its back
for (x, y, z, h, w, lean, out) in ((0.2, 2.08, -0.22, 0.34, 0.1, -0.35, -0.22), (-0.13, 2.0, -0.3, 0.26, 0.085, -0.5, 0.25),
                                   (0.5, 2.06, -0.1, 0.2, 0.075, -0.2, -0.45)):
    stone(V(x, y, z), (w, h, w * 0.9), "chest", shade=0.86, rot=(lean, 0.3, out), taper=(0.28, 0.32), cuts=4,
          depth=(0.05, 0.2), bevel=0.012)
# a cluster of crystals bursting out of the right shoulder (the second colour): the silhouette's one asymmetry
old = b.cur_pal
b.cur_pal = 0.5
for k, (dx, dz, h, tilt, turn) in enumerate(((0.0, -0.02, 0.44, 0.15, 0.0), (0.09, 0.06, 0.3, 0.6, 0.8), (-0.08, 0.04, 0.26, -0.35, 1.9),
                                              (0.02, -0.11, 0.22, 0.45, 3.1), (-0.05, -0.08, 0.16, -0.7, 4.2))):
    b.crystal(V(-0.66 + dx, 2.04, -0.06 + dz), 0.06 + 0.015 * (k == 0), h, (0.95, 0.95, 0.95), bone="arm.R", tint=1.0,
              rot=(tilt * 0.7, turn, 0.4 + tilt * 0.5))
b.cur_pal = old

# ---------------------------------------------------------------- the head: a small wedge sunk low between the shoulders
stone(V(0, 1.8, 0.36), (0.14, 0.12, 0.13), "head", shade=0.8, taper=(0.95, 0.9), base=(0.72, 0.85), rot=(0.12, 0, 0), cuts=6)
# a heavy brow that overhangs and shadows the eyes, and a chin set back under the face
stone(V(0, 1.9, 0.44), (0.21, 0.06, 0.11), "head", shade=0.92, rot=(-0.2, 0, 0), rock=11, depth=(0.05, 0.3), bevel=0.012)
stone(V(0, 1.69, 0.38), (0.095, 0.05, 0.075), "head", shade=0.66, rot=(0.15, 0, 0), rock=8, bevel=0.012)
for s in (1, -1):
    glow(V(0.062 * s, 1.84, 0.49), (0.05, 0.018, 0.014), "head", rot=(0, 0, 0.18 * s), seg=10, rings=5)

# ---------------------------------------------------------------- arms: shoulder stones, upper arms, the great forearms and fists
# (big, medium, small: the forearm and the fist are the heaviest blocks; every block overlaps the next)
for s, sd in ((1, "L"), (-1, "R")):
    arm, fore = "arm." + sd, "fore." + sd
    stone(SH[s] + V(0.04 * s, 0.1, 0.0), (0.29, 0.25, 0.29), arm, shade=0.86, rot=(0.1, 0.4 * s, -0.25 * s), taper=(0.85, 0.85), rock=16)
    du = EL[s] - SH[s]
    stone(SH[s].lerp(EL[s], 0.5), (0.14, du.length * 0.58, 0.14), arm, shade=0.74, rot=frame_y(du), rock=12)
    # the point of the elbow, bridging the upper arm and the forearm
    stone(EL[s] + V(0.02 * s, 0.02, -0.08), (0.11, 0.1, 0.1), arm, shade=0.7, rock=9)
    df = WR[s] - EL[s]
    fa, fp = stone(EL[s].lerp(WR[s], 0.55), (0.21, df.length * 0.6, 0.2), fore, shade=0.82, rot=frame_y(df), taper=(1.25, 1.25), rock=15)
    seam(fp, EL[s].lerp(WR[s], 0.55), [(0.9 * s, 0.55, 0.3), (1.0 * s, 0.05, 0.25), (0.85 * s, -0.5, 0.4)], fore, 0.011)
    # the fist: a block of a hand grown out of the forearm, a row of knuckle stones and a thumb
    fist = WR[s] + V(0.03 * s, -0.15, 0.06)
    stone(fist, (0.23, 0.19, 0.22), fore, shade=0.84, rot=(0.15, 0.1 * s, 0.05 * s), rock=14)
    for k in range(4):
        u = (k - 1.5) / 1.5
        stone(fist + V(u * 0.135 * s, -0.11 - 0.015 * abs(u), 0.18), (0.075, 0.08, 0.08), fore, shade=0.88, rock=10, bevel=0.012)
    stone(fist + V(-0.19 * s, -0.02, 0.13), (0.07, 0.1, 0.075), fore, shade=0.8, rot=(0.3, 0, 0.3 * s), rock=10, bevel=0.012)

# ---------------------------------------------------------------- legs: thigh, shin and a broad foot slab
for s, sd in ((1, "L"), (-1, "R")):
    th, sn = "thigh." + sd, "shin." + sd
    stone(HIP[s].lerp(KN[s], 0.5) + V(0.02 * s, 0, 0), (0.19, 0.25, 0.2), th, shade=0.78, rot=frame_y(KN[s] - HIP[s]), rock=13)
    stone(KN[s].lerp(AN[s], 0.5), (0.17, 0.24, 0.18), sn, shade=0.74, rot=frame_y(AN[s] - KN[s]), taper=(1.1, 1.1), rock=12)
    stone(V(0.32 * s, 0.075, 0.09), (0.21, 0.08, 0.27), "foot." + sd, shade=0.66, taper=(0.85, 0.85), extra=[((0, 0.55, 1.0), 0.24)])

T = 3.0


def idle(t):
    w = 2 * math.pi / T
    br = math.sin(t * w)
    p = zero_pose(r)
    p["hips"] = ((0, math.sin(t * w + 0.5) * 0.04, 0), (0, br * 0.02, 0))
    p["chest"] = ((0.06 + br * 0.03, math.sin(t * w) * 0.05, 0), (0, 0, 0))
    p["head"] = ((-0.06, math.sin(t * w) * 0.15, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((math.sin(t * w + s) * 0.05, 0, 0.04 * s * br), (0, 0, 0))
        p["fore.%s" % sd] = ((-0.12, 0, 0), (0, 0, 0))
        p["shin.%s" % sd] = ((0.08, 0, 0), (0, 0, 0))
        p["thigh.%s" % sd] = ((-0.08, 0, 0), (0, 0, 0))
    return p


def attack(t):
    """Both fists raised over the head, then brought down together on the ground."""
    k = t / 0.55
    e = env(k)
    up = math.sin(min(1.0, k / 0.45) * math.pi / 2)
    slam = max(0.0, min(1.0, (k - 0.45) / 0.2))
    p = idle(0.0)
    p["chest"] = ((-0.3 * up + 0.75 * slam, 0, 0), (0, 0, 0))
    p["root"] = ((0, 0, 0), (0, 0, 0.3 * slam * e))
    for sd in ("L", "R"):
        p["arm.%s" % sd] = ((-2.5 * up + 2.1 * slam, 0, 0), (0, 0, 0))
        p["fore.%s" % sd] = ((-0.6 * up, 0, 0), (0, 0, 0))
    p["thigh.L"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["shin.L"] = ((0.4 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["chest"] = ((-0.25 * e, 0.15 * e, 0.1 * e), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["root"] = ((0, 0, 0), (0, 0, -0.15 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["chest"] = ((-0.25 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((-0.4 * e, 0, s * 1.1 * e), (0, 0, 0))
        p["fore.%s" % sd] = ((-0.8 * e, 0, 0), (0, 0, 0))
    return p


T_WALK = 1.6
WALK = Walker(r, [("thigh.L", "shin.L"), ("thigh.R", "shin.R")], [0.0, 0.5], duty=0.62, sagittal=True)


def walk(t):
    """A heavy biped stride: the hips shift over the planted foot and drop on each step, the
    chest counter-turns and the long arms swing like pendulums."""
    ph = (t / T_WALK) % 1.0
    w = 2 * math.pi
    p = zero_pose(r)
    add(p, "hips", (0.04, 0.08 * math.sin(w * ph), 0.05 * math.sin(w * ph)), (0.05 * math.sin(w * ph), -0.04 * abs(math.cos(w * ph)), 0))
    add(p, "chest", (0.08, -0.12 * math.sin(w * ph), -0.03 * math.sin(w * ph)))
    add(p, "head", (-0.04, 0.06 * math.sin(w * ph), 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm.%s" % sd, (0.3 * s_ * math.sin(w * ph), 0, 0.04 * s_))
        add(p, "fore.%s" % sd, (-0.15 - 0.12 * max(0.0, s_ * math.sin(w * ph)), 0, 0))
    p = WALK.step(p, ph, 0.5, 0.14)
    return level_feet(p)


def level_feet(p):
    """Turn each foot slab back by what its leg has turned, so it stays flat on the ground."""
    for sd in ("L", "R"):
        tilt = p["root"][0][0] + p["hips"][0][0] + p["thigh." + sd][0][0] + p["shin." + sd][0][0]
        p["foot." + sd] = ((-tilt, 0.0, 0.0), (0, 0, 0))
    return p


def die(t):
    """The knees give, the construct pitches forward onto its face and its blocks settle."""
    k = min(1.0, t / 1.2)
    buckle = smooth(0.0, 0.35, k)
    f = smooth(0.3, 0.8, k)
    p = zero_pose(r)
    a = 1.4 * f
    q = V(0, 0, 0.32)
    R = creature.euler_g((a, 0.0, 0.0))
    off = q - R @ q
    add(p, "root", (a, 0.0, 0.0), (off.x, off.y - 0.35 * buckle * (1.0 - f) + 0.3 * f, off.z))
    add(p, "chest", (0.15 * buckle, 0.1 * f, 0.08 * f))
    add(p, "head", (0.3 * buckle, 0.4 * f, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "thigh.%s" % sd, (-0.8 * buckle * (1.0 - 0.6 * f), 0, 0))
        add(p, "shin.%s" % sd, (1.2 * buckle * (1.0 - 0.6 * f), 0, 0))
        # the arms fall splayed out to the sides, not under the body
        add(p, "arm.%s" % sd, (0.3 * f, 0, s_ * 1.25 * f))
        add(p, "fore.%s" % sd, (-0.3 * f, 0, 0))
    # the feet stay flat while the knees give, then go over with the body
    flat = level_feet({nm: v for nm, v in p.items()})
    for sd in ("L", "R"):
        add(p, "foot." + sd, (flat["foot." + sd][0][0] * (1.0 - f), 0.0, 0.0))
    return p


print("[art] golem: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/golem.glb", {"idle": (T, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=14, dist=0.3, strength=0.5, floor_y=0.0)
