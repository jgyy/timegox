"""Steppe Shaman A Lan of the Aurora Steppe: fur cap and pale blue robes.
Run: blender --background --python art/characters/steppe_shaman.py  ->  assets/characters/steppe_shaman.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/steppe_shaman.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.2,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": ["drum"],
    "robe": "a0c0e0",
    "trim": "f0f8ff",
    "hair": "1a1a2a",
    "hair_style": "long",
    "hat": "fur",
    "hat_col": "d8ccb8",
    "eyes": "4a8ac0",
    "sash": "4a6a90",
    "ribbon": "60ffc0",})
