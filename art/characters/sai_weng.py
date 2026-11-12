"""Sai Weng (Part XXIV): the old man of the frontier who lost his horse and asked how anybody knew it was not good fortune: a man of
seventy in a felt coat the colour of dry grass, a fur hat, a long white beard, and the face of somebody who is waiting to see.
Run: blender --background --python art/characters/sai_weng.py  ->  assets/characters/sai_weng.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/sai_weng.glb", {"fem": False, "age": 0.95, "build": 0.9, "jaw": 0.95, "brow": 1.1, "smile": True, "skin": "c8a888",
    "robe": "8a7a5a", "trim": "5a4630", "inner": "d8d0bc", "sash": "7a3a2a", "pants": "4a4034", "boots": "3a2c22", "hair": "e8e4dc", "hair_style": "bun", "eyes": "3a3028",
    "beard": True, "beard_len": 0.5, "beard_col": "ece8e0", "hat": "fur", "sleeve_w": 1.05, "staff": True, "staff_gem": "c8b080"})
