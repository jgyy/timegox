"""Chan Master Zhichang of Guizong Temple (Part XXVII): whom a prefect asked how Mount Sumeru could be put into a
mustard seed, and who asked back where in a head the size of a coconut ten thousand scrolls had been put; a lean, upright
monk of seventy with a shaven head, in a patched grey robe under a brown kasaya, with a fly-whisk.
Run: blender --background --python art/characters/zhichang.py  ->  assets/characters/zhichang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zhichang.glb", {"fem": False, "age": 0.74, "build": 0.9, "jaw": 0.98, "brow": 1.2, "cheek": 1.1, "smile": True, "skin": "d0b08c",
    "robe": "7a7a78", "trim": "6a4a2a", "inner": "e4dccc", "sash": "6a4a2a", "pants": "5a5a58", "boots": "3a3028", "shoes": "sandals",
    "hair": "d8d4cc", "hair_style": "bald", "eyes": "2e2418",
    "props": ["fly_whisk"], "pose": "hold_r"})
