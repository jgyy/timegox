"""Golem: a hulking construct of weathered boulders held together by a molten heart (Lava Titan,
Glass Colossus, Bronze Sentinel, Crucible Golem ...).  The body is a glowing core sculpted as one
piece; boulders sheared on fracture planes and mottled with crevices and lichen sit over it, so
the light shows as seams between every stone.  Great breast stones split by a lit fault, a mossy
hump, a small heavy-browed head sunk between the shoulders with slits of light for eyes, round
shoulder stones grown over with crystals and grass, arms of stacked stones ending in fists of
boulders with separate knuckles, short legs on flat foot stones, pebbles orbiting the heart.
The stone and the glow take the enemy's colour.
Run: blender --background --python art/monsters/golem.py  ->  assets/monsters/golem.glb"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import zero_pose  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, STONE, V, Builder, Rig, env, mix  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from sculpt import fbm3, morph_sphere  # noqa: E402
from creature import Walker, add, smooth  # noqa: E402

kit.reset()
creature.realtime()
rnd = random.Random(5)
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("hips", (0, 0.95, 0), (0, 1.25, 0), "root")
r.bone("chest", (0, 1.25, 0), (0, 1.85, 0.05), "hips")
r.bone("head", (0, 1.85, 0.1), (0, 2.15, 0.15), "chest")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm.%s" % sd, (0.55 * s, 1.75, 0), (0.72 * s, 1.25, 0.05), "chest")
    r.bone("fore.%s" % sd, (0.72 * s, 1.25, 0.05), (0.78 * s, 0.75, 0.15), "arm.%s" % sd)
    r.bone("thigh.%s" % sd, (0.25 * s, 0.95, 0), (0.28 * s, 0.5, 0.02), "hips")
    r.bone("shin.%s" % sd, (0.28 * s, 0.5, 0.02), (0.28 * s, 0.06, 0.0), "thigh.%s" % sd)


def boulder(c, radii, bone, seed, shade=0.9, moss=0.0, facets=6, rough=0.14, seg=22, rings=15, tint=1.0):
    """A weathered boulder: a sphere scaled to `radii`, split flat on random fracture planes (the
    fresh faces paler), lumpy and pitted with two scales of noise, mottled grey with dark
    crevices, lichen on top when `moss`.  Returns surf(dir) -> world point on its surface."""
    rr = random.Random(seed)
    planes = []
    for _ in range(facets):
        n = V(rr.uniform(-1, 1), rr.uniform(-0.6, 1.0), rr.uniform(-1, 1)).normalized()
        planes.append((n, rr.uniform(0.6, 0.84)))
    o = V(rr.uniform(0, 40), rr.uniform(0, 40), rr.uniform(0, 40))
    c = V(c)

    def lumps(d):
        return fbm3((d.x * 1.8 + o.x, d.y * 1.8 + o.y, d.z * 1.8 + o.z), 2, seed) - 0.5

    def pits(d):
        return fbm3((d.x * 6.0 + o.z, d.y * 6.0 + o.x, d.z * 6.0 + o.y), 2, seed + 3) - 0.5

    def cut(d):
        p = V(d)
        hit = 0.0
        for n, off in planes:
            k = p.dot(n)
            if k > off:
                p = p - n * (k - off)
                hit = max(hit, min(1.0, (k - off) * 8.0))
        return p, hit

    def shape(d):
        p, hit = cut(d)
        p = p * (1.0 + rough * lumps(d) + 0.05 * pits(d) * (1.0 - 0.6 * hit))
        return V((p.x * radii[0], p.y * radii[1], p.z * radii[2]))

    def lichen(d, g):
        return smooth(0.25, 0.7, d.y) * smooth(0.45, 0.62, g) * moss if moss else 0.0

    def col(lp, d):
        _, hit = cut(d)
        g = fbm3((lp.x * 6.0 + o.x, lp.y * 6.0 + o.y, lp.z * 6.0 + o.z), 3, seed + 1)
        v = shade * (0.94 + 0.24 * (g - 0.5)) + 0.06 * hit
        # hairline cracks: thin dark lines along the contours of the pitting noise
        v -= 0.32 * smooth(0.035, 0.0, abs(pits(d) + 0.06)) * (1.0 - hit)
        v = max(0.2, min(0.98, v))
        m = lichen(d, g)
        return mix((v, v, v), (0.48, 0.62, 0.32), m) if m > 0 else (v, v, v)

    def tnt(lp, d):
        g = fbm3((lp.x * 6.0 + o.x, lp.y * 6.0 + o.y, lp.z * 6.0 + o.z), 3, seed + 1)
        return tint * (1.0 - lichen(d, g))

    morph_sphere(b, c, shape, col, cls=STONE, bone=bone, seg=seg, rings=rings, tint_fn=tnt)
    return lambda d: c + shape(V(d).normalized())


def crack(surf, dirs, bone, r=0.012):
    """A glowing fault running over a boulder through the given directions."""
    pts = []
    for i in range(len(dirs) - 1):
        a, e = V(dirs[i]).normalized(), V(dirs[i + 1]).normalized()
        for k in range(3):
            pts.append(surf(a.lerp(e, k / 3)))
    pts.append(surf(dirs[-1]))
    b.cur_pal = 0.5
    A.glow_seam(b, pts, r, (1.0, 1.0, 1.0), bone)
    b.cur_pal = 0.0


b = Builder("golem")
# the heart: a glowing molten body inside the stones; it shows in every gap between them as a
# lit seam, and takes the enemy's colour
core = Clay(0.035, "golem_core")
core.ellipsoid(V(0, 1.5, 0.0), (0.33, 0.38, 0.21), bones={"chest": 0.8, "hips": 0.2})
core.ellipsoid(V(0, 1.08, 0.0), (0.25, 0.17, 0.18), bones={"hips": 1.0})
core.chain([V(0, 1.75, 0.0), V(0, 2.0, 0.12)], [0.11, 0.09], bones={"chest": 0.5, "head": 0.5})
for s, sd in ((1, "L"), (-1, "R")):
    core.chain([V(0.55 * s, 1.75, 0.0), V(0.72 * s, 1.25, 0.05), V(0.78 * s, 0.78, 0.15)], [0.1, 0.085, 0.1],
               bones=limb_weights(["arm." + sd, "fore." + sd]), t0=0.0, t1=2.0)
    core.chain([V(0.25 * s, 0.98, 0.0), V(0.28 * s, 0.5, 0.02), V(0.28 * s, 0.1, 0.02)], [0.1, 0.085, 0.08],
               bones=limb_weights(["thigh." + sd, "shin." + sd]), t0=0.0, t1=2.0)
b.cur_pal = 0.5  # palette slot (kit.py): the glow takes the analogous secondary colour (red stone, orange fire)
core.build(b, lambda p, info: (1.0, 1.0, 1.0), cls=CRYSTAL, tint_fn=lambda p, info: 1.0, mat=MAT_GLOW)
b.cur_pal = 0.0

# torso: two great breast stones split by a lit fault, a belly stone, a hunched back and a
# mossy hump between the shoulders
S = [100]


def nxt():
    S[0] += 7
    return S[0]


for s in (1, -1):
    pec = boulder(V(0.21 * s, 1.6, 0.11), (0.27, 0.27, 0.22), "chest", nxt(), 0.8)
    crack(pec, [(-0.2 * s, 0.6, 0.8), (0.1 * s, 0.1, 1.0), (-0.1 * s, -0.5, 0.85)], "chest")
back = boulder(V(0, 1.58, -0.12), (0.45, 0.33, 0.24), "chest", nxt(), 0.8)
crack(back, [(0.6, 0.5, -0.6), (0.1, 0.0, -1.0), (-0.5, -0.4, -0.7)], "chest")
boulder(V(0, 1.86, -0.1), (0.36, 0.17, 0.25), "chest", nxt(), 0.74, moss=0.9)
boulder(V(0, 1.3, 0.07), (0.3, 0.17, 0.22), {"chest": 0.6, "hips": 0.4}, nxt(), 0.76)
boulder(V(0, 1.06, 0.0), (0.33, 0.17, 0.25), "hips", nxt(), 0.7)
for s in (1, -1):
    boulder(V(0.24 * s, 1.36, -0.02), (0.13, 0.16, 0.17), "chest", nxt(), 0.7)
# head: a small, heavy-browed stone sunk between the shoulders, two slits of light for eyes
boulder(V(0, 1.99, 0.15), (0.16, 0.15, 0.16), "head", nxt(), 0.82, facets=5)
boulder(V(0, 2.07, 0.25), (0.15, 0.055, 0.07), "head", nxt(), 0.7, facets=2, rough=0.1)
boulder(V(0, 1.92, 0.24), (0.11, 0.05, 0.07), "head", nxt(), 0.76, facets=2, rough=0.1)
b.cur_pal = 0.5
for s in (1, -1):
    b.ellipsoid(V(0.065 * s, 2.015, 0.305), (0.04, 0.014, 0.012), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="head", tint=1.0, mat=MAT_GLOW, seg=10, rings=5, rot=(0, 0, 0.18 * s))
b.cur_pal = 0.0
# shoulders: huge round stones grown over with moss and crystals; arms of stacked stones down to
# fists like boulders, the knuckles separate stones
for s, sd in ((1, "L"), (-1, "R")):
    arm, fore = "arm." + sd, "fore." + sd
    sh = boulder(V(0.63 * s, 1.84, 0.0), (0.26, 0.24, 0.27), {"chest": 0.4, arm: 0.6}, nxt(), 0.78, moss=1.0)
    for k in range(3):
        root = sh((0.3 * s, 1.0, -0.2 + 0.25 * k))
        b.crystal(root - V(0, 0.03, 0), 0.045, 0.22 - k * 0.04, (0.95, 0.95, 0.95), bone=arm, tint=1.0, rot=(0.3 - 0.25 * k, 0, -0.45 * s))
    for k in range(6):
        root = sh((0.5 * s * math.cos(k), 1.0, 0.5 * math.sin(k * 1.7)))
        b.leaf(root, root + V(0.02 * math.sin(k), 0.09 + 0.03 * (k % 3), 0.02), 0.016, "5a8a3a", bone=arm, col_tip="9ac060", tint=0.0)
    ua = boulder(V(0.68 * s, 1.5, 0.02), (0.17, 0.23, 0.17), arm, nxt(), 0.84)
    crack(ua, [(0.8 * s, 0.6, 0.5), (1.0 * s, 0.0, 0.2), (0.7 * s, -0.6, 0.4)], arm, 0.01)
    boulder(V(0.73 * s, 1.26, 0.05), (0.12, 0.1, 0.12), {arm: 0.5, fore: 0.5}, nxt(), 0.7)
    fa = boulder(V(0.75 * s, 1.03, 0.1), (0.2, 0.24, 0.2), fore, nxt(), 0.76)
    crack(fa, [(0.9 * s, 0.6, 0.3), (0.9 * s, -0.1, 0.4), (0.7 * s, -0.7, 0.2)], fore, 0.01)
    boulder(V(0.79 * s, 0.72, 0.16), (0.27, 0.22, 0.27), fore, nxt(), 0.82)
    for k in range(4):
        boulder(V((0.79 + (k - 1.5) * 0.1) * s, 0.6, 0.36), (0.07, 0.075, 0.075), fore, nxt(), 0.86, facets=2, seg=12, rings=8)
    boulder(V(0.6 * s, 0.68, 0.25), (0.07, 0.09, 0.07), fore, nxt(), 0.84, facets=2, seg=12, rings=8)
    # legs: a thigh stone, a knee stone, a shin and a broad, flat foot stone
    th = boulder(V(0.27 * s, 0.75, 0.02), (0.19, 0.22, 0.2), "thigh." + sd, nxt(), 0.82)
    crack(th, [(0.3 * s, 0.7, 0.7), (0.0, 0.0, 1.0), (-0.2 * s, -0.7, 0.7)], "thigh." + sd, 0.01)
    boulder(V(0.28 * s, 0.5, 0.07), (0.12, 0.1, 0.12), {"thigh." + sd: 0.5, "shin." + sd: 0.5}, nxt(), 0.78)
    boulder(V(0.28 * s, 0.3, 0.02), (0.17, 0.19, 0.18), "shin." + sd, nxt(), 0.74)
    boulder(V(0.29 * s, 0.075, 0.08), (0.2, 0.085, 0.27), "shin." + sd, nxt(), 0.68, facets=3, rough=0.1)
# a few pebbles orbiting the heart in its pull
for k in range(6):
    a = k / 6 * 2 * math.pi
    boulder(V(math.cos(a) * 0.62, 1.5 + math.sin(a) * 0.45, 0.42), (0.05, 0.045, 0.05), "chest", nxt(), 0.86, facets=2, seg=10, rings=6)


T = 3.0


def idle(t):
    w = 2 * math.pi / T
    br = math.sin(t * w)
    p = zero_pose(r)
    p["hips"] = ((0, math.sin(t * w + 0.5) * 0.04, 0), (0, br * 0.02, 0))
    p["chest"] = ((br * 0.03, math.sin(t * w) * 0.05, 0), (0, 0, 0))
    p["head"] = ((0, math.sin(t * w) * 0.15, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((math.sin(t * w + s) * 0.06, 0, 0.05 * s * br), (0, 0, 0))
        p["fore.%s" % sd] = ((-0.2, 0, 0), (0, 0, 0))
        p["shin.%s" % sd] = ((0.05, 0, 0), (0, 0, 0))
        p["thigh.%s" % sd] = ((-0.05, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    up = math.sin(min(1.0, k / 0.45) * math.pi / 2)
    slam = max(0.0, min(1.0, (k - 0.45) / 0.2))
    p = idle(0.0)
    p["chest"] = ((-0.3 * up + 0.7 * slam, 0, 0), (0, 0, 0))
    p["root"] = ((0, 0, 0), (0, 0, 0.3 * slam * e))
    for sd in ("L", "R"):
        p["arm.%s" % sd] = ((-2.6 * up + 2.2 * slam, 0, 0), (0, 0, 0))
        p["fore.%s" % sd] = ((-0.6 * up, 0, 0), (0, 0, 0))
    p["thigh.L"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["shin.L"] = ((0.4 * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["chest"] = ((-0.25 * e, 0.15 * e, 0.1 * e), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["root"] = ((0, 0, 0), (0, 0, -0.15 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    p["chest"] = ((-0.25 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm.%s" % sd] = ((-0.4 * e, 0, s * 1.2 * e), (0, 0, 0))
        p["fore.%s" % sd] = ((-0.8 * e, 0, 0), (0, 0, 0))
    return p


T_WALK = 1.6
WALK = Walker(r, [("thigh.L", "shin.L"), ("thigh.R", "shin.R")], [0.0, 0.5], duty=0.62, sagittal=True)


def walk(t):
    """A heavy biped stride: the hips shift over the planted foot and drop on each step, the
    chest counter-turns and the arms swing like pendulums."""
    ph = (t / T_WALK) % 1.0
    w = 2 * math.pi
    p = zero_pose(r)
    add(p, "hips", (0.04, 0.08 * math.sin(w * ph), 0.05 * math.sin(w * ph)), (0.05 * math.sin(w * ph), -0.04 * abs(math.cos(w * ph)), 0))
    add(p, "chest", (0.04, -0.12 * math.sin(w * ph), -0.03 * math.sin(w * ph)))
    add(p, "head", (0, 0.06 * math.sin(w * ph), 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "arm.%s" % sd, (0.35 * s_ * math.sin(w * ph), 0, 0.05 * s_))
        add(p, "fore.%s" % sd, (-0.25 - 0.15 * max(0.0, s_ * math.sin(w * ph)), 0, 0))
    return WALK.step(p, ph, 0.5, 0.14)


def die(t):
    """The knees give, the construct pitches forward onto its face and its blocks settle."""
    k = min(1.0, t / 1.2)
    buckle = smooth(0.0, 0.35, k)
    f = smooth(0.3, 0.8, k)
    p = zero_pose(r)
    a = 1.45 * f
    q = V(0, 0, 0.3)
    from creature import euler_g
    R = euler_g((a, 0.0, 0.0))
    off = q - R @ q
    add(p, "root", (a, 0.0, 0.0), (off.x, off.y - 0.35 * buckle * (1.0 - f) + 0.25 * f, off.z))
    add(p, "chest", (0.15 * buckle, 0.1 * f, 0.08 * f))
    add(p, "head", (0.3 * buckle, 0.4 * f, 0))
    for sd, s_ in (("L", 1), ("R", -1)):
        add(p, "thigh.%s" % sd, (-0.8 * buckle * (1.0 - 0.6 * f), 0, 0))
        add(p, "shin.%s" % sd, (1.2 * buckle * (1.0 - 0.6 * f), 0, 0))
        add(p, "arm.%s" % sd, (-1.0 * f, 0, s_ * 0.4 * f))
    return p

print("[art] golem: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/golem.glb", {"idle": (T, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=14, dist=0.3, strength=0.55, floor_y=0.0)
