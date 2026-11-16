"""The Old Man under the Moon (Part XXXII): who sits on a temple step by moonlight with a book nobody else can read
and a bag of red thread, tying the foot of every man born to the foot of the woman he will marry, and has been heard
to say that he is only the clerk. Very old, very cheerful, a white beard to the sash, a moon-pale robe with a red
hem, the book against his chest and a skein of thread over his wrist.
Run: blender --background --python art/characters/yue_lao.py  ->  assets/characters/yue_lao.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yue_lao.glb", {"age": 0.95, "build": 1.04, "jaw": 1.0, "brow": 1.1, "smile": True, "skin": "ecd0b8",
    "robe": "d8dce8", "trim": "b02828", "inner": "f6f4ee", "sash": "b02828", "pants": "a8acb8", "boots": "4a3a3a",
    "hair": "f0f0ec", "hair_style": "topknot", "eyes": "2a2420", "beard": True, "beard_len": 0.75, "beard_col": "f4f4f0", "brow_col": "f0f0ec",
    "props": [("red_thread", {})], "pose": "hold_l"})
