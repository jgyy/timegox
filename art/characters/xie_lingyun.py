"""Xie Lingyun, Duke of Kangle (Part XXII): the poet who wore clogs with teeth that came out, and cut roads through
mountains with a few hundred friends until a governor took them for bandits: a traveller's short green robe, leg wraps.
Run: blender --background --python art/characters/xie_lingyun.py  ->  assets/characters/xie_lingyun.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/xie_lingyun.glb", {"fem": False, "age": 0.45, "build": 1.0, "jaw": 0.98, "brow": 1.0, "stern": False, "smile": True, "skin": "e0c0a0",
    "robe": "3a6a5a", "trim": "e8dcc0", "inner": "f0e8d8", "sash": "8a5a2a", "pants": "4a4a3a", "boots": "5a4028", "hair": "2a2420", "hair_style": "topknot", "eyes": "3a2a1a",
    "beard": True, "beard_len": 0.2, "beard_col": "2a2420", "robe_len": "short", "wraps": "c8b890", "bracers": "5a4028", "sleeve_w": 0.9})
