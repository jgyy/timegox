"""Ape (new in Part VIII): the great apes of the cloud cliffs (Cloud Ape, Magpie-Bridge Gibbon King,
the White Ape Who Stole the Sword Manual, the Thunder and Storm Ape Kings).

A silverback gorilla rather than a man in fur (after gorilla anatomy: arms longer than the legs -
an intermembral index near 116 against a man's 72 - and the knuckle-walking stance):

* **Silhouette.**  The weight is on the knuckles, the forelimbs columnar and long, so the back
  slopes steeply down from a great hump of shoulders and trapezius to a low rump; the head hangs
  low and forward in front of that hump with no neck to speak of; the hind legs are short, bent
  and bowed, on flat feet with the big toe set apart.
* **Masses.**  A barrel chest and a round belly; huge deltoids; an upper arm and forearm that are
  thick (the forearm is thickest just below the elbow) and taper to a broad hand resting on the
  backs of its curled fingers.
* **Head.**  A conical, high-domed skull rising to the sagittal crest of a male; a shelf of a
  brow ridge over small, deep-set eyes; a broad flat nose with flaring nostrils inside a ridge;
  a protruding muzzle and a wide, closed mouth; small ears close to the head.
* **Value.**  The bare face, chest, palms and soles are dark skin (keeping their colour); the
  coat is darker on the arms and legs, with a pale silver saddle across the lower back and a
  reddish crown (the secondary colour), and long hair hanging from the forearms and shoulders.

Clips: idle (breathing, looking about), walk (a diagonal-sequence knuckle-walk), attack (rears up
and hammers both fists down), hurt, die and cast (rises and beats its chest).
Run: blender --background --python art/monsters/ape.py  ->  assets/monsters/ape.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from creature import QuadMotion, add, quad_rig2, quad_skel, smooth  # noqa: E402
from kit import CLOTH, MAT_PLAIN, SKIN, V, Builder, mix  # noqa: E402
from mammal import lip_line  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
SKINC = (0.5, 0.42, 0.4)
sk = quad_skel(H=1.0, hip_z=-0.17, sh_z=0.3, hip_w=0.16, sh_w=0.32, foot="plant", tail=[])
for sd, s in (("L", 1), ("R", -1)):
    # short, bent, bowed legs on flat feet
    sk["hip." + sd] = V(0.16 * s, 0.84, -0.17)
    sk["kn." + sd] = V(0.25 * s, 0.47, 0.02)
    sk["hk." + sd] = V(0.23 * s, 0.11, -0.1)
    sk["hb." + sd] = V(0.23 * s, 0.035, 0.08)
    sk["ht." + sd] = V(0.23 * s, 0.02, 0.18)
    # long columnar arms on the knuckles, the hands a little ahead of the shoulders
    sk["sc." + sd] = V(0.16 * s, 1.42, 0.2)
    sk["sh." + sd] = V(0.33 * s, 1.26, 0.32)
    sk["el." + sd] = V(0.41 * s, 0.76, 0.31)
    sk["wr." + sd] = V(0.41 * s, 0.25, 0.43)
    sk["fb." + sd] = V(0.41 * s, 0.06, 0.47)
    sk["ft." + sd] = V(0.41 * s, 0.03, 0.4)
sk["body"] = V(0, 1.02, 0.05)
sk["loin"] = V(0, 0.94, -0.07)
sk["pelvis"] = V(0, 0.87, -0.17)
sk["chest"] = V(0, 1.2, 0.2)
sk["neck0"] = V(0, 1.31, 0.36)
sk["neck1"] = V(0, 1.34, 0.45)
sk["head"] = V(0, 1.35, 0.5)
sk["snout"] = V(0, 1.27, 0.78)
HC = V(0, 1.37, 0.57)
hf = A.HeadFrame(HC, V(0, -0.12, 1.0))
K = 1.18


def hp(x, y, z):
    return hf.at(x * K, y * K, z * K)


ears = [(hp(0.1, 0.0, -0.04), hp(0.12, 0.05, -0.05)), (hp(-0.1, 0.0, -0.04), hp(-0.12, 0.05, -0.05))]
r, legs = quad_rig2(sk, ears=ears)
r.bones["jaw"] = (hp(0, -0.06, -0.01), hp(0, -0.1, 0.13), "head")
# primates walk in a diagonal sequence: hind left, fore right, hind right, fore left
for leg in legs:
    leg.td = {(True, 1): 0.75, (False, 1): 0.0, (True, -1): 0.25, (False, -1): 0.5}[(leg.front, leg.side)]
b = Builder("ape")

# ---------------------------------------------------------------- body
c = Clay(0.019, "ape_body")
c.ellipsoid(V(0, 0.87, -0.17), (0.21, 0.17, 0.17), bones={"pelvis": 1.0}, tag="body")
c.ellipsoid(V(0, 0.9, 0.0), (0.25, 0.23, 0.23), bones={"loin": 0.5, "body": 0.5}, tag="belly")
c.ellipsoid(V(0, 1.1, 0.2), (0.3, 0.27, 0.25), rot=(-0.55, 0, 0), bones={"chest": 0.7, "body": 0.3}, tag="chest")
# the hump of the shoulders and the trapezius rising to the back of the skull
c.ellipsoid(V(0, 1.34, 0.22), (0.27, 0.15, 0.22), rot=(-0.25, 0, 0), bones={"chest": 1.0}, tag="body")
c.ellipsoid(V(0, 1.38, 0.36), (0.17, 0.12, 0.13), rot=(-0.4, 0, 0), bones={"chest": 0.5, "neck0": 0.5}, tag="body")
c.chain([V(0, 1.27, 0.3), V(0, 1.33, 0.42), HC + V(0, -0.03, -0.06)], [0.16, 0.13, 0.1],
        bones=lambda p, t: {"chest": 1.0 - t * 0.5, "neck0": t * 0.5} if t < 1.0 else {"neck0": 2.0 - t, "neck1": t - 1.0}, tag="body", t0=0.0, t1=2.0)
for sd, s in (("L", 1), ("R", -1)):
    sb = "shoulder." + sd
    up, lo, mt, tb = "f_up." + sd, "f_lo." + sd, "f_meta." + sd, "f_toe." + sd
    sh, el, wr, fb, ft = (sk[k + "." + sd] for k in ("sh", "el", "wr", "fb", "ft"))
    # the deltoid, the heavy upper arm, a forearm thickest below the elbow
    c.ball(sh + V(0.025 * s, 0.03, 0.0), 0.155, bones={sb: 0.5, up: 0.5}, tag="body")
    c.ellipsoid(sh.lerp(el, 0.42) + V(0.0, 0, -0.02), (0.12, 0.2, 0.125), rot=(0.02, 0, 0), bones={up: 1.0}, tag="arm")
    c.chain([sh, el, wr], [0.115, 0.088, 0.062], bones=limb_weights([up, lo]), tag="arm", t0=0.0, t1=2.0)
    c.ellipsoid(el.lerp(wr, 0.26) + V(0.012 * s, 0, 0.012), (0.105, 0.18, 0.1), rot=(0.2, 0, 0), bones={lo: 1.0}, tag="arm", t=1.3)
    # the hand on its knuckles: the back of the hand down to the knuckles, the bare fingers
    # folded under it and showing in front, the thumb along the side
    c.ellipsoid(wr.lerp(fb, 0.5) + V(0, 0, 0.005), (0.07, 0.11, 0.06), rot=(0.18, 0, 0), bones={mt: 1.0}, tag="hand_back")
    c.ellipsoid(fb + V(0, 0.028, 0.012), (0.074, 0.038, 0.045), bones={tb: 1.0}, tag="hand")
    for k in range(4):
        u = (k / 3 - 0.5) * 2
        c.ellipsoid(fb + V(u * 0.03, 0.025, 0.03 - abs(u) * 0.006), (0.019, 0.026, 0.026), bones={tb: 1.0}, tag="hand")
    c.ellipsoid(wr.lerp(fb, 0.75) + V(-0.06 * s, 0.0, 0.03), (0.018, 0.04, 0.02), rot=(0.4, 0, 0.3 * s), bones={mt: 1.0}, tag="hand")
    hip, kn, hk, hb, ht = (sk[k + "." + sd] for k in ("hip", "kn", "hk", "hb", "ht"))
    up, lo, mt, tb = "h_up." + sd, "h_lo." + sd, "h_meta." + sd, "h_toe." + sd
    # short, bowed legs: a thick thigh, the calf, a long flat foot with the big toe apart
    c.ellipsoid(hip.lerp(kn, 0.45) + V(0.025 * s, 0.0, -0.01), (0.115, 0.19, 0.13), rot=(-0.55, 0, 0.15 * s), bones={up: 0.8, "pelvis": 0.2}, tag="leg")
    c.chain([hip, kn, hk], [0.115, 0.085, 0.062], bones=limb_weights([up, lo]), tag="leg", t0=0.0, t1=2.0)
    c.ellipsoid(kn.lerp(hk, 0.32) + V(0, 0.0, -0.035), (0.075, 0.13, 0.075), rot=(0.25, 0, 0), bones={lo: 1.0}, tag="leg")
    c.ellipsoid(hk.lerp(hb, 0.55) + V(0, -0.03, 0.0), (0.07, 0.04, 0.13), bones={mt: 1.0}, tag="foot")
    for k in range(4):
        u = (k / 3 - 0.5) * 2
        c.ellipsoid(hb.lerp(ht, 0.6) + V(u * 0.028 - 0.008 * s, 0.0, -abs(u) * 0.012), (0.017, 0.016, 0.045), bones={tb: 1.0}, tag="foot")
    c.ellipsoid(hk.lerp(hb, 0.62) + V(-0.075 * s, -0.035, 0.03), (0.022, 0.02, 0.055), rot=(0, -0.6 * s, 0), bones={mt: 1.0}, tag="foot")
# long hair hanging from the backs of the forearms and the shoulders, sculpted into the coat
for sd, s in (("L", 1), ("R", -1)):
    el, wr, sh = sk["el." + sd], sk["wr." + sd], sk["sh." + sd]
    for k in range(3):
        a = el.lerp(wr, 0.05 + 0.25 * k) + V(0.045 * s, 0.0, -0.06)
        c.chain([a, a + V(0.03 * s, -0.12, -0.06)], [0.06, 0.035], bones={"f_lo." + sd: 1.0}, tag="arm", t0=1.2, t1=1.4)
    for k in range(2):
        a = sh + V(0.1 * s, -0.04 - 0.12 * k, -0.06)
        c.chain([a, a + V(0.05 * s, -0.14, -0.04)], [0.075, 0.04], bones={"f_up." + sd: 1.0}, tag="arm", t0=0.4, t1=0.6)
    hip, kn = sk["hip." + sd], sk["kn." + sd]
    a = hip.lerp(kn, 0.5) + V(0.06 * s, 0.0, -0.1)
    c.chain([a, a + V(0.02 * s, -0.13, -0.06)], [0.07, 0.04], bones={"h_up." + sd: 1.0}, tag="leg", t0=0.5, t1=0.7)
# the head: a conical skull rising to the crest, the shelf of the brow, the cheeks, the
# protruding muzzle with the broad flat nose, sockets pressed in under the brow
A.head_clay(c, hf, K, [
    ("ell", (0, 0.02, -0.03), (0.098, 0.1, 0.1), "head", False, False),
    ("ell", (0, 0.105, -0.05), (0.032, 0.075, 0.085), "crest", False, False),
    ("ell", (0, 0.06, -0.035), (0.075, 0.07, 0.085), "crest", False, False),
    ("ell", (0, 0.05, 0.078), (0.1, 0.03, 0.036), "face", False, False),
    ("ell", (0.072, -0.02, 0.035), (0.045, 0.05, 0.05), "head", True, False),
    ("ell", (0, -0.055, 0.088), (0.084, 0.058, 0.07), "face", False, False),
    ("ell", (0.036, -0.09, 0.095), (0.05, 0.024, 0.06), "lip", True, False),
    ("ell", (0, -0.015, 0.128), (0.048, 0.042, 0.03), "nose", False, False),
    ("ell", (0.04, 0.012, 0.1), (0.026, 0.02, 0.024), "face", True, True),
])


def head_local(p):
    return hf.M.transposed() @ (p - HC) / K


def bare(p, info):
    """How much of the skin here is bare (the face, the chest, palms, soles)."""
    tag = info.tag
    if tag in ("face", "nose", "lip", "hand", "foot"):
        return 1.0
    if tag in ("head", "crest"):
        q = head_local(p)
        # the bare face reaches back under the brow and round the eyes
        return smooth(0.03, 0.06, q.z) * smooth(0.06, 0.02, q.y)
    if tag == "chest":
        return smooth(0.25, 0.45, info.n.z) * smooth(0.6, 0.3, info.n.y) * smooth(0.18, 0.1, abs(p.x))
    return 0.0


def col(p, info):
    tag = info.tag
    n = info.n
    g = fbm3((p.x * 6.0, p.y * 6.0, p.z * 6.0), 2, 3)
    if tag == "crest":
        v = 0.74
    else:
        # the silver saddle across the lower back and the rump
        saddle = smooth(0.1, 0.7, n.y) * smooth(1.25, 1.0, p.y) * smooth(-0.36, -0.1, p.z) * (1.0 - smooth(0.08, 0.3, p.z))
        v = 0.64 + 0.05 * (g - 0.5)
        if tag in ("arm", "leg", "hand_back"):
            v = 0.6 + 0.05 * (g - 0.5)          # the limbs a shade darker
        if tag in ("body", "chest", "belly"):
            v -= 0.04 * smooth(0.5, 1.0, n.y) * (1.0 - saddle)
        v = v * (1.0 - saddle) + 0.76 * saddle
    sk_ = bare(p, info)
    if sk_ > 0.0:
        cc = SKINC
        if tag == "lip":
            cc = (0.34, 0.28, 0.27)
        elif tag == "nose":
            cc = (0.38, 0.32, 0.31)
        return mix((v, v, v), cc, sk_)
    return (v, v, v)


def pal(p, info):
    # a reddish crown (the secondary colour), as on a western gorilla
    if info.tag == "crest" and bare(p, info) < 0.5:
        return 0.5
    return 0.0


def tint(p, info):
    return 1.0 - bare(p, info)


def shag(p, info):
    """The coat hangs in soft clumps groomed downwards (none on bare skin)."""
    if bare(p, info) > 0.3 or info.tag in ("hand", "foot"):
        return None
    nn = info.n
    w = fbm3((p.x * 7.0, p.y * 7.0, p.z * 7.0), 2, 5)
    u = p.y * 11.0 + 0.4 * math.sin(math.atan2(nn.x, nn.z) * 7.0) + 0.9 * w
    k = u - math.floor(u)
    return nn * (0.011 * math.sin(math.pi * k) ** 2)


c.build(b, col, cls=CLOTH, tint_fn=tint, post=shag, pal_fn=pal)

# ---------------------------------------------------------------- the lower jaw, fitted under the upper lip, the mouth closed
hit = A.surface(b)
st = lip_line(hit, hf, K, [0.04, 0.07, 0.1, 0.125, 0.145], x_out=0.3, y_top=-0.04, y_bot=-0.16)
j = Clay(0.012, "ape_jaw")
for kk, (zq, yb, xb) in enumerate(st):
    f = kk / max(1, len(st) - 1)
    hh = 0.04 * (1.0 - 0.25 * f)
    j.ellipsoid(hp(0, yb - hh * 0.5 + 0.01, zq), (max(0.03, xb - 0.003), hh * 0.5, 0.03), rot=hf.M, bones={"jaw": 1.0}, tag="jaw")
if st:
    zl, yl, xl = st[-1]
    j.ellipsoid(hp(0, yl - 0.022, zl - 0.03), (0.04, 0.02, 0.024), rot=hf.M, bones={"jaw": 1.0}, tag="jaw")


def jaw_col(p, info):
    # dark lips and a dark mouth inside
    return mix(SKINC, (0.2, 0.15, 0.15), smooth(0.3, 0.7, info.n.dot(hf.u)))


j.build(b, jaw_col, cls=SKIN)
lip0 = st[1][1] if len(st) > 1 else -0.1
b.ellipsoid(hp(0, lip0 + 0.012, 0.08), (0.06, 0.012, 0.05), "2a1014", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
for s in (1, -1):
    A.fang(b, hp(0.032 * s, lip0 + 0.02, 0.11), -hf.u, 0.026, 0.008, "head", back=-hf.f, curve=0.15)
    # small deep-set eyes under the brow, wide nostrils on the flat nose
    A.animal_eye(b, hp(0.04 * s, 0.014, 0.108), hf.f + hf.r * (0.15 * s), 0.0135, "6a3a18", "head", pupil="round", almond=0.72, side=s, lid="0e0808",
                 lid_w=0.16)
    b.ellipsoid(hp(0.017 * s, -0.012, 0.152), (0.014, 0.01, 0.008), "0a0606", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=8, rings=4, mat=MAT_PLAIN)
for s, sd in ((1, "L"), (-1, "R")):
    A.ear(b, hp(0.098 * s, 0.0, -0.035), hf.r * s + hf.f * 0.3, 0.045, 0.036, 0.018, SKINC, (0.3, 0.22, 0.2), "ear." + sd, up=hf.u, point=0.0, cup=0.4,
          tint=0.0, tint_in=0.0, side=s)

# ---------------------------------------------------------------- long hair: forearms and shoulders
# ---------------------------------------------------------------- motion
qm = QuadMotion(r, legs, T_walk=1.6, stride=0.4, lift=0.1, duty=0.62, bob=0.02, crouch=0.04, roll=0.06, yaw=0.08, head_nod=0.04, head_low=0.0,
                tail_amp=0.0, pounce="bite", T_idle=4.0, front_flex=0.45, hind_flex=0.4, rest_h=0.3, lunge=0.3, ear_flick=0.0)
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


def attack(t):
    """Rear up on the hind legs, both fists raised overhead, and hammer them down."""
    k = t / 0.55
    up = smooth(0.0, 0.35, k) * (1.0 - smooth(0.36, 0.56, k))
    slam = smooth(0.38, 0.56, k) * (1.0 - smooth(0.75, 1.0, k))
    p = qm.zero()
    add(p, "root", (0, 0, 0), (0, 0.04 * up, 0.07 * slam))
    add(p, "body", (-0.45 * up + 0.25 * slam, 0, 0))
    add(p, "chest", (-0.2 * up + 0.2 * slam, 0, 0))
    add(p, "neck0", (0.35 * up - 0.2 * slam, 0, 0))
    add(p, "jaw", (0.5 * (up + slam), 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "f_up." + sd, (-2.4 * up + 0.4 * slam, 0, -0.25 * s * up))
        add(p, "f_lo." + sd, (-0.6 * up - 0.2 * slam, 0, 0))
        add(p, "f_meta." + sd, (0.6 * up, 0, 0))
    D_hind = [(0.07 * slam, 0.0) if not leg.front else (0.0, 0.0) for leg in legs]
    p2 = qm.plant(dict(p), D_hind)
    for leg in legs:
        if not leg.front:
            for nm in leg.chain:
                p[nm] = p2[nm]
    return p


def cast(t):
    """Rise up and beat the chest, roaring."""
    k = t / 0.6
    e = math.sin(math.pi * min(1.0, k))
    beat = math.sin(k * math.pi * 6.0)
    p = qm.zero()
    add(p, "body", (-0.5 * e, 0, 0))
    add(p, "neck0", (-0.2 * e, 0, 0))
    add(p, "head", (-0.2 * e, 0, 0))
    add(p, "jaw", (0.7 * e, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "f_up." + sd, (-1.3 * e, 0, (0.5 + 0.2 * beat * s) * s * e))
        add(p, "f_lo." + sd, (-1.5 * e, 0, 0))
    D_hind = [(0.0, 0.0) for leg in legs]
    p2 = qm.plant(dict(p), D_hind)
    for leg in legs:
        if not leg.front:
            for nm in leg.chain:
                p[nm] = p2[nm]
    return p


clips = qm.clips({"attack": (0.55, attack), "cast": (0.6, cast)})
print("[art] ape: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/ape.glb", clips, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
