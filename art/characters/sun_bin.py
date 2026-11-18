"""Sun Bin (Part XXXVIII): the strategist of Qi whose fellow student Pang Juan had his kneecaps cut out and his face branded, and who beat him twice from a cart, the second time under a tree at Maling (Records of the Historian). A composed man of forty-five in a scholar's slate robe with a rug-grey sash, a brand-scar's shadow on one cheek, and very still hands.
Run: blender --background --python art/characters/sun_bin.py  ->  assets/characters/sun_bin.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/sun_bin.glb", {"age": 0.45, "build": 0.9, "jaw": 0.98, "brow": 1.05, "smile": False, "skin": "c8a888", "robe": "5a5a6a", "trim": "2a2a34", "inner": "d0d0d8", "sash": "8a8a84", "pants": "4a4a56", "shoes": "boots", "hair": "1e1c1c", "hair_style": "topknot", "eyes": "221a14", "beard": True, "beard_len": 0.15, "beard_col": "2a2828", "brow_col": "1e1c1c", "robe_len": "long"})
