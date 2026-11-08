"""Mist-Fisher Lao Wu (Part XII): a fisherman of Landfall who fishes the mists of Yingzhou for thoughts, in a straw rain-cape with a rod over his shoulder.
Run: blender --background --python art/characters/mist_fisher.py  ->  assets/characters/mist_fisher.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/mist_fisher.glb", {
    "age": 0.6, "build": 0.98, "brow": 1.15, "beard": True, "beard_col": "3a3430", "beard_len": 0.5,
    "props": [("fishing_rod", {"col": "a08a50"}), ("straw_cape", {"col": "b8a060"})], "pose": "hold_r", "hat": "straw", "hat_col": "c8a868", "robe_len": "short",
    "robe": "6a7a8a", "trim": "d8d0c0", "inner": "ece8e0", "sash": "3a3a44", "hair": "2a2622", "hair_style": "topknot", "eyes": "2a2620", "pants": "4a5a6a"
})
