"""Mushroom folk (new in Part V): a walking glowcap (the Spore Puff, the Mother of Spores).

Designed silhouette first, after real fungi: the cap is the creature's head and hat at once, a
bell-shaped dome a little under twice the width of the stem and tipped to one side, its rim curled
under and coming down low enough to shade the eyes - not a flat saucer on a post.  Under it the
anatomy of an agaric: radial gills, long and short in turn; a torn, ruffled ring (the annulus)
round the top of the stem; and the stem itself is the body, pale, fibrous and pear-shaped, with
stubby arms, three-fingered hands and round toed feet.  Value: the cap darkest and most
saturated at its crown, the stem and gills pale; the warts of the veil scattered over the cap
in cream, a few spots glowing in the accent colour, and spores drifting round it.  The face sits
in the shadow of the brim: two dark eyes that catch the light, and a small mouth.
Run: blender --background --python art/monsters/mushroom.py  ->  assets/monsters/mushroom.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay  # noqa: E402
from creature import add, zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, morph_sphere, scatter, smooth, strand  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(3)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, 0.12, 0), (0, 0.5, 0), "root")
r.bone("head", (0, 0.5, 0.0), (0, 0.8, 0.0), "body")
r.bone("cap", (0, 0.8, 0), (0, 1.3, 0), "head")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm.%s" % sd, (0.24 * s, 0.5, 0.03), (0.44 * s, 0.32, 0.1), "body")
    r.bone("foot.%s" % sd, (0.14 * s, 0.16, 0), (0.15 * s, 0.02, 0.1), "root")

b = Builder("mushroom")


def stem_w(p, t=0.0):
    if p.y < 0.26:
        k = smooth(0.08, 0.26, p.y)
        return {"body": 0.55 + 0.45 * k, "root": 0.45 - 0.45 * k}
    if p.y < 0.46:
        return {"body": 1.0}
    k = smooth(0.46, 0.62, p.y)
    return {"body": 1.0 - k, "head": k}


# ---------------------------------------------------------------- the stem is the body
cl = Clay(0.02, "mushroom_body")
cl.chain([V(0, 0.12, 0.0), V(0.015, 0.32, 0.02), V(0.0, 0.56, 0.015), V(-0.02, 0.84, -0.02)], [0.3, 0.31, 0.24, 0.18], bones=stem_w, tag="stem")
cl.ellipsoid(V(0, 0.3, 0.1), (0.26, 0.21, 0.21), bones=stem_w, tag="stem")
for s, sd in ((1, "L"), (-1, "R")):
    a = "arm.%s" % sd
    sh, hand = r.head(a), r.tail(a)
    cl.chain([sh + V(-0.05 * s, 0.03, 0), sh.lerp(hand, 0.5) + V(0, -0.015, 0), hand], [0.072, 0.058, 0.052], bones={a: 1.0}, tag="arm")
    cl.ball(hand + V(0.01 * s, -0.01, 0.01), 0.062, bones={a: 1.0}, tag="hand")
    for f in range(3):
        ang = (f - 1) * 0.65
        cl.chain([hand, hand + V(math.sin(ang) * 0.07 * s, -0.05, math.cos(ang) * 0.07)], [0.026, 0.02], bones={a: 1.0}, tag="hand")
    fb = "foot.%s" % sd
    cl.ellipsoid(V(0.15 * s, 0.07, 0.06), (0.12, 0.08, 0.15), bones={fb: 1.0}, tag="foot")
    for t3 in range(3):
        cl.ball(V(0.15 * s + (t3 - 1) * 0.05, 0.045, 0.18), 0.034, bones={fb: 1.0}, tag="foot")


def body_col(p, info):
    a = math.atan2(p.x, p.z)
    streak = smooth(0.55, 0.95, math.sin(a * 22.0 + p.y * 3.0 + 2.0 * fbm3((p.x * 3, p.y * 3, p.z * 3), 2, 6)))
    base = {"stem": (0.97, 0.94, 0.86), "arm": (0.96, 0.92, 0.83), "hand": (0.96, 0.92, 0.83), "foot": (0.86, 0.8, 0.68)}[info.tag]
    k = 1.0 - 0.08 * streak if info.tag == "stem" else 1.0
    # warmer and darker towards the foot, and in the shadow under the cap
    k *= 1.0 - 0.1 * smooth(0.42, 0.08, p.y) - 0.12 * smooth(0.7, 0.84, p.y)
    return (base[0] * k, base[1] * k, base[2] * k)


cl.build(b, body_col, cls=SKIN, tint_fn=lambda p, info: 0.0)

# ---------------------------------------------------------------- the ring: a torn, ruffled skirt round the top of the stem
rows = []
for j in range(4):
    t = j / 3
    row = []
    for i in range(49):
        a = 2 * math.pi * i / 48
        ruff = 0.018 * math.sin(a * 11.0) * t + 0.01 * math.sin(a * 5.0 + 1.0) * t
        tear = 0.03 * smooth(0.5, 0.9, fbm3((math.cos(a) * 3, math.sin(a) * 3, 2.0), 2, 9)) * t
        rr = 0.235 + 0.075 * t + ruff
        row.append(V(math.sin(a) * rr, 0.75 - 0.09 * t + tear * 0.5 - tear, math.cos(a) * rr - 0.01))
    rows.append(row)
b.sheet(rows, "f6efe0", cls=SKIN, bone={"head": 0.7, "body": 0.3}, cols=["f8f2e6", "f2eadb", "e8dcc6", "dccdb4"], thickness=0.008)

# ---------------------------------------------------------------- the cap: a bell tipped to one side
CAPC = V(0, 0.8, 0.0)
R_CAP, H_CAP, RIM_Y = 0.56, 0.44, 0.05
TILT = kit.euler_g((0.1, 0.0, -0.12))


def cap_shape(d):
    th = math.acos(max(-1.0, min(1.0, d.y)))
    u = th / math.pi
    ph = math.atan2(d.x, d.z)
    lump = fbm3((d.x * 2.2, d.y * 2.2, d.z * 2.2), 2, 4) - 0.5
    wave = 0.022 * math.sin(ph * 5.0 + 0.7) + 0.012 * math.sin(ph * 9.0 + 2.0)
    if u < 0.6:
        # the dome: full and round over the shoulders, flatter on the crown
        k = u / 0.6
        rr = R_CAP * math.sin(k * math.pi * 0.5) ** 0.85
        y = RIM_Y + (H_CAP - RIM_Y) * math.cos(k * math.pi * 0.5) ** 0.75
        rr *= 1.0 + 0.07 * lump
        y += 0.03 * lump * math.sin(k * math.pi)
        y += wave * k ** 4
    elif u < 0.72:
        # the rim curls under
        k = (u - 0.6) / 0.12
        rr = R_CAP * (1.0 - 0.07 * math.sin(k * math.pi * 0.5))
        y = RIM_Y - 0.045 * math.sin(k * math.pi * 0.5) + wave
    else:
        # the underside, rising a little into the stem
        k = (u - 0.72) / 0.28
        rr = R_CAP * 0.93 * (1.0 - k) + 0.12 * k
        y = RIM_Y - 0.045 + 0.06 * k + wave * (1.0 - k)
    return TILT @ V(math.sin(ph) * rr, y, math.cos(ph) * rr)


def cap_col(lp, d):
    u = math.acos(max(-1.0, min(1.0, d.y))) / math.pi
    if u > 0.66:
        return (0.93, 0.88, 0.8)
    # darkest at the crown, lightening towards the rim, mottled
    g = fbm3((d.x * 5.0, d.y * 5.0, d.z * 5.0), 2, 8)
    v = 0.64 + 0.3 * smooth(0.0, 0.5, u) + 0.08 * (g - 0.5)
    return (v, v, v)


def cap_tint(lp, d):
    u = math.acos(max(-1.0, min(1.0, d.y))) / math.pi
    return 1.0 - smooth(0.6, 0.68, u)


b.cur_pal = 0.0
cap_v = morph_sphere(b, CAPC, cap_shape, cap_col, cls=CLOTH, bone="cap", seg=64, rings=40, tint_fn=cap_tint)
# the warts of the torn veil: flat, irregular cream patches, bigger near the crown
for pos, nrm in scatter(b, cap_v, 16, seed=5, pred=lambda p, n: n.y > 0.45, min_dist=0.11):
    sz = rnd.uniform(0.03, 0.06) * (1.0 + 0.5 * smooth(1.0, 1.2, pos.y))
    b.ellipsoid(pos + nrm * 0.006, (sz, sz * 0.32, sz * rnd.uniform(0.7, 1.0)), (0.97, 0.94, 0.86), cls=SKIN, bone="cap", tint=0.15,
                seg=9, rings=5, rot=(math.atan2(nrm.z, nrm.y), rnd.uniform(0, 3), -math.atan2(nrm.x, nrm.y)))
# a few spots that glow in the accent colour
b.cur_pal = 1.0
for pos, nrm in scatter(b, cap_v, 7, seed=11, pred=lambda p, n: 0.15 < n.y < 0.8, min_dist=0.2):
    sz = rnd.uniform(0.028, 0.04)
    b.ellipsoid(pos + nrm * 0.004, (sz, 0.008, sz), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="cap", tint=1.0, mat=MAT_GLOW, seg=10, rings=4,
                rot=(math.atan2(nrm.z, nrm.y), 0, -math.atan2(nrm.x, nrm.y)))
b.cur_pal = 0.0
# gills: thin radial sheets under the cap, long and short in turn
for k in range(36):
    a = 2 * math.pi * k / 36
    inner = 0.13 if k % 2 == 0 else 0.34
    p0 = CAPC + TILT @ V(math.sin(a) * inner, RIM_Y - 0.0, math.cos(a) * inner)
    p1 = CAPC + TILT @ V(math.sin(a) * R_CAP * 0.9, RIM_Y - 0.035, math.cos(a) * R_CAP * 0.9)
    b.leaf(p0, p1, 0.03, "e6d8c0", cls=FOLIAGE, bone="cap", side=TILT @ V(math.cos(a), 0, -math.sin(a)), curl=0.0, n=3, col_tip="d4c0a6")

# ---------------------------------------------------------------- the face, in the shade of the brim
hit = A.surface(b)


def on_stem(x, y):
    h = hit(V(x, y, 1.0), V(0, 0, -1), 2.0)
    return (h[0], h[1]) if h is not None else (V(x, y, 0.25), V(0, 0, 1))


for s in (1, -1):
    c, n = on_stem(0.09 * s, 0.6)
    rot = (0, math.atan2(n.x, n.z), 0)
    b.ellipsoid(c + n * 0.004, (0.038, 0.056, 0.018), "1a1216", cls=SKIN, bone="head", rot=rot, seg=14, rings=8, mat=MAT_PLAIN)
    b.ellipsoid(c + n * 0.018 + V(0.012 * s, 0.02, 0), (0.013, 0.016, 0.006), "ffffff", cls=CLOTH, bone="head", rot=rot, seg=8, rings=5, mat=MAT_GLOW)
    b.ellipsoid(c + n * 0.018 + V(-0.01 * s, -0.024, 0), (0.006, 0.006, 0.004), "ffffff", cls=CLOTH, bone="head", seg=6, rings=4, mat=MAT_GLOW)
mouth = []
for i in range(5):
    x = (i / 4 - 0.5) * 0.065
    pm, nm = on_stem(x, 0.505 + ((i / 4 - 0.5) ** 2) * 0.08)
    mouth.append(pm + nm * 0.003)
b.tube(mouth, [0.0055] * 5, "5a2a20", cls=SKIN, bone="head", seg=6, mat=MAT_PLAIN)
# mycelium threads trailing from the feet
for k in range(7):
    a = 2 * math.pi * k / 7 + 0.4
    strand(b, [V(math.sin(a) * 0.26, 0.04, math.cos(a) * 0.26), V(math.sin(a + 0.2) * 0.4, 0.015, math.cos(a + 0.2) * 0.4),
               V(math.sin(a - 0.1) * 0.52, 0.006, math.cos(a - 0.1) * 0.52)], 0.007, 0.002, "f4efe2", cls=SKIN, bone="root", seg=4, per=3, mat=MAT_PLAIN)
# spores drifting round the cap
b.cur_pal = 1.0
for k in range(9):
    a = k * 0.8
    b.ball(V(math.sin(a) * 0.72, 1.12 + 0.14 * math.sin(k * 2.0), math.cos(a) * 0.72), 0.022 + 0.008 * (k % 3), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="cap",
           tint=0.6, mat=MAT_GLOW, seg=8, rings=5)
b.cur_pal = 0.0

T = 2.0


def idle(t):
    w = 2 * math.pi / T
    bounce = abs(math.sin(t * w))
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, bounce * 0.05, 0))
    p["body"] = ((0, math.sin(t * w + 0.9) * 0.08, math.sin(t * w) * 0.05), (0, 0, 0), (1.0 + 0.035 * (1 - bounce), 1.0 - 0.045 * (1 - bounce), 1.0 + 0.035 * (1 - bounce)))
    p["head"] = ((0.04 * math.sin(t * w * 2), 0.06 * math.sin(t * w + 0.4), 0.0), (0, 0, 0))
    p["cap"] = ((math.sin(t * w + 1) * 0.05, 0, math.sin(t * w + 0.5) * 0.06), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((math.sin(t * w + s) * 0.3, 0, s * 0.2 * math.sin(t * w)), (0, 0, 0))
        p["foot.%s" % sd] = ((math.sin(t * w + (0 if s > 0 else math.pi)) * 0.2, 0, 0), (0, 0, 0))
    return p


def attack(t):
    """A head-butt with the cap: crouch, spring and butt forward."""
    k = t / 0.55
    e = env(k)
    butt = math.sin(min(1.0, k * 1.5) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.22 * e, 0.35 * butt))
    p["body"] = ((0.4 * butt - 0.2 * e, 0, 0), (0, 0, 0))
    p["head"] = ((0.25 * butt, 0, 0), (0, 0, 0))
    p["cap"] = ((0.2 * butt, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["arm.%s" % sd] = ((-1.2 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["body"] = ((-0.3 * e, 0, 0), (0, 0, 0), (1.0 + 0.15 * e, 1.0 - 0.2 * e, 1.0 + 0.15 * e))
    p["head"] = ((-0.15 * e, 0, 0.1 * e), (0, 0, 0))
    p["cap"] = ((-0.2 * e, 0, 0.15 * e), (0, 0, 0))
    return p


def cast(t):
    """The cap swells and puffs a cloud of spores."""
    e = env(t / 0.6)
    p = idle(0.0)
    p["cap"] = ((0, 0, 0), (0, 0.08 * e, 0), (1.0 + 0.22 * e, 1.0 + 0.1 * e, 1.0 + 0.22 * e))
    p["body"] = ((-0.15 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((-0.5 * e, 0, s * 1.6 * e), (0, 0, 0))
    return p


T_WALK = 0.9


def walk(t):
    """A waddle: the stem rocks from foot to foot, each round foot lifting in turn."""
    ph = (t / T_WALK) % 1.0
    w = 2 * math.pi
    p = zero_pose(r)
    sw = math.sin(w * ph)
    add(p, "root", (0, 0.08 * sw, 0), (0.03 * sw, 0.04 * abs(math.sin(w * ph * 2 + 1.57)), 0))
    add(p, "body", (0.06, 0, 0.12 * sw))
    add(p, "head", (0.0, 0, -0.04 * sw))
    add(p, "cap", (0.04 * math.sin(w * ph * 2), 0, -0.07 * math.sin(w * ph - 0.5)))
    for sd, s_ in (("L", 1), ("R", -1)):
        lift = max(0.0, -s_ * sw)
        add(p, "foot.%s" % sd, (-0.35 * lift + 0.15 * s_ * math.cos(w * ph), 0, 0), (0, 0.08 * lift, 0.05 * s_ * math.cos(w * ph)))
        add(p, "arm.%s" % sd, (0.4 * s_ * sw, 0, 0.2 * s_))
    return p


def die(t):
    """Totters, then falls over backwards; the cap rolls a little and settles."""
    k = min(1.0, t / 1.2)
    f = smooth(0.25, 0.75, k)
    p = zero_pose(r)
    a = -1.45 * f
    q = V(0, 0, -0.32)
    R = creature.euler_g((a, 0.0, 0.25 * f))
    off = q - R @ q
    add(p, "root", (a, 0.0, 0.25 * f), (off.x, off.y, off.z))
    add(p, "body", (0.0, 0.0, 0.1 * math.sin(k * 12.0) * (1.0 - f)))
    add(p, "cap", (-0.2 * f, 0, 0.2 * f))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm.%s" % sd, (-0.6 * f, 0, s_ * 0.8 * f))
        add(p, "foot.%s" % sd, (-0.5 * f, 0, 0))
    return p


print("[art] mushroom: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/mushroom.glb", {"idle": (T, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=12, dist=0.25, strength=0.45, floor_y=0.0)
