"""Dragon: an eastern loong (Azure Dragon King, Frost Wyrm, Bone Wyrm, Ink Dragon, the Jiao of the
Nine Bends, the Lantern Dragon ...).

After the painters' rules for the loong (Guo Ruoxu's "three sections and nine resemblances", the
robe dragons of the Ming and Qing): the body is a long, even serpent's body, eighteen times as long
as it is thick, thrown into three bends - head to shoulders, shoulders to hips, hips to the tail -
and swimming through the air.  The nine resemblances: the head of a camel, the antlers of a deer,
the eyes of a rabbit (big and bulging), the ears of a cow, the neck of a snake, the belly of a clam
(broad pale plates), the scales of a carp, the claws of an eagle and the palms of a tiger.
The head: a long muzzle whose upper lip curls up into a broad, bulbous nose with flaring nostrils,
a shorter lower jaw with the fangs showing, heavy arched brows with flames of hair over the bulging
eyes, a lump on the forehead between the antlers, cow's ears; two long whiskers spring from the lip
beside the nose and trail back in S-curves, a beard hangs from the chin, tufts flare from the cheeks
and a mane of flame-like locks streams back down the neck.  The scales are sculpted (rows of carp
scales staggered by half a scale, each overlapping the next), a crest of swept fins runs down the
spine to a tail that ends in a fan of flame, four short, muscular legs reach and kick with tufts of
flame at the elbows and spread eagle's talons, and one forefoot holds the pearl.
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
import serpentine as S  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from creature import add, smooth, zero_pose  # noqa: E402
from kit import CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, mix  # noqa: E402
from sculpt import bump  # noqa: E402

kit.reset()
creature.realtime()
# the three bends: the neck rises to the head, the body dips under the shoulders, humps, dips under
# the hips and the tail sweeps up and curls; the whole line also snakes from side to side
CTRL = [V(0.0, 1.8, 0.86), V(0.06, 1.62, 0.6), V(0.22, 1.37, 0.33), V(0.3, 1.17, 0.02), V(0.13, 1.07, -0.31), V(-0.2, 1.15, -0.6),
        V(-0.35, 1.37, -0.9), V(-0.2, 1.5, -1.22), V(0.14, 1.39, -1.5), V(0.31, 1.14, -1.78), V(0.18, 0.98, -2.08), V(-0.12, 1.0, -2.3),
        V(-0.3, 1.16, -2.45)]
SP = A.Spline(CTRL, per=10)
U_CHEST, U_HIP = 0.2, 0.56
NS = 10


def rad(u):
    """An even serpent's girth: a slim neck, the chest a little fuller, a long tapering tail."""
    r = 0.094 + 0.036 * smooth(0.0, 0.17, u) - 0.006 * bump(u, 0.4, 0.12) + 0.004 * bump(u, 0.57, 0.08)
    r *= 1.0 - 0.8 * smooth(0.58, 1.0, u) ** 1.2
    return max(0.022, r)


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
HC = H0 + HF * 0.15 + U0 * 0.04
hf = A.HeadFrame(HC, (HF + V(0, -0.1, 0)).normalized())
r.bone("head", SP.at(0.02)[0], HC + hf.f * 0.42, "neck2")
r.bone("jaw", hf.at(0, -0.075, -0.06), hf.at(0, -0.11, 0.33), "head")
WHISK = {}
for s, sd in ((1, "L"), (-1, "R")):
    # the whiskers spring outwards from the lip beside the nose, then trail back in an S
    w0 = hf.at(0.075 * s, -0.01, 0.39)
    pts = [w0, w0 + hf.r * (0.1 * s) + hf.f * 0.03 - hf.u * 0.04, w0 + hf.r * (0.19 * s) - hf.f * 0.1 - hf.u * 0.19,
           w0 + hf.r * (0.23 * s) - hf.f * 0.4 - hf.u * 0.24, w0 + hf.r * (0.19 * s) - hf.f * 0.66 - hf.u * 0.13]
    WHISK[sd] = pts
    prev = "head"
    for i in range(3):
        r.bone("wh%s%d" % (sd, i), pts[i], pts[i + 1], prev)
        prev = "wh%s%d" % (sd, i)
LEGS = []
for li, (u, par) in enumerate(((U_CHEST + 0.02, "chest"), (U_HIP + 0.02, "seg%d" % int((U_HIP + 0.02 - U_CHEST) / (1.0 - U_CHEST) * NS)))):
    p, t, up, side = SP.at(u)
    fw = -t                                # forward, towards the head
    for s, sd in ((1, "L"), (-1, "R")):
        sv = side * s
        sh = p + sv * rad(u) * 0.62 - up * rad(u) * 0.45
        if li == 0:
            # the foreleg: the elbow tucked back, the forearm and the palm reaching forward
            el = sh + sv * 0.1 - up * 0.15 - fw * 0.07
            wr = el + sv * 0.04 - up * 0.05 + fw * 0.17
            ft = wr + fw * 0.1 - up * 0.02 + sv * 0.02
        else:
            # the hind leg: the knee forward, the shank and the foot kicking back
            el = sh + sv * 0.1 - up * 0.1 + fw * 0.1
            wr = el + sv * 0.04 - up * 0.1 - fw * 0.17
            ft = wr - fw * 0.1 - up * 0.03 + sv * 0.02
        r.bone("leg%d.%s" % (li, sd), sh, el, par)
        r.bone("fore%d.%s" % (li, sd), el, wr, "leg%d.%s" % (li, sd))
        r.bone("foot%d.%s" % (li, sd), wr, ft, "fore%d.%s" % (li, sd))
        LEGS.append((li, sd, s, sh, el, wr, ft, up, fw, sv))
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
# ---------------------------------------------------------------- the body: carp scales, a clam's belly
S.scaled_body(b, SP, rad, spine_w, scale_len=0.072, cols=10, per=4, belly=55.0, height=0.08, plate_h=0.05, flat=0.2, ridge=0.08,
              back=0.62, flank=0.8, under=0.96, edge=0.24, cap0=True, cap1=True)

# ---------------------------------------------------------------- legs: tiger's palms, eagle's claws
for li, sd, s, sh, el, wr, ft, up, fw, sv in LEGS:
    lg, fo, fb = "leg%d.%s" % (li, sd), "fore%d.%s" % (li, sd), "foot%d.%s" % (li, sd)
    c = Clay(0.0195, "dragon_leg%d%s" % (li, sd))
    c.chain([sh - sv * 0.07, sh, el, wr], [0.075, 0.072, 0.052, 0.043], bones=limb_weights([lg, lg, fo]), tag="leg", t0=0.0, t1=3.0)
    # the shoulder (or haunch) muscle and the swell of the forearm
    c.ellipsoid(sh.lerp(el, 0.38), (0.068, 0.062, 0.095), rot=A.frame_m(el - sh), bones={lg: 1.0}, tag="leg")
    c.ellipsoid(el.lerp(wr, 0.3), (0.05, 0.046, 0.07), rot=A.frame_m(wr - el), bones={fo: 1.0}, tag="leg")
    # the tiger's palm: a padded paw from which the eagle's talons spring
    c.ellipsoid(wr.lerp(ft, 0.45), (0.048, 0.034, 0.062), rot=A.frame_m(ft - wr), bones={fb: 1.0}, tag="paw")
    c.build(b, lambda p, info: S.grey(0.94 if info.tag == "paw" else 0.78 - 0.08 * smooth(0.2, 0.8, info.n.dot(up))), cls=S.PLAIN,
            tint_fn=lambda p, info: 1.0)
    # eagle's talons: three forward and one back, hooked, dark at the root
    for k in range(4):
        a = (k - 1) * 0.55 if k < 3 else math.pi
        d = (fw * math.cos(a) * (1 if li == 0 else -1) + sv * math.sin(a)).normalized()
        d = (d - up * 0.25).normalized()
        base = wr.lerp(ft, 0.6) + d * 0.035
        A.claw(b, base, d, 0.085 if k < 3 else 0.06, 0.017, fb, down=-up, hook=0.9, col0="3a3028", col1="f2ead8")

# ---------------------------------------------------------------- the camel's head
HP = [
    ("ell", (0, 0.035, -0.05), (0.118, 0.105, 0.13), "head", False, False),     # cranium
    ("ell", (0, 0.11, 0.03), (0.055, 0.04, 0.075), "head", False, False),       # the lump on the forehead
    ("ell", (0.082, 0.09, 0.1), (0.058, 0.034, 0.08), "brow", True, False),     # heavy, arched brows
    ("ell", (0.1, -0.025, 0.02), (0.062, 0.072, 0.085), "head", True, False),   # cheeks
    ("ell", (0.1, -0.055, -0.08), (0.05, 0.06, 0.07), "head", True, False),     # the jaw muscle
    ("ell", (0, 0.0, 0.17), (0.092, 0.07, 0.12), "head", False, False),         # muzzle
    ("ell", (0, -0.01, 0.29), (0.078, 0.06, 0.09), "head", False, False),
    ("ell", (0, 0.03, 0.235), (0.06, 0.03, 0.06), "head", False, True),         # the dip of the bridge
    ("ell", (0, 0.05, 0.37), (0.074, 0.05, 0.06), "nose", False, False),        # the bulbous nose
    ("ball", (0.045, 0.046, 0.395), 0.036, "nose", True, False),                # its flaring wings
    ("ball", (0.047, 0.06, 0.428), 0.015, "nose", True, True),                  # nostrils
    ("ell", (0, -0.03, 0.4), (0.066, 0.03, 0.045), "lip", False, False),        # the upper lip curling up
    ("ball", (0.088, 0.058, 0.13), 0.034, "head", True, True),                  # eye sockets
]
hc = Clay(0.0135, "dragon_head")
A.head_clay(hc, hf, 1.0, HP)


def head_col(p, info):
    q = hf.M.transposed() @ (p - HC)
    if info.tag == "nose":
        return S.grey(0.86)
    if info.tag == "lip":
        return S.grey(0.92)
    v = 0.72 + 0.16 * smooth(0.02, -0.08, q.y) - 0.08 * smooth(0.05, 0.12, q.y)
    if info.tag == "brow":
        v = 0.66
    return S.grey(v)


hc.build(b, head_col, cls=S.PLAIN, tint_fn=lambda p, info: 1.0)
# the lower jaw: shorter than the upper, pale under the chin
j = Clay(0.013, "dragon_jaw")
for s in (1, -1):
    j.chain([hf.at(0.1 * s, -0.08, -0.02), hf.at(0.068 * s, -0.105, 0.17), hf.at(0.03 * s, -0.1, 0.31)], [0.042, 0.036, 0.03], bones={"jaw": 1.0}, tag="jaw")
j.ellipsoid(hf.at(0, -0.1, 0.3), (0.042, 0.032, 0.035), rot=hf.M, bones={"jaw": 1.0}, tag="jaw")
j.build(b, lambda p, info: mix((0.94, 0.94, 0.94), (0.45, 0.14, 0.18), smooth(0.2, 0.5, info.n.dot(hf.u))), cls=S.PLAIN,
        tint_fn=lambda p, info: 0.6 * (1.0 - smooth(0.2, 0.5, info.n.dot(hf.u))))
# the mouth: a dark palate, a tongue, the fangs and the teeth
b.ellipsoid(hf.at(0, -0.065, 0.2), (0.078, 0.02, 0.18), "3a1014", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
b.ellipsoid(hf.at(0, -0.09, 0.2), (0.048, 0.013, 0.14), "b03848", cls=SKIN, bone="jaw", rot=A.euler_of(hf.M), seg=10, rings=5, mat=MAT_PLAIN)
for k in range(5):
    z = 0.37 - k * 0.06
    for s in (1, -1):
        x = (0.042 + k * 0.011) * s
        A.fang(b, hf.at(x, -0.055, z), -hf.u, 0.075 if k == 0 else 0.03, 0.012 if k == 0 else 0.007, "head", back=-hf.f, curve=0.25)
        A.fang(b, hf.at(x * 0.92, -0.098, z - 0.04), hf.u, 0.05 if k == 0 else 0.024, 0.01 if k == 0 else 0.006, "jaw", back=-hf.f, curve=0.2)
# rabbit's eyes: big, round and bulging, under the heavy brows
for s in (1, -1):
    A.animal_eye(b, hf.at(0.093 * s, 0.056, 0.135), hf.f * 0.45 + hf.r * (0.85 * s) + hf.u * 0.08, 0.044, "ffb020", "head", pupil="slit", almond=0.88,
                 slant=0.1, side=s, glow=True)
# cow's ears behind the eyes
for s in (1, -1):
    A.ear(b, hf.at(0.125 * s, 0.07, -0.085), hf.r * s * 0.8 - hf.f * 0.6, 0.12, 0.065, 0.03, (0.72, 0.72, 0.72), (0.9, 0.85, 0.85), "head",
          up=hf.r * s - hf.u * 0.3 - hf.f * 0.5, point=0.6, cup=0.5, tint=1.0, tint_in=0.4, side=s)
# a deer's antlers: a beam swept back from behind the brows, branching into three tines
for s in (1, -1):
    a0 = hf.at(0.065 * s, 0.13, -0.03)
    beam = [a0, a0 + hf.u * 0.15 - hf.f * 0.05 + hf.r * 0.05 * s, a0 + hf.u * 0.28 - hf.f * 0.22 + hf.r * 0.1 * s, a0 + hf.u * 0.36 - hf.f * 0.44 + hf.r * 0.08 * s]
    A.horn(b, beam, 0.03, "8a7050", "f6ecd0", "head", r1=0.006, seg=10, cls=0.9)
    for k, (tt, dv) in enumerate(((0.32, hf.u * 0.13 + hf.f * 0.07 + hf.r * 0.03 * s), (0.58, hf.u * 0.11 + hf.r * 0.08 * s), (0.82, hf.u * 0.12 - hf.f * 0.02))):
        i = min(2, int(tt * 3))
        q = beam[i].lerp(beam[i + 1], tt * 3 - i)
        A.horn(b, [q, q + dv * 0.5 + hf.u * 0.01, q + dv], 0.016, "a08860", "f6ecd0", "head", r1=0.004, seg=8, cls=0.9)

# ---------------------------------------------------------------- mane, brows, beard, whiskers (the secondary colour)
b.cur_pal = 0.5
hit = A.surface(b)
n_mane = 0
for i in range(16):
    u = 0.015 + 0.2 * i / 15
    p, t, up, side = SP.at(u)
    h = hit(p + up * 0.6, -up)
    if h is None:
        continue
    root, nrm = h
    n_mane += 1
    ln = 0.3 - 0.12 * (u / 0.22)
    for sgn in (1, -1):
        out = side * sgn
        # a lock of flame: up off the neck, then streaming back and curling over
        base = root + out * 0.02
        pts = [base, base + nrm * ln * 0.35 + out * ln * 0.25 + t * ln * 0.15, base + nrm * ln * 0.5 + out * ln * 0.42 + t * ln * 0.55,
               base + nrm * ln * 0.38 + out * ln * 0.55 + t * ln * 0.95]
        shade = 0.74 + 0.1 * ((i + (sgn > 0)) % 2)
        S.flame(b, pts, ln * 0.13, out, S.grey(shade), S.grey(min(1.0, shade + 0.18)), bone=spine_w(u), thick=0.3, cls=HAIR)
print("[art] dragon mane locks:", n_mane)
# the mane behind the head and the tufts flaring back from the cheeks and the angle of the jaw
for s in (1, -1):
    for k in range(4):
        base = hf.at((0.06 + 0.025 * k) * s, 0.06 - 0.03 * k, -0.1 - 0.02 * k)
        out = (hf.r * s * 0.7 + hf.u * (0.5 - 0.2 * k)).normalized()
        ln = 0.26 - 0.03 * k
        S.flame(b, [base, base + out * ln * 0.4 - hf.f * ln * 0.25, base + out * ln * 0.55 - hf.f * ln * 0.65, base + out * ln * 0.4 - hf.f * ln],
                ln * 0.14, hf.r * s, S.grey(0.78), S.grey(0.95), bone="head", thick=0.3, cls=HAIR)
    for k in range(3):
        base = hf.at(0.12 * s, -0.04 - 0.03 * k, -0.04 - 0.03 * k)
        out = (hf.r * s - hf.u * 0.3 * k).normalized()
        ln = 0.16 - 0.02 * k
        S.flame(b, [base, base + out * ln * 0.45 - hf.f * ln * 0.2, base + out * ln * 0.6 - hf.f * ln * 0.6, base + out * ln * 0.5 - hf.f * ln],
                ln * 0.16, hf.u, S.grey(0.8), S.grey(0.96), bone="head", thick=0.3, cls=HAIR)
    # flames of brow sweeping up and back over the eyes
    for k in range(3):
        base = hf.at((0.06 + 0.03 * k) * s, 0.115 - 0.01 * k, 0.15 - 0.04 * k)
        ln = 0.13 - 0.02 * k
        dv = (hf.u * 0.7 - hf.f * 0.7 + hf.r * 0.3 * s).normalized()
        S.flame(b, [base, base + dv * ln * 0.4 + hf.u * 0.01, base + dv * ln * 0.75 - hf.f * ln * 0.1, base + dv * ln - hf.f * ln * 0.25],
                ln * 0.17, hf.r * s, S.grey(0.8), S.grey(1.0), bone="head", thick=0.3, cls=HAIR)
# the beard: locks hanging from the chin and sweeping back
for k in range(5):
    u2 = (k / 4 - 0.5) * 2
    base = hf.at(0.045 * u2, -0.12, 0.26 - 0.03 * abs(u2))
    ln = 0.2 - 0.03 * abs(u2)
    S.flame(b, [base, base - hf.u * ln * 0.5 - hf.f * ln * 0.1, base - hf.u * ln * 0.75 - hf.f * ln * 0.5, base - hf.u * ln * 0.7 - hf.f * ln * 0.95],
            ln * 0.13, hf.f, S.grey(0.74), S.grey(0.95), bone="jaw", thick=0.3, cls=HAIR)
# the long whiskers: tapered barbels on their own bone chains
for sd, pts in WHISK.items():
    cp = A.catmull(pts, 5)
    m = len(cp)
    bones = [{"wh%s%d" % (sd, min(2, int(i / (m - 1) * 2.999))): 1.0} for i in range(m)]
    b.tube(cp, [0.0095 * (1.0 - 0.88 * i / (m - 1)) + 0.0012 for i in range(m)], (0.9, 0.9, 0.9), cls=HAIR, bones=bones, seg=6, tint=1.0,
           cols=[mix((0.82, 0.82, 0.82), (1.0, 1.0, 1.0), i / (m - 1)) for i in range(m)])
b.cur_pal = 0.0

# ---------------------------------------------------------------- the crest, the elbow flames, the tail's flame, the pearl
b.cur_pal = 1.0
n_fin = 0
for i in range(30):
    u = 0.23 + 0.7 * i / 29
    p, t, up, side = SP.at(u)
    h = hit(p + up * 0.6, -up)
    if h is None:
        continue
    root, nrm = h
    n_fin += 1
    ht = 0.1 * (1.0 - 0.6 * (u - 0.23) / 0.7) * (0.85 + 0.15 * (i % 2))
    S.fin(b, root - nrm * 0.01, t, nrm, ht, spine_w(u), col=0.66, col_tip=0.98, sweep=0.8, width=0.75, cls=S.PLAIN)
print("[art] dragon fins:", n_fin)
for li, sd, s, sh, el, wr, ft, up, fw, sv in LEGS:
    back = -fw if li == 0 else fw
    for k in range(3):
        base = el + up * 0.015 * k - back * 0.01
        ln = 0.16 - 0.025 * k
        dv = (back * 0.85 + up * 0.35 + sv * (0.25 - 0.15 * k)).normalized()
        S.flame(b, [base, base + dv * ln * 0.4 + sv * 0.01, base + dv * ln * 0.75 + up * ln * 0.1, base + dv * ln + up * ln * 0.28], ln * 0.2, sv,
                S.grey(0.85), S.grey(1.0), bone="fore%d.%s" % (li, sd), thick=0.25, cls=HAIR, mat=MAT_GLOW)
# the tail ends in a fan of flame, spread in the plane of the body's back
p, t, up, side = SP.at(0.965)
for k in range(9):
    a = (k / 8 - 0.5) * 2.2
    out = (up * math.cos(a) + side * math.sin(a) * 0.35).normalized()
    ln = 0.34 * (1.0 - 0.35 * abs(a) / 1.1)
    base = p - t * 0.03
    pts = [base, base + t * ln * 0.3 + out * ln * 0.25, base + t * ln * 0.62 + out * ln * 0.5 + side * ln * 0.06, base + t * ln + out * ln * 0.62]
    S.flame(b, pts, ln * 0.12, side, S.grey(0.8), S.grey(1.0), bone="seg%d" % (NS - 1), thick=0.25, cls=HAIR)
b.cur_pal = 0.0
pearl_at = LEGS[0][6] + LEGS[0][8] * 0.03 - LEGS[0][7] * 0.03
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
            # the whiskers stream and ripple, never flipping up over the face (a small pitch, drooping)
            add(p, "wh%s%d" % (sd, i), (0.045 * math.sin(w * t * 2 - i * 0.9) - 0.025, 0.1 * s * math.sin(w * t - i * 0.8), 0.0))


def paddle(p, t, T, amp):
    w = 2 * math.pi / T
    for li in (0, 1):
        for sd, s in (("L", 1), ("R", -1)):
            ph = w * t + li * math.pi + (0 if s > 0 else math.pi)
            add(p, "leg%d.%s" % (li, sd), (amp * math.sin(ph), 0.0, 0.0))
            add(p, "fore%d.%s" % (li, sd), (0.3 * amp * math.sin(ph - 0.8) + 0.1, 0.0, 0.0))
            add(p, "foot%d.%s" % (li, sd), (0.15 + 0.25 * math.sin(ph - 1.4), 0.0, 0.0))


def idle(t):
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.08 * math.sin(2 * math.pi * t / T_IDLE * 2), 0))
    swim(p, t, T_IDLE, 0.06, 0.04)
    paddle(p, t, T_IDLE, 0.2)
    add(p, "jaw", (0.1 + 0.06 * math.sin(2 * math.pi * t / T_IDLE * 2) ** 2, 0, 0))
    return p


def walk(t):
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.06 * math.sin(2 * math.pi * t / T_WALK * 2), 0))
    swim(p, t, T_WALK, 0.13, 0.06, head_amp=0.06)
    paddle(p, t, T_WALK, 0.45)
    add(p, "jaw", (0.1, 0, 0))
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
            add(p, "wh%s%d" % (sd, i), (-0.2 * fall, 0, 0))
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
