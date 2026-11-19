"""Owl (new in the Turned Face release): the Owl That Moved East, and the night birds of Part XLIV.

The owl was moving east.  A dove met it and asked why.  "The people of this village hate my cry."  "If
you can change your cry, stay.  If you cannot, the people of the east will hate it too."  So the Shuo
Yuan, which is the whole of the Turned Face release in four sentences.

After the Eurasian eagle-owl (Bubo bubo, the xiao the old books call an unfilial bird):

* **Silhouette.**  Upright and barrel-chested, standing on a pair of feathered legs with the toes
  splayed; a big round head with no neck to speak of, and on it the two ear-tufts standing up and out
  like horns: those and the great round eyes are what the eye reads first.  The folded wings lie along
  the flanks and cross over the short tail.
* **Head.**  The facial disc, a shallow dish of stiff pale feathers ringed by a dark rim, set round two
  huge forward-facing eyes (orange in the eagle-owl; here the accent colour) with a round black pupil;
  a short hooked beak, dark, half hidden in the bristles between them.
* **Value.**  The back and the wings dark and mottled; the breast paler, streaked with dark drops down
  the middle and finely barred on the belly; the facial disc and the throat palest; the flight feathers
  barred across.  The plumage takes the enemy's colour, the eyes the accent, the beak and the talons
  keep their black.

Clips: idle (the head turns slowly round, the way an owl's does, and back; the tufts twitch), walk (low,
silent flight: the wings beat slow and deep, the legs tucked), attack (rises and drops on the prey with
the talons thrown forward and the wings back), hurt, die (drops onto its back on the ground, wings out),
cast (mantles: the wings spread wide and low, the head thrust forward, and it screeches).
Run: blender --background --python art/monsters/owl.py  ->  assets/monsters/owl.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
import arthropod as X  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from creature import add, smooth, zero_pose  # noqa: E402
from kit import CLOTH, HAIR, MAT_PLAIN, STONE, V, Builder, Rig  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
HC = V(0, 0.86, 0.05)
hf = A.HeadFrame(HC, V(0, 0.0, 1.0))

# ---------------------------------------------------------------- rig
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, 0.24, -0.02), (0, 0.66, 0.03), "root")
r.bone("chest", (0, 0.5, 0.0), (0, 0.72, 0.04), "body")
r.bone("head", (0, 0.72, 0.04), (0, 0.98, 0.06), "chest")
r.bone("tail", (0, 0.3, -0.13), (0, 0.16, -0.33), "body")
WING = {}
for s, sd in ((1, "L"), (-1, "R")):
    S = V(0.15 * s, 0.64, 0.01)
    E = V(0.2 * s, 0.5, -0.07)
    W = V(0.195 * s, 0.36, -0.15)
    T = V(0.15 * s, 0.17, -0.32)
    WING[sd] = (S, E, W, T)
    r.bone("wing0.%s" % sd, S, E, "chest")
    r.bone("wing1.%s" % sd, E, W, "wing0.%s" % sd)
    r.bone("wing2.%s" % sd, W, T, "wing1.%s" % sd)
    r.bone("tuft.%s" % sd, HC + V(0.07 * s, 0.1, 0.0), HC + V(0.11 * s, 0.2, -0.03), "head")
    hip = V(0.075 * s, 0.3, 0.02)
    hock = V(0.085 * s, 0.11, 0.05)
    toe = V(0.09 * s, 0.015, 0.12)
    r.bone("thigh.%s" % sd, hip, hock, "body")
    r.bone("foot.%s" % sd, hock, toe, "thigh.%s" % sd)
b = Builder("owl")


def hp(x, y, z):
    return hf.at(x, y, z)


# ---------------------------------------------------------------- body clay: barrel chest, round head, the wing's leading edge
c = Clay(0.012, "owl_body")
c.ellipsoid(V(0, 0.46, 0.0), (0.2, 0.27, 0.17), bones={"body": 0.8, "chest": 0.2}, tag="body")
c.ellipsoid(V(0, 0.58, 0.05), (0.17, 0.17, 0.15), bones={"chest": 1.0}, tag="breast")
c.ellipsoid(V(0, 0.3, 0.03), (0.15, 0.12, 0.13), bones={"body": 1.0}, tag="belly")
# the head: wider than it is tall, flat across the face
c.ellipsoid(HC, (0.17, 0.15, 0.14), bones={"head": 1.0}, tag="head")
# the facial disc is a dish: hollowed either side of the beak
for s in (1, -1):
    c.ellipsoid(hp(0.065 * s, 0.005, 0.15), (0.06, 0.065, 0.045), bones={"head": 1.0}, tag="disc", neg=True)
c.ellipsoid(hp(0, -0.06, 0.08), (0.11, 0.06, 0.07), bones={"head": 1.0}, tag="disc")
for s, sd in ((1, "L"), (-1, "R")):
    S, E, W, T = WING[sd]
    c.chain([S, E, W], [0.07, 0.06, 0.045], bones=limb_weights(["wing0.%s" % sd, "wing1.%s" % sd]), tag="wing", t0=0.0, t1=2.0)
    # the feathered legs: trousers of down to the toes
    hip, hock = r.head("thigh.%s" % sd), r.tail("thigh.%s" % sd)
    c.chain([hip, hock], [0.06, 0.04], bones=limb_weights(["thigh.%s" % sd]), tag="leg", t0=0.0, t1=1.0)
    c.ellipsoid(hock + V(0, -0.04, 0.03), (0.035, 0.04, 0.045), bones={"foot.%s" % sd: 1.0}, tag="leg")


def head_local(p):
    return hf.M.transposed() @ (p - HC)


def col(p, info):
    g = fbm3((p.x * 14.0, p.y * 14.0, p.z * 14.0), 3, 21)
    tag = info.tag
    n = info.n
    v = 0.76 + 0.12 * (g - 0.5)
    if tag in ("breast", "belly", "body"):
        # paler down the front, streaked with dark drops down the middle, finely barred on the belly
        front = smooth(0.0, 0.7, n.z)
        v = v * (1.0 - front) + (0.9 + 0.05 * (g - 0.5)) * front
        drop = smooth(0.4, 0.9, math.sin(p.x * 70.0 + 0.5 * math.sin(p.y * 30.0))) * smooth(0.72, 0.4, p.y) * smooth(0.25, 0.6, p.y)
        v -= 0.3 * drop * front * smooth(0.1, 0.0, abs(p.x) - 0.06)
        v -= 0.12 * smooth(0.5, 0.95, math.sin(p.y * 160.0)) * front * smooth(0.45, 0.25, p.y)
    if tag in ("head", "disc"):
        q = head_local(p)
        # the facial disc: palest in the dish, ringed by a dark rim
        rr = math.hypot(q.x * 0.9, q.y + 0.01)
        face = smooth(0.0, 0.08, q.z) * smooth(0.15, 0.1, rr)
        v = v * (1.0 - face) + 0.9 * face
        v -= 0.35 * smooth(0.02, 0.0, abs(rr - 0.13)) * smooth(-0.02, 0.06, q.z)
        # the crown darker, streaked
        v -= 0.12 * smooth(0.06, 0.13, q.y) * smooth(0.5, 0.9, math.sin(q.x * 90.0))
    if tag == "wing":
        v = 0.7 + 0.12 * (g - 0.5) - 0.08 * smooth(0.6, 0.95, math.sin(p.y * 60.0 + p.z * 40.0))
    if tag == "leg":
        v = 0.86 + 0.05 * (g - 0.5)
    return (min(1.0, v), min(1.0, v), min(1.0, v))


def plumage(p, info):
    """Feathers laid over one another: shallow scallops down the body, ruffled at the face's rim."""
    nn = info.n
    if info.tag in ("disc",):
        return None
    w = fbm3((p.x * 16.0, p.y * 16.0, p.z * 16.0), 2, 17)
    u = -p.y * 32.0 + 0.6 * math.sin(math.atan2(nn.x, nn.z) * 10.0) + 1.1 * w
    k = u - math.floor(u)
    amp = 0.006 if info.tag in ("breast", "belly", "body", "wing") else 0.004
    return nn * (amp * k ** 1.8)


c.build(b, col, cls=HAIR, tint_fn=lambda p, info: 1.0, post=plumage)

# ---------------------------------------------------------------- the face: eyes, beak, bristles, tufts
hit = A.surface(b)
for s in (1, -1):
    d = (hf.f * 0.95 + hf.r * 0.18 * s).normalized()
    base = hp(0.062 * s, 0.01, 0.1)
    h = hit(base + d * 0.3, -d, 0.6)
    ep = h[0] - d * 0.012 if h is not None else base
    A.animal_eye(b, ep, d, 0.036, "ff8a1a", "head", pupil="round", almond=0.95, side=s, lid="1a1410", lid_w=0.14)
# the beak: short, hooked, dark, half buried in the bristles between the eyes
bk = [hp(0, -0.02, 0.135), hp(0, -0.045, 0.165), hp(0, -0.075, 0.16)]
X.finger(b, bk, 0.028, 0.03, "head", col0="3a3430", col1="141210", tip_from=0.4, tint=0.0, tint_tip=0.0, n=10, cls=STONE)
for s in (1, -1):
    for k in range(4):
        a0 = hp(0.01 * s, -0.012 + 0.008 * k, 0.138)
        b.tube([a0, a0 + hf.f * 0.016 + hf.r * (0.008 * s) - hf.u * 0.012], [0.003, 0.0008], "e8e0d0", cls=HAIR, bone="head", seg=4, mat=MAT_PLAIN, tint=0.6)
# the ear tufts: a fan of feathers standing up and out from each brow
for s, sd in ((1, "L"), (-1, "R")):
    t0 = r.head("tuft.%s" % sd)
    for k in range(5):
        tip = r.tail("tuft.%s" % sd) + V(0.012 * s * (k - 2), 0.02 * (2 - abs(k - 2)) - 0.01 * k, -0.015 * k)
        A.feather(b, t0 + V(-0.01 * s * k, -0.012 * k, -0.005 * k), tip, 0.022, "807060", col_tip="3a3028", side=V(0, 0, 1), bone="tuft.%s" % sd, tint=1.0,
                  curl=0.08)

# ---------------------------------------------------------------- the wings: secondaries along the forearm, primaries from the hand
for s, sd in ((1, "L"), (-1, "R")):
    S, E, W, T = WING[sd]
    out = V(s, 0, 0)
    # covert rows over the arm (short, rounded)
    for k in range(7):
        t = k / 6
        root = E.lerp(W, t) + out * 0.02 + V(0, 0.02, 0)
        A.feather(b, root, root + V(0.01 * s, -0.11, -0.07), 0.045, "6a5a48", col_tip="4a3c30", side=V(0, 0, 1), bone="wing1.%s" % sd, tint=1.0, curl=0.05)
    # the secondaries: long, square-tipped, barred across, lying back along the flank
    for k in range(9):
        t = k / 8
        root = E.lerp(W, t) + out * 0.012
        tip = root + V(-0.01 * s, -0.24 + 0.03 * t, -0.13 - 0.03 * t)
        A.feather(b, root, tip, 0.055, "7a6a56", col_tip="3a3028", side=V(0, 0, 1), bone="wing1.%s" % sd, tint=1.0, curl=0.04)
    # the primaries: longest at the wing's tip, crossing over the tail
    for k in range(8):
        t = k / 7
        root = W.lerp(T, 0.25 * t) + out * 0.01
        tip = T + V(-0.03 * s * t, -0.08 + 0.05 * t, -0.08 - 0.06 * (1.0 - t))
        A.feather(b, root, tip, 0.045, "6a5a48", col_tip="2a2018", side=V(0, 0, 1), bone="wing2.%s" % sd, tint=1.0, curl=0.04)
# the tail: short and barred, under the crossed primaries
for k in range(7):
    a = (k - 3) * 0.12
    root = V(0.02 * (k - 3), 0.3, -0.12)
    tip = V(math.sin(a) * 0.12, 0.13, -0.32)
    A.feather(b, root, tip, 0.05, "7a6a56", col_tip="3a3028", side=V(1, 0, 0), bone="tail", tint=1.0, curl=0.03)

# ---------------------------------------------------------------- the talons: four toes, two forward and two back, black hooks
for s, sd in ((1, "L"), (-1, "R")):
    hock = r.tail("thigh.%s" % sd)
    base = V(hock.x, 0.03, hock.z + 0.03)
    for k, (dx, dz) in enumerate(((0.025, 0.07), (-0.01, 0.075), (0.04, -0.02), (-0.03, -0.045))):
        dx *= s
        p1 = base + V(dx * 0.5, 0.0, dz * 0.5)
        p2 = base + V(dx, -0.012, dz)
        # the toe, feathered to the last joint, then the bare talon curling down
        b.tube([base, p1, p2], [0.016, 0.013, 0.011], "c8b8a0", cls=HAIR, bone="foot.%s" % sd, seg=6, tint=0.6)
        X.finger(b, [p2, p2 + V(dx * 0.35, 0.0, dz * 0.35), p2 + V(dx * 0.5, -0.03, dz * 0.5)], 0.01, 0.011, "foot.%s" % sd, col0="2a2622",
                 col1="0e0c0a", tip_from=0.3, tint=0.0, tint_tip=0.0, n=8, cls=STONE)

# ---------------------------------------------------------------- motion
SIDES = (("L", 1), ("R", -1))
T_IDLE = 3.2
T_WALK = 0.8


def fold(p, k=1.0):
    """Nothing: the rest pose is the folded wing."""
    return p


def spread(p, k, beat=0.0, s_up=1.0):
    """Open the wings: the arm swings out and up, the forearm and the hand straighten; `beat` (-1..1)
    raises (+) or sweeps down (-) the whole wing."""
    for sd, s in SIDES:
        add(p, "wing0.%s" % sd, (-0.5 * k, -0.4 * s * k, (1.4 * k + 0.7 * beat * k * s_up) * s))
        add(p, "wing1.%s" % sd, (0.0, 0.9 * s * k, 0.25 * s * k))
        add(p, "wing2.%s" % sd, (0.0, 0.6 * s * k, -0.15 * beat * k * s))


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    # the head turns slowly round, holds, and turns back; a little bob to judge the distance
    turn = 1.1 * math.sin(w * t) ** 3
    add(p, "head", (0.05 * math.sin(w * t * 4) ** 2, turn, 0.04 * math.sin(w * t * 2)))
    add(p, "body", (0.02 * math.sin(w * t), 0, 0), (0, 0.004 * math.sin(w * t * 2), 0))
    for sd, s in SIDES:
        add(p, "tuft.%s" % sd, (0.1 * max(0.0, math.sin(w * t * 3 + s)) ** 4, 0, 0))
    add(p, "tail", (0.04 * math.sin(w * t * 2), 0, 0))
    return p


def walk(t):
    """Low silent flight: the body lifts and leans forward, the wings beat slow and deep, the legs tuck."""
    ph = (t / T_WALK) % 1.0
    beat = math.cos(2 * math.pi * ph)
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.38 + 0.05 * math.sin(2 * math.pi * ph - 0.6), 0))
    add(p, "body", (0.75, 0, 0))
    add(p, "head", (-0.6, 0, 0))
    add(p, "tail", (-0.4, 0, 0))
    spread(p, 1.0, beat)
    for sd, s in SIDES:
        add(p, "thigh.%s" % sd, (-0.6, 0, 0))
        add(p, "foot.%s" % sd, (-0.9, 0, 0))
    return p


def attack(t):
    """Rises on a beat of the wings and drops forward onto the prey with the talons thrown out ahead."""
    k = t / 0.6
    rise = smooth(0.0, 0.35, k) * (1.0 - smooth(0.4, 0.6, k))
    strike = smooth(0.4, 0.55, k) * (1.0 - smooth(0.75, 1.0, k))
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.3 * rise + 0.05 * strike, 0.35 * strike))
    add(p, "body", (-0.35 * strike + 0.2 * rise, 0, 0))
    add(p, "head", (0.3 * strike, 0, 0))
    spread(p, max(rise, strike), 0.8 * rise - 0.6 * strike)
    for sd, s in SIDES:
        add(p, "thigh.%s" % sd, (-1.1 * strike, 0, 0))
        add(p, "foot.%s" % sd, (-0.6 * strike + 0.3 * rise, 0, 0))
    return p


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.02 * e, -0.1 * e))
    add(p, "body", (-0.25 * e, 0, 0.12 * e))
    add(p, "head", (-0.2 * e, 0.4 * e, 0))
    spread(p, 0.45 * e, 0.4 * e)
    return p


def die(t):
    """The wings jerk open, it topples back and lies on the ground on its back with the wings out."""
    k = min(1.0, t / 1.2)
    fall = smooth(0.15, 0.7, k)
    p = zero_pose(r)
    a = -1.5 * fall
    # pivot about the tail's end on the ground: the body ends lying along it
    q = 0.12
    add(p, "root", (a, 0, 0), (0, q * (1.0 - math.cos(a)) + 0.12 * fall - 0.02, -0.25 * fall))
    add(p, "head", (0.4 * fall, 0.6 * fall, 0))
    spread(p, smooth(0.0, 0.3, k) * (1.0 - 0.35 * fall), -0.4 * fall)
    for sd, s in SIDES:
        add(p, "thigh.%s" % sd, (0.6 * fall, 0, 0.2 * s * fall))
        add(p, "foot.%s" % sd, (0.8 * fall, 0, 0))
    return p


def cast(t):
    """Mantles: the wings spread wide and low over the ground, the head thrust forward, the tufts flat."""
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    add(p, "body", (0.35 * e, 0, 0))
    add(p, "head", (-0.15 * e, 0, 0), (0, 0, 0.04 * e))
    spread(p, e, -0.5)
    for sd, s in SIDES:
        add(p, "tuft.%s" % sd, (0.6 * e, 0, -0.4 * s * e))
    return p


print("[art] owl: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/owl.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.6, attack), "hurt": (0.55, hurt), "die": (1.2, die),
                                             "cast": (0.6, cast)}, samples=14, dist=0.25, strength=0.45, floor_y=0.0)
