"""Su Wan, Lin Feng's mother (Part VI): a soft green hanfu, long hair with a jade pin.
Run: blender --background --python art/characters/su_wan.py  ->  assets/characters/su_wan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/su_wan.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "eye_size": 1.32,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("lantern", {"col": "f0f0e0", "glow": "fff0c0"})], "pose": "hold_l",
    "robe": "6aa88a", "trim": "f0f0e0", "inner": "f8f4ec", "sash": "3a6a5a", "hair": "201a24", "hair_style": "long",
    "pin": "6af0b0", "eyes": "3a7ae8", "ribbon": "e8f0e0", "collar2": "a8d0b8", "embroidery": "f0e8c0",
})
