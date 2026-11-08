"""Innkeeper Dong of the Leaping Carp Inn at Longmen: a genial innkeeper with a teapot and an apron, whose best room has been dry for a whole week.
Run: blender --background --python art/characters/innkeeper_dong.py  ->  assets/characters/innkeeper_dong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/innkeeper_dong.glb", {
    "age": 0.6, "build": 1.15, "cheek": 1.15, "eye_size": 1.0, "smile": True, "beard": True, "beard_len": 0.3, "beard_col": "4a3a30",
    "robe": "a85a3a", "trim": "f0e0c8", "inner": "f4ece0", "sash": "3a5a3a", "hair": "3a2a20", "hair_style": "topknot",
    "eyes": "3a2a1a", "props": [("apron", {"col": "f0e8d8", "strap": "8a6a50"}), "teapot"], "pose": "hold_both",
})
