"""Serpent: the great snakes and eels (Tide Hydra, Rainbow Serpent, Rot-Root Hydra, Chaos Eel, Kelp
Serpent, Ash Salamander, the Serpent Beneath the Naihe Bridge ...).  A long body sculpted in clay
along a spline (art/lib/clay.py), coiled on the ground and rearing into an S-shaped neck; a
dark-edged saddle pattern painted down the back over paler flanks, broad pale ventral scutes
under the belly; a viper's wedge-shaped head, broad behind the jaws, with raised brow scales over
slit-pupilled eyes, heat pits, a separate lower jaw with long fangs and a forked tongue, two short
horns, and webbed fins of membrane down the neck.  Two bone chains run from the coil - one to the
tail, one up the neck to the head - so the body ripples and the neck sways.
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
from clay import Clay  # noqa: E402
from creature import add, smooth, zero_pose  # noqa: E402
from kit import CLOTH, MAT_PLAIN, SCALE, SKIN, STONE, V, Builder, Rig, mix  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
CTRL = [V(0.05, 0.08, -1.62), V(0.55, 0.12, -1.32), V(0.72, 0.15, -0.76), V(0.18, 0.18, -0.36), V(-0.42, 0.2, -0.12), V(-0.38, 0.4, 0.2),
        V(-0.05, 0.85, 0.32), V(0.05, 1.38, 0.32), V(0.0, 1.72, 0.52)]
SP = A.Spline(CTRL, per=8)
U_MID = 0.5
NT, NN = 5, 6


def rad(u):
    r = 0.05 + 0.15 * math.sin(min(1.0, u * 1.35) * math.pi * 0.85) ** 0.8 + 0.03 * u
    return r * (1.0 - 0.38 * smooth(0.8, 1.0, u))


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
HC = HP + HT * 0.1
hf = A.HeadFrame(HC, (HT + V(0, -0.15, 0)).normalized())
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


b = Builder("serpent")
c = Clay(0.016, "serpent_body")
us = [k / 70.0 for k in range(71)]
c.chain([SP.at(u)[0] for u in us], [rad(u) for u in us], bones=lambda p, t: spine_w(t), tag="body", t0=0.0, t1=1.0)
# the viper's head: broad behind the jaws (venom glands), a narrowing snout, brow scales
A.head_clay(c, hf, K, [
    ("ell", (0, 0.0, 0.0), (0.12, 0.075, 0.13), "head", False, False),
    ("ell", (0.08, -0.02, -0.04), (0.06, 0.05, 0.07), "head", True, False),
    ("ell", (0, -0.005, 0.12), (0.075, 0.05, 0.1), "head", False, False),
    ("ell", (0, -0.01, 0.2), (0.05, 0.035, 0.05), "head", False, False),
    ("ell", (0.06, 0.05, 0.04), (0.03, 0.02, 0.05), "brow", True, False),
    ("ell", (0.062, 0.03, 0.05), (0.022, 0.016, 0.02), "head", True, True),
])


def col(p, info):
    n = info.n
    if info.tag in ("head", "brow"):
        q = hf.M.transposed() @ (p - HC)
        v = 0.78 - 0.12 * smooth(0.0, 0.06, q.y) + 0.2 * smooth(-0.02, -0.06, q.y)
        # a dark stripe from the eye back along the jaw
        v *= 1.0 - 0.45 * smooth(0.012, 0.004, abs(q.y - 0.01 + 0.25 * (q.z - 0.05))) * smooth(0.04, 0.07, abs(q.x))
        return (v, v, v)
    u = info.t
    a, _ = SP.local(p, u)
    under = smooth(1.9, 2.5, abs(a))
    # saddles down the back: dark-edged blotches with paler centres, pale flanks
    s_len = u * SP.L / 0.16
    w = fbm3((p.x * 4.0, p.y * 4.0, p.z * 4.0), 2, 3)
    ph = s_len + 0.25 * (w - 0.5)
    k = abs((ph % 1.0) - 0.5) * 2.0 + abs(a) * 0.55
    saddle = smooth(0.78, 0.68, k)
    edge = smooth(0.08, 0.0, abs(k - 0.72))
    v = 0.84 - 0.1 * smooth(1.2, 0.0, abs(a))
    v = v * (1.0 - 0.28 * saddle) * (1.0 - 0.5 * edge)
    scute = 0.97 - 0.25 * smooth(0.82, 0.95, 0.5 + 0.5 * math.cos(u * SP.L / 0.045 * math.pi))
    return (v * (1.0 - under) + scute * under,) * 3


def tint(p, info):
    if info.tag != "body":
        return 1.0
    a, _ = SP.local(p, info.t)
    return 1.0 - 0.6 * smooth(1.9, 2.5, abs(a))


c.build(b, col, cls=SCALE, tint_fn=tint)
j = Clay(0.012, "serpent_jaw")
for s in (1, -1):
    j.chain([hp(0.085 * s, -0.04, -0.06), hp(0.055 * s, -0.05, 0.08), hp(0.018 * s, -0.045, 0.2)], [0.032, 0.026, 0.021], bones={"jaw": 1.0}, tag="jaw")
j.build(b, lambda p, info: mix((0.95, 0.95, 0.95), (0.5, 0.18, 0.22), smooth(0.2, 0.5, info.n.dot(hf.u))), cls=SCALE,
        tint_fn=lambda p, info: 0.5 * (1.0 - smooth(0.2, 0.5, info.n.dot(hf.u))))
b.ellipsoid(hp(0, -0.03, 0.06), (0.09, 0.016, 0.17), "3a1418", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
tongue = [hp(0, -0.04, 0.1), hp(0, -0.045, 0.22), hp(0, -0.05, 0.28)]
b.tube(tongue, [0.008, 0.007, 0.005], "c02040", cls=SKIN, bone="jaw", seg=6, mat=MAT_PLAIN)
for s in (1, -1):
    b.tube([tongue[-1], tongue[-1] + hf.r * 0.02 * s + hf.f * 0.05 - hf.u * 0.01], [0.005, 0.001], "c02040", cls=SKIN, bone="jaw", seg=5, mat=MAT_PLAIN)
    A.fang(b, hp(0.04 * s, -0.03, 0.18), -hf.u * 0.8 - hf.f * 0.2, 0.09, 0.011, "head", back=-hf.f, curve=0.35)
    A.animal_eye(b, hp(0.064 * s, 0.03, 0.055), hf.f * 0.5 + hf.r * (0.85 * s) + hf.u * 0.15, 0.031, "ffd040", "head", pupil="slit", almond=0.8, side=s, glow=True)
    b.ellipsoid(hp(0.05 * s, -0.005, 0.15), (0.008, 0.008, 0.006), "100810", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=6, rings=4, mat=MAT_PLAIN)
    b.ellipsoid(hp(0.022 * s, 0.01, 0.235), (0.007, 0.005, 0.004), "100810", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=6, rings=4, mat=MAT_PLAIN)
    # two short horns over the brow
    b.cur_pal = 1.0  # accent horns
    A.horn(b, [hp(0.06 * s, 0.065, 0.0), hp(0.085 * s, 0.11, -0.06), hp(0.09 * s, 0.13, -0.15)], 0.028, "b0b0b0", "ffffff", "head", r1=0.003, rings=4, seg=8, tint=1.0)
    b.cur_pal = 0.0
# webbed fins of membrane between spines down the back of the neck (secondary colour)
b.cur_pal = 0.5
hit = A.surface(b)
prev = None
for i in range(11):
    u = 0.55 + 0.38 * i / 10
    p, t, up, side = SP.at(u)
    h = hit(p + up * 0.6 - t * 0.0, -up)
    if h is None:
        continue
    root, nrm = h
    tip = root + nrm * (0.14 + 0.05 * math.sin(i * 1.3)) - t * 0.06
    b.cur_pal = 1.0  # the fin rays in the accent colour, the membrane between them secondary
    A.horn(b, [root - nrm * 0.01, root.lerp(tip, 0.5), tip], 0.012, (0.75, 0.75, 0.75), (0.95, 0.95, 0.95), spine_w(u), r1=0.002, cls=STONE, seg=6, per=2, tint=1.0)
    b.cur_pal = 0.5
    if prev is not None:
        r0, t0, u0 = prev
        rows = [[r0 + (t0 - r0) * 0.05, t0], [root + (tip - root) * 0.05, tip]]
        b.sheet(rows, (0.7, 0.7, 0.7), cls=CLOTH, bones=[spine_w(u0), spine_w(u)], cols=[(0.7, 0.7, 0.7), (0.85, 0.85, 0.85)], tint=1.0, thickness=0.006)
    prev = (root, tip, u)
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
