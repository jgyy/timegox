"""Zhongli Quan of the Fan (Part XII): the general who lost a battle and found the Dao, big-bellied, bald but for two tufts, a long beard, his robe open and a great fan in his hand.
Run: blender --background --python art/characters/zhongli_quan.py  ->  assets/characters/zhongli_quan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zhongli_quan.glb", {
    "age": 0.65, "build": 1.24, "brow": 1.25, "jaw": 1.12, "beard": True, "beard_col": "2a2018", "beard_len": 1.1, "smile": True,
    "props": [("folding_fan", {"col": "f0e0c0", "ribs": "5a3a20", "painted": "c84a2a"})], "pose": "hold_l",
    "robe": "c84a2a", "trim": "f0c850", "inner": "f6e8d0", "sash": "3a2a1a", "hair": "1a1410", "hair_style": "twin_buns", "eyes": "2a1a10"
})
