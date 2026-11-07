"""Spore-Witch Mo Gu of Glowcap Vale: violet hood, long hair and a glowing staff.
Run: blender --background --python art/characters/spore_witch.py  ->  assets/characters/spore_witch.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/spore_witch.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "age": 0.35,
    # signature props and how they are held (art/lib/accessory.py, person.POSES)
    "props": [("basket", {"fill": "c070e0"})], "pose": "hold_l",
    "robe": "8a6ab0",
    "trim": "c8a0e0",
    "hair": "e0d8f0",
    "hair_style": "long",
    "hat": "hood",
    "hat_col": "5a4a7a",
    "eyes": "60e0c0",
    "sash": "4a3a6a",
    "staff": True,
    "staff_gem": "60ffd0",})
