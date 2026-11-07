"""Innkeeper Fu of the Green Stone Inn (Part VII): a broad, cheerful man in brown with a green apron and a cloth cap.
Run: blender --background --python art/characters/innkeeper.py  ->  assets/characters/innkeeper.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/innkeeper.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "age": 0.4, "build": 1.12, "beard_len": 0.5, "cheek": 1.3,
    "robe": "7a5a3a", "trim": "4a8a5a", "inner": "e8dcc0", "sash": "3a6a4a", "hair": "2a2018", "hair_style": "topknot",
    "eyes": "4a3018", "beard": True, "beard_col": "2a2018", "hat": "scholar", "hat_col": "4a3a2a", "embroidery": "8ac08a",
})
