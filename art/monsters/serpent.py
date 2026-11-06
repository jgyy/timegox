"""Serpent: the great snakes and eels (Tide Hydra, Rainbow Serpent, Rot-Root Hydra, Chaos Eel, the
Serpent Beneath the Naihe Bridge ...).  A coiled body swept along a smooth spline, rearing up into an
S-shaped neck, with a ridge of fin-spikes down its back, pale belly plates, a frilled horned head,
a hinged jaw full of fangs and whiskers.  Eight spine bones carry a travelling wave.
Tinted by the game per enemy; eyes, fangs and belly highlights keep their colours.
Run: blender --background --python art/monsters/serpent.py  ->  assets/monsters/serpent.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
from creature import catmull, chain_rig, chain_weights, eyes, fangs, wave_chain, zero_pose  # noqa: E402
from kit import CLOTH, SCALE, SKIN, STONE, V, Builder, Rig, env  # noqa: E402

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

# body: a tube along the resampled spline, thickest in the middle coils
pts, idx = catmull(PTS, per=5)
n = len(pts)
radii = []
for i in range(n):
    t = i / (n - 1)
    radii.append(0.035 + 0.2 * math.sin(min(1.0, t * 1.25) * math.pi * 0.85) + 0.05 * t)
bones = [chain_weights("sp", f, len(spine)) for f in idx]
shade = [(0.78 + 0.1 * math.sin(i * 0.9), 0.78 + 0.1 * math.sin(i * 0.9), 0.78 + 0.1 * math.sin(i * 0.9)) for i in range(n)]
b.tube(pts, radii, (0.8, 0.8, 0.8), cls=SCALE, bones=bones, seg=16, tint=1.0, cols=shade)
# belly plates and dorsal fin spikes along the length
for i in range(2, n - 2):
    p0 = pts[i]
    tan = (pts[i + 1] - pts[i - 1]).normalized()
    side = tan.cross(V(0, 1, 0))
    if side.length < 0.2:
        side = V(1, 0, 0)
    side.normalize()
    up = side.cross(tan).normalized()
    if up.y < 0:
        up = -up
    rr = radii[i]
    b.ellipsoid(p0 - up * rr * 0.75, (rr * 0.7, rr * 0.25, rr * 0.55), (1.0, 1.0, 1.0), cls=SCALE, bone=bones[i], tint=1.0, seg=10, rings=5)
    if i % 2 == 0:
        b.leaf(p0 + up * rr * 0.85, p0 + up * (rr + 0.16) - tan * 0.12, 0.06, (0.55, 0.55, 0.55), side=tan, cls=CLOTH, bone=bones[i], tint=1.0, col_tip=(0.9, 0.9, 0.9))
# head: long skull, snout, frills and swept-back horns
hc = PTS[-1]
b.ellipsoid(hc + V(0, 0.04, 0.12), (0.17, 0.13, 0.22), (0.85, 0.85, 0.85), cls=SCALE, bone="head", tint=1.0, seg=18, rings=10)
b.ellipsoid(hc + V(0, 0.0, 0.36), (0.11, 0.08, 0.16), (0.9, 0.9, 0.9), cls=SCALE, bone="head", tint=1.0, seg=14, rings=8)
b.ellipsoid(hc + V(0, -0.07, 0.3), (0.09, 0.04, 0.17), (1.0, 1.0, 1.0), cls=SCALE, bone="jaw", tint=1.0, seg=12, rings=6)
b.ellipsoid(hc + V(0, -0.05, 0.3), (0.075, 0.015, 0.14), "a02030", cls=SKIN, bone="jaw", seg=10, rings=4)
fangs(b, [hc + V(0.05, -0.05, 0.44), hc + V(-0.05, -0.05, 0.44)], 0.08, "head")
eyes(b, hc + V(0, 0.1, 0.24), 0.1, 0.035, iris="ffe040", slit=True, glow=True, bone="head", rot_y=0.9, h=0.9)
for s in (1, -1):
    b.tube([hc + V(0.08 * s, 0.14, 0.05), hc + V(0.16 * s, 0.22, -0.12), hc + V(0.18 * s, 0.24, -0.32)], [0.035, 0.022, 0.004], "e8dcc0", cls=STONE, bone="head", seg=8)
    # frill: a fan of membranes behind the jaw
    for k in range(4):
        a = 0.3 + k * 0.35
        root = hc + V(0.13 * s, 0.0, 0.02)
        b.leaf(root, root + V(math.cos(a) * 0.28 * s, math.sin(a) * 0.2 - 0.05, -0.12), 0.08, (0.6, 0.6, 0.6), side=(0, 0, 1), cls=CLOTH, bone="head", tint=1.0, col_tip=(1.0, 1.0, 1.0))
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
