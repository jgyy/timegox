"""Hui Shi (Part XXXIX): the minister of Wei whose books filled five carts, who said the sun at noon is setting and an egg has feathers, and whom Zhuangzi missed when he was dead as a carpenter misses the man who could stand still under the axe (Zhuangzi, Under Heaven). A broad, comfortable man of fifty-five in a minister's plum robe with a jade-green sash, a full grey-shot beard and the look of somebody enjoying an argument he expects to lose.
Run: blender --background --python art/characters/hui_shi.py  ->  assets/characters/hui_shi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/hui_shi.glb", {"age": 0.55, "build": 1.15, "jaw": 1.05, "brow": 1.0, "smile": True, "skin": "d2aa86", "robe": "6a3a5a", "trim": "2e1a28", "inner": "e0d8d0", "sash": "5a8a6a", "pants": "4a2e42", "shoes": "boots", "hair": "3a3636", "hair_style": "topknot", "eyes": "221a14", "beard": True, "beard_len": 0.3, "beard_col": "5a5654", "brow_col": "3a3636", "robe_len": "long"})
