"""King Wen of Zhao, Who Loved Swords (Part XXI, the Hundred Arms release; a lord of the story, fought in his own model): three years of watching men
kill each other at his gate have left him thin and grey in a robe of dark red brocade too big for him, a king's crown, a sword he has never drawn in anger.
Run: blender --background --python art/characters/king_zhao.py  ->  assets/characters/king_zhao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/king_zhao.glb", {"fem": False, "age": 0.6, "build": 0.9, "jaw": 0.92, "brow": 1.1, "stern": True, "smile": False, "skin": "d8c8b8", "scale": 1.08,
    "robe": "6a2a3a", "trim": "d8b050", "inner": "e8dcc8", "sash": "d8b050", "pants": "3a1a22", "boots": "2a1418", "hair": "6a6a70", "hair_style": "topknot", "eyes": "5a4a3a",
    "beard": True, "beard_len": 0.45, "beard_col": "7a7a80", "crown": True, "cape": "3a1420", "brocade": "cloud", "brocade_col": "a8504a", "sleeve_w": 1.5, "sword": True, "blade": "e8ecf4", "hilt": "d8b050"})
