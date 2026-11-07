"""Cormorant Fisher Old Yu of the Nine-Bend River (Part VI): a patched blue-grey work robe, a straw rain hat and a white beard.
Run: blender --background --python art/characters/fisher.py  ->  assets/characters/fisher.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/fisher.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "age": 0.8, "beard_len": 0.8, "build": 0.97,
    "robe": "5a7a8a", "trim": "c8c0a8", "inner": "e8e0d0", "sash": "3a4a50", "hair": "d8d8d8", "hair_style": "bun",
    "hat": "straw", "hat_col": "c8a868", "eyes": "4a3a2a", "beard": True, "beard_col": "e8e8e8", "staff": True, "staff_gem": "a0e0ff",
    "pants": "3a4a50", "boots": "4a3a2a", "embroidery": "c8c0a8",
})
