"""Mushroom folk (new in Part V): a walking glowcap.  A lumpy dome of a cap - no two alike - with
warts and glowing spots on top and radial gills underneath, long and short in turn; a fibrous stem
with a torn annulus under the cap and a cup-like volva at its foot; a shy face, stubby arms with
three-fingered hands, round feet with toes, mycelium threads trailing from the base and spore motes.
Run: blender --background --python art/monsters/mushroom.py  ->  assets/monsters/mushroom.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
from creature import eyes, zero_pose  # noqa: E402
from sculpt import fbm3, morph_sphere, scatter, smooth, strand  # noqa: E402
from kit import CLOTH, CRYSTAL, FOLIAGE, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, env  # noqa: E402
from creature import add  # noqa: E402
from clay import Clay  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(3)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, 0.15, 0), (0, 0.85, 0), "root")
r.bone("cap", (0, 0.85, 0), (0, 1.35, 0), "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm.%s" % sd, (0.26 * s, 0.6, 0.02), (0.48 * s, 0.38, 0.08), "body")
    r.bone("foot.%s" % sd, (0.14 * s, 0.18, 0), (0.15 * s, 0.02, 0.1), "root")

b = Builder("mushroom")
# stem: fibrous, a little swollen at the base, with a torn annulus (ring) under the cap and the
# cup-like volva at its foot
# the body is the stem itself, sculpted in one piece with its stubby arms, three-fingered hands
# and round toed feet: a pear-shaped trunk with a soft belly, fibrous streaks running up it
cl = Clay(0.022, "mushroom_body")


def stem_w(p, t):
    return {"body": 1.0} if p.y > 0.3 else {"body": 0.55 + 0.45 * smooth(0.1, 0.3, p.y), "root": 0.45 - 0.45 * smooth(0.1, 0.3, p.y)}


cl.chain([V(0, 0.14, 0.0), V(0, 0.36, 0.01), V(0, 0.6, 0.0), V(0, 0.86, 0.0)], [0.28, 0.31, 0.28, 0.22], bones=stem_w, tag="stem")
cl.ellipsoid(V(0, 0.36, 0.1), (0.24, 0.2, 0.18), bones=stem_w, tag="stem")
for s, sd in ((1, "L"), (-1, "R")):
    a = "arm.%s" % sd
    sh, hand = r.head(a), r.tail(a)
    cl.chain([sh + V(-0.04 * s, 0.02, 0), sh.lerp(hand, 0.5) + V(0, -0.02, 0), hand], [0.075, 0.06, 0.055], bones={a: 1.0}, tag="arm")
    cl.ball(hand + V(0.01 * s, -0.01, 0.01), 0.065, bones={a: 1.0}, tag="hand")
    for f in range(3):
        ang = (f - 1) * 0.6
        cl.chain([hand, hand + V(math.sin(ang) * 0.07 * s, -0.05, math.cos(ang) * 0.07)], [0.026, 0.02], bones={a: 1.0}, tag="hand")
    fb = "foot.%s" % sd
    cl.ellipsoid(V(0.15 * s, 0.07, 0.06), (0.12, 0.08, 0.15), bones={fb: 1.0}, tag="foot")
    for t3 in range(3):
        cl.ball(V(0.15 * s + (t3 - 1) * 0.05, 0.045, 0.18), 0.034, bones={fb: 1.0}, tag="foot")


def body_col(p, info):
    a = math.atan2(p.x, p.z)
    streak = smooth(0.6, 0.95, math.sin(a * 26.0 + p.y * 3.0 + 2.0 * fbm3((p.x * 3, p.y * 3, p.z * 3), 2, 6)))
    base = {"stem": (0.96, 0.93, 0.85), "arm": (0.95, 0.91, 0.82), "hand": (0.95, 0.91, 0.82), "foot": (0.88, 0.83, 0.72)}[info.tag]
    k = 1.0 - 0.07 * streak if info.tag == "stem" else 1.0
    # a little warmer and darker towards the foot of the stem
    k *= 1.0 - 0.08 * smooth(0.45, 0.1, p.y)
    return (base[0] * k, base[1] * k, base[2] * k)


cl.build(b, body_col, cls=SKIN, tint_fn=lambda p, info: 0.0)
ring = []
for i in range(25):
    a = 2 * math.pi * i / 24
    ring.append(V(math.sin(a) * 0.3, 0.8 - 0.03 * abs(math.sin(a * 5.0)), math.cos(a) * 0.3))
b.tube(ring, [(0.03, 0.012)] * 25, "f8f0e0", cls=SKIN, bone="body", seg=6, cap0=False, cap1=False, up=(0, 1, 0))
for k in range(10):
    a = 2 * math.pi * k / 10 + 0.2
    root = V(math.sin(a) * 0.3, 0.79, math.cos(a) * 0.3)
    b.leaf(root, root + V(math.sin(a) * 0.04, -0.08 - 0.03 * (k % 3), math.cos(a) * 0.04), 0.035, "f8f0e0", cls=SKIN, bone="body", side=(math.cos(a), 0, -math.sin(a)), n=3, curl=0.05)
b.lathe(V(0, 0, 0), [(0.34, 0.03), (0.36, 0.1), (0.33, 0.2)], "d8ccb0", cls=SKIN, seg=20, bone="root", cap_bottom=False, cap_top=False, folds=(9, 0.08, 0.0))
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# cap: a lumpy dome (no two the same), darker in its centre, studded with warts and glowing spots
def cap_shape(d):
    if d.y < -0.05:
        return V(d.x * 0.15, 0.0, d.z * 0.15) + V(0, -0.0, 0)
    p = V(d.x * 0.8, max(0.0, d.y) * 0.56, d.z * 0.8)
    lump = fbm3((d.x * 2.5, d.y * 2.5, d.z * 2.5), 2, 4) - 0.5
    p = p * (1.0 + 0.12 * lump)
    p.y += 0.06 * smooth(0.95, 0.4, d.y) * smooth(-0.05, 0.25, d.y)     # the rim curls under
    return p


CAPC = V(0, 0.88, 0)
cap_v = morph_sphere(b, CAPC, cap_shape, lambda p, d: (0.7 + 0.3 * smooth(0.95, 0.3, d.y),) * 3, cls=CLOTH, bone="cap", seg=80, rings=40, tint_fn=lambda p, d: 1.0)
for pos, nrm in scatter(b, cap_v, 26, seed=5, pred=lambda p, n: n.y > 0.3, min_dist=0.1):
    sz = rnd.uniform(0.025, 0.05)
    b.ellipsoid(pos + nrm * 0.008, (sz, sz * 0.6, sz), (1.0, 1.0, 1.0), cls=SKIN, bone="cap", tint=0.25, seg=8, rings=5, rot=(math.atan2(nrm.z, nrm.y), 0, -math.atan2(nrm.x, nrm.y)))
for k in range(16):
    a = rnd.uniform(0, 2 * math.pi)
    rr = rnd.uniform(0.15, 0.62)
    d = V(math.sin(a) * rr, 1.0, math.cos(a) * rr).normalized()
    c = CAPC + cap_shape(d)
    nrm = (c - V(0, 0.6, 0)).normalized()
    rx = math.atan2(nrm.z, nrm.y)
    rz = -math.atan2(nrm.x, nrm.y)
    sz = rnd.uniform(0.04, 0.08)
    b.ellipsoid(c, (sz, 0.012, sz), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="cap", rot=(rx, 0, rz), tint=0.35, mat=MAT_GLOW, seg=10, rings=4)
# gills: thin radial sheets under the cap, long ones alternating with short ones
for k in range(44):
    a = 2 * math.pi * k / 44
    inner = 0.15 if k % 2 == 0 else 0.42
    b.leaf(V(math.sin(a) * inner, 0.87, math.cos(a) * inner), V(math.sin(a) * 0.76, 0.93, math.cos(a) * 0.76), 0.032, "e8d8c0", cls=FOLIAGE, bone="cap", side=(math.cos(a), 0, -math.sin(a)), curl=0.0, n=3, col_tip="d8c0a8")
# face
eyes(b, V(0, 0.62, 0.27), 0.09, 0.04, iris="402818", bone="body", slit=False, glow=False, rot_y=0.35, h=1.3)
mouth = [V((i / 4 - 0.5) * 0.08, 0.5 + ((i / 4 - 0.5) ** 2) * 0.12, 0.3) for i in range(5)]
b.tube(mouth, [0.006] * 5, "6a3020", cls=SKIN, bone="body", seg=6, mat=MAT_PLAIN)
for s in (1, -1):
    b.ellipsoid(V(0.15 * s, 0.53, 0.27), (0.04, 0.02, 0.01), "ffb0a0", cls=SKIN, bone="body", seg=8, rings=4, rot=(0, 0.5 * s, 0), mat=MAT_PLAIN)
# mycelium threads trailing from the base
for k in range(9):
    a = 2 * math.pi * k / 9
    strand(b, [V(math.sin(a) * 0.3, 0.05, math.cos(a) * 0.3), V(math.sin(a + 0.2) * 0.45, 0.02, math.cos(a + 0.2) * 0.45), V(math.sin(a - 0.1) * 0.6, 0.01, math.cos(a - 0.1) * 0.6)], 0.008, 0.002, "f8f4e8", cls=SKIN, bone="root", seg=4, per=3, mat=MAT_PLAIN)
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# spore motes floating around the cap
for k in range(10):
    a = k * 0.8
    b.ball(V(math.sin(a) * 0.8, 1.2 + 0.15 * math.sin(k * 2.0), math.cos(a) * 0.8), 0.03, (1.0, 1.0, 1.0), cls=CRYSTAL, bone="cap", tint=0.5, mat=MAT_GLOW, seg=8, rings=5)

T = 2.0


def idle(t):
    w = 2 * math.pi / T
    bounce = abs(math.sin(t * w))
    p = zero_pose(r)
    p["root"] = ((0, 0, 0), (0, bounce * 0.06, 0))
    p["body"] = ((0, math.sin(t * w + 0.9) * 0.1, math.sin(t * w) * 0.06), (0, 0, 0), (1.0 + 0.04 * (1 - bounce), 1.0 - 0.05 * (1 - bounce), 1.0 + 0.04 * (1 - bounce)))
    p["cap"] = ((math.sin(t * w + 1) * 0.06, 0, math.sin(t * w + 0.5) * 0.08), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((math.sin(t * w + s) * 0.3, 0, s * 0.2 * math.sin(t * w)), (0, 0, 0))
        p["foot.%s" % sd] = ((math.sin(t * w + (0 if s > 0 else math.pi)) * 0.25, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    butt = math.sin(min(1.0, k * 1.5) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.25 * e, 0.35 * butt))
    p["body"] = ((0.5 * butt - 0.2 * e, 0, 0), (0, 0, 0))
    p["cap"] = ((0.3 * butt, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["arm.%s" % sd] = ((-1.2 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["body"] = ((-0.3 * e, 0, 0), (0, 0, 0), (1.0 + 0.15 * e, 1.0 - 0.2 * e, 1.0 + 0.15 * e))
    p["cap"] = ((-0.2 * e, 0, 0.15 * e), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["cap"] = ((0, 0, 0), (0, 0.08 * e, 0), (1.0 + 0.25 * e, 1.0 + 0.1 * e, 1.0 + 0.25 * e))
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
    add(p, "cap", (0.04 * math.sin(w * ph * 2), 0, -0.08 * math.sin(w * ph - 0.5)))
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
    from creature import euler_g
    q = V(0, 0, -0.32)
    R = euler_g((a, 0.0, 0.25 * f))
    off = q - R @ q
    add(p, "root", (a, 0.0, 0.25 * f), (off.x, off.y, off.z))
    add(p, "body", (0.0, 0.0, 0.1 * math.sin(k * 12.0) * (1.0 - f)))
    add(p, "cap", (-0.2 * f, 0, 0.2 * f))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm.%s" % sd, (-0.6 * f, 0, s_ * 0.8 * f))
        add(p, "foot.%s" % sd, (-0.5 * f, 0, 0))
    return p

print("[art] mushroom: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/mushroom.glb", {"idle": (T, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=12, dist=0.25, strength=0.5, floor_y=0.0)
