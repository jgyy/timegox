"""Shenshu, Door God of the Peach Tree (Part XVI): the red-faced one of the two door gods who judge the ghosts at the gate under the great peach tree, a giant in gilded armour with a halberd; his portrait is on half the doors in the land at New Year.
Run: blender --background --python art/characters/shenshu.py  ->  assets/characters/shenshu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/shenshu.glb", {"age": 0.45, "build": 1.4, "scale": 1.12, "jaw": 1.25, "brow": 1.3, "stern": True, "skin": "c8603a", "beard": True, "beard_len": 0.6, "beard_col": "1a1410", "robe": "a82a24", "trim": "f0c850", "inner": "f0e4c8", "sash": "2a2a30", "hair": "141010", "hair_style": "topknot", "eyes": "2a1a10", "armor": True, "metal": "c8a040", "halberd": True})
