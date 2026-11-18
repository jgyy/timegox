"""Fuchai, King of Wu (Part XXXVIII): the king who broke Yue at Fujiao and kept its king for a groom (Records of the Historian). One of the three who stand above Lin Feng (betters.gd). A tall, easy man of thirty-five in a king's dark sea-blue armour-robe trimmed with bronze, short black beard, who sits a horse even when he is standing.
Run: blender --background --python art/characters/fuchai.py  ->  assets/characters/fuchai.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/fuchai.glb", {"age": 0.35, "build": 1.12, "jaw": 1.06, "brow": 1.08, "smile": False, "skin": "c8a480", "robe": "2a5a7a", "trim": "b8862a", "inner": "1a2a3a", "sash": "b8862a", "pants": "1e3a50", "shoes": "boots", "hair": "141212", "hair_style": "topknot", "eyes": "1a1410", "beard": True, "beard_len": 0.15, "beard_col": "141212", "brow_col": "141212", "robe_len": "long"})
