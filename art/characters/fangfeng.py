"""Fangfeng of the Great People (Part XXXI): the lord of the Wangmang who came late to the assembly Yu called at Kuaiji and
was cut down for it, and one joint of whose bones filled a cart. A giant in late middle age, whom the game draws at twice
a man's height: grey in a long beard, a lord's topknot under a plain pin, a dark hemp robe of the flood years, and the
heavy brow of somebody who has been explaining himself for four thousand years.
Run: blender --background --python art/characters/fangfeng.py  ->  assets/characters/fangfeng.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/fangfeng.glb", {"age": 0.6, "build": 1.3, "head_scale": 0.9, "hand_k": 1.15, "jaw": 1.14, "brow": 1.4, "stern": True, "smile": False, "skin": "b8926c",
    "robe": "3e4a4a", "trim": "9aa49a", "inner": "d8d4c4", "sash": "6a5a3a", "pants": "33372f", "boots": "2e2a24",
    "hair": "6a6a6a", "hair_style": "topknot", "eyes": "2e2620", "beard": True, "beard_len": 0.9, "beard_col": "8a8a88", "pin": "8a8a7a"})
