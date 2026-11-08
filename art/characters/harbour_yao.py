"""Harbourmistress Jiang Yao of Longmen: a weathered ferry-town harbourmaster in river blue with a ferry oar and a straw hat, who measures the river every hour on the flood stele.
Run: blender --background --python art/characters/harbour_yao.py  ->  assets/characters/harbour_yao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/harbour_yao.glb", {
    "fem": True, "age": 0.5, "build": 1.05, "brow": 1.1, "eye_size": 1.05, "stern": True,
    "robe": "2e5a7a", "trim": "e8d8b0", "inner": "f0eadc", "sash": "c8a040", "hair": "1a1418", "hair_style": "bun", "pin": "6a9ab0",
    "eyes": "2a3a4a", "hat": "straw", "hat_col": "c8a858", "props": ["oar"], "pose": "hold_r", "bracers": "4a3a2a", "robe_len": "short", "pants": "2a3a4a",
})
