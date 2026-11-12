"""Qilin (new in Part VIII): the auspicious hoofed beast of the Jasper Pool and the star-meadows
(Jade Qilin, Star-Mane Qilin, the Golden Ox Star's herd-guardians, and the white horses and deer
that wear its shape).

After the classical descriptions and the Qing images (the Shuowen: "the body of a deer, the tail
of an ox, one horn"; the bronze qilin before the Summer Palace: a dragon's head, cloven hooves,
a scaled body with flames rising from it):

* **Silhouette.**  A deer's body - a deep chest, a tucked belly, slender legs on cloven hooves -
  with the neck arched high and the head carried proud above the withers; one horn swept back
  over the crown; a mane that curls along the crest of the neck; flames licking up from the
  elbows and hocks; an ox's tail ending in a curling plume.
* **Head.**  A dragon's: long in the face, heavy ridges over the eyes, the cheeks full, a broad
  upturned nose with flared nostrils at the end of the muzzle, long whiskers sweeping back from
  the upper lip and a beard under the chin; the mouth closed at rest.
* **Scales and value.**  Carp scales over the back, flanks, neck and haunches, each a shingle
  lying over the one behind it with a darker rim, in rows that follow the body and grow smaller
  on the neck and legs (no grid); pale ridged plates along the belly; the back darker.  The
  mane, beard and plume take the secondary colour, the horn and flames the accent, the hooves
  their own.

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
from kit import CLOTH, MAT_PLAIN, SKIN, V, Builder, mix  # noqa: E402
from mammal import flame, lip_line  # noqa: E402

kit.reset()
creature.realtime()
H = 0.98
hip_z, sh_z = -0.46, 0.4
neck0 = V(0, H + 0.08, sh_z + 0.07)
neck1 = V(0, H + 0.25, sh_z + 0.2)
headp = V(0, H + 0.37, sh_z + 0.29)
snout = headp + V(0, -0.16, 0.36)
tb = V(0, H + 0.02, hip_z - 0.1)
tail = [tb + V(0, -0.14 * k + 0.012 * k * k, -0.06 * k) for k in range(6)]
sk = quad_skel(H=H, hip_z=hip_z, sh_z=sh_z, hip_w=0.12, sh_w=0.115, foot="hoof", withers=0.08, neck=(neck1, headp), head=snout, tail=tail)
HC = headp + V(0, -0.02, 0.09)
hf = A.HeadFrame(HC, V(0, -0.42, 1.0))
K = 1.2


def hp(x, y, z):
    return hf.at(x * K, y * K, z * K)


ears = [(hp(0.055, 0.04, -0.05), hp(0.12, 0.03, -0.09)), (hp(-0.055, 0.04, -0.05), hp(-0.12, 0.03, -0.09))]
r, legs = quad_rig2(sk, ears=ears)
r.bones["jaw"] = (hp(0, -0.04, -0.01), hp(0, -0.06, 0.2), "head")
b = Builder("qilin")

# ---------------------------------------------------------------- body
c = Clay(0.016, "qilin_body")
NECK = [V(0, H + 0.02, sh_z), neck0.lerp(neck1, 0.6) + V(0, 0, -0.01), headp + V(0, -0.03, 0.0)]
A.clay_torso(c, sk, w=0.21, d=0.3, haunch=(0.2, 0.21, 0.21), tuck=0.06, withers=0.12, neck=[0.19, 0.15, 0.11], throat=0.12, chest_y=0.76, neck_pts=NECK)
for sd in ("L", "R"):
    A.clay_foreleg(c, sk, sd, g=0.72, foot="hoof", paw=0.95)
    A.clay_hindleg(c, sk, sd, g=0.76, foot="hoof", paw=0.95)
A.clay_tail(c, sk, [0.04, 0.032, 0.026, 0.022, 0.02, 0.018])
# the dragon's head: a long face, heavy ridges over the eyes, full cheeks, the long muzzle ending
# in a broad upturned nose with flared nostrils; lip skirts the jaw closes under
A.head_clay(c, hf, K, [
    ("ell", (0, 0.03, -0.025), (0.068, 0.062, 0.075), "head", False, False),
    ("ell", (0.044, 0.056, 0.05), (0.03, 0.022, 0.045), "head", True, False),
    ("ell", (0.048, -0.02, 0.02), (0.04, 0.042, 0.05), "head", True, False),
    ("ell", (0, 0.0, 0.1), (0.042, 0.048, 0.075), "muzzle", False, False),
    ("ell", (0, -0.008, 0.17), (0.036, 0.042, 0.055), "muzzle", False, False),
    ("ell", (0, 0.016, 0.218), (0.046, 0.034, 0.032), "nose", False, False),
    ("ball", (0.024, 0.032, 0.222), 0.018, "nose", True, False),
    ("ell", (0.022, -0.032, 0.14), (0.02, 0.02, 0.08), "lip", True, False),
    ("ell", (0.05, 0.024, 0.065), (0.024, 0.017, 0.018), "head", True, True),
    ("ball", (0.026, 0.036, 0.236), 0.009, "nose", True, True),
])


def head_local(p):
    return hf.M.transposed() @ (p - HC) / K


# ---------------------------------------------------------------- carp scales that follow the body
def scale_uv(p, tag, t):
    """(u, v, size) of the scale pattern at p: u runs back along the body (or down the neck and
    legs), v round it.  Returns None where there are no scales."""
    if tag in ("body", "neck"):
        if tag == "neck":
            u = (sh_z + 0.25 - p.z) * 0.6 + (H + 0.4 - p.y) * 0.9
            size = 0.095
        else:
            u = (sh_z + 0.15 - p.z)
            size = 0.13
        v = p.y + 0.35 * abs(p.x)
        return u, v, size
    if tag == "leg":
        return (sh_z - p.z) if p.z > 0.0 else (-p.z), p.y + 0.3 * abs(p.x), 0.1
    if tag in ("fleg", "hleg") and t < 1.2:
        return t * 0.3, p.y, 0.08
    return None


def scale_at(p, info):
    """Where p falls among the scales: rows of round scales, each overlapping half of the row
    behind it (the classic dragon-scale scallops).  Returns (d, row) with d the distance from
    the scale's root, 0.5 on its free edge."""
    g = scale_uv(p, info.tag, info.t)
    if g is None:
        return None
    u, v, size = g
    sy = u / size
    sx = v / size + 0.5 * (math.floor(sy) % 2)
    fx = sx - math.floor(sx)
    fy = sy - math.floor(sy)
    d = math.hypot(fx - 0.5, fy)
    return d, fy


def under_k(p, info):
    n = info.n
    under = smooth(-0.2, -0.6, n.y)
    if info.tag == "neck":
        under = max(under, smooth(0.2, -0.3, n.y) * smooth(0.2, 0.8, n.z))
    return under


def col(p, info):
    tag = info.tag
    n = info.n
    if tag in ("head", "muzzle", "nose", "lip"):
        q = head_local(p)
        v = 0.78 - 0.08 * smooth(0.0, 0.06, q.y)
        # the throat, the lips and the chin pale
        v = v * (1.0 - smooth(-0.015, -0.04, q.y)) + 0.94 * smooth(-0.015, -0.04, q.y)
        if tag == "nose":
            v = 0.7
        return (v, v, v)
    if tag == "fetlock":
        return (0.5, 0.5, 0.5)
    if tag == "tail":
        return (0.74, 0.74, 0.74)
    under = under_k(p, info)
    v = 0.78 - 0.14 * smooth(0.2, 0.9, n.y)
    sc = scale_at(p, info) if under < 0.6 else None
    if sc is not None:
        d, fy = sc
        # each scale catches the light at its root and darkens towards its free edge
        v = v * (1.0 - 0.2 * smooth(0.12, 0.48, d))
    if tag in ("fleg", "hleg"):
        v -= 0.08 * smooth(1.2, 2.2, info.t)
    if under > 0.0:
        # pale plates along the belly
        z = p.z if tag != "neck" else p.y
        band = smooth(0.62, 0.78, 0.5 + 0.5 * math.cos(z * 48.0))
        belly = 0.95 - 0.12 * band
        v = v * (1.0 - under) + belly * under
    return (v, v, v)


def tint(p, info):
    cc = col(p, info)[0]
    return 1.0 - 0.6 * smooth(0.88, 0.97, cc)


def shingle(p, info):
    """The scales stand a little proud, each a low dome over the next, so they read as scales."""
    if under_k(p, info) > 0.4:
        return None
    sc = scale_at(p, info)
    if sc is None:
        return None
    d, fy = sc
    g = scale_uv(p, info.tag, info.t)
    dome = max(0.0, 1.0 - d / 0.5) ** 0.5 if d < 0.5 else 0.0
    return info.n * (0.1 * g[2] * dome)


c.build(b, col, cls=CLOTH, tint_fn=tint, post=shingle)

# ---------------------------------------------------------------- jaw (closed under the lip), mouth, eyes, ears, horn
hit = A.surface(b)
st = lip_line(hit, hf, K, [0.06, 0.09, 0.12, 0.15, 0.18, 0.2], y_top=-0.01, y_bot=-0.09)
j = Clay(0.01, "qilin_jaw")
for kk, (zq, yb, xb) in enumerate(st):
    f = kk / max(1, len(st) - 1)
    hh = 0.026 * (1.0 - 0.3 * f)
    j.ellipsoid(hp(0, yb - hh * 0.5 + 0.005, zq), (max(0.01, xb - 0.002) * K, hh * 0.5 * K, 0.022 * K), rot=hf.M, bones={"jaw": 1.0}, tag="jaw")
if st:
    z0, y0, x0 = st[0]
    for s in (1, -1):
        j.chain([hp(0.04 * s, -0.045, -0.01), hp(x0 * 0.85 * s, y0 - 0.01, z0)], [0.018 * K, 0.014 * K], bones={"jaw": 1.0}, tag="jaw")


def jaw_dark(p, info):
    return smooth(0.2, 0.5, info.n.dot(hf.u))


j.build(b, lambda p, info: mix((0.94, 0.94, 0.94), (0.42, 0.16, 0.18), jaw_dark(p, info)), cls=CLOTH,
        tint_fn=lambda p, info: 0.6 * (1.0 - jaw_dark(p, info)))
lip0 = st[2][1] if len(st) > 2 else -0.045
b.ellipsoid(hp(0, lip0 + 0.008, 0.11), (0.026 * K, 0.008 * K, 0.08 * K), "3a1418", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
for s in (1, -1):
    A.fang(b, hp(0.02 * s, lip0 + 0.012, 0.19), -hf.u, 0.016 * K, 0.0045 * K, "head", back=-hf.f, curve=0.2)
    A.animal_eye(b, hp(0.052 * s, 0.024, 0.066), hf.f + hf.r * (0.6 * s) + hf.u * 0.12, 0.02 * K, "f0c030", "head", pupil="round", almond=0.62, slant=0.2,
                 side=s, lid="1a1210", lid_w=0.16)
    # the dark nostrils in the flared nose
    b.ellipsoid(hp(0.022 * s, 0.03, 0.24), (0.009 * K, 0.007 * K, 0.006 * K), "1a0e0c", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=8, rings=5,
                mat=MAT_PLAIN)
for s, sd in ((1, "L"), (-1, "R")):
    # ox ears, held out to the sides behind the horn
    A.ear(b, hp(0.055 * s, 0.04, -0.05), hf.r * s + hf.f * 0.5, 0.08 * K, 0.045 * K, 0.022 * K, (0.7, 0.7, 0.7), (0.95, 0.9, 0.88), "ear." + sd,
          up=hf.u * 0.3 + hf.r * s - hf.f * 0.4, point=0.7, cup=0.5, tint=1.0, tint_in=0.3, side=s)
# ---------------------------------------------------------------- mane, beard, whiskers, plume (the secondary colour)
b.cur_pal = 0.5
hit = A.surface(b)
crest_a = hp(0, 0.05, -0.08)
crest_b = V(0, H + 0.12, sh_z - 0.08)
for i in range(17):
    t = i / 16
    q = crest_a.lerp(crest_b, t)
    h = hit(q + V(0, 0.6, 0), V(0, -1, 0))
    if h is None:
        continue
    root, nrm = h
    sgn = 1 if i % 2 else -1
    shade = 0.8 - 0.12 * (i % 3) / 2
    bone = "head" if t < 0.1 else ({"neck1": 0.7, "neck0": 0.3} if t < 0.45 else ({"neck0": 0.8, "chest": 0.2} if t < 0.8 else {"chest": 1.0}))
    # each lock curls like a flame: out to the side, back, and up at its end
    groom = V(0.55 * sgn, 0.35, -1.0).normalized()
    ln = 0.22 - 0.06 * t
    A.blade(b, root - nrm * 0.015, root + groom * ln, 0.075 - 0.02 * t, (shade,) * 3, (min(1.0, shade + 0.14),) * 3, side=V(0, 1, 0).cross(groom).normalized(),
            bone=bone, curl=0.22 * sgn, thick=0.3, tint=1.0, cls=CLOTH, point=0.85)
# the beard under the chin and two long whiskers sweeping back from the upper lip
for k in range(3):
    u = (k - 1) * 0.9
    r0 = hp(0.014 * u, -0.066, 0.15 - 0.03 * abs(u))
    dd = (-hf.u * 0.85 - hf.f * 0.35 + hf.r * 0.15 * u).normalized()
    A.blade(b, r0, r0 + dd * 0.13, 0.04, (0.8,) * 3, (0.92,) * 3, side=hf.r, bone="jaw", curl=0.15, thick=0.3, tint=1.0, cls=CLOTH, point=0.85)
b.cur_pal = 0.0
b.cur_pal = 0.5
for s in (1, -1):
    # the whiskers: long, smooth, sweeping out and back from the upper lip and curling at the ends
    w0 = hp(0.03 * s, -0.012, 0.212)
    w = [w0, w0 + hf.r * (0.04 * s) - hf.u * 0.03, w0 + hf.r * (0.07 * s) - hf.u * 0.08 - hf.f * 0.03,
         w0 + hf.r * (0.08 * s) - hf.u * 0.12 - hf.f * 0.01, w0 + hf.r * (0.1 * s) - hf.u * 0.13 + hf.f * 0.03]
    A.horn(b, w, 0.008, (0.8, 0.8, 0.8), (0.92, 0.92, 0.92), "head", r1=0.0015, seg=6, per=5, cls=CLOTH, tint=1.0)
b.cur_pal = 0.0
# the ox's tail ends in a curling plume
b.cur_pal = 0.5
tl = sk.tail
for k in range(7):
    a = k / 7 * 2 * math.pi
    out = V(math.cos(a), 0, math.sin(a))
    dd = (V(0, -1, 0) + out * 0.45).normalized()
    A.blade(b, tl[-2] + out * 0.02, tl[-2] + out * 0.02 + dd * 0.26, 0.07, (0.75,) * 3, (0.9,) * 3, side=V(0, 1, 0).cross(out).normalized(), bone="tail4",
            curl=0.25, thick=0.3, tint=1.0, cls=CLOTH, point=0.85)
b.cur_pal = 0.0

# the single horn: ridged keratin swept back over the crown, the qilin's focal point
horn = [hp(0, 0.07, 0.03), hp(0, 0.125, 0.0), hp(0, 0.165, -0.07), hp(0, 0.18, -0.15), hp(0, 0.17, -0.22)]
b.cur_pal = 1.0
A.horn(b, horn, 0.022 * K, "b0b0b0", "ffffff", "head", r1=0.003, rings=6, ring_k=0.18, ridge=0.08, seg=12, tint=1.0)
b.cur_pal = 0.0

# ---------------------------------------------------------------- hooves and flames at the elbows and hocks
for sd, s in (("L", 1), ("R", -1)):
    for pre, fb, ft in (("f", "fb", "ft"), ("h", "hb", "ht")):
        p1 = sk[ft + "." + sd]
        A.hoof(b, V(p1.x, 0.0, p1.z - 0.03), V(0, 0, 1), 0.048, 0.07, "2a2420", pre + "_toe." + sd, cloven=True, col_top="4a3a30")
    for jn, bone in ((sk["el." + sd], "f_lo." + sd), (sk["hk." + sd], "h_meta." + sd)):
        for k in range(2):
            base = jn + V(0.03 * s, 0.02 * k, -0.04)
            flame(b, base, V(0.35 * s, 0.6, -0.75).normalized(), 0.13 - 0.03 * k, bone, bend=1.0 if k else -1.0)

# ---------------------------------------------------------------- motion
qm = QuadMotion(r, legs, T_walk=1.4, stride=0.42, lift=0.12, duty=0.62, bob=0.014, roll=0.025, yaw=0.04, head_nod=0.06, head_low=-0.05,
                neck_up=0.05, tail_amp=0.15, tail_lift=0.0, tail_droop=0.1, pounce="rear", T_idle=4.0, front_flex=1.6, hind_flex=0.8,
                rest_h=0.21, lunge=0.3)
raw_idle, raw_walk = qm.idle, qm.walk


def shut_idle(t):
    p = raw_idle(t)
    add(p, "jaw", (-0.03, 0.0, 0.0))
    return p


def shut_walk(t):
    p = raw_walk(t)
    add(p, "jaw", (-0.04, 0.0, 0.0))
    return p


qm.idle, qm.walk = shut_idle, shut_walk


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = qm.idle(0.0)
    add(p, "neck0", (-0.4 * e, 0, 0))
    add(p, "head", (-0.35 * e, 0, 0))
    add(p, "jaw", (0.35 * e, 0, 0))
    return p


print("[art] qilin: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/qilin.glb", qm.clips({"cast": (0.6, cast)}), samples=16, dist=0.3, strength=0.5, floor_y=0.0)
