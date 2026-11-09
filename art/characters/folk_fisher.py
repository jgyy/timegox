"""A fisherman of the towns (scripts/folk.gd): a wide straw hat, rolled sleeves and trousers and leg wraps; out on the shore before dawn, mending nets after noon.
Run: blender --background --python art/characters/folk_fisher.py  ->  assets/characters/folk_fisher.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_fisher.glb", {"age": 0.48, "build": 1.08, "cheek": 1.1, "beard": True, "beard_len": 0.2, "beard_col": "2a2420", "robe": "4a6a7a", "trim": "d4ccb4", "inner": "e4dcc8", "sash": "5a4a30", "hair": "1e1a16", "hair_style": "topknot", "eyes": "2a2014", "hat": "straw", "hat_col": "c8a858", "robe_len": "short", "wraps": "a89c80", "shoes": "sandals"})
