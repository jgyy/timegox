"""Que Lao, the Old Magpie (Part VIII): eldest of the magpies who build the bridge across the
Silver River each seventh night.  An old man in a cloak of black-and-white magpie feathers with a
blue sheen, a white bun, a long beard and a gnarled staff.
Run: blender --background --python art/characters/que_lao.py  ->  assets/characters/que_lao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/que_lao.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.85, "beard_len": 1.2, "brow": 1.2, "build": 0.94,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": ["feather_cloak"],
    "robe": "2a2a34", "trim": "f0f0f8", "inner": "f4f4f8", "sash": "3a5ab0", "hair": "e8e8ec", "hair_style": "bun",
    "eyes": "2a2a3a", "beard": True, "beard_col": "f0f0f4", "staff": True, "staff_gem": "a0c0ff", "embroidery": "a0b8f0",
    "pin": "3a5ab0", "collar2": "3a5ab0",
})
