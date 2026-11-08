"""Innkeeper Lou of the Inn of the Late Arrival at Tushan: a brisk woman with a teapot, whose inn is named for the giant Fangfeng.
Run: blender --background --python art/characters/innkeeper_lou.py  ->  assets/characters/innkeeper_lou.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/innkeeper_lou.glb", {
    "fem": True, "age": 0.45, "build": 1.05, "cheek": 1.15, "eye_size": 1.1,
    "robe": "a86a5a", "trim": "f0e0c8", "inner": "f4ece0", "sash": "4a6a8a", "hair": "2a1a14", "hair_style": "bun", "pin": "c8a040",
    "eyes": "4a2a1a", "props": ["teapot"], "pose": "hold_both",
})
