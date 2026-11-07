"""Little Bai, the new sweeper of the sect's steps (towns): a skinny boy with a big broom, wearing the same plain grey Lin Feng wore.
Run: blender --background --python art/characters/sweeper_bai.py  ->  assets/characters/sweeper_bai.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/sweeper_bai.glb", {
    "age": 0.0, "build": 0.86, "jaw": 0.9, "eye_size": 1.3, "scale": 0.9,
    "robe": "8a8a90", "trim": "d8d8dc", "inner": "eceae6", "sash": "5a5a64", "hair": "1a1a20", "hair_style": "short",
    "eyes": "3a3a44", "props": ["broom"], "pose": "hold_r", "robe_len": "short", "wraps": "c8c4b8", "shoes": "sandals",
})
