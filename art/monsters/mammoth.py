"""Mammoth (new in Part V): a shaggy giant of the Aurora Steppe (Frost Yak, Mammoth Ancestor).
Sculpted in clay (art/lib/clay.py): high domed shoulders sloping down to low haunches, a heavy
hanging belly, pillar legs on round padded feet with toenails, a high domed skull with a deep
forehead, a six-bone trunk ringed with wrinkles and ending in two fingers, long tusks spiralling
out and up from their sockets, small fur-covered ears and a short tail.  The coat is a dense
undercoat shingled into the skin and a skirt of broad guard-hair locks hanging from the back and
flanks nearly to the knees, longer over the shoulders and the hump.
Clips: idle (trunk swaying, ears flapping), walk (a slow heavy four-beat walk), attack (a tusk
sweep), hurt, die and cast (trumpeting).
Run: blender --background --python art/monsters/mammoth.py  ->  assets/monsters/mammoth.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from creature import QuadMotion, add, quad_rig2, quad_skel, smooth  # noqa: E402
from kit import CLOTH, HAIR, MAT_PLAIN, SKIN, STONE, V, Builder  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(21)
H = 1.38
hip_z, sh_z = -0.62, 0.5
neck0 = V(0, H + 0.02, sh_z + 0.12)
neck1 = V(0, H + 0.05, sh_z + 0.28)
headp = V(0, H + 0.05, sh_z + 0.38)
snout = headp + V(0, -0.3, 0.32)
tb = V(0, H - 0.25, hip_z - 0.28)
tail = [tb + V(0, -0.1 * k, -0.04 * k) for k in range(5)]
sk = quad_skel(H=H, hip_z=hip_z, sh_z=sh_z, hip_w=0.3, sh_w=0.32, foot="pillar", withers=0.12, croup=-0.18, neck=(neck1, headp), head=snout, tail=tail)
for sd, s in (("L", 1), ("R", -1)):
    # straight pillar legs: the joints stacked almost vertically under the body
    sk["sh." + sd] = V(0.32 * s, 0.72 * H, sh_z + 0.02)
    sk["el." + sd] = V(0.32 * s, 0.42 * H, sh_z - 0.05)
    sk["wr." + sd] = V(0.32 * s, 0.13 * H, sh_z - 0.02)
    sk["fb." + sd] = V(0.32 * s, 0.05 * H, sh_z + 0.02)
    sk["ft." + sd] = V(0.32 * s, 0.01, sh_z + 0.14)
    sk["hip." + sd] = V(0.3 * s, 0.7 * H, hip_z)
    sk["kn." + sd] = V(0.3 * s, 0.42 * H, hip_z + 0.06)
    sk["hk." + sd] = V(0.3 * s, 0.14 * H, hip_z - 0.03)
    sk["hb." + sd] = V(0.3 * s, 0.05 * H, hip_z + 0.01)
    sk["ht." + sd] = V(0.3 * s, 0.01, hip_z + 0.13)
HC = V(0, H + 0.18, sh_z + 0.5)
hf = A.HeadFrame(HC, V(0, -0.45, 1.0))
TR = [hf.at(0, -0.12, 0.2), hf.at(0, -0.3, 0.27), hf.at(0, -0.52, 0.28), hf.at(0, -0.74, 0.24), hf.at(0, -0.92, 0.25), hf.at(0, -1.02, 0.36), hf.at(0, -1.0, 0.48)]
ears = [(hf.at(0.22, 0.02, -0.12), hf.at(0.34, -0.12, -0.16)), (hf.at(-0.22, 0.02, -0.12), hf.at(-0.34, -0.12, -0.16))]
extra = []
prev = "head"
for i in range(len(TR) - 1):
    extra.append(("trunk%d" % i, TR[i], TR[i + 1], prev))
    prev = "trunk%d" % i
r, legs = quad_rig2(sk, ears=ears, extra=extra)
r.bones["jaw"] = (hf.at(0, -0.1, 0.0), hf.at(0, -0.2, 0.15), "head")
b = Builder("mammoth")

# ---------------------------------------------------------------- body
c = Clay(0.026, "mammoth_body")
A.clay_torso(c, sk, w=0.36, d=0.42, haunch=(0.3, 0.3, 0.3), tuck=0.0, belly=0.1, withers=0.18, neck=(0.3, 0.28, 0.26), throat=0.2, chest_y=0.72, loin_y=0.82,
             neck_pts=[V(0, H, sh_z), neck0.lerp(neck1, 0.5), HC + V(0, -0.1, -0.1)])
# the hump over the shoulders and the high domed skull
c.ellipsoid(V(0, H + 0.1, sh_z - 0.05), (0.26, 0.2, 0.32), bones={"chest": 1.0}, tag="hump")
for sd in ("L", "R"):
    A.clay_foreleg(c, sk, sd, g=1.15, foot="pillar", paw=1.1)
    A.clay_hindleg(c, sk, sd, g=1.15, foot="pillar", paw=1.05)
A.clay_tail(c, sk, [0.06, 0.05, 0.04, 0.035, 0.03])
# the coat's skirt: long guard hair hanging from the flanks below the belly line
for s_ in (1, -1):
    for k, (z, bones_) in enumerate(((hip_z + 0.05, {"pelvis": 0.7, "loin": 0.3}), (-0.2, {"loin": 0.5, "body": 0.5}), (0.1, {"body": 0.6, "chest": 0.4}), (sh_z - 0.05, {"chest": 1.0}))):
        c.ellipsoid(V(0.27 * s_, 0.6 * H, z), (0.15, 0.3 * H, 0.26), rot=(0.0, 0.0, -0.12 * s_), bones=bones_, tag="skirt")
A.head_clay(c, hf, 1.0, [
    ("ell", (0, 0.08, -0.04), (0.24, 0.26, 0.24), "head", False, False),
    ("ell", (0, 0.2, -0.06), (0.17, 0.16, 0.17), "head", False, False),
    ("ell", (0, -0.05, 0.1), (0.2, 0.17, 0.16), "head", False, False),
    ("ell", (0.12, -0.12, 0.12), (0.09, 0.09, 0.09), "head", True, False),
    ("ell", (0.15, 0.0, 0.17), (0.035, 0.025, 0.03), "head", True, True),
])
c.chain(TR, [0.15, 0.13, 0.11, 0.09, 0.075, 0.06, 0.05], bones=limb_weights(["trunk%d" % i for i in range(len(TR) - 1)]), tag="trunk", t0=0.0, t1=len(TR) - 1.0)


def col(p, info):
    tag = info.tag
    n = info.n
    g = fbm3((p.x * 5.0, p.y * 5.0, p.z * 5.0), 2, 3)
    if tag == "trunk":
        ring = smooth(0.6, 0.9, 0.5 + 0.5 * math.cos(info.t * 18.0))
        v = 0.76 - 0.12 * ring + 0.12 * smooth(-0.2, -0.8, n.z)
        return (v, v, v)
    if tag == "paw":
        return (0.5, 0.5, 0.5)
    if tag in ("fleg", "hleg"):
        v = 0.74 - 0.12 * smooth(1.6, 2.6, info.t) + 0.08 * (g - 0.5)
        return (v, v, v)
    # shaggy brown: darker on the hump and the back, a little lighter on the flanks
    v = 0.84 - 0.12 * smooth(0.3, 0.9, n.y) + 0.1 * (g - 0.5)
    if tag == "head":
        v = 0.8 + 0.08 * (g - 0.5)
    return (v, v, v)


def shingle(p, info):
    """Long hair: the skirt grooved into broad hanging clumps, the rest of the coat gently
    shingled."""
    if info.tag in ("trunk", "paw"):
        return None
    nn = info.n
    w = fbm3((p.x * 6.0, p.y * 6.0, p.z * 6.0), 2, 11)
    sk_ = info.share("skirt")
    if sk_ > 0.2:
        g = 0.5 + 0.5 * math.cos(2 * math.pi * (p.z * 7.0 + 0.8 * w))
        return nn * (0.045 * g * smooth(0.2, 0.6, sk_))
    u = -p.y * 7.0 + 0.6 * math.sin(math.atan2(nn.x, nn.z) * 7.0) + 1.2 * w
    k = u - math.floor(u)
    return nn * (0.014 * math.sin(math.pi * k) ** 2)


# the skirt of guard hair takes the secondary colour
c.build(b, col, cls=CLOTH, tint_fn=lambda p, info: 1.0 if info.tag not in ("paw",) else 0.6, post=shingle,
        pal_fn=lambda p, info: 0.5 if info.share("skirt") > 0.5 else 0.0)

# ---------------------------------------------------------------- face: eyes, mouth, tusks, ears, toenails
for s in (1, -1):
    A.animal_eye(b, hf.at(0.15 * s, 0.0, 0.18), hf.f * 0.6 + hf.r * (0.8 * s), 0.022, "6a4020", "head", pupil="round", almond=0.75, side=s)
b.ellipsoid(hf.at(0, -0.2, 0.08), (0.08, 0.04, 0.06), "4a2028", cls=SKIN, bone="jaw", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
for s in (1, -1):
    # tusks: long ivory curving out, down, forward and up in a spiral, yellowed at the root
    base = hf.at(0.11 * s, -0.16, 0.12)
    tusk = [base, base + V(0.06 * s, -0.25, 0.18), base + V(0.18 * s, -0.4, 0.5), base + V(0.24 * s, -0.25, 0.85), base + V(0.14 * s, 0.05, 1.05), base + V(0.0 * s, 0.25, 1.02)]
    A.horn(b, tusk, 0.075, "c8b890", "f8f2e2", "head", r1=0.008, rings=0, seg=14, per=5, power=1.3)
    b.ellipsoid(base + V(0, 0.02, -0.02), (0.1, 0.09, 0.1), (0.55, 0.55, 0.55), cls=CLOTH, bone="head", tint=1.0, seg=12, rings=8)
for s, sd in ((1, "L"), (-1, "R")):
    # small, fur-covered ears (cold-adapted)
    A.ear(b, hf.at(0.21 * s, 0.04, -0.1), hf.r * s * 0.6 + hf.f * 0.8, 0.15, 0.12, 0.045, (0.72, 0.72, 0.72), (0.8, 0.74, 0.74), "ear." + sd,
          up=-hf.u + hf.r * s * 0.3, point=0.2, cup=0.3, tint=1.0, tint_in=0.8, side=s)
for sd, s in (("L", 1), ("R", -1)):
    for pre, fb in (("f", "fb"), ("h", "hb")):
        foot = sk[fb + "." + sd]
        for k in range(4):
            a = (k - 1.5) * 0.42
            b.ellipsoid(V(foot.x + math.sin(a) * 0.13, 0.04, foot.z + 0.05 + math.cos(a) * 0.12), (0.045, 0.04, 0.03), "e8dcc0", cls=STONE,
                        bone=pre + "_toe." + sd, seg=8, rings=5, rot=(0, a, 0), mat=MAT_PLAIN)

# ---------------------------------------------------------------- the coat of guard hairs
hit = A.surface(b)
# a mop on the crown and long hair on the legs' upper halves
for k in range(9):
    a = (k / 8 - 0.5) * 2.6
    root = hf.at(math.sin(a) * 0.14, 0.33, -0.05 + 0.04 * math.cos(a))
    A.lock(b, root, hf.f * 0.4 - hf.u * 0.2 + hf.r * math.sin(a) * 0.8, hf.u, 0.22, 0.08, (0.68,) * 3, (0.82,) * 3, bone="head", lift=0.3, rise=0.2, cls=HAIR)
for sd, s in (("L", 1), ("R", -1)):
    for pre in ("f", "h"):
        up = pre + "_up." + sd
        top = r.bones[up][0]
        kn = r.bones[up][1]
        for k in range(5):
            a = (k + 0.5) / 5 * 2 * math.pi
            out = V(math.sin(a), 0, math.cos(a))
            root = top.lerp(kn, 0.8) + out * 0.14
            A.lock(b, root, V(out.x * 0.2, -1.0, out.z * 0.2), out, 0.2, 0.1, (0.74,) * 3, (0.68,) * 3, bone=up, lift=0.2, rise=0.12, thick=0.5, cls=HAIR, steps=5, seg=7)
for k in range(5):
    tl = sk.tail
    A.lock(b, tl[-2], V((k - 2) * 0.15, -1.0, -0.2), V(0, 0, -1), 0.2, 0.04, (0.55,) * 3, (0.45,) * 3, bone="tail3", lift=0.2, rise=0.1, cls=HAIR)

# ---------------------------------------------------------------- motion
qm = QuadMotion(r, legs, T_walk=1.8, stride=0.56, lift=0.12, duty=0.68, bob=0.025, crouch=0.035, roll=0.03, yaw=0.04, head_nod=0.04, head_low=0.0,
                tail_amp=0.25, tail_lift=0.0, pounce="ram", T_idle=4.0, front_flex=0.7, hind_flex=0.4, rest_h=0.48, lunge=0.25)
TRUNK = ["trunk%d" % i for i in range(len(TR) - 1)]


def trunk(p, t, T, amp, curl=0.0):
    w = 2 * math.pi / T
    for i, nm in enumerate(TRUNK):
        add(p, nm, (math.sin(t * w - i * 0.7) * amp * (0.5 + 0.15 * i) - curl * (0.2 + 0.1 * i), math.sin(t * w + 1.3 - i * 0.6) * amp * 0.8, 0.0))


def ears_flap(p, t, T, amp):
    w = 2 * math.pi / T
    for sd, s in (("ear.L", 1), ("ear.R", -1)):
        add(p, sd, (0.0, s * amp * math.sin(t * w * 2), 0.0))


def idle(t):
    p = qm.idle(t)
    trunk(p, t, 4.0, 0.12)
    ears_flap(p, t, 4.0, 0.2)
    return p


def walk(t):
    p = qm.walk(t)
    trunk(p, t, 1.8, 0.16)
    ears_flap(p, t, 1.8, 0.12)
    return p


def attack(t):
    """Head down, a sweep of the tusks from side to side, then up."""
    p = qm.attack(t)
    k = t / 0.55
    sweep = math.sin(math.pi * smooth(0.25, 0.7, k))
    add(p, "neck0", (0.15 * sweep, 0.35 * math.sin(2 * math.pi * smooth(0.25, 0.75, k)), 0.0))
    trunk(p, t, 0.55, 0.3, curl=0.6 * sweep)
    return p


def hurt(t):
    p = qm.hurt(t)
    e = math.sin(math.pi * min(1.0, t / 0.55))
    trunk(p, t, 0.55, 0.2, curl=-0.5 * e)
    ears_flap(p, t, 0.55, 0.4 * e)
    return p


def die(t):
    p = qm.die(t)
    k = smooth(0.2, 0.85, t / 1.2)
    for i, nm in enumerate(TRUNK):
        add(p, nm, (-0.12 * k, -0.15 * k, 0.0))
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = qm.idle(0.0)
    add(p, "neck0", (-0.3 * e, 0, 0))
    add(p, "head", (-0.25 * e, 0, 0))
    trunk(p, t, 0.6, 0.1, curl=1.0 * e)
    ears_flap(p, t, 0.6, 0.5 * e)
    return p


print("[art] mammoth: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/mammoth.glb", {"idle": (4.0, idle), "walk": (1.8, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die),
                                                  "cast": (0.6, cast)}, samples=12, dist=0.3, strength=0.38, floor_y=0.0)
