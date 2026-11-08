"""Fan, Who Failed the Examinations Nine Times (towns): Longmen's happiest scholar, in a scholar's robe and cap, a brush behind his ear and a book in his hand.
Run: blender --background --python art/characters/examiner_fan.py  ->  assets/characters/examiner_fan.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/examiner_fan.glb", {
    "age": 0.65, "build": 0.9, "brow": 1.1, "jaw": 0.92, "beard": True, "beard_col": "5a5650", "beard_len": 0.7, "smile": True,
    "props": [("ledger", {"cover": "3a3a5a", "paper": "f0e4c0"})], "pose": "hold_l", "hat": "scholar", "hat_col": "141418",
    "robe": "3a3a5a", "trim": "e8dcc0", "inner": "f2ece0", "sash": "8a6a3a", "hair": "5a5650", "hair_style": "topknot", "eyes": "2a2a2a"
})
