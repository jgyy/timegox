"""Hua Tuo, the physician (Part XXVI): who puts the sick into hot springs and has them do the frolics of five beasts, who
opens people asleep under the boiling-hemp powder and closes them again, and who told a warlord what was in his head; a
wiry old man in undyed hemp with a grey topknot and a short grey beard, straw sandals, a gourd at his belt and a basket of
herbs on his arm.
Run: blender --background --python art/characters/hua_tuo.py  ->  assets/characters/hua_tuo.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/hua_tuo.glb", {"fem": False, "age": 0.78, "build": 0.88, "jaw": 0.96, "brow": 1.1, "cheek": 1.15, "smile": True, "skin": "d4b490",
    "robe": "a89a7a", "trim": "6a5a40", "inner": "ece4d0", "sash": "5a4a30", "pants": "4a3e2a", "boots": "3a3020", "shoes": "sandals",
    "hair": "cdc8be", "hair_style": "topknot", "eyes": "3a2a1a", "beard": True, "beard_len": 0.45, "beard_col": "dcd8d0",
    "props": ["gourd", ("basket", {"col": "a88a50", "fill": "6a8a3a"})], "pose": "hold_l", "sleeve_w": 0.85})
