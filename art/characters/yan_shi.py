"""Yan Shi the Artificer (Part XIX, the Hundred Works release): the maker who showed King Mu a dancer of leather and
lacquer: a thin old man with young hands, in a faded court robe of violet brocade and a scholar's cap.
Run: blender --background --python art/characters/yan_shi.py  ->  assets/characters/yan_shi.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yan_shi.glb", {"fem": False, "age": 0.8, "build": 0.94, "jaw": 0.92, "brow": 1.05, "skin": "e0c0a0",
    "robe": "5a4a7a", "trim": "c8b060", "inner": "e8e0f0", "sash": "8a3a4a", "pants": "3a3050", "boots": "2a2438", "hair": "c8c4c0", "hair_style": "topknot", "eyes": "3a3048",
    "beard": True, "beard_len": 0.7, "beard_col": "d8d4d0", "hat": "scholar", "hat_col": "2a2438", "brocade": "cloud", "brocade_col": "8a7ab0", "sleeve_w": 1.2})
