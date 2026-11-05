"""The Keeper at the Origin of the Dao: robes of dawn violet and gold, long white hair.
Run: blender --background --python art/characters/origin_keeper.py  ->  assets/characters/origin_keeper.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/origin_keeper.glb", {
    "robe": "a08ad0", "trim": "f8e0a0", "inner": "fff8f0", "sash": "6a4aa0", "hair": "f4f0f8", "hair_style": "long", "pin": "ffe080",
    "eyes": "c0a0ff", "glow_eyes": True, "staff": True, "staff_gem": "fff0d0", "embroidery": "f8e0a0",
})
