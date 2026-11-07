"""Serpent: the great snakes and eels (Tide Hydra, Rainbow Serpent, Rot-Root Hydra, Chaos Eel, the
Serpent Beneath the Naihe Bridge ...).  A coiled body lofted along a smooth spline with a snake's
cross-section (domed back, flat belly) and a diamond pattern, rearing up into an S-shaped neck,
with a webbed dorsal fin, pale ventral scutes, and a viper's wedge-shaped head with brow scales,
heat pits, a forked tongue, ribbed frills, horns, fangs and whiskers.  Eight spine bones carry a travelling wave.
Tinted by the game per enemy; eyes, fangs and belly highlights keep their colours.
Run: blender --background --python art/monsters/serpent.py  ->  assets/monsters/serpent.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import catmull, chain_rig, chain_weights, eyes, fangs, wave_chain, zero_pose  # noqa: E402
from kit import CLOTH, MAT_PLAIN, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402
from sculpt import blob3, fbm3, loft, morph_sphere, prof_d, section, smooth  # noqa: E402

kit.reset()
PTS = [V(0.05, 0.12, -1.7), V(0.55, 0.16, -1.35), V(0.7, 0.2, -0.75), V(0.15, 0.24, -0.38), V(-0.45, 0.3, -0.1),
       V(-0.35, 0.58, 0.22), V(0.0, 1.1, 0.32), V(0.05, 1.62, 0.36), V(0.0, 1.95, 0.6)]
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
spine = chain_rig(r, "sp", PTS, "root")
head_end = PTS[-1] + V(0, 0.02, 0.5)
r.bone("head", PTS[-1], head_end, spine[-1])
r.bone("jaw", PTS[-1] + V(0, -0.08, 0.05), PTS[-1] + V(0, -0.12, 0.45), "head")
b = Builder("serpent")

# body: a loft along the resampled spline with a snake's cross-section (domed back, flat belly),
# thickest in the middle coils, coloured with a diamond pattern along the back
pts, idx = catmull(PTS, per=6)
n = len(pts)
radii = []
for i in range(n):
    t = i / (n - 1)
    radii.append(0.035 + 0.2 * math.sin(min(1.0, t * 1.25) * math.pi * 0.85) + 0.05 * t)
bones = [chain_weights("sp", f, len(spine)) for f in idx]
frames = []
rings = []
for i in range(n):
    tan = (pts[min(n - 1, i + 1)] - pts[max(0, i - 1)]).normalized()
    side = tan.cross(V(0, 1, 0))
    if side.length < 0.2:
        side = V(1, 0, 0)
    side.normalize()
    up = side.cross(tan).normalized()
    if up.y < 0:
        up = -up
    frames.append((tan, side, up))
    rings.append(section(pts[i], tan, prof_d(radii[i] * 1.08, radii[i], 0.7), 18, up=up))
along = [0.0]
for i in range(1, n):
    along.append(along[-1] + (pts[i] - pts[i - 1]).length)


def scale_col(p, j, i):
    """Diamonds along the back, a pale belly, darker flanks, fine scale speckle."""
    tan, side, up = frames[j]
    rel = (p - pts[j]).normalized()
    u = rel.dot(up)
    sd = rel.dot(side)
    v = 0.62 + 0.32 * smooth(-0.2, -0.8, u)
    dz = along[j] * 5.0
    diamond = abs(((dz % 1.0) - 0.5) * 2.0) + abs(sd) * 1.6
    if u > 0.1 and diamond < 0.75:
        v *= 0.62 if diamond > 0.55 else 1.12
    v *= 0.94 + 0.12 * fbm3((p.x * 40, p.y * 40, p.z * 40), 1, 3)
    return (v, v, v)


loft(b, rings, (0.8, 0.8, 0.8), cls=SCALE, col_fn=scale_col, bones=bones, tint=1.0, cap0=True, cap1=False, cap_push=0.8)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# ventral scutes: wide pale bands across the belly, and a dorsal fin of membrane between spines
prev_tip = None
for i in range(2, n - 2):
    tan, side, up = frames[i]
    rr = radii[i]
    p0 = pts[i]
    band = [p0 - up * rr * 0.68 + side * rr * 0.9 * math.sin(a) - up * rr * 0.08 * math.cos(a) for a in [(-1.2 + 2.4 * k / 6) for k in range(7)]]
    if i % 2 == 0:
        b.tube(band, [(rr * 0.07, rr * 0.03)] * 7, (1.0, 1.0, 1.0), cls=SCALE, bone=bones[i], tint=0.6, seg=6, up=tuple(tan))
    if i % 3 == 0 and i < n - 6:
        root = p0 + up * rr * 0.85
        tip = p0 + up * (rr + 0.14 + 0.04 * math.sin(i)) - tan * 0.1
        b.tube([root, tip], [0.014, 0.002], (0.85, 0.85, 0.85), cls=STONE, bone=bones[i], seg=6, tint=1.0)
        if prev_tip is not None:
            r0, t0 = prev_tip
            b.sheet([[r0, t0], [root, tip]], (0.5, 0.5, 0.5), bones=[bones[i - 3], bones[i]], cols=[(0.55, 0.55, 0.55), (0.45, 0.45, 0.45)], tint=1.0, thickness=0.008)
        prev_tip = (root, tip)
b.cur_pal = 0.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# head: a viper's wedge, broad behind the jaws, with brow scales over the eyes, nostrils, heat
# pits, a lipline of scales and a forked tongue
hc = PTS[-1]
hf = A.HeadFrame(hc + V(0, 0.03, 0.14), V(0, -0.08, 1.0))


def skull(d):
    p = V(d.x * 0.16, d.y * 0.1, d.z * 0.25)
    front = smooth(-0.2, 1.0, d.z)
    p.x *= 1.0 - 0.55 * front ** 1.5
    p.y *= 1.0 - 0.3 * front
    q = p.copy()
    off = 0.0
    for s2 in (1, -1):
        off += 0.025 * blob3(q, (0.075 * s2, 0.07, 0.04), (0.04, 0.02, 0.05))   # brow scale over the eye
        off += 0.03 * blob3(q, (0.13 * s2, -0.03, -0.1), (0.04, 0.05, 0.07))    # venom glands
    return p + p.normalized() * off


morph_sphere(b, hf.c, skull, lambda p, d: (0.75 + 0.2 * d.y * 0.5 + 0.1 * smooth(-0.3, -0.8, d.y),) * 3, cls=SCALE, bone="head", seg=24, rings=16, tint_fn=lambda p, d: 1.0, rot=hf.M)
b.ellipsoid(hf.at(0, -0.075, 0.08), (0.12, 0.035, 0.2), (1.0, 1.0, 1.0), cls=SCALE, bone="jaw", tint=1.0, seg=14, rings=6)
b.ellipsoid(hf.at(0, -0.06, 0.08), (0.1, 0.012, 0.17), "a02030", cls=SKIN, bone="jaw", seg=10, rings=4)
tongue = [hf.at(0, -0.06, 0.16), hf.at(0, -0.065, 0.28), hf.at(0, -0.07, 0.34)]
b.tube(tongue, [0.008, 0.007, 0.006], "c02040", cls=SKIN, bone="jaw", seg=6)
for s2 in (1, -1):
    b.tube([tongue[-1], tongue[-1] + hf.M @ V(0.025 * s2, -0.01, 0.06)], [0.005, 0.001], "c02040", cls=SKIN, bone="jaw", seg=5)
    b.ellipsoid(hf.at(0.03 * s2, 0.02, 0.24), (0.01, 0.007, 0.006), "100810", cls=SKIN, bone="head", seg=6, rings=4, mat=MAT_PLAIN)
    b.ellipsoid(hf.at(0.06 * s2, -0.01, 0.17), (0.008, 0.008, 0.006), "100810", cls=SKIN, bone="head", seg=6, rings=4, mat=MAT_PLAIN)
    lip = [hf.at(0.11 * s2 - 0.06 * s2 * t, -0.045, -0.04 + 0.28 * t) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    b.tube(lip, [0.008] * 5, (0.95, 0.95, 0.95), cls=SCALE, bone="head", seg=6, tint=0.6)
fangs(b, [hf.at(0.045, -0.06, 0.2), hf.at(-0.045, -0.06, 0.2)], 0.09, "head")
eyes(b, hf.at(0, 0.035, 0.1), 0.085, 0.032, iris="ffe040", slit=True, glow=True, bone="head", rot_y=0.95, h=0.9)
for s in (1, -1):
    b.tube([hc + V(0.08 * s, 0.14, 0.05), hc + V(0.16 * s, 0.22, -0.12), hc + V(0.18 * s, 0.24, -0.32)], [0.035, 0.022, 0.004], "e8dcc0", cls=STONE, bone="head", seg=8)
    b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
    # frill: ribbed membranes fanned behind the jaw
    for k in range(5):
        a = 0.25 + k * 0.3
        root = hc + V(0.13 * s, 0.0, 0.02)
        tip = root + V(math.cos(a) * 0.3 * s, math.sin(a) * 0.22 - 0.05, -0.12)
        b.leaf(root, tip, 0.07, (0.6, 0.6, 0.6), side=(0, 0, 1), cls=CLOTH, bone="head", tint=1.0, col_tip=(1.0, 1.0, 1.0))
        b.tube([root, tip], [0.008, 0.002], (0.4, 0.4, 0.4), cls=STONE, bone="head", seg=4, tint=1.0)
    # whiskers
    b.tube([hc + V(0.07 * s, -0.02, 0.44), hc + V(0.2 * s, -0.05, 0.5), hc + V(0.34 * s, -0.12, 0.42), hc + V(0.42 * s, -0.24, 0.3)], [0.008, 0.007, 0.005, 0.002], "f0e0b0", cls=SKIN, bone="head", seg=5)

T_IDLE = 3.2


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    wave_chain(p, spine, t, w, 0.05, axis=1, lag=0.8, grow=0.25)
    p[spine[-1]] = ((math.sin(t * w) * 0.06, math.sin(t * w * 0.5) * 0.2, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w * 2) * 0.05, math.sin(t * w) * 0.15, 0), (0, 0, 0))
    p["jaw"] = ((0.05 + 0.08 * max(0.0, math.sin(t * w * 1.5)), 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    strike = math.sin(min(1.0, k * 1.5) * math.pi)
    p = idle(0.0)
    p[spine[-3]] = ((-0.35 * e + 0.6 * strike, 0, 0), (0, 0, 0))
    p[spine[-2]] = ((-0.3 * e + 0.5 * strike, 0, 0), (0, 0, 0))
    p[spine[-1]] = ((0.3 * strike, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.9 * strike, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p[spine[-2]] = ((-0.4 * e, 0.2 * e, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, -0.3 * e, 0), (0, 0, 0))
    p["jaw"] = ((0.5 * e, 0, 0), (0, 0, 0))
    wave_chain(p, spine[:5], t, 25.0, 0.08 * e)
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    for nm in spine[4:]:
        p[nm] = ((-0.18 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((1.0 * e, 0, 0), (0, 0, 0))
    return p


print("[art] serpent: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/serpent.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
