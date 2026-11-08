"""Xia and Her Cormorant (towns): a young fisherwoman of Longmen with a cormorant on her arm and a straw hat on her back.
Run: blender --background --python art/characters/xia_cormorant.py  ->  assets/characters/xia_cormorant.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/xia_cormorant.glb", {
    "fem": True, "age": 0.15, "eye_size": 1.25, "jaw": 0.88, "build": 0.94,
    "props": [("cormorant", {"col": "1a1a20", "beak": "e0c040"})], "hat": "straw", "hat_col": "c8a868", "robe_len": "short",
    "robe": "4a6a7a", "trim": "f0e8d0", "inner": "f6f2e8", "sash": "c8803a", "hair": "141016", "hair_style": "braid", "eyes": "2a2018", "pants": "3a4a5a"
})
