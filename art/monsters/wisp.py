"""Wisp: will-o'-the-wisps, ghost lights and fire sprites (Leaf Sprites, Spark Wisps, Ember Sprites,
Ghost Lanterns, Foxfire Wisps ...).

Designed silhouette first, after the ghost-fire of Chinese and Japanese tales (guihuo, the
hitodama): a round flame of a head trailing a tail of light that sweeps back and curls up like a
comet's, crowned by a crest of three big tongues of flame licking up and back, with small
detached licks floating above their tips the way real flames break.  The whole flame is one
seamless solid shape, so it keeps its ink outline and reads in daylight; its values are laid in
hard steps from the root of every tongue to its tip, which the game's palette turns into a
temperature ramp (pale and hot at the heart, the enemy's colour through the body, dark at the
tips).  A soft halo of additive light round the head, embers circling it, little hands with
fingers of flame, and a face of two dark gem eyes on the hot heart.  Tinted per enemy.
Run: blender --background --python art/monsters/wisp.py  ->  assets/monsters/wisp.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from clay import Clay, limb_weights  # noqa: E402
from creature import add, chain_rig, glow_ball, wave_chain, zero_pose  # noqa: E402
from kit import CLOTH, MAT_GLOW, MAT_PLAIN, SKIN, V, Builder, Rig, env  # noqa: E402
from sculpt import fbm3, smooth  # noqa: E402

kit.reset()
creature.realtime()
Y = 1.25
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
r.bone("body", (0, Y - 0.2, 0), (0, Y + 0.25, 0), "root")
r.bone("head", (0, Y - 0.02, 0.1), (0, Y + 0.12, 0.22), "body")
# the crest: three big tongues sweeping back, two small ones low at the sides
TONGUES = [
    ([V(0, Y + 0.12, -0.02), V(0, Y + 0.36, -0.09), V(0.0, Y + 0.56, -0.21), V(0.0, Y + 0.69, -0.38)], [0.2, 0.125, 0.06, 0.014]),
    ([V(0.12, Y + 0.12, 0.0), V(0.21, Y + 0.31, -0.06), V(0.24, Y + 0.45, -0.17), V(0.22, Y + 0.53, -0.31)], [0.12, 0.075, 0.038, 0.012]),
    ([V(-0.12, Y + 0.12, 0.0), V(-0.21, Y + 0.31, -0.06), V(-0.24, Y + 0.45, -0.17), V(-0.22, Y + 0.53, -0.31)], [0.12, 0.075, 0.038, 0.012]),
    ([V(0.18, Y + 0.0, -0.08), V(0.29, Y + 0.1, -0.17), V(0.34, Y + 0.17, -0.3)], [0.075, 0.04, 0.012]),
    ([V(-0.18, Y + 0.0, -0.08), V(-0.29, Y + 0.1, -0.17), V(-0.34, Y + 0.17, -0.3)], [0.075, 0.04, 0.012]),
]
flames = []
for k, (pts, rad) in enumerate(TONGUES):
    flames.append((chain_rig(r, "f%d_" % k, pts, "body"), pts, rad))
TAIL = [V(0, Y - 0.05, -0.12), V(0.02, Y - 0.24, -0.34), V(-0.03, Y - 0.36, -0.6), V(0.03, Y - 0.32, -0.86), V(0.0, Y - 0.2, -1.0)]
tail = chain_rig(r, "tail", TAIL, "body")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("arm." + sd, (0.2 * s, Y - 0.04, 0.06), (0.36 * s, Y - 0.14, 0.14), "body")
b = Builder("wisp")

# ---------------------------------------------------------------- the flame: one seamless shape, head, crest and tail
cl = Clay(0.017, "wisp_flame")
cl.ellipsoid(V(0, Y, 0.0), (0.25, 0.27, 0.25), bones={"body": 1.0}, tag="head")
for names, pts, rad in flames:
    cl.chain(pts, rad, bones=limb_weights(names), tag="tongue", t0=0.0, t1=float(len(names)))
cl.chain(TAIL, [0.17, 0.13, 0.08, 0.04, 0.012], bones=limb_weights(tail), tag="tail", t0=0.0, t1=float(len(tail)))
for s, sd in ((1, "L"), (-1, "R")):
    a = "arm." + sd
    sh, hand = V(r.bones[a][0]), V(r.bones[a][1])
    cl.chain([sh, sh.lerp(hand, 0.5) + V(0, -0.015, 0), hand], [0.05, 0.035, 0.028], bones={a: 1.0}, tag="arm")
    for f in range(3):
        ang = (f - 1) * 0.55
        tip = hand + V(math.sin(ang) * 0.045 * s, 0.035 + 0.035 * math.cos(ang), 0.03)
        cl.chain([hand, tip], [0.018, 0.006], bones={a: 1.0}, tag="finger")


def heat(p, info):
    """Which part of the flame a point is: 0 the white-hot heart (a teardrop on the front of the
    head, round the face), 0.4 the body of the flame, 1 the tips of the tongues and the tail."""
    if info.tag in ("tongue", "tail"):
        n = len(TAIL) - 1 if info.tag == "tail" else 3
        return 1.0 if info.t / n > (0.62 if info.tag == "tail" else 0.7) else 0.4
    if info.tag in ("arm", "finger"):
        return 0.4 if info.tag == "arm" else 1.0
    d = (p - V(0, Y - 0.04, 0)).normalized()
    # (narrowing upwards, like the inner flame of a candle)
    return 0.0 if d.z > 0.3 + 0.5 * max(0.0, d.y) ** 1.5 else 0.4


# a stylised flame is nested shapes, not bands: near white and barely tinted in the heart, the
# enemy's colour through the body, deeper and saturated at the tips (never black)
STEPS = ((0.2, 1.0, 0.3), (0.7, 0.92, 1.0), (9.0, 0.68, 1.0))


def flame_grey(p, info):
    u = heat(p, info)
    for lim, v, _ in STEPS:
        if u < lim:
            return (v, v, v)


def flame_tint(p, info):
    u = heat(p, info)
    for lim, _, tn in STEPS:
        if u < lim:
            return tn


def lick(p, info):
    # the surface licks upward a little (flames are never round)
    w = fbm3((p.x * 5.0, p.y * 3.0 - 1.0, p.z * 5.0), 2, 7) - 0.5
    return info.n * (0.012 * w) + V(0, 0.01 * w * max(0.0, info.n.y), 0)


cl.build(b, flame_grey, cls=SKIN, tint_fn=flame_tint, post=lick)
# small detached licks floating above the big tongues, the way a flame breaks at its tip
for k, (names, pts, rad) in enumerate(flames[:3]):
    tip = pts[-1]
    up = (pts[-1] - pts[-2]).normalized()
    for j, (off, sz) in enumerate(((0.1, 0.045), (0.2, 0.03))):
        c = tip + up * off + V(0.03 * (j - 0.5) * (1 if k % 2 else -1), 0.02, 0.0)
        A.blade(b, c - up * sz * 1.2, c + up * sz * 1.6, sz * 0.9, (0.66, 0.66, 0.66), (0.6, 0.6, 0.6), bone=names[-1], curl=0.1, thick=0.6,
                tint=1.0, cls=SKIN, steps=4, seg=8, point=0.9)

# ---------------------------------------------------------------- the face: two dark gem eyes on the hot heart
hit = A.surface(b)
for s in (1, -1):
    h = hit(V(0.085 * s, Y + 0.02, 1.0), V(0, 0, -1), 2.0)
    p, n = (h[0], h[1]) if h is not None else (V(0.085 * s, Y + 0.02, 0.24), V(0, 0, 1))
    rot = (0.0, math.atan2(n.x, n.z), -0.15 * s)
    b.ellipsoid(p + n * 0.004, (0.034, 0.05, 0.016), "1c0c14", cls=SKIN, bone="head", rot=rot, seg=14, rings=8, mat=MAT_PLAIN)
    b.ellipsoid(p + n * 0.016 + V(0.01 * s, 0.018, 0), (0.011, 0.014, 0.005), "ffffff", cls=CLOTH, bone="head", rot=rot, seg=8, rings=5, mat=MAT_GLOW)
h = hit(V(0.0, Y - 0.07, 1.0), V(0, 0, -1), 2.0)
p, n = (h[0], h[1]) if h is not None else (V(0.0, Y - 0.07, 0.24), V(0, 0, 1))
b.tube([p + V(-0.025, 0.004, 0) + n * 0.003, p + V(0, -0.006, 0) + n * 0.004, p + V(0.025, 0.004, 0) + n * 0.003], [0.006, 0.007, 0.006], "3a1420",
       cls=SKIN, bone="head", seg=5, mat=MAT_PLAIN)

# ---------------------------------------------------------------- light: a soft halo round the head, embers circling it
b.cur_pal = 0.0
# (behind the head, so it brightens the outline and not the face)
b.ellipsoid(V(0, Y + 0.03, -0.1), (0.36, 0.38, 0.14), (0.36, 0.36, 0.36), cls=CLOTH, bone="body", tint=1.0, mat=MAT_GLOW, seg=20, rings=14)
b.cur_pal = 1.0
for k in range(6):
    a = k / 6 * 2 * math.pi
    glow_ball(b, V(math.cos(a) * 0.42, Y + 0.12 * math.sin(a * 2), math.sin(a) * 0.42), 0.02, "fff8d0", "body", accent=True)
for k in range(5):
    t = 0.35 + k * 0.13
    i = min(len(TAIL) - 2, int(t * (len(TAIL) - 1)))
    q = TAIL[i].lerp(TAIL[i + 1], t * (len(TAIL) - 1) - i) + V(0.07 * math.sin(k * 2.3), 0.05 * math.cos(k * 1.7), 0.04 * math.sin(k))
    glow_ball(b, q, 0.014 + 0.007 * (k % 2), "fff0c0", tail[min(len(tail) - 1, i)], accent=True)
b.cur_pal = 0.0

T_IDLE = 2.0


def flicker(p, t, speed, amp):
    for k, (names, _, _) in enumerate(flames):
        # whole multiples of the clip's base speed so the loops close
        wave_chain(p, names, t + k * 0.37, speed * (1.0 + 0.5 * (k % 3)), amp, axis=2 if k % 2 else 0, lag=0.9, grow=0.4)
    wave_chain(p, tail, t, speed * 0.5, amp * 0.7, axis=1, lag=0.8)


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    flicker(p, t, w * 2, 0.16)
    p["body"] = ((0, math.sin(t * w + 0.7) * 0.15, 0), (0, math.sin(t * w) * 0.08, 0), (1.0 + 0.04 * math.sin(t * w * 2), 1.0 - 0.04 * math.sin(t * w * 2), 1.0))
    for sd, s in (("L", 1), ("R", -1)):
        p["arm." + sd] = ((math.sin(t * w + s) * 0.3, 0, math.sin(t * w * 2) * 0.2 * s), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    p = idle(0.0)
    flicker(p, t, 18.0, 0.32)
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
    """Drifts forward, leaning into the motion, its crest and tail streaming behind."""
    w = 2 * math.pi / T_WALK
    p = idle(t * T_IDLE / T_WALK)
    flicker(p, t, w * 2, 0.2)
    add(p, "body", (0.3, 0, 0.08 * math.sin(t * w)), (0, 0.05 * math.sin(t * w * 2), 0))
    for nm in tail:
        add(p, nm, (0.15, 0, 0))
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
# a flame is lit from within: its stepped values are its own (no coat split), and it takes almost no occlusion
kit.finish_rigged(b, r, "monsters/wisp.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)},
                  coat=False, samples=8, dist=0.1, strength=0.12)
