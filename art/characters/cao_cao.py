"""Cao Cao, Lord of Wei, with the Wind in His Head (Part XXVI): the warlord who suffered all his life from a splitting
headache, sent for Hua Tuo, and put him in chains for offering to open his skull; a lean, hard man in his middle years in
black lacquered armour over a black robe with dark red trims, a short dark beard.
Run: blender --background --python art/characters/cao_cao.py  ->  assets/characters/cao_cao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/cao_cao.glb", {"fem": False, "age": 0.5, "build": 1.04, "jaw": 1.08, "brow": 1.3, "stern": True, "smile": False, "skin": "d0ae8c",
    "robe": "1e1e26", "trim": "8a2a2a", "inner": "d8d0c4", "sash": "8a2a2a", "pants": "16161c", "boots": "101014", "armor": True, "metal": "2e2e36",
    "hair": "18161a", "hair_style": "topknot", "eyes": "2a2222", "beard": True, "beard_len": 0.28, "beard_col": "1e1a1a"})
