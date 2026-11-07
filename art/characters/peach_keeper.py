"""Peach Keeper Tao Yao of the Garden of Immortal Peaches: blossom-pink robes, a crown of flowers and long hair.
Run: blender --background --python art/characters/peach_keeper.py  ->  assets/characters/peach_keeper.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/peach_keeper.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "eye_size": 1.34,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": ["peach_branch"], "pose": "hold_l",
    "robe": "f0a8c0", "trim": "fff0f4", "inner": "fff8fa", "sash": "c05a80", "hair": "3a2028", "hair_style": "long", "pin": "ff90b0",
    "eyes": "e070a0", "crown": True, "ribbon": "ffd0e0", "embroidery": "fff0a0", "collar2": "ffd0e0",
})
