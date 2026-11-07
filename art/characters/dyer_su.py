"""Dyer Su of the Dawn Market (Part IX): a dyer with indigo-stained sleeves bound up and a basket of skeins fading in the endless noon.
Run: blender --background --python art/characters/dyer_su.py  ->  assets/characters/dyer_su.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/dyer_su.glb", {
    "fem": True, "age": 0.3, "eye_size": 1.24, "build": 0.95,
    "robe": "3a4a8a", "trim": "e8e8f0", "inner": "f4f4f8", "sash": "c85a7a", "sleeve": "2a3a7a", "hair": "1a1420", "hair_style": "braid",
    "eyes": "3a3a5a", "props": [("basket", {"fill": "d8607a"})], "pose": "hold_l", "sleeve_w": 0.8, "pin": "e8c050",
})
