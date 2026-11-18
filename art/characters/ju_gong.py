"""Ju Gong (Part XL): the keeper of monkeys of the Zhuangzi and the Liezi, who told his troop they should have three acorns in the morning and four at night, and when they were furious gave them four in the morning and three at night, and they were delighted. A small, weathered man of seventy in a patched bark-brown coat with an acorn-green sash, a wisp of white beard, and the patient smile of somebody who has been outvoted by monkeys every day for fifty years.
Run: blender --background --python art/characters/ju_gong.py  ->  assets/characters/ju_gong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ju_gong.glb", {"age": 0.72, "build": 0.82, "jaw": 0.94, "brow": 0.96, "smile": True, "skin": "b8906a", "robe": "6a5238", "trim": "3a2c1e", "inner": "c8c0a4", "sash": "6a8a4a", "pants": "5a4a34", "shoes": "boots", "hair": "d8d4cc", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.12, "beard_col": "dcd8d0", "brow_col": "c8c4bc", "robe_len": "long"})
