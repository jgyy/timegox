"""Stable-boy Shitou of the Cloudfoot post stables: a small boy in a straw hat with a stable broom taller than he is, whose name means stone.
Run: blender --background --python art/characters/stableboy_shitou.py  ->  assets/characters/stableboy_shitou.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/stableboy_shitou.glb", {
    "age": 0.0, "build": 0.82, "eye_size": 1.4, "scale": 0.72, "head_scale": 1.18, "jaw": 0.85,
    "robe": "8a6a4a", "trim": "e8d8b8", "inner": "f0e8d8", "sash": "3a5a3a", "hair": "1a1410", "hair_style": "topknot",
    "eyes": "3a2414", "hat": "straw", "hat_col": "d0b060", "props": ["broom"], "pose": "hold_r", "robe_len": "short", "pants": "4a3a2a",
})
