"""The Lord of the Eastern Peak (Part XXII): the mountain to which seventy-two kings came up to tell heaven that they had
succeeded, in the shape of the official who had to listen: stone-grey court robes, a flat crown, a beard like a waterfall.
Run: blender --background --python art/characters/dongyue.py  ->  assets/characters/dongyue.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/dongyue.glb", {"fem": False, "age": 0.75, "build": 1.18, "jaw": 1.1, "brow": 1.2, "stern": True, "smile": False, "skin": "c8bcb0", "scale": 1.16,
    "robe": "5a5a66", "trim": "d8c080", "inner": "d8d4cc", "sash": "d8c080", "pants": "3a3a44", "boots": "2a2a30", "hair": "d8d8dc", "hair_style": "topknot", "eyes": "6a6a5a",
    "beard": True, "beard_len": 0.6, "beard_col": "e0e0e4", "crown": True, "cape": "3a3a44", "brocade": "cloud", "brocade_col": "8a8a96", "sleeve_w": 1.6})
