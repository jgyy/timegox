"""Keeper Lan Jing of the Mirror Lake: pale blue silks, long silver hair, a jade pin.
Run: blender --background --python art/characters/lake_keeper.py  ->  assets/characters/lake_keeper.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lake_keeper.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "eye_size": 1.3,
    "robe": "9ac8e8", "trim": "f0f8ff", "inner": "f8fcff", "sash": "4a7aa8", "hair": "d8e4f0", "hair_style": "long", "pin": "a0e8ff",
    "eyes": "5aa8e8", "ribbon": "e8f4ff", "staff": True, "staff_gem": "c8f0ff", "embroidery": "e8f4ff",
})
