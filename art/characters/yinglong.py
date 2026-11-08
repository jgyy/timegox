"""Yinglong, the winged dragon who dug the rivers with his tail, in the shape of an old man: dragon horns, a long white beard, a teal robe and a staff of driftwood.
Run: blender --background --python art/characters/yinglong.py  ->  assets/characters/yinglong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yinglong.glb", {
    "age": 1.0, "build": 1.0, "brow": 1.3, "eye_size": 1.0, "slit_eyes": True, "beard": True, "beard_len": 1.2, "beard_col": "f4f4f0",
    "horns": True, "horn_col": "d8c890", "glow_eyes": "e0c060",
    "robe": "2a5a6a", "trim": "d8c890", "inner": "e8f0ec", "sash": "1a3a4a", "hair": "f0f0ec", "hair_style": "long",
    "eyes": "c8a030", "staff": True, "staff_gem": "60c0d0", "cape": "1a3a4a", "embroidery": "d8c890",
})
