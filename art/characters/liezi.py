"""Liezi, Master Lie Yukou (Part XXII): who rode the wind for fifteen days and came back, and still leaned on something:
a thin man in pale robes with sleeves made for air.
Run: blender --background --python art/characters/liezi.py  ->  assets/characters/liezi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/liezi.glb", {"fem": False, "age": 0.55, "build": 0.85, "jaw": 0.92, "brow": 0.95, "stern": False, "smile": True, "skin": "e8d4c0",
    "robe": "c8d4e0", "trim": "8aa0b8", "inner": "f4f6fa", "sash": "6a88a8", "pants": "a8b4c4", "boots": "5a6878", "hair": "b8b8c0", "hair_style": "topknot", "eyes": "4a5a6a",
    "beard": True, "beard_len": 0.35, "beard_col": "c0c0c8", "sleeve_w": 1.7, "cape": "a8bcd0"})
