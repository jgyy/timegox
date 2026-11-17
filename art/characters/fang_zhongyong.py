"""Fang Zhongyong at twenty (Part XXXV): the boy of Jinxi who made verses at five with nobody to teach him, was led
from door to door by his father for the coppers, and at twenty was no different from anybody (Wang Anshi). A farmer
in a short jacket of faded hemp with the sleeves rolled, sunburnt, a straw hat, a good plain face; nothing about him
would make anybody look twice, which is the point of him.
Run: blender --background --python art/characters/fang_zhongyong.py  ->  assets/characters/fang_zhongyong.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/fang_zhongyong.glb", {"age": 0.15, "build": 1.04, "jaw": 1.0, "brow": 1.0, "smile": False, "skin": "c89e74",
    "robe": "8a7a5a", "trim": "5a4e38", "inner": "d8ccb0", "sash": "4a3a28", "pants": "6a5e48", "shoes": "sandals",
    "hair": "18140f", "hair_style": "topknot", "eyes": "2a2018", "hat": "straw", "robe_len": "short", "wraps": "a89a7a"})
