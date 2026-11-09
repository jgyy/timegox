"""A grandfather of the towns (scripts/folk.gd): a white beard, a stoop and a walking staff; he does his slow morning exercises in the square, plays weiqi in the afternoon and dozes on the bench.
Run: blender --background --python art/characters/folk_grandpa.py  ->  assets/characters/folk_grandpa.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_grandpa.glb", {"age": 0.92, "build": 0.9, "beard": True, "beard_len": 0.7, "beard_col": "e8e4dc", "robe": "5a5a4a", "trim": "e0d8c4", "inner": "eee8da", "sash": "6a4a2a", "hair": "dedad4", "hair_style": "topknot", "eyes": "3a3020", "staff": True, "staff_gem": "8a6a3a", "scale": 0.95})
