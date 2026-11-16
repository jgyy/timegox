"""Yan Ying, Master Yan of Qi (Part XXXI): the minister who stood under six chi and was shown, at the gate of Chu, a small
door cut beside the great one, and said that an envoy to a country of dogs goes in by the dog-door. A short, spare,
elderly man with a very straight back, a thirty-year-old fox-brown robe mended at the cuffs, his hands in his sleeves,
and the bright dry eye of somebody who has never once lost an argument about a door.
Run: blender --background --python art/characters/yan_ying.py  ->  assets/characters/yan_ying.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/yan_ying.glb", {"age": 0.5, "build": 0.9, "scale": 0.86, "head_scale": 1.04, "jaw": 0.92, "brow": 0.95, "smile": True, "skin": "d4b490",
    "robe": "7a5a36", "trim": "d8c8a0", "inner": "f0e8d4", "sash": "3a2e22", "pants": "4a3e30", "boots": "2a221c",
    "hair": "b8b4ac", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.35, "beard_col": "c8c4bc", "pose": "sleeves"})
