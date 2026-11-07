"""Feng Meng, the Last Apprentice (Part IX): Hou Yi's apprentice, the second-best archer under heaven,
who killed his master out of envy and has carried it for four thousand years.  A lean old archer
with a grey topknot and beard, a scar across his brow, an olive hunting robe tucked up over leg
wraps, leather bracers, a recurved horn bow in his left hand and a quiver of arrows on his back.
Run: blender --background --python art/characters/feng_meng.py  ->  assets/characters/feng_meng.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402
from kit import V  # noqa: E402

kit.reset()

# where the left hand hangs at rest (the bow rides the hand bone, so it follows every clip)
GRIP = V(0.274, 0.855, 0.05)


def _bow_limb(sign):
    """One limb of a Chinese horn bow from the grip: it bends back towards the archer, then the
    stiff ear (siyah) flicks forward again at the tip."""
    pts = []
    for i in range(9):
        t = i / 8
        y = 0.05 + 0.6 * t
        z = -0.1 * math.sin(t * math.pi * 0.85) + (0.09 * (t - 0.75) / 0.25 if t > 0.75 else 0.0)
        pts.append(GRIP + V(0.0, y * sign, z))
    return pts


def bow_and_quiver(b, rig, o, tor):
    hb = "hand.L"
    horn, wrap, string = "4a3020", "c8a060", "e8e0c8"
    # grip, wrapped in cord
    b.tube([GRIP + V(0, -0.06, 0), GRIP + V(0, 0.06, 0)], [0.017, 0.017], wrap, cls=kit.CLOTH, bone=hb, seg=8)
    tips = []
    for sign in (1, -1):
        limb = _bow_limb(sign)
        radii = [0.014 - 0.009 * (i / 8) for i in range(9)]
        b.tube(limb, radii, horn, cls=kit.WOOD, bone=hb, seg=7, cols=[horn if i % 3 else "8a6a40" for i in range(9)])
        # bone nock at the tip
        b.ball(limb[-1], 0.009, "e8dcc0", cls=kit.STONE, bone=hb, seg=6, rings=4)
        tips.append(limb[-1])
    # the string runs straight from nock to nock, behind the belly of the bow
    b.tube([tips[0], tips[1]], [0.0022, 0.0022], string, cls=kit.HAIR, bone=hb, seg=3, mat=kit.MAT_PLAIN)
    # a red tassel on the upper limb
    b.tube([tips[0] + V(0, -0.1, -0.02), tips[0] + V(0, -0.2, -0.03)], [0.008, 0.003], "c02a20", cls=kit.CLOTH, bone=hb, seg=5)
    # quiver across the back, from the right hip up over the left shoulder, full of fletched arrows
    qb = {"chest": 0.6, "spine": 0.4}
    q0 = V(-0.12, 0.98, -0.2)
    q1 = V(0.1, 1.5, -0.2)
    b.tube([q0, q0.lerp(q1, 0.5) + V(0, 0, -0.015), q1], [0.05, 0.055, 0.052], "6a4a2a", cls=kit.CLOTH, bone=qb, seg=12, cols=["6a4a2a", "7a5a34", "6a4a2a"])
    for t in (0.15, 0.85):
        q = q0.lerp(q1, t)
        b.tube([q + (q1 - q0).normalized() * 0.008, q - (q1 - q0).normalized() * 0.008], [0.058, 0.058], "c8a060", cls=kit.METAL, bone=qb, seg=12, cap0=False, cap1=False)
    b.tube([V(0.17, 1.42, 0.05), V(0.05, 1.32, 0.17), V(-0.12, 1.08, 0.12), V(-0.13, 1.0, -0.08)], [0.008] * 4, "4a3020", cls=kit.CLOTH, bone=qb, seg=5)
    d = (q1 - q0).normalized()
    for k in range(7):
        a = k / 7 * 2 * math.pi
        root = q1 + V(math.cos(a) * 0.03, 0.0, math.sin(a) * 0.03)
        tip = root + d * (0.12 + 0.02 * (k % 3))
        b.tube([root - d * 0.05, tip], [0.004, 0.004], "c8b090", cls=kit.WOOD, bone=qb, seg=4)
        for f in range(3):
            fa = a + f * 2.1
            side = V(math.cos(fa), 0.0, math.sin(fa))
            b.leaf(tip - d * 0.06, tip - d * 0.005 + side * 0.012, 0.012, "f0ece0" if k % 2 else "c02a20", side=side, cls=kit.HAIR, bone=qb, curl=0.05, n=3)


person.export_person("characters/feng_meng.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.75, "build": 0.98, "brow": 1.35, "jaw": 1.05, "stern": True, "marks": "scar", "beard_len": 0.8,
    # signature props: a bow and quiver of his own (built below), bracers for the string arm
    "extra": bow_and_quiver, "bracers": "6a4a2a", "staff": False,
    "robe": "5a5a3a", "trim": "a89868", "inner": "e0d8c0", "sash": "3a2a1a", "hair": "b8b4b0", "hair_style": "topknot",
    "eyes": "3a3a2a", "beard": True, "beard_col": "c8c4c0", "embroidery": "a89868", "collar2": "4a4a2a",
    "pants": "4a4030", "boots": "2a2018", "robe_len": "short", "wraps": "c8bca0",
})
