"""Egg-Warden Luan of Featherfall (Part XI): the Yumin woman who keeps the clutch-house warm, where
the eggs of the Feathered Folk lie a hundred years before they hatch.  Dove-grey wings and crest,
soft robes of dove grey and rose, and a great white egg cradled in her hand (held where the dragon
pearl floats, accessory.pearl), warm with her qi.
Run: blender --background --python art/characters/egg_warden_luan.py  ->  assets/characters/egg_warden_luan.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402  (first: it loads bpy, which provides mathutils)
import accessory as acc  # noqa: E402
import person  # noqa: E402
from kit import V  # noqa: E402

kit.reset()


def egg(b, rig, o, tor):
    """The pearl of accessory.pearl grown into an egg: an egg-shaped shell resting on the palm with
    a few pale speckles, and a faint warm ring of qi round it."""
    c = acc.held_l() + V(0.0, 0.1, 0.05)
    shell = [(0.0001, -0.07), (0.035, -0.062), (0.052, -0.035), (0.056, 0.0), (0.05, 0.035), (0.034, 0.064), (0.0001, 0.082)]
    b.lathe(c, shell, "f6f2ea", cls=kit.STONE, bone="hand.L", seg=18, col_top="fffdf8", cols=None)
    for k in range(7):
        a = k * 2.4
        q = c + V(math.cos(a) * 0.05, -0.02 + 0.012 * (k % 3), math.sin(a) * 0.05)
        b.ellipsoid(q, (0.006, 0.004, 0.006), "e0d4c0", cls=kit.STONE, bone="hand.L", seg=6, rings=4, mat=kit.MAT_PLAIN)
    ring = [c + V(math.cos(a) * 0.085, 0.006 * math.sin(a * 2), math.sin(a) * 0.085) for a in [i / 18 * 2 * math.pi for i in range(19)]]
    b.tube(ring, [0.0035] * 19, "ffe2a8", cls=kit.CRYSTAL, bone="hand.L", seg=4, mat=kit.MAT_GLOW, cap0=False, cap1=False)


person.export_person("characters/egg_warden_luan.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.25, "eye_size": 1.24, "jaw": 0.9, "lip": "d08088",
    # race (art/lib/race.py): a dove's wings and crest
    "wings": "aaa8b2", "wing_tip": "e8e6ee", "crest": "b6b4be", "crest_tip": "eae8f0", "crest_len": 0.22, "crest_n": 4,
    # the egg rests in her raised left hand (person.POSES)
    "pose": "hold_l", "extra": egg,
    "robe": "8a8098", "trim": "e8d0d4", "inner": "f6f0f2", "sash": "c88a94", "collar2": "d0a8b0",
    "hair": "2a2628", "hair_style": "bun", "pin": "c88a94", "eyes": "6a5a7a",
})
