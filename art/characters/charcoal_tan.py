"""Charcoal-Burner Ah Tan of Tushan: blackened to the elbows from the kilns, with a straw hat and a basket of charcoal for the casting pits.
Run: blender --background --python art/characters/charcoal_tan.py  ->  assets/characters/charcoal_tan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/charcoal_tan.glb", {
    "age": 0.4, "build": 1.1, "jaw": 1.05, "eye_size": 1.0, "smile": True,
    "robe": "3a3a3a", "trim": "8a7a60", "inner": "6a6458", "sash": "8a5a2a", "hair": "1a1410", "hair_style": "short",
    "eyes": "3a2414", "hat": "straw", "hat_col": "a89050", "props": [("basket", {"fill": "2a2622"})], "pose": "hold_l", "robe_len": "short", "wraps": "6a6050", "shoes": "sandals",
})
