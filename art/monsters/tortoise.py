"""Tortoise (Eon Tortoise, Moss-Backed Tortoise, Xuan Wu the Black Tortoise, the Guardian of the Six
Paths).

After tortoise anatomy: a high-domed carapace of keratin scutes laid out as in life - five
vertebrals down the spine, four costals either side, a ring of marginals with the nuchal over the
neck and the supracaudal over the tail - each a raised plate stepped with concentric growth
annuli round a pale areola and parted from its neighbours by deep seams (the scutes come from a
weighted Voronoi diagram of hand-placed centres, so the seams run straight between them); the
marginals flare over the neck and the hind legs and are notched at the back; a flat, pale
plastron of paired plates underneath.  The skin (the secondary colour) is one sculpted piece of
clay: a long neck in loose folds; a small reptile head, flat on top under big head scales, with a
heavy-lidded eye and a hooked horny beak over the lower bill; columnar, elephantine hind legs and
flattened forelegs armoured in front with big overlapping scales, on round feet with blunt nails;
a short tail.  Moss grows in the seams and crystals of the enemy's accent colour push up through it.
Run: blender --background --python art/monsters/tortoise.py  ->  assets/monsters/tortoise.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
import arthropod as X  # noqa: E402
from creature import Walker, add, euler_yxz, zero_pose  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from sculpt import fbm3, morph_sphere, smooth  # noqa: E402
from kit import CRYSTAL, FOLIAGE, SKIN, V, Builder, Rig, env  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(9)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("shell", (0, 0.55, -0.3), (0, 0.6, 0.3), "root")
r.bone("neck", (0, 0.52, 0.62), (0, 0.68, 1.06), "shell")
r.bone("head", (0, 0.68, 1.06), (0, 0.69, 1.38), "neck")
r.bone("jaw", (0, 0.64, 1.12), (0, 0.62, 1.32), "head")
r.bone("tail", (0, 0.42, -0.82), (0, 0.32, -1.02), "shell")
for fz, nm in ((0.46, "f"), (-0.46, "h")):
    for s, sd in ((1, "L"), (-1, "R")):
        r.bone("%s_up.%s" % (nm, sd), (0.46 * s, 0.48, fz), (0.66 * s, 0.27, fz + 0.04), "shell")
        r.bone("%s_lo.%s" % (nm, sd), (0.66 * s, 0.27, fz + 0.04), (0.67 * s, 0.03, fz + 0.06), "%s_up.%s" % (nm, sd))

b = Builder("tortoise")

# ---------------------------------------------------------------- the carapace
SC = V(0, 0.42, 0)
RX, RY, RZ = 0.86, 0.8, 0.98


def unit(x, y, z):
    v = V(x, y, z)
    return v.normalized()


# scute centres on the unit sphere of directions and their weights (a power diagram: a bigger
# weight claims a bigger scute)
CENTRES = []
for phi in (-60.0, -30.0, 0.0, 30.0, 58.0):                                  # vertebrals
    a = math.radians(phi)
    CENTRES.append((unit(0.0, math.cos(a), -math.sin(a)), 0.4, "v"))
for s in (1, -1):                                                            # costals
    for phi in (-46.0, -16.0, 15.0, 44.0):
        a, c = math.radians(phi), math.radians(52.0)
        CENTRES.append((unit(math.sin(c) * s, math.cos(c) * math.cos(a), -math.cos(c) * math.sin(a)), 0.42, "c"))
for k in range(24):                                                          # marginals, nuchal at 0
    th = math.radians(k * 15.0)
    e = math.radians(5.0)
    CENTRES.append((unit(math.sin(th) * math.cos(e), math.sin(e), math.cos(th) * math.cos(e)), 0.1 if k else 0.06, "m"))


def scute(d):
    """(index, distance to the scute's edge, kind) of direction d in the power diagram."""
    best = None
    pw = []
    for i, (c, w, kind) in enumerate(CENTRES):
        q = (d - c).length_squared - w * w
        pw.append(q)
        if best is None or q < pw[best]:
            best = i
    ci = CENTRES[best][0]
    dist = 9.0
    for j, (c, w, kind) in enumerate(CENTRES):
        if j == best:
            continue
        den = 2.0 * (c - ci).length
        if den < 1e-6:
            continue
        dist = min(dist, (pw[j] - pw[best]) / den)
    return best, dist, CENTRES[best][2]


def base_point(d):
    if d.y < 0.0:
        # the plastron: flat underneath, inside the rim
        return V(d.x * RX * 0.86, d.y * 0.13, d.z * RZ * 0.88)
    p = V(d.x * RX, d.y * RY, d.z * RZ)
    # the marginals flare out over the neck and the hind legs
    if d.y < 0.3:
        th = math.atan2(d.x, d.z)
        flare = 0.05 + 0.05 * (math.cos(th) ** 2)
        p += V(d.x, 0.0, d.z) * (flare * smooth(0.3, 0.02, d.y))
    return p


def ring_spacing(kind):
    return 0.045 if kind == "m" else 0.06


def shell_shape(d):
    p = base_point(d)
    if d.y < 0.0:
        return p
    i, dist, kind = scute(d)
    sp = ring_spacing(kind)
    nrm = V(d.x / RX, d.y / RY, d.z / RZ).normalized()
    # each scute is a pillow: it rises from deep seams through two broad growth annuli (steps) to
    # a flat areola.  (Everything here is wider than the mesh spacing, so it reads, not aliases.)
    rise = 0.03 * smooth(0.0, sp * 2.4, dist)
    steps = 0.006 * (smooth(sp * 0.9, sp * 1.1, dist) + smooth(sp * 1.9, sp * 2.1, dist))
    seam = 0.014 * smooth(0.04, 0.0, dist)
    off = rise + steps - seam
    # the rim is notched between the hind marginals
    if kind == "m" and d.z < -0.3 and d.y < 0.14:
        off -= 0.03 * smooth(0.03, 0.0, dist) * smooth(0.14, 0.03, d.y)
    return p + nrm * off


def shell_col(lp, d):
    if d.y < 0.0:
        # plastron: pale paired plates, dark seams down the middle and across
        x, z = lp.x, lp.z
        seam = max(smooth(0.012, 0.0, abs(x)), max(smooth(0.012, 0.0, abs(z - zz)) for zz in (0.5, 0.25, -0.05, -0.35, -0.6)))
        return X.grey(0.9 - 0.4 * seam)
    i, dist, kind = scute(d)
    sp = ring_spacing(kind)
    # dark in the seams, the annuli a step paler each, the areola palest (horn weathers that way)
    v = 0.42 + 0.2 * smooth(0.0, sp * 0.9, dist) + 0.08 * smooth(sp * 1.0, sp * 1.2, dist) + 0.12 * smooth(sp * 2.0, sp * 2.6, dist)
    v *= 0.95 + 0.1 * fbm3((lp.x * 8.0, lp.y * 8.0, lp.z * 8.0), 2, 3)
    return X.grey(v)


# horn, not wet scales: the carapace takes the matte horn surface class
morph_sphere(b, SC, shell_shape, shell_col, cls=0.9, bone="shell", seg=112, rings=52, tint_fn=lambda p, d: 1.0)
# moss in the seams of the crown, and crystals of the accent colour pushing up through it
for k in range(16):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.05, 0.55)
    d = V(math.sin(a) * rr, 1.0, math.cos(a) * rr - 0.05).normalized()
    root = SC + shell_shape(d) - d * 0.01
    b.leaf(root, root + d * 0.1 + V(rnd.uniform(-0.05, 0.05), 0.03, rnd.uniform(-0.05, 0.05)), 0.04, "4a7a34", cls=FOLIAGE, bone="shell", col_tip="8ab858")
b.cur_pal = 1.0
for k, (a, rr) in enumerate(((0.6, 0.32), (2.4, 0.38), (4.3, 0.26))):
    d = V(math.sin(a) * rr, 1.0, math.cos(a) * rr - 0.1).normalized()
    b.crystal(SC + shell_shape(d) - d * 0.03, 0.04 + 0.01 * (k % 2), 0.11 + 0.03 * k, (0.92, 0.92, 0.92), cls=CRYSTAL, bone="shell", rot=(0.4 * d.z, 0, -0.4 * d.x),
              tint=1.0)
b.cur_pal = 0.0

# ---------------------------------------------------------------- skin: neck, head, legs, tail
SKIN_GREY = 0.8
HC = V(0, 0.71, 1.22)


def skin_col(p, info):
    tag = info.tag
    v = SKIN_GREY
    if tag == "neck":
        v *= 0.86 + 0.14 * (0.5 + 0.5 * math.sin(info.t * 38.0))
        v = v + (0.95 - v) * 0.6 * smooth(-0.2, -0.8, info.n.y)        # a pale throat
    elif tag in ("leg", "foot"):
        v *= 0.92 + 0.1 * fbm3((p.x * 18.0, p.y * 18.0, p.z * 18.0), 2, 5)
        v = v + (0.94 - v) * 0.4 * smooth(-0.1, -0.7, info.n.y)
    elif tag in ("head", "jaw"):
        v *= 0.9 + 0.12 * smooth(-0.6, 0.4, info.n.y)
        v = v + (0.95 - v) * 0.5 * smooth(-0.2, -0.8, info.n.y)
    return X.grey(min(1.0, v))


def skin_post(p, info):
    if info.tag == "neck":
        # loose folds of skin round the neck
        return info.n * (0.011 * math.sin(info.t * 38.0) - 0.004)
    if info.tag in ("leg", "foot", "tail"):
        return info.n * (0.008 * (fbm3((p.x * 22.0, p.y * 22.0, p.z * 22.0), 2, 7) - 0.5))
    return None


sk = Clay(0.0185, "tortoise_skin")
neck = [V(0, 0.5, 0.56), V(0, 0.58, 0.8), V(0, 0.66, 1.0), V(0, 0.7, 1.13)]


def neck_w(p, t):
    if t < 0.4:
        return {"shell": 1.0 - t / 0.4, "neck": t / 0.4}
    if t < 0.85:
        return {"neck": 1.0}
    return {"neck": 1.0 - (t - 0.85) / 0.3, "head": (t - 0.85) / 0.3}


sk.chain(neck, [0.15, 0.118, 0.088, 0.068], bones=neck_w, tag="neck")
# the head: a flat-topped skull, the snout narrowing to the beak, the cheeks behind the eyes
hf = A.HeadFrame(HC, V(0, -0.05, 1.0))
A.head_clay(sk, hf, 1.0, [
    ("ell", (0, 0.012, -0.03), (0.085, 0.072, 0.1), "head", False, False),
    ("ell", (0, 0.0, 0.045), (0.066, 0.056, 0.065), "head", False, False),
    ("ell", (0.055, -0.02, -0.03), (0.05, 0.052, 0.058), "head", True, False),
    ("ell", (0.045, 0.045, 0.02), (0.03, 0.02, 0.04), "head", True, False),
    ("ell", (0, 0.062, -0.01), (0.07, 0.02, 0.085), "head", False, False),
])
sk.ellipsoid(hf.at(0, -0.052, 0.035), (0.062, 0.028, 0.075), rot=hf.M, bones={"jaw": 1.0}, tag="jaw")
# legs: the forelegs bow out and are flattened front to back; the hind legs are columns
for nm in ("f", "h"):
    for sd, s2 in (("L", 1), ("R", -1)):
        up, lo = "%s_up.%s" % (nm, sd), "%s_lo.%s" % (nm, sd)
        h0, k0, f0 = r.head(up), r.tail(up), r.tail(lo)
        if nm == "f":
            sk.chain([h0 + V(-0.12 * s2, 0.02, -0.02), k0 + V(0.02 * s2, 0.0, 0.0), f0 + V(0, 0.07, 0.01)], [0.12, 0.12, 0.11], bones=limb_weights([up, lo]),
                     tag="leg", t0=0.0, t1=2.0)
            sk.ellipsoid(k0.lerp(f0, 0.45) + V(0.0, 0.0, 0.02), (0.12, 0.13, 0.09), bones={lo: 1.0}, tag="leg")
        else:
            sk.chain([h0 + V(-0.12 * s2, 0.02, 0.0), k0 + V(0.01 * s2, 0.0, 0.0), f0 + V(0, 0.07, 0)], [0.13, 0.14, 0.13], bones=limb_weights([up, lo]),
                     tag="leg", t0=0.0, t1=2.0)
        # the round, flat-soled foot
        sk.ellipsoid(f0 + V(0, 0.045, 0.02), (0.14, 0.055, 0.15), bones={lo: 1.0}, tag="foot")
sk.chain([V(0, 0.44, -0.78), V(0, 0.38, -0.9), V(0, 0.31, -1.02)], [0.075, 0.05, 0.02], bones={"tail": 1.0}, tag="tail")
b.cur_pal = 0.5  # palette slot (kit.py): the skin is naturally another colour than the shell
sk.build(b, skin_col, cls=X.CHITIN, tint_fn=lambda p, info: 0.8, post=skin_post)

# head scales: the big plates over the crown and the scales of the cheek
b.cur_pal = 0.5
for x, z, rx, rz in ((0.0, 0.05, 0.045, 0.035), (0.032, -0.012, 0.032, 0.04), (-0.032, -0.012, 0.032, 0.04), (0.0, -0.07, 0.055, 0.035)):
    c = hf.at(x, 0.075 - 0.004 * abs(x) / 0.035, z)
    b.ellipsoid(c, (rx, 0.012, rz), X.grey(0.72), cls=0.9, bone="head", rot=A.euler_of(hf.M), seg=12, rings=6, tint=0.8)
b.cur_pal = 0.0
# the horny beak: a hooked upper sheath over the lower bill (horn-coloured, not tinted)
up_beak = [hf.at(0, 0.03, 0.075), hf.at(0, 0.012, 0.11), hf.at(0, -0.022, 0.122), hf.at(0, -0.048, 0.11)]
A.horn(b, up_beak, 0.042, "8a7a5c", "2e261c", "head", r1=0.008, cls=0.9, seg=12, flat=0.72, up=(1, 0, 0), tint=0.0)
lo_beak = [hf.at(0, -0.055, 0.045), hf.at(0, -0.066, 0.085), hf.at(0, -0.056, 0.105)]
A.horn(b, lo_beak, 0.036, "8a7a5c", "2e261c", "jaw", r1=0.008, cls=0.9, seg=10, flat=0.65, up=(1, 0, 0), tint=0.0)
for s in (1, -1):
    A.animal_eye(b, hf.at(0.071 * s, 0.026, 0.032), hf.r * (0.85 * s) + hf.f * 0.55 + hf.u * 0.05, 0.029, "c09020", "head", pupil="round", almond=0.66,
                 lid="2a2018", lid_w=0.24, side=s)
    # a heavy upper lid over each eye
    b.cur_pal = 0.5
    b.ellipsoid(hf.at(0.066 * s, 0.054, 0.03), (0.032, 0.012, 0.034), X.grey(0.74), cls=X.CHITIN, bone="head", rot=A.euler_of(hf.M), seg=10, rings=6, tint=0.8)
    b.cur_pal = 0.0
    b.ball(hf.at(0.014 * s, 0.022, 0.118), 0.006, "201810", cls=SKIN, bone="head", seg=6, rings=4)

# ---------------------------------------------------------------- scales and nails
b.cur_pal = 0.5
for sd, s2 in (("L", 1), ("R", -1)):
    # the front of each foreleg is armoured with big overlapping scales, in rows
    up, lo = "f_up.%s" % sd, "f_lo.%s" % sd
    k0, f0 = r.tail(up), r.tail(lo)
    fwd = V(0.25 * s2, 0.0, 1.0).normalized()
    side = V(1.0, 0.0, 0.0)
    for row in range(5):
        t = 0.08 + row * 0.18
        c = k0.lerp(f0 + V(0, 0.08, 0), t) + V(0.015 * s2, 0.0, 0.0)
        for col in range(4 if row % 2 == 0 else 3):
            u = (col - (1.5 if row % 2 == 0 else 1.0)) * 0.058
            p = c + side * u + fwd * (0.105 - 0.25 * u * u)
            nrm = (fwd + side * (u * 3.0)).normalized()
            rot = euler_yxz(X.rot_to(nrm, V(0, 1, 0)))
            b.ellipsoid(p, (0.036, 0.032, 0.013), X.grey(0.68 + 0.04 * ((row + col) % 2)), cls=0.9, bone=lo, rot=rot, seg=10, rings=6, tint=0.8)
b.cur_pal = 0.0
for nm in ("f", "h"):
    for sd, s2 in (("L", 1), ("R", -1)):
        lo = "%s_lo.%s" % (nm, sd)
        f0 = r.tail(lo)
        for k in range(5 if nm == "f" else 4):
            n_ = 5 if nm == "f" else 4
            u = (k / (n_ - 1) - 0.5) * 2
            A.claw(b, f0 + V(u * 0.09, 0.04, 0.13 - abs(u) * 0.04), V(u * 0.35, -0.2, 1.0), 0.05, 0.022, lo, hook=0.25, col0="4a4038", col1="c8bca0")

T = 4.0


def idle(t):
    w = 2 * math.pi / T
    p = zero_pose(r)
    p["shell"] = ((math.sin(t * w) * 0.015, 0, math.sin(t * w + 0.9) * 0.01), (0, math.sin(t * w * 2) * 0.008, 0))
    p["neck"] = ((math.sin(t * w) * 0.08, math.sin(t * w + 0.5) * 0.25, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w + 1) * 0.06, math.sin(t * w + 0.9) * 0.15, 0), (0, 0, 0))
    p["jaw"] = ((0.04 + 0.04 * abs(math.sin(t * w)), 0, 0), (0, 0, 0))
    p["tail"] = ((0, math.sin(t * w * 2) * 0.2, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    snap = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["neck"] = ((0.4 * snap - 0.3 * e, 0, 0), (0, 0.05 * snap, 0.35 * snap))
    p["head"] = ((-0.2 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.8 * snap, 0, 0), (0, 0, 0))
    p["shell"] = ((0.1 * snap, 0, 0), (0, 0, 0.1 * snap))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["neck"] = ((0, 0, 0), (0, -0.05 * e, -0.25 * e))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["shell"] = ((-0.1 * e, 0, 0.08 * e), (0, 0, -0.1 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["shell"] = ((-0.25 * e, 0, 0), (0, 0.12 * e, 0))
    p["neck"] = ((-0.5 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.7 * e, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up.%s" % sd] = ((-0.7 * e, 0, 0), (0, 0, 0))
    return p


T_WALK = 2.0
LEGS4 = [("f_up.L", "f_lo.L"), ("h_up.L", "h_lo.L"), ("f_up.R", "f_lo.R"), ("h_up.R", "h_lo.R")]
WALK = Walker(r, LEGS4, [0.25, 0.0, 0.75, 0.5], duty=0.75)


def walk(t):
    """A slow four-beat walk: the shell rocks over each planted foot, the neck nods."""
    ph = (t / T_WALK) % 1.0
    w = 2 * math.pi
    p = zero_pose(r)
    add(p, "shell", (0.02 * math.sin(w * ph * 2), 0.04 * math.sin(w * ph), 0.03 * math.sin(w * ph - 0.6)), (0.015 * math.sin(w * ph), 0.012 * abs(math.sin(w * ph * 2)), 0))
    add(p, "neck", (0.06 * math.sin(w * ph * 2), -0.08 * math.sin(w * ph), 0), (0, 0, 0.03 * math.sin(w * ph * 2)))
    add(p, "head", (-0.04 * math.sin(w * ph * 2), 0.05 * math.sin(w * ph), 0))
    add(p, "tail", (0, 0.2 * math.sin(w * ph), 0))
    return WALK.step(p, ph, 0.2, 0.08)


def die(t):
    """Head and legs draw into the shell; the shell drops onto its plastron and tips."""
    k = min(1.0, t / 1.2)
    w = smooth(0.0, 0.5, k)
    f = smooth(0.3, 0.8, k)
    p = zero_pose(r)
    add(p, "neck", (0.3 * w, 0, 0), (0, -0.1 * w, -0.32 * w))
    add(p, "head", (0.4 * w, 0, 0.3 * f))
    add(p, "jaw", (0.2 * f, 0, 0))
    add(p, "shell", (0.08 * f, 0, 0.12 * f), (0, -0.3 * f + 0.03 * math.sin(math.pi * smooth(0.7, 0.88, k)), 0))
    for nm, s_ in (("L", 1), ("R", -1)):
        for fr in ("f", "h"):
            add(p, "%s_up.%s" % (fr, nm), (0.0, 0.0, 0.9 * s_ * w))
            add(p, "%s_lo.%s" % (fr, nm), (0.0, 0.0, -1.3 * s_ * w))
    add(p, "tail", (0.4 * w, 0, 0))
    return p


print("[art] tortoise: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/tortoise.glb", {"idle": (T, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=14, dist=0.3, strength=0.5, floor_y=0.0)
