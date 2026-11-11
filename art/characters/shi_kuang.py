"""Music-Master Kuang (Part XXIII): Shi Kuang of Jin, who put out his own eyes with mugwort smoke so as to hear better, and could tell from the airs of
the south which host would lose: an old man in plum-grey with a cloth bound over his eyes, his head a little on one side.
Run: blender --background --python art/characters/shi_kuang.py  ->  assets/characters/shi_kuang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/shi_kuang.glb", {"fem": False, "age": 0.75, "build": 0.9, "jaw": 0.95, "brow": 0.9, "stern": False, "smile": True, "skin": "e0ccb6",
    "robe": "6a5a7a", "trim": "c8c0d8", "inner": "ece8f0", "sash": "3a3048", "pants": "4a4058", "boots": "2a2434", "hair": "c8c8cc", "hair_style": "topknot", "eyes": "9a9aa0",
    "beard": True, "beard_len": 0.4, "beard_col": "d0d0d4", "sleeve_w": 1.6, "blindfold": "e8e4dc"})
