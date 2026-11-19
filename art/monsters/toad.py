"""Toad (new in the Turned Face release): the Three-Legged Toad of the money-changers (the jin chan), and
what greed leaves lying about in Part XLIV: the toad that sits on the strings of cash, the purse that
swallowed its owner, and the toad that croaks a name.

After toad anatomy (Bufo gargarizans, the Asiatic toad, the one the jin chan is drawn from):

* **Silhouette.**  Squat and broad, wider than it is tall, the body a flattened pear that sits low on
  the ground with its rump the highest point; the head is a wide, flat wedge as broad as the body, with
  no neck at all, and the two eye turrets stand up from it like the knobs on a lid.  Three legs, as the
  money toad has them: two short, thick forelegs splayed out to the sides with the hands turned in, and
  a single hind leg folded under the rump, its long foot laid flat behind.  A string of square-holed
  cash is draped over its back on a red cord, and a coin is held in the corner of its mouth: those are
  what leave the outline.
* **Head.**  A mouth as wide as the head, the lip line running back under the eyes to the tympanum (the
  round drum of the ear behind each eye); the great parotoid glands lie behind the eyes like two loaves;
  the eyes are big, gold, with the horizontal bar pupil of a toad, set high on the turrets.
* **Value.**  The back dark and warty, the warts raised and paler at their tips, a darker band along the
  flanks; the throat and belly pale and smooth; the hands and the foot pale underneath.  The skin takes
  the enemy's colour (taken down to a hide by `Assets.natural`); the eyes take the accent; the cash and
  the coin keep their own bronze and gold, and the cord its red.

Clips: idle (the throat pumps, the body breathes, the head turns), walk (a hop: the hind leg drives,
the forelegs reach and take the landing), attack (the tongue: the jaw drops and the tongue lashes out
its whole length and back), hurt, die (rolls onto its back on the ground, the legs curling), cast (puffs
itself up to twice its size, as a toad does when it is threatened, and the coin in its mouth flares).
Run: blender --background --python art/monsters/toad.py  ->  assets/monsters/toad.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from creature import Poser, add, flip_die, leg_ik, smooth, zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, MAT_PLAIN, METAL, SKIN, V, Builder, Rig  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
BY = 0.34                                  # the body's resting height (the middle of the back)
# (bone scales are in the bone's own axes: x across, y along the bone, z up for a level bone)
HC = V(0, 0.4, 0.3)                        # the middle of the head
hf = A.HeadFrame(HC, V(0, -0.08, 1.0))

# ---------------------------------------------------------------- rig
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, BY, -0.32), (0, BY + 0.05, 0.12), "root")
r.bone("head", (0, BY + 0.05, 0.12), HC + V(0, 0.02, 0.2), "body")
r.bone("jaw", HC + V(0, -0.07, -0.14), HC + V(0, -0.1, 0.2), "head")
r.bone("throat", HC + V(0, -0.1, -0.12), HC + V(0, -0.16, 0.08), "head")
r.bone("tongue0", HC + V(0, -0.06, -0.02), HC + V(0, -0.06, 0.1), "jaw")
r.bone("tongue1", HC + V(0, -0.06, 0.1), HC + V(0, -0.06, 0.2), "tongue0")
r.bone("cash", (0, BY + 0.2, -0.25), (0, BY + 0.24, 0.0), "body")
ARMS = {}
for s, sd in ((1, "L"), (-1, "R")):
    sh = V(0.17 * s, BY - 0.02, 0.2)
    el = V(0.31 * s, BY - 0.14, 0.24)
    wr = V(0.3 * s, 0.05, 0.33)
    hd = V(0.26 * s, 0.015, 0.42)
    ARMS[sd] = (sh, el, wr, hd)
    r.bone("upper_arm.%s" % sd, sh, el, "body")
    r.bone("forearm.%s" % sd, el, wr, "upper_arm.%s" % sd)
    r.bone("hand.%s" % sd, wr, hd, "forearm.%s" % sd)
# the one hind leg: the thigh out and forward under the rump, the shin folded back along it, the long
# foot flat on the ground behind
HIP = V(0, BY - 0.04, -0.3)
KNEE = V(0.0, 0.16, -0.08)
ANKLE = V(0.0, 0.06, -0.4)
BALL = V(0.0, 0.02, -0.56)
TOE = V(0.0, 0.015, -0.7)
r.bone("thigh", HIP, KNEE, "body")
r.bone("shin", KNEE, ANKLE, "thigh")
r.bone("foot", ANKLE, BALL, "shin")
r.bone("toe", BALL, TOE, "foot")
b = Builder("toad")


def hp(x, y, z):
    return hf.at(x, y, z)


# ---------------------------------------------------------------- body clay
c = Clay(0.013, "toad_body")
# the body: a flattened pear, broadest behind the forelegs, the rump the highest point
c.ellipsoid(V(0, BY, -0.12), (0.33, 0.22, 0.34), bones={"body": 1.0}, tag="back")
c.ellipsoid(V(0, BY + 0.03, -0.3), (0.27, 0.2, 0.2), bones={"body": 0.8, "thigh": 0.2}, tag="back")
c.ellipsoid(V(0, BY - 0.1, -0.05), (0.3, 0.13, 0.3), bones={"body": 1.0}, tag="belly")
# the head: a wide flat wedge as broad as the body, no neck; the snout blunt and rounded
A.head_clay(c, hf, 1.0, [
    ("ell", (0, 0.0, -0.02), (0.27, 0.11, 0.17), "head", False, False),
    ("ell", (0, -0.015, 0.1), (0.2, 0.08, 0.1), "head", False, False),
    ("ell", (0, -0.04, 0.16), (0.12, 0.05, 0.06), "snout", False, False),
    # the eye turrets, standing up from the lid of the head
    ("ell", (0.13, 0.08, 0.02), (0.07, 0.07, 0.075), "turret", True, False),
    # the parotoid glands: two loaves behind the eyes
    ("ell", (0.15, 0.06, -0.14), (0.065, 0.045, 0.1), "gland", True, False),
    # the tympanum: a shallow drum behind the corner of the mouth
    ("ball", (0.235, -0.01, -0.07), 0.032, "head", True, True),
])
# the throat and the lower jaw
c.ellipsoid(hp(0, -0.075, 0.02), (0.2, 0.06, 0.15), bones={"jaw": 0.6, "throat": 0.4}, tag="throat")
c.ellipsoid(hp(0, -0.1, -0.05), (0.15, 0.055, 0.12), bones={"throat": 1.0}, tag="throat")
for s, sd in ((1, "L"), (-1, "R")):
    sh, el, wr, hd = ARMS[sd]
    c.chain([sh, el, wr], [0.075, 0.055, 0.04], bones=limb_weights(["upper_arm.%s" % sd, "forearm.%s" % sd]), tag="arm", t0=0.0, t1=2.0)
    c.ellipsoid(wr.lerp(hd, 0.5), (0.05, 0.022, 0.06), bones={"hand.%s" % sd: 1.0}, tag="hand")
c.chain([HIP, KNEE], [0.1, 0.07], bones=limb_weights(["thigh"]), tag="leg", t0=0.0, t1=1.0)
c.chain([KNEE, ANKLE], [0.07, 0.045], bones=limb_weights(["shin"]), tag="leg", t0=0.0, t1=1.0)
c.chain([ANKLE, BALL, TOE], [0.045, 0.04, 0.03], bones=limb_weights(["foot", "toe"]), tag="foot", t0=0.0, t1=2.0)


def wart(p):
    """0..1: how far a point of the skin is up a wart (a cellular field: a bump on a jittered grid)."""
    q = V(p.x * 11.0, p.y * 11.0, p.z * 11.0)
    best = 9.0
    ix, iy, iz = math.floor(q.x), math.floor(q.y), math.floor(q.z)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                gx, gy, gz = ix + dx, iy + dy, iz + dz
                h = math.sin(gx * 127.1 + gy * 311.7 + gz * 74.7) * 43758.5453
                jx = h - math.floor(h)
                h2 = math.sin(gx * 269.5 + gy * 183.3 + gz * 246.1) * 43758.5453
                jy = h2 - math.floor(h2)
                h3 = math.sin(gx * 113.5 + gy * 271.9 + gz * 124.6) * 43758.5453
                jz = h3 - math.floor(h3)
                d = (q.x - gx - jx) ** 2 + (q.y - gy - jy) ** 2 + (q.z - gz - jz) ** 2
                best = min(best, d)
    return smooth(0.32, 0.0, best)


def back_of(info):
    """How much a vertex is on the upper (warty) side: the back, the head's lid, the outsides of the legs."""
    if info.tag == "hand":
        return 0.0
    return smooth(-0.6, -0.12, info.n.y)


def col(p, info):
    g = fbm3((p.x * 7.0, p.y * 7.0, p.z * 7.0), 3, 11)
    up = back_of(info)
    w = wart(p) * up
    # the back mottled dark, a darker band along each flank, the warts paler at their tips; the belly,
    # the throat and the palms pale and smooth
    v = 0.8 + 0.1 * (g - 0.5) - 0.05 * smooth(0.2, 0.0, abs(info.n.y - 0.1)) * smooth(0.2, 0.6, abs(info.n.x))
    v = v * up + 0.95 * (1.0 - up)
    v = min(1.0, v + 0.12 * w)
    if info.tag == "gland":
        v = 0.86 + 0.06 * (g - 0.5)
    if info.tag == "snout":
        v -= 0.06
    return (v, v, v)


def bumps(p, info):
    """The warts are raised from the skin, and the glands are pitted."""
    up = back_of(info)
    if up <= 0.0:
        return None
    amp = 0.016 if info.tag in ("back", "leg", "arm") else 0.009
    if info.tag == "gland":
        return info.n * (-0.006 * wart(p * 1.7))
    return info.n * (amp * wart(p) * up)


c.build(b, col, cls=SKIN, tint_fn=lambda p, info: 1.0, post=bumps)

# ---------------------------------------------------------------- face: gold bar-pupilled eyes, the lip line, nostrils
hit = A.surface(b)
for s in (1, -1):
    d = (hf.r * s * 0.75 + hf.f * 0.45 + hf.u * 0.5).normalized()
    base = hp(0.13 * s, 0.1, 0.05)
    h = hit(base + d * 0.3, -d, 0.6)
    ep = h[0] - d * 0.008 if h is not None else base
    A.animal_eye(b, ep, d, 0.042, "d8a830", "head", pupil="bar", almond=0.86, side=s, lid="2a2418", lid_w=0.16)
    # nostrils on the tip of the snout
    b.ellipsoid(hp(0.035 * s, -0.012, 0.215), (0.009, 0.006, 0.006), "141008", cls=SKIN, bone="head", seg=6, rings=4, mat=MAT_PLAIN)
# the lip line: from the tip of the snout back under the eye to the corner of the mouth, either side
lip = []
for k in range(15):
    t = k / 14
    a = (t - 0.5) * math.pi * 0.92
    lip.append(hp(0.235 * math.sin(a) * (1.0 - 0.1 * t), -0.045 - 0.012 * abs(math.sin(a)), 0.2 * math.cos(a) - 0.02))
b.tube(lip, [0.006] * len(lip), "1c1610", cls=SKIN, bone="head", seg=5, mat=MAT_PLAIN)

# ---------------------------------------------------------------- the tongue: a pink strap folded back in the mouth
tg = [hp(0, -0.06, -0.02), hp(0, -0.062, 0.04), hp(0, -0.062, 0.1), hp(0, -0.06, 0.17)]
b.tube(tg, [0.022, 0.026, 0.026, 0.03], "d86a78", cls=SKIN, bones=[{"tongue0": 1.0}, {"tongue0": 0.6, "tongue1": 0.4}, {"tongue1": 1.0}, {"tongue1": 1.0}],
       seg=8, mat=MAT_PLAIN)
b.ball(tg[-1] + V(0, 0.0, 0.015), 0.034, "e87888", cls=SKIN, bone="tongue1", seg=10, rings=6, mat=MAT_PLAIN)

# ---------------------------------------------------------------- the coin in the corner of the mouth, and the cash on the back
GOLD = "e8c050"
BRONZE = "8a6a34"


def coin(cen, rot, rad, colr, bone, glow=False):
    """A cash coin: a round disc with a square hole and a raised rim, standing on edge in `rot`."""
    b.disc(cen, rad, colr, cls=METAL, bone=bone, seg=20, rot=rot, mat=MAT_GLOW if glow else MAT_PLAIN, col_rim=kit.lighten(colr, 0.25), thick=rad * 0.12)
    b.box(cen, (rad * 0.42, rad * 0.42, rad * 0.16), "1a120a", rot=rot, cls=METAL, bone=bone, mat=MAT_PLAIN)


b.cur_pal = 1.0
mouth_coin = hp(0.16, -0.045, 0.1)
coin(mouth_coin, (0.0, 1.1, 0.0), 0.075, "f8f0d8", "jaw", glow=True)
b.cur_pal = 0.0
# a red cord over the back from flank to flank, strung with a dozen coins that hang down the sides
cord = []
for k in range(17):
    t = k / 16
    a = (t - 0.5) * math.pi * 1.25
    cord.append(V(0.36 * math.sin(a), BY + 0.04 + 0.2 * math.cos(a), -0.13 + 0.03 * math.sin(a * 2.0)))
b.tube(cord, [0.012] * len(cord), "a82a24", cls=CLOTH, bone="cash", seg=6, mat=MAT_PLAIN)
for k in range(1, 16, 1):
    p = cord[k]
    nrm = (p - V(0, BY - 0.04, -0.13)).normalized()
    tang = (cord[min(16, k + 1)] - cord[max(0, k - 1)]).normalized()
    # each coin threaded on the cord, lying flat along the curve of the back
    yaw = math.atan2(tang.x, tang.z)
    tilt = math.atan2(nrm.x, nrm.y)
    coin(p + nrm * 0.01, (0.0, yaw, -tilt), 0.045, GOLD if k % 3 else BRONZE, "cash")
# a knot and a tassel at the end that hangs on the left
b.ball(cord[0] + V(0.005, -0.01, 0), 0.02, "a82a24", cls=CLOTH, bone="cash", seg=8, rings=5, mat=MAT_PLAIN)
for q in range(5):
    a = q / 5 * 2 * math.pi
    b.tube([cord[0] + V(0.0, -0.02, 0), cord[0] + V(0.01 + 0.012 * math.cos(a), -0.1, 0.012 * math.sin(a))], [0.004, 0.003], "c83a30", cls=CLOTH, bone="cash",
           seg=4, mat=MAT_PLAIN)

# ---------------------------------------------------------------- fingers and toes: pale-tipped, the hands turned in
for s, sd in ((1, "L"), (-1, "R")):
    sh, el, wr, hd = ARMS[sd]
    for q in range(4):
        a = (-0.9 + 0.55 * q) * s
        dd = V(math.sin(a) * 0.5 + (hd - wr).normalized().x * 0.5, 0.0, math.cos(a) * 0.5 + (hd - wr).normalized().z * 0.5).normalized()
        f0 = hd - (hd - wr) * 0.2 + V(0, 0.005, 0)
        b.tube([f0, f0 + dd * 0.045, f0 + dd * 0.07 + V(0, -0.006, 0)], [0.014, 0.011, 0.009], "e0d8c0", cls=SKIN, bone="hand.%s" % sd, seg=6,
               cols=["b8b098", "d8d0b8", "f0e8d0"], mat=MAT_PLAIN, tint=0.4)
for q in range(5):
    a = (-0.5 + 0.25 * q)
    dd = V(math.sin(a), 0.0, -math.cos(a))
    f0 = BALL + V(0, 0.004, 0)
    ln = 0.07 + 0.04 * (1.0 - abs(q - 2) / 2.0)
    b.tube([f0, f0 + dd * ln * 0.6, f0 + dd * ln + V(0, -0.004, 0)], [0.012, 0.01, 0.008], "e0d8c0", cls=SKIN, bone="toe", seg=6,
           cols=["b8b098", "d8d0b8", "f0e8d0"], mat=MAT_PLAIN, tint=0.4)

# ---------------------------------------------------------------- motion
poser = Poser(r)
SIDES = (("L", 1), ("R", -1))


def plant(p, dy=0.0, dz=0.0):
    """The foot stays where it stood on the ground whatever the body does."""
    D = poser.fk(p)
    res = leg_ik(r, D, ["thigh", "shin", "foot", "toe"], "body", BALL + V(0, dy, dz), 0.0, 0.0)
    for nm, val in res.items():
        p[nm] = val
    return p


def gulp(p, t, T, amp=1.0):
    """The throat pumps in and out: a toad breathes with its mouth shut."""
    k = 0.5 + 0.5 * math.sin(2 * math.pi * t / T * 3)
    add(p, "throat", (0, 0, 0), (0, -0.02 * k * amp, 0), (1.0 + 0.25 * k * amp, 1.0 + 0.15 * k * amp, 1.0 + 0.6 * k * amp))


T_IDLE = 2.4
T_WALK = 0.9


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    add(p, "body", (0.02 * math.sin(w * t), 0, 0), (0, 0.006 * math.sin(w * t), 0), (1.0 + 0.02 * math.sin(w * t), 1.0, 1.0 + 0.03 * math.sin(w * t)))
    add(p, "head", (-0.03 * math.sin(w * t), 0.12 * math.sin(w * t * 0.5), 0))
    gulp(p, t, T_IDLE)
    for sd, s in SIDES:
        add(p, "upper_arm.%s" % sd, (0, 0, 0.02 * s * math.sin(w * t)))
    add(p, "cash", (0.03 * math.sin(w * t), 0, 0.02 * math.sin(w * t * 2)))
    return plant(p)


def walk(t):
    """A hop: crouch, the hind leg drives, the body is thrown up and forward with the forelegs reaching,
    the hands take the landing and the foot comes up under the rump again."""
    k = (t / T_WALK) % 1.0
    air = math.sin(math.pi * smooth(0.18, 0.72, k))
    crouch = math.exp(-((k - 0.08) / 0.08) ** 2) + math.exp(-((k - 0.85) / 0.1) ** 2) * 0.7
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.17 * air - 0.03 * crouch, 0.05 * air))
    add(p, "body", (-0.3 * air + 0.12 * crouch, 0, 0))
    add(p, "head", (0.18 * air, 0, 0))
    add(p, "cash", (0.15 * air - 0.08 * crouch, 0, 0))
    for sd, s in SIDES:
        add(p, "upper_arm.%s" % sd, (-0.7 * air, 0, -0.2 * s * air))
        add(p, "forearm.%s" % sd, (0.4 * air, 0, 0))
    # the leg straightens back while the body is in the air, then folds under it again
    add(p, "thigh", (0.9 * air, 0, 0))
    add(p, "shin", (-1.1 * air, 0, 0))
    add(p, "foot", (0.5 * air, 0, 0))
    return p if air > 0.1 else plant(p, 0.0, 0.0)


def attack(t):
    """The jaw drops and the tongue goes out its whole length at the prey, and back."""
    k = t / 0.55
    gape = smooth(0.05, 0.25, k) * (1.0 - smooth(0.65, 0.9, k))
    out = smooth(0.2, 0.38, k) * (1.0 - smooth(0.45, 0.72, k))
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.02 * out, 0.1 * out))
    add(p, "body", (-0.08 * gape, 0, 0))
    add(p, "head", (-0.22 * gape, 0, 0))
    add(p, "jaw", (0.55 * gape, 0, 0))
    add(p, "tongue0", (-0.5 * gape, 0, 0), (0, 0, 0.35 * out), (1.0, 1.0 + 3.0 * out, 1.0))
    add(p, "tongue1", (0.3 * out, 0, 0), (0, 0, 0.25 * out), (1.0 + 0.4 * out, 1.0 + 1.5 * out, 1.0 + 0.4 * out))
    for sd, s in SIDES:
        add(p, "upper_arm.%s" % sd, (-0.2 * out, 0, 0))
    return plant(p)


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.04 * e, -0.12 * e))
    add(p, "body", (0.2 * e, 0, 0.12 * e), (0, 0, 0), (1.0 - 0.1 * e, 1.0, 1.0 - 0.12 * e))
    add(p, "head", (0.25 * e, 0.2 * e, 0))
    add(p, "cash", (-0.3 * e, 0, 0.2 * e))
    for sd, s in SIDES:
        add(p, "upper_arm.%s" % sd, (0.3 * e, 0, 0.3 * s * e))
    return plant(p)


def die(t):
    """Rolls over onto its back and lies on the ground with its pale belly up, the legs curling."""
    p = zero_pose(r)
    curl = [("upper_arm.L", (-0.6, 0.0, -0.8)), ("upper_arm.R", (-0.6, 0.0, 0.8)), ("forearm.L", (0.0, 0.0, -0.6)), ("forearm.R", (0.0, 0.0, 0.6)),
            ("thigh", (1.2, 0.0, 0.0)), ("shin", (-0.6, 0.0, 0.0))]
    roll = flip_die(p, t, 1.2, BY, side=1, curl_legs=curl, rest=0.2)
    add(p, "head", (0.2 * roll, 0, 0))
    add(p, "jaw", (0.35 * roll, 0, 0))
    add(p, "tongue1", (0, 0, 0), (0, -0.01 * roll, 0.06 * roll))
    add(p, "cash", (0.4 * roll, 0, 0.6 * roll))
    return p


def cast(t):
    """Puffs itself up as a toad does when it is threatened, rears on its forelegs, and the coin flares."""
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    add(p, "body", (-0.18 * e, 0, 0), (0, 0.06 * e, 0), (1.0 + 0.32 * e, 1.0 + 0.22 * e, 1.0 + 0.45 * e))
    add(p, "head", (0.12 * e, 0, 0))
    add(p, "throat", (0, 0, 0), (0, -0.03 * e, 0), (1.0 + 0.4 * e, 1.0 + 0.3 * e, 1.0 + 1.1 * e))
    for sd, s in SIDES:
        add(p, "upper_arm.%s" % sd, (0.35 * e, 0, 0.15 * s * e))
    return plant(p)


print("[art] toad: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/toad.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die),
                                              "cast": (0.6, cast)}, samples=14, dist=0.25, strength=0.45, floor_y=0.0)
