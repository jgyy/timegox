"""Dragon: an eastern loong (Azure Dragon King, Frost Wyrm, Bone Wyrm, Ink Dragon, the Jiao of the
Nine Bends ...), after the "nine resemblances" (Wikipedia, Chinese dragon): the head of a camel,
the antlers of a deer, the eyes of a rabbit, the ears of a cow, the neck of a snake, the belly of
a clam, the scales of a carp, the claws of an eagle and the palms of a tiger.  The long body hangs
in an S through its three sections - head to shoulders, shoulders to hips, hips to the tail - and
undulates as it swims through the air.

Sculpted in clay along a spline (art/lib/clay.py): a long camel face with a heavy brow, an
upturned nose with flared nostrils, big bulging eyes, cow ears and branching antlers; a snake's
neck; carp scales painted in rows over the back and flanks and the pale clam-ridged plates of the
belly; four legs with tiger-padded palms and hooked eagle talons; a flowing mane along the neck,
dorsal spines down the back, flame tufts at the elbows and a flame-like tuft at the tail; two long
whiskers on their own bone chains, a beard, and the pearl in one claw.
Clips: idle (hovering undulation), walk (swimming through the air), attack (rears back and
lunges with open jaws), hurt, die (crashes to the ground), cast (rears and roars).
Run: blender --background --python art/monsters/dragon.py  ->  assets/monsters/dragon.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from creature import add, smooth, zero_pose  # noqa: E402
from kit import CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SCALE, SKIN, V, Builder, Rig, mix  # noqa: E402

kit.reset()
creature.realtime()
CTRL = [V(0, 1.78, 0.95), V(0.1, 1.62, 0.62), V(0.28, 1.38, 0.3), V(0.22, 1.18, -0.05), V(-0.12, 1.06, -0.36), V(-0.36, 1.12, -0.72),
        V(-0.28, 1.28, -1.08), V(0.06, 1.36, -1.36), V(0.34, 1.24, -1.66), V(0.3, 1.04, -1.96), V(0.04, 0.94, -2.2), V(-0.22, 1.0, -2.42)]
SP = A.Spline(CTRL, per=8)
U_CHEST, U_HIP = 0.2, 0.56
NS = 10


def rad(u):
    """Body radius along the arc: a snake's neck, the chest, a slimmer waist, the hips, a long tail."""
    r = 0.12 + 0.085 * math.exp(-((u - 0.23) / 0.1) ** 2) + 0.05 * math.exp(-((u - 0.55) / 0.08) ** 2)
    r *= 1.0 - 0.72 * smooth(0.55, 1.0, u)
    return max(0.03, r)


# ---------------------------------------------------------------- rig
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
pc, tc, uc, sc = SP.at(U_CHEST)
r.bone("chest", pc, pc + uc * 0.2, "root")
NECK_U = [U_CHEST, 0.13, 0.07, 0.02]
prev = "chest"
for i in range(3):
    r.bone("neck%d" % i, SP.at(NECK_U[i])[0], SP.at(NECK_U[i + 1])[0], prev)
    prev = "neck%d" % i
SEG_U = [U_CHEST + (1.0 - U_CHEST) * i / NS for i in range(NS + 1)]
prev = "chest"
for i in range(NS):
    r.bone("seg%d" % i, SP.at(SEG_U[i])[0], SP.at(SEG_U[i + 1])[0], prev)
    prev = "seg%d" % i
H0, T0, U0, S0 = SP.at(0.0)
HF = -T0                                  # the head looks forward, away from the body
HC = H0 + HF * 0.12 + U0 * 0.06
hf = A.HeadFrame(HC, (HF + V(0, -0.12, 0)).normalized())
r.bone("head", SP.at(0.02)[0], HC + hf.f * 0.4, "neck2")
r.bone("jaw", hf.at(0, -0.08, -0.06), hf.at(0, -0.12, 0.38), "head")
WHISK = {}
for s, sd in ((1, "L"), (-1, "R")):
    w0 = hf.at(0.07 * s, -0.02, 0.38)
    pts = [w0, w0 + hf.r * (0.12 * s) - hf.f * 0.06 + hf.u * 0.01, w0 + hf.r * (0.2 * s) - hf.f * 0.3 - hf.u * 0.04, w0 + hf.r * (0.2 * s) - hf.f * 0.58 - hf.u * 0.14]
    WHISK[sd] = pts
    prev = "head"
    for i in range(3):
        r.bone("wh%s%d" % (sd, i), pts[i], pts[i + 1], prev)
        prev = "wh%s%d" % (sd, i)
LEGS = []
for li, (u, par) in enumerate(((U_CHEST + 0.02, "chest"), (U_HIP + 0.02, "seg%d" % int((U_HIP + 0.02 - U_CHEST) / (1.0 - U_CHEST) * NS)))):
    p, t, up, side = SP.at(u)
    t = -t                                # forward, towards the head
    for s, sd in ((1, "L"), (-1, "R")):
        sv = side * s
        sh = p + sv * rad(u) * 0.75 - up * rad(u) * 0.35
        el = sh + sv * 0.14 - up * 0.13 - t * 0.08
        wr = el + sv * 0.03 - up * 0.17 + t * 0.06
        ft = wr - up * 0.04 + t * 0.11
        r.bone("leg%d.%s" % (li, sd), sh, el, par)
        r.bone("fore%d.%s" % (li, sd), el, wr, "leg%d.%s" % (li, sd))
        r.bone("foot%d.%s" % (li, sd), wr, ft, "fore%d.%s" % (li, sd))
        LEGS.append((li, sd, s, sh, el, wr, ft, up, t, sv))
SPINE = ["neck2", "neck1", "neck0"] + ["seg%d" % i for i in range(NS)]
SPINE_U = [0.02, 0.07, 0.13] + SEG_U


def spine_w(u):
    """Bone weights at arc position u: the head beyond the neck, then the neck and body bones,
    blended over a short zone at each joint."""
    if u < 0.025:
        k = smooth(0.0, 0.025, u)
        return {"head": 1.0 - 0.5 * k, "neck2": 0.5 * k}
    for i in range(len(SPINE)):
        a, c = SPINE_U[i], SPINE_U[i + 1] if i + 1 < len(SPINE_U) else 1.0
        if i < 3:
            a, c = NECK_U[3 - i], NECK_U[2 - i]
        if a <= u <= c or i == len(SPINE) - 1:
            z = 0.25 * (c - a)
            if u > c - z and i + 1 < len(SPINE):
                k = 0.5 * (u - (c - z)) / z
                return {SPINE[i]: 1.0 - k, SPINE[i + 1]: k}
            if u < a + z and i > 0:
                k = 0.5 + 0.5 * (u - a) / z
                return {SPINE[i - 1]: 1.0 - k, SPINE[i]: k}
            return {SPINE[i]: 1.0}
    return {SPINE[-1]: 1.0}


b = Builder("dragon")
# ---------------------------------------------------------------- body
c = Clay(0.018, "dragon_body")
us = [k / 60.0 for k in range(61)]
c.chain([SP.at(u)[0] for u in us], [rad(u) for u in us], bones=lambda p, t: spine_w(t), tag="body", t0=0.0, t1=1.0)
for li, sd, s, sh, el, wr, ft, up, t, sv in LEGS:
    lg, fo, fb = "leg%d.%s" % (li, sd), "fore%d.%s" % (li, sd), "foot%d.%s" % (li, sd)
    c.chain([sh - sv * 0.06, sh, el, wr], [0.09, 0.085, 0.065, 0.048], bones=limb_weights([lg, lg, fo]), tag="leg", t0=0.0, t1=3.0)
    c.ellipsoid(sh.lerp(el, 0.4), (0.085, 0.08, 0.11), rot=A.frame_m(el - sh), bones={lg: 1.0}, tag="leg")
    # the tiger's palm: a padded paw from which the eagle's talons spring
    c.ellipsoid(wr.lerp(ft, 0.5), (0.05, 0.035, 0.065), rot=A.frame_m(t), bones={fb: 1.0}, tag="paw")
# the camel's head: a long face, a heavy brow, an upturned nose with flared nostrils, cheeks
A.head_clay(c, hf, 1.0, [
    ("ell", (0, 0.03, -0.02), (0.15, 0.13, 0.16), "head", False, False),
    ("ell", (0.085, 0.09, 0.1), (0.06, 0.035, 0.09), "brow", True, False),
    ("ell", (0, 0.0, 0.2), (0.105, 0.085, 0.13), "head", False, False),
    ("ell", (0, 0.0, 0.33), (0.085, 0.07, 0.09), "head", False, False),
    ("ell", (0, 0.04, 0.4), (0.075, 0.06, 0.05), "nose", False, False),
    ("ball", (0.045, 0.06, 0.42), 0.035, "nose", True, False),
    ("ball", (0.048, 0.07, 0.445), 0.016, "nose", True, True),
    ("ell", (0.13, -0.03, 0.02), (0.06, 0.07, 0.09), "head", True, False),
    ("ell", (0.09, 0.07, 0.13), (0.045, 0.035, 0.035), "head", True, True),
])


def col(p, info):
    tag = info.tag
    n = info.n
    if tag in ("head", "brow", "nose"):
        q = hf.M.transposed() @ (p - HC)
        v = 0.8 + 0.12 * smooth(0.0, -0.08, q.y) - 0.1 * smooth(0.05, 0.12, q.y)
        if tag == "nose":
            v = 0.86
        return (v, v, v)
    if tag == "paw":
        return (0.95, 0.95, 0.95)
    if tag == "leg":
        return (0.78, 0.78, 0.78)
    u = info.t
    a, _ = SP.local(p, u)
    under = smooth(2.0, 2.6, abs(a))
    # carp scales: rows of round scales offset row to row, each darker at its rim
    s_len = u * SP.L / max(0.05, rad(u) * 0.75)
    sy = a * 2.4 + 0.5 * (math.floor(s_len) % 2)
    fx, fy = s_len - math.floor(s_len), sy - math.floor(sy)
    rim = smooth(0.28, 0.48, math.hypot(fx - 0.35, fy - 0.5))
    v = 0.84 - 0.12 * smooth(0.6, 0.0, abs(a)) - 0.2 * rim
    # the clam's belly: broad pale plates with dark seams between them
    plate = 0.97 - 0.3 * smooth(0.8, 0.95, 0.5 + 0.5 * math.cos(u * SP.L / 0.06 * math.pi))
    return (v * (1.0 - under) + plate * under,) * 3


def tint(p, info):
    if info.tag == "paw":
        return 0.5
    if info.tag != "body":
        return 1.0
    a, _ = SP.local(p, info.t)
    return 1.0 - 0.65 * smooth(2.0, 2.6, abs(a))


c.build(b, col, cls=SCALE, tint_fn=tint)

# ---------------------------------------------------------------- jaw and mouth
j = Clay(0.013, "dragon_jaw")
for s in (1, -1):
    j.chain([hf.at(0.1 * s, -0.08, 0.0), hf.at(0.07 * s, -0.1, 0.2), hf.at(0.03 * s, -0.1, 0.38)], [0.04, 0.035, 0.03], bones={"jaw": 1.0}, tag="jaw")
j.build(b, lambda p, info: mix((0.95, 0.95, 0.95), (0.45, 0.14, 0.18), smooth(0.2, 0.5, info.n.dot(hf.u))), cls=SCALE,
        tint_fn=lambda p, info: 0.5 * (1.0 - smooth(0.2, 0.5, info.n.dot(hf.u))))
b.ellipsoid(hf.at(0, -0.07, 0.2), (0.08, 0.02, 0.18), "3a1014", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
b.ellipsoid(hf.at(0, -0.085, 0.22), (0.05, 0.012, 0.14), "b03848", cls=SKIN, bone="jaw", rot=A.euler_of(hf.M), seg=10, rings=5, mat=MAT_PLAIN)
for k in range(5):
    z = 0.38 - k * 0.06
    for s in (1, -1):
        x = (0.045 + k * 0.012) * s
        A.fang(b, hf.at(x, -0.065, z), -hf.u, 0.06 if k == 0 else 0.03, 0.01 if k == 0 else 0.007, "head", back=-hf.f, curve=0.25)
        A.fang(b, hf.at(x * 0.92, -0.095, z - 0.02), hf.u, 0.04 if k == 0 else 0.024, 0.009 if k == 0 else 0.006, "jaw", back=-hf.f, curve=0.2)
# rabbit's eyes: big, round and bulging, under a heavy brow
for s in (1, -1):
    A.animal_eye(b, hf.at(0.098 * s, 0.06, 0.13), hf.f * 0.5 + hf.r * (0.85 * s) + hf.u * 0.1, 0.042, "ffb020", "head", pupil="slit", almond=0.85, slant=0.1, side=s, glow=True)
# cow's ears behind the eyes
for s in (1, -1):
    A.ear(b, hf.at(0.13 * s, 0.07, -0.08), hf.r * s * 0.8 - hf.f * 0.6, 0.14, 0.07, 0.03, (0.75, 0.75, 0.75), (0.9, 0.85, 0.85), "head", up=hf.r * s - hf.u * 0.3 - hf.f * 0.5,
          point=0.6, cup=0.5, tint=1.0, tint_in=0.4, side=s)
b.cur_pal = 0.0
# a deer's antlers: a curved main beam swept back with three tines, horn-coloured
for s in (1, -1):
    a0 = hf.at(0.07 * s, 0.13, -0.04)
    beam = [a0, a0 + hf.u * 0.14 - hf.f * 0.06 + hf.r * 0.05 * s, a0 + hf.u * 0.26 - hf.f * 0.2 + hf.r * 0.1 * s, a0 + hf.u * 0.34 - hf.f * 0.38 + hf.r * 0.08 * s]
    A.horn(b, beam, 0.03, "a08860", "fff2d0", "head", r1=0.006, seg=10)
    for k, (tt, dv) in enumerate(((0.35, hf.u * 0.12 + hf.f * 0.06 + hf.r * 0.03 * s), (0.6, hf.u * 0.1 + hf.r * 0.08 * s), (0.85, hf.u * 0.12 - hf.f * 0.02))):
        i = min(2, int(tt * 3))
        q = beam[i].lerp(beam[i + 1], tt * 3 - i)
        A.horn(b, [q, q + dv * 0.5 + hf.u * 0.01, q + dv], 0.016, "c0a878", "fff2d0", "head", r1=0.004, seg=8)
b.ball(hf.at(0, 0.13, 0.17), 0.022, "60f0ff", cls=CRYSTAL, bone="head", seg=10, rings=6, mat=MAT_GLOW)

# ---------------------------------------------------------------- mane, beard, whiskers (secondary colour)
b.cur_pal = 0.5
hit = A.surface(b)
n_mane = 0
for i in range(18):
    u = 0.03 + 0.21 * i / 17
    p, t, up, side = SP.at(u)
    h = hit(p + up * 0.6, -up)
    if h is None:
        continue
    root, nrm = h
    n_mane += 1
    for sgn in (1, -1):
        groom = (t * 0.8 + side * (0.55 * sgn) - up * 0.2).normalized()
        shade = 0.72 + 0.12 * ((i + (sgn > 0)) % 2)
        A.lock(b, root, groom, nrm + side * (0.4 * sgn), 0.26 - 0.08 * (u / 0.24), 0.07, (shade,) * 3, (min(1.0, shade + 0.2),) * 3, bone=spine_w(u),
               lift=0.35, rise=0.3, thick=0.35, cls=HAIR, bend=0.3 * sgn, droop=0.2)
print("[art] dragon mane locks:", n_mane)
# flame brows and a beard
for s in (1, -1):
    for k in range(3):
        root = hf.at((0.06 + 0.03 * k) * s, 0.12 - 0.01 * k, 0.16 - 0.04 * k)
        A.lock(b, root, (hf.u * 0.6 - hf.f * 0.8 + hf.r * 0.3 * s).normalized(), hf.u, 0.12 - 0.02 * k, 0.03, (0.8,) * 3, (1.0,) * 3, bone="head", lift=0.4, rise=0.25, cls=HAIR)
for k in range(5):
    u2 = (k / 4 - 0.5) * 2
    A.lock(b, hf.at(0.05 * u2, -0.14, 0.25 - 0.04 * abs(u2)), -hf.u * 0.7 - hf.f * 0.5, -hf.f, 0.2, 0.04, (0.72,) * 3, (0.95,) * 3, bone="jaw", lift=0.25, rise=0.15, cls=HAIR)
# the long whiskers: tapered barbels on their own bone chains
for sd, pts in WHISK.items():
    cp = A.catmull(pts, 5)
    m = len(cp)
    bones = [{"wh%s%d" % (sd, min(2, int(i / (m - 1) * 2.999))): 1.0} for i in range(m)]
    b.tube(cp, [0.013 * (1.0 - 0.9 * i / (m - 1)) + 0.0015 for i in range(m)], (0.9, 0.9, 0.9), cls=HAIR, bones=bones, seg=7, tint=1.0,
           cols=[mix((0.85, 0.85, 0.85), (1.0, 1.0, 1.0), i / (m - 1)) for i in range(m)])
# the tail ends in a flame-like tuft (accent colour)
b.cur_pal = 1.0
p, t, up, side = SP.at(0.97)
for k in range(9):
    a = k / 9 * 2 * math.pi
    out = (up * math.cos(a) + side * math.sin(a)).normalized()
    A.lock(b, p, (t * 1.0 + out * 0.6).normalized(), out, 0.3, 0.06, (0.75,) * 3, (1.0,) * 3, bone="seg%d" % (NS - 1), lift=0.3, rise=0.2, cls=HAIR)
b.cur_pal = 0.0

# ---------------------------------------------------------------- dorsal spines, elbow flames, talons, pearl
for i in range(26):
    u = 0.25 + 0.68 * i / 25
    p, t, up, side = SP.at(u)
    h = hit(p + up * 0.6, -up)
    if h is None:
        continue
    root, nrm = h
    ln = 0.12 * (1.0 - 0.6 * (u - 0.25) / 0.7)
    # the dorsal spines carry the accent colour down the back (a focal line, not the body's hue)
    b.cur_pal = 1.0
    A.horn(b, [root - nrm * 0.01, root + nrm * ln * 0.6 + t * ln * 0.3, root + nrm * ln + t * ln * 0.75], ln * 0.22, (0.62, 0.62, 0.62), (0.95, 0.95, 0.95), spine_w(u),
           r1=0.002, cls=SCALE, seg=6, per=2, tint=1.0, flat=0.45, up=tuple(side))
    b.cur_pal = 0.0
for li, sd, s, sh, el, wr, ft, up, t, sv in LEGS:
    for k in range(3):
        b.cur_pal = 1.0  # elbow flames burn in the accent colour
        A.lock(b, el + up * 0.02 * k, (-t * 1.0 + up * 0.5 + sv * 0.3).normalized(), sv, 0.14 - 0.02 * k, 0.03, "d8d8d8", "ffffff", bone="fore%d.%s" % (li, sd),
               lift=0.4, rise=0.2, cls=HAIR, mat=MAT_GLOW, tint=1.0)
        b.cur_pal = 0.0
    # eagle's talons: three forward, one back, hooked and dark at the root
    fb = "foot%d.%s" % (li, sd)
    for k in range(4):
        a = (k - 1) * 0.5 if k < 3 else math.pi
        d = (t * math.cos(a) + sv * math.sin(a)).normalized()
        base = wr.lerp(ft, 0.7) + d * 0.04
        A.claw(b, base, d, 0.07, 0.014, fb, down=-up, hook=0.8, col0="3a3028", col1="f0e8d8")
pearl_at = LEGS[0][6] + LEGS[0][8] * 0.03 - LEGS[0][7] * 0.02
b.ball(pearl_at, 0.06, "ffffff", cls=CRYSTAL, bone="foot0.L", seg=14, rings=10, mat=MAT_GLOW, tint=0.3)

# ---------------------------------------------------------------- motion
T_IDLE = 4.0
T_WALK = 2.0


def swim(p, t, T, amp_y, amp_p, lag=0.55, head_amp=0.1):
    w = 2 * math.pi / T
    for i in range(NS):
        k = 0.5 + 0.6 * i / NS
        add(p, "seg%d" % i, (amp_p * math.sin(w * t - i * lag + 1.0) * k, amp_y * math.sin(w * t - i * lag) * k, amp_y * 0.3 * math.sin(w * t - i * lag)))
    for i in range(3):
        add(p, "neck%d" % i, (-amp_p * 0.6 * math.sin(w * t + (i + 1) * lag + 1.0), -amp_y * 0.6 * math.sin(w * t + (i + 1) * lag), 0.0))
    add(p, "head", (head_amp * 0.5 * math.sin(w * t + 2.0), head_amp * math.sin(w * t + 1.8), 0.0))
    for sd, s in (("L", 1), ("R", -1)):
        for i in range(3):
            add(p, "wh%s%d" % (sd, i), (0.15 * math.sin(w * t * 2 - i * 0.9), 0.12 * s * math.sin(w * t - i * 0.8), 0.0))


def paddle(p, t, T, amp):
    w = 2 * math.pi / T
    for li in (0, 1):
        for sd, s in (("L", 1), ("R", -1)):
            ph = w * t + li * math.pi + (0 if s > 0 else math.pi)
            add(p, "leg%d.%s" % (li, sd), (amp * math.sin(ph), 0.0, 0.0))
            add(p, "fore%d.%s" % (li, sd), (0.3 * amp * math.sin(ph - 0.8) + 0.2, 0.0, 0.0))
            add(p, "foot%d.%s" % (li, sd), (0.3 + 0.3 * math.sin(ph - 1.4), 0.0, 0.0))


def idle(t):
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.08 * math.sin(2 * math.pi * t / T_IDLE * 2), 0))
    swim(p, t, T_IDLE, 0.06, 0.04)
    paddle(p, t, T_IDLE, 0.2)
    add(p, "jaw", (0.08 + 0.06 * math.sin(2 * math.pi * t / T_IDLE * 2) ** 2, 0, 0))
    return p


def walk(t):
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.06 * math.sin(2 * math.pi * t / T_WALK * 2), 0))
    swim(p, t, T_WALK, 0.13, 0.06, head_amp=0.06)
    paddle(p, t, T_WALK, 0.45)
    add(p, "jaw", (0.08, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    ant = smooth(0.0, 0.3, k) * (1.0 - smooth(0.3, 0.42, k))
    hit_ = smooth(0.3, 0.42, k) * (1.0 - smooth(0.62, 1.0, k))
    p = idle(0.0)
    add(p, "root", (0, 0, 0), (0, 0.15 * ant - 0.1 * hit_, -0.2 * ant + 0.55 * hit_))
    add(p, "chest", (-0.3 * ant + 0.25 * hit_, 0, 0))
    add(p, "neck0", (-0.35 * ant + 0.3 * hit_, 0, 0))
    add(p, "neck1", (-0.25 * ant + 0.2 * hit_, 0, 0))
    add(p, "head", (-0.2 * ant + 0.25 * hit_, 0, 0))
    add(p, "jaw", (1.0 * smooth(0.22, 0.38, k) * (1.0 - smooth(0.5, 0.7, k)), 0, 0))
    for i in range(NS):
        add(p, "seg%d" % i, (0.06 * ant, 0.1 * math.sin(k * 6.0 - i * 0.6) * (ant + hit_), 0))
    for sd in ("L", "R"):
        add(p, "leg0." + sd, (-0.9 * hit_, 0, 0))
        add(p, "foot0." + sd, (-0.5 * hit_, 0, 0))
    return p


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = idle(0.0)
    add(p, "root", (0, 0, 0), (0, 0.12 * e, -0.25 * e))
    add(p, "chest", (-0.25 * e, 0.15 * e, 0))
    add(p, "neck0", (-0.3 * e, 0.25 * e, 0))
    add(p, "head", (-0.3 * e, 0.2 * e, 0.2 * e))
    add(p, "jaw", (0.6 * e, 0, 0))
    for i in range(NS):
        add(p, "seg%d" % i, (0.0, 0.12 * math.sin(k * 20.0 - i * 0.7) * e, 0.0))
    return p


def die(t):
    """Writhes, then crashes to the ground and lies still in its coils."""
    k = min(1.0, t / 1.2)
    fall = smooth(0.15, 0.7, k)
    writhe = math.sin(k * 14.0) * (1.0 - smooth(0.4, 0.75, k)) * 0.15
    p = zero_pose(r)
    add(p, "root", (0, 0, 0.25 * fall), (0, -0.92 * fall + 0.05 * math.sin(math.pi * smooth(0.7, 0.85, k)) * 0.5, 0))
    for i in range(NS):
        add(p, "seg%d" % i, (0.04 * fall * (1 if i % 2 else -1), writhe * math.sin(i * 0.9) + 0.06 * fall, 0))
    add(p, "chest", (0.15 * fall, 0, 0))
    add(p, "neck0", (0.3 * fall, 0.2 * fall, 0))
    add(p, "neck1", (0.25 * fall, 0.15 * fall, 0))
    add(p, "neck2", (0.15 * fall, 0, 0))
    add(p, "head", (0.15 * fall, 0, 0.35 * fall))
    add(p, "jaw", (0.35 * fall, 0, 0))
    for li in (0, 1):
        for sd, s in (("L", 1), ("R", -1)):
            add(p, "leg%d.%s" % (li, sd), (0.4 * fall, 0, -0.3 * s * fall))
            add(p, "foot%d.%s" % (li, sd), (0.6 * fall, 0, 0))
    for sd in ("L", "R"):
        for i in range(3):
            add(p, "wh%s%d" % (sd, i), (0.25 * fall, 0, 0))
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = idle(t)
    add(p, "root", (0, 0, 0), (0, 0.25 * e, 0))
    add(p, "chest", (-0.35 * e, 0, 0))
    add(p, "neck0", (-0.4 * e, 0, 0))
    add(p, "head", (-0.3 * e, 0, 0))
    add(p, "jaw", (1.0 * e, 0, 0))
    return p


print("[art] dragon: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/dragon.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die),
                                                 "cast": (0.6, cast)}, samples=14, dist=0.3, strength=0.45)
