"""Stone-Carver Shi of Tushan: a dusty old carver of steles with spectacles on his nose and a brush for laying out the characters before the chisel.
Run: blender --background --python art/characters/carver_shi.py  ->  assets/characters/carver_shi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/carver_shi.glb", {
    "age": 0.75, "build": 0.9, "eye_size": 1.0, "beard": True, "beard_len": 0.5, "beard_col": "c8c4bc",
    "robe": "8a8a80", "trim": "e0dcd0", "inner": "eeeae0", "sash": "4a4a4a", "hair": "b8b4ac", "hair_style": "topknot",
    "eyes": "3a3a3a", "hat": "qing", "hat_col": "3a3a3a", "props": ["brush", "spectacles"], "pose": "hold_l",
})
