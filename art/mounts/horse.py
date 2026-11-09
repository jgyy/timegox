"""The mountain horse Lin Feng rides (scripts/fashion.gd RIDES "pony"): a sturdy steppe horse with a
deep chest, a short strong back and clean legs on solid hooves, a heavy mane falling on both sides of
the crest, a forelock, and a long tail; saddled for the road with a high-pommelled saddle on a
saddle-cloth, stirrups and a bridle with the reins up to the pommel.

Sculpted in clay over the muscle masses like the qilin (art/lib/clay.py, art/lib/anatomy.py); the
coat is painted in greys on the dominant palette slot (a darker back, a pale belly, dark legs below
the knee), the mane and tail take the secondary slot and the saddle-cloth the accent, so the game
can make one horse a bay, a dun or a grey (scripts/assets.gd).
Clips: idle, walk (the four-beat walk), run (the gallop the game plays under a rider), and the attack,
hurt and die every monster rig carries.
Run: blender --background --python art/mounts/horse.py  ->  assets/mounts/horse.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay  # noqa: E402
from creature import LegSpec, QuadMotion, add, quad_rig2, quad_skel, smooth  # noqa: E402
from kit import CLOTH, HAIR, MAT_PLAIN, METAL, SKIN, WOOD, V, Builder  # noqa: E402

kit.reset()
creature.realtime()
H = 1.16
hip_z, sh_z = -0.52, 0.46
neck0 = V(0, H + 0.1, sh_z + 0.06)
neck1 = V(0, H + 0.36, sh_z + 0.3)
headp = V(0, H + 0.5, sh_z + 0.44)
snout = headp + V(0, -0.3, 0.36)
tb = V(0, H + 0.04, hip_z - 0.12)
tail = [tb + V(0, -0.1 * k + 0.004 * k * k, -0.07 * k + 0.01 * k * k) for k in range(6)]
sk = quad_skel(H=H, hip_z=hip_z, sh_z=sh_z, hip_w=0.14, sh_w=0.13, foot="hoof", withers=0.1, neck=(neck1, headp), head=snout, tail=tail)
HC = headp + V(0, -0.05, 0.08)
hf = A.HeadFrame(HC, V(0, -0.62, 0.78))
K = 1.6


def hp(x, y, z):
    return hf.at(x * K, y * K, z * K)


ears = [(hp(0.035, 0.055, -0.04), hp(0.05, 0.13, -0.06)), (hp(-0.035, 0.055, -0.04), hp(-0.05, 0.13, -0.06))]
r, legs = quad_rig2(sk, ears=ears)
r.bones["jaw"] = (hp(0, -0.03, 0.0), hp(0, -0.04, 0.2), "head")
b = Builder("horse")

# ---------------------------------------------------------------- body
c = Clay(0.017, "horse_body")
NECK = [V(0, H + 0.04, sh_z), neck0.lerp(neck1, 0.55) + V(0, 0, -0.02), headp + V(0, -0.04, -0.02)]
NECK_R = [0.21, 0.165, 0.11]
A.clay_torso(c, sk, w=0.23, d=0.33, haunch=(0.23, 0.24, 0.24), tuck=0.03, withers=0.14, neck=NECK_R, throat=0.12, chest_y=0.78, neck_pts=NECK)
for sd in ("L", "R"):
    A.clay_foreleg(c, sk, sd, g=0.8, foot="hoof", paw=1.0)
    A.clay_hindleg(c, sk, sd, g=0.84, foot="hoof", paw=1.0)
A.clay_tail(c, sk, [0.045, 0.034, 0.026, 0.02, 0.016, 0.014])
# the horse's head: a long straight face from the broad flat forehead to soft muzzle and nostrils,
# the cheek (jowl) round below the eye, the eye sockets set high and wide
A.head_clay(c, hf, K, [
    ("ell", (0, 0.025, -0.03), (0.06, 0.06, 0.07), "head", False, False),
    ("ell", (0.042, -0.02, -0.01), (0.03, 0.05, 0.055), "head", True, False),
    ("ell", (0, 0.012, 0.07), (0.04, 0.046, 0.075), "muzzle", False, False),
    ("ell", (0, 0.0, 0.15), (0.034, 0.042, 0.06), "muzzle", False, False),
    ("ell", (0, -0.012, 0.21), (0.036, 0.044, 0.04), "muzzle", False, False),
    ("ball", (0.02, 0.0, 0.235), 0.017, "muzzle", True, False),
    ("ell", (0.048, 0.03, 0.02), (0.02, 0.016, 0.018), "head", True, True),
])


def head_local(p):
    return hf.M.transposed() @ (p - HC) / K


def col(p, info):
    tag = info.tag
    n = info.n
    if tag in ("head", "muzzle"):
        q = head_local(p)
        # a darker muzzle, a pale blaze down the face
        v = 0.74 - 0.18 * smooth(0.12, 0.24, q.z)
        blaze = smooth(0.022, 0.008, abs(q.x)) * smooth(-0.02, 0.02, q.y) * smooth(0.2, 0.05, q.z)
        v = v * (1.0 - blaze) + 0.96 * blaze
        return (v, v, v)
    under = smooth(-0.2, -0.65, n.y)
    if tag in ("body", "neck"):
        v = 0.76 - 0.1 * smooth(0.3, 0.95, n.y)
        return (v * (1.0 - under) + 0.88 * under,) * 3
    if tag in ("fleg", "hleg"):
        # dark points: the legs darken below the knee and hock
        v = 0.72 - 0.4 * smooth(1.1, 1.7, info.t)
        return (v, v, v)
    if tag == "fetlock":
        return (0.3, 0.3, 0.3)
    if tag == "tail":
        return (0.4, 0.4, 0.4)
    return (0.74, 0.74, 0.74)


def tint(p, info):
    return 1.0


c.build(b, col, cls=SKIN, tint_fn=tint)

# ---------------------------------------------------------------- jaw, eyes, ears, nostrils
j = Clay(0.012, "horse_jaw")
for s in (1, -1):
    j.chain([hp(0.03 * s, -0.04, 0.0), hp(0.02 * s, -0.045, 0.1), hp(0.012 * s, -0.04, 0.19)], [0.022, 0.018, 0.016], bones={"jaw": 1.0}, tag="jaw")
j.build(b, lambda p, info: (0.55, 0.55, 0.55), cls=SKIN, tint_fn=lambda p, info: 1.0)
for s in (1, -1):
    A.animal_eye(b, hp(0.05 * s, 0.03, 0.02), hf.r * s * 0.9 + hf.f * 0.35 + hf.u * 0.1, 0.019 * K, "3a2416", "head", pupil="round", almond=0.7, slant=0.05, side=s)
    b.ellipsoid(hp(0.02 * s, 0.0, 0.245), (0.008, 0.012, 0.006), "1a1210", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=8, rings=6, mat=MAT_PLAIN)
for s, sd in ((1, "L"), (-1, "R")):
    # upright pointed ears, turned forward
    A.ear(b, hp(0.035 * s, 0.055, -0.04), hf.u * 0.9 + hf.r * (0.25 * s) - hf.f * 0.2, 0.095 * K, 0.04 * K, 0.022 * K, (0.6, 0.6, 0.6), (0.82, 0.78, 0.76), "ear." + sd,
          up=-hf.f * 0.8 + hf.r * (0.3 * s), point=0.85, cup=0.55, tint=1.0, tint_in=0.4, side=s)

# ---------------------------------------------------------------- mane, forelock, tail (secondary colour)
b.cur_pal = 0.5
hit = A.surface(b)
crest_a = hp(0, 0.05, -0.08)
crest_b = V(0, H + 0.13, sh_z - 0.12)
for i in range(18):
    t = i / 17
    q = crest_a.lerp(crest_b, t)
    h = hit(q + V(0, 0.6, 0), V(0, -1, 0))
    if h is None:
        continue
    root, nrm = h
    sgn = 1 if i % 2 else -1
    shade = 0.5 - 0.12 * (i % 3) / 2
    bone = "head" if t < 0.1 else ({"neck1": 0.7, "neck0": 0.3} if t < 0.5 else ({"neck0": 0.8, "chest": 0.2} if t < 0.85 else {"chest": 1.0}))
    for layer in range(2):
        groom = V(0.5 * sgn * (1 + layer), -0.35 - 0.3 * layer, -0.8).normalized()
        A.lock(b, root + V(0.01 * sgn * layer, -0.01 * layer, 0), groom, nrm + V(sgn * 0.4, 0, 0), 0.26 - 0.06 * layer, 0.07 - 0.012 * layer,
               (shade,) * 3, (min(1.0, shade + 0.18),) * 3, bone=bone, lift=0.25, rise=0.08, thick=0.35, tint=1.0, cls=HAIR, bend=0.3 * sgn, droop=0.45)
A.lock(b, hp(0, 0.08, -0.03), hf.f * 0.9 + hf.u * 0.25, hf.u, 0.12, 0.05, (0.45,) * 3, (0.6,) * 3, bone="head", lift=0.25, rise=0.08, cls=HAIR)
# the tail: long hair from the dock, falling nearly to the hocks
tl = sk.tail
for k in range(9):
    a = k / 9 * 2 * math.pi
    out = V(math.cos(a), 0.2, math.sin(a) * 0.6)
    A.lock(b, tl[1] + out * 0.025, (V(0, -1, -0.25) + out * 0.15).normalized(), out, 0.55 + 0.05 * (k % 3), 0.055, (0.42,) * 3, (0.58,) * 3,
           bone={"tail1": 0.5, "tail2": 0.5}, lift=0.15, rise=0.1, cls=HAIR, droop=0.2)
b.cur_pal = 0.0

# ---------------------------------------------------------------- hooves
for sd, s in (("L", 1), ("R", -1)):
    for pre, ft in (("f", "ft"), ("h", "ht")):
        p1 = sk[ft + "." + sd]
        A.hoof(b, V(p1.x, 0.0, p1.z - 0.03), V(0, 0, 1), 0.058, 0.08, "2a2420", pre + "_toe." + sd, cloven=False, col_top="3a302a")

# ---------------------------------------------------------------- tack: saddle, cloth, stirrups, bridle, reins
SEAT = V(0, H + 0.16, sh_z - 0.46)      # the scripts/fashion.gd seat offsets are measured from here
# the saddle-cloth (accent colour, a woven border), draped over the back and down both sides
b.cur_pal = 1.0
for s in (1, -1):
    rows = []
    for i in range(5):
        z = SEAT.z - 0.26 + i * 0.13
        top = V(0.0, H + 0.13 + 0.02 * math.sin(math.pi * i / 4), z)
        mid = V(0.2 * s, H + 0.02, z)
        bot = V(0.27 * s, H - 0.2, z)
        rows.append([top, mid, bot])
    cols = []
    b.sheet(rows, "c8c8c8", cls=CLOTH, bone="body", tint=1.0, thickness=0.01)
b.cur_pal = 0.0
# the saddle: a leather seat with a high pommel in front and a cantle behind
b.lathe(SEAT + V(0, -0.03, 0), [(0.0, 0.0), (0.16, 0.0), (0.17, 0.04), (0.12, 0.07), (0.0, 0.075)], "6a3e22", cls=WOOD, bone="body", seg=14, squash=(0.85, 1.6))
b.box(SEAT + V(0, 0.06, 0.2), (0.12, 0.12, 0.05), "5a3218", cls=WOOD, bone="body", rot=(-0.3, 0, 0))
b.box(SEAT + V(0, 0.05, -0.2), (0.22, 0.09, 0.05), "5a3218", cls=WOOD, bone="body", rot=(0.35, 0, 0))
b.ball(SEAT + V(0, 0.13, 0.22), 0.025, "d8b050", cls=METAL, bone="body", seg=8, rings=6)
for s in (1, -1):
    # stirrup leathers and iron stirrups
    top = SEAT + V(0.15 * s, 0.0, 0.0)
    foot = V(0.3 * s, H - 0.44, SEAT.z + 0.04)
    b.tube([top, top.lerp(foot, 0.5) + V(0.02 * s, 0, 0), foot + V(0, 0.05, 0)], [0.012, 0.012, 0.012], "4a2a16", cls=WOOD, bone="body", seg=4, flat=0.3)
    b.lathe(foot, [(0.045, -0.02), (0.05, 0.0), (0.045, 0.02)], "a8acb8", cls=METAL, bone="body", seg=10, squash=(1.0, 0.5), cap_top=False, cap_bottom=False)
    b.box(foot + V(0, -0.02, 0), (0.05, 0.01, 0.04), "8a8e98", cls=METAL, bone="body")
    # a girth strap under the belly
    b.tube([SEAT + V(0.18 * s, -0.04, 0.12), V(0.23 * s, H - 0.24, SEAT.z + 0.12), V(0.0, H - 0.34, SEAT.z + 0.12)], [0.014, 0.014, 0.014], "4a2a16", cls=WOOD, bone="body", seg=4, flat=0.4)
# the bridle: a headstall round the face, a browband and noseband, the bit and the reins
for s in (1, -1):
    b.tube([hp(0.045 * s, 0.06, -0.03), hp(0.05 * s, 0.0, 0.04), hp(0.035 * s, -0.035, 0.17)], [0.008, 0.008, 0.008], "3a2010", cls=WOOD, bone="head", seg=4, flat=0.4)
    b.ball(hp(0.036 * s, -0.035, 0.18), 0.012, "c8ccd8", cls=METAL, bone="head", seg=8, rings=6)
ring = [hp(math.cos(a) * 0.04, -0.005 + math.sin(a) * 0.035, 0.15) for a in [i / 12 * 2 * math.pi for i in range(13)]]
b.tube(ring, [0.007] * 13, "3a2010", cls=WOOD, bone="head", seg=4, cap0=False, cap1=False)
brow = [hp(math.cos(a) * 0.05, 0.06 + math.sin(a) * 0.01, -0.02) for a in [i / 8 * math.pi for i in range(9)]]
b.tube(brow, [0.007] * 9, "b03030", cls=CLOTH, bone="head", seg=4, cap0=False, cap1=False)
for s in (1, -1):
    bit = hp(0.036 * s, -0.035, 0.18)
    rein = [bit, bit.lerp(SEAT + V(0.06 * s, 0.1, 0.22), 0.35) + V(0, -0.06, 0), bit.lerp(SEAT + V(0.06 * s, 0.1, 0.22), 0.7) + V(0, -0.05, 0), SEAT + V(0.05 * s, 0.1, 0.24)]
    b.tube(rein, [0.007] * 4, "3a2010", cls=WOOD, bone={"neck1": 0.5, "neck0": 0.5}, seg=4, flat=0.4)

# ---------------------------------------------------------------- motion
qm = QuadMotion(r, legs, T_walk=1.3, stride=0.48, lift=0.13, duty=0.62, bob=0.016, roll=0.022, yaw=0.035, head_nod=0.07, head_low=-0.02,
                neck_up=0.04, tail_amp=0.12, tail_lift=0.0, tail_droop=0.2, pounce="rear", T_idle=4.0, front_flex=1.7, hind_flex=0.85,
                rest_h=0.24, lunge=0.28)
# the gallop: the same legs on a bounding four-beat (both hinds, then both fores, a moment of
# suspension), a long stride, the back flexing and the head reaching with each bound
GALLOP_TD = {(True, 1): 0.56, (True, -1): 0.66, (False, 1): 0.0, (False, -1): 0.1}
glegs = [LegSpec(lg.chain, lg.parent, lg.front, lg.side, GALLOP_TD[(lg.front, lg.side)]) for lg in legs]
gm = QuadMotion(r, glegs, T_walk=0.62, stride=1.15, lift=0.24, duty=0.36, bob=0.05, roll=0.012, yaw=0.015, pitch=0.06, head_nod=0.12,
                head_low=0.05, neck_up=-0.02, tail_amp=0.1, tail_lift=0.35, tail_droop=0.0, T_idle=4.0, front_flex=2.0, hind_flex=1.1,
                rest_h=0.24, reach=0.08)


def run(t):
    p = gm.walk(t)
    ph = (t / 0.62) % 1.0
    add(p, "neck0", (0.1 * math.sin(2 * math.pi * (ph - 0.15)), 0.0, 0.0))
    return p


print("[art] horse: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "mounts/horse.glb", qm.clips({"run": (0.62, run)}), samples=16, dist=0.3, strength=0.5, floor_y=0.0)
