"""Xu Fu, Who Came Back (Part XII): the First Emperor's magician, ageing at last after two thousand years: the black-and-gold robe and tall cap of a Qin court magician, a grey beard coming in, a walking staff.
Run: blender --background --python art/characters/xu_fu_home.py  ->  assets/characters/xu_fu_home.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/xu_fu_home.glb", {
    "age": 0.75, "build": 0.96, "brow": 1.15, "jaw": 1.0, "beard": True, "beard_col": "8a8680", "beard_len": 0.9,
    "staff": True, "staff_gem": "a0ffc0", "hat": "scholar", "hat_col": "141418",
    "robe": "2a2430", "trim": "d8c070", "inner": "e8e0cc", "sash": "8a2a2a", "hair": "6a6660", "hair_style": "topknot", "eyes": "3a3028", "embroidery": "d8c070"
})
