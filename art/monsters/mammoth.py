"""Mammoth (new in Part V): a shaggy giant of the Aurora Steppe (Frost Yak, Mammoth Ancestor, Kui).

After the woolly mammoth as the cave painters drew it (Rouffignac, Chauvet) and as frozen
carcasses show it:

* **Silhouette.**  The highest point is the head: a tall single dome over the brow; behind it a
  notch at the neck, then the fatty hump over the shoulders, and the back slopes steeply down to
  low hindquarters.  Long, curving tusks sweep out, down, forward and up, crossing at the tips in
  front of a trunk that hangs nearly to the ground.  Small ears and a short tufted tail (both
  cut down against the cold); pillar legs on round padded feet with toenails.
* **Coat.**  A dense undercoat under long guard hairs that hang from the flanks and belly in a
  skirt nearly to the knees, longest over the shoulders - sculpted as a fringe of broad locks
  that breaks the outline - and a mop of hair on the crown of the dome.
* **Value.**  Darker over the hump and back, the hanging hair paler at its ends, the trunk and
  face darker, the tusks ivory, so the head reads clearly from the front between the tusks.

Clips: idle (trunk swaying, ears flapping), walk (a slow heavy four-beat walk), attack (a tusk
sweep), hurt, die and cast (trumpeting).
Run: blender --background --python art/monsters/mammoth.py  ->  assets/monsters/mammoth.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from creature import QuadMotion, add, quad_rig2, quad_skel, smooth  # noqa: E402
from kit import CLOTH, MAT_PLAIN, SKIN, STONE, V, Builder  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
H = 1.38
hip_z, sh_z = -0.62, 0.42
neck0 = V(0, 1.5, sh_z + 0.12)
neck1 = V(0, 1.52, sh_z + 0.26)
headp = V(0, 1.54, sh_z + 0.34)
snout = V(0, 1.18, 1.05)
tb = V(0, 1.18, hip_z - 0.3)
tail = [tb + V(0, -0.1 * k, -0.035 * k) for k in range(5)]
sk = quad_skel(H=H, hip_z=hip_z, sh_z=sh_z, hip_w=0.28, sh_w=0.3, foot="pillar", withers=0.3, croup=-0.12, neck=(neck1, headp), head=snout, tail=tail)
for sd, s in (("L", 1), ("R", -1)):
    # straight pillar legs: the joints stacked almost vertically under the body
    sk["sc." + sd] = V(0.24 * s, 1.5, sh_z - 0.12)
    sk["sh." + sd] = V(0.3 * s, 1.03, sh_z + 0.02)
    sk["el." + sd] = V(0.3 * s, 0.6, sh_z - 0.05)
    sk["wr." + sd] = V(0.3 * s, 0.19, sh_z - 0.02)
    sk["fb." + sd] = V(0.3 * s, 0.07, sh_z + 0.02)
    sk["ft." + sd] = V(0.3 * s, 0.01, sh_z + 0.14)
    sk["hip." + sd] = V(0.28 * s, 0.99, hip_z)
    sk["kn." + sd] = V(0.28 * s, 0.58, hip_z + 0.06)
    sk["hk." + sd] = V(0.28 * s, 0.19, hip_z - 0.03)
    sk["hb." + sd] = V(0.28 * s, 0.07, hip_z + 0.01)
    sk["ht." + sd] = V(0.28 * s, 0.01, hip_z + 0.13)
HC = V(0, 1.55, 0.86)
hf = A.HeadFrame(HC, V(0, -0.55, 1.0))
# the trunk hangs from between the tusk sockets nearly to the ground, the tip curling forward
TR = [V(0, 1.22, 1.08), V(0, 1.02, 1.16), V(0, 0.8, 1.18), V(0, 0.58, 1.16), V(0, 0.38, 1.17), V(0, 0.24, 1.24), V(0, 0.2, 1.34)]
ears = [(V(0.25, 1.6, 0.72), V(0.33, 1.47, 0.66)), (V(-0.25, 1.6, 0.72), V(-0.33, 1.47, 0.66))]
extra = []
prev = "head"
for i in range(len(TR) - 1):
    extra.append(("trunk%d" % i, TR[i], TR[i + 1], prev))
    prev = "trunk%d" % i
r, legs = quad_rig2(sk, ears=ears, extra=extra)
r.bones["jaw"] = (V(0, 1.3, 0.86), V(0, 1.16, 0.98), "head")
b = Builder("mammoth")

# ---------------------------------------------------------------- body
c = Clay(0.03, "mammoth_body")
# low hindquarters, the barrel, a deep chest, and the fatty hump over the shoulders
c.ellipsoid(V(0, 1.1, hip_z), (0.36, 0.34, 0.34), bones={"pelvis": 1.0}, tag="body")
c.ellipsoid(V(0, 1.1, -0.2), (0.42, 0.44, 0.5), bones={"loin": 0.5, "body": 0.5}, tag="body")
c.ellipsoid(V(0, 1.18, 0.3), (0.42, 0.48, 0.4), bones={"chest": 0.7, "body": 0.3}, tag="body")
c.ellipsoid(V(0, 1.52, 0.22), (0.3, 0.26, 0.36), rot=(0.25, 0, 0), bones={"chest": 1.0}, tag="hump")
c.ellipsoid(V(0, 1.4, -0.25), (0.3, 0.2, 0.4), rot=(0.3, 0, 0), bones={"body": 0.6, "chest": 0.4}, tag="hump")
# a short thick neck dipping between the hump and the dome of the head
c.chain([V(0, 1.32, 0.5), V(0, 1.38, 0.66)], [0.36, 0.33], bones={"neck0": 0.5, "neck1": 0.5}, tag="neck", t0=0.0, t1=1.0)
for sd in ("L", "R"):
    A.clay_foreleg(c, sk, sd, g=1.12, foot="pillar", paw=1.05)
    A.clay_hindleg(c, sk, sd, g=1.12, foot="pillar", paw=1.0)
A.clay_tail(c, sk, [0.06, 0.05, 0.04, 0.035, 0.03])
# the head: the tall single dome over the brow, the long face down to the trunk, the tusk sockets
c.ellipsoid(V(0, 1.66, 0.8), (0.25, 0.28, 0.25), rot=(0.2, 0, 0), bones={"head": 1.0}, tag="dome")
c.ellipsoid(V(0, 1.44, 0.95), (0.23, 0.27, 0.19), rot=(0.35, 0, 0), bones={"head": 1.0}, tag="face")
for s in (1, -1):
    c.ellipsoid(V(0.13 * s, 1.24, 1.02), (0.1, 0.12, 0.1), bones={"head": 1.0}, tag="face")
c.ellipsoid(V(0, 1.24, 1.06), (0.13, 0.12, 0.1), bones={"head": 1.0}, tag="face")
c.chain(TR, [0.15, 0.12, 0.1, 0.085, 0.07, 0.058, 0.048], bones=limb_weights(["trunk%d" % i for i in range(len(TR) - 1)]), tag="trunk",
        t0=0.0, t1=len(TR) - 1.0)


def col(p, info):
    tag = info.tag
    n = info.n
    g = fbm3((p.x * 5.0, p.y * 5.0, p.z * 5.0), 2, 3)
    if tag == "trunk":
        ring = smooth(0.62, 0.9, 0.5 + 0.5 * math.cos(info.t * 16.0))
        v = 0.56 - 0.1 * ring + 0.08 * smooth(-0.2, -0.8, n.z)
        return (v, v, v)
    if tag == "paw":
        return (0.52, 0.52, 0.52)
    if tag in ("fleg", "hleg", "leg"):
        v = 0.66 - 0.1 * smooth(1.6, 2.6, info.t) + 0.06 * (g - 0.5)
        return (v, v, v)
    if tag == "face":
        return (0.6 + 0.05 * (g - 0.5),) * 3
    # the coat: darker over the hump and the back
    v = 0.68 - 0.16 * smooth(0.3, 0.9, n.y) + 0.06 * (g - 0.5)
    return (v, v, v)


def shingle(p, info):
    """The dense undercoat lies in soft shingles groomed down the body."""
    if info.tag in ("trunk", "paw", "face"):
        return None
    nn = info.n
    w = fbm3((p.x * 6.0, p.y * 6.0, p.z * 6.0), 2, 11)
    u = -p.y * 6.0 + 0.5 * math.sin(math.atan2(nn.x, nn.z) * 7.0) + 1.0 * w
    k = u - math.floor(u)
    return nn * (0.014 * math.sin(math.pi * k) ** 2)


c.build(b, col, cls=CLOTH, tint_fn=lambda p, info: 1.0 if info.tag != "paw" else 0.6, post=shingle)

# ---------------------------------------------------------------- the skirt of guard hair, a fringe that breaks the outline
skirt = Clay(0.034, "mammoth_skirt")
for side in (1, -1):
    for k in range(12):
        z = hip_z + 0.0 + k * 0.1
        jit = math.sin(k * 2.7 + side) * 0.5 + 0.5
        top_y = 1.3 + 0.12 * smooth(-0.3, 0.3, z)
        rx = 0.34 + 0.05 * math.sin(math.pi * k / 11)
        root = V((rx - 0.04) * side, top_y, z)
        tip = V((rx + 0.05) * side, 0.6 + 0.1 * jit + 0.05 * smooth(-0.3, 0.3, z), z - 0.07)
        mid = root.lerp(tip, 0.45) + V(0.06 * side, 0, 0)
        wd = 0.085 + 0.02 * jit
        bw = {"pelvis": 1.0} if z < -0.45 else ({"loin": 0.5, "body": 0.5} if z < 0.0 else {"chest": 0.7, "body": 0.3})
        skirt.chain([root, mid, tip], [wd, wd * 0.82, 0.045], bones=bw, tag="skirt", t0=0.0, t1=1.0)
# the long hair under the chest and the throat, and down the backs of the thighs
for k in range(5):
    u = (k / 4 - 0.5) * 2
    root = V(u * 0.25, 0.95, 0.42 - abs(u) * 0.05)
    tip = V(u * 0.3, 0.55, 0.45)
    skirt.chain([root, tip], [0.12, 0.05], bones={"chest": 1.0}, tag="skirt", t0=0.0, t1=1.0)
for k in range(4):
    u = (k / 3 - 0.5) * 2
    root = V(u * 0.22, 1.2, 0.62)
    tip = V(u * 0.28, 0.82, 0.68)
    skirt.chain([root, tip], [0.11, 0.05], bones={"neck0": 0.6, "chest": 0.4}, tag="skirt", t0=0.0, t1=1.0)
# long hair at the back of the haunches and over the shoulders
for side in (1, -1):
    for k in range(4):
        a = side * (0.35 + 0.3 * k)
        root = V(math.sin(a) * 0.3, 1.25 - 0.04 * k, hip_z - 0.24 + 0.04 * k)
        tip = V(math.sin(a) * 0.36, 0.72 + 0.06 * (k % 2), hip_z - 0.3 + 0.03 * k)
        skirt.chain([root, root.lerp(tip, 0.5) - V(0, 0, 0.04), tip], [0.09, 0.075, 0.042], bones={"pelvis": 1.0}, tag="skirt", t0=0.0, t1=1.0)
    for k in range(4):
        z = sh_z - 0.1 + k * 0.1
        root = V(0.3 * side, 1.5 - 0.03 * k, z)
        tip = V(0.44 * side, 1.12 + 0.05 * (k % 2), z - 0.06)
        skirt.chain([root, root.lerp(tip, 0.5) + V(0.05 * side, 0, 0), tip], [0.1, 0.085, 0.045], bones={"chest": 1.0}, tag="skirt", t0=0.0, t1=1.0)
# a mop of hair on the crown of the dome
for k in range(6):
    a = (k / 5 - 0.5) * 2.4
    root = V(math.sin(a) * 0.12, 1.86, 0.76 + 0.04 * math.cos(a))
    tip = root + V(math.sin(a) * 0.12, -0.08, -0.12)
    skirt.chain([root, tip], [0.07, 0.03], bones={"head": 1.0}, tag="mop", t0=0.0, t1=1.0)


def skirt_col(p, info):
    # the guard hair is paler towards its ends
    v = 0.6 + 0.07 * smooth(0.2, 1.0, info.t)
    return (v, v, v)


def comb(p, info):
    """Long straight hair: a few soft grooves running down the locks."""
    nn = info.n
    g = 0.5 + 0.5 * math.cos(2 * math.pi * (p.z * 6.0 + p.x * 6.0))
    return nn * (0.006 * g * smooth(0.1, 0.5, info.t))


skirt.build(b, skirt_col, cls=CLOTH, tint_fn=lambda p, info: 1.0, post=comb)

# ---------------------------------------------------------------- face: eyes, mouth, tusks, ears, toenails
hit = A.surface(b)
for s in (1, -1):
    # small eyes low on the side of the face, set into the skin
    d = V(0.8 * s, 0.05, 0.6).normalized()
    h = hit(V(0, 1.47, 0.95) + d * 0.6, -d, 1.0)
    ep = h[0] - d * 0.008 if h is not None else V(0.2 * s, 1.47, 1.0)
    A.animal_eye(b, ep, V(0.8 * s, 0.05, 0.6), 0.026, "6a4020", "head", pupil="round", almond=0.68, side=s, lid="1a1210", lid_w=0.2)
b.ellipsoid(V(0, 1.12, 0.98), (0.09, 0.05, 0.07), "3a2024", cls=SKIN, bone="jaw", seg=12, rings=6, mat=MAT_PLAIN)
for s in (1, -1):
    # tusks: long ivory curving out, down, forward and up in a spiral, the tips turning in
    base = V(0.13 * s, 1.2, 1.05)
    tusk = [base, base + V(0.05 * s, -0.22, 0.14), base + V(0.17 * s, -0.4, 0.42), base + V(0.24 * s, -0.3, 0.76), base + V(0.16 * s, -0.02, 0.98),
            base + V(0.02 * s, 0.18, 0.98)]
    A.horn(b, tusk, 0.07, "c8b890", "f8f2e2", "head", r1=0.008, rings=0, seg=14, per=5, power=1.3)
    b.ellipsoid(base + V(0, 0.01, -0.01), (0.1, 0.09, 0.1), (0.58, 0.58, 0.58), cls=CLOTH, bone="head", tint=1.0, seg=12, rings=8)
for s, sd in ((1, "L"), (-1, "R")):
    # small fur-covered ears (cut down against the cold)
    A.ear(b, V(0.24 * s, 1.6, 0.72), V(0.8 * s, 0.0, 0.6), 0.16, 0.13, 0.05, (0.62, 0.62, 0.62), (0.7, 0.66, 0.66), "ear." + sd,
          up=V(0.3 * s, -0.9, -0.2), point=0.2, cup=0.3, tint=1.0, tint_in=0.8, side=s)
for sd, s in (("L", 1), ("R", -1)):
    for pre, fb in (("f", "fb"), ("h", "hb")):
        foot = sk[fb + "." + sd]
        for k in range(4):
            a = (k - 1.5) * 0.42
            b.ellipsoid(V(foot.x + math.sin(a) * 0.13, 0.04, foot.z + 0.05 + math.cos(a) * 0.12), (0.045, 0.04, 0.03), "e8dcc0", cls=STONE,
                        bone=pre + "_toe." + sd, seg=8, rings=5, rot=(0, a, 0), mat=MAT_PLAIN)
# the tuft at the end of the short tail
tl = sk.tail
for k in range(5):
    A.lock(b, tl[-2], V((k - 2) * 0.15, -1.0, -0.2), V(0, 0, -1), 0.18, 0.04, (0.5,) * 3, (0.45,) * 3, bone="tail3", lift=0.2, rise=0.1, cls=CLOTH)

# ---------------------------------------------------------------- motion
qm = QuadMotion(r, legs, T_walk=1.8, stride=0.56, lift=0.12, duty=0.68, bob=0.025, crouch=0.035, roll=0.03, yaw=0.04, head_nod=0.04, head_low=0.0,
                tail_amp=0.25, tail_lift=0.0, pounce="ram", T_idle=4.0, front_flex=0.7, hind_flex=0.4, rest_h=0.5, lunge=0.25)
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
    trunk(p, t, 4.0, 0.1)
    ears_flap(p, t, 4.0, 0.18)
    return p


def walk(t):
    p = qm.walk(t)
    trunk(p, t, 1.8, 0.14)
    ears_flap(p, t, 1.8, 0.1)
    return p


def attack(t):
    """Head down, a sweep of the tusks from side to side, then up."""
    p = qm.attack(t)
    k = t / 0.55
    sweep = math.sin(math.pi * smooth(0.25, 0.7, k))
    add(p, "neck0", (0.15 * sweep, 0.35 * math.sin(2 * math.pi * smooth(0.25, 0.75, k)), 0.0))
    trunk(p, t, 0.55, 0.28, curl=0.6 * sweep)
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
