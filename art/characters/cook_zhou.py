"""Auntie Zhou, cook of the sect's kitchen (towns): a round, brisk woman in an apron with a ladle-bowl and her sleeves bound up.
Run: blender --background --python art/characters/cook_zhou.py  ->  assets/characters/cook_zhou.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/cook_zhou.glb", {
    "fem": True, "age": 0.6, "build": 1.18, "eye_size": 1.12, "cheek": 1.3,
    "robe": "a85a3a", "trim": "f0e4d0", "inner": "f4ece0", "sash": "6a3a2a", "hair": "3a2a24", "hair_style": "bun", "pin": "c8a040",
    "eyes": "4a3020", "props": [("apron", {"col": "f0ece0", "strap": "8a7a60"}), "bowl"], "pose": "hold_both", "sleeve_w": 0.8,
})
