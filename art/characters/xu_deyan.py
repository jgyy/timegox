"""Xu Deyan (Part XXXII): the gentleman of Chen who broke a bronze mirror in two with his wife on the night the kingdom
fell, kept one half, and for nine years has gone to the capital's market on the fifteenth of the first month to find the
other being cried at a price nobody would pay. A thin man of forty in a scholar's robe gone grey at the seams, who holds
half a mirror up in his left hand as other men hold a lamp.
Run: blender --background --python art/characters/xu_deyan.py  ->  assets/characters/xu_deyan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/xu_deyan.glb", {"age": 0.4, "build": 0.88, "jaw": 0.92, "brow": 0.9, "smile": False, "skin": "dcc0a0",
    "robe": "5c6672", "trim": "aab2b8", "inner": "e8e4d8", "sash": "34404c", "pants": "484e56", "boots": "2a2828",
    "hair": "24201e", "hair_style": "topknot", "eyes": "2a2420", "beard": True, "beard_len": 0.18, "beard_col": "2e2a28",
    "hat": "scholar", "hat_col": "2e343c", "props": [("half_mirror", {"side": 1})], "pose": "hold_l"})
