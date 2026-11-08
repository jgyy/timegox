"""Cartographer Pei of Cloudfoot: a sharp-eyed map-maker in a scholar's hat and spectacles, a half-drawn map in one hand and a brush behind his ear, who has been right about the Court's maps for twelve years.
Run: blender --background --python art/characters/cartographer_pei.py  ->  assets/characters/cartographer_pei.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/cartographer_pei.glb", {
    "age": 0.55, "build": 0.9, "brow": 1.15, "eye_size": 1.0, "beard": True, "beard_len": 0.35, "beard_col": "3a3028",
    "robe": "3e6a5a", "trim": "e8dcc0", "inner": "f0eadc", "sash": "a86a30", "hair": "2a2420", "hair_style": "topknot",
    "eyes": "2a3a2a", "hat": "scholar", "hat_col": "2a2a30", "props": ["scroll", "spectacles"], "pose": "hold_l", "embroidery": "c8a860",
})
