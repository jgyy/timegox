"""Elder Bu Si of the Deathless (Part XI): eldest of the people who live under the roots of the world
tree, eat of its fruit and drink of its spring, and do not die.  Very old and still quite upright,
deep brown-black skin, white hair and a long white beard, robes of ochre and leaf green, and a
staff of living root-wood that still puts out leaves.
Run: blender --background --python art/characters/bu_si.py  ->  assets/characters/bu_si.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402  (first: it loads bpy, which provides mathutils)
import accessory as acc  # noqa: E402
import person  # noqa: E402
from kit import V  # noqa: E402
from sculpt import strand  # noqa: E402

kit.reset()
WOOD, DARK, LEAF = "6a4a2e", "48321e", "5a9a3a"


def root_staff(b, rig, o, tor):
    """A staff of living root-wood in the right hand: three roots twisted together, splaying at the
    head into a knot of rootlets, with a few new leaves."""
    h = acc.HAND_R + V(0.004, 0.0, 0.0)
    for k in range(3):
        pts = []
        cols = []
        for j in range(17):
            t = j / 16
            a = t * 4.5 * math.pi + k * 2.0 * math.pi / 3
            r = 0.012 * (1.0 - 0.25 * t)
            pts.append(h + V(math.cos(a) * r, -0.8 + 1.4 * t, math.sin(a) * r))
            cols.append(WOOD if (j + k) % 3 else DARK)
        b.tube(pts, [0.0115 - 0.003 * (j / 16) for j in range(17)], WOOD, cls=kit.WOOD, bone="hand.R", seg=6, cols=cols)
    top = h + V(0.0, 0.6, 0.0)
    b.ellipsoid(top, (0.03, 0.036, 0.03), DARK, cls=kit.WOOD, bone="hand.R", seg=10, rings=6)
    for k in range(6):
        a = k / 6 * 2.0 * math.pi + 0.3
        out = V(math.cos(a), 0.0, math.sin(a))
        strand(b, [top + out * 0.02 + V(0, 0.02, 0), top + out * 0.06 + V(0, 0.065, 0), top + out * 0.095 + V(0, 0.035, 0), top + out * 0.105 + V(0, -0.03, 0)],
               0.0085, 0.0015, WOOD, cls=kit.WOOD, bone="hand.R", seg=5, per=3)
    for k, (dy, a) in enumerate(((0.3, 0.4), (0.48, 2.6), (0.62, 4.2), (0.7, 1.2), (0.78, 5.4), (0.86, 3.1))):
        q = h + V(math.cos(a) * 0.014, -0.8 + 1.4 * dy, math.sin(a) * 0.014)
        out = V(math.cos(a), 0.45, math.sin(a))
        b.leaf(q, q + out * 0.075, 0.026, LEAF, cls=kit.FOLIAGE, bone="hand.R", col_tip="a8e070")


person.export_person("characters/bu_si.glb", {
    # face and build (see art/lib/face.py, garment.py); old in the face but not stooped (age 0.5)
    "fem": False, "age": 0.5, "brow": 1.2, "build": 1.0, "skin": "4a3428",
    "beard": True, "beard_col": "f2f0ea", "beard_len": 1.3,
    # his root-wood staff
    "extra": root_staff,
    "robe": "a8782a", "trim": "e8d8a8", "inner": "f2ead4", "sash": "4e8a3a", "pants": "5a4a2a", "collar2": "6a9a48",
    "hair": "f2f0ea", "hair_style": "bun", "pin": "6a9a48", "eyes": "4a3020", "embroidery": "d8c070",
})
