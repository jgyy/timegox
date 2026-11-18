"""Goujian of Yue (Part XXXVIII): the king of Yue who lost his country to Wu at Fujiao, served three years as his conqueror's groom, and then slept on brushwood and tasted gall for twenty (Records of the Historian). A lean man of fifty in undyed hemp, hollow in the cheek, with a short grey beard and the eyes of somebody who gets up early on purpose.
Run: blender --background --python art/characters/goujian.py  ->  assets/characters/goujian.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/goujian.glb", {"age": 0.55, "build": 0.85, "jaw": 0.94, "brow": 1.1, "smile": False, "skin": "b89a78", "robe": "a89878", "trim": "5a4a38", "inner": "d8d0c0", "sash": "4a6a5a", "pants": "7a6a52", "shoes": "sandals", "hair": "3a3632", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.2, "beard_col": "8a8680", "brow_col": "3a3632", "robe_len": "long"})
