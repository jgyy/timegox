"""Auntie Aysha, cook of the Shazhou caravanserai: a broad, laughing cook with a bowl of lamb noodles for every caravan that comes in off the sand.
Run: blender --background --python art/characters/cook_aysha.py  ->  assets/characters/cook_aysha.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/cook_aysha.glb", {
    "fem": True, "age": 0.55, "build": 1.2, "cheek": 1.25, "eye_size": 1.1, "smile": True,
    "robe": "a84a3a", "trim": "f0d8a0", "inner": "f4ece0", "sash": "e0a040", "hair": "2a1810", "hair_style": "braid",
    "eyes": "3a2414", "hat": "hood", "hat_col": "c8603a", "props": [("apron", {"col": "f0e8d8", "strap": "8a6a50"}), ("bowl", {"soup": "d8a060"})], "pose": "hold_both",
})
