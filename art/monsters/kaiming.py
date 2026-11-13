"""Kaiming (new in Part VIII): Kaiming, Beast of the Nine Gates, who guards the gates of Kunlun.  The
Classic of Mountains and Seas (Hainei Xijing): "its body is large, like a tiger's, and it has nine
heads, all with human faces; it stands on Kunlun facing east" - and each of Kunlun's nine gates is
kept by a Kaiming beast.  (The same book gives Tianwu, the god of the waters, eight human-faced
heads on a tiger's body.)  An Eastern Han relief in the Shandong Museum shows a beast crowned with
human heads; modern renderings take the faces from the terracotta warriors.

Nine faces on one beast read best in a form the eye already knows: the crowned guardian.  So the
great cat of art/lib/feline.py (sculpted in clay, its stripes painted into the greys) carries,
instead of a cat's head, one stern human face like a sphinx's - a heavy brow, a drooping
moustache, a beard, the hair drawn up into a topknot - and on its head a gilded crown of eight
petal-shaped plaques, each bearing a smaller face turned to watch one of the gates (the way a
bodhisattva's crown carries its little figures).  A lion's mane flows back from round the face
over the neck and shoulders; gilded plates guard the shoulders.  The coat and mane take the
enemy's colour; the faces, hair and gold keep theirs.
Clips: the tiger's idle, walk, attack (a pounce), hurt, die and roar (cast).
Run: blender --background --python art/monsters/kaiming.py  ->  assets/monsters/kaiming.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
import feline  # noqa: E402
from clay import Clay  # noqa: E402
from kit import CLOTH, METAL, V  # noqa: E402
from mammal import human_head, mask_face  # noqa: E402
from sculpt import smooth  # noqa: E402

kit.reset()
creature.realtime()

b, r, hf, clips = feline.build("kaiming", res=0.0172, head=False)
# the face sits where the cat's head would be, looking ahead and a little down
C0 = V(0, 1.0, 0.8)
F0 = V(0, -0.1, 1.0).normalized()
SIDE = V(1, 0, 0)
UP0 = F0.cross(SIDE).normalized() * -1.0
if UP0.y < 0:
    UP0 = -UP0
KF = 1.3

# ---------------------------------------------------------------- a lion's mane flowing back from round the face
mane = Clay(0.022, "kaiming_mane")
for row in range(2):
    n_t = 11
    for i in range(n_t):
        a = (i / (n_t - 1) - 0.5) * (4.6 - 0.4 * row)
        out = (SIDE * math.sin(a) + UP0 * math.cos(a)).normalized()
        down = smooth(0.0, -1.0, math.cos(a))
        root = C0 - F0 * (0.1 + 0.11 * row) + out * (0.085 + 0.015 * row) + V(0, -0.03, 0)
        d = (out * 0.5 - F0 * 0.8 + V(0, -0.3 - 0.4 * down, 0)).normalized()
        ln = 0.17 + 0.04 * row + 0.05 * down
        wd = 0.058 + 0.006 * row
        bw = {"neck1": 0.5, "head": 0.5} if row == 0 else {"neck1": 0.4, "neck0": 0.6}
        mane.chain([root, root + d * ln * 0.5, root + d * ln], [wd, wd * 0.85, wd * 0.42], bones=bw, tag="mane", t0=0.0, t1=1.0)


def mane_col(p, info):
    # a darker mane, its ends a little paler
    v = 0.56 + 0.16 * smooth(0.4, 1.0, info.t)
    return (v, v, v)


mane.build(b, mane_col, cls=CLOTH, tint_fn=lambda p, info: 1.0)

# ---------------------------------------------------------------- the face and the crown of eight faces
at = human_head(b, C0, F0, KF, "head", res=0.0098, beard=0.15, knot=(0.0, 0.4), brow_tilt=0.6, name="kaiming_face", jaw_bone="jaw",
                skin=(0.84, 0.64, 0.5))
GOLD = "e0b040"
# the band of the crown round the brow
ring = [at(math.sin(t) * 0.086, 0.06 + 0.006 * math.cos(t), math.cos(t) * 0.088 - 0.012) for t in [i / 24 * 2 * math.pi for i in range(25)]]
b.tube(ring, [0.009 * KF] * 25, GOLD, cls=METAL, bone="head", seg=6, cap0=False, cap1=False)
# a five-leaf crown in front (the crown of the five buddhas) and three smaller leaves behind:
# eight faces, each turned out to its gate
LEAVES = [(-1.0, 1.0), (-0.5, 1.0), (0.0, 1.1), (0.5, 1.0), (1.0, 1.0), (math.pi - 0.75, 0.78), (math.pi, 0.82), (math.pi + 0.75, 0.78)]
for i, (t, big) in enumerate(LEAVES):
    out = (SIDE * math.sin(t) + F0 * math.cos(t)).normalized()
    base = at(math.sin(t) * 0.087, 0.062, math.cos(t) * 0.089 - 0.012)
    lean = (UP0 * 0.95 + out * 0.3).normalized()
    tip = base + lean * 0.17 * KF * big
    # the leaf: a pointed petal of gold, its face looking out to its gate
    A.blade(b, base - lean * 0.012, tip, 0.075 * KF * big, GOLD, "f0d070", side=out.cross(lean).normalized(), bone="head", curl=-0.05, thick=0.14,
            tint=0.0, cls=METAL, point=0.7)
    fc = base.lerp(tip, 0.45) + out * 0.012 * KF
    mask_face(b, fc, (out + lean * 0.08).normalized(), 0.46 * KF * big, "head", up=lean, brow_tilt=0.3 + 0.3 * (i % 2), seg=18, rings=12)
    # a jewel at the foot of each leaf
    # (the jewels take the foe's accent: the one colour of a guardian of the gates that is its own)
    old_pal = b.cur_pal
    b.cur_pal = 1.0
    b.ball(base + out * 0.012, 0.01 * KF, "d03a2a" if i % 2 == 0 else "2a8a6a", cls=METAL, bone="head", seg=8, rings=6, tint=0.8)
    b.cur_pal = old_pal

# ---------------------------------------------------------------- gilded plates on the shoulders
for sd, s in (("L", 1), ("R", -1)):
    sc = r.bones["shoulder." + sd][0]
    for k in range(3):
        b.superquad(sc + V(0.06 * s, -0.04 - k * 0.07, 0.05 - k * 0.04), (0.075, 0.048, 0.014), GOLD, e=0.4, cls=METAL, bone="shoulder." + sd,
                    rot=(0, 1.3 * s, -0.4 * s), seg=8, rings=5)

print("[art] kaiming: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/kaiming.glb", clips, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
