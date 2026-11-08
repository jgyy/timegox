"""Tofu Seller Sun (towns): a stall keeper in an indigo apron carrying a tray of fresh tofu, the best gossip in the valley.
Run: blender --background --python art/characters/tofu_sun.py  ->  assets/characters/tofu_sun.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/tofu_sun.glb", {
    "age": 0.45, "build": 1.0, "cheek": 1.15, "smile": True,
    "robe": "3a4a7a", "trim": "e8e4d8", "inner": "f0ece0", "sash": "c8a050", "hair": "2a2420", "hair_style": "topknot",
    "eyes": "3a2a1a", "hat": "scholar", "hat_col": "2a2a3a", "props": [("apron", {"col": "2a3a6a", "strap": "1a2440"}), ("bowl", {"col": "e8e4d8", "soup": "f8f6ec"})], "pose": "hold_both",
})
