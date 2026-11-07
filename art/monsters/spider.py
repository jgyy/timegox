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
import anatomy as A  # noqa: E402
from creature import leg_chain, scuttle, zero_pose  # noqa: E402
from kit import HAIR, MAT_GLOW, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402
from sculpt import blob3, fbm3, morph_sphere, smooth, strand  # noqa: E402

kit.reset()
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


def abd_shape(d):
    p = V(d.x * 0.36, d.y * 0.32, d.z * 0.46)
    if d.z < 0:
        p.x *= 1.0 - 0.25 * smooth(0.3, 1.0, -d.z)
        p.y *= 1.0 - 0.2 * smooth(0.3, 1.0, -d.z)
    return p


def abd_col(p, d):
    v = 0.6 + 0.35 * smooth(0.2, -0.8, d.y)
    if d.y > -0.1:
        z = (p.z + 0.46) / 0.92                          # 0 at the back, 1 at the front
        chev = abs(((z * 5.0 + abs(p.x) * 4.0) % 1.0) - 0.5)
        if abs(p.x) < 0.22 * (0.4 + z):
            v *= 0.55 if chev < 0.18 else 1.05
    v *= 0.9 + 0.2 * fbm3((p.x * 12, p.y * 12, p.z * 12), 2, 8)
    return (v, v, v)


abd = morph_sphere(b, AC, abd_shape, abd_col, cls=SCALE, bone="abdomen", seg=28, rings=18, tint_fn=lambda p, d: 1.0)
A.fur(b, abd, 160, 0.05, 0.012, seed=6, bone_fn=lambda p: "abdomen", min_dist=0.04, col_root=(0.5, 0.5, 0.5), col_tip=(0.85, 0.85, 0.85),
      groom=lambda p, n: (V(0, 0, -1) - n * n.z * -1).normalized() if abs(n.z) < 0.95 else V(0, 1, 0), lift=0.6)
for s in (1, -1):
    b.cone(AC + V(0.03 * s, -0.12, -0.46), 0.025, 0.07, (0.5, 0.5, 0.5), cls=SCALE, bone="abdomen", tint=1.0, seg=8, rot=(-1.9, 0, 0.2 * s))
b.cone(AC + V(0, -0.1, -0.47), 0.03, 0.08, (0.45, 0.45, 0.45), cls=SCALE, bone="abdomen", tint=1.0, seg=8, rot=(-1.9, 0, 0))
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# pedicel joining the two halves
b.tube([V(0, BY + 0.04, -0.02), V(0, BY + 0.08, -0.14)], [0.06, 0.07], (0.6, 0.6, 0.6), cls=SCALE, bones=["thorax", "abdomen"], tint=1.0, seg=10)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
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
    v = 0.62 + 0.28 * smooth(0.1, -0.7, d.y)
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
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# chelicerae: two bulky bases, hairy in front, with curved black fangs folded under
for s in (1, -1):
    base = V(0.05 * s, BY + 0.02, 0.38)
    b.ellipsoid(base + V(0, -0.05, 0.03), (0.045, 0.07, 0.045), (0.55, 0.55, 0.55), cls=SCALE, bone="fangs", tint=1.0, seg=12, rings=8)
    strand(b, [base + V(0.005 * s, -0.1, 0.05), base + V(0.015 * s, -0.16, 0.08), base + V(-0.005 * s, -0.22, 0.06), base + V(-0.025 * s, -0.24, 0.02)], 0.022, 0.003, "201418", col_tip="503840", cls=STONE, bone="fangs", seg=8, per=3)
    for k in range(5):
        root = base + V(0.01 * s * k, -0.03 - 0.02 * k, 0.07)
        b.tube([root, root + V(0.02 * s, 0.01, 0.04)], [0.004, 0.001], (0.4, 0.4, 0.4), cls=HAIR, bone="fangs", tint=1.0, seg=3)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# legs: coxa, femur, patella, tibia, metatarsus and tarsus marked by joint bands, the femur
# thick, bristles along the outside, a pair of tarsal claws at the tip
for s, sd in ((1, "L"), (-1, "R")):
    for k in range(4):
        nm = "leg%d.%s" % (k, sd)
        a0, a1 = V(r.bones[nm + "_a"][0]), V(r.bones[nm + "_a"][1])
        f1 = V(r.bones[nm + "_b"][1])
        ba, bb = nm + "_a", nm + "_b"
        femur = [a0, a0.lerp(a1, 0.35) + V(0, 0.06, 0), a0.lerp(a1, 0.75) + V(0, 0.03, 0), a1]
        b.tube(femur, [0.04, 0.047, 0.042, 0.035], (0.7, 0.7, 0.7), cls=SCALE, bones=[ba, ba, ba, {ba: 0.5, bb: 0.5}], tint=1.0, seg=10)
        knee_mid = a1.lerp(f1, 0.55) + V(0.04 * s, 0.03, 0)
        lower = [a1, a1.lerp(knee_mid, 0.5), knee_mid, knee_mid.lerp(f1, 0.6), f1]
        b.tube(lower, [0.034, 0.03, 0.025, 0.017, 0.007], (0.78, 0.78, 0.78), cls=SCALE, bones=[{ba: 0.5, bb: 0.5}, bb, bb, bb, bb], tint=1.0, seg=8)
        for q, rr in ((a0.lerp(a1, 0.12), 0.046), (a1, 0.038), (knee_mid, 0.028), (knee_mid.lerp(f1, 0.6), 0.02)):
            b.ellipsoid(q, (rr, rr * 0.7, rr), (0.45, 0.45, 0.45), cls=SCALE, bone=bb if q != a0.lerp(a1, 0.12) else ba, tint=1.0, seg=8, rings=5)
        A.bristles(b, [a0.lerp(a1, t) + V(0, 0.05, 0) for t in (0.3, 0.5, 0.7)] + [a1.lerp(f1, t) + V(0.02 * s, 0.03, 0) for t in (0.2, 0.35, 0.5, 0.65, 0.8)], 0.05, (0.4, 0.4, 0.4), lambda p, ba=ba, bb=bb, a1=a1: ba if p.y > a1.y - 0.02 and (p - a1).length > 0.15 and p.y > BY else bb, seed=k * 2 + (s > 0))
        for c in (-1, 1):
            b.tube([f1, f1 + V(0.01 * c, -0.01, 0.015), f1 + V(0.015 * c, -0.025, 0.005)], [0.005, 0.003, 0.001], "201418", cls=STONE, bone=bb, seg=4)
    pa = r.bones["palp." + sd]
    p0, p1 = V(pa[0]), V(pa[1])
    b.tube([p0, p0.lerp(p1, 0.5) + V(0, 0.03, 0), p1], [0.03, 0.026, 0.022], (0.65, 0.65, 0.65), cls=SCALE, bone="palp." + sd, tint=1.0, seg=8)
    b.ellipsoid(p1 + V(0, -0.005, 0.02), (0.035, 0.03, 0.04), (0.45, 0.45, 0.45), cls=SCALE, bone="palp." + sd, tint=1.0, seg=10, rings=6)

T_IDLE = 2.2


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    scuttle(p, legs, t, w, 0.05, 0.03)
    p["thorax"] = ((math.sin(t * w) * 0.03, 0, 0), (0, abs(math.sin(t * w)) * 0.015, 0))
    p["abdomen"] = ((math.sin(t * w * 0.5) * 0.08, math.sin(t * w * 0.7) * 0.06, 0), (0, 0, 0))
    p["fangs"] = ((0.1 * max(0.0, math.sin(t * w * 2)), 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["palp." + sd] = ((math.sin(t * w * 2 + s) * 0.2, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.1 * lunge, 0.4 * lunge))
    p["thorax"] = ((0.25 * e - 0.4 * lunge, 0, 0), (0, 0, 0))
    p["fangs"] = ((0.8 * lunge, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["leg0.%s_a" % sd] = ((-0.9 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["thorax"] = ((-0.3 * e, 0, 0.1 * e), (0, 0, -0.08 * e))
    scuttle(p, legs, t, 40.0, 0.2 * e, 0.1 * e)
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    # rear up, abdomen raised to spray web
    p["thorax"] = ((-0.35 * e, 0, 0), (0, 0.12 * e, 0))
    p["abdomen"] = ((-0.6 * e, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["leg0.%s_a" % sd] = ((-1.0 * e, 0, 0), (0, 0, 0))
        p["leg1.%s_a" % sd] = ((-0.6 * e, 0, 0), (0, 0, 0))
    return p


print("[art] spider: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/spider.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
