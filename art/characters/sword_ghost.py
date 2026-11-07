"""Ancestor Jian Wuchen, the sword ghost of Thunder Valley: pale blue-white robes, a topknot and a long beard, a jian at his side.
Run: blender --background --python art/characters/sword_ghost.py  ->  assets/characters/sword_ghost.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/sword_ghost.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "age": 0.6, "beard_len": 1.1, "brow": 1.2,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": ["spirit_swords"],
    "robe": "c8dcf0", "trim": "5a8ac8", "inner": "f4f8ff", "sash": "3a5a8a", "hair": "e8eef8", "hair_style": "topknot", "eyes": "8ac8ff",
    "glow_eyes": True, "beard": True, "beard_col": "eef4ff", "sword": True, "blade": "e8f4ff", "embroidery": "a0d0ff", "stern": True,
})
