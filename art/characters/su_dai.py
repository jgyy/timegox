"""Su Dai the Persuader (Part XXXVII): the travelling persuader of the Warring States who told King Anxi of Wei that
ceding land to Qin was carrying firewood to put out a fire (Strategies of the Warring States), and was thanked, and
not heeded. A lean man of fifty in a traveller's rust-brown coat with the dust of nine roads on it, a persuader's
quick brows, a short dark beard going grey, and the patience of somebody who has only ever told people what they knew.
Run: blender --background --python art/characters/su_dai.py  ->  assets/characters/su_dai.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/su_dai.glb", {"age": 0.55, "build": 0.9, "jaw": 0.96, "brow": 1.12, "smile": False, "skin": "c8a882", "robe": "8a5a3a", "trim": "3a2a1e", "inner": "d8d0c0", "sash": "4a3a2a", "pants": "5a4a3a", "shoes": "boots", "hair": "2a2624", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.25, "beard_col": "6a6660", "brow_col": "2a2624", "robe_len": "long"})
