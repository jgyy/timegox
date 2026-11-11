"""Han Yu the scholar (Part XXII): who climbed to the top to see the view, looked down, and could not get down again;
he wrote his farewells and threw them off the edge: an official's dark blue robe, much rained on.
Run: blender --background --python art/characters/han_yu.py  ->  assets/characters/han_yu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/han_yu.glb", {"fem": False, "age": 0.4, "build": 1.05, "jaw": 1.0, "brow": 1.08, "stern": True, "smile": False, "skin": "dcc0a4",
    "robe": "3a4a6a", "trim": "c8c0a8", "inner": "e8e0d0", "sash": "2a3448", "pants": "2a3040", "boots": "20242c", "hair": "201c1c", "hair_style": "topknot", "eyes": "3a2a1a",
    "beard": True, "beard_len": 0.3, "beard_col": "201c1c", "sleeve_w": 1.4, "pose": "sleeves"})
