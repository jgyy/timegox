"""Carpenter Shi of Qi (Part XXXV): the master carpenter of the Zhuangzi who walked past the great oak of the shrine
without turning his head, called it useless timber, and was visited by it in a dream. A broad man of sixty with a
carpenter's stoop and a grey beard cut square, in a short brown working robe and a leather apron, his sleeves bound;
he stands like somebody who has measured everything he ever looked at, and has lately been measured back.
Run: blender --background --python art/characters/carpenter_shi.py  ->  assets/characters/carpenter_shi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/carpenter_shi.glb", {"age": 0.62, "build": 1.22, "jaw": 1.08, "brow": 1.2, "stern": True, "skin": "caa27a",
    "robe": "6a5a44", "trim": "3a3024", "inner": "d8ccb0", "sash": "2e241a", "pants": "4a4030", "boots": "2a221a",
    "hair": "8a8680", "hair_style": "topknot", "eyes": "2e241a", "beard": True, "beard_len": 0.3, "beard_col": "9a968e", "brow_col": "8a8680",
    "props": [("apron", {"col": "5a4028", "strap": "2e2218"})], "robe_len": "short", "wraps": "9a8a6a"})
