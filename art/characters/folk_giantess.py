"""One of the Great People (the Tall People release, scripts/giants.gd, scripts/folk.gd): a woman of the Daren, whom the
game draws at twice a woman's height. Broad in the shoulder and the hip, a small head on a long neck, a strong jaw,
big capable hands; a wrapped hemp dress with a wide woven belt, her hair in one thick braid; the game dyes her clothes.
Run: blender --background --python art/characters/folk_giantess.py  ->  assets/characters/folk_giantess.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/folk_giantess.glb", {"fem": True, "age": 0.3, "build": 1.24, "head_scale": 0.92, "hand_k": 1.08, "jaw": 1.04, "brow": 0.6, "cheek": 1.06, "eye_size": 1.12, "smile": True, "skin": "c8a07a",
    "robe": "8a5a4a", "trim": "d8c8a0", "inner": "ece4d0", "sash": "4a6a5a", "pants": "6a5a4a", "wraps": "b0a080", "shoes": "sandals",
    "hair": "241a14", "hair_style": "long", "hair_len": 0.7, "eyes": "3a2818", "lip": "b86a5c"})
