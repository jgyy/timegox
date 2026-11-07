"""Lin Shan, Lin Feng's father (Part VI): a sect sweeper's patched grey robe, a topknot, kind eyes.
Run: blender --background --python art/characters/lin_shan.py  ->  assets/characters/lin_shan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lin_shan.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": False, "age": 0.15,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": ["hoe"],
    "robe": "7a7a70", "trim": "c8c0a8", "inner": "e8e4d8", "sash": "4a4a40", "hair": "1a1a2a", "hair_style": "topknot",
    "eyes": "3a6ad8", "pants": "4a4a44", "boots": "3a3430", "embroidery": "c8c0a8", "collar2": "5a5a50",
})
