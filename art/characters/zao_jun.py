"""Zao Jun, Lord of the Stove (Part XVI): the Kitchen God of the sect's kitchen, a small round old man in a soot-black robe with a singed beard, a tall black hat and the household's ledger under his arm, who would not go up the chimney.
Run: blender --background --python art/characters/zao_jun.py  ->  assets/characters/zao_jun.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/zao_jun.glb", {"age": 0.85, "build": 1.25, "scale": 0.9, "cheek": 1.35, "smile": True, "beard": True, "beard_len": 0.55, "beard_col": "2a2420", "robe": "2a2224", "trim": "c8402a", "inner": "e8dcc8", "sash": "c8a040", "hair": "2a2420", "hair_style": "topknot", "eyes": "3a2a1a", "hat": "scholar", "hat_col": "141012", "props": ["ledger"], "pose": "hold_l", "embroidery": "e8b040"})
