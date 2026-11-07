"""Innkeeper Bao of the Noon Inn (Part IX): a stout, sharp-eyed woman in an apron with a teapot, renting naps by the hour.
Run: blender --background --python art/characters/innkeeper_bao.py  ->  assets/characters/innkeeper_bao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/innkeeper_bao.glb", {
    "fem": True, "age": 0.55, "build": 1.2, "eye_size": 1.1, "cheek": 1.25,
    "robe": "8a3a3a", "trim": "f0e0c8", "inner": "f4ece0", "sash": "d8a040", "hair": "2a1a14", "hair_style": "bun", "pin": "e0b040",
    "eyes": "4a2a1a", "props": [("apron", {"col": "f0e8d8", "strap": "8a6a50"}), "teapot"], "pose": "hold_both",
})
