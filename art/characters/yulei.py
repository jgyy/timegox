"""Yulei, Door God of the Peach Tree (Part XVI): the dark-faced one of the two door gods, in iron armour with a coil of reed rope at his belt, who ties up the ghosts that did harm in the night and feeds them to the tiger.
Run: blender --background --python art/characters/yulei.py  ->  assets/characters/yulei.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yulei.glb", {"age": 0.5, "build": 1.38, "scale": 1.1, "jaw": 1.3, "brow": 1.35, "stern": True, "skin": "6a4a3a", "beard": True, "beard_len": 0.5, "beard_col": "121010", "robe": "2a3a5a", "trim": "d8c070", "inner": "e8e0cc", "sash": "6a2a2a", "hair": "100e0e", "hair_style": "wild", "eyes": "2a1a10", "armor": True, "metal": "6a6a74", "props": ["whip"], "cape": "1a2438"})
