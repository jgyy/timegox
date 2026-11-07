"""The Ferryman of the River of Ten Thousand Years: amber robes, a wide straw hat, an oar-like staff.
Run: blender --background --python art/characters/time_ferryman.py  ->  assets/characters/time_ferryman.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/time_ferryman.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "age": 0.6,
    "robe": "c8902a", "trim": "f0d890", "inner": "f4e8c8", "sash": "6a4a18", "hair": "3a2a1a", "hair_style": "bun", "eyes": "e0a040",
    "hat": "straw", "hat_col": "b89a58", "staff": True, "staff_gem": "ffd060", "beard": True, "beard_col": "c8c0b0", "embroidery": "f0d890",
})
