"""Ling Lun (Part XXIII, the Thundering Pots release): the Yellow Emperor's music-master, who cut the twelve pipes to the phoenix's song from the bamboo
of Xiexi: a spare old man in bamboo-yellow with a green hem, wide sleeves for carrying pipes in, and a long thin white beard.
Run: blender --background --python art/characters/ling_lun.py  ->  assets/characters/ling_lun.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ling_lun.glb", {"fem": False, "age": 0.8, "build": 0.82, "jaw": 0.9, "brow": 0.95, "stern": False, "smile": True, "skin": "e4d2bc",
    "robe": "d8c890", "trim": "3a7a5a", "inner": "f0ece0", "sash": "3a7a5a", "pants": "8a7a4a", "boots": "4a4030", "hair": "e0e0e4", "hair_style": "topknot", "eyes": "5a6a4a",
    "beard": True, "beard_len": 0.55, "beard_col": "e8e8ec", "sleeve_w": 1.8, "jade": "6ad8a8", "pin": "3a7a5a"})
