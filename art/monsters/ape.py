"""Ape (new in Part VIII): the great apes of the cloud cliffs (Cloud Ape, Magpie-Bridge Gibbon King,
the White Ape Who Stole the Sword Manual).

Great-ape anatomy rather than a man in fur: it stands hunched with its weight forward on its
knuckles, the arms longer than the legs, a barrel chest and a belly, short bowed legs on flat
hand-like feet with an opposable big toe.  The head carries a sagittal crest and a heavy brow
ridge over deep-set eyes, a flat nose with flared nostrils, a long prognathous muzzle and a jaw
with canines; the face, palms and soles are bare skin, the rest a groomed coat of fur that is
longer on the forearms and shoulders, with a silver saddle on the back.
Tinted by the game per enemy; the bare skin keeps its own colour.
Run: blender --background --python art/monsters/ape.py  ->  assets/monsters/ape.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import eyes, fangs, zero_pose  # noqa: E402
from kit import CLOTH, MAT_PLAIN, SKIN, V, Builder, Rig, auto_weights, env, mix, rgb  # noqa: E402
from sculpt import blob3, loft, morph_sphere, prof_egg, section, smooth  # noqa: E402

kit.reset()
SKINC = "4a3a34"
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("pelvis", (0, 0.78, -0.12), (0, 0.98, -0.02), "root")
r.bone("spine", (0, 0.98, -0.02), (0, 1.22, 0.14), "pelvis")
r.bone("chest", (0, 1.22, 0.14), (0, 1.42, 0.32), "spine")
r.bone("neck", (0, 1.42, 0.32), (0, 1.5, 0.44), "chest")
r.bone("head", (0, 1.5, 0.44), (0, 1.62, 0.66), "neck")
r.bone("jaw", (0, 1.44, 0.5), (0, 1.38, 0.7), "head")
for s, sd in ((1, "L"), (-1, "R")):
    sh = V(0.34 * s, 1.36, 0.28)
    el = V(0.46 * s, 0.92, 0.36)
    wr = V(0.44 * s, 0.32, 0.48)
    r.bone("upper_arm." + sd, sh, el, "chest")
    r.bone("forearm." + sd, el, wr, "upper_arm." + sd)
    r.bone("hand." + sd, wr, wr + V(0.0, -0.26, 0.06), "forearm." + sd)
    hip = V(0.17 * s, 0.8, -0.12)
    kn = V(0.26 * s, 0.46, 0.04)
    an = V(0.24 * s, 0.1, -0.08)
    r.bone("thigh." + sd, hip, kn, "pelvis")
    r.bone("shin." + sd, kn, an, "thigh." + sd)
    r.bone("foot." + sd, an, an + V(0.02 * s, -0.06, 0.2), "shin." + sd)
b = Builder("ape")
weights = auto_weights(r, [n for n in r.bones if n not in ("root", "jaw")], sharp=3.0, k=3)

# torso: a loft from the pelvis up the hunched spine - broad hips, a round belly, a barrel chest,
# massive shoulders and the hump of the trapezius into the neck
spine_pts = [V(0, 0.74, -0.16), V(0, 0.86, -0.12), V(0, 1.0, -0.04), V(0, 1.12, 0.06), V(0, 1.24, 0.15), V(0, 1.34, 0.24), V(0, 1.42, 0.31), V(0, 1.48, 0.38)]
dims = [(0.2, 0.12, 0.16), (0.24, 0.14, 0.22), (0.26, 0.16, 0.28), (0.29, 0.18, 0.3), (0.33, 0.2, 0.28), (0.35, 0.2, 0.24), (0.28, 0.16, 0.18), (0.14, 0.11, 0.12)]
rings = []
for k, c in enumerate(spine_pts):
    d = (spine_pts[min(len(spine_pts) - 1, k + 1)] - spine_pts[max(0, k - 1)]).normalized()
    w, up, dn = dims[k]
    rings.append(section(c, d, prof_egg(w, up, dn, flat=0.1), 22, up=V(0, 0.3, -1)))


def coat(p, j, i):
    v = 0.62 + 0.1 * smooth(0.9, 1.3, p.y)
    # the silver saddle across the lower back
    if p.z < 0.1 and abs(p.x) < 0.25 and 0.9 < p.y < 1.25:
        v = 0.95
    return (v, v, v)


torso = loft(b, rings, (0.62, 0.62, 0.62), col_fn=coat, bone_fn=weights, tint_fn=lambda p: 1.0, cap0=True, cap1=True, cap_push=0.5)
# bare chest skin and nipples on the pectorals
b.ellipsoid(V(0, 1.2, 0.32), (0.2, 0.16, 0.06), SKINC, cls=SKIN, bone={"spine": 0.4, "chest": 0.6}, seg=16, rings=8)
# arms: muscled lofts, long; legs short and bowed
limbs = []
for s, sd in ((1, "L"), (-1, "R")):
    ua, fa, hd = "upper_arm." + sd, "forearm." + sd, "hand." + sd
    sh, el, wr = r.head(ua), r.tail(ua), r.tail(fa)
    pts = [sh + V(-0.06 * s, 0.04, -0.02), sh, sh.lerp(el, 0.4), el, el.lerp(wr, 0.35), el.lerp(wr, 0.75), wr]
    rad = [0.13, 0.13, 0.12, 0.085, 0.1, 0.08, 0.06]
    bones = [{"chest": 0.6, ua: 0.4}, ua, ua, {ua: 0.5, fa: 0.5}, fa, fa, {fa: 0.6, hd: 0.4}]
    limbs.append((b.tube(pts, rad, (0.6, 0.6, 0.6), cls=CLOTH, bones=bones, seg=14, tint=1.0), ua))
    # knuckle-walking hand: a bare palm folded under, four thick knuckles on the ground, a thumb
    hc = r.tail(hd)
    b.ellipsoid(wr.lerp(hc, 0.5), (0.065, 0.11, 0.06), (0.6, 0.6, 0.6), cls=CLOTH, bone=hd, seg=12, rings=8, tint=1.0)
    for k in range(4):
        z = (k - 1.5) * 0.03
        knuck = hc + V(0.0, 0.03, z + 0.03)
        b.ellipsoid(knuck, (0.03, 0.03, 0.025), SKINC, cls=SKIN, bone=hd, seg=8, rings=6)
        b.tube([knuck + V(0, 0.02, -0.02), knuck + V(0, 0.05, -0.05)], [0.022, 0.018], SKINC, cls=SKIN, bone=hd, seg=6)
    b.tube([wr + V(-0.03 * s, -0.08, 0.04), hc + V(-0.04 * s, 0.06, 0.06)], [0.022, 0.016], SKINC, cls=SKIN, bone=hd, seg=6)
    th, sn, ft = "thigh." + sd, "shin." + sd, "foot." + sd
    hip, kn, an = r.head(th), r.tail(th), r.tail(sn)
    lp = [hip + V(0, 0.04, 0), hip.lerp(kn, 0.5) + V(0.02 * s, 0, 0), kn, kn.lerp(an, 0.5), an]
    limbs.append((b.tube(lp, [0.14, 0.12, 0.09, 0.085, 0.07], (0.6, 0.6, 0.6), cls=CLOTH, bones=[{"pelvis": 0.5, th: 0.5}, th, {th: 0.5, sn: 0.5}, sn, {sn: 0.5, ft: 0.5}], seg=12, tint=1.0), th))
    # a flat, hand-like foot with long toes and the big toe set apart
    fc = an + V(0.0, -0.06, 0.08)
    b.ellipsoid(fc, (0.07, 0.035, 0.13), SKINC, cls=SKIN, bone=ft, seg=12, rings=6)
    for k in range(4):
        x = (k - 1.5) * 0.028 * s
        b.tube([fc + V(x, 0.0, 0.1), fc + V(x * 1.2, -0.01, 0.17)], [0.016, 0.012], SKINC, cls=SKIN, bone=ft, seg=6)
    b.tube([fc + V(-0.06 * s, 0.0, 0.02), fc + V(-0.12 * s, -0.01, 0.07)], [0.02, 0.015], SKINC, cls=SKIN, bone=ft, seg=6)

b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# head: crest and brow ridge, deep-set eyes, flat nose, prognathous muzzle and jaw
HC = V(0, 1.56, 0.52)
hf = A.HeadFrame(HC, V(0, -0.15, 1.0))


def skull(d):
    p = V(d.x * 0.13, d.y * 0.13, d.z * 0.13)
    q = p.copy()
    off = 0.0
    off += 0.04 * blob3(q, (0, 0.13, -0.02), (0.02, 0.04, 0.08))                       # sagittal crest
    off += 0.03 * blob3(q, (0, 0.04, 0.12), (0.1, 0.02, 0.03))                          # brow ridge
    off += 0.06 * blob3(q, (0, -0.06, 0.12), (0.07, 0.05, 0.05))                        # muzzle
    for s2 in (1, -1):
        off -= 0.02 * blob3(q, (0.045 * s2, 0.015, 0.12), (0.025, 0.02, 0.03))          # eye sockets
        off += 0.02 * blob3(q, (0.11 * s2, -0.04, 0.03), (0.03, 0.05, 0.05))            # cheek pads
    return p + p.normalized() * off


def face_col(p, d):
    """Bare dark skin over the face and muzzle, fur everywhere else."""
    bare = smooth(0.2, 0.6, d.z) * (1.0 - smooth(0.35, 0.6, d.y))
    return mix((0.6, 0.6, 0.6), rgb(SKINC), bare)


morph_sphere(b, hf.c, skull, face_col, cls=CLOTH, bone="head", seg=26, rings=18, tint_fn=lambda p, d: 1.0 - smooth(0.2, 0.6, d.z) * (1.0 - smooth(0.35, 0.6, d.y)), rot=hf.M)
b.ellipsoid(hf.at(0, -0.01, 0.17), (0.04, 0.025, 0.02), "2a2020", cls=SKIN, bone="head", seg=10, rings=6)
for s in (1, -1):
    b.ellipsoid(hf.at(0.018 * s, -0.018, 0.182), (0.01, 0.007, 0.006), "100808", cls=SKIN, bone="head", seg=6, rings=4, mat=MAT_PLAIN)
    b.ellipsoid(hf.at(0.13 * s, 0.0, -0.01), (0.015, 0.035, 0.03), SKINC, cls=SKIN, bone="head", seg=8, rings=6)
b.ellipsoid(hf.at(0, -0.1, 0.1), (0.075, 0.035, 0.07), SKINC, cls=SKIN, bone="jaw", seg=12, rings=6)
b.ellipsoid(hf.at(0, -0.08, 0.1), (0.06, 0.01, 0.06), "8a3040", cls=SKIN, bone="jaw", seg=10, rings=4)
eyes(b, hf.at(0, 0.02, 0.135), 0.09, 0.02, iris="c08020", bone="head", slit=False, glow=False, rot_y=0.4, h=0.85)
fangs(b, [hf.at(0.03, -0.06, 0.16), hf.at(-0.03, -0.06, 0.16)], 0.045, "head")
fangs(b, [hf.at(0.028, -0.08, 0.15), hf.at(-0.028, -0.08, 0.15)], 0.03, "jaw", down=False)

b.cur_pal = 0.3  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# the coat: groomed down the back and arms, longer over the shoulders and forearms
A.fur(b, torso, 300, 0.07, 0.03, seed=31, bone_fn=weights, min_dist=0.04, col_root=(0.5, 0.5, 0.5), col_tip=(0.8, 0.8, 0.8),
      groom=lambda p, n: (V(0, -1, -0.4) - n * V(0, -1, -0.4).dot(n)).normalized(), pred=lambda p, n: n.z < 0.6 or p.y > 1.3)
for verts, bone in limbs:
    A.fur(b, verts, 60, 0.08, 0.028, seed=len(bone) + ord(bone[-1]), bone_fn=lambda p, bone=bone: {bone: 1.0}, min_dist=0.04,
          col_root=(0.5, 0.5, 0.5), col_tip=(0.8, 0.8, 0.8), groom=lambda p, n: (V(0, -1, 0) - n * n.y * -1).normalized() if abs(n.y) < 0.95 else V(0, 0, 1))

T_IDLE = 3.2


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    br = math.sin(t * w * 2)
    p["pelvis"] = ((0, math.sin(t * w) * 0.04, 0), (0, br * 0.01, 0))
    p["chest"] = ((br * 0.03, 0, 0), (0, br * 0.006, 0))
    p["neck"] = ((0, math.sin(t * w) * 0.2, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w * 2) * 0.05, math.sin(t * w + 0.5) * 0.15, 0), (0, 0, 0))
    p["jaw"] = ((0.03 + 0.05 * max(0.0, math.sin(t * w * 1.3)), 0, 0), (0, 0, 0))
    shift = math.sin(t * w)
    p["upper_arm.L"] = ((0.05 * shift, 0, 0), (0, 0, 0))
    p["upper_arm.R"] = ((-0.05 * shift, 0, 0), (0, 0, 0))
    return p


def attack(t):
    """Rear up and bring both fists down."""
    k = t / 0.6
    e = env(k)
    up = smooth(0.0, 0.35, k) * (1.0 - smooth(0.4, 0.55, k))
    slam = smooth(0.4, 0.55, k) * (1.0 - smooth(0.75, 1.0, k))
    p = idle(0.0)
    p["pelvis"] = ((-0.45 * up + 0.2 * slam, 0, 0), (0, 0.1 * up, 0.15 * slam))
    p["chest"] = ((-0.2 * up + 0.2 * slam, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["upper_arm." + sd] = ((-2.4 * up + 0.3 * slam, 0, 0), (0, 0, 0))
        p["forearm." + sd] = ((-0.6 * up, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.6 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0, -0.15 * e))
    p["chest"] = ((-0.3 * e, 0.2 * e, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, -0.3 * e, 0), (0, 0, 0))
    p["jaw"] = ((0.4 * e, 0, 0), (0, 0, 0))
    return p


def cast(t):
    """Rise up and beat the chest, roaring."""
    k = t / 0.6
    e = env(k)
    beat = math.sin(k * math.pi * 6.0)
    p = idle(0.0)
    p["pelvis"] = ((-0.5 * e, 0, 0), (0, 0.12 * e, 0))
    p["neck"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.8 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-1.2 * e, 0, (0.7 + 0.2 * beat * s) * s * e), (0, 0, 0))
        p["forearm." + sd] = ((-1.4 * e, 0, 0), (0, 0, 0))
    return p


print("[art] ape: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/ape.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
