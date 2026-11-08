"""Carp: the golden koi of the Hanging Falls and the river carp of the Nine Bends (Part VI).  A
deep-bodied fish hovering above the ground as if it swam through air: overlapping scales, a
dorsal fin, long flowing pectoral, pelvic and tail fins made of layered ribbons, barbels at the
mouth and a pearl-like eye.  The body is a five-bone chain so it swims with a travelling wave.
Tinted by the game per enemy; white patches (koi markings), eyes and barbels keep their colours.
Scales are painted as rows of overlapping cycloid scales with darker rims, a lateral
line runs down each flank, the gill cover has its edge, and fine rays stiffen every fin.
Run: blender --background --python art/monsters/carp.py  ->  assets/monsters/carp.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
from creature import chain_weights, zero_pose  # noqa: E402
from sculpt import fbm3, smooth  # noqa: E402
from clay import Clay  # noqa: E402
import anatomy as A  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, MAT_PLAIN, SCALE, SKIN, V, Builder, Rig, env  # noqa: E402
from creature import add  # noqa: E402

kit.reset()
creature.realtime()
Y = 1.05
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
zs = [0.75, 0.38, 0.0, -0.38, -0.72, -1.02]
for i in range(5):
    r.bone("body%d" % i, (0, Y, zs[i]), (0, Y, zs[i + 1]), "root" if i == 0 else "body%d" % (i - 1))
r.bone("tailfin", (0, Y, zs[5]), (0, Y, zs[5] - 0.4), "body4")
r.bone("jaw", (0, Y - 0.05, 0.62), (0, Y - 0.08, 0.86), "body0")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("pec." + sd, (0.18 * s, Y - 0.12, 0.42), (0.42 * s, Y - 0.3, 0.2), "body0")
    r.bone("pelv." + sd, (0.12 * s, Y - 0.2, -0.15), (0.3 * s, Y - 0.42, -0.35), "body2")
b = Builder("carp")


def body_bone(z):
    f = 0.0
    for i in range(5):
        if z <= zs[i] and z >= zs[i + 1]:
            f = i + (zs[i] - z) / (zs[i] - zs[i + 1])
            break
    if z > zs[0]:
        f = 0.0
    if z < zs[5]:
        f = 4.99
    return chain_weights("body", f, 5)


def koi_patch(p):
    """Where the white koi markings fall (they keep their colour)."""
    n = math.sin(p.z * 5.5 + p.x * 9.0) * math.cos(p.z * 3.1 - p.y * 7.0) + 0.25 * (fbm3((p.x * 4, p.y * 4, p.z * 4), 2, 21) - 0.5)
    return n > 0.38 and p.y > Y - 0.02


# body: one sculpted piece - a deep, round-backed koi with a blunt head, a soft belly and a slim
# tail stalk - painted with rows of overlapping cycloid scales, the lateral line, a darker back
# and a silvery belly, and white koi patches
cl = Clay(0.016, "koi_body")
# laterally compressed: each cross-section is taller than it is wide
for z, dy, ry in ((0.84, 0.0, 0.09), (0.66, 0.02, 0.18), (0.42, 0.04, 0.24), (0.14, 0.04, 0.26), (-0.16, 0.03, 0.24),
                  (-0.44, 0.02, 0.19), (-0.7, 0.0, 0.12), (-0.9, 0.0, 0.07), (-1.03, 0.0, 0.05)):
    cl.ellipsoid(V(0, Y + dy, z), (ry * 0.74, ry, 0.2), bones=lambda p, t: body_bone(p.z), tag="head" if z > 0.55 else "body")
cl.ellipsoid(V(0, Y - 0.06, 0.15), (0.17, 0.17, 0.4), bones=lambda p, t: body_bone(p.z), tag="belly")
cl.ellipsoid(V(0, Y - 0.05, 0.86), (0.07, 0.05, 0.06), bones={"jaw": 1.0}, tag="lips")


def body_col(p, info):
    if info.tag == "lips":
        return (0.8, 0.8, 0.8)
    if koi_patch(p):
        return (1.0, 1.0, 1.0)
    sx = (0.9 - p.z) * 9.0
    ang = math.atan2(p.y - Y, abs(p.x) + 1e-4)
    sy = ang * 3.2 + 0.5 * (math.floor(sx) % 2)
    fx, fy = sx - math.floor(sx), sy - math.floor(sy)
    rim = 1.0 - 0.22 * smooth(0.28, 0.48, math.hypot(fx - 0.3, fy - 0.5))
    lateral = 1.0 - 0.3 * smooth(0.015, 0.0, abs(p.y - Y - 0.02 - 0.03 * math.sin(p.z * 2.0)))
    v = (0.86 if p.y > Y else 1.0) * (1.0 - 0.18 * smooth(Y + 0.1, Y + 0.25, p.y))
    if p.z > 0.6:
        rim = 1.0
    gill = 1.0 - 0.3 * smooth(0.02, 0.0, abs(p.z - 0.5 + 0.12 * ((p.y - Y) / 0.2) ** 2)) * smooth(0.05, 0.12, abs(p.x))
    v *= rim * lateral * gill
    return (v, v, v)


def body_tint(p, info):
    if info.tag == "lips":
        return 0.6
    return 0.0 if koi_patch(p) else 1.0


cl.build(b, body_col, cls=SCALE, tint_fn=body_tint)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# mouth and two pairs of barbels, the upper pair long and drooping
b.ellipsoid(V(0, Y - 0.05, 0.915), (0.04, 0.025, 0.02), "301018", cls=SKIN, bone="jaw", seg=10, rings=5)
for s in (1, -1):
    A.horn(b, [V(0.05 * s, Y - 0.04, 0.87), V(0.13 * s, Y - 0.1, 0.9), V(0.22 * s, Y - 0.22, 0.86), V(0.27 * s, Y - 0.38, 0.8)], 0.013, "e8d0a0", "f8f0d8", "jaw", r1=0.002, cls=SKIN, seg=6)
    A.horn(b, [V(0.04 * s, Y - 0.07, 0.86), V(0.08 * s, Y - 0.12, 0.86), V(0.11 * s, Y - 0.17, 0.83)], 0.009, "e8d0a0", "f8f0d8", "jaw", r1=0.002, cls=SKIN, seg=6)
    A.animal_eye(b, V(0.128 * s, Y + 0.06, 0.68), V(0.9 * s, 0.05, 0.4), 0.04, "f0d060", "body0", pupil="round", almond=0.95, side=s, lid="303030", lid_w=0.08)
    # gill cover edge and nostrils
    b.ellipsoid(V(0.055 * s, Y + 0.07, 0.82), (0.013, 0.009, 0.009), "201018", cls=SKIN, bone="body0", seg=6, rings=4, mat=MAT_PLAIN)
b.ellipsoid(V(0, Y + 0.185, 0.58), (0.07, 0.025, 0.1), "f0c050", cls=SCALE, bone="body0", seg=12, rings=6)


def fin_sheet(rows_pts, bones, col0=0.9, col1=1.0, rays=True, bone_of=None):
    """A soft fin: a grid of points (rows from root to edge), paler towards the edge, with fine
    dark rays along it."""
    nr = len(rows_pts)
    cols = [(col0 + (col1 - col0) * (j / (nr - 1)),) * 3 for j in range(nr)]
    b.sheet(rows_pts, (col0,) * 3, cls=CLOTH, bones=bones, cols=cols, tint=1.0, thickness=0.006)
    if rays:
        for i in range(0, len(rows_pts[0]), 2):
            ray = [rows_pts[j][i] for j in range(nr)]
            bb = bone_of(i) if bone_of else bones[0]
            b.tube(ray, [0.005] + [0.003] * (nr - 2) + [0.001], (0.6, 0.6, 0.6), cls=CLOTH, bone=bb, tint=1.0, seg=4, mat=MAT_PLAIN)


# long, flowing fins in the secondary colour - a butterfly koi's: a dorsal fin running down the
# back, a broad twin-lobed tail trailing far behind, long pectoral and pelvic fins
dors = []
for j in range(5):
    t = j / 4
    row = []
    for i in range(8):
        u = i / 7
        z = 0.38 - u * 0.85 - t * 0.18 * (0.3 + u)
        h = 0.06 + t * (0.3 * math.sin(math.pi * min(1.0, u * 1.15 + 0.05)) + 0.04)
        row.append(V(0.02 * t * math.sin(u * 9.0), Y + 0.25 - 0.06 * u + h, z))
    dors.append(row)
fin_sheet(dors, [{"body1": 0.5, "body2": 0.5}] * 5)
def fan(root, axis_a, axis_b, length_fn, u0, u1, bones, nrm, n_rows=6, n_cols=11, wave=0.035):
    """A fin as a fan of rays from its root: columns sweep from angle u0 to u1 in the plane of
    axis_a/axis_b, each ray length_fn(u) long, the membrane rippling off the plane towards its
    edge."""
    axis_a, axis_b, nrm = V(axis_a).normalized(), V(axis_b).normalized(), V(nrm).normalized()
    rows = []
    for j in range(n_rows):
        t = j / (n_rows - 1)
        row = []
        for i in range(n_cols):
            u = u0 + (u1 - u0) * i / (n_cols - 1)
            d = axis_a * math.cos(u) + axis_b * math.sin(u)
            row.append(V(root) + d * (length_fn(u) * t) + nrm * (wave * math.sin(i * 1.9 + t * 3.0) * t))
        rows.append(row)
    fin_sheet(rows, bones)


# the tail: a deep fork, its two lobes long and trailing
fan(V(0, Y, -1.0), (0, 0, -1), (0, 1, 0), lambda u: 0.42 + 0.42 * abs(u) ** 1.3, -1.05, 1.05, ["body4"] + ["tailfin"] * 5, (1, 0, 0), n_cols=13)
for s, sd in ((1, "L"), (-1, "R")):
    # long pectorals drooping like sleeves, short pelvics
    fan(V(0.15 * s, Y - 0.13, 0.44), (0.55 * s, -0.45, -0.35), (0.0, -0.2, -1.0), lambda u: 0.42 - 0.12 * abs(u - 0.55), 0.0, 1.1, ["body0"] + ["pec." + sd] * 5, (s, 0.3, 0))
    fan(V(0.1 * s, Y - 0.2, -0.14), (0.4 * s, -0.6, -0.3), (0.0, -0.2, -1.0), lambda u: 0.26 - 0.08 * abs(u - 0.5), 0.0, 1.0, ["body2"] + ["pelv." + sd] * 5, (s, 0.2, 0), n_rows=5, n_cols=8)
b.cur_pal = 0.0


# a sparkle of pearl bubbles trailing from the mouth
for k in range(5):
    b.ball(V(0.02 * math.sin(k * 2.0), Y + 0.06 + k * 0.09, 0.95 + 0.02 * k), 0.018 + 0.006 * (k % 2), "f0f8ff", cls=CRYSTAL, bone="jaw", seg=6, rings=4, mat=MAT_GLOW)


T_IDLE = 2.4


def swim(p, t, speed, amp, hover=0.05, fin=1.3, pelv=1.1, bob=0.5, fin_amp=1.0):
    """Travelling wave down the body.  Loops pass fin/pelv/bob ratios that give whole cycles."""
    for i in range(5):
        p["body%d" % i] = ((0, math.sin(t * speed - i * 0.9) * amp * (0.4 + i * 0.25), 0), (0, 0, 0))
    p["tailfin"] = ((0, math.sin(t * speed - 5 * 0.9) * amp * 1.8, 0), (0, 0, 0))
    p["root"] = ((math.sin(t * speed * bob) * 0.04, 0, 0), (0, math.sin(t * speed * bob) * hover, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["pec." + sd] = ((math.sin(t * speed * fin) * 0.3 * fin_amp, 0, math.sin(t * speed * fin + 0.5) * 0.25 * s * fin_amp), (0, 0, 0))
        p["pelv." + sd] = ((math.sin(t * speed * pelv + 1.0) * 0.2 * fin_amp, 0, 0), (0, 0, 0))


def idle(t):
    p = zero_pose(r)
    swim(p, t, 2 * math.pi / T_IDLE * 2, 0.14, fin=1.5, pelv=1.0, bob=0.5)
    p["jaw"] = ((0.1 + 0.1 * max(0.0, math.sin(t * 2 * math.pi / T_IDLE * 3)), 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.5) * math.pi)
    p = zero_pose(r)
    # the thrash builds and settles with the strike instead of snapping back to the idle swim
    swim(p, t, 16.0, 0.08 + 0.14 * e)
    p["root"] = ((0.15 * lunge, 0, 0), (0, 0.1 * lunge, 0.6 * lunge))
    p["jaw"] = ((0.6 * lunge, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = zero_pose(r)
    swim(p, t, 20.0, 0.25 * e)
    p["root"] = ((-0.3 * e, 0, 0.4 * e), (0, 0, -0.15 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = zero_pose(r)
    # leap: arch the body like a carp climbing the dragon gate
    for i in range(5):
        p["body%d" % i] = ((-0.25 * e, 0, 0), (0, 0, 0))
    p["tailfin"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["root"] = ((-0.5 * e, 0, 0), (0, 0.4 * e, 0))
    return p


T_WALK = 1.2


def walk(t):
    """Swims through the air: a stronger travelling wave and beating pectoral fins."""
    p = zero_pose(r)
    swim(p, t, 2 * math.pi / T_WALK, 0.2, hover=0.04, fin=2.0, pelv=1.0, bob=1.0)
    add(p, "root", (0.06, 0, 0))
    return p


def die(t):
    """Thrashes, rolls belly-up and sinks to the ground."""
    k = min(1.0, t / 1.2)
    f = smooth(0.15, 0.8, k) ** 1.3
    roll = smooth(0.1, 0.6, k)
    p = zero_pose(r)
    swim(p, t, 20.0 * (1.0 - f) + 0.5, 0.25 * (1.0 - f), hover=0.05 * (1.0 - f), fin_amp=1.0 - f)
    add(p, "root", (0, 0, math.pi * roll), (0, -0.82 * f, 0))
    for i in range(5):
        add(p, "body%d" % i, (0.05 * f, 0, 0))
    return p

print("[art] carp: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/carp.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.45)
