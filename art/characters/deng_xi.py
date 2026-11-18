"""Deng Xi (Part XXXIX): the advocate of Zheng who taught the people to go to law, argued either side of anything for a fee of a coat, and wrote his own code on bamboo when the minister's was cast in bronze (Lushi Chunqiu, Zuo Zhuan). A quick, lean man of forty in a litigant's brown robe with ink on the cuffs, a thin moustache and a smile that has already been paid.
Run: blender --background --python art/characters/deng_xi.py  ->  assets/characters/deng_xi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/deng_xi.glb", {"age": 0.4, "build": 0.85, "jaw": 0.92, "brow": 1.0, "smile": True, "skin": "caa27e", "robe": "6a4a32", "trim": "2a1e16", "inner": "d8d0b8", "sash": "a8823a", "pants": "4a3a2a", "shoes": "boots", "hair": "1c1a18", "hair_style": "topknot", "eyes": "241a12", "beard": True, "beard_len": 0.08, "beard_col": "24201c", "brow_col": "1c1a18", "robe_len": "long"})
