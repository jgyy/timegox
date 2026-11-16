"""The Man of Zheng (Part XXXI): who measured his foot at home, left the measure on his seat, went to market, found the
shoe-seller, remembered, went back for the measure, and came again to find the market shut; and, asked why he had not
tried the shoe on his foot, said that he trusted the measure. A careful, anxious, middling man in a townsman's grey
robe with a length of knotted cord held up in front of him.
Run: blender --background --python art/characters/zheng_buyer.py  ->  assets/characters/zheng_buyer.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zheng_buyer.glb", {"age": 0.42, "build": 0.96, "jaw": 0.94, "brow": 0.85, "smile": False, "skin": "d8b894",
    "robe": "76787a", "trim": "c4c8c8", "inner": "eceae2", "sash": "3a4a5a", "pants": "55585a", "boots": "2c2a2a",
    "hair": "1e1a18", "hair_style": "topknot", "eyes": "2e2620", "beard": True, "beard_len": 0.2, "beard_col": "1e1a18", "pose": "hold_l"})
