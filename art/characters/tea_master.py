"""Tea Master Lu Yu of the Cloud-Tea Terraces (Part VII): a tea sage in leaf green under a wide straw hat, with a long white beard.
Run: blender --background --python art/characters/tea_master.py  ->  assets/characters/tea_master.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/tea_master.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "age": 0.65, "beard_len": 0.9,
    "robe": "4a7a3a", "trim": "e8e0b8", "inner": "f0ecd8", "sash": "2a4a20", "hair": "e8e4e0", "hair_style": "bun",
    "eyes": "3a2a1a", "beard": True, "beard_col": "f0ece8", "hat": "straw", "hat_col": "c8a868", "staff": True, "staff_gem": "a0e080", "embroidery": "c8e0a0",
})
