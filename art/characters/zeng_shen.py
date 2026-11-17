"""Zeng Shen as a boy (Part XXXV): the disciple of whom the Master said "Shen is dull", who examined himself three
times a day and to whom the teaching was handed in the end. A square, plain child of twelve with large ears, in a
farm boy's short jacket of undyed blue-grey let out at the cuffs, a bundle's cord across his chest; he stands very
straight, as a child stands who has been told to and is still thinking about it.
Run: blender --background --python art/characters/zeng_shen.py  ->  assets/characters/zeng_shen.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zeng_shen.glb", {"age": 0.0, "build": 0.96, "eye_size": 1.25, "scale": 0.8, "head_scale": 1.14, "jaw": 1.02, "brow": 1.1, "smile": False, "skin": "dcc0a0",
    "robe": "7a8a9a", "trim": "4a5662", "inner": "e8e2d2", "sash": "3a3a34", "pants": "5a6068", "shoes": "sandals",
    "hair": "16120e", "hair_style": "topknot", "eyes": "2a2018", "robe_len": "short"})
