"""Old Farmer Tian of the Scorched Millet Plains (Part IX): a millet farmer of sixty harvests who prays
every morning to Hou Ji, Lord of Millet.  Sun-browned and wiry, a faded hemp work robe tucked up
over leg wraps and straw sandals, a broad straw hat, a white beard, a hoe on his shoulder, a water
gourd at his hip and a sheaf of withered millet tied to his belt.
Run: blender --background --python art/characters/farmer_tian.py  ->  assets/characters/farmer_tian.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402
from kit import V  # noqa: E402

kit.reset()


def millet_sheaf(b, rig, o, tor):
    """A small sheaf of withered millet tied at the left hip: drooping heads on dry stalks, bound
    with a twist of red cord (the last of last year's seed, kept for luck)."""
    bone = {"hips": 0.5, "robe_l": 0.5}
    tie = V(0.21, 0.9, 0.08)
    for k in range(7):
        a = (k / 6 - 0.5) * 0.9
        base = tie + V(0.01 * math.sin(k * 2.1), -0.16, 0.0)
        top = tie + V(0.05 * math.sin(a), 0.22, 0.04 * math.cos(a * 2.0))
        b.tube([base, tie, top], [0.004, 0.004, 0.003], "b89a58", cls=kit.WOOD, bone=bone, seg=4)
        head = top + V(0.06 * math.sin(a) + 0.03, -0.07, 0.03)
        b.tube([top, top + V(0.03 * math.sin(a) + 0.02, 0.02, 0.02), head], [0.012, 0.016, 0.006], "c8a040", cls=kit.FOLIAGE, bone=bone, seg=6)
    b.tube([tie + V(-0.02, 0, 0.0), tie + V(0.02, 0, 0.0)], [0.016, 0.016], "c02a20", cls=kit.CLOTH, bone=bone, seg=8)


person.export_person("characters/farmer_tian.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.85, "build": 0.92, "brow": 1.15, "cheek": 0.95, "skin": "c8946c", "beard_len": 0.75,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("hoe", {"col": "8a6a40", "blade": "5a5a62"}), ("gourd", {"col": "c89a48", "side": 1})], "pose": "hold_r",
    "extra": millet_sheaf, "staff": False,
    "robe": "8a7a58", "trim": "c8b890", "inner": "e8dcc0", "sash": "5a4a30", "hair": "c8c4c0", "hair_style": "bun",
    "eyes": "4a3a2a", "beard": True, "beard_col": "e0dcd8", "hat": "straw", "hat_col": "c8a868", "embroidery": "c8b890",
    "pants": "5a4a30", "boots": "4a3a2a", "robe_len": "short", "wraps": "d8ccb0", "shoes": "sandals", "collar2": "6a5a3a",
})
