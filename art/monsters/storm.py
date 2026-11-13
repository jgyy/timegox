"""Storm: thunderheads with a temper (the Thunder Spirit, the Lightning Magistrate, the Stray Gust,
the Heavenly Tribulation ...).

Designed silhouette first, after Lei Gong, the Lord of Thunder, who makes thunder on a ring of
drums (the Raijin of Sotatsu's screens stands inside a circle of them): a spirit whose head and
shoulders are a towering thunderhead, its body narrowing below into a funnel of wind that trails
rain and forks of lightning down towards the ground (no flat base: it is weather, not a hat), and
behind its shoulders a great ring of drums on a hoop - the shape that names it from across a
field.  The cloud is built of clean round billows (the auspicious clouds of Chinese decoration
are lobes, not noise): pale where the sun is on them, blue-grey on the flanks, dark beneath, so it
reads as masses.  A scowling brow of dark cloud over two burning eyes; arms of cloud with a
drumstick in each fist; lightning glowing in veins through the billows.  Tinted by the game.
Run: blender --background --python art/monsters/storm.py  ->  assets/monsters/storm.glb"""
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
from kit import CLOTH, CRYSTAL, MAT_GLOW, MAT_PLAIN, METAL, SKIN, WOOD, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, smooth  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(7)
Y = 2.0
RING_C = V(0, Y + 0.38, -0.78)
RING_R = 1.18
N_DRUMS = 8
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, Y - 0.6, 0), (0, Y + 0.8, 0), "root")
r.bone("head", (0, Y + 0.32, 0.12), (0, Y + 0.72, 0.3), "body")
r.bone("halo", RING_C, RING_C + V(0, 0.3, 0), "body")
r.bone("bolts", (0, Y - 0.6, 0), (0, 0.1, 0), "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm." + sd, (0.62 * s, Y + 0.12, 0.05), (1.05 * s, Y - 0.22, 0.55), "body")
b = Builder("storm")

# ---------------------------------------------------------------- the thunderhead: head, shoulders and a funnel of wind
# cumulus: each mass is a core covered with smaller billows, so the outline is scalloped all round
cloud = Clay(0.04, "storm_cloud")


def mass(c, R, tag="cloud", bone="body", n=26, keep=None, squash=(1.0, 1.0, 1.0), lobe=0.36, seed=0):
    c = V(c)
    rr = random.Random(seed)
    cloud.ellipsoid(c, (R * 0.78 * squash[0], R * 0.78 * squash[1], R * 0.78 * squash[2]), bones={bone: 1.0}, tag=tag)
    for k in range(n):
        y = 1.0 - 2.0 * (k + 0.5) / n
        q = math.sqrt(max(0.0, 1.0 - y * y))
        a = k * 2.399963 + seed
        d = V(math.cos(a) * q, y, math.sin(a) * q)
        if keep is not None and not keep(d):
            continue
        p = c + V(d.x * R * 0.74 * squash[0], d.y * R * 0.74 * squash[1], d.z * R * 0.74 * squash[2])
        cloud.ball(p, R * lobe * rr.uniform(0.8, 1.2), bones={bone: 1.0}, tag=tag)


# the head: a towering billow, its front left smooth for the face
mass((0, Y + 0.62, 0.05), 0.44, "head", "head", n=30, keep=lambda d: d.z < 0.55 or d.y > 0.6, seed=1)
# shoulders and chest: broad billows piled up round the head
mass((0, Y + 0.12, 0.02), 0.56, n=34, squash=(1.15, 0.85, 0.95), seed=2)
for s in (1, -1):
    mass((0.62 * s, Y + 0.32, -0.08), 0.36, n=22, seed=3 + s)
    mass((0.42 * s, Y + 0.7, -0.3), 0.26, n=16, seed=5 + s)
mass((0, Y + 0.38, -0.36), 0.42, n=22, seed=8)
# the body narrows into a funnel of wind that turns as it falls
for k in range(6):
    t = k / 5
    a = t * 2.4
    rad = 0.36 * (1.0 - t) ** 1.1 + 0.07
    mass((math.sin(a) * 0.12 * t, Y - 0.38 - 0.9 * t, math.cos(a) * 0.08 * t - 0.05), rad, "funnel", n=10, lobe=0.42, seed=10 + k)


def billow(p, info):
    # a little unevenness over the billows
    g = fbm3((p.x * 3.0, p.y * 3.0, p.z * 3.0), 2, 3) - 0.5
    return info.n * (0.03 * g)


def cloud_col(p, info):
    n = info.n
    lit = smooth(-0.5, 0.75, n.y + 0.25 * n.z)
    h = smooth(Y - 1.2, Y + 1.0, p.y)
    v = 0.48 + 0.4 * lit + 0.14 * h
    if info.tag == "funnel":
        v -= 0.1 * smooth(Y - 0.4, Y - 1.3, p.y)
    return (min(1.0, v),) * 3


cloud.build(b, cloud_col, cls=CLOTH, tint_fn=lambda p, info: 1.0, post=billow)
hit = A.surface(b)

# ---------------------------------------------------------------- the face: a scowling brow of dark cloud over burning eyes
def on_cloud(x, y):
    h = hit(V(x, y, 2.5), V(0, 0, -1), 4.0)
    return (h[0], h[1]) if h is not None else (V(x, y, 0.5), V(0, 0, 1))


brow = Clay(0.03, "storm_brow")
for s in (1, -1):
    p, n = on_cloud(0.14 * s, Y + 0.72)
    brow.chain([p + V(-0.05 * s, -0.04, 0.0) + n * 0.03, p + V(0.1 * s, 0.03, 0.0) + n * 0.02, p + V(0.24 * s, 0.08, -0.07)], [0.07, 0.065, 0.04],
               bones={"head": 1.0}, tag="brow")
brow.build(b, lambda p, info: (0.5, 0.5, 0.5), cls=CLOTH, tint_fn=lambda p, info: 1.0)
for s in (1, -1):
    p, n = on_cloud(0.14 * s, Y + 0.6)
    rot = (0.0, math.atan2(n.x, n.z), -0.3 * s)
    # a dark hollow of storm-cloud, and in it the lightning looking out
    b.ellipsoid(p + n * 0.004, (0.088, 0.052, 0.035), "262a44", cls=CLOTH, bone="head", rot=rot, seg=16, rings=8, mat=MAT_PLAIN)
    b.cur_pal = 1.0
    b.ellipsoid(p + n * 0.022, (0.07, 0.034, 0.02), (1.0, 1.0, 1.0), cls=CLOTH, bone="head", tint=1.0, rot=rot, seg=14, rings=7, mat=MAT_GLOW)
    b.ellipsoid(p + n * 0.034, (0.03, 0.016, 0.01), (1.0, 1.0, 1.0), cls=CLOTH, bone="head", tint=0.2, rot=rot, seg=10, rings=5, mat=MAT_GLOW)
    b.cur_pal = 0.0
# a grim mouth: a jagged dark slit
p, n = on_cloud(0.0, Y + 0.42)
pts = [p + V(x * 0.16, 0.02 * math.sin(x * 9.0) - 0.035 * x * x, 0.0) + n * 0.012 for x in [i / 6 * 2 - 1 for i in range(7)]]
b.tube(pts, [0.016, 0.022, 0.026, 0.028, 0.026, 0.022, 0.016], "141428", cls=SKIN, bone="head", seg=6, mat=MAT_PLAIN)

# ---------------------------------------------------------------- cloud arms, a drumstick in each fist
for s, sd in ((1, "L"), (-1, "R")):
    ar = r.bones["arm." + sd]
    a0, a1 = V(ar[0]), V(ar[1])
    arm = Clay(0.035, "storm_arm_" + sd)
    for k in range(5):
        t = k / 4
        cc = a0.lerp(a1, t) + V(0, 0.06 * math.sin(t * 3.0), 0)
        arm.ball(cc, 0.2 - 0.04 * t, bones={"arm." + sd: 1.0}, tag="arm")
        for j in range(4):
            q = j / 4 * 2 * math.pi + k
            arm.ball(cc + V(0.0, math.cos(q) * 0.15, math.sin(q) * 0.15) * (1.0 - 0.2 * t), 0.1, bones={"arm." + sd: 1.0}, tag="arm")
    for j in range(6):
        q = j / 6 * 2 * math.pi
        arm.ball(a1 + V(0.03 * s, -0.03, 0.06) + V(math.cos(q) * 0.11, math.sin(q) * 0.11, 0.05 * math.sin(q * 2)), 0.11, bones={"arm." + sd: 1.0}, tag="fist")
    arm.ball(a1 + V(0.03 * s, -0.03, 0.06), 0.15, bones={"arm." + sd: 1.0}, tag="fist")
    arm.build(b, cloud_col, cls=CLOTH, tint_fn=lambda p, info: 1.0, post=billow)
    # the drumstick: a lacquered handle and a round striking head
    d = (a1 - a0).normalized()
    grip = a1 + V(0.04 * s, -0.02, 0.1)
    tip = grip + (V(0.1 * s, 0.75, 0.35)).normalized() * 0.72
    b.tube([grip - (tip - grip) * 0.25, tip], [0.034, 0.028], "6a3a24", cls=WOOD, bone="arm." + sd, seg=8)
    b.cur_pal = 0.5
    b.ball(tip, 0.1, (0.95, 0.95, 0.95), cls=WOOD, bone="arm." + sd, tint=1.0, seg=14, rings=9)
    b.cur_pal = 0.0

# ---------------------------------------------------------------- the ring of drums on its hoop, behind the shoulders
b.cur_pal = 0.0
hoop = [RING_C + V(math.cos(a) * RING_R, math.sin(a) * RING_R, 0.0) for a in [i / 48 * 2 * math.pi for i in range(49)]]
b.tube(hoop, [0.042] * 49, "4a3020", cls=WOOD, bone="halo", seg=8, cap0=False, cap1=False)
for k in range(N_DRUMS):
    a = math.pi / 2 + 2 * math.pi * k / N_DRUMS
    c = RING_C + V(math.cos(a) * RING_R, math.sin(a) * RING_R, 0.0)
    # a barrel drum facing forward, its body lacquered (the second colour), its heads pale hide
    b.cur_pal = 0.5
    b.lathe(c, [(0.15, -0.11), (0.18, -0.055), (0.19, 0.0), (0.18, 0.055), (0.15, 0.11)], (0.92, 0.92, 0.92), cls=WOOD, bone="halo", seg=18,
            rot=(math.pi / 2, 0, 0), tint=1.0, cap_bottom=False, cap_top=False)
    b.cur_pal = 0.0
    for zz in (-1, 1):
        b.lathe(c + V(0, 0, 0.11 * zz), [(0.152, -0.006), (0.152, 0.006)], "e8dcc0", cls=SKIN, bone="halo", seg=18, rot=(math.pi / 2, 0, 0))
        # the comma swirl painted on the head
        b.cur_pal = 1.0
        b.ellipsoid(c + V(0, 0, 0.118 * zz), (0.06, 0.06, 0.006), (0.9, 0.9, 0.9), cls=SKIN, bone="halo", tint=1.0, seg=12, rings=4)
        b.cur_pal = 0.0
        # a band of round studs below each head
        for j in range(9):
            q = j / 9 * 2 * math.pi
            b.ball(c + V(math.cos(q) * 0.165, math.sin(q) * 0.165, 0.085 * zz), 0.012, "d8b050", cls=METAL, bone="halo", seg=6, rings=4)
    # the drum hangs on the hoop by a short iron bracket
    b.tube([c - V(math.cos(a), math.sin(a), 0) * 0.1, c - V(math.cos(a), math.sin(a), 0) * 0.18], [0.02, 0.02], "3a3a44", cls=METAL, bone="halo", seg=6)


# ---------------------------------------------------------------- lightning: veins glowing through the billows, forks below
def bolt(p0, d, n, width, depth=0):
    """Forked lightning: a jagged channel that splits into thinner branches."""
    pts = [p0]
    for j in range(n):
        pts.append(pts[-1] + d * 0.26 + V(rnd.uniform(-0.15, 0.15), rnd.uniform(-0.05, 0.05), rnd.uniform(-0.1, 0.1)))
    b.cur_pal = 1.0
    b.tube(pts, [width] * len(pts), (1.0, 1.0, 1.0), cls=CLOTH, bone="bolts", seg=5, mat=MAT_GLOW, tint=0.25)
    b.tube(pts, [width * 2.4] * len(pts), (0.7, 0.7, 0.7), cls=CRYSTAL, bone="bolts", seg=5, mat=MAT_GLOW, tint=1.0)
    b.cur_pal = 0.0
    if depth < 2:
        for j in range(1, len(pts) - 1, 2):
            nd = (d + V(rnd.uniform(-0.8, 0.8), 0.0, rnd.uniform(-0.4, 0.4))).normalized()
            bolt(pts[j], nd, max(2, n - 2), width * 0.6, depth + 1)


for k in range(3):
    bolt(V(rnd.uniform(-0.25, 0.25), Y - 0.9 - 0.2 * k, rnd.uniform(-0.15, 0.2)), V(0.15 * (k - 1), -1, 0).normalized(), 4, 0.026)
# lightning flashing across the chest, between the billows
for k, (x0, y0, x1, y1) in enumerate(((-0.32, Y + 0.25, 0.05, Y - 0.12), (0.36, Y + 0.18, 0.12, Y - 0.2), (-0.12, Y - 0.05, 0.2, Y - 0.38))):
    pts = []
    for j in range(7):
        t = j / 6
        x = x0 + (x1 - x0) * t + (0.05 if j % 2 else -0.05) * (1.0 if 0 < j < 6 else 0.0)
        y = y0 + (y1 - y0) * t
        h = hit(V(x, y, 2.5), V(0, 0, -1), 4.0)
        if h is not None:
            pts.append(h[0] + h[1] * 0.008)
    if len(pts) >= 3:
        m = len(pts)
        rad = [0.004 + 0.012 * math.sin(math.pi * (0.1 + 0.8 * i / (m - 1))) for i in range(m)]
        b.cur_pal = 1.0
        b.tube(pts, rad, (1.0, 1.0, 1.0), cls=CLOTH, bone="body", seg=5, mat=MAT_GLOW, tint=0.35)
        b.tube(pts, [x * 2.2 for x in rad], (0.6, 0.6, 0.6), cls=CRYSTAL, bone="body", seg=5, mat=MAT_GLOW, tint=1.0)
        b.cur_pal = 0.0
# rain falling from the funnel in streaks
b.cur_pal = 0.5
for k in range(26):
    x = rnd.uniform(-0.5, 0.5)
    z = rnd.uniform(-0.35, 0.35)
    y0 = Y - 0.5 - rnd.uniform(0.0, 0.5)
    b.tube([V(x, y0, z), V(x - 0.04, y0 - 0.32, z)], [0.006, 0.002], (0.85, 0.9, 1.0), cls=CRYSTAL, bone="bolts", seg=3, tint=0.5, mat=MAT_PLAIN)
b.cur_pal = 0.0

T_IDLE = 3.0


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    p["body"] = ((0, math.sin(t * w + 0.5) * 0.06, 0), (0, math.sin(t * w) * 0.1, 0), (1.0 + 0.025 * math.sin(t * w * 2), 1.0 + 0.025 * math.sin(t * w * 2 + 1.0), 1.0))
    p["head"] = ((0.04 * math.sin(t * w * 2), 0.08 * math.sin(t * w + 0.3), 0), (0, 0, 0))
    # the ring of drums turns an eighth of a turn every loop (the drums repeat every eighth)
    p["halo"] = ((0, 0, -2 * math.pi / N_DRUMS * t / T_IDLE), (0, 0, 0))
    p["bolts"] = ((0, 0, 0), (0, 0, 0), (1.0, 0.6 + 0.4 * abs(math.sin(t * w * 5)), 1.0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((math.sin(t * w + s) * 0.12, 0, math.sin(t * w + 0.7) * 0.12 * s), (0, 0, 0))
    return p


def attack(t):
    """Both drumsticks raised and brought down on the air: the thunderclap."""
    k = t / 0.55
    e = env(k)
    up = math.sin(min(1.0, k / 0.45) * math.pi / 2)
    hit_ = smooth(0.45, 0.6, k) * (1.0 - smooth(0.8, 1.0, k))
    p = idle(0.0)
    p["body"] = ((0.25 * hit_ - 0.1 * up, 0, 0), (0, 0, 0.3 * hit_), (1.0 + 0.12 * e, 1.0 + 0.12 * e, 1.0 + 0.12 * e))
    p["head"] = ((-0.15 * up + 0.2 * hit_, 0, 0), (0, 0, 0))
    p["bolts"] = ((0, 0, 0), (0, 0, 0), (1.0 + 0.3 * e, 1.0 + 0.6 * e, 1.0 + 0.3 * e))
    for sd in ("L", "R"):
        p["arm." + sd] = ((-1.2 * up * (1.0 - hit_) + 0.4 * hit_, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["body"] = ((-0.2 * e, 0, 0.2 * e), (0, 0, -0.15 * e), (1.0 - 0.12 * e, 1.0 - 0.12 * e, 1.0 - 0.12 * e))
    p["head"] = ((-0.25 * e, 0.15 * e, 0), (0, 0, 0))
    return p


def cast(t):
    """The ring of drums whirls and swells, the lightning beneath flares."""
    e = env(t / 0.6)
    p = idle(0.0)
    p["halo"] = ((0, 0, -t * 9.0), (0, 0.15 * e, 0), (1.0 + 0.25 * e, 1.0 + 0.25 * e, 1.0))
    p["bolts"] = ((0, t * 5.0, 0), (0, 0, 0), (1.0 + 0.5 * e, 1.3, 1.0 + 0.5 * e))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((-0.9 * e, 0, 0.4 * s * e), (0, 0, 0))
    return p


T_WALK = 2.0


def walk(t):
    """Rolls forward like weather: the mass leans and churns, the funnel and the rain slant."""
    w = 2 * math.pi / T_WALK
    p = idle(t * T_IDLE / T_WALK)
    add(p, "body", (0.15, 0.05 * math.sin(t * w), 0.06 * math.sin(t * w)), (0, 0.05 * math.sin(t * w * 2), 0))
    add(p, "bolts", (-0.25, 0, 0))
    return p


def die(t):
    """Breaks up: the cloud swells, thins and sinks away, the lightning gone, the drums fall still."""
    k = min(1.0, t / 1.2)
    swell = math.sin(math.pi * smooth(0.0, 0.3, k))
    f = smooth(0.2, 0.86, k)
    p = idle(0.0)
    s_ = (1.0 + 0.15 * swell) * (1.0 - 0.85 * f) + 0.02
    p["body"] = ((0, 0, 0), (0, -1.6 * f, 0), (s_ * (1.0 + 0.3 * f), s_ * (1.0 - 0.4 * f), s_ * (1.0 + 0.3 * f)))
    p["bolts"] = ((0, 0, 0), (0, 0, 0), (max(0.01, 1.0 - 1.5 * k), max(0.01, 1.0 - 1.5 * k), max(0.01, 1.0 - 1.5 * k)))
    u = min(1.0, k / 0.85)
    p["halo"] = ((0.3 * f, 0, -1.2 * (u - 0.5 * u * u)), (0, -0.3 * f, 0), (1.0 - 0.5 * f, 1.0 - 0.5 * f, 1.0))
    return p


print("[art] storm: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/storm.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  samples=10, dist=0.3, strength=0.35)
