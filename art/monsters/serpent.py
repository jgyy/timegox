"""Serpent: the great snakes and eels (Kelp Serpent, Ash Salamander, Tide Hydra, Rainbow Serpent, Chaos
Eel, Rot-Root Hydra, Silkworm Queen, the Serpent Beneath the Naihe Bridge, the Jiao of the Silted
Ford ...).

After viper anatomy: a long body coiled on the ground and rearing into an S-shaped neck, its scales
sculpted in diagonal rows (keeled, overlapping tailwards) with a bold pattern of dark-edged saddles
down the back over paler flanks, and broad pale ventral scutes under the belly.  The head is the
viper's wedge, much wider than the neck behind it where the venom glands swell the angles of the
jaw, flat on top under big plates; the supraocular scales jut out over the eyes like a frown, a
ridge (the canthus) runs from them to the snout, the nostrils sit near its tip with a heat pit
between each nostril and eye, the lips are lined with pale scales; big eyes with slit pupils, a
separate lower jaw with long fangs and a forked tongue, and a short horn over each brow (a horned
viper's).  Two bone chains run from the coil -
one to the tail, one up the neck to the head - so the body ripples and the neck sways.
Clips: idle (swaying, tasting the air), walk (slithering ripples), attack (draws back and
strikes), hurt, die (the neck collapses onto the coils), cast (rears and hisses).
Run: blender --background --python art/monsters/serpent.py  ->  assets/monsters/serpent.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
import serpentine as S  # noqa: E402
from clay import Clay  # noqa: E402
from creature import add, smooth, zero_pose  # noqa: E402
from kit import MAT_PLAIN, SKIN, V, Builder, Rig, mix  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
# coiled on the ground, the neck rearing in an S and bending forward at the top so the head is level
CTRL = [V(0.05, 0.08, -1.62), V(0.55, 0.12, -1.32), V(0.72, 0.15, -0.76), V(0.18, 0.18, -0.36), V(-0.42, 0.2, -0.12), V(-0.38, 0.4, 0.2),
        V(-0.06, 0.84, 0.3), V(0.04, 1.3, 0.26), V(0.03, 1.58, 0.38), V(0.0, 1.66, 0.62)]
SP = A.Spline(CTRL, per=8)
U_MID = 0.5
NT, NN = 5, 6
U_HEAD = 0.975


def rad(u):
    """Thickest a little behind the middle, a slim neck under the head, a long tapering tail."""
    r = 0.045 + 0.15 * math.sin(min(1.0, u * 1.35) * math.pi * 0.85) ** 0.8 + 0.03 * u
    r *= 1.0 - 0.42 * smooth(0.78, 0.97, u)
    return r


r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
pm = SP.at(U_MID)[0]
r.bone("base", pm, pm + V(0, 0.2, 0), "root")
TAIL_U = [U_MID - U_MID * i / NT for i in range(NT + 1)]
NECK_U = [U_MID + (0.97 - U_MID) * i / NN for i in range(NN + 1)]
prev = "base"
for i in range(NT):
    r.bone("tail%d" % i, SP.at(TAIL_U[i])[0], SP.at(TAIL_U[i + 1])[0], prev)
    prev = "tail%d" % i
prev = "base"
for i in range(NN):
    r.bone("sp%d" % i, SP.at(NECK_U[i])[0], SP.at(NECK_U[i + 1])[0], prev)
    prev = "sp%d" % i
HP, HT, HU, HS = SP.at(1.0)
HC = HP + HT * 0.08
hf = A.HeadFrame(HC, (HT + V(0, -0.12, 0)).normalized())
K = 1.3


def hp(x, y, z):
    return hf.at(x * K, y * K, z * K)


r.bone("head", SP.at(0.97)[0], HC + hf.f * 0.25, "sp%d" % (NN - 1))
r.bone("jaw", hp(0, -0.04, -0.08), hp(0, -0.07, 0.2), "head")
NAMES = ["tail%d" % i for i in reversed(range(NT))] + ["sp%d" % i for i in range(NN)]
BOUNDS = list(reversed(TAIL_U)) + NECK_U[1:]


def spine_w(u):
    if u > 0.97:
        return {"head": 1.0}
    for i in range(len(NAMES)):
        a, c = BOUNDS[i], BOUNDS[i + 1]
        if a <= u <= c or i == len(NAMES) - 1:
            z = 0.25 * (c - a)
            if u > c - z and i + 1 < len(NAMES):
                k = 0.5 * (u - (c - z)) / z
                return {NAMES[i]: 1.0 - k, NAMES[i + 1]: k}
            if u < a + z and i > 0:
                k = 0.5 + 0.5 * (u - a) / z
                return {NAMES[i - 1]: 1.0 - k, NAMES[i]: k}
            return {NAMES[i]: 1.0}
    return {NAMES[-1]: 1.0}


SADDLE = 0.17     # metres between the saddles down the back


def pattern(u, a, f, g, kind, v):
    """Dark-edged saddles with paler centres down the back, a pale lateral line, freckled flanks."""
    if kind == "plate":
        return v
    s = u * SP.L / SADDLE
    w = fbm3((u * 37.0, a * 1.3, 0.5), 2, 3)
    ph = s + 0.25 * (w - 0.5)
    ca = abs(a)
    k = abs((ph % 1.0) - 0.5) * 2.0 + ca * 0.55                 # 0 in a saddle's middle
    saddle = smooth(0.78, 0.66, k)
    rim = smooth(0.1, 0.0, abs(k - 0.72))
    v = v * (1.0 - 0.24 * saddle) * (1.0 - 0.42 * rim)
    v += 0.06 * smooth(0.12, 0.0, abs(ca - 1.55)) * (1.0 - saddle)   # a faint pale line along each side
    return v


b = Builder("serpent")
# the body from the tip of the tail to the back of the head: scales overlap towards the tail
S.scaled_body(b, SP, rad, spine_w, scale_len=0.062, cols=12, per=3, belly=50.0, height=0.07, plate_h=0.05, flat=0.22, ridge=0.04, back=0.7, flank=0.84,
              under=0.96, edge=0.2, u0=0.0, u1=U_HEAD, cap0=True, cap1=True, col_fn=pattern, reverse=True)

# ---------------------------------------------------------------- the viper's head
c = Clay(0.011, "serpent_head")
A.head_clay(c, hf, K, [
    ("ell", (0, 0.0, -0.01), (0.108, 0.068, 0.12), "head", False, False),          # the skull
    ("ell", (0.078, -0.02, -0.05), (0.06, 0.052, 0.072), "jowl", True, False),      # venom glands swelling the jaw's angle
    ("ell", (0, -0.006, 0.115), (0.072, 0.048, 0.085), "head", False, False),       # the snout
    ("ell", (0, -0.012, 0.19), (0.046, 0.034, 0.045), "head", False, False),
    ("ell", (0, 0.038, 0.03), (0.095, 0.022, 0.13), "crown", False, False),         # a flat crown of plates
    ("ell", (0.07, 0.052, 0.045), (0.034, 0.02, 0.052), "brow", True, False),         # supraoculars jutting over the eyes
    ("ell", (0.045, 0.034, 0.13), (0.02, 0.016, 0.065), "brow", True, False),        # the canthus ridge
    ("ball", (0.082, 0.024, 0.052), 0.024, "head", True, True),                      # eye sockets
    ("ball", (0.045, 0.008, 0.155), 0.008, "head", True, True),                      # heat pits
    ("ball", (0.026, 0.012, 0.215), 0.007, "head", True, True),                      # nostrils
])
# the neck: slim behind the wide head (it melts into the body's skin)
for k in range(4):
    u = 0.955 + 0.007 * k
    p, t, up, side = SP.at(u)
    c.ball(p, rad(u) * 0.98, bones=spine_w(u), tag="neck")


def head_col(p, info):
    q = hf.M.transposed() @ (p - HC) / K
    tag = info.tag
    if tag == "neck":
        return S.grey(0.74)
    v = 0.74 - 0.08 * smooth(0.0, 0.05, q.y) + 0.22 * smooth(-0.01, -0.05, q.y)      # pale lips and chin
    if tag == "crown":
        # the big plates of the crown, edged dark
        gx = abs(q.x)
        edge = smooth(0.006, 0.0, abs(gx - 0.03)) * smooth(-0.05, 0.0, q.z) + smooth(0.008, 0.0, abs(q.z - 0.06)) * smooth(0.05, 0.02, gx)
        v = 0.68 * (1.0 - 0.3 * edge)
    if tag == "brow":
        v = 0.62
    # a dark stripe from the eye back along the jaw, the labial scales barred
    v *= 1.0 - 0.45 * smooth(0.014, 0.004, abs(q.y - 0.012 + 0.25 * (q.z - 0.05))) * smooth(0.04, 0.07, abs(q.x)) * smooth(0.08, 0.02, q.z)
    if q.y < -0.008:
        v *= 1.0 - 0.18 * smooth(0.8, 1.0, abs(math.sin(q.z * 95.0)))
    return S.grey(v)


c.build(b, head_col, cls=S.PLAIN, tint_fn=lambda p, info: 1.0)
# the lower jaw
j = Clay(0.011, "serpent_jaw")
for s in (1, -1):
    j.chain([hp(0.088 * s, -0.04, -0.06), hp(0.056 * s, -0.052, 0.08), hp(0.018 * s, -0.047, 0.2)], [0.03, 0.025, 0.02], bones={"jaw": 1.0}, tag="jaw")
j.build(b, lambda p, info: mix((0.95, 0.95, 0.95), (0.5, 0.18, 0.22), smooth(0.2, 0.5, info.n.dot(hf.u))), cls=S.PLAIN,
        tint_fn=lambda p, info: 0.5 * (1.0 - smooth(0.2, 0.5, info.n.dot(hf.u))))
b.ellipsoid(hp(0, -0.03, 0.06), (0.09, 0.016, 0.17), "3a1418", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
tongue = [hp(0, -0.04, 0.1), hp(0, -0.045, 0.22), hp(0, -0.05, 0.28)]
b.tube(tongue, [0.008, 0.007, 0.005], "c02040", cls=SKIN, bone="jaw", seg=6, mat=MAT_PLAIN)
for s in (1, -1):
    b.tube([tongue[-1], tongue[-1] + hf.r * 0.02 * s + hf.f * 0.05 - hf.u * 0.01], [0.005, 0.001], "c02040", cls=SKIN, bone="jaw", seg=5, mat=MAT_PLAIN)
    A.fang(b, hp(0.038 * s, -0.035, 0.18), -hf.u * 0.8 - hf.f * 0.2, 0.1, 0.011, "head", back=-hf.f, curve=0.35)
    # a big eye with a slit pupil, under the jutting supraocular
    A.animal_eye(b, hp(0.083 * s, 0.024, 0.054), hf.f * 0.42 + hf.r * (0.9 * s) + hf.u * 0.05, 0.043, "ffd040", "head", pupil="slit", almond=0.8,
                 side=s, glow=True, lid_w=0.16)
    # a horned viper's spike over each brow (the accent colour)
    b.cur_pal = 1.0
    A.horn(b, [hp(0.072 * s, 0.062, 0.04), hp(0.082 * s, 0.086, 0.0), hp(0.085 * s, 0.095, -0.05)], 0.018, "b0b0b0", "ffffff", "head", r1=0.002, rings=3, seg=8,
           tint=1.0, cls=0.9)
    b.cur_pal = 0.0

T_IDLE = 3.2
T_WALK = 1.6
NECK = ["sp%d" % i for i in range(NN)]
TAIL = ["tail%d" % i for i in range(NT)]


def sway(p, t, T, amp, tail_amp, lag=0.7):
    w = 2 * math.pi / T
    for i, nm in enumerate(NECK):
        add(p, nm, (amp * 0.4 * math.sin(w * t - i * lag + 1.0), amp * math.sin(w * t - i * lag) * (0.5 + 0.12 * i), 0.0))
    for i, nm in enumerate(TAIL):
        add(p, nm, (0.0, tail_amp * math.sin(w * t + i * lag) * (0.6 + 0.15 * i), 0.0))


def idle(t):
    p = zero_pose(r)
    sway(p, t, T_IDLE, 0.06, 0.04)
    w = 2 * math.pi / T_IDLE
    add(p, "head", (0.05 * math.sin(w * t * 2), 0.12 * math.sin(w * t + 0.6), 0.0))
    add(p, "jaw", (0.05 + 0.08 * max(0.0, math.sin(w * t * 3)) ** 4, 0, 0))
    return p


def walk(t):
    p = zero_pose(r)
    sway(p, t, T_WALK, 0.1, 0.14, lag=0.9)
    w = 2 * math.pi / T_WALK
    add(p, "base", (0.0, 0.08 * math.sin(w * t), 0.0), (0.03 * math.sin(w * t), 0.0, 0.0))
    add(p, "head", (0.0, -0.1 * math.sin(w * t - 4.0), 0.0))
    add(p, "jaw", (0.05, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    ant = smooth(0.0, 0.3, k) * (1.0 - smooth(0.3, 0.4, k))
    hit_ = smooth(0.3, 0.4, k) * (1.0 - smooth(0.6, 1.0, k))
    p = idle(0.0)
    for i, nm in enumerate(NECK):
        add(p, nm, (-0.18 * ant * (i > 1) + 0.22 * hit_ * (i > 1), 0.0, 0.0))
    add(p, "base", (0, 0, 0), (0, 0, 0.25 * hit_))
    add(p, "head", (0.2 * ant - 0.25 * hit_, 0, 0))
    add(p, "jaw", (1.0 * smooth(0.25, 0.38, k) * (1.0 - smooth(0.5, 0.7, k)), 0, 0))
    return p


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = idle(0.0)
    for i, nm in enumerate(NECK):
        add(p, nm, (-0.12 * e, 0.12 * e * math.sin(i + k * 12.0), 0.0))
    add(p, "head", (-0.3 * e, 0.3 * e, 0.2 * e))
    add(p, "jaw", (0.5 * e, 0, 0))
    for i, nm in enumerate(TAIL):
        add(p, nm, (0.0, 0.2 * e * math.sin(k * 20.0 + i), 0.0))
    return p


def die(t):
    """The neck sags and collapses onto the coils; the head comes to rest on the ground."""
    k = min(1.0, t / 1.2)
    f = smooth(0.1, 0.75, k)
    writhe = math.sin(k * 16.0) * (1.0 - smooth(0.3, 0.7, k)) * 0.12
    p = zero_pose(r)
    for i, nm in enumerate(NECK):
        add(p, nm, ((0.42 if i < 3 else 0.2) * f, writhe + 0.15 * f * (1 if i % 2 else -1), 0.0))
    add(p, "head", (0.3 * f, 0.0, 0.5 * f))
    add(p, "jaw", (0.3 * f, 0, 0))
    for i, nm in enumerate(TAIL):
        add(p, nm, (0.0, writhe * 1.5, 0.0))
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = idle(t)
    for nm in NECK[2:]:
        add(p, nm, (-0.12 * e, 0, 0))
    add(p, "head", (-0.35 * e, 0, 0))
    add(p, "jaw", (1.0 * e, 0, 0))
    return p


print("[art] serpent: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/serpent.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die),
                                                  "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
