"""Silk Farmer Can Niang of the Mulberry Woods (Part VII): a young silk farmer in cream and mulberry purple with a headscarf.
Run: blender --background --python art/characters/can_niang.py  ->  assets/characters/can_niang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/can_niang.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.2,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("basket", {"fill": "5aaa3a"})], "pose": "hold_l",
    "robe": "e8dcb8", "trim": "7a3a5a", "inner": "f8f4e8", "sash": "7a3a5a", "hair": "2a1a14", "hair_style": "braid",
    "eyes": "4a2a1a", "hat": "hood", "hat_col": "8a4a6a", "ribbon": "f0d0e0", "embroidery": "b05080",
})
