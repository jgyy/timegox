"""Wisp: will-o'-the-wisps, ghost lights and fire sprites.  A teardrop of soft light whose
surface flickers with noise around a bright core, crowned with solid tongues of flame, broad at
the root and licking to points, in two layers on bone chains, trailing a tail of light that thins into embers, orbited by sparks, with little
arms ending in fingers of flame and a face with big eyes and blushing cheeks.  Tinted per enemy.
Run: blender --background --python art/monsters/wisp.py  ->  assets/monsters/wisp.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import chain_rig, glow_ball, wave_chain, zero_pose  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, morph_sphere, smooth  # noqa: E402
from creature import add  # noqa: E402

kit.reset()
creature.realtime()
Y = 1.25
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, Y - 0.2, 0), (0, Y + 0.25, 0), "root")
flames = []
for k in range(7):
    a = 2 * math.pi * k / 7
    base = V(math.cos(a) * 0.16, Y + 0.12, math.sin(a) * 0.16)
    pts = [base, base + V(math.cos(a) * 0.08, 0.2, math.sin(a) * 0.08), base + V(math.cos(a) * 0.06, 0.42, math.sin(a) * 0.06), base + V(0, 0.6, 0)]
    flames.append((chain_rig(r, "f%d_" % k, pts, "body"), pts))
tail = chain_rig(r, "tail", [V(0, Y - 0.15, -0.05), V(0, Y - 0.4, -0.2), V(0.05, Y - 0.62, -0.42), V(0.0, Y - 0.78, -0.66)], "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm." + sd, (0.2 * s, Y, 0.05), (0.38 * s, Y - 0.1, 0.12), "body")
b = Builder("wisp")

# the shell: a teardrop of soft light that flickers (noise on its surface), brighter at the core
def shell(d):
    p = V(d.x * 0.26, d.y * (0.36 if d.y > 0 else 0.3), d.z * 0.26)
    if d.y > 0:
        p.x *= 1.0 - 0.55 * smooth(0.2, 1.0, d.y)
        p.z *= 1.0 - 0.55 * smooth(0.2, 1.0, d.y)
    return p * (1.0 + 0.08 * (fbm3((d.x * 3, d.y * 3, d.z * 3), 2, 2) - 0.5))


morph_sphere(b, V(0, Y, 0), shell, lambda p, d: (0.86 + 0.14 * smooth(-0.5, 0.8, d.y),) * 3, cls=SKIN, bone="body", seg=40, rings=26, tint_fn=lambda p, d: 1.0)
glow_ball(b, V(0, Y, 0.02), 0.14, "fffaf0", "body")
b.ellipsoid(V(0, Y - 0.02, 0.02), (0.2, 0.22, 0.2), (1.0, 1.0, 1.0), cls=CRYSTAL, bone="body", seg=14, rings=10, mat=MAT_GLOW, tint=0.6)
b.cur_pal = 1.0  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# flame tongues: an outer dim layer and an inner bright one, crossed so they read from any side
for k, (names, pts) in enumerate(flames):
    out = V(pts[0].x, 0, pts[0].z).normalized()
    side = V(-out.z, 0, out.x)
    for j in range(len(pts) - 1):
        # solid tongues of flame, broad at the root and licking to a point, overlapping up the chain
        root = pts[j] - (pts[j + 1] - pts[j]) * 0.15
        A.blade(b, root, pts[j + 1] + V(0, 0.05, 0), 0.065 - 0.016 * j, (0.95, 0.95, 0.95), (1.0, 1.0, 1.0), side=side, bone=names[j], curl=0.12,
                thick=0.35, tint=1.0, cls=CLOTH, mat=MAT_GLOW, steps=5, seg=8, point=0.9, twist=0.4 * (1 if k % 2 else -1))
        A.blade(b, root + V(0, 0.02, 0) + out * 0.01, pts[j + 1], 0.03, "fffff0", "ffffff", side=side, bone=names[j], curl=0.18, thick=0.4, tint=0.3, cls=CLOTH,
                mat=MAT_GLOW, steps=4, seg=6, point=0.9)
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# tail of trailing light, thinning into embers
tp = [r.head(n) for n in tail] + [r.tail(tail[-1])]
b.tube(tp, [0.15, 0.1, 0.06, 0.005], (0.88, 0.88, 0.88), cls=SKIN, bones=[tail[0], tail[0], tail[1], tail[2]], tint=1.0, seg=14)
for k in range(7):
    t = 0.3 + k * 0.1
    i = min(len(tp) - 2, int(t * (len(tp) - 1)))
    q = tp[i].lerp(tp[i + 1], t * (len(tp) - 1) - i) + V(0.06 * math.sin(k * 2.3), 0.04 * math.cos(k * 1.7), 0.05 * math.sin(k))
    glow_ball(b, q, 0.012 + 0.008 * (k % 2), "fff0c0", tail[min(len(tail) - 1, i)])
# sparks orbiting the body
for k in range(6):
    a = k / 6 * 2 * math.pi
    glow_ball(b, V(math.cos(a) * 0.38, Y + 0.12 * math.sin(a * 2), math.sin(a) * 0.38), 0.016, "fff8d0", "body")
b.cur_pal = 0.5  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# little arms with three fingers of flame, and a face: big eyes, blushing cheeks, a small mouth
for s, sd in ((1, "L"), (-1, "R")):
    ar = r.bones["arm." + sd]
    b.tube([ar[0], V(ar[0]).lerp(V(ar[1]), 0.5) + V(0, -0.02, 0), ar[1]], [0.05, 0.035, 0.022], (0.92, 0.92, 0.92), cls=SKIN, bone="arm." + sd, tint=1.0, seg=10)
    for f in range(3):
        a = (f - 1) * 0.5
        tip = V(ar[1]) + V(math.sin(a) * 0.04 * s, 0.02 + 0.03 * math.cos(a), 0.03)
        b.leaf(V(ar[1]), tip, 0.012, (1.0, 1.0, 1.0), cls=CLOTH, bone="arm." + sd, tint=1.0, mat=MAT_GLOW, n=3)
    b.eye(V(0.09 * s, Y + 0.04, 0.22), 0.055, "203040", side=s, bone="body", rot_y=0.3, h=1.3, accent=True)
    b.ellipsoid(V(0.15 * s, Y - 0.05, 0.2), (0.035, 0.018, 0.01), "ffa0a0", cls=SKIN, bone="body", seg=8, rings=4, rot=(0, 0.6 * s, 0), mat=MAT_PLAIN)
b.tube([V(-0.04, Y - 0.08, 0.25), V(0, Y - 0.1, 0.26), V(0.04, Y - 0.08, 0.25)], [0.008, 0.008, 0.008], "302030", cls=CLOTH, bone="body", seg=5)

T_IDLE = 2.0


def flicker(p, t, speed, amp):
    for k, (names, _) in enumerate(flames):
        # whole multiples of the clip's base speed so the loops close
        wave_chain(p, names, t + k * 0.37, speed * (1.0 + 0.5 * (k % 3)), amp, axis=2 if k % 2 else 0, lag=0.9, grow=0.4)
    wave_chain(p, tail, t, speed * 0.5, amp * 0.8, axis=1, lag=0.8)


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    flicker(p, t, w * 2, 0.18)
    p["body"] = ((0, math.sin(t * w + 0.7) * 0.2, 0), (0, math.sin(t * w) * 0.08, 0), (1.0 + 0.04 * math.sin(t * w * 2), 1.0 - 0.04 * math.sin(t * w * 2), 1.0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((math.sin(t * w + s) * 0.3, 0, math.sin(t * w * 2) * 0.2 * s), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    p = idle(0.0)
    flicker(p, t, 18.0, 0.35)
    p["root"] = ((0, 0, 0), (0, 0.1 * e, 0.6 * math.sin(min(1.0, k * 1.6) * math.pi)))
    p["body"] = ((0.3 * e, 0, 0), (0, 0, 0), (1.0 + 0.3 * e, 1.0 + 0.3 * e, 1.0 + 0.3 * e))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    flicker(p, t, 25.0, 0.4 * e)
    p["body"] = ((-0.3 * e, 0, 0.3 * e), (0, -0.1 * e, -0.15 * e), (1.0 - 0.25 * e, 1.0 - 0.25 * e, 1.0 - 0.25 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    flicker(p, t, 12.0, 0.3)
    p["body"] = ((0, t * 8.0, 0), (0, 0.25 * e, 0), (1.0 + 0.4 * e, 1.0 + 0.4 * e, 1.0 + 0.4 * e))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((-1.2 * e, 0, 0), (0, 0, 0))
    return p


T_WALK = 1.0


def walk(t):
    """Drifts forward, leaning into the motion, its flames and tail streaming behind."""
    w = 2 * math.pi / T_WALK
    p = idle(t * T_IDLE / T_WALK)
    flicker(p, t, w * 2, 0.22)
    add(p, "body", (0.3, 0, 0.08 * math.sin(t * w)), (0, 0.05 * math.sin(t * w * 2), 0))
    for nm in tail:
        add(p, nm, (0.2, 0, 0))
    return p


def die(t):
    """Gutters out: flares once, shrinks to a spark and drops."""
    k = min(1.0, t / 1.2)
    flare = math.sin(math.pi * smooth(0.0, 0.25, k))
    f = smooth(0.2, 0.9, k)
    p = idle(t * (1.0 - f))
    flicker(p, t, 30.0, 0.4 * (1.0 - f))
    s_ = max(0.02, (1.0 + 0.3 * flare) * (1.0 - 0.95 * f))
    p["body"] = ((0, 0, 0), (0, -1.1 * f, 0), (s_, s_, s_))
    return p

print("[art] wisp: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/wisp.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=10, dist=0.2, strength=0.25)
