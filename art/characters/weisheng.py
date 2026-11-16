"""Weisheng (Part XXXII): the young man of Lu who promised to meet a girl under a bridge, and when she did not come
and the water did, put his arms round the pillar and stayed. A youth of twenty with his hair come down and his plain
robe dark with wet to the chest, standing as if he still had hold of something.
Run: blender --background --python art/characters/weisheng.py  ->  assets/characters/weisheng.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/weisheng.glb", {"age": 0.05, "build": 0.94, "jaw": 0.96, "brow": 0.95, "smile": False, "skin": "d8c4b0",
    "robe": "3e5660", "trim": "8aa0a4", "inner": "d0d4cc", "sash": "26343a", "pants": "34444a", "boots": "22282a",
    "hair": "141618", "hair_style": "wild", "eyes": "26221e", "robe_len": "short", "pose": "hold_both"})
