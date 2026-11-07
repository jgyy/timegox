"""Archivist Lan of the Scripture Library (Part VII): a bookish elder in midnight blue with a scholar's cap and ink-stained sleeves.
Run: blender --background --python art/characters/archivist.py  ->  assets/characters/archivist.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/archivist.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "age": 0.55, "beard_len": 0.8,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": ["scroll", "spectacles"],
    "robe": "2a3a6a", "trim": "d8c890", "inner": "e8e4d8", "sash": "1a2440", "hair": "a8a8b0", "hair_style": "topknot",
    "eyes": "3a3a4a", "hat": "scholar", "hat_col": "1a1a2a", "beard": True, "beard_col": "c8c8cc", "sleeve": "1a1a24", "embroidery": "e0d090",
})
