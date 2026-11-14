"""Hua Xin (Part XXIX): Guan Ning's friend, who picked up the gold and threw it away again, and put down his book to go and
look at a great man's carriage; later an honest minister of Wei.  A rounder, readier man in a purple-grey silk robe a
little too good for a garden, a book pushed through his sash, a neat black moustache and an official's small cap; he
laughs at himself, which his friend never does.
Run: blender --background --python art/characters/hua_xin.py  ->  assets/characters/hua_xin.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/hua_xin.glb", {"fem": False, "age": 0.45, "build": 1.08, "jaw": 1.05, "brow": 0.95, "smile": True, "skin": "d8b890",
    "robe": "6a4a8a", "trim": "c8a850", "inner": "f0e8d8", "sash": "c8a850", "pants": "4a3a5a", "boots": "1e1c1a",
    "hair": "18161a", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.12, "beard_col": "18161a"})
