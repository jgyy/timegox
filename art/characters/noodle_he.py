"""Granny He of the Noodle Stall (towns): Cloudfoot's noodle-seller, round and quick, in an apron, a ladle-bowl in her hands.
Run: blender --background --python art/characters/noodle_he.py  ->  assets/characters/noodle_he.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/noodle_he.glb", {
    "fem": True, "age": 0.85, "build": 1.08, "eye_size": 1.05, "jaw": 0.96, "smile": True,
    "props": [("apron", {"col": "e8e0d0", "strap": "8a6a4a"}), ("bowl", {"col": "e8e8e0", "soup": "d8a060"})], "pose": "hold_both",
    "robe": "a8503a", "trim": "f0e0c8", "inner": "f6eee0", "sash": "4a3a2a", "hair": "d8d4cc", "hair_style": "bun", "eyes": "2a2018"
})
