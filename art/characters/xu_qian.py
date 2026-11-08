"""Headwoman Xu Qian of Landfall (Part XII): a sturdy woman of fifty among the Thousand Children, in a sea-blue robe with a carved staff of driftwood and the town's keys at her sash.
Run: blender --background --python art/characters/xu_qian.py  ->  assets/characters/xu_qian.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/xu_qian.glb", {
    "fem": True, "age": 0.55, "jaw": 0.95, "build": 1.04, "eye_size": 1.1,
    "staff": True, "staff_gem": "e8e0c8",
    "robe": "3a5a8a", "trim": "e8dcc0", "inner": "f4efe4", "sash": "8a4a2a", "hair": "3a3434", "hair_style": "bun", "eyes": "3a2a1a", "pin": "c8b070"
})
