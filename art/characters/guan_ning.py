"""Guan Ning (Part XXIX): the scholar of the end of Han who went on hoeing when gold turned up in the furrow, read on when a
canopied carriage passed the gate, and cut the mat he shared with Hua Xin; who then refused every office for fifty years.
A lean, upright man in a plain dark-green cotton robe with the sleeves tied back for hoeing, a black cloth cap, a short
black beard.
Run: blender --background --python art/characters/guan_ning.py  ->  assets/characters/guan_ning.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/guan_ning.glb", {"fem": False, "age": 0.45, "build": 0.92, "jaw": 1.0, "brow": 1.15, "stern": True, "smile": False, "skin": "c8a680",
    "robe": "4a5a4a", "trim": "2a3228", "inner": "e0d8c8", "sash": "2a3228", "pants": "3a4038", "boots": "2a2620",
    "hair": "18161a", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.2, "beard_col": "18161a"})
