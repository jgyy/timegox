"""Old Bo the Lamplighter (towns): a shade who has lit every lantern in the Dark Capital every night for six hundred years; stooped, pale, with a lantern on a pole.
Run: blender --background --python art/characters/lamplighter_bo.py  ->  assets/characters/lamplighter_bo.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/lamplighter_bo.glb", {
    "age": 0.9, "build": 0.9, "brow": 1.25, "beard": True, "beard_col": "dce4ea", "beard_len": 0.8, "skin": "cad6de", "glow_eyes": True,
    "props": [("lantern", {"col": "e8eef2", "frame": "3a3a44", "glow": "d8f4ff"})], "pose": "hold_l",
    "robe": "6a6a7a", "trim": "c8d0d8", "inner": "e4e8ec", "sash": "3a3a44", "hair": "dce4ea", "hair_style": "topknot", "eyes": "c8f0ff"
})
