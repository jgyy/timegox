"""Watchman Zhou of the Dawn Market (Part IX): an old night-watchman in a straw hat with his gong and an unlit lantern, beating the hours of a night that never comes.
Run: blender --background --python art/characters/watchman_zhou.py  ->  assets/characters/watchman_zhou.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/watchman_zhou.glb", {
    "age": 0.8, "build": 0.95, "beard": True, "beard_len": 0.55, "beard_col": "d8d4cc", "eye_size": 1.0,
    "robe": "4a5a6a", "trim": "d8d0c0", "inner": "e8e4d8", "sash": "8a3a2a", "hair": "c8c4c0", "hair_style": "topknot",
    "eyes": "3a3020", "hat": "straw", "hat_col": "d0b060", "props": [("lantern", {"glow": "fff0d0"}), "drum"], "pose": "hold_l",
})
