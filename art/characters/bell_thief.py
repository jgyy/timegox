"""The man who stopped his ears (Part XXXIV): when the house of Fan fell, a man of the people got hold of a bell, found
it too big to carry, broke it with a mallet, and when it rang stopped his own ears so that nobody should hear (the
Lushi Chunqiu). A thick-set labourer of forty in a short brown jacket with the sleeves rolled and a rag tied round his
head over both ears, anxious and loud.
Run: blender --background --python art/characters/bell_thief.py  ->  assets/characters/bell_thief.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/bell_thief.glb", {"age": 0.4, "build": 1.18, "jaw": 1.1, "brow": 1.2, "smile": False, "skin": "c8a47c",
    "robe": "6a4e34", "trim": "3e3022", "inner": "cfc6ae", "sash": "2e2418", "pants": "4a4032", "shoes": "sandals",
    "hair": "18140f", "hair_style": "topknot", "eyes": "2e241a", "beard": True, "beard_len": 0.15, "beard_col": "1a1618",
    "hat": "headcloth", "hat_col": "c8c0a8", "bracers": "4a3a28", "robe_len": "short"})
