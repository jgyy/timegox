"""Master Sun (Part XXIII): Sun Wu of Qi, who wrote the thirteen chapters and drilled the King of Wu's palace ladies: a spare, exact man in slate grey
with a black cap, a short dark beard, and nothing about him that could catch on anything.
Run: blender --background --python art/characters/sun_wu.py  ->  assets/characters/sun_wu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/sun_wu.glb", {"fem": False, "age": 0.45, "build": 0.92, "jaw": 1.0, "brow": 1.15, "stern": True, "smile": False, "skin": "dcc8b0",
    "robe": "4a5462", "trim": "1e2228", "inner": "d8d8d4", "sash": "1e2228", "pants": "2e343c", "boots": "1a1c20", "hair": "1e1e24", "hair_style": "topknot", "eyes": "3a3a3a",
    "beard": True, "beard_len": 0.2, "beard_col": "24242a", "crown": True, "sleeve_w": 1.1})
