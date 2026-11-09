"""A merchant of the towns (scripts/folk.gd): a stout, prosperous man in a long robe with a neat short beard, who keeps a stall in the market by day and sits in the tea house by evening.
Run: blender --background --python art/characters/folk_merchant.py  ->  assets/characters/folk_merchant.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_merchant.glb", {"age": 0.55, "build": 1.32, "cheek": 1.35, "jaw": 1.1, "beard": True, "beard_len": 0.25, "beard_col": "2a221c", "robe": "7a3a3a", "trim": "e8c870", "inner": "f0e6d0", "sash": "2a2a3a", "hair": "1e1a16", "hair_style": "topknot", "eyes": "3a2a1a", "smile": True})
