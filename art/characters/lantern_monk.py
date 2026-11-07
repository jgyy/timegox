"""Lantern Monk Jing Kong of the Maple Gorge (Part VI): saffron and russet robes, shaven head, a ringed staff with a soul lantern.
Run: blender --background --python art/characters/lantern_monk.py  ->  assets/characters/lantern_monk.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lantern_monk.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "age": 0.3, "build": 1.04,
    "robe": "d8902a", "trim": "8a2a1a", "inner": "f0e0c0", "sash": "6a2a18", "hair": "2a2020", "hair_style": "bald",
    "eyes": "5a3a20", "staff": True, "staff_gem": "ffc860", "beard": False, "collar2": "8a2a1a", "embroidery": "f0c040",
})
