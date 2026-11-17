"""Bian He (Part XXXV): the man of Chu who found a jade in the rough, was called a liar by two kings' jewellers and
lost a foot to each, and wept three days at the foot of the hills, not for his feet (Han Feizi). A gaunt old man
of seventy in a hill-man's coat of grey-green hemp, white hair loose from its knot, the front of the coat dark; he
is drawn standing, as everybody is, and the game seats him against a rock. He holds nothing in the hand: what he
holds is in his arms.
Run: blender --background --python art/characters/bian_he.py  ->  assets/characters/bian_he.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/bian_he.glb", {"age": 0.85, "build": 0.86, "jaw": 0.94, "brow": 1.15, "smile": False, "skin": "cfb090",
    "robe": "8a9a8a", "trim": "4a5648", "inner": "d8d2c0", "sash": "3a4238", "pants": "5a6456", "shoes": "sandals",
    "hair": "d8d6d0", "hair_style": "wild", "eyes": "3a2e22", "beard": True, "beard_len": 0.5, "beard_col": "e0deda", "brow_col": "d8d6d0", "robe_len": "short"})
