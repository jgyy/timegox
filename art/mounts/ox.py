"""The draught ox of the Two-Wheeled Ox-Cart (scripts/fashion.gd RIDES "ox_cart", scripts/models.gd
_carriage): a water buffalo of the rice country, built as such an animal is seen: the hump of muscle
over the shoulders is the highest point of it and not the head, which is carried low and forward on a
short thick neck; a barrel of a body deeper than a horse's on shorter, heavier legs with cloven
hooves; a broad flat brow and a wide wet muzzle; horns that leave the sides of the skull and sweep
out, back and up in a crescent; ears carried level under them; a dewlap from the throat to the
brisket; a thin tail with a tuft.

Sculpted in clay over the muscle masses like the horse (art/lib/clay.py, art/lib/anatomy.py).  The
hide is painted in greys on the dominant palette slot (a dark back, a pale belly and chest, dark
points below the knee, the pale chevron under the throat and the pale muzzle a buffalo has), the
blanket and the rosette of market day take the secondary slot and the eyes the accent, so the game
can make one ox slate, dun or red (scripts/assets.gd).  It wears its own yoke: a bow of wood in front
of the hump, a nose-rope to a brass ring.
Clips: idle, walk (a slow heavy four-beat walk), run (the same walk hurried: an ox does not gallop),
and the attack, hurt and die every monster rig carries.
Run: blender --background --python art/mounts/ox.py  ->  assets/mounts/ox.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay  # noqa: E402
from creature import QuadMotion, quad_rig2, quad_skel, smooth  # noqa: E402
from kit import CLOTH, HAIR, MAT_PLAIN, METAL, SKIN, WOOD, V, Builder  # noqa: E402

kit.reset()
creature.realtime()
H = 1.12
hip_z, sh_z = -0.6, 0.5
neck0 = V(0, H + 0.02, sh_z + 0.1)
neck1 = V(0, H - 0.02, sh_z + 0.34)
headp = V(0, H - 0.04, sh_z + 0.5)
snout = headp + V(0, -0.24, 0.34)
tb = V(0, H - 0.02, hip_z - 0.2)
tail = [tb + V(0, -0.13 * k, -0.03 * k + 0.006 * k * k) for k in range(6)]
sk = quad_skel(H=H, hip_z=hip_z, sh_z=sh_z, hip_w=0.2, sh_w=0.19, foot="hoof", withers=0.2, croup=-0.04, neck=(neck1, headp), head=snout, tail=tail)
HC = headp + V(0, -0.03, 0.08)
hf = A.HeadFrame(HC, V(0, -0.55, 0.84))
K = 1.9


def hp(x, y, z):
    return hf.at(x * K, y * K, z * K)


ears = [(hp(0.07, 0.03, -0.05), hp(0.15, 0.02, -0.07)), (hp(-0.07, 0.03, -0.05), hp(-0.15, 0.02, -0.07))]
r, legs = quad_rig2(sk, ears=ears)
r.bones["jaw"] = (hp(0, -0.03, 0.0), hp(0, -0.04, 0.2), "head")
b = Builder("ox")

# ---------------------------------------------------------------- body
c = Clay(0.02, "ox_body")
NECK = [V(0, H - 0.02, sh_z), neck0.lerp(neck1, 0.55) + V(0, -0.04, 0), headp + V(0, -0.05, -0.04)]
NECK_R = [0.27, 0.22, 0.16]
A.clay_torso(c, sk, w=0.34, d=0.4, haunch=(0.3, 0.3, 0.3), belly=0.05, withers=0.24, neck=NECK_R, throat=0.17, chest_y=0.72, neck_pts=NECK)
# the hump: a mound of muscle over the shoulders, the highest point of the animal
c.ellipsoid(V(0, H + 0.2, sh_z - 0.1), (0.17, 0.16, 0.3), bones={"chest": 1.0}, tag="body")
# the dewlap: a fold of skin hanging from the throat down to the brisket
c.chain([neck1 + V(0, -0.24, 0.04), neck0 + V(0, -0.36, 0.02), V(0, H - 0.5, sh_z + 0.02), V(0, H - 0.56, sh_z - 0.2)], [0.05, 0.075, 0.09, 0.07],
        bones={"neck0": 0.5, "chest": 0.5}, tag="dewlap")
for sd in ("L", "R"):
    A.clay_foreleg(c, sk, sd, g=1.12, foot="hoof", paw=1.15)
    A.clay_hindleg(c, sk, sd, g=1.12, foot="hoof", paw=1.15)
A.clay_tail(c, sk, [0.045, 0.03, 0.022, 0.018, 0.016, 0.014])
# the head: a broad flat brow between the horn bases, cheeks deep under the eye, a long straight
# face widening again to a broad square muzzle
A.head_clay(c, hf, K, [
    ("ell", (0, 0.03, -0.03), (0.075, 0.06, 0.075), "head", False, False),
    ("ell", (0.05, -0.015, -0.01), (0.035, 0.055, 0.06), "head", True, False),
    ("ell", (0, 0.012, 0.07), (0.055, 0.05, 0.08), "muzzle", False, False),
    ("ell", (0, 0.0, 0.15), (0.05, 0.046, 0.06), "muzzle", False, False),
    ("ell", (0, -0.012, 0.2), (0.056, 0.046, 0.042), "muzzle", False, False),
    ("ball", (0.03, 0.0, 0.228), 0.02, "muzzle", True, False),
    ("ell", (0.062, 0.035, 0.02), (0.022, 0.016, 0.02), "head", True, True),
])


def head_local(p):
    return hf.M.transposed() @ (p - HC) / K


def col(p, info):
    tag = info.tag
    n = info.n
    if tag in ("head", "muzzle"):
        q = head_local(p)
        # a dark face, and the pale wet muzzle of a buffalo
        v = 0.6 - 0.1 * smooth(0.0, 0.1, q.z)
        pale = smooth(0.15, 0.2, q.z)
        return ((v * (1.0 - pale) + 0.86 * pale),) * 3
    if tag == "dewlap":
        # the pale chevron under the throat
        return (0.84, 0.84, 0.84)
    under = smooth(-0.15, -0.6, n.y)
    if tag in ("body", "neck"):
        # dark along the back and over the hump, paling down the flank to the belly
        v = 0.66 - 0.16 * smooth(0.2, 0.95, n.y)
        return (v * (1.0 - under) + 0.9 * under,) * 3
    if tag in ("fleg", "hleg"):
        # pale stockings above dark points
        v = 0.62 + 0.2 * smooth(0.9, 1.3, info.t) - 0.5 * smooth(1.45, 1.8, info.t)
        return (v, v, v)
    if tag == "fetlock":
        return (0.28, 0.28, 0.28)
    if tag == "tail":
        return (0.45, 0.45, 0.45)
    return (0.64, 0.64, 0.64)


c.build(b, col, cls=SKIN, tint_fn=lambda p, info: 1.0)

# ---------------------------------------------------------------- jaw, eyes, nostrils, ears, horns
j = Clay(0.014, "ox_jaw")
for s in (1, -1):
    j.chain([hp(0.035 * s, -0.045, 0.0), hp(0.03 * s, -0.05, 0.1), hp(0.022 * s, -0.045, 0.18)], [0.026, 0.022, 0.02], bones={"jaw": 1.0}, tag="jaw")
j.build(b, lambda p, info: (0.6, 0.6, 0.6), cls=SKIN, tint_fn=lambda p, info: 1.0)
for s in (1, -1):
    A.animal_eye(b, hp(0.064 * s, 0.035, 0.02), hf.r * s * 0.9 + hf.f * 0.3 + hf.u * 0.1, 0.017 * K, "2a1a10", "head", pupil="round", almond=0.75, slant=-0.05, side=s)
    b.ellipsoid(hp(0.03 * s, 0.002, 0.24), (0.012, 0.016, 0.008), "1a1210", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=8, rings=6, mat=MAT_PLAIN)
for s, sd in ((1, "L"), (-1, "R")):
    # ears carried level, under the horns, opening forward
    A.ear(b, hp(0.07 * s, 0.03, -0.05), hf.r * (0.95 * s) - hf.u * 0.1 - hf.f * 0.1, 0.085 * K, 0.045 * K, 0.022 * K, (0.5, 0.5, 0.5), (0.8, 0.74, 0.72), "ear." + sd,
          up=hf.f * 0.7 + hf.u * 0.5, point=0.6, cup=0.55, tint=1.0, tint_in=0.4, side=s)
    # the horns: out of the sides of the skull, sweeping out, back and up in a flat crescent
    base = hp(0.06 * s, 0.065, -0.06)
    back = V(0, 0.25, -1.0)
    horn = [base, base + V(0.13 * s, 0.0, 0.0) + back * 0.02, base + V(0.26 * s, 0.01, 0.0) + back * 0.1,
            base + V(0.34 * s, 0.03, 0.0) + back * 0.22, base + V(0.34 * s, 0.07, 0.0) + back * 0.34, base + V(0.27 * s, 0.12, 0.0) + back * 0.43]
    A.horn(b, horn, 0.052, "4a443a", "d8d0bc", "head", r1=0.008, rings=5, seg=12, per=5, power=1.2)

# ---------------------------------------------------------------- the tuft of the tail
tl = sk.tail
for k in range(7):
    a = k / 7 * 2 * math.pi
    out = V(math.cos(a), 0.1, math.sin(a) * 0.7)
    A.lock(b, tl[4] + out * 0.012, (V(0, -1, -0.1) + out * 0.2).normalized(), out, 0.24 + 0.03 * (k % 3), 0.05, (0.16,) * 3, (0.3,) * 3,
           bone={"tail3": 0.5, "tail4": 0.5}, lift=0.12, rise=0.06, cls=HAIR, droop=0.15)

# ---------------------------------------------------------------- hooves: cloven
for sd, s in (("L", 1), ("R", -1)):
    for pre, ft in (("f", "ft"), ("h", "ht")):
        p1 = sk[ft + "." + sd]
        A.hoof(b, V(p1.x, 0.0, p1.z - 0.03), V(0, 0, 1), 0.07, 0.085, "2a2420", pre + "_toe." + sd, cloven=True, col_top="3a302a")

# ---------------------------------------------------------------- what it wears: a blanket, the yoke, a nose-rope, a rosette
BACK = V(0, H + 0.1, -0.12)
b.cur_pal = 0.5
for s in (1, -1):
    rows = []
    for i in range(5):
        z = BACK.z - 0.3 + i * 0.15
        rows.append([V(0.0, H + 0.17 + 0.015 * math.sin(math.pi * i / 4), z), V(0.2 * s, H + 0.14, z), V(0.36 * s, H + 0.0, z), V(0.43 * s, H - 0.3, z)])
    b.sheet(rows, "c8c8c8", cls=CLOTH, bone="body", tint=1.0, thickness=0.012)
# the rosette of market day between the horns
b.lathe(hp(0, 0.085, -0.02), [(0.0, 0.0), (0.045, 0.004), (0.03, 0.02), (0.0, 0.024)], "c8c8c8", cls=CLOTH, bone="head", seg=10)
b.cur_pal = 0.0
# the yoke: a bow of wood lying on the neck in front of the hump, its ends turned down for the shafts
YZ = sh_z + 0.2
yoke = [V(-0.44, H - 0.14, YZ), V(-0.36, H + 0.04, YZ), V(-0.2, H + 0.16, YZ), V(0.0, H + 0.2, YZ), V(0.2, H + 0.16, YZ), V(0.36, H + 0.04, YZ), V(0.44, H - 0.14, YZ)]
b.tube(yoke, [0.035, 0.045, 0.05, 0.055, 0.05, 0.045, 0.035], "7a5230", cls=WOOD, bone={"neck0": 0.5, "chest": 0.5}, seg=8)
for s in (1, -1):
    b.ball(V(0.44 * s, H - 0.16, YZ), 0.045, "5a3a22", cls=WOOD, bone={"neck0": 0.5, "chest": 0.5}, seg=8, rings=6)
    # a strap under the throat holds it on
    b.tube([V(0.34 * s, H + 0.04, YZ), V(0.26 * s, H - 0.3, YZ + 0.02), V(0.0, H - 0.5, YZ + 0.03)], [0.014, 0.014, 0.014], "4a2a16", cls=WOOD, bone={"neck0": 0.5, "chest": 0.5}, seg=4, flat=0.4)
# the nose-ring of brass and the rope from it back to the yoke
ring = [hp(math.cos(a) * 0.022, -0.035 + math.sin(a) * 0.022, 0.235) for a in [i / 10 * 2 * math.pi for i in range(11)]]
b.tube(ring, [0.006] * 11, "d8b050", cls=METAL, bone="head", seg=5, cap0=False, cap1=False)
nose = hp(0.0, -0.055, 0.235)
b.tube([nose, nose.lerp(V(0.2, H + 0.1, YZ), 0.4) + V(0.1, -0.12, 0), nose.lerp(V(0.2, H + 0.1, YZ), 0.75) + V(0.08, -0.08, 0), V(0.22, H + 0.15, YZ)], [0.008] * 4, "b8a070", cls=CLOTH,
       bone={"neck1": 0.5, "neck0": 0.5}, seg=4)

# ---------------------------------------------------------------- motion
qm = QuadMotion(r, legs, T_walk=1.7, stride=0.4, lift=0.09, duty=0.68, bob=0.014, roll=0.03, yaw=0.03, head_nod=0.09, head_low=0.06,
                neck_up=-0.04, tail_amp=0.22, tail_lift=0.0, tail_droop=0.1, pounce="rear", T_idle=5.0, front_flex=1.5, hind_flex=0.8,
                rest_h=0.2, lunge=0.2)
# hurried: the same heavy walk, quicker and longer.  An ox in a hurry is still an ox.
hm = QuadMotion(r, legs, T_walk=1.05, stride=0.55, lift=0.12, duty=0.6, bob=0.024, roll=0.035, yaw=0.035, head_nod=0.12, head_low=0.08,
                neck_up=-0.04, tail_amp=0.3, tail_lift=0.15, tail_droop=0.0, T_idle=5.0, front_flex=1.6, hind_flex=0.9, rest_h=0.2)

print("[art] ox: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "mounts/ox.glb", qm.clips({"run": (1.05, hm.walk)}), samples=16, dist=0.3, strength=0.5, floor_y=0.0)
