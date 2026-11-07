"""Granny Wen the Midwife (Part VII): the village midwife who raised Lin Feng, in faded indigo with a white apron and grey hair in a bun.
Run: blender --background --python art/characters/granny_wen.py  ->  assets/characters/granny_wen.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/granny_wen.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.9, "build": 0.95, "eye_size": 1.1,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("basket", {"fill": "f0e8d0"})], "pose": "hold_l",
    "robe": "3a4a7a", "trim": "e8e4d8", "inner": "f0ece0", "sash": "e8e4d8", "hair": "b8b4b8", "hair_style": "bun",
    "pin": "8a6a3a", "eyes": "4a3a2a", "staff": True, "staff_gem": "e8d8a0", "collar2": "5a6a9a", "embroidery": "c8d0e8",
})
