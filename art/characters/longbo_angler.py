"""The Angler of Longbo (Part XXXI): the giant of the Country of the Dragon Earl who, in a few strides, came to the five
isles of the immortals, let down one line, hooked six of the fifteen great turtles that held them up, and carried them
home on his back to scorch their shells for oracles; for which the Emperor of Heaven made his country narrow and his
people short. A weathered giant in a fisherman's short coat and a wide straw hat, salt in his beard, mild as the sea
on a still day.
Run: blender --background --python art/characters/longbo_angler.py  ->  assets/characters/longbo_angler.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/longbo_angler.glb", {"age": 0.55, "build": 1.28, "head_scale": 0.9, "hand_k": 1.16, "jaw": 1.1, "brow": 1.15, "smile": True, "skin": "a88462",
    "robe": "4a5e5a", "trim": "9ab0a4", "inner": "d0d4c4", "sash": "3a3a30", "pants": "3a4642", "robe_len": "short", "wraps": "8a8a70", "shoes": "sandals",
    "hair": "7a7a74", "hair_style": "topknot", "eyes": "3a4a4a", "beard": True, "beard_len": 0.55, "beard_col": "a0a098", "hat": "straw", "hat_col": "b8a060"})
