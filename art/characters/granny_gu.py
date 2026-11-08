"""Granny Gu, keeper of the Yanggu granary (Part IX): a tiny, upright old woman with a ledger of millet and sixty harvests behind her.
Run: blender --background --python art/characters/granny_gu.py  ->  assets/characters/granny_gu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/granny_gu.glb", {
    "fem": True, "age": 0.95, "build": 0.88, "eye_size": 1.05,
    "robe": "6a5a3a", "trim": "e8dcc0", "inner": "f0e8d8", "sash": "8a4a2a", "hair": "d8d4d0", "hair_style": "bun", "pin": "3a8a5a",
    "eyes": "3a3020", "props": ["ledger"], "pose": "hold_l", "staff": True, "staff_gem": "e0c070", "scale": 0.94,
})
