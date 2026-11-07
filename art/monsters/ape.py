"""Ape (new in Part VIII): the great apes of the cloud cliffs (Cloud Ape, Magpie-Bridge Gibbon King,
the White Ape Who Stole the Sword Manual, the Thunder and Storm Ape Kings).

Great-ape anatomy rather than a man in fur, sculpted in clay (art/lib/clay.py): it stands with its
weight forward on its knuckles, the arms much longer than the legs; a barrel chest and a round
belly, massive shoulders with the trapezius rising into a short neck; short bowed legs on flat,
hand-like feet with the big toe set apart.  The head carries a sagittal crest and a heavy brow
ridge over small deep-set eyes, a broad flat nose and a protruding muzzle; the face, chest, palms
and soles are bare dark skin (keeping their colour), the coat takes the enemy's colour with a
silver saddle across the back and long hair hanging from the forearms and shoulders.
Clips: idle (breathing, looking about), walk (a diagonal-sequence knuckle-walk), attack (rears
up and hammers both fists down), hurt, die and cast (rises and beats its chest).
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
from kit import CLOTH, HAIR, MAT_PLAIN, SKIN, V, Builder, mix  # noqa: E402
from sculpt import fbm3  # noqa: E402

kit.reset()
creature.realtime()
SKINC = (0.34, 0.28, 0.26)
sk = quad_skel(H=1.1, hip_z=-0.12, sh_z=0.28, hip_w=0.17, sh_w=0.34, foot="plant", tail=[])
for sd, s in (("L", 1), ("R", -1)):
    sk["hip." + sd] = V(0.17 * s, 0.82, -0.12)
    sk["kn." + sd] = V(0.25 * s, 0.48, 0.05)
    sk["hk." + sd] = V(0.23 * s, 0.12, -0.08)
    sk["hb." + sd] = V(0.23 * s, 0.035, 0.1)
    sk["ht." + sd] = V(0.23 * s, 0.02, 0.19)
    sk["sc." + sd] = V(0.17 * s, 1.36, 0.26)
    sk["sh." + sd] = V(0.36 * s, 1.24, 0.4)
    sk["el." + sd] = V(0.45 * s, 0.78, 0.44)
    sk["wr." + sd] = V(0.45 * s, 0.28, 0.56)
    sk["fb." + sd] = V(0.45 * s, 0.05, 0.6)
    sk["ft." + sd] = V(0.45 * s, 0.03, 0.52)
sk["body"] = V(0, 1.06, 0.08)
sk["loin"] = V(0, 0.96, -0.04)
sk["pelvis"] = V(0, 0.86, -0.12)
sk["chest"] = V(0, 1.25, 0.28)
sk["neck0"] = V(0, 1.36, 0.42)
sk["neck1"] = V(0, 1.41, 0.5)
sk["head"] = V(0, 1.44, 0.56)
sk["snout"] = V(0, 1.4, 0.84)
HC = V(0, 1.47, 0.64)
hf = A.HeadFrame(HC, V(0, -0.15, 1.0))
K = 1.0


def hp(x, y, z):
    return hf.at(x * K, y * K, z * K)


ears = [(hp(0.12, 0.0, -0.03), hp(0.14, 0.04, -0.04)), (hp(-0.12, 0.0, -0.03), hp(-0.14, 0.04, -0.04))]
r, legs = quad_rig2(sk, ears=ears)
r.bones["jaw"] = (hp(0, -0.06, 0.0), hp(0, -0.11, 0.15), "head")
# primates walk in a diagonal sequence: hind left, fore right, hind right, fore left
for leg in legs:
    leg.td = {(True, 1): 0.75, (False, 1): 0.0, (True, -1): 0.25, (False, -1): 0.5}[(leg.front, leg.side)]
b = Builder("ape")

# ---------------------------------------------------------------- body
c = Clay(0.02, "ape_body")
c.ellipsoid(V(0, 0.9, -0.1), (0.23, 0.18, 0.18), bones={"pelvis": 1.0}, tag="body")
c.ellipsoid(V(0, 0.98, 0.06), (0.27, 0.23, 0.24), bones={"loin": 0.5, "body": 0.5}, tag="belly")
c.ellipsoid(V(0, 1.16, 0.26), (0.35, 0.26, 0.28), rot=(-0.7, 0, 0), bones={"chest": 0.7, "body": 0.3}, tag="chest")
c.ellipsoid(V(0, 1.33, 0.28), (0.3, 0.15, 0.22), rot=(-0.3, 0, 0), bones={"chest": 1.0}, tag="body")
c.chain([V(0, 1.32, 0.38), V(0, 1.39, 0.5), HC + V(0, -0.02, -0.04)], [0.17, 0.14, 0.1], bones=lambda p, t: {"chest": 1.0 - t * 0.5, "neck0": t * 0.5} if t < 1.0 else {"neck0": 2.0 - t, "neck1": t - 1.0}, tag="body", t0=0.0, t1=2.0)
for sd, s in (("L", 1), ("R", -1)):
    sb = "shoulder." + sd
    up, lo, mt, tb = "f_up." + sd, "f_lo." + sd, "f_meta." + sd, "f_toe." + sd
    sh, el, wr, fb, ft = (sk[k + "." + sd] for k in ("sh", "el", "wr", "fb", "ft"))
    # deltoid and the long, heavy arm: biceps and triceps, a forearm thick below the elbow
    c.ball(sh + V(0.02 * s, 0.03, 0.0), 0.16, bones={sb: 0.5, up: 0.5}, tag="body")
    c.ellipsoid(sh.lerp(el, 0.45) + V(0, 0, -0.03), (0.13, 0.2, 0.13), rot=(0.1, 0, 0), bones={up: 1.0}, tag="arm")
    c.chain([sh, el, wr], [0.125, 0.1, 0.08], bones=limb_weights([up, lo]), tag="arm", t0=0.0, t1=2.0)
    c.ellipsoid(el.lerp(wr, 0.28) + V(0.01 * s, 0, 0.0), (0.12, 0.19, 0.115), rot=(0.18, 0, 0), bones={lo: 1.0}, tag="arm", t=1.3)
    # the hand on its knuckles: the hairy back of the hand down to the knuckles, the bare black
    # fingers folded under it and showing in front
    c.ellipsoid(wr.lerp(fb, 0.45), (0.075, 0.11, 0.068), rot=(0.1, 0, 0), bones={mt: 1.0}, tag="arm", t=2.5)
    c.ellipsoid(fb + V(0, 0.035, 0.035), (0.072, 0.04, 0.045), bones={tb: 1.0}, tag="hand")
    for k in range(4):
        u = (k / 3 - 0.5) * 2
        c.ellipsoid(fb + V(u * 0.03, 0.03, 0.045), (0.022, 0.028, 0.035), bones={tb: 1.0}, tag="hand")
    hip, kn, hk, hb, ht = (sk[k + "." + sd] for k in ("hip", "kn", "hk", "hb", "ht"))
    up, lo, mt, tb = "h_up." + sd, "h_lo." + sd, "h_meta." + sd, "h_toe." + sd
    # short, bowed legs and a flat, hand-like foot with the big toe apart
    c.ellipsoid(hip.lerp(kn, 0.45) + V(0.03 * s, 0, -0.02), (0.11, 0.17, 0.12), rot=(-0.6, 0, 0.15 * s), bones={up: 0.8, "pelvis": 0.2}, tag="leg")
    c.chain([hip, kn, hk], [0.12, 0.095, 0.07], bones=limb_weights([up, lo]), tag="leg", t0=0.0, t1=2.0)
    c.ellipsoid(kn.lerp(hk, 0.35) + V(0, 0, -0.03), (0.07, 0.12, 0.07), bones={lo: 1.0}, tag="leg")
    c.ellipsoid(hk.lerp(hb, 0.5) + V(0, -0.04, 0), (0.07, 0.04, 0.13), bones={mt: 1.0}, tag="foot")
    for k in range(4):
        u = (k / 3 - 0.5) * 2
        c.ellipsoid(hb.lerp(ht, 0.6) + V(u * 0.03, 0.0, -abs(u) * 0.01), (0.017, 0.016, 0.045), bones={tb: 1.0}, tag="foot")
    c.ellipsoid(hk.lerp(hb, 0.6) + V(-0.07 * s, -0.04, 0.0), (0.02, 0.018, 0.05), rot=(0, -0.7 * s, 0), bones={mt: 1.0}, tag="foot")
# the head: a sagittal crest, a heavy brow ridge, cheek pads, a protruding muzzle
A.head_clay(c, hf, K, [
    ("ell", (0, 0.02, -0.02), (0.11, 0.11, 0.11), "head", False, False),
    ("ell", (0, 0.12, -0.04), (0.03, 0.07, 0.09), "crest", False, False),
    ("ell", (0, 0.05, 0.08), (0.1, 0.035, 0.045), "face", False, False),
    ("ell", (0, -0.04, 0.1), (0.075, 0.06, 0.07), "face", False, False),
    ("ell", (0.08, -0.03, 0.04), (0.04, 0.05, 0.05), "face", True, False),
    ("ell", (0.042, 0.022, 0.11), (0.022, 0.018, 0.02), "face", True, True),
    ("ell", (0, -0.0, 0.15), (0.045, 0.03, 0.03), "face", False, False),
])


def col(p, info):
    tag = info.tag
    n = info.n
    g = fbm3((p.x * 6.0, p.y * 6.0, p.z * 6.0), 2, 3)
    if tag in ("face", "hand", "foot"):
        return SKINC
    if tag == "chest" and n.z > 0.25 and n.y < 0.6:
        return mix(SKINC, (0.7, 0.7, 0.7), smooth(0.45, 0.25, n.z))
    if tag == "crest":
        return (0.6, 0.6, 0.6)
    # the silver saddle across the lower back
    saddle = smooth(0.3, 0.7, n.y) * smooth(1.25, 1.1, p.y) * smooth(-0.3, -0.1, p.z) * (1.0 - smooth(0.15, 0.3, p.z))
    v = 0.7 + 0.08 * (g - 0.5) - 0.1 * smooth(0.6, 1.0, n.y) * (1.0 - saddle)
    v = v * (1.0 - saddle) + 0.96 * saddle
    return (v, v, v)


def tint(p, info):
    if info.tag in ("face", "hand", "foot"):
        return 0.0
    if info.tag == "chest" and info.n.z > 0.25 and info.n.y < 0.6:
        return 1.0 - smooth(0.25, 0.45, info.n.z)
    return 1.0


def shag(p, info):
    """The coat hangs in shingled clumps (none on the bare face, chest, hands and feet)."""
    if info.tag in ("face", "hand", "foot", "crest") or (info.tag == "chest" and info.n.z > 0.2 and info.n.y < 0.6):
        return None
    nn = info.n
    w = fbm3((p.x * 8.0, p.y * 8.0, p.z * 8.0), 2, 5)
    u = p.y * 13.0 + 0.5 * math.sin(math.atan2(nn.x, nn.z) * 6.0) + 1.1 * w
    k = u - math.floor(u)
    return nn * (0.02 * k ** 1.5)


body = c.build(b, col, cls=CLOTH, tint_fn=tint, post=shag)
# a separate lower jaw with a dark lip
j = Clay(0.012, "ape_jaw")
j.ellipsoid(hp(0, -0.1, 0.1), (0.065, 0.035, 0.06), rot=hf.M, bones={"jaw": 1.0}, tag="jaw")
j.build(b, lambda p, info: mix(SKINC, (0.45, 0.15, 0.18), smooth(0.2, 0.5, info.n.dot(hf.u))), cls=SKIN)
b.ellipsoid(hp(0, -0.075, 0.09), (0.05, 0.015, 0.05), "2a1014", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, mat=MAT_PLAIN)
for s in (1, -1):
    A.fang(b, hp(0.032 * s, -0.07, 0.135), -hf.u, 0.035, 0.008, "head", back=-hf.f, curve=0.15)
    A.fang(b, hp(0.03 * s, -0.08, 0.125), hf.u, 0.024, 0.007, "jaw", back=-hf.f, curve=0.1)
    A.animal_eye(b, hp(0.042 * s, 0.022, 0.115), hf.f + hf.r * (0.2 * s), 0.014, "7a4a20", "head", pupil="round", almond=0.8, side=s, lid="100808")
    # wide nostrils on the flat nose
    b.ellipsoid(hp(0.018 * s, -0.005, 0.18), (0.012, 0.008, 0.006), "0a0606", cls=SKIN, bone="head", rot=A.euler_of(hf.M), seg=8, rings=4, mat=MAT_PLAIN)
for s, sd in ((1, "L"), (-1, "R")):
    A.ear(b, hp(0.11 * s, 0.0, -0.03), hf.r * s + hf.f * 0.3, 0.05, 0.04, 0.02, SKINC, (0.32, 0.24, 0.22), "ear." + sd, up=hf.u, point=0.0, cup=0.4, tint=0.0, tint_in=0.0, side=s)

# ---------------------------------------------------------------- long hair: forearms, shoulders, a mop on the crest
hit = A.surface(b)
for sd, s in (("L", 1), ("R", -1)):
    el, wr = sk["el." + sd], sk["wr." + sd]
    for k in range(2):
        q = el + V(0.02 * s, 0.02 - 0.06 * k, -0.06)
        A.lock(b, q, V(0.2 * s, -1.0, -0.4).normalized(), V(s * 0.4, 0, -1), 0.14, 0.07, (0.68,) * 3, (0.78,) * 3, bone={"f_lo." + sd: 0.5, "f_up." + sd: 0.5}, lift=0.2, rise=0.12, thick=0.45, cls=HAIR)
    sh = sk["sh." + sd]
    for k in range(3):
        q = sh + V(0.04 * s, 0.05 - 0.07 * k, -0.04 + 0.02 * k)
        A.lock(b, q, V(0.4 * s, -1.0, -0.2).normalized(), V(s, 0.2, 0), 0.18, 0.07, (0.66,) * 3, (0.76,) * 3, bone={"shoulder." + sd: 0.4, "f_up." + sd: 0.6}, lift=0.2, rise=0.15, thick=0.45, cls=HAIR)

# ---------------------------------------------------------------- motion
qm = QuadMotion(r, legs, T_walk=1.6, stride=0.4, lift=0.1, duty=0.62, bob=0.02, crouch=0.05, roll=0.06, yaw=0.08, head_nod=0.04, head_low=0.0,
                tail_amp=0.0, pounce="bite", T_idle=4.0, front_flex=0.5, hind_flex=0.4, rest_h=0.26, lunge=0.3, ear_flick=0.0)


def attack(t):
    """Rear up on the hind legs, both fists raised overhead, and hammer them down."""
    k = t / 0.55
    up = smooth(0.0, 0.35, k) * (1.0 - smooth(0.36, 0.56, k))
    slam = smooth(0.38, 0.56, k) * (1.0 - smooth(0.75, 1.0, k))
    p = qm.zero()
    add(p, "root", (0, 0, 0), (0, 0.04 * up, 0.07 * slam))
    add(p, "body", (-0.5 * up + 0.25 * slam, 0, 0))
    add(p, "chest", (-0.2 * up + 0.2 * slam, 0, 0))
    add(p, "neck0", (0.4 * up - 0.2 * slam, 0, 0))
    add(p, "jaw", (0.6 * (up + slam), 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        add(p, "f_up." + sd, (-2.5 * up + 0.4 * slam, 0, -0.25 * s * up))
        add(p, "f_lo." + sd, (-0.6 * up - 0.2 * slam, 0, 0))
        add(p, "f_meta." + sd, (0.6 * up, 0, 0))
    offs = []
    for leg in legs:
        offs.append((0.12 * slam if leg.front else 0.05 * slam, 0.0) if not leg.front else None)
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
    add(p, "body", (-0.55 * e, 0, 0))
    add(p, "neck0", (-0.2 * e, 0, 0))
    add(p, "head", (-0.2 * e, 0, 0))
    add(p, "jaw", (0.8 * e, 0, 0))
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
