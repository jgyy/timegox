"""The Dragon King's envoy of the Sunken Dragon Palace: sea-green robes with pearl trim and a crown.
Run: blender --background --python art/characters/dragon_envoy.py  ->  assets/characters/dragon_envoy.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/dragon_envoy.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "jaw": 0.94,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": ["pearl"], "pose": "hold_l",
    "robe": "2a8a8a", "trim": "e8f4f0", "inner": "d8f0f0", "sash": "1a4a5a", "hair": "1a3a4a", "hair_style": "long", "eyes": "40d0c0",
    "crown": True, "staff": True, "staff_gem": "a0f0ff", "embroidery": "e8f4f0", "collar2": "40a8a0",
})
