"""Ah Fu, the Ship's Boy Who Never Grew Up (Part XII): a cabin boy of Xu Fu's fleet who took a bite of the green fruit two thousand years ago and has been ten ever since; pale, in a short sailor's jacket.
Run: blender --background --python art/characters/ship_boy_ah_fu.py  ->  assets/characters/ship_boy_ah_fu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ship_boy_ah_fu.glb", {
    "age": 0.0, "build": 0.8, "eye_size": 1.45, "scale": 0.7, "head_scale": 1.2, "jaw": 0.85, "skin": "d6dee4", "glow_eyes": True,
    "props": [("lantern", {"col": "c8d8e8", "frame": "3a3a44", "glow": "d8f4ff"})], "pose": "hold_l", "robe_len": "short",
    "robe": "5a6a7a", "trim": "d8dce0", "inner": "eef0f2", "sash": "3a2a2a", "hair": "2a2a30", "hair_style": "short", "eyes": "a8e0ff", "pants": "3a4048"
})
