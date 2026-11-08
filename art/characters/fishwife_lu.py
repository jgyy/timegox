"""Fishwife Lu of the Longmen fish market: loud, cheerful and red-cheeked, with a basket of golden carp that did not quite make it over the Dragon Gate.
Run: blender --background --python art/characters/fishwife_lu.py  ->  assets/characters/fishwife_lu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/fishwife_lu.glb", {
    "fem": True, "age": 0.55, "build": 1.2, "cheek": 1.3, "eye_size": 1.1, "smile": True,
    "robe": "c86a4a", "trim": "f0e0c8", "inner": "f4ece0", "sash": "3a6a8a", "hair": "2a1a14", "hair_style": "bun", "pin": "e0b040",
    "eyes": "4a2a1a", "props": [("apron", {"col": "e8e0d0", "strap": "8a6a50"}), ("basket", {"fill": "e8a830"})], "pose": "hold_l",
})
