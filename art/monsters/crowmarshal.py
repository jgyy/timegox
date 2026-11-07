"""Crow marshal (new in Part VIII): the Crow Marshal of the Broken Bridge and the black-feathered
officers of the fallen Court.  Black lacquered lamellar armour, a lacquered crow mask with a long
hooked beak and red-glass eyes, a cloak of crow feathers and a halberd across the way.
Cloth is tinted per enemy; the mask, feathers and steel keep their own colours.
Run: blender --background --python art/monsters/crowmarshal.py  ->  assets/monsters/crowmarshal.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import accessory as acc  # noqa: E402
import face as facelib  # noqa: E402
import garment as G  # noqa: E402
import person  # noqa: E402

kit.reset()


def crow(b, rig, o, tor):
    G.crow_mask(b, facelib.HC)
    acc.feather_cloak(b, col="14141c", white="2a2a34", sheen="3a3a6a")


person.export_person("monsters/crowmarshal.glb", {
    "fem": False, "age": 0.3, "build": 1.1, "stern": True, "smile": False, "halberd": True, "armor": True, "metal": "2a2a32",
    "bracers": "1a1a20", "extra": crow, "claws": True, "claw_col": "1a1a1a",
    "robe": "b0b0b0", "trim": "d8d8d8", "inner": "8a8a8a", "sash": "4a4a4a", "pants": "4a4a4a", "boots": "1a1a1a", "sleeve": "a0a0a0",
    "hair": "0a0a10", "hair_style": "wild", "eyes": "c02020", "embroidery": "8a8a9a", "tint_cloth": True, "scale": 1.3,
})
