"""Qilin (new in Part VIII): the auspicious hoofed beast of the Jasper Pool and the star-meadows
(Jade Qilin, Star-Mane Qilin, the Golden Ox Star's herd-guardians).

After the classical descriptions: the body of a deer or an ox - a deep chest, a strong back and
slender legs on cloven hooves - covered in the scales of a carp; the head of a dragon, long in the
face with heavy brow ridges, flared nostrils, whiskers and a beard; a single ridged horn swept back
over the crown; a flowing mane from the crown down the crest of the neck; flames curling at the
elbows and hocks; an ox's tail ending in a plume.  Sculpted in clay over the muscle masses
(art/lib/clay.py), the scales and the pale belly plates painted into the greys; the mane, beard
and plume take the secondary colour, the horn and hooves their own.
Clips: idle, walk (a high-stepping four-beat walk), attack (rears and stamps), hurt, die, and cast
(the head thrown up, the horn calling down light).
Run: blender --background --python art/monsters/qilin.py  ->  assets/monsters/qilin.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay  # noqa: E402
from creature import QuadMotion, add, quad_rig2, quad_skel, smooth  # noqa: E402
from kit import CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SCALE, SKIN, V, Builder, mix  # noqa: E402

kit.reset()
creature.realtime()
H = 0.98
hip_z, sh_z = -0.46, 0.4
neck0 = V(0, H + 0.06, sh_z + 0.08)
neck1 = V(0, H + 0.19, sh_z + 0.25)
headp = V(0, H + 0.27, sh_z + 0.37)
snout = headp + V(0, -0.14, 0.38)
tb = V(0, H + 0.02, hip_z - 0.1)
tail = [tb + V(0, -0.14 * k + 0.012 * k * k, -0.06 * k) for k in range(6)]
sk = quad_skel(H=H, hip_z=hip_z, sh_z=sh_z, hip_w=0.13, sh_w=0.125, foot="hoof", withers=0.07, neck=(neck1, headp), head=snout, tail=tail)
HC = headp + V(0, -0.02, 0.1)
hf = A.HeadFrame(HC, V(0, -0.35, 1.0))
K = 1.25


def hp(x, y, z):
    return hf.at(x * K, y * K, z * K)


ears = [(hp(0.06, 0.035, -0.04), hp(0.13, 0.01, -0.07)), (hp(-0.06, 0.035, -0.04), hp(-0.13, 0.01, -0.07))]
r, legs = quad_rig2(sk, ears=ears)
r.bones["jaw"] = (hp(0, -0.04, -0.01), hp(0, -0.055, 0.2), "head")
b = Builder("qilin")

# ---------------------------------------------------------------- body
c = Clay(0.016, "qilin_body")
NECK = [V(0, H + 0.02, sh_z), neck0.lerp(neck1, 0.6) + V(0, 0, -0.02), headp + V(0, -0.02, 0.0)]
NECK_R = [0.2, 0.17, 0.13]
A.clay_torso(c, sk, w=0.22, d=0.31, haunch=(0.21, 0.22, 0.22), tuck=0.02, withers=0.13, neck=NECK_R, throat=0.14, chest_y=0.75, neck_pts=NECK)
for sd in ("L", "R"):
    A.clay_foreleg(c, sk, sd, g=0.78, foot="hoof", paw=1.0)
    A.clay_hindleg(c, sk, sd, g=0.82, foot="hoof", paw=1.0)
A.clay_tail(c, sk, [0.04, 0.032, 0.026, 0.022, 0.02, 0.018])
# the dragon's head: a long face, heavy brow ridges over the eyes, a broad nose with flared
# nostrils, the cheeks, eye sockets
A.head_clay(c, hf, K, [
    ("ell", (0, 0.02, -0.02), (0.075, 0.07, 0.08), "head", False, False),
    ("ell", (0.045, 0.045, 0.06), (0.03, 0.022, 0.05), "head", True, False),
    ("ell", (0.05, -0.025, 0.02), (0.038, 0.042, 0.05), "head", True, False),
    ("ell", (0, -0.005, 0.1), (0.042, 0.047, 0.07), "muzzle", False, False),
    ("ell", (0, -0.012, 0.17), (0.034, 0.042, 0.06), "muzzle", False, False),
    ("ell", (0, -0.008, 0.222), (0.034, 0.04, 0.032), "muzzle", False, False),
    ("ell", (0, 0.028, 0.16), (0.022, 0.016, 0.07), "muzzle", False, False),
    ("ball", (0.018, 0.02, 0.228), 0.018, "muzzle", True, False),
    ("ball", (0.019, 0.026, 0.243), 0.008, "muzzle", True, True),
    ("ell", (0.05, 0.022, 0.062), (0.024, 0.017, 0.018), "head", True, True),
])


def head_local(p):
    return hf.M.transposed() @ (p - HC) / K


def scales(p, n, size=1.0):
    """Carp scales: rows of round scales offset row to row, each darker at its rim."""
    sx = (p.z + 3.0) * 9.0 / size
    sy = (p.y + 0.3 * abs(p.x)) * 10.0 / size + 0.5 * (math.floor(sx) % 2)
    fx, fy = sx - math.floor(sx), sy - math.floor(sy)
    return smooth(0.3, 0.5, math.hypot(fx - 0.35, fy - 0.5))


def col(p, info):
    tag = info.tag
    n = info.n
    if tag in ("head", "muzzle"):
        q = head_local(p)
        v = 0.78 + 0.1 * smooth(0.0, -0.04, q.y)
        rim = scales(p, n, 0.6) * smooth(0.03, 0.06, q.y) * smooth(0.12, 0.04, q.z)
        v *= 1.0 - 0.15 * rim
        v = v * (1.0 - smooth(-0.02, -0.05, q.y)) + 0.95 * smooth(-0.02, -0.05, q.y)
        return (v, v, v)
    under = smooth(-0.15, -0.6, n.y)
    if tag == "neck":
        under = max(under, smooth(0.2, -0.3, n.y) * smooth(0.2, 0.8, n.z))
    if tag in ("body", "neck", "leg"):
        # a darker back, carp scales over the hide, pale ribbed plates along the belly
        v = 0.8 - 0.12 * smooth(0.2, 0.9, n.y)
        v *= 1.0 - 0.06 * scales(p, n)
        band = smooth(0.55, 0.75, 0.5 + 0.5 * math.cos((p.z if tag != "neck" else p.y) * 55.0))
        belly = 0.95 - 0.18 * band
        return (v * (1.0 - under) + belly * under,) * 3
    if tag in ("fleg", "hleg"):
        v = 0.78 - 0.12 * smooth(1.2, 2.2, info.t)
        v *= 1.0 - 0.08 * scales(p, n, 0.7) * (1.0 - smooth(1.0, 1.6, info.t))
        return (v, v, v)
    if tag == "fetlock":
        return (0.55, 0.55, 0.55)
    if tag == "tail":
        return (0.72, 0.72, 0.72)
    return (0.8, 0.8, 0.8)


def tint(p, info):
    cc = col(p, info)[0]
    return 1.0 - 0.6 * smooth(0.88, 0.97, cc)


c.build(b, col, cls=SCALE, tint_fn=tint)

# ---------------------------------------------------------------- jaw, mouth, eyes, ears, horn
j = Clay(0.012, "qilin_jaw")
for s in (1, -1):
    j.chain([hp(0.04 * s, -0.045, 0.0), hp(0.026 * s, -0.052, 0.11), hp(0.012 * s, -0.05, 0.2)], [0.02, 0.018, 0.016], bones={"jaw": 1.0}, tag="jaw")
j.build(b, lambda p, info: mix((0.95, 0.95, 0.95), (0.42, 0.16, 0.18), smooth(0.2, 0.5, info.n.dot(hf.u))), cls=SCALE,
        tint_fn=lambda p, info: 0.6 * (1.0 - smooth(0.2, 0.5, info.n.dot(hf.u))))
b.ellipsoid(hp(0, -0.035, 0.1), (0.028, 0.01, 0.09), "3a1418", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
for s in (1, -1):
    A.fang(b, hp(0.022 * s, -0.035, 0.2), -hf.u, 0.022 * K, 0.005 * K, "head", back=-hf.f, curve=0.2)
    A.animal_eye(b, hp(0.05 * s, 0.022, 0.064), hf.f + hf.r * (0.6 * s) + hf.u * 0.12, 0.021 * K, "f0c030", "head", pupil="round", almond=0.68, slant=0.12, side=s)
for s, sd in ((1, "L"), (-1, "R")):
    # ox ears, held out to the sides
    A.ear(b, hp(0.06 * s, 0.035, -0.04), hf.r * s + hf.f * 0.6, 0.085 * K, 0.05 * K, 0.025 * K, (0.7, 0.7, 0.7), (0.95, 0.9, 0.88), "ear." + sd,
          up=hf.u * 0.3 + hf.r * s - hf.f * 0.4, point=0.7, cup=0.5, tint=1.0, tint_in=0.3, side=s)
b.cur_pal = 0.0
# the single horn: ridged keratin swept back over the crown, pale at the tip
horn = [hp(0, 0.065, 0.03), hp(0, 0.115, 0.0), hp(0, 0.15, -0.07), hp(0, 0.16, -0.15), hp(0, 0.145, -0.21)]
A.horn(b, horn, 0.022 * K, "b8a070", "fff4d8", "head", r1=0.003, rings=6, ring_k=0.18, ridge=0.08, seg=12)
b.ball(hp(0, 0.06, 0.05), 0.014 * K, "80f0d0", cls=CRYSTAL, bone="head", seg=8, rings=6, mat=MAT_GLOW)

# ---------------------------------------------------------------- mane, beard, whiskers, plume (secondary colour)
b.cur_pal = 0.5
# the crest of the neck: found by casting down onto the sculpted neck, from the crown to the
# withers; two layers of broad locks fall to either side
hit = A.surface(b)
crest_a = hp(0, 0.04, -0.1)
crest_b = V(0, H + 0.08, sh_z - 0.1)
for i in range(16):
    t = i / 15
    q = crest_a.lerp(crest_b, t)
    h = hit(q + V(0, 0.6, 0), V(0, -1, 0))
    if h is None:
        continue
    root, nrm = h
    sgn = 1 if i % 2 else -1
    shade = 0.78 - 0.18 * (i % 3) / 2
    bone = "head" if t < 0.12 else ({"neck1": 0.7, "neck0": 0.3} if t < 0.45 else ({"neck0": 0.8, "chest": 0.2} if t < 0.8 else {"chest": 1.0}))
    for layer in range(2):
        groom = V(0.45 * sgn * (1 + layer), -0.2 - 0.3 * layer, -1.0).normalized()
        A.lock(b, root + V(0.012 * sgn * layer, -0.01 * layer, 0), groom, nrm + V(sgn * 0.4, 0, 0), (0.24 - 0.07 * t - 0.04 * layer) * K / 1.25, 0.065 - 0.012 * layer,
               (shade,) * 3, (min(1.0, shade + 0.2),) * 3, bone=bone, lift=0.3, rise=0.1 + 0.2 * smooth(0.0, 0.3, t), thick=0.35, tint=1.0, cls=HAIR, bend=0.3 * sgn, droop=0.3)
# forelock over the brow
A.lock(b, hp(0, 0.08, -0.02), hf.f * 0.9 + hf.u * 0.2, hf.u, 0.1, 0.04, (0.8,) * 3, (0.95,) * 3, bone="head", lift=0.3, rise=0.1, cls=HAIR)
# a beard under the chin and two long whiskers from the upper lip
for k in range(3):
    u = (k - 1) * 0.9
    A.lock(b, hp(0.012 * u, -0.07, 0.15 - 0.03 * abs(u)), -hf.u * 0.8 - hf.f * 0.35, -hf.f, 0.12 * K / 1.25, 0.03, (0.78,) * 3, (0.95,) * 3, bone="jaw", lift=0.2, rise=0.1, cls=HAIR)
# the ox's tail ends in a plume
tl = sk.tail
for k in range(7):
    a = k / 7 * 2 * math.pi
    out = V(math.cos(a), 0, math.sin(a))
    A.lock(b, tl[-2] + out * 0.02, (V(0, -1, 0) + out * 0.25).normalized(), out, 0.22, 0.045, (0.75,) * 3, (0.95,) * 3, bone="tail4", lift=0.25, rise=0.25, cls=HAIR)
b.cur_pal = 0.0

# ---------------------------------------------------------------- hooves and flames
for sd, s in (("L", 1), ("R", -1)):
    for pre, fb, ft in (("f", "fb", "ft"), ("h", "hb", "ht")):
        p0 = sk[fb + "." + sd]
        p1 = sk[ft + "." + sd]
        A.hoof(b, V(p1.x, 0.0, p1.z - 0.03), V(0, 0, 1), 0.05, 0.075, "2a2420", pre + "_toe." + sd, cloven=True, col_top="4a3a30")
    # flames curling at the elbow and the hock (they keep their own golden colour)
    for jn, bone in ((sk["el." + sd], "f_lo." + sd), (sk["hk." + sd], "h_meta." + sd)):
        for k in range(3):
            root = jn + V(0.03 * s, 0.03 * k - 0.02, -0.03)
            A.lock(b, root, V(0.3 * s, 0.45 + 0.2 * k, -1.0).normalized(), V(s, 0, 0), 0.11 - 0.02 * k, 0.03, "ffa030", "fff0a0", bone=bone,
                   lift=0.4, rise=0.2, cls=HAIR, mat=MAT_GLOW, tint=0.0, bend=0.3 * s)
# auspicious cloud wisps curling round the hooves
for k in range(6):
    a = k / 6 * 2 * math.pi
    cc = V(math.cos(a) * 0.45, 0.05, math.sin(a) * 0.62)
    curl = [cc + V(math.cos(a + t * 3.0) * 0.08 * (1 - t), 0.03 * t, math.sin(a + t * 3.0) * 0.08 * (1 - t)) for t in (0.0, 0.33, 0.66, 1.0)]
    b.tube(curl, [0.028, 0.022, 0.016, 0.005], "f8f4ff", cls=CRYSTAL, bone="root", seg=6, mat=MAT_GLOW, tint=0.3)

# ---------------------------------------------------------------- motion
qm = QuadMotion(r, legs, T_walk=1.4, stride=0.42, lift=0.12, duty=0.62, bob=0.014, roll=0.025, yaw=0.04, head_nod=0.06, head_low=-0.05,
                neck_up=0.05, tail_amp=0.15, tail_lift=0.0, tail_droop=0.1, pounce="rear", T_idle=4.0, front_flex=1.6, hind_flex=0.8,
                rest_h=0.21, lunge=0.3)


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = qm.idle(0.0)
    add(p, "neck0", (-0.4 * e, 0, 0))
    add(p, "head", (-0.35 * e, 0, 0))
    add(p, "jaw", (0.35 * e, 0, 0))
    return p


print("[art] qilin: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/qilin.glb", qm.clips({"cast": (0.6, cast)}), samples=16, dist=0.3, strength=0.5, floor_y=0.0)
