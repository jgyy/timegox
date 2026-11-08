"""Farida the Star-Glass Blower (towns): a glass-blower of Shazhou whose grandmother came with a caravan from beyond the western desert; a blue head-scarf, a long coat and a bulb of star-glass.
Run: blender --background --python art/characters/farida.py  ->  assets/characters/farida.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/farida.glb", {
    "fem": True, "age": 0.35, "eye_size": 1.2, "jaw": 0.9, "build": 0.96, "skin": "c8986a",
    "props": [("pearl", {"col": "9ad8ff"})], "pose": "hold_l", "hat": "hood", "hat_col": "3a8ab0",
    "robe": "3a8ab0", "trim": "f0d070", "inner": "f4ecd8", "sash": "c8502a", "hair": "1a1210", "hair_style": "long", "eyes": "3a2a1a", "embroidery": "f0d070"
})
