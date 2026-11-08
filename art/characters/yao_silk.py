"""Silk-Diver Yao (towns): a Pearl-Weeper of Tearwater who dives in silk the water cannot wet; fin ears, scales on her cheeks and a shuttle of shining silk.
Run: blender --background --python art/characters/yao_silk.py  ->  assets/characters/yao_silk.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yao_silk.glb", {
    "fem": True, "age": 0.15, "eye_size": 1.3, "jaw": 0.86, "lip": "d88a90", "build": 0.94,
    "ears": "fin", "ear_col": "4ab0b0", "ear_inner": "e0faf6", "scales": "4aa8a8",
    "props": [("shuttle", {"col": "e8f4f8"})], "pose": "hold_l",
    "robe": "4ab0b0", "trim": "f4fbfa", "inner": "ffffff", "sash": "2a6a7a", "hair": "1a2a3a", "hair_style": "long", "eyes": "2a5a6a"
})
