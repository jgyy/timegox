"""The Old Man in the Grass (Part XXVIII): the father of the woman Wei Ke gave in marriage instead of burying, who came
back to knot the grass of the field in front of his benefactor's enemy; a small bent old man in undyed hemp the colour of
dry grass, bare-headed, a thin white beard, straw sandals, a grass-stained apron.
Run: blender --background --python art/characters/grass_elder.py  ->  assets/characters/grass_elder.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/grass_elder.glb", {"fem": False, "age": 0.95, "build": 0.84, "jaw": 0.95, "cheek": 0.9, "smile": True, "skin": "d0b08a",
    "robe": "a89c70", "trim": "7a7048", "inner": "d8d0b0", "sash": "6a7a3a", "pants": "8a8058", "boots": "5a4a2a", "shoes": "sandals", "sleeve_w": 0.8,
    "hair": "e8e4dc", "hair_style": "topknot", "eyes": "3a3020", "beard": True, "beard_len": 0.5, "beard_col": "eeeae2", "scale": 0.92})
