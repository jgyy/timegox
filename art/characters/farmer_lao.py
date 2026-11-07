"""Farmer Lao of Qingshi Village (towns): a weathered man in a straw hat and rolled trousers with a hoe on his shoulder.
Run: blender --background --python art/characters/farmer_lao.py  ->  assets/characters/farmer_lao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/farmer_lao.glb", {
    "age": 0.55, "build": 1.05, "cheek": 1.2, "beard": True, "beard_len": 0.3, "beard_col": "3a3028",
    "robe": "6a7a5a", "trim": "d8d0b8", "inner": "e8e0c8", "sash": "4a3a2a", "hair": "2a2420", "hair_style": "topknot",
    "eyes": "3a2a1a", "hat": "straw", "hat_col": "d0b060", "props": ["hoe"], "pose": "hold_r", "robe_len": "short", "wraps": "b8a888", "shoes": "sandals",
})
