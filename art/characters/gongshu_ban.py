"""Gongshu Ban (Lu Ban), master of carpenters (Part XIX, the Hundred Works release): a broad, cheerful man with a
carpenter's forearms, a leather apron over a short brown robe, sawdust-grey hair in a topknot and a mallet in his hand.
Run: blender --background --python art/characters/gongshu_ban.py  ->  assets/characters/gongshu_ban.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/gongshu_ban.glb", {"fem": False, "age": 0.55, "build": 1.28, "jaw": 1.1, "brow": 1.15, "smile": True, "skin": "d8a878",
    "robe": "8a6238", "trim": "e0c890", "inner": "f0e4c8", "sash": "3a2a1a", "pants": "5a4630", "boots": "3a2a1c", "hair": "8a8478", "hair_style": "topknot", "eyes": "3a2814",
    "beard": True, "beard_len": 0.35, "beard_col": "8a8478", "robe_len": "short", "wraps": "c8b48a", "props": [("apron", {"col": "7a4e2a", "strap": "3a2818"}), "hammer"]})
