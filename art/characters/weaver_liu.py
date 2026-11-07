"""Weaver Liu of Qingshi Village (Part VII): a weaver in lilac with thread spools at her sash and long dark hair.
Run: blender --background --python art/characters/weaver_liu.py  ->  assets/characters/weaver_liu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/weaver_liu.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.3,
    "robe": "8a6ab0", "trim": "f0e0f8", "inner": "f4f0f8", "sash": "4a3a6a", "hair": "1a1420", "hair_style": "long",
    "pin": "e8c860", "eyes": "5a3a6a", "ribbon": "e0c0f0", "embroidery": "f0d8ff",
})
