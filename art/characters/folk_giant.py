"""One of the Great People (the Tall People release, scripts/giants.gd, scripts/folk.gd): a man of the Daren, whom the game
draws at twice a man's height. Sculpted as somebody that size is built, not as a man made larger: a head that is small
on the shoulders, a heavy brow and jaw, a deep chest, long thick limbs and big hands, in a short hemp jacket and leg
wraps with a rope for a belt, bare-headed with his hair tied back; the game dyes his clothes.
Run: blender --background --python art/characters/folk_giant.py  ->  assets/characters/folk_giant.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_giant.glb", {"age": 0.35, "build": 1.32, "head_scale": 0.9, "hand_k": 1.16, "jaw": 1.16, "brow": 1.35, "cheek": 1.08, "eye_size": 1.02, "smile": True, "skin": "c49a72",
    "robe": "7a6a52", "trim": "c8b890", "inner": "e0d8c0", "sash": "5a4630", "pants": "5c5446", "robe_len": "short", "wraps": "a89878", "shoes": "sandals",
    "hair": "2a2018", "hair_style": "topknot", "eyes": "3a2a1a", "bracers": "6a5238"})
