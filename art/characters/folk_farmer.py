"""A farmer of the towns (the Living Land release, scripts/folk.gd): a weathered man in a straw hat, rolled trousers and sandals; the game puts a hoe or a basket in his hands and dyes his clothes, so one model is a whole village of farmers.
Run: blender --background --python art/characters/folk_farmer.py  ->  assets/characters/folk_farmer.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_farmer.glb", {"age": 0.4, "build": 1.1, "cheek": 1.1, "jaw": 1.05, "robe": "6a7a52", "trim": "d8d0b4", "inner": "e8e0c8", "sash": "4a3a2a", "hair": "241e18", "hair_style": "topknot", "eyes": "3a2a1a", "hat": "straw", "hat_col": "d0b060", "robe_len": "short", "wraps": "b8a888", "shoes": "sandals"})
