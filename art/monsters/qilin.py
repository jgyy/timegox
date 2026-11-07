"""Qilin (new in Part VIII): the auspicious hoofed beast of the Jasper Pool and the star-meadows
(Jade Qilin, Star-Mane Qilin, the Golden Ox Star's herd-guardians).

Built on art/lib/anatomy.py with a deer's light frame: a deep chest and tucked waist, long slender
legs ending in cloven hooves with fetlocks, a long arched neck, and a head between a dragon's and
a deer's - a short muzzle with flared nostrils, a heavy brow, a single ridged horn swept back, ox
ears and long whiskers.  Its hide is covered in rows of round carp scales (painted on the body),
a flowing mane runs from crown to withers, flame tufts burn at its elbows and fetlocks, and an
ox's tail ends in a plume.  Tinted by the game per enemy; horn, hooves and flames keep their own
colours.
Run: blender --background --python art/monsters/qilin.py  ->  assets/monsters/qilin.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import eyes, fangs, quad_rig, tail_wave, weights_for, zero_pose  # noqa: E402
from kit import CRYSTAL, HAIR, MAT_GLOW, MAT_PLAIN, SKIN, STONE, V, Builder, env  # noqa: E402
from sculpt import blob3, catmull, morph_sphere, smooth, strand  # noqa: E402

kit.reset()
BY = 1.0
NECK = V(0, 1.5, 0.66)
HEAD = V(0, 1.6, 0.98)
TAIL = [(0, 1.08, -0.56), (0, 1.0, -0.78), (0, 0.84, -0.94), (0, 0.66, -1.04), (0, 0.5, -1.06)]
r = quad_rig(BY, 0.4, -0.44, 0.12, NECK, HEAD, TAIL,
             extra=[("ear.L", (0.08, 1.7, 0.78), (0.18, 1.74, 0.72), "head"), ("ear.R", (-0.08, 1.7, 0.78), (-0.18, 1.74, 0.72), "head")])
b = Builder("qilin")
body_bones = [n for n in r.bones if not n.startswith("ear") and n not in ("jaw", "root") and "_paw" not in n and "_lo" not in n]
weights = weights_for(r, body_bones, sharp=3.0, k=3)

sp = A.QuadSpec(hip_w=0.17, chest_w=0.16, chest_d=0.36, waist_d=0.16, waist_w=0.13, back_h=0.11, withers=0.08, neck_r=0.12, shade=(0.6, 1.02), seed=21)
torso, spine_y = A.quad_body(b, r, sp, weights)


# carp scales over the hide: rows of round scales with darker rims, smaller towards the belly
def scale_paint(v):
    p = kit.b2g(v.co)
    c = v[b.cl]
    sx = (p.z + 2.0) * 11.0
    sy = (p.y - spine_y(p.z)) * 14.0 + 0.5 * (math.floor(sx) % 2)
    fx, fy = sx - math.floor(sx), sy - math.floor(sy)
    rim = 1.0 - 0.2 * smooth(0.28, 0.48, math.hypot(fx - 0.3, fy - 0.5))
    under = smooth(spine_y(p.z) - 0.25, spine_y(p.z) - 0.4, p.y)
    k = rim * (1.0 - under) + under
    v[b.cl] = (c[0] * k, c[1] * k, c[2] * k, c[3])


for v in torso:
    scale_paint(v)
for nm in ("f", "h"):
    for sd in ("L", "R"):
        legv = A.quad_leg(b, r, nm, sd, sp, spine_y, thick=0.75 if nm == "f" else 0.85, paw=False, hoof=True)
        # flame tufts at the elbow (or hock) and round the fetlock
        up = r.tail("%s_up.%s" % (nm, sd))
        ank = r.tail("%s_lo.%s" % (nm, sd))
        s = 1 if sd == "L" else -1
        for k in range(4):
            a = k / 4 * 2 * math.pi
            out = V(math.sin(a) * 0.4 + 0.6 * s, 0.0, math.cos(a))
            out.normalize()
            strand(b, [up + out * 0.04, up + out * 0.08 + V(0, 0.03, -0.06), up + out * 0.1 + V(0, 0.1, -0.14)], 0.03, 0.002, "ffb040", col_tip="fff0a0", cls=HAIR, bone="%s_lo.%s" % (nm, sd), seg=5, per=3, mat=MAT_GLOW)
            strand(b, [ank + out * 0.035, ank + out * 0.07 + V(0, 0.03, -0.04), ank + out * 0.08 + V(0, 0.09, -0.1)], 0.025, 0.002, "ffb040", col_tip="fff0a0", cls=HAIR, bone="%s_paw.%s" % (nm, sd), seg=5, per=3, mat=MAT_GLOW)

# head: a short dragon-deer face on the head bone
hv = (HEAD - NECK).normalized()
hf = A.HeadFrame(NECK + hv * 0.12 + V(0, 0.04, 0), hv + V(0, -0.25, 0))


def skull(d):
    p = V(d.x * 0.1, d.y * 0.1, d.z * 0.12)
    front = smooth(0.0, 1.0, d.z)
    p.z += 0.12 * front ** 1.3
    p.x *= 1.0 - 0.3 * front ** 1.2
    p.y *= 1.0 - 0.25 * front
    q = p.copy()
    off = 0.0
    for s2 in (1, -1):
        off += 0.02 * blob3(q, (0.055 * s2, 0.07, 0.07), (0.035, 0.018, 0.05))   # brow ridges
        off += 0.016 * blob3(q, (0.035 * s2, 0.02, 0.22), (0.025, 0.02, 0.03))   # nostril bulbs
    return p + p.normalized() * off


morph_sphere(b, hf.c, skull, lambda p, d: (0.78 + 0.15 * d.y,) * 3, cls=HAIR, bone="head", seg=24, rings=16, tint_fn=lambda p, d: 1.0, rot=hf.M)
b.ellipsoid(hf.at(0, -0.075, 0.1), (0.06, 0.03, 0.12), (0.95, 0.95, 0.95), cls=SKIN, bone="jaw", tint=1.0, seg=12, rings=6)
for s in (1, -1):
    b.ellipsoid(hf.at(0.032 * s, 0.015, 0.235), (0.012, 0.009, 0.006), "201010", cls=SKIN, bone="head", seg=6, rings=4, mat=MAT_PLAIN)
    whisker = [hf.at(0.04 * s, -0.01, 0.22), hf.at(0.12 * s, -0.03, 0.24), hf.at(0.24 * s, -0.12, 0.2), hf.at(0.3 * s, -0.24, 0.12)]
    strand(b, whisker, 0.007, 0.0015, "f0e0a0", cls=HAIR, bone="head", seg=5, per=3)
    ear = [hf.at(0.08 * s, 0.07, -0.04), hf.at(0.15 * s, 0.08, -0.07), hf.at(0.2 * s, 0.06, -0.1)]
    b.tube(ear, [(0.03, 0.01), (0.026, 0.008), (0.003, 0.002)], (0.7, 0.7, 0.7), cls=HAIR, bone="ear." + ("L" if s > 0 else "R"), seg=8, up=(0, 1, 0), tint=1.0)
eyes(b, hf.at(0, 0.05, 0.08), 0.09, 0.028, iris="ffd040", bone="head", slit=False, glow=True, rot_y=0.9, h=0.9)
fangs(b, [hf.at(0.03, -0.055, 0.2), hf.at(-0.03, -0.055, 0.2)], 0.035, "head")
# the single ridged horn, swept back over the crown
horn = [hf.at(0, 0.1, 0.02), hf.at(0, 0.2, -0.04), hf.at(0, 0.28, -0.14), hf.at(0, 0.3, -0.26)]
strand(b, horn, 0.035, 0.004, "e8d8a8", col_tip="fff8e0", cls=STONE, bone="head", seg=10, per=4)
for k in range(5):
    q = horn[0].lerp(horn[2], 0.15 + k * 0.17)
    b.tube([q + V(0, 0.004, 0), q - V(0, 0.004, 0)], [0.034 - k * 0.004] * 2, "c8b888", cls=STONE, bone="head", seg=10, cap0=False, cap1=False)
b.ball(hf.at(0, 0.1, 0.06), 0.018, "80f0d0", cls=CRYSTAL, bone="head", seg=8, rings=6, mat=MAT_GLOW)
# mane: long locks from the crown down the crest of the neck to the withers
for i in range(16):
    t = i / 15
    root = hf.at(0, 0.1, -0.05).lerp(V(0, BY + 0.2, 0.38), t)
    for sgn in (-1, 1):
        tip = root + V(0.1 * sgn, -0.12 - 0.06 * math.sin(t * math.pi), -0.12)
        strand(b, [root, root.lerp(tip, 0.5) + V(0.03 * sgn, 0.04, 0), tip], 0.03, 0.003, (0.5, 0.5, 0.5), col_tip=(0.95, 0.95, 0.95), cls=HAIR, bone=weights(root) if t > 0.2 else "head", flat=0.4, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
# a beard of fine hair under the jaw
for k in range(5):
    u = (k / 4 - 0.5)
    root = hf.at(u * 0.06, -0.09, 0.1)
    strand(b, [root, root + V(0, -0.06, 0.01), root + V(u * 0.03, -0.12, -0.01)], 0.012, 0.002, (0.85, 0.85, 0.85), cls=HAIR, bone="jaw", flat=0.4, seg=4, per=3, tint=1.0, mat=MAT_PLAIN)
# an ox's tail: a slender core ending in a long plume
tp = [V(p) for p in TAIL]
core = catmull(tp, 3)
tb = ["tail%d" % min(3, int(i / (len(core) - 1) * 3.999)) for i in range(len(core))]
b.tube(core, [0.035 - 0.02 * i / len(core) for i in range(len(core))], (0.7, 0.7, 0.7), bones=tb, tint=1.0, seg=8, cls=HAIR)
end = core[-1]
for k in range(10):
    a = k / 10 * 2 * math.pi
    out = V(math.cos(a), 0, math.sin(a))
    strand(b, [end + V(0, 0.12, 0) + out * 0.02, end + out * 0.06, end + out * 0.05 + V(0, -0.18, 0)], 0.025, 0.003, (0.5, 0.5, 0.5), col_tip=(0.95, 0.95, 0.95), cls=HAIR, bone="tail3", flat=0.4, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
# an aura of auspicious cloud wisps curling round the hooves
for k in range(6):
    a = k / 6 * 2 * math.pi
    c = V(math.cos(a) * 0.45, 0.06, math.sin(a) * 0.6)
    curl = [c + V(math.cos(a + t * 3.0) * 0.08 * (1 - t), 0.03 * t, math.sin(a + t * 3.0) * 0.08 * (1 - t)) for t in (0.0, 0.33, 0.66, 1.0)]
    b.tube(curl, [0.03, 0.025, 0.018, 0.006], "f8f4ff", cls=CRYSTAL, bone="root", seg=6, mat=MAT_GLOW, tint=0.3)

T_IDLE = 3.0


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    br = math.sin(t * w * 2)
    p["pelvis"] = ((0, 0, 0), (0, br * 0.008, 0))
    p["chest"] = ((br * 0.015, 0, 0), (0, br * 0.004, 0))
    p["neck"] = ((math.sin(t * w) * 0.05 - 0.05, math.sin(t * w) * 0.12, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w * 2) * 0.05, math.sin(t * w) * 0.1, 0), (0, 0, 0))
    p["jaw"] = ((0.04 + 0.04 * max(0.0, math.sin(t * w * 1.5)), 0, 0), (0, 0, 0))
    p["ear.L"] = ((0, 0, -0.25 * max(0.0, math.sin(t * w * 3)) ** 8), (0, 0, 0))
    p["ear.R"] = ((0, 0, 0.25 * max(0.0, math.sin(t * w * 3 + 1.2)) ** 8), (0, 0, 0))
    tail_wave(p, 4, t, w * 2, 0.15, curl=-0.05)
    # a slow paw of one fore hoof at the ground
    paw = max(0.0, math.sin(t * w)) ** 3
    p["f_up.L"] = ((-0.25 * paw, 0, 0), (0, 0, 0))
    p["f_lo.L"] = ((0.5 * paw, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    rear = smooth(0.0, 0.35, k) * (1.0 - smooth(0.45, 0.6, k))
    strike = math.sin(min(1.0, max(0.0, (k - 0.35) * 2.5)) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0.12 * rear, 0.35 * strike))
    p["pelvis"] = ((-0.45 * rear, 0, 0), (0, 0, 0))
    p["neck"] = ((-0.3 * rear + 0.4 * strike, 0, 0), (0, 0, 0))
    p["head"] = ((0.4 * strike, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up." + sd] = ((-1.0 * rear + 0.3 * strike, 0, 0), (0, 0, 0))
        p["f_lo." + sd] = ((1.2 * rear, 0, 0), (0, 0, 0))
        p["h_up." + sd] = ((0.35 * rear, 0, 0), (0, 0, 0))
    tail_wave(p, 4, t, 12.0, 0.2 + 0.1 * e)
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0, -0.16 * e))
    p["chest"] = ((-0.2 * e, 0, 0.1 * e), (0, 0, 0))
    p["neck"] = ((-0.35 * e, 0.25 * e, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["ear." + sd] = ((0.6 * e, 0, 0), (0, 0, 0))
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    # head thrown up, the horn calling down light
    p["neck"] = ((-0.5 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.4 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.4 * e, 0, 0), (0, 0, 0))
    tail_wave(p, 4, t, 9.0, 0.25, curl=0.3 * e)
    return p


print("[art] qilin: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/qilin.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
