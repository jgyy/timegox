"""Kuang Heng (Part XXXIII): who had no candle, bored a hole in the wall to read by his neighbour's light, and hired
himself out to a great house for no wage but the loan of its books. A labourer of twenty in a short hemp jacket the
colour of the road, sleeves rolled, lime on his shoulder from the wall he leans on, and a borrowed scroll held up
to whatever light there is.
Run: blender --background --python art/characters/kuang_heng.py  ->  assets/characters/kuang_heng.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/kuang_heng.glb", {"age": 0.08, "build": 1.04, "jaw": 1.0, "brow": 1.05, "smile": False, "skin": "d0b090",
    "robe": "8a7a5e", "trim": "5e5240", "inner": "d8d0bc", "sash": "4a4034", "pants": "5a5244", "shoes": "sandals",
    "hair": "18140f", "hair_style": "topknot", "eyes": "2a2018", "robe_len": "short", "bracers": "6a5c46",
    "props": [("scroll", {"paper": "f0e4c0", "rod": "4a3020"})], "pose": "hold_l"})
