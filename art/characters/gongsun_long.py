"""Gongsun Long (Part XXXIX): the disputer of Zhao who rode a white horse up to a frontier gate and proved to the warden that a white horse is not a horse, and held that hard and white are two things and never one stone (Gongsun Longzi). A tall, spare man of fifty in a robe as white as his argument with a slate trim, a narrow pointed beard, and no expression that could be used against him.
Run: blender --background --python art/characters/gongsun_long.py  ->  assets/characters/gongsun_long.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/gongsun_long.glb", {"age": 0.5, "build": 0.88, "jaw": 0.95, "brow": 1.1, "smile": False, "skin": "d0b090", "robe": "e8e6e0", "trim": "4a4e58", "inner": "c8ccd4", "sash": "6a6e78", "pants": "b8b6b0", "shoes": "boots", "hair": "2a2828", "hair_style": "topknot", "eyes": "1e1a18", "beard": True, "beard_len": 0.22, "beard_col": "3a3838", "brow_col": "2a2828", "robe_len": "long"})
