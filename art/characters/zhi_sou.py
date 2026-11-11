"""Zhi Sou, the Wise Old Man of the River Bend (Part XX, the Hollow Hills release): who laughed at Yu Gong and has
not been allowed to forget it: a neat, dry old gentleman in a long robe of grey-green silk with wide sleeves
and a scholar's cap, his hands folded away in them.
Run: blender --background --python art/characters/zhi_sou.py  ->  assets/characters/zhi_sou.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zhi_sou.glb", {"fem": False, "age": 0.85, "build": 0.88, "jaw": 0.9, "brow": 1.08, "stern": True, "skin": "e4c8a8",
    "robe": "6a8078", "trim": "d8d0b0", "inner": "f0ece0", "sash": "3a4a48", "pants": "4a5a56", "boots": "2a3432", "hair": "d8d4cc", "hair_style": "topknot", "eyes": "3a3830",
    "beard": True, "beard_len": 0.8, "beard_col": "e0dcd4", "hat": "scholar", "hat_col": "2a3432", "brocade": "cloud", "brocade_col": "8aa098", "sleeve_w": 1.4,
    "pose": "sleeves"})
