"""Jade rabbit (new in Part IX): the hare of the moon who pounds the elixir of immortality.  An upright
white hare sculpted in clay (art/lib/clay.py): round powerful haunches on long flat hind feet, a
pear-shaped body with a fluffy chest, short forearms, a rounded head with a short muzzle, a split
upper lip and a twitching pink nose, big dark-red eyes set to the sides, two very long ears with
pink insides on their own two-bone chains, cheek ruffs of soft fur and a cotton tail.  It holds a
jade mortar against its belly in its left arm and a long pestle in its right paw.  The fur takes
the enemy's colour (white for the moon's own rabbit); the ears' insides, eyes, nose and the jade
keep theirs.
Clips: idle (pounding the elixir, ears swaying), walk (hops with both hind feet together, the ears
trailing), attack (swings the pestle overhead and brings it down), hurt, die (topples onto its
side), cast (holds the mortar up to the moon).
Run: blender --background --python art/monsters/jade_rabbit.py  ->  assets/monsters/jade_rabbit.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from creature import Poser, add, leg_ik, smooth, zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SKIN, STONE, WOOD, V, Builder, Rig, mix  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("hips", (0, 0.42, -0.06), (0, 0.6, -0.02), "root")
r.bone("spine", (0, 0.6, -0.02), (0, 0.8, 0.02), "hips")
r.bone("chest", (0, 0.8, 0.02), (0, 0.98, 0.04), "spine")
r.bone("neck", (0, 0.98, 0.04), (0, 1.05, 0.06), "chest")
r.bone("head", (0, 1.05, 0.06), (0, 1.22, 0.12), "neck")
HC = V(0, 1.14, 0.1)
hf = A.HeadFrame(HC, V(0, -0.1, 1.0))
EARS = {}
for s, sd in ((1, "L"), (-1, "R")):
    e0 = hf.at(0.045 * s, 0.09, -0.04)
    e1 = e0 + V(0.05 * s, 0.2, -0.04)
    e2 = e1 + V(0.03 * s, 0.2, -0.08)
    EARS[sd] = (e0, e1, e2)
    r.bone("ear0.%s" % sd, e0, e1, "head")
    r.bone("ear1.%s" % sd, e1, e2, "ear0.%s" % sd)
    sh = V(0.13 * s, 0.9, 0.06)
    el = sh + V(0.04 * s, -0.17, 0.06)
    wr = el + V(-0.05 * s, -0.03, 0.15)
    r.bone("upper_arm.%s" % sd, sh, el, "chest")
    r.bone("forearm.%s" % sd, el, wr, "upper_arm.%s" % sd)
    r.bone("hand.%s" % sd, wr, wr + V(-0.02 * s, 0.0, 0.07), "forearm.%s" % sd)
    hip = V(0.1 * s, 0.42, -0.06)
    kn = V(0.14 * s, 0.28, 0.1)
    an = V(0.13 * s, 0.1, -0.12)
    ball = V(0.12 * s, 0.025, 0.1)
    toe = V(0.12 * s, 0.02, 0.2)
    r.bone("thigh.%s" % sd, hip, kn, "hips")
    r.bone("shin.%s" % sd, kn, an, "thigh.%s" % sd)
    r.bone("foot.%s" % sd, an, ball, "shin.%s" % sd)
    r.bone("toe.%s" % sd, ball, toe, "foot.%s" % sd)
r.bone("tail", (0, 0.4, -0.22), (0, 0.44, -0.3), "hips")
b = Builder("jade_rabbit")


def hp(x, y, z):
    return hf.at(x, y, z)


# ---------------------------------------------------------------- body clay
c = Clay(0.012, "rabbit_body")
c.ellipsoid(V(0, 0.48, -0.04), (0.17, 0.15, 0.17), bones={"hips": 1.0}, tag="body")
c.ellipsoid(V(0, 0.66, 0.0), (0.15, 0.17, 0.14), bones={"spine": 0.7, "hips": 0.3}, tag="body")
c.ellipsoid(V(0, 0.86, 0.03), (0.13, 0.13, 0.12), bones={"chest": 1.0}, tag="body")
c.ellipsoid(V(0, 0.82, 0.1), (0.1, 0.12, 0.07), bones={"chest": 0.7, "spine": 0.3}, tag="chestfur")
c.chain([V(0, 0.92, 0.04), V(0, 1.02, 0.06), HC + V(0, -0.04, -0.02)], [0.09, 0.08, 0.07], bones=limb_weights(["chest", "neck"]), tag="body", t0=0.0, t1=2.0)
# the head: a rounded skull, full cheeks, a short muzzle with a split upper lip
A.head_clay(c, hf, 1.0, [
    ("ell", (0, 0.01, -0.01), (0.085, 0.085, 0.095), "head", False, False),
    ("ell", (0.055, -0.035, 0.03), (0.045, 0.045, 0.05), "cheek", True, False),
    ("ell", (0, -0.03, 0.08), (0.05, 0.042, 0.05), "muzzle", False, False),
    ("ball", (0.02, -0.045, 0.115), 0.024, "muzzle", True, False),
    ("ell", (0.065, 0.022, 0.045), (0.02, 0.022, 0.016), "head", True, True),
])
for s, sd in ((1, "L"), (-1, "R")):
    ua, fa, hd = "upper_arm.%s" % sd, "forearm.%s" % sd, "hand.%s" % sd
    sh, el = r.bones[ua][0], r.bones[ua][1]
    wr = r.bones[fa][1]
    c.chain([sh, el, wr], [0.05, 0.04, 0.034], bones=limb_weights([ua, fa]), tag="arm", t0=0.0, t1=2.0)
    c.ellipsoid(wr + V(-0.01 * s, -0.005, 0.03), (0.032, 0.028, 0.045), bones={hd: 1.0}, tag="paw")
    th, sn, ft, tb = "thigh.%s" % sd, "shin.%s" % sd, "foot.%s" % sd, "toe.%s" % sd
    hip, kn = r.bones[th][0], r.bones[th][1]
    an, ball = r.bones[ft][0], r.bones[ft][1]
    toe = r.bones[tb][1]
    # the round powerful haunch and the long flat foot
    c.ellipsoid(hip.lerp(kn, 0.5) + V(0.03 * s, 0.02, -0.02), (0.1, 0.13, 0.15), rot=(-0.4, 0, 0), bones={th: 0.8, "hips": 0.2}, tag="leg")
    c.chain([hip, kn, an], [0.08, 0.06, 0.035], bones=limb_weights([th, sn]), tag="leg", t0=0.0, t1=2.0)
    c.chain([an, ball, toe], [0.04, 0.04, 0.032], bones=limb_weights([ft, tb]), tag="foot", t0=0.0, t1=2.0)
c.ball(V(0, 0.42, -0.24), 0.065, bones={"tail": 1.0}, tag="tail")


def col(p, info):
    g = fbm3((p.x * 10.0, p.y * 10.0, p.z * 10.0), 2, 5)
    v = 0.94 + 0.05 * (g - 0.5)
    if info.tag in ("chestfur", "cheek", "tail"):
        v = 0.99
    if info.tag == "muzzle":
        q = hf.M.transposed() @ (p - HC)
        v = 0.98 - 0.25 * smooth(0.006, 0.0, abs(q.x)) * smooth(-0.03, -0.06, q.y)
    return (v, v, v)


def fluff(p, info):
    """Soft fur: the chest, cheeks and tail fluffed into small clumps."""
    if info.tag not in ("chestfur", "cheek", "tail", "body"):
        return None
    nn = info.n
    w = fbm3((p.x * 12.0, p.y * 12.0, p.z * 12.0), 2, 9)
    u = -p.y * 18.0 + 0.5 * math.sin(math.atan2(nn.x, nn.z) * 8.0) + 1.2 * w
    k = u - math.floor(u)
    amp = 0.012 if info.tag != "body" else 0.005
    return nn * (amp * k ** 1.6)


c.build(b, col, cls=CLOTH, tint_fn=lambda p, info: 1.0, post=fluff)

# ---------------------------------------------------------------- face: eyes, nose, whisker spots, teeth
for s in (1, -1):
    A.animal_eye(b, hp(0.066 * s, 0.022, 0.05), hf.r * s + hf.f * 0.25, 0.024, "a01828", "head", pupil="round", almond=0.95, side=s, lid="3a2828")
A.nose_pad(b, hp(0, -0.012, 0.128), hf.f + hf.u * 0.3, 0.026, 0.018, "e88a98", "head", kind="cat")
b.ellipsoid(hp(0, -0.062, 0.112), (0.012, 0.012, 0.004), "fffaf0", cls=STONE, bone="head", rot=A.euler_of(hf.M), seg=8, rings=4, mat=MAT_PLAIN)
for s in (1, -1):
    for k in range(3):
        b.ball(hp(0.024 * s + 0.006 * k * s, -0.038 - 0.006 * k, 0.122 - 0.005 * k), 0.0028, "c8b8b8", cls=SKIN, bone="head", seg=5, rings=3, mat=MAT_PLAIN)

# ---------------------------------------------------------------- the long ears on two-bone chains
for sd, s in (("L", 1), ("R", -1)):
    e0, e1, e2 = EARS[sd]
    d = (e2 - e0).normalized()
    fwd = (hf.f * 0.9 + hf.r * 0.35 * s).normalized()
    # lofted as one long cupped leaf: white backs, pink insides, a darker tip
    rows = []
    for j in range(9):
        t = j / 8
        cpt = e0.lerp(e1, min(1.0, t * 2)) if t < 0.5 else e1.lerp(e2, (t - 0.5) * 2)
        w = 0.05 * math.sin(math.pi * min(1.0, 0.12 + t * 0.95)) ** 0.7 * (1.0 - 0.25 * t) + 0.004
        rows.append((cpt, w))
    for j in range(len(rows) - 1):
        pass
    rings = []
    rcols = []
    bones = []
    for j, (cpt, w) in enumerate(rows):
        t = j / 8
        side = d.cross(fwd).normalized()

        def prof(a, w=w):
            cs, sn = math.cos(a), math.sin(a)
            rr = 1.0 / math.sqrt((cs / (w * 0.32)) ** 2 + (sn / w) ** 2)
            return rr

        from sculpt import section
        rings.append(section(cpt, d, prof, 14, up=fwd))
        bones.append({"ear0.%s" % sd: 1.0 - smooth(0.35, 0.65, t), "ear1.%s" % sd: smooth(0.35, 0.65, t)})
    from sculpt import loft
    ear_v = loft(b, rings, (0.95, 0.95, 0.95), cls=CLOTH, bones=bones, tint=1.0, cap0=True, cap1=True, cap_push=0.3)
    # the pink inside of the ear, inset on the front face
    for v in ear_v:
        p = kit.b2g(v.co)
        rel = p - e0
        along = max(0.0, min(1.0, rel.dot(d) / (e2 - e0).length))
        off = rel - d * rel.dot(d)
        inner = smooth(0.0, 0.012, off.dot(fwd)) * (1.0 - smooth(0.022, 0.034, abs(off.dot(d.cross(fwd).normalized())))) * smooth(0.05, 0.15, along) * (1.0 - smooth(0.85, 0.95, along))
        tipdark = smooth(0.82, 0.95, along)
        cc = mix(mix((0.95, 0.95, 0.95), (0.5, 0.5, 0.52), tipdark), (0.95, 0.62, 0.68), inner)
        lc = kit.lin(cc, kit.CLOTH)
        v[b.cl] = (lc[0], lc[1], lc[2], v[b.cl][3])
        v[b.tl] = 1.0 - inner
# cheek ruffs and a chest bib of soft locks
for s in (1, -1):
    for k in range(2):
        A.lock(b, hp(0.075 * s, -0.04 - 0.02 * k, 0.0), (-hf.f * 0.6 + hf.r * 0.6 * s - hf.u * 0.4).normalized(), hf.r * s, 0.06, 0.03, (0.98,) * 3, (1.0,) * 3,
               bone="head", lift=0.3, rise=0.2, cls=HAIR)

# ---------------------------------------------------------------- the jade mortar and the pestle
JADE = "8ad0a8"
mort = V(0.02, 0.72, 0.2)
b.lathe(mort, [(0.07, -0.07), (0.1, -0.05), (0.11, 0.02), (0.1, 0.06), (0.085, 0.07), (0.07, 0.03), (0.0001, 0.0)], JADE, cls=STONE, seg=20,
        bone="forearm.L", col_top="c8f0d8", cap_bottom=True, cap_top=False)
b.lathe(mort + V(0, 0.055, 0), [(0.07, 0.0), (0.075, 0.008)], "3a5a48", cls=STONE, seg=20, bone="forearm.L", cap_bottom=False, cap_top=True, mat=MAT_PLAIN)
b.ball(mort + V(0, 0.07, 0), 0.03, "f8fff0", cls=CRYSTAL, bone="forearm.L", seg=10, rings=6, mat=MAT_GLOW)
for k in range(4):
    a = k / 4 * 2 * math.pi
    b.tube([mort + V(math.cos(a) * 0.105, -0.02, math.sin(a) * 0.105), mort + V(math.cos(a + 0.4) * 0.11, 0.04, math.sin(a + 0.4) * 0.11)], [0.006, 0.006], "e0c060",
           cls=STONE, bone="forearm.L", seg=4, mat=MAT_PLAIN)
hand_r = r.bones["hand.R"][0]
pestle = [hand_r + V(0.0, 0.16, 0.0), hand_r + V(0.0, 0.0, 0.01), hand_r + V(0.0, -0.18, 0.02)]
b.tube(pestle, [0.018, 0.016, 0.026], "c8a878", cls=WOOD, bone="hand.R", seg=10, cols=["b89868", "c8a878", JADE])
b.ball(pestle[2] + V(0, -0.012, 0), 0.03, JADE, cls=STONE, bone="hand.R", seg=10, rings=6)

# ---------------------------------------------------------------- motion
poser = Poser(r)
LEGS = [("L", 1), ("R", -1)]


def plant(p, dy=0.0, dz=0.0, meta=0.0):
    D = poser.fk(p)
    for sd, s in LEGS:
        ball = r.bones["foot.%s" % sd][1]
        res = leg_ik(r, D, ["thigh.%s" % sd, "shin.%s" % sd, "foot.%s" % sd, "toe.%s" % sd], "hips", ball + V(0, dy, dz), meta, 0.0)
        for nm, val in res.items():
            p[nm] = val
    return p


def hold(p, pound=0.0):
    """Arms: the left cradles the mortar, the right raises and drops the pestle."""
    add(p, "upper_arm.L", (-0.1, 0.0, 0.0))
    add(p, "upper_arm.R", (-0.25 - 0.7 * pound, 0.0, -0.05))
    add(p, "forearm.R", (-0.2 - 0.6 * pound, 0.0, 0.0))
    add(p, "hand.R", (0.2 + 0.5 * pound, 0.0, 0.0))


def ears(p, t, T, amp, lag=0.6, back=0.0):
    w = 2 * math.pi / T
    for sd, s in LEGS:
        add(p, "ear0.%s" % sd, (back + amp * math.sin(w * t), 0.0, s * 0.08 * math.sin(w * t + 0.6)))
        add(p, "ear1.%s" % sd, (back * 0.6 + amp * 1.4 * math.sin(w * t - lag), 0.0, 0.0))


T_IDLE = 2.4
T_WALK = 0.8


def idle(t):
    k = (t / (T_IDLE / 2)) % 1.0
    pound = smooth(0.05, 0.45, k) * (1.0 - smooth(0.55, 0.65, k))
    p = zero_pose(r)
    impact = math.exp(-((k - 0.66) / 0.05) ** 2)
    add(p, "hips", (0.0, 0.0, 0.0), (0.0, -0.01 * impact, 0.0))
    add(p, "spine", (0.04 * pound - 0.03 * impact, 0.0, 0.0))
    add(p, "chest", (-0.05 * pound + 0.06 * impact, -0.05 * pound, 0.0))
    add(p, "head", (0.05 * impact + 0.03 * math.sin(2 * math.pi * t / T_IDLE), 0.12 * math.sin(2 * math.pi * t / T_IDLE), 0.0))
    hold(p, pound)
    ears(p, t, T_IDLE / 2, 0.05)
    add(p, "tail", (0.0, 0.2 * math.sin(2 * math.pi * t / T_IDLE * 3), 0.0))
    return plant(p)


def walk(t):
    """Hops: crouch, push off with both hind feet together, fly, land and absorb."""
    k = (t / T_WALK) % 1.0
    air = smooth(0.2, 0.32, k) * (1.0 - smooth(0.7, 0.82, k))
    # the crouch peaks between landing (k = 0.82) and push-off (k = 0.2), wrapping round k = 0
    dk = (k - 0.01 + 0.5) % 1.0 - 0.5
    crouch = math.exp(-(dk / 0.1) ** 2)
    hop = 0.18 * math.sin(math.pi * smooth(0.2, 0.82, k))
    p = zero_pose(r)
    add(p, "root", (0.0, 0.0, 0.0), (0.0, hop - 0.05 * crouch, 0.0))
    add(p, "hips", (0.25 * air + 0.1 * crouch, 0.0, 0.0))
    add(p, "chest", (0.05 * crouch, 0.0, 0.0))
    add(p, "neck", (-0.15 * air, 0.0, 0.0))
    hold(p, 0.1)
    ears(p, t, T_WALK, 0.15, back=0.35 * air)
    # the feet stay on the ground, then tuck under and swing forward in the air
    D = poser.fk(p)
    for sd, s in LEGS:
        ball = r.bones["foot.%s" % sd][1]
        # planted from landing to push-off the feet slide back under the body; in the air they
        # swing forward again, so the cycle closes without a jump
        ks = (k - 0.82) % 1.0
        if ks < 0.38:
            dz = 0.1 * (1.0 - 2.0 * ks / 0.38)
        else:
            dz = 0.1 * (2.0 * smooth(0.38, 1.0, ks) - 1.0)
        res = leg_ik(r, D, ["thigh.%s" % sd, "shin.%s" % sd, "foot.%s" % sd, "toe.%s" % sd], "hips", ball + V(0, 0.05 * air, dz), 0.4 * air, 0.3 * air)
        for nm, val in res.items():
            p[nm] = val
    return p


def attack(t):
    k = t / 0.55
    up = smooth(0.0, 0.35, k) * (1.0 - smooth(0.38, 0.5, k))
    smash = smooth(0.38, 0.5, k) * (1.0 - smooth(0.7, 1.0, k))
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.05 * up, 0.12 * smash))
    add(p, "spine", (-0.25 * up + 0.35 * smash, 0, 0))
    add(p, "chest", (-0.15 * up + 0.2 * smash, 0, 0))
    add(p, "upper_arm.R", (-2.4 * up - 0.6 * smash, 0, -0.2 * up))
    add(p, "forearm.R", (-0.6 * up, 0, 0))
    add(p, "upper_arm.L", (-0.1, 0, 0))
    ears(p, t, 0.55, 0.2, back=0.5 * smash)
    return plant(p)


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0, -0.1 * e))
    add(p, "spine", (-0.25 * e, 0, 0.1 * e))
    add(p, "head", (-0.3 * e, 0.3 * e, 0))
    hold(p, 0.0)
    ears(p, t, 0.55, 0.1, back=0.9 * e)
    return plant(p)


def die(t):
    """The legs give; the hare topples onto its side and lies still, ears limp."""
    k = min(1.0, t / 1.2)
    buckle = smooth(0.0, 0.35, k)
    fall = smooth(0.25, 0.75, k)
    p = zero_pose(r)
    q = -0.12
    a = 1.45 * fall
    add(p, "root", (0.0, 0.0, a), (q - math.cos(a) * q, -math.sin(a) * q - 0.12 * buckle * (1.0 - fall), 0.0))
    add(p, "spine", (0.3 * buckle, 0, 0))
    add(p, "neck", (0.3 * buckle, -0.2 * fall, 0))
    add(p, "head", (0.2 * buckle, 0, 0.3 * fall))
    for sd, s in LEGS:
        add(p, "thigh.%s" % sd, (-0.8 * buckle, 0, 0))
        add(p, "shin.%s" % sd, (1.0 * buckle, 0, 0))
        add(p, "ear0.%s" % sd, (0.9 * fall, 0, 0.3 * s * fall))
        add(p, "ear1.%s" % sd, (0.4 * fall, 0, 0))
        add(p, "upper_arm.%s" % sd, (0.3 * fall, 0, -0.4 * s * fall))
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    add(p, "spine", (-0.15 * e, 0, 0))
    add(p, "head", (-0.35 * e, 0, 0))
    add(p, "upper_arm.L", (-1.6 * e, 0, -0.3 * e))
    add(p, "forearm.L", (-0.5 * e, 0, 0))
    hold(p, 0.0)
    ears(p, t, 0.6, 0.1, back=-0.2 * e)
    return plant(p)


print("[art] jade_rabbit: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/jade_rabbit.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die),
                                                     "cast": (0.6, cast)}, samples=14, dist=0.25, strength=0.4, floor_y=0.0)
