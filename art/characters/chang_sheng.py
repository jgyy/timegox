"""Grove-Keeper Chang Sheng of the Deathless (Part XI): she tends the orchard under the roots of the
world tree whose fruit is the reason her people do not die, and gives it to no one who asks for
it.  Deep brown-black skin, black hair coiled with a jade pin, leaf-green robes with a red sash,
and a basket on her arm heaped with the red fruit of the deathless trees.
Run: blender --background --python art/characters/chang_sheng.py  ->  assets/characters/chang_sheng.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402  (first: it loads bpy, which provides mathutils)
import accessory as acc  # noqa: E402
import person  # noqa: E402
from kit import V  # noqa: E402

kit.reset()
FRUIT = "c8362a"


def fruit(b, rig, o, tor):
    """Red fruit heaped in the basket (accessory.basket) on her left arm, each with a leaf."""
    c = acc.held_l() + V(0.04, -0.06, 0.02)
    spots = [(math.cos(a) * 0.05, 0.075, math.sin(a) * 0.05) for a in (0.3, 1.55, 2.8, 4.05, 5.3)] + [(0.0, 0.105, 0.0)]
    for k, (x, y, z) in enumerate(spots):
        q = c + V(x, y, z)
        b.ball(q, 0.03, FRUIT, cls=kit.SKIN, bone="hand.L", seg=12, rings=8, col2=kit.darken(FRUIT, 0.3))
        b.ball(q + V(-0.01, 0.014, 0.018), 0.008, "f08070", cls=kit.SKIN, bone="hand.L", seg=6, rings=4, mat=kit.MAT_PLAIN)
        b.leaf(q + V(0, 0.026, 0), q + V(0.02 * math.cos(k * 2.1), 0.05, 0.02 * math.sin(k * 2.1)), 0.012, "3a7a2a", cls=kit.FOLIAGE, bone="hand.L")


person.export_person("characters/chang_sheng.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.3, "eye_size": 1.24, "jaw": 0.9, "skin": "4e3628", "lip": "8a4a48",
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("basket", {"col": "b89a60", "fill": "4a8a3a"})], "pose": "hold_l", "extra": fruit,
    "robe": "4a8a3a", "trim": "e8dca8", "inner": "f4f0dc", "sash": "b83228", "collar2": "c8a040",
    "hair": "1a1210", "hair_style": "bun", "pin": "5ab08a", "eyes": "3a2a1a",
})
