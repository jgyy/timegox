"""Herb-Gardener Ruan (towns): the sect's eleventh herb-gardener, in a straw hat and green work-clothes with a hoe.
Run: blender --background --python art/characters/gardener_ruan.py  ->  assets/characters/gardener_ruan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/gardener_ruan.glb", {
    "age": 0.55, "build": 1.02, "brow": 1.1, "beard": True, "beard_col": "3a3028", "beard_len": 0.3,
    "props": [("hoe", {"col": "7a5a38", "blade": "6a6a70"})], "pose": "hold_r", "hat": "straw", "hat_col": "c8a868", "robe_len": "short",
    "robe": "5a8a4a", "trim": "e8e0c8", "inner": "f0ece0", "sash": "3a4a2a", "hair": "2a2420", "hair_style": "topknot", "eyes": "2a2018", "pants": "4a5a3a"
})
