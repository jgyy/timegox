"""Beast: the wolf / lion / qilin / ape shape (Bamboo Wolf, Frost Wolf, Jade Guardian Lion, Azure
Qilin ...).  Built on art/lib/anatomy.py: a keel-shaped ribcage with a tucked waist, withers and
croup, muscled shoulders and haunches on legs with the stifle forward and the hock back, paws with
toe pads and claws, a canine head with a stop, wedge muzzle and separate jaw, a groomed coat of
fur clumps, a heavier mane round the neck and a bushy tail.  Tinted by the game per enemy.
Run: blender --background --python art/monsters/beast.py  ->  assets/monsters/beast.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import anatomy as A  # noqa: E402
from creature import quad_rig, tail_wave, weights_for, zero_pose  # noqa: E402
from kit import HAIR, MAT_PLAIN, V, Builder, env  # noqa: E402
from sculpt import catmull, smooth, strand  # noqa: E402

kit.reset()
BY = 0.86
NECK = V(0, 1.14, 0.62)
HEAD = V(0, 1.12, 1.02)
r = quad_rig(BY, 0.4, -0.42, 0.13, NECK, HEAD, [(0, 0.95, -0.6), (0, 1.02, -0.84), (0, 1.0, -1.06), (0, 0.9, -1.26), (0, 0.8, -1.42)],
             extra=[("ear.L", (0.08, 1.24, 0.72), (0.11, 1.4, 0.68), "head"), ("ear.R", (-0.08, 1.24, 0.72), (-0.11, 1.4, 0.68), "head")])
b = Builder("beast")
body_bones = [n for n in r.bones if not n.startswith("ear") and n not in ("jaw", "root") and "_paw" not in n and "_lo" not in n]
weights = weights_for(r, body_bones, sharp=3.0, k=3)

sp = A.QuadSpec(hip_w=0.19, chest_w=0.18, chest_d=0.33, waist_d=0.17, waist_w=0.14, back_h=0.12, withers=0.06, neck_r=0.13, shade=(0.52, 1.0), stripes=9.0)
torso, spine_y = A.quad_body(b, r, sp, weights)
legs = {}
for nm in ("f", "h"):
    for sd in ("L", "R"):
        legs[nm + sd] = A.quad_leg(b, r, nm, sd, sp, spine_y, thick=1.0 if nm == "f" else 1.1)

# head: a canine skull on the head bone, looking slightly down along the muzzle
hv = (HEAD - NECK).normalized()
hf = A.HeadFrame(NECK + hv * 0.12 + V(0, 0.03, 0), hv + V(0, -0.15, 0))
A.canine_head(b, hf, 1.25, eye_col="ffd040", long=0.95, ear_len=0.9)

# coat: clumps groomed back along the body and down the flanks, longer over the shoulders
def longer_fore(p):
    return 1.0 + 0.6 * smooth(0.0, 0.5, p.z) + 0.3 * smooth(0.0, -0.3, p.y - spine_y(p.z))


A.fur(b, torso, 360, 0.075, 0.03, groom=A.groom_back, seed=11, bone_fn=weights, len_fn=longer_fore, min_dist=0.035,
      col_root=(0.55, 0.55, 0.55), col_tip=(0.9, 0.9, 0.9))
# shoulders and haunches carry the coat down the upper legs; the lower legs stay sleek
for key, verts in legs.items():
    up = "%s_up.%s" % (key[0], key[1])
    A.fur(b, verts, 40, 0.06, 0.026, seed=20 + len(key) + ord(key[1]), bone_fn=lambda p, up=up: {up: 1.0},
          pred=lambda p, n: p.y > BY * 0.5, min_dist=0.03, col_root=(0.5, 0.5, 0.5), col_tip=(0.85, 0.85, 0.85),
          groom=lambda p, n: (V(0, -1, -0.2) - n * V(0, -1, -0.2).dot(n)).normalized())
# mane: a ruff of long locks round the neck and over the withers
for ring in range(3):
    for i in range(16):
        a = (i + 0.5 * ring) / 16 * 2 * math.pi
        c = NECK.lerp(V(0, BY + 0.08, 0.36), 0.25 + ring * 0.28)
        out = V(math.sin(a), math.cos(a) * 0.9, 0.0)
        root = c + out * (0.14 + 0.02 * ring)
        tip = root + out * (0.1 - 0.02 * ring) + V(0, -0.06, -0.16)
        w = weights(root)
        strand(b, [root, root.lerp(tip, 0.5) + out * 0.03, tip], 0.04, 0.004, (0.5, 0.5, 0.5), col_tip=(0.9, 0.9, 0.9), cls=HAIR, bone=w, flat=0.45, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)
# chest bib of pale fur
for i in range(10):
    a = (i / 9 - 0.5) * 2.2
    root = V(math.sin(a) * 0.12, BY - 0.02 - abs(a) * 0.02, 0.5 + math.cos(a) * 0.04)
    strand(b, [root, root + V(math.sin(a) * 0.03, -0.1, 0.05), root + V(math.sin(a) * 0.05, -0.2, 0.03)], 0.03, 0.003, (0.85, 0.85, 0.85), col_tip=(1, 1, 1), cls=HAIR, bone="chest", flat=0.4, seg=5, per=3, tint=1.0, mat=MAT_PLAIN)

# tail: a tapering core wrapped in long fur, a darker tip
tp = [r.head("tail0"), r.head("tail1"), r.head("tail2"), r.head("tail3"), r.tail("tail3")]
core = catmull(tp, 3)
tb = []
for i in range(len(core)):
    f = i / (len(core) - 1) * 3.999
    tb.append("tail%d" % int(f))
b.tube(core, [0.06 - 0.03 * i / len(core) for i in range(len(core))], (0.6, 0.6, 0.6), bones=tb, tint=1.0, seg=10, cls=HAIR)
for i in range(1, len(core)):
    d = (core[i] - core[i - 1]).normalized()
    side = d.cross(V(0, 1, 0)).normalized()
    up = side.cross(d).normalized()
    for k in range(6):
        a = k / 6 * 2 * math.pi + i * 0.5
        out = side * math.cos(a) + up * math.sin(a)
        root = core[i] + out * 0.03
        ln = 0.12 + 0.06 * math.sin(math.pi * i / len(core))
        dark = smooth(0.7, 1.0, i / len(core))
        strand(b, [root, root + out * ln * 0.5 + d * ln * 0.6, root + out * ln * 0.4 + d * ln * 1.3], 0.03, 0.003, (0.55 - 0.25 * dark,) * 3, col_tip=(0.85 - 0.5 * dark,) * 3, cls=HAIR, bone=tb[i], flat=0.4, seg=5, per=2, tint=1.0, mat=MAT_PLAIN)

T_IDLE = 3.0


def idle(t):
    w = 2 * math.pi / T_IDLE
    p = zero_pose(r)
    br = math.sin(t * w * 2)
    p["pelvis"] = ((0, 0, 0), (0, br * 0.008, 0))
    p["chest"] = ((br * 0.02, 0, 0), (0, br * 0.004, 0))
    p["neck"] = ((math.sin(t * w) * 0.05 - 0.05, math.sin(t * w) * 0.15, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w * 2) * 0.04, math.sin(t * w) * 0.1, math.sin(t * w + 0.5) * 0.04), (0, 0, 0))
    p["jaw"] = ((0.05 + abs(math.sin(t * w)) * 0.12, 0, 0), (0, 0, 0))   # panting
    p["ear.L"] = ((0, 0, -0.2 * max(0.0, math.sin(t * w * 3)) ** 8), (0, 0, 0))
    p["ear.R"] = ((0, 0, 0.2 * max(0.0, math.sin(t * w * 3 + 1.0)) ** 8), (0, 0, 0))
    tail_wave(p, 4, t, w * 2, 0.16, curl=-0.08)
    for sd, s in (("L", 1), ("R", -1)):
        p["f_up." + sd] = ((br * 0.02, 0, 0), (0, 0, 0))
        p["h_up." + sd] = ((-0.04, 0, 0), (0, 0, 0))
        p["h_lo." + sd] = ((0.06, 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.6
    e = env(k)
    crouch = smooth(0.0, 0.3, k) * (1.0 - smooth(0.3, 0.45, k))
    lunge = math.sin(min(1.0, max(0.0, (k - 0.25) * 1.9)) * math.pi)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, -0.06 * crouch + 0.06 * lunge, 0.5 * lunge))
    p["pelvis"] = ((0.1 * crouch, 0, 0), (0, 0, 0))
    p["chest"] = ((0.25 * crouch - 0.4 * lunge, 0, 0), (0, 0, 0))
    p["neck"] = ((0.2 * crouch + 0.3 * lunge, 0, 0), (0, 0, 0))
    p["head"] = ((-0.2 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.8 * lunge, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up." + sd] = ((-0.95 * lunge + 0.2 * crouch, 0, 0), (0, 0, 0))
        p["f_lo." + sd] = ((0.6 * lunge, 0, 0), (0, 0, 0))
        p["h_up." + sd] = ((0.45 * lunge - 0.3 * crouch, 0, 0), (0, 0, 0))
        p["h_lo." + sd] = ((0.3 * crouch, 0, 0), (0, 0, 0))
    tail_wave(p, 4, t, 12.0, 0.25)
    return p


def hurt(t):
    e = env(t / 0.55)
    p = idle(0.0)
    p["root"] = ((0, 0, 0), (0, 0, -0.18 * e))
    p["chest"] = ((-0.25 * e, 0, 0.1 * e), (0, 0, 0))
    p["neck"] = ((-0.4 * e, 0.2 * e, 0), (0, 0, 0))
    p["jaw"] = ((0.35 * e, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["ear." + sd] = ((0.6 * e, 0, 0), (0, 0, 0))
    tail_wave(p, 4, t, 8.0, 0.1, curl=0.4 * e)
    return p


def cast(t):
    e = env(t / 0.6)
    p = idle(0.0)
    # rear up and howl
    p["pelvis"] = ((-0.3 * e, 0, 0), (0, 0.05 * e, 0))
    p["neck"] = ((-0.6 * e, 0, 0), (0, 0, 0))
    p["head"] = ((-0.35 * e, 0, 0), (0, 0, 0))
    p["jaw"] = ((0.7 * e, 0, 0), (0, 0, 0))
    for sd in ("L", "R"):
        p["f_up." + sd] = ((-0.6 * e, 0, 0), (0, 0, 0))
        p["f_lo." + sd] = ((0.9 * e, 0, 0), (0, 0, 0))
        p["h_up." + sd] = ((0.3 * e, 0, 0), (0, 0, 0))
    tail_wave(p, 4, t, 9.0, 0.3, curl=0.3)
    return p


print("[art] beast: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/beast.glb", {"idle": (T_IDLE, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
