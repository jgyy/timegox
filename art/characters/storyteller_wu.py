"""Old Wu the storyteller of Cloudfoot: a long white beard, a red robe gone pink with age and a folding fan he snaps shut at the best part of every tale.
Run: blender --background --python art/characters/storyteller_wu.py  ->  assets/characters/storyteller_wu.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/storyteller_wu.glb", {
    "age": 0.9, "build": 0.9, "eye_size": 1.05, "smile": True, "beard": True, "beard_len": 1.0, "beard_col": "f0eee8",
    "robe": "8a3a3a", "trim": "e8d8b8", "inner": "f4ece0", "sash": "d8a040", "hair": "e8e4e0", "hair_style": "topknot",
    "eyes": "3a2a2a", "props": [("folding_fan", {"painted": "8a2a2a"})], "pose": "hold_l", "scale": 0.96,
})
