"""Frost Maiden (new in Part XVII): Qing Nu, the Maiden of Frost, who combs the frost out of her long
white hair over the land a night at a time, from autumn until spring sends her home.  Built from the
character library with the anime re-sculpt (fem, young, tall and slender): long white hair falling
to the knee, pale glowing eyes, a crown of ice crystals, a comb of ice in her hand, a long robe of
frost-white layered over pale blue with a train that drags behind her, and wide snow-white sleeves.
Cloth is tinted per enemy; skin, ice and hair keep their colours.
Run: blender --background --python art/monsters/frost_maiden.py  ->  assets/monsters/frost_maiden.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import person  # noqa: E402
from creature import person_die  # noqa: E402
from kit import CRYSTAL, MAT_GLOW, V  # noqa: E402

kit.reset()
creature.realtime()


def frost(b, rig, o, tor):
    """A crown of ice crystals round the head and a comb of ice in the left hand."""
    top = 1.9
    for k in range(9):
        a = (k / 8 - 0.5) * 2.6
        h = 0.09 + 0.06 * math.cos((k / 8 - 0.5) * math.pi) ** 2
        c = V(math.sin(a) * 0.1, top - 0.05, math.cos(a) * 0.09 - 0.01)
        b.crystal(c, 0.016, h, "d8f0ff", cls=CRYSTAL, bone="head", rot=(-0.25 * math.cos(a), 0, 0.3 * math.sin(a)))
    b.ball(V(0, top - 0.02, 0.1), 0.014, "aef0ff", cls=CRYSTAL, bone="head", mat=MAT_GLOW, seg=8, rings=6)
    hand = V(0.232, 0.84, 0.05)
    b.superquad(hand + V(0.0, -0.02, 0.03), (0.05, 0.016, 0.006), "c8ecff", e=0.3, cls=CRYSTAL, bone="hand.L", seg=10, rings=5)
    for k in range(7):
        x = (k / 6 - 0.5) * 0.09
        b.cone(hand + V(x, -0.05, 0.03), 0.004, 0.05, "e8f8ff", cls=CRYSTAL, bone="hand.L", rot=(math.pi, 0, 0), seg=4)


person.export_person("monsters/frost_maiden.glb", {
    # face and build: the loneliest of the immortals, young and very still
    "fem": True, "age": 0.0, "build": 0.92, "eye_size": 1.36, "lip": "b8c8e0", "glow_eyes": True, "smile": False,
    "robe": "e8eef8", "trim": "ffffff", "inner": "f6faff", "sash": "a8c0e0", "pants": "c8d8f0", "boots": "d8e4f4", "sleeve": "f0f4fc",
    "hair": "eef4ff", "hair_style": "long", "hair_len": 0.92, "eyes": "8ad8ff", "skin": "f4ecf0",
    "brocade": "cloud", "brocade_col": "ffffff", "embroidery": "c8e8ff", "collar2": "b8d0f0", "flare": 1.35,
    "extra": frost, "tint_cloth": True, "scale": 1.15,
}, clips=dict(person.CLIPS, die=(1.2, person_die(person.clip_idle))))
