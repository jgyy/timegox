"""Caravan-Master Kang of the Four Roads: a broad Sogdian trader in a fur hat with a camel whip, who has walked silk west and jade east for thirty years.
Run: blender --background --python art/characters/caravan_kang.py  ->  assets/characters/caravan_kang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/caravan_kang.glb", {
    "age": 0.5, "build": 1.2, "jaw": 1.15, "brow": 1.2, "beard": True, "beard_len": 0.7, "beard_col": "4a2a1a",
    "robe": "a86a3a", "trim": "e8c890", "inner": "f0e0c0", "sash": "6a2a2a", "hair": "3a2014", "hair_style": "wild",
    "eyes": "4a3a2a", "hat": "fur", "hat_col": "6a4a30", "props": ["whip"], "embroidery": "e0b050", "boots": "4a3020", "robe_len": "short", "pants": "5a3a2a",
})
