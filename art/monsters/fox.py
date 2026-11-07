"""Fox: the nine-tailed fox spirit of the Maple Gorge (Part VI) and the Hounds of the Ten Courts.
A slender body from art/lib/anatomy.py on long dark-stockinged legs, a long narrow muzzle, tall
black-tipped ears, white cheek ruffs and bib, a groomed coat, and nine bushy tails fanned behind it, each tipped in white with a wisp of fox-fire.  Every
tail is its own three-bone chain, so the fan ripples like flames.  Tinted by the game per enemy;
the white tips, bib and fox-fire keep their own colours.
Run: blender --background --python art/monsters/fox.py  ->  assets/monsters/fox.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import glow_ball, quad_rig, weights_for, zero_pose  # noqa: E402
from kit import HAIR, MAT_PLAIN, V, Builder, env  # noqa: E402
from sculpt import catmull, smooth, strand  # noqa: E402

kit.reset()
BY = 0.78
N_TAILS = 9
extra = [("ear.L", (0.09, 1.2, 0.84), (0.13, 1.44, 0.8), "head"), ("ear.R", (-0.09, 1.2, 0.84), (-0.13, 1.44, 0.8), "head")]
# nine tail chains fanned behind the hips
tails = []
for k in range(N_TAILS):
    # a three-dimensional fan: outer tails sweep wide and low, inner ones rise high; heights,
    # lengths and curl vary per tail so the tips do not line up
    u = k / (N_TAILS - 1) - 0.5
    a = u * 3.0
    ln = 1.0 - 0.18 * abs(math.sin(k * 2.3))
    lift = 0.55 - 0.45 * abs(u) * 2 + 0.08 * math.sin(k * 1.7)
    base = V(0, 0.86, -0.5)
    d1 = V(math.sin(a) * 0.25, 0.1 + lift * 0.3, -0.36) * ln
    d2 = V(math.sin(a) * 0.55, lift, -0.18 + 0.12 * math.cos(k * 1.3)) * ln
    d3 = V(math.sin(a) * 0.3 + 0.06 * math.cos(k), 0.1 - 0.15 * abs(u), 0.18) * ln
    p1 = base + d1
    p2 = p1 + d2
    p3 = p2 + d3
    tails.append([base, p1, p2, p3])
    extra.append(("ft%d_0" % k, base, p1, "pelvis"))
    extra.append(("ft%d_1" % k, p1, p2, "ft%d_0" % k))
    extra.append(("ft%d_2" % k, p2, p3, "ft%d_1" % k))
r = quad_rig(BY, 0.36, -0.4, 0.1, (0, 1.04, 0.58), (0, 1.04, 0.96), [(0, 0.86, -0.5), (0, 0.9, -0.6)], extra=extra)
b = Builder("fox")
body_bones = [n for n in r.bones if not n.startswith("ear") and not n.startswith("ft") and n not in ("jaw", "root", "tail0") and "_paw" not in n and "_lo" not in n]
weights = weights_for(r, body_bones, sharp=3.0, k=3)

# a slender, light-boned body: shallow tuck, long legs, narrow chest
sp = A.QuadSpec(hip_w=0.15, chest_w=0.14, chest_d=0.26, waist_d=0.14, waist_w=0.11, back_h=0.1, withers=0.03, neck_r=0.1, shade=(0.6, 1.05), seed=5)
torso, spine_y = A.quad_body(b, r, sp, weights)
legs = {}
for nm in ("f", "h"):
    for sd in ("L", "R"):
        # dark "stockings" on the lower legs keep their own colour
        legs[nm + sd] = A.quad_leg(b, r, nm, sd, sp, spine_y, thick=0.8 if nm == "f" else 0.9)
for v in b.bm.verts:
    p = kit.b2g(v.co)
    if p.y < 0.36 and abs(p.x) > 0.04:
        k = smooth(0.36, 0.22, p.y)
        c = v[b.cl]
        v[b.cl] = (c[0] * (1 - 0.85 * k) + 0.02 * k, c[1] * (1 - 0.85 * k) + 0.015 * k, c[2] * (1 - 0.85 * k) + 0.02 * k, c[3])
        v[b.tl] = v[b.tl] * (1.0 - k)
hv = (V(0, 1.04, 0.96) - V(0, 1.04, 0.58)).normalized()
hf = A.HeadFrame(V(0, 1.06, 0.66), hv + V(0, -0.1, 0))
A.canine_head(b, hf, 1.0, eye_col="ffb020", long=1.25, ear_len=1.35, ruff=False)
A.fur(b, torso, 280, 0.06, 0.024, seed=9, bone_fn=weights, min_dist=0.03, col_root=(0.6, 0.6, 0.6), col_tip=(0.92, 0.92, 0.92))
# white bib on the chest and throat and white cheek ruffs (untinted)
for i in range(14):
    a = (i / 13 - 0.5) * 2.4
    root = V(math.sin(a) * 0.09, 0.98 - abs(a) * 0.03, 0.5 + math.cos(a) * 0.04)
    strand(b, [root, root + V(math.sin(a) * 0.03, -0.08, 0.04), root + V(math.sin(a) * 0.04, -0.17, 0.02)], 0.03, 0.003, "f4f0ea", col_tip="ffffff", cls=HAIR, bone="chest", flat=0.4, seg=5, per=3, mat=MAT_PLAIN)
for s in (1, -1):
    for k in range(5):
        root = hf.at(0.07 * s, -0.03 - k * 0.012, 0.02 - k * 0.015)
        strand(b, [root, root + hf.M @ V(0.06 * s, -0.015, -0.03), root + hf.M @ V(0.1 * s, -0.04 - k * 0.01, -0.06)], 0.022, 0.002, "f4f0ea", col_tip="ffffff", cls=HAIR, bone="head", flat=0.4, seg=5, per=3, mat=MAT_PLAIN)
    # black ear tips
    tip = hf.at(0.085 * s, 0.07 + 0.14 * 1.35, -0.01)
    b.ellipsoid(tip + V(0, -0.02, 0), (0.018, 0.04, 0.008), "1a1418", cls=HAIR, bone="ear." + ("L" if s > 0 else "R"), seg=8, rings=5)
b.cur_pal = 0.3  # palette slot (kit.py): 0 primary, 0.5 secondary, 1 accent
# nine bushy tails: a core per tail wrapped in spiralling fur, the colour fading to a white tip,
# a wisp of fox-fire at the end
for k, pts in enumerate(tails):
    core = catmull(pts, 3)
    m = len(core)
    tb = ["ft%d_%d" % (k, min(2, int(i / (m - 1) * 2.999))) for i in range(m)]
    radii = [0.04 + 0.08 * math.sin(math.pi * min(1.0, i / (m - 1) * 1.15)) for i in range(m)]
    white = [smooth(0.62, 0.9, i / (m - 1)) for i in range(m)]
    b.tube(core, radii, (0.8, 0.8, 0.8), bones=tb, seg=12, cls=HAIR, cols=[(0.8 + 0.2 * w,) * 3 for w in white], tints=[1.0 - w for w in white])
    for i in range(1, m - 1):
        d = (core[i + 1] - core[i - 1]).normalized()
        side = d.cross(V(0, 1, 0))
        side = side.normalized() if side.length > 1e-4 else V(1, 0, 0)
        up = side.cross(d).normalized()
        for j in range(5):
            a = j / 5 * 2 * math.pi + i * 0.9 + k
            out = side * math.cos(a) + up * math.sin(a)
            root = core[i] + out * radii[i] * 0.8
            ln = 0.09 + 0.05 * math.sin(math.pi * i / m)
            w = white[i]
            c = (0.7 + 0.3 * w,) * 3
            strand(b, [root, root + out * ln * 0.45 + d * ln * 0.5, root + out * ln * 0.3 + d * ln * 1.1], 0.03, 0.003, c, col_tip=(0.95,) * 3, cls=HAIR, bone=tb[i], flat=0.4, seg=5, per=2, tint=1.0 - w, mat=MAT_PLAIN)
    glow_ball(b, pts[3] + (pts[3] - pts[2]).normalized() * 0.08, 0.045, "ffb860", "ft%d_2" % k)

T_IDLE = 3.0


def fan(p, t, speed, amp, spread=0.0):
    for k in range(N_TAILS):
        ph = t * speed + k * 0.55
        for j in range(3):
            p["ft%d_%d" % (k, j)] = ((math.sin(ph - j * 0.8) * amp * (0.6 + j * 0.3) - spread * 0.2, math.cos(ph - j * 0.6) * amp * 0.6, (k / (N_TAILS - 1) - 0.5) * spread), (0, 0, 0))


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    br = math.sin(t * w * 2)
    p["pelvis"] = ((0, 0, 0), (0, br * 0.008, 0))
    p["chest"] = ((br * 0.02, 0, 0), (0, 0, 0))
    p["neck"] = ((math.sin(t * w) * 0.05, math.sin(t * w) * 0.18, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w * 2) * 0.05, 0, math.sin(t * w) * 0.12), (0, 0, 0))
    p["jaw"] = ((0.04 + abs(math.sin(t * w)) * 0.06, 0, 0), (0, 0, 0))
    p["ear.L"] = ((0, 0, -0.25 * max(0.0, math.sin(t * w * 3)) ** 8), (0, 0, 0))
    p["ear.R"] = ((0, 0, 0.25 * max(0.0, math.sin(t * w * 3 + 1.3)) ** 8), (0, 0, 0))
    fan(p, t, w * 2, 0.16)
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.6) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.08 * lunge, 0.5 * lunge))
    p["chest"] = ((0.2 * e - 0.35 * lunge, 0, 0), (0, 0, 0))
    p["neck"] = ((0.3 * lunge, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.7 * lunge, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up." + sd] = ((-0.9 * lunge, 0, 0), (0, 0, 0))
        p["f_lo." + sd] = ((0.6 * lunge, 0, 0), (0, 0, 0))
        p["h_up." + sd] = ((0.45 * lunge, 0, 0), (0, 0, 0))
    fan(p, t, 14.0, 0.25, spread=0.4 * e)
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0, -0.2 * e))
    p["chest"] = ((-0.25 * e, 0, 0.12 * e), (0, 0, 0))
    p["neck"] = ((-0.4 * e, 0.25 * e, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["ear." + sd] = ((0.7 * e, 0, 0), (0, 0, 0))
    fan(p, t, 20.0, 0.1, spread=-0.5 * e)
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    # the tails flare into a full fan of fox-fire
    p["neck"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.5 * e, 0, 0), (0, 0, 0))
    fan(p, t, 10.0, 0.12, spread=1.0 * e)
    return p


print("[art] fox: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/fox.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
