"""Pang Juan, General of Wei (Part XXXVIII): the general who had his fellow student's kneecaps cut out because he could not be second, and died under a white tree at Maling (Records of the Historian). One of the three who stand above Lin Feng (betters.gd). A spare, quick man of forty in red lacquer and black, narrow-eyed, with a clerk's tidy moustache.
Run: blender --background --python art/characters/pang_juan.py  ->  assets/characters/pang_juan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/pang_juan.glb", {"age": 0.42, "build": 0.98, "jaw": 0.96, "brow": 1.16, "smile": False, "skin": "c0a080", "robe": "8a2a22", "trim": "141414", "inner": "2a2a2a", "sash": "141414", "pants": "2a1a1a", "shoes": "boots", "hair": "161414", "hair_style": "topknot", "eyes": "1a1410", "beard": True, "beard_len": 0.1, "beard_col": "161414", "brow_col": "161414", "robe_len": "long"})
