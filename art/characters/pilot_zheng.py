"""Old Pilot Zheng (Part XII): sixty years a pilot inside the mirage, grey-bearded and weathered, a straw hat and an oar over his shoulder.
Run: blender --background --python art/characters/pilot_zheng.py  ->  assets/characters/pilot_zheng.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/pilot_zheng.glb", {
    "age": 0.85, "build": 0.95, "brow": 1.2, "beard": True, "beard_col": "c8c4bc", "beard_len": 0.85,
    "props": [("oar", {"col": "7a5a38"})], "pose": "hold_r", "hat": "straw", "hat_col": "c8a868", "robe_len": "short",
    "robe": "5a5a6a", "trim": "c8c0b0", "inner": "e8e4d8", "sash": "3a3a44", "hair": "c8c4bc", "hair_style": "topknot", "eyes": "3a3028", "pants": "4a4a54"
})
