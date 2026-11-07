"""Spider: the eight-legged hunters (Cave Spider, Root Crawler) and, recoloured brass, the Brass
Spider Engine of Heaven's Forge.  A hairy abdomen with a folium of dark chevrons and spinnerets on a
pedicel, a cephalothorax shield with a fovea and radial grooves, eight eyes in two rows on a raised
mound, bulky chelicerae with curved fangs, bulbed pedipalps, and eight segmented, bristled legs with
joint bands and tarsal claws that walk in an alternating gait.  Tinted by the game per enemy; eyes and fangs keep their colours.
Run: blender --background --python art/monsters/spider.py  ->  assets/monsters/spider.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import Walker, add, flip_die, leg_chain, smooth, zero_pose  # noqa: E402
from kit import CLOTH, HAIR, MAT_GLOW, SCALE, SKIN, STONE, V, Builder, Rig  # noqa: E402
from clay import Clay  # noqa: E402
from sculpt import blob3, fbm3, morph_sphere, strand  # noqa: E402

kit.reset()
creature.realtime()
BY = 0.7
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("thorax", (0, BY, -0.05), (0, BY, 0.35), "root")
r.bone("abdomen", (0, BY + 0.05, -0.1), (0, BY + 0.2, -0.85), "thorax")
r.bone("fangs", (0, BY - 0.05, 0.35), (0, BY - 0.2, 0.5), "thorax")
legs = []
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(4):
        z = 0.22 - k * 0.15
        spread = (0.45, 0.15, -0.15, -0.45)[k]
        root = V(0.17 * s, BY, z)
        knee = V((0.62 + 0.05 * k) * s, BY + 0.5, z + spread * 0.6)
        foot = V((1.0 + 0.04 * k) * s, 0.02, z + spread * 1.4)
        nm = "leg%d.%s" % (k, sd)
        leg_chain(r, nm, root, knee, foot, "thorax")
        legs.append((nm + "_a", nm + "_b", (k % 2) * math.pi + (0 if s > 0 else math.pi)))
    r.bone("palp." + sd, (0.08 * s, BY - 0.02, 0.36), (0.16 * s, BY - 0.05, 0.62), "thorax")
b = Builder("spider")

# abdomen: an egg narrowing to the spinnerets, with the folium (a chain of dark chevrons) down the
# back, pale flanks, then a pile of fine hair over it
AC = V(0, BY + 0.2, -0.55)


def abd_col(p, d):
    v = 0.72 + 0.26 * smooth(0.2, -0.8, d.y)
    if d.y > -0.1:
        z = (p.z + 0.46) / 0.92                          # 0 at the back, 1 at the front
        chev = abs(((z * 5.0 + abs(p.x) * 4.0) % 1.0) - 0.5)
        if abs(p.x) < 0.22 * (0.4 + z):
            v *= 0.55 if chev < 0.18 else 1.05
    v *= 0.9 + 0.2 * fbm3((p.x * 12, p.y * 12, p.z * 12), 2, 8)
    return (v, v, v)


ab = Clay(0.016, "spider_abdomen")
ab.ellipsoid(AC + V(0, 0.0, 0.04), (0.36, 0.31, 0.4), bones={"abdomen": 1.0}, tag="abd")
ab.ellipsoid(AC + V(0, -0.03, -0.3), (0.24, 0.21, 0.2), bones={"abdomen": 1.0}, tag="abd")


def abd_fur(p, info):
    nn = info.n
    w = fbm3((p.x * 10.0, p.y * 10.0, p.z * 10.0), 2, 11)
    u = -p.z * 16.0 + 0.6 * math.sin(math.atan2(nn.x, nn.y) * 9.0) + 1.3 * w
    k = u - math.floor(u)
    return nn * (0.016 * k ** 1.6)


ab.build(b, lambda p, info: abd_col(p - AC, (p - AC).normalized()), cls=CLOTH, tint_fn=lambda p, info: 1.0, post=abd_fur)
for s in (1, -1):
    b.cone(AC + V(0.03 * s, -0.12, -0.46), 0.025, 0.07, (0.5, 0.5, 0.5), cls=SCALE, bone="abdomen", tint=1.0, seg=8, rot=(-1.9, 0, 0.2 * s))
b.cone(AC + V(0, -0.1, -0.47), 0.03, 0.08, (0.45, 0.45, 0.45), cls=SCALE, bone="abdomen", tint=1.0, seg=8, rot=(-1.9, 0, 0))
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# pedicel joining the two halves
b.tube([V(0, BY + 0.04, -0.02), V(0, BY + 0.08, -0.14)], [0.06, 0.07], (0.6, 0.6, 0.6), cls=SCALE, bones=["thorax", "abdomen"], tint=1.0, seg=10)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# cephalothorax: a shield with a central fovea and radial grooves, a raised eye mound in front
TC = V(0, BY + 0.04, 0.16)


def ceph_shape(d):
    p = V(d.x * 0.22, d.y * 0.15, d.z * 0.26)
    if d.y > 0:
        p.y *= 1.0 - 0.25 * smooth(0.0, 1.0, -d.z)      # the shield slopes down behind
        p.y += 0.04 * smooth(0.3, 1.0, d.z) * smooth(0.2, 0.9, d.y)   # the eye mound
    q = p.copy()
    p = p - p.normalized() * 0.02 * blob3(q, (0, 0.13, -0.02), (0.03, 0.03, 0.04))
    return p


def ceph_col(p, d):
    v = 0.74 + 0.2 * smooth(0.1, -0.7, d.y)
    a = math.atan2(p.x, p.z + 0.02)
    groove = smooth(0.92, 1.0, abs(math.cos(a * 4.0))) * smooth(0.2, 0.7, d.y)
    return ((v * (1.0 - 0.3 * groove)),) * 3


morph_sphere(b, TC, ceph_shape, ceph_col, cls=SCALE, bone="thorax", seg=24, rings=16, tint_fn=lambda p, d: 1.0)
# eight eyes in two rows: the big forward pair, a smaller pair either side and a row behind
for k, (x, y, rr) in enumerate(((0.035, 0.16, 0.034), (-0.035, 0.16, 0.034), (0.09, 0.15, 0.022), (-0.09, 0.15, 0.022), (0.04, 0.205, 0.02), (-0.04, 0.205, 0.02), (0.11, 0.19, 0.016), (-0.11, 0.19, 0.016))):
    c = V(x, BY + y, 0.39 - abs(x) * 0.5 - (0.03 if y > 0.2 else 0.0))
    b.ball(c, rr, "200810", cls=SKIN, bone="thorax", seg=10, rings=6)
    b.ball(c + V(0, 0, rr * 0.45), rr * 0.6, "ff3040", cls=SKIN, bone="thorax", seg=8, rings=5, mat=MAT_GLOW)
    b.ball(c + V(rr * 0.3, rr * 0.35, rr * 0.75), rr * 0.18, "ffffff", cls=SKIN, bone="thorax", seg=5, rings=3, mat=MAT_GLOW)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# chelicerae: two bulky bases, hairy in front, with curved black fangs folded under
for s in (1, -1):
    base = V(0.05 * s, BY + 0.02, 0.38)
    b.ellipsoid(base + V(0, -0.05, 0.03), (0.045, 0.07, 0.045), (0.55, 0.55, 0.55), cls=SCALE, bone="fangs", tint=1.0, seg=12, rings=8)
    strand(b, [base + V(0.005 * s, -0.1, 0.05), base + V(0.015 * s, -0.16, 0.08), base + V(-0.005 * s, -0.22, 0.06), base + V(-0.025 * s, -0.24, 0.02)], 0.022, 0.003, "201418", col_tip="503840", cls=STONE, bone="fangs", seg=8, per=3)
    for k in range(5):
        root = base + V(0.01 * s * k, -0.03 - 0.02 * k, 0.07)
        b.tube([root, root + V(0.02 * s, 0.01, 0.04)], [0.004, 0.001], (0.4, 0.4, 0.4), cls=HAIR, bone="fangs", tint=1.0, seg=3)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# legs: coxa, femur, patella, tibia, metatarsus and tarsus marked by joint bands, the femur
# thick, bristles along the outside, a pair of tarsal claws at the tip
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(4):
        nm = "leg%d.%s" % (k, sd)
        a0, a1 = V(r.bones[nm + "_a"][0]), V(r.bones[nm + "_a"][1])
        f1 = V(r.bones[nm + "_b"][1])
        ba, bb = nm + "_a", nm + "_b"
        knee_mid = a1.lerp(f1, 0.5) + V(0.04 * s, 0.04, 0)
        meta = knee_mid.lerp(f1, 0.62)
        # coxa and a thick, keeled femur; patella and tibia; metatarsus; a thin tarsus
        A.sclerite(b, a0 - (a1 - a0) * 0.04, a0.lerp(a1, 0.16), 0.05, 0.045, ba, col=0.7, seg=12, rings=6)
        A.sclerite(b, a0.lerp(a1, 0.13), a1, 0.05, 0.046, ba, col=0.76, keels=2, phase=math.pi / 2, ridge=0.1, seg=14, rings=10, blunt=0.5)
        A.sclerite(b, a1 - (knee_mid - a1) * 0.06, a1.lerp(knee_mid, 0.3), 0.042, 0.04, bb, col=0.66, seg=12, rings=6)
        A.sclerite(b, a1.lerp(knee_mid, 0.28), knee_mid, 0.036, 0.034, bb, col=0.78, seg=12, rings=8, blunt=0.5)
        A.sclerite(b, knee_mid - (meta - knee_mid) * 0.04, meta, 0.026, 0.025, bb, col=0.8, seg=10, rings=8, blunt=0.5)
        A.sclerite(b, meta, f1 + (f1 - meta) * 0.03, 0.018, 0.017, bb, col=0.72, seg=8, rings=6, taper=0.4)
        A.bristles(b, [a0.lerp(a1, t) + V(0, 0.05, 0) for t in (0.3, 0.5, 0.7)] + [a1.lerp(f1, t) + V(0.02 * s, 0.03, 0) for t in (0.2, 0.35, 0.5, 0.65, 0.8)], 0.05, (0.4, 0.4, 0.4), lambda p, ba=ba, bb=bb, a1=a1: ba if p.y > a1.y - 0.02 and (p - a1).length > 0.15 and p.y > BY else bb, seed=k * 2 + (s > 0))
        for c in (-1, 1):
            b.tube([f1, f1 + V(0.01 * c, -0.01, 0.015), f1 + V(0.015 * c, -0.025, 0.005)], [0.005, 0.003, 0.001], "201418", cls=STONE, bone=bb, seg=4)
    pa = r.bones["palp." + sd]
    p0, p1 = V(pa[0]), V(pa[1])
    b.tube([p0, p0.lerp(p1, 0.5) + V(0, 0.03, 0), p1], [0.03, 0.026, 0.022], (0.65, 0.65, 0.65), cls=SCALE, bone="palp." + sd, tint=1.0, seg=8)
    b.ellipsoid(p1 + V(0, -0.005, 0.02), (0.035, 0.03, 0.04), (0.45, 0.45, 0.45), cls=SCALE, bone="palp." + sd, tint=1.0, seg=10, rings=6)

T_IDLE = 2.4
T_WALK = 1.0
# alternating tetrapods: L0 R1 L2 R3 swing together, then R0 L1 R2 L3
WALK = Walker(r, [(a_, b_) for a_, b_, _ in legs], [0.0 if ((i // 4 == 0) == (i % 4 % 2 == 0)) else 0.5 for i in range(8)], duty=0.55)


def body(p, t, T, amp=1.0):
    w = 2 * math.pi / T
    add(p, "thorax", (math.sin(t * w) * 0.03 * amp, math.sin(t * w + 1.0) * 0.04 * amp, 0), (0, 0.01 * math.sin(t * w * 2) * amp, 0))
    add(p, "abdomen", (math.sin(t * w - 0.6) * 0.08 * amp, math.sin(t * w + 0.6) * 0.05 * amp, 0))
    add(p, "fangs", (0.1 * max(0.0, math.sin(t * w * 2)) ** 3, 0, 0))
    for sd, sg in (("L", 1), ("R", -1)):
        add(p, "palp." + sd, (math.sin(t * w * 2 + sg) * 0.2, 0, 0))


def idle(t):
    p = zero_pose(r)
    body(p, t, T_IDLE)
    # the feet stay planted while the body breathes and sways over them; one foreleg taps
    tap = max(0.0, math.sin(2 * math.pi * t / T_IDLE)) ** 4
    offs = [(0.0, 0.06 * tap if i == 0 else 0.0, 0.03 * tap if i == 0 else 0.0) for i in range(8)]
    return WALK.step(p, offsets=offs)


def walk(t):
    p = zero_pose(r)
    body(p, t, T_WALK, 0.6)
    ph = (t / T_WALK) % 1.0
    add(p, "thorax", (0, 0, 0), (0, 0.015 * abs(math.sin(2 * math.pi * ph * 2)), 0))
    return WALK.step(p, ph, 0.26, 0.09)


def attack(t):
    k = t / 0.55
    rear = smooth(0.0, 0.3, k) * (1.0 - smooth(0.32, 0.42, k))
    strike = smooth(0.3, 0.42, k) * (1.0 - smooth(0.62, 1.0, k))
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.06 * rear, 0.35 * strike))
    add(p, "thorax", (-0.3 * rear + 0.2 * strike, 0, 0))
    add(p, "abdomen", (0.25 * rear, 0, 0))
    add(p, "fangs", (0.9 * smooth(0.28, 0.4, k) * (1.0 - smooth(0.5, 0.7, k)), 0, 0))
    offs = []
    for i in range(8):
        front = i % 4 == 0
        offs.append((0.0, (0.35 * rear + 0.1 * strike) if front else 0.0, (0.15 * rear + 0.35 * strike) if front else 0.35 * strike))
    return WALK.step(p, offsets=offs)


def hurt(t):
    k = t / 0.55
    e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
    p = zero_pose(r)
    add(p, "root", (0, 0, 0), (0, 0.04 * e, -0.15 * e))
    add(p, "thorax", (-0.3 * e, 0, 0.1 * e))
    add(p, "abdomen", (0.3 * e, 0.2 * e, 0))
    offs = [(0.0, 0.05 * e * (1 if i % 2 else 0), -0.15 * e) for i in range(8)]
    return WALK.step(p, offsets=offs)


def die(t):
    """Staggers, rolls onto its back and curls its legs up over its belly."""
    p = zero_pose(r)
    k = min(1.0, t / 1.2)
    p = WALK.step(p, offsets=[(0.0, 0.1 * smooth(0.0, 0.3, k) * (i % 2), 0.0) for i in range(8)])
    curl = []
    for a_, b_, _ in legs:
        sg = 1 if a_.endswith(".L_a") else -1
        curl.append((a_, (0.0, 0.0, -1.1 * sg)))
        curl.append((b_, (0.0, 0.0, -1.6 * sg)))
    flip_die(p, t, 1.2, BY, side=1, curl_legs=curl, rest=0.12)
    return p


def cast(t):
    e = math.sin(math.pi * min(1.0, t / 0.6))
    p = zero_pose(r)
    # rears up and raises the abdomen to spray web
    add(p, "thorax", (-0.35 * e, 0, 0), (0, 0.12 * e, 0))
    add(p, "abdomen", (-0.6 * e, 0, 0))
    offs = [(0.0, 0.35 * e if i % 4 == 0 else 0.0, 0.1 * e if i % 4 == 0 else 0.0) for i in range(8)]
    return WALK.step(p, offsets=offs)


print("[art] spider: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/spider.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=16, dist=0.3, strength=0.5, floor_y=0.0)
