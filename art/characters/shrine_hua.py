"""Shrine-Maiden Hua of the River Temple at Longmen: a young temple maiden in white and red with a bowl of dumplings for the river god.
Run: blender --background --python art/characters/shrine_hua.py  ->  assets/characters/shrine_hua.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/shrine_hua.glb", {
    "fem": True, "age": 0.2, "build": 0.9, "eye_size": 1.25,
    "robe": "f0ece4", "trim": "c83a2a", "inner": "fafaf6", "sash": "c83a2a", "hair": "1a1418", "hair_style": "long", "pin": "e0b040",
    "eyes": "3a2a2a", "props": [("bowl", {"col": "e8e0d0", "soup": "f0e8d0"})], "pose": "hold_both", "ribbon": "c83a2a",
})
