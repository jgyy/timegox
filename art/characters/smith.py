"""Smith Tie: leather-armoured, wild-haired and bearded.
Run: blender --background --python art/characters/smith.py  ->  assets/characters/smith.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/smith.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "age": 0.35, "build": 1.14, "beard_len": 0.6, "brow": 1.3,
    "robe": "d08a5a",
    "trim": "f0d0b0",
    "hair": "3a2a20",
    "hair_style": "wild",
    "armor": True,
    "metal": "8a6a4a",
    "beard": True,
    "beard_col": "4a3020",
    "eyes": "5a3a2a",
    "sash": "5a3a20",
    "stern": True,})
