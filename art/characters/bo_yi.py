"""Bo Yi of the Dykes: Yu the Great's old helper, four thousand years old, in a straw hat with the hoe he dug the first channels with.
Run: blender --background --python art/characters/bo_yi.py  ->  assets/characters/bo_yi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/bo_yi.glb", {
    "age": 1.0, "build": 0.9, "brow": 1.2, "eye_size": 0.95, "beard": True, "beard_len": 1.0, "beard_col": "e8e6e0",
    "robe": "6a7a5a", "trim": "c8b890", "inner": "e0dccc", "sash": "4a3a2a", "hair": "e8e4e0", "hair_style": "topknot",
    "eyes": "3a3a2a", "hat": "straw", "hat_col": "b8a060", "props": ["hoe"], "pose": "hold_r", "robe_len": "short", "wraps": "a89870", "shoes": "sandals", "scale": 0.95,
})
