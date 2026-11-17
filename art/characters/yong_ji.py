"""Yong Ji (Part XXXVI): the counsellor of Duke Wen of Jin who said, drain the pond to fish and next year there are
no fish (the Spring and Autumn of Master Lu), and was rewarded above the uncle whose plan won the battle. A spare,
upright man of sixty-five in the long slate-blue coat of a court he has left, grey beard combed, the hem dark with
the mud of a marsh he walked down into after a pond.
Run: blender --background --python art/characters/yong_ji.py  ->  assets/characters/yong_ji.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yong_ji.glb", {"age": 0.72, "build": 0.9, "jaw": 0.96, "brow": 1.1, "smile": False, "skin": "d2b494",
    "robe": "5a6a7a", "trim": "2e3844", "inner": "d8d4c8", "sash": "8a7a4a", "pants": "3e4650", "shoes": "boots",
    "hair": "9a9a98", "hair_style": "topknot", "eyes": "2e2620", "beard": True, "beard_len": 0.7, "beard_col": "a8a8a4", "brow_col": "8a8a88", "robe_len": "long"})
