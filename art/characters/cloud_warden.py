"""Warden Feng Yu of the Sea of Clouds: sky-blue and white robes with feathered trim and a ribbon.
Run: blender --background --python art/characters/cloud_warden.py  ->  assets/characters/cloud_warden.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/cloud_warden.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.1,
    # woven brocade over the robe (garment.MOTIFS)
    "brocade": "cranes", "brocade_col": "f4f8ff",
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("gourd", {"col": "e8f0ff", "side": 1})],
    "robe": "7ab0e8", "trim": "ffffff", "inner": "f0f8ff", "sash": "3a6aa8", "hair": "2a2a40", "hair_style": "topknot", "eyes": "4a90e0",
    "ribbon": "ffffff", "cape": "e8f4ff", "staff": True, "staff_gem": "f0ffff", "embroidery": "c8e8ff",
})
